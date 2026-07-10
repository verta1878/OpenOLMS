unit olms_kbd_sdl;
{
  OpenOLMS - SDL keyboard backend (IKeyboard via SDL2 events)
  SPDX-License-Identifier: GPL-3.0-or-later
  Copyright (C) 2026  Antonio Rico / Ecstasy BBS (github.com/verta1878)
  Distributed under the GNU General Public License v3 or later. See LICENSE.

  Reads keystrokes from the SDL2 event queue (via the shared sdl_bind binding
  used by src/mystic_sdl) and maps them to OpenOLMS TKey values, so the same
  EditField / menu code runs in the graphical SDL window as on DOS CRT.
}

{$MODE OBJFPC}{$H+}
{$INTERFACES CORBA}

interface

uses
  SysUtils, olms_input, sdl_bind;

type
  TSdlKeyboard = class(TObject, IKeyboard)
  private
    FPending : TKey;
    FHave    : Boolean;
    function Poll(out K: TKey): Boolean;
  public
    function ReadKey: TKey;
    function KeyPressed: Boolean;
  end;

implementation

const
  // SDL keycodes we care about
  SDLK_RETURN    = 13;
  SDLK_ESCAPE    = 27;
  SDLK_BACKSPACE = 8;
  SDLK_TAB       = 9;
  SDLK_DELETE    = 127;
  SDLK_MASK      = $40000000;   // SDLK_SCANCODE_MASK for nav keys
  SDLK_RIGHT     = SDLK_MASK or $4F;
  SDLK_LEFT      = SDLK_MASK or $50;
  SDLK_DOWN      = SDLK_MASK or $51;
  SDLK_UP        = SDLK_MASK or $52;
  SDLK_HOME      = SDLK_MASK or $4A;
  SDLK_END       = SDLK_MASK or $4D;
  SDLK_PGUP      = SDLK_MASK or $4B;
  SDLK_PGDN      = SDLK_MASK or $4E;

{ Read the SDL keycode (keysym.sym) out of the event buffer.
  Event layout: type(4) timestamp(4) windowID(4) state(1) repeat(1) pad(2)
  keysym{ scancode(4) sym(4) ... }. sym is at byte offset 20 => Pad[16..19]. }
function KeycodeOf(const Ev: TSDL_Event): LongWord;
begin
  Move(Ev.Pad[16], Result, 4);
end;

function MapKey(code: LongWord): TKey;
begin
  Result.Ch := #0;
  case code of
    SDLK_RETURN    : Result.Code := kcEnter;
    SDLK_ESCAPE    : Result.Code := kcEsc;
    SDLK_BACKSPACE : Result.Code := kcBksp;
    SDLK_TAB       : Result.Code := kcTab;
    SDLK_DELETE    : Result.Code := kcDel;
    SDLK_UP        : Result.Code := kcUp;
    SDLK_DOWN      : Result.Code := kcDown;
    SDLK_LEFT      : Result.Code := kcLeft;
    SDLK_RIGHT     : Result.Code := kcRight;
    SDLK_HOME      : Result.Code := kcHome;
    SDLK_END       : Result.Code := kcEnd;
    SDLK_PGUP      : Result.Code := kcPgUp;
    SDLK_PGDN      : Result.Code := kcPgDn;
  else
    if (code >= 32) and (code < 127) then
      begin Result.Code := kcChar; Result.Ch := Chr(code); end
    else
      Result.Code := kcUnknown;
  end;
end;

function TSdlKeyboard.Poll(out K: TKey): Boolean;
var Ev: TSDL_Event;
begin
  Result := False;
  if not SDLLoaded then Exit;
  while SDL_PollEvent(Ev) <> 0 do
  begin
    if Ev.EventType = SDL_QUIT_EVENT then
      begin K.Code := kcEsc; K.Ch := #0; Exit(True); end;
    if Ev.EventType = SDL_KEYDOWN then
    begin
      K := MapKey(KeycodeOf(Ev));
      if K.Code <> kcUnknown then Exit(True);
    end;
  end;
end;

function TSdlKeyboard.KeyPressed: Boolean;
begin
  if FHave then Exit(True);
  FHave := Poll(FPending);
  Result := FHave;
end;

function TSdlKeyboard.ReadKey: TKey;
begin
  if FHave then begin FHave := False; Exit(FPending); end;
  repeat
    if Poll(Result) then Exit;
    SDL_Delay(8);          // don't busy-spin while waiting
  until False;
end;

end.
