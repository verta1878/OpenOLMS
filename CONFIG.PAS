Program OLMS_CFG;

{$I d:\develop\olms2k\BBSTYPE.INC}

{$IFDEF BBS_RA2}
Uses DM6000, INTERFAC, Dos, Crt, JAMCRC32, U_UNIT, U_NEW, U_REG, U_LANG, FHANDLES;
{$ENDIF}

{$IFDEF BBS_RA1}
Uses C_RA111, DM6000, INTERFAC, Dos, Crt, JAMCRC32, U_UNIT, U_NEW, U_REG, U_LANG, HANDLES;
{$ENDIF}

{$R}
{$V-}

{$M 20000,192000,192000}

Const
  AreaRange = 2000;
  LangSizeMax = 29000;

Type
  LANGUAGErecord = Record
                     Name           : String[20];
                     Attribute      : Byte;
                     DefName,
                     MenuPath,
                     TextPath,
                     QuesPath       : String[60];
                     Security       : Word;
                     Flags,
                     NotFlagsMask   : Array[1..4] Of Byte;
                     FreeSpace      : Array[1..190] of Byte;
                   End;

  pStr40 = ^tStr40;
  tStr40 = String[25];
  RPbuf = ^RTbuf;
  RTbuf = String[160];
  LanguageTextType = Array[1..MaxLang] Of RPbuf;

  pAreaNumbers = ^tAreaNumbers;
  tAreaNumbers = Array[1..AreaRange] Of Word;

  pAreaNames = ^tAreaNames;
  tAreaNames = Array[1..AreaRange] Of pStr40;

  pSETUPrecord = ^SETUPrecord;


Var
  HotKeys: Array[1..24] Of Char;
  RADir, MainDir: String[128];
  RALName: Array[0..14] Of String[20];
  OLF: Array[0..14] Of OLFrecord;
  Keys: Array[1..MaxLang] Of Char;
  HighSize, SIZE_USERS, ZMaxAreas: Word;
  AreaNames: pAreaNames;
  AreaNumbers: pAreaNumbers;
  MaxNodes: Byte;
  UserAreas: Word;
  LanguageText: Array[1..2] Of LanguageTextType;
  RA250, Reg: Boolean;
  ArcString, ProtString: String[10];
  SetupVersion: String[40];
  Setup: pSETUPrecord;
  LNGCRC, CFGCRC: Longint;
  GRegs: Registers;
  MainCounter: Word;
  Saved: Pointer;
  BBS_CC: String[5];

Function YN(b: Boolean): String;
Begin
  If b Then YN := 'Yes' Else YN := 'No ';
End;

Procedure ClearHalt;
Begin
  SetColor(Lightgray);
  Window(1,1,80,25);
  Clrscr;
  CursorView;
  Halt;
End;

Procedure Note1(st: String);
Begin
  StoreScreen(4);
  DrawWindow(10,12,70,14,White+Red*16);
  WriteCenterString(56,' '+st);
End;

Procedure Note2;
Begin
  RestoreScreen(4);
  TextAttr := 7;
End;

Procedure Note(st: String);
Begin
  Note1(st);
  Readkey;
  Note2;
End;

Function Warning_ChangeAreas: Char;
Var
  Key: Char;
Begin
  StoreScreen(4);
  DrawWindow(7,6,73,18,White+Red*16);
  WriteLines(1);
  SetColor(Yellow+64);
  WriteCenterString(64,'WARNING          << Advanced Command >>          WARNING');
  WriteLines(1);
  SetColor(White+64);
  WriteCenterString(64,'Changing this value restructurizes the size of USERS.DAT');
  WriteCenterString(64,'USERS.INF and the OLMS.CFG file.   If you restore from a');
  WriteCenterString(64,'backup,  make sure that all files are restored properly.');
  WriteCenterString(64,'Having non-syncronized files will certainly cause you to');
  WriteCenterString(64,'experience operational errors.                          ');
  WriteLines(1);
  WriteCenterString(64,'Continue with changes? (yes/No)');
  Repeat
    Key := Upcase(Readkey);
  Until Key In ['Y','N',#13,#27];
  Warning_ChangeAreas := Key;
  TextAttr := 7;
  RestoreScreen(4);
End;

Procedure Change_Areas(osize, nsize:Word);
Var
  fUSRDAT, fo, fn: File;
  OLDSIZE_USERS: Word;
  U: USERrecord;
Begin
  OLDSIZE_USERS := SIZE_USERS;
  UserAreas := nsize;
  If UserAreas>MaxAreas Then UserAreas := MaxAreas;
  SIZE_USERS := Sizeof(USERrecord) - (MaxAreas-UserAreas);
  If SizeofFile(MainDir+'USERS.DAT') MOD OLDSIZE_USERS <> 0 Then
    Begin
      Note('<!> USERS.INF corrupt size mismatch');
      ClearHalt;
    End;
  If UserAreas<HighSize Then
    Begin
      Note1('Warning! Supported areas is less than actual high area');
      Sleep(3);
      Note2;
    End;
  If Not OpenFile(fo,'USERS.DAT','R',OLDSIZE_USERS,faReadOnly+faDenyNone) Then
    Begin
      Note('Error: Cannot open USERS.DAT');
      ClearHalt;
    End;
  If Not OpenFile(fn,'USERS.NEW','W',SIZE_USERS,faReadWrite+faDenyAll) Then
    Begin
      CloseFile(fo);
      Note('Error: Cannot create USERS.NEW');
      ClearHalt;
    End;

  Note1('Converting users');
  While Not Eof(fo) Do
    Begin
      FillChar(U,Sizeof(U),0);
      BlockRead(fo,U,1);
      BlockWrite(fn,U,1);
      WriteString(#13+'       Converting ÍÍ '+SpacePad(U.Name,35));
    End;
  CloseFile(fn);
  CloseFile(fo);
  Erase(fo);
  Rename(fn,'USERS.DAT');
  If OpenFile(fUSRDAT,MainDir+'USERS.INF','W',1,faWriteOnly+faDenyNone) Then
    Begin
      BlockWrite(fUSRDAT,UserAreas,2);
      CloseFile(fUSRDAT);
    End;
  Note2;
  Note('Conversion Complete');
End;

Procedure Bullet(S: String);
Var
  A: Byte;
Begin
  Setcolor(Lightcyan);
  Write(' þ ');
  SetColor(White);
  Write(S);
  SetColor(Lightgray);
  Write(' ');
  For A := Length(S) To 54 Do Write('ú');
  Write(' ');
End;

Function IsPossible(S: String): Boolean;
Begin
  IsPossible := False;
  If S = '' Then Exit;
  If FileExists(S) Then
    Begin
      IsPossible := True;
      Exit;
    End;
  If CreateFile(S) Then
    Begin
      KillFile(S);
      IsPossible := True;
      Exit;
    End;
End;

Procedure Pass;
Begin
  Setcolor(Lightgreen);
  Writeln('Pass');
End;

Procedure Fail;
Begin
  Setcolor(Lightred);
  Writeln('Fail');
End;

Function FileNameOf(st: String): String;
Begin
  If Pos(' ',st) = 0 Then FileNameOf := st
  Else FileNameOf := Copy(st,1,Pos(' ',st)-1);
End;

Function CanRun(st: String): Boolean;
Var
  p, t: String;
Begin
  st := FileNameOf(st);

  If Pos('\',st) <> 0 Then CanRun := FileExists(st)
  Else If Pos(':',st) <> 0 Then CanRun := FileExists(st)
  Else
    Begin
      p := GetEnv('PATH');
      CanRun := False;
      While p <> '' Do
        Begin
          If Pos(';',p) <> 0 Then t := Copy(p,1,Pos(';',p)-1)
          Else t := p;
          If t = p Then p := '' Else p := Copy(p,Length(t)+2,255);
          If t[Length(t)] <> '\' Then t := t + '\';
          If FileExists(t+st) Then CanRun := True;
        End;
    End;
End;

Function SpacePad(st: String; Len:Byte): String;
Begin
  SpacePad := Copy(st,1,Len) +
              Copy('                                        ',1,Len-Length(st));
End;

Procedure CheckFile(Name: String);
Begin
   If Pos(' ',Name) <> 0 Then Name := Copy(Name,1,Pos(' ',Name)-1);
   If Name='' Then Exit;
   If Not FileExists(Name) Then
     Begin
      StoreScreen(4);
      Drawwindow(20,11,60,15,Darkgray+Lightgray*16);
      Window(22,12,59,15);
      SetColor(White+Lightgray*16);
      CenterString(40,'WARNING');
      SetColor(Darkgray+Lightgray*16);
      CenterString(40,Copy(Name,1,36));
      SetColor(White+Lightgray*16);
      If Pos('*',Name) = 0 Then CenterString(40,'File does not exist')
      Else CenterString(40,'File may not exist when expanded');
      Repeat Until Readkey = #27;
      RestoreScreen(4);
      SetColor(White);
     End;
End;

Procedure CheckRun(Name: String);
Begin
   If Pos(' ',Name) <> 0 Then Name := Copy(Name,1,Pos(' ',Name)-1);
   If Name = '' Then Exit;
   If Not CanRun(Name) Then
     Begin
      StoreScreen(4);
      Drawwindow(20,11,60,15,Darkgray+Lightgray*16);
      Window(22,12,59,15);
      SetColor(White+Lightgray*16);
      CenterString(40,'WARNING');
      SetColor(Darkgray+Lightgray*16);
      CenterString(40,Copy(Name,1,36));
      SetColor(White+Lightgray*16);
      If Pos('*',Name) = 0 Then CenterString(40,'Cannot locate file!')
      Else CenterString(40,'File may not exist when expanded');
      Repeat Until Readkey = #27;
      RestoreScreen(4);
      SetColor(White);
     End;
End;

Procedure CheckPath(Name: String);
Var
   OldDir: String;
Begin
   If Name='' Then Exit;
   GetDir(0,OldDir);
   Name := GetPath(Name);
   If (Length(Name)>3) And (Name[Length(Name)] = '\') Then Name := Copy(Name,1,Length(Name)-1);
   If Not ChangeDirectory(Name) Then
     Begin
      StoreScreen(4);
      Drawwindow(20,11,60,15,Darkgray+Lightgray*16);
      Window(22,12,59,15);
      SetColor(White+Lightgray*16);
      CenterString(40,'WARNING');
      SetColor(Darkgray+Lightgray*16);
      CenterString(40,Copy(Name,1,36));
      SetColor(White+Lightgray*16);
      If Pos('*',Name) = 0 Then CenterString(40,'Path does not exist')
      Else CenterString(40,'Path may not exist when expanded');
      Repeat Until Readkey = #27;
      RestoreScreen(4);
     End;
   ChangeDirectory(OldDir);
End;

Procedure LoadConfig;
Const
 MaxRecords = 10;
Var
 Records, Loop: Word;
 dCTL: Array[1..MaxRecords] Of MESSAGErecord;
 fCTL: File;
 fRACFG: File;
 dRACFG: CONFIGrecord;
 Locked: Boolean;
 Handle: Integer;
 f: File;
 ff: File;
 st: String;
 w, Conf: Word;
 c, by: Byte;
Begin
{$IFDEF BBS_RA2}
  st := GetEnv('RA');
  If st = '' Then
    Begin
      ClrScr;
      Writeln;
      Writeln('Enviroment variable "RA" not set!');
      Sleep(3);
      Halt;
    End;
  PutTrail(st);
  BBS_CC := 'RA';
{$ELSE}
  st := MainDir;
  BBS_CC := 'CC';
{$ENDIF}
  RADir := st;

  KillFile(MainDir+'LOCKTEST.$$$');
  CreateFile(MainDir+'LOCKTEST.$$$');
  Handle := OpenHandle(MainDir+'LOCKTEST.$$$');
  If Handle > 0 Then
    Begin
      Locked := LockHandle(Handle,1,0,True);
      If Locked Then LockHandle(Handle,1,0,False);
      CloseHandle(Handle);
    End;
  KillFile(MainDir+'LOCKTEST.$$$');

  If (Handle=-1) Or (SizeofFile(MainDir+'OLMS.CFG') <> Sizeof(SETUPrecord)) Then
    Begin
      If Handle=-1 Then Note('Can not write to current directory')
      Else Note('Incorrect OLMS.CFG version');
      ClearHalt;
    End;

  {$IFDEF BBS_RA2}
  If FileExists(st+'MESSAGES.RDX') Then RA250 := True;
  {$ENDIF}

  If  OpenFile(f,MainDir+'OLMS.CFG','R',Sizeof(SETUPrecord),faNormal)
  And OpenFile(fRACFG,st+'CONFIG.'+BBS_CC,'R',Sizeof(CONFIGrecord),faNormal)
  And OpenFile(fCTL,st+'MESSAGES.'+BBS_CC,'R',Sizeof(MESSAGErecord),faNormal)
  Then
    Begin
      HighSize := FileSize(fCTL);
      Note1('Scanning Message Configuration');
      BlockRead(f,Setup^,1);
      BlockRead(fRACFG,dRACFG,1);

{     If Setup^.Serial[1] = 'E' Then MaxNodes := 250
      Else If Setup^.Serial[1] = 'Q' Then MaxNodes := 10
      Else MaxNodes := 3; }
      MaxNodes := 250;

      If Setup^.GoodValue = 0 Then
        Begin
          Setup^.SystemName := dRACFG.SystemName;
          Setup^.Sysop      := dRACFG.Sysop;
          Setup^.GoodValue  := 2002;
        End;

      If Setup^.GoodValue < 2511 Then
        Begin
          Setup^.NetmailCrash  := 65535;
          Setup^.NetmailFatch  := 65535;
          Setup^.NetmailHold   := 65535;
          Setup^.NetmailImm    := 65535;
          Setup^.NetmailFreq   := 65535;
          Setup^.NetmailDirect := 65535;
          Setup^.Gloat         := True;
          Setup^.GoodValue     := 2511;
        End;

      If Setup^.GoodValue < 2522 Then
        Begin
          Setup^.MinuteCol     := 7;
          Setup^.GoodValue     := 2522;
        End;

      CloseFile(f);
      CloseFile(fRACFG);

      If Setup^.Version < 200 Then
        Begin
          Note('Configuration version mismatch, run conversion tools first');
          ClearHalt;
        End;

      Setup^.MsgBasePath  := dRACFG.MsgBasePath;  PutTrail(Setup^.MsgBasePath);
      Setup^.NodelistPath := dRACFG.NodelistPath; PutTrail(Setup^.Nodelistpath);
{$IFDEF BBS_RA2}
      Setup^.FileBasePath := dRACFG.FileBasePath; PutTrail(Setup^.FileBasePath);
{$ENDIF}

      Setup^.MainPath := st;
      For by := 0 To 9 Do
        Begin
          Setup^.Address[by].Zone := dRACFG.Address[by].Zone;
          Setup^.Address[by].Net  := dRACFG.Address[by].Net;
          Setup^.Address[by].Node := dRACFG.Address[by].Node;
          Setup^.Address[by].Point:= dRACFG.Address[by].Point;
        End;
      ZMaxAreas := 0;
      Conf := 0;

      CFGCRC := crc32(Setup^,Sizeof(Setuprecord),$FFFFFFFF);

      {$IFDEF PROVERSION}
      If OpenFile(ff,MainDir+'MESSAGES.INF','R',1,faReadOnly+faDenyNone)  Then
        Begin
          BlockRead(ff,w,2);
          BlockRead(ff,HighSize,2);
          BlockRead(ff,w,2);
          CloseFile(ff);
        End;
      {$ENDIF}

      While Not Eof(fCTL) And (ZMaxAreas<AreaRange) Do
        Begin
          BlockRead(fCTL,dCTL,MaxRecords,Records);
          For Loop := 1 To Records Do
            Begin
              Inc(Conf);
              If RA250 Then w := dCTL[Loop].AreaNum Else w := Conf;
              If w > HighSize Then HighSize := w;
              If StripLeadAndTrail(dCTL[Loop].Name)<>'' Then
                Begin
                  Inc(ZMaxAreas);
                  AreaNames^[ZMaxAreas]^ := dCTL[Loop].Name;
                  AreaNumbers^[ZMaxAreas] := w;
                End;
            End;
        End;
      CloseFile(fCTL);
      Note2;
    End
  Else
    Begin
      Writeln('Error opening configuration files!');
      Sleep(3);
      Halt;
    End;

  (* If share was detected, reset singlenode flag to 0 *)
  If Locked Then Setup^.SingleNodeFlag := 0;

  (* If override was selected, then override it *)
  If UpcaseStr(ParamStr(1))='/NOLOCK' Then Setup^.SingleNodeFlag := 200;

  { !!! v2000
  If (Setup^.SingleNodeFlag <> 200) And (Not Locked) Then
    Begin
      StoreScreen(4);
      DrawWindow(10,3,70,23,White+Red*16);
      WriteLines(1);
      WriteCenterString(58,'<WARNING>  No file locking support was detected!');
      WriteCenterString(58,'Such programs as SHARE.EXE are required for file');
      WriteCenterString(58,'locking when using the JAM message base, or when');
      WriteCenterString(58,'running a multinode system.                     ');
      WriteLines(1);
      WriteCenterString(58,'This is not a limitation of OLMS, but a standard');
      WriteCenterString(58,'security measure.                               ');
      WriteLines(1);
      WriteCenterString(58,'It is highly suggested that you load SHARE.EXE  ');
      WriteCenterString(58,'in your AUTOEXEC.BAT file, however if you wish  ');
      WriteCenterString(58,'to override this protection then run the config ');
      WriteCenterString(58,'program with the parameter /NOLOCK to do so...  ');
      WriteLines(1);
      WriteCenterString(58,'For example:  CONFIG.EXE /NOLOCK');
      WriteLines(1);
      WriteCenterString(58,'If at any time OLMS detects file locking ability');
      WriteCenterString(58,'it will reset itself to use this protection.    ');
      Readkey;
      RestoreScreen(4);
      ClearHalt;
    End; }
End;

Procedure WriteConfig;
Var
  f: File;
Begin
  OpenFile(f,MainDir+'OLMS.CFG','W',Sizeof(SETUPrecord),faNormal);
  BlockWrite(f,Setup^,1);
  CloseFile(f);
End;

Function LengthLang(b: Byte): Word;
Var
  c, w: Word;
Begin
  w := 0;
  For c := 1 To MaxLang Do Inc(w,(Length(LanguageText[b][c]^)+1));
  LengthLang := w;
End;

Procedure Language(LName,LPath: String);
Var
  O, L, OO: Word;
  Key: Char;
  C: Byte;
  LangLength: Word;
  stSearch, Temp2, Temp: String;
  Rip, NewOne: Boolean;
Begin
  RestoreScreen(1);
  DrawWindow(2,3,78,16,Lightgray); Window(69,3,79,3); Write('µ      Æ');
  DrawWindow(2,17,78,19,Lightgray); SetColor(LightGray); Write(' Default: ');
  DrawWindow(2,20,40,23,Lightgray);
  Window(5,21,42,22);
  SetColor(LightGray); Write('Name: '); SetColor(White); Writeln(LName);
  SetColor(LightGray); Write('File: '); SetColor(White); Write(Copy(LPath,1,28));
  If Length(LPath)>28 Then Begin SetColor(Lightgray); Write(#26); End;
  DrawWindow(41,20,56,23,Lightgray);
  DrawWindow(57,20,78,23,Lightgray);
  SetColor(LightGray); Writeln(' Text Language [ ]');
  SetColor(LightGray); Write('  RIP Language [ ]');
  Rip := False;
  O := 0;
  L := 0;
  Repeat
  LangLength := LengthLang(Byte(Rip)+1);
  Window(43,21,56,22);
  SetColor(LightGray); Write(' Used: '); SetColor(White); Writeln(LangLength);
  SetColor(LightGray); Write(' Free: '); SetColor(White); Write(Longint(LangSizeMax)-Longint(LangLength));
  Window(75,21,75,22); SetColor(White); ClrScr;
  Window(75,21,76,22); Gotoxy(1,Byte(Rip)+1); Write('û');
  NewOne := False;
  If(LangLength>LangSizeMax) Then Note('Language size exceeds limits');
  TextAttr := White;
  Window(4,4,77,16);
  Repeat
    OO := O;
    TextColor(White);
    For C := 1 To 12 Do
      Begin
        If O+C<20 Then Temp := '('+HotKeys[O+C]+') ' Else Temp := '';
        Gotoxy(3,C); Write(Copy(Temp+LanguageText[Byte(Rip)+1][O+C]^,1,70)); ClrEol;
      End;
    TextColor(Yellow);
    Gotoxy(2,L+1); Write(#26);
    Gotoxy(73,L+1); Write(#27);
    Repeat
      Window(71,3,75,3); SetColor(White); Write('#',ZeroPad(O+L+1,3));
      Window(14,18,77,18);
      SetColor(White);
      Temp := DEFAULTLANG(O+L+1);
      If O+L+1<20 Then Temp := '('+DefaultHotKeys[O+L+1]+') '+Temp;
      If Temp = '' Then Temp := 'Reserved'+Copy(DM_Spaces,1,55);
      Write(Copy(Temp,1,63)+
            Copy('°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°'+
                 '°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°',1,63-Length(Temp)));
      Window(4,4,77,16);
      Key := Upcase(Readkey);
      Gotoxy(2,L+1); Write(' ');
      Gotoxy(73,L+1); Write(' ');
      If Key = #0 Then
        Begin
          Key := Readkey;
          Case Key Of
                   {!! Online Help would be nice}
            #30: Begin
                   StoreScreen(3);
                   DrawWindow(20,10,60,15,Black+Lightgray*16);
                   WriteLines(1);
                   WriteCenterString(38,' Copy the text language set to the');
                   WriteCenterString(38,' the RIP language entries? (y/N)');
                   Repeat
                     Key := Upcase(Readkey);
                   Until Key In ['Y','N',#13,#27];
                   If Key = 'Y' Then
                     Begin
                       For C := 1 To MaxLang Do
                         LanguageText[2][C]^ := LanguageText[1][C]^;
                       NewOne := True;
                     End;
                   RestoreScreen(3);
                   TextAttr := White;
                 End;
            '!': Begin
                   StoreScreen(3);
                   DrawWindow(20,10,60,15,Black+Lightgray*16);
                   WriteCenterString(38,' Search text');
                   WriteLines(1);
                   WriteString('    ');
                   stSearch := '';
                   GetString2(stSearch,30,30,15,Upper);
                   Gotoxy(1,3);
                   SetColor(Black+Lightgray*16);
                   For C := 1 To MaxLang Do
                     Begin
                       Temp := LanguageText[Byte(Rip)+1][C]^;
                       If Pos(stSearch,UpcaseStr(Temp)) <> 0 Then
                         Begin
                           WriteChar(#13);
                           WriteCenterString(37,' '+Copy(Temp,1,25)+', (Y/n)');
                           Key := Upcase(Readkey);
                           If Key <> 'N' Then
                             Begin
                               O := C-1-L;
                               C := MaxLang-1;
                             End;
                         End;
                     End;
                   RestoreScreen(3);
                   TextAttr := White;
                 End;
            ' ': Begin LanguageText[Byte(Rip)+1][L+O+1]^ := DEFAULTLANG(L+O+1); NewOne := True; End;
            #20: Begin Rip := False; NewOne := True; End;
            #19: Begin Rip := True; NewOne := True; End;
            'G': Begin O:= 0; L:=0; End;
            'O': Begin O:= MaxLang-1-12; L:=11; End;
            'I': Begin If O>13 Then Dec(O,12) Else O := 0; L := 0; End;
            'Q': Begin If O<MaxLang-1-24 Then Inc(O,12) Else O := MaxLang-1-12; L := 11; End;
            'P': Begin
                   Inc(L);
                   If L > 11 Then
                     Begin
                       L := 11;
                       If O+12 < MaxLang-1 Then Inc(O);
                     End;
                 End;
            'H': Begin
                   If L = 0 Then
                     Begin
                       L := 0;
                       If O > 0 Then Dec(O);
                     End
                   Else Dec(L);
                 End;
          End;
        End
      Else If Key = #13 Then
        Begin
          If L+O+1 < 25 Then
            Begin
              StoreScreen(3);
              Gotoxy(4,L+1); SetColor(Yellow+Blink); Write('*');
              DrawWindow(20,12,60,14,Lightblue+Blue*16);
              WriteCenterString(36,' Press an option key for this entry');
              Repeat
                HotKeys[L+O+1] := Upcase(Readkey);
              Until HotKeys[L+O+1] In ['A'..'Z','0'..'9','-','/','\','.',':','*',#32,#27,'?','!'];
              RestoreScreen(3);
              Window(4,4,77,16);
            End;
          Gotoxy(3,L+1);
          Temp := LanguageText[Byte(Rip)+1][L+O+1]^;
          Temp2 := Temp;
          GetString2(Temp,250,70,White,Normal);
          If (Temp <> Temp2) Or (L+O+1<20) Then
            Begin
              NewOne := True;
              LanguageText[Byte(Rip)+1][L+O+1]^ := Temp;
            End;
        End;
      Window(4,4,77,16);
      TextColor(Yellow);
      Gotoxy(2,L+1); Write(#26);
      Gotoxy(73,L+1); Write(#27);
      If (Key=#27) And (LangLength>LangSizeMax) Then
        Begin
          Note('Cannot exit while language size exceeds limits');
          Key := #0;
        End;
    Until (Key In [#27]) Or (O<>OO) Or NewOne;
  Until (Key = #27) Or NewOne;
  Until Key = #27;
End;

Procedure ReadLang;
Var
  c: Byte;
  fOLF: File;
  fRAL: File;
  dRAL: LANGUAGErecord;
Begin
  FillChar(OLF,Sizeof(OLF),0);
  FillChar(RALName,Sizeof(RALName),0);
  If OpenFile(fOLF,Maindir+'LANGUAGE.DAT','R',1,faNormal) Then
    Begin
      {$I-} BlockRead(fOLF,OLF,Sizeof(OLF)); {$I+}
      CloseFile(fOLF);
    End;
  If OpenFile(fRAL,RADir+'LANGUAGE.RA','R',Sizeof(LANGUAGErecord),faNormal) Then
    Begin
      c := 0;
      While (c<15) And Not Eof(fRAL) Do
        Begin
          {$I-}
          BlockRead(fRAL,dRAL,1);
          {$I+}
          If IoResult=0 Then
            Begin
              RALName[c] := Copy(dRAL.Name,1,20);
              Inc(c);
            End;
        End;
      CloseFile(fRAL);
    End;
  LNGCRC := Crc32(OLF,Sizeof(OLF),$FFFFFFFF);
End;

Procedure WriteLang(Force: Boolean);
Var
  fOLF: File;
  Key: Char;
Begin
  If Force Or (LNGCRC <> Crc32(OLF,Sizeof(OLF),$FFFFFFFF)) Then
  Begin
  If Not Force Then
  Begin
  DrawWindow(22,11,58,15,Black+Lightgray*16);
  Writeln;
  WriteCenterString(34,' Save changes? (Y/n)');
  Key := Upcase(Readkey);
  End Else Key := 'Y';
  LNGCRC := Crc32(OLF,Sizeof(OLF),$FFFFFFFF);
  If (Key <> 'N') Then
    Begin
      If OpenFile(fOLF,Maindir+'LANGUAGE.DAT','W',1,faNormal) Then
        Begin
          {$I-} BlockWrite(fOLF,OLF,Sizeof(OLF)); {$I+}
          CloseFile(fOLF);
        End
    End
  Else ReadLang;
  End;
End;

Function LoadLanguageText(n: Byte): Boolean;
Var
  f: File;
  c: Word;
  b: Byte;
  tmp, st, s: String;
Begin
  st := OLF[n].Filename;
  LoadLanguageText := False;
  If st = '' Then
    Begin
      Note('Cannot edit text until "Filename" is filled');
      Exit;
    End;
  If Not OpenFile(f,st,'R',1,faNormal) Then
    Begin
      If Not CreateFile(st) Then
        Begin
          Note('Cannot create the language file');
          Exit;
        End
      Else KillFile(st);
      For c := 1 To MaxLang Do LanguageText[1][c]^ := DEFAULTLANG(c);
      For c := 1 To MaxLang Do LanguageText[2][c]^ := DEFAULTLANG(c); {RIP}
      For c := 1 To 24 Do HotKeys[c] := DefaultHotKeys[c];
      DayToDate(PresentDay,OLF[n].DateMade);
    End
  Else
    Begin
      For c := 1 To MaxLang Do
        Begin
          BlockRead(f,b,1);
          BlockRead(f,tmp[1],b);
          tmp[0] := Chr(b);
          LanguageText[1][c]^ := Copy(tmp,1,160);
        End;
      BlockRead(f,b,1);
      If b <> 72 Then
        Begin
          CloseFile(f);
          Note('Corrupt language file');
          Exit;
        End;
      For c := 1 To MaxLang Do
        Begin
          BlockRead(f,b,1);
          BlockRead(f,tmp[1],b);
          tmp[0] := Chr(b);
          LanguageText[2][c]^ := Copy(tmp,1,160);
        End;
      BlockRead(f,HotKeys,Sizeof(HotKeys));
      CloseFile(f);
    End;
  LoadLanguageText := True;
End;

Procedure SaveLanguageText(n: Byte);
Var
  f: File;
  c: Word;
  b: Byte;
  st, s: String;
  Key: Char;
Begin
  Begin
  DrawWindow(22,11,58,15,Black+Lightgray*16);
  Writeln;
  WriteCenterString(34,' Save changes? (Y/n)');
  Key := Upcase(Readkey);
  If Key <> 'N' Then
  Begin
  st := OLF[n].Filename;
  If Not OpenFile(f,st,'W',1,faNormal) Then
    Begin
      Note('Cannot save the language file');
      Exit;
    End;
  DayToDate(PresentDay,OLF[n].DateEdit);
  WriteLang(True);
  For c := 1 To MaxLang Do
    Begin
      BlockWrite(f,LanguageText[1][c]^[0],1);
      BlockWrite(f,LanguageText[1][c]^[1],Length(LanguageText[1][c]^));
    End;
  b := 72;
  BlockWrite(f,b,1);
  For c := 1 To MaxLang Do
    Begin
      BlockWrite(f,LanguageText[2][c]^[0],1);
      BlockWrite(f,LanguageText[2][c]^[1],Length(LanguageText[2][c]^));
    End;
  BlockWrite(f,HotKeys,Sizeof(HotKeys));
  CloseFile(f);
  End;
  End;
End;

Procedure PickLang;
Var
  c: Byte;
  Key: Char;
Begin
  ReadLang;
  RestoreScreen(1);
  DrawWindow(2,4,78,22,Lightgray);
  SetColor(Yellow);
  Writeln('    RA Language           OLMS Language         Created   Changed  Active');
  SetColor(LightGray);
  Writeln(' ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
  Window(5,7,77,22); SetColor(LightGray); For c := 0 To 14 Do Writeln(Chr(c+65),')');

  Repeat
  Window(8,7,77,22); SetColor(White);
  For c := 0 To 14 Do
    Begin
      Write(SpacePad(RALName[c],20),'  ',SpacePad(OLF[c].Name,20),'  ',
            SpacePad(OLF[c].DateMade,8),'  ',SpacePad(OLF[c].DateEdit,8),'  ');
      If OLF[c].Active And (OLF[c].Name<>'') And (Reg Or (C=0)) Then Writeln('Yes') Else Writeln('No ');
    End;
  Window(8,7,77,21);
  Repeat
    Key := Upcase(Readkey);
  Until Key In ['A'..'O',#27];
  If Key In ['A'..'O'] Then
    Begin
      c := Byte(Key)-65;
      StoreScreen(5);
      DrawWindow(7,9,72,15,Lightgray);
      SetColor(LightGray);
      Writeln(' A)     Language: ');
      Writeln(' B)     Filename: ');
      Writeln('+C)       Active: ');
      Writeln(' D) Screens Path: ');
      Write  (' E)    Edit text: ');
      Window(27,10,71,14);
      SetColor(White);
      Writeln(OLF[c].Name);
      Writeln(Copy(OLF[c].Filename,1,44));
      If OLF[c].Active And (Reg Or (C=0)) Then Writeln('Yes') Else Writeln('No');
      Writeln(Copy(OLF[c].ScreenPath,1,44));
      Write('List');
      Repeat
        Window(27,10,71,14);
        Key := Upcase(Readkey);
        Case Key Of
          'A': Begin
                 Gotoxy(1,1); GetString2(OLF[c].Name,20,20,15,Normal);
               End;
          'B': Begin
                 With OLF[c] Do
                 Begin
                 Gotoxy(1,2); GetString2(FileName,60,44,15,Execute);
                 If Pos('.',Filename) > 0 Then Filename := Copy(Filename,1,Pos('.',OLF[c].Filename)-1);
                 If Filename <> '' Then
                   Begin
                     If (Filename[2]<>':') And (Filename[1]<>'\') Then Filename := Copy(MainDir+Filename,1,60);
                     Filename := UpcaseStr(Filename)+'.OLF';
                   End;
                 Gotoxy(1,2); Write(Filename); ClrEol;
                 End;
               End;
          'C': If Reg Or (C=0) Then
               Begin
                 OLF[c].Active := Not OLF[C].Active;
                 Gotoxy(1,3);
                 If OLF[c].Active Then Writeln('Yes') Else Writeln('No ');
               End;
          'D': Begin
                 Gotoxy(1,4); GetString2(OLF[c].ScreenPath,60,44,15,Path);
                 If OLF[c].ScreenPath = '\' Then OLF[c].ScreenPath := '';
                 Gotoxy(1,4); Write(OLF[c].ScreenPath); ClrEol;
               End;
          'E': Begin
                 If LoadLanguageText(c) Then
                   Begin
                     StoreScreen(5);
                     Language(OLF[c].Name,OLF[c].Filename);
                     SaveLanguageText(c);
                     RestoreScreen(5);
                     SetColor(White);
                   End;
               End;
        End;
      Until Key = #27;
      Key := '*';
      RestoreScreen(5);
    End;
  Until Key In [#27];
  WriteLang(False);
End;


Function AutoPath(st: String): String;
Var
  f, t, p: String;
Begin
  If Pos(' ',st) > 0 Then f := Copy(st,1,Pos(' ',st)-1) Else f := st;
  AutoPath := st;
  p := GetEnv('PATH');
  While p <> '' Do
    Begin
      If Pos(';',p) <> 0 Then t := Copy(p,1,Pos(';',p)-1)
      Else t := p;
      If t = p Then p := '' Else p := Copy(p,Length(t)+2,255);
      If t[Length(t)] <> '\' Then t := t + '\';
      If FileExists(t+f) Then AutoPath := Copy(t+st,1,70);
    End;
End;

Procedure CheckConfig;
Var
  c, Count: Byte;
  Key: Char;
  Temp: String;
Begin
  If Not FileExists(Getpath(ParamStr(0))+'OLMS.CFG') Then
    Begin
      StoreScreen(5);
      Drawwindow(20,11,60,15,Lightgray+Red*16);
      SetColor(White+Red*16);
      CenterString(40,'File OLMS.CFG not found');
      Writeln;
      Write('  Space to create or escape to abort');
      Repeat Key := Readkey; Until Key In [#32,#27];
      If Key = #27 Then
        Begin
          ClearHalt;
        End;
      {
      Drawwindow(20,10,60,15,Darkgray+Lightgray*16);
      SetColor(White+Lightgray*16);
      CenterString(40,'Please enter the startup password:');
      SetColor(Darkgray+Lightgray*16);
      CenterString(40,'(Found in the documentation)');
      Writeln;
      Write('               ');
      Temp := '';
      GetString(Temp,8,White,Upper);
      If Temp <> 'AGREED' Then
        Begin
          SetColor(Lightgray);
          Window(1,1,80,25);
          Clrscr;
          CursorView;
          Halt;
        End;
      }
      Fillchar(Setup^,Sizeof(SETUPrecord),0);
      With Setup^ Do
      Begin
        Serial           := 'DEMO';
        Registration     := '0';
        BoardID          := 'DEFAULT';
        PhoneNumber      := '(XXX)YYY-ZZZZ';
        Version          := 200;
        Setup^.MaxSlices  := 20;
        Setup^.TagFile    := 'C:\RA\OLMS.TAG';
        Setup^.Retear     := True;
        Setup^.UseSlice   := True;
        Dated            := PresentDay;
        Fillchar(SwappingControl,Sizeof(SwappingControl),1);
        For c := 1 To 3 Do
          Begin
            TransmitNames[c] := Chr(87+c)+'modem';
            TransmitKeys[c]  := Chr(87+c);
          End;
        For c := 4 To 6 Do
          Begin
            TransmitNames[c] := '';
            TransmitKeys[c]  := ' ';
          End;
        Compress[1]      := AutoPath('ARJ.EXE a');
        Compress[2]      := AutoPath('LHA.EXE a /m');
        Compress[3]      := AutoPath('PKZIP.EXE -ex');
        Compress[4]      := AutoPath('PKARC.COM A');
        Compress[5]      := AutoPath('PAK.EXE A /I');
        Compress[6]      := AutoPath('RAR.EXE a');
        Decompress[1]    := AutoPath('ARJ.EXE e');
        Decompress[2]    := AutoPath('LHA.EXE e /m');
        Decompress[3]    := AutoPath('PKUNZIP.EXE -o');
        Decompress[4]    := AutoPath('PKXARC.COM -ER');
        Decompress[5]    := AutoPath('PAK.EXE E /I /WA');
        Decompress[6]    := AutoPath('RAR.EXE e -o+');
        Transmit[1]      := AutoPath('DSZ.EXE port *P sx');
        Transmit[2]      := AutoPath('DSZ.EXE port *P sb');
        Transmit[3]      := AutoPath('DSZ.EXE port *P sz -rr');
        Receive[1]       := AutoPath('DSZ.EXE port *P rx');
        Receive[2]       := AutoPath('DSZ.EXE port *P rb');
        Receive[3]       := AutoPath('DSZ.EXE port *P rz');
        LocalULPath      := 'C:\FD\OUTBOUND\';
        LocalDLPath      := 'C:\FD\FILES\';
        NewsFile         := 'C:\RA\TXTFILES\WELCOME.ANS';
        HelloFile        := 'C:\RA\TXTFILES\LOGO.ANS';
        GoodbyeFile      := 'C:\RA\TXTFILES\GOODBYE.ANS';
        Logfile          := 'C:\RA\OLMS.LOG';
        LogMode          := 'R';
        Tagfile          := 'C:\RA\OLMS.TAG';
        Retear           := True;
        CheckDupes       := True;
        CheckHeaderDupes := True;
        NumberDupes      := 5000;
        Screens          := 1;
        Opening          := True;
        MaxConference    :=  1000;
        MaxPacket[0]     := 10000;  {     0 }
        MaxPacket[1]     :=   300;  {  1200 }
        MaxPacket[2]     :=   700;  {  2400 }
        MaxPacket[3]     :=  1000;  {  9600 }
        MaxPacket[4]     :=  1500;  { 14400 }
        MaxPacket[5]     :=  2000;  { 19200 }
        MaxPacket[6]     :=  2500;  { 28800 }
        MaxPacket[7]     :=  3000;  { 38400 }

        For Count := 1 To MaxBull Do BulletinFlags[Count] := 1;
        WriteConfig;
      End;
    End;
End;

Procedure CheckRegs;
Var
  Temp: String;
  Counter1, A: Byte;
Begin
  Reg := CheckReg(Setup^.SystemName,Setup^.Sysop,Setup^.Serial,Setup^.Registration);

  If Not Reg Then
    Begin
      Temp := '  *** Unregistered ***    Please register this program    *** Unregistered ***  ';
      A := Yellow+Blue*16;
    End
  Else
    Begin
      A := Lightblue+Blue*16;
      Temp := 'Registered to '+Setup^.SystemName+', thank you.';
      Temp := Copy('                                         ',1,40-Length(Temp)DIV 2)
              + Temp +
              Copy('                                         ',1,40-Length(Temp)DIV 2);

    End;
  For Counter1 := 0 To 79 Do
    Begin
      Byte(Ptr(VideoAddress,3680 + Counter1*2)^) := Byte(Temp[Counter1+1]);
      Byte(Ptr(VideoAddress,3681 + Counter1*2)^) := Byte(A);
    End;
End;

Procedure MainScreen;
Var
  Counter: Byte;
Begin
  TextAttr := 15;
  ClrScr;
  Writeln(' Olms '+SetupVersion+', The Offline Mail System');
  TextAttr := Blue * 16 + LightBlue;
  Write('                                                                                ');
  TextAttr := 8;
  Write('¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À');
  For Counter := 1 To 10 Do
    Begin
      Write('À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿');
      Write('¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À¿À');
    End;
  TextAttr := Blue * 16 + White;
  Write('                                                                                ');
  TextAttr := 7;
  Write('                          Copyrighted Multiboard Communications Centre, 1994-98');
  StoreScreen(1);
End;

Procedure Notice;
Var
  L0,L1,L2: String[60];
  Temp: String[5];
  Counter: Byte;
  pd, Value: Longint;
Begin
  CheckRegs;
  L0 := 'PETER ROCCA';
  L1 := '142 Sandy Street';
  L2 := 'London, Ontario, Canada, N5Z 5C7';

  Value := 0;
  For Counter := 1 To Length(L0) Do Value := Value + Byte(L0[Counter]) * 2;
  For Counter := 1 To Length(L1) Do Value := Value + Byte(L1[Counter]) * 3;
  For Counter := 1 To Length(L2) Do Value := Value + Byte(L2[Counter]) * 7;

  If Value <> 23641 Then
    Begin
      Writeln('PROGRAM ALTERED');
      ClearHalt;
    End;

  DrawWindow(15,7,65,17,Lightgray+Blue*16);
  Writeln;
  SetColor(Yellow+Blue*16);
  CenterString(50,'Olms '+SetupVersion);
  Writeln;
  SetColor(White+Blue*16);
  CenterString(50,'Copyrighted 1994-98');
  Writeln;
  CenterString(50,'Peter Rocca');
  CenterString(50,'of');
  CenterString(50,'Multiboard Communications Centre');
  Readkey;
  If Not Reg Then
    Begin
      DrawWindow(10,5,70,20,Lightgray+Red*16);
      Writeln;
      SetColor(Yellow+Red*16+128);
      pd := Setup^.Dated;
      {$IFDEF PROVERSION}
      If Setup^.ProActivated=224 Then pd := Setup^.ProDated;
      {$ENDIF}
      Str(PresentDay-pd+1,Temp);
      CenterString(60,'Unregistered Version, Evaluation Day '+Temp);
      Writeln;
      SetColor(White+Red*16);
      If PresentDay <= pd+45 Then CenterString(60,'Support shareware authors, register your software soon.')
      Else If PresentDay > pd+98 Then
        Begin
          Write('  ');
          SetColor(Blue+Cyan*16+128); Write('Û');
          SetColor(Cyan+Blue*16+128); Write('Û');
          SetColor(White+Red*16);
          Write('  You are way overdue to register this software!  ');
          SetColor(Cyan+Blue*16+128); Write('Û');
          SetColor(Blue+Cyan*16+128); Writeln('Û');
          SetColor(White+Red*16);
          Sound(150); Delay(420); NoSound; Delay(50);
          Sound(150); Delay(420); NoSound; Delay(50);
          Sound(150); Delay(420); NoSound; Delay(50);
          Sound(100); Delay(800);
          NoSound;
        End
      Else CenterString(60,'Support shareware authors and register your software!');
      Writeln;
      CenterString(60,'Please fill in the registration form that is included');
      CenterString(60,'with the documentation and send it with your fee to:');
      Writeln;
      CenterString(60,L0);
      CenterString(60,L1);
      CenterString(60,L2);
      Writeln;
      SetColor(Yellow+Red*16+128);
      Write('                Annoying Ten Second Delay'+#13);
      Sleep(10);
      SetColor(White+Red*16);
      CenterString(60,'Press any key to continue');
      Readkey;
    End;
  RestoreScreen(1);
  CursorHide;
End;


(**************************************************************************)

Function ReturnSysopFlags(Value: Byte): String;
Var
  Flag: String;
Begin
       If Value And sFORCED   <> 0 Then Flag := 'F'
  Else If Value And sBLOCKED  <> 0 Then Flag := 'B'
  Else If Value And sHIDDEN   <> 0 Then Flag := 'H'
  Else Flag := '.';
  Flag := Flag + '.';
  If Value And sDEFAULT <> 0 Then Flag := Flag + 'D' Else Flag := Flag + '.';
  If Value And sKEEPTO  <> 0 Then Flag := Flag + 'K' Else Flag := Flag + '.';
  If Value And sNOTAG   <> 0 Then Flag := Flag + 'X' Else Flag := Flag + '.';
  ReturnSysopFlags := Flag;
End;

Procedure SysopForced;
Var
  L: Longint;
  OO, O, C: Word;
  b: Byte;
  Key: Char;
Begin
  StoreScreen(5);
  DrawWindow(1,5,13,13,Lightblue+Blue*16);
  SetColor(White+Blue*16);
  Write('.) Normal ');
  Write('F) Forced ');
  Write('B) Blocked');
  Write('H) Hidden ');
  Write('D) Default');
  Write('K) Keep To');
  Write('X) No Tag');
  DrawWindow(15,5,66,20,Lightgray);
  O := 0;
  L := 0;
  Repeat
    OO := O;
    Gotoxy(1,1);
    For C := 1 To 14 Do
      Begin
        TextColor(White);
        Write('  ',SpacePad(AreaNames^[C+O]^,39));
        TextColor(LightGray);
        Write(' '+ReturnSysopFlags(Setup^.SysopFlags[AreaNumbers^[C+O]]));
        If C <> 14 Then Writeln;
      End;
    TextColor(Yellow);
    Gotoxy(2,L+1); Write(#26);
    Gotoxy(48,L+1); Write(#27);
    Repeat
      Key := Upcase(Readkey);
      Gotoxy(2,L+1); Write(' ');
      Gotoxy(48,L+1); Write(' ');
      If Key = #0 Then
        Begin
          Key := Readkey;
          Case Key Of
            'G': Begin O:= 0; L:=0; End;
            'O': Begin O:= ZMaxAreas-14; L:=13; End;
            'I': Begin If O>14 Then Dec(O,14) Else O := 0; L := 0; End;
            'Q': Begin If O<ZMaxAreas-28 Then Inc(O,14) Else O := ZMaxAreas-14; L := 13; Key := #0; End;
            'P': Begin
                   Inc(L);
                   If L > 13 Then
                     Begin
                       L := 13;
                       If O+14 < ZMaxAreas Then Inc(O);
                     End;
                 End;
            'H': Begin
                   If L = 0 Then
                     Begin
                       L := 0;
                       If O > 0 Then Dec(O);
                     End
                   Else Dec(L);
                 End;
          End;
        End
      Else
        Begin
          b := Setup^.SysopFlags[AreaNumbers^[O+L+1]];
          Case Key Of
            'X': b := (b Xor sNOTAG);
            'K': b := (b Xor sKEEPTO);
            'D': b := (b Xor sDEFAULT);
            'F': b := b And 248 + sFORCED;
            'B': b := b And 248 + sBLOCKED;
            'H': b := b And 248 + sHIDDEN;
            '.': b := 0;
          End;
          Setup^.SysopFlags[AreaNumbers^[O+L+1]] := b;
        End;
      Gotoxy(2,L+1); Write(#26);
      Gotoxy(48,L+1); Write(#27);
    Until (Key In [#27,'Q','.','X','K','F','B','H','D']) Or (O<>OO);
  Until Key In [#27,'Q'];
  Key := #0;
  RestoreScreen(5);
  SetColor(White);
End;

Procedure SystemInfo;
Var
  UseGate: Boolean;
  Wrong: Byte;
  Key: Char;
  Temp: String[10];
  Value: Word;
  Code: Integer;
Begin
  If Setup^.DefaultPacketType > 3 Then Setup^.DefaultPacketType := 0;
  Wrong := 0;
  RestoreScreen(1);
  DrawWindow(8,7,72,17,Lightgray);
  SetColor(LightGray);
  Writeln(' N)      System name:');
  Writeln(' Y)       Sysop name:');
  Writeln(' S)    Serial number:');
  Writeln(' R)     Registration:');
  Writeln(' B)         Board Id:');
  Writeln(' P)     Phone number:');
  Writeln(' G)  Gateway support:');
  Writeln(' A)    ÓÄÄÄÄ Address:');
  Write  ('åU)  Supported areas:');
  If Setup^.GatewayAddress = '' Then UseGate := False Else UseGate := True;
  Repeat
    Window(32,8,71,16);
    ClrScr;
    Window(32,8,71,17);
    SetColor(White);
    Writeln(Setup^.SystemName);
    Writeln(Setup^.Sysop);
    {$IFDEF PROVERSION}
{   If Setup^.Serial[1] = 'E' Then MaxNodes := 250
    Else If Setup^.Serial[1] = 'Q' Then MaxNodes := 10
    Else MaxNodes := 3; }
    MaxNodes := 250;
    If Not Reg Then Writeln('xxxxxxxx/Professional - 10 node demo')
    Else Writeln(Setup^.Serial,'/Professional - ',MaxNodes,' node');
    {$ELSE}
    Writeln(Setup^.Serial);
    {$ENDIF}
    Writeln(Setup^.Registration);
    Writeln(Setup^.BoardID);
    Writeln(Setup^.PhoneNumber);
    If UseGate Then Writeln('Yes') Else Writeln('No ');
    Writeln(Setup^.GatewayAddress);
    Write  (UserAreas,', (',HighSize,' defined on the BBS)');
    Key := Upcase(Readkey);
    Case Key Of
      'N': Begin
             Gotoxy(1,1); GetString2(Setup^.SystemName,30,30,15,Sentence);
           End;
      'Y': Begin
             Gotoxy(1,2); GetString2(Setup^.Sysop,35,35,15,Sentence);
           End;
      'S': Begin
             Gotoxy(1,3); GetString2(Setup^.Serial,8,8,15,Upper);
           End;
      'R': Begin
             Gotoxy(1,4); GetString2(Setup^.Registration,24,24,15,Upper);
             CheckRegs;
             If Not Reg Then
               Begin
                 Inc(Wrong);
                 Sleep(Wrong);
               End;
           End;
      'B': Begin
             Gotoxy(1,5); GetString2(Setup^.BoardID,8,8,15,Upper);
           End;
      'P': Begin
             Gotoxy(1,6); GetString2(Setup^.PhoneNumber,19,19,15,Upper);
           End;
      'G': Begin
             UseGate := Not UseGate;
             If UseGate Then Key := 'A' Else Setup^.GatewayAddress := '';
           End;
{$IFDEF PROVERSION}
      'U': Begin
             Temp := ZeroPad(UserAreas,0);
             Gotoxy(1,9); Write(SpacePad('',36));
             Gotoxy(1,9);
             GetString2(Temp,5,5,15,Number);
             Val(Temp,Value,Code);
             If (Value>0) And (Value<=10000) Then
               Begin
                 If Value<>UserAreas Then If Warning_ChangeAreas = 'Y' Then Change_Areas(UserAreas,Value);
               End
             Else Note('Value out of range (1-10000)');
           End;
{$ENDIF}
    End;
    If Key = 'A' Then
      Begin
        Gotoxy(1,7);
        If UseGate Then Writeln('Yes') Else Writeln('No ');
        Gotoxy(1,8); GetString2(Setup^.GatewayAddress,19,19,15,Upper);
        If Setup^.GatewayAddress = '' Then UseGate := False;
      End;
    If Key In ['S','R','N','Y'] Then
      Begin
       CheckRegs; StoreScreen(3); RestoreScreen(1);
       CheckRegs; StoreScreen(1); RestoreScreen(3);
      End;
  Until Key = #27;
End;

Procedure ArcPrograms;
Var
  Key: Char;
  N, c: Byte;
Begin
  RestoreScreen(1);
  DrawWindow(2,4,78,19,Lightgray);
  SetColor(Yellow);
  Writeln('          Mode   Name  Program                                      Swap ');
  SetColor(LightGray);
  Write('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
  Window(4,7,77,18);
  ClrScr;
  Writeln('   Compression A) ARJ:','':44,'M)');
  Writeln('               B) LZH:','':44,'N)');
  Writeln('               C) ZIP:','':44,'O)');
  Writeln('               D) ARC:','':44,'P)');
  Writeln('               E) PAK:','':44,'Q)');
  Writeln('               F) RAR:','':44,'R)');
  Writeln(' Decompression G) ARJ:','':44,'S)');
  Writeln('               H) LZH:','':44,'T)');
  Writeln('               I) ZIP:','':44,'U)');
  Writeln('               J) ARC:','':44,'V)');
  Writeln('               K) PAK:','':44,'W)');
  Write  ('               L) RAR:','':44,'X)');
  SetColor(White);
  Window(73,7,77,19);
  For n := 1 To 6 Do Writeln(YN(Boolean(Setup^.SwappingControl[1][n])));
  For n := 1 To 6 Do Writeln(YN(Boolean(Setup^.SwappingControl[2][n])));
  Window(27,7,77,19);
  For n := 1 To 6 Do Writeln(Copy(Setup^.Compress[n],1,42));
  For n := 1 To 6 Do Writeln(Copy(Setup^.Decompress[n],1,42));
  Repeat
    Key := Upcase(Readkey);
    N := Byte(Key)-64;
    Gotoxy(1,N);
    Case Key Of
      'A'..'F': Begin
                  GetString2(Setup^.Compress[N],70,42,15,Execute);
                  CheckRun(Setup^.Compress[N]);
                End;
      'G'..'L': Begin
                  GetString2(Setup^.Decompress[N-6],70,42,15,Execute);
                  CheckRun(Setup^.Decompress[N-6]);
                End;
      'M'..'X': Begin
                  N := N - 12;
                  SetColor(White);
                  Gotoxy(47,N);
                  If N > 6 Then Begin Dec(N,6); C := 2; End Else C := 1;
                  If Setup^.SwappingControl[C][N]>0
                  Then Setup^.SwappingControl[C][N] := 0
                  Else Setup^.SwappingControl[C][N] := 1;
                  Write(YN(Boolean(Setup^.SwappingControl[c][n])));
                End;
    End;
    Window(27,7,77,19);
  Until Key = #27;
End;

Function TN(by: Byte): String;
Var
  p: Byte;
Begin
  If Setup^.TransmitKeys[by]=' ' Then
    Begin
      SetColor(LightGray);
      Write(SpacePad('Inactive',10));
    End
  Else
    Begin
      p := Pos(Upcase(Setup^.TransmitKeys[by]),UpcaseStr(Setup^.TransmitNames[by]));
      If p = 0 Then
        Begin
          SetColor(Yellow); Write(Setup^.TransmitKeys[by]);
          SetColor(Lightgray); Write(SpacePad(Setup^.TransmitNames[by],9));
        End
      Else
        Begin
          SetColor(Lightgray); Write(Copy(Setup^.TransmitNames[by],1,p-1));
          SetColor(Yellow); Write(Setup^.TransmitKeys[by]);
          SetColor(Lightgray); Write(SpacePad(Copy(Setup^.TransmitNames[by],p+1,255),10-p));
        End;
    End;
  SetColor(LightGray);
  TN := '';
End;

Procedure ProtPrograms;
Var
  Key: Char;
  N, c: Byte;
Begin
  RestoreScreen(1);
  DrawWindow(2,4,78,19,Lightgray);
  SetColor(Yellow);
  Writeln(' Mode        Name       Program                                     Swap ');
  SetColor(LightGray);
  Write('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
  Window(4,7,77,18);
  ClrScr;
  Write(' Transmit A) '); TN(1); Writeln('':43,'M)');
  Write('          B) '); TN(2); Writeln('':43,'N)');
  Write('          C) '); TN(3); Writeln('':43,'O)');
  Write('          D) '); TN(4); Writeln('':43,'P)');
  Write('          E) '); TN(5); Writeln('':43,'Q)');
  Write('          F) '); TN(6); Writeln('':43,'R)');
  Write(' Receive  G) '); TN(1); Writeln('':43,'S)');
  Write('          H) '); TN(2); Writeln('':43,'T)');
  Write('          I) '); TN(3); Writeln('':43,'U)');
  Write('      1)  J) '); TN(4); Writeln('':43,'V)');
  Write('      2)  K) '); TN(5); Writeln('':43,'W)');
  Write('      3)  L) '); TN(6); Write  ('':43,'X)');
  SetColor(White);
  Window(73,7,77,19);
  For n := 1 To 6 Do Writeln(YN(Boolean(Setup^.SwappingControl[3][n])));
  For n := 1 To 6 Do Writeln(YN(Boolean(Setup^.SwappingControl[4][n])));
  Window(28,7,77,19);
  For n := 1 To 6 Do Writeln(Copy(Setup^.Transmit[n],1,41));
  For n := 1 To 6 Do Writeln(Copy(Setup^.Receive[n],1,41));
  Window(28,7,77,19);
  Repeat
    Key := Upcase(Readkey);
    N := Byte(Key)-64;
    Gotoxy(1,N);
    Case Key Of
      '1'..'3': Begin
                  n := Byte(Key)-48+3;
                  Window(17,7,77,19);
                  Gotoxy(1,n+6);
                  GetString2(Setup^.TransmitNames[n],10,10,15,Normal);
                  StoreScreen(3);
                  DrawWindow(20,12,60,15,Lightblue+Blue*16);
                  WriteCenterString(36,' Choose a hot key for this protocol');
                  Writeln;
                  Write('          or space to disable');
                  Repeat
                    Setup^.TransmitKeys[n] := Upcase(Readkey);
                  Until Setup^.TransmitKeys[n] In ['A'..'Z','0'..'9','-','/','\','.',':',#32,'!'];
                  RestoreScreen(3);
                  Window(17,7,77,19);
                  Gotoxy(1,n);   TN(n);
                  Gotoxy(1,n+6); TN(n);
                  TextAttr := White;
                End;
      'A'..'F': Begin
                  GetString2(Setup^.Transmit[N],70,41,15,Execute);
                  CheckRun(Setup^.Transmit[N]);
                End;
      'G'..'L': Begin
                  GetString2(Setup^.Receive[N-6],70,41,15,Execute);
                  CheckRun(Setup^.Receive[N-6]);
                End;
      'M'..'X': Begin
                  N := N - 12;
                  SetColor(White);
                  Gotoxy(46,N);
                  If N > 6 Then Begin Dec(N,6); C := 4; End Else C := 3;
                  Setup^.SwappingControl[C][N] := Setup^.SwappingControl[C][N] Xor 1;
                  Write(YN(Boolean(Setup^.SwappingControl[c][n])));
                End;
    End;
    Window(28,7,77,19);
  Until Key = #27;
End;

Procedure FilesConfig;
Var
  Key: Char;
  ExtraLine, by: Byte;
  Temp: String;
Begin
{$IFDEF BBS_RA1}
  ExtraLine := 1;
{$ELSE}
  ExtraLine := 0;
{$ENDIF}
  RestoreScreen(1);
  DrawWindow(5,8,75,18+ExtraLine,Lightgray);
  SetColor(LightGray);
  Writeln(' A)            News file:');
  Writeln(' B)       Welcome screen:');
  Writeln(' C)       Goodbye screen:');
  Writeln(' D) OLMS/System log file:');
  Writeln(' E)  ÇÄÄÄÄÄÄÄÄÄ Log mode:');
  Writeln(' F)  ÓÄÄ Add linefeed/CR:');
  Writeln(' G)    Local upload path:');
  Writeln(' H)  Local download path:');
  Write  (' I)         Tagline file:');
{$IFDEF BBS_RA1}
  Writeln;
  Write  (' J)       New files list:');
{$ENDIF}

  Repeat
  Window(33,9,74,18+ExtraLine);
  SetColor(White);
  Writeln(Copy(Setup^.NewsFile,1,36));
  Writeln(Copy(Setup^.HelloFile,1,36));
  Writeln(Copy(Setup^.GoodbyeFile,1,36));
  Writeln(Copy(Setup^.LogFile,1,36));
  Case Setup^.LogMode Of
    'E': Writeln('Extended');
    'C': Writeln('Compact ');
    'R': Writeln('Regular ');
    'D': Writeln('Debug   ');
  End;
  If Setup^.LogHeaders Then Writeln('Yes') Else Writeln('No ');
  Writeln(Copy(Setup^.LocalULPath,1,36));
  Writeln(Copy(Setup^.LocalDLPath,1,36));
  Write  (Copy(Setup^.TagFile,1,36));
{$IFDEF BBS_RA1}
  Writeln;
  Write  (Copy(Setup^.FileBasePath,1,36));
{$ENDIF}
  Repeat
    Key := Upcase(Readkey);
    Case Key Of
      'A': Begin
             Gotoxy(1,1); GetString2(Setup^.NewsFile,59,36,15,Execute);
             CheckFile(Setup^.NewsFile);
           End;
      'B': Begin
             Gotoxy(1,2); GetString2(Setup^.HelloFile,59,36,15,Execute);
             CheckFile(Setup^.HelloFile);
           End;
      'C': Begin
             Gotoxy(1,3); GetString2(Setup^.GoodbyeFile,59,36,15,Execute);
             CheckFile(Setup^.GoodbyeFile);
           End;
      'D': Begin
             Gotoxy(1,4); GetString2(Setup^.LogFile,59,36,15,Execute);
             CheckFile(Setup^.LogFile);
           End;
      'E':      If Setup^.LogMode = 'E' Then Setup^.LogMode := 'C'
           Else If Setup^.LogMode = 'C' Then Setup^.LogMode := 'R'
           Else If Setup^.LogMode = 'R' Then Setup^.LogMode := 'D'
           Else If Setup^.LogMode = 'D' Then Setup^.LogMode := 'E';
      'F': Setup^.LogHeaders := Not Setup^.LogHeaders;
      'G': Begin
             Gotoxy(1,7); GetString2(Setup^.LocalULPath,59,36,15,Path);
             CheckPath(Setup^.LocalULPath);
           End;
      'H': Begin
             Gotoxy(1,8); GetString2(Setup^.LocalDLPath,59,36,15,Path);
             CheckPath(Setup^.LocalDLPath);
           End;
      'I': Begin
             Gotoxy(1,9); GetString2(Setup^.TagFile,59,36,15,Execute);
             CheckFile(Setup^.TagFile);
           End;
      'J': Begin
             {$IFDEF BBS_RA1}
             Gotoxy(1,10); GetString2(Setup^.FileBasePath,59,36,15,Execute);
             CheckFile(Setup^.FileBasePath);
             {$ELSE}
             Key := 'Z';
             {$ENDIF}
           End;
    End;
  Until Key In ['A'..'J',#27];
  Until Key = #27;
End;

Procedure BulletinConfig;
Var
  Key: Char;
  X, O, N: Byte;
  INF: Array [0..3] Of String[12];
Begin
  INF[bINACTIVE] := 'Inactive   ';
  INF[bNORMAL]   := 'Normal     ';
  INF[bFORCED]   := 'Forced     ';
  INF[bNEWONLY]  := 'Only If New';

  RestoreScreen(1);
  DrawWindow(10,3,71,23,Lightgray);
  O := 0;
  Repeat
  SetColor(LightGray);
  Window(14,4,70,23);
  For N := 1 To 9 Do
    Begin
      Writeln(Char(N*2+63),') Desc: ',N:28,') Stat: ');
      Writeln(Char(N*2+64),') File: ');
    End;
  If O=0 Then Write('*) Next    ') Else Write('*) Previous');
  X := 0;
  SetColor(White);
  Window(59,4,70,23);
  For N := 1 To 9 Do
    Begin
      Gotoxy(1,N*2-1);
      Writeln(INF[Setup^.BulletinFlags[N+O*9]]);
    End;
  Window(23,4,70,23);
  For N := 1 To 9 Do
    Begin
      Writeln(SpacePad(Setup^.BulletinNames[N+O*9],25));
      Writeln(SpacePad(Setup^.Bulletins[N+O*9],46));
    End;
  Repeat
    Window(23,4,70,23);
    Key := Upcase(Readkey);
    N := Byte(Key)-64;
    Gotoxy(1,N);
    Case Key Of
      '*':
      Begin
        If O = 0 Then O := 1 Else O := 0;
        X := 1;
      End;
      '1'..'9':
      Begin
        Window(59,4,70,23);
        N := Byte(Key)-48;
        Inc(Setup^.BulletinFlags[N+O*9]);
        If Setup^.BulletinFlags[N+O*9] > 3 Then Setup^.BulletinFlags[N+O*9] := 0;
        Gotoxy(1,N*2-1);
        Write(INF[Setup^.BulletinFlags[N+O*9]]);
        Window(23,4,70,23);
      End;
      'A','C','E','G','I','K','M','O','Q':
      Begin
        GetString2(Setup^.BulletinNames[N DIV 2+1+O*9],25,25,15,Sentence);
      End;
      'B','D','F','H','J','L','N','P','R':
      Begin
        GetString2(Setup^.Bulletins[N DIV 2+O*9],60,46,15,Execute);
        If Setup^.Bulletins[N DIV 2+O*9] <>'' Then CheckFile(Setup^.Bulletins[N DIV 2+O*9]);
      End;
    End;
  Until (Key=#27) Or (X=1);
  Until Key = #27;
End;

Procedure GetNum(x,y: Byte; Var Num: Word; Max: Word; Width: Byte);
Var
  Temp: String;
  Value: Word;
  Code: Integer;
Begin
  Gotoxy(x,y); Write('':Width); Gotoxy(x,y);
  Str(Num,Temp);
  GetString2(Temp,Width,Width,15,Number);
  Val(Temp,Value,Code);
  If Code = 0 Then
    Begin
      If Value > Max Then Value := Max;
      Num := Value;
    End;
  Gotoxy(x,y); Write(SpacePad(ZeroPad(Num,0),Width));
End;

Procedure NetmailOptions;
Var
  Key: Char;
Begin
  StoreScreen(5);
  DrawWindow(20,9,61,17,Lightgray);
  Writeln(' A)    Set kill/sent on netmail: ');
  Writeln(' B) Security for ÄÄÄÄÄÄÄÄ Crash: ');
  Writeln(' C)  ÇÄÄÄÄÄÄÄÄÄÄÄÄÄ File-attach: ');
  Writeln(' D)  ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Hold: ');
  Writeln(' E)  ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Immediate: ');
  Writeln(' F)  ÇÄÄÄÄÄÄÄÄÄÄÄÄ File-request: ');
  Write  (' G)  ÓÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Direct: ');
  Repeat
    Window(55,10,60,17);
    TextAttr := White;
    Writeln(YN(Setup^.KillSentNetmail));
    Writeln(Setup^.NetmailCrash);
    Writeln('n/a');
    Writeln(Setup^.NetmailHold);
    Writeln(Setup^.NetmailImm);
    Writeln(Setup^.NetmailFreq);
    Write  (Setup^.NetmailDirect);
    Repeat
      Key := Upcase(Readkey);
    Until Key In [#27,'A'..'G'];
    Case Key Of
      'A': Setup^.KillSentNetmail := Not Setup^.KillSentNetmail;
      'B': GetNum(1,2,Setup^.NetmailCrash,65535,5);
      'C': ; {NetmailFatch}
      'D': GetNum(1,4,Setup^.NetmailHold,65535,5);
      'E': GetNum(1,5,Setup^.NetmailImm,65535,5);
      'F': GetNum(1,6,Setup^.NetmailFreq,65535,5);
      'G': GetNum(1,7,Setup^.NetmailDirect,65535,5);
    End;
  Until Key=#27;
  RestoreScreen(5);
End;

Procedure ControlSetup;
Var
  Temp: String;
  Value: Longint;
  Code: Integer;
  Key: Char;
  Whichone: Boolean;
  NAF: Array[0..2] Of String[5];
  MT: Array[0..2] Of String[8];
  TT: Array[False..True] Of Array[False..True] Of String[8];
Begin
  MT[0] := 'None  ';
  MT[1] := 'Pend  ';
  MT[2] := 'Strict';

  TT[True ,True ] := 'Replace';
  TT[True ,False] := 'Remove ';
  TT[False,True ] := 'Append ';
  TT[False,False] := 'Ignore ';

  NAF[0] := 'No   ';
  NAF[1] := 'Allow';
  NAF[2] := 'Force';

  Whichone := False;

  If Byte(Setup^.RestrictTime)>1 Then Setup^.RestrictTime := False;

  RestoreScreen(1);
  DrawWindow(2,3,78,23,Lightgray);
  SetColor(LightGray);
  Writeln(' A)              Netmail options:');
  Writeln(' B)  Check for duplicate uploads:');
  Writeln(' C)    ÇÄÄÄÄÄÄÄÄ Include headers:');
  Writeln(' D)    ÓÄÄÄÄÄ Signatures to keep:');
  Writeln(' E) Send welcome/goodbye screens:');
  Writeln('+F)       Display opening screen:');
  Writeln(' G)          Allow new file scan:');
  Writeln(' H)       ^A kludge line control:');
  Writeln(' I)  Max timeslice release level:');
  Writeln(' J)    Replace tear/origin lines:');
  Writeln(' K)              Tagline control:');
  Writeln('åL)  Auto-include attached files:');
  Writeln(' M)  Kill local uploaded replies:');
  Writeln('+N)       Allow logoff from door:');
  Writeln(' O)        Select areas by group:');
  Writeln(' P)           Sysop area control:');
  Writeln(' Q) Allow time exceeding packets:');
  Writeln(' R)        Default packet format:');
  Write  (' S)          Menu style (levels):');

  Window(44,4,78,23);
  Writeln(' T)      Allow RIP emulation:');
  Writeln(' U) Use "aw" in forced areas:');
  Writeln(' V)  Add registered tearline:');
  Writeln(' W) Color for minutes remain:');
{  Writeln(' X)                         :');
  Writeln(' Y)                         :');
  Writeln(' Z)                         :');
  Writeln(' 1)                         :');
  Writeln(' 2)                         :');
  Writeln(' 3)                         :');
  Writeln(' 4)                         :');
  Writeln(' 5)                         :');
  Writeln(' 6)                         :');
  Writeln(' 7)                         :');
  Writeln(' 8)                         :');
  Writeln(' 9)                         :');
  Writeln(' 0)                         :');
  Writeln;
  Write  (' ?) Help'); }

  Repeat
    {$IFNDEF PROVERSION}
    Setup^.AutoPackAttaches := False;
    {$ENDIF}
    Window(37,4,43,22);
    {ClrScr;}
    If Not Reg Then
      Begin
        Setup^.Opening := True;
        Setup^.AllowLogoff := True;
      End;
    SetColor(White);
    Gotoxy(1,1);
    Writeln(' ->');
    Writeln(YN(Setup^.CheckDupes));
    If Setup^.CheckDupes Then
      Begin
        Writeln(YN(Setup^.CheckHeaderDupes));
        Writeln(Setup^.NumberDupes);
      End
    Else
      Begin
        Writeln('':3);
        Writeln('':5);
      End;
    Writeln(NAF[Setup^.Screens]);
    Writeln(YN(Setup^.Opening));
    Writeln(YN(Setup^.AllowFileScan));
    Case Setup^.KeepKludges Of
      0: Writeln('Delete');
      1: Writeln('Keep  ');
      2: Writeln('Auto  ');
    Else Writeln('??    ');
    End;
    If Setup^.MaxSlices=0 Then
      Begin
        Setup^.UseSlice := False;
        Writeln('None');
      End
    Else
      Begin
        Setup^.UseSlice := True;
        Writeln(Setup^.MaxSlices);
      End;
    Writeln(YN(Setup^.Retear));
    Write(TT[Setup^.KillTag,Setup^.InsertTag]);
    Writeln(YN(Setup^.AutoPackAttaches));
    Writeln(YN(Setup^.KillRep));
    Writeln(YN(Setup^.AllowLogoff));
    {$IFDEF BBS_RA1}
    Writeln('N/A');
    {$ELSE}
    Writeln(YN(Setup^.GroupPick));
    {$ENDIF}
    Writeln(' ->');
    Writeln(YN(Not Setup^.RestrictTime));
    Case Setup^.DefaultPacketType Of
      0: Writeln('QWK ');
      1: Writeln('QWKE');
      2: Writeln('n/a ');
      3: Writeln('BW  ');
    Else Writeln('??  ');
    End;
    If Setup^.TwoLevelMenu Then Write('Two') Else Write('One');

    Window(73,4,77,22);
    {ClrScr;}
    Writeln(YN(Setup^.AllowRip));
    Writeln(YN(Setup^.IncSelfInForced));
    Writeln(YN(Setup^.Gloat));
    Writeln(ZeroPad(Setup^.MinuteCol,-2));

    Repeat
      Key := UpCase(Readkey);

      If Key In ['A'..'S'] Then Window(37,4,43,22);

      Case Key Of
        'A': NetmailOptions;
        'B': Setup^.CheckDupes := Not Setup^.CheckDupes;
        'C': Setup^.CheckHeaderDupes := Not Setup^.CheckHeaderDupes;
        'D': Begin
               Gotoxy(1,4);
               Str(Setup^.NumberDupes,Temp);
               GetString2(Temp,5,5,15,Number);
               Val(Temp,Value,Code);
               If Code = 0 Then
                 Begin
                   If Value > 60000 Then Value := 60000;
                   Setup^.NumberDupes := Value;
                 End;
             End;
        'E': Begin
               Inc(Setup^.Screens);
               If Setup^.Screens > 2 Then Setup^.Screens := 0;
             End;
        'F': If Reg Then Setup^.Opening := Not Setup^.Opening;
        'G': Setup^.AllowFileScan := Not Setup^.AllowFileScan;
        'H': Begin
               Inc(Setup^.KeepKludges);
               If Setup^.KeepKludges>2 Then Setup^.KeepKludges := 0;
             End;
        'I': Begin
               Gotoxy(1,9); Writeln('    ');
               Gotoxy(1,9);
               Str(Setup^.MaxSlices,Temp);
               GetString(Temp,2,15,Number);
               Val(Temp,Value,Code);
               Setup^.MaxSlices := Value;
             End;
        'J': Setup^.ReTear := Not Setup^.ReTear;
        'K': Begin
               Case Whichone Of
                 True:  Setup^.KillTag     := Not Setup^.KillTag;
                 False: Setup^.InsertTag   := Not Setup^.InsertTag;
               End;
               Whichone := Not Whichone;
             End;
        'L': Setup^.AutoPackAttaches := Not Setup^.AutoPackAttaches;
        'M': Setup^.KillRep := Not Setup^.KillRep;
        'N': If Reg Then Setup^.AllowLogoff := Not Setup^.AllowLogoff;
        'O': Setup^.GroupPick := Not Setup^.GroupPick;
        'P': SysopForced;
        'Q': Setup^.RestrictTime := Not Setup^.RestrictTime;
        'R': Begin
               Inc(Setup^.DefaultPacketType);
               If Setup^.DefaultPacketType > 3 Then Setup^.DefaultPacketType := 0;
             End;
        'S': Setup^.TwoLevelMenu := Not Setup^.TwoLevelMenu;
        'T': Setup^.AllowRip := Not Setup^.AllowRip;
        'U': Setup^.IncSelfInForced := Not Setup^.IncSelfInForced;
        'V': Setup^.Gloat := Not Setup^.Gloat;
        'W': Begin Inc(Setup^.MinuteCol); If Setup^.MinuteCol > 15 Then Setup^.MinuteCol := 0; End;
      End;
    Until Key In ['A'..'Z','0'..'9',#27];
  Until Key = #27;
End;

Procedure LimitsInfo;
Var
  Key: Char;
  Value: Longint;
  N: Byte;
  Result: Integer;
  Temp: String;
Begin
  RestoreScreen(1);
  DrawWindow(13,7,68,16,Lightgray);
  SetColor(LightGray);
  Writeln(' A)          Maximum messages per conference:');
  Writeln(' B) Maximum messages per packet at 1200 baud:');
  Writeln(' C)                                2400 baud:');
  Writeln(' D)     "      "      "            9600 baud:');
  Writeln(' E)                              14,400 baud:');
  Writeln(' F)     "      "      "          19,200 baud:');
  Writeln(' G)                              28,800 baud:');
  Write  (' H)     "      "      "     over 28,800 baud:');
  Repeat
    Window(61,8,67,15);
    SetColor(White);
    ClrScr;
    Writeln(Setup^.MaxConference);
    For Result := 1 To 6 Do Writeln(Setup^.MaxPacket[Result]);
    Write(Setup^.MaxPacket[7]);
    Key := Upcase(Readkey);
    If Key In ['A'..'H'] Then
      Begin
        N := Byte(Key)-65;
        If N = 0 Then Str(Setup^.MaxConference,Temp)
        Else Str(Setup^.MaxPacket[N],Temp);
        Gotoxy(1,N+1);
        GetString(Temp,5,15,Number);
        Val(Temp,Value,Result);
        If Result = 0 Then
          Begin
            If (Value < 1) Or (Value > 60000) Then Value := 60000;
            If N = 0 Then Setup^.MaxConference := Value
            Else Setup^.MaxPacket[N] := Value;
          End;
      End;
  Until Key = #27;
End;

Procedure DefineShortStyle;
Var
  Temp, s1, s2, s3, s4: String;
  Key: Char;
  Style, C, N: Word;
Begin
  RestoreScreen(1);
  DrawWindow(2,3,78,23,Lightgray);
  SetColor(Yellow);
  Window(4,4,77,23);
  Writeln('     Original         Style 1       Style 2       Style 3       Style 4');
  SetColor(LightGray);
  Writeln('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄ');
  Gotoxy(1,18);
  Writeln('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄ');
  SetColor(Yellow);
  Gotoxy(1,19);
  Write('(N)ext, (P)revious, (1-4) Style, (A)uto Internet, (S)hort Word, (C)ompress');
  N := 0;
  Style := Setup^.ShortStyle; If Style = 0 Then Style := 1;
  Key := 'P';
  Repeat
    Window(4,6,77,21);
    If Key In ['N','P','1','2','3','4','A','S','C'] Then
      Begin
        Gotoxy(1,1);
        For C := 1 To 15 Do
          Begin
            If Word(N)*15+Word(C) <= ZMaxAreas Then
              Begin
                Temp := AreaNames^[N*15+C]^;
                SetColor(White);
                Write(SpacePad(Temp,18));
                SetColor(LightGray); Write('³');
                If Not IsInternet(Temp) And Setup^.CapsWord Then Temp := CapsWord(Temp);
                If (Style = 1) And (Not IsInternet(Temp) Or Not Setup^.AutoInternet) Then SetColor(LightCyan);
                If Setup^.ShortWord Then Write(SpacePad(FirstWordLetter(Temp)+'-'+ShortWord(SecondWordString(Temp)),13))
                Else Write(SpacePad(FirstWordLetter(Temp)+'-'+SecondWordString(Temp),13));
                SetColor(LightGray); Write('³');
                If (Style = 2) And (Not IsInternet(Temp) Or Not Setup^.AutoInternet) Then SetColor(LightCyan);
                If Setup^.ShortWord Then Write(SpacePad(LastWordLetter(Temp)+'-'+Copy(ShortWord(Temp),1,11),13))
                Else Write(SpacePad(LastWordLetter(Temp)+'-'+Copy(Temp,1,11),13));
                SetColor(LightGray); Write('³');
                If (Style = 3) And (Not IsInternet(Temp) Or Not Setup^.AutoInternet) Then SetColor(LightCyan);
                If Setup^.ShortWord Then Write(SpacePad(ShortWord(Temp),13))
                Else Write(SpacePad(Temp,13));
                SetColor(LightGray); Write('³');
                If (Style = 4) Or (Setup^.AutoInternet And IsInternet(Temp)) Then SetColor(LightCyan);
                Write(SpacePad(InternetStyle(Temp),13));
              End
            Else
              Begin
                Gotoxy(1,C);
                SetColor(Lightgray);
                Write('³':19,'³':14,'³':14,'³':14,'':13);
              End;
          End;
      End;
    Key := Upcase(Readkey);
    Case Key Of
      'N': If (N+1)*15 < ZMaxAreas Then Inc(N) Else Key := '@';
      'P': If N > 0 Then Dec(N) Else Key := '@';
    '1'..'4': Style := Byte(Key)-48;
      'A': Setup^.AutoInternet := Not Setup^.AutoInternet;
      'S': Setup^.ShortWord := Not Setup^.ShortWord;
      'C': Setup^.CapsWord := Not Setup^.CapsWord;
    End;
  Until Key = #27;
  Setup^.ShortStyle := Style;
End;

Procedure MetaFileExists(st: String);
Var
  s: String;
Begin
  If Pos('*',st) > 0 Then
    Begin
      s := GetPath(st);
      If (Pos('*',s)=0) And Not IsPossible(s+'TMP.ZZZ') Then Fail
      Else
        Begin
          SetColor(LightCyan); Writeln(#8+#8+#8+#8+' Unknown');
        End;
    End
  Else If FileExists(st) Then Pass Else Fail;
End;

Procedure CheckConfiguration;
Var
  I, C: Byte;
  Temp: String;
Begin
  RestoreScreen(1);
  DrawWindow(6,4,75,22,Lightgray);
  Window(9,5,74,21);
  With Setup^ Do
  Begin
    SetColor(LightCyan);
    ClrScr;
    Writeln('Reminder: If the paths or settings contain metastrings such as');
    Writeln('*P or *G, then the test status may "Fail" or be "Unknown"');
    Writeln('since it cannot expand these until the program is running.');
    Writeln('Please manually check that the files will exist.');
    SetColor(Yellow);
    Writeln;
    Writeln('Testing file and path configuration');
    Writeln;
    Bullet('Local upload path'); If IsPossible(LocalULPath+'TMP.ZZZ') Then Pass Else Fail;
    Bullet('Local download path'); If IsPossible(LocalDLPath+'TMP.ZZZ') Then Pass Else Fail;
    Bullet('Log file'); If IsPossible(LogFile) Then Pass Else MetaFileExists(LogFile);
    Bullet('News file'); MetaFileExists(NewsFile);
    Bullet('Welcome file'); MetaFileExists(HelloFile);
    Bullet('Goodbye file'); MetaFileExists(GoodbyeFile);
    {$IFDEF BBS_RA1}
    Bullet('New files list'); MetaFileExists(FileBasePath);
    {$ENDIF}
    Bullet('Board ID'); If IsPossible(BoardID) Then Pass Else Fail;
    Writeln;
    Bullet('Press space to continue                                ');
    Readkey;
    SetColor(Yellow);
    ClrScr;
    Writeln('Testing for external programs existance');
    Writeln;
    Bullet('Unpack ARJ program'); If CanRun(Decompress[1]) Then Pass Else Fail;
    Bullet('Unpack LZH program'); If CanRun(Decompress[2]) Then Pass Else Fail;
    Bullet('Unpack ZIP program'); If CanRun(Decompress[3]) Then Pass Else Fail;
    Bullet('Unpack ARC program'); If CanRun(Decompress[4]) Then Pass Else Fail;
    Bullet('Unpack PAK program'); If CanRun(Decompress[5]) Then Pass Else Fail;
    Bullet('Unpack RAR program'); If CanRun(Decompress[6]) Then Pass Else Fail;
    Bullet('Pack ARJ program');   If CanRun(Compress[1])   Then Pass Else Fail;
    Bullet('Pack LZH program');   If CanRun(Compress[2])   Then Pass Else Fail;
    Bullet('Pack ZIP program');   If CanRun(Compress[3])   Then Pass Else Fail;
    Bullet('Pack ARC program');   If CanRun(Compress[4])   Then Pass Else Fail;
    Bullet('Pack PAK program');   If CanRun(Compress[5])   Then Pass Else Fail;
    Bullet('Pack RAR program');   If CanRun(Compress[6])   Then Pass Else Fail;
    Writeln;
    Bullet('Press space to continue                                ');
    Readkey;
    SetColor(Yellow);
    ClrScr;
    Writeln('Testing for external programs existance');
    Writeln;
    Bullet('Receive Xmodem program'); If CanRun(Receive[1]) Then Pass Else Fail;
    Bullet('Receive Ymodem program'); If CanRun(Receive[2]) Then Pass Else Fail;
    Bullet('Receive Zmodem program'); If CanRun(Receive[3]) Then Pass Else Fail;
    Bullet('Transmit Xmodem program'); If CanRun(Transmit[1]) Then Pass Else Fail;
    Bullet('Transmit Ymodem program'); If CanRun(Transmit[2]) Then Pass Else Fail;
    Bullet('Transmit Zmodem program'); If CanRun(Transmit[3]) Then Pass Else Fail;
    Writeln;
    Bullet('Press space to continue                                ');
    Readkey;
    For C := 1 To 2 Do
      Begin
        SetColor(Yellow);
        ClrScr;
        Writeln('Testing for bulletins existance ',C,'/2');
        Writeln;
        For I := 1 To 9 Do
          Begin
            Str(I+(c-1)*9:2,Temp);
            Bullet('Bulletin #'+Temp);
            SetColor(Yellow);
            If Bulletins[I+(C-1)*9] = '' Then Writeln('None')
            Else MetaFileExists(Bulletins[I+(C-1)*9]);
          End;
        Writeln;
        Bullet('Press space to continue                                ');
        Readkey;
      End;
  End;
End;

Procedure PS(A, B: String);
Begin
  SetColor(White);
  Write(A,' ');
  SetColor(Lightgray);
  Writeln(B);
End;

Procedure PN(A: String; Var B);
Begin
  TextColor(White);
  Write(A,' ');
  TextColor(Lightgray);
  Writeln(Word(B));
End;

Function ReturnFlags(Value: Byte): String;
Var
  Flag: String;
Begin
       If Value And fGENERAL  <> 0 Then Flag := 'g'
  Else If Value And fPERSONAL <> 0 Then Flag := 'p'
  Else If Value And fALL      <> 0 Then Flag := 'a'
  Else If Value And fCONNECT  <> 0 Then Flag := 'c'
  Else Flag := '.';
  If Value And fSELF    <> 0 Then Flag := Flag + 'w' Else Flag := Flag + '.';
  If Value And fKEYWORD <> 0 Then Flag := Flag + 'k' Else Flag := Flag + '.';
  If Value And fFILTER  <> 0 Then Flag := Flag + 'f' Else Flag := Flag + '.';
  If Value And fNETWORK <> 0 Then Flag := Flag + 'n' Else Flag := Flag + '.';
  ReturnFlags := Flag;
End;


{x$IFDEF PROVERSION}
{Procedure UserEditor;
Begin
  SwapShellMethod := $257;
  Shell(MainDir+'EDITOR.EXE');
End;}
{x$ELSE}
Procedure UserEditor;
Var
  b: Byte;
  i: Integer;
  l: Longint;
  O, OO, C, NumEntries, UserNumber: Word;
  Key2, Key: Char;
  U: USERrecord;
  fU: File;
  p: Byte;
  stSearch, Temp: String;
  ARC: Array['A'..'Z'] Of String[4];
  UCRC: Longint;
Begin
  ArcString  := 'ALZCPR';
  ProtString := '';
  For c := 1 To 6 Do ProtString := ProtString + Setup^.TransmitKeys[c];
  ARC['A'] := 'Arj';
  ARC['L'] := 'Lzh';
  ARC['Z'] := 'Zip';
  ARC['R'] := 'Rar';
  ARC['C'] := 'Arc';
  ARC['P'] := 'Pak';

  If Not OpenFile(fU,MainDir+'USERS.DAT','R',SIZE_USERS,faReadWrite+faDenyNone) Then Exit;
  RestoreScreen(1);
  DrawWindow(6,3,75,23,Lightgray);
  SetColor(Yellow);
  ClrScr;
  Writeln(' User editor');
  TextColor(DarkGray);
  Writeln('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
  Gotoxy(1,18);
  Write('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
  SetColor(Yellow);
  Write(' (N)ext, (P)revious, (F)ind.                     (*) Toggle delete');
  UserNumber := 0;
  Temp := '';
  stSearch := '';
  NumEntries := FileSize(fU);
  Key := 'P';
  With U Do
  Begin
    Repeat
      If Key In ['P','N','F'] Then
        Begin
          Seek(fU,UserNumber);
          {$I-}
          FillChar(U,sizeof(U),0);
          BlockRead(fU,U,1);
          If IoResult=0 Then ;
          {$I+}
          UCRC := crc32(U,Sizeof(U),$FFFFFFFF);
        End;
      Window(9,6,74,20);
      SetColor(White);
      Clrscr;
      Window(9,6,74,21);
      If U.Del Then PS('User name:',Name+', Deleted')
      Else PS('User name:',Name);
      PS('Last date:',LastDateDownload);
      PS('Last time:',LastTimeDownload);
      PS('#)    LID:',LocalName);
      PS('@) Format:',PacketFormatString[PacketType]);
      Writeln;
      p := Pos(Protocol,ProtString);
      If p = 0 Then Temp := 'Unknown' Else Temp := Setup^.TransmitNames[p];
      PS('A)       Archiver:',ARC[Archiver]);
      PS('B)       Protocol:',Temp);
      PS('C)       Password:','Not implemented');
      PN('D)      Downloads:',TotalDownloads);
      PN('E)  File requests:',TotalFilesDownloaded);
      PN('G)     Max/packet:',MaxPacket);
      PN('H) Max/conference:',MaxConference);
      PS('I) Use number ext:',YN(NumericExtension));
      PN('J) Current number:',CurrentExtension);
      Window(50,6,73,21);

      PS('K)         Indexes:',YN(Indexes));
      PS('L)           Files:',YN(Files));
      PS('M) Welcome Screens:',YN(GetWelcome));
      PS('O)            News:',YN(News));
      PS('Q) Global keywords:',YN(GlobalKeywords));
      PS('R) Global personal:',YN(GlobalPersonal));
      PS('S) Filter personal:',YN(FilterPersonal));
      PS('T)   Twit personal:',YN(TwitPersonal));
      PS('U) Short conf list:',YN(ShortList));
      PS('V)      High Ascii:',YN(UseHigh));
      PS('X)      ^A kludges:',YN(KeepKludge));
      PS('Y)   Ignore limits:',YN(IgnoreLimits));
      Writeln;
      TextColor(White); Writeln('!) Areas configuration'); Writeln('$) Save changes');
      Repeat
        Key := Upcase(Readkey);
        If Key = #0 Then
          Begin
            Key := Upcase(Readkey);
            Case Key Of
              'K': Key := 'P';
              'M': Key := 'N';
            Else Key := #199;
            End;
          End;
        If (Key In [#27,'F','N','P']) Then
          Begin
            If UCRC <> crc32(U,Sizeof(U),$FFFFFFFF) Then
              Begin
                StoreScreen(5);
                DrawWindow(22,11,58,15,Black+Lightgray*16);
                Writeln;
                WriteCenterString(34,' Save changes? (Y/n)');
                Key2 := Upcase(Readkey);
                If Key2 <> 'N' Then Key := '$';
                RestoreScreen(5);
              End;
          End;
      Until Key In [#27,'A'..'Y','@','$','!','#','*'];
      If Key In ['A'..'J'] Then Window(28,12,74,21);
      Case Key Of
        '!': Begin
               StoreScreen(5);
               DrawWindow(1,6,14,16,Lightblue+Blue*16);
               SetColor(White+Blue*16);
               Window(3,7,13,16);
               Write  ('.) Normal  ');
               Write  ('G) General ');
               Write  ('P) Personal');
               Write  ('A) All     ');
               Write  ('K) Keyword ');
               Write  ('F) Filter  ');
               Write  ('W) FromSelf');
               Write  ('N) Network ');
               Write  ('C) Connect ');
               DrawWindow(15,6,65,20,Lightgray);
               O := 0;
               L := 0;
               Repeat
                 OO := O;
                 Gotoxy(1,1);
                 For C := 1 To 13 Do
                   Begin
                     TextColor(White);
                     Write('  ',SpacePad(AreaNames^[C+O]^,38));
                     TextColor(LightGray);
                     Write(' '+ReturnFlags(Flags[AreaNumbers^[C+O]]));
                     If C <> 13 Then Writeln;
                   End;
                 TextColor(Yellow);
                 Gotoxy(2,L+1); Write(#26);
                 Gotoxy(47,L+1); Write(#27);
                 Repeat
                   Key := Upcase(Readkey);
                   Gotoxy(2,L+1); Write(' ');
                   Gotoxy(47,L+1); Write(' ');
                   If Key = #0 Then
                   Begin
                   Key := Readkey;
                   Case Key Of
                     'G': Begin O:= 0; L:=0; End;
                     'O': Begin O:= ZMaxAreas-13; L:=12; End;
                     'I': Begin If O>13 Then Dec(O,13) Else O := 0; L := 0; End;
                     'Q': Begin If O<ZMaxAreas-26 Then Inc(O,13) Else O := ZMaxAreas-13; L := 12; End;
                     'P': Begin
                           Inc(L);
                           If L > 12 Then
                             Begin
                               L := 12;
                               If O+13 < ZMaxAreas Then Inc(O);
                             End;
                          End;
                     'H': Begin
                           If L = 0 Then
                             Begin
                               L := 0;
                               If O > 0 Then Dec(O);
                             End
                           Else Dec(L);
                          End;
                   End;
                   End
                   Else
                   Begin
                     b := Flags[AreaNumbers^[O+L+1]];
                     Case Key Of
                       '.': b := 0;
                       'N': b := (b Xor fNETWORK) And fNETWORK;
                       'C': b := ((b Xor fCONNECT) And 192) Or (b Xor fNETWORK) And fNETWORK;
                       'A': b := b And 56 + fALL;
                       'P': b := b And 56 + fPERSONAL;
                       'G': b := b And 56 + fGENERAL;
                       'W': If (b And fNETWORK) = 0 Then b := b Xor fSELF;
                       'K': If (b And fNETWORK) = 0 Then b := b Xor fKEYWORD;
                       'F': If (b And fNETWORK) = 0 Then b := b Xor fFILTER;
                     End;
                     Flags[AreaNumbers^[O+L+1]] := b;
                   End;
                   Gotoxy(2,L+1); Write(#26);
                   Gotoxy(47,L+1); Write(#27);
                 Until (Key In [#27,'.','W','N','C','A','G','P','K','F']) Or (O<>OO);
               Until Key = #27;
               Key := #0;
               RestoreScreen(5);
               SetColor(White);
             End;
        '*': Begin
               U.Del := Not U.Del;
             End;
        '$': Begin
               UCRC := crc32(U,Sizeof(U),$FFFFFFFF);
               Seek(fU,UserNumber);
               BlockWrite(fU,U,1);
             End;
        '#': Begin
                 Window(20,9,74,21);
                 GetString(LocalName,8,White,Upper);
             End;
        '@': Begin
               Inc(PacketType);
               If PacketType > 3 Then PacketType := 0;
             End;
        'A': Begin
               If Archiver = 'A' Then Archiver := 'L'
               Else If Archiver = 'L' Then Archiver := 'Z'
               Else If Archiver = 'Z' Then Archiver := 'R'
               Else If Archiver = 'R' Then Archiver := 'C'
               Else If Archiver = 'C' Then Archiver := 'P'
               Else Archiver := 'A';
             End;
        'B': Begin
               p := Pos(Protocol,ProtString);
               Repeat
                 Inc(p);
               Until (p>6) Or (ProtString[p]<>' ');
               If p>6 Then p := 1;
               Protocol := ProtString[p];
             End;
        'D': Begin
               Repeat
                 Gotoxy(1,4);
                 Str(TotalDownloads,Temp);
                 GetString(Temp,5,White,Number);
                 Val(Temp,l,i);
               Until (i = 0) And (l<=65000);
               TotalDownloads := l;
             End;
        'E': Begin
               Repeat
                 Gotoxy(1,5);
                 Str(TotalFilesDownloaded,Temp);
                 GetString(Temp,5,White,Number);
                 Val(Temp,l,i);
               Until (i = 0) And (l<=65000);
               TotalFilesDownloaded := l;
             End;
        'G': Begin
               Repeat
                 Gotoxy(1,6);
                 Str(MaxPacket,Temp);
                 GetString(Temp,5,White,Number);
                 Val(Temp,l,i);
               Until (i = 0) And (l<=65000);
               MaxPacket := l;
             End;
        'H': Begin
               Repeat
                 Gotoxy(1,7);
                 Str(MaxConference,Temp);
                 GetString(Temp,5,White,Number);
                 Val(Temp,l,i);
               Until (i = 0) And (l<=65000);
               MaxConference := l;
             End;
        'J': Begin
               Repeat
                 Gotoxy(1,9);
                 Str(CurrentExtension,Temp);
                 GetString(Temp,2,White,Number);
                 Val(Temp,l,i);
               Until (i = 0);
               CurrentExtension := l;
             End;
        'I': NumericExtension := Not NumericExtension;
        'K': Indexes := Not Indexes;
        'L': Files := Not Files;
        'M': GetWelcome := Not GetWelcome;
        'O': News := Not News;
        'Q': GlobalKeywords := Not GlobalKeywords;
        'R': GlobalPersonal := Not GlobalPersonal;
        'S': FilterPersonal := Not FilterPersonal;
        'T': TwitPersonal := Not TwitPersonal;
        'U': ShortList := Not ShortList;
        'V': UseHigh := Not UseHigh;
        'X': KeepKludge := Not KeepKludge;
        'Y': IgnoreLimits := Not IgnoreLimits;
        'F': Begin
               StoreScreen(5);
               DrawWindow(20,10,60,15,Black+Lightgray*16);
               WriteCenterString(38,' Search user');
               WriteLines(1);
               WriteString('          ');
               GetString(stSearch,20,15,Upper);
               SetColor(Black+Lightgray*16);
               Seek(fU,0);
               For C := 0 To NumEntries-1 Do
                 Begin
                   {$I-}
                   BlockRead(fU,U,1);
                   {$I+}
                   If (IoResult=0) And (Pos(stSearch,UpcaseStr(U.Name)) <> 0) Then
                     Begin
                       WriteChar(#13);
                       WriteCenterString(37,' '+U.Name+', (Y/n)');
                       Key := Upcase(Readkey);
                       If Key <> 'N' Then
                         Begin
                           UserNumber := C;
                           C := NumEntries-1;
                         End;
                     End;
                 End;
               RestoreScreen(5);
               SetColor(White);
               Key := 'P';
             End;
        'P': If UserNumber >0 Then Dec(UserNumber);
        'N': If UserNumber < NumEntries-1 Then Inc(UserNumber);
      End;
    Until Key = #27;
  End;
End;
{x$ENDIF}

Procedure RequestSetup;
Var
  Key: Char;
  GenReq: Boolean;
  Temp: String[10];
  Code: Integer;
  Value: Word;
Begin
  If Byte(Setup^.AllowDownloadAttach )>1 Then Setup^.AllowDownloadAttach  := False;
  If Byte(Setup^.DownloadAttachFree  )>1 Then Setup^.DownloadAttachFree   := False;
  If Byte(Setup^.DownloadAttachNoTime)>1 Then Setup^.DownloadAttachNotime := False;
  RestoreScreen(1);
  DrawWindow(15,10,66,16,Lightgray);
  SetColor(LightGray);
  Writeln(' A)   Allow users to request general files:');
  Writeln(' B)     ÓÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Daily maximum:');
  Writeln(' C)   Allow users to request file attaches:');
  Writeln(' D)     ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Free:');
  Write  (' E)     ÓÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Notime:');
  If Setup^.AllowFiles>0 Then GenReq := True Else GenReq := False;
  Repeat
    Window(61,11,65,15);
    SetColor(White);
    ClrScr;
    Writeln(YN(GenReq));
    If Not GenReq Then Writeln Else Writeln(Setup^.AllowFiles);
    Writeln(YN(Setup^.AllowDownloadAttach));
    If Setup^.AllowDownloadAttach Then
      Begin
        Writeln(YN(Setup^.DownloadAttachFree));
        Write(YN(Setup^.DownloadAttachNotime));
      End;
    If GenReq And (Setup^.AllowFiles=0) Then Key := 'B'
    Else
    Repeat
      Key := Upcase(Readkey);
    Until Key In ['A'..'E',#27];
    Case Key Of
      'A': GenReq := Not GenReq;
      'B': Begin
             Gotoxy(1,2); Writeln('    '); Gotoxy(1,2);
             Str(Setup^.AllowFiles,Temp);
             GetString(Temp,2,15,Number);
             Val(Temp,Value,Code);
             If Value>MaxRequests Then Value := MaxRequests;
             Setup^.AllowFiles := Value;
             If Value = 0 Then GenReq := False;
           End;
      'C': Setup^.AllowDownloadAttach  := Not Setup^.AllowDownloadAttach;
      'D': Setup^.DownloadAttachFree   := Not Setup^.DownloadAttachFree;
      'E': Setup^.DownloadAttachNoTime := Not Setup^.DownloadAttachNotime;
    End;
  Until Key = #27;
  If Not GenReq Then Setup^.AllowFiles := 0;
End;

Procedure MainMenu;
Var
  Key: Char;
Begin
  CheckRegs;
  StoreScreen(1);
  DrawWindow(24,4,56,22,Lightgray);
  SetColor(Yellow);
  Writeln;
  CenterString(32,'Main Menu');
  Writeln;
  SetColor(White);
  Writeln('   S)ystem Information');
  Writeln('   A)rchiver Programs');
  Writeln('   P)rotocol Programs');
  Writeln('   F)iles Configuration');
  Writeln('   B)ulletins');
  Writeln('   C)ontrol Setup');
  {$IFDEF BBS_FILEREQUEST}
  Writeln('   R)equesting Control');
  {$ENDIF}
  Writeln('   L)imits Setup');
  Writeln('   D)efine Shortname Style');
  Writeln('   M)ulti-language Setup');
  Writeln('   U)ser Editor');
  Writeln('   T)est Current Setup');
  Writeln('   Q)uit Setup');
  StoreScreen(2);
  Repeat
    RestoreScreen(2);
    Repeat
      Key := Upcase(Readkey);
      Case Key Of
        'S': SystemInfo;
        'A': ArcPrograms;
        'P': ProtPrograms;
        'F': FilesConfig;
        'B': BulletinConfig;
        'C': ControlSetup;
        'L': LimitsInfo;
        'D': DefineShortStyle;
        'T': CheckConfiguration;
        {$IFDEF BBS_FILEREQUEST}
        'R': RequestSetup;
        {$ENDIF}
        'M': PickLang;
        'U': UserEditor;
      End;
      If Key In ['M','R','S','A','P','F','B','C','L','D','T','U'] Then
        Begin
          RestoreScreen(2);
          CheckRegs;
          StoreScreen(2);
        End;
      CursorHide;
    Until Key In ['Q',#27];
    If CFGCRC <> crc32(Setup^,Sizeof(Setuprecord),$FFFFFFFF) Then
      Begin
        RestoreScreen(1);
        DrawWindow(29,11,51,15,Lightgray+Red*16);
        Writeln;
        SetColor(White+Red*16);
        Write(' Save Changes (Y/N)');
        Repeat
          Key := Upcase(Readkey);
        Until Key In ['N','Y',#27];
        If Key = 'Y' Then WriteConfig;
      End
    Else Key := 'N';
  Until Key In ['N','Y'];
  ClearHalt;
End;

{$F+}
Procedure Ending;
Begin
  CursorView;
  ExitProc := Saved;
  For MainCounter := 1 To AreaRange Do Dispose(AreaNames^[MainCounter]);
  For MainCounter := 1 To MaxLang Do
    Begin
      Dispose(LanguageText[1][MainCounter]);
      Dispose(LanguageText[2][MainCounter]);
    End;
  Dispose(AreaNames);
  Dispose(AreaNumbers);
  Dispose(Setup);
End;
{$F-}

Procedure UserINFScan;
Var
  fUSRDAT: File;
Begin
  UserAreas := MaxAreas;
  {$IFDEF PROVERSION}
  If OpenFile(fUSRDAT,MainDir+'USERS.INF','R',1,faReadOnly+faDenyNone) Then
    Begin
      BlockRead(fUSRDAT,UserAreas,2);
      CloseFile(fUSRDAT);
    End;
  {$ENDIF}
  If UserAreas>MaxAreas Then UserAreas := MaxAreas;
  SIZE_USERS := Sizeof(USERrecord) - (MaxAreas-UserAreas);
  If SizeofFile(MainDir+'USERS.DAT') MOD SIZE_USERS <> 0 Then
    Begin
      Note('<!> USERS.INF corrupt size mismatch');
      ClearHalt;
    End;
  If UserAreas<HighSize Then Note('Warning! Supported areas is less than actual high area');
End;

Begin

{  If Pos('.',Version)>0 Then SetupVersion := Version
  Else SetupVersion := Version+'.0'; }
  SetupVersion := Version;
  {$IFDEF BBS_RA1}
  SetupVersion := SetupVersion + '.111';
  {$ENDIF}

  RA250 := False;
  WatchUserTime := False;

  GRegs.Ah := $0F;
  Intr($10,GRegs);
  If (GRegs.Al In [0..3]) Then VideoAddress := $B800
  Else VideoAddress := $B000;

  FileMode := $42;
  MainDir := GetPath(ParamStr(0));
  If Length(MainDir)<3 Then GetDir(0,MainDir);
  PutTrail(MainDir);

  {$IFNDEF BBS_RA2}
  CrossConfiguration(MainDir);
  {$ENDIF}

  CursorHide;
  MainScreen;
  Saved    := ExitProc;
  ExitProc := @Ending;
  AreaNames   := New(pAreaNames);
  AreaNumbers := New(pAreaNumbers);
  Setup       := New(pSETUPrecord);
  For Zmaxareas := 1 To AreaRange Do AreaNames^[Zmaxareas] := New(pStr40);

  For MainCounter := 1 To MaxLang Do
    Begin
      LanguageText[1][MainCounter] := New(RPBuf);
      LanguageText[2][MainCounter] := New(RPBuf);
    End;

  CheckConfig;
  LoadConfig;
  Setup^.Marked286 :=(1333105144)+$2D1E;
  Setup^.Marked86 := (2125635314)+$D1E;

  {$IFDEF PROVERSION}
  If Setup^.ProActivated<>224 Then
    Begin
      Setup^.ProActivated := 224;
      Setup^.ProDated     := PresentDay;
    End;
  {$ENDIF}

  UserINFScan;
  Notice;
  MainMenu;
End.ÿÿÿ