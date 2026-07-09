{
  OpenOLMS - keyboard backends
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
unit olms_kbd_console;
{ IKeyboard backends:
    TConsoleKeyboard - real keys via the CRT unit (for the actual program).
    TScriptKeyboard  - a queued key sequence (for headless testing of the
                       interactive editor / menu logic without a terminal).
  Same seam as the screen backends. }

{$MODE OBJFPC}{$H+}
{$INTERFACES CORBA}

interface

uses
  SysUtils, olms_input;

type
  TScriptKeyboard = class(TObject, IKeyboard)
  private
    FKeys : array of TKey;
    FPos  : Integer;
  public
    constructor Create;
    procedure PushChar(const S: string);
    procedure PushKey(Code: TKeyCode);
    function ReadKey: TKey;
    function KeyPressed: Boolean;
  end;

  { Console keyboard using CRT. Compiled but only meaningful with a real
    terminal; kept minimal. }
  TConsoleKeyboard = class(TObject, IKeyboard)
  public
    function ReadKey: TKey;
    function KeyPressed: Boolean;
  end;

implementation

uses
  Crt;

{ ---- scripted ---- }
constructor TScriptKeyboard.Create; begin inherited Create; FPos := 0; end;

procedure TScriptKeyboard.PushChar(const S: string);
var i, n: Integer; k: TKey;
begin
  for i := 1 to Length(S) do
  begin
    k.Code := kcChar; k.Ch := S[i];
    n := Length(FKeys); SetLength(FKeys, n+1); FKeys[n] := k;
  end;
end;

procedure TScriptKeyboard.PushKey(Code: TKeyCode);
var n: Integer; k: TKey;
begin
  k.Code := Code; k.Ch := #0;
  n := Length(FKeys); SetLength(FKeys, n+1); FKeys[n] := k;
end;

function TScriptKeyboard.ReadKey: TKey;
begin
  if FPos < Length(FKeys) then begin Result := FKeys[FPos]; Inc(FPos); end
  else begin Result.Code := kcEsc; Result.Ch := #0; end;  // run out -> Esc
end;

function TScriptKeyboard.KeyPressed: Boolean;
begin Result := FPos < Length(FKeys); end;

{ ---- console (CRT) ---- }
function TConsoleKeyboard.KeyPressed: Boolean;
begin Result := Crt.KeyPressed; end;

function TConsoleKeyboard.ReadKey: TKey;
var c: Char;
begin
  c := Crt.ReadKey;
  if c = #0 then
  begin
    c := Crt.ReadKey;   // extended key
    case c of
      #72: Result.Code := kcUp;
      #80: Result.Code := kcDown;
      #75: Result.Code := kcLeft;
      #77: Result.Code := kcRight;
      #73: Result.Code := kcPgUp;
      #81: Result.Code := kcPgDn;
      #83: Result.Code := kcDel;
      #71: Result.Code := kcHome;
      #79: Result.Code := kcEnd;
      #59: Result.Code := kcF1;
    else  Result.Code := kcUnknown;
    end;
    Result.Ch := #0;
  end
  else
    case c of
      #13: Result.Code := kcEnter;
      #27: Result.Code := kcEsc;
      #9:  Result.Code := kcTab;
      #8:  Result.Code := kcBksp;
    else begin Result.Code := kcChar; Result.Ch := c; end;
    end;
end;

end.
