{
  OpenOLMS - text-mode UI framework
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
unit olms_ui;
{ ===========================================================================
  OpenOLMS — text-mode UI framework for config.exe (and olms.exe screens).

  Draws through an abstract IScreen so the SAME UI code runs on the console now
  and through the SDL front-end later (logic/presentation split, like the RIP
  client's IRipCanvas). Provides the primitives a config-screen clone needs:
  colored cells, boxes, labels, and labeled input fields.

  Colors are CGA/ANSI 0..15 (matching the original's look).
  =========================================================================== }

{$MODE OBJFPC}{$H+}
{$INTERFACES CORBA}   // IScreen is manually managed (no refcount/auto-free)

interface

uses
  SysUtils;

type
  { The screen abstraction. Console backend now; SDL backend later. }
  IScreen = interface
    ['{05C33EE0-0002-4000-9000-000000000002}']
    procedure Clear(Bg: Byte);
    procedure PutStr(X, Y: Integer; const S: string; Fg, Bg: Byte);
    procedure PutCh(X, Y: Integer; Ch: Char; Fg, Bg: Byte);
    procedure Refresh;                 // flush to the actual display
    function  Cols: Integer;
    function  Rows: Integer;
  end;

  { Single/double-line box styles. }
  TBoxStyle = (bsSingle, bsDouble);

{ Drawing helpers built on IScreen — these are the reusable UI primitives. }
procedure DrawBox(Scr: IScreen; X, Y, W, H: Integer; Fg, Bg: Byte; Style: TBoxStyle);
procedure DrawTitledBox(Scr: IScreen; X, Y, W, H: Integer; const Title: string;
                        Fg, Bg, TitleFg: Byte; Style: TBoxStyle);
procedure DrawField(Scr: IScreen; X, Y, LabelW, FieldW: Integer;
                    const ALabel, AValue: string;
                    LabelFg, ValueFg, Bg: Byte);

const
  { CGA/ANSI color indices }
  clBlack=0; clBlue=1; clGreen=2; clCyan=3; clRed=4; clMagenta=5; clBrown=6;
  clLightGray=7; clDarkGray=8; clLightBlue=9; clLightGreen=10; clLightCyan=11;
  clLightRed=12; clLightMagenta=13; clYellow=14; clWhite=15;

implementation

const
  { CP437 box-drawing characters }
  SglTL=#218; SglTR=#191; SglBL=#192; SglBR=#217; SglH=#196; SglV=#179;
  DblTL=#201; DblTR=#187; DblBL=#200; DblBR=#188; DblH=#205; DblV=#186;

procedure DrawBox(Scr: IScreen; X, Y, W, H: Integer; Fg, Bg: Byte; Style: TBoxStyle);
var i: Integer; tl,tr,bl,br,hh,vv: Char;
begin
  if Style = bsDouble then
    begin tl:=DblTL; tr:=DblTR; bl:=DblBL; br:=DblBR; hh:=DblH; vv:=DblV; end
  else
    begin tl:=SglTL; tr:=SglTR; bl:=SglBL; br:=SglBR; hh:=SglH; vv:=SglV; end;
  Scr.PutCh(X, Y, tl, Fg, Bg);
  Scr.PutCh(X+W-1, Y, tr, Fg, Bg);
  Scr.PutCh(X, Y+H-1, bl, Fg, Bg);
  Scr.PutCh(X+W-1, Y+H-1, br, Fg, Bg);
  for i := X+1 to X+W-2 do
  begin Scr.PutCh(i, Y, hh, Fg, Bg); Scr.PutCh(i, Y+H-1, hh, Fg, Bg); end;
  for i := Y+1 to Y+H-2 do
  begin Scr.PutCh(X, i, vv, Fg, Bg); Scr.PutCh(X+W-1, i, vv, Fg, Bg); end;
end;

procedure DrawTitledBox(Scr: IScreen; X, Y, W, H: Integer; const Title: string;
                        Fg, Bg, TitleFg: Byte; Style: TBoxStyle);
var tx: Integer;
begin
  DrawBox(Scr, X, Y, W, H, Fg, Bg, Style);
  if Title <> '' then
  begin
    tx := X + (W - (Length(Title)+2)) div 2;
    Scr.PutStr(tx, Y, ' ' + Title + ' ', TitleFg, Bg);
  end;
end;

procedure DrawField(Scr: IScreen; X, Y, LabelW, FieldW: Integer;
                    const ALabel, AValue: string;
                    LabelFg, ValueFg, Bg: Byte);
var i: Integer; v: string;
begin
  Scr.PutStr(X, Y, ALabel, LabelFg, Bg);
  // field slot as a reverse-ish input area
  for i := 0 to FieldW-1 do Scr.PutCh(X+LabelW+i, Y, ' ', ValueFg, clBlue);
  v := Copy(AValue, 1, FieldW);
  Scr.PutStr(X+LabelW, Y, v, ValueFg, clBlue);
end;

end.
