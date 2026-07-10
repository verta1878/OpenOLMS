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
  olms_hudson, olms_rep, olms_archiver, olms_filter, olms_pointers,
  olms_runtime, olms_ver;

var
  cfg  : TOlmsConfig;
  sess : TDoorSession;
  opts : TDoorOptions;
  dir  : string;
  i    : Integer;
  logg : TOlmsLog;

{ Open the right reader for an area; nil if the base isn't present. }
function OpenAreaReader(const Dir: string; const A: TMsgArea): IMsgBase;
var jam: TJamReader; hud: THudsonReader; base: string;
begin
  Result := nil;
  base := A.Path;
  // absolute if it has a drive (X:) or starts with a path separator
  if not ((Length(base) >= 2) and (base[2] = ':')) and
     not ((Length(base) >= 1) and ((base[1] = '\') or (base[1] = '/'))) then
    base := IncludeTrailingPathDelimiter(Dir) + base;
  if A.Kind = akJAM then
  begin
    if not FileExists(base + '.JHR') then Exit;
    jam := TJamReader.Create;
    if jam.Open(base) then Result := jam else jam.Free;
  end
  else
  begin
    hud := THudsonReader.Create;
    if hud.OpenBase(ExtractFilePath(base + '.'), A.Board) then Result := hud else hud.Free;
  end;
end;

{ Scan all configured message areas and build a QWK packet for the session. }
function RunScan(const Dir: string; const S: TDoorSession): Boolean;
var
  reader : IMsgBase;
  P : TOlmsPacket; c : TOlmsConference; m : TOlmsMessage;
  w : IPacketWriter;
  idx, gotArea, gotTotal, ai : Integer;
  arc : TArchiveResult;
  filt : TFilterSet;
  ptrs : TPointerStore;
  guard : TLimitGuard;
  lastMsg, highSeen : LongInt;
  user, qwkPath : string;
begin
  Result := False;
  if S.Valid then user := S.UserName else user := 'SYSOP';
  if opts.ForcedUser <> '' then user := opts.ForcedUser;

  filt := TFilterSet.Create;
  filt.LoadFromFile(IncludeTrailingPathDelimiter(Dir) + 'FILTER.CFG');
  ptrs := TPointerStore.Create;
  ptrs.Load(IncludeTrailingPathDelimiter(Dir) + 'POINTERS.DAT');
  guard := TLimitGuard.Create(cfg.Limits);

  P := TOlmsPacket.Create;
  try
    P.Info.BBSName   := cfg.Sys.SystemName;
    P.Info.SysopName := cfg.Sys.SysopName;
    P.Info.BBSID     := cfg.Sys.BoardID; if P.Info.BBSID = '' then P.Info.BBSID := 'PACKET';
    P.Info.Phone     := cfg.Sys.Phone;
    P.Info.UserName  := user;
    P.Info.Serial    := OLMS_NAME + ' ' + OLMS_VERSION;

    gotTotal := 0;
    for ai := 0 to cfg.AreaCount-1 do
    begin
      if not cfg.Areas[ai].Active then Continue;
      reader := OpenAreaReader(Dir, cfg.Areas[ai]);
      if reader = nil then
      begin
        logg.Verbose('area ' + IntToStr(cfg.Areas[ai].Number) + ' (' +
                     cfg.Areas[ai].Name + '): base not found, skipped');
        Continue;
      end;
      c := P.AddConference(cfg.Areas[ai].Number, cfg.Areas[ai].Name);
      lastMsg := ptrs.GetPointer(user, cfg.Areas[ai].Number);
      highSeen := lastMsg;
      gotArea := 0;
      for idx := 0 to reader.MessageCount-1 do
      begin
        m := TOlmsMessage.Create;
        if reader.ReadMessage(idx, m) then
        begin
          m.ConfNum := cfg.Areas[ai].Number;
          if (m.MsgNum > lastMsg) and filt.ShouldInclude(m) and guard.CanAdd(m) then
          begin
            c.AddMessage(m); guard.Added(m); Inc(gotArea); Inc(gotTotal);
            if m.MsgNum > highSeen then highSeen := m.MsgNum;
          end
          else m.Free;
        end
        else m.Free;
      end;
      ptrs.SetPointer(user, cfg.Areas[ai].Number, highSeen);
      reader.Close;
      Writeln('  area ', cfg.Areas[ai].Number:3, ' ', cfg.Areas[ai].Name,
              ': ', gotArea, ' new');
      logg.Log('area ' + IntToStr(cfg.Areas[ai].Number) + ' ' + cfg.Areas[ai].Name +
               ': ' + IntToStr(gotArea) + ' new for ' + user);
    end;
    ptrs.Save;

    Writeln('  ', gotTotal, ' new message(s) across ', P.Count, ' area(s)');
    if gotTotal = 0 then
    begin
      Writeln('  nothing new to pack.');
      logg.Log(user + ': no new mail');
      Exit(True);
    end;

    w := TQwkWriter.Create;
    if not w.WritePacket(P, IncludeTrailingPathDelimiter(Dir) + 'packet') then
    begin Writeln('  packet write failed'); Exit(False); end;
    Writeln('  wrote ', w.FormatName, ' packet');

    qwkPath := IncludeTrailingPathDelimiter(Dir) + P.Info.BBSID + '.QWK';
    arc := CompressPacket(cfg, cfg.Archivers[0].Tag,
             IncludeTrailingPathDelimiter(Dir) + 'packet', qwkPath);
    if arc.Success then
    begin
      Writeln('  compressed -> ', P.Info.BBSID, '.QWK  (ready for download)');
      logg.Log(user + ': packed ' + IntToStr(gotTotal) + ' msgs -> ' + P.Info.BBSID + '.QWK');
      Result := True;
    end
    else
    begin
      Writeln('  ARCHIVER FAILED: ', arc.Output);
      Writeln('  (set your archiver in CONFIG.EXE; PKZIP/PKUNZIP must be on the PATH)');
      logg.Log(user + ': ARCHIVER FAILED - ' + arc.Output);
      Result := False;
    end;
  finally
    guard.Free; ptrs.Free; filt.Free; P.Free;
  end;
end;

{ /U upload: extract the caller's <BBSID>.REP and report the replies. }
function RunUpload(const Dir: string; const S: TDoorSession): Boolean;
var
  repPath, msgPath, user : string;
  arc : TArchiveResult;
  rep : TRepReader;
  R : TOlmsPacket; n : Integer;
begin
  Result := False;
  if S.Valid then user := S.UserName else user := 'SYSOP';
  repPath := IncludeTrailingPathDelimiter(Dir) + cfg.Sys.BoardID + '.REP';
  if not FileExists(repPath) then
  begin
    Writeln('  no reply packet (', cfg.Sys.BoardID, '.REP) found.');
    Exit(True);
  end;
  arc := ExtractReply(cfg, cfg.Archivers[0].Tag, repPath,
                      IncludeTrailingPathDelimiter(Dir) + 'rep');
  msgPath := IncludeTrailingPathDelimiter(Dir) + 'rep' + PathDelim + cfg.Sys.BoardID + '.MSG';
  if not FileExists(msgPath) then
  begin
    Writeln('  could not extract replies: ', arc.Output);
    logg.Log(user + ': reply extract FAILED - ' + arc.Output);
    Exit(False);
  end;
  R := TOlmsPacket.Create;
  rep := TRepReader.Create;
  try
    n := rep.ReadReplies(msgPath, R);
    Writeln('  read ', n, ' reply/replies from ', user);
    logg.Log(user + ': uploaded ' + IntToStr(n) + ' replies');
    Result := True;
  finally
    rep.Free; R.Free;
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
  if O.VacationPack then Writeln('                  vacation: pack all users');
  if O.VacationUser then Writeln('                  vacation: user interface');
  if O.NoTime then Writeln('                  no time deduction (/NT)');
  if O.ResetAll then Writeln('                  reset pointers: all areas', BackStr(O.ResetBack));
  if O.ResetSel then Writeln('                  reset pointers: selected areas', BackStr(O.ResetBack));
end;

procedure ShowHelp;
begin
  Writeln('Usage: OLMS [switches]   (run as a BBS door)');
  Writeln('  /D  /U        auto download / upload new mail');
  Writeln('  /DA /UA       ... without waits    /DL /UL  ... with logoff');
  Writeln('  /DQ /UQ       ... with ask-logoff');
  Writeln('  add R         return to OLMS instead of the BBS (e.g. /DAR)');
  Writeln('  /L            interactive with fewer prompts');
  Writeln('  /V            pack ALL users vacation mail (run at an event)');
  Writeln('  /M            vacation mail interface for the user');
  Writeln('  /MD /MDA...   vacation interface + download');
  Writeln('  /NT           do not deduct the user''s time');
  Writeln('  /RG /RS[=n]   reset message pointers (all / selected; back n)');
  Writeln('  /P=name       load user from USERS.BBS (put first)');
  Writeln('  --dir <path>  working directory (default: current)');
  Writeln('  /?            this help    --version  show version');
  Writeln;
  Writeln('Use CONFIG.EXE to view or edit the configuration (OLMS.CFG).');
end;

begin
  dir := GetCurrentDir;
  for i := 1 to ParamCount do
  begin
    if (ParamStr(i) = '--dir') and (i < ParamCount) then dir := ParamStr(i+1);
    if (ParamStr(i) = '--version') or (ParamStr(i) = '-v') then
    begin Writeln(OLMS_BANNER); Halt(0); end;
    if (ParamStr(i) = '--help') or (ParamStr(i) = '-h') or (ParamStr(i) = '/?') then
    begin
      Writeln(OLMS_BANNER);
      ShowHelp;
      Halt(0);
    end;
  end;

  cfg := TOlmsConfig.Create;
  logg := TOlmsLog.Create(IncludeTrailingPathDelimiter(dir) + 'OLMS.LOG', lmNormal);
  try
    Writeln(OLMS_BANNER);
    cfg.Load(IncludeTrailingPathDelimiter(dir) + 'OLMS.CFG');   // defaults if absent
    ParseDoorArgs(opts);
    ReadDropfile(dir, sess);
    logg.Log('start: user=' + sess.UserName + ' action=' + IntToStr(Ord(opts.Action)));

    case opts.Action of
      daDownload:
        begin
          ShowSession(sess, opts);
          Writeln;
          Writeln('Download: scanning message areas...');
          if RunScan(dir, sess) then ExitCode := 0 else ExitCode := 1;
        end;
      daUpload:
        begin
          ShowSession(sess, opts);
          Writeln;
          Writeln('Upload: processing replies...');
          if RunUpload(dir, sess) then ExitCode := 0 else ExitCode := 1;
        end;
    else
      // Bare run (no switches): show the command line so the sysop sees the
      // options. CONFIG.EXE views/edits OLMS.CFG.
      ShowHelp;
      ExitCode := 0;
    end;
  finally
    logg.Free;
    cfg.Free;
  end;
end.
