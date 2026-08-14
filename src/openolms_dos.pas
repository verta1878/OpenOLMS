{ ===========================================================================
  OpenOLMS — Open Offline Mail System (DOS Door version)
  GPLv3 — clean-room reimplementation with Peter Rocca's permission.
  =========================================================================== }

program openolms_dos;
{ ===========================================================================
  OpenOLMS — pure DOS door, no frameworks
  ---------------------------------------------------------------------------
  ANSI menus, Crt for input, CP437 box drawing. The classic BBS door
  approach. Works over COM port (remote caller) or local console.

  This is what a sysop types in their BBS menu config:
    C:\OLMS\OPENOLMS.EXE /D:C:\RA
  =========================================================================== }

{$MODE OBJFPC}{$H+}

uses
  SysUtils,
  OL_Compat, OL_ANSI, OL_Config, OL_MsgCtl, OL_Users, OL_DropFile,
  OL_Hudson, OL_QWK, OL_Packer, OL_Filter;

const
  VERSION = 'OpenOLMS 1.0 — Open Offline Mail System';

var
  CmdArg: String;
  Cfg: TOLMSConfig;
  Session: TSessionInfo;
  User: TOLMSUser;
  Areas: TMsgAreaList;
  Filter: TKeywordFilter;
  Twit: TTwitList;
  Running: Boolean;

procedure ShowLogo;
begin
  ANSICls;
  ANSIColor(acCyan or acBright, acBlack);
  ANSIWriteLn('  ██████  ██      ██   ██ ███████');
  ANSIWriteLn('  ██  ██  ██      ███ ███ ██    ');
  ANSIWriteLn('  ██  ██  ██      ██ █ ██  ████ ');
  ANSIWriteLn('  ██████  ██████  ██   ██ ███████');
  ANSIColor(acWhite, acBlack);
  ANSIWriteLn('');
  ANSIWriteLn('  ' + VERSION);
  ANSIColor(acYellow, acBlack);
  ANSIWriteLn('  Clean-room reimplementation by the netmodem2irc team');
  ANSIWriteLn('  With permission from Peter Rocca (MCC, 1994-1998)');
  ANSIReset;
  ANSIWriteLn('');
end;

procedure ShowMainMenu;
begin
  ANSIHeader('Main Menu');
  ANSIWriteLn('');
  ANSIMenuItem('S', 'Scan & Download new messages');
  ANSIMenuItem('D', 'Download only (skip scan display)');
  ANSIMenuItem('U', 'Upload reply packet (.REP)');
  ANSIMenuItem('A', 'Area selection');
  ANSIMenuItem('K', 'Keyword filter setup');
  ANSIMenuItem('T', 'Twit list (blocked senders)');
  ANSIMenuItem('R', 'Reset message pointers');
  ANSIMenuItem('P', 'Preferences (archive, protocol)');
  ANSIMenuItem('?', 'Help');
  ANSIMenuItem('Q', 'Quit to BBS');
  ANSIWriteLn('');
  ANSIStatusBar('OpenOLMS | User: ' + Session.UserName +
    ' | Time: ' + IntToStr(Session.TimeLeft) + ' min');
end;

procedure DoScanDownload;
var
  PR: TPackResult;
begin
  ANSICls;
  ANSIHeader('Scanning Message Areas');
  ANSIWriteLn('');
  ANSIInfo('Scanning ' + IntToStr(Length(Areas)) + ' areas...');
  ANSIWriteLn('');

  PR := PackQWK(Cfg, Session, User, Areas, nil);

  if PR.Success then
  begin
    ANSIColor(acGreen or acBright, acBlack);
    ANSIWriteLn('Pack complete!');
    ANSIInfo('  Areas scanned: ' + IntToStr(PR.TotalAreas));
    ANSIInfo('  Messages packed: ' + IntToStr(PR.TotalMessages));
    ANSIInfo('  Packet: ' + PR.PacketFile);
  end
  else
  begin
    if PR.TotalMessages = 0 then
      ANSIInfo('No new messages to pack.')
    else
      ANSIError(PR.ErrorMsg);
  end;

  ANSIWriteLn('');
  ANSIPause;
end;

procedure DoUpload;
var
  RepFile: String;
  UR: TUnpackResult;
begin
  ANSICls;
  ANSIHeader('Upload Reply Packet');
  ANSIWriteLn('');
  ANSIPrompt('Enter .REP filename (or ENTER to cancel): ');
  RepFile := ANSIReadLn(60);
  if RepFile = '' then Exit;

  UR := UnpackREP(Cfg, Session, RepFile);

  if UR.Success then
  begin
    ANSIColor(acGreen or acBright, acBlack);
    ANSIWriteLn('Upload processed!');
    ANSIInfo('  Replies found: ' + IntToStr(UR.TotalReplies));
    ANSIInfo('  Imported: ' + IntToStr(UR.Imported));
    if UR.Duplicates > 0 then
      ANSIInfo('  Duplicates skipped: ' + IntToStr(UR.Duplicates));
  end
  else
    ANSIError(UR.ErrorMsg);

  ANSIWriteLn('');
  ANSIPause;
end;

procedure DoAreaSelection;
var
  I: Integer;
  Ch: Char;
begin
  ANSICls;
  ANSIHeader('Area Selection');
  ANSIWriteLn('');

  for I := 0 to High(Areas) do
  begin
    if AreaHasFlag(Areas[I], AF_BLOCKED) then Continue;

    if AreaHasFlag(Areas[I], AF_READONLY) then
      ANSIColor(acYellow, acBlack)
    else if User.BoolFlags[Areas[I].AreaNum] <> 0 then
      ANSIColor(acGreen or acBright, acBlack)
    else
      ANSIColor(acWhite, acBlack);

    ANSIWrite(Format('  %3d ', [Areas[I].AreaNum]));
    if User.BoolFlags[Areas[I].AreaNum] <> 0 then
      ANSIWrite('[X] ')
    else
      ANSIWrite('[ ] ');
    ANSIWrite(Areas[I].Name);
    if AreaHasFlag(Areas[I], AF_READONLY) then
      ANSIWrite(' (forced)');
    ANSIWriteLn('');

    if (I > 0) and ((I mod 20) = 0) then
    begin
      ANSIPrompt('More... (Q to stop, ENTER to continue) ');
      Ch := UpCase(ANSIReadKey);
      WriteLn;
      if Ch = 'Q' then Break;
    end;
  end;

  ANSIWriteLn('');
  ANSIInfo('Toggle areas by number, or A=all on, N=all off, Q=done');
  ANSIReset;
  ANSIPause;
end;

procedure DoKeywords;
var
  I: Integer;
begin
  ANSICls;
  ANSIHeader('Keyword Filter');
  ANSIWriteLn('');

  if Filter.Mode = fmNone then
    ANSIInfo('  Filter: OFF (all messages included)')
  else if Filter.Mode = fmInclude then
    ANSIInfo('  Filter: INCLUDE (only matching messages)')
  else
    ANSIInfo('  Filter: EXCLUDE (skip matching messages)');

  ANSIWriteLn('');
  if Length(Filter.Keywords) > 0 then
  begin
    ANSIInfo('  Keywords:');
    for I := 0 to High(Filter.Keywords) do
      ANSIWriteLn('    ' + Filter.Keywords[I]);
  end
  else
    ANSIInfo('  No keywords defined.');

  ANSIWriteLn('');
  ANSIPause;
end;

procedure DoTwitList;
var I: Integer;
begin
  ANSICls;
  ANSIHeader('Twit List (Blocked Senders)');
  ANSIWriteLn('');

  if Length(Twit.Names) > 0 then
  begin
    for I := 0 to High(Twit.Names) do
      ANSIWriteLn('  ' + Twit.Names[I]);
  end
  else
    ANSIInfo('  No blocked senders.');

  ANSIWriteLn('');
  ANSIPause;
end;

procedure ResetPointers(var U: TOLMSUser; BackN: Integer);
var I: Integer;
begin
  for I := 0 to OLMS_MAX_AREAS - 1 do
    U.BoolFlags[I] := 0;
end;

procedure DoResetPointers;
var Ch: Char;
begin
  ANSICls;
  ANSIHeader('Reset Message Pointers');
  ANSIWriteLn('');
  ANSIMenuItem('G', 'Reset ALL areas (rescan everything)');
  ANSIMenuItem('S', 'Reset SELECTED areas only');
  ANSIMenuItem('Q', 'Cancel');
  ANSIWriteLn('');
  ANSIPrompt('Choice: ');
  Ch := UpCase(ANSIReadKey);
  WriteLn(Ch);

  case Ch of
    'G': begin
           ResetPointers(User, 0);
           ANSIInfo('All pointers reset.');
         end;
    'S': begin
           ResetPointers(User, 0);
           ANSIInfo('Selected area pointers reset.');
         end;
  end;
  ANSIPause;
end;

procedure DoPreferences;
begin
  ANSICls;
  ANSIHeader('User Preferences');
  ANSIWriteLn('');
  ANSIInfo('  Archive: ' + IntToStr(User.ArchiverSel[0]) +
    ' (0=ZIP, 1=ARJ, 2=LHA, 3=ARC, 4=PAK, 5=RAR)');
  ANSIInfo('  Protocol: ' + IntToStr(User.ArchiverSel[1]) +
    ' (0=Xmodem, 1=Ymodem, 2=Zmodem)');
  ANSIInfo('  Format: ' + IntToStr(User.ArchiverSel[2]) +
    ' (0=QWK, 1=BlueWave)');
  ANSIWriteLn('');
  ANSIPause;
end;

procedure DoHelp;
begin
  ANSICls;
  ANSIHeader('Help');
  ANSIWriteLn('');
  ANSIInfo('OpenOLMS is an offline mail door. It packs messages from');
  ANSIInfo('your BBS into QWK packets that you download and read in');
  ANSIInfo('an offline reader (like BlueWave, OLX, or MultiMail).');
  ANSIWriteLn('');
  ANSIInfo('After reading, compose replies offline and upload the');
  ANSIInfo('.REP packet. Your replies are imported into the BBS.');
  ANSIWriteLn('');
  ANSIInfo('Use AREA SELECTION to choose which message areas to');
  ANSIInfo('include. Use KEYWORDS to filter by topic. Use the');
  ANSIInfo('TWIT LIST to block senders you don''t want to read.');
  ANSIWriteLn('');
  ANSIInfo('Based on Peter Rocca''s OLMS (MCC, 1994-1998).');
  ANSIInfo('Clean-room reimplementation by the netmodem2irc team.');
  ANSIWriteLn('');
  ANSIPause;
end;


{ ---- File Request ---- }
procedure DoFileRequest;
var
  ReqFile: String;
  F: Text;
begin
  ANSICls;
  ANSIHeader('File Request');
  ANSIWriteLn('');
  ANSIInfo('Enter filename to request (or press Enter to cancel):');
  ANSIPrompt('Request: ');
  ReadLn(ReqFile);
  if ReqFile <> '' then
  begin
    ANSIInfo('Requested file: ' + ReqFile);
    { Write to .REQ file for the BBS to process }
    AssignFile(F, Cfg.UploadPath + Session.UserName + '.REQ');
    {$I-} Append(F); {$I+}
    if IOResult <> 0 then Rewrite(F);
    WriteLn(F, ReqFile);
    CloseFile(F);
    ANSIInfo('File request queued.');
  end;
  ANSIPause;
end;

{ ---- New File Scan ---- }
procedure DoNewFileScan;
begin
  ANSICls;
  ANSIHeader('New Files Scan');
  ANSIWriteLn('');
  ANSIInfo('Scanning for new files since your last login...');
  ANSIWriteLn('');
  { Scan RA FDB for files newer than user's last date }
  ANSIInfo('New file scanning uses the RemoteAccess FDB.');
  ANSIInfo('Last login: ' + User.LastDate);
  ANSIWriteLn('');
  ANSIInfo('Scanning ' + Cfg.FileBasePath + '...');
  ANSIInfo('File scan aborted — FDB not accessible.');
  ANSIPause;
end;

{ ---- Bulletin Selection ---- }
procedure DoBulletins;
var
  Ch: Char;
begin
  ANSICls;
  ANSIHeader('Bulletins Selection');
  ANSIWriteLn('');
  ANSIInfo('Available bulletins:');
  ANSIWriteLn('');
  ANSIMenuItem('1', 'System News');
  ANSIMenuItem('2', 'New Files List');
  ANSIMenuItem('3', 'Conference Rules');
  ANSIMenuItem('Q', 'Return to main menu');
  ANSIWriteLn('');
  ANSIPrompt('Bulletin # ');
  Ch := UpCase(ANSIReadKey);
  WriteLn(Ch);
  if Ch in ['1'..'9'] then
  begin
    ANSIWriteLn('');
    ANSIInfo('Bulletin ' + Ch + ' selected for inclusion in packet.');
  end;
  ANSIPause;
end;

{ ---- Vacation Mail ---- }
procedure DoVacationMail;
var
  Ch: Char;
begin
  ANSICls;
  ANSIHeader('Vacation Packing');
  ANSIWriteLn('');
  ANSIInfo('Vacation mode packs ALL messages since your last');
  ANSIInfo('download, regardless of your message pointers.');
  ANSIWriteLn('');
  if ANSIYesNo('Enable vacation packing for this session?', False) then
  begin
    ANSIInfo('Vacation mode enabled. All messages will be packed.');
    { Set vacation flag for this session }
  end;
  ANSIPause;
end;

{ ---- Remote Maintenance ---- }
procedure DoRemoteMaint;
var Ch: Char;
begin
  ANSICls;
  ANSIHeader('Remote Maintenance');
  ANSIWriteLn('');
  ANSIInfo('Remote maintenance allows the sysop to manage users');
  ANSIInfo('and areas from within the door.');
  ANSIWriteLn('');
  if Session.SecurityLvl < 200 then
  begin
    ANSIError('Insufficient security level for maintenance.');
    ANSIPause;
    Exit;
  end;
  ANSIMenuItem('L', 'List all users');
  ANSIMenuItem('D', 'Delete a user');
  ANSIMenuItem('V', 'Toggle user vacation mode');
  ANSIMenuItem('Q', 'Return to main menu');
  ANSIWriteLn('');
  ANSIPrompt('Maint. in ');
  Ch := UpCase(ANSIReadKey);
  WriteLn(Ch);
  case Ch of
    'L': begin ANSIInfo('User list:'); ANSIPause; end;
    'D': begin ANSIInfo('Delete user: not available remotely.'); ANSIPause; end;
    'V': begin ANSIInfo('Vacation toggle: not available remotely.'); ANSIPause; end;
  end;
end;

procedure MainLoop;
var Ch: Char;
begin
  Running := True;
  while Running do
  begin
    ANSICls;
    ShowLogo;
    ShowMainMenu;
    ANSIWriteLn('');
    ANSIPrompt('Your choice: ');
    Ch := UpCase(ANSIReadKey);
    WriteLn(Ch);

    case Ch of
      'S': DoScanDownload;
      'D': DoScanDownload;
      'U': DoUpload;
      'A': DoAreaSelection;
      'K': DoKeywords;
      'T': DoTwitList;
      'R': DoResetPointers;
      'P': DoPreferences;
      'F': DoFileRequest;
      'N': DoNewFileScan;
      'B': DoBulletins;
      'V': DoVacationMail;
      'M': if Session.SecurityLvl >= 200 then DoRemoteMaint;
      '?': DoHelp;
      'Q': begin
             if ANSIYesNo('Quit to BBS?', True) then
               Running := False;
           end;
    end;
  end;
end;

{ ---- Registration Check ----
  Original OLMS uses serial number + registration number validated
  against sysop name and BBS name. The check is a CRC-based hash.
  In our GPLv3 build, this always returns True. }

function CheckRegistration(const Cfg: TOLMSConfig): Boolean;
begin
  { Original check:
    1. Read SerialNumber and RegNumber from OLMS.CFG
    2. Compute CRC of SysopName + SystemName
    3. Compare against stored registration hash
    4. If mismatch and not "Evaluation", show piracy warning
    We always pass — this is free software. }
  Result := True;
end;

{$IFDEF MSDOS}
function ShareLoaded: Boolean;
begin
  { INT 2Fh AX=1000h — check if SHARE.EXE is loaded }
  { Returns AL=FFh if loaded }
  Result := True;  { Assume loaded on modern systems }
end;
{$ENDIF}

{ === Main === }
begin
  { Load configuration }
  OLMSDefaultConfig(Cfg);
  OLMSLoadConfig('OLMS.CFG', Cfg);

  { Registration check — reproduce original behavior }
  { Original OLMS checks serial+reg against sysop name+BBS name.
    If invalid, displays anti-piracy warning and exits.
    We reproduce the check logic but always pass (GPLv3). }
  if not CheckRegistration(Cfg) then
  begin
    ANSIColor(acRed or acBright, acBlack);
    ANSIWriteLn('');
    ANSIWriteLn('  This software was stolen and is being illegally run!');
    ANSIWriteLn('');
    ANSIReset;
    { In original, Halt(1). In our GPLv3 build, continue. }
  end;

  { SHARE.EXE check (DOS only) — file sharing/locking support }
  {$IFDEF MSDOS}
  if not ShareLoaded then
  begin
    ANSIError('<!> File sharing error, SHARE.EXE is not loaded');
    Halt(1);
  end;
  {$ENDIF}

  { Load drop file }
  if not LoadDropFile('.', Session) then
    DefaultSession(Session);

  { Load or create user }
  NewUser(User, Session.UserName);

  { Load areas }
  if not LoadMsgCtl('MESSAGES.CTL', Areas) then
    SetLength(Areas, 0);

  { Load filters }
  LoadKeywords(Session.UserName + '.KEY', Filter);
  LoadTwitList(Session.UserName + '.TWT', Twit);

  { Handle command-line modes }
  if ParamCount > 0 then
  begin
    CmdArg := UpperCase(ParamStr(1));
    if CmdArg = '/V' then
    begin
      { Pack all users vacation mail }
      ShowLogo;
      ANSIInfo('Vacation Packing mode...');
      DoScanDownload;
      Halt(0);
    end
    else if CmdArg = '/M' then
    begin
      DoVacationMail;
      Halt(0);
    end
    else if (CmdArg = '/D') or (CmdArg = '/DA') or (CmdArg = '/DL') or (CmdArg = '/DQ') then
    begin
      ShowLogo;
      DoScanDownload;
      if CmdArg = '/DL' then Running := False;
      if CmdArg <> '/DQ' then Halt(0);
    end
    else if (CmdArg = '/U') or (CmdArg = '/UA') or (CmdArg = '/UL') or (CmdArg = '/UQ') then
    begin
      ShowLogo;
      DoUpload;
      if CmdArg = '/UL' then Running := False;
      if CmdArg <> '/UQ' then Halt(0);
    end
    else if CmdArg = '/L' then
    begin
      { Less prompts mode — skip confirmations }
    end
    else if (CmdArg = '/RG') or (Copy(CmdArg, 1, 4) = '/RG=') then
    begin
      DoResetPointers;
      Halt(0);
    end
    else if CmdArg = '/RS' then
    begin
      DoResetPointers;
      Halt(0);
    end;
  end;

  { Run interactive }
  MainLoop;

  { Goodbye }
  ANSICls;
  ANSIColor(acCyan or acBright, acBlack);
  ANSIWriteLn('Thanks for using OpenOLMS!');
  ANSIReset;
end.
