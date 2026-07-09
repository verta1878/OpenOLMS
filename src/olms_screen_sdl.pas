unit olms_screen_sdl;
{
  OpenOLMS - SDL screen backend (IScreen via Mystic's CP437 renderer)
  SPDX-License-Identifier: GPL-3.0-or-later
  Copyright (C) 2026  Antonio Rico - Ecstasy BBS / Reapern66
  Distributed under the GNU General Public License v3 or later. See LICENSE.

  Renders OpenOLMS's text UI into a graphical 80x25 CP437 window using the
  self-contained SDL screen engine from Mystic BBS (TDosScreen, by James Coyle
  / g00r00, GPLv3 - see src/mystic_sdl/). Used on modern OSes where SDL2 is
  available; the DOS build uses the CRT backend. Same UI code drives both.
}

{$MODE OBJFPC}{$H+}
{$INTERFACES CORBA}

interface

uses
  SysUtils, olms_ui, sdl_dosscreen;

type
  TSdlScreen = class(TObject, IScreen)
  private
    FScr : TDosScreen;
    FOk  : Boolean;
  public
    constructor Create(const Title: string = 'OpenOLMS';
                       const FontFile: string = 'VGA8X16.FNT');
    destructor Destroy; override;
    function  Ready: Boolean;
    function  Raw: TDosScreen;
    procedure Clear(Bg: Byte);
    procedure PutStr(X, Y: Integer; const S: string; Fg, Bg: Byte);
    procedure PutCh(X, Y: Integer; Ch: Char; Fg, Bg: Byte);
    procedure Refresh;
    function  Cols: Integer;
    function  Rows: Integer;
    procedure PlaceCursor(X, Y: Integer);
  end;

implementation

function Attr(Fg, Bg: Byte): Byte; inline;
begin
  Result := ((Bg and $07) shl 4) or (Fg and $0F);
end;

constructor TSdlScreen.Create(const Title, FontFile: string);
begin
  inherited Create;
  FScr := TDosScreen.Create;
  FScr.LoadFont(FontFile);
  FOk := FScr.Open(Title);
end;

destructor TSdlScreen.Destroy;
begin
  if Assigned(FScr) then begin FScr.Close; FScr.Free; end;
  inherited Destroy;
end;

function TSdlScreen.Ready: Boolean;  begin Result := FOk; end;
function TSdlScreen.Raw: TDosScreen;  begin Result := FScr; end;
function TSdlScreen.Cols: Integer;    begin Result := COLS; end;
function TSdlScreen.Rows: Integer;    begin Result := ROWS; end;

procedure TSdlScreen.Clear(Bg: Byte);
begin
  FScr.Clear(Attr(7, Bg));
end;

procedure TSdlScreen.PutStr(X, Y: Integer; const S: string; Fg, Bg: Byte);
begin
  if (Y < 0) or (Y >= ROWS) then Exit;
  FScr.SetAttr(Attr(Fg, Bg));
  FScr.WriteXY(X, Y, S);
end;

procedure TSdlScreen.PutCh(X, Y: Integer; Ch: Char; Fg, Bg: Byte);
begin
  FScr.SetAttr(Attr(Fg, Bg));
  FScr.PutChar(X, Y, Ch);
end;

procedure TSdlScreen.Refresh;
begin
  FScr.Present;
end;

procedure TSdlScreen.PlaceCursor(X, Y: Integer);
begin
  // SDL CP437 screen has no hardware text cursor; no-op.
end;

end.
