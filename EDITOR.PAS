Program Editor;

{$I d:\develop\olms\BBSTYPE.INC}

{$IFDEF PROVERSION}
Uses Lib, U_NEW, Dos, Crt, JamCrc32, Shelling;

{$S+,V-}
{$M 25000,90500,90500}

Const
  MaxAreas    = 10000;
  BufferSize  = 300;
  AreaRange   = 2000;

Type
  pStr40 = ^tStr40;
  tStr40 = String[25];

  pAreaNumbers = ^tAreaNumbers;
  tAreaNumbers = Array[1..AreaRange] Of Word;

  pAreaNames = ^tAreaNames;
  tAreaNames = Array[1..AreaRange] Of pStr40;

  pSETUPrecord = ^SETUPrecord;

  ListStruct = Record
                 Name: String[35];
                 Del, Vac: Boolean;
                 Last: Date;
                 Down: Word;
               End;

Var
  BufferUse: Word;
  AreaNames: pAreaNames;
  AreaNumbers: pAreaNumbers;
  RA250: Boolean;
  Setup: pSETUPrecord;
  IndexLow, IndexHigh, SIZE_USERS, ZMaxAreas: Word;
  IndexCount: Word;
  Users: Array[1..BufferSize] Of ListStruct;
  SearchName: String[40];
  MainDir: String[128];
  Saved: Pointer;

Procedure ClearHalt;
Begin
  TextAttr := 7;
  Window(1,1,80,25);
  Clrscr;
  CursorView;
  Halt;
End;

Procedure Note1(st: String);
Begin
  StoreScreen(4);
  DrawWindow(10,12,70,14,White+Red*16,BORDER_THICK);
  Write(Center(' '+st,56));
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

Procedure FillScreen(c1: Byte; c2: Char);
Var
   A: Integer;
   Regs: Registers;
Begin
   Regs.Ah := $0F;
   Intr($10,Regs);
   If (Regs.Al In [0..3]) Then VideoAddress := $B800
   Else VideoAddress := $B000;
   For A := 0 To 1999 Do
     Begin
       Byte(Ptr(VideoAddress,A*2+1)^) := c1;
       Char(Ptr(VideoAddress,A*2  )^) := c2;
     End;
End;

Procedure UserSizeSetup;
Var
  fUSRDAT: File;
  UserAreas: Word;
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
End;

Procedure Wait;
Var
  c: Byte;
  s: String[5];
Begin
  s := ' Wait';
  For c := 1 To 5 Do
    Begin
      Byte(Ptr(VideoAddress,(1830+c)*2+1)^) := 12;
      Char(Ptr(VideoAddress,(1830+c)*2  )^) := s[c];
    End;
End;

Procedure NoWait;
Var
  c: Byte;
  s: String[5];
Begin
  s := 'Ready';
  For c := 1 To 5 Do
    Begin
      Byte(Ptr(VideoAddress,(1830+c)*2+1)^) := 10;
      Char(Ptr(VideoAddress,(1830+c)*2  )^) := s[c];
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
      If      Is(Setup^.SysopFlags[Conf],sFORCED) Then Flag := 'aw..F'
      Else If Is(Setup^.SysopFlags[Conf],sBLOCKED)  Then Flag[5] := 'B'
      Else Flag := '....H';
    End;
  ReturnFlags := Flag;
End;

Procedure SelectFlags(Var U: USERrecord);
Var
  L, C, O, OO: Word;
  Key: Char;
  b: Byte;
Begin
  StoreScreen(5);
  DrawWindow(6,6,22,16,Lightblue+Blue*16,BORDER_THICK);
  SetColor(White+Blue*16);
  Window(8,7,21,16);
  Write  (' (.) Normal   ');
  Write  (' (G) General  ');
  Write  (' (P) Personal ');
  Write  (' (A) All      ');
  Write  (' (K) Keyword  ');
  Write  (' (F) Filter   ');
  Write  (' (W) FromSelf ');
  Write  (' (N) Network  ');
  Write  (' (C) Connect  ');
  DrawWindow(24,6,74,20,7,BORDER_THICK);

  O := 0;
  L := 0;
  Repeat
    OO := O;
    Gotoxy(1,1);
    For C := 1 To 13 Do
      Begin
         Gotoxy(2,C);
         If C=L+1 Then TextAttr := 31 Else TextAttr := 15;
         Write(' ',PadStr(AreaNames^[C+O]^,38));
         Write(' '+ReturnFlags(U.Flags[AreaNumbers^[C+O]],AreaNumbers^[C+O])+' ');
      End;
    Repeat
      Key := Upcase(Readkey);
      TextAttr := 15;
      Gotoxy(2,L+1);
      Write(' ',PadStr(AreaNames^[L+1+O]^,38));
      Write(' '+ReturnFlags(U.Flags[AreaNumbers^[L+1+O]],AreaNumbers^[L+1+O])+' ');
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
          b := U.Flags[AreaNumbers^[O+L+1]];
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
          U.Flags[AreaNumbers^[O+L+1]] := b;
        End;
      TextAttr := 31;
      Gotoxy(2,L+1);
      Write(' ',PadStr(AreaNames^[L+1+O]^,38));
      Write(' '+ReturnFlags(U.Flags[AreaNumbers^[L+1+O]],AreaNumbers^[L+1+O])+' ');
    Until (Key In [#27,'.','W','N','C','A','G','P','K','F']) Or (O<>OO);
  Until Key = #27;
  Key := #0;
  RestoreScreen(5);
  SetColor(White);
End;

Function EditUser(lRec: Longint): Boolean;
Var
  c: Word;
  i: Integer;
  l: Longint;
  Key2, Key: Char;
  U: USERrecord;
  fU: File;
  ARC: Array['A'..'Z'] Of String[4];
  YN: Array[False..True] Of String[4];
  UCRC: Longint;
  Temp, ProtString, ArcString: String[10];
Begin
  EditUser := False;
  If lRec=-1 Then Exit;

  ArcString  := 'ALZCPR';
  ProtString := '';
  For c := 1 To 6 Do ProtString := ProtString + Setup^.TransmitKeys[c];
  ARC['A'] := 'Arj';
  ARC['L'] := 'Lzh';
  ARC['Z'] := 'Zip';
  ARC['R'] := 'Rar';
  ARC['C'] := 'Arc';
  ARC['P'] := 'Pak';
  YN[False] := 'No ';
  YN[True]  := 'Yes';

  StoreScreen(1);
  DrawWindow(2,2,78,24,15,BORDER_THICK);
  Writeln(' User editor');
  TextAttr := 7;  Writeln(' ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
  Gotoxy(1,20);   Writeln(' ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
  TextAttr := 7;
  Window(6,6,74,21);
  Writeln('User name:');
  Writeln('Last date:');
  Writeln('Last time:');
  Writeln('@) Format:');
  Writeln('#)    LID:');
  Writeln('Q)  QWKID:');
  Writeln;
  Writeln('A) Archiver:');
  Writeln('P) Protocol:');
  Writeln;
  Writeln('D)      Downloads:');
  Writeln('R)  File requests:');
  Writeln('X)     Max/packet:');
  Writeln('M) Max/conference:');
  Writeln('E)    Current ext:');
  Window(52,6,73,21);
  Writeln('U)  Use number ext:');
  Writeln('I)         Indexes:');
  Writeln('F)           Files:');
  Writeln('W) Welcome Screens:');
  Writeln('N)            News:');
  Writeln('G) Global keywords:');
  Writeln('O) Global personal:');
  Writeln('Z) Filter personal:');
  Writeln('T)   Twit personal:');
  Writeln('S) Short conf list:');
  Writeln('H)      High Ascii:');
  Writeln('^)      ^A kludges:');
  Writeln('L)   Ignore limits:');
  Writeln('V)   Vacation Mode:');
  Writeln('!)    User Deleted:');

  Repeat
    If Not OpenFile(fU,MainDir+'USERS.DAT','R',SIZE_USERS,faReadOnly+faDenyNone) Then
      Begin
        Note('Cannot open USERS.DAT file');
        Exit;
      End;
    Seek(fU,lRec);
    {$I-}
    BlockRead(fU,U,1);
    If IoResult<>0 Then
      Begin
        CloseFile(fU);
        Note('Corrupt USERS.DAT file, run MAINTAIN.EXE');
        ClearHalt;
      End;
    {$I+}
    CloseFile(fU);
    UCRC := crc32(U,Sizeof(U),$FFFFFFFF);
    Window(4,23,78,23);
    TextAttr := 15;
    Write(' User '+PadStr(NumStr(lRec+1,0)+' of '+NumStr(IndexHigh,0),28)+'                          (C)onferences');
    Temp := '';
    Key := 'P';
    With U Do
      Begin
      Repeat
        TextAttr := 15;
        Window(17,6,74,22);
        Writeln(PadStr(Name,35));
        Writeln(PadStr(LastDateDownload,10));
        Writeln(PadStr(LastTimeDownload,10));
        Writeln(PadStr(PacketFormatString[PacketType],20));
        Writeln(PadStr(LocalName,10));
        Writeln(PadStr(NumStr(QWKID,0),10));
        Window(19,13,74,21);
        c := Pos(Protocol,ProtString);
        If c = 0 Then Temp := 'Unknown' Else Temp := Setup^.TransmitNames[c];
        Writeln(ARC[Archiver]);
        Writeln(PadStr(Temp,20));
        Window(25,16,74,21);
        Writeln(TotalDownloads:5);
        Writeln(TotalFilesDownloaded:5);
        Writeln(MaxPacket:5);
        Writeln(MaxConference:5);
        Writeln(CurrentExtension MOD 100:5);
        Window(72,6,76,22);
        Writeln(YN[NumericExtension]);
        Writeln(YN[Indexes]);
        Writeln(YN[Files]);
        Writeln(YN[GetWelcome]);
        Writeln(YN[News]);
        Writeln(YN[GlobalKeywords]);
        Writeln(YN[GlobalPersonal]);
        Writeln(YN[FilterPersonal]);
        Writeln(YN[TwitPersonal]);
        Writeln(YN[ShortList]);
        Writeln(YN[UseHigh]);
        Writeln(YN[KeepKludge]);
        Writeln(YN[IgnoreLimits]);
        Writeln(YN[VacationMode]);
        Writeln(YN[Del]);
        Repeat
          Key := Upcase(Readkey);
          If Key = #0 Then
            Begin
              Key := Upcase(Readkey);
              Case Key Of
                'G': Key := #252;
                'O': Key := #251;
                'K': Key := #254;
                'M': Key := #253;
                'H': Key := #254;
                'P': Key := #253;
                'I': Key := #254;
                'Q': Key := #253;
                Else Key := #0;
              End;
            End;
          If (Key In [#27,#251..#254]) Then
            Begin
              If UCRC <> crc32(U,Sizeof(U),$FFFFFFFF) Then
                Begin
                  StoreScreen(5);
                  DrawWindow(22,11,58,15,Black+Lightgray*16,BORDER_THICK);
                  Writeln;
                  Write(Center(' Save changes? (Y/n)',34));
                  Repeat
                    Key2 := Upcase(Readkey);
                    If Key2=#13 Then Key2 := 'Y';
                  Until Key2 In [#27,'Y','N'];
                  If Key2 = 'Y' Then
                    Begin
                      If Not OpenFile(fU,MainDir+'USERS.DAT','R',SIZE_USERS,faReadWrite+faDenyNone) Then
                        Begin
                          Note('Cannot open USERS.DAT file');
                          Exit;
                        End;
                      EditUser := True;
                      UCRC := crc32(U,Sizeof(U),$FFFFFFFF);
                      Seek(fU,lRec);
                      BlockWrite(fU,U,1);
                      CloseFile(fU);
                      Users[lRec-IndexLow+1].Del := Del;
                      Users[lRec-IndexLow+1].Vac := VacationMode;
                    End
                  Else If Key2 = #27 Then Key := #0;
                  RestoreScreen(5);
                End;
            End;
        Until Key In [#27,'A'..'Z','^','@','!','#',#251..#254];
        If Key In ['D','R','M','X','E'] Then Window(25,13,74,21); {DO!}
        Case Key Of
         #252: lRec := 0;
         #251: lRec := IndexHigh-1;
         #254: If lRec>0 Then Dec(lRec);
         #253: If lRec<IndexHigh-1 Then Inc(lRec);
          'C': Begin
                 SelectFlags(U);
               End;
          '#': Begin
                 Window(17,10,74,21);
                 Input(LocalName,8,8,White,White,INPUT_UPPER);
               End;
          'Q': Begin
                 Repeat
                   Window(17,11,74,21);
                   Str(QWKID,Temp);
                   Input(Temp,5,5,White,White,INPUT_NUMBER);
                   Val(Temp,l,i);
                 Until (i = 0) And (l<=65000);
                 QWKID := l;
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
          'P': Begin
                 c := Pos(Protocol,ProtString);
                 Repeat
                   Inc(c);
                 Until (c>6) Or (ProtString[c]<>' ');
                 If c>6 Then c := 1;
                 Protocol := ProtString[c];
               End;
          'D': Begin
                 Repeat
                   Gotoxy(1,4);
                   Str(TotalDownloads,Temp);
                   Input(Temp,5,5,White,White,INPUT_NUMBER);
                   Val(Temp,l,i);
                 Until (i = 0) And (l<=65000);
                 TotalDownloads := l;
               End;
          'R': Begin
                 Repeat
                   Gotoxy(1,5);
                   Str(TotalFilesDownloaded,Temp);
                   Input(Temp,5,5,White,White,INPUT_NUMBER);
                   Val(Temp,l,i);
                 Until (i = 0) And (l<=65000);
                 TotalFilesDownloaded := l;
               End;
          'X': Begin
                 Repeat
                   Gotoxy(1,6);
                   Str(MaxPacket,Temp);
                   Input(Temp,5,5,White,White,INPUT_NUMBER);
                   Val(Temp,l,i);
                 Until (i = 0) And (l<=65000);
                 MaxPacket := l;
               End;
          'M': Begin
                 Repeat
                   Gotoxy(1,7);
                   Str(MaxConference,Temp);
                   Input(Temp,5,5,White,White,INPUT_NUMBER);
                   Val(Temp,l,i);
                 Until (i = 0) And (l<=65000);
                 MaxConference := l;
               End;
          'E': Begin
                 Repeat
                   Gotoxy(1,8); Write('   ');
                   Str(CurrentExtension MOD 100,Temp);
                   Input(Temp,2,2,White,White,INPUT_NUMBER);
                   Val(Temp,l,i);
                 Until (i = 0);
                 CurrentExtension := l;
               End;
          'U': NumericExtension := Not NumericExtension;
          'I': Indexes := Not Indexes;
          'F': Files := Not Files;
          'W': GetWelcome := Not GetWelcome;
          'N': News := Not News;
          'G': GlobalKeywords := Not GlobalKeywords;
          'O': GlobalPersonal := Not GlobalPersonal;
          'Z': FilterPersonal := Not FilterPersonal;
          'T': TwitPersonal := Not TwitPersonal;
          'S': ShortList := Not ShortList;
          'H': UseHigh := Not UseHigh;
          '^': KeepKludge := Not KeepKludge;
          'L': IgnoreLimits := Not IgnoreLimits;
          'V': VacationMode := Not VacationMode;
          '!': Del := Not Del;
        End;
      Until Key In [#27,#251..#254];
      End;
  Until Key = #27;
  RestoreScreen(1);
End;

Function ReadUsers(Start: Longint): Integer;
Var
  f: File;
  Result: Integer;
  UserTemp: USERrecord;
Begin
  If Not OpenFile(f,MainDir+'USERS.DAT','R',SIZE_USERS,faReadWrite+faDenyNone) Then
    Begin
      Note('Cannot open USERS.DAT file');
      ClearHalt;
    End;
  Seek(f,Start);
  Result := 0;
  Wait;
  While Not Eof(f) And (Result<BufferUse) Do
    Begin
      BlockRead(f,UserTemp,1);
      Inc(Result);
      With Users[Result] Do
        Begin
          Name := UserTemp.Name;
          Del  := UserTemp.Del;
          Vac  := UserTemp.VacationMode;
          Last := UserTemp.LastDateDownload;
          Down := UserTemp.TotalDownloads;
          If Last = 'None' Then Last := '';
        End;
    End;
  CloseFile(f);
  NoWait;
  ReadUsers := Result;
End;

Function Marker(b: Boolean): String;
Begin
  If b Then Marker := 'ş' Else Marker := ' ';
End;

Procedure WriteIt(Number: Word);
Var
  w: Word;
Begin
  w := Number-1;
  If (w<IndexLow) Or (w>=IndexLow+IndexCount) Then
    Begin
      If w>10 Then Dec(w,10) Else w := 0;
      IndexLow   := w;
      IndexCount := ReadUsers(w);
    End;
  w := Number-Indexlow;
  Write(Number:5,'   ',PadStr(Users[w].Name,35),'   ',PadStr(Users[w].Last,8),
        ' ',Users[w].Down:5,'    ',Marker(Users[w].Vac),'    ',Marker(Users[w].Del)+'  ');
End;

Function FindUser(n: Word; ss: String): Longint;
Var
  s: String[40];
  f: File;
  UserTemp: USERrecord;
  b, Found: Boolean;
Begin
  FindUser := -1;

  StoreScreen(1);
  If ss='' Then
    Begin
      DrawWindow(15,11,66,13,25,BORDER_THICK);
      TextAttr := 31;
      Write(' Search for: ');
      s := SearchName;
      b := Input(s,35,35,White,White,INPUT_NORMAL);
      RestoreScreen(1);
      If Not b Or (s='') Then Exit;
      SearchName := s;
    End
  Else s := ss;

  Wait;

  If Not OpenFile(f,MainDir+'USERS.DAT','R',SIZE_USERS,faReadWrite+faDenyNone) Then
    Begin
      Note('Cannot open USERS.DAT file');
      ClearHalt;
    End;

  If n>=IndexHigh Then n := IndexHigh-1;
  s := UpcaseStr(s);
  Found := False;

  While Not Eof(f) And Not Found Do
    Begin
      If (n-1<IndexLow) Or (n-1>=IndexLow+IndexCount) Then
        Begin
          {$I-}
          Seek(f,n-1);
          BlockRead(f,UserTemp,1);
          If (Pos(s,UpcaseStr(UserTemp.Name)) > 0) Then
            Begin
              Found := True;
            End;
          If IoResult=0 Then ;
          {$I+}
        End
      Else
        Begin
          If (Pos(s,UpcaseStr(Users[n-IndexLow].Name)) > 0) Then
            Begin
              Found := True;
            End;
        End;
      Inc(n);
    End;
  CloseFile(f);
  RestoreScreen(1);
  If Found Then FindUser := n-1
  Else Note('Could not find any matches beyond this point.');
End;

Procedure DeleteVacation(n: Word; v, d: Boolean);
Var
  f: File;
  u: UserRecord;
Begin
  If Not OpenFile(f,MainDir+'USERS.DAT','R',SIZE_USERS,faReadWrite+faDenyNone) Then
    Begin
      Note('Cannot open USERS.DAT file');
      ClearHalt;
    End;

  Dec(n);
  Seek(f,n);
  BlockRead(f,u,1);
  If (n<IndexLow) Or (n>=IndexLow+IndexCount) Then
  Else Begin Users[n-IndexLow+1].Vac := v; Users[n+1].Del := d; End;
  u.Del := d;
  u.VacationMode := v;
  Seek(f,n);
  BlockWrite(f,u,1);
  CloseFile(f);
End;

Procedure Transfer(n: String; i: Byte);
Begin
  While Pos(' ',n)>0 Do n[Pos(' ',n)] := '_';
  if(i=1) Then n := n + ' /M';
  Shell(MainDir+'OLMS.EXE /P='+n);
End;

Function BrowseUser: Longint;
Var
  LastOffset, Number, Offset: Word;
  LastCursor, c, Cursor: Byte;
  Done, Redraw: Boolean;
  SkipKey, Key: Char;
  Search: Longint;
Begin
  IndexLow   := $FFFF;
  IndexCount := 0;
  IndexHigh  := SizeofFile(MainDir+'USERS.DAT') DIV SIZE_USERS;
  If IndexHigh > BufferSize Then BufferUse := 75;

  FillScreen(9+1*16,'°');
  DrawWindow(2,2,78,24,15,BORDER_THICK);
  SkipKey    := #0;
  Offset     := 0;
  LastOffset := 1;
  Cursor     := 1;
  Done := False;
  Repeat
    Window(4,3,77,23);
    TextAttr := White;     Writeln('   Num   Name                                  Download Stats   Vac  Del');
    TextAttr := LightGray; Writeln(' ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
    Gotoxy(1,20);
    TextAttr := LightGray; Writeln(' ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
    TextAttr := White;     Write  (' (F)ind, (R)epeat, (E)dit, (V)acation, (D)elete, (T)ransfer              ');
    Redraw := False;
    Repeat
      If SkipKey=#0 Then
      Begin
      Window(5,5,77,21);
      If Offset<>LastOffset Then
        Begin
          For c := 1 To 17 Do
            Begin
              Number := Offset+C;
              Gotoxy(1,c);
              If Number <= IndexHigh Then
                Begin
                  If c = Cursor Then TextAttr := 31 Else TextAttr := 15;
                  WriteIt(Number);
                End
              Else
                Begin
                  TextAttr := 15;
                  ClrEol;
                End;
            End;
          End
        Else
          Begin
            Gotoxy(1,LastCursor); TextAttr := 15; WriteIt(Offset+LastCursor);
            Gotoxy(1,Cursor);     TextAttr := 31; WriteIt(Offset+Cursor);
          End;
        LastCursor := Cursor;
        LastOffset := Offset;
      End;

      NoWait;

      Repeat
        If SkipKey <> #0 Then
          Begin
            Key := SkipKey;
            Skipkey := #0;
          End
        Else Key := Upcase(Readkey);
      Until Key In [#0,#27,#13,'F','R','E','S','V','D','I','T',''];
      Case Key Of
        'D': With Users[Offset+Cursor-IndexLow] Do DeleteVacation(Offset+Cursor,Vac,Not Del);
        'V': With Users[Offset+Cursor-IndexLow] Do DeleteVacation(Offset+Cursor,Not Vac,Del);
        'T': Transfer(Users[Offset+Cursor-IndexLow].Name,0);
        '': Transfer(Users[Offset+Cursor-IndexLow].Name,1);
        'S': Begin
               Skipkey := 'R';
               SearchName := Setup^.Sysop;
             End;
        #13,
        'E': Begin If EditUser(Offset+Cursor-1) Then LastOffset := $FFFF; Redraw := True; End;
        'F',
        'R': Begin
               TextAttr := 15;
               Gotoxy(1,Cursor);
               WriteIt(Offset+Cursor);
               If Key = 'F' Then Search := FindUser(Offset+Cursor+1,'')
               Else Search := FindUser(Offset+Cursor+1,SearchName);
               If Search > -1 Then
                 Begin
                   Offset := Search-1;
                   Cursor := 1;
                   If (IndexHigh>16) And (Offset+17>=IndexHigh) Then
                     Begin
                       Offset := IndexHigh-17;
                       Cursor := Search-Offset;
                     End;
                 End;
             End;
        #27: Begin
               Done := True;
             End;
        #0 : Begin
               Key := Readkey;
               Case Key Of
                 #20: SkipKey := 'T';
                 #18: SkipKey := 'E';
                 #23: SkipKey := 'I';
                 'R': SkipKey := 'I';
                 ' ': SkipKey := 'D';
                 'S': SkipKey := 'D';
                 '/': SkipKey := 'V';
                 #19: SkipKey := 'R';
                 '!': SkipKey := 'F';
               End;
               Case Key Of
                 'H': If (Cursor>1)  Then Dec(Cursor) Else If (Offset>0) Then Dec(Offset);
                 'P': If (Cursor<17) And (Cursor<IndexHigh) Then Inc(Cursor) Else If (Offset+17<IndexHigh) Then Inc(Offset);
                 'I': If Offset>17 Then Dec(Offset,17) Else If Offset+Cursor>17 Then Begin Offset := 0; End Else Key := 'G';
                 'Q': If (Offset<IndexHigh-33) And (Offset+17<IndexHigh) Then Inc(Offset,17) Else Key := 'O';
               End;
               Case Key Of
                 'O': If IndexHigh > 16 Then
                      Begin Cursor := 17; Offset := IndexHigh-17; End Else
                      Begin Cursor := IndexHigh; Offset := 0; End;
                 'G': Begin Cursor := 1; Offset := 0; End;
               End;
             End;
      End;
    Until Done Or Redraw;
  Until Done;
  BrowseUser := -1;
End;

Procedure LoadConfig;
Const
 MaxRecords = 10;
Var
 fCTL: File;
 Records, Loop: Word;
 dCTL: Array[1..MaxRecords] Of MESSAGErecord;
 f: File;
 st: String;
 BBS_CC: String[5];
 w, Conf: Word;
Begin
  RA250 := False;
  {$IFDEF BBS_RA2}
  st := GetEnv('RA');
  If st = '' Then
    Begin
      Note('Enviroment variable "RA" not set');
      ClearHalt;
    End;
  PutTrail(st);
  BBS_CC := 'RA';
  {$ELSE}
  st := MainDir;
  BBS_CC := 'CC';
  {$ENDIF}

  If (SizeofFile(MainDir+'OLMS.CFG') <> Sizeof(SETUPrecord)) Then
    Begin
      Note('Incorrect OLMS.CFG version');
      ClearHalt;
    End;

  {$IFDEF BBS_RA2}
  If FileExists(st+'MESSAGES.RDX') Then RA250 := True;
  {$ENDIF}

  If  OpenFile(f,MainDir+'OLMS.CFG','R',Sizeof(SETUPrecord),faNormal)
  And OpenFile(fCTL,st+'MESSAGES.'+BBS_CC,'R',Sizeof(MESSAGErecord),faNormal)
  Then
    Begin
      Note1('Scanning Message Configuration');
      BlockRead(f,Setup^,1);
      CloseFile(f);
      ZMaxAreas := 0;
      Conf := 0;

      While Not Eof(fCTL) And (ZMaxAreas<AreaRange) Do
        Begin
          BlockRead(fCTL,dCTL,MaxRecords,Records);
          For Loop := 1 To Records Do
            Begin
              Inc(Conf);
              If RA250 Then w := dCTL[Loop].AreaNum Else w := Conf;
              If CleanStr(dCTL[Loop].Name)<>'' Then
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
      Note('Error opening configuration files!');
      ClearHalt;
    End;
End;

Function HeapFunc(Size: Word): Integer; Far;
Begin
  HeapFunc := 1;
End;

Procedure TvClear;
Var
  c: Byte;
Begin
  Window(1,1,80,25);
  If UpcaseStr(ParamStr(1))<>'/NOFANCY' Then
  Begin
  CursorHide;
  TextAttr := 15;
  For c := 1 To 12 Do
    Begin
      Gotoxy(1,c);    ClrEol;
      Gotoxy(1,26-c); ClrEol;
      Delay(35);
    End;
  Gotoxy(1,13); Write('  ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'); ClrEol;
  For c := 1 To 38 Do
    Begin
      Gotoxy(c+1,13);  Write(' ');
      Gotoxy(78-c,13); Write(' ');
      Delay(15);
    End;
  Gotoxy(39,13); Write('ù'); Delay(40);
  Gotoxy(39,13); Write('ú'); Delay(40);
  TextAttr := 7; Gotoxy(39,13); Write('ú'); Delay(40);
  TextAttr := 8; Gotoxy(39,13); Write('ú'); Delay(40); Write(#8,' ');
  End;
  TextAttr := 7;
  CursorView;
  ClrScr;
End;

{$F+}
Procedure Ending;
Var
  c: Word;
Begin
  ExitProc := Saved;
  For c := 1 To ZMaxAreas Do If AreaNames^[c] <> Nil Then Dispose(AreaNames^[c]);
  Dispose(AreaNames);
  Dispose(AreaNumbers);
  Dispose(Setup);
  TvClear;
End;
{$F-}

{$ENDIF}

Begin
  BufferUse     := BufferSize;
  Saved         := ExitProc;
  ExitProc      := @Ending;
  HeapError     := @HeapFunc;
  Setup         := New(pSETUPrecord);
  AreaNames     := New(pAreaNames);
  AreaNumbers   := New(pAreaNumbers);
  For Zmaxareas := 1 To AreaRange Do AreaNames^[Zmaxareas] := New(pStr40);

  CursorHide;
  LoadConfig;
  MainDir         := ExecutablePath;
  SearchName      := '';
  UserSizeSetup;
  While EditUser(BrowseUser) Do;
  CursorView;
End.

