{
  OpenOLMS - QWK packet writer
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
unit olms_qwk;
{ ===========================================================================
  OpenOLMS — QWK packet writer.

  Emits a standard QWK offline-mail packet from a TOlmsPacket:
    CONTROL.DAT   - BBS info + conference list (text)
    MESSAGES.DAT  - 128-byte-block message store (header block + text blocks)
    <conf>.NDX    - per-conference index of message offsets

  Built entirely from the public QWK format (Mark "Sparky" Herring, 1987), the
  same spec every reader implements. No OLMS code involved.

  QWK MESSAGES.DAT layout (128-byte blocks):
    Block 0 : 128-char ident/copyright text.
    Each message : 1 header block + ceil(len/128) text blocks.
      Text uses 0xE3 (227) as the line separator instead of CRLF, space-padded
      to the block boundary.
    Header block fields (1-based byte positions):
      1     status char
      2-8   message number (ASCII, 7)
      9-16  date MM-DD-YY (8)
      17-21 time HH:MM (5)
      22-46 To   (25)
      47-71 From (25)
      72-96 Subject (25)
      97-108 password (12)
      109-116 reference number (8)
      117-122 number of 128-byte blocks incl. header (ASCII, 6)
      123   active flag (225 active / 226 deleted)
      124-125 conference number (16-bit LE)
      126-127 packet msg number (16-bit LE)
      128   net-tag indicator (' ')
  =========================================================================== }

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, Classes, olms_types;

type
  TQwkWriter = class(TInterfacedObject, IPacketWriter)
  public
    function WritePacket(P: TOlmsPacket; const OutputDir: string): Boolean;
    function FormatName: string;
  end;

implementation

const
  QWK_BLOCK = 128;
  QWK_SEP   = #227;   // 0xE3 line separator in message text
  ACTIVE    = #225;   // 0xE1

function PadRt(const S: string; N: Integer): string;
begin
  Result := Copy(S, 1, N);
  while Length(Result) < N do Result := Result + ' ';
end;

function PadNum(V: LongInt; N: Integer): string;
begin
  Result := IntToStr(V);
  Result := Copy(Result, 1, N);
  while Length(Result) < N do Result := Result + ' ';
end;

{ CONTROL.DAT — the packet manifest the reader parses first. }
procedure WriteControl(P: TOlmsPacket; const Dir: string);
var
  f: TextFile; i: Integer; c: TOlmsConference;
begin
  AssignFile(f, IncludeTrailingPathDelimiter(Dir) + 'CONTROL.DAT');
  Rewrite(f);
  Writeln(f, P.Info.BBSName);
  Writeln(f, P.Info.City);
  Writeln(f, P.Info.Phone);
  Writeln(f, P.Info.SysopName);
  Writeln(f, P.Info.Serial, ',', P.Info.BBSID);         // "serial,BBSID"
  Writeln(f, FormatDateTime('mm-dd-yyyy,hh:nn:ss', Now));
  Writeln(f, UpperCase(P.Info.UserName));
  Writeln(f, '');                                       // reader menu (blank)
  Writeln(f, '0');                                      // (reserved)
  Writeln(f, P.TotalMessages);                          // total messages
  Writeln(f, P.Count - 1);                              // highest conf index (count-1)
  for i := 0 to P.Count-1 do
  begin
    c := P.Conf(i);
    Writeln(f, c.Number);                               // conf number
    Writeln(f, c.Name);                                 // conf name
  end;
  Writeln(f, 'HELLO');                                  // welcome file
  Writeln(f, 'NEWS');                                   // news file
  Writeln(f, 'GOODBYE');                                // logoff file
  CloseFile(f);
end;

{ Encode a message body into QWK text blocks (E3 line sep, space-padded). }
function EncodeBody(const Body: string): AnsiString;
var s: AnsiString; i: Integer; pad: Integer;
begin
  s := '';
  for i := 1 to Length(Body) do
    if Body[i] = #10 then s := s + QWK_SEP
    else if Body[i] <> #13 then s := s + Body[i];
  if (Length(s) = 0) or (s[Length(s)] <> QWK_SEP) then s := s + QWK_SEP;
  pad := (QWK_BLOCK - (Length(s) mod QWK_BLOCK)) mod QWK_BLOCK;
  s := s + StringOfChar(' ', pad);
  Result := s;
end;

function TQwkWriter.WritePacket(P: TOlmsPacket; const OutputDir: string): Boolean;
var
  msgFile : TFileStream;
  ndx     : TFileStream;
  dir     : string;
  ci, mi  : Integer;
  c       : TOlmsConference;
  m       : TOlmsMessage;
  ident   : AnsiString;
  hdr     : AnsiString;
  bodyEnc : AnsiString;
  blocks  : Integer;
  packetMsgNo : Word;
  blockOffset : LongInt;   // 1-based block number of this msg's header (for NDX)
  ndxRec  : packed record OfsFloat: Single; Conf: Byte; end;

  procedure WriteBlockStr(fs: TFileStream; const S: AnsiString);
  begin if Length(S) > 0 then fs.WriteBuffer(S[1], Length(S)); end;

begin
  Result := False;
  dir := IncludeTrailingPathDelimiter(OutputDir);
  ForceDirectories(dir);

  WriteControl(P, OutputDir);

  msgFile := TFileStream.Create(dir + 'MESSAGES.DAT', fmCreate);
  try
    // Block 0: 128-char identifier text
    ident := PadRt('Produced by OpenOLMS. Format QWK by Sparky Herring.', QWK_BLOCK);
    WriteBlockStr(msgFile, ident);

    packetMsgNo := 0;
    for ci := 0 to P.Count-1 do
    begin
      c := P.Conf(ci);
      if c.Count = 0 then Continue;

      // one .NDX per conference: <confnum>.NDX
      ndx := TFileStream.Create(dir + Format('%.3d.NDX', [c.Number]), fmCreate);
      try
        for mi := 0 to c.Count-1 do
        begin
          m := c.Msg(mi);
          Inc(packetMsgNo);

          bodyEnc := EncodeBody(m.Body);
          blocks  := 1 + (Length(bodyEnc) div QWK_BLOCK);   // header + text blocks

          // header block position = current file size / 128, then +1 (1-based)
          blockOffset := (msgFile.Position div QWK_BLOCK) + 1;

          // build the 128-byte header block
          hdr := ' ';                                        // 1 status
          hdr := hdr + PadNum(m.MsgNum, 7);                  // 2-8
          hdr := hdr + PadRt(FormatDateTime('mm-dd-yy', m.DateTime), 8);  // 9-16
          hdr := hdr + PadRt(FormatDateTime('hh:nn', m.DateTime), 5);     // 17-21
          hdr := hdr + PadRt(m.Recipient, 25);               // 22-46
          hdr := hdr + PadRt(m.Sender, 25);                  // 47-71
          hdr := hdr + PadRt(m.Subject, 25);                 // 72-96
          hdr := hdr + PadRt('', 12);                        // 97-108 password
          if m.RefNum > 0 then hdr := hdr + PadNum(m.RefNum, 8)
                          else hdr := hdr + PadRt('', 8);    // 109-116
          hdr := hdr + PadNum(blocks, 6);                    // 117-122
          hdr := hdr + ACTIVE;                               // 123 active
          hdr := hdr + Chr(c.Number and $FF) + Chr((c.Number shr 8) and $FF);      // 124-125 conf LE
          hdr := hdr + Chr(packetMsgNo and $FF) + Chr((packetMsgNo shr 8) and $FF);// 126-127 pkt no LE
          hdr := hdr + ' ';                                  // 128 net tag
          // (hdr is exactly 128 bytes)

          WriteBlockStr(msgFile, hdr);
          WriteBlockStr(msgFile, bodyEnc);

          // NDX record: 4-byte MS-Binary float block number + 1 byte conf.
          // Readers accept IEEE single in practice; we store block number.
          ndxRec.OfsFloat := blockOffset;
          ndxRec.Conf := c.Number and $FF;
          ndx.WriteBuffer(ndxRec, SizeOf(ndxRec));
        end;
      finally
        ndx.Free;
      end;
    end;
  finally
    msgFile.Free;
  end;

  Result := True;
end;

function TQwkWriter.FormatName: string;
begin Result := 'QWK'; end;

end.
