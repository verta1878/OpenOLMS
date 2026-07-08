{
  OpenOLMS - console screen backend
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
unit olms_screen_console;
{ IScreen backends:
    TBufferScreen  - an in-memory cell buffer that can dump to text (headless
                     testing / proof) and to ANSI for a real terminal.
    (A console TCrtScreen using the CRT unit, and later an SDL backend, plug in
     the same way.)
  Keeps the UI framework display-agnostic. }

{$MODE OBJFPC}{$H+}
{$INTERFACES CORBA}

interface

uses
  SysUtils, olms_ui;

type
  TCell = record Ch: Char; Fg, Bg: Byte; end;

  TBufferScreen = class(TObject, IScreen)
  private
    FCols, FRows: Integer;
    FCell: array of TCell;
    function Idx(X, Y: Integer): Integer; inline;
  public
    constructor Create(ACols: Integer = 80; ARows: Integer = 25);
    // IScreen
    procedure Clear(Bg: Byte);
    procedure PutStr(X, Y: Integer; const S: string; Fg, Bg: Byte);
    procedure PutCh(X, Y: Integer; Ch: Char; Fg, Bg: Byte);
    procedure Refresh;
    function  Cols: Integer;
    function  Rows: Integer;
    // dumps for testing / real output
    procedure DumpPlain;                     // characters only (headless proof)
    procedure DumpAnsi;                      // ANSI-colored to stdout
    function  CellAt(X, Y: Integer): TCell;
  end;

implementation

constructor TBufferScreen.Create(ACols, ARows: Integer);
begin
  inherited Create;
  FCols := ACols; FRows := ARows;
  SetLength(FCell, FCols*FRows);
  Clear(0);
end;

function TBufferScreen.Idx(X, Y: Integer): Integer; begin Result := Y*FCols + X; end;

function TBufferScreen.Cols: Integer; begin Result := FCols; end;
function TBufferScreen.Rows: Integer; begin Result := FRows; end;

procedure TBufferScreen.Clear(Bg: Byte);
var i: Integer;
begin
  for i := 0 to High(FCell) do
  begin FCell[i].Ch := ' '; FCell[i].Fg := 7; FCell[i].Bg := Bg; end;
end;

procedure TBufferScreen.PutCh(X, Y: Integer; Ch: Char; Fg, Bg: Byte);
begin
  if (X<0)or(X>=FCols)or(Y<0)or(Y>=FRows) then Exit;
  FCell[Idx(X,Y)].Ch := Ch; FCell[Idx(X,Y)].Fg := Fg; FCell[Idx(X,Y)].Bg := Bg;
end;

procedure TBufferScreen.PutStr(X, Y: Integer; const S: string; Fg, Bg: Byte);
var i: Integer;
begin
  for i := 1 to Length(S) do PutCh(X+i-1, Y, S[i], Fg, Bg);
end;

procedure TBufferScreen.Refresh; begin { buffer: no-op } end;
function TBufferScreen.CellAt(X, Y: Integer): TCell; begin Result := FCell[Idx(X,Y)]; end;

procedure TBufferScreen.DumpPlain;
var x, y: Integer; line: string;
begin
  for y := 0 to FRows-1 do
  begin
    line := '';
    for x := 0 to FCols-1 do line := line + FCell[Idx(x,y)].Ch;
    Writeln(TrimRight(line));
  end;
end;

procedure TBufferScreen.DumpAnsi;
const AnsiFg: array[0..15] of Integer = (30,34,32,36,31,35,33,37,90,94,92,96,91,95,93,97);
      AnsiBg: array[0..15] of Integer = (40,44,42,46,41,45,43,47,100,104,102,106,101,105,103,107);
var x, y: Integer; c: TCell;
begin
  for y := 0 to FRows-1 do
  begin
    for x := 0 to FCols-1 do
    begin
      c := FCell[Idx(x,y)];
      Write(#27'[', AnsiFg[c.Fg and 15], ';', AnsiBg[c.Bg and 15], 'm', c.Ch);
    end;
    Writeln(#27'[0m');
  end;
end;

end.
