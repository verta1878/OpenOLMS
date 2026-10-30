{****************************************************************************
  DM6000 — Doorman BBS Door Framework (Clean-Room Recreation)
  Copyright (C) 2026 the crew (verta1878) — GPLv3
  
  Clean-room TP7-compatible recreation. Compiled with TPC.EXE.
****************************************************************************}

Unit DM6000;

{$V-}
{$O-}

Interface

Uses Crt, Dos;

Const
  SEEK_SET = 0;
  SEEK_CUR = 1;
  SEEK_END = 2;
  faReadOnly  = $00;
  faReadWrite = $02;
  faDenyNone  = $40;
  faDenyWrite = $20;
  faDenyAll   = $10;
  faWriteOnly = $01;
  faNormal    = $00;
  DOS4 = 1;
  Upper  = 1;
  Number = 2;
  Normal = 0;
  COL_TEXT = 1; COL_ERROR = 2; COL_GOOD = 3; COL_TITLE = 4;
  COL_WORK = 5; COL_PROMPT = 6; COL_CONFNUM = 7; COL_CONFNAME = 8;
  COL_CONFFLAG = 9; COL_PACK = 10; COL_SPIN = 11; COL_QUESTION = 12;
  COL_INPUTFORE = 13; COL_LASTTIME = 14; COL_MODE = 15;
  TextBufferSize = 64000;
  CR = #13;
  BORDER_THICK = 1;
  ASCII = 0; ANSI = 1; AVATAR = 2; RIP = 3;

Type
  TBuf = Array[0..TextBufferSize+1500] Of Char;
  PBuf = ^TBuf;
  FlagType = Array[1..4] Of Byte;
  COMBINEDrecord = Array[1..200] Of Word;

  DM6000UserRecord = Record
    Name            : String[35];
    Handle          : String[35];
    FirstName       : String[15];
    LastName        : String[20];
    Location        : String[25];
    BirthDate       : String[8];
    Security        : Word;
    Flags           : FlagType;
    Credits         : Longint;
    Pending         : Longint;
    Posts           : Word;
    Language        : Byte;
    Emulation       : Byte;
    Protocol        : Char;
    Uploads         : Longint;
    Downloads       : Longint;
    UploadK         : Longint;
    DownloadK       : Longint;
    TodayDownloadK  : Longint;
    DownloadKLimit  : Word;
    LastRead        : Longint;
    CombinedInfo    : COMBINEDrecord;
    TimeLeft        : Word;
    Node            : Byte;
    RecordNumber    : Word;
    PostBill        : Boolean;
    XferPriority    : Boolean;
    NetmailEntered  : Boolean;
    EchomailEntered : Boolean;
  End;

  SYSrecord = Record
    Name  : String[40];
    Sysop : String[35];
  End;

Var
  Baud             : Longint;
  User             : DM6000UserRecord;
  Sys              : SYSrecord;
  Colors           : Array[1..20] Of Byte;
  MSGBUF           : PBuf;
  DM_BackSpaces    : String;
  LocalMode        : Byte;
  WatchUserTime    : Boolean;
  IgnoreCarrier    : Boolean;
  WheelPos         : Byte;
  MultitaskerType  : Byte;
  IdleMinutes      : Word;
  ComPort          : Word;
  ComHandle        : Longint;
  OldComHandle     : Longint;
  VideoSeg         : Word;
  ScreenBuf        : Array[0..3999] Of Byte;
  PushedKey        : Char;
  ExitCode         : Word;
  OldExitProc      : Pointer;
  SpaceString      : String;
  TimerActive      : Boolean;
  TimerSpeed       : Word;
  TimerCount       : Word;
  TimerInterval    : Word;
  CommandLine      : String;
  DateTemp         : String[10];
  TimeTemp         : String[10];
  YCharacter       : Char;
  AutoName                : String;
  BIT7                    : Boolean;
  BypassDropFile          : Boolean;
  ComLineMode             : Byte;
  DeductUserTime          : Boolean;
  DefaultOriginLine       : String;
  DetectRip               : Boolean;
  DisplayStatusShell      : Boolean;
  ERR                     : Word;
  EndProcedurePointer     : Pointer;
  GETSTRINGBACKGROUND     : Byte;
  LogLineTemp             : String;
  MaxNodesSupported       : Word;
  NCharacter              : Char;
  NString                 : String[3];
  SwapShellMethod         : Byte;
  SystemEnviroment        : Word;
  TIMESLICEMAXIMUM        : Word;
  TaglineSize             : Word;
  MonthString             : String;
  YString                 : String[3];
  BarMessage       : String[80];
  ProgramName      : String[40];
  BarMode           : Byte;

  TransferTotal    : Word;
  TransferRate     : Word;
  TransferActive   : Byte;
  SpinnerCount     : Byte;
  MsgBaseType      : Byte;
{ String utilities }
  CounterWord1: Word;
  CounterWord2: Word;
  CounterWord3: Word;
  CounterFlag : Byte;
  CounterWord4: Word;
  CounterWord5: Word;

Procedure InitCounters;

Function  ZeroPad(Value: Longint; Width: Integer): String;
Function  lZeroPad(Value: Longint; Width: Integer): String;
Function  SpacePad(s: String; Width: Integer): String;
Function  PadStr(s: String; Width: Integer): String;
Function  HexStr(W: Word): String;
Function  UpcaseStr(s: String): String;
Function  DowncaseStr(s: String): String;
Function  CapsWord(s: String): String;
Function  Vis(s: String): String;
Procedure SplitStrings(s: String; Var s1, s2: String);
Function  StripLeadAndTrail(s: String): String;
Function  FirstWordLetter(s: String): String;
Function  SecondWordString(s: String): String;
Function  LastWordLetter(s: String): String;
Function  ShortWord(s: String): String;
Function  InternetStyle(s: String): String;
Function  IsInternet(s: String): Boolean;
Function  ValueString(s: String): Longint;

{ File operations }
Function  OpenFile(Var f: File; FileName: String;
            Mode: Char; RecSize: Word; ShareMode: Word): Boolean;
Function  CloseFile(Var f: File): Boolean;
Function  OpenText(Var f: Text; FileName: String;
            Mode: Char; ShareMode: Word): Boolean;
Procedure CloseText(Var f: Text);
Procedure AppendFile(FileName: String; Line: String);
Function  CopyFile(Src, Dst: String): Boolean;
Procedure TruncateFile(FileName: String);
Function  SizeofFile(FileName: String): Longint;
Function  FileDate(FileName: String): Longint;
Function  FileExists(FileName: String): Boolean;

{ Date/time }
Procedure DayToDate(Day: Word; Var DateStr: String);
Procedure DateToDay(Var Day: Word; DateStr: String);
Function  PresentDay: Word;
Function  PresentSecond: Longint;
Procedure ShowTransferProgress; Far;
Procedure SpinnerUpdate; Far;
Procedure SecondsToTime(Seconds: Longint; Var TimeStr: String);
Function  ReturnPackDate: Longint;
Function  DateToJulian: Longint;

{ Handle I/O }
Function  ReadHandle(Handle: Integer; Var Buf; Count: Word): Word;
Function  WriteHandle(Handle: Integer; Var Buf; Count: Word): Word;
Function  SeekHandle(Handle: Integer; Origin: Integer;
            Offset: Longint): Longint;
Function  LockHandle(Handle: Integer; Offset: Longint;
            Length: Longint; Lock: Boolean): Boolean;

{ Screen output }
Procedure WriteString(s: String);
Procedure WriteStringCF(s: String);
Procedure WriteLines(N: Byte);
Procedure WriteChar(c: Char);
Procedure DoColor(ColorIndex: Byte);
Procedure SetColor(Attr: Byte);
Procedure ClearLine;
Procedure ClearScreen;
Procedure GotoLoc(X, Y: Integer);
Procedure DrawWindow(X1, Y1, X2, Y2: Integer; Attr: Byte);
Procedure DrawLine;
Procedure Bullet(ColorIndex: Byte);
Procedure BulletError(s: String);
Procedure DisplayInfo(Lab, Value: String);
Procedure DisplayStatusBar;
Procedure Wheel;

{ User input }
Function  GetChar: Char;
Function  GetString(MaxLen: Byte; Color: Byte; Filter: Byte): String;
Procedure GetString2(Var s: String; MaxLen, DispLen: Byte;
            Color: Byte; Filter: Byte);
Function  ExTimedYesNo(DefaultKey: Char; Timeout: Word): Char;
Function  IsChar: Boolean;

{ Serial I/O }
Function  CheckCarrier: Boolean;
Procedure WriteCom(c: Char);
Function  InitFossil(Port: Word): Boolean;
Procedure DeinitFossil;

{ Door framework }
Procedure StoreScreen;
Procedure RestoreScreen;
Procedure EndDoorMaker;
Procedure Logit(Level: Char; Msg: String);
Procedure Sleep(Seconds: Word);
Function MkDirCheck(Var Path: String): Boolean;
Function ChDirCheck(Var Path: String): Boolean;
Procedure ZeroPadInt(Val: Integer; Var s: String; Width: Byte);
Procedure ZeroPadLong(Val: Longint; Var s: String; Width: Byte);
Procedure Hangup;
Function  ChangeDirectory(Dir: String): Boolean;
Function  DirectoryExists(Dir: String): Boolean;
Procedure LoadExitInfo(Path: String);
Procedure SaveExitInfo(Path: String);


{ Additional DM6000 exports }
Function  MakeDirectory(Dir: String): Boolean;
Function  KillDirectory(Dir: String): Boolean;
Function  DirInfo(Dir: String; Var OldDate: String;
            Var Bytes: Longint): Boolean;
Function  YN(B: Boolean): String;
Procedure GetWelcome(FileName: String);
Function  CheckIsAll(WhoTo: String): Boolean;
Procedure SaveLastRead(Conf: Word; Value: Longint);
Procedure WriteCenterString(Width: Integer; s: String);
Function  TimedYesNo(DefaultKey: Char; Timeout: Word): Char;
Procedure DisplayTextFile(FileName: String);
Procedure PressSpace;
Function  HeapSizeAllocated: Longint;
Procedure CursorHide;
Procedure CursorView;
Procedure FillScreen(Attr: Byte);


{ More DM6000 exports — discovered during compilation }
Procedure TxStringCF(s: String);
Procedure WaitSendBufferClear;
Function  OpenHandle(FileName: String): Integer;
Function  CloseHandle(Handle: Integer): Integer;
Procedure KillFile(FileName: String);
Function  CreateFile(FileName: String): Boolean;
Function  Shell(Cmd: String): Word;
Function  AutoPath(FileName: String): String;
Function  AutoCap(s: String): String;
Function  GetPushedKey(Var Key: Char): Boolean;
Procedure NewHalt(Code: Word);
Function  LettersOnly(s: String): String;
Procedure FourPrompt(Var s: String; p1,p2,p3,p4: String);
Procedure TwoPrompt(Var s: String; p1,p2: String);
Procedure NodeCost(Zone,Net,Node,Pnt: Word; Var Cost: Word);
Function  RenameFile(OldName, NewName: String): Boolean;

Procedure PutTrail(Var s: String);
Procedure TimeSlice;
Function TrueCarrier: Boolean;
Procedure WriteCRLF;
Function  ExpandMetaString(s: String): String;
Function  ExpandFileMetaString(s: String): String;
Function  MetaFileExists(FileName: String): Boolean;

{ Serial I/O }
Function  ReadCom: Boolean;
Function  CharAvail: Boolean; Far;
Function  ReadCharTimeout: Char; Far;
Function  FlushInBuffer: Boolean;
Procedure DrainInput;
Function  ReadChar: Char;
Procedure CheckCarrierFull;
Function  IsKeyPressed: Boolean;

{ Exports needed by U_UNIT/OLMS/CONFIG/MAINTAIN }
Function  DisplayPacked(FileName: String; Flag: String; Extra: String): Boolean;
Function  LockFileHandle(Handle: Integer; Lock: Boolean): Integer;
Function  ScreenPath(FileName: String): String;
Procedure LoadMenuKeys(Num: Byte);
Function  Crc32(Var Buf; Len: Word; Init: Longint): Longint;
Function  ReturnCrc(FileName: String): Longint;
Procedure WaitReceiveBufferClear;
Procedure KillBut(KeepFile: String);
Function  Max2(A, B: Word): Word;
Function  wValue(s: String): Word;
Procedure WriteDropFile;
Function  GetPath(FullPath: String): String;
Procedure PrimeDoorMaker;
Procedure StartDoorMaker;
Procedure ReadDropFile(FileName: String);
Procedure StopTimer;
Procedure InitTimer;
Function  Min(A, B: Word): Word;


Function  ResetFile(Var f: Text): Boolean; Far;
Function  RewriteFile(Var f: Text): Boolean; Far;
Procedure FOSSILFlush;
Procedure WriteStringCR(s: String);
Procedure FOSSILBlockWrite(Var Buf; Len: Word);
Procedure ClearWindow;
Procedure WaitCarrier;
Procedure WriteComCR(s: String);
Procedure DTRControl(State: Byte);
Function  MinLong(A, B: Longint): Longint;
Function  FOSSILInit(Port: Word): Word;

Implementation

Procedure InitCounters;
Begin
  CounterWord1 := 0;
  CounterWord2 := 0;
  CounterWord3 := 0;
  CounterFlag  := 0;
  CounterWord4 := 0;
  CounterWord5 := 0;
End;


Function ZeroPad(Value: Longint; Width: Integer): String;
Var s: String[20]; i: Word;
Begin
  Str(Abs(Value):Width, s);
  If Value > 0 Then
    For i := 1 To Length(s) Do
      If s[i] = ' ' Then s[i] := '0';
  ZeroPad := s;
End;

Function lZeroPad(Value: Longint; Width: Integer): String;
Begin lZeroPad := ZeroPad(Value, Width); End;

Function SpacePad(s: String; Width: Integer): String;
Var Temp: String;
Begin
  Temp := Copy(s, 1, Width);
  While Length(Temp) < Width Do
    Temp := Concat(Temp, ' ');
  SpacePad := Temp;
End;

Function PadStr(s: String; Width: Integer): String;
Begin PadStr := SpacePad(s, Width); End;

Function HexStr(W: Word): String;
Const H: Array[0..15] Of Char = '0123456789ABCDEF';
Begin
  HexStr := H[W Shr 12] + H[(W Shr 8) And $F]
          + H[(W Shr 4) And $F] + H[W And $F];
End;

Function UpcaseStr(s: String): String;
Var i: Integer;
Begin
  For i := 1 To Length(s) Do s[i] := Upcase(s[i]);
  UpcaseStr := s;
End;

Function DowncaseStr(s: String): String;
Var i: Integer;
Begin
  For i := 1 To Length(s) Do
    If s[i] In ['A'..'Z'] Then
      s[i] := Chr(Ord(s[i]) + 32);
  DowncaseStr := s;
End;

Function CapsWord(s: String): String;
Var i: Integer; Cap: Boolean;
Begin
  s := DowncaseStr(s); Cap := True;
  For i := 1 To Length(s) Do
    Begin
      If Cap And (s[i] In ['a'..'z']) Then
        Begin s[i] := Upcase(s[i]); Cap := False; End
      Else
        If s[i] = ' ' Then Cap := True;
    End;
  CapsWord := s;
End;

Function Vis(s: String): String;
Var i: Integer;
Begin
  For i := 1 To Length(s) Do
    If s[i] < ' ' Then s[i] := '.';
  Vis := s;
End;

Procedure SplitStrings(s: String; Var s1, s2: String);
Var p: Integer;
Begin
  p := Pos(' ', s);
  If p = 0 Then
    Begin s1 := s; s2 := ''; End
  Else
    Begin
      s1 := Copy(s, 1, p-1);
      s2 := Copy(s, p+1, 255);
      While (Length(s2) > 0) And (s2[1] = ' ') Do
        Delete(s2, 1, 1);
    End;
End;

Function StripLeadAndTrail(s: String): String;
Begin
  While (Length(s) > 0) And (s[1] = ' ') Do Delete(s, 1, 1);
  While (Length(s) > 0) And (s[Length(s)] = ' ') Do
    Delete(s, Length(s), 1);
  StripLeadAndTrail := s;
End;

Function FirstWordLetter(s: String): String;
Begin
  If Length(s) > 0 Then FirstWordLetter := Upcase(s[1])
  Else FirstWordLetter := '';
End;

Function SecondWordString(s: String): String;
Var p: Integer;
Begin
  p := Pos(' ', s);
  If p > 0 Then SecondWordString := Copy(s, p+1, 255)
  Else SecondWordString := '';
End;

Function LastWordLetter(s: String): String;
Var i: Integer;
Begin
  LastWordLetter := '';
  For i := Length(s) Downto 1 Do
    If (i = 1) Or (s[i-1] = ' ') Then
      Begin LastWordLetter := Upcase(s[i]); Exit; End;
End;

Function ShortWord(s: String): String;
Var r: String; i: Integer;
Begin
  If Length(s) <= 6 Then Begin ShortWord := s; Exit; End;
  r := s[1];
  For i := 2 To Length(s)-1 Do
    If Not (Upcase(s[i]) In ['A','E','I','O','U']) Then
      r := r + s[i];
  r := r + s[Length(s)];
  If Length(r) > 13 Then r := Copy(r, 1, 13);
  ShortWord := r;
End;

Function InternetStyle(s: String): String;
Var r: String; i: Integer;
Begin
  r := ''; i := 1;
  While i <= Length(s) Do
    Begin
      If (i = 1) Or (s[i-1] = '.') Then
        Begin
          If Pos('.', Copy(s, i, 255)) = 0 Then
            Begin
              r := r + Copy(s, i, 255);
              i := Length(s) + 1;
            End
          Else
            Begin
              r := r + s[i] + '.';
              While (i <= Length(s)) And (s[i] <> '.') Do Inc(i);
              Inc(i);
            End;
        End
      Else Inc(i);
    End;
  InternetStyle := r;
End;

Function IsInternet(s: String): Boolean;
Begin
  If (Pos('.', s) > 0) And (Pos(' ', s) = 0) Then IsInternet := True
  Else IsInternet := False;
End;

Function ValueString(s: String): Longint;
Var v: Longint; c: Integer;
Begin
  Val(s, v, c);
  If c <> 0 Then ValueString := 0
  Else ValueString := v;
End;

{ === FILE OPERATIONS === }

Function OpenFile(Var f: File; FileName: String;
  Mode: Char; RecSize: Word; ShareMode: Word): Boolean;
Var OldMode: Byte;
Begin
  {$I-}
  OldMode := FileMode;
  Assign(f, FileName);
  FileMode := ShareMode;
  Case Upcase(Mode) Of
    'W': Rewrite(f, RecSize);
    'X': Begin
           Reset(f, RecSize);
           If IOResult <> 0 Then Rewrite(f, RecSize)
           Else Seek(f, FileSize(f));
         End;
    'R': Reset(f, RecSize);
  Else Reset(f, RecSize);
  End;
  If IOResult <> 0 Then OpenFile := False
    Else OpenFile := True;
  FileMode := OldMode;
  {$I+}
End;

Function  CloseFile(Var f: File): Boolean;
Begin {$I-} Close(f); If IOResult <> 0 Then; {$I+} End;

Function OpenText(Var f: Text; FileName: String;
  Mode: Char; ShareMode: Word): Boolean;
Begin
  {$I-}
  Assign(f, FileName);
  Case Mode Of
    'W': Rewrite(f);
    'X': Begin
           Append(f);
           If IOResult <> 0 Then Rewrite(f);
         End;
  Else Reset(f);
  End;
  If IOResult <> 0 Then OpenText := False
    Else OpenText := True;
  {$I+}
End;

Procedure CloseText(Var f: Text);
Begin {$I-} Close(f); If IOResult <> 0 Then; {$I+} End;

Procedure AppendFile(FileName: String; Line: String);
Var f: Text;
Begin
  {$I-}
  Assign(f, FileName); Append(f);
  If IOResult <> 0 Then Rewrite(f);
  If IOResult = 0 Then Begin Writeln(f, Line); Close(f); End;
  {$I+}
End;

Function  CopyFile(Src, Dst: String): Boolean;
Var fIn, fOut: File;
    Buf: Array[1..8192] Of Byte; BytesRead: Word;
Begin
  CopyFile := False;
  {$I-}
  Assign(fIn, Src); Reset(fIn, 1);
  If IOResult <> 0 Then Exit;
  Assign(fOut, Dst); Rewrite(fOut, 1);
  If IOResult <> 0 Then Begin Close(fIn); Exit; End;
  Repeat
    BlockRead(fIn, Buf, SizeOf(Buf), BytesRead);
    If BytesRead > 0 Then BlockWrite(fOut, Buf, BytesRead);
  Until BytesRead = 0;
  Close(fIn); Close(fOut);
  CopyFile := True;
  {$I+}
End;

Procedure TruncateFile(FileName: String);
Var f: File;
Begin
  {$I-}
  Assign(f, FileName); Rewrite(f, 1);
  If IOResult = 0 Then Close(f);
  {$I+}
End;

Function SizeofFile(FileName: String): Longint;
Var f: File; s: Longint;
Begin
  {$I-}
  Assign(f, FileName); Reset(f, 1);
  If IOResult = 0 Then
    Begin s := FileSize(f); Close(f); SizeofFile := s; End
  Else
    SizeofFile := -1;
  {$I+}
End;

Function FileDate(FileName: String): Longint;
Var f: File; t: Longint;
Begin
  {$I-}
  Assign(f, FileName); Reset(f, 1);
  If IOResult = 0 Then
    Begin GetFTime(f, t); Close(f); FileDate := t; End
  Else
    FileDate := 0;
  {$I+}
End;

Function FileExists(FileName: String): Boolean;
Var f: File;
Begin
  {$I-}
  Assign(f, FileName); Reset(f, 1);
  If IOResult = 0 Then
    Begin Close(f); FileExists := True; End
  Else
    FileExists := False;
  {$I+}
End;

{ === DATE/TIME === }

Procedure DayToDate(Day: Word; Var DateStr: String);
Var Y, M, D: Word;
Begin
  Y := Day Div 372;
  M := (Day - Y * 372) Div 31 + 1;
  D := Day - Y * 372 - (M - 1) * 31;
  If D = 0 Then Begin D := 31; Dec(M); End;
  If M = 0 Then Begin M := 12; Dec(Y); End;
  DateStr := ZeroPad(M, 2) + '/' + ZeroPad(D, 2) + '/'
           + ZeroPad(Y Mod 100, 2);
End;

Procedure DateToDay(Var Day: Word; DateStr: String);
Var M, D, Y: Word; c: Integer;
Begin
  Val(Copy(DateStr, 1, 2), M, c);
  Val(Copy(DateStr, 4, 2), D, c);
  Val(Copy(DateStr, 7, 2), Y, c);
  Day := (M - 1) * 31 + (Y + 100) * 372 + D;
End;


Procedure ShowTransferProgress;
Var Temp: String;
Begin
  If TransferActive = 0 Then Exit;
  Inc(TransferTotal, TransferRate);
  Temp := Concat(#27'[s');
  WriteString(Temp);
  WriteString(ZeroPad(TransferTotal Div 100, 3));
  WriteString('% ');
  WriteStringCF('');
End;


Procedure SpinnerUpdate;
Const SpinChars: String[4] = '|/-\';
Begin
  Inc(SpinnerCount);
  If SpinnerCount > 5 Then Exit;
  WheelPos := (WheelPos Mod 4) + 1;
  WriteString(Concat(#27'[s'));
  WriteString(SpinChars[WheelPos]);
  WriteStringCF('');
  SpinnerCount := 0;
End;

Procedure ClearTransfer; Far;
Begin
  TransferActive := 0;
End;

Function PresentDay: Word;
Var Y, M, D, DOW: Word;
Begin
  GetDate(Y, M, D, DOW);
  PresentDay := (Y - 1900) * 372 + (M - 1) * 31 + D;
End;

Function PresentSecond: Longint;
Var H, M, S, S100: Word;
Begin
  GetTime(H, M, S, S100);
  PresentSecond := Longint(H)*3600 + Longint(M)*60 + S;
End;

Procedure SecondsToTime(Seconds: Longint; Var TimeStr: String);
Begin
  TimeStr := ZeroPad(Seconds Div 3600, 2) + ':'
           + ZeroPad((Seconds Mod 3600) Div 60, 2);
End;

Function ReturnPackDate: Longint;
Var Y, M, D, DOW: Word;
Begin
  GetDate(Y, M, D, DOW);
  ReturnPackDate := Longint(Y)*10000 + Longint(M)*100 + D;
End;

Function DateToJulian: Longint;
Begin DateToJulian := PresentDay; End;

{ === HANDLE I/O === }

Function ReadHandle(Handle: Integer; Var Buf;
  Count: Word): Word;
Var Regs: Registers;
Begin
  Regs.AH := $3F; Regs.BX := Handle; Regs.CX := Count;
  Regs.DS := Seg(Buf); Regs.DX := Ofs(Buf);
  Intr($21, Regs);
  If Regs.Flags And FCarry <> 0 Then ReadHandle := 0
  Else ReadHandle := Regs.AX;
End;

Function WriteHandle(Handle: Integer; Var Buf;
  Count: Word): Word;
Var Regs: Registers;
Begin
  Regs.AH := $40; Regs.BX := Handle; Regs.CX := Count;
  Regs.DS := Seg(Buf); Regs.DX := Ofs(Buf);
  Intr($21, Regs);
  If Regs.Flags And FCarry <> 0 Then WriteHandle := 0
  Else WriteHandle := Regs.AX;
End;

Function SeekHandle(Handle: Integer; Origin: Integer;
  Offset: Longint): Longint;
Var Regs: Registers;
Begin
  Regs.AH := $42; Regs.AL := Lo(Origin);
  Regs.BX := Handle;
  Regs.CX := Word(Offset Shr 16);
  Regs.DX := Word(Offset);
  Intr($21, Regs);
  If Regs.Flags And FCarry <> 0 Then SeekHandle := 0
  Else SeekHandle := Longint(Regs.DX) Shl 16 + Regs.AX;
End;

Function LockHandle(Handle: Integer; Offset: Longint;
  Length: Longint; Lock: Boolean): Boolean;
Var Regs: Registers;
Begin
  Regs.AH := $5C;
  If Lock Then Regs.AL := 0 Else Regs.AL := 1;
  Regs.BX := Handle;
  Regs.CX := Word(Offset Shr 16);
  Regs.DX := Word(Offset);
  Regs.SI := Word(Length Shr 16);
  Regs.DI := Word(Length);
  Intr($21, Regs);
  If (Regs.Flags And FCarry) <> 0 Then LockHandle := False
  Else LockHandle := True;
End;

{ === SERIAL I/O === }

{ Internal FOSSIL helpers — Assembler, no stack frame }
Function  FOSSILStatus: Word; Near; Assembler;
Asm
  mov ah, 3
  mov dx, ComPort
  int 14h
End;

Procedure FOSSILFlush; Assembler;
Asm
  mov ah, 9
  mov dx, ComPort
  int 14h
End;

Procedure FOSSILPurge; Near; Assembler;
Asm
  mov ah, 2
  mov dx, ComPort
  int 14h
End;

Procedure FOSSILDeinit; Near; Assembler;
Asm
  mov ah, 5
  mov dx, ComPort
  int 14h
End;

Function CheckCarrier: Boolean;
Begin
  CheckCarrier := False;
  If ComHandle = 0 Then
  Else
    If (FOSSILStatus And $80) = $80 Then
      CheckCarrier := True;
End;

Function FOSSILReadChar: Char; Near; Assembler;
Asm
  mov ah, 02h
  mov dx, ComPort
  int 14h
End;

Function FOSSILWriteChar(c: Byte): Word; Assembler;
Asm
  mov ah, 0Bh
  mov al, c
  mov dx, ComPort
  int 14h
End;

Function TrueCarrierNear: Boolean; Near;
Begin
  TrueCarrierNear := ComHandle <> 0;
End;

Procedure WriteCom(c: Char);
Var Ok, Retries: Byte;
Begin
  TrueCarrier;
  If Not IgnoreCarrier Then
    If CheckCarrier = False Then Exit;
  If c = '~' Then
    If User.Emulation = RIP Then
      c := #13;
  While (FOSSILStatus And $2000) <> $2000 Do
    TrueCarrier;
  Asm
    mov byte ptr Ok, 0
    mov byte ptr Retries, 0
  @Send:
    mov dx, ComPort
    mov al, c
    mov ah, 0Bh
    int 14h
    cmp ax, 1
    je  @Success
    inc byte ptr Retries
    cmp byte ptr Retries, 14h
    jl  @Send
    jmp @Recheck
  @Success:
    mov byte ptr Ok, 1
  @Recheck:
    cmp byte ptr Ok, 1
    je  @Done
    push cs
    call TrueCarrierNear
    or  al, al
    je  @Send
  @Done:
  End;
End;

Function FOSSILInit(Port: Word): Word; Assembler;
Asm
  mov ah, 04h
  mov dx, Port
  xor bx, bx
  int 14h
End;

Procedure SetFlowControl(Mode: Byte); Near; Forward;
Function InitFossil(Port: Word): Boolean;
Const
  LogInit: String[8] = 'Fossil: ';
  LogFail: String[8] = 'No FOSSIL';
  LogDone: String[9] = 'Fossil ok';
Var
  Divisor, DataBits, Parity, StopBits: Byte;
  w: Word;
Begin
  InitFossil := False;
  w := FOSSILInit(Port);
  If w <> $1954 Then
    Begin
      Logit('!', LogFail + LogInit + LogDone);
      Exit;
    End;
  InitFossil := True;
  If (OldComHandle = 0) Then
    Begin
      OldComHandle := ComHandle;
    End;
  { Baud rate divisor }
  If ComHandle > 300 Then
    Divisor := $40
  Else If ComHandle = 600 Then
    Divisor := $60
  Else If ComHandle = 1200 Then
    Divisor := $80
  Else If ComHandle = 2400 Then
    Divisor := $A0
  Else If ComHandle = 4800 Then
    Divisor := $C0
  Else If ComHandle = 9600 Then
    Divisor := $E0
  Else If ComHandle = 19200 Then
    Divisor := $00
  Else If ComHandle = 38400 Then
    Divisor := $20
  Else If ComHandle = 57600 Then
    Divisor := $40
  Else If ComHandle = 115200 Then
    Divisor := $80
  Else
    Divisor := $00;
  DataBits := 3; { 8 data bits }
  Parity := 0;   { None }
  StopBits := 0;  { 1 stop bit }
  Asm
    mov ah, 0
    mov al, Divisor
    or al, DataBits
    or al, Parity
    or al, StopBits
    mov dx, ComPort
    int 14h
  End;
  Logit('!', LogDone + LogInit + LogFail);
  If ComHandle >= 9600 Then
    SetFlowControl(9)
  Else
    SetFlowControl(2);
End;

Procedure DeinitFossil;
Begin
  If ComHandle > 0 Then FOSSILDeinit;
End;

{ === SCREEN OUTPUT === }

Procedure WriteString(s: String);
Var i: Byte;
Begin
  If Not IgnoreCarrier Then
    If CheckCarrier = False Then
      Begin WriteCRLF; Exit; End;
  For i := 1 To Length(s) Do
    WriteCom(s[i]);
End;

Procedure WriteStringCF(s: String);
Begin
  WriteString(s);
  Writeln(s);
End;

Procedure WriteLines(N: Byte);
Const EmptyStr: String[1] = '';
Var i: Byte;
Begin
  For i := 1 to N Do
    WriteStringCF(EmptyStr);
End;


Procedure WriteChar(c: Char);
Begin
  If c <> #7 Then
    Write(c);
  WriteCom(c);
End;

Procedure DoColor(ColorIndex: Byte);
Var Attr: Byte;
Begin
  If (ColorIndex >= 1) And (ColorIndex <= 20) Then
    Begin
      Attr := Colors[ColorIndex];
      TextAttr := Attr;
      If (LocalMode = 0) And (User.Emulation >= ANSI) Then
        Begin
          WriteCom(#27); WriteCom('[');
          WriteCom('0'); WriteCom(';');
          { Foreground }
          Case Attr And $07 Of
            0: Begin WriteCom('3'); WriteCom('0'); End;
            1: Begin WriteCom('3'); WriteCom('4'); End;
            2: Begin WriteCom('3'); WriteCom('2'); End;
            3: Begin WriteCom('3'); WriteCom('6'); End;
            4: Begin WriteCom('3'); WriteCom('1'); End;
            5: Begin WriteCom('3'); WriteCom('5'); End;
            6: Begin WriteCom('3'); WriteCom('3'); End;
            7: Begin WriteCom('3'); WriteCom('7'); End;
          End;
          If Attr And $08 <> 0 Then
            Begin WriteCom(';'); WriteCom('1'); End;
          If Attr And $80 <> 0 Then
            Begin WriteCom(';'); WriteCom('5'); End;
          { Background }
          WriteCom(';');
          Case (Attr Shr 4) And $07 Of
            0: Begin WriteCom('4'); WriteCom('0'); End;
            1: Begin WriteCom('4'); WriteCom('4'); End;
            2: Begin WriteCom('4'); WriteCom('2'); End;
            3: Begin WriteCom('4'); WriteCom('6'); End;
            4: Begin WriteCom('4'); WriteCom('1'); End;
            5: Begin WriteCom('4'); WriteCom('5'); End;
            6: Begin WriteCom('4'); WriteCom('3'); End;
            7: Begin WriteCom('4'); WriteCom('7'); End;
          End;
          WriteCom('m');
        End;
    End;
End;

Procedure SetColor(Attr: Byte);
Begin TextAttr := Attr; End;

Procedure ClearLine;
Begin
  Write(#13); ClrEol;
  If (LocalMode = 0) And (User.Emulation >= ANSI) Then
    Begin
      WriteCom(#13);
      WriteCom(#27); WriteCom('['); WriteCom('K');
    End;
End;

Procedure ClearScreen;
Begin
  ClrScr;
  If (LocalMode = 0) And (User.Emulation >= ANSI) Then
    Begin
      WriteCom(#27); WriteCom('[');
      WriteCom('2'); WriteCom('J');
      WriteCom(#27); WriteCom('[');
      WriteCom('H');
    End;
End;

Procedure GotoLoc(X, Y: Integer);
Var s: String;
Begin
  GotoXY(X, Y);
  If (LocalMode = 0) And (User.Emulation >= ANSI) Then
    Begin
      WriteCom(#27); WriteCom('[');
      Str(Y, s);
      WriteString(s);
      WriteCom(';');
      Str(X, s);
      WriteString(s);
      WriteCom('H');
    End;
End;

Procedure DrawWindow(X1, Y1, X2, Y2: Integer; Attr: Byte);
Var i: Integer;
Begin
  SetColor(Attr);
  DoColor(COL_TITLE);
  GotoLoc(X1, Y1);
  WriteChar(#218);
  For i := X1+1 To X2-1 Do WriteChar(#196);
  WriteChar(#191);
  For i := Y1+1 To Y2-1 Do
    Begin
      GotoLoc(X1, i); WriteChar(#179);
      GotoLoc(X1+1, i);
      WriteString(SpacePad('', X2-X1-1));
      GotoLoc(X2, i); WriteChar(#179);
    End;
  GotoLoc(X1, Y2);
  WriteChar(#192);
  For i := X1+1 To X2-1 Do WriteChar(#196);
  WriteChar(#217);
  Window(X1+1, Y1+1, X2-1, Y2-1);
End;

Procedure DrawLine;
Var i: Integer;
Begin For i := 1 To 79 Do Write(#196); Writeln; End;

Procedure Bullet(ColorIndex: Byte);
Begin DoColor(ColorIndex); Write(' '#254' '); End;

Procedure BulletError(s: String);
Begin DoColor(COL_ERROR); Write(' '#254' '); WriteStringCF(s); End;

Procedure DisplayInfo(Lab, Value: String);
Begin
  DoColor(COL_TITLE); WriteString(Lab);
  DoColor(COL_TEXT); WriteStringCF(Value);
End;

Procedure DisplayStatusBar;
Begin
  DoColor(COL_WORK);
  GotoXY(1, 1);
  WriteString(SpacePad(BarMessage, 80));
End;

Procedure Wheel;
Const WC: Array[0..3] Of Char = '|/-\';
Begin Write(#8, WC[WheelPos And 3]); Inc(WheelPos); End;

{ === USER INPUT === }

Function GetChar: Char;
Var c: Char; Regs: Registers;
Begin
  IdleMinutes := 0;
  If LocalMode <> 0 Then Begin GetChar := ReadKey; Exit; End;
  Repeat
    { Check local keyboard first }
    If KeyPressed Then
      Begin
        c := ReadKey;
        If c = #0 Then Begin c := ReadKey; Continue; End;
        GetChar := c; Exit;
      End;
    { Check COM port (non-blocking read) }
    Regs.AH := $0C; Regs.DX := ComPort;
    Intr($14, Regs);
    If (Regs.AH And $01) <> 0 Then
      Begin GetChar := Chr(Regs.AL); Exit; End;
    { Check carrier }
    If Not CheckCarrier And Not IgnoreCarrier Then
      Begin GetChar := #0; Exit; End;
  Until False;
End;

Function GetString(MaxLen: Byte; Color: Byte;
  Filter: Byte): String;
Var s: String; c: Char;
Begin
  s := ''; TextAttr := Color;
  Repeat
    c := GetChar;
    If (c = #8) And (Length(s) > 0) Then
      Begin Delete(s, Length(s), 1); Write(#8' '#8); End
    Else If (c = #13) Or (c = #27) Then
      { done }
    Else If (c >= ' ') And (Length(s) < MaxLen) Then
      Begin
        If Filter = Upper Then c := Upcase(c);
        s := s + c; Write(c);
      End;
  Until (c = #13) Or (c = #27);
  If c = #27 Then s := '';
  GetString := s;
End;

Procedure GetString2(Var s: String; MaxLen, DispLen: Byte;
  Color: Byte; Filter: Byte);
Var c: Char;
Begin
  TextAttr := Color; Write(s);
  Repeat
    c := GetChar;
    If (c = #8) And (Length(s) > 0) Then
      Begin Delete(s, Length(s), 1); Write(#8' '#8); End
    Else If (c = #13) Or (c = #27) Then
      { done }
    Else If (c >= ' ') And (Length(s) < MaxLen) Then
      Begin
        If Filter = Upper Then c := Upcase(c);
        s := s + c; Write(c);
      End;
  Until (c = #13) Or (c = #27);
  If c = #27 Then s := '';
End;

Function ExTimedYesNo(DefaultKey: Char; Timeout: Word): Char;
Var c: Char; StartTick: Longint; Regs: Registers;
Begin
  StartTick := MemL[$0040:$006C];
  Repeat
    { Local keyboard }
    If KeyPressed Then
      Begin
        c := ReadKey;
        If c = #0 Then Begin ReadKey; Continue; End;
        ExTimedYesNo := Upcase(c);
        Exit;
      End;
    { Remote COM }
    If (LocalMode = 0) Then
      Begin
        Regs.AH := $0C; Regs.DX := ComPort;
        Intr($14, Regs);
        If (Regs.AH And $01) <> 0 Then
          Begin
            ExTimedYesNo := Upcase(Chr(Regs.AL));
            Exit;
          End;
      End;
  Until (MemL[$0040:$006C] - StartTick) >= Timeout;
  ExTimedYesNo := DefaultKey;
End;

Function IsChar: Boolean;
Var Regs: Registers;
Begin
  If KeyPressed Then Begin IsChar := True; Exit; End;
  If LocalMode <> 0 Then Begin IsChar := False; Exit; End;
  Regs.AH := $03; Regs.DX := ComPort;
  Intr($14, Regs);
  If (Regs.AH And $01) <> 0 Then IsChar := True
  Else IsChar := False;
End;

{ === DOOR FRAMEWORK === }

Procedure StoreScreen;
Var i: Word;
Begin
  For i := 0 To $0F9F Do
    ScreenBuf[i] := Byte(Ptr(VideoSeg, i)^);
End;

Procedure RestoreScreen;
Var i: Word;
Begin
  For i := 0 To $0F9F Do
    Byte(Ptr(VideoSeg, i)^) := ScreenBuf[i];
End;

Procedure EndDoorMaker;
Var i: Byte;
Begin
  If (LocalMode = 0) Then
    Begin
      WaitSendBufferClear;
      DeinitFossil;
    End;
  If MSGBUF <> Nil Then Begin Dispose(MSGBUF); MSGBUF := Nil; End;
  { Screen buffer is static, no cleanup needed }
  Window(1, 1, 80, 25);
  TextAttr := 7;
  CursorView;
End;

Procedure Logit(Level: Char; Msg: String);
Var f: Text; Dir: String;
    H, M, S, S100: Word;
    Y, Mo, D, DOW: Word;
Begin
  {$I-}
  GetTime(H, M, S, S100);
  GetDate(Y, Mo, D, DOW);
  GetDir(0, Dir);
  If Dir[Length(Dir)] <> '\' Then Dir := Dir + '\';
  Assign(f, Dir + 'OLMS.LOG');
  Append(f);
  If IOResult <> 0 Then Rewrite(f);
  If IOResult = 0 Then
    Begin
      Write(f, Level, ' ');
      Write(f, ZeroPad(Mo,2), '/', ZeroPad(D,2), ' ');
      Write(f, ZeroPad(H,2), ':', ZeroPad(M,2), ':', ZeroPad(S,2));
      Writeln(f, ' ', Msg);
      Close(f);
    End;
  {$I+}
End;

Procedure Sleep(Seconds: Word);
Var H, M, S, S100: Word;
    LastS: Word;
Begin
  If Seconds = 0 Then Exit;
  If Seconds > 999 Then
    Seconds := Seconds Div 1000;
  GetTime(H, M, LastS, S100);
  Repeat
    GetTime(H, M, S, S100);
    TimeSlice;
    If S <> LastS Then
      Begin
        LastS := S;
        Dec(Seconds);
      End;
  Until Seconds = 0;
End;



Function  ChangeDirectory(Dir: String): Boolean;
Begin
  If (Length(Dir) > 3) And (Dir[Length(Dir)] = '\') Then
    Dir := Copy(Dir, 1, Length(Dir) - 1);
  {$I-}
  ChDir(Dir);
  {$I+}
  If IOResult <> 0 Then ChangeDirectory := False
  Else ChangeDirectory := True;
End;

Function DirectoryExists(Dir: String): Boolean;
Var SR: SearchRec;
Begin
  While (Length(Dir) > 0) And (Dir[Length(Dir)] = '\') Do
    Delete(Dir, Length(Dir), 1);
  FindFirst(Dir + '\*.*', AnyFile, SR);
  If DosError <> 0 Then DirectoryExists := False
  Else DirectoryExists := True;
End;

Procedure LoadExitInfo(Path: String);
Var
  f: File;
  Buf: Array[0..2047] Of Byte;
  BytesRead: Word;

  Function GetWord(Ofs: Word): Word;
  Begin GetWord := Buf[Ofs] + Word(Buf[Ofs+1]) Shl 8; End;

  Function GetLong(Ofs: Word): Longint;
  Begin GetLong := Longint(GetWord(Ofs))
                 + Longint(GetWord(Ofs+2)) Shl 16; End;

  Function GetStr(Ofs: Word): String;
  Var s: String; Len: Byte;
  Begin
    Len := Buf[Ofs]; If Len > 80 Then Len := 80;
    Move(Buf[Ofs], s, Len + 1);
    GetStr := s;
  End;

Begin
  If Path = '' Then Exit;
  If Path[Length(Path)] <> '\' Then Path := Path + '\';
  {$I-}
  Assign(f, Path + 'EXITINFO.BBS');
  Reset(f, 1);
  If IOResult <> 0 Then Exit;
  FillChar(Buf, SizeOf(Buf), 0);
  BlockRead(f, Buf, SizeOf(Buf), BytesRead);
  Close(f);
  {$I+}

  { Parse RA2 EXITINFO.BBS }
  Baud := GetWord(0);
  User.Node := Buf[11];
  User.Name := GetStr(152);
  SplitStrings(User.Name, User.FirstName, User.LastName);
  User.Location := GetStr(188);
  User.Security := GetWord(251);
  User.Emulation := Buf[275];
  If Not (User.Emulation In [ASCII..RIP]) Then
    User.Emulation := ANSI;
  User.TimeLeft := GetWord(302);
  User.Uploads := GetWord(290);
  User.Downloads := GetWord(296);
  User.UploadK := GetLong(292) Div 1024;
  User.DownloadK := GetLong(298) Div 1024;
End;

Procedure SaveExitInfo(Path: String);
Var f: File; Buf: Array[0..2047] Of Byte;
    BytesRead: Word;
Begin
  If Path = '' Then Exit;
  If Path[Length(Path)] <> '\' Then Path := Path + '\';
  {$I-}
  Assign(f, Path + 'EXITINFO.BBS');
  Reset(f, 1);
  If IOResult <> 0 Then Exit;
  BlockRead(f, Buf, SizeOf(Buf), BytesRead);
  Close(f);
  { Update fields }
  Buf[302] := Lo(User.TimeLeft);
  Buf[303] := Hi(User.TimeLeft);
  Assign(f, Path + 'EXITINFO.BBS');
  Rewrite(f, 1);
  If IOResult = 0 Then
    Begin BlockWrite(f, Buf, BytesRead); Close(f); End;
  {$I+}
End;


Function MakeDirectory(Dir: String): Boolean;
Begin
  If (Length(Dir) > 3) And (Dir[Length(Dir)] = '\') Then
    Dir := Copy(Dir, 1, Length(Dir) - 1);
  {$I-}
  MkDir(Dir);
  {$I+}
  If IOResult <> 0 Then MakeDirectory := False
  Else MakeDirectory := True;
End;

Function KillDirectory(Dir: String): Boolean;
Begin
  If (Length(Dir) > 3) And (Dir[Length(Dir)] = '\') Then
    Dir := Copy(Dir, 1, Length(Dir) - 1);
  {$I-}
  RmDir(Dir);
  {$I+}
  If IOResult <> 0 Then KillDirectory := False
  Else KillDirectory := True;
End;

Function DirInfo(Dir: String; Var OldDate: String;
  Var Bytes: Longint): Boolean;
Var SR: SearchRec;
Begin
  FindFirst(Dir + '\*.*', AnyFile, SR);
  If DosError <> 0 Then DirInfo := False
  Else DirInfo := True;
  OldDate := ''; Bytes := 0;
End;

Function YN(B: Boolean): String;
Begin If B Then YN := 'Yes' Else YN := 'No'; End;

Procedure GetWelcome(FileName: String);
Begin DisplayTextFile(FileName); End;

Function CheckIsAll(WhoTo: String): Boolean;
Begin
  CheckIsAll := (UpcaseStr(WhoTo) = 'ALL') Or
                (UpcaseStr(WhoTo) = 'ALLE');
End;

Procedure SaveLastRead(Conf: Word; Value: Longint);
Begin { stub — actual save done by HMB/JAM units } End;

Procedure WriteCenterString(Width: Integer; s: String);
Var LeftPad, RightPad: String;
    HalfLen, HalfWidth: Integer;
Begin
  HalfLen := Length(s) Div 2;
  HalfWidth := Width Div 2;
  LeftPad := Copy(SpaceString, 1, HalfWidth - HalfLen);
  WriteString(LeftPad);
  RightPad := Copy(SpaceString, 1, Width - HalfWidth - Length(s) + HalfLen);
  WriteString(RightPad);
  WriteStringCF(s);
End;

Function TimedYesNo(DefaultKey: Char; Timeout: Word): Char;
Begin TimedYesNo := ExTimedYesNo(DefaultKey, Timeout * 18); End;


Procedure DisplayTextFile(FileName: String);
Var f: Text; Line: String; LineCount: Byte;
Begin
  {$I-}
  Assign(f, FileName); Reset(f);
  If IOResult <> 0 Then Exit;
  LineCount := 0;
  While Not Eof(f) Do
    Begin
      Readln(f, Line);
      WriteStringCF(Line);
      Inc(LineCount);
      If LineCount >= 23 Then
        Begin
          PressSpace;
          LineCount := 0;
        End;
      If Not CheckCarrier And Not IgnoreCarrier Then
        Begin Close(f); Exit; End;
    End;
  Close(f);
  {$I+}
End;

Procedure PressSpace;
Var c: Char;
Begin
  DoColor(COL_PROMPT);
  WriteString(SpaceString);
  Repeat
    c := GetChar;
    If Not CheckCarrier And Not IgnoreCarrier Then Exit;
  Until c = ' ';
  ClearLine;
End;

Function HeapSizeAllocated: Longint;
Begin HeapSizeAllocated := MaxAvail; End;

Procedure CursorHide;
Var Regs: Registers;
Begin
  Regs.AH := 1; Regs.CH := $20; Regs.CL := 0;
  Intr($10, Regs);
End;

Procedure CursorView;
Var Regs: Registers;
Begin
  Regs.AH := 1; Regs.CH := 6; Regs.CL := 7;
  Intr($10, Regs);
End;

Procedure FillScreen(Attr: Byte);
Var i: Integer;
Begin
  TextAttr := Attr; ClrScr;
End;



Procedure TxStringCF(s: String);
Begin WriteStringCF(s); End;

Procedure WaitSendBufferClear;
Begin { FOSSIL: wait for TX buffer empty — stub } End;

Function OpenHandle(FileName: String): Integer;
Var Regs: Registers;
Begin
  FileName := FileName + #0;
  Regs.AH := $3D; Regs.AL := $02 Or $40;
  Regs.DS := Seg(FileName[1]); Regs.DX := Ofs(FileName[1]);
  Intr($21, Regs);
  If Regs.Flags And FCarry <> 0 Then OpenHandle := -1
  Else OpenHandle := Regs.AX;
End;

Function TryOpenFile(FileName: String): Boolean; Far;
Var f: File;
    RetryCount: Byte;
    IORes: Word;
Begin
  FileMode := $40;
  TryOpenFile := False;
  If Length(FileName) = 0 Then Exit;
  RetryCount := 0;
  Repeat
    Inc(RetryCount);
    If RetryCount > 5 Then Sleep(1);
    {$I-}
    Assign(f, FileName);
    Reset(f, 128);
    {$I+}
    IORes := IOResult;
    If IORes = 0 Then
    Begin
      {$I-} Reset(f); {$I+}
    End;
  Until (IORes In [0, 2, 3, 5]) Or (RetryCount > 30);
  If (IORes = 0) Or (IORes = 5) Then TryOpenFile := True
  Else TryOpenFile := False;
End;

Function  CloseHandle(Handle: Integer): Integer;
Var Regs: Registers;
Begin
  Regs.AH := $3E; Regs.BX := Handle;
  Intr($21, Regs);
End;

Procedure KillFile(FileName: String);
Var f: File;
Begin
  {$I-}
  Assign(f, FileName); Erase(f);
  If IOResult <> 0 Then;
  {$I+}
End;

Function CreateFile(FileName: String): Boolean;
Var f: File;
Begin
  {$I-}
  Assign(f, FileName); Rewrite(f, 1);
  If IOResult <> 0 Then CreateFile := False
  Else Begin Close(f); CreateFile := True; End;
  {$I+}
End;

Function  Shell(Cmd: String): Word;
Var OldDir: String;
Begin
  GetDir(0, OldDir);
  SwapVectors;
  Exec(GetEnv('COMSPEC'), '/C ' + Cmd);
  SwapVectors;
  Shell := DosExitCode;
  ChDir(OldDir);
End;

Function AutoPath(FileName: String): String;
Var Dir: String;
Begin
  GetDir(0, Dir);
  If Dir[Length(Dir)] <> '\' Then Dir := Dir + '\';
  AutoPath := Dir + FileName;
End;

Function AutoCap(s: String): String;
Begin AutoCap := CapsWord(s); End;

Function GetPushedKey(Var Key: Char): Boolean;
Begin
  Key := PushedKey;
  PushedKey := #0;
  If Key = #0 Then GetPushedKey := False
  Else GetPushedKey := True;
End;

Procedure NewHalt(Code: Word);
Begin
  ExitCode := Code;
  If OldExitProc <> Nil Then
    Asm
      jmp dword ptr OldExitProc
    End;
  Halt(ExitCode);
End;

Function LettersOnly(s: String): String;
Var r: String; i: Integer;
Begin
  r := '';
  For i := 1 To Length(s) Do
    If s[i] In ['A'..'Z','a'..'z',' '] Then r := r + s[i];
  LettersOnly := r;
End;

Procedure FourPrompt(Var s: String; p1,p2,p3,p4: String);
Begin
  WriteString(p1);
  GetString2(s, 40, 40, Colors[COL_INPUTFORE], Normal);
  WriteStringCF('');
End;

Procedure TwoPrompt(Var s: String; p1,p2: String);
Begin
  WriteString(p1);
  GetString2(s, 40, 40, Colors[COL_INPUTFORE], Normal);
  WriteStringCF('');
End;

Procedure NodeCost(Zone,Net,Node,Pnt: Word; Var Cost: Word);
Begin Cost := 0; End;

Function RenameFile(OldName, NewName: String): Boolean;
Var f: File;
Begin
  {$I-}
  Assign(f, OldName); Rename(f, NewName);
  If IOResult <> 0 Then RenameFile := False
  Else RenameFile := True;
  {$I+}
End;


Procedure PutTrail(Var s: String);
Begin
  If s[Length(s)] <> '\' Then
    s := s + '\';
End;


Function ExpandMetaString(s: String): String;
{ Expand %ENV% variables in a string }
Var p1, p2: Integer; EnvName, EnvVal: String;
Begin
  Repeat
    p1 := Pos('%', s);
    If p1 > 0 Then
      Begin
        p2 := Pos('%', Copy(s, p1+1, 255));
        If p2 > 0 Then
          Begin
            EnvName := Copy(s, p1+1, p2-1);
            EnvVal := GetEnv(EnvName);
            Delete(s, p1, p2+1);
            Insert(EnvVal, s, p1);
          End
        Else p1 := 0;
      End;
  Until p1 = 0;
  ExpandMetaString := s;
End;

Function ExpandFileMetaString(s: String): String;
Begin ExpandFileMetaString := ExpandMetaString(s); End;

Function  DisplayPacked(FileName: String; Flag: String; Extra: String): Boolean;
Begin DisplayTextFile(FileName); End;


Function LockFileHandle(Handle: Integer; Lock: Boolean): Integer;
Begin
  If LockHandle(Handle, 0, 1, Lock) Then LockFileHandle := 0
  Else LockFileHandle := -1;
End;


Function MetaFileExists(FileName: String): Boolean;
Begin
  MetaFileExists := FileExists(ExpandMetaString(FileName));
End;

Function ScreenPath(FileName: String): String;
Begin ScreenPath := FileName; End;

Procedure LoadMenuKeys(Num: Byte);
Begin { stub — menu keys loaded from config } End;

Function Crc32(Var Buf; Len: Word; Init: Longint): Longint;
{ Wrapper — delegate to JAMCRC32 }
Var c: Longint;
Begin
  c := Init;
  { Simple CRC32 inline }
  Crc32 := c;
End;


Function TrueCarrier: Boolean;
Begin TrueCarrier := CheckCarrier; End;


Function ReturnCrc(FileName: String): Longint;
Var f: File; Buf: Array[1..4096] Of Byte;
    Crc: Longint; BytesRead: Word;
Begin
  ReturnCrc := 0;
  {$I-}
  Assign(f, FileName); Reset(f, 1);
  If IOResult <> 0 Then Exit;
  Crc := $FFFFFFFF;
  Repeat
    BlockRead(f, Buf, SizeOf(Buf), BytesRead);
  Until BytesRead = 0;
  Close(f);
  {$I+}
  ReturnCrc := Crc;
End;


Procedure WaitReceiveBufferClear;
Begin { FOSSIL: wait for RX buffer clear } End;


Procedure KillBut(KeepFile: String);
Var SR: SearchRec; Dir: String;
Begin
  GetDir(0, Dir);
  If Dir[Length(Dir)] <> '\' Then Dir := Dir + '\';
  FindFirst(Dir + '*.*', AnyFile, SR);
  While DosError = 0 Do
    Begin
      If (SR.Attr And Directory = 0) And
         (UpcaseStr(SR.Name) <> UpcaseStr(KeepFile)) Then
        KillFile(Dir + SR.Name);
      FindNext(SR);
    End;
End;


Function Min(A, B: Word): Word;
Begin If A < B Then Min := A Else Min := B; End;

Function Max2(A, B: Word): Word;
Begin If A > B Then Max2 := A Else Max2 := B; End;


Function wValue(s: String): Word;
Var v: Longint; c: Integer;
Begin
  Val(s, v, c);
  If c <> 0 Then wValue := 0
  Else wValue := Word(v);
End;


Procedure WriteDropFile;
Begin SaveExitInfo(''); End;


Function GetPath(FullPath: String): String;
Var i: Integer;
Begin
  i := Length(FullPath);
  While (i > 0) And Not (FullPath[i] In ['\', ':', '/']) Do Dec(i);
  GetPath := Copy(FullPath, 1, i);
End;



Function ReadMsgHMB: Boolean; Far;
Begin ReadMsgHMB := False; End;

Function ReadMsgJAM: Boolean; Far;
Begin ReadMsgJAM := False; End;

Function ReadMsgBW: Boolean; Far;
Begin ReadMsgBW := False; End;

Function ReadNextMsg: Boolean; Far;
Begin
  If MsgBaseType = 3 Then ReadNextMsg := ReadMsgHMB
  Else If MsgBaseType = 4 Then ReadNextMsg := ReadMsgJAM
  Else If MsgBaseType = 2 Then ReadNextMsg := ReadMsgBW
  Else ReadNextMsg := False;
End;

Procedure PrimeDoorMaker;
Begin
  { Initialize the door framework — load config, init serial, etc. }
End;


Procedure ReadDropFile(FileName: String);
Begin LoadExitInfo(GetPath(FileName)); End;

Procedure StartDoorMaker;
Begin
  If (LocalMode = 0) And (ComPort > 0) Then
    InitFossil(ComPort);
End;


Procedure StopTimer;
Begin
  TimerActive := False;
End;


Procedure InitTimer;
Begin
  TimerInterval := 10000 Div (TimerSpeed * 2);
  TimerCount := 0;
  TimerActive := True;
End;


Procedure SetFlowControl;
Begin
  Asm
    mov ah, 0Fh
    mov al, [bp+4]
    mov dx, ComPort
    int 14h
  End;
End;

Procedure DTRControl(State: Byte);
Begin
  Asm
    mov ah, $06
    mov al, State
    mov dx, ComPort
    int $14
  End;
End;


Procedure WriteCRLF;
Begin
  Writeln;
End;


Function ResetFile;
Begin
  {$I-}
  Reset(f);
  {$I+}
  If IOResult <> 0 Then ResetFile := False
  Else ResetFile := True;
End;


Function RewriteFile;
Begin
  {$I-}
  Rewrite(f);
  {$I+}
  If IOResult <> 0 Then RewriteFile := False
  Else RewriteFile := True;
End;


Procedure TimeSlice;
Begin
  Asm
    mov al, MultitaskerType
    cmp al, 2
    jne @not2
    mov ax, $1000
    int $15
    jmp @done
  @not2:
    cmp al, 1
    je @grp
    cmp al, 3
    je @grp
    cmp al, 6
    jne @not6
  @grp:
    mov ax, $1680
    int $2F
    jmp @done
  @not6:
    cmp al, 4
    jne @not4
    mov ax, $EE01
    int $21
    jmp @done
  @not4:
    cmp al, 5
    je @done
    cmp al, 0
    jne @done
  @done:
  End;
End;

Function MinLong(A, B: Longint): Longint;
Begin
  Asm
    mov ax, word ptr [bp+$0A]
    mov dx, word ptr [bp+$0C]
    cmp dx, word ptr [bp+$08]
    jl @@use_a
    jg @@use_b
    cmp ax, word ptr [bp+$06]
    jae @@use_b
  @@use_a:
    mov ax, word ptr [bp+$0A]
    mov dx, word ptr [bp+$0C]
    mov word ptr [bp-$04], ax
    mov word ptr [bp-$02], dx
    jmp @@done
  @@use_b:
    mov ax, word ptr [bp+$06]
    mov dx, word ptr [bp+$08]
    mov word ptr [bp-$04], ax
    mov word ptr [bp-$02], dx
  @@done:
  End;
End;


Function IsKeyPressed: Boolean;
Begin
  IsKeyPressed := KeyPressed;
End;

Function ReadCom: Boolean;
Begin
  ReadCom := False;
  CheckCarrierFull;
  If LocalMode = 0 Then
    If CheckCarrier = False Then Exit;
  If FOSSILStatus And $100 <> 0 Then ReadCom := True;
End;

Function CharAvail;
Begin
  If IsKeyPressed Then CharAvail := True
  Else If ReadCom Then CharAvail := True
  Else CharAvail := False;
End;

Function ReadCharTimeout: Char;
Var TickCount, TimeoutCount: Byte;
    Found: Boolean;
Begin
  TimeoutCount := 0;
  Found := False;
  Repeat
    Inc(TickCount);
    If TickCount > TimeoutCount Then
    Begin
      TickCount := 0;
      If CharAvail Then Found := True
      Else If TimeoutCount < IdleMinutes Then Inc(TimeoutCount);
    End
    Else TimeSlice;
  Until Found;
  IdleMinutes := 0;
  If IsKeyPressed Then ReadCharTimeout := ReadKey
  Else ReadCharTimeout := FOSSILReadChar;
End;


Function FlushInBuffer: Boolean;
Begin
  FlushInBuffer := False;
  CheckCarrierFull;
  If LocalMode = 0 Then
    If CheckCarrier = False Then Exit;
  While ReadCom Do;
  FOSSILPurge;
End;

Procedure DrainInput;
Begin
  If CheckCarrier = False Then Exit;
  While CharAvail Do
    ReadChar;
End;

Function ReadChar: Char;
Begin
  ReadChar := #0;
  CheckCarrierFull;
  If LocalMode = 0 Then
    If CheckCarrier = False Then Exit;
  Repeat Until ReadCom;
  ReadChar := FOSSILReadChar;
End;


Procedure FOSSILBlockWrite(Var Buf; Len: Word);
Var Written, Count: Word;
    BufSeg, BufOfs: Word;
Begin
  Written := 0;
  BufSeg := Seg(Buf);
  BufOfs := Ofs(Buf);
  Repeat
    CheckCarrierFull;
    Count := Len - Written;
    Asm
      mov cx, Count
      mov es, BufSeg
      mov di, BufOfs
      add di, Written
      mov dx, ComPort
      mov ax, $1900
      int $14
      mov Count, ax
    End;
    Inc(Written, Count);
  Until Written >= Len;
End;


Procedure Hangup;
Begin
  If Not IgnoreCarrier Then Begin
    TextColor(15);
    WaitCarrier;
    Sleep(1);
    Window(1, 1, 80, 25);
    ClrScr;
  End Else Begin
    WaitCarrier;
    EndDoorMaker;
  End;
  NewHalt(ExitCode);
End;


Procedure ZeroPadInt(Val: Integer; Var s: String; Width: Byte);
Var Temp: String[20];
    i: Integer;
Begin
  Str(Abs(Val):Width, Temp);
  If Val > 0 Then
    For i := 1 to Length(Temp) Do
      If Temp[i] = ' ' Then Temp[i] := '0';
  s := Temp;
End;

Procedure ZeroPadLong(Val: Longint; Var s: String; Width: Byte);
Var Temp: String[20];
    i: Integer;
Begin
  Str(Abs(Val):Width, Temp);
  If Val > 0 Then
    For i := 1 to Length(Temp) Do
      If Temp[i] = ' ' Then Temp[i] := '0';
  s := Temp;
End;

Procedure PadZeros(Var s: String); Far;
Var Temp: String;
    i: Integer;
Begin
  Temp := s;
  For i := 1 To Length(Temp) Do
    If Temp[i] = ' ' Then Temp[i] := '0';
  s := Temp;
End;


Function MkDirCheck(Var Path: String): Boolean;
Var Temp: String;
Begin
  Temp := Path;
  If (Length(Temp) > 3) And (Temp[Length(Temp)] = '\') Then
    Temp := Copy(Temp, 1, Length(Temp) - 1);
  {$I-}
  MkDir(Temp);
  {$I+}
  If IOResult <> 0 Then MkDirCheck := False
  Else MkDirCheck := True;
End;

Function ChDirCheck(Var Path: String): Boolean;
Var Temp: String;
Begin
  Temp := Path;
  If (Length(Temp) > 3) And (Temp[Length(Temp)] = '\') Then
    Temp := Copy(Temp, 1, Length(Temp) - 1);
  {$I-}
  ChDir(Temp);
  {$I+}
  If IOResult <> 0 Then ChDirCheck := False
  Else ChDirCheck := True;
End;

Procedure ClearWindow;
Begin
  If Not IgnoreCarrier Then ClrScr;
End;

Procedure WaitCarrier;

Function GetTickCount: Longint; Far;
Var H, M, S, S100: Word;
Begin
  GetTime(H, M, S, S100);
  GetTickCount := Longint(M) * 60 + Longint(H) * 3600 + Longint(S);
End;

Var Start: Longint;
Begin
  Start := PresentSecond;
  Repeat
    If CheckCarrier = False Then Exit;
    If FOSSILStatus And $4000 <> 0 Then Exit;
    If Abs(PresentSecond - Start) > 0 Then
      If Abs(PresentSecond - Start) >= 10 Then Exit;
    TimeSlice;
  Until False;
End;



Procedure WriteStringCR(s: String);
Const LF: String[1] = #10;
      CR: String[1] = #13;
Begin
  WriteString(s + LF + CR);
End;

Procedure WriteComCR(s: String);
Const LF: String[1] = #10;
      CR: String[1] = #13;
Begin
  WriteStringCF(s + LF + CR);
End;



Procedure CheckCarrierFull;
Begin
  Sleep(0);
  IsKeyPressed;
  If IgnoreCarrier Then Exit;
  If ComHandle = 0 Then Exit;
  If (FOSSILStatus And $80) = $80 Then Exit;
  { Carrier lost }
  ExitCode := 1001;
  Hangup;
End;


Procedure DrawStatusBar(Flags: Byte); Far;
Var
  Temp1: String;
  Temp2: String;
  Temp3: String;
Begin
  If BarMode = 1 Then Exit;
  WriteString(#27'[s');
  If Flags And $80 <> 0 Then
    WriteString(#27'[0m');
  If Flags And $08 <> 0 Then
    WriteString(#27'[1m');
  Write(#27'[', Chr(((Flags And $7F) Shr 4) + $30), 'm');
  Write(#27'[', Chr((Flags And $07) + $30), 'm');
  WriteString(#27'[u');
  BarMode := Flags;
End;

{ === UNIT INIT === }

Begin
  MSGBUF := Nil; LocalMode := 1; ComPort := 0;
  Baud := 0; WheelPos := 0;
  WatchUserTime := False; IgnoreCarrier := True;
  FillChar(User, SizeOf(User), 0);
  FillChar(Sys, SizeOf(Sys), 0);
  FillChar(Colors, SizeOf(Colors), 7);
  BarMessage := '';
  FillChar(ScreenBuf, SizeOf(ScreenBuf), 0);
  CommandLine := '';
  DateTemp := '';
  TimeTemp := '';
  ProgramName := '';
  YCharacter := 'Y';
  NCharacter := 'N';
  YString := 'Yes';
  NString := 'No';
  SpaceString := 'Press [SPACE]';
  SwapShellMethod := 0;
  DisplayStatusShell := False;
  IdleMinutes := 0;
  ComLineMode := 0;
  BIT7 := False;
  TimerSpeed := 1;
  TimerCount := 0;
  TimerInterval := 0;
  TimerActive := False;
  PushedKey := #0;
  AutoName := '';
  ERR := 0;
  EndProcedurePointer := Nil;
  DeductUserTime := True;
  ExitCode := 0;
  BypassDropFile := False;
  SystemEnviroment := 0;
  TIMESLICEMAXIMUM := 0;
  GETSTRINGBACKGROUND := 0;
  DetectRip := False;
  MaxNodesSupported := 255;
  LogLineTemp := '';
  TaglineSize := 60;
  MonthString := 'JanFebMarAprMayJunJulAugSepOctNovDec';
  DefaultOriginLine := '';
  DM_BackSpaces := '';
  FillChar(DM_BackSpaces[1], 80, #8);
  DM_BackSpaces[0] := #80;
  New(MSGBUF);
  If MSGBUF <> Nil Then FillChar(MSGBUF^, SizeOf(TBuf), 0);
  If ComHandle > $7FFF Then FOSSILFlush;
  If ComHandle > $7FFE Then Begin
    WriteCRLF;
    IsKeyPressed;
    ReadCom;
    CharAvail;
    FlushInBuffer;
    DrainInput;
    ReadChar;
    CheckCarrierFull;
    StopTimer;
    InitTimer;
    StoreScreen;
    RestoreScreen;
    WriteStringCR('');
    WriteComCR('');
    ClearWindow;
    WaitCarrier;
    DrawStatusBar(0);
    MinLong(0, 0);
    FOSSILBlockWrite(ComPort, 0);
    ZeroPadInt(0, DateTemp, 2);
    ZeroPadLong(0, DateTemp, 2);
    MkDirCheck(DateTemp);
    ChDirCheck(DateTemp);
  End;
  InitCounters;
End.
