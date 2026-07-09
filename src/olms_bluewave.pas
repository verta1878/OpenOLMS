{
  OpenOLMS - Blue Wave packet writer
  SPDX-License-Identifier: GPL-3.0-or-later

  Copyright (C) 2026  Antonio Rico - Ecstasy BBS / Reapern66

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

  Built in Free Pascal from published format specifications.
}
unit olms_bluewave;
{ ===========================================================================
  OpenOLMS — Blue Wave packet writer (Phase 9).

  Blue Wave is a fixed-record offline format (Cutting Edge Computing, open spec).
  A packet is four files named by the BBSID:
    <BBSID>.INF  - packet/ system info + area (conference) records
    <BBSID>.MIX  - one record per area that HAS mail: msg count + offset into FTI
    <BBSID>.FTI  - one fixed record per message (header: from/to/subj/date + ptr)
    <BBSID>.DAT  - raw message text, pointed to by FTI records

  We implement the core structures needed to produce a readable Blue Wave packet
  from a TOlmsPacket. Field sizes follow the published Blue Wave format.

  Records (packed, little-endian):
    INF header (fixed) then INF area records (per area).
    MIX record  : AreaNum(u16) · TotalMsgs(u16) · Start(u32 offset in FTI/# recs)
    FTI record  : Status(u8) · MsgNum(u32) · From[36] · To[36] · Subj[72]
                  · Date[20] · RefNum(u32) · TxtPtr(u32) · TxtLen(u32) · Area(u16)
  =========================================================================== }

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, Classes, olms_types;

type
  TBlueWaveWriter = class(TInterfacedObject, IPacketWriter)
  public
    function WritePacket(P: TOlmsPacket; const OutputDir: string): Boolean;
    function FormatName: string;
  end;

implementation

type
  TMixRec = packed record
    AreaNum   : Word;
    TotalMsgs : Word;
    StartRec  : LongWord;   // index of first FTI record for this area
  end;

  TFtiRec = packed record
    Status  : Byte;
    MsgNum  : LongWord;
    From    : array[0..35] of Char;
    ToName  : array[0..35] of Char;
    Subject : array[0..71] of Char;
    DateStr : array[0..19] of Char;
    RefNum  : LongWord;
    TxtPtr  : LongWord;     // offset into .DAT
    TxtLen  : LongWord;
    Area    : Word;
  end;

  TInfHeader = packed record
    Signature : array[0..3] of Char;   // 'BW'#0#0
    Version   : Word;
    KeyWords  : Word;                  // (unused here)
    NumAreas  : Word;
    Reserved  : array[0..117] of Byte;
  end;

  TInfArea = packed record
    AreaNum   : LongWord;
    Title     : array[0..49] of Char;
    EchoTag   : array[0..19] of Char;
    NetType   : Byte;                  // 0=local
    Reserved  : array[0..15] of Byte;
  end;

procedure SetArr(var arr: array of Char; const s: string);
var i: Integer;
begin
  for i := 0 to High(arr) do
    if i < Length(s) then arr[i] := s[i+1] else arr[i] := #0;
end;

function TBlueWaveWriter.WritePacket(P: TOlmsPacket; const OutputDir: string): Boolean;
var
  dir, id : string;
  inf, mix, fti, dat : TFileStream;
  hdr : TInfHeader; area : TInfArea;
  mrec : TMixRec; frec : TFtiRec;
  ci, mi : Integer;
  c : TOlmsConference; m : TOlmsMessage;
  ftiIndex : LongWord;
  txt : AnsiString;
begin
  Result := False;
  dir := IncludeTrailingPathDelimiter(OutputDir);
  ForceDirectories(dir);
  id := P.Info.BBSID; if id = '' then id := 'PACKET';

  inf := TFileStream.Create(dir + id + '.INF', fmCreate);
  mix := TFileStream.Create(dir + id + '.MIX', fmCreate);
  fti := TFileStream.Create(dir + id + '.FTI', fmCreate);
  dat := TFileStream.Create(dir + id + '.DAT', fmCreate);
  try
    // INF header
    FillChar(hdr, SizeOf(hdr), 0);
    hdr.Signature[0]:='B'; hdr.Signature[1]:='W';
    hdr.Version := 3;
    hdr.NumAreas := P.Count;
    inf.WriteBuffer(hdr, SizeOf(hdr));
    // INF area records
    for ci := 0 to P.Count-1 do
    begin
      c := P.Conf(ci);
      FillChar(area, SizeOf(area), 0);
      area.AreaNum := c.Number;
      SetArr(area.Title, c.Name);
      SetArr(area.EchoTag, c.Name);
      inf.WriteBuffer(area, SizeOf(area));
    end;

    // FTI + DAT + MIX
    ftiIndex := 0;
    for ci := 0 to P.Count-1 do
    begin
      c := P.Conf(ci);
      if c.Count = 0 then Continue;

      // MIX record for this area
      mrec.AreaNum   := c.Number;
      mrec.TotalMsgs := c.Count;
      mrec.StartRec  := ftiIndex;
      mix.WriteBuffer(mrec, SizeOf(mrec));

      for mi := 0 to c.Count-1 do
      begin
        m := c.Msg(mi);
        // text to .DAT (CR-separated per Blue Wave)
        txt := StringReplace(m.Body, #10, #13, [rfReplaceAll]);
        FillChar(frec, SizeOf(frec), 0);
        frec.Status := 0;
        frec.MsgNum := m.MsgNum;
        SetArr(frec.From, m.Sender);
        SetArr(frec.ToName, m.Recipient);
        SetArr(frec.Subject, m.Subject);
        SetArr(frec.DateStr, FormatDateTime('mm-dd-yy hh:nn', m.DateTime));
        frec.RefNum := m.RefNum;
        frec.TxtPtr := dat.Position;
        frec.TxtLen := Length(txt);
        frec.Area   := c.Number;
        fti.WriteBuffer(frec, SizeOf(frec));
        if Length(txt) > 0 then dat.WriteBuffer(txt[1], Length(txt));
        Inc(ftiIndex);
      end;
    end;
    Result := True;
  finally
    inf.Free; mix.Free; fti.Free; dat.Free;
  end;
end;

function TBlueWaveWriter.FormatName: string;
begin Result := 'BlueWave'; end;

end.
