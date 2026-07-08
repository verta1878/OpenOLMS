{
  OpenOLMS - file request subsystem
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

  OpenOLMS is a clean-room reimplementation of the OLMS offline-mail door,
  written from published format specifications and documentation. It contains
  no code from the original OLMS.
}
unit olms_files;
{ ===========================================================================
  OpenOLMS — file subsystem (Phase 14).

  Lets a caller request files and scan for new ones alongside their mail, per
  OLMS.DOC (Requesting Control): request general files, request file attaches,
  scan for new files, optional auto-download of attaches. Honors the daily/size
  limits from the Requesting Control screen.

  Reads a simple file database (FILES.BBS-style: "NAME  SIZE  DATE  DESC" or a
  path scan) and produces a request list the packet build attaches. Kept format-
  light so it works against a directory scan or a files listing.
  =========================================================================== }

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, Classes;

type
  TFileEntry = record
    Name : string;
    Size : Int64;
    Date : TDateTime;
    Desc : string;
    Area : string;
  end;
  TFileList = array of TFileEntry;

  TRequestLimits = record
    MaxFilesPerDay : Integer;
    MaxKB          : Int64;
    AllowGeneral   : Boolean;
    AllowAttaches  : Boolean;
    AllowNewScan   : Boolean;
    AutoAttaches   : Boolean;
  end;

  TFileSubsystem = class
  private
    FCatalog : TFileList;
    FLimits  : TRequestLimits;
    FReqBytes : Int64;
    FReqCount : Integer;
  public
    constructor Create(const Limits: TRequestLimits);
    { Load a files listing: lines "NAME<TAB or spaces>SIZE<..>DATE<..>DESC". }
    procedure LoadCatalog(const FileName, Area: string);
    { Scan a directory into the catalog. }
    procedure ScanDir(const Dir, Area: string);
    function  Count: Integer;
    function  Entry(Idx: Integer): TFileEntry;
    { New files since a date (for the new-files scan). }
    function  NewSince(Since: TDateTime; out Hits: TFileList): Integer;
    { Try to add a file to the request; enforces limits. }
    function  Request(const Name: string): Boolean;
    function  FindByName(const Name: string; out E: TFileEntry): Boolean;
    property  RequestedCount: Integer read FReqCount;
    property  RequestedBytes: Int64 read FReqBytes;
  end;

implementation

constructor TFileSubsystem.Create(const Limits: TRequestLimits);
begin inherited Create; FLimits := Limits; FReqBytes := 0; FReqCount := 0; end;

procedure TFileSubsystem.LoadCatalog(const FileName, Area: string);
var
  f: TextFile; line: string; e: TFileEntry; p: Integer; parts: TStringList;
begin
  if not FileExists(FileName) then Exit;
  AssignFile(f, FileName); Reset(f);
  parts := TStringList.Create;
  try
    while not Eof(f) do
    begin
      Readln(f, line); line := Trim(line);
      if (line = '') or (line[1] = ';') then Continue;
      parts.Clear;
      parts.Delimiter := ' '; parts.StrictDelimiter := False;
      parts.DelimitedText := line;
      if parts.Count < 2 then Continue;
      FillChar(e, SizeOf(e), 0);
      e.Name := parts[0];
      e.Size := StrToInt64Def(parts[1], 0);
      e.Area := Area;
      e.Date := Now;
      p := Pos(e.Name, line); Delete(line, 1, p + Length(e.Name));
      e.Desc := Trim(line);
      SetLength(FCatalog, Length(FCatalog)+1);
      FCatalog[High(FCatalog)] := e;
    end;
  finally
    parts.Free; CloseFile(f);
  end;
end;

procedure TFileSubsystem.ScanDir(const Dir, Area: string);
var sr: TSearchRec; e: TFileEntry;
begin
  if FindFirst(IncludeTrailingPathDelimiter(Dir)+'*', faAnyFile, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
      begin
        FillChar(e, SizeOf(e), 0);
        e.Name := sr.Name; e.Size := sr.Size; e.Area := Area;
        e.Date := FileDateToDateTime(sr.Time);
        e.Desc := '';
        SetLength(FCatalog, Length(FCatalog)+1);
        FCatalog[High(FCatalog)] := e;
      end;
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
end;

function TFileSubsystem.Count: Integer; begin Result := Length(FCatalog); end;
function TFileSubsystem.Entry(Idx: Integer): TFileEntry; begin Result := FCatalog[Idx]; end;

function TFileSubsystem.NewSince(Since: TDateTime; out Hits: TFileList): Integer;
var i: Integer;
begin
  SetLength(Hits, 0);
  if not FLimits.AllowNewScan then Exit(0);
  for i := 0 to High(FCatalog) do
    if FCatalog[i].Date >= Since then
    begin
      SetLength(Hits, Length(Hits)+1);
      Hits[High(Hits)] := FCatalog[i];
    end;
  Result := Length(Hits);
end;

function TFileSubsystem.FindByName(const Name: string; out E: TFileEntry): Boolean;
var i: Integer;
begin
  Result := False;
  for i := 0 to High(FCatalog) do
    if SameText(FCatalog[i].Name, Name) then begin E := FCatalog[i]; Exit(True); end;
end;

function TFileSubsystem.Request(const Name: string): Boolean;
var e: TFileEntry;
begin
  Result := False;
  if not FLimits.AllowGeneral then Exit;
  if not FindByName(Name, e) then Exit;
  if (FLimits.MaxFilesPerDay > 0) and (FReqCount >= FLimits.MaxFilesPerDay) then Exit;
  if (FLimits.MaxKB > 0) and ((FReqBytes + e.Size) > FLimits.MaxKB*1024) then Exit;
  Inc(FReqCount); FReqBytes := FReqBytes + e.Size;
  Result := True;
end;

end.
