Program MAINTAIN;

Uses DM6000, U_NEW, U_UNIT, Crt, Dos, JAMCRC32;

{$M 32000,128000,640000}
{$I d:\develop\olms\BBSTYPE.INC}

Var
  QwkIds: Array[0..8192] Of Byte;
  Buffer: Array[1..512] Of Longint;
  fc: File;
  f, ft: File;
  fd1, fd2: File;
  Result, i: Integer;
  NN: Longint;
  VacAge, VacSize, QFix, LastFind, PD, c, r, D,M,Y, n, Days, LastDate: Word;
  t, StartDir, MainDir: String;
  DoSort, VacNotOn, VacKill, VacOff, VacCrop, DupeBit: Boolean;
  GlobalIndex, UserAreas: Word;
  STemp: String[30];
  MVersion: String;
  Gin, Gout: File;

Type
  TElement  = Record
                Name: String[35];                                       {Element Type}
                Index: Word;
              End;

  TPointer  = ^TNode;                                   {Pointer of Node Type}

  TNode     = Record                                               {Node Type}
                Element: TElement;
                pLeft, pRight: TPointer;
              End;

  TTree     = Object                                             {Tree Object}
                Constructor Create;
                Procedure   Insert(Element: TElement);
                Procedure   InOrder;
                Procedure   Destroy;
              Private
                pTreeRoot: TPointer;
                Procedure   InsertTree(Var pRoot: TPointer; pNode: TPointer);
                Procedure   RInOrder(pRoot: TPointer);
                Destructor  RDestroy(pRoot: TPointer);
              End;

Procedure Logit(st: String);
Var
  W, D, M, Y, S, N, H, T: Word;
  st2: String;
Begin
  GetDate(Y,M,D,W);
  GetTime(H,N,S,T);
  st2 := '> '+ZeroPad(D,2)+'-'+Copy(MonthString,(M-1)*3+1,3)+' '+
                                   ZeroPad(H,2)+':'+ZeroPad(N,2)+':'+ZeroPad(S,2)+' QWKM';
  AppendFile('MAINTAIN.LOG',st2+' '+st);
End;

Constructor TTree.Create;
Begin
  pTreeRoot := Nil;
End;

Procedure TTree.Insert(Element: TElement);
Var
  Node: TPointer;
Begin
  New(Node);
  If Node = Nil Then
    Begin
      Writeln(' þ Out of memory sorting user list');
      Logit('Out of memory sorting user list');
      Destroy;
      Halt;
    End;
  Node^.Element := Element;
  InsertTree(pTreeRoot,Node);
End;

Procedure TTree.InOrder;
Begin
  RInOrder(pTreeRoot);
End;

Procedure TTree.Destroy;
Begin
  RDestroy(pTreeRoot);
End;

Function LastWord(st: String): String;
Var
  p: Byte;
  o: String;
Begin
  o := st;
  Repeat
    p := Pos(' ',st);
    if(p>0) Then st := Copy(st,p+1,255);
  Until p=0;
  LastWord := UpcaseStr(Copy(st+' '+o,1,35));
End;

Procedure TTree.InsertTree(Var pRoot: TPointer; pNode: TPointer);
Var
  C1, C2: String[35];
Begin
  If pRoot = Nil Then
    Begin
      pRoot := pNode;
      pRoot^.pLeft := Nil;
      pRoot^.pRight := Nil;
    End
  Else
    Begin
      C1 := LastWord(pNode^.Element.Name);
      C2 := LastWord(pRoot^.Element.Name);
      If (C1 < C2) {Or (Human^.Name=Setup^.Sysop)} Then InsertTree(pRoot^.pLeft,pNode)
      Else InsertTree(pRoot^.pRight,pNode);
    End;
End;

Procedure TTree.RInOrder(pRoot: TPointer);
Begin
  If pRoot <> Nil Then
    Begin
      RInOrder(pRoot^.pLeft);
      Seek(Gin,pRoot^.Element.Index);
      BlockRead(Gin,Human^,1);
      Human^.RecordNumber := GlobalIndex;
      Inc(GlobalIndex);
      BlockWrite(Gout,Human^,1);
      RInOrder(pRoot^.pRight);
    End;
End;

Destructor TTree.RDestroy(pRoot: TPointer);
Begin
  If pRoot <> Nil Then
    Begin
      TTree.RDestroy(pRoot^.pLeft);
      TTree.RDestroy(pRoot^.pRight);
      Dispose(pRoot);
    End;
End;

Procedure ClearBits;
Begin
 LastFind := 0;
 Fillchar(Qwkids,sizeof(Qwkids),0);
End;

Function IsBit(w: Word): Boolean;
Var
  a,b: Byte;
Begin
 a := w DIV 8;
 b := 1 Shl (w MOD 8);
 If (QwkIds[a] And b) = b Then IsBit := True Else IsBit := False;
End;

Procedure SetBit(w: Word);
Var
  a,b: Byte;
Begin
 a := w DIV 8;
 b := 1 Shl (w MOD 8);
 QwkIds[a] := QwkIds[a] Or b;
End;

Function FindEmptyBit: Word;
Var
  c: Word;
  Found: Boolean;
Begin
  Found := False;
  If LastFind<>$FFFF Then
    Begin
      c := LastFind;
      Repeat
        Inc(c);
        If Not IsBit(c) Then Found := True;
      Until Found Or (c=$FFFF);
      LastFind := c;
    End;
  FindEmptyBit := LastFind;
End;

Function Vis(st: String): String;
Var
  nst: String;
  c: Byte;
Begin
  nst := '';
  For c := 1 To length(st) Do
    If Upcase(st[c]) In ['þ','A'..'Z','0'..'9','.',' ',',','-'] Then nst := nst + st[c];
  Vis := nst;
End;

Function Pad(st: String; l: Byte): String;
Const
  Dots = 'úúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúúú';
Begin
  st := Vis(st);
  Pad := (Copy(st,1,l)+' '+Copy(Dots,1,l-Length(st))+' ');
End;

Procedure TreeSort;
Var
  e: TElement;
  w: Word;
  Tree: TTree;
Begin
  GlobalIndex := 0;
  Tree.Create;
  Writeln(' þ User sorting');
  If Not OpenFile(Gin,MainDir+'USERS.DAT','R',SIZE_USERS,faReadWrite+faDenyAll) Then
    Begin
      Writeln(' þ Cannot open files');
      Exit;
    End;

  If Not OpenFile(Gout,MainDir+'USERS.$$$','W',SIZE_USERS,faReadWrite+faDenyAll) Then
    Begin
      CloseFile(Gin);
      Writeln(' þ Cannot open files');
      Exit;
    End;

  w := 0;
  While Not Eof(Gin) Do
    Begin
      BlockRead(Gin,Human^,1);
      e.Name  := Human^.Name;
      e.Index := w;
      Tree.Insert(e);
      Inc(w);
    End;

{  Writeln(' þ Memory: ',MaxAvail,' bytes free'); }
  Writeln(' þ Rewriting user files');
  Tree.InOrder;

  CloseFile(Gin);
  CloseFile(Gout);

  Tree.Destroy;
  KillFile(MainDir+'USERS.TMP');
  RenameFile(MainDir+'USERS.DAT',MainDir+'USERS.TMP');
  If RenameFile(MainDir+'USERS.$$$',MainDir+'USERS.DAT')
  Then KillFile(MainDir+'USERS.TMP');
  Logit('Users sorted');
  ReindexUsers;
End;


{$IFDEF PROVERSION}
Procedure INFupdate;
Var
  f: File;
  NetmailReplyArea, HighConf, NumConf: Word;
  fi: File;
  fc: File;
  dc: MESSAGECONTROLrecord;
  Mainpath:String;
  fCTL: File;
  dCTL: Messagerecord;
  r, c: Word;
  RA250: Boolean;
Begin
  Mainpath := GetEnv('RA');
  If Mainpath = '' Then
    Begin
      Writeln(' þ Cannot compare fast message index, RA enviroment not set');
      Exit;
    End;
  PutTrail(MainPath);

  RA250 := FileExists(MainPath+'MESSAGES.RDX');
  If FileDate(MainPath+'MESSAGES.RA') < FileDate(MainDir+'MESSAGES.CTL') Then Exit;
  If Not OpenFile(fCTL,MainPath+'MESSAGES.RA','R',sizeof(messagerecord),faReadOnly+faDenyNone) Then
    Begin
      Writeln(' þ Cannot open messages config');
      Logit('<!> Cannot open MESSAGES.RA');
      Exit;
    End;

  Writeln(' þ Reindexing fast message indexes');

  If Not OpenFile(fi,MainDir+'MESSAGES.IDX','W',sizeof(FASTINDEXrecord),faReadWrite+faDenyAll)
  Or Not OpenFile(fc,MainDir+'MESSAGES.CTL','W',sizeof(MESSAGECONTROLrecord),faReadWrite+faDenyAll) Then
    Begin
      Writeln(' þ Could not create fast index');
      Logit('<!> Could not create fast index');
      Exit;
    End
  Else
    Begin
      Logit('Reindexing fast message index');
    End;

  NetMailReplyArea := 0;
  HighConf         := 0;
  NumConf          := 0;

  While Not Eof(fCTL) Do
    Begin
      {$I-}
      BlockRead(fCTL,dCTL,1);
      {$I+}
      If IoResult = 0 Then
        Begin
          Inc(NumConf);
          If RA250 Then c := dCTL.AreaNum Else c := NumConf;
          If c > HighConf Then HighConf := c;
          If (NetmailReplyArea=0) And (dCTL.Typ=Netmail) Then NetmailReplyArea := c;
          BlockWrite(fi,c,1);
          FillChar(dc,sizeof(dc),0);
          Seek(fc,c-1);
          dc.Name       := dCTL.Name;
          dc.Age        := dCTL.Age;
          dc.Security   := dCTL.ReadSecurity;
          dc.Group      := dCTL.Group;
          dc.Typ        := dCTL.Typ;
          dc.MsgKinds   := dCTL.MsgKinds;
          dc.Attribute  := dCTL.Attribute;
          dc.Attribute2 := dCTL.Attribute2;
          For r := 1 To 3 Do dc.AltGroup[r] := dCTL.AltGroup[r];
          For r := 1 To 4 Do dc.Flag[r]     := dCTL.ReadFlags[r];
          For r := 1 To 4 Do dc.NotFlag[r]  := dCTL.ReadNotFlags[r];
          BlockWrite(fc,dc,1);
        End;
    End;
  {$I+}
  CloseFile(fCTL);

  CloseFile(fi);
  CloseFile(fc);

  If OpenFile(f,MainDir+'MESSAGES.INF','W',1,faReadWrite+faDenyAll) Then
    Begin
      BlockWrite(f,NumConf,2);
      BlockWrite(f,HighConf,2);
      BlockWrite(f,NetmailReplyArea,2);
      CloseFile(f);
    End;
End;
{$ENDIF}

Function DirInfo(st: String; Var Age, Bytes: Longint): Boolean;
Var
  Info: SearchRec;
  DT: DateTime;
  w: Word;
  v, MaxDif, l: Longint;
Begin
  Fillchar(DT,Sizeof(DT),0);
  GetDate(DT.Year,DT.Month,DT.Day,w);
  PackTime(DT,l);

  Bytes := 0;
  MaxDif := 0;
  DirInfo := False;
  If ChangeDirectory(st) Then
    Begin
      FindFirst('*.*',255-Directory,Info);
      While DosError=0 Do
        Begin
          v := ((l-Info.Time) DIV 92000)+1;
          If v > MaxDif Then MaxDif := v;
          Inc(Bytes,Info.Size);
          FindNext(Info);
        End;
      DirInfo := True;
    End;
  ChangeDirectory(StartDir);
  Age := MaxDif;
End;

Function ProcessCommandLine: Boolean;
Var
  P: Boolean;
  c: Word;
  s: String;
Begin
  VacAge  := $FFFF;
  VacNotOn:= False;
  VacSize := $FFFF;
  VacCrop := False;
  VacKill := False;
  VacOff  := False;
  DoSort  := False;

  Days := 5000;
  ProcessCommandLine := True;
  P := False;

  For c := 1 To ParamCount Do
    Begin
      s := ParamStr(c);
      If Not (s[1] In ['-','/']) Then
        Begin
          If c = 1 Then
            Begin
              i := 0;
              Val(ParamStr(c),Days,i);
              If (i <> 0) Or (Days<1) Or (Days>5000) Then
                Begin
                  Writeln(' þ Number of idle days is not valid. ');
                  Writeln(' þ Range: 1-5000');
                  Halt;
                End;
            End
          Else ProcessCommandLine := False;
        End
      Else
        Begin
          s := UpcaseStr(Copy(ParamStr(c),2,255));
          If      Copy(s,1,6) = 'V:AGE='  Then Begin VacAge  := ValueString(Copy(s,7,255)); P:=True; End
          Else If Copy(s,1,7) = 'V:SIZE=' Then Begin VacSize := ValueString(Copy(s,8,255)); P:=True; End
          Else If Copy(s,1,7) = 'V:NOTON' Then Begin VacNotOn := True; P:=True; End
          Else If Copy(s,1,6) = 'V:CROP'  Then VacCrop  := True
          Else If Copy(s,1,8) = 'V:DELETE'Then VacKill  := True
          Else If Copy(s,1,6) = 'V:OFF'   Then VacOff   := True
          Else If Copy(s,1,4) = 'SORT'    Then DoSort   := True
          Else ProcessCommandLine := False;
        End;
    End;
  If VacKill And VacCrop Then ProcessCommandLine := False;
  If (VacKill Or VacCrop Or VacOff) And Not P Then ProcessCommandLine := False;
  If P And Not (VacKill Or VacCrop Or VacOff) Then ProcessCommandLine := False;
End;

Procedure CleanVacDir(st: String);
Var
  OldDate: Longint;
  OldName: String;
  Killed, LimitsOk, AnyFile: Boolean;
  Info: SearchRec;
  vo, vb: Longint;
Begin
  Repeat
    AnyFile := False;

    (* Find the oldest file *)
    FindFirst(st+'\*.*',255-Directory,Info);
    OldDate := Info.Time;
    OldName := Info.Name;
    While DosError=0 Do
      Begin
        If Info.Time < OldDate Then
          Begin
            OldDate := Info.Time;
            OldName := Info.Name;
          End;
        AnyFile := True;
        FindNext(Info);
      End;

    (* Delete the oldest file *)
    If AnyFile Then Killed := KillFile(st+'\'+OldName);

    (* Recheck limits *)
    LimitsOk := True;
    DirInfo(st,vo,vb);
    vb := vb DIV 1024;
    If (vo>VacAge)
    Or (vb>VacSize) Then LimitsOk := False;

  Until Not AnyFile Or LimitsOk Or Not Killed;

End;

Function HeapFunc(Size: Word): Integer; Far;
Begin
  HeapFunc := 1;
End;

Var
  C_Username: Array[1..40] Of Char;
  VacOld, VacBytes, C_Crc: Longint;
  VacDir: String;

Begin
  HeapError           := @HeapFunc;
  GetDir(0,StartDir); PutTrail(StartDir);
  Human       := New(pUSERrecord);
  Setup       := New(pSETUPrecord);

  MVersion := ShortVersion;
  {$IFDEF BBS_RA1}
  MVersion := MVersion + '.111';
  {$ENDIF}

  Writeln;
  Writeln('OLMS '+MVersion+' Maintenance program');
  Writeln('Copyright Multiboard Communications Centre and Peter Rocca, 1994-98');
  Writeln('ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ');
  FileMode := $12;


  If Not ProcessCommandLine Then
    Begin
      Writeln(' þ Usage: MAINTAIN [#days] [/V:COMMAND=VALUE...] [/SORT]');
      Writeln;
      Writeln('     #days         - days of inactivity before deleting the user record');
      Writeln('     /SORT         - sort the user records alphabetically');
      {$IFDEF PROVERSION}
      Writeln;
      Writeln('   Vacation Maintenance Commands');
      Writeln('   ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
      Writeln;
      Writeln('   Options used to trigger vacation maintenance actions');
      Writeln;
      Writeln('     /V:AGE=#      -   where # is the number of days old to limit');
      Writeln('     /V:SIZE=#     -   where # is the number of KB to limit');
      Writeln('     /V:NOTON      -   take action if users vacation flag is not on');
      Writeln;
      Writeln('   Available actions to take when the mail limits are exceeded');
      Writeln;
      Writeln('     /V:CROP       -   reduce vacation mail to meet limits');
      Writeln('     /V:DELETE     -   delete users vacation mail');
      Writeln('     /V:OFF        -   turn off the users vacation mail flag');
      {$ENDIF}
      Halt;
    End;

  MainDir := GetPath(ParamStr(0));
  DataDir := MainDir;
  AppendFile('MAINTAIN.LOG','');

  Stemp := '';
  For i := 1 To ParamCount Do Stemp := Stemp + UpcaseStr(ParamStr(i)) + ' ';
  If Stemp = '' Then Stemp := 'None';
  Logit('OLMS '+MVersion+' (MAINTAIN) Command='+Stemp);

  UserAreas := MaxAreas;
  {$IFDEF PROVERSION}
  If OpenFile(f,MainDir+'USERS.INF','R',1,faReadOnly+faDenyNone) Then
    Begin
      BlockRead(f,UserAreas,2);
      CloseFile(f);
    End;
  {$ENDIF}
  If UserAreas>MaxAreas Then UserAreas := MaxAreas;
  SIZE_USERS := Sizeof(USERrecord) - (MaxAreas-UserAreas);
  If SizeofFile(MainDir+'USERS.DAT') MOD SIZE_USERS <> 0 Then
    Begin
      Logit('<!> USERS.INF corrupt size mismatch');
      Writeln(' þ USERS.INF corrupt size mismatch!');
      Halt;
    End;

  If Not OpenFile(f,MainDir+'USERS.DAT','R',SIZE_USERS,faReadWrite+faDenyAll)
  Or Not OpenFile(ft,MainDir+'USERS.$$$','W',SIZE_USERS,faReadWrite+faDenyAll)
  Then
    Begin
      Writeln(' þ File Error');
      Writeln(' þ Could not open/create the user files. USERS.DAT must not be in use by any');
      Writeln('   other processes, and there must be room to create the new file');
      Logit('Could not open/create user files');
      Halt;
    End;

  If Not OpenFile(fc,MainDir+'OLMS.CFG','R',Sizeof(Setup^),faReadWrite+faDenyAll)
  Then
    Begin
      Writeln(' þ File Error');
      Writeln(' þ Could not open the OLMS.CFG file');
      Logit('Could not open '+MainDir+'OLMS.CFG');
      Halt;
    End;
  BlockRead(fc,Setup^,1);
  CloseFile(fc);

  ClearBits;
  Writeln(' þ User packing');
  PD := PresentDay;
  n := 0;
  r := 0;
  QFix := 0;
  While Not Eof(f) Do
    Begin
      {$I-}
      BlockRead(f,Human^,1);
      If IoResult<>0 Then
        Begin
          Human^.Del  := True;
          Human^.Name := 'Corrupt Entry';
        End;
      {$I+}

      CString(C_Username,DowncaseStr(Human^.Name));
      C_Crc := Crc32(C_Username,Length(Human^.Name),$FFFFFFFF);
      VacDir := MainDir+'VACATION\'+HexStr(C_Crc Shr 16)+HexStr(Word(C_CRC));

      DupeBit := IsBit(Human^.QWKID);
      If (Human^.LastDateDownload <> 'None') Then
        Begin
          Val(Copy(Human^.LastDateDownload,1,2),M,i);
          Val(Copy(Human^.LastDateDownload,4,2),D,i);
          Val(Copy(Human^.LastDateDownload,7,2),Y,i);
          If Y < 40 Then Inc(Y,100); {!Y2KOK!}
          LastDate := (Word(Y)) * 372 + (M-1) * 31 + D;
        End
      Else LastDate := 0;

      If Not Human^.Del And (PD-Lastdate < Days) Then
        Begin
{          Writeln('Positional: ',n:4,'  Record shows: ',u.RecordNumber); DEBUG!}
          Human^.RecordNumber := n;
          If DupeBit Then Begin Inc(QFix); Human^.QWKID := FindEmptyBit; End;
          SetBit(Human^.QWKID);
          {$IFDEF PROVERSION}
          If DirInfo(VacDir,VacOld,VacBytes) Then
            Begin
              VacBytes := VacBytes DIV 1024;
              If (VacOld>VacAge)
              Or (VacBytes>VacSize)
              Or (VacNotOn And Not Human^.VacationMode)
              Then
                Begin
                  If VacCrop Then Writeln(Pad(' þ '+Human^.Name,45),'Vacation mail cropped');
                  If VacKill Then Writeln(Pad(' þ '+Human^.Name,45),'Vacation mail deleted');
                  If VacOff  Then Writeln(Pad(' þ '+Human^.Name,45),'Vacation mode off');
                  If VacCrop Then Logit(SpacePad(Vis(Human^.Name),33)+': Vacation mail cropped');
                  If VacKill Then Logit(SpacePad(Vis(Human^.Name),33)+': Vacation mail deleted');
                  If VacOff  Then Logit(SpacePad(Vis(Human^.Name),33)+': Vacation mode off');

                  If VacCrop Then CleanVacDir(VacDir);
                  If VacKill Then KillDirectory(VacDir);
                  If VacOff  Then Human^.VacationMode := False;
                  ChangeDirectory(StartDir);
                End;
            End;
          {$ENDIF}
          BlockWrite(ft,Human^,1);
          Inc(n);
        End
      Else
        Begin
          Inc(r);
          t := '';
          For c := 1 To Length(Human^.Name) Do
            If Human^.Name[c] In ['A'..'Z',' ','a'..'z','0'..'9']
              Then t := t + Human^.Name[c];
          Human^.Name := t;
          If Human^.Del Then
            Begin
              Writeln(Pad(' þ '+Human^.Name,45),'Marked as deleted');
              Logit(SpacePad(Vis(Human^.Name),33)+': marked as deleted');
            End
          Else
            Begin
              If LastDate > 0 Then
                Begin
                  Writeln(Pad(' þ '+Human^.Name,45),'Inactive for ',PD-Lastdate,' days');
                  Logit(SpacePad(Vis(Human^.Name),33)+': inactive '+ZeroPad(PD-Lastdate,0)+' days');
                End
              Else
                Begin
                  Writeln(Pad(' þ '+Human^.Name,45),'Never downloaded');
                  Logit(SpacePad(Vis(Human^.Name),33)+': never downloaded');
                End
            End;
          {$IFDEF PROVERSION}
          If DirectoryExists(VacDir) Then
            Begin
              If DirInfo(VacDir,VacOld,VacBytes) Then Logit('   ÈÍÍ deleted '+VacDir);
              KillDirectory(VacDir);
            End;
          ChangeDirectory(StartDir);
          {$ENDIF}
        End;
    End;
  Writeln(' þ ',r,' records deleted');
  Logit(ZeroPad(r,0)+' records deleted');
  If QFix > 0 Then
    Begin
      Writeln(' þ ',QFix,' unique identifiers updated');
      Logit(ZeroPad(QFix,0)+' unique identifiers updated');
    End;
  CloseFile(f);
  CloseFile(ft);
  KillFile(MainDir+'USERS.TMP');
  RenameFile(MainDir+'USERS.DAT',MainDir+'USERS.TMP');
  If RenameFile(MainDir+'USERS.$$$',MainDir+'USERS.DAT')
  Then KillFile(MainDir+'USERS.TMP');

  Writeln(' þ Reindexing users');
  Logit('Reindexing user file');
  ReindexUsers;

  If OpenFile(fd1,MainDir+'MESSAGES.DUP','R',Sizeof(Longint),faReadWrite+faDenyAll) Then
    Begin
      Writeln(' þ Duplicate database packing');
      NN := FileSize(fd1);
      Writeln(' þ File contains ',NN,' signatures');
      Writeln(' þ Limit is ',Setup^.NumberDupes,' signatures');
      If NN > Setup^.NumberDupes Then
        Begin
          Writeln(' þ Purging ',NN-Setup^.NumberDupes,' signatures');
          Logit(ZeroPad(NN-Setup^.NumberDupes,0)+' message signatures removed');
          If OpenFile(fd2,MainDir+'MESSAGES.$$$','W',Sizeof(Longint),faReadWrite+faDenyAll) Then
            Begin
              Seek(fd1,NN-Setup^.NumberDupes);
              While Not Eof(fd1) Do
                Begin
                  BlockRead(fd1,Buffer,512,Result);
                  BlockWrite(fd2,Buffer,Result);
                End;
              CloseFile(fd2);
              CloseFile(fd1);
              KillFile(MainDir+'MESSAGES.TMP');
              RenameFile(MainDir+'MESSAGES.DUP',MainDir+'MESSAGES.TMP');
              If RenameFile(MainDir+'MESSAGES.$$$',MainDir+'MESSAGES.DUP')
              Then KillFile(MainDir+'MESSAGES.TMP');
            End;
        End
      Else CloseFile(fd1);
    End;

  If DoSort Then TreeSort;

  {$IFDEF PROVERSION}
  INFupdate;
  {$ENDIF}
  Logit('Complete');
  Dispose(Setup);
  Dispose(Human);
End.ÿÿ

