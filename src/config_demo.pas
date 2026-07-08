{
  OpenOLMS - sysop configuration (main program)
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
program config_demo;
{ OpenOLMS config.exe — first cloned screen: System Information.
  Renders the System Information config screen (grounded in OLMS.DOC p.3) using
  the text-mode UI framework, into a headless buffer we can print — proving the
  config-UI pattern. On a real terminal this same code draws live; the SDL
  backend will render the same screen graphically.

  Usage: config_demo            (prints the screen as plain text)
         config_demo --ansi     (prints with ANSI colors) }

{$MODE OBJFPC}{$H+}

uses
  SysUtils, olms_ui, olms_screen_console, olms_config;

procedure DrawSysInfoScreen(Scr: IScreen; const Cfg: TOlmsConfig);
begin
  Scr.Clear(clBlue);
  // top title bar (matching the original's banded look)
  Scr.PutStr(0, 0, StringOfChar(' ', Scr.Cols), clWhite, clCyan);
  Scr.PutStr(2, 0, 'OpenOLMS Configuration', clBlack, clCyan);
  Scr.PutStr(Scr.Cols-14, 0, 'System Info', clBlack, clCyan);

  // main framed panel
  DrawTitledBox(Scr, 8, 3, 64, 16, 'System Information', clLightCyan, clBlue,
                clYellow, bsDouble);

  // fields (label + input slot), laid out like the original config screen
  DrawField(Scr, 11,  5, 20, 34, 'System name  :', Cfg.Sys.SystemName, clLightGray, clWhite, clBlue);
  DrawField(Scr, 11,  7, 20, 34, 'Sysop name   :', Cfg.Sys.SysopName,  clLightGray, clWhite, clBlue);
  DrawField(Scr, 11,  9, 20, 10, 'Board ID     :', Cfg.Sys.BoardID,    clLightGray, clWhite, clBlue);
  DrawField(Scr, 11, 11, 20, 20, 'Phone number :', Cfg.Sys.Phone,      clLightGray, clWhite, clBlue);
  DrawField(Scr, 11, 13, 20, 34, 'Gateway addr :', Cfg.Sys.Gateway,    clLightGray, clWhite, clBlue);

  // help/hint line inside the panel
  Scr.PutStr(11, 16, 'System/Sysop names come from CONFIG.RA. Board ID: 1-8 chars, unique.',
             clLightGreen, clBlue);

  // bottom status/key bar
  Scr.PutStr(0, Scr.Rows-1, StringOfChar(' ', Scr.Cols), clBlack, clCyan);
  Scr.PutStr(2, Scr.Rows-1, 'ENTER=edit  TAB=next  ESC=save & exit', clBlack, clCyan);
end;

var
  scr: TBufferScreen;
  cfg: TOlmsConfig;
begin
  cfg := TOlmsConfig.Create;
  cfg.SetDefaults;
  cfg.Sys.SystemName := 'Ecstasy BBS';
  cfg.Sys.SysopName  := 'reapern66';
  cfg.Sys.BoardID    := 'ECSTASY';
  cfg.Sys.Phone      := '';
  cfg.Sys.Gateway    := '';

  scr := TBufferScreen.Create(80, 25);
  try
    DrawSysInfoScreen(scr as IScreen, cfg);
    if (ParamCount >= 1) and (ParamStr(1) = '--ansi') then scr.DumpAnsi
    else scr.DumpPlain;
  finally
    scr.Free;
    cfg.Free;
  end;
end.
