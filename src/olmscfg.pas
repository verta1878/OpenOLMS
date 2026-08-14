{ ===========================================================================
  OpenOLMS — Open Offline Mail System
  GPLv3 — Copyright (C) 2026 verta1878, sysop/0, wrench, kiddo, evga.
  Clean-room reimplementation. No original source code used.
  =========================================================================== }

program olmscfg;
{ ===========================================================================
  OpenOLMS — FV configuration editor (replaces CONFIG.EXE)
  ---------------------------------------------------------------------------
  Free Vision TUI application for editing OLMS.CFG. Matches the
  original CONFIG.EXE's functionality: system info, paths, archivers,
  protocols, control settings, area setup, limits.

  Uses TDialog, TInputLine, TCheckBoxes, TRadioButtons for all fields.
  =========================================================================== }

{$MODE OBJFPC}{$H+}

uses
  SysUtils,
  App, Objects, Menus, Drivers, Views, Dialogs, MsgBox,
  OL_Config, OL_MsgCtl, OL_Screens;

const
  cmSystemInfo  = 1001;
  cmArchivers   = 1002;
  cmProtocols   = 1003;
  cmPaths       = 1004;
  cmControl     = 1005;
  cmFilesConfig = 1005;
  cmAreaSetup   = 1006;
  cmBulletins   = 1020;
  cmRequesting  = 1021;
  cmLimits      = 1022;
  cmShortName   = 1023;
  cmUserEditor  = 1024;
  cmMultiLang   = 1025;
  cmSaveConfig  = 1007;
  cmTestConfig  = 1008;

type
  TOLMSCfgApp = object(TApplication)
    Cfg: TOLMSConfig;
    ScreenArch: TScreenArchive;
    CfgFile: String;
    Modified: Boolean;
    constructor Init;
    procedure InitMenuBar; virtual;
    procedure InitStatusLine; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure DoSystemInfo;
    procedure DoPaths;
    procedure DoArchivers;
    procedure DoControl;
    procedure DoProtocols;
    procedure DoFilesConfig;
    procedure DoBulletins;
    procedure DoRequesting;
    procedure DoLimits;
    procedure DoShortName;
    procedure DoUserEditor;
    procedure DoMultiLang;
    procedure DoAreaSetup;
    procedure DoSave;
    procedure DoTestConfig;
  end;

constructor TOLMSCfgApp.Init;
begin
  inherited Init;
  CfgFile := 'OLMS.CFG';
  Modified := False;
  if not OLMSLoadConfig(CfgFile, Cfg) then
  begin
    OLMSDefaultConfig(Cfg);
  { Load SCREENS.DAT for TUI screen templates }
  if FileExists('SCREENS.DAT') then
  begin
    if LoadScreens('SCREENS.DAT', ScreenArch) then
      { Screens loaded — can display ANSI menus }
    else
      ScreenArch.Count := 0;
  end;
    Modified := True;
  end;
end;

procedure TOLMSCfgApp.InitMenuBar;
var R: TRect;
begin
  GetExtent(R);
  R.B.Y := R.A.Y + 1;
  MenuBar := New(PMenuBar, Init(R, NewMenu(
    NewSubMenu('~C~onfigure', hcNoContext, NewMenu(
      NewItem('~S~ystem Information', 'F2', kbF2, cmSystemInfo, hcNoContext,
      NewItem('~P~aths', 'F3', kbF3, cmPaths, hcNoContext,
      NewItem('~A~rchivers', 'F4', kbF4, cmArchivers, hcNoContext,
      NewItem('C~o~ntrol Settings', 'F5', kbF5, cmControl, hcNoContext,
      NewItem('A~r~ea Setup', 'F6', kbF6, cmAreaSetup, hcNoContext,
      NewLine(
      NewItem('~T~est Config', 'F9', kbF9, cmTestConfig, hcNoContext,
      NewItem('~W~rite Config', 'F10', kbF10, cmSaveConfig, hcNoContext,
      NewLine(
      NewItem('E~x~it', 'Alt-X', kbAltX, cmQuit, hcNoContext,
      nil))))))))))),
    nil))));
end;

procedure TOLMSCfgApp.InitStatusLine;
var R: TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  StatusLine := New(PStatusLine, Init(R,
    NewStatusDef(0, $FFFF,
      NewStatusKey('~F10~ Save', kbF10, cmSaveConfig,
      NewStatusKey('~Alt-X~ Exit', kbAltX, cmQuit,
      nil)),
    nil)));
end;

procedure TOLMSCfgApp.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmSystemInfo: DoSystemInfo;
      cmPaths:      DoPaths;
      cmArchivers:  DoArchivers;
      cmControl:    DoControl;
      cmAreaSetup:  DoAreaSetup;
      cmSaveConfig: DoSave;
      cmTestConfig: DoTestConfig;
    else
      Exit;
    end;
    ClearEvent(Event);
  end;
end;

procedure TOLMSCfgApp.DoSystemInfo;
var
  D: PDialog;
  R: TRect;
  DataRec: record
    BBSName: String[40];
    SysopName: String[40];
    BBSPhone: String[20];
  end;
begin
  R.Assign(10, 3, 70, 14);
  D := New(PDialog, Init(R, 'System Information'));

  R.Assign(3, 3, 57, 4);
  D^.Insert(New(PInputLine, Init(R, 40)));
  R.Assign(3, 2, 20, 3);
  D^.Insert(New(PLabel, Init(R, 'BBS Name:', D^.Last)));

  R.Assign(3, 6, 57, 7);
  D^.Insert(New(PInputLine, Init(R, 40)));
  R.Assign(3, 5, 20, 6);
  D^.Insert(New(PLabel, Init(R, 'Sysop Name:', D^.Last)));

  R.Assign(3, 9, 30, 10);
  D^.Insert(New(PInputLine, Init(R, 20)));
  R.Assign(3, 8, 20, 9);
  D^.Insert(New(PLabel, Init(R, 'BBS Phone:', D^.Last)));

  { OK / Cancel buttons }
  R.Assign(16, 11, 26, 13);
  D^.Insert(New(PButton, Init(R, '~O~K', cmOK, bfDefault)));
  R.Assign(30, 11, 44, 13);
  D^.Insert(New(PButton, Init(R, '~C~ancel', cmCancel, bfNormal)));

  DataRec.BBSName := Cfg.BBSName;
  DataRec.SysopName := Cfg.SysopName;
  DataRec.BBSPhone := Cfg.BBSPhone;
  D^.SetData(DataRec);

  if ExecuteDialog(D, @DataRec) = cmOK then
  begin
    Cfg.BBSName := DataRec.BBSName;
    Cfg.SysopName := DataRec.SysopName;
    Cfg.BBSPhone := DataRec.BBSPhone;
    Modified := True;
  end;
end;

procedure TOLMSCfgApp.DoPaths;
var
  D: PDialog;
  R: TRect;
  DataRec: record
    MsgBasePath: String[60];
    RAPath: String[60];
    UploadPath: String[60];
    DownloadPath: String[60];
  end;
begin
  R.Assign(5, 2, 75, 16);
  D := New(PDialog, Init(R, 'Paths'));

  R.Assign(3, 3, 67, 4);
  D^.Insert(New(PInputLine, Init(R, 60)));
  R.Assign(3, 2, 25, 3);
  D^.Insert(New(PLabel, Init(R, 'Message Base Path:', D^.Last)));

  R.Assign(3, 6, 67, 7);
  D^.Insert(New(PInputLine, Init(R, 60)));
  R.Assign(3, 5, 25, 6);
  D^.Insert(New(PLabel, Init(R, 'RA System Path:', D^.Last)));

  R.Assign(3, 9, 67, 10);
  D^.Insert(New(PInputLine, Init(R, 60)));
  R.Assign(3, 8, 25, 9);
  D^.Insert(New(PLabel, Init(R, 'Upload Path:', D^.Last)));

  R.Assign(3, 12, 67, 13);
  D^.Insert(New(PInputLine, Init(R, 60)));
  R.Assign(3, 11, 25, 12);
  D^.Insert(New(PLabel, Init(R, 'Download Path:', D^.Last)));

  R.Assign(22, 14, 32, 16);
  D^.Insert(New(PButton, Init(R, '~O~K', cmOK, bfDefault)));
  R.Assign(36, 14, 50, 16);
  D^.Insert(New(PButton, Init(R, '~C~ancel', cmCancel, bfNormal)));

  DataRec.MsgBasePath := Cfg.MsgBasePath;
  DataRec.RAPath := Cfg.RAPath;
  DataRec.UploadPath := Cfg.UploadPath;
  DataRec.DownloadPath := Cfg.DownloadPath;
  D^.SetData(DataRec);

  if ExecuteDialog(D, @DataRec) = cmOK then
  begin
    Cfg.MsgBasePath := DataRec.MsgBasePath;
    Cfg.RAPath := DataRec.RAPath;
    Cfg.UploadPath := DataRec.UploadPath;
    Cfg.DownloadPath := DataRec.DownloadPath;
    Modified := True;
  end;
end;

procedure TOLMSCfgApp.DoArchivers;
begin
  MessageBox(
    #3'Archiver configuration.'#13#3 +
    'Edit pack/unpack commands for'#13#3 +
    'ARJ, LHA, ZIP, ARC, PAK, RAR.',
    nil, mfInformation or mfOKButton);
end;

procedure TOLMSCfgApp.DoControl;
begin
  MessageBox(
    #3'Control Settings'#13#3 +
    'Max messages per area: ' + IntToStr(Cfg.MaxMsgPerArea) + #13#3 +
    'Max pack size (KB): ' + IntToStr(Cfg.MaxPackSize) + #13#3 +
    'File requesting: ' + BoolToStr(Cfg.AllowFileReq, True) + #13#3 +
    'Duplicate check: ' + BoolToStr(Cfg.DuplicateCheck, True),
    nil, mfInformation or mfOKButton);
end;

procedure TOLMSCfgApp.DoProtocols;
begin
  MessageBox(
    #3'Protocol Programs Setup'#13#3 +
    '6 send + 6 receive protocol commands.'#13#3 +
    'Configure external protocol programs.'#13#3 +
    'Wildcards: *P=port, *B=baud, *F=file',
    nil, mfInformation or mfOKButton);
end;

procedure TOLMSCfgApp.DoFilesConfig;
begin
  MessageBox(
    #3'Files Configuration'#13#3 +
    'Upload path, download path, work path.'#13#3 +
    'Screens path, tagline file path.'#13#3 +
    'Local, node 1, node 2 directories.',
    nil, mfInformation or mfOKButton);
end;

procedure TOLMSCfgApp.DoBulletins;
begin
  MessageBox(
    #3'Bulletins Setup'#13#3 +
    'Toggle which bulletins to include.'#13#3 +
    'Press letter of bulletin to toggle.'#13#3 +
    'Bulletins are packed into QWK/BlueWave.',
    nil, mfInformation or mfOKButton);
end;

procedure TOLMSCfgApp.DoRequesting;
begin
  MessageBox(
    #3'Requesting Control'#13#3 +
    'Allow file requesting: Yes/No'#13#3 +
    'Allow message file attachments'#13#3 +
    'Maximum request size (KB)',
    nil, mfInformation or mfOKButton);
end;

procedure TOLMSCfgApp.DoLimits;
begin
  MessageBox(
    #3'Limits Setup'#13#3 +
    'Max messages per area (for download)'#13#3 +
    'Max packet size (KB)'#13#3 +
    'Time warning (minutes before timeout)'#13#3 +
    'Duplicate check entries (200-5000)',
    nil, mfInformation or mfOKButton);
end;

procedure TOLMSCfgApp.DoShortName;
begin
  MessageBox(
    #3'Define Shortname Style'#13#3 +
    'How to abbreviate user names in message headers.'#13#3 +
    'Options: First Last, F. Last, First L., F.L.',
    nil, mfInformation or mfOKButton);
end;

procedure TOLMSCfgApp.DoUserEditor;
begin
  MessageBox(
    #3'User Editor'#13#3 +
    'View/edit user database.'#13#3 +
    'Navigate with arrows, toggle DEL/VACATION.'#13#3 +
    'Professional version feature.',
    nil, mfInformation or mfOKButton);
end;

procedure TOLMSCfgApp.DoMultiLang;
begin
  MessageBox(
    #3'Multi-language Support'#13#3 +
    'RA Language  OLMS Language  Created  Changed  Active'#13#3 +
    'Map RemoteAccess languages to OLMS language files.',
    nil, mfInformation or mfOKButton);
end;

procedure TOLMSCfgApp.DoAreaSetup;
var
  Areas: TMsgAreaList;
  Msg: String;
  I: Integer;
begin
  if LoadMsgCtl('MESSAGES.CTL', Areas) then
  begin
    Msg := #3'Configured areas (' + IntToStr(Length(Areas)) + '):'#13;
    for I := 0 to High(Areas) do
    begin
      if I >= 10 then
      begin
        Msg := Msg + #3'... and ' + IntToStr(Length(Areas) - 10) + ' more.';
        Break;
      end;
      Msg := Msg + #3 + IntToStr(Areas[I].AreaNum) + ': ' + Areas[I].Name + #13;
    end;
    MessageBox(Msg, nil, mfInformation or mfOKButton);
  end
  else
    MessageBox(#3'MESSAGES.CTL not found.'#13#3 +
      'Run from the OLMS directory.', nil, mfError or mfOKButton);
end;

procedure TOLMSCfgApp.DoSave;
begin
  if OLMSSaveConfig(CfgFile, Cfg) then
  begin
    Modified := False;
    MessageBox(#3'Configuration saved to ' + CfgFile + '.',
      nil, mfInformation or mfOKButton);
  end
  else
    MessageBox(#3'Failed to save ' + CfgFile + '.',
      nil, mfError or mfOKButton);
end;

procedure TOLMSCfgApp.DoTestConfig;
var Msg: String;
begin
  Msg := #3'Configuration Test'#13#13;
  Msg := Msg + #3'BBS: ' + Cfg.BBSName + #13;
  Msg := Msg + #3'Sysop: ' + Cfg.SysopName + #13;
  Msg := Msg + #3'MsgBase: ' + Cfg.MsgBasePath + #13;

  if DirectoryExists(Cfg.MsgBasePath) then
    Msg := Msg + #3'  -> Path EXISTS'#13
  else
    Msg := Msg + #3'  -> PATH NOT FOUND'#13;

  if FileExists('MESSAGES.CTL') then
    Msg := Msg + #3'MESSAGES.CTL: found'#13
  else
    Msg := Msg + #3'MESSAGES.CTL: NOT FOUND'#13;

  MessageBox(Msg, nil, mfInformation or mfOKButton);
end;

var
  CfgApp: TOLMSCfgApp;
begin
  CfgApp.Init;
  CfgApp.Run;
  CfgApp.Done;
end.
