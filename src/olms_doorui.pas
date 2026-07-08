{
  OpenOLMS - door user interface screens
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
unit olms_doorui;
{ ===========================================================================
  OpenOLMS — door user interface (Phase 4).

  The interactive screens a CALLER sees inside the door, built on the olms_ui
  framework (so console now, SDL later). Cloned in layout/flow from the OLMS
  screenshots + manual: a main menu and a conference-selection screen with
  toggle-to-join, matching the original's look (letter/number selectors,
  titled boxes, help + status bars).

  This is presentation + selection state; the actions call into the door engine
  (scan/packet/reply) already built.
  =========================================================================== }

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, olms_ui;

type
  TConfEntry = record
    Number : Word;
    Name   : string;
    Joined : Boolean;
  end;
  TConfList = array of TConfEntry;

{ Render the door main menu (the caller's top-level options). }
procedure DrawMainMenu(Scr: IScreen; const BBSName, UserName: string;
                       TimeLeftMin: Integer);

{ Render the conference-selection screen; 'joined' shown with a marker. }
procedure DrawConfSelect(Scr: IScreen; const Confs: TConfList; TopIndex: Integer);

implementation

procedure DrawMainMenu(Scr: IScreen; const BBSName, UserName: string;
                       TimeLeftMin: Integer);
begin
  Scr.Clear(clBlue);
  // top bar
  Scr.PutStr(0, 0, StringOfChar(' ', Scr.Cols), clWhite, clCyan);
  Scr.PutStr(2, 0, 'OpenOLMS  -  ' + BBSName, clBlack, clCyan);
  Scr.PutStr(Scr.Cols-20, 0, Format('%s  %dm', [UserName, TimeLeftMin]), clBlack, clCyan);

  DrawTitledBox(Scr, 22, 4, 36, 15, 'Main Menu', clLightCyan, clBlue, clYellow, bsDouble);

  Scr.PutStr(27,  6, '(D)  Download new mail',     clLightGray, clBlue);
  Scr.PutStr(27,  7, '(U)  Upload replies',        clLightGray, clBlue);
  Scr.PutStr(27,  8, '(C)  Configure conferences', clLightGray, clBlue);
  Scr.PutStr(27,  9, '(K)  Keywords / filters',    clLightGray, clBlue);
  Scr.PutStr(27, 10, '(T)  Twit list',             clLightGray, clBlue);
  Scr.PutStr(27, 11, '(B)  Bulletins',             clLightGray, clBlue);
  Scr.PutStr(27, 12, '(V)  Vacation mail',         clLightGray, clBlue);
  Scr.PutStr(27, 14, '(G)  Goodbye (return to BBS)', clLightGreen, clBlue);

  // highlight the primary action
  Scr.PutStr(27, 6, '(D)', clYellow, clBlue);

  Scr.PutStr(0, Scr.Rows-1, StringOfChar(' ', Scr.Cols), clBlack, clCyan);
  Scr.PutStr(2, Scr.Rows-1, 'Select an option, or (G) to leave.', clBlack, clCyan);
end;

procedure DrawConfSelect(Scr: IScreen; const Confs: TConfList; TopIndex: Integer);
var
  i, row, shown, maxRows: Integer;
  sel: Char;
  line: string;
begin
  Scr.Clear(clBlue);
  Scr.PutStr(0, 0, StringOfChar(' ', Scr.Cols), clWhite, clCyan);
  Scr.PutStr(2, 0, 'OpenOLMS  -  Conference Selection', clBlack, clCyan);

  DrawTitledBox(Scr, 4, 2, Scr.Cols-8, Scr.Rows-4, 'Conferences', clLightCyan, clBlue, clYellow, bsSingle);

  maxRows := Scr.Rows - 7;
  shown := 0;
  row := 4;
  for i := TopIndex to High(Confs) do
  begin
    if shown >= maxRows then Break;
    // selector letter A.. then number for overflow
    if i < 26 then sel := Chr(Ord('A') + i) else sel := '#';
    line := Format('(%s) %-30s', [sel, Confs[i].Name]);
    Scr.PutStr(8, row, line, clLightGray, clBlue);
    if Confs[i].Joined then
      Scr.PutStr(46, row, '[JOINED]', clLightGreen, clBlue)
    else
      Scr.PutStr(46, row, '[      ]', clDarkGray, clBlue);
    Inc(row); Inc(shown);
  end;

  Scr.PutStr(0, Scr.Rows-1, StringOfChar(' ', Scr.Cols), clBlack, clCyan);
  Scr.PutStr(2, Scr.Rows-1, 'Letter=toggle join   PgUp/PgDn=scroll   (Q)uit', clBlack, clCyan);
end;

end.
