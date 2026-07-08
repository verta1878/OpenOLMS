{
  OpenOLMS - mail door (main program)
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

  Built in Free Pascal from published format specifications.
}
program olms;
{ OpenOLMS — olms.exe, the mail DOOR entry point.

  Flow (per OLMS.DOC): the BBS drops the caller in, olms.exe reads the dropfile
  + command-line switches, identifies the session, then runs interactively or
  performs an auto up/download and returns to the BBS or OLMS as directed.

  This milestone wires door support (dropfile + args) to the existing QWK
  engine and reports the session. Message-base scanning (JAM/Hudson) and the
  interactive UI plug in at the marked points next.

  Usage examples (matching the manual):
    olms                         interactive, dropfile in current dir
    olms /DA                     auto-download, no waits, return to BBS
    olms /P=pete_rocca /DA       load user from USERS.BBS, auto-download
    olms --dir <path>            look for the dropfile in <path> }

{$MODE OBJFPC}{$H+}

uses
  SysUtils, olms_types, olms_qwk, olms_config, olms_door, olms_msgbase,
  olms_archiver, olms_filter, olms_pointers;

var
  cfg  : TOlmsConfig;
  sess : TDoorSession;
  opts : TDoorOptions;
  dir  : string;
  i    : Integer;

{ Scan a JAM base and build a QWK packet for the session — the real door job. }
function RunScan(const Dir: string; const S: TDoorSession): Boolean;
var
  reader : IMsgBase;
  P : TOlmsPacket; c : TOlmsConference; m : TOlmsMessage;
  w : IPacketWriter;
  basePath : string;
  idx, got : Integer;
  arc : TArchiveResult;
  filt : TFilterSet;
  ptrs : TPointerStore;
  guard : TLimitGuard;
  lastMsg, highSeen : LongInt;
begin
  Result := False;
  basePath := IncludeTrailingPathDelimiter(Dir) + 'GENERAL';   // demo area
  if not FileExists(basePath + '.JHR') then
  begin
    Writeln('  (no JAM base at ', basePath, '.JHR — nothing to scan)');
    Exit;
  end;
  reader := TJamReader.Create;
  if not reader.Open(basePath) then begin Writeln('  JAM open failed'); Exit; end;

  P := TOlmsPacket.Create;
  try
    P.Info.BBSName := 'Ecstasy BBS'; P.Info.BBSID := 'ECSTASY';
    P.Info.SysopName := 'reapern66';
    if S.Valid then P.Info.UserName := S.UserName else P.Info.UserName := 'SYSOP';
    P.Info.Serial := 'OPENOLMS';
    c := P.AddConference(1, 'General');
    got := 0;
    filt := TFilterSet.Create;
    filt.LoadFromFile(IncludeTrailingPathDelimiter(Dir) + 'FILTER.CFG');  // optional
    ptrs := TPointerStore.Create;
    ptrs.Load(IncludeTrailingPathDelimiter(Dir) + 'POINTERS.DAT');
    guard := TLimitGuard.Create(cfg.Limits);
    lastMsg := ptrs.GetPointer(P.Info.UserName, 1);
    highSeen := lastMsg;
    for idx := 0 to reader.MessageCount-1 do
    begin
      m := TOlmsMessage.Create;
      if reader.ReadMessage(idx, m) then
      begin
        m.ConfNum := 1;
        if (m.MsgNum > lastMsg) and filt.ShouldInclude(m) and guard.CanAdd(m) then
        begin
          c.AddMessage(m); guard.Added(m); Inc(got);
          if m.MsgNum > highSeen then highSeen := m.MsgNum;
        end
        else m.Free;
      end
      else m.Free;
    end;
    ptrs.SetPointer(P.Info.UserName, 1, highSeen);   // advance read pointer
    ptrs.Save;
    guard.Free; ptrs.Free; filt.Free;
    reader.Close;
    Writeln('  scanned ', got, ' NEW message(s) (pointer was ', lastMsg,
            ', now ', highSeen, ', after filters+limits)');

    w := TQwkWriter.Create;
    Result := w.WritePacket(P, IncludeTrailingPathDelimiter(Dir) + 'packet');
    if Result then
    begin
      Writeln('  wrote ', w.FormatName, ' packet -> ', Dir, PathDelim, 'packet');
      // compress into <BBSID>.QWK using the configured archiver
      arc := CompressPacket(cfg, 'ZIP',
               IncludeTrailingPathDelimiter(Dir) + 'packet',
               IncludeTrailingPathDelimiter(Dir) + P.Info.BBSID + '.QWK');
      if arc.Success then
        Writeln('  compressed -> ', P.Info.BBSID, '.QWK  (ready for download)')
      else
        Writeln('  archiver note: ', arc.Output, '  [', arc.Command, ']');
    end
    else
      Writeln('  packet write failed');
  finally
    P.Free;
  end;
end;

function BackStr(n: Integer): string;
begin if n > 0 then Result := ' (back ' + IntToStr(n) + ')' else Result := ''; end;

procedure ShowSession(const S: TDoorSession; const O: TDoorOptions);
const ActName: array[TDoorAction] of string = ('interactive','auto-upload','auto-download');
      AftName: array[TAfterAction] of string = ('return to BBS','return to OLMS','logoff','ask logoff');
begin
  Writeln('OpenOLMS door  (olms.exe)');
  Writeln('-------------------------');
  if O.ForcedUser <> '' then
    Writeln('User (forced /P): ', O.ForcedUser)
  else if S.Valid then
  begin
    Writeln('Dropfile        : ', S.Source);
    Writeln('User            : ', S.UserName);
    Writeln('Node / time     : ', S.Node, ' / ', S.TimeLeftMin, ' min');
    Writeln('Emulation       : ', S.Emulation, '   Port: ', S.ComPort, '   Baud: ', S.Baud);
  end
  else
    Writeln('Dropfile        : none found (', S.Source, ') — would run local/interactive');
  Writeln('Mode            : ', ActName[O.Action], '  (', AftName[O.After], ')');
  if not O.Waits then Writeln('                  no-waits');
  if O.LessPrompts then Writeln('                  less prompts (/L)');
  if O.Vacation then Writeln('                  vacation mail');
  if O.ResetAll then Writeln('                  reset pointers: all areas', BackStr(O.ResetBack));
  if O.ResetSel then Writeln('                  reset pointers: selected areas', BackStr(O.ResetBack));
end;

begin
  dir := GetCurrentDir;
  for i := 1 to ParamCount-1 do
    if ParamStr(i) = '--dir' then dir := ParamStr(i+1);

  cfg := TOlmsConfig.Create;
  try
    cfg.Load(IncludeTrailingPathDelimiter(dir) + 'OLMS.CFG');   // ok if absent (defaults)
    ParseDoorArgs(opts);
    ReadDropfile(dir, sess);

    ShowSession(sess, opts);

    Writeln;
    if opts.Action in [daDownload] then
    begin
      Writeln('Auto-download: scanning bases and building packet...');
      RunScan(dir, sess);
    end
    else
      Writeln('[ interactive mode: conference select + menu UI plug in here ]');
  finally
    cfg.Free;
  end;
end.
