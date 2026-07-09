{
  OpenOLMS - configuration model
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
unit olms_config;
{ ===========================================================================
  OpenOLMS — configuration model (the shared seam).

  config.exe WRITES this; olms.exe READS it. Mirrors the role of the original
  OLMS.CFG. Field set is grounded in the OLMS manual's configuration sections
  (System Information, Archiver Programs, Limits, etc.) — modelled from the
  documented behavior, as our own original structures.
  =========================================================================== }

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, Classes;

const
  OLMS_CFG_MAGIC   = 'OPENOLMS-CFG';
  OLMS_CFG_VERSION = 1;
  MAX_ARCHIVERS    = 8;
  MAX_PROTOCOLS    = 8;
  MAX_AREAS        = 200;   // message areas (conferences) the door serves

type
  TAreaKind = (akJAM, akHudson);

  { A message area (conference) the door offers. }
  TMsgArea = record
    Number : Word;        // conference number in the packet
    Name   : string[40];  // display name
    Kind   : TAreaKind;   // JAM or Hudson
    Path   : string[80];  // JAM: base path w/o ext; Hudson: dir + board index
    Board  : Byte;        // Hudson board number (ignored for JAM)
    Active : Boolean;
  end;
  { System Information screen (manual p.3). }
  TSysInfo = record
    SystemName : string[60];    // from CONFIG.RA
    SysopName  : string[36];    // exact case matters for original; kept for parity
    BoardID    : string[8];     // 1-8 chars, unique
    Phone      : string[20];
    Gateway    : string[40];    // UUCP/GATEWAY/INTERNET re-address target ('' = off)
    // NOTE: original has Serial/Registration fields here. OpenOLMS is
    // unregistered-free by design, so these are left out intentionally.
  end;

  { Archiver Programs screen (manual p.4). One row per archive type. }
  TArchiver = record
    Tag        : string[8];     // e.g. ZIP, ARJ, LHA
    Compress   : string[60];    // e.g. PKZIP.EXE -ex   ('OFF' disables)
    Decompress : string[60];    // e.g. PKUNZIP.EXE -o
    Swap       : Boolean;       // swap out of memory while shelling
  end;

  { Protocol Programs screen (manual p.5). }
  TProtocol = record
    Name       : string[20];
    UpCmd      : string[60];
    DownCmd    : string[60];
  end;

  { Limits Setup screen (manual p.13). }
  TLimits = record
    MaxMessages   : LongInt;    // per packet
    MaxPacketKB   : LongInt;    // size cap
    MaxConfs      : Word;       // conferences a user may join
    MaxTaglines   : Byte;       // 0..10 (registered) — OpenOLMS: no cap
  end;

  { The whole config. }
  TOlmsConfig = class
    Sys       : TSysInfo;
    Archivers : array[0..MAX_ARCHIVERS-1] of TArchiver;
    Protocols : array[0..MAX_PROTOCOLS-1] of TProtocol;
    Limits    : TLimits;
    Areas     : array[0..MAX_AREAS-1] of TMsgArea;
    AreaCount : Integer;
    procedure SetDefaults;
    function  Load(const FileName: string): Boolean;
    function  Save(const FileName: string): Boolean;
  end;

implementation

function IfThenAK(cond: Boolean; const a, b: string): string;
begin if cond then Result := a else Result := b; end;

procedure TOlmsConfig.SetDefaults;
var i: Integer;
begin
  FillChar(Sys, SizeOf(Sys), 0);
  Sys.SystemName := 'My BBS';
  Sys.SysopName  := 'Sysop';
  Sys.BoardID    := 'MYBBS';
  Sys.Phone      := '';
  Sys.Gateway    := '';
  for i := 0 to MAX_ARCHIVERS-1 do
  begin
    FillChar(Archivers[i], SizeOf(TArchiver), 0);
    Archivers[i].Compress := 'OFF';
  end;
  // one sensible default archiver
  Archivers[0].Tag := 'ZIP';
  Archivers[0].Compress := 'PKZIP.EXE -ex';
  Archivers[0].Decompress := 'PKUNZIP.EXE -o';
  Archivers[0].Swap := True;
  for i := 0 to MAX_PROTOCOLS-1 do FillChar(Protocols[i], SizeOf(TProtocol), 0);
  Limits.MaxMessages := 1000;
  Limits.MaxPacketKB := 500;
  Limits.MaxConfs    := 2000;   // manual: 2000 confs in shareware version
  Limits.MaxTaglines := 10;
  // default message areas: one JAM area named General
  for i := 0 to MAX_AREAS-1 do FillChar(Areas[i], SizeOf(TMsgArea), 0);
  AreaCount := 1;
  Areas[0].Number := 1; Areas[0].Name := 'General';
  Areas[0].Kind := akJAM; Areas[0].Path := 'GENERAL'; Areas[0].Active := True;
end;

{ Simple, readable key=value store (easy to diff/hand-edit; both exes parse it). }
function TOlmsConfig.Save(const FileName: string): Boolean;
var f: TextFile; i: Integer;
begin
  Result := False;
  AssignFile(f, FileName);
  {$I-} Rewrite(f); {$I+}
  if IOResult <> 0 then Exit;
  Writeln(f, OLMS_CFG_MAGIC, ' ', OLMS_CFG_VERSION);
  Writeln(f, 'SystemName=', Sys.SystemName);
  Writeln(f, 'SysopName=', Sys.SysopName);
  Writeln(f, 'BoardID=', Sys.BoardID);
  Writeln(f, 'Phone=', Sys.Phone);
  Writeln(f, 'Gateway=', Sys.Gateway);
  for i := 0 to MAX_ARCHIVERS-1 do
    if Archivers[i].Tag <> '' then
    begin
      Writeln(f, 'Archiver=', Archivers[i].Tag, '|', Archivers[i].Compress, '|',
                 Archivers[i].Decompress, '|', Ord(Archivers[i].Swap));
    end;
  Writeln(f, 'MaxMessages=', Limits.MaxMessages);
  Writeln(f, 'MaxPacketKB=', Limits.MaxPacketKB);
  Writeln(f, 'MaxConfs=', Limits.MaxConfs);
  // message areas:  Area=num|name|kind(J/H)|path|board|active
  for i := 0 to AreaCount-1 do
    if Areas[i].Name <> '' then
      Writeln(f, 'Area=', Areas[i].Number, '|', Areas[i].Name, '|',
                 IfThenAK(Areas[i].Kind = akJAM, 'J', 'H'), '|',
                 Areas[i].Path, '|', Areas[i].Board, '|', Ord(Areas[i].Active));
  CloseFile(f);
  Result := True;
end;

function TOlmsConfig.Load(const FileName: string): Boolean;
var
  f: TextFile; line, key, val: string; p, ai: Integer;
  parts: TStringList;
  areasSeen: Boolean;
begin
  Result := False;
  SetDefaults;
  if not FileExists(FileName) then Exit;
  AssignFile(f, FileName);
  {$I-} Reset(f); {$I+}
  if IOResult <> 0 then Exit;
  ai := 0; areasSeen := False;
  while not Eof(f) do
  begin
    Readln(f, line);
    p := Pos('=', line);
    if p = 0 then Continue;
    key := Copy(line, 1, p-1);
    val := Copy(line, p+1, MaxInt);
    if key = 'SystemName' then Sys.SystemName := val
    else if key = 'SysopName' then Sys.SysopName := val
    else if key = 'BoardID'   then Sys.BoardID := val
    else if key = 'Phone'     then Sys.Phone := val
    else if key = 'Gateway'   then Sys.Gateway := val
    else if key = 'MaxMessages' then Limits.MaxMessages := StrToIntDef(val, 1000)
    else if key = 'MaxPacketKB' then Limits.MaxPacketKB := StrToIntDef(val, 500)
    else if key = 'MaxConfs'    then Limits.MaxConfs := StrToIntDef(val, 2000)
    else if (key = 'Archiver') and (ai < MAX_ARCHIVERS) then
    begin
      parts := TStringList.Create;
      try
        parts.Delimiter := '|'; parts.StrictDelimiter := True;
        parts.DelimitedText := val;
        if parts.Count >= 4 then
        begin
          Archivers[ai].Tag := parts[0];
          Archivers[ai].Compress := parts[1];
          Archivers[ai].Decompress := parts[2];
          Archivers[ai].Swap := parts[3] = '1';
          Inc(ai);
        end;
      finally parts.Free; end;
    end
    else if key = 'Area' then
    begin
      if not areasSeen then begin AreaCount := 0; areasSeen := True; end;
      if AreaCount < MAX_AREAS then
      begin
        parts := TStringList.Create;
        try
          parts.Delimiter := '|'; parts.StrictDelimiter := True;
          parts.DelimitedText := val;
          if parts.Count >= 4 then
          begin
            FillChar(Areas[AreaCount], SizeOf(TMsgArea), 0);
            Areas[AreaCount].Number := StrToIntDef(parts[0], 0);
            Areas[AreaCount].Name   := parts[1];
            if (parts[2] = 'H') or (parts[2] = 'h') then Areas[AreaCount].Kind := akHudson
                                                    else Areas[AreaCount].Kind := akJAM;
            Areas[AreaCount].Path := parts[3];
            if parts.Count >= 5 then Areas[AreaCount].Board  := StrToIntDef(parts[4], 0);
            if parts.Count >= 6 then Areas[AreaCount].Active := parts[5] = '1'
                                else Areas[AreaCount].Active := True;
            Inc(AreaCount);
          end;
        finally parts.Free; end;
      end;
    end;
  end;
  CloseFile(f);
  Result := True;
end;

end.
