{ ===========================================================================
  OpenOLMS — Maintenance Utility (replaces MAINTAIN.EXE)
  GPLv3 — Copyright (C) 2026 FPC264IRC Contributors.
  Clean-room reimplementation. No original source code used.

  From OLMS.DOC and binary analysis:
    MAINTAIN /P      Pack/purge inactive users
    MAINTAIN /P=N    Purge users inactive N days
    MAINTAIN /L      List all users
    MAINTAIN /U name Delete a specific user
    MAINTAIN /R      Rebuild MESSAGES.IDX
    MAINTAIN /S      Show statistics
    MAINTAIN /I      Reindex fast message index
    MAINTAIN /D      Delete duplicate messages
  =========================================================================== }

program olmsmnt;

{$MODE OBJFPC}{$H+}
{$PACKRECORDS 1}

uses
  SysUtils, DateUtils, OL_Compat, OL_Config, OL_Users, OL_MsgCtl;

const
  VERSION = 'OpenOLMS Maintain v1.0';

{ ---- Read user records from USERS.DAT ---- }

function LoadUsersRaw(const Fn: String; var Users: array of TOLMSUser;
  var Count: Integer): Boolean;
var
  F: File;
  BytesRead: Integer;
begin
  Result := False;
  Count := 0;
  if not FileExists(Fn) then Exit;

  AssignFile(F, Fn);
  {$I-} Reset(F, 1); {$I+}
  if IOResult <> 0 then Exit;

  while (not Eof(F)) and (Count < High(Users)) do
  begin
    {$I-} BlockRead(F, Users[Count], SizeOf(TOLMSUser), BytesRead); {$I+}
    if BytesRead <> SizeOf(TOLMSUser) then Break;
    Inc(Count);
  end;

  CloseFile(F);
  Result := Count > 0;
end;

function SaveUsersRaw(const Fn: String; var Users: array of TOLMSUser;
  Count: Integer): Boolean;
var
  F: File;
  I: Integer;
begin
  Result := False;
  AssignFile(F, Fn);
  {$I-} Rewrite(F, 1); {$I+}
  if IOResult <> 0 then Exit;

  for I := 0 to Count - 1 do
    BlockWrite(F, Users[I], SizeOf(TOLMSUser));

  CloseFile(F);
  Result := True;
end;

{ ---- List all users ---- }

procedure DoListUsers;
var
  Users: array[0..OLMS_MAX_USERS-1] of TOLMSUser;
  Count, I: Integer;
  UName, UDate: String;
begin
  WriteLn(VERSION);
  WriteLn;

  if not LoadUsersRaw('USERS.DAT', Users, Count) then
  begin
    WriteLn('Could not open USERS.DAT');
    Exit;
  end;

  WriteLn('Users in database: ', Count);
  WriteLn;
  WriteLn(' #  Name                            Last Date   Status');
  WriteLn('--- -------------------------------- ----------- ------');

  for I := 0 to Count - 1 do
  begin
    UName := ReadTPStr(Users[I].UserName, 30);
    UDate := ReadTPStr(Users[I].LastDate, 8);
    if UName = '' then UName := '(empty slot)';
    WriteLn(Format('%3d %-32s %-11s  $%04x', [
      I + 1, UName, UDate, Users[I].Status]));
  end;
end;

{ ---- Purge inactive users ---- }

procedure DoPurge(Days: Integer);
var
  Users: array[0..OLMS_MAX_USERS-1] of TOLMSUser;
  Count, I, Purged: Integer;
  UName, UDate: String;
  LastAccess: TDateTime;
  Cutoff: TDateTime;
begin
  WriteLn(VERSION);
  WriteLn;

  if not LoadUsersRaw('USERS.DAT', Users, Count) then
  begin
    WriteLn('Could not open USERS.DAT');
    Exit;
  end;

  Cutoff := Now - Days;
  Purged := 0;

  for I := 0 to Count - 1 do
  begin
    UName := ReadTPStr(Users[I].UserName, 30);
    UDate := ReadTPStr(Users[I].LastDate, 8);

    if (UName = '') or (Users[I].Status = 0) then Continue;

    { Parse date MM-DD-YY }
    try
      LastAccess := StrToDate(UDate);
    except
      Continue;  { Can't parse — skip }
    end;

    if LastAccess < Cutoff then
    begin
      WriteLn(Format('  Purging: %-30s  Inactive for %d days',
        [UName, DaysBetween(Now, LastAccess)]));
      FillChar(Users[I], SizeOf(TOLMSUser), 0);
      Users[I].Status := 0;
      Inc(Purged);
    end;
  end;

  if Purged > 0 then
  begin
    SaveUsersRaw('USERS.DAT', Users, Count);
    WriteLn;
    WriteLn('Purged ', Purged, ' user(s).');
  end
  else
    WriteLn('No users to purge.');
end;

{ ---- Delete specific user ---- }

procedure DoDeleteUser(const Target: String);
var
  Users: array[0..OLMS_MAX_USERS-1] of TOLMSUser;
  Count, I: Integer;
  UName: String;
  Found: Boolean;
begin
  WriteLn(VERSION);
  WriteLn;

  if not LoadUsersRaw('USERS.DAT', Users, Count) then
  begin
    WriteLn('Could not open USERS.DAT');
    Exit;
  end;

  Found := False;
  for I := 0 to Count - 1 do
  begin
    UName := ReadTPStr(Users[I].UserName, 30);
    if SameText(UName, Target) then
    begin
      WriteLn('Marked as deleted: ', UName);
      FillChar(Users[I], SizeOf(TOLMSUser), 0);
      Found := True;
      Break;
    end;
  end;

  if Found then
  begin
    SaveUsersRaw('USERS.DAT', Users, Count);
    WriteLn('User deleted. Run /P to pack the database.');
  end
  else
    WriteLn('User not found: ', Target);
end;

{ ---- Rebuild MESSAGES.IDX ---- }

procedure DoRebuildIndex;
var
  Areas: TMsgAreaList;
  F: File of Word;
  I: Integer;
  Users: array[0..OLMS_MAX_USERS-1] of TOLMSUser;
  Count, Active, J: Integer;
begin
  WriteLn(VERSION);
  WriteLn;
  WriteLn('Reindexing fast message index');

  if not LoadMsgCtl('MESSAGES.CTL', Areas) then
  begin
    WriteLn('Could not open MESSAGES.CTL');
    Exit;
  end;

  AssignFile(F, 'MESSAGES.IDX');
  {$I-} Rewrite(F); {$I+}
  if IOResult <> 0 then
  begin
    WriteLn('Cannot create MESSAGES.IDX');
    Exit;
  end;

  for I := 0 to High(Areas) do
    Write(F, Word(Areas[I].AreaNum));

  CloseFile(F);
  WriteLn('Reindexing user file');

  { Rebuild USERS.IDX }
  {$I-}
  AssignFile(F, 'USERS.IDX');
  Rewrite(F);
  {$I+}
  if IOResult = 0 then
  begin
    { Count non-empty user slots }
    Active := 0;
    if LoadUsersRaw('USERS.DAT', Users, Count) then
      for J := 0 to Count - 1 do
        if Users[J].Status <> 0 then Inc(Active);
    Write(F, Word(Active));
    Write(F, Word(0));
    CloseFile(F);
  end;

  WriteLn('Complete');
end;

{ ---- Show statistics ---- }

procedure DoShowStats;
var
  Cfg: TOLMSConfig;
  Areas: TMsgAreaList;
  Users: array[0..OLMS_MAX_USERS-1] of TOLMSUser;
  UCount, ActiveUsers, I: Integer;
begin
  WriteLn(VERSION);
  WriteLn;

  if not OLMSLoadConfig('OLMS.CFG', Cfg) then
  begin
    WriteLn('Invalid configuration file!');
    Exit;
  end;

  WriteLn('BBS Name:     ', Cfg.BBSName);
  WriteLn('Sysop:        ', Cfg.SysopName);
  WriteLn('Board ID:     ', Cfg.BBSName);
  WriteLn('Version:      ', '2000');
  WriteLn;

  if LoadMsgCtl('MESSAGES.CTL', Areas) then
    WriteLn('Message areas: ', Length(Areas))
  else
    WriteLn('MESSAGES.CTL: not found');

  ActiveUsers := 0;
  if LoadUsersRaw('USERS.DAT', Users, UCount) then
  begin
    for I := 0 to UCount - 1 do
      if Users[I].Status <> 0 then Inc(ActiveUsers);
    WriteLn('User slots:    ', UCount, ' (', ActiveUsers, ' active)');
  end
  else
    WriteLn('USERS.DAT: not found');

  WriteLn;
  WriteLn('Paths:');
  WriteLn('  Message base: ', Cfg.MsgBasePath);
  WriteLn('  RA path:      ', Cfg.RAPath);
  WriteLn('  Upload:       ', Cfg.UploadPath);
  WriteLn('  Download:     ', Cfg.DownloadPath);
  WriteLn('  Log:          ', Cfg.MsgBasePath);
end;

{ ---- Sort users alphabetically ---- }

procedure DoSortUsers;
var
  Users: array[0..OLMS_MAX_USERS-1] of TOLMSUser;
  Count, I, J: Integer;
  Temp: TOLMSUser;
  N1, N2: String;
begin
  WriteLn(VERSION);
  WriteLn;

  if not LoadUsersRaw('USERS.DAT', Users, Count) then
  begin
    WriteLn('Could not open USERS.DAT');
    Exit;
  end;

  { Bubble sort by username }
  for I := 0 to Count - 2 do
    for J := I + 1 to Count - 1 do
    begin
      N1 := ReadTPStr(Users[I].UserName, 30);
      N2 := ReadTPStr(Users[J].UserName, 30);
      { Empty slots sort to end }
      if (N1 = '') and (N2 <> '') then
      begin
        Temp := Users[I]; Users[I] := Users[J]; Users[J] := Temp;
      end
      else if (N1 <> '') and (N2 <> '') and (CompareText(N1, N2) > 0) then
      begin
        Temp := Users[I]; Users[I] := Users[J]; Users[J] := Temp;
      end;
    end;

  SaveUsersRaw('USERS.DAT', Users, Count);
  WriteLn('Users sorted');
end;

{ ---- Main ---- }

var
  I: Integer;
  Arg, Param: String;
  Days: Integer;
begin
  if ParamCount = 0 then
  begin
    WriteLn(VERSION);
    WriteLn;
    WriteLn('Usage:');
    WriteLn('  olmsmnt /P           purge inactive users (>90 days)');
    WriteLn('  olmsmnt /P=DAYS      purge users inactive for DAYS');
    WriteLn('  olmsmnt /L           list all users');
    WriteLn('  olmsmnt /U "name"    delete a specific user');
    WriteLn('  olmsmnt /R           rebuild indexes');
    WriteLn('  olmsmnt /S           show statistics');
    WriteLn('  olmsmnt /O           sort users alphabetically');
    Halt(0);
  end;

  for I := 1 to ParamCount do
  begin
    Arg := UpperCase(ParamStr(I));

    if Arg = '/L' then DoListUsers
    else if Arg = '/S' then DoShowStats
    else if Arg = '/R' then DoRebuildIndex
    else if Arg = '/O' then DoSortUsers
    else if Arg = '/P' then DoPurge(90)
    else if Copy(Arg, 1, 3) = '/P=' then
    begin
      Days := StrToIntDef(Copy(Arg, 4, Length(Arg)), 90);
      DoPurge(Days);
    end
    else if Arg = '/U' then
    begin
      if I < ParamCount then
        DoDeleteUser(ParamStr(I + 1))
      else
        WriteLn('Usage: olmsmnt /U "username"');
    end
    else if (Arg = '/?') or (Arg = '-H') or (Arg = '/HELP') then
    begin
      WriteLn(VERSION);
      WriteLn('Run olmsmnt with no args for help.');
    end;
  end;
end.
