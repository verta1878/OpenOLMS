{
  OpenOLMS - external archiver integration
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
unit olms_archiver;
{ ===========================================================================
  OpenOLMS — archiver integration (Phase 2).

  A QWK packet is a directory of files (CONTROL.DAT, MESSAGES.DAT, *.NDX) that
  gets compressed into <BBSID>.QWK for the caller to download; replies come back
  as <BBSID>.REP to be extracted. OLMS shells out to a configured external
  archiver (PKZIP/ARJ/LHA...) for this — we do the same, using the commands from
  TOlmsConfig.Archivers (Compress/Decompress), per OLMS.DOC "Archiver Programs".

  The command templates use the archiver's own syntax, e.g.:
     Compress   :  PKZIP.EXE -ex   %ARCHIVE% %FILES%
     Decompress :  PKUNZIP.EXE -o  %ARCHIVE%
  We substitute %ARCHIVE% and %FILES% (and %DIR%). On non-DOS hosts you can map
  the ZIP tag to Info-ZIP (zip/unzip) for testing; the mechanism is identical.
  =========================================================================== }

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, Classes,
  {$IFDEF GO32V2} Dos {$ELSE} Process {$ENDIF},
  olms_config;

type
  TArchiveResult = record
    Success  : Boolean;
    Command  : string;     // the command line actually run
    ExitCode : Integer;
    Output   : string;
  end;

{ Find a configured archiver by tag (e.g. 'ZIP'); returns index or -1. }
function FindArchiver(const Cfg: TOlmsConfig; const Tag: string): Integer;

{ Compress all files in PacketDir into ArchivePath using the archiver's
  Compress template. }
function CompressPacket(const Cfg: TOlmsConfig; const Tag, PacketDir,
                        ArchivePath: string): TArchiveResult;

{ Extract ArchivePath (a .REP reply) into DestDir using Decompress template. }
function ExtractReply(const Cfg: TOlmsConfig; const Tag, ArchivePath,
                      DestDir: string): TArchiveResult;

implementation

function FindArchiver(const Cfg: TOlmsConfig; const Tag: string): Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to High(Cfg.Archivers) do
    if SameText(Cfg.Archivers[i].Tag, Tag) then Exit(i);
end;

{ Split a command template into program + args, substituting placeholders.
  %FILES% expands to one argument per file in FilesList. }
procedure BuildArgs(const Template, Archive, Dir: string; FilesList: TStrings;
                    out Exe: string; Args: TStrings);
var
  toks: TStringList; i, k: Integer; t: string;
begin
  toks := TStringList.Create;
  try
    toks.Delimiter := ' '; toks.StrictDelimiter := True;
    toks.DelimitedText := Template;
    Exe := '';
    for i := 0 to toks.Count-1 do
    begin
      t := toks[i];
      if t = '' then Continue;
      if t = '%FILES%' then
      begin
        if FilesList <> nil then
          for k := 0 to FilesList.Count-1 do
            if Exe = '' then Exe := FilesList[k] else Args.Add(FilesList[k]);
        Continue;
      end;
      t := StringReplace(t, '%ARCHIVE%', Archive, [rfReplaceAll]);
      t := StringReplace(t, '%DIR%',     Dir,     [rfReplaceAll]);
      if Exe = '' then Exe := t else Args.Add(t);
    end;
  finally
    toks.Free;
  end;
end;

function RunTemplate(const Template, Archive, Dir: string; FilesList: TStrings): TArchiveResult;
var
  exe: string; args: TStringList; i: Integer;
{$IFDEF GO32V2}
  cmdline, savedir: string;
{$ELSE}
  proc: TProcess; outstream: TStringStream; buf: array[0..2047] of Byte; n: Integer;
{$ENDIF}
begin
  FillChar(Result, SizeOf(Result), 0);
  args := TStringList.Create;
  try
    BuildArgs(Template, Archive, Dir, FilesList, exe, args);
    Result.Command := exe + ' ' + args.DelimitedText;
    if (exe = '') or SameText(exe, 'OFF') then
    begin
      Result.Success := False; Result.Output := 'archiver disabled (OFF)'; Exit;
    end;

{$IFDEF GO32V2}
    // DOS: change into the working dir and Exec the archiver via COMSPEC.
    args.Delimiter := ' '; args.StrictDelimiter := True;
    cmdline := '/C ' + exe;
    for i := 0 to args.Count-1 do cmdline := cmdline + ' ' + args[i];
    savedir := GetCurrentDir;
    try
      if Dir <> '' then SetCurrentDir(Dir);
      SwapVectors;
      Exec(GetEnv('COMSPEC'), cmdline);
      SwapVectors;
      Result.ExitCode := DosExitCode;
      Result.Success := (DosError = 0) and (Result.ExitCode = 0);
      Result.Output := 'DosError=' + IntToStr(DosError);
    finally
      SetCurrentDir(savedir);
    end;
{$ELSE}
    proc := TProcess.Create(nil);
    outstream := TStringStream.Create('');
    try
      proc.Executable := exe;
      for i := 0 to args.Count-1 do proc.Parameters.Add(args[i]);
      if Dir <> '' then proc.CurrentDirectory := Dir;
      proc.Options := [poUsePipes, poStderrToOutPut];
      try
        proc.Execute;
        while proc.Running or (proc.Output.NumBytesAvailable > 0) do
        begin
          if proc.Output.NumBytesAvailable > 0 then
          begin
            n := proc.Output.Read(buf, SizeOf(buf));
            if n > 0 then outstream.Write(buf, n);
          end else Sleep(2);
        end;
        Result.ExitCode := proc.ExitStatus;
        Result.Output := outstream.DataString;
        Result.Success := Result.ExitCode = 0;
      except
        on E: Exception do
        begin Result.Success := False; Result.Output := 'exec failed: ' + E.Message; end;
      end;
    finally
      outstream.Free; proc.Free;
    end;
{$ENDIF}
  finally
    args.Free;
  end;
end;

function CompressPacket(const Cfg: TOlmsConfig; const Tag, PacketDir,
                        ArchivePath: string): TArchiveResult;
var
  ai: Integer; sr: TSearchRec; fl: TStringList;
begin
  ai := FindArchiver(Cfg, Tag);
  if ai < 0 then
  begin
    FillChar(Result, SizeOf(Result), 0);
    Result.Output := 'no archiver configured for tag ' + Tag; Exit;
  end;
  // gather the packet's files (names only; command runs in PacketDir)
  fl := TStringList.Create;
  try
    if FindFirst(IncludeTrailingPathDelimiter(PacketDir)+'*', faAnyFile, sr) = 0 then
    begin
      repeat
        if (sr.Attr and faDirectory) = 0 then fl.Add(sr.Name);
      until FindNext(sr) <> 0;
      FindClose(sr);
    end;
    Result := RunTemplate(Cfg.Archivers[ai].Compress, ArchivePath, PacketDir, fl);
  finally
    fl.Free;
  end;
  if not Result.Success then Result.Success := FileExists(ArchivePath);
end;

function ExtractReply(const Cfg: TOlmsConfig; const Tag, ArchivePath,
                      DestDir: string): TArchiveResult;
var ai: Integer;
begin
  ai := FindArchiver(Cfg, Tag);
  if ai < 0 then
  begin
    FillChar(Result, SizeOf(Result), 0);
    Result.Output := 'no archiver configured for tag ' + Tag; Exit;
  end;
  ForceDirectories(DestDir);
  Result := RunTemplate(Cfg.Archivers[ai].Decompress, ArchivePath, DestDir, nil);
end;

end.
