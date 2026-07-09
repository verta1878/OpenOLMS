{
  OpenOLMS - message filtering (twits/keywords/filters)
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
unit olms_filter;
{ ===========================================================================
  OpenOLMS — message filtering (Phase 6).

  Applied during the scan/gather step to decide, per message, whether it goes in
  the caller's packet. Cloned in behavior from OLMS.DOC (keywording, filters,
  twit lists):

    - Twit list : sender/recipient names to BLOCK outright (message skipped).
    - Filters   : include/exclude rules on From/To/Subject (substring, case-
                  insensitive). Exclude wins over include.
    - Keywords  : terms that mark a message "of interest". In keyword-only mode
                  the scan keeps ONLY keyword hits; otherwise keywords just flag.

  A per-user TFilterSet is consulted by ShouldInclude(msg). Kept independent of
  message-base format so it works for JAM, Hudson, anything.
  =========================================================================== }

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, Classes, olms_types;

type
  TFilterField = (ffFrom, ffTo, ffSubject, ffBody);

  TFilterRule = record
    Field   : TFilterField;
    Term    : string;      // substring to match (case-insensitive)
    Exclude : Boolean;     // True = exclude on match; False = include-only hint
  end;

  TFilterSet = class
  private
    FTwits    : TStringList;   // blocked names (From or To)
    FKeywords : TStringList;   // interest terms
    FRules    : array of TFilterRule;
    FKeywordOnly : Boolean;    // keep only keyword hits when True
    function FieldText(M: TOlmsMessage; F: TFilterField): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddTwit(const Name: string);
    procedure AddKeyword(const Word: string);
    procedure AddRule(Field: TFilterField; const Term: string; Exclude: Boolean);
    property  KeywordOnly: Boolean read FKeywordOnly write FKeywordOnly;
    function  IsTwit(M: TOlmsMessage): Boolean;
    function  MatchesKeyword(M: TOlmsMessage): Boolean;
    { The scan calls this per message. }
    function  ShouldInclude(M: TOlmsMessage): Boolean;
    procedure LoadFromFile(const FileName: string);   // simple text config
  end;

implementation

constructor TFilterSet.Create;
begin
  inherited Create;
  FTwits := TStringList.Create;    FTwits.CaseSensitive := False;
  FKeywords := TStringList.Create; FKeywords.CaseSensitive := False;
  FKeywordOnly := False;
end;

destructor TFilterSet.Destroy;
begin
  FTwits.Free; FKeywords.Free;
  inherited Destroy;
end;

procedure TFilterSet.AddTwit(const Name: string);
begin if Trim(Name) <> '' then FTwits.Add(Trim(Name)); end;

procedure TFilterSet.AddKeyword(const Word: string);
begin if Trim(Word) <> '' then FKeywords.Add(Trim(Word)); end;

procedure TFilterSet.AddRule(Field: TFilterField; const Term: string; Exclude: Boolean);
begin
  SetLength(FRules, Length(FRules)+1);
  FRules[High(FRules)].Field   := Field;
  FRules[High(FRules)].Term    := Term;
  FRules[High(FRules)].Exclude := Exclude;
end;

function TFilterSet.FieldText(M: TOlmsMessage; F: TFilterField): string;
begin
  case F of
    ffFrom   : Result := M.Sender;
    ffTo     : Result := M.Recipient;
    ffSubject: Result := M.Subject;
    ffBody   : Result := M.Body;
  else Result := '';
  end;
end;

function TFilterSet.IsTwit(M: TOlmsMessage): Boolean;
begin
  Result := (FTwits.IndexOf(Trim(M.Sender)) >= 0) or
            (FTwits.IndexOf(Trim(M.Recipient)) >= 0);
end;

function TFilterSet.MatchesKeyword(M: TOlmsMessage): Boolean;
var i: Integer; hay: string;
begin
  Result := False;
  hay := UpperCase(M.Subject + ' ' + M.Body);
  for i := 0 to FKeywords.Count-1 do
    if Pos(UpperCase(FKeywords[i]), hay) > 0 then Exit(True);
end;

function TFilterSet.ShouldInclude(M: TOlmsMessage): Boolean;
var i: Integer; hasInclude, includeHit: Boolean; hay: string;
begin
  // 1. twit list blocks outright
  if IsTwit(M) then Exit(False);

  // 2. exclude rules win immediately
  for i := 0 to High(FRules) do
    if FRules[i].Exclude then
    begin
      hay := UpperCase(FieldText(M, FRules[i].Field));
      if Pos(UpperCase(FRules[i].Term), hay) > 0 then Exit(False);
    end;

  // 3. include-only rules: if any exist, at least one must match
  hasInclude := False; includeHit := False;
  for i := 0 to High(FRules) do
    if not FRules[i].Exclude then
    begin
      hasInclude := True;
      hay := UpperCase(FieldText(M, FRules[i].Field));
      if Pos(UpperCase(FRules[i].Term), hay) > 0 then includeHit := True;
    end;
  if hasInclude and not includeHit then Exit(False);

  // 4. keyword-only mode keeps only keyword hits
  if FKeywordOnly and (FKeywords.Count > 0) then
    Exit(MatchesKeyword(M));

  Result := True;
end;

{ Simple text config:
    TWIT name
    KEYWORD term
    KEYWORDONLY on|off
    INCLUDE from|to|subject|body term
    EXCLUDE from|to|subject|body term }
procedure TFilterSet.LoadFromFile(const FileName: string);
var
  f: TextFile; line, kw, rest: string; p: Integer;
  function FieldOf(const s: string): TFilterField;
  begin
    if SameText(s,'from') then Result:=ffFrom
    else if SameText(s,'to') then Result:=ffTo
    else if SameText(s,'body') then Result:=ffBody
    else Result:=ffSubject;
  end;
  procedure SplitRule(const s: string; Exclude: Boolean);
  var sp: Integer; fld, term: string;
  begin
    sp := Pos(' ', s);
    if sp = 0 then Exit;
    fld := Copy(s,1,sp-1); term := Trim(Copy(s,sp+1,MaxInt));
    AddRule(FieldOf(fld), term, Exclude);
  end;
begin
  if not FileExists(FileName) then Exit;
  AssignFile(f, FileName); Reset(f);
  while not Eof(f) do
  begin
    Readln(f, line); line := Trim(line);
    if (line='') or (line[1]='#') then Continue;
    p := Pos(' ', line);
    if p = 0 then Continue;
    kw := UpperCase(Copy(line,1,p-1)); rest := Trim(Copy(line,p+1,MaxInt));
    if kw='TWIT' then AddTwit(rest)
    else if kw='KEYWORD' then AddKeyword(rest)
    else if kw='KEYWORDONLY' then FKeywordOnly := SameText(rest,'on')
    else if kw='INCLUDE' then SplitRule(rest, False)
    else if kw='EXCLUDE' then SplitRule(rest, True);
  end;
  CloseFile(f);
end;

end.
