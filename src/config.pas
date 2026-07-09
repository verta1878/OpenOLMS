program config;
{
  OpenOLMS - sysop configuration tool (main program)
  SPDX-License-Identifier: GPL-3.0-or-later
  Copyright (C) 2026  Antonio Rico / Ecstasy BBS (github.com/verta1878)
  Distributed under the GNU General Public License v3 or later. See LICENSE.
  Built in Free Pascal from published format specifications.
}

{ Interactive configuration editor. Loads OLMS.CFG (or defaults if absent),
  lets the sysop edit settings on live screens, and saves OLMS.CFG — the same
  file olms.exe reads. Uses the live CRT screen + keyboard backends.

  Usage:  CONFIG            edit ./OLMS.CFG
          CONFIG <path>     edit <path>\OLMS.CFG }

{$MODE OBJFPC}{$H+}

uses
  SysUtils, olms_ui, olms_screen_crt, olms_input, olms_kbd_console, olms_config;

var
  scr : TCrtScreen;
  kbd : TConsoleKeyboard;
  cfg : TOlmsConfig;
  cfgPath : string;

procedure Bar(Y: Integer; const S: string; Fg, Bg: Byte);
begin
  scr.PutStr(0, Y, StringOfChar(' ', scr.Cols), Fg, Bg);
  scr.PutStr(2, Y, S, Fg, Bg);
end;

{ Edit a labelled field in place; returns the key that ended editing. }
function EditRow(Y, labelW, fieldW: Integer; const lbl: string;
                 var value: string): TKey;
var k: TKey;
begin
  scr.PutStr(11, Y, lbl, clLightGray, clBlue);
  value := EditField(scr as IScreen, kbd as IKeyboard,
                     11 + labelW, Y, fieldW, value, clWhite, clBlue, k);
  Result := k;
end;

procedure ScreenSystemInfo;
var k: TKey; done: Boolean; field: Integer;
    s, sy, bid, ph, gw: string;
begin
  s := cfg.Sys.SystemName; sy := cfg.Sys.SysopName; bid := cfg.Sys.BoardID;
  ph := cfg.Sys.Phone; gw := cfg.Sys.Gateway;
  field := 0; done := False;
  repeat
    scr.Clear(clBlue);
    scr.PutStr(0,0, StringOfChar(' ',scr.Cols), clBlack, clCyan);
    scr.PutStr(2,0,'OpenOLMS Configuration', clBlack, clCyan);
    scr.PutStr(scr.Cols-14,0,'System Info', clBlack, clCyan);
    DrawTitledBox(scr as IScreen, 8,3,64,16,'System Information', clLightCyan, clBlue, clYellow, bsDouble);
    // draw current values (the active field will be re-entered for editing)
    scr.PutStr(11,5, 'System name  :', clLightGray, clBlue); scr.PutStr(31,5, s,   clWhite, clBlue);
    scr.PutStr(11,7, 'Sysop name   :', clLightGray, clBlue); scr.PutStr(31,7, sy,  clWhite, clBlue);
    scr.PutStr(11,9, 'Board ID     :', clLightGray, clBlue); scr.PutStr(31,9, bid, clWhite, clBlue);
    scr.PutStr(11,11,'Phone number :', clLightGray, clBlue); scr.PutStr(31,11,ph,  clWhite, clBlue);
    scr.PutStr(11,13,'Gateway addr :', clLightGray, clBlue); scr.PutStr(31,13,gw,  clWhite, clBlue);
    scr.PutStr(11,16,'TAB/ENTER = next field, ESC = back to menu', clLightGreen, clBlue);
    Bar(scr.Rows-1, 'Editing System Information', clBlack, clCyan);

    case field of
      0: k := EditRow(5, 20, 34, 'System name  :', s);
      1: k := EditRow(7, 20, 34, 'Sysop name   :', sy);
      2: k := EditRow(9, 20, 8,  'Board ID     :', bid);
      3: k := EditRow(11,20, 20, 'Phone number :', ph);
      4: k := EditRow(13,20, 34, 'Gateway addr :', gw);
    end;

    if k.Code = kcEsc then done := True
    else if k.Code = kcUp then begin if field > 0 then Dec(field); end
    else begin Inc(field); if field > 4 then field := 0; end;
  until done;

  cfg.Sys.SystemName := s; cfg.Sys.SysopName := sy; cfg.Sys.BoardID := bid;
  cfg.Sys.Phone := ph; cfg.Sys.Gateway := gw;
end;

procedure ScreenArchiver;
var k: TKey; comp, decomp: string; field: Integer; done: Boolean;
begin
  comp := cfg.Archivers[0].Compress; decomp := cfg.Archivers[0].Decompress;
  if cfg.Archivers[0].Tag = '' then cfg.Archivers[0].Tag := 'ZIP';
  field := 0; done := False;
  repeat
    scr.Clear(clBlue);
    scr.PutStr(2,0,'OpenOLMS Configuration', clBlack, clCyan);
    scr.PutStr(0,0,StringOfChar(' ',scr.Cols),clBlack,clCyan);
    scr.PutStr(2,0,'OpenOLMS Configuration', clBlack, clCyan);
    scr.PutStr(scr.Cols-12,0,'Archiver', clBlack, clCyan);
    DrawTitledBox(scr as IScreen, 4,3,scr.Cols-8,14,'Archiver Programs', clLightCyan, clBlue, clYellow, bsDouble);
    scr.PutStr(7,5, 'Tag: ' + cfg.Archivers[0].Tag, clYellow, clBlue);
    scr.PutStr(7,7, 'Compress   :', clLightGray, clBlue); scr.PutStr(20,7, comp, clWhite, clBlue);
    scr.PutStr(7,9, 'Decompress :', clLightGray, clBlue); scr.PutStr(20,9, decomp, clWhite, clBlue);
    scr.PutStr(7,12,'Point these at your archiver, e.g.  PKZIP.EXE -ex  /  PKUNZIP.EXE -o', clLightGreen, clBlue);
    scr.PutStr(7,13,'%ARCHIVE% = the .QWK,  %FILES% = the packet files.', clLightGreen, clBlue);
    Bar(scr.Rows-1,'Editing Archiver  (TAB=next, ESC=back)', clBlack, clCyan);
    case field of
      0: begin scr.PutStr(7,7,'Compress   :',clLightGray,clBlue);
               comp := EditField(scr as IScreen, kbd as IKeyboard, 20,7,58, comp, clWhite, clBlue, k); end;
      1: begin scr.PutStr(7,9,'Decompress :',clLightGray,clBlue);
               decomp := EditField(scr as IScreen, kbd as IKeyboard, 20,9,58, decomp, clWhite, clBlue, k); end;
    end;
    if k.Code = kcEsc then done := True
    else begin Inc(field); if field > 1 then field := 0; end;
  until done;
  cfg.Archivers[0].Compress := comp; cfg.Archivers[0].Decompress := decomp;
end;

function MenuChoice: Integer;
var k: TKey;
begin
  scr.Clear(clBlue);
  scr.PutStr(0,0,StringOfChar(' ',scr.Cols),clBlack,clCyan);
  scr.PutStr(2,0,'OpenOLMS Configuration', clBlack, clCyan);
  DrawTitledBox(scr as IScreen, 24,3,32,15,'Configuration', clLightCyan, clBlue, clYellow, bsDouble);
  scr.PutStr(28,6, '(1) System Information', clLightGray, clBlue);
  scr.PutStr(28,8, '(2) Archiver Programs', clLightGray, clBlue);
  scr.PutStr(28,10,'(3) Limits', clLightGray, clBlue);
  scr.PutStr(28,13,'(S) Save and exit', clYellow, clBlue);
  scr.PutStr(28,14,'(Q) Quit without saving', clLightRed, clBlue);
  Bar(scr.Rows-1,'Config: ' + cfgPath, clBlack, clCyan);
  repeat
    k := kbd.ReadKey;
    if k.Code = kcChar then
      case UpCase(k.Ch) of
        '1': Exit(1); '2': Exit(2); '3': Exit(3);
        'S': Exit(100); 'Q': Exit(101);
      end
    else if k.Code = kcEsc then Exit(101);
  until False;
end;

procedure ScreenLimits;
var k: TKey; mm, mk, mc: string; field: Integer; done: Boolean;
begin
  mm := IntToStr(cfg.Limits.MaxMessages); mk := IntToStr(cfg.Limits.MaxPacketKB);
  mc := IntToStr(cfg.Limits.MaxConfs); field := 0; done := False;
  repeat
    scr.Clear(clBlue);
    scr.PutStr(0,0,StringOfChar(' ',scr.Cols),clBlack,clCyan);
    scr.PutStr(2,0,'OpenOLMS Configuration', clBlack, clCyan);
    DrawTitledBox(scr as IScreen, 12,4,56,12,'Limits Setup', clLightCyan, clBlue, clYellow, bsDouble);
    scr.PutStr(15,6, 'Max messages / packet :', clLightGray, clBlue); scr.PutStr(40,6, mm, clWhite, clBlue);
    scr.PutStr(15,8, 'Max packet size (KB)  :', clLightGray, clBlue); scr.PutStr(40,8, mk, clWhite, clBlue);
    scr.PutStr(15,10,'Max conferences       :', clLightGray, clBlue); scr.PutStr(40,10,mc, clWhite, clBlue);
    scr.PutStr(15,13,'0 = unlimited.  TAB=next, ESC=back', clLightGreen, clBlue);
    Bar(scr.Rows-1,'Editing Limits', clBlack, clCyan);
    case field of
      0: begin scr.PutStr(15,6,'Max messages / packet :',clLightGray,clBlue);
               mm := EditField(scr as IScreen, kbd as IKeyboard, 40,6,10, mm, clWhite, clBlue, k); end;
      1: begin scr.PutStr(15,8,'Max packet size (KB)  :',clLightGray,clBlue);
               mk := EditField(scr as IScreen, kbd as IKeyboard, 40,8,10, mk, clWhite, clBlue, k); end;
      2: begin scr.PutStr(15,10,'Max conferences       :',clLightGray,clBlue);
               mc := EditField(scr as IScreen, kbd as IKeyboard, 40,10,10, mc, clWhite, clBlue, k); end;
    end;
    if k.Code = kcEsc then done := True
    else begin Inc(field); if field > 2 then field := 0; end;
  until done;
  cfg.Limits.MaxMessages := StrToIntDef(mm, cfg.Limits.MaxMessages);
  cfg.Limits.MaxPacketKB := StrToIntDef(mk, cfg.Limits.MaxPacketKB);
  cfg.Limits.MaxConfs    := StrToIntDef(mc, cfg.Limits.MaxConfs);
end;

var dir: string; choice: Integer; running: Boolean;
begin
  dir := GetCurrentDir;
  if ParamCount >= 1 then dir := ParamStr(1);
  cfgPath := IncludeTrailingPathDelimiter(dir) + 'OLMS.CFG';

  cfg := TOlmsConfig.Create;
  cfg.Load(cfgPath);   // defaults if absent

  scr := TCrtScreen.Create(80, 25);
  kbd := TConsoleKeyboard.Create;
  running := True;
  try
    while running do
    begin
      choice := MenuChoice;
      case choice of
        1: ScreenSystemInfo;
        2: ScreenArchiver;
        3: ScreenLimits;
        100: begin
               if cfg.Save(cfgPath) then
               begin scr.Clear(clBlue); scr.PutStr(2,2,'Saved '+cfgPath, clLightGreen, clBlue); end
               else begin scr.Clear(clBlue); scr.PutStr(2,2,'ERROR saving '+cfgPath, clLightRed, clBlue); end;
               scr.PutStr(2,4,'Press a key...', clLightGray, clBlue);
               kbd.ReadKey; running := False;
             end;
        101: running := False;
      end;
    end;
  finally
    scr.Clear(clBlack);
    scr.PlaceCursor(0,0);
    kbd.Free; scr.Free; cfg.Free;
  end;
end.
