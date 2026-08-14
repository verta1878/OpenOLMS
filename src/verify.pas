{ verify.pas — Byte-for-byte verification against original OLMS data files }
program verify;

{$MODE OBJFPC}{$H+}
{$PACKRECORDS 1}

uses
  SysUtils, OL_Compat, OL_MsgCtl, OL_Users, OL_Screens;

const
  OLMS_DIR = '../OLMS/';

procedure CompareFiles(const Name, File1, File2: String);
var
  F1, F2: File;
  B1, B2: Byte;
  Pos: LongInt;
  Size1, Size2: LongInt;
  Mismatches: Integer;
begin
  Write('  ', Name:20, ': ');

  if not FileExists(File1) then begin WriteLn('ORIGINAL MISSING'); Exit; end;
  if not FileExists(File2) then begin WriteLn('OUTPUT MISSING'); Exit; end;

  AssignFile(F1, File1); Reset(F1, 1);
  AssignFile(F2, File2); Reset(F2, 1);

  Size1 := FileSize(F1);
  Size2 := FileSize(F2);

  if Size1 <> Size2 then
  begin
    WriteLn('SIZE MISMATCH: orig=', Size1, ' ours=', Size2);
    CloseFile(F1); CloseFile(F2);
    Exit;
  end;

  Mismatches := 0;
  Pos := 0;
  while not EOF(F1) do
  begin
    BlockRead(F1, B1, 1);
    BlockRead(F2, B2, 1);
    if B1 <> B2 then
    begin
      if Mismatches < 5 then
        WriteLn('MISMATCH at offset ', Pos, ': orig=$', IntToHex(B1, 2),
                ' ours=$', IntToHex(B2, 2));
      Inc(Mismatches);
    end;
    Inc(Pos);
  end;

  CloseFile(F1); CloseFile(F2);

  if Mismatches = 0 then
    WriteLn('MATCH (', Size1, ' bytes)')
  else
    WriteLn('  TOTAL MISMATCHES: ', Mismatches, ' of ', Size1, ' bytes');
end;

{ ---- Test 1: OLMS.CFG round-trip ---- }
procedure TestConfig;
var
  CfgRaw: TOLMSConfigRaw;
begin
  WriteLn('=== TEST 1: OLMS.CFG Round-Trip ===');
  WriteLn;

  if not OLMSLoadConfig(OLMS_DIR + 'OLMS.CFG', CfgRaw) then
  begin
    WriteLn('  Failed to load OLMS.CFG');
    Exit;
  end;

  WriteLn('  Loaded: Version=', CfgGetVersion(CfgRaw),
          ' BBS="', CfgGetBBSName(CfgRaw), '"',
          ' Sysop="', CfgGetSysopName(CfgRaw), '"');

  { Write back }
  OLMSSaveConfig('/tmp/OLMS_OUT.CFG', CfgRaw);

  { Compare }
  CompareFiles('OLMS.CFG', OLMS_DIR + 'OLMS.CFG', '/tmp/OLMS_OUT.CFG');
  WriteLn;
end;

{ ---- Test 2: MESSAGES.CTL round-trip ---- }
procedure TestMessages;
var
  Areas: TMsgAreaList;
begin
  WriteLn('=== TEST 2: MESSAGES.CTL Round-Trip ===');
  WriteLn;

  if not LoadMsgCtl(OLMS_DIR + 'MESSAGES.CTL', Areas) then
  begin
    WriteLn('  Failed to load MESSAGES.CTL');
    Exit;
  end;

  WriteLn('  Loaded: ', Length(Areas), ' areas');
  if Length(Areas) > 0 then
    WriteLn('  First: "', Areas[0].Name, '" AreaNum=', Areas[0].AreaNum);

  { Write back }
  SaveMsgCtl('/tmp/MESSAGES_OUT.CTL', Areas);

  CompareFiles('MESSAGES.CTL', OLMS_DIR + 'MESSAGES.CTL', '/tmp/MESSAGES_OUT.CTL');
  WriteLn;
end;

{ ---- Test 3: USERS.DAT round-trip ---- }
procedure TestUsers;
var
  F1, F2: File;
  Users: array[0..OLMS_MAX_USERS-1] of TOLMSUser;
  Count, I, BytesRead: Integer;
begin
  WriteLn('=== TEST 3: USERS.DAT Round-Trip ===');
  WriteLn;

  if not FileExists(OLMS_DIR + 'USERS.DAT') then
  begin
    WriteLn('  USERS.DAT not found');
    Exit;
  end;

  { Read original }
  AssignFile(F1, OLMS_DIR + 'USERS.DAT');
  Reset(F1, 1);
  Count := 0;
  while not EOF(F1) do
  begin
    BlockRead(F1, Users[Count], SizeOf(TOLMSUser), BytesRead);
    if BytesRead <> SizeOf(TOLMSUser) then Break;
    Inc(Count);
  end;
  CloseFile(F1);

  WriteLn('  Loaded: ', Count, ' user records (', Count * SizeOf(TOLMSUser), ' bytes)');

  { Show first user }
  if Count > 0 then
    WriteLn('  First: "', ReadTPStr(Users[0].UserName, 30), '"',
            ' Status=', Users[0].Status,
            ' Access=', Users[0].AccessLevel);

  { Write back }
  AssignFile(F2, '/tmp/USERS_OUT.DAT');
  Rewrite(F2, 1);
  for I := 0 to Count - 1 do
    BlockWrite(F2, Users[I], SizeOf(TOLMSUser));
  CloseFile(F2);

  CompareFiles('USERS.DAT', OLMS_DIR + 'USERS.DAT', '/tmp/USERS_OUT.DAT');
  WriteLn;
end;

{ ---- Test 4: SCREENS.DAT parse ---- }
procedure TestScreens;
var
  Arch: TScreenArchive;
  I: Integer;
  Data: String;
begin
  WriteLn('=== TEST 4: SCREENS.DAT Parse ===');
  WriteLn;

  if not LoadScreens(OLMS_DIR + 'SCREENS.DAT', Arch) then
  begin
    WriteLn('  Failed to load SCREENS.DAT');
    Exit;
  end;

  WriteLn('  Loaded: ', Arch.Count, ' screen entries');
  WriteLn;

  for I := 0 to Arch.Count - 1 do
  begin
    Data := GetScreenData(Arch, I);
    WriteLn('  ', I+1:3, ' ', Arch.Entries[I].Name:14,
            '  offset=', Arch.Entries[I].Offset:6,
            '  size=', Arch.Entries[I].Size:5,
            '  read=', Length(Data):5);
  end;
  WriteLn;
end;

{ ---- Test 5: Record sizes ---- }
procedure TestRecordSizes;
begin
  WriteLn('=== TEST 5: Record Size Verification ===');
  WriteLn;
  WriteLn('  TOLMSConfigRaw: ', SizeOf(TOLMSConfigRaw), ' bytes (expect 14889)');
  WriteLn('  TOLMSUser:      ', SizeOf(TOLMSUser), ' bytes (expect 478)');
  WriteLn('  TOLMSArea:      ', SizeOf(TOLMSArea), ' bytes (expect 64)');
  WriteLn('  TOLMSUserIdx:   ', SizeOf(TOLMSUserIdx), ' bytes (expect 4)');
  WriteLn;
end;

{ ---- Main ---- }
begin
  WriteLn('OpenOLMS Byte-for-Byte Verification');
  WriteLn('====================================');
  WriteLn;

  TestRecordSizes;
  TestConfig;
  TestMessages;
  TestUsers;
  TestScreens;

  WriteLn('Verification complete.');
end.
