{
  OpenOLMS - QWKE packet writer
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
unit olms_qwke;
{ ===========================================================================
  OpenOLMS — QWKE packet writer (Phase 8).

  QWKE extends QWK to carry long To/From/Subject (QWK caps each at 25 chars).
  It reuses the entire QWK packet (CONTROL.DAT, MESSAGES.DAT, *.NDX) and ADDS a
  text file, TOREADER.EXT, whose lines give the full-length fields per message,
  keyed by packet message number. Readers that understand QWKE use the long
  fields; plain QWK readers ignore the extra file. (Open QWKE spec.)

  TOREADER.EXT line format (one directive per line):
    To: <n> <fullname>       full recipient for packet msg #n
    From: <n> <fullname>     full sender
    Subject: <n> <text>      full subject
  We emit these only when a field exceeds the 25-char QWK limit (that's the
  whole point), keeping the file compact.

  Implementation: delegate the base packet to the QWK writer, then append EXT.
  =========================================================================== }

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, Classes, olms_types, olms_qwk;

type
  TQwkeWriter = class(TInterfacedObject, IPacketWriter)
  public
    function WritePacket(P: TOlmsPacket; const OutputDir: string): Boolean;
    function FormatName: string;
  end;

implementation

function TQwkeWriter.WritePacket(P: TOlmsPacket; const OutputDir: string): Boolean;
var
  qwk : IPacketWriter;
  ext : TextFile;
  dir : string;
  ci, mi, pktNo : Integer;
  c : TOlmsConference; m : TOlmsMessage;
  need : Boolean;
begin
  // 1. write the standard QWK packet (25-char fields, full compatibility)
  qwk := TQwkWriter.Create;
  Result := qwk.WritePacket(P, OutputDir);
  if not Result then Exit;

  // 2. append TOREADER.EXT with long fields, matching packet msg numbering
  dir := IncludeTrailingPathDelimiter(OutputDir);
  AssignFile(ext, dir + 'TOREADER.EXT');
  {$I-} Rewrite(ext); {$I+}
  if IOResult <> 0 then Exit;

  pktNo := 0;
  for ci := 0 to P.Count-1 do
  begin
    c := P.Conf(ci);
    for mi := 0 to c.Count-1 do
    begin
      m := c.Msg(mi);
      Inc(pktNo);   // must match TQwkWriter's packet numbering (1-based, in order)
      need := (Length(m.Recipient) > 25) or (Length(m.Sender) > 25) or (Length(m.Subject) > 25);
      if need then
      begin
        if Length(m.Recipient) > 25 then Writeln(ext, 'To: ', pktNo, ' ', m.Recipient);
        if Length(m.Sender)    > 25 then Writeln(ext, 'From: ', pktNo, ' ', m.Sender);
        if Length(m.Subject)   > 25 then Writeln(ext, 'Subject: ', pktNo, ' ', m.Subject);
      end;
    end;
  end;
  CloseFile(ext);
  Result := True;
end;

function TQwkeWriter.FormatName: string;
begin Result := 'QWKE'; end;

end.
