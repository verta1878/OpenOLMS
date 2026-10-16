Unit U_UNIT;

Interface

{$I BBSTYPE.INC}

Uses DM6000, U_LANG, U_NEW, FHANDLES, JAMCRC32, Crt, Dos;
{$V-}

Function  FileDate(FileName: String): Longint;
Function  ValueString(st: String): Word;
Function  ReturnSettings(Conf: Word; Var dCFG: MESSAGErecord): String;
Function  ReturnPackDate: Longint;
Procedure AutoLogoff;
Procedure DisplayInfo(Info, Value: String);
Procedure CheckShare;
Procedure CloseMessage;
Function  ReturnFlags(Value: Byte; Conf: Word): String;
Function  CreateWorkSpace: Boolean;
Procedure EraseWorkSpace;
Procedure PressSpace;
Procedure BulletError(st: String);
Function  EstimateTime(l: Longint): Longint;
Procedure Bullet(ColorIndex: Byte);
Function  BufferedCopyFile(Src, Dst: String): Boolean;
Function  GotoWelcome: Char;
Function  GotoFilescan: Char;
Function  GotoLogoff: Char;
Procedure LoadMenuKeys;
Function  SearchBack(st: String): String;
Function  DosShell(a,b: Byte; CommandLine: String): Word;
Procedure RegMessage;
Function  IsAttachedName(Var st: String): Boolean;
Function  PackFile(stPath, stName: String): Boolean;
Procedure EditRequested;
Function  DownloadRequested: Boolean;
Function  ExTimedYesNo(Default: Char; Sec: Integer): Char;
Procedure SelectBulletins;
Procedure ChangePacketFormat;
Procedure ChangeArchiver;
Procedure SelectKeywords;
Procedure ViewSettings(Alias: String; MAXPPACK, MAXPCONF: Word);
Function  NoteDisabled: Char;
Procedure DrawLine;
Procedure Display(Filename, GoodChars: String);
Function  Changer(st: String): Boolean;
Procedure ChangeProtocol;
Procedure ChangeLimits(Var MAXPPACK, MAXPCONF: Word);
Procedure DoColor(c: Byte);
Procedure TwoPrompt(s1, s2: String);
Procedure FourPrompt(s1, s2, s3, s4: String);
Function  IsNew(FileName: String): Boolean;
Function  GetBulletin(w: Byte): Boolean;
Function  LettersOnly(st: String): String;
Function  ReturnIncludes(Var Includes: Array Of Boolean; st: String; HighConf: Word): Boolean;
Function  LastWordLetter(st: String): Char;
Function  FirstWordLetter(st: String): Char;
Function  SecondWordString(st: String): String;
Function  ShortWord(st: String): String;
Function  CapsWord(st: String): String;
Function  InternetStyle(st: String): String;
Function  IsInternet(st: String): Boolean;
Function  ExpandFileMetaString(CommandLine, Filename: String): String;
Procedure LoadConfigFiles(Var TaglineSize: Longint; Var DefaultOriginLine: String);
Procedure Logit(Level: Char; st: String);
Procedure GoodBye;
Function  LoadLocalUser(Name: String): Boolean;
Procedure SaveLocalUser(Name: String);
Function  NodeCost(st: String; Zone, Net, Node: Word): Word;
Function  NewFiles: Word;
Function  IsArea(Sec: Word; Flag, NotFlag: FlagType): Boolean;
Function  SeeGroup(Group, Group1, Group2, Group3: Word; Atr, Mask: Byte): Boolean;
Function  HasSysopRightsArea(Var CFG: MESSAGErecord; Conf: Word): Boolean;
Function  VisableArea(Var CFG: MESSAGErecord; Conf: Word): Boolean;
Function  WritableArea(Var CFG: MESSAGErecord; Conf: Word): Boolean;
Function  DetectArc(FileName: String): Char;
Function  LANG(Index: Word): String;
Function  BKT(Index: Word): String;
Function  CheckReg(SystemName, Sysop, Serial, Registration: String): Boolean;
Procedure LoadOLF(n: Byte);
Procedure ValidateFiles;
Procedure ReindexUsers;
Procedure TruncateFile(st: String);
Procedure CheckPackMaybe(Var WhoTo, WhoFrom: String; Flags: Byte; Pvt: Boolean; Var Pack, Maybe, Personal: Boolean);
Function  CheckIsAll(Var WhoTo: String): Boolean;

Implementation

Function FileDate(FileName: String): Longint;
Var
  d: SearchRec;
Begin
  FindFirst(FileName,255,d);
  If (DosError=0) Then FileDate := d.Time
  Else FileDate := 0;
End;

Function CreateWorkSpace: Boolean;
Begin
  ChangeDirectory(MainDir);
  KillDirectory(WorkDir);
  If MakeDirectory(WorkDir) And ChangeDirectory(WorkDir) Then CreateWorkSpace := True
  Else
    Begin
      DoColor(COL_ERROR);
      WriteLines(2);
      WriteStringCF(ProgramName+LANG(L_WorkError1));
      WriteStringCF(LANG(L_WorkError2)+LANG(L_Inform));
      LogIt('C','<!> Could not create workspace');
      WriteLines(1);
      PressSpace;
      CreateWorkSpace := False;
    End;
End;

Procedure EraseWorkSpace;
Begin
  ChangeDirectory(MainDir);
  KillDirectory(WorkDir);
End;

Procedure CloseMessage;
Begin
  ClearScreen;
  If (User.Emulation=RIP) Then TxStringCF(#13+'!|e|E|1K|w0000270M00'+#13);
  WaitSendBufferClear;
  WriteLines(1);
  WriteStringCF(LANG(L_Returning)+Setup^.SystemName+'...');
End;

Procedure PressSpace;
Begin
  If Not Wait Then Exit;
  Bullet(COL_PRESSSPACE); WriteString(LANG(L_PressSpace));
  Repeat Until Getchar In [HotKey[L_PressSpace],#13,'.'];
  WriteLines(1);
End;

Procedure BulletError(st: String);
Begin
  Bullet(COL_ERROR); WriteStringCF(st);
  WriteLines(1);
  PressSpace;
End;

Function EstimateTime(l: Longint): Longint;
Var
  r: Longint;
Begin
  If Baud >= 9600 Then r := 150 Else r := 0;
  If Baud > 0 Then EstimateTime := l DIV Longint((Longint(Baud) * Longint(950 + r)) DIV 10000)
  Else EstimateTime := 0;
End;

Function Is(a,b: Word): Boolean; (* DUPE! *)
Begin
  Is := (A And B) = B;
End;

Procedure Bullet(ColorIndex: Byte);
Begin
  SetColor(Colors[ColorIndex]);
  WriteString('      ');
End;

Function IsNew(FileName: String): Boolean;
Var
  d: SearchRec;
  Day, Month, Year: Word;
  i: Integer;
  DT: DateTime;
  l: Longint;
Begin
  If Human^.LastDateDownload='None' Then
    Begin
      IsNew := True;
      Exit;
    End;
  FillChar(DT,Sizeof(DT),0);
  Val(Copy(Human^.LastDateDownload,1,2),DT.Month,i);
  Val(Copy(Human^.LastDateDownload,4,2),DT.Day,i);
  Val(Copy(Human^.LastDateDownload,7,2),DT.Year,i);
  Inc(DT.Year,1900); If(DT.Year<1940) Then Inc(DT.Year,100); {!Y2KOK!}
  PackTime(DT,l);
  FindFirst(FileName,255,d);
  If (DosError=0) And (d.Time > l) Then IsNew := True
  Else IsNew := False;
End;

Function ReturnStringDate(l: Longint): String; (* PRIVATE *)
Var
  DT: DateTime;
Begin
  UnpackTime(l,DT);
  ReturnStringDate := ZeroPad(DT.Month,2)+'-'+ZeroPad(DT.Day,2)+'-'+ZeroPad(DT.Year Mod 100,2);
End;

Function GetBulletin(w: Byte): Boolean;
Begin
  If (Setup^.Bulletins[w] <> '')
  And ((Setup^.BulletinFlags[w]<>bNEWONLY) Or IsNew(Setup^.Bulletins[w]))
  And (Is(Human^.Bulletins[w DIV 8],1 Shl (w MOD 8)) Or (Setup^.BulletinFlags[w]=bFORCED))
  And (Setup^.BulletinFlags[w]<>bINACTIVE) Then GetBulletin := True
  Else GetBulletin := False;
End;

Function LettersOnly(st: String): String;
Var
  nst: String;
  by: Byte;
Begin
  nst := '';
  For by := 1 To Length(st) Do
    If Upcase(st[by]) In ['A'..'Z'] Then nst := nst + st[by];
  LettersOnly := nst;
End;

Function ReturnIncludes(Var Includes: Array Of Boolean; st: String; HighConf: Word): Boolean;
Var
  LocMem, Count, bc, Loc: Word;
  m, Start: Byte;
  b: Boolean;
  Code: Integer;
Begin
  FillChar(Includes,Sizeof(Includes),0);
  ReturnIncludes := False;
  If st = '' Then Exit
  Else If st = 'ALL' Then
    Begin
      For Count := 1 To HighConf Do Includes[Count] := True;
      ReturnIncludes := True;
      Exit;
    End;

  For Count := 1 To Length(st) Do If st[Count] In ['.',',','/','\'] Then st[Count] := ' ';
  st := st + ' ';
  Start := 1;
  m := 0;
  b := False;
  Loc:= 0;
  For Count := 1 To Length(st) Do
    Begin
      If st[Count] In [' ','-'] Then
        Begin
          If st[Count] = '-' Then
            Begin
              st[Count] := ' ';
              b := True;
              m := 1;
            End
          Else If b Then
            Begin
              b := False;
              m := 2;
            End;
          LocMem := Loc;
          Val(Copy(st,Start,Count-Start),Loc,Code);
          If (m=0) And (Loc<=HighConf) Then Includes[Loc] := True
          Else If (m=1) Then LocMem := Loc
          Else If (m=2) Then
            Begin
              If LocMem<1 Then LocMem := 1
              Else If LocMem>HighConf Then LocMem := HighConf;
              If Loc<1 Then Loc := 1
              Else If Loc>HighConf Then Loc:= HighConf;
              For bc := LocMem To Loc Do Includes[bc] := True;
              m := 0;
            End;
          Start := Count+1;
        End;
    End;
  For Count := 1 To HighConf Do If Includes[Count] Then ReturnIncludes := True;
End;

Function ShortWord(st: String): String;
Var
  nst: String;
  b: Byte;
Begin
  nst := '';
  Repeat
    b := Pos(' ',st);
    If b>0 Then
      Begin
        If b<5 Then nst := nst + Copy(st,1,b-1) + ' '
        Else nst := nst + Copy(st,1,4) + ' ';
        st := Copy(st,b+1,255);
      End;
  Until b = 0;
  ShortWord := nst+st;
End;

Function CapsWord(st: String): String;
Var
  nst, wst, cst: String[100];
  c, NumCaps: Byte;
Begin
  nst := '';
  wst := '';
  cst := '';
  NumCaps := 0;
  For c := 1 To Length(st) Do
    Begin
      If st[c] = ' ' Then
        Begin
          If NumCaps > 1 Then nst := nst + cst + ' '
          Else nst := nst + wst + ' ';
          NumCaps := 0;
          wst := '';
          cst := '';
        End
      Else
        Begin
          wst := wst + st[c];
          If st[c] In ['A'..'Z'] Then
            Begin
              Inc(NumCaps);
              cst := cst + st[c];
            End;
        End;
    End;
  If NumCaps > 1 Then nst := nst + cst + ' '
  Else nst := nst + wst + ' ';
  CapsWord := Copy(nst,1,Length(nst)-1);
End;

Function LastWordLetter(st: String): Char;
Var
  O, C: Byte;
  K: Char;
Begin
  K := '?';
  For C := Length(st)-1 Downto 1 Do
    If (st[C] = ' ') And (K = '?') Then
      Begin
        K := Upcase(st[C+1]);
        O := 0;
        While Not (K In ['A'..'Z']) And (C+O < Length(st)) Do
          Begin
            Inc(O);
            K := Upcase(st[C+O]);
          End;
      End;
  LastWordLetter := K;
End;

Function FirstWordLetter(st: String): Char;
Var
  N: Byte;
  K: Char;
Begin
  K := '?';
  For N := 1 To Length(st) Do
    If (K='?') And (Upcase(st[N]) In ['A'..'Z']) Then K := Upcase(st[N]);
  FirstWordLetter := K;
End;

Function SecondWordString(st: String): String;
Var
  L, N: Byte;
  b: Boolean;
Begin
  b := True;
  L := 0;
  For N := 1 To Length(st) Do
    Begin
      If Not b And (st[N] In ['0'..'9','A'..'Z']) And (L=0) Then L := N;
      If st[N] = ' ' Then b := False;
    End;
  SecondWordString := Copy(st,L,255);
End;

Function InternetStyle(st: String): String;
Var
  L, N: Byte;
  nst: String;
Begin
  nst := '';
  For N := 1 To Length(st) Do If st[N] In ['.','/','\',' ',':','-','_','0'..'9','A'..'Z','a'..'z'] Then nst := nst + st[N];
  st := nst;
  nst := '';
  L := 1;
  For N := 2 To Length(st) Do
    Begin
      If st[N] In ['.','/','\',' ',':'] Then
        Begin
          nst := nst + st[L];
          L := N + 1;
        End;
    End;
  nst := nst + '-' + Copy(st,L,255);
  InternetStyle := DowncaseStr(nst);
End;

Function IsInternet(st: String): Boolean;
Begin
  If ((DowncaseStr(st) = st) And (Pos('.',st) <> 0 ))
  Or ((Pos('.',st) <> 0) And (Pos(' ',Copy(st,Pos('.',st)+1,255))=0)) Then IsInternet := True
  Else IsInternet := False;
End;

Function ExpandFileMetaString(CommandLine, Filename: String): String;
Var
  Loc: Byte;
Begin
  Loc := Pos('*F',UpcaseStr(CommandLine));
  If Loc = 0 Then ExpandFileMetaString := CommandLine + ' ' + Filename
  Else ExpandFileMetaString := Copy(CommandLine,1,Loc-1) + Filename
                               + Copy(CommandLine,Loc+2,255);
End;

Procedure LoadConfigFiles(Var TaglineSize: Longint; Var DefaultOriginLine: String);
Var
 f: File;
 fRACFG: File;
 dRACFG: CONFIGrecord;
 st: String;
 Count, by: Byte;
 i: Integer;
 t: Text;
 TempColors: Array[0..MaxColors] Of Byte;
 Usedefault: Boolean;
Begin
  {$IFDEF BBS_RA2}
  st := GetEnv('RA');
  If st = '' Then
    Begin
      Writeln;
      Writeln('Enviroment variable "RA" not set!');
      Sleep(3);
      NewHalt(5000);
    End;
  PutTrail(st);
  {$ELSE}
  st := MainDir;
  {$ENDIF}

  If  OpenFile(f,MainDir+'OLMS.CFG','R',Sizeof(SETUPrecord),faReadOnly+faDenyNone)
  And OpenFile(fRACFG,st+'CONFIG.'+BBS_CC,'R',Sizeof(CONFIGrecord),faReadOnly+faDenyNone)
  Then
    Begin
      {$I+}
      BlockRead(f,Setup^,1);
      BlockRead(fRACFG,dRACFG,1);
      CloseFile(f);
      CloseFile(fRACFG);

      If Setup^.InsertTag Then
        Begin
          If Setup^.TagFile <> '' Then TagLineSize := SizeofFile(Setup^.TagFile)
          Else Setup^.InsertTag := False;
          If TagLineSize < 10 Then Setup^.InsertTag := False;
        End;

      DefaultOriginLine  := dRACFG.OriginLine;
      Setup^.LogExpanded  := Boolean(dRACFG.LogStyle=0);
      Setup^.Nodelistpath := dRACFG.NodelistPath;
                            ExpandMetaString(Setup^.NodelistPath);
                            PutTrail(Setup^.NodelistPath);
      Setup^.MsgBasePath  := dRACFG.MsgBasePath;
                            ExpandMetaString(Setup^.MsgBasePath);
                            PutTrail(Setup^.MsgBasePath);
      Setup^.MainPath     := st;

      (* Incase user has not run SETUP, enforce netmail restrictions *)
      If Setup^.GoodValue < 2511 Then
        Begin
          Setup^.NetmailCrash  := 65535;
          Setup^.NetmailFatch  := 65535;
          Setup^.NetmailHold   := 65535;
          Setup^.NetmailImm    := 65535;
          Setup^.NetmailFreq   := 65535;
          Setup^.NetmailDirect := 65535;
        End;
      If Setup^.GoodValue < 2522 Then Setup^.MinuteCol := 7;

      {$IFDEF BBS_RA2}
      Setup^.FileBasePath := dRACFG.FileBasePath;
      ExpandMetaString(Setup^.FileBasePath);
      PutTrail(Setup^.FileBasePath);
      {$ENDIF}

      For Count := 1 To 6  Do
        Begin
          ExpandMetaString(Setup^.Compress[Count]);
          ExpandMetaString(Setup^.Decompress[Count]);
          ExpandMetaString(Setup^.Transmit[Count]);
          ExpandMetaString(Setup^.Receive[Count]);
        End;
      For Count := 1 To MaxBull Do ExpandMetaString(Setup^.Bulletins[Count]);

      ExpandMetaString(Setup^.LocalULPath); PutTrail(Setup^.LocalULPath);
      ExpandMetaString(Setup^.LocalDLPath); PutTrail(Setup^.LocalDLPath);
      ExpandMetaString(Setup^.NewsFile);
      ExpandMetaString(Setup^.GoodbyeFile);
      ExpandMetaString(Setup^.HelloFile);
      ExpandMetaString(Setup^.LogFile);

      For Count := 0 To 9 Do
        Begin
          Setup^.Address[Count].Zone := dRACFG.Address[Count].Zone;
          Setup^.Address[Count].Net  := dRACFG.Address[Count].Net;
          Setup^.Address[Count].Node := dRACFG.Address[Count].Node;
          Setup^.Address[Count].Point:= dRACFG.Address[Count].Point;
        End;
    End
  Else
    Begin
      Writeln('Error opening configuration files!');
      Sleep(3);
      NewHalt(5001);
    End;

       If Baud =     0 Then BaudRange := 0
  Else If Baud <  2400 Then BaudRange := 1
  Else If Baud <  9600 Then BaudRange := 2
  Else If Baud < 14400 Then BaudRange := 3
  Else If Baud < 19200 Then BaudRange := 4
  Else If Baud < 28800 Then BaudRange := 5
  Else If Baud < 38400 Then BaudRange := 6
  Else                      BaudRange := 7;

  Reg := CheckReg(Setup^.SystemName,Setup^.Sysop,Setup^.Serial,Setup^.Registration);
  If Not Reg Then Begin Setup^.Serial := MSG_EVALUATE; MaxNodesSupported := 10; End
             Else Setup^.Serial := UpcaseStr(Setup^.Serial);

  If Reg And OpenText(t,SearchBack('OLMS.COL'),'R',faReadOnly+faDenyNone) Then
    Begin
      Count := 0;
      {$I-}
      While (IoResult=0) And (Count<=30) And Not Eof(t) Do
        Begin
          st := 'X';
          Readln(t,st);
          If st[1] In ['0'..'9'] Then
            Begin
              TempColors[Count] := ValueString(st);
              Inc(Count);
            End;
        End;
      {$I+}
      If Count <> 31 Then
        Begin
          Logit('C','Error in color definition file: '+SearchBack('OLMS.COL'));
          Usedefault := True;
        End
      Else Usedefault := False;
      CloseText(t);
    End
  Else Usedefault := True;

  XorReg := NotReg Xor Reg;

  If Not Usedefault Then
    For Count := 0 To MaxColors Do Colors[Count] := TempColors[Count];
End;

Function LockFileHandle(h: Integer; On: Boolean): Integer;
Begin
  If LockHandle(h,0,1,On) Then LockFileHandle := 0 Else LockFileHandle := -1;
End;


Procedure CheckShare;
Var
  Handle, Locked: Integer;
Begin
  If Setup^.SingleNodeFlag = 200
  Then MultiNode := False
  Else MultiNode := True;
  {If Not MultiNode Then Logit('D','DEBUG: Single node confirmed');}

  (* Test for share.exe *)
  KillFile(MainDir+'LOCKTEST.$$$');
  CreateFile(MainDir+'LOCKTEST.$$$');
  Handle := OpenHandle(MainDir+'LOCKTEST.$$$');
  If Handle > 0 Then
    Begin
      Locked := LockFileHandle(Handle,True);
      If Locked <> -1 Then LockFileHandle(Handle,False);
      CloseHandle(Handle);
    End;
  KillFile(MainDir+'LOCKTEST.$$$');

  If (SizeofFile(MainDir+'OLMS.CFG') <> Sizeof(SETUPrecord)) Then
    Begin
      Logit('C','<!> Incorrect configuration version');
      NewHalt(200);
    End;

  If (Handle=-1) Then
    Begin
      Logit('C','<!> Cannot write to OLMS directory');
      NewHalt(200);
    End;

  (* If the file was not locked *)
  {If Locked=-1
  Then Logit('D','DEBUG: File locking not available')
  Else Logit('D','DEBUG: File locking available');}

  (* If multinode setup and not locked *)
  If MultiNode And (Locked=-1) Then
    Begin
      Logit('C','<!> File sharing error, SHARE.EXE is not loaded');
      NewHalt(200);
    End;

  (* If single node, but we have file locking, then upgrade to multinode *)
  If Not MultiNode And (Locked<>-1) Then
    Begin
      {Logit('D','DEBUG: Overriding single node setup to include file locking');}
      MultiNode := True;
    End;
  If UpcaseStr(Copy(GetEnv('OLMSSAFE'),1,1))='Y'
  Then CreateNewJam := False
  Else CreateNewJam := True;
End;

Procedure Logit(Level: Char; st: String);
Var
  W, D, M, Y, S, N, H, T: Word;
  st2: String;
Begin
  Level := Upcase(Level);
  If (Pos(Level,'CRED') > Pos(Setup^.LogMode,'CRED')) Then Exit;

  GetDate(Y,M,D,W);
  GetTime(H,N,S,T);
  If Setup^.LogExpanded
  Or Setup^.LogHeaders  Then st2 := '> '+ZeroPad(D,2)+'-'+Copy(MonthString,(M-1)*3+1,3)+' '+
                                   ZeroPad(H,2)+':'+ZeroPad(N,2)+':'+ZeroPad(S,2)+' QD'+
                                   ZeroPad(User.Node,2)
                       Else st2 := '> ' + ZeroPad(H,2)+':'+ZeroPad(N,2)+':'+ZeroPad(S,2) + ' ';
  AppendFile(Setup^.Logfile,st2+' '+st);
End;

Procedure GoodBye;
Begin
  ClearScreen;
  DisplayPacked(Setup^.GoodbyeFile,'*','');
  WaitSendBufferClear;
  LogIt('R','Logoff requested from door');
  Sleep(1);
  Hangup;
  If TrueCarrier Then Hangup;
  BootEm := True;
  EndDoorMaker;
End;

Type
{$IFDEF BBS_RA2}
  USERSBBSREC = Record
                  Name: String[35];
                  Location: String[25];
                  Organisation, Address1, Address2, Address3: String[50];
                  Handle: String[35];
                  Comment: String[80];
                  PasswordCRC: LongInt;
                  DataPhone, VoicePhone: String[15];
                  LastTime: String[5];
                  LastDate: String[8];
                  Attribute, Attribute2: Byte;
                  Flags: Array[1..4] of Byte;
                  Credit, Pending: LongInt;
                  MsgsPosted, Security: Word;
                  LastRead, NoCalls, Uploads, Downloads, UploadsK, DownloadsK, TodayK: LongInt;
                  Elapsed: Integer;
                  ScreenLength: Word;
                  LastPwdChange: Byte;
                  Group: Word;
                  CombinedInfo: Array[1..200] of Word;
                  FirstDate, BirthDate, SubDate: String[8];
                  ScreenWidth, Language, DateFormat: Byte;
                  ForwardTo: String[35];
                  MsgArea, FileArea: Word;
                  DefaultProtocol: Char;
                  FileGroup: Word;
                  LastDOBCheck: Byte;
                  Sex: Byte;
                  XIrecord: LongInt;
                  MsgGroup: Word;
                  FreeSpace: Array[1..48] of Byte;
                End;
{$ENDIF}

{$IFDEF BBS_RA1}
  USERSXIREC        = record
                     Handle         : String[35];
                     Comment        : String[80];
                     FirstDate      : Date;
                     CombinedInfo   : Array[1..25] Of Byte;
                     BirthDate      : Date;
                     SubDate        : Date;
                     ScreenWidth    : Byte;
                     ExtraSpace     : Array[1..83] of Byte;
                   end;

  USERSBBSREC       = Record
                     Name           : String[35];
                     Location       : String[25];
                     Password       : String[15];
                     DataPhone,
                     VoicePhone     : String[12];
                     LastTime       : Time;
                     LastDate       : Date;
                     Attribute      : Byte;
                     Flags          : FlagType;
                     Credit,
                     Pending        : Word;
                     MsgsPosted,
                     LastRead,
                     Security,
                     NoCalls,
                     Uploads,
                     Downloads,
                     UploadsK,
                     DownloadsK     : Word;
                     TodayK,
                     Elapsed        : Integer;
                     ScreenLength   : Word;
                     LastPwdChange,
                     Attribute2,
                     Group          : Byte;
                     XIrecord       : Word;
                     ExtraSpace     : array[1..3] of Byte;
                   End;
{$ENDIF}

Function LookUpUserNumber(st: String): Longint;
Type
  USERSIDXrecord = Record
                     NameCRC32,
                     HandleCRC32    : LongInt;
                   End;
Var
  f: File;
  UserIndex:  Array[1..100] Of USERSIDXrecord;
  c: Word;
  Result: Integer;
  Crc, Number: Longint;
  Found: Boolean;
  Name: Array[0..35] Of Char;
Begin
  Found := False;
  Number := -1;
  CString(Name,UpcaseStr(st));
  Crc := crc32(Name,Length(st),$FFFFFFFF);
  If OpenFile(f,Setup^.MsgbasePath+'USERSIDX.BBS','R',Sizeof(USERSIDXrecord),faReadOnly+faDenyNone) Then
    Begin
      While Not Found And Not Eof(f) Do
        Begin
          BlockRead(f,UserIndex,100,Result);
          For c := 1 To Result Do
            Begin
              If Not Found Then
                Begin
                  Inc(Number);
                  If ((UserIndex[c].HandleCRC32=Crc)
                  Or (UserIndex[c].NameCRC32=Crc)) Then Found := True;
                End
            End;
        End;
      CloseFile(f);
    End;
  If Not Found Then Number := -1;
  LookUpUserNumber := Number;
End;

Function LoadLocalUser(Name: String): Boolean;
Var
  {$IFDEF BBS_RA1}
  fi: File;
  di: USERSXIREC;
  {$ENDIF}
  f: File;
  d: USERSBBSREC;
  c, l: Longint;
  by: Byte;
Begin
  LoadLocalUser := False;

  Name := UpcaseStr(Name);
  If Name[1]='*' Then Name := Copy(Name,2,255)
  Else Begin For c := 1 To Length(Name) Do If Name[c] = '_' Then Name[c] := ' '; End;

  l := LookUpUserNumber(Name);

  If l=-1 Then
    Begin
      Writeln;
      Writeln('Could not find ',Name,' in the user file.');
      Exit;
    End;

  LoadLocalUser := True;

  If Not OpenFile(f,Setup^.MsgbasePath+'USERS.BBS','R',Sizeof(d),faReadOnly+faDenyNone) Then
    Begin
      Writeln;
      Writeln('Could not open the USERS.BBS userbase!');
      Sleep(3);
      NewHalt(1000);
    End;

  Seek(f,l);
  BlockRead(f,d,1);
  CloseFile(f);

  If UpcaseStr(d.Name) <> Name Then
    Begin
      Writeln;
      Writeln('Fatal index error; run RAUSER.EXE -P');
      Sleep(3);
      NewHalt(1000);
    End;

  {$IFDEF BBS_RA1}
  If Not OpenFile(fi,Setup^.MsgbasePath+'USERSXI.BBS','R',Sizeof(di),faReadOnly+faDenyNone) Then
    Begin
      Writeln;
      Writeln('Could not open the USERSXI.BBS userbase!');
      Sleep(3);
      NewHalt(1000);
    End;

  Seek(fi,d.XIRecord);
  Read(fi,di);
  CloseFile(fi);
  User.Handle    := di.Handle;
  User.Protocol  := '@';
  User.BirthDate := di.BirthDate;
  {$ENDIF}

  {$IFDEF BBS_RA2}
  User.Handle    := d.Handle;
  User.Protocol  := d.DefaultProtocol;
  For by := 1 To 200 Do User.CombinedInfo[by] := d.CombinedInfo[by];
  User.BirthDate := d.BirthDate;
  {$ENDIF}

  User.Downloads := d.Downloads;
  User.DownloadK := d.DownloadsK;
  User.TodayDownloadK := d.TodayK; {!! Reset if LastCall<>TodaysDate, but will they be freq'ing anyways?}
  User.Name      := d.Name;
  User.Security  := d.Security;
  User.FirstName := Copy(User.Name,1,Pos(' ',User.Name)-1);
  User.LastName  := Copy(User.Name,Pos(' ',User.Name)+1,255);
  User.RecordNumber := l;
  User.PostBill := Boolean((d.Attribute2 And 128)=128);
  User.Emulation := ANSI;
  For by := 1 To 4 Do User.Flags[by] := d.Flags[by];
  User.Posts := d.MsgsPosted;
  User.Credits := d.Credit;
  User.Pending := d.Pending;
End;

Procedure SaveLocalUser(Name: String);
Var
  f: File;
  d: USERSBBSREC;
  c: Byte;
Begin
  Name := UpcaseStr(Name);
  If Name[1]='*' Then Name := Copy(Name,2,255)
  Else Begin For c := 1 To Length(Name) Do If Name[c] = '_' Then Name[c] := ' '; End;

  If Not OpenFile(f,Setup^.MsgbasePath+'USERS.BBS','R',Sizeof(d),faReadWrite+faDenyNone) Then Exit;
  Fillchar(d,Sizeof(d),0);
  {$I-}
  Seek(f,User.RecordNumber);
  BlockRead(f,d,1);
  {$I+}
  If (UpcaseStr(d.Name)=Name) Then
    Begin
      d.MsgsPosted := User.Posts;
      d.Credit     := User.Credits;
      d.Pending    := User.Pending;
      d.Downloads  := User.Downloads;
      d.DownloadsK := User.DownloadK;
      d.TodayK     := User.TodayDownloadK;
      Seek(f,User.RecordNumber);
      BlockWrite(f,d,1);
    End;
  CloseFile(f);
End;

Function NodeCost(st: String; Zone, Net, Node: Word): Word;
Type
  R = Record
         Level: Byte;
         Number, Cost: Word;
         FileNumber: Byte;
         FileOffset: Longint;
      End;
Var
  tH: Text;
  fH: File;
  d: Array [1..256] Of R;
  v,Z,N: Word;
  c, x: Integer;
  cs: String[12];
  s: String;
  Found: Boolean;
Begin
  NodeCost := 0;
  If OpenFile(fH,st+'NODEIDX.RA','R',Sizeof(r),faReadOnly+faDenyNone) Then
    Begin
      Found := False;
      While Not Eof(fH) And Not Found Do
        Begin
          BlockRead(fH,d,256,x);
          For c := 1 To x Do
            Begin
              If      d[c].Level=0 Then Z:=d[c].Number
              Else If d[c].Level=2 Then N:=d[c].Number;
              If(Zone=Z) And (Net=N) Then
                Begin
                  NodeCost := d[c].Cost;
                  Found := True;
                  c := x;
                End;
            End;
        End;
      Closefile(fH);
    End;

  If (Node>0) And OpenText(tH,Setup^.Mainpath+'NODECOST.CTL','R',faReadOnly+faDenyNone) Then
    Begin
      Found := False;
      While Not Eof(tH) And Not Found Do
        Begin
          Readln(tH,s);
          s := StripLeadAndTrail(s);
          If UpcaseStr(Copy(s,1,5))='NODE ' Then
            Begin
              s := StripLeadAndTrail(Copy(s,5,255));
              c := Pos('.',s); If c>0 Then s := Copy(s,1,c-1);
              c := Pos(' ',s); If c>0 Then
                Begin
                  cs := StripLeadAndTrail(Copy(s,c+1,12));
                  s  := Copy(s,1,c-1);
                  If s = Zeropad(Zone,0)+':'+ZeroPad(Net,0)+'/'+ZeroPad(Node,0) Then
                    Begin
                      Val(cs,v,c);
                      If c=0 Then
                        Begin
                          NodeCost := v;
                          Found := True;
                        End;
                    End;
                End;
            End;
        End;
      CloseText(tH);
    End;
End;

Function NewFiles: Word;
Var
  Loop, NumberRead, Found, i, w: Word;
  aa, a: Byte;
  c: Char;
  fC: File;
  dC: FILESrecord;
  fH: File;
  dH: Array[0..19] Of FILESHDRrecord;
  TextBuf: Array[0..127] Of Char;
  TextCount, Counter: Word;
  fT: File;
  UseCR, BW, Done, b: Boolean;
  Temp: String;
  t: Text;
Begin
{!!  If Not NotReg And (Setup^.Serial[3]<>Upcase(Setup^.SystemName[1])) Then
  Asm
    INT 3
  End;}

  (* PROTECT *)
  If (MaxNodesSupported > 10) And Not Reg Then Hangup;

  {$IFDEF BBS_RA1}
  CopyFile(Setup^.FileBasePath,'NEWFILES.DAT');
  NewFiles := $FFFE;
  Exit;
  {$ENDIF}

  {$IFDEF BBS_RA2}
  Logit('E','Scanning for new files');

  If Not OpenText(t,'NEWFILES.DAT','W',faReadWrite+faDenyAll) Then Exit;
  If Not OpenFile(fc,Setup^.MainPath+'FILES.RA','R',Sizeof(dC),faReadOnly+faDenyNone) Then
    Begin
      CloseText(t);
      Exit;
    End;

  IgnoreCarrier := True;

  BW := (Human^.PacketType = ptBWAVE);
  If BW And (Human^.ColorFilelistingInBlueWave=BW_NOCOLOR) Then BW := False;

  w := 0;
  Found := 0;
  Done := False;
  While Not Eof(fC) And Not Done Do
    Begin
      {$I-}
      Wheel;
      BlockRead(fC,dC,1);
      If IoResult = 0 Then
      Begin
      If RA250 Then w := dC.AreaNum Else Inc(w);
      If  (dC.Name <> '')
      And (dC.Attrib And 9 = 1)
      And IsArea(dC.ListSecurity,dC.ListFlags,dC.ListNotFlags)
      And SeeGroup(dC.Group,dC.AltGroup[1],dC.AltGroup[2],dC.AltGroup[3],dC.Attrib2,2)
      And (UserAge >= dC.Age)
      Then
        Begin
          b := True;
          If OpenFile(fH,Setup^.FileBasePath+'HDR\FDB'+ZeroPad(w,0)+'.HDR'
                        ,'R',Sizeof(FILESHDRrecord),faReadOnly+faDenyNone) Then
            Begin
              If OpenFile(fT,Setup^.FileBasePath+'TXT\FDB'+ZeroPad(w,0)+'.TXT','R',1,faReadOnly+faDenyNone) Then
                While Not Eof(fH) And (IoResult=0) Do
                  Begin
                    Wheel;
                    BlockRead(fH,dH,20,NumberRead);
                    If NumberRead > 0 Then
                    For Loop := 0 To NumberRead-1 Do
                    Begin
                    If  (dH[Loop].UploadDate >= Human^.LastFileScan)
                    And (dH[Loop].Attrib And 35 = 0)
                    Then
                      Begin
                        If b Then
                          Begin
                            Writeln(t);
                            Writeln(t);
                            If BW Then
                              Begin
                                Writeln(t,'[0;36mÞ[1;37;46mÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ',
                                          'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ[0;30;46m¿Þ[0m');
                                Writeln(t,'[0;36mÞ[1;37;46m³ [0;30;46m',dC.Name,
                                          '³':75-Length(dC.Name),'Þ[0m');
                                Writeln(t,'[0;36mÞ[1;37;46mÀ[0;30;46mÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ',
                                          'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙÞ[0m');
                              End
                            Else If Human^.UseHigh Then
                              Begin
                                Writeln(t,'ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»');
                                Writeln(t,'º ',dC.Name,'º':77-Length(dC.Name));
                                Writeln(t,'ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼');
                              End
                            Else
                              Begin
                                Writeln(t,'+-----------------------------------------------------------------------------+');
                                Writeln(t,'| ',dC.Name,'|':77-Length(dC.Name));
                                Writeln(t,'+-----------------------------------------------------------------------------+');
                              End;
                            Writeln(t,'');
                            b := False;
                          End;
                        Str(dH[Loop].Size:8,Temp);
                        If BW
                        Then Write(t,'[0;1;36m '+SpacePad(dH[Loop].Name,12),'[33m'+
                             Temp+'  [34m'+ReturnStringDate(dH[Loop].FileDate)+'  [0m')
                        Else Write(t,' ',SpacePad(dH[Loop].Name,12),Temp+'  '+ReturnStringDate(dH[Loop].FileDate)+'  ');
                        Temp := '';
                        Seek(fT,dH[Loop].LongDescPtr);
                        If IoResult=0 Then
                        Begin
                        Inc(Found);
                        i := 0;
                        a := 0;
                        UseCR := True;
                        Repeat
                          Wheel;
                          BlockRead(fT,TextBuf,Sizeof(TextBuf),TextCount);
                          c := #0;
                          For Counter := 1 To TextCount Do
                            Begin
                              c := TextBuf[Counter-1];
                              If c In [#0,#26] Then i := 2001
                              Else If i <= 2000 Then
                                Begin
                                  Inc(i);
                                  If (c=#13) And Not UseCR Then c := #32;
                                  If (c<>#13) Then
                                    Begin
                                      If Not (c In [#0,#10,#26]) Then
                                        Begin
                                          Temp := Temp + c;
                                          Inc(a);
                                          If a > 45 Then
                                            Begin
                                              UseCr := False;
                                              a := Length(Temp)+1;
                                              For aa := 1 To Length(Temp) Do If Temp[aa] = ' ' Then a := aa;
                                              Writeln(t,Copy(Temp,1,a-1));
                                              If BW Then Write(t,'[0m');
                                              Write(t,'':33);
                                              Temp := Copy(Temp,a+1,255);
                                              a := Length(Temp);
                                            End;
                                        End;
                                    End
                                  Else
                                    Begin
                                      If Temp<>'' Then
                                        Begin
                                          Writeln(t,Temp);
                                          If BW Then Write(t,'[0m');
                                          Write(t,'':33);
                                          a := 0;
                                          Temp := '';
                                        End;
                                    End;
                                End;
                            End;
                        Until (c=#0) Or (c=#26) Or (i>=2000);
                        End;
                        If Temp<>'' Then Writeln(t,Temp);
                        Writeln(t);
                      End;
                    End;
                  End;
              CloseFile(fT);
              CloseFile(fH);
            End;
        End;
      End;
      If IsChar Then If Upcase(Getchar) = HotKey[L_Stop] Then Done := True;
    End;
  CloseFile(fC);
  CloseText(t);

  IgnoreCarrier := False;

  If Done Or (Found = 0) Then KillFile('NEWFILES.DAT');
  If Not Done Then Logit('E',ZeroPad(Found,0)+' new files found')
  Else Begin Logit('E','File scan aborted'); Found := $FFFF; End;
  NewFiles := Found;
  {$I+}
  {$ENDIF} (* BBS_RA2 *)
End;

Function IsArea(Sec: Word; Flag, NotFlag: FlagType): Boolean;
Begin
  If  (Sec <= User.Security)
  And (Flag[1] And User.Flags[1] = Flag[1])
  And (Flag[2] And User.Flags[2] = Flag[2])
  And (Flag[3] And User.Flags[3] = Flag[3])
  And (Flag[4] And User.Flags[4] = Flag[4])
  And (NotFlag[1] And User.Flags[1] = 0)
  And (NotFlag[2] And User.Flags[2] = 0)
  And (NotFlag[3] And User.Flags[3] = 0)
  And (NotFlag[4] And User.Flags[4] = 0)
  Then IsArea := True
  Else IsArea := False;
End;

{ Fix 4: Per-area credit charging }
Function GetAreaCredit(Area: Word): Word;
Var
  f: File;
  Credit: Word;
Begin
  GetAreaCredit := 0;
  Credit := 0;
  If OpenFile(f,MainDir+'AREACRDT.DAT','R',Sizeof(Word),faReadOnly+faDenyNone) Then
    Begin
      If Area <= FileSize(f) Then
        Begin
          Seek(f,Area-1);
          BlockRead(f,Credit,1);
        End;
      CloseFile(f);
    End;
  GetAreaCredit := Credit;
End;

Function SeeGroup(Group, Group1, Group2, Group3: Word; Atr, Mask: Byte): Boolean;
Begin

  If (Group >MaxGroups) Then Group := 0;
  If (Group1>MaxGroups) Then Group := 0;
  If (Group2>MaxGroups) Then Group := 0;
  If (Group3>MaxGroups) Then Group := 0;

  If (Group = 0)
  Or (Groups[Group]  And Mask <> 0)
  Or (Groups[Group1] And Mask <> 0)
  Or (Groups[Group2] And Mask <> 0)
  Or (Groups[Group3] And Mask <> 0)
  Or ((Atr And 1)=1)
  Then SeeGroup := True
  Else SeeGroup := False;
End;

Function HasSysopRightsArea(Var CFG: MESSAGErecord; Conf: Word): Boolean;
Begin
  If  (CFG.Name <> '')
  And ((Setup^.SysopFlags[Conf] And sHIDDEN) = 0)
  And IsArea(CFG.SysopSecurity,CFG.SysopFlags,CFG.SysopNotFlags)
  And SeeGroup(CFG.Group,CFG.AltGroup[1],CFG.AltGroup[2],CFG.AltGroup[3],CFG.Attribute2,1)
  Then HasSysopRightsArea := True
  Else HasSysopRightsArea := False;
End;

Function VisableArea(Var CFG: MESSAGErecord; Conf: Word): Boolean;
Begin
  If  (CFG.Name <> '') {!! stripleadandtrail?}
  And ((Setup^.SysopFlags[Conf] And sHIDDEN) = 0)
  And (UserAge >= CFG.Age)
  And IsArea(CFG.ReadSecurity,CFG.ReadFlags,CFG.ReadNotFlags)
  And SeeGroup(CFG.Group,CFG.AltGroup[1],CFG.AltGroup[2],CFG.AltGroup[3],CFG.Attribute2,1)
  Then VisableArea := True
  Else VisableArea := False;
End;

Function WritableArea(Var CFG: MESSAGErecord; Conf: Word): Boolean;
Begin
  If  (CFG.Name <> '')
  And (UserAge >= CFG.Age)
  And ((Setup^.SysopFlags[Conf] And sBLOCKED) = 0)
  And (Not (CFG.MsgKinds In [kReadOnly]))
  And IsArea(CFG.WriteSecurity,CFG.WriteFlags,CFG.WriteNotFlags)
  And SeeGroup(CFG.Group,CFG.AltGroup[1],CFG.AltGroup[2],CFG.AltGroup[3],CFG.Attribute2,1)
  Then WritableArea := True
  Else WritableArea := False;
End;

Function DetectArc(FileName: String): Char;
Var
  Kind: Char;
  f: File;
  Test: String[40];
  Loop: Byte;
Begin
  DetectArc := 'Z';
  If Not OpenFile(f,FileName,'R',1,faReadOnly+faDenyNone) Then Exit;

  Loop := 0;
  While Not Eof(f) And (Loop<20) Do {!! Optimize loop?}
    Begin
      Inc(Loop);
      BlockRead(f,Test[Loop],1);
    End;
  CloseFile(f);
  Test[0] := Chr(Loop);

  Kind := '!';
  Loop := 0;
  While (Loop<12) And (Kind='!') Do
   Begin
    Inc(Loop);
    If '`ê'=Copy(Test,Loop,2) Then Kind := 'A'
    Else If 'PK'=Copy(Test,Loop,4) Then Kind := 'Z'
    Else If ('-l'=Copy(Test,Loop,2)) And ('-'=Test[Loop+4]) Then Kind := 'L'
    Else If 'Rar!'=Copy(Test,Loop,4) Then Kind := 'R';
   End;
   If Kind = '!' Then Kind := Human^.Archiver;
  DetectArc := Kind;
End;

Function IsAttachedName(Var st: String): Boolean;
Var
  p, Count: Byte;
  nst: String;
  b: Boolean;
Begin
  b := True;
  nst := st;
  Repeat
    p := Pos('#',nst);
    If p > 0 Then nst := Copy(nst,1,p-1) + Copy(nst,p+1,255);
  Until p = 0;
  For Count := 1 To Length(nst) Do If Not (nst[Count] In ['0'..'9',' ']) Then b := False;
  If b Then st := nst;
  IsAttachedName := b;
End;

Function BufferedCopyFile(Src, Dst: String): Boolean;
Var
  SrcHandle, DstHandle: File;
  BytesRead, BytesWritten: Word;
  FILEBUF: pDATBUF_WAV;
Begin
  BufferedCopyFile := False;
  If FileExists(Src) Then
    Begin
      FILEBUF := New(pDATBUF_WAV);
      If FILEBUF <> Nil Then
        Begin
          If OpenFile(SrcHandle,Src,'R',1,faReadOnly+faDenyNone) And OpenFile(DstHandle,Dst,'W',1,faReadWrite+faDenyAll) Then
            Begin
              BufferedCopyFile := True;
              Repeat
                BlockRead(SrcHandle,FILEBUF^,TextBufferSize,BytesRead);
                Blockwrite(DstHandle,FILEBUF^,BytesRead,BytesWritten);
              Until(BytesRead=0) or (BytesRead<>BytesWritten)
            End;
          CloseFile(SrcHandle);
          CloseFile(DstHandle);
          Dispose(FILEBUF);
        End
      Else BufferedCopyFile := CopyFile(Src,Dst);
    End;
End;

Function PackFile(stPath, stName: String): Boolean;
Begin
  PutTrail(stPath);
  PackFile := BufferedCopyFile(stPath+stName,stName);
End;

Procedure EditRequested;
Var
  Key, Opt: Char;
  Temp: String[5];
  Amount: Word;
  i: Integer;
Begin
  Repeat
    WriteLines(1);
    Bullet(COL_TOPACK); WriteString(LANG(L_EditMenu));
    SetColor(Colors[COL_YESNO]);
    Repeat
      Key := Upcase(Getchar);
    Until Key In [HotKey[L_Remove],HotKey[L_List],HotKey[L_Erase],HotKey[L_DidContinue],#13];
    If Key = HotKey[L_Remove] Then
      Begin
        WriteStringCF(LANG(L_Remove));
        If Human^.FilesQueued = 0 Then
          Begin
            Bullet(COL_ERROR); WriteStringCF(LANG(L_ListEmpty));
          End
        Else
          Begin
            Bullet(COL_TOPACK);
            WriteString(LANG(L_RemoveMenu));
            SetColor(Colors[COL_CONFNUM]);
            Repeat
              Opt := Upcase(Getchar);
            Until Opt In ['A'..'J',#13];
            If Opt = #13 Then WriteStringCF(LANG(L_None))
            Else
              Begin
                WriteStringCF(Opt);
                Amount := Byte(Opt)-64;
                If (Amount > 0) And (Amount <= Human^.FilesQueued) Then
                  Begin
                    Bullet(COL_TEXT); WriteString(Human^.FileQueue[Amount]);
                    SetColor(Colors[COL_TOPACK]); WriteStringCF(LANG(L_IsRemoved));
                    Dec(Human^.FilesQueued);
                    For i := Amount To Human^.FilesQueued Do
                      Human^.FileQueue[i] := Human^.FileQueue[i+1];
                  End
                Else
                  Begin
                    Bullet(COL_ERROR); WriteStringCF(LANG(L_OutRange));
                  End;
              End;
          End;
      End
    Else If Key = HotKey[L_Erase] Then
      Begin
        WriteStringCF(LANG(L_Erase));
        Bullet(COL_TOPACK); WriteString(LANG(L_EraseMenu));
        SetColor(Colors[COL_YESNO]);
        Opt := TimedYesNo(HotKey[L_No],30);
        WriteLines(1);
        If Opt = HotKey[L_Yes] Then
          Begin
            Human^.FilesQueued := 0;
            Bullet(COL_TOPACK); WriteStringCF(LANG(L_IsErased));
          End;
      End
    Else If Key = HotKey[L_List] Then
      Begin
        WriteStringCF(LANG(L_List));
        If Human^.FilesQueued = 0 Then
          Begin
            Bullet(COL_ERROR); WriteStringCF(LANG(L_ListEmpty));
          End
        Else
          Begin
             WriteLines(1);
             For i := 1 To Human^.FilesQueued Do
               Begin
                 Bullet(COL_CONFNUM); WriteString(Chr(i+64));
                 SetColor(Colors[COL_TEXT]); WriteStringCF(') '+UpcaseStr(Human^.FileQueue[i]));
               End;
          End;
      End;
  Until Key In [#13,HotKey[L_DidContinue]];
  WriteStringCF(LANG(L_DidContinue));
  WriteLines(1);
End;

Function DownloadRequested: Boolean;
Var
 Key: Char;
 Count: Byte;
Begin
  If Not NotReg And (Setup^.Serial[2]<>Upcase(Setup^.Sysop[1])) Then
  Asm
    INT 1
  End;   (* PROTECT *)
  DownloadRequested := False;
  Repeat
    If Human^.FilesQueued = 0 Then Exit;
    If FLAG_BufferFull Then
      Begin
        Bullet(COL_TOPACK); WriteStringCF(LANG(L_ReqFull));
      End;
    Bullet(COL_TOPACK); WriteStringCF(LANG(L_ReqReady));
    If Wait Then
      Begin
        Bullet(COL_TOPACK);  WriteString(LANG(L_ReqDownNow));
        SetColor(Colors[COL_YESNO]); Key := TimedYesNo(HotKey[L_Yes],30);

        If Key = HotKey[L_No] Then
          Begin
            WriteLines(1);
            Bullet(COL_TOPACK); WriteString(LANG(L_ReqAskEdit));
            SetColor(Colors[COL_YESNO]); Key := TimedYesNo(HotKey[L_No],30);
            If Key = HotKey[L_Yes] Then
              Begin
                EditRequested;
                Key := '*';
              End
            Else WriteLines(2);
          End;
      End
    Else Key := HotKey[L_Yes];
  Until Key <> '*';
  If Key = HotKey[L_Yes] Then DownloadRequested := True
  Else DownloadRequested := False;
End;

Function ExTimedYesNo(Default: Char; Sec: Integer): Char;
Begin
  DoColor(COL_YESNO);
  If Not Wait Then
    Begin
      If Upcase(Default) = HotKey[L_Yes] Then WriteString(LANG(L_Yes))
      Else WriteString(LANG(L_No));
      ExTimedYesNo := Default;
    End
  Else ExTimedYesNo := TimedYesNo(Default,Sec);
End;

Procedure ChangeArchiver;
Var
  Key: Char;
  a: Byte;
Begin
  Display('-ARC',ArcString);
  Repeat
  Repeat
    If Not GetPushedKey(Key) Then Key := Upcase(Getchar);
    If Key = ' ' Then Key := '@';
  Until Pos(Key,ArcString)>0;
  a := Pos(Key,ArcString);
  If (Length(Setup^.Compress[a])+Length(Setup^.Decompress[a]))<10 Then Key := #0;
  Until Key<>#0;
  Human^.Archiver := Key;
End;

Procedure SelectKeywords;
Var
  b: Boolean;
  Offset, Option, c: Byte;
  Key: Char;
  ast: Array[1..6] Of String[50];
  YN: Array[False..True] Of String[3];
Begin
  Offset := 0;
  ast[1]    := LANG(L_Keyword);
  ast[2]    := LANG(L_Filter);
  ast[3]    := LANG(L_Twit);
  ast[4]    := LANG(L_KeyWhat);
  ast[5]    := LANG(L_FilWhat);
  ast[6]    := LANG(L_TwitWhat);
  YN[False] := LANG(L_No);
  YN[True]  := LANG(L_Yes);

  ClearScreen;
  Repeat
  If User.Emulation = ASCII Then ClearScreen;
  DoColor(COL_TITLE); WriteStringCF(LANG(L_KeyTitle));
  DrawLine;
  For c := 1 To 15 Do
    Begin
      DoColor(COL_CONFNUM); WriteChar(Chr(64+c));
      DoColor(COL_TEXT);    WriteString(' '+SpacePad(UpcaseStr(Human^.Keywords[C+Offset*15]),22));
      DoColor(COL_CONFNUM); WriteChar(Chr(64+c));
      DoColor(COL_TEXT);    WriteString(' '+SpacePad(UpcaseStr(Human^.Filters[C+Offset*15]),22));
      DoColor(COL_CONFNUM); WriteChar(Chr(64+c));
      DoColor(COL_TEXT);    WriteStringCF(' '+SpacePad(UpcaseStr(Human^.Twits[C+Offset*15]),27));
    End;
  DrawLine;
  DoColor(COL_CONFNUM);  WriteChar(Menu4[1]);
  DoColor(COL_QUESTION); WriteString(SpacePad(LANG(L_GlobalKey),18));
  DoColor(COL_DATA);     WriteString(Spacepad(YN[Human^.GlobalKeywords],5));
  DoColor(COL_CONFNUM);  WriteChar(Menu4[2]);
  DoColor(COL_QUESTION); WriteString(Spacepad(LANG(L_FilterPersonal),18));
  DoColor(COL_DATA);     WriteString(Spacepad(YN[Human^.FilterPersonal],5));
  DoColor(COL_CONFNUM);  WriteChar(Menu4[3]);
  DoColor(COL_QUESTION); WriteString(SpacePad(LANG(L_TwitPersonal),21));
  DoColor(COL_DATA);     WriteStringCF(Spacepad(YN[Human^.TwitPersonal],3));
  DrawLine;
  Repeat
    ClearLine;
    DoColor(COL_OPTION); WriteString('('+ZeroPad(Offset+1,1)+'/3): '+LANG(L_KeyMenu));
    Repeat
      Key := Upcase(Getchar);
      If Key In ['1'..'3'] Then
        Begin
          Offset := Byte(Key)-49;
          Key := HotKey[L_Help];
          ClearScreen;
        End
      Else If Pos(Key,Menu4)>0 Then
        Begin
          Clearline;
          If Key = Menu4[1] Then WriteString(ast[4]+'? ') Else
          If Key = Menu4[2] Then WriteString(ast[5]+'? ') Else
          If Key = Menu4[3] Then WriteString(ast[6]+'? ');
          If User.Emulation > ASCII Then
            Begin
              If Key = Menu4[1] Then GotoLoc(20,19) Else
              If Key = Menu4[2] Then GotoLoc(44,19) Else
              If Key = Menu4[3] Then GotoLoc(71,19);
            End;
          b := TimedYesNo('*',1000) = HotKey[L_Yes];
          If Key = Menu4[1] Then Human^.GlobalKeywords := b Else
          If Key = Menu4[2] Then Human^.FilterPersonal := b Else
          If Key = Menu4[3] Then Human^.TwitPersonal   := b;
          If User.Emulation > ASCII Then GotoLoc(1,21);
          Key := HotKey[L_Keyword];
        End
      Else If Key In [HotKey[L_Keyword],HotKey[L_Filter],HotKey[L_Twit]] Then
        Begin
          If Key = HotKey[L_Keyword] Then Option := 1
          Else If Key = HotKey[L_Filter] Then Option := 2
          Else Option := 3;
          Clearline;
          WriteString(LANG(L_LetterOf)+ast[Option]+LANG(L_ToEdit));
          Repeat Key := Upcase(Getchar); Until Key In [#13,'A'..'O'];
          If Key <> #13 Then
          Begin
          Clearline;
          WriteString(LANG(L_New)+ast[Option]+': ');
          If User.Emulation > ASCII Then
            Begin
              GotoLoc((Option-1)*24+3,Byte(Key)-62);
            End;
          Case Option Of
            1: Human^.Keywords[Offset*15+Byte(Key)-64] := GetString(20,Colors[COL_INPUTFORE],Upper);
            2: Human^.Filters[Offset*15+Byte(Key)-64] := GetString(20,Colors[COL_INPUTFORE],Upper);
            3: Human^.Twits[Offset*15+Byte(Key)-64] := GetString(25,Colors[COL_INPUTFORE],Upper);
          End;
          DoColor(COL_QUESTION);
          If User.Emulation > ASCII Then GotoLoc(1,21);
          End;
          Key := HotKey[L_Keyword];
        End
      Else If Key = HotKey[L_Help] Then
        Begin
          DisplayTextFile(SearchBack('KEYWORD.HLP'));
          ClearScreen;
        End;
    Until Key In [HotKey[L_Help],HotKey[L_Keyword],HotKey[L_Filter],HotKey[L_Twit],HotKey[L_Quit],'1'..'3'];
  Until (User.Emulation = ASCII) Or (Key = HotKey[L_Quit]) Or (Key=HotKey[L_Help]);
  Until Key = HotKey[L_Quit];
End;

Procedure ViewSettings(Alias: String; MAXPPACK, MAXPCONF: Word);
Var
  Temp: String;
  YN: Array[False..True] Of String[4];
Begin
  YN[False] := LANG(L_No);
  YN[True]  := LANG(L_Yes);

  ClearScreen;
  DoColor(COL_TITLE);
  WriteStringCF(LANG(L_CurSettings));
  Drawline;
  With Human^ Do
  Begin
  Temp := Name;  AutoCap(Temp);
  {$IFDEF PROVERSION}
  If VacationMode Then Temp := Temp + ' ' + LANG(L_OnVacation);
  {$ENDIF}
  TwoPrompt(LANG(L_VName),Temp);
  Temp := Alias; AutoCap(Temp); TwoPrompt(LANG(L_VAlias),Temp);
  TwoPrompt(LANG(L_VStyle),PacketFormatString[Human^.PacketType]);
  TwoPrompt(LANG(L_VLastDL),LastTimeDownload+' '+LastDateDownload);
  TwoPrompt(LANG(L_VDownloads),ZeroPad(TotalDownloads,0));
  TwoPrompt(LANG(L_VProtocol),Setup^.TransmitNames[Pos(Protocol,ProtString)]);
  Case Archiver Of
    'A': Temp := 'Arj';
    'L': Temp := 'Lzh';
    'Z': Temp := 'Zip';
    'P': Temp := 'Pak';
    'C': Temp := 'Arc';
    'R': Temp := 'Rar';
  Else Temp := 'Unknown';
  End;
  TwoPrompt(LANG(L_VArc),Temp);
  WriteLines(1);
  FourPrompt(LANG(L_VIndex),YN[Indexes],LANG(L_VGlobalKey),YN[GlobalKeywords]);
  FourPrompt(LANG(L_VNewFiles),YN[Files],LANG(L_VGlobalPers),YN[GlobalPersonal]);
  FourPrompt(LANG(L_VNews),YN[News],LANG(L_VFilterPers),YN[FilterPersonal]);
  FourPrompt(LANG(L_VScreens),YN[GetWelcome],LANG(L_VTwitPers),YN[TwitPersonal]);
  TwoPrompt(LANG(L_VShort),YN[ShortList]);
{  If Human^.PacketType <> 3 Then (* Not BlueWave *) }
  Begin
  If NumericExtension
  Then FourPrompt(LANG(L_VNumeric),YN[NumericExtension],', ',ZeroPad(CurrentExtension,2))
  Else  TwoPrompt(LANG(L_VNumeric),YN[NumericExtension]);
  End;
  WriteLines(1);
  TwoPrompt(LANG(L_VMaxConf),ZeroPad(MAXPCONF,0));
  TwoPrompt(LANG(L_VMaxPack),ZeroPad(MAXPPACK,0));
  WriteLines(1);
  DoColor(COL_INFO);  WriteString('Copyrighted by: ');
  DoColor(COL_VALUE); WriteStringCF('Peter Rocca and Multiboard Communications Centre, 1994-98');
  DoColor(COL_INFO);  WriteString(' Registered to: ');
  If Reg Then
    Begin
      DoColor(COL_VALUE); WriteStringCF(Setup^.SystemName);
    End
  Else
    Begin
      SetColor(WHITE+BLINK); WriteStringCF('UNREGISTERED EVALUATION VERSION');
    End;
  Drawline;
  DoColor(COL_PRESSSPACE); WriteString(LANG(L_PressSpace));
  Repeat Until Getchar In [HotKey[L_PressSpace],#13,'.'];
  End;
End;

Function NoteDisabled: Char;
Begin
  If (User.Emulation=RIP) Then GotoLoc(1,23);
  DoColor(COL_TITLE);
  WriteCenterString(78,' '+LANG(L_SysopDisable));
  Sleep(3);
  ClearLine;
  NoteDisabled := '*';
End;

Procedure SelectBulletins;
Var
  Redraw: Boolean;
  Count: Byte;
  Key: Char;
Begin
  Redraw := True;

  If User.Emulation > ASCII Then
    Begin
      ClearScreen;
      WriteStringCF(LANG(L_BullSel));
      DrawLine; GotoLoc(1,21);
      DrawLine; GotoLoc(1,3);
    End;

  Repeat
    If User.Emulation = ASCII Then
      Begin
        ClearScreen;
        DoColor(COL_TITLE); WriteStringCF(LANG(L_BullSel));
        DrawLine;
      End;
    If Redraw Or (User.Emulation = ASCII) Then
      Begin
        Redraw := False;
        For Count := 1 To 18 Do
          Begin
            If User.Emulation > ASCII Then ClearLine;
            DoColor(COL_CONFNUM);
            WriteString(' '+Chr(Count+64+Byte(Count>16))+' ');
            If (Setup^.Bulletins[Count] <> '') And (Setup^.BulletinFlags[Count]>0) Then
              Begin
                DoColor(COL_CONFFLAG);
                If Setup^.BulletinFlags[Count] = bFORCED Then WriteString(SpacePad(LANG(L_Forced),12))
                Else If Is(Human^.Bulletins[Count DIV 8],1 Shl (Count MOD 8)) Then WriteString(SpacePad(LANG(L_Collect),12))
                Else WriteString(SpacePad('',12));
                DoColor(COL_CONFNAME);
                If Setup^.BulletinNames[Count] <> '' Then WriteString(Setup^.BulletinNames[Count])
                Else WriteString(LANG(L_Bulletin)+ZeroPad(Count,1));
              End;
            WriteLines(1);
          End;
      End;
    If User.Emulation = ASCII Then DrawLine
    Else
      Begin
        GotoLoc(1,22);
        DoColor(COL_PROMPT);
      End;
    WriteString(LANG(L_BullMenu));
    Repeat
      Key := Upcase(Getchar);
    Until (Key In ['A'..'S']) Or (Key=HotKey[L_Quit]);
    If Key <> HotKey[L_Quit] Then
      Begin
        Count := Ord(Key)-64;
        If Count > 16 Then Dec(Count);
        Human^.Bulletins[Count DIV 8] := Human^.Bulletins[Count DIV 8] Xor (1 Shl (Count MOD 8));
        If (User.Emulation > ASCII) And (Setup^.Bulletins[Count]<>'') Then
          Begin
            GotoLoc(4,Count+2);
            DoColor(COL_CONFFLAG);
            If Setup^.BulletinFlags[Count] = bFORCED Then WriteString(SpacePad(LANG(L_Forced),12))
            Else If Is(Human^.Bulletins[Count DIV 8],1 Shl (Count MOD 8)) Then WriteString(SpacePad(LANG(L_Collect),12))
            Else WriteString(SpacePad('',12));
          End;
      End;
  Until Key = HotKey[L_Quit];
End;

Procedure ChangePacketFormat;
Var
  Key: Char;
Begin
  Display('-TYPE','QEB');
  Repeat If Not GetPushedKey(Key) Then Key := Upcase(Getchar); Until Key In ['Q','E','B'];
  Case Key Of
    'Q': Human^.PacketType := 0;
    'E': Human^.PacketType := 1;
    'B': Human^.PacketType := 3;
  End;
End;

Procedure DrawLine;
Begin
  DoColor(COL_LINE); WriteChar(#13);
  If (User.Emulation > ASCII) And Human^.UseHigh Then WriteStringCF(SolidLine)
  Else WriteStringCF(DottedLine);
End;

Procedure Display(Filename, GoodChars: String);
Var
  Em, Lap: Byte;
  Ok: Boolean;
Begin
  ClearScreen;
  Ok := False;
  For Lap := 2*Byte(Reg=False)+1 To 3 Do
    Begin
      Em := User.Emulation;
      While Not Ok And (Em>0) Do
        Begin
          Case Lap Of
            1: Ok := DisplayPacked(ScreenDir+Filename+EXTTYPE[Em],'*',GoodChars);
            2: Ok := DisplayPacked(MainDir+FileName+EXTTYPE[Em],'*',GoodChars);
            3: Ok := DisplayPacked(MainDir+'SCREENS.DAT',FileName+EXTTYPE[Em],GoodChars);
          End;
          Dec(Em);
        End;
    End;
End;

Function Changer(st: String): Boolean;
Var
  Key: Char;
Begin
  Display(st,'YN'+YCharacter+NCharacter);

  Repeat
    If Not GetPushedKey(Key) Then Key := Upcase(Getchar);
  Until Key In ['N','Y',YCharacter,NCharacter];

       If Key = YCharacter Then Changer := True
  Else If Key = NCharacter Then Changer := False
  Else If Key = 'Y'        Then Changer := True
  Else                          Changer := False;
End;

Procedure ChangeProtocol;
Var
  Key: Char;
Begin
  Display('-PROT',ProtString);
  Repeat
    If Not GetPushedKey(Key) Then Key := Upcase(Getchar);
    If Key = ' ' Then Key := '@';
  Until Pos(Key,ProtString)>0;
  Human^.Protocol := Key;
End;

Procedure ChangeLimits(Var MAXPPACK, MAXPCONF: Word);
Var
  Key: Char;
  Temp: String[100];
  Amount: Word;
  i: Integer;
Begin
  If Not NotReg And (Pos(Setup^.Serial[7],Conversions)>13) Then
  Asm
  @@BadMonth_Loop:
    PUSH CX
    JMP  @@BadMonth_Loop
  End;  (* PROTECT *)

  Repeat
    Display('-LIMIT','LMD123');
    Repeat
      If Not GetPushedKey(Key) Then Key := Upcase(Getchar);
    Until Key In ['L','M','D','1','2','3'];
    If Key In ['D','3'] Then Exit;
    ClearScreen;
    DoColor(COL_TITLE);   WriteStringCF(LANG(L_Limiting));
    DrawLine;
    DoColor(COL_QUESTION);
    Case Key Of
      'L','2': WriteString(LANG(L_MaxPacket)+' (1-'+ZeroPad(Setup^.MaxPacket[BaudRange],0)+'): ');
      'M','1': WriteString(LANG(L_MaxConf)+' (1-'+ZeroPad(Setup^.MaxConference,0)+'): ');
    End;
    Temp := GetString(5,Colors[COL_INPUTFORE],Number);
    If Temp = '' Then Exit;
    Val(Temp,Amount,i);
    If Amount = 0 Then Amount := 60000;
    Case Key Of
      'L','2': Human^.MaxPacket := Amount;
      'M','1': Human^.MaxConference := Amount;
    End;
    MAXPPACK := Human^.MaxPacket;
    MAXPCONF := Human^.MaxConference;
    If (MAXPPACK < 1) Or (MAXPPACK > Setup^.MaxPacket[BaudRange]) Then MAXPPACK := Setup^.MaxPacket[BaudRange];
    If (MAXPCONF < 1) Or (MAXPCONF > Setup^.MaxConference) Then MAXPCONF := Setup^.MaxConference;
  Until Key = 'D';
End;

Procedure DoColor(c: Byte);
Begin
  SetColor(Colors[c]);
End;

Procedure TwoPrompt(s1, s2: String);
Begin
  DoColor(COL_INFO);
  WriteString(s1);
  DoColor(COL_VALUE);
  WriteStringCF(s2);
End;

Procedure FourPrompt(s1, s2, s3, s4: String);
Begin
  DoColor(COL_INFO);   WriteString(s1);
  DoColor(COL_VALUE);  WriteString(s2);
  DoColor(COL_INFO);   WriteString(s3);
  DoColor(COL_VALUE);  WriteStringCF(s4);
End;

Function BKT(Index: Word): String;
Begin
  If (Index>24) Or (HotKey[Index]=Copy(LANG(Index),1,1)) Then BKT := '('+Copy(LANG(Index),1,1)+')'+Copy(LANG(Index),2,255)
  Else BKT := '('+HotKey[Index]+')'+Copy(LANG(Index),2,255);
End;

Function LANG(Index: Word): String;
Begin
  LANG := LanguageText[Index]^;
End;

Function CheckReg(SystemName, Sysop, Serial, Registration: String): Boolean;
Const
  Index : Array[1..26] Of Byte = (1,4,3,5,2,6,7,11,9,10,8,16,15,14,12,13,18,19,20,17,21,22,23,24,25,26);
Var
  Check, Temp, TempS: String[80];
  Counter1, Counter2, A, B, C, D, E: Word;
  X: Integer;
Begin
  A:=0; B:=0; C:=0; D:=0;
  CheckReg := False;
  For Counter1 := 1 To Length(SystemName) Do
    For Counter2 := 1 To Length(Sysop) Do
      Begin
	 A := A + (Byte(SystemName[Counter1])+Counter2) * (Byte(Sysop[Counter2])+Counter1);
	 B := B + (Byte(SystemName[Counter1])*Counter2) DIV ((Byte(Sysop[Counter2]) MOD Counter1)+3);
	 C := C + (Byte(SystemName[Counter1])-Counter2) + (Byte(Sysop[Counter2]) * Counter1);
	 D := D + (Byte(SystemName[Counter1])+Counter2) DIV (Byte(Sysop[Counter2])+Counter1-22);
      End;
  E := A MOD 3322 + 18;
  If (Sysop='') Or (SystemName='') Or (Serial='') Then Exit;
  TempS := '';
  If Serial[1] In ['L','P','C','B','R','F'] Then
       For Counter1 := 1 To Length(Serial) Do E := E + Byte(Serial[Counter1]) * 13
  Else If Serial[1] In ['A','B','X','U'] Then
       For Counter1 := 1 To Length(Serial) Do E := E + Byte(Serial[Counter1]) * (Byte(Serial[1])-64)
  Else For Counter1 := 1 To Length(Serial) Do E := E + Byte(Serial[Counter1]) * (Byte(Serial[1])-128);
  While E > 0 Do
    Begin
      TempS := TempS + Chr(E MOD 23 + 65);
      E := E DIV 23;
    End;
  If Serial[1]<>'R' Then
  Begin
  Str(A MOD 21231:5,Temp); Check := Chr(Byte(TempS[1])+2)+Temp[3]+Temp[2]+Temp[4]+Temp[1]+Temp[5];
  Str(B MOD  9421:5,Temp); Check := Check + Temp[1]+Temp[5]+Temp[3]+Temp[4]+Temp[2];
  Str(C MOD 12341:5,Temp); Check := Check + Temp[5]+Temp[4]+Temp[3]+Temp[1]+Temp[2];
  Str(D MOD  7745:5,Temp); Check := Check + Temp[2]+Temp[3]+Temp[4]+Temp[1]+Temp[5]+TempS;
  End
  Else
  Begin
  Str(A MOD 23411:5,Temp); Check := Chr(Byte(TempS[1])+2)+Temp[3]+Temp[2]+Temp[4]+Temp[1]+Temp[5];
  Str(B MOD  9812:5,Temp); Check := Check + Temp[1]+Temp[5]+Temp[3]+Temp[4]+Temp[2];
  Str(C MOD 23512:5,Temp); Check := Check + Temp[5]+Temp[4]+Temp[3]+Temp[1]+Temp[2];
  Str(D MOD  8272:5,Temp); Check := Check + Temp[2]+Temp[3]+Temp[4]+Temp[1]+Temp[5]+TempS;
  End;

  If Sysop=Serial Then A := 1 Else A := 0;
  If Serial[1] In ['1','7','9','0','2','3','5'] Then
    Begin
      For Counter1 := 1 To Length(Serial) Do E := E + Byte(Serial[Counter1]) * 13;
      If Counter1>1 Then
        Begin
          CheckReg    := False;
          NotReg      := True;
          WhoCaresReg := False;
        End
      Else
        Begin
          CheckReg    := True;
          NotReg      := True;
          WhoCaresReg := True;
        End;
    End
  Else If Serial[1] > #33 Then
    Begin
      B := 25;
      A := 10;
      MaxNodesSupported := B*A;
      {If Serial[1]='E' Then MaxNodesSupported := B*A;}
      {If Serial[1]='Q' Then MaxNodesSupported := A;}
      {If Serial[1]='H' Then MaxNodesSupported := 3;}

      X := Length(Registration); If X < 5 Then X := 5;
      B := 0;
      A := 0;

      While A < Length(Check) Do
        Begin
          Inc(A);
          If A MOD 5 = 2 Then
            Begin
              Temp := Copy(Check,A,5);
              Repeat
                D := Pos(' ',Temp);
                If D > 0 Then
                  Begin
                    Inc(B);
                    Temp := Copy(Temp,D+1,5);
                  End;
              Until D = 0;
            End;
          If Check[A] In [#0,' '] Then
          Else If Index[A]-B > Length(Registration) Then X := -1
          Else If (Check[A]=Registration[Index[A]-B]) Then Dec(X);
        End;
      CheckReg    := Not Boolean(X);
      NotReg      := Not(Not Boolean(X));
      WhoCaresReg := False;
    End
  Else
    Begin
      NotReg := True;
      B    := 3;
      C    := B * 10;      (* 30 *)
      D    := C * B;       (* 90 *)
      E    := D - C + B;   (* 63 *)
      NotReg      := True;
      If E = D Then CheckReg := True
      Else CheckReg := False;
      WhoCaresReg := True;
    End;
  If NotReg Or (A=Length(Check)) Then WasInReg := True
  Else WasInReg := False;
End;

Procedure LoadOLF(n: Byte);
Type
  IndexType = Record
                Name: String[12];
                OffSet: Longint;
              End;
Var
  Buffer: Array[0..2047] Of Char;
  Left, Offset, LangNum, Result: Integer;
  Loop: Byte;
  i: IndexType;
  f: File;
  t: Text;
  c: Word;
  b: Byte;
  st: String;
  dOLF: OLFrecord;
  fOLF: File;
Begin
  If Reg And (Pos(Setup^.Serial[6],Conversions)<4) Then XorReg := False;
  Asm (* PROTECT *)
    MOV  CL,XorReg
    XOR  CH,CH
    XOR  CX,1
  @@XorReg_Loop:
    INC  CX
    LOOP @@XorReg_Loop
  End;
  If (n=0) Or (n>15) Then n := 1;
  FillChar(dOLF,Sizeof(dOLF),0);
  If OpenFile(fOLF,Maindir+'LANGUAGE.DAT','R',Sizeof(OLFrecord),faReadOnly+faDenyNone) Then
    Begin
      {$I-}
      Seek(fOLF,n-1);
      BlockRead(fOLF,dOLF,1);
      {$I+}
      CloseFile(fOLF);
      If Not dOLF.Active Then dOLF.Filename := '';
    End;
  If Not OpenFile(f,dOLF.Filename,'R',1,faReadOnly+faDenyNone) Then
    Begin
      ScreenDir := '';
      If OpenFile(f,MainDir+'SCREENS.DAT','R',1,faReadOnly+faDenyNone) Then
        Begin
          i.Name := '';
          While (i.Name<>'DEFAULT.OLF') And Not Eof(f) Do BlockRead(f,i,Sizeof(i));
          Seek(f,i.OffSet);
        End
      Else
        Begin
          Logit('C','<!> Fatal attempt to load language');
          NewHalt(1);
        End;
    End
  Else ScreenDir := dOLF.ScreenPath;
  If ScreenDir <> '' Then PutTrail(ScreenDir);

  LangNum := 0;
  Loop    := 0;
  Result  := 0;
  Offset  := 0;
  Fillchar(Buffer,Sizeof(Buffer),0);

  While Loop<2 Do
    Begin
      If LangNum = MaxLang Then
        Begin
          Inc(Offset);
          Inc(Loop);
          LangNum := 0;
        End;
      Inc(LangNum);
      If Loop<2 Then
        Begin
          If Offset+Byte(Buffer[Offset]) >= Result Then
            Begin
              Left := Result - Offset;
              If Left < 0 Then
                Begin
                  BlockRead(f,b,1);
                  If b<>72 Then
                    Begin
                      Writeln('<C> Language text error!');
                      Halt;
                    End;
                  Left   := 0;
                  Offset := 0;
                End;
              Move(Buffer[Offset],Buffer,Left);
              BlockRead(f,Buffer[Left],Sizeof(Buffer)-Left,Result);
              Inc(Result,Left);
              Offset := 0;
            End;
          Move(Buffer[Offset],st,Byte(Buffer[Offset])+1);
          Inc(Offset,Byte(Buffer[Offset])+1);
          If (Loop=0) And (User.Emulation <> RIP) Then
            Begin
              LanguageText[LangNum] := New(RPBuf);
              LanguageText[LangNum]^ := Copy(st,1,160);
            End
          Else If (Loop=1) And (User.Emulation = RIP) Then
            Begin
              LanguageText[LangNum] := New(RPBuf);
              LanguageText[LangNum]^ := Copy(st,1,160);
            End;
        End;
    End;

  Seek(f,FilePos(f)-(Result-Offset+1));

  (*

  For c := 1 To MaxLang Do
    Begin
      BlockRead(f,b,1);
      BlockRead(f,st[1],b);
      st[0] := Chr(b);
      If User.Emulation <> RIP Then
        Begin
          LanguageText[c] := New(RPBuf);
          LanguageText[c]^ := Copy(st,1,160);
        End;
    End;
  BlockRead(f,b,1);
  For c := 1 To MaxLang Do
    Begin
      BlockRead(f,b,1);
      BlockRead(f,st[1],b);
      st[0] := Chr(b);
      If User.Emulation = RIP Then
        Begin
          LanguageText[c] := New(RPBuf);
          LanguageText[c]^ := Copy(st,1,160);
        End;
    End;
  *)
  BlockRead(f,HotKey,Sizeof(HotKey));
  YCharacter := HotKey[L_Yes];
  NCharacter := HotKey[L_No];
  YString    := LanguageText[L_Yes]^;
  NString    := LanguageText[L_No]^;
  SpaceString:= LanguageText[L_PressSpace]^;
  CloseFile(f);
End;

Function SearchBack(st: String): String;
Begin
  If (ScreenDir<>'') And FileExists(ScreenDir+st) Then SearchBack := ScreenDir+st
  Else If FileExists(MainDir+st) Then SearchBack := MainDir+st
  Else SearchBack := '';
End;

Function LoadMenuKeysFile(st: String): String; (* PRIVATE *)
Var
  t: Text;
  Info: SearchRec;
  p: String[80];
  l: String;
  Ok: Boolean;
Begin
  Ok := False;
  If (ScreenDir<>'') And (FileExists(ScreenDir+st+'.OPT'))
  Then p := ScreenDir
  Else p := MainDir;

  If p<>'' Then
    Begin
      If OpenText(t,p+st+'.OPT','R',faReadOnly+faDenyNone) Then
        Begin
          {$I-}
          Readln(t,l);
          If (IoResult<>0) Or (Length(l)>25) Then Logit('C','Error in screen option data: '+p+st+'.OPT')
          Else Ok := True;
          {$I+}
          CloseText(t);
        End;
    End;
  If Ok Then LoadMenuKeysFile := SpacePad(UpcaseStr(l),24)
  Else LoadMenuKeysFile := '';
End;

Procedure LoadMenuKeys;
Begin
  If Reg Then
    Begin
      Menu0 := LoadMenuKeysFile('MAIN');
      Menu1 := LoadMenuKeysFile('MAIN2');
      Menu2 := LoadMenuKeysFile('PREF');
      Menu3 := LoadMenuKeysFile('VACMGR');
      Menu4 := LoadMenuKeysFile('KEYWORD');
    End;
  If Not Reg Or (Menu0='') Then Menu0 := 'UDCKAPVHQGIFBNW7MRSELT!';
  If Not Reg Or (Menu1='') Then Menu1 := 'UDCKSHQG';
  If Not Reg Or (Menu2='') Then Menu2 := 'IFBNWAPMRSELT7VCQ';
  If Not Reg Or (Menu3='') Then Menu3 := 'DEIUVHQG';
  If Not Reg Or (Menu4='') Then Menu4 := '+-!';
End;

Procedure PCM(Col: Byte; Ch: Char);     (* PRIVATE *)
Begin
  SetColor(Lightgray); WriteChar(Ch);
  SetColor(Col);
End;

Function GotoLogoff: Char;
Begin
  If Setup^.AllowLogoff Then
    Begin
      GoodBye;
      GotoLogoff := '*';
    End
  Else GotoLogoff := NoteDisabled;
End;

Function GotoFilescan: Char;
Begin
  If Setup^.AllowFileScan Then
    Begin
      Human^.Files := Changer('-FILES');
      GotoFilescan := '?';
    End
  Else GotoFilescan := NoteDisabled;
End;

Function GotoWelcome: Char;
Begin
  If Setup^.AllowLogoff Then
    Begin
      Human^.GetWelcome := Changer('-GETWELL');
      GotoWelcome := '?';
    End
  Else GotoWelcome := NoteDisabled;
End;

Procedure RegMessage;
Var
  Temp: String[15];
  c: Byte;
Begin
  If User.Emulation=RIP Then TxStringCF(#13+'!|*'+#13);

  If(PresentDay<Setup^.Dated) Then
    Begin
      WriteStringCF('Invalid configuration file!');
      Logit('C','Invalid configuration file!');
      Sleep(3);
      EndDoorMaker;
    End;

  ClearScreen;

  If Not Reg Then
    Begin
      WriteLines(1);
      SetColor(Yellow); WriteString('      OLMS '); PCM(Yellow,'-'); WriteStringCF(' The Offline Mail System');
      SetColor(White);  WriteString('      Copyrighted Peter Rocca and Multiboard Communications Centre');
                        PCM(White,','); WriteStringCF(' 1994-98');
      WriteString('      All rights reserved'); PCM(White,','); WriteString(' worldwide'); PCM(White,'.');
      WriteLines(2);
      Str(PresentDay-Setup^.Dated+1,Temp);
      SetColor(140);    WriteStringCF('      UNREGISTERED EVALUATION COPY');
      WriteLines(1);
      SetColor(White);  WriteStringCF('      '+Setup^.Sysop+' has been evaluating this mail door for '+Temp+' days.');
                        WriteStringCF('      Please let it be known if you like it.');
      WriteLines(1);    WriteStringCF('      Thank you very much.');
      WaitSendBufferClear;
      Sleep(4);
      Setup^.Opening := True;
      Setup^.AllowLogoff := True;
      If Setup^.AllowFiles>2 Then Setup^.AllowFiles:=2;
      WasInReg := Reg;
    End
  Else
    Begin
      If Setup^.AllowFiles>MaxRequests Then Setup^.AllowFiles:=MaxRequests;
      WasInReg := Not Reg;
      Sleep(1);
    End;
  ArcString  := 'ALZCPR';
  ProtString := '';
  For c := 1 To 6 Do ProtString := ProtString + Setup^.TransmitKeys[c];
  WaitSendBufferClear;
End;

Function DosShell(a,b: Byte; CommandLine: String): Word;
Var
  SubStr: String;
  p: Byte;
Begin
  p := Pos(' ',CommandLine);
  If (p>0) Then SubStr := Copy(CommandLine,1,p-1) Else SubStr := CommandLine;
  If (Pos('\',SubStr)+Pos(':',SubStr)=0) Then CommandLine := AutoPath(CommandLine);

  If Setup^.SwappingControl[a][b]>0 Then SwapShellMethod := DefaultSwapShellMethod
  Else SwapShellMethod := $0;

  Case a Of
    typeDecompress: Logit('E','Decompress - '+CommandLine);
    typeCompress  : Logit('E','Compress - '+CommandLine);
    typeTransmit  : Logit('E','Transmit - '+CommandLine);
    typeReceive   : Logit('E','Receive - '+CommandLine);
  End;
  If a In [typeTransmit,typeReceive] Then DisplayStatusShell := True
  Else DisplayStatusShell := False;
  DosShell := Shell(CommandLine);
  DisplayStatusShell := False;
  SwapShellMethod := DefaultSwapShellMethod;
End;

Procedure ValidateFiles;
Var
  Temp: String[50];
  x: Word;
Begin
  Temp := MSG_EVALUATE;
  If crc32(Temp,10,$FFFFFFFF) <> 804831773 Then x := x DIV (x XOR x);
  If ReturnCrc(MainDir+'SCREENS.DAT') <> (-856985632) Then
    Begin
      Writeln('<!> SCREENS.DAT is corrupt or missing: exiting.');
      Logit('C','<!> SCREENS.DAT is corrupt or missing');
      NewHalt(5000);

{!! PROGRAM CRC-CHECK
    End
  Else If ReturnCrc(ParamStr(0)) <> (Setup^.Marked86-$D1E) Then
    Begin
      Writeln('<!> Program integrity check failure: exiting.');
      Logit('C','<!> Program integrity failure');
      NewHalt(5000);
!!}
    End;
End;

Function ReturnFlags(Value: Byte; Conf: Word): String;
Var
  Flag: String[20];
Begin
       If Is(Value,fGENERAL)  Then Flag := 'g'
  Else If Is(Value,fPERSONAL) Then Flag := 'p'
  Else If Is(Value,fALL)      Then Flag := 'a'
  Else If Is(Value,fCONNECT)  Then Flag := 'c'
  Else Flag := '.';
  If Is(Value,fSELF)    Then Flag := Flag + 'w' Else Flag := Flag + '.';
  If Is(Value,fKEYWORD) Then Flag := Flag + 'k' Else Flag := Flag + '.';
  If Is(Value,fFILTER)  Then Flag := Flag + 'f' Else Flag := Flag + '.';
  If Is(Value,fNETWORK) Then Flag := Flag + 'n' Else Flag := Flag + '.';
  If((Setup^.SysopFlags[Conf] And 7) <> 0) Then
    Begin
      If Is(Setup^.SysopFlags[Conf],sFORCED) Then
        Begin
          If Setup^.IncSelfInForced Then Flag := 'aw..F' Else Flag := 'a...F';
        End
      Else If Is(Setup^.SysopFlags[Conf],sBLOCKED)  Then Flag[5] := 'B'
      Else Flag := 'ERROR';
    End;
  ReturnFlags := Flag;
End;

Procedure AutoLogoff;
Var
  c: Byte;
  Temp: String[40];
  Key: Char;
Begin
  Bullet(COL_LOGOFF); WriteStringCF(LANG(L_AutoLogoff));
  Bullet(COL_LOGOFF); WriteString(LANG(L_LogoffTimer));
  DoColor(COL_TEXT);
  WaitSendBufferClear;
  Sleep(1);
  For c := 9 Downto 1 Do
    Begin
      Str(c,Temp);
      WriteString(#8+Temp);
      Sleep(1);
      If IsChar Then
        Begin
          Key := Upcase(GetChar);
          If Key = HotKey[L_Stop] Then
            Begin
              ClearLine;
              Bullet(COL_LOGOFF); WriteStringCF(LANG(L_LogoffAborted));
              WriteLines(1);
              PressSpace;
              Exit;
            End
          Else If Key = HotKey[L_Logoff] Then Goodbye;
        End;
    End;
  Goodbye;
End;

Procedure DisplayInfo(Info, Value: String);
Begin
  Bullet(COL_INFO);   WriteString(Info);
  DoColor(COL_VALUE); WriteStringCF(Value);
End;

Function ReturnSettings(Conf: Word; Var dCFG: MESSAGErecord): String;
Var
  Temp: String[10];
Begin
  Temp := '';
  If (Conf>0) And (Conf<=HighConf) Then
    Begin
      Case dCFG.MsgKinds Of
        kPrivate: Temp := Temp + 'P';
         kPublic: Temp := Temp + 'O';
           kBoth: Temp := Temp + 'X';
       kReadOnly: Temp := Temp + 'R';
        kNoReply: Temp := Temp + 'Z';
      End;
      Case dCFG.Typ Of
       LocalMail: Temp := Temp + 'L';
         Netmail: Temp := Temp + 'N';
        Echomail: Temp := Temp + 'E';
        Internet: Temp := Temp + 'I';
        UseGroup: Temp := Temp + 'U';
      End;
      If Is(dCFG.Attribute,32) Then Temp := Temp + 'H';      (* Handles     *)
      If Is(dCFG.Attribute,8)  Then Temp := Temp + 'A';      (* Alias       *)
      If Is(dCFG.Attribute,4)  Then Temp := Temp + '&';      (* File attach *)
    End;
  ReturnSettings := Temp;
End;

Function ReturnPackDate: Longint;
Var
  PK: Longint;
  DT: DateTime;
  Year, Month, Day, Week: Word;
Begin
  GetDate(Year,Month,Day,Week);
  Fillchar(DT,Sizeof(DT),0);
  DT.Year  := Year;
  DT.Month := Month;
  DT.Day   := Day;
  PackTime(DT,PK);
  ReturnPackDate := PK;
End;

Function ValueString(st: String): Word;
Var
  Num: Word;
  Code: Integer;
Begin
  Val(st,Num,Code);
  If Code <> 0 Then Val(Copy(st,1,Code-1),Num,Code);
  ValueString := Num;
End;

Procedure ReindexUsers;
Var
  fUSRIDX, fUSRDAT: File;
  l: Longint;
  C_Username: Array[1..40] Of Char;
Begin
  If Not (OpenFile(fUSRIDX,DataDir+'USERS.IDX','W',Sizeof(Longint),faWriteOnly+faDenyAll) And
          OpenFile(fUSRDAT,DataDir+'USERS.DAT','R',SIZE_USERS,faReadOnly+faDenyNone))
  Then
    Begin
      Logit('C','<!> User records could not be opened.');
      BulletError('<!> User records could not be opened.');
      NewHalt(2000);
    End;

  While Not Eof(fUSRDAT) Do
    Begin
      BlockRead(fUSRDAT,Human^,1);
      CString(C_Username,Copy(DowncaseStr(Human^.Name),1,39));
      l := Crc32(C_Username,LenBuf(C_Username),$FFFFFFFF);
      BlockWrite(fUSRIDX,l,1);
    End;

  CloseFile(fUSRDAT);
  CloseFile(fUSRIDX);
End;

Procedure TruncateFile(st: String);
Var
  f: File;
Begin
  If OpenFile(f,st,'R',1,faNormal) Then
    Begin
      Truncate(f);
      CloseFile(f);
    End;
End;

Procedure CheckPackMaybe(Var WhoTo, WhoFrom: String; Flags: Byte; Pvt: Boolean; Var Pack, Maybe, Personal: Boolean);
Var
  Written: Boolean;
Begin
  Inc(PNew);
  Inc(CNew);
  Pack     := False;
  Maybe    := False;

  If ((CPack >= MAXPCONF) Or (PPack >= MAXPPACK)) And Not Human^.IgnoreLimits Then Exit;

  Written  := IsWritten(WhoFrom);
  Personal := IsPersonal(WhoTo);

  If Is(Flags,fPERSONAL)     Then Begin If Personal Then Pack := True; End
  Else If Is(Flags,fGENERAL) Then Begin If Personal Or CheckIsAll(WhoTo) Then Pack := True; End
  Else If Is(Flags,fALL)     Then Begin Pack := True; End;

  If Is(Flags,fCONNECT) Then Pack := True
  Else If Personal And Human^.GlobalPersonal Then Pack := True
  Else If Written And Is(Flags,fSELF) Then Pack := True
  Else If Written Then Begin Pack := False; Maybe := False; End
  Else If (Pvt And Not PvtRights) And Not (Personal Or Written Or Is(Flags,fCONNECT))
       Then Begin Pack := False; Maybe := False; End
  Else If Is(Flags,fKEYWORD) Or Human^.GlobalKeywords Then Maybe := True;
End;

Function CheckIsAll(Var WhoTo: String): Boolean;
Var
  s1, s2: String[128];
Begin
  CheckIsAll := False;
  If (WhoTo = 'ALL') Or (Copy(WhoTo,1,4) = 'ALL ') Then
    Begin
      CheckIsAll := True
    End
  Else
    Begin
      s2 := UpcaseStr(LANG(L_All));
{      Logit('D','DEBUG: CA: Configuration='+s2); }
      Repeat
        SplitStrings(s2,s1,s2);
{        Logit('D','DEBUG: CA: s1='+s1+'; s2='+s2); }
        If (s1 <> '') Then
          Begin
            If (WhoTo = s1) Or (Copy(WhoTo,1,Length(s1)+1) = s1+' ') Then
              Begin
{                Logit('D','DEBUG: CA: Found'); }
                CheckIsAll := True;
                s2 := '';
              End;
          End;
      Until s2='';
    End;
End;

End.ÿÿÿ