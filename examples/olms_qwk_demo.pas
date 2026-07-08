{
  OpenOLMS - example: build a sample QWK packet
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
program olms_qwk_demo;
{ Builds a sample QWK packet from an in-memory message set — proves the
  OpenOLMS core (data model + QWK writer) end to end.
  Usage: olms_qwk_demo <output_dir> }

{$MODE OBJFPC}{$H+}

uses
  SysUtils, olms_types, olms_qwk;

var
  P : TOlmsPacket;
  c1, c2 : TOlmsConference;
  m : TOlmsMessage;
  w : IPacketWriter;
  outdir : string;

  function NewMsg(num: LongInt; conf: Word; const frm, tto, subj, body: string): TOlmsMessage;
  begin
    Result := TOlmsMessage.Create;
    Result.MsgNum := num; Result.ConfNum := conf; Result.RefNum := 0;
    Result.DateTime := Now;
    Result.Sender := frm; Result.Recipient := tto;
    Result.Subject := subj; Result.Body := body;
  end;

begin
  if ParamCount < 1 then begin Writeln('usage: olms_qwk_demo <output_dir>'); Halt(1); end;
  outdir := ParamStr(1);

  P := TOlmsPacket.Create;
  try
    P.Info.BBSName   := 'Ecstasy BBS';
    P.Info.City      := 'New York, NY';
    P.Info.Phone     := '000-000-0000';
    P.Info.SysopName := 'reapern66';
    P.Info.BBSID     := 'ECSTASY';
    P.Info.UserName  := 'reapern66';
    P.Info.Serial    := 'OPENOLMS';

    c1 := P.AddConference(1, 'General');
    c1.AddMessage(NewMsg(101, 1, 'reapern66', 'All',
      'Welcome', 'Welcome to the board.'#10'This is a QWK test message.'#10'73s.'));
    c1.AddMessage(NewMsg(102, 1, 'g00r00', 'reapern66',
      'Re: Welcome', 'Thanks!'#10'NetModem revival is looking good.'));

    c2 := P.AddConference(2, 'Mystic');
    c2.AddMessage(NewMsg(55, 2, 'lenny', 'All',
      'a38 serial code', 'The modem serial layer is coming along in FPC.'));

    w := TQwkWriter.Create;
    if w.WritePacket(P, outdir) then
      Writeln('Wrote ', w.FormatName, ' packet to ', outdir,
              '  (', P.Count, ' confs, ', P.TotalMessages, ' msgs)')
    else
      Writeln('write failed');
  finally
    P.Free;
  end;
end.
