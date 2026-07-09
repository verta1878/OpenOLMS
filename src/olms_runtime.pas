{
  OpenOLMS - multi-language, logging, vacation
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
unit olms_runtime;
{ ===========================================================================
  OpenOLMS — multi-language, logging, vacation (Phase 16).

  The runtime/maintenance pieces that finish the feature set, per OLMS.DOC
  (Multi-language Support, Log mode, Vacation mail):

  * Multi-language: prompts/screens come from a language file (.OLF) keyed by
    token, so the door speaks the caller's language. TLangFile loads "KEY=text".
  * Logging: TOlmsLog appends timestamped activity lines to OLMS.LOG, honoring a
    log mode (off / normal / verbose).
  * Vacation: TVacation marks a user away with an auto-reply, and /V packs all
    pending mail regardless of pointers (the vacation catch-up).
  =========================================================================== }

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, Classes;

type
  TLogMode = (lmOff, lmNormal, lmVerbose);

  TLangFile = class
  private
    FStr : TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const FileName: string);
    { Look up a token; returns Default if absent (so English fallback works). }
    function Text(const Key, Default: string): string;
  end;

  TOlmsLog = class
  private
    FFile : string;
    FMode : TLogMode;
  public
    constructor Create(const FileName: string; Mode: TLogMode);
    procedure Log(const S: string);
    procedure Verbose(const S: string);
  end;

  TVacation = record
    Active    : Boolean;
    Message   : string;    // auto-reply text
    Until_     : TDateTime;
  end;

{ /V vacation pack: returns True if pointers should be ignored (grab everything). }
function VacationPackAll(const V: TVacation): Boolean;

implementation

{ ---- TLangFile ---- }
constructor TLangFile.Create;
begin inherited Create; FStr := TStringList.Create; FStr.CaseSensitive := False; end;
destructor TLangFile.Destroy; begin FStr.Free; inherited Destroy; end;

procedure TLangFile.Load(const FileName: string);
begin FStr.Clear; if FileExists(FileName) then FStr.LoadFromFile(FileName); end;

function TLangFile.Text(const Key, Default: string): string;
var v: string;
begin
  v := FStr.Values[Key];
  if v = '' then Result := Default else Result := v;
end;

{ ---- TOlmsLog ---- }
constructor TOlmsLog.Create(const FileName: string; Mode: TLogMode);
begin inherited Create; FFile := FileName; FMode := Mode; end;

procedure TOlmsLog.Log(const S: string);
var f: TextFile;
begin
  if FMode = lmOff then Exit;
  AssignFile(f, FFile);
  {$I-}
  if FileExists(FFile) then Append(f) else Rewrite(f);
  {$I+}
  if IOResult <> 0 then Exit;
  Writeln(f, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), '  ', S);
  CloseFile(f);
end;

procedure TOlmsLog.Verbose(const S: string);
begin if FMode = lmVerbose then Log('[v] ' + S); end;

{ ---- vacation ---- }
function VacationPackAll(const V: TVacation): Boolean;
begin
  Result := V.Active and (Now <= V.Until_);
end;

end.
