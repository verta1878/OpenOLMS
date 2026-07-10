unit olms_screen_crt;
{
  OpenOLMS - live console screen backend (Crt)
  SPDX-License-Identifier: GPL-3.0-or-later
  Copyright (C) 2026  Antonio Rico / Ecstasy BBS (github.com/verta1878)
  Distributed under the GNU General Public License v3 or later. See LICENSE.
  Built in Free Pascal from published format specifications.
}

{ A live IScreen backend that writes straight to the text console via the CRT
  unit (GotoXY / TextColor / TextBackground). Unlike TBufferScreen (which only
  holds a buffer and dumps it), this updates the screen in place, so the
  interactive config tool can edit fields and redraw live on DOS. }

{$MODE OBJFPC}{$H+}
{$INTERFACES CORBA}

interface

uses
  SysUtils, olms_ui;

type
  TCrtScreen = class(TObject, IScreen)
  private
    FCols, FRows: Integer;
  public
    constructor Create(ACols: Integer = 80; ARows: Integer = 25);
    procedure Clear(Bg: Byte);
    procedure PutStr(X, Y: Integer; const S: string; Fg, Bg: Byte);
    procedure PutCh(X, Y: Integer; Ch: Char; Fg, Bg: Byte);
    procedure Refresh;
    function  Cols: Integer;
    function  Rows: Integer;
    procedure PlaceCursor(X, Y: Integer);
  end;

implementation

uses
  Crt;

constructor TCrtScreen.Create(ACols, ARows: Integer);
begin
  inherited Create;
  FCols := ACols; FRows := ARows;
end;

function TCrtScreen.Cols: Integer; begin Result := FCols; end;
function TCrtScreen.Rows: Integer; begin Result := FRows; end;

procedure TCrtScreen.Clear(Bg: Byte);
begin
  TextBackground(Bg and 7);
  TextColor(7);
  ClrScr;
end;

procedure TCrtScreen.PutCh(X, Y: Integer; Ch: Char; Fg, Bg: Byte);
begin
  if (X < 0) or (X >= FCols) or (Y < 0) or (Y >= FRows) then Exit;
  // Writing the bottom-right cell makes DOS scroll the whole screen up; skip it.
  if (X = FCols-1) and (Y = FRows-1) then Exit;
  GotoXY(X+1, Y+1);            // CRT is 1-based
  TextColor(Fg and 15);
  TextBackground(Bg and 7);
  Write(Ch);
end;

procedure TCrtScreen.PutStr(X, Y: Integer; const S: string; Fg, Bg: Byte);
var i, n: Integer;
begin
  if (Y < 0) or (Y >= FRows) then Exit;
  if X < 0 then X := 0;
  GotoXY(X+1, Y+1);
  TextColor(Fg and 15);
  TextBackground(Bg and 7);
  n := Length(S);
  if X + n > FCols then n := FCols - X;   // clip to width (avoid wrap/scroll)
  // On the LAST row, never write the final column: writing the bottom-right
  // cell scrolls the whole DOS screen up by one line.
  if (Y = FRows-1) and (X + n >= FCols) then n := FCols - 1 - X;
  for i := 1 to n do Write(S[i]);
end;

procedure TCrtScreen.Refresh;
begin
  // CRT writes immediately; nothing to flush.
end;

procedure TCrtScreen.PlaceCursor(X, Y: Integer);
begin
  if (X >= 0) and (X < FCols) and (Y >= 0) and (Y < FRows) then GotoXY(X+1, Y+1);
end;

end.
