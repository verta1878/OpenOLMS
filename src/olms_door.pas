{
  OpenOLMS - BBS door integration (dropfiles, switches)
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
unit olms_door;
{ ===========================================================================
  OpenOLMS — door support (the BBS integration layer for olms.exe).

  A mail door is launched BY the bbs, which "drops" the caller into it and
  passes session info via a DROPFILE in the current directory. This unit reads
  those dropfiles and parses OLMS's command-line switches, per OLMS.DOC
  ("Running OLMS", p.19-20).

  Dropfiles supported (OLMS.DOC: "EXITINFO.BBS, DORINFO1.DEF and DOOR.SYS"):
    - DORINFO1.DEF  (FidoNet/RA classic, plain text — implemented)
    - DOOR.SYS      (52-line standard, widely used — implemented)
    - EXITINFO.BBS  (RA binary record — stub; DORINFO/DOOR.SYS cover most)

  Command-line switches (OLMS.DOC p.19):
    /U  /D         auto upload / download
    /UA /DA        ... without waits
    /UL /DL        ... with logoff
    /UQ /DQ        ... with ask-logoff
    trailing R     return to interactive OLMS instead of the BBS
    /L             interactive, fewer prompts
    /V             pack ALL users' vacation mail (event mode)
    /M             vacation mail interface for the user
    /MD /MDA /MDQ /MDL   vacation interface + download (like /D, /DA, ...)
    /NT            do not deduct the user's time
    /RG /RS[=n]    reset pointers (all / selected areas; =n resets back n)
    /P=user_name   load user from USERS.BBS instead of a dropfile
  =========================================================================== }

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, Classes;

type
  TDoorAction = (daInteractive, daUpload, daDownload);
  TAfterAction = (aaReturnBBS, aaReturnOLMS, aaLogoff, aaAskLogoff);

  TDoorSession = record
    Valid       : Boolean;
    UserName    : string;
    FirstName   : string;
    LastName    : string;
    Node        : Integer;
    TimeLeftMin : Integer;   // minutes remaining
    Baud        : LongInt;
    ComPort     : Integer;   // 0 = local
    Emulation   : string;    // 'ANSI' / 'TTY' / 'RIP'
    Source      : string;    // which dropfile / source we used
  end;

  TDoorOptions = record
    Action      : TDoorAction;
    After       : TAfterAction;
    Waits       : Boolean;    // False = the "A" (no waits) variants
    LessPrompts : Boolean;    // /L
    VacationPack: Boolean;    // /V  - pack ALL users' vacation mail (event mode)
    VacationUser: Boolean;    // /M  - vacation mail interface for the user
    NoTime      : Boolean;    // /NT - do not deduct the user's time
    ResetAll    : Boolean;    // /RG
    ResetSel    : Boolean;    // /RS
    ResetBack   : Integer;    // /RG=n or /RS=n  (0 = full)
    ForcedUser  : string;     // /P=name (load from USERS.BBS)
  end;

{ Read the first dropfile found in Dir (DORINFO1.DEF, then DOOR.SYS). }
function ReadDropfile(const Dir: string; out Sess: TDoorSession): Boolean;

{ Parse OLMS-style switches from the command line into Opts. }
procedure ParseDoorArgs(out Opts: TDoorOptions);

implementation

{ ---------- DORINFO1.DEF ----------
  Line-based text dropfile. Relevant lines (1-based):
   1 system name       2 sysop first   3 sysop last   4 COM port ("COM0"=local)
   5 baud line         6 (reserved)    7 user first   8 user last
   9 user city        10 ANSI (1=yes) 11 security     12 time left (minutes) }
function ReadDorinfo(const FileName: string; out S: TDoorSession): Boolean;
var f: TextFile; L: array[1..12] of string; i: Integer; comLine: string;
begin
  Result := False;
  FillChar(S, SizeOf(S), 0);
  if not FileExists(FileName) then Exit;
  AssignFile(f, FileName);
  {$I-} Reset(f); {$I+}
  if IOResult <> 0 then Exit;
  for i := 1 to 12 do begin if Eof(f) then L[i]:='' else Readln(f, L[i]); end;
  CloseFile(f);
  S.FirstName   := Trim(L[7]);
  S.LastName    := Trim(L[8]);
  S.UserName    := Trim(S.FirstName + ' ' + S.LastName);
  comLine       := Trim(L[4]);
  if (comLine = 'COM0') or (comLine = '0') then S.ComPort := 0
    else S.ComPort := StrToIntDef(Copy(comLine, 4, 2), 0);
  S.Baud        := StrToIntDef(Trim(L[5]), 0);
  if Trim(L[10]) = '1' then S.Emulation := 'ANSI' else S.Emulation := 'TTY';
  S.TimeLeftMin := StrToIntDef(Trim(L[12]), 0);
  S.Node        := 1;
  S.Source      := 'DORINFO1.DEF';
  S.Valid       := S.UserName <> '';
  Result        := S.Valid;
end;

{ ---------- DOOR.SYS ----------
  52-line standard dropfile. Relevant lines:
   1 COMx:(0=local) 2 baud 6 usernum 10 user full name 11 city
   14 time left(min) 15 emulation(GR: 0=none/1=ANSI) 18 node ... }
function ReadDoorSys(const FileName: string; out S: TDoorSession): Boolean;
var f: TextFile; L: array[1..52] of string; i: Integer; comLine: string;
begin
  Result := False;
  FillChar(S, SizeOf(S), 0);
  if not FileExists(FileName) then Exit;
  AssignFile(f, FileName);
  {$I-} Reset(f); {$I+}
  if IOResult <> 0 then Exit;
  for i := 1 to 52 do begin if Eof(f) then L[i]:='' else Readln(f, L[i]); end;
  CloseFile(f);
  comLine := Trim(L[1]);
  if (comLine = 'COM0:') or (comLine = '0') then S.ComPort := 0
    else S.ComPort := StrToIntDef(Copy(comLine, 4, 1), 0);
  S.Baud        := StrToIntDef(Trim(L[2]), 0);
  S.UserName    := Trim(L[10]);
  if Pos(' ', S.UserName) > 0 then
  begin
    S.FirstName := Copy(S.UserName, 1, Pos(' ', S.UserName)-1);
    S.LastName  := Copy(S.UserName, Pos(' ', S.UserName)+1, MaxInt);
  end
  else S.FirstName := S.UserName;
  S.TimeLeftMin := StrToIntDef(Trim(L[14]), 0);
  if Trim(L[15]) = '0' then S.Emulation := 'TTY' else S.Emulation := 'ANSI';
  S.Node        := StrToIntDef(Trim(L[18]), 1);
  S.Source      := 'DOOR.SYS';
  S.Valid       := S.UserName <> '';
  Result        := S.Valid;
end;

function ReadDropfile(const Dir: string; out Sess: TDoorSession): Boolean;
var base: string;
begin
  base := IncludeTrailingPathDelimiter(Dir);
  if ReadDorinfo(base + 'DORINFO1.DEF', Sess) then Exit(True);
  if ReadDoorSys (base + 'DOOR.SYS',    Sess) then Exit(True);
  // EXITINFO.BBS (RA binary) could be added here.
  FillChar(Sess, SizeOf(Sess), 0);
  Sess.Source := '(none)';
  Result := False;
end;

procedure ParseDoorArgs(out Opts: TDoorOptions);
var i, eq: Integer; a, up: string;

  procedure ApplyAfter(const s: string);
  begin
    if Pos('R', s) > 0 then Opts.After := aaReturnOLMS
    else if Pos('L', s) > 0 then Opts.After := aaLogoff
    else if Pos('Q', s) > 0 then Opts.After := aaAskLogoff
    else Opts.After := aaReturnBBS;
  end;

  { Apply a download-style action + variants from a switch tail like "AQ" / "LR". }
  procedure ApplyDLVariant(const tail: string);
  begin
    Opts.Action := daDownload;
    Opts.Waits  := Pos('A', tail) = 0;
    ApplyAfter(tail);
  end;

begin
  FillChar(Opts, SizeOf(Opts), 0);
  Opts.Action := daInteractive;
  Opts.After  := aaReturnBBS;
  Opts.Waits  := True;

  for i := 1 to ParamCount do
  begin
    a := ParamStr(i);
    if (a = '') or (a[1] <> '/') then Continue;
    up := UpperCase(a);

    if Copy(up,1,3) = '/P=' then Opts.ForcedUser := Copy(a, 4, MaxInt)
    else if up = '/NT' then Opts.NoTime := True         // no time deduction
    else if up = '/L' then Opts.LessPrompts := True
    else if up = '/V' then Opts.VacationPack := True     // pack all vacation mail
    else if Copy(up,1,3) = '/MD' then                    // /MD /MDA /MDQ /MDL
      begin Opts.VacationUser := True; ApplyDLVariant(Copy(up,4,MaxInt)); end
    else if up = '/M' then Opts.VacationUser := True     // user vacation interface
    else if Copy(up,1,3) = '/RG' then
      begin Opts.ResetAll := True; eq := Pos('=', a); if eq>0 then Opts.ResetBack := StrToIntDef(Copy(a,eq+1,MaxInt),0); end
    else if Copy(up,1,3) = '/RS' then
      begin Opts.ResetSel := True; eq := Pos('=', a); if eq>0 then Opts.ResetBack := StrToIntDef(Copy(a,eq+1,MaxInt),0); end
    else if Copy(up,1,2) = '/U' then
      begin Opts.Action := daUpload;   Opts.Waits := Pos('A', up)=0; ApplyAfter(Copy(up,3,MaxInt)); end
    else if Copy(up,1,2) = '/D' then
      begin Opts.Action := daDownload; Opts.Waits := Pos('A', up)=0; ApplyAfter(Copy(up,3,MaxInt)); end;
  end;
end;

end.
