program config;
{
  OpenOLMS - sysop configuration tool (main program)
  SPDX-License-Identifier: GPL-3.0-or-later
  Copyright (C) 2026  Antonio Rico - Ecstasy BBS / Reapern66
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
  SysUtils, olms_ui, olms_input, olms_config,
  {$IFDEF USE_SDL}
  olms_screen_sdl, olms_kbd_sdl;      // modern (Windows/Linux/macOS) - g00r00 SDL engine
  {$ELSE}
  olms_screen_crt, olms_kbd_console;  // DOS / text console
  {$ENDIF}

var
  {$IFDEF USE_SDL}
  scr : TSdlScreen;
  kbd : TSdlKeyboard;
  {$ELSE}
  scr : TCrtScreen;
  kbd : TConsoleKeyboard;
  {$ENDIF}
  cfg : TOlmsConfig;
  cfgPath : string;

procedure Bar(Y: Integer; const S: string; Fg, Bg: Byte);
begin
  scr.PutStr(0, Y, StringOfChar(' ', scr.Cols-1), Fg, Bg);
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
    scr.PutStr(0,0, StringOfChar(' ',scr.Cols-1), clBlack, clCyan);
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
    scr.PutStr(0,0,StringOfChar(' ',scr.Cols-1),clBlack,clCyan);
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

function IfThenB(cond: Boolean; a, b: Byte): Byte;
begin if cond then Result := a else Result := b; end;

function IfThenAKs(cond: Boolean; const a, b: string): string;
begin if cond then Result := a else Result := b; end;

{ Edit one area's fields: number, name, type (JAM/Hudson), path, board. }
procedure EditArea(ix: Integer);
var k: TKey; field: Integer; done: Boolean;
    num, nm, path, board: string; kind: TAreaKind;
begin
  num := IntToStr(cfg.Areas[ix].Number); nm := cfg.Areas[ix].Name;
  path := cfg.Areas[ix].Path; board := IntToStr(cfg.Areas[ix].Board);
  kind := cfg.Areas[ix].Kind; field := 0; done := False;
  repeat
    scr.Clear(clBlue);
    scr.PutStr(2,0,'Edit Message Area', clBlack, clCyan);
    scr.PutStr(0,0,StringOfChar(' ',scr.Cols-1),clBlack,clCyan);
    scr.PutStr(2,0,'Edit Message Area', clBlack, clCyan);
    DrawTitledBox(scr as IScreen, 10,4,58,14,'Area', clLightCyan, clBlue, clYellow, bsDouble);
    scr.PutStr(13,6, 'Number   :', clLightGray, clBlue); scr.PutStr(26,6, num, clWhite, clBlue);
    scr.PutStr(13,8, 'Name     :', clLightGray, clBlue); scr.PutStr(26,8, nm, clWhite, clBlue);
    scr.PutStr(13,10,'Type     :', clLightGray, clBlue);
    scr.PutStr(26,10, IfThenAKs(kind=akJAM,'JAM (SPACE to toggle)','Hudson (SPACE to toggle)'), clYellow, clBlue);
    scr.PutStr(13,12,'Path/base:', clLightGray, clBlue); scr.PutStr(26,12, path, clWhite, clBlue);
    scr.PutStr(13,14,'Board #  :', clLightGray, clBlue); scr.PutStr(26,14, board, clWhite, clBlue);
    scr.PutStr(13,16,'(Board # only used for Hudson)', clLightGreen, clBlue);
    Bar(scr.Rows-1,'TAB=next  SPACE=toggle type  ENTER=save  ESC=cancel', clBlack, clCyan);
    case field of
      0: begin scr.PutStr(13,6,'Number   :',clLightGray,clBlue);
               num := EditField(scr as IScreen, kbd as IKeyboard, 26,6,6, num, clWhite, clBlue, k); end;
      1: begin scr.PutStr(13,8,'Name     :',clLightGray,clBlue);
               nm := EditField(scr as IScreen, kbd as IKeyboard, 26,8,25, nm, clWhite, clBlue, k); end;
      2: begin k := kbd.ReadKey;
               if (k.Code = kcChar) and (k.Ch = ' ') then
                 begin if kind=akJAM then kind:=akHudson else kind:=akJAM; end; end;
      3: begin scr.PutStr(13,12,'Path/base:',clLightGray,clBlue);
               path := EditField(scr as IScreen, kbd as IKeyboard, 26,12,40, path, clWhite, clBlue, k); end;
      4: begin scr.PutStr(13,14,'Board #  :',clLightGray,clBlue);
               board := EditField(scr as IScreen, kbd as IKeyboard, 26,14,6, board, clWhite, clBlue, k); end;
    end;
    if k.Code = kcEsc then Exit
    else if k.Code = kcEnter then done := True
    else begin Inc(field); if field > 4 then field := 0; end;
  until done;
  cfg.Areas[ix].Number := StrToIntDef(num, cfg.Areas[ix].Number);
  cfg.Areas[ix].Name := nm; cfg.Areas[ix].Kind := kind;
  cfg.Areas[ix].Path := path; cfg.Areas[ix].Board := StrToIntDef(board, 0);
  cfg.Areas[ix].Active := True;
end;

procedure ScreenAreas;
var k: TKey; sel, i, top: Integer; done: Boolean; kindStr: string;
begin
  sel := 0; top := 0; done := False;
  repeat
    scr.Clear(clBlue);
    scr.PutStr(0,0,StringOfChar(' ',scr.Cols-1),clBlack,clCyan);
    scr.PutStr(2,0,'OpenOLMS Configuration', clBlack, clCyan);
    scr.PutStr(scr.Cols-16,0,'Message Areas', clBlack, clCyan);
    DrawTitledBox(scr as IScreen, 3,2,scr.Cols-6,scr.Rows-4,'Message Areas', clLightCyan, clBlue, clYellow, bsDouble);
    scr.PutStr(6,4,'Num  Name                      Type    Path', clWhite, clBlue);
    for i := 0 to cfg.AreaCount-1 do
    begin
      if i < top then Continue;
      if 6 + (i-top) > scr.Rows-6 then Break;
      if cfg.Areas[i].Kind = akJAM then kindStr := 'JAM' else kindStr := 'Hudson';
      scr.PutStr(6, 6+(i-top),
        Format('%-4d %-25s %-7s %s', [cfg.Areas[i].Number,
               Copy(cfg.Areas[i].Name,1,25), kindStr, Copy(cfg.Areas[i].Path,1,20)]),
        IfThenB(i=sel, clYellow, clLightGray), clBlue);
    end;
    Bar(scr.Rows-1, 'UP/DN select  E=edit  A=add  D=delete  ESC=back', clBlack, clCyan);
    k := kbd.ReadKey;
    case k.Code of
      kcEsc: done := True;
      kcUp: if sel > 0 then Dec(sel);
      kcDown: if sel < cfg.AreaCount-1 then Inc(sel);
      kcChar:
        case UpCase(k.Ch) of
          'A': if cfg.AreaCount < MAX_AREAS then
               begin
                 FillChar(cfg.Areas[cfg.AreaCount], SizeOf(TMsgArea), 0);
                 cfg.Areas[cfg.AreaCount].Number := cfg.AreaCount+1;
                 cfg.Areas[cfg.AreaCount].Name := 'New Area';
                 cfg.Areas[cfg.AreaCount].Kind := akJAM;
                 cfg.Areas[cfg.AreaCount].Path := 'AREA' + IntToStr(cfg.AreaCount+1);
                 cfg.Areas[cfg.AreaCount].Active := True;
                 sel := cfg.AreaCount; Inc(cfg.AreaCount);
                 EditArea(sel);
               end;
          'E': if cfg.AreaCount > 0 then EditArea(sel);
          'D': if cfg.AreaCount > 0 then
               begin
                 for i := sel to cfg.AreaCount-2 do cfg.Areas[i] := cfg.Areas[i+1];
                 Dec(cfg.AreaCount);
                 if sel >= cfg.AreaCount then sel := cfg.AreaCount-1;
                 if sel < 0 then sel := 0;
               end;
        end;
    end;
  until done;
end;

function MenuChoice: Integer;
var k: TKey;
begin
  scr.Clear(clBlue);
  scr.PutStr(0,0,StringOfChar(' ',scr.Cols-1),clBlack,clCyan);
  scr.PutStr(2,0,'OpenOLMS Configuration', clBlack, clCyan);
  DrawTitledBox(scr as IScreen, 24,3,32,15,'Configuration', clLightCyan, clBlue, clYellow, bsDouble);
  scr.PutStr(28,6, '(1) System Information', clLightGray, clBlue);
  scr.PutStr(28,8, '(2) Archiver Programs', clLightGray, clBlue);
  scr.PutStr(28,10,'(3) Limits', clLightGray, clBlue);
  scr.PutStr(28,11,'(4) Message Areas', clLightGray, clBlue);
  scr.PutStr(28,13,'(S) Save and exit', clYellow, clBlue);
  scr.PutStr(28,14,'(Q) Quit without saving', clLightRed, clBlue);
  Bar(scr.Rows-1,'Config: ' + cfgPath, clBlack, clCyan);
  repeat
    k := kbd.ReadKey;
    if k.Code = kcChar then
      case UpCase(k.Ch) of
        '1': Exit(1); '2': Exit(2); '3': Exit(3); '4': Exit(4);
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
    scr.PutStr(0,0,StringOfChar(' ',scr.Cols-1),clBlack,clCyan);
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

  {$IFDEF USE_SDL}
  scr := TSdlScreen.Create('OpenOLMS Configuration');
  kbd := TSdlKeyboard.Create;
  {$ELSE}
  scr := TCrtScreen.Create(80, 25);
  kbd := TConsoleKeyboard.Create;
  {$ENDIF}
  running := True;
  try
    while running do
    begin
      choice := MenuChoice;
      case choice of
        1: ScreenSystemInfo;
        2: ScreenArchiver;
        3: ScreenLimits;
        4: ScreenAreas;
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
