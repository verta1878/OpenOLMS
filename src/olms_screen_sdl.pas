{
  OpenOLMS - SDL screen backend
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

  Built in Free Pascal from published format specifications.
}
unit olms_screen_sdl;
{ ===========================================================================
  OpenOLMS — SDL screen backend (Phase 13).

  The graphical target for the IScreen framework: renders the 80x25 text cells
  into a pixel buffer (each cell an 8x16 glyph in its CGA colors) and presents
  via SDL2 — the SAME approach as Mystic's mystic_sdl and our RIP client. Since
  it owns a pixel surface, this is ALSO the surface a RIP session draws onto, so
  RIP support plugs in here (Control Setup's "Allow RIP emulation").

  IScreen (text) and RIP (graphics) share one SDL surface: text screens blit
  glyphs; a RIP screen would blit vector primitives. Built once, used for both.

  Self-contained: minimal SDL2 binding + an 8x16 cell font. Compiles headless;
  needs libSDL2 + a display to actually show a window (like the RIP viewer).
  =========================================================================== }

{$MODE OBJFPC}{$H+}
{$INTERFACES CORBA}

interface

uses
  SysUtils, olms_ui;

const
  CELL_W = 8; CELL_H = 16;
  SCR_COLS = 80; SCR_ROWS = 25;
  PIX_W = SCR_COLS * CELL_W;   // 640
  PIX_H = SCR_ROWS * CELL_H;   // 400

type
  TSdlScreen = class(TObject, IScreen)
  private
    FCols, FRows : Integer;
    FCh  : array of Char;
    FFg  : array of Byte;
    FBg  : array of Byte;
    FPix : array of LongWord;    // ARGB, PIX_W x PIX_H
    FWin, FRen, FTex : Pointer;
    FScale : Integer;
    procedure RenderCells;
  public
    constructor Create(AScale: Integer = 2);
    function  InitWindow(const Title: string): Boolean;
    // IScreen
    procedure Clear(Bg: Byte);
    procedure PutStr(X, Y: Integer; const S: string; Fg, Bg: Byte);
    procedure PutCh(X, Y: Integer; Ch: Char; Fg, Bg: Byte);
    procedure Refresh;
    function  Cols: Integer;
    function  Rows: Integer;
    procedure Shutdown;
  end;

implementation

{ minimal SDL2 (mirrors the RIP client's sdl2min) }
const
  {$IFDEF WINDOWS} SDL_LIB='SDL2.dll'; {$ELSE} SDL_LIB='libSDL2-2.0.so.0'; {$ENDIF}
  SDL_INIT_VIDEO=$20; WPOS_CENTER=$2FFF0000; WIN_SHOWN=$04;
  PF_ARGB8888=$16362004; TEX_STREAM=1; REN_ACCEL=$02;
function SDL_Init(f:LongWord):LongInt;cdecl;external SDL_LIB;
procedure SDL_Quit;cdecl;external SDL_LIB;
function SDL_CreateWindow(t:PAnsiChar;x,y,w,h:LongInt;f:LongWord):Pointer;cdecl;external SDL_LIB;
procedure SDL_DestroyWindow(w:Pointer);cdecl;external SDL_LIB;
function SDL_CreateRenderer(w:Pointer;i:LongInt;f:LongWord):Pointer;cdecl;external SDL_LIB;
procedure SDL_DestroyRenderer(r:Pointer);cdecl;external SDL_LIB;
function SDL_CreateTexture(r:Pointer;fmt:LongWord;a,w,h:LongInt):Pointer;cdecl;external SDL_LIB;
procedure SDL_DestroyTexture(t:Pointer);cdecl;external SDL_LIB;
function SDL_UpdateTexture(t:Pointer;rc:Pointer;px:Pointer;pitch:LongInt):LongInt;cdecl;external SDL_LIB;
function SDL_RenderClear(r:Pointer):LongInt;cdecl;external SDL_LIB;
function SDL_RenderCopy(r,t,s,d:Pointer):LongInt;cdecl;external SDL_LIB;
procedure SDL_RenderPresent(r:Pointer);cdecl;external SDL_LIB;

{$I font8x16.inc}   // FONT8X16: array[0..255,0..15] of Byte  (VGA cell font)

const
  CGA: array[0..15] of LongWord = (
    $FF000000,$FF0000AA,$FF00AA00,$FF00AAAA,$FFAA0000,$FFAA00AA,$FFAA5500,$FFAAAAAA,
    $FF555555,$FF5555FF,$FF55FF55,$FF55FFFF,$FFFF5555,$FFFF55FF,$FFFFFF55,$FFFFFFFF);

constructor TSdlScreen.Create(AScale: Integer);
begin
  inherited Create;
  FCols := SCR_COLS; FRows := SCR_ROWS; FScale := AScale;
  SetLength(FCh, FCols*FRows); SetLength(FFg, FCols*FRows); SetLength(FBg, FCols*FRows);
  SetLength(FPix, PIX_W*PIX_H);
  Clear(0);
end;

function TSdlScreen.Cols: Integer; begin Result := FCols; end;
function TSdlScreen.Rows: Integer; begin Result := FRows; end;

procedure TSdlScreen.Clear(Bg: Byte);
var i: Integer;
begin
  for i := 0 to High(FCh) do begin FCh[i]:=' '; FFg[i]:=7; FBg[i]:=Bg; end;
end;

procedure TSdlScreen.PutCh(X, Y: Integer; Ch: Char; Fg, Bg: Byte);
var idx: Integer;
begin
  if (X<0)or(X>=FCols)or(Y<0)or(Y>=FRows) then Exit;
  idx := Y*FCols+X; FCh[idx]:=Ch; FFg[idx]:=Fg; FBg[idx]:=Bg;
end;

procedure TSdlScreen.PutStr(X, Y: Integer; const S: string; Fg, Bg: Byte);
var i: Integer;
begin for i:=1 to Length(S) do PutCh(X+i-1,Y,S[i],Fg,Bg); end;

procedure TSdlScreen.RenderCells;
var cx, cy, gx, gy, o: Integer; ch: Byte; fg, bg: LongWord; bits: Byte;
begin
  for cy := 0 to FRows-1 do
    for cx := 0 to FCols-1 do
    begin
      o := cy*FCols+cx;
      ch := Ord(FCh[o]); fg := CGA[FFg[o] and 15]; bg := CGA[FBg[o] and 15];
      for gy := 0 to CELL_H-1 do
      begin
        bits := FONT8X16[ch][gy];
        for gx := 0 to CELL_W-1 do
          if (bits and (128 shr gx)) <> 0 then
            FPix[(cy*CELL_H+gy)*PIX_W + (cx*CELL_W+gx)] := fg
          else
            FPix[(cy*CELL_H+gy)*PIX_W + (cx*CELL_W+gx)] := bg;
      end;
    end;
end;

function TSdlScreen.InitWindow(const Title: string): Boolean;
begin
  Result := False;
  if SDL_Init(SDL_INIT_VIDEO) <> 0 then Exit;
  FWin := SDL_CreateWindow(PAnsiChar(AnsiString(Title)), WPOS_CENTER, WPOS_CENTER,
            PIX_W*FScale, PIX_H*FScale, WIN_SHOWN);
  if FWin = nil then Exit;
  FRen := SDL_CreateRenderer(FWin, -1, REN_ACCEL);
  if FRen = nil then Exit;
  FTex := SDL_CreateTexture(FRen, PF_ARGB8888, TEX_STREAM, PIX_W, PIX_H);
  Result := FTex <> nil;
end;

procedure TSdlScreen.Refresh;
begin
  if FTex = nil then Exit;
  RenderCells;
  SDL_UpdateTexture(FTex, nil, @FPix[0], PIX_W*4);
  SDL_RenderClear(FRen);
  SDL_RenderCopy(FRen, FTex, nil, nil);
  SDL_RenderPresent(FRen);
end;

procedure TSdlScreen.Shutdown;
begin
  if FTex<>nil then SDL_DestroyTexture(FTex);
  if FRen<>nil then SDL_DestroyRenderer(FRen);
  if FWin<>nil then SDL_DestroyWindow(FWin);
  SDL_Quit;
end;

end.
