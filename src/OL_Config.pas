{ ===========================================================================
  OpenOLMS — OL_Config.pas
  Configuration types and I/O for OLMS.CFG.
  GPLv3 — Copyright (C) 2026 verta1878, wrench

  v1.0: Now backed by OL_Compat packed records for binary compatibility.
  The TOLMSConfig record uses dynamic strings for easy field access.
  Load/Save convert between dynamic strings and the packed binary format.
  =========================================================================== }

{$MODE OBJFPC}{$H+}

unit OL_Config;

interface

uses OL_Compat;

const
  OLMS_MAX_ARCHIVERS = 6;
  OLMS_MAX_PROTOCOLS = 9;

type
  TOLMSArchiver = record
    PackCmd   : String;
    UnpackCmd : String;
  end;

  TOLMSProtocol = record
    Name    : String;
    SendCmd : String;
    RecvCmd : String;
  end;

  TOLMSConfig = record
    { System Information }
    BBSName      : String;
    SysopName    : String;
    MsgBasePath  : String;
    RAPath       : String;
    FileBasePath : String;
    NodelistPath : String;

    { Display files }
    WelcomeFile  : String;
    LogoFile     : String;
    GoodbyeFile  : String;

    { Operational paths }
    LogFile      : String;
    UploadPath   : String;
    DownloadPath : String;
    TaglinePath  : String;

    { Registration }
    RegCode      : String;
    RegName      : String;

    { Archivers }
    Archivers    : array[0..OLMS_MAX_ARCHIVERS - 1] of TOLMSArchiver;

    { Protocols }
    Protocols    : array[0..OLMS_MAX_PROTOCOLS - 1] of TOLMSProtocol;

    { Control settings }
    AllowFileReq   : Boolean;
    AllowAttach    : Boolean;
    AutoLogoff     : Boolean;
    IncludeNewFiles: Boolean;
    DuplicateCheck : Boolean;
    MaxMsgPerArea  : Word;
    MaxPackSize    : Word;
    TimeWarning    : Word;
    MsgBaseFormat  : Byte;

    { Phone number }
    BBSPhone       : String;

    { Default language }
    DefLanguage    : String;

    { Raw binary buffer — preserves unknown fields for round-trip }
    RawData        : TOLMSConfigRaw;
    RawLoaded      : Boolean;
  end;

{ Load configuration from OLMS.CFG file — binary compatible }
function OLMSLoadConfig(const Filename: String; var Cfg: TOLMSConfig): Boolean;

{ Save configuration to OLMS.CFG file — binary compatible }
function OLMSSaveConfig(const Filename: String; var Cfg: TOLMSConfig): Boolean;

{ Initialize a config with sane defaults }
procedure OLMSDefaultConfig(var Cfg: TOLMSConfig);

implementation

uses SysUtils;

procedure RawToConfig(var Raw: TOLMSConfigRaw; var Cfg: TOLMSConfig);
{ Convert packed binary buffer to dynamic-string record }
var I: Integer;
begin
  Cfg.BBSName      := CfgGetBBSName(Raw);
  Cfg.SysopName    := CfgGetSysopName(Raw);
  Cfg.MsgBasePath  := CfgGetPath(Raw, 0);
  Cfg.RAPath       := CfgGetPath(Raw, 1);
  Cfg.FileBasePath := CfgGetPath(Raw, 2);
  Cfg.NodelistPath := CfgGetPath(Raw, 3);
  Cfg.WelcomeFile  := CfgGetPath(Raw, 4);
  Cfg.LogoFile     := CfgGetPath(Raw, 5);
  Cfg.GoodbyeFile  := CfgGetPath(Raw, 6);
  Cfg.LogFile      := CfgGetPath(Raw, 7);
  Cfg.UploadPath   := CfgGetPath(Raw, 8);
  Cfg.DownloadPath := CfgGetPath(Raw, 9);
  Cfg.TaglinePath  := CfgGetPath(Raw, 10);
  Cfg.RegCode      := CfgGetRegCode(Raw);
  Cfg.RegName      := CfgGetRegName(Raw);
  Cfg.DefLanguage  := CfgGetDefLanguage(Raw);
  Cfg.BBSPhone     := CfgGetBBSPhone(Raw);

  for I := 0 to OLMS_MAX_ARCHIVERS - 1 do
  begin
    Cfg.Archivers[I].PackCmd   := CfgGetArchiverPack(Raw, I);
    Cfg.Archivers[I].UnpackCmd := CfgGetArchiverUnpack(Raw, I);
  end;

  for I := 0 to OLMS_MAX_PROTOCOLS - 1 do
  begin
    Cfg.Protocols[I].SendCmd := CfgGetProtocolSend(Raw, I);
    Cfg.Protocols[I].RecvCmd := CfgGetProtocolRecv(Raw, I);
  end;

  for I := 0 to 9 do
    if I < OLMS_MAX_PROTOCOLS then
      Cfg.Protocols[I].Name := CfgGetProtocolName(Raw, I);
end;

procedure ConfigToRaw(var Cfg: TOLMSConfig; var Raw: TOLMSConfigRaw);
{ Convert dynamic-string record back to packed binary buffer.
  Starts from existing RawData to preserve unknown fields. }
var I: Integer;
begin
  CfgSetBBSName(Raw, Cfg.BBSName);
  CfgSetSysopName(Raw, Cfg.SysopName);
  CfgSetPath(Raw, 0, Cfg.MsgBasePath);
  CfgSetPath(Raw, 1, Cfg.RAPath);
  CfgSetPath(Raw, 2, Cfg.FileBasePath);
  CfgSetPath(Raw, 3, Cfg.NodelistPath);
  CfgSetPath(Raw, 4, Cfg.WelcomeFile);
  CfgSetPath(Raw, 5, Cfg.LogoFile);
  CfgSetPath(Raw, 6, Cfg.GoodbyeFile);
  CfgSetPath(Raw, 7, Cfg.LogFile);
  CfgSetPath(Raw, 8, Cfg.UploadPath);
  CfgSetPath(Raw, 9, Cfg.DownloadPath);
  CfgSetPath(Raw, 10, Cfg.TaglinePath);
  { Version stays in raw buffer — not in dynamic fields }
end;

procedure OLMSDefaultConfig(var Cfg: TOLMSConfig);
begin
  FillChar(Cfg, SizeOf(Cfg), 0);
  Cfg.BBSName       := 'My BBS';
  Cfg.SysopName     := 'Sysop';
  Cfg.MsgBasePath   := 'C:\MSGBASE\';
  Cfg.RAPath        := 'C:\RA\';
  Cfg.FileBasePath  := 'C:\RA\FDB\';
  Cfg.UploadPath    := 'C:\RA\OLMS\UPLOAD\';
  Cfg.DownloadPath  := 'C:\RA\OLMS\DOWN\';
  Cfg.LogFile       := 'C:\RA\OLMS.LOG';
  Cfg.TaglinePath   := 'C:\RA\OLMS.TAG';
  Cfg.BBSPhone      := '(XXX)YYY-ZZZZ';
  Cfg.DefLanguage   := 'DEFAULT';
  Cfg.MaxMsgPerArea := 300;
  Cfg.MaxPackSize   := 1024;
  Cfg.TimeWarning   := 5;
  Cfg.MsgBaseFormat := 0;
  Cfg.AllowFileReq  := True;
  Cfg.DuplicateCheck:= True;

  Cfg.Archivers[0].PackCmd := 'ARJ.EXE a';       Cfg.Archivers[0].UnpackCmd := 'ARJ.EXE e';
  Cfg.Archivers[1].PackCmd := 'LHA.EXE a /m';     Cfg.Archivers[1].UnpackCmd := 'LHA.EXE e /m';
  Cfg.Archivers[2].PackCmd := 'PKZIP.EXE -ex';    Cfg.Archivers[2].UnpackCmd := 'PKUNZIP.EXE -o';
  Cfg.Archivers[3].PackCmd := 'PKARC.COM A';      Cfg.Archivers[3].UnpackCmd := 'PKXARC.COM -ER';
  Cfg.Archivers[4].PackCmd := 'PAK.EXE A /I';     Cfg.Archivers[4].UnpackCmd := 'PAK.EXE E /I /WA';
  Cfg.Archivers[5].PackCmd := 'RAR.EXE a';        Cfg.Archivers[5].UnpackCmd := 'RAR.EXE e -o+';

  Cfg.Protocols[0].Name := 'Xmodem';
  Cfg.Protocols[1].Name := 'Ymodem';
  Cfg.Protocols[2].Name := 'Zmodem';

  { Initialize raw buffer with defaults }
  FillChar(Cfg.RawData, SizeOf(Cfg.RawData), 0);
  Cfg.RawData.Data[0] := OLMS_VERSION and $FF;
  Cfg.RawData.Data[1] := (OLMS_VERSION shr 8) and $FF;
  ConfigToRaw(Cfg, Cfg.RawData);
  Cfg.RawLoaded := False;
end;

function OLMSLoadConfig(const Filename: String; var Cfg: TOLMSConfig): Boolean;
var F: File;
begin
  Result := False;
  if not FileExists(Filename) then Exit;

  { Load the raw binary buffer }
  AssignFile(F, Filename);
  Reset(F, 1);
  FillChar(Cfg.RawData, SizeOf(Cfg.RawData), 0);
  BlockRead(F, Cfg.RawData, OLMS_CFG_SIZE);
  CloseFile(F);
  Cfg.RawLoaded := True;

  { Convert to dynamic strings for easy access }
  RawToConfig(Cfg.RawData, Cfg);
  Result := True;
end;

function OLMSSaveConfig(const Filename: String; var Cfg: TOLMSConfig): Boolean;
var F: File;
begin
  Result := False;

  { If we loaded from a file, start from that raw buffer
    to preserve unknown fields. Otherwise start from defaults. }
  if not Cfg.RawLoaded then
  begin
    FillChar(Cfg.RawData, SizeOf(Cfg.RawData), 0);
    Cfg.RawData.Data[0] := OLMS_VERSION and $FF;
    Cfg.RawData.Data[1] := (OLMS_VERSION shr 8) and $FF;
  end;

  { Write dynamic fields back to raw buffer }
  ConfigToRaw(Cfg, Cfg.RawData);

  { Save }
  AssignFile(F, Filename);
  Rewrite(F, 1);
  BlockWrite(F, Cfg.RawData, OLMS_CFG_SIZE);
  CloseFile(F);
  Result := True;
end;

end.
