{ ===========================================================================
  OL_Users — User database management
  GPLv3 — Copyright (C) 2026 FPC264IRC Contributors.
  Clean-room reimplementation. No original source code used.
  =========================================================================== }

unit OL_Users;

{$MODE OBJFPC}{$H+}
{$PACKRECORDS 1}

interface

uses
  SysUtils, OL_Compat;

type
  TSessionInfo = record
    UserName      : String;
    RealName      : String;
    SecurityLevel : Integer;
    TimeRemaining : Integer;
    ComPort       : Integer;
    BaudRate      : LongInt;
    NodeNumber    : Integer;
    ANSI          : Boolean;
    RIP           : Boolean;
  end;

procedure DefaultSession(var S: TSessionInfo);
procedure NewUser(var U: TOLMSUser; const Name: String);
function  LoadUser(const Filename: String; const Name: String;
  var U: TOLMSUser): Boolean;
procedure SaveUser(const Filename: String; const Name: String;
  const U: TOLMSUser);

{ Credit control }
function  UserGetCredits(const U: TOLMSUser): Integer;
function  UserHasCredits(const U: TOLMSUser; Cost: Integer): Boolean;
procedure UserDeductCredit(var U: TOLMSUser; Cost: Integer);
procedure UserAddCredits(var U: TOLMSUser; Amount: Integer);

implementation

procedure DefaultSession(var S: TSessionInfo);
begin
  FillChar(S, SizeOf(S), 0);
  S.UserName := 'LOCAL';
  S.RealName := 'Local User';
  S.SecurityLevel := 255;
  S.TimeRemaining := 60;
  S.ComPort := 0;
  S.ANSI := True;
end;

procedure NewUser(var U: TOLMSUser; const Name: String);
begin
  FillChar(U, SizeOf(U), 0);
  U.Status := 1;
  WriteTPStr(U.UserName, 30, Name);
  WriteTPStr(U.LastDate, 8, FormatDateTime('mm-dd-yy', Now));
  WriteTPStr(U.LastTime, 8, FormatDateTime('hh:nn', Now));
end;

function LoadUser(const Filename: String; const Name: String;
  var U: TOLMSUser): Boolean;
var
  F: File;
  Rec: TOLMSUser;
  BytesRead: Integer;
begin
  Result := False;
  if not FileExists(Filename) then Exit;
  AssignFile(F, Filename);
  {$I-} Reset(F, 1); {$I+}
  if IOResult <> 0 then Exit;

  while not Eof(F) do
  begin
    {$I-} BlockRead(F, Rec, SizeOf(TOLMSUser), BytesRead); {$I+}
    if BytesRead <> SizeOf(TOLMSUser) then Break;
    if SameText(ReadTPStr(Rec.UserName, 30), Name) then
    begin
      U := Rec;
      Result := True;
      Break;
    end;
  end;
  CloseFile(F);
end;

procedure SaveUser(const Filename: String; const Name: String;
  const U: TOLMSUser);
var
  F: File;
  Rec: TOLMSUser;
  BytesRead: Integer;
  Pos: LongInt;
begin
  if not FileExists(Filename) then Exit;
  AssignFile(F, Filename);
  {$I-} Reset(F, 1); {$I+}
  if IOResult <> 0 then Exit;

  Pos := 0;
  while not Eof(F) do
  begin
    {$I-} BlockRead(F, Rec, SizeOf(TOLMSUser), BytesRead); {$I+}
    if BytesRead <> SizeOf(TOLMSUser) then Break;
    if SameText(ReadTPStr(Rec.UserName, 30), Name) then
    begin
      Seek(F, Pos);
      BlockWrite(F, U, SizeOf(TOLMSUser));
      Break;
    end;
    Inc(Pos, SizeOf(TOLMSUser));
  end;
  CloseFile(F);
end;

{ ---- Credit Control ---- }

function UserGetCredits(const U: TOLMSUser): Integer;
begin
  { Credits stored in Tail[0..1] as Word }
  Result := U.Tail[0] or (U.Tail[1] shl 8);
end;

function UserHasCredits(const U: TOLMSUser; Cost: Integer): Boolean;
begin
  if Cost <= 0 then Result := True
  else Result := UserGetCredits(U) >= Cost;
end;

procedure UserDeductCredit(var U: TOLMSUser; Cost: Integer);
var C: Integer;
begin
  C := UserGetCredits(U) - Cost;
  if C < 0 then C := 0;
  U.Tail[0] := C and $FF;
  U.Tail[1] := (C shr 8) and $FF;
end;

procedure UserAddCredits(var U: TOLMSUser; Amount: Integer);
var C: Integer;
begin
  C := UserGetCredits(U) + Amount;
  if C > 65535 then C := 65535;
  U.Tail[0] := C and $FF;
  U.Tail[1] := (C shr 8) and $FF;
end;

end.
