{
  OpenOLMS - read pointers, taglines, limits
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
unit olms_pointers;
{ ===========================================================================
  OpenOLMS — message pointers, taglines, limits (Phase 11).

  Three pieces that make the scan correct and personalized:

  * Message pointers (POINTERS.DAT): per user, per area, the highest message
    number already sent. The scan gathers only messages ABOVE the pointer, then
    advances it. /RG resets all pointers (optionally back N); /RS resets
    selected areas. This is what stops the caller re-downloading old mail.

  * Taglines (TAGLINES): a pool of one-line signatures. A packet can carry a
    selection for the reader to pick from; the door can also append a random one
    to the packet's welcome text. "# of signatures to keep" caps it.

  * Limits: enforce max messages per packet, max packet KB, and per-area caps
    during the gather, matching the Limits Setup screen.

  Grounded in OLMS.DOC (Modify Pointers, Tagline Control, Limits Setup).
  =========================================================================== }

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, Classes, olms_types, olms_config;

type
  { Per-user read pointers, keyed "user|area" -> highest msg number seen. }
  TPointerStore = class
  private
    FList : TStringList;   // "user|area=highmsg"
    FFile : string;
    function KeyFor(const User: string; Area: Word): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const FileName: string);
    procedure Save;
    function  GetPointer(const User: string; Area: Word): LongInt;
    procedure SetPointer(const User: string; Area: Word; HighMsg: LongInt);
    procedure ResetAll(BackTo: LongInt);                 // /RG  (0 = to zero)
    procedure ResetArea(const User: string; Area: Word; BackTo: LongInt); // /RS
  end;

  { Tagline pool. }
  TTaglines = class
  private
    FLines : TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const FileName: string);
    function  Count: Integer;
    function  Random: string;
    function  Line(Idx: Integer): string;
  end;

  { Enforce limits while gathering; returns True if another message fits. }
  TLimitGuard = class
  private
    FMaxMsgs, FMsgs : Integer;
    FMaxBytes, FBytes : Int64;
  public
    constructor Create(const L: TLimits);
    function CanAdd(M: TOlmsMessage): Boolean;
    procedure Added(M: TOlmsMessage);
    property Count: Integer read FMsgs;
  end;

implementation

{ ---------- TPointerStore ---------- }
constructor TPointerStore.Create;
begin inherited Create; FList := TStringList.Create; FList.CaseSensitive := False; end;
destructor TPointerStore.Destroy; begin FList.Free; inherited Destroy; end;

function TPointerStore.KeyFor(const User: string; Area: Word): string;
begin Result := LowerCase(Trim(User)) + '|' + IntToStr(Area); end;

procedure TPointerStore.Load(const FileName: string);
begin
  FFile := FileName;
  FList.Clear;
  if FileExists(FileName) then FList.LoadFromFile(FileName);
end;

procedure TPointerStore.Save;
begin if FFile <> '' then FList.SaveToFile(FFile); end;

function TPointerStore.GetPointer(const User: string; Area: Word): LongInt;
var v: string;
begin
  v := FList.Values[KeyFor(User, Area)];
  Result := StrToIntDef(v, 0);
end;

procedure TPointerStore.SetPointer(const User: string; Area: Word; HighMsg: LongInt);
begin FList.Values[KeyFor(User, Area)] := IntToStr(HighMsg); end;

procedure TPointerStore.ResetAll(BackTo: LongInt);
var i: Integer; k: string; cur: LongInt;
begin
  for i := 0 to FList.Count-1 do
  begin
    k := FList.Names[i];
    if BackTo <= 0 then FList.Values[k] := '0'
    else begin
      cur := StrToIntDef(FList.ValueFromIndex[i], 0);
      if cur - BackTo < 0 then FList.Values[k] := '0'
      else FList.Values[k] := IntToStr(cur - BackTo);
    end;
  end;
end;

procedure TPointerStore.ResetArea(const User: string; Area: Word; BackTo: LongInt);
var cur: LongInt;
begin
  if BackTo <= 0 then SetPointer(User, Area, 0)
  else begin
    cur := GetPointer(User, Area);
    if cur - BackTo < 0 then SetPointer(User, Area, 0)
    else SetPointer(User, Area, cur - BackTo);
  end;
end;

{ ---------- TTaglines ---------- }
constructor TTaglines.Create; begin inherited Create; FLines := TStringList.Create; end;
destructor TTaglines.Destroy; begin FLines.Free; inherited Destroy; end;

procedure TTaglines.Load(const FileName: string);
begin FLines.Clear; if FileExists(FileName) then FLines.LoadFromFile(FileName); end;

function TTaglines.Count: Integer; begin Result := FLines.Count; end;
function TTaglines.Line(Idx: Integer): string;
begin if (Idx>=0) and (Idx<FLines.Count) then Result := FLines[Idx] else Result := ''; end;

function TTaglines.Random: string;
begin
  if FLines.Count = 0 then Exit('');
  Result := FLines[System.Random(FLines.Count)];
end;

{ ---------- TLimitGuard ---------- }
constructor TLimitGuard.Create(const L: TLimits);
begin
  inherited Create;
  FMaxMsgs := L.MaxMessages;
  FMaxBytes := Int64(L.MaxPacketKB) * 1024;
  FMsgs := 0; FBytes := 0;
end;

function TLimitGuard.CanAdd(M: TOlmsMessage): Boolean;
begin
  Result := True;
  if (FMaxMsgs > 0) and (FMsgs >= FMaxMsgs) then Exit(False);
  if (FMaxBytes > 0) and (FBytes + Length(M.Body) > FMaxBytes) then Exit(False);
end;

procedure TLimitGuard.Added(M: TOlmsMessage);
begin Inc(FMsgs); FBytes := FBytes + Length(M.Body); end;

end.
