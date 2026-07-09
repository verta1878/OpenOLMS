{
  OpenOLMS - interactive input framework
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
unit olms_input;
{ ===========================================================================
  OpenOLMS — interactive input (Phase 12).

  Turns the render-only UI into live screens. Like IScreen, input goes through
  an abstraction (IKeyboard) so it stays display-agnostic: a console keyboard
  now (CRT), an SDL keyboard later — the interactive logic never changes.

  Provides:
    - IKeyboard: ReadKey returning a normalized TKey
    - EditField : in-place line editor in a field slot (returns edited text)
    - MenuLoop  : hotkey menu dispatch over a screen's rendered options
  =========================================================================== }

{$MODE OBJFPC}{$H+}
{$INTERFACES CORBA}

interface

uses
  SysUtils, olms_ui;

type
  TKeyCode = (kcChar, kcEnter, kcEsc, kcTab, kcBksp, kcUp, kcDown, kcLeft,
              kcRight, kcPgUp, kcPgDn, kcDel, kcHome, kcEnd, kcF1, kcUnknown);

  TKey = record
    Code : TKeyCode;
    Ch   : Char;      // valid when Code = kcChar
  end;

  IKeyboard = interface
    ['{05C33EE0-0003-4000-9000-000000000003}']
    function ReadKey: TKey;
    function KeyPressed: Boolean;
  end;

{ Edit a single text field in place at (X,Y), width W, starting from Value.
  Returns the final string. Terminates on Enter/Tab/Esc/Up/Down (out-key
  returned via OutKey so the caller can navigate between fields). }
function EditField(Scr: IScreen; Kbd: IKeyboard; X, Y, W: Integer;
                   const Value: string; Fg, Bg: Byte; out OutKey: TKey): string;

type
  TMenuItem = record
    HotKey : Char;      // uppercased selector
    Id     : Integer;   // returned when chosen
  end;

{ Wait for a hotkey matching one of Items; returns its Id, or -1 on Esc. }
function MenuLoop(Kbd: IKeyboard; const Items: array of TMenuItem): Integer;

implementation

function EditField(Scr: IScreen; Kbd: IKeyboard; X, Y, W: Integer;
                   const Value: string; Fg, Bg: Byte; out OutKey: TKey): string;
var
  s: string; caret: Integer; k: TKey; i: Integer;

  procedure Paint;
  var i: Integer; ch: Char;
  begin
    for i := 0 to W-1 do
    begin
      if i < Length(s) then ch := s[i+1] else ch := ' ';
      Scr.PutCh(X+i, Y, ch, Fg, Bg);
    end;
    Scr.Refresh;
  end;

begin
  s := Value; caret := Length(s);
  Paint;
  repeat
    k := Kbd.ReadKey;
    case k.Code of
      kcEnter, kcTab, kcEsc, kcUp, kcDown:
        begin OutKey := k; Exit(s); end;
      kcBksp:
        if caret > 0 then begin Delete(s, caret, 1); Dec(caret); Paint; end;
      kcDel:
        if caret < Length(s) then begin Delete(s, caret+1, 1); Paint; end;
      kcLeft:  if caret > 0 then Dec(caret);
      kcRight: if caret < Length(s) then Inc(caret);
      kcHome:  caret := 0;
      kcEnd:   caret := Length(s);
      kcChar:
        if (Length(s) < W) and (k.Ch >= ' ') then
        begin Insert(k.Ch, s, caret+1); Inc(caret); Paint; end;
    end;
  until False;
end;

function MenuLoop(Kbd: IKeyboard; const Items: array of TMenuItem): Integer;
var k: TKey; i: Integer; c: Char;
begin
  repeat
    k := Kbd.ReadKey;
    if k.Code = kcEsc then Exit(-1);
    if k.Code = kcChar then
    begin
      c := UpCase(k.Ch);
      for i := 0 to High(Items) do
        if UpCase(Items[i].HotKey) = c then Exit(Items[i].Id);
    end;
  until False;
end;

end.
