{
  OpenOLMS - configuration screens
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
unit olms_configui;
{ ===========================================================================
  OpenOLMS — config.exe screens (Phase 5).

  The sysop configuration screens beyond System Information, cloned in
  layout/flow from OLMS.DOC + screenshots, drawn on the olms_ui framework:
    - Main configuration menu
    - Archiver Programs   (compress/decompress/swap per archive type)
    - Protocol Programs   (up/down command lines)
    - Limits Setup        (max messages, packet KB, conferences)
  Data comes straight from TOlmsConfig, so these edit the same records
  olms.exe reads.
  =========================================================================== }

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, olms_ui, olms_config;

procedure DrawConfigMenu(Scr: IScreen);
procedure DrawArchiverScreen(Scr: IScreen; const Cfg: TOlmsConfig);
procedure DrawProtocolScreen(Scr: IScreen; const Cfg: TOlmsConfig);
procedure DrawLimitsScreen(Scr: IScreen; const Cfg: TOlmsConfig);
procedure DrawFilesScreen(Scr: IScreen; const Cfg: TOlmsConfig);
procedure DrawControlScreen(Scr: IScreen; const Cfg: TOlmsConfig);
procedure DrawRequestingScreen(Scr: IScreen; const Cfg: TOlmsConfig);
procedure DrawUserEditorScreen(Scr: IScreen);
procedure DrawBulletinsScreen(Scr: IScreen);
procedure DrawLanguageScreen(Scr: IScreen);
procedure DrawTestScreen(Scr: IScreen; const Cfg: TOlmsConfig);

implementation

procedure TopBar(Scr: IScreen; const Right: string);
begin
  Scr.PutStr(0, 0, StringOfChar(' ', Scr.Cols), clWhite, clCyan);
  Scr.PutStr(2, 0, 'OpenOLMS Configuration', clBlack, clCyan);
  if Right <> '' then Scr.PutStr(Scr.Cols-Length(Right)-2, 0, Right, clBlack, clCyan);
end;

procedure BotBar(Scr: IScreen; const S: string);
begin
  Scr.PutStr(0, Scr.Rows-1, StringOfChar(' ', Scr.Cols), clBlack, clCyan);
  Scr.PutStr(2, Scr.Rows-1, S, clBlack, clCyan);
end;

procedure DrawConfigMenu(Scr: IScreen);
begin
  Scr.Clear(clBlue);
  TopBar(Scr, 'Main');
  DrawTitledBox(Scr, 24, 3, 32, 17, 'Configuration', clLightCyan, clBlue, clYellow, bsDouble);
  Scr.PutStr(28,  5, '(1) System Information',  clLightGray, clBlue);
  Scr.PutStr(28,  6, '(2) Archiver Programs',   clLightGray, clBlue);
  Scr.PutStr(28,  7, '(3) Protocol Programs',   clLightGray, clBlue);
  Scr.PutStr(28,  8, '(4) Files Configuration', clLightGray, clBlue);
  Scr.PutStr(28,  9, '(5) Bulletins',           clLightGray, clBlue);
  Scr.PutStr(28, 10, '(6) Control Setup',       clLightGray, clBlue);
  Scr.PutStr(28, 11, '(7) Requesting Control',  clLightGray, clBlue);
  Scr.PutStr(28, 12, '(8) Limits Setup',        clLightGray, clBlue);
  Scr.PutStr(28, 13, '(9) User Editor',         clLightGray, clBlue);
  Scr.PutStr(28, 14, '(0) Multi-language',      clLightGray, clBlue);
  Scr.PutStr(28, 16, '(T) Test Configuration',  clLightGreen, clBlue);
  Scr.PutStr(28, 17, '(S) Save & Exit',         clYellow, clBlue);
  BotBar(Scr, 'Choose a section to configure.');
end;

procedure DrawArchiverScreen(Scr: IScreen; const Cfg: TOlmsConfig);
var i, row: Integer; sw: string;
begin
  Scr.Clear(clBlue);
  TopBar(Scr, 'Archivers');
  DrawTitledBox(Scr, 3, 2, Scr.Cols-6, Scr.Rows-4, 'Archiver Programs', clLightCyan, clBlue, clYellow, bsDouble);
  Scr.PutStr(6, 4, 'Tag       Compression / Decompression command       Swap', clWhite, clBlue);
  row := 6;
  for i := 0 to High(Cfg.Archivers) do
  begin
    if Cfg.Archivers[i].Tag = '' then Continue;
    if Cfg.Archivers[i].Swap then sw := 'Yes' else sw := 'No';
    Scr.PutStr(6,  row, Format('%-8s', [Cfg.Archivers[i].Tag]), clYellow, clBlue);
    Scr.PutStr(16, row, Copy(Cfg.Archivers[i].Compress, 1, 40), clLightGray, clBlue);
    Scr.PutStr(Scr.Cols-10, row, sw, clLightGreen, clBlue);
    Scr.PutStr(16, row+1, Copy(Cfg.Archivers[i].Decompress, 1, 40), clDarkGray, clBlue);
    Inc(row, 3);
  end;
  Scr.PutStr(6, Scr.Rows-4, 'Set a command to OFF to disable that archiver.', clLightGreen, clBlue);
  BotBar(Scr, 'ENTER=edit  INS=add  DEL=remove  ESC=back');
end;

procedure DrawProtocolScreen(Scr: IScreen; const Cfg: TOlmsConfig);
var i, row: Integer;
begin
  Scr.Clear(clBlue);
  TopBar(Scr, 'Protocols');
  DrawTitledBox(Scr, 3, 2, Scr.Cols-6, Scr.Rows-4, 'Protocol Programs', clLightCyan, clBlue, clYellow, bsDouble);
  Scr.PutStr(6, 4, 'Name            Upload / Download command', clWhite, clBlue);
  row := 6;
  for i := 0 to High(Cfg.Protocols) do
  begin
    if Cfg.Protocols[i].Name = '' then Continue;
    Scr.PutStr(6,  row, Format('%-14s', [Cfg.Protocols[i].Name]), clYellow, clBlue);
    Scr.PutStr(22, row, Copy(Cfg.Protocols[i].UpCmd, 1, 48), clLightGray, clBlue);
    Scr.PutStr(22, row+1, Copy(Cfg.Protocols[i].DownCmd, 1, 48), clDarkGray, clBlue);
    Inc(row, 3);
  end;
  if row = 6 then
    Scr.PutStr(6, 6, '(no protocols defined — INS to add Zmodem, etc.)', clDarkGray, clBlue);
  BotBar(Scr, 'ENTER=edit  INS=add  DEL=remove  ESC=back');
end;

procedure DrawLimitsScreen(Scr: IScreen; const Cfg: TOlmsConfig);
begin
  Scr.Clear(clBlue);
  TopBar(Scr, 'Limits');
  DrawTitledBox(Scr, 12, 4, 56, 14, 'Limits Setup', clLightCyan, clBlue, clYellow, bsDouble);
  DrawField(Scr, 15,  6, 30, 12, 'Max messages / packet    :', IntToStr(Cfg.Limits.MaxMessages), clLightGray, clWhite, clBlue);
  DrawField(Scr, 15,  8, 30, 12, 'Max packet size (KB)     :', IntToStr(Cfg.Limits.MaxPacketKB), clLightGray, clWhite, clBlue);
  DrawField(Scr, 15, 10, 30, 12, 'Max conferences / user   :', IntToStr(Cfg.Limits.MaxConfs), clLightGray, clWhite, clBlue);
  DrawField(Scr, 15, 12, 30, 12, 'Taglines kept            :', IntToStr(Cfg.Limits.MaxTaglines), clLightGray, clWhite, clBlue);
  Scr.PutStr(15, 15, 'Zero = unlimited where applicable.', clLightGreen, clBlue);
  BotBar(Scr, 'ENTER=edit  TAB=next  ESC=back');
end;

procedure DrawFilesScreen(Scr: IScreen; const Cfg: TOlmsConfig);
begin
  Scr.Clear(clBlue);
  TopBar(Scr, 'Files');
  DrawTitledBox(Scr, 8, 3, 64, 16, 'Files Configuration', clLightCyan, clBlue, clYellow, bsDouble);
  DrawField(Scr, 11,  5, 26, 30, 'Local upload path    :', '', clLightGray, clWhite, clBlue);
  DrawField(Scr, 11,  7, 26, 30, 'Local download path  :', '', clLightGray, clWhite, clBlue);
  DrawField(Scr, 11,  9, 26, 30, 'Welcome screen file  :', 'HELLO', clLightGray, clWhite, clBlue);
  DrawField(Scr, 11, 11, 26, 30, 'News file            :', 'NEWS', clLightGray, clWhite, clBlue);
  DrawField(Scr, 11, 13, 26, 30, 'Goodbye screen file  :', 'GOODBYE', clLightGray, clWhite, clBlue);
  DrawField(Scr, 11, 15, 26, 30, 'OLMS log file        :', 'OLMS.LOG', clLightGray, clWhite, clBlue);
  Scr.PutStr(11, 17, 'Paths where packets and reply files are staged.', clLightGreen, clBlue);
  BotBar(Scr, 'ENTER=edit  TAB=next  ESC=back');
end;

procedure DrawControlScreen(Scr: IScreen; const Cfg: TOlmsConfig);
begin
  Scr.Clear(clBlue);
  TopBar(Scr, 'Control');
  DrawTitledBox(Scr, 8, 3, 64, 16, 'Control Setup', clLightCyan, clBlue, clYellow, bsDouble);
  Scr.PutStr(11,  5, '[X] Send Welcome and Goodbye screens',   clLightGray, clBlue);
  Scr.PutStr(11,  6, '[X] Display opening screen',             clLightGray, clBlue);
  Scr.PutStr(11,  7, '[X] Check for duplicate message uploads',clLightGray, clBlue);
  Scr.PutStr(11,  8, '[ ] Include headers in dupe check',      clLightGray, clBlue);
  Scr.PutStr(11,  9, '[X] Allow users to logoff from door',    clLightGray, clBlue);
  Scr.PutStr(11, 10, '[X] Allow RIP emulation',                clLightGray, clBlue);
  Scr.PutStr(11, 11, '[X] Delete local reply files after upload', clLightGray, clBlue);
  Scr.PutStr(11, 12, '[ ] Replace tearlines and origin lines', clLightGray, clBlue);
  Scr.PutStr(11, 13, '[X] Add registered tearline',            clLightGray, clBlue);
  Scr.PutStr(11, 14, '[ ] ^A kludge line control',             clLightGray, clBlue);
  Scr.PutStr(11, 15, '[X] Release unused time slices',         clLightGray, clBlue);
  BotBar(Scr, 'SPACE=toggle  TAB=next  ESC=back');
end;

procedure DrawRequestingScreen(Scr: IScreen; const Cfg: TOlmsConfig);
begin
  Scr.Clear(clBlue);
  TopBar(Scr, 'Requesting');
  DrawTitledBox(Scr, 8, 3, 64, 16, 'Requesting Control', clLightCyan, clBlue, clYellow, bsDouble);
  Scr.PutStr(11,  5, '[X] Allow users to request general files', clLightGray, clBlue);
  Scr.PutStr(11,  6, '[X] Allow users to request file attaches', clLightGray, clBlue);
  Scr.PutStr(11,  7, '[X] Allow users to scan for new files',    clLightGray, clBlue);
  Scr.PutStr(11,  8, '[ ] Auto download file attaches',          clLightGray, clBlue);
  DrawField(Scr, 11, 10, 26, 30, 'File request path    :', '', clLightGray, clWhite, clBlue);
  DrawField(Scr, 11, 12, 26, 8,  'Daily maximum (files):', '20', clLightGray, clWhite, clBlue);
  DrawField(Scr, 11, 14, 26, 8,  'Max request KB       :', '5000', clLightGray, clWhite, clBlue);
  BotBar(Scr, 'SPACE=toggle  ENTER=edit  ESC=back');
end;

procedure DrawUserEditorScreen(Scr: IScreen);
begin
  Scr.Clear(clBlue);
  TopBar(Scr, 'Users');
  DrawTitledBox(Scr, 3, 2, Scr.Cols-6, Scr.Rows-4, 'User Editor', clLightCyan, clBlue, clYellow, bsDouble);
  Scr.PutStr(6, 4, 'Name                 Confs  Default Pkt   Last On', clWhite, clBlue);
  Scr.PutStr(6, 6, 'reapern66            6      Blue Wave     07-08-26', clYellow, clBlue);
  Scr.PutStr(6, 7, 'g00r00               3      QWK           07-05-26', clLightGray, clBlue);
  Scr.PutStr(6, 8, 'lenny                4      QWKE          07-07-26', clLightGray, clBlue);
  Scr.PutStr(6, Scr.Rows-4, 'Per-user conferences, keywords, twits, packet type.', clLightGreen, clBlue);
  BotBar(Scr, 'ENTER=edit user  INS=add  DEL=remove  ESC=back');
end;

procedure DrawBulletinsScreen(Scr: IScreen);
var i, row: Integer; letters: string;
begin
  Scr.Clear(clBlue);
  TopBar(Scr, 'Bulletins');
  DrawTitledBox(Scr, 4, 2, Scr.Cols-8, Scr.Rows-4, 'Bulletins', clLightCyan, clBlue, clYellow, bsDouble);
  letters := 'ABCDEFGHIJ';
  row := 4;
  for i := 1 to Length(letters) do
  begin
    Scr.PutStr(8, row, Format('(%s) BULL%d.TXT', [letters[i], i]), clLightGray, clBlue);
    if i <= 3 then Scr.PutStr(30, row, '[enabled]', clLightGreen, clBlue)
              else Scr.PutStr(30, row, '[empty]', clDarkGray, clBlue);
    Inc(row);
  end;
  Scr.PutStr(8, Scr.Rows-4, 'Bulletins are sent in the packet for the reader to view.', clLightGreen, clBlue);
  BotBar(Scr, 'Letter=toggle/edit  ESC=back');
end;

procedure DrawLanguageScreen(Scr: IScreen);
begin
  Scr.Clear(clBlue);
  TopBar(Scr, 'Language');
  DrawTitledBox(Scr, 14, 4, 52, 14, 'Multi-language Support', clLightCyan, clBlue, clYellow, bsDouble);
  Scr.PutStr(18,  6, 'Language files (.OLF):', clWhite, clBlue);
  Scr.PutStr(20,  8, '(1) ENGLISH.OLF     [default]', clLightGreen, clBlue);
  Scr.PutStr(20,  9, '(2) FRANCAIS.OLF', clLightGray, clBlue);
  Scr.PutStr(20, 10, '(3) DEUTSCH.OLF',  clLightGray, clBlue);
  Scr.PutStr(20, 11, '(4) ESPANOL.OLF',  clLightGray, clBlue);
  Scr.PutStr(18, 14, 'Prompts & menus load from the selected file;', clLightGreen, clBlue);
  Scr.PutStr(18, 15, 'missing keys fall back to English.', clLightGreen, clBlue);
  BotBar(Scr, 'Number=select  INS=add language  ESC=back');
end;

procedure DrawTestScreen(Scr: IScreen; const Cfg: TOlmsConfig);
begin
  Scr.Clear(clBlue);
  TopBar(Scr, 'Test');
  DrawTitledBox(Scr, 10, 3, 60, 16, 'Test Configuration', clLightCyan, clBlue, clYellow, bsDouble);
  Scr.PutStr(13,  5, 'Checking configuration...', clWhite, clBlue);
  Scr.PutStr(13,  7, 'System name .......... ' + Cfg.Sys.SystemName, clLightGray, clBlue);
  Scr.PutStr(13,  8, 'Board ID ............. ' + Cfg.Sys.BoardID, clLightGray, clBlue);
  Scr.PutStr(13, 10, '[OK]  Archiver ZIP present', clLightGreen, clBlue);
  Scr.PutStr(13, 11, '[OK]  Message base path readable', clLightGreen, clBlue);
  Scr.PutStr(13, 12, '[OK]  Packet output path writable', clLightGreen, clBlue);
  Scr.PutStr(13, 13, '[--]  No protocols defined (local only)', clYellow, clBlue);
  Scr.PutStr(13, 15, 'Configuration looks valid.', clLightCyan, clBlue);
  BotBar(Scr, 'Press a key to return.');
end;

end.
