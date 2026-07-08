{
  OpenOLMS - QWK reply (.REP) reader
  SPDX-License-Identifier: GPL-3.0-or-later

  Copyright (C) 2026  Antonio Rico / Ecstasy BBS (github.com/verta1878)

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.

  OpenOLMS is a clean-room reimplementation of the OLMS offline-mail door,
  written from published format specifications and documentation. It contains
  no code from the original OLMS.
}
unit olms_rep;
{ ===========================================================================
  OpenOLMS — QWK reply intake (Phase 3).

  The return direction of the round trip. After reading mail offline, a caller's
  reader bundles replies into  <BBSID>.REP  — a compressed packet whose payload
  is  <BBSID>.MSG , a 128-byte-block message store in the SAME layout as a QWK
  MESSAGES.DAT, EXCEPT there is no leading identifier block: the file begins at
  the first message header. (Open QWK/.REP spec.)

  Flow: olms.exe receives <BBSID>.REP -> ExtractReply (archiver) -> this unit
  parses <BBSID>.MSG -> messages get posted back to the message base.

  Header fields are read at the same offsets the QWK writer produced, so this
  round-trips cleanly with olms_qwk.
  =========================================================================== }

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, Classes, olms_types;

type
  TRepReader = class
  private
    FStream : TFileStream;
  public
    { Parse a <BBSID>.MSG file into a TOlmsPacket (one conference bucket per
      conference number found). Returns count of replies read. }
    function ReadReplies(const MsgFile: string; Dest: TOlmsPacket): Integer;
  end;

implementation

const
  QWK_BLOCK = 128;
  QWK_SEP   = #227;   // 0xE3 line separator

{ Read a fixed-width field from a 128-byte header block (1-based positions). }
function Fld(const Blk: AnsiString; Start, Len: Integer): string;
begin
  Result := Trim(Copy(Blk, Start, Len));
end;

function TRepReader.ReadReplies(const MsgFile: string; Dest: TOlmsPacket): Integer;
var
  hdr : AnsiString;
  textBuf : AnsiString;
  blocks, i : Integer;
  confNum : Word;
  m : TOlmsMessage;
  c : TOlmsConference;
  body : string;

  function GetConf(num: Word): TOlmsConference;
  var k: Integer;
  begin
    Result := nil;
    for k := 0 to Dest.Count-1 do
      if Dest.Conf(k).Number = num then Exit(Dest.Conf(k));
    Result := Dest.AddConference(num, 'Conf ' + IntToStr(num));
  end;

begin
  Result := 0;
  if not FileExists(MsgFile) then Exit;
  FStream := TFileStream.Create(MsgFile, fmOpenRead or fmShareDenyNone);
  try
    SetLength(hdr, QWK_BLOCK);
    // .REP MSG has NO ident block; start at byte 0.
    while FStream.Position + QWK_BLOCK <= FStream.Size do
    begin
      FStream.ReadBuffer(hdr[1], QWK_BLOCK);

      // block count incl. header is at bytes 117-122 (ASCII)
      blocks := StrToIntDef(Fld(hdr, 117, 6), 1);
      if blocks < 1 then blocks := 1;

      // conference number: bytes 124-125 (16-bit LE)
      confNum := Byte(hdr[124]) or (Byte(hdr[125]) shl 8);

      // read the message text blocks
      SetLength(textBuf, (blocks-1)*QWK_BLOCK);
      if blocks > 1 then FStream.ReadBuffer(textBuf[1], (blocks-1)*QWK_BLOCK);

      // decode 0xE3 separators back to LF, trim trailing pad
      body := StringReplace(textBuf, QWK_SEP, #10, [rfReplaceAll]);
      body := TrimRight(body);

      m := TOlmsMessage.Create;
      m.MsgNum    := StrToIntDef(Fld(hdr, 2, 7), 0);
      m.DateTime  := Now;                       // reply time = now (upload)
      m.Recipient := Fld(hdr, 22, 25);
      m.Sender    := Fld(hdr, 47, 25);
      m.Subject   := Fld(hdr, 72, 25);
      m.RefNum    := StrToIntDef(Fld(hdr, 109, 8), 0);
      m.ConfNum   := confNum;
      m.Body      := body;

      c := GetConf(confNum);
      c.AddMessage(m);
      Inc(Result);
    end;
  finally
    FreeAndNil(FStream);
  end;
end;

end.
