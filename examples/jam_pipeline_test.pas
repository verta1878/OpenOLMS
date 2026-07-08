{
  OpenOLMS - example: JAM -> QWK pipeline
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
program jam_pipeline_test;
{ Proves Phase 1 end to end:
    1. synthesize a small valid JAM base (.JHR/.JDT)
    2. read it back with TJamReader (IMsgBase)
    3. gather into a TOlmsPacket
    4. write a QWK packet with TQwkWriter
  Usage: jam_pipeline_test <workdir> }

{$MODE OBJFPC}{$H+}

uses
  SysUtils, Classes, olms_types, olms_qwk, olms_msgbase;

{ --- minimal JAM writer, just for the test fixture (open JAM spec) --- }
procedure WriteU16(fs: TFileStream; v: Word);   begin fs.WriteBuffer(v,2); end;
procedure WriteU32(fs: TFileStream; v: LongWord);begin fs.WriteBuffer(v,4); end;

procedure AddSubfield(fs: TFileStream; id: Word; const s: AnsiString);
begin
  WriteU16(fs, id); WriteU16(fs, 0); WriteU32(fs, Length(s));
  if Length(s) > 0 then fs.WriteBuffer(s[1], Length(s));
end;

{ A precise message writer matching olms_msgbase field offsets exactly. }
procedure MakeMsgPrecise(jhr, jdt: TFileStream; msgNum, replyTo: LongWord;
                         const from, tto, subj, body: AnsiString);
var subLen, txtOff: LongWord;
begin
  txtOff := jdt.Position;
  if Length(body) > 0 then jdt.WriteBuffer(body[1], Length(body));
  subLen := (8+Length(from)) + (8+Length(tto)) + (8+Length(subj));

  jhr.WriteBuffer(('JAM'#0)[1], 4);        // +0  sig
  WriteU16(jhr, 1);                        // +4  Revision
  WriteU16(jhr, 0);                        // +6  Reserved
  WriteU32(jhr, subLen);                   // +8  SubfieldLen
  WriteU32(jhr, 0);                        // +12 TimesRead
  WriteU32(jhr, 0);                        // +16 MSGIDcrc
  WriteU32(jhr, 0);                        // +20 REPLYcrc
  WriteU32(jhr, replyTo);                  // +24 ReplyTo
  WriteU32(jhr, 0);                        // +28 Reply1st
  WriteU32(jhr, 0);                        // +32 ReplyNext
  WriteU32(jhr, 1000000000);               // +36 DateWritten (unix)
  WriteU32(jhr, 0);                        // +40 DateReceived
  WriteU32(jhr, 0);                        // +44 DateProcessed
  WriteU32(jhr, msgNum);                   // +48 MessageNumber
  WriteU32(jhr, 0);                        // +52 Attribute
  WriteU32(jhr, 0);                        // +56 Attribute2
  WriteU32(jhr, txtOff);                   // +60 Offset into .JDT
  WriteU32(jhr, Length(body));             // +64 TxtLen
  WriteU32(jhr, 0);                        // +68 PasswordCRC
  WriteU32(jhr, 0);                        // +72 Cost   (fixed header ends @76)
  // subfields
  AddSubfield(jhr, 2, from);   // sender
  AddSubfield(jhr, 3, tto);    // recipient
  AddSubfield(jhr, 6, subj);   // subject
end;

var
  work, basePath: string;
  jhr, jdt: TFileStream;
  reserved: array[0..999] of Byte;
  reader: IMsgBase;
  P: TOlmsPacket; c: TOlmsConference; m: TOlmsMessage;
  w: IPacketWriter;
  i, n: Integer;
begin
  if ParamCount < 1 then begin Writeln('usage: jam_pipeline_test <workdir>'); Halt(1); end;
  work := IncludeTrailingPathDelimiter(ParamStr(1));
  ForceDirectories(work);
  basePath := work + 'GENERAL';

  // 1. synthesize JAM base with the precise writer
  jhr := TFileStream.Create(basePath + '.JHR', fmCreate);
  jdt := TFileStream.Create(basePath + '.JDT', fmCreate);
  try
    jhr.WriteBuffer(('JAM'#0)[1], 4);
    WriteU32(jhr,0); WriteU32(jhr,0); WriteU32(jhr,2); WriteU32(jhr,0); WriteU32(jhr,100);
    FillChar(reserved,SizeOf(reserved),0); jhr.WriteBuffer(reserved,SizeOf(reserved));
    MakeMsgPrecise(jhr, jdt, 100, 0, 'reapern66', 'All', 'Welcome',
                   'Welcome to Ecstasy BBS.'#13'Read offline with OpenOLMS.');
    MakeMsgPrecise(jhr, jdt, 101, 100, 'g00r00', 'reapern66', 'Re: Welcome',
                   'Thanks - the JAM reader works!');
  finally
    jhr.Free; jdt.Free;
  end;
  Writeln('JAM base written: ', basePath, '.JHR/.JDT');

  // 2+3. read it, gather into a packet
  reader := TJamReader.Create;
  if not reader.Open(basePath) then begin Writeln('JAM open failed'); Halt(2); end;
  Writeln('JAM opened: ', reader.MessageCount, ' messages, base#=', reader.BaseMsgNum);

  P := TOlmsPacket.Create;
  try
    P.Info.BBSName:='Ecstasy BBS'; P.Info.City:='New York, NY';
    P.Info.SysopName:='reapern66'; P.Info.BBSID:='ECSTASY';
    P.Info.UserName:='reapern66'; P.Info.Serial:='OPENOLMS';
    c := P.AddConference(1, 'General');

    n := reader.MessageCount;
    for i := 0 to n-1 do
    begin
      m := TOlmsMessage.Create;
      if reader.ReadMessage(i, m) then
      begin
        m.ConfNum := 1;
        c.AddMessage(m);
        Writeln(Format('  msg #%d  from %-12s to %-12s  "%s"',
                [m.MsgNum, m.Sender, m.Recipient, m.Subject]));
      end
      else m.Free;
    end;
    reader.Close;

    // 4. write QWK
    w := TQwkWriter.Create;
    if w.WritePacket(P, work + 'packet') then
      Writeln('QWK packet written to ', work, 'packet  (', P.TotalMessages, ' msgs)')
    else
      Writeln('QWK write failed');
  finally
    P.Free;
  end;
end.
