{
  * Inconsistancy:  Handle<>-1 was changed to >0 in OLMS, in JAMMB >=0
}

{$V-,S+,I+,R-,X+,G-}
{$M 27000,177104,225776}   (* Stack used: OLMS+DM = 19k + ~4k = ~23k *)

Program OLMS280;

{$I BBSTYPE.INC}

{$IFDEF BBS_RA2}
Uses DM6000, Crt, Dos, U_UNIT, U_NEW, U_LANG, U_HMB, U_JAM, JAMCRC32, JAM;
{$ENDIF}

{$IFDEF BBS_RA1}
Uses C_RA111, DM6000, Crt, Dos, U_UNIT, U_NEW, U_LANG, U_HMB, U_JAM, JAMCRC32, JAM;
{$ENDIF}

{$IFNDEF PROVERSION}
'Always compile in proversion.'
{$ENDIF}

Label
  VacationRecycle;

Type
  pControlIndex = ^tControlIndex;
  tControlIndex = Array[1..1000] Of MESSAGECONTROLrecord;

Var
  InDownloadingPacket: Boolean;
  ControlIndex: pControlIndex;
  NetmailReplyArea: Word;
  HeapSizeAllocated, TagLineSize: Longint;
  AutoName: String[35];
  ComLineMode, LogLineTemp: String[8];
  ErrorExitProc: Pointer;

  UserIndex, VacationPointer: Word;
  ErrorTimes: Byte;
  Control_Running, VacationLoaded, VacationManager, VacationMode, Closeited, UserLoaded, LessWait: Boolean;
  Control_Low, Control_High: Word;


Function CanDispose(Var p): Boolean;
Begin
  CanDispose := Boolean(Pointer(p) <> Nil);
End;

Procedure MarkDispose(Var p);
Begin
  Pointer(p) := Nil;
End;

Procedure ControlInit;
Begin
  Control_Running := True;
  Control_Low     := 0;
  Control_High    := 0;
  ControlIndex    := New(pControlIndex);
End;

Procedure ControlInfo(w, p: Word; Var dCFG: MESSAGErecord);
Var
  fi: File;
  x, n: Word;
  r: Byte;
Begin
  {$IFDEF PROVERSION}
  If (w<Control_Low) Or (w>Control_High) Then
    Begin
      If OpenFile(fi,MainDir+'MESSAGES.CTL','R',Sizeof(MESSAGECONTROLrecord),faReadOnly+faDenyNone) Then
        Begin
          Seek(fi,w-1);
          BlockRead(fi,ControlIndex^,1000,n);
          CloseFile(fi);
          Control_Low  := w;
          Control_High := w + n - 1;
          If Control_High > MaxAreas Then Control_High := MaxAreas;
        End
      Else
        Begin
          Logit('C','<!> Error reading message control index');
          EndDoorMaker;
        End;
    End;
  FillChar(dCFG,Sizeof(MESSAGErecord),0);
  x := w - Control_Low + 1;
  dCFG.Name         := ControlIndex^[x].Name;
  dCFG.Age          := ControlIndex^[x].Age;
  dCFG.ReadSecurity := ControlIndex^[x].Security;
  dCFG.Group        := ControlIndex^[x].Group;
  dCFG.Typ          := ControlIndex^[x].Typ;
  dCFG.MsgKinds     := ControlIndex^[x].MsgKinds;
  dCFG.Attribute    := ControlIndex^[x].Attribute;
  dCFG.Attribute2   := ControlIndex^[x].Attribute2;
  For r := 1 To 3 Do dCFG.AltGroup[r]     := ControlIndex^[x].AltGroup[r];
  For r := 1 To 4 Do dCFG.ReadFlags[r]    := ControlIndex^[x].Flag[r];
  For r := 1 To 4 Do dCFG.ReadNotFlags[r] := ControlIndex^[x].NotFlag[r];
  {$ELSE}
  Seek(fCFG,p-1);
  Read(fCFG,dCFG);
  {$ENDIF}
End;

Procedure ControlDone;
Begin
  Control_Running := False;
  If CanDispose(ControlIndex) Then Dispose(ControlIndex); MarkDispose(ControlIndex);
End;

Function HeapFunc(Size: Word): Integer; Far;
Begin
  HeapFunc := 1;
End;

Function Selected(Conf: Word): Boolean;
Begin
  If (Conf<1) Or (Conf>HighConf)
  Then Selected := False
  Else Selected := (Human^.Flags[Conf] > 0) Or ((Setup^.SysopFlags[Conf] And sFORCED) <> 0);
End;

Function RemoveKludges(Var Kludge: Char; Var Data: String; Var Len: Word; Conf: Word): Boolean;
Var
  st: String;
  Start: Byte;
Begin
  st := '';
  For Start := 0 To 7 Do st := st + Upcase(MSGBUF^[Start]);

  If (Copy(st,1,3) = 'TO:') And Not Is(Setup^.SysopFlags[Conf],sKEEPTO) Then Begin Start := 3; Kludge := 'T'; End
  Else If Copy(st,1,8) = 'SUBJECT:' Then Begin Start := 8; Kludge := 'S'; End
  Else If Copy(st,1,5) = 'SUBJ:' Then Begin Start := 5; Kludge := 'S'; End
  Else Begin RemoveKludges := False; Exit; End;

  RemoveKludges := True;
  st := '';
  While (Start<Len) And Not (MSGBUF^[Start] In [CR,#10,#13,#0]) Do
    Begin
      st := st + MSGBUF^[Start];
      Inc(Start);
    End;
  Move(MSGBUF^[Start+1],MSGBUF^[0],Len-Start+1);
  Len := Len-Start-1;

  While(st[0]>#0) And (st[1]=' ') Do st := Copy(st,2,255);
  While(st[Byte(st[0])]=' ') Do Dec(st[0]);

  If (Kludge='T') And (Pos('@',st)=0) Then AutoCap(st);
  Data := st;
End;

Procedure Signature(Filename: String; Var TextLen: Word);
Var
  T: Text;
  Line: String;
  c: Byte;
Begin
  If Not Reg Then Exit;
  If Longint(TextLen)+SizeofFile(MainDir+FileName) > Longint(TextBufferSize) Then Exit;
  If OpenText(T,MainDir+Filename,'R',faNormal) Then
    Begin
      TextLen := InsertBuffer(TextLen,TextLen,#13);
      While Not Eof(T) Do
        Begin
          Readln(T,Line);
          For c := 1 To Length(Line) Do If Line[c] < #32 Then Line[c] := #32;
          Line := Line + #13;
          TextLen := InsertBuffer(TextLen,TextLen,Line);
        End;
      CloseText(T);
    End;
End;

Function InsertTearLine(Conf, Len: Word; ConfType: MsgType; Attr: Byte; Origin: String;
                        Zone, Net, Node, Point: Word): Word;
Var
  gs, st: String[128];
  ch: Char;
  fH: File;
  l: Longint;
  Loc, Last, a: Word;
  Temp: String;
Begin

  (* Clean #10's out of data *)
  a := 0;
  While a <= Len Do
    Begin
      If MSGBUF^[a] = #10 Then
        Begin
          Move(MSGBUF^[a+1],MSGBUF^[a],Len-a+1);
          Dec(Len);
        End
      Else
        Begin
          If MSGBUF^[a] = CR Then MSGBUF^[a] := #13
          Else If MSGBUF^[a] = #0 Then MSGBUF^[a] := #32;
          Inc(a);
        End;
    End;

  If Len>160 Then Loc := Len-200 Else Loc := 0;
  While Loc<Len Do
    Begin
      Last := 0;
      For a := Loc To Len-1 Do If (Last=0) And (MSGBUF^[a]=#13) Then Last := a;
      If Last = 0 Then Last := Len;
      Move(MSGBUF^[Loc],Temp[1],10); Temp[0] := #10;
      a := 0;
      If Setup^.KillTag Or Is(Setup^.SysopFlags[Conf],sNOTAG) Then
        Begin
          If (Copy(Temp,1,4)='... ')
          Or (Copy(Temp,1,4)='...'+#13)
          Or (Copy(Temp,1,4)='___ ')
          Or (Copy(Temp,1,4)='___'+#13) Then a := 1;
        End;
      If Setup^.Retear Then
        Begin
          If (Copy(Temp,1,4)='--- ')
          Or (Copy(Temp,1,4)='---'+#13)
          Or (Copy(Temp,1,10)=' * Origin:') Then a := 1;
        End
      Else
        Begin
          If (Copy(Temp,1,4)='--- ')
          Or (Copy(Temp,1,4)='---'+#13) Then MSGBUF^[Loc+1] := '!';
        End;
      If a=1 Then
        Begin
          Move(MSGBUF^[Last+1],MSGBUF^[Loc],Len-Last);
          Dec(Len,Last-Loc+1);
        End
      Else Inc(Loc,Last-Loc+1);
    End;

  (* Clean up the end of the message *)
  While (MSGBUF^[Len] In [#13,#32,#0]) And (Len>0) Do
    Begin
      MSGBUF^[Len] := #32;
      Dec(Len);
    End;
  Inc(Len);

  (* Insert signatures *)
  Case ConfType Of
    Netmail  : Signature('NETMAIL.TAG',Len);
    EchoMail : Signature('ECHOMAIL.TAG',Len);
    Internet : Signature('INTERNET.TAG',Len);
    UseGroup : Signature('USEGROUP.TAG',Len);
  Else         Signature('LOCAL.TAG',Len);
  End;

  (* Clean up the end of the message *)
  While (MSGBUF^[Len] In [#13,#32,#0]) And (Len>0) Do
    Begin
      MSGBUF^[Len] := #32;
      Dec(Len);
    End;
  Inc(Len);

  Temp := #13+#13;
  If Setup^.InsertTag And Not Is(Setup^.SysopFlags[Conf],sNOTAG) Then
    Begin
      l := Random(Abs(TagLineSize-60));
      If OpenFile(fH,Setup^.TagFile,'R',1,faReadOnly+faDenyNone) Then
        Begin
          {$I-}
          Seek(fH,l);
          If IoResult = 0 Then
            Begin
              ch := #0;
              While Not Eof(fH) And (ch = #0) Do
                Begin
                  BlockRead(fH,ch,1); {!! this routine is SHIT }
                  If ch In [#10,#13] Then
                    Begin
                      BlockRead(fH,ch,1);
                      If ch In [#10,#13] Then BlockRead(fH,ch,1);
                    End
                  Else ch := #0;
                End;
              Temp := Temp + '... ' + ch;
              l := 0;
              While Not Eof(fH) And Not (ch In [#10,#13]) And (l<60) Do
                Begin
                  Inc(l);
                  BlockRead(fH,ch,1);
                  If Not (ch In [#10,#13]) Then Temp := Temp + ch;
                End;
              Temp := Temp + #13;
            End;
          {$I+}
          CloseFile(fH);
        End;
    End;

  (* Build origin line *)
  If Origin = '' Then Origin := DefaultOriginLine;
  st := 'Origin: '+Origin+' ('+ZeroPad(Zone,1)+':'+ZeroPad(Net,1)+'/'+ZeroPad(Node,1);
  If Point > 0 Then st := st + '.'+ZeroPad(Point,1);
  st := st + ')';

  (* Add required lines to bottom of message *)
  If Reg And Setup^.Gloat Then gs := ' OLMS '+ShortVersion+'+ ['+Setup^.Serial+']' Else gs := '';
  If Not Reg Then Temp := Temp + '-+- OLMS '+ShortVersion+' UNREG' + #13;
  If Is(Attr,1) Then Temp := Temp + '---' + gs + #13 + ' * '+st+#13;
  Len := InsertBuffer(Len,Len,Temp);
  InsertTearLine := Len;
End;

Procedure LoadLastRead;
Begin
  (* Load lastread pointers *)
  HMB_LoadLastReads;
  JAM_LoadLastReads;
End;

Procedure SaveLastRead;
Begin
  (* Write lastread pointers *)
{ If paramstr(2)='!' Then Exit; {!!}
{ If paramstr(3)='!' Then Exit; {!!}
  HMB_SaveLastReads;
  JAM_SaveLastReads;
End;

Procedure SaveReceived;
Begin
  (* Write received bits *)
  HMB_SaveReceived;
  JAM_SaveReceived;
End;

Procedure ModifyPointer(Conf: Word; Mode: Char; Amount: Word);
Var
  dCFG: MESSAGErecord;
Begin
  IdleMinutes := 0;
  If Not ValidConference(Conf) Then Exit;
  {$I-}
  Seek(fCFG,ConferenceLocation(Conf)-1);
  BlockRead(fCFG,dCFG,1);
  If IoResult <> 0 Then
    Begin
      Logit('C','<!> Modify pointer error on conference '+Zeropad(Conf,0));
      Exit;
    End;
  {$I+}
  If Not VisableArea(dCFG,Conf) Then Exit;

  If Not Is(dCFG.Attribute,cJAM) Then HMB_ModifyPointer(Conf,Amount)
  Else If dCFG.JamBase <> ''     Then JAM_ModifyPointer(dCFG.JamBase,Conf,Amount);
End;

Procedure ChangePointers;
Var
  dCFG: MESSAGErecord;
  Includes: Array[0..MaxAreas] Of Boolean;
  Temp: String;
  Key: Char;
  Conf, Position, Amount: Word;
  ii: Integer;
Begin
  Display('-MODIFY','ACN123');
  Repeat
    If Not GetPushedKey(Key) Then Key := Upcase(Getchar);
  Until Key In ['A','C','N','1','2','3'];
  If Key In ['N','3'] Then Exit;

  ClearScreen;
  DoColor(COL_TITLE);
  WriteStringCF(LANG(L_ModifyPointers));
  DrawLine;
  DoColor(COL_TITLE);

  Fillchar(Includes,Sizeof(Includes),0);
  If Key In ['A','1'] Then
    Begin
      WriteStringCF(LANG(L_GlobalChange));
      For Conf := 1 To MaxAreas Do If Selected(Conf) Then Includes[Conf] := True;
    End
  Else
    Begin
      WriteString(LANG(L_ListCurrent));
      Key := ExTimedYesNo(HotKey[L_No],1000);
      WriteLines(1);
      If Key = HotKey[L_Yes] Then
        Begin
          WriteLines(1);
          Amount := 0;
          Seek(fCFG,0);
          For Position := 1 To NumConf Do
            Begin
              Conf := ConferenceNumber(Position);
              If Selected(Conf) Then
                Begin
                  Seek(fCFG,Position-1);
                  BlockRead(fCFG,dCFG,1);
                  If VisableArea(dCFG,Conf) Then
                    Begin
                      DoColor(COL_CONFNUM);  WriteString(ZeroPad(Position,-4));
                      DoColor(COL_CONFNAME); WriteStringCF('  '+dCFG.Name);
                      Inc(Amount);
                    End;
                End;
              If Amount = 19 Then (* Continue (Y/n) *)
                Begin
                  Amount := 0;
                  DoColor(COL_PROMPT); WriteString(LANG(L_Continue));
                  Key := ExTimedYesNo(HotKey[L_Yes],1000);
                  ClearLine;
                  If Key <> HotKey[L_Yes] Then Position := NumConf;
                End;
            End;
          WriteLines(1);
        End;
      DoColor(COL_QUESTION);
      WriteString(LANG(L_AreasToChange));
      Temp := GetString(50,Colors[COL_INPUTFORE],Upper);
      If Not ReturnIncludes(Includes,Temp,HighConf) Then Exit;
      WriteLines(1);
    End;
  DoColor(COL_QUESTION);
  WriteString(LANG(L_HowMany));
  Temp := GetString(4,Colors[COL_INPUTFORE],Number);
  If Temp = '' Then Exit;
  Val(Temp,Amount,ii);
  WriteLines(1);
  DoColor(COL_TITLE); WriteString(LANG(L_Resetting));

  If Key In ['A','1'] Then (* Global change *)
    Begin
      For Conf := 1 To MaxAreas Do
        Begin
          If Includes[Conf] Then ModifyPointer(Conf,'N',Amount);
        End;
    End
  Else (* Selected areas change *)
    Begin
      For Position := 1 To NumConf Do
        Begin
          If Includes[Position] Then
            Begin
              Conf := ConferenceNumber(Position);
              If Conf>0 Then ModifyPointer(Conf,'N',Amount);
            End;
        End;
    End;
  SaveLastRead;
  WriteLines(2);
  DoColor(COL_PRESSSPACE); WriteString(LANG(L_PressSpace));
  Repeat Until Getchar In [HotKey[L_PressSpace],#13];
End;

Procedure ResetAllPointers(st: String);
Var
  V, Count: Word;
Begin
  If (st[1] <> 'R') Or Not (st[2] In ['G','S']) Then Exit;
  V := ValueString(Copy(st,4,5));

  DoColor(COL_TITLE);
  WriteString(SpacePad('',38-Length(LANG(L_Resetting)) DIV 2)+LANG(L_Resetting)+'    ');
  DoColor(COL_SPIN);
  LoadLastRead;
  SaveStat_Init;
  For Count := 1 To HighConf Do
    Begin
      If ValidConference(Count) Then
        Begin
          SaveStat_Display;
          If (st[2]='G') Or Selected(Count) Then
            Begin
              ModifyPointer(Count,'N',V);
            End;
        End;
    End;
  SaveLastRead;
  SaveStat_Complete;
  SaveStat_Close;
End;


(**************************************************************************)
(* Message posting Routines                                               *)
(**************************************************************************)
Procedure HudsonOpen;
Begin
 If HMB_Open Then Exit;
 WriteStringCF(' '+LANG(L_NotOpen)+LANG(L_MessageBase)+', '+LANG(L_Inform));
 LogIt('C','<!> Could not open the Hudson message base');
 Sleep(3);
 ExitProc := ErrorExitProc;
 EndDoorMaker;
End;

(**************************************************************************)
(* Datafile IO Routines                                                   *)
(**************************************************************************)
Procedure OpenMessagesConfig;
Label
  EndOfOpenConfig;
Var
  fi: File;
  fc: File;
  dc: MESSAGECONTROLrecord;
  f: File;
  fGRP: File;
  dGRP: Array[1..10] Of GROUPrecord;
  dCFG: MESSAGErecord;
  RdxResult, r, Result: Word;
  c: Word;
Begin
  FillChar(Groups,Sizeof(Groups),3);
  HighMessageGroup := 0;
  RdxResult := 0;

  {$IFDEF BBS_RA2}
  If FileExists(Setup^.MainPath+'MESSAGES.RDX') Then RA250 := True;
  If OpenFile(f,Setup^.MainPath+'MESSAGES.RDX','R',2,faReadOnly+faDenyNone) Then
    Begin
      RA250 := True;
      BlockRead(f,dRDX,MaxAreas,Result);
      RdxResult := Result;
      CloseFile(f);
    End
  Else If RA250 Then
    Begin
      Logit('C','<!> Fatal error; could not read RDX file');
      EndDoorMaker;
    End;

  If OpenFile(fGRP,Setup^.MainPath+'MGROUPS.RA','R',Sizeof(GROUPrecord),faReadOnly+faDenyNone) Then
    Begin
      {$I-}
      c := 0;
      While Not Eof(fGRP) Do
        Begin
          BlockRead(fGRP,dGRP,10,Result);
          For r := 1 To Result Do
            Begin
              If IoResult = 0 Then
                Begin
                  If RA250 Then c := dGRP[r].AreaNum Else Inc(c);
                  If c > HighMessageGroup Then HighMessageGroup := c;
                  If c <= MaxGroups Then
                    Begin
                      If Not IsArea(dGRP[r].Security,dGRP[r].Flags,dGRP[r].NotFlagsMask)
                      Then Groups[c]     := 2                        (* Subtract MGRP access *)
                      Else GroupNames[c] := Copy(dGRP[r].Name,1,40); (* Store name *)
                    End;
                End;
            End;
        End;
      {$I+}
      CloseFile(fGRP);
    End;

  If OpenFile(fGRP,Setup^.MainPath+'FGROUPS.RA','R',Sizeof(GROUPrecord),faReadOnly+faDenyNone) Then
    Begin
      {$I-}
      c := 0;
      While Not Eof(fGRP) Do
        Begin
          BlockRead(fGRP,dGRP,10,Result);
          For r := 1 To Result Do
            Begin
              If IoResult = 0 Then
                Begin
                  If RA250 Then c := dGRP[r].AreaNum Else Inc(c);
                  If c <= MaxGroups Then
                    Begin
                      If Not IsArea(dGRP[r].Security,dGRP[r].Flags,dGRP[r].NotFlagsMask)
                      Then Groups[c] := Groups[c] And 1  (* Subtract FGRP access *)
                      Else Begin End;                    (* Leave it alone *)
                    End;
                End;
            End;
        End;
      {$I+}
      CloseFile(fGRP);
    End;
  {$ENDIF} (* BBS_RA2 *)

  (* So group 0's don't effect security *)
  Groups[0] := 0;

  If Not OpenFile(fCFG,Setup^.MainPath+'MESSAGES.'+BBS_CC,'R',Sizeof(MESSAGErecord),faReadOnly+faDenyNone) Then
    Begin
      WriteStringCF(' '+LANG(L_NotOpen)+LANG(L_MessageCfg)+', '+LANG(L_Inform));
      Logit('C','<!> Could not open '+Setup^.MainPath+'MESSAGES.'+BBS_CC);
      Sleep(3);
      ExitProc := ErrorExitProc;
      EndDoorMaker;
    End;

  NetMailReplyArea := 0;
  HighConf         := 0;
  NumConf          := 0;

  {$IFDEF PROVERSION}
  If (FileDate(Setup^.MainPath+'MESSAGES.RA') < FileDate(MainDir+'MESSAGES.CTL'))
  And FileExists(MainDir+'MESSAGES.IDX')
  Then
    Begin
      If OpenFile(f,MainDir+'MESSAGES.INF','R',1,faReadOnly+faDenyNone)  Then
        Begin
          BlockRead(f,NumConf,2);
          BlockRead(f,HighConf,2);
          BlockRead(f,NetmailReplyArea,2);
          CloseFile(f);
          Goto EndOfOpenConfig;
        End;
    End
  Else
    Begin
      If Not OpenFile(fi,MainDir+'MESSAGES.IDX','W',sizeof(FASTINDEXrecord),faReadWrite+faDenyAll)
      Or Not OpenFile(fc,MainDir+'MESSAGES.CTL','W',sizeof(MESSAGECONTROLrecord),faReadWrite+faDenyAll) Then
        Begin
          Logit('C','<!> Could not create fast index');
          EndDoorMaker;
        End
      Else
        Begin
          Logit('C','Reindexing fast message index');
        End;
      BarMessage := ' Recompiling';
      DisplayStatusbar;
    End;
  {$ENDIF}

  (* Figure out the default netmail reply area *)
  {$I-}
  c := 0;
  While Not Eof(fCFG) And (NumConf<MaxAreas) Do
    Begin
      BlockRead(fCFG,dCFG,1);
      If IoResult = 0 Then
        Begin
          Inc(NumConf);
          If RA250 Then c := dCFG.AreaNum Else c := NumConf;
          If c > HighConf Then HighConf := c;
          If (NetmailReplyArea=0) And (dCFG.Typ=Netmail) Then NetmailReplyArea := c;
          {$IFDEF PROVERSION}
          BlockWrite(fi,c,1);
          FillChar(dc,sizeof(dc),0);
          if(c>0) Then Seek(fc,c-1)
          Else Logit('C','<!> Warning RA 2.5 conference contains zero field');
          dc.Name       := dCFG.Name;
          dc.Age        := dCFG.Age;
          dc.Security   := dCFG.ReadSecurity;
          dc.Group      := dCFG.Group;
          dc.Typ        := dCFG.Typ;
          dc.MsgKinds   := dCFG.MsgKinds;
          dc.Attribute  := dCFG.Attribute;
          dc.Attribute2 := dCFG.Attribute2;
          For r := 1 To 3 Do dc.AltGroup[r] := dCFG.AltGroup[r];
          For r := 1 To 4 Do dc.Flag[r]     := dCFG.ReadFlags[r];
          For r := 1 To 4 Do dc.NotFlag[r]  := dCFG.ReadNotFlags[r];
          BlockWrite(fc,dc,1);
          {$ENDIF}
        End;
    End;
  {$I+}

  {$IFDEF PROVERSION}
  CloseFile(fi);
  CloseFile(fc);
  If OpenFile(f,MainDir+'MESSAGES.INF','W',1,faReadWrite+faDenyAll) Then
    Begin
      BlockWrite(f,NumConf,2);
      BlockWrite(f,HighConf,2);
      BlockWrite(f,NetmailReplyArea,2);
      CloseFile(f);
    End;
  {$ENDIF}

EndOfOpenConfig:

  If RA250 And (RdxResult <> HighConf) Then Logit('D','DEBUG: MESSAGES.RDX file does not matchup with HighConf');

  If HighConf > MaxAreas Then HighConf := MaxAreas;
  If NumConf  > MaxAreas Then NumConf  := MaxAreas;
End;

Procedure InitUserRecordSize;
Var
  fUSRDAT: File;
  UserAreas: Word;
Begin
  UserAreas := MaxAreas;
  {$IFDEF PROVERSION}
  If OpenFile(fUSRDAT,DataDir+'USERS.INF','R',1,faReadOnly+faDenyNone) Then
    Begin
      BlockRead(fUSRDAT,UserAreas,2);
      CloseFile(fUSRDAT);
    End;
  {$ENDIF}
  If UserAreas>MaxAreas Then UserAreas := MaxAreas;
  SIZE_USERS := Sizeof(USERrecord) - (MaxAreas-UserAreas);
  If SizeofFile(DataDir+'USERS.DAT') MOD SIZE_USERS <> 0 Then
    Begin
      Logit('C','<!> USERS.INF corrupt size mismatch, exiting.');
      EndDoorMaker;
    End;
End;

Procedure LoadUser;
Type
  pUSRBUF = ^tUSRBUF;
  tUSRBUF = Array[1..BUFMAX_USR] Of Longint;
Var
  USRBUF: pUSRBUF;
  C_Username: Array[1..40] Of Char;
  fUSRIDX, fUSRDAT: File;
  Found: Boolean;
  Loop, Result, Count: Word;
  Key: Char;
Begin
  CString(C_Username,DowncaseStr(User.Name));
  Username_CRC := Crc32(C_Username,LenBuf(C_Username),$FFFFFFFF);
  Name         := UpcaseStr(User.Name);
  Alias        := UpcaseStr(User.Handle); If Alias = '' Then Alias := Name;

  If Not FileExists(DataDir+'USERS.IDX') Then CreateFile(DataDir+'USERS.IDX');
  If Not FileExists(DataDir+'USERS.DAT') Then CreateFile(DataDir+'USERS.DAT');

  If (SizeofFile(DataDir+'USERS.IDX') DIV Sizeof(Longint)) <>
     (SizeofFile(DataDir+'USERS.DAT') DIV SIZE_USERS) Then
    Begin
        Logit('C','Reindexing user file');
        BarMessage := ' Reindexing';
        DisplayStatusBar;
        ReIndexUsers;
    End;

  If Not (OpenFile(fUSRIDX,DataDir+'USERS.IDX','R',Sizeof(Longint),faReadOnly+faDenyNone) And
          OpenFile(fUSRDAT,DataDir+'USERS.DAT','R',SIZE_USERS,faReadWrite+faDenyWrite))
  Then
    Begin
      Logit('C','<!> User records could not be opened.');
      BulletError('<!> User records could not be opened.');
      NewHalt(2000);
    End;

  USRBUF := New(pUSRBUF);
  If USRBUF = Nil Then
    Begin
      WriteLines(2);
      BulletError(LANG(L_NoMemory)+', '+LANG(L_Inform));
      EndDoorMaker;
    End;

  Found := False;
  Count := 0;
  While Not Found And (Not Eof(fUSRIDX)) Do
    Begin
      BlockRead(fUSRIDX,USRBUF^,BUFMAX_USR,Result);
      For Loop := 1 To Result Do
        Begin
          If Not Found Then
            Begin
              If USRBUF^[Loop] = Username_CRC Then
                Begin
                  Seek(fUSRDAT,Count);
                  FillChar(Human^,Sizeof(Human^),0);
                  BlockRead(fUSRDAT,Human^,1);
                  Found := True;
                End;
              Inc(Count);
            End;
        End;
    End;
  Dispose(USRBUF);
  CloseFile(fUSRDAT);
  CloseFile(fUSRIDX);

  If Not Found Then
    With Human^ Do
    Begin
      BarMessage := '   Newuser   ';
      FillChar(Human^,Sizeof(USERrecord),0);
      FillChar(Human^.Bulletins,Sizeof(Human^.Bulletins),255);
      For Count := 1 To MaxAreas Do If Is(Setup^.SysopFlags[Count],sDEFAULT) Then Human^.Flags[Count] := fALL;
      For Count := 1 To 200 Do
        Begin
          If  (User.CombinedInfo[Count] > 0)
          And (User.CombinedInfo[Count]<=MaxAreas)
          Then Human^.Flags[User.CombinedInfo[Count]] := fALL;
        End;
      QWKID            := Crc32(Name[1],Length(Name),$FFFFFFFF);
      Name             := User.Name;
      LastDateDownload := 'None';
      LastTimeDownload := 'None';
      Indexes          := True;
      Files            := True;
      News             := True;
      LastFileScan     := ReturnPackDate - 200000;
      UseHigh          := True;
      GetWelcome       := True;
      Revision         := 20002000;
      Archiver         := '@';
      Protocol         := User.Protocol;
      ShortList        := Boolean(NumConf>500);
      PacketType       := Setup^.DefaultPacketType;
      If PacketType>ptBWave Then PacketType := ptQWK;
      If Protocol In ['1','Q'] Then Protocol := 'X';
      If Protocol In ['G'    ] Then Protocol := 'Y';
      If OpenFile(fUSRDAT,DataDir+'USERS.DAT','R',SIZE_USERS,faReadWrite+faDenyWrite) Then
        Begin
          If OpenFile(fUSRIDX,DataDir+'USERS.IDX','A',Sizeof(Longint),faReadWrite+faDenyWrite) Then
            Begin
              BlockWrite(fUSRIDX,Username_CRC,1);
              CloseFile(fUSRIDX);
            End;
          Human^.RecordNumber := Word(FileSize(fUSRDAT));
          Seek(fUSRDAT,Human^.RecordNumber);
          BlockWrite(fUSRDAT,Human^,1);
          CloseFile(fUSRDAT);
          Logit('E','Newuser record created');
          Display('-NEW','F.'+HotKey[L_PressSpace]+#13);
          Repeat
            If Not GetPushedKey(Key) Then Key := Upcase(Getchar);
          Until Key In ['F',HotKey[L_PressSpace],#13,'.'];
          If Key = 'F' Then ResetAllPointers('RG=50');
          Count := Human^.RecordNumber + 1;
        End
      Else
        Begin
          Logit('C','Could not save new user record!');
          NewHalt(2000);
        End;
    End;
End;

Procedure ValidateUserFields;
Var
  Count: Word;
  Temp: String[40];
Begin
  UserLoaded := True;
  If Human^.Revision <> 20002000 Then
    Begin
      Human^.PacketType   := 0;
      Human^.FilesQueued  := 0;
      Human^.UseHigh      := True;
      Human^.GetWelcome   := True;
      FillChar(Human^.Bulletins,Sizeof(Human^.Bulletins),1);
      Human^.Revision := 20002000;
    End;
  Setup^.MaxPacket[0] := 60000;
  DateToDay(Count,User.BirthDate);
  UserAge   := (PresentDay-Count) DIV 365;
  UserIndex := Human^.RecordNumber;
  MAXPPACK  := Human^.MaxPacket;
  MAXPCONF  := Human^.MaxConference;
  If (MAXPPACK < 1) Or (MAXPPACK > Setup^.MaxPacket[BaudRange]) Then MAXPPACK := Setup^.MaxPacket[BaudRange];
  If (MAXPCONF < 1) Or (MAXPCONF > Setup^.MaxConference) Then MAXPCONF := Setup^.MaxConference;

  If Not Reg Then ProtString := 'XYZ   ';
  If Human^.Protocol = ' ' Then Human^.Protocol := '@';
  If Pos(Human^.Protocol,ProtString)=0 Then Begin If Wait Then ChangeProtocol Else Human^.Protocol := 'Z'; End;
  If Pos(Human^.Archiver,ArcString)=0  Then Begin If Wait Then ChangeArchiver Else Human^.Archiver := 'Z'; End;

  If {(Baud=0) And }(Human^.LocalName<>'') Then Setup^.BoardID := Human^.LocalName;
  If Human^.PacketType = 2 Then Human^.PacketType := 0; {QWK2}
  DayToDate(PresentDay,Temp);
  If Temp <> Human^.LastDateDownload Then
    Begin
      Human^.TodayDownloads := 0;
      Human^.TodayFileDownloads := 0;
    End;
End;

Function VacationLoadUser(Var Ok: Boolean): Boolean;
Var
  fUSRDAT: File;
  Found: Boolean;
  C_Username: Array[1..40] Of Char;
Begin
  Found := False;
  Ok    := False;
  If OpenFile(fUSRDAT,DataDir+'USERS.DAT','R',SIZE_USERS,faReadWrite+faDenyWrite) Then
    Begin
      If VacationPointer<FileSize(fUSRDAT) Then
        Begin
          Seek(fUSRDAT,VacationPointer);
          Repeat
            FillChar(Human^,Sizeof(Human^),0);
            BlockRead(fUSRDAT,Human^,1);
            If Human^.VacationMode Then Found := True;
            Inc(VacationPointer);
          Until Found Or Eof(fUSRDAT);
        End;
      CloseFile(fUSRDAT);
    End;

  If Found Then
    Begin
      Ok := LoadLocalUser('*'+Human^.Name);
      CString(C_Username,DowncaseStr(User.Name));
      Username_CRC := Crc32(C_Username,LenBuf(C_Username),$FFFFFFFF);
      Name         := UpcaseStr(User.Name);
      Alias        := UpcaseStr(User.Handle); If Alias = '' Then Alias := Name;
    End;
  VacationLoadUser := Found;
End;

Procedure SaveUser;
Var
  fUSR: File;
Begin
  If Not UserLoaded Then Exit;
  If Not OpenFile(fUSR,DataDir+'USERS.DAT','R',SIZE_USERS,faReadWrite+faDenyWrite) Then
    Begin
      Logit('C','<!> Could not update user record.');
      Exit;
    End;
  Seek(fUSR,UserIndex);
  BlockWrite(fUSR,Human^,1);
  CloseFile(fUSR);
End;


Procedure CreatePacket;
Var
  QHDR: QWKTXTrecord;
  Ok: Boolean;
  Count: Word;
Begin
  For Count := 1 To 15 Do
    Begin
      Human^.Keywords[Count] := UpcaseStr(Human^.Keywords[Count]);
      Human^.Filters[Count]  := UpcaseStr(Human^.Filters[Count]);
      Human^.Twits[Count]    := UpcaseStr(Human^.Twits[Count]);
    End;

  If Not BlueWave Then
    Begin
      Ok := OpenFile(fQWKM,'MESSAGES.DAT','W',Sizeof(QWKTXTrecord),faReadWrite+faDenyAll);
      If Ok Then
        Begin
          StrBuf(ProgramName+' - Copyrighted Peter Rocca, 1994-98',QHDR,128);  (* Header block *)
          BlockWrite(fQWKM,QHDR,1);
        End;
    End
  Else
    Begin
      Ok := OpenFile(fDAT,Setup^.BoardID+'.DAT','W',1,faReadWrite+faDenyAll);
      If Ok Then Ok := OpenFile(fFTI,Setup^.BoardID+'.FTI','W',Sizeof(FTI_RECORD),faReadWrite+faDenyAll);
    End;

  If Not Ok Then
    Begin
      WriteStringCF(' '+LANG(L_FatalWrite)+', '+LANG(L_Inform));
      Logit('C','<!> Fatal write error; disk full?');
      Sleep(3);
      ExitProc := ErrorExitProc;
      EndDoorMaker;
    End;

  InDownloadingPacket := True;
  FillChar(PackedMessage,Sizeof(PackedMessage),0);
End;

Procedure ClosePacket;
Var
  dNET: QWKTXTRecord;
  dINFH: INF_HEADER;
  dINF: INF_RECORD;
  txt, fCNF: Text;
  fINF, fPTR: File;
  Conf, Position, Count: Word;
  Loop: Byte;
  Check: String[8];
  DateTemp, TimeTemp: String[12];
  Temp: String[100];
  AnyNet, Ok: Boolean;
  DirInfo: SearchRec;
  dCFG: MESSAGErecord;
Begin

  ControlInit;

  If OpenFile(fPTR,'POINTERS.DAT','W',1,faReadWrite+faDenyAll) Then
    Begin
      Check := 'OLMS200'+#26;
      BlockWrite(fPTR,Check,Sizeof(Check));
      BlockWrite(fPTR,Setup^.BoardID,Sizeof(Setup^.BoardId));
      BlockWrite(fPTR,JamLastReads^,Sizeof(JamLastReads^));
      BlockWrite(fPTR,LastReads,Sizeof(LastReads));
      BlockWrite(fPTR,Check,Sizeof(Check));
      CloseFile(fPTR);
    End;

  If Human^.News Then BufferedCopyFile(Setup^.NewsFile,'NEWS');
  If (Setup^.Screens=2) Or ((Setup^.Screens=1) And Human^.GetWelcome) Then
    Begin
      BufferedCopyFile(Setup^.HelloFile,'WELCOME');
      BufferedCopyFile(Setup^.GoodbyeFile,'GOODBYE');
    End;

  If Not Reg And OpenText(txt,'BLT-1.20','W',faReadWrite+faDenyAll) Then
    Begin
      Writeln(txt,'');
      Writeln(txt,'Thank you for using OLMS, the offline mail system.');
      Writeln(txt,'');
      Writeln(txt,Setup^.Sysop+' is currently evaluating this unregistered version.');
      Writeln(txt,'Please encourage the registration of this program if you enjoy it.');
      Writeln(txt,'');
      Writeln(txt,'Thank you');
      Writeln(txt,'');
      Writeln(txt,'Peter Rocca');
      CloseText(txt);
    End;

  For Count := 1 To MaxBull Do
    If GetBulletin(Count) Then
      Begin
        BufferedCopyFile(Setup^.Bulletins[Count],'BLT-1.'+ZeroPad(Count,0));
        If Human^.PacketType = ptQWKE Then AppendFile('TOREADER.EXT','BULL BLT-1.'+ZeroPad(Count,0)+' '
                                                                    +Setup^.BulletinNames[Count]);
      End;

  Count := 0;
  FindFirst(MainDir+'*.(N)',255,DirInfo);
  While DosError=0 Do
    Begin
      If IsNew(MainDir+DirInfo.Name) Then
        Begin
          Inc(Count);
          BufferedCopyFile(MainDir+DirInfo.Name,'BLT-2.'+ZeroPad(Count,0));
          If Human^.PacketType = ptQWKE Then AppendFile('TOREADER.EXT','BULL BLT-2.'+ZeroPad(Count,0)+' '+LANG(L_NewBull));
        End;
      FindNext(DirInfo);
    End;

  If Not BlueWave Then
   Begin
    AnyNet := False;
    For Count := HighConf DIV Sizeof(QWKTXTrecord) Downto 0 Do
      Begin
        FillChar(dNET,Sizeof(QWKTXTrecord),0);
        For Loop := 1 To Sizeof(QWKTXTrecord) Do
          If Is(Human^.Flags[Loop+Count*Sizeof(QWKTXTrecord)],fNETWORK) Then
            Begin
              dNET[Loop-1] := #255;
              AnyNet := True;
            End;
        BlockWrite(fQWKM,dNET,1);
      End;
    Ok := CloseFile(fQWKM);
    InDownloadingPacket := False;

    If Ok And AnyNet Then
      Begin
        Ok := OpenFile(fQWKM,'NETFLAGS.DAT','W',Sizeof(QWKTXTrecord),faReadWrite+faDenyAll);
        If Ok Then
          Begin
            For Count := HighConf DIV Sizeof(QWKTXTrecord) Downto 0 Do
              Begin
                FillChar(dNET,Sizeof(QWKTXTrecord),0);
                For Loop := 1 To Sizeof(QWKTXTrecord) Do
                  If Is(Human^.Flags[Loop+Count*Sizeof(QWKTXTrecord)],fNETWORK) Then
                    Begin
                      dNET[Loop-1] := #255;
                    End;
                BlockWrite(fQWKM,dNET,1);
              End;
            Ok := CloseFile(fQWKM);
          End;
      End;

    If Ok And OpenText(fCNF,'DOOR.ID','W',faReadWrite+faDenyAll) Then
      Begin
        Writeln(fCNF,'DOOR = OLMS');
        Writeln(fCNF,'VERSION = '+Version);
        Writeln(fCNF,'SYSTEM = REMOTEACCESS 2.x');
        Writeln(fCNF,'CONTROLNAME = OLMS');
        Writeln(fCNF,'CONTROLTYPE = ADD');
        Writeln(fCNF,'CONTROLTYPE = DROP');
        Writeln(fCNF,'CONTROLTYPE = RESET');
        Writeln(fCNF,'CONTROLTYPE = KEYWORD');
        Writeln(fCNF,'CONTROLTYPE = FILTER');
        Writeln(fCNF,'CONTROLTYPE = TWIT');
        Writeln(fCNF,'CONTROLTYPE = REQUEST');
        If (Human^.PacketType = 1) Then
          Begin
            Writeln(fCNF,'CONTROLTYPE = MAXKEYWORDS ',MaxKeywords);
            Writeln(fCNF,'CONTROLTYPE = MAXFILTERS ',MaxFilters);
            Writeln(fCNF,'CONTROLTYPE = MAXTWITS ',MaxTwits);
            If Setup^.AllowFiles > 0 Then
              Begin
                Writeln(fCNF,'CONTROLTYPE = ALLOWREQUESTS');
                Writeln(fCNF,'CONTROLTYPE = MAXREQUESTS ',Setup^.AllowFiles);
              End;
          End;
        CloseText(fCNF);
      End
    Else Ok := False;

    If Ok And (Human^.PacketType = 1) And OpenText(fCNF,'TOREADER.EXT','X',faReadWrite+faDenyAll) Then
      Begin
        Writeln(fCNF,'ALIAS '+Alias);
        For Position := 1 To NumConf Do
          Begin
            Conf := ConferenceNumber(Position);
            ControlInfo(Conf,Position,dCFG);
            If VisableArea(dCFG,Conf)
            And (Not Human^.ShortList Or Selected(Conf) Or Is(PackedMessage[Conf DIV 8],1 Shl (Conf MOD 8)))
            Then
              Begin
                Temp := ReturnFlags(Human^.Flags[Conf],Conf) + ReturnSettings(Conf,dCFG);
                While Pos('.',Temp) > 0 Do Temp := Copy(Temp,1,Pos('.',Temp)-1) + Copy(Temp,Pos('.',Temp)+1,255);
                Writeln(fCNF,'AREA '+ZeroPad(Conf,0)+' '+Temp);
              End;
          End;
        For Count := 1 To MaxKeywords Do If Human^.Keywords[Count] <> '' Then Writeln(fCNF,'KEYWORD '+Human^.Keywords[Count]);
        For Count := 1 To MaxFilters Do If Human^.Filters[Count] <> '' Then Writeln(fCNF,'FILTER '+Human^.Filters[Count]);
        For Count := 1 To MaxTwits Do If Human^.Twits[Count] <> '' Then Writeln(fCNF,'TWIT '+Human^.Twits[Count]);
        CloseText(fCNF);
      End;

    If Ok And OpenText(fCNF,'CONTROL.DAT','W',faReadWrite+faDenyAll) Then
      Begin
        Writeln(fCNF,UpcaseStr(Sys.Name));
        Writeln(fCNF,' ');
        Writeln(fCNF,Setup^.PhoneNumber);
        Writeln(fCNF,UpcaseStr(Sys.Sysop)+', Sysop');
        Writeln(fCNF,'00000,'+Setup^.BoardID);
        DayToDate(PresentDay,DateTemp);

        If ValueString(Copy(DateTemp,7,2)) < 40       {!Y2KOK!}
        Then DateTemp := Copy(DateTemp,1,6)+'20'+Copy(DateTemp,7,2)
        Else DateTemp := Copy(DateTemp,1,6)+'19'+Copy(DateTemp,7,2);

        SecondsToTime(PresentSecond,TimeTemp); TimeTemp := TimeTemp + ':00';
        Writeln(fCNF,DateTemp+','+TimeTemp);
        Writeln(fCNF,UpcaseStr(User.Name));
        Writeln(fCNF,' ');
        Writeln(fCNF,'0');
        Writeln(fCNF,PPack);

        Count := 0;
        For Position := 1 To NumConf Do
          Begin
            Conf := ConferenceNumber(Position);
            ControlInfo(Conf,Position,dCFG);
            If VisableArea(dCFG,Conf)
            And (Not Human^.ShortList Or Selected(Conf) Or Is(PackedMessage[Conf DIV 8],1 Shl (Conf MOD 8)))
            Then Inc(Count);
          End;
        Writeln(fCNF,Count-1);

        For Position := 1 To NumConf Do
          Begin
            Conf := ConferenceNumber(Position);
            ControlInfo(Conf,Position,dCFG);
            If VisableArea(dCFG,Conf)
            And (Not Human^.ShortList Or Selected(Conf) Or Is(PackedMessage[Conf DIV 8],1 Shl (Conf MOD 8)))
            Then
              Begin
              Writeln(fCNF,Conf);
              If Human^.PacketType = ptQWKE Then
              Begin
                Writeln(fCNF,dCFG.Name);
              End
              Else
              Begin
              If Not IsInternet(dCFG.Name) And Setup^.CapsWord Then dCFG.Name := CapsWord(dCFG.Name);
              If (Setup^.AutoInternet And IsInternet(dCFG.Name))
              Or (Setup^.ShortStyle=4) Then Writeln(fCNF,SpacePad(InternetStyle(dCFG.Name),13))
              Else If Setup^.ShortStyle=1 Then
                Begin
                  If Setup^.ShortWord
                  Then Writeln(fCNF,SpacePad(FirstWordLetter(dCFG.Name)+'-'+ShortWord(SecondWordString(dCFG.Name)),13))
                  Else Writeln(fCNF,SpacePad(FirstWordLetter(dCFG.Name)+'-'+SecondWordString(dCFG.Name),13))
                End
              Else If Setup^.ShortStyle=2 Then
                Begin
                  If Setup^.ShortWord
                  Then Writeln(fCNF,SpacePad(LastWordLetter(dCFG.Name)+'-'+Copy(ShortWord(dCFG.Name),1,11),13))
                  Else Writeln(fCNF,SpacePad(LastWordLetter(dCFG.Name)+'-'+Copy(dCFG.Name,1,11),13))
                End
              Else
                Begin
                  If Setup^.ShortWord
                  Then Writeln(fCNF,SpacePad(ShortWord(dCFG.Name),13))
                  Else Writeln(fCNF,SpacePad(dCFG.Name,13));
                End;
              End;
            End;
          End;
        Writeln(fCNF,'WELCOME');
        Writeln(fCNF,'NEWS');
        Writeln(fCNF,'GOODBYE');
        CloseText(fCNF);
      End
    Else Ok := False;
   End
  Else (* Is BlueWave *)
   Begin
     Ok := CloseFile(fFTI);
     Ok := CloseFile(fDAT);
     InDownloadingPacket := False;
     If Ok And OpenFile(fINF,Setup^.BoardID+'.INF','W',1,faReadWrite+faDenyAll) Then
       Begin
         FillChar(dINFH,Sizeof(dINFH),0);
         dINFH.Version := BWVERSION;
         CString(dINFH.ReaderFiles[1],'WELCOME');
         CString(dINFH.ReaderFiles[2],'GOODBYE');
         CString(dINFH.ReaderFiles[3],'NEWS');
         CString(dINFH.Name,User.Name);
         CString(dINFH.Alias,User.Handle);
         dINFH.Zone  := Setup^.Address[0].Zone;
         dINFH.Net   := Setup^.Address[0].Net;
         dINFH.Node  := Setup^.Address[0].Node;
         dINFH.Point := Setup^.Address[0].Point;
         CString(dINFH.SysopName,Sys.Sysop);
         CString(dINFH.SystemName,Sys.Name);
         For Count := 1 To 10 Do CString(dINFH.Keywords[Count],Human^.Keywords[Count]);
         For Count := 1 To 10 Do CString(dINFH.Filters[Count],Human^.Filters[Count]);
         If User.Emulation>ASCII    Then dINFH.UserFlags := INF_HOTKEYS + INF_GRAPHICS Else dINFH.UserFlags := INF_HOTKEYS;
         If Human^.NumericExtension Then Inc(dINFH.UserFlags,INF_NUMERICEXT);
         If User.Credits > 65535    Then dINFH.NetmailCredits := 65535 Else dINFH.NetmailCredits := Word(User.Credits);
         If User.Pending > 65535    Then dINFH.NetmailDebits  := 65535 Else dINFH.NetmailDebits  := Word(User.Pending);
         If Human^.Files Then
           Begin
             If Human^.ColorFilelistingInBlueWave=BW_NOCOLOR Then dINFH.FileList := 1 Else dINFH.FileList := 2;
           End;
         dINFH.MaxFreqs        := Setup^.AllowFiles;
         dINFH.Size_INF_HEADER := Sizeof(INF_HEADER);
         dINFH.Size_INF        := Sizeof(INF_RECORD);
         dINFH.Size_MIX        := Sizeof(MIX_RECORD);
         dINFH.Size_FTI        := Sizeof(FTI_RECORD);
         dINFH.UPL_Supported   := True;
         dINFH.CanForward      := True;

         If Setup^.KillSentNetmail              Then Inc(dINFH.NetmailFlags,UPL_NETKILL);
         If User.Security>=Setup^.NetmailCrash  Then Inc(dINFH.NetmailFlags,UPL_NETCRASH);
        {If User.Security>=Setup^.NetmailFatch  Then Inf(dINFH.NetmailFlags,UPL_NETFILE);}
         If User.Security>=Setup^.NetmailHold   Then Inc(dINFH.NetmailFlags,UPL_NETHOLD);
         If User.Security>=Setup^.NetmailImm    Then Inc(dINFH.NetmailFlags,UPL_NETIMMEDIATE);
         If User.Security>=Setup^.NetmailDirect Then Inc(dINFH.NetmailFlags,UPL_NETDIRECT);
         If User.Security>=Setup^.NetmailFreq   Then Inc(dINFH.NetmailFlags,UPL_NETFRQ);

         dINFH.Size_WhoFields  := 35;
         dINFH.Size_Subject    := 71;
         CString(dINFH.BoardID,Setup^.BoardID);
         BlockWrite(fINF,dINFH,Sizeof(dINFH));
         For Position := 1 To NumConf Do
           Begin
            Conf := ConferenceNumber(Position);
            ControlInfo(Conf,Position,dCFG);
             If VisableArea(dCFG,Conf)
             And (Not Human^.ShortList Or Selected(Conf) Or Is(PackedMessage[Conf DIV 8],1 Shl (Conf MOD 8)))
             Then
               Begin
                 CString(dINF.AreaNum,ZeroPad(Position,0)); {CHANGED! BWT}
                 CString(dINF.EchoTag,'AREA'+ZeroPad(Conf,5));
                 CString(dINF.Title,Copy(dCFG.Name,1,48));
                 dINF.AreaFlags   := 0;
                 dINF.NetworkType := INF_NET_FIDONET; { = 0 }

                 Case dCFG.Typ Of
                   LocalMail : ;
                   EchoMail  : dINF.AreaFlags   := INF_ECHOAREA;
                   NetMail   : dINF.AreaFlags   := INF_NETMAILAREA;
                   Internet  : Begin
                                 dINF.NetworkType := INF_NET_QWKNET; (* This is how it does EMAIL *)
                                 dINF.AreaFlags   := INF_NETMAILAREA + INF_ECHOAREA;
                               End;
                   UseGroup  : Begin
                                 dINF.NetworkType := INF_NET_QWKNET; (* This is how it does USEGROUPS *)
                                 dINF.AreaFlags   := INF_ECHOAREA;
                               End;
                 End;

                 If Selected(Conf) Then
                   Begin
                     Inc(dINF.AreaFlags,INF_SELECTED);
                     If (Human^.Flags[Conf] And 1) = 1 Then Inc(dINF.AreaFlags,INF_SELECT_GENE);
                     If (Human^.Flags[Conf] And 2) = 2 Then Inc(dINF.AreaFlags,INF_SELECT_PERS);
                   End;
                 If dCFG.MsgKinds = kPublic  Then Inc(dINF.AreaFlags,INF_NOPRIVATE);
                 If dCFG.MsgKinds = kPrivate Then Inc(dINF.AreaFlags,INF_NOPUBLIC);
                 If Not Is(Setup^.SysopFlags[Conf],sBLOCKED)
                    And (dCFG.MsgKinds <> kReadOnly)   Then Inc(dINF.AreaFlags,INF_POST);
                 If Is(Setup^.SysopFlags[Conf],sNOTAG) Then Inc(dINF.AreaFlags,INF_NOTAGLINE); {CHECK! Took out Not for 2.6}
                 If Is(dCFG.Attribute,32)     Then Inc(dINF.AreaFlags,INF_ALIASNAME)
                 Else If Is(dCFG.Attribute,8) Then Inc(dINF.AreaFlags,INF_ANYNAME);
                 BlockWrite(fINF,dINF,Sizeof(dINF));
               End;
           End;
         CloseFile(fINF);
       End
     Else Ok := False;
   End;

  ControlDone;

  If Not Ok Then
    Begin
      WriteStringCF(' '+LANG(L_FatalWrite)+', '+LANG(L_Inform));
      Logit('C','<!> Fatal write error; disk full?');
      Sleep(3);
      ExitProc := ErrorExitProc;
      EndDoorMaker;
    End;
End;


(**************************************************************************)
(* Main options                                                           *)
(**************************************************************************)
Procedure SelectFlags;
Var
  INGROUP, Amount, Count, Conf: Word;
  Stopped, ALLONE, INCONF: Boolean;
  Temp: String;
  i: Integer;
  Option, Key: Char;
  LinkBack: Array[1..MaxAreas DIV 10] Of Word;
  Includes: Array[0..MaxAreas] Of Boolean;
  SetFlag, LinkLoc, Displayed: Byte;
  RC: Word;
  dCFG: MESSAGErecord;
Begin
  ALLONE := Not Setup^.GroupPick;
  INCONF := ALLONE;
  Fillchar(Includes,Sizeof(Includes),1); (* Setup for display *)
  LinkLoc     := 1;
  LinkBack[1] := 1;

  Repeat

  If User.Emulation > ASCII Then
    Begin
      ClearScreen;
      DoColor(COL_TITLE);
      If INCONF Then WriteStringCF(LANG(L_ConfSel))
      Else WriteStringCF(LANG(L_ConfGrpSel));
      DrawLine; GotoLoc(1,21);
      DrawLine; GotoLoc(1,3);
    End;

  Repeat
    If User.Emulation > ASCII Then GotoLoc(1,3)
    Else
      Begin
        ClearScreen;
        If INCONF Then WriteStringCF(LANG(L_ConfSel))
        Else WriteStringCF(LANG(L_ConfGrpSel));
        DrawLine;
      End;
    Conf := LinkBack[LinkLoc]-1;
    Displayed := 0;
    Stopped := False;
     While Not Stopped Do
    If INCONF And (Conf>=NumConf) Then Stopped := True
    Else If Not INCONF And (Conf>=MaxGroups) Then Stopped := True
    Else If Displayed>=(36 DIV (1 + Byte(Not INCONF))) Then Stopped := True
    Else
     Begin
       Inc(Conf);
       If INCONF Then
         Begin
           {$I-}
           Seek(fCFG,Conf-1);
           BlockRead(fCFG,dCFG,1);
           If RA250 Then RC := dCFG.AreaNum Else RC := Conf;
           If IoResult<> 0 Then RC := 0;
           {$I+}
         End;
       If (INCONF And ((ValidConference(RC)) And VisableArea(dCFG,RC) And
          (ALLONE Or (dCFG.Group=INGROUP)
                  Or (dCFG.AltGroup[1]=INGROUP)
                  Or (dCFG.AltGroup[2]=INGROUP)
                  Or (dCFG.AltGroup[3]=INGROUP)
                  Or ((dCFG.Attribute2 And 1) = 1))))
       Or (Not INCONF And (Conf<=MaxGroups) And Is(Groups[Conf],1) And (GroupNames[Conf]<>'')) Then
        Begin
          Inc(Displayed);
          If INCONF Then
            Begin
              If Not Includes[Conf] And (User.Emulation > ASCII) Then GotoLoc(Displayed MOD 2 * 40 +1,Displayed DIV 2 + 3)
              Else
                Begin
                  DoColor(COL_CONFNUM);  Str(Conf:4,Temp); WriteString(Temp+'  ');
                  DoColor(COL_CONFFLAG); WriteString(ReturnFlags(Human^.Flags[RC],RC));
                  DoColor(COL_CONFNAME); WriteString('  '+SpacePad(dCFG.Name,26));
                  If (Displayed MOD 2) = 0 Then WriteLines(1) Else WriteChar(' ');
                End;
            End
          Else
            Begin
              DoColor(COL_CONFNUM);  Str(Conf:4,Temp); WriteString(Temp+'  ');
              DoColor(COL_CONFFLAG); WriteString('.....');
              DoColor(COL_CONFNAME); WriteStringCF('  '+SpacePad(GroupNames[Conf],40));
            End;
        End;
     End;
    If INCONF Then For Count := Displayed+1 To 36 Do
      Begin
        WriteString('                                       ');
        If (Count MOD 2) = 0 Then WriteLines(1) Else WriteChar(' ');
      End
    Else For Count := Displayed+1 To 18 Do
      Begin
        ClearLine;
        WriteLines(1);
      End;
    If User.Emulation > ASCII Then
      Begin
        GotoLoc(1,22);
      End
    Else DrawLine;
    Repeat
    DoColor(COL_OPTION);
    ClearLine;
    If LinkLoc > 1 Then WriteString(BKT(L_Previous)+', ');
    If (INCONF And (Conf < NumConf)) Or (Not INCONF And (Conf < HighMessageGroup)) Then WriteString(BKT(L_Next)+', ');
    If INCONF Then WriteString(BKT(L_Join)+', '+BKT(L_Drop))
    Else WriteString(BKT(L_Scan));
    WriteString(', '+BKT(L_Help)+', '+BKT(L_Quit)+'.');
    Repeat
      Key := Upcase(Getchar);
      If (Key = HotKey[L_Scan]) Then
      Begin
           If Not INCONF Then
               Begin
                 ClearLine;
                 WriteString(LANG(L_Scan)+': ');
                 Temp := GetString(3,Colors[COL_INPUTFORE],Upper);
                 Val(Temp,Amount,i);
                 ClearLine;
                 If (i <> 0) Or (Amount<0) Or (Amount>HighMessageGroup) Or Not Is(Groups[Amount],1) Or (GroupNames[Amount]='')
                 Then Key := '!'
                 Else
                   Begin
                     Fillchar(Includes,Sizeof(Includes),1);
                     INCONF      := True;
                     INGROUP     := Byte(Amount);
                     LinkLoc     := 1;
                     LinkBack[1] := 1;
                     Key         := HotKey[L_Help];
                   End;
               End
               Else Key := '*';
      End
      Else If Key = HotKey[L_Join] Then
      Begin
           If INCONF Then
             Begin
               ClearLine;
               WriteString(LANG(L_Join)+': ');
               Temp := GetString(60,Colors[COL_INPUTFORE],Upper);
               If ReturnIncludes(Includes,Temp,HighConf) Then
               Begin
               WriteLines(1);
               DoColor(COL_QUESTION);
               WriteString(LANG(L_RecTypeMsgs));
               Repeat
                 Option := Upcase(Getchar);
                 If Option = '?' Then
                   Begin
                     ClearLine;
                     WriteString(LANG(L_ExplainType));
                   End;
               Until Option In [#13,'A','P','G']; ClearLine;
               Case Option Of
                     'G': SetFlag := fGENERAL;
                     'P': SetFlag := fPERSONAL;
                 #13,'A': SetFlag := fALL;
               End;

               WriteString(LANG(L_RecSelf));
               If ExTimedYesNo(HotKey[L_No],1000) = HotKey[L_Yes] Then SetFlag := SetFlag + fSELF;
               ClearLine;

               WriteString(LANG(L_ApplyFilters));
               If ExTimedYesNo(HotKey[L_No],1000) = HotKey[L_Yes] Then SetFlag := SetFlag + fFILTER;
               ClearLine;

               If Not Is(SetFlag,fALL) Or Is(SetFlag,fFILTER) Then
                 Begin
                   WriteString(LANG(L_ApplyKeywords));
                   If ExTimedYesNo(HotKey[L_No],1000) = HotKey[L_Yes] Then SetFlag := SetFlag + fKEYWORD;
                   ClearLine;
                 End;

               WriteString(LANG(L_StartLastRead));
               If ExTimedYesNo(HotKey[L_Yes],1000) = HotKey[L_No] Then
                 Begin
                   ClearLine;
                   WriteString(LANG(L_NumMsgSelArea));
                   Temp := GetString(4,Colors[COL_INPUTFORE],Number);
                   If Temp <> '' Then
                     Begin
                       Val(Temp,Amount,i); ClearLine;
                       WriteString(LANG(L_Resetting));
                       For Count := 1 To NumConf Do
                         Begin
                           If Includes[Count] Then
                             Begin
                               RC := ConferenceNumber(Count);
                               If (RC>0) Then ModifyPointer(RC,Option,Amount);
                             End;
                         End;
                       SaveLastRead;
                     End;
                 End;
               For Count := 1 To NumConf Do
                 Begin
                   If Includes[Count] Then
                     Begin
                       RC := ConferenceNumber(Count);
                       If (RC>0) Then
                         Begin
                           If Is(Human^.Flags[RC],fNETWORK) Then Human^.Flags[RC] := fNETWORK+fCONNECT
                           Else Human^.Flags[RC] := SetFlag;
                         End;
                     End;
                 End;
               ClearLine;
               End
               Else Key := '!';
             End
             Else Key := '*';
        End
        Else If Key = HotKey[L_Drop] Then
        Begin
           If INCONF Then
             Begin
               ClearLine;
               WriteString(LANG(L_Drop)+': ');
               Temp := GetString(60,Colors[COL_INPUTFORE],Upper);
               If ReturnIncludes(Includes,Temp,HighConf) Then
                 Begin
                   For Count := 1 To NumConf Do
                     Begin
                       If Includes[Count] Then
                         Begin
                           RC := ConferenceNumber(Count);
                           If (RC>0) Then Human^.Flags[RC] := (Human^.Flags[RC] And fNETWORK);
                         End;
                     End;
                 End
               Else Key := '!';
             End
             Else Key := '*';
        End
        Else If Key = HotKey[L_Previous] Then
        Begin
              If LinkLoc > 1 Then
               Begin
                 FillChar(Includes,Sizeof(Includes),1);
                 Dec(LinkLoc)
               End Else Key := '*';
        End
        Else If Key = HotKey[L_Next] Then
        Begin
              If (INCONF And (Conf < NumConf)) Or (Not INCONF And (Conf < HighMessageGroup)) Then
               Begin
                 Fillchar(Includes,Sizeof(Includes),1);
                 Inc(LinkLoc);
                 LinkBack[LinkLoc] := Conf+1;
               End Else Key := '*';
        End
        Else If Key = HotKey[L_Help] Then
        Begin
               ClearScreen;
               DisplayTextFile(SearchBack('SELECT.HLP'));
               Fillchar(Includes,Sizeof(Includes),1);
        End
        Else If Key = HotKey[L_Quit] Then
        Begin
             If INCONF And Not ALLONE Then
               Begin
                 INCONF := False;
                 LinkLoc     := 1;
                 LinkBack[1] := 1;
                 Key := HotKey[L_Help];
               End;
        End;
    Until Key In [HotKey[L_Scan],HotKey[L_Help],HotKey[L_Quit],HotKey[L_Next],
                 HotKey[L_Previous],HotKey[L_Join],HotKey[L_Drop],'!'];
    Until Key In [HotKey[L_Scan],HotKey[L_Help],HotKey[L_Quit],HotKey[L_Next],
                 HotKey[L_Previous],HotKey[L_Join],HotKey[L_Drop]];
  Until Key In [HotKey[L_Help],HotKey[L_Quit]];
  Until Key = HotKey[L_Quit];
End;

Procedure SetupFormat;
Begin
  IDXLOC_WAV := 0;
  FTILOC_WAV := 0;
  DATLOC_WAV := 0;

  IDXLOC_QWK := 0;
  IDXCNF_QWK := 0;

  FLAG_BufferFull := False;

  BlueWaveLength := 0;
  If Human^.PacketType = ptBWAVE Then
    Begin
      MAXLEN_SUB := 71;
      MAXLEN_WHO := 35;
      BlueWave := True;
      CR := #13;
    End
  Else
    Begin
      BlueWave := False;
      MAXLEN_SUB := 25;
      MAXLEN_WHO := 25;
      CR := 'ã';
    End;
End;

Function GetAttachedPath(st: String): String;
Var
  s1, s2: String[12];
  p: String[60];
  v1: Word;
  v2: Longint;
  i: Integer;
  dCFG: MESSAGErecord;
Begin
  p := '';
  SplitStrings(st,s1,s2);
  Val(s1,v1,i);
  If i = 0 Then Val(s2,v2,i);
  If i = 0 Then
    Begin
      If ValidConference(v1) Then
        Begin
          Seek(fCFG,ConferenceLocation(v1)-1);
          BlockRead(fCFG,dCFG,1);
          If VisableArea(dCFG,v1) Then
            Begin
              If HasSysopRightsArea(dCFG,v1)
              Then PvtRights := True
              Else PvtRights := False;

              If Is(dCFG.Attribute,cJAM)
              Then p := JAM_GetAttachedPath(dCFG.JamBase,v2)
              Else p := HMB_GetAttachedPath(v1,Word(v2));
            End;
        End;
    End;
  GetAttachedPath := p;
End;

Function GetFiles: Word;
Const
  MaxQueue = 50;
Type
  WhereRec = Record
              C: Word;
              N: Longint;
             End;
Var
  i: Integer;
  s1,s2: String[20];
  ff: SearchRec;
  fL: File;
  dL: LIMITSrecord;
  fC: File;
  dC: FILESrecord;
  fH: File;
  dH: Array[0..19] Of FILESHDRrecord;
  LeftToFind, QueueSize, Count: Byte;
  Result, Loop, Area, HighSec, RatioN, RatioK: Word;
  TempPath: String[40];
  FileQueueNames:     Array[1..MaxQueue] Of String[12];
  FileQueuePaths:     Array[1..MaxQueue] Of String[60];
  FileQueueFound:     Array[1..MaxQueue] Of Boolean;
  FileQueueSize:      Array[1..MaxQueue] Of Longint;
  FileQueueCosts:     Array[1..MaxQueue] Of Word;
  FileQueueAttribute: Array[1..MaxQueue] Of Byte;
  FileQueueWhere:     Array[1..MaxQueue] Of WhereRec;
  KBytesLeft, TotalFilesPacked, TotalFiles, Bytes, TotalBytes, AvailableCredits, Seconds, TotalSeconds: Longint;
Begin
  GetFiles := 0;
  WriteLines(1);
  Bullet(COL_FILES);
  WriteString(LANG(L_ProcFreq));
  SetColor(Colors[COL_SPIN]);

  If Not OpenFile(fC,Setup^.MainPath+'FILES.RA','R',Sizeof(dC),faReadOnly+faDenyNone) Then {EC} Exit;
  If Not OpenFile(fL,Setup^.MainPath+'LIMITS.RA','R',Sizeof(dL),faReadOnly+faDenyNone) Then
    Begin
      {EC}
      CloseFile(fC);
      Exit;
    End;

  RatioN  := 0;
  RatioK  := 0;
  HighSec := 0;
  While Not Eof(fL) Do
    Begin
      BlockRead(fL,dL,1);
      If (User.Security >= dL.Security)
      And (User.Security >= HighSec) Then
        Begin
          RatioN := dL.RatioNum;
          RatioK := dL.RatioK;
          HighSec := dL.Security;
        End;
    End;
  CloseFile(fL);

  LeftToFind := 0;
  QueueSize := 0;
  For Count := 1 To Human^.FilesQueued Do
    Begin
      If Human^.FileQueueAttached[Count] Then
        Begin
          TempPath := GetAttachedPath(Human^.FileQueue[Count]);
          If TempPath <> '' Then
            Begin
              PutTrail(TempPath);
              Findfirst(TempPath+'*.*',Archive,ff);
              While DosError=0 Do
                Begin
                  If QueueSize < MaxQueue Then
                    Begin
                      Inc(QueueSize);
                      FileQueuePaths[QueueSize]     := TempPath;
                      FileQueueNames[QueueSize]     := ff.Name;
                      FileQueueSize [QueueSize]     := ff.Size;
                      FileQueueFound[QueueSize]     := True;
                      FileQueueCosts[QueueSize]     := 0;
                      FileQueueAttribute[QueueSize] := 10;
                      SplitStrings(Human^.FileQueue[Count],s1,s2);
                      Val(s1,FileQueueWhere[QueueSize].C,i);
                      Val(s2,FileQueueWhere[QueueSize].N,i);
                    End;
                  FindNext(ff);
                End;
            End;
        End
      Else
        Begin
          If QueueSize < MaxQueue Then
            Begin
              Inc(QueueSize);
              Inc(LeftToFind);
              FileQueuePaths[QueueSize]     := '';
              FileQueueCosts[QueueSize]     := 0;
              FileQueueFound[QueueSize]     := False;
              FileQueueAttribute[QueueSize] := 0;
              FileQueueNames[QueueSize]     := UpcaseStr(Human^.FileQueue[Count]);
            End;
        End;
    End;

  AvailableCredits  := User.Credits-User.Pending;
  TotalFilesPacked  := 0;
  TotalSeconds := 0;
  TotalFiles   := 0;
  TotalBytes   := 0;
  KBytesLeft   := User.DownloadKLimit - User.TodayDownloadK;
  {$I-}
  Area := 0;
  If LeftToFind>0 Then Logit('D','Searching for files to fill file requests...');
  While Not Eof(fC) And (LeftToFind>0) Do
    Begin
      BlockRead(fC,dC,1);
      If IoResult = 0 Then
      Begin
      If RA250 Then Area := dC.AreaNum Else Inc(Area);
      If  (dC.Name <> '')
      And IsArea(dC.Security,dC.Flags,dC.NotFlags)
      And SeeGroup(dC.Group,dC.AltGroup[1],dC.AltGroup[2],dC.AltGroup[3],dC.Attrib2,2)
      And (UserAge >= dC.Age)
      Then
        If OpenFile(fH,Setup^.FileBasePath+'HDR\FDB'+ZeroPad(Area,0)+'.HDR'
                      ,'R',Sizeof(FILESHDRrecord),faReadOnly+faDenyNone) Then
          Begin
            While Not Eof(fH) Do
              Begin
                Wheel;
                BlockRead(fH,dH,20,Result);
                For Loop := 0 To Result-1 Do
                For Count := 1 To QueueSize Do
                  Begin
                    If UpcaseStr(dH[Loop].Name) = FileQueueNames[Count] Then
                      Begin
                        If Not FileQueueFound[Count] And ((dH[Loop].Attrib And 3) = 0) Then
                          Begin
                            FileQueuePaths[Count] := dC.FilePath;
                            FileQueueFound[Count] := True;
                            FileQueueSize[Count]  := dH[Loop].Size;
                            If dH[Loop].Password <> '' Then FileQueueAttribute[Count] := 1
                            Else If (dH[Loop].Cost>AvailableCredits) And Not User.PostBill Then FileQueueAttribute[Count] := 2
                            Else If Is(dH[Loop].Attrib,8)  Then FileQueueAttribute[Count] := 3
                            Else If Is(dH[Loop].Attrib,32) Then FileQueueAttribute[Count] := 4
                            Else If Is(dH[Loop].Attrib,64) Then FileQueueAttribute[Count] := 5;
                            If Is(dC.Attrib,16) Or Is(dH[Loop].Attrib,4) Then
                              Begin
                                If Is(dH[Loop].Attrib,64) Then FileQueueAttribute[Count] := 7
                                Else FileQueueAttribute[Count] := 6;
                              End;
                            If Not (FileQueueAttribute[Count] In [1..4]) Then
                              Begin
                                Dec(AvailableCredits,FileQueueCosts[Count]);
                              End;
                            Dec(LeftToFind);
                          End;
                      End;
                  End;
              End;
            CloseFile(fH);
          End;
      End;
    End;
  CloseFile(fC);
  {$I+}
  WriteStringCF(#8+' ');
  WriteLines(1);
  For Count := 1 To QueueSize Do
    Begin
      Bullet(COL_TEXT); WriteString(SpacePad(FileQueueNames[Count],14)+'... ');
      DoColor(COL_ERROR);
      If Not FileQueueFound[Count] Then WriteStringCF(LANG(L_NotFound))
      Else
        Begin
          Case FileQueueAttribute[Count] Of
            1: WriteStringCF(LANG(L_Passworded));
            2: WriteStringCF(LANG(L_InfCredits));
            3: WriteStringCF(LANG(L_Unavail));
            4: WriteStringCF(LANG(L_Missing));
          Else
            Begin
              Bytes := FileQueueSize[Count];
              Seconds := EstimateTime(Bytes);
              If (FileQueueAttribute[Count] In [6..7]) Or
                 ((FileQueueAttribute[Count]=10) And Setup^.DownloadAttachFree)
                   Then Bytes := 0;
              If (FileQueueAttribute[Count] In [5,7]) Or
                 ((FileQueueAttribute[Count]=10) And Setup^.DownloadAttachNotime)
                   Then Seconds := 0;
              If (((TotalSeconds+Seconds) DIV 60) > User.TimeLeft)
                   Then WriteStringCF(LANG(L_InfTime))
              Else If (Bytes>0) And Not User.XferPriority And (((TotalBytes+Bytes) DIV 1024) > KBytesLeft)
                   Then WriteStringCF(LANG(L_ExceedDayLimit))
              Else If (Bytes>0) And Not User.XferPriority And
                   ( (RatioK<>0) And ((User.DownloadK+((TotalBytes+Bytes) DIV 1024)) > ((User.UploadK+1)*(RatioK+1)) ) Or
                   ( (RatioN<>0) And ((User.Downloads+TotalFiles) > ((User.Uploads+1)*(RatioN+1)))) )
                   Then WriteStringCF(LANG(L_ExceedRatio))
              Else
                Begin
                  If (TotalFiles+Byte(Bytes>0)+Human^.TodayFileDownloads) > Setup^.AllowFiles Then
                    Begin
                      WriteStringCF(LANG(L_ExceedReqLimit));
                    End
                  Else If PackFile(FileQueuePaths[Count],FileQueueNames[Count]) Then
                    Begin
                      Inc(TotalFilesPacked);
                      Inc(GlobalPendingCredits,FileQueueCosts[Count]);
                      Inc(TotalSeconds,Seconds);
                      Inc(TotalBytes,Bytes);
                      Inc(TotalFiles,Byte(Bytes>0));
                      Logit('E','Requested file: '+FileQueueNames[Count]+' ('+FileQueuePaths[Count]+')');
                      DoColor(COL_GOOD);
                      WriteString(LANG(L_Okay));
                      Str(FileQueueWhere[Count].N,s1);
                      If FileQueueAttribute[Count] = 10
                      Then AppendFile('TOREADER.EXT','ATTACH '+FileQueueNames[Count]+' '
                                                              +ZeroPad(FileQueueWhere[Count].C,0)+' '+s1)
                      Else AppendFile('TOREADER.EXT','FILE '+FileQueueNames[Count]);
                      If FileQueueAttribute[Count] In [5..7] Then WriteStringCF(LANG(L_Free))
                      Else If FileQueueAttribute[Count] = 10 Then WriteStringCF(LANG(L_Attach))
                      Else WriteLines(1);
                    End
                  Else WriteStringCF(LANG(L_NotLocate));
                End;
            End;
          End;
        End;
    End;
  WriteLines(1);
  GlobalPendingBytes := TotalBytes;
  GlobalPendingFiles := TotalFiles;
  GetFiles := TotalFilesPacked;
End;

Function TransmitFile(f: String): Word;
Var
  Ret: Word;
  ps: Byte;
  l: Longint;
Begin
  Writelines(2);
  l := SizeofFile(f);
  DisplayInfo(LANG(L_DownloadSize),lZeroPad(l,0)+' '+LANG(L_Bytes));
  l := EstimateTime(l);
  DisplayInfo(LANG(L_DownloadTime),ZeroPad((l DIV 60),0)+':'+ZeroPad((l MOD 60),2)+LANG(L_MinApprox));
  ps := Pos(Human^.Protocol,ProtString);
  DisplayInfo(LANG(L_TransferType),Setup^.TransmitNames[ps]);
  Writelines(1);

  If Setup^.RestrictTime And ((l DIV 60) > User.TimeLeft) Then
    Begin
      Logit('E','Insufficent time to download packet');
      DoColor(COL_TITLE);
      WriteStringCF(LANG(L_NoTimePkt));
      ClearLine;
      TransmitFile := $FFFF;
      Exit;
    End;

  Bullet(COL_WORK); WriteStringCF(LANG(L_StartRec)+f+LANG(L_Using)+Setup^.TransmitNames[ps]+LANG(L_OrAbort));
  Writelines(1);
  If Baud > 0 Then
    Begin
      Ret := DosShell(typeTransmit,ps,ExpandFileMetaString(Setup^.Transmit[ps],f))
    End
  Else
    Begin
      Logit('E','Copy - '+f);
      Ret := Byte(Not BufferedCopyFile(f,Setup^.LocalDLPath+f));
    End;
  TransmitFile := Ret;
End;

Procedure TransmitGood;
Begin
 Logit('R','Download successful');
 ClearLine;
 Writelines(1);
 WaitSendBufferClear;
 WaitReceiveBufferClear;
 Bullet(COL_GOOD); WriteStringCF(LANG(L_DownSucc));
 Writelines(1);
End;

Function TransmitBadRetry(Ret: Word): Boolean;
Var
  Key: Char;
Begin
  TransmitBadRetry := False;
  Wait := False;
  ClearLine;
  Writelines(1);
  WaitSendBufferClear;
  WaitReceiveBufferClear;
  Sleep(1);
  Logit('R','Download unsuccessful');
  Logit('E','Code - '+ZeroPad(Ret DIV 256,2)+'-'+ZeroPad(Ret MOD 256,2));
  Bullet(COL_ERROR);  WriteStringCF(LANG(L_BadTransfer));
  WriteLines(1);
  Bullet(COL_TOPACK); WriteString(LANG(L_WantAgain));
  Key := TimedYesNo(HotKey[L_Yes],30);
  WriteLines(1);
  If Key = HotKey[L_Yes] Then
    Begin
      Logit('R','Download retry attempt');
      TransmitBadRetry := True;
    End;
End;

Procedure PackPacket;
Label
  DownloadRecovery;
Var
  WeekDay, w, Ret, Position, Conf: Word;
  ps, TodayCount: Byte;
  Temp2, Temp, Flag: String[10];
  PacketExtension: String[10];
  Key: Char;
  l: Longint;
  Error, Logoff: Boolean;
  dCFG: MESSAGErecord;
Begin

  Logit('E','Download requested');

  SetupFormat;
  EraseWorkSpace;
  If Not CreateWorkSpace Then Exit;

  If Not DownloadRequestedOnly Then
  Begin

  ClearScreen;
  CreatePacket;

  PNew             := 0;
  PPack            := 0;
  PPersonal        := 0;
  PKeyword         := 0;
  PFilter          := 0;
  Index            := 2; (* Set to 2 for who knows why, but it works *)
  ReceivedMessages := 0;

  (* Protect *)
  If Reg And (Copy(Setup^.Serial,2,2)='XX') Then Setup^.Serial := 'XXXXXXX';
  If Reg And (Length(Setup^.Serial)<8) And (Baud>0) Then
    Begin
      {!!}
      TruncateFile(DataDir+'OLMS.CFG');
      IgnoreCarrier := False;
      SetColor(14+128);
      WriteLines(1);
      WriteStringCF('  This software was stolen and is being illegally run!');
      WriteLines(1);
      SetColor(7);
      WriteStringCF('  To the sysop who has stolen this package, please consider doing the');
      WriteStringCF('  honourable thing, and register this package legally.  You can overcome');
      WriteStringCF('  the trouble and headaches by helping to support the thousands of hours');
      WriteStringCF('  of work that have been put into OLMS for a mere $20 US');
      WriteLines(1);
      WriteStringCF('  Please note that this is a very light warning, if caught again the');
      WriteStringCF('  results could be tragic to your system.');
      WriteLines(1);
      SetColor(15);
      Write        ('  Press any local key to exit...');
      Readkey;
      Hangup;
    End;

  WatchUserTime := False;

  If Human^.LastDateDownload <> 'None' Then
    Begin
      DoColor(COL_LASTTIME);  WriteString(LANG(L_LastPacket)+Human^.LastDateDownload
                                          +LANG(L_At)+Human^.LastTimeDownload);
    End;
  DoColor(COL_MODE);
  WriteStringCF(SpacePad('',80-Length(LANG(L_DownloadMail))-Wherex)+LANG(L_DownloadMail));
  WriteLines(1);
  DoColor(COL_TITLE);
  WriteStringCF(LANG(L_DownloadTitle));
  DrawLine;

  Error := True;
  MSGBUF := New(PBuf);
  If MSGBUF <> Nil Then
    Begin
      FTIBUF_WAV := New(pFTIBUF_WAV);
      If FTIBUF_WAV <> Nil Then
        Begin
          Error := False;
          DATBUF_WAV := New(pDATBUF_WAV);
          If DATBUF_WAV = Nil
          Then
            Begin
              DATMEM_WAV := 0;
              Logit('D','DEBUG: No memory for 2nd data buffer, using direct writes');
            End
          Else DATMEM_WAV := DATMAX_WAV;
        End
      Else
        Begin
          Dispose(MSGBUF);
        End;
    End;
  If Error Then
    Begin
      WriteLines(2);
      BulletError(LANG(L_NoMemory)+', '+LANG(L_Inform));
      EndDoorMaker;
    End;

  For Position := 1 To NumConf Do
   Begin
    Conf := ConferenceNumber(Position);
    If Selected(Conf) Or Human^.GlobalKeywords Or Human^.GlobalPersonal Then
     Begin
       Seek(fCFG,Position-1);
       BlockRead(fCFG,dCFG,1);

      If HasSysopRightsArea(dCFG,Conf)
      Then PvtRights := True
      Else PvtRights := False;

      Flag := ReturnFlags(Human^.Flags[Conf],Conf);
      If VisableArea(dCFG,Conf) Then
       Begin
       UpdatePackStatus;
       DoColor(COL_CONFNUM);  Str(Position:4,Temp); WriteString(#13+Temp+'  ');
       DoColor(COL_CONFNAME);  WriteString(SpacePad(dCFG.Name,23)+' ');

       If Selected(Conf) Then
         Begin
           DoColor(COL_CONFFLAG);
           WriteString(Flag+'   ');
         End
       Else WriteString('        ');

       DoColor(COL_SPIN);

       CNew         := 0;
       CPack        := 0;
       CPersonal    := 0;
       CKeyword     := 0;
       CFilter      := 0;

       {$IFDEF MESSAGE_JAM}
       If Not Is(dCFG.Attribute,cJAM)
       Then HMB_Scan(Conf,Human^.Flags[Conf])
       Else JAM_Scan(Conf,dCFG.JAMBase,Human^.Flags[Conf]);
       {$ELSE}
       HMB_Scan(Conf,Human^.Flags[Conf]);
       {$ENDIF}

       If CPack > 0 Then
         Begin
           Str(CPack:4,Temp2);
           Str(Conf:4,Temp);
           Logit('E','Packed '+Temp2+' in area '+Temp+' - '+dCFG.Name);
           DoColor(COL_CONFFLAG);
           WriteString(Copy(DM_BackSpaces,1,8)+Flag+'   ');
         End;

       If Selected(Conf) Or (CPack>0) Then
       Begin
         If BlueWave And (CPack>0) Then Write_MIX(Position,CPack,CPersonal,PPack-CPack); {CHANGED! BWT}
         WriteChar(#8);
         DoColor(COL_NEW);   WriteString(ZeroPad(CNew,-5));
         DoColor(COL_HOW);   WriteString(ZeroPad(CKeyword,-9));
                             WriteString(ZeroPad(CFilter,-9));
                             WriteString(ZeroPad(CPersonal,-9));
         DoColor(COL_PACK);  WriteStringCF(ZeroPad(CPack,-9));
       End;

       If (PPack >= MAXPPACK) And Not Human^.IgnoreLimits Then
         Begin
           Position := NumConf;
           ClearLine;
           Bullet(COL_PROMPT); WriteStringCF(LANG(L_MaxMsgReach));
         End
       Else If IsChar Then If Upcase(GetChar) = HotKey[L_Stop] Then
         Begin
           Position := NumConf;
           ClearLine;
           Bullet(COL_PROMPT); WriteStringCF(LANG(L_QuitScan));
         End;
       End;
     End;
   End;

  DrawLine;
  DoColor(COL_TEXT);  WriteString(LANG(L_Totals));
  DoColor(COL_NEW);   WriteString(lZeroPad(PNew,-7));
  DoColor(COL_HOW);   WriteString(lZeroPad(PKeyword,-9));
                      WriteString(lZeroPad(PFilter,-9));
                      WriteString(ZeroPad(Ppersonal,-9));
  DoColor(COL_PACK);  WriteStringCF(ZeroPad(PPack,-9));

  UpdatePackStatus;
  DiskWrite_QWKIndex;
  DiskWrite_MIX;
  DiskWrite_FTI;
  DiskWrite_DAT;
  If CanDispose(DATBUF_WAV) Then Dispose(DATBUF_WAV); MarkDispose(DATBUF_WAV);
  If CanDispose(FTIBUF_WAV) Then Dispose(FTIBUF_WAV); MarkDispose(FTIBUF_WAV);
  If CanDispose(MSGBUF)     Then Dispose(MSGBUF);     MarkDispose(MSGBUF);

  ClosePacket;

  Str(PPack,Temp); Logit('R',Temp+' messages packed');

  If VacationMode Then Logit('C',SpacePad(User.Name,35)+ZeroPad(PPack,-5)+' messages packed');

  WriteLines(2);
  If PPack > 0 Then
    Begin
      If Human^.Files Then
        Begin
          Bullet(COL_FILES); WriteString(LANG(L_ScanFiles));
          DoColor(COL_SPIN);
          Ret := NewFiles;
          If Ret = $FFFF Then WriteStringCF(#8+LANG(L_Aborted))
          Else WriteStringCF(#8+' ');
          Writelines(1);
        End
      Else Ret := 0;
    End
  Else Ret := $FFFF;

  DisplayInfo(LANG(L_NumMsgIns),ZeroPad(PPack,-5));
  If Human^.Files And (Ret < $FF00) Then DisplayInfo(LANG(L_NumNewFiles),ZeroPad(Ret,-5))
  Else Ret := 0;

  WriteLines(1);
  WaitSendBufferClear;

  WatchUserTime := True;
  If PPack+Ret=0 Then
    Begin
      Bullet(COL_NOPACK); WriteStringCF(LANG(L_NoMail));
      WriteLines(1);
      PressSpace;
      LoadLastRead;
      Exit;
    End;
  If User.TimeLeft < 1 Then User.TimeLeft := 2;
  If Wait Then
    Begin
      Bullet(COL_TOPACK); WriteString(LANG(L_WantPacket));
                          Key := ExTimedYesNo(HotKey[L_Yes],45);
      WriteLines(1);
    End
  Else Key := HotKey[L_Yes];
  End (* of NOT DOWNLOAD REQUESTED ONLY *)
  Else Key := HotKey[L_Yes];

  If Key = HotKey[L_No] Then
    Begin
      Logit('R','Download aborted');
      Bullet(COL_TOPACK); WriteString(LANG(L_WantMarked));
                          Key := ExTimedYesNo(HotKey[L_No],1000);
      WriteLines(1);

      If Key = HotKey[L_Yes] Then
        Begin
          SaveLastRead;
          SaveReceived;
          DayToDate(PresentDay,Human^.LastDateDownload);
          SecondsToTime(PresentSecond,Human^.LastTimeDownload);
        End
      Else LoadLastRead;
      WriteLines(1);
      PressSpace;
    End
  Else
    Begin
      If User.TimeLeft < 3 Then User.TimeLeft := 3;
      If BlueWave Then
        Begin
          TodayCount := Human^.TodayDownloads+1;
          If (TodayCount<1) Or (TodayCount>9) Then TodayCount := 1;
          If Not Human^.NumericExtension Then
            Begin
              GetDate(w,w,w,WeekDay);
              PacketExtension := '.'+Copy(WeekString,WeekDay*2+1,2) + ZeroPad(TodayCount,1);
            End
          Else
            Begin
              If Human^.CurrentExtension > 999 Then Human^.CurrentExtension := 1;
              PacketExtension := '.'+ZeroPad(Human^.CurrentExtension,3);
            End;
        End
      Else If VacationMode Or Human^.NumericExtension Then
        Begin
          If Human^.CurrentExtension > 99 Then Human^.CurrentExtension := 1;
          PacketExtension := '.Q'+ ZeroPad(Human^.CurrentExtension,2);
        End
      Else PacketExtension := '.QWK';

      {$IFDEF BBS_FILEREQUEST}
      If DownloadRequestedOnly Then
        Begin
          If GetFiles=0 Then
            Begin
              WriteLines(1);
              PressSpace;
              Exit;
            End;
        End
      Else If DownloadRequested Then GetFiles;
      {$ENDIF}

      If Wait And Setup^.AllowLogoff Then
        Begin
          Bullet(COL_TOPACK); WriteString(LANG(L_LogoffAfter));
                              Key := ExTimedYesNo(HotKey[L_Yes],15);
          If Key = HotKey[L_Yes] Then Logoff := True Else Logoff := False;
        End
      Else Logoff := False;

      Writelines(2);
      Bullet(COL_WORK); WriteString(LANG(L_Compress));

      ps := Pos(Human^.Archiver,ArcString);
      Ret := DosShell(typeCompress,ps,ExpandFileMetaString(Setup^.Compress[ps],Setup^.BoardID+PacketExtension));
      If Ret = 0 Then
        Begin

          KillBut(Setup^.BoardID+PacketExtension);

DownloadRecovery:

          WatchUserTime := False;
          Ret := TransmitFile(Setup^.BoardID+PacketExtension);
          If User.TimeLeft < 2 Then User.TimeLeft := 2;
          WatchUserTime := True;

          If Ret = 0 Then
            Begin
              Human^.LastFileScan   := ReturnPackDate;
              Inc(Human^.CurrentExtension);
              Inc(Human^.TotalDownloads);
              Human^.TodayDownloads := TodayCount;
              Dec(User.Credits,GlobalPendingCredits);
              Inc(Human^.TotalFilesDownloaded,GlobalPendingFiles);
              Inc(Human^.TodayFileDownloads,GlobalPendingFiles);
              Inc(User.Downloads,GlobalPendingFiles);
              Inc(User.DownloadK,(GlobalPendingBytes DIV 1024));
              Inc(User.TodayDownloadK,(GlobalPendingBytes DIV 1024));
              Human^.FilesQueued := 0;
              DayToDate(PresentDay,Human^.LastDateDownload);
              SecondsToTime(PresentSecond,Human^.LastTimeDownload);

              WatchUserTime := False;
              IgnoreCarrier := True;
              TransmitGood;
              If Not DownloadRequestedOnly Then
                Begin
                  Bullet(COL_TITLE); WriteString(LANG(L_Resetting));
                  Savelastread;
                  SaveReceived;
                  ClearLine;
                End;
              IgnoreCarrier := False;
              WatchUserTime := True;

              If Logoff Then AutoLogoff Else
                Begin
                  If Not LessWait Then PressSpace;
                End;
            End
          Else If Ret = $FFFF Then
            Begin
              WriteLines(1);
              If Not LessWait Then PressSpace;
            End
          Else
            Begin
              If TransmitBadRetry(Ret) Then Goto DownloadRecovery;
              If Not DownloadRequestedOnly Then
              Begin
              Bullet(COL_TOPACK); WriteString(LANG(L_WantMarked));
                                  Key := TimedYesNo(HotKey[L_No],60);
              If Key = HotKey[L_Yes] Then
                Begin
                  Human^.LastFileScan := ReturnPackDate;
                  DayToDate(PresentDay,Human^.LastDateDownload);
                  SecondsToTime(PresentSecond,Human^.LastTimeDownload);
                  SaveLastRead;
                  SaveReceived;
                End
              Else
                Begin
                  LoadLastRead;
                End;
              End;
              WriteLines(2);
              PressSpace;
            End;
        End
      Else
        Begin
          Writelines(1);
          Logit('C','<!> Error compressing');
          Logit('E','Code - '+ZeroPad(Ret DIV 256,2)+'-'+ZeroPad(Ret MOD 256,2));
          LoadLastRead;
          BulletError(LANG(L_CompressError)+', '+LANG(L_Inform));
        End;
    End;
End;

Procedure UploadPTR;
Var
  fPTR: File;
  i: Integer;
  Ret: Word;
  Check1, Check2, Who: String[8];
Begin
  ClearScreen;
  EraseWorkSpace;
  If Not CreateWorkSpace Then Exit;

  WriteLines(2);
  Bullet(COL_WORK); WriteStringCF(LANG(L_SendNow)+'POINTERS.DAT'+LANG(L_Using)+
                                  Setup^.TransmitNames[Pos(Human^.Protocol,ProtString)]+LANG(L_OrAbort));
  Writelines(1);
  DisplayStatusShell := True;
  If Baud > 0 Then Ret := Shell(ExpandFileMetaString(Setup^.Receive[Pos(Human^.Protocol,ProtString)],'POINTERS.DAT'))
  Else If BufferedCopyFile(Setup^.LocalULPath+'POINTERS.DAT','POINTERS.DAT') Then Ret := 0
  Else Ret := 1;
  DisplayStatusShell := False;

  ClearLine;
  WriteLines(1);

  If Ret <> 0 Then
    Begin
      BulletError(LANG(L_BadTransfer));
      Exit;
    End;

  Bullet(COL_GOOD); WriteStringCF(LANG(L_GoodTransfer));
  WriteLines(1);

  If Not OpenFile(fPTR,'POINTERS.DAT','R',1,faReadOnly+faDenyWrite) Then {EC} Exit;
  {$I-}
  BlockRead(fPTR,Check1,Sizeof(Check1));
  BlockRead(fPTR,Who,Sizeof(Who));
  BlockRead(fPTR,JamLastReads^,Sizeof(JamLastReads^));
  BlockRead(fPTR,LastReads,Sizeof(LastReads));
  BlockRead(fPTR,Check2,Sizeof(Check2));
  {$I+}
  i := IoResult;
  CloseFile(fPTR);

  If (i<>0) Or (Check1<>'OLMS200'+#26) Or (Check1 <> Check2) Then
    Begin
      BulletError(LANG(L_BadPointers));
      Exit;
    End;

  If (Who<>Setup^.BoardID) Then
    Begin
      BulletError(LANG(L_WrongPointers));
      Exit;
    End;

  For i := 1 To MaxAreas Do
    If JamLastReads^[i] <> -1
      Then JamLastReads^[i] := Abs(JamLastReads^[i]);

  Bullet(COL_WORK); WriteStringCF(LANG(L_Resetting));
  SaveLastRead;
  WriteLines(1);
  PressSpace;
End;

Procedure RemoteMaint(Conf: Word; Mode: Char; Extra: String);
Var
  MaxScan, Count, Last: Byte;
  Temp, OldOne, NewOne: String[50];
  AttachedName, Trade: Boolean;
  Amount, Attr: Word;
  Result: Integer;
Begin
  If Mode = 'G' Then
    Begin
     AttachedName := IsAttachedName(Extra);
     If AttachedName And Not Setup^.AllowDownloadAttach Then
        Begin
          {! Bullet(COL_PROMPT); WriteStringCF('Downloading attached files is not allowed'); !}
        End
      Else If Not AttachedName And (Setup^.AllowFiles=0) Then
        Begin
          {! Bullet(COL_PROMPT); WriteStringCF('File requests are not allowed'); !}
        End
     Else If Human^.FilesQueued >= MaxRequests Then
        Begin
          FLAG_BufferFull := True;
        End
      Else
        Begin
          Inc(Human^.FilesQueued);
          If AttachedName And (Conf>0) And (Pos(' ',Extra)=0) Then Extra := ZeroPad(Conf,0)+' '+Extra;
          Human^.FileQueue[Human^.FilesQueued] := StripLeadAndTrail(Copy(Extra,1,12));
          Human^.FileQueueAttached[Human^.FilesQueued] := AttachedName;
        End;
    End
  Else If Mode = 'A' Then
    Begin
      Human^.Flags[Conf] := Human^.Flags[Conf] And fNETWORK;
      Attr := (Human^.Flags[Conf] And fNETWORK);
      If (Attr = fNETWORK) And (Extra<>'D') Then Attr := Attr + fCONNECT
      Else If Extra = '' Then Attr := Attr + fALL
      Else
        Begin
          If Pos('A',Extra)>0 Then Attr := (Attr And 56) + fALL;
          If Pos('P',Extra)>0 Then Attr := (Attr And 56) + fPERSONAL;
          If Pos('G',Extra)>0 Then Attr := (Attr And 56) + fGENERAL;
          If Pos('W',Extra)>0 Then Attr := Attr Or fSELF;
          If Pos('K',Extra)>0 Then Attr := Attr Or fKEYWORD;
          If Pos('F',Extra)>0 Then Attr := Attr Or fFILTER;
        End;
      Human^.Flags[Conf] := Attr;
    End
  Else If Mode = 'R' Then
    Begin
      Temp := '';
      For Attr := 1 To Length(Extra) Do
      If Extra[Attr] In ['0'..'9'] Then Temp := Temp + Extra[Attr];
      Val(Temp,Amount,Result);
      If Result <> 0 Then Amount := 60000;
      ModifyPointer(Conf,'N',Amount);
      SaveLastRead;
    End
  Else
  Begin
  If Extra[1] = '-' Then
    Begin
      OldOne := Copy(Extra,2,255);
      NewOne := '';
    End
  Else
    Begin
      OldOne := '';
      NewOne := Extra;
    End;

  Trade   := False;
  MaxScan := 0;

  Case Mode Of
    'K': MaxScan := MaxKeywords;
    'F': MaxScan := MaxFilters;
    'T': MaxScan := MaxTwits;
  End;

  For Count := 1 To MaxScan Do
    Begin
      Case Mode Of
        'K': If (Human^.Keywords[Count] = OldOne) Then Trade := True;
        'F': If (Human^.Filters[Count] = OldOne)  Then Trade := True;
        'T': If (Human^.Twits[Count] = OldOne)    Then Trade := True;
      End;
    If Trade Then
      Begin
        Case Mode Of
          'K': Human^.Keywords[Count] := NewOne;
          'F': Human^.Filters[Count] := NewOne;
          'T': Human^.Twits[Count] := NewOne;
        End;
        Count := MaxScan;
      End;
    End;
  End;
End;

Procedure UnpackPacket;
Label
  OLMSCOMMANDTAG;
Var
  fCNF: Text;
  fDUP: File;
  dDUP: Array[1..100] Of Longint;
  MsgTime, MsgDate: String[10];
  PacketExtension: String[5];
  Temp, Temp2, Extra, WhoTo, WhoFrom, Subject, GatewaySubject: String[105];
  Netflags: Integer;
  GatewayFix: Boolean;
  dQWKD: QWKDATrecord;
  dQWKT: QWKTXTrecord;
  dUPLH: UPL_HEADER;
  dUPLR: UPL_REC;
  dPDQH: PDQ_HEADER;
  dPDQR: PDQ_REC;
  dREQR: REQ_REC;
  dCFG: MESSAGErecord;
  TextLen, IC, ConfNum, HMA, HNA, Good, Bad, Blocks, Ref, Count: Word;
  JMA, Crc: Longint;
  IsEmail, WaitIt, Dupe, Ok: Boolean;
  ps, a: Byte;
  Zone: Word;
  Cost, Ret, Net, Node, Pnt: Word;
  i, Result: Integer;
  ArcKind, Kludge: Char;
Begin
  WaitIt := False;
  Logit('E','Upload requested');
  SetupFormat;
  ClearScreen;
  EraseWorkSpace;
  If Not CreateWorkSpace Then Exit;

  WriteLines(2);
  If BlueWave Then PacketExtension := '.NEW' Else PacketExtension := '.REP';
  ps := Pos(Human^.Protocol,ProtString);
  Bullet(COL_WORK); WriteStringCF(LANG(L_SendNow)+Setup^.BoardID+PacketExtension+
                                  LANG(L_Using)+Setup^.TransmitNames[ps]+LANG(L_OrAbort));
  Writelines(1);
  If Baud > 0 Then
    Begin
      Ret := DosShell(typeReceive,ps,ExpandFileMetaString(Setup^.Receive[ps],Setup^.BoardID+PacketExtension))
    End
  Else
    Begin
      Logit('E','Copy - '+Setup^.LocalULPath+Setup^.BoardID+PacketExtension);
      If BufferedCopyFile(Setup^.LocalULPath+Setup^.BoardID+PacketExtension,Setup^.BoardID+PacketExtension)
        Then Ret := 0
        Else Ret := 1;
    End;
  ClearLine;
  WriteLines(1);
  If Ret <> 0 Then
    Begin
      Logit('R','Upload unsuccessful');
      Logit('E','Code - '+ZeroPad(Ret DIV 256,2)+'-'+ZeroPad(Ret MOD 256,2));
      BulletError(LANG(L_BadTransfer));
      Exit;
    End;

  Logit('R','Upload successful');
  Bullet(COL_GOOD); WriteStringCF(LANG(L_GoodTransfer));
  WriteLines(1);
  If Not LessWait Then PressSpace;
  WriteLines(1);
  Bullet(COL_WORK); WriteStringCF(LANG(L_Decompress));
  WriteLines(1);

  ArcKind := DetectArc(Setup^.BoardID+PacketExtension);
  ps := Pos(ArcKind,ArcString);
  Ret := DosShell(typeDecompress,ps,ExpandFileMetaString(Setup^.Decompress[ps],Setup^.BoardID+PacketExtension));
  If Ret <> 0 Then
    Begin
      Logit('R','Error decompressing file');
      Logit('E','Code - '+ZeroPad(Ret DIV 256,2)+'-'+ZeroPad(Ret MOD 256,2));
      BulletError(LANG(L_DecompError));
      Exit;
    End;

  Good := 0;
  Bad := 0;

  If BlueWave
  Then Ok := OpenFile(fQWKM,Setup^.BoardID+'.UPL','R',1,faReadOnly+faDenyWrite)
  Else Ok := OpenFile(fQWKM,Setup^.BoardID+'.MSG','R',Sizeof(QWKDATrecord),faReadOnly+faDenyWrite);

  If Not Ok Then
    Begin
      Logit('R','No messages in packet');
      Bullet(COL_ERROR); WriteStringCF(LANG(L_NoMessage1));
      BulletError(LANG(L_NoMessage2)+PacketFormatString[Human^.PacketType]+LANG(L_NoMessage3));
      Exit;
    End;

  If Not BlueWave Then
    Begin
      BlockRead(fQWKM,dQWKT,1)
    End
  Else
    Begin
      BlockRead(fQWKM,dUPLH,Sizeof(dUPLH));
      Seek(fQWKM,dUPLH.Size_UPL_HEADER);
    End;

  If BlueWave
  Or (Copy(dQWKT,1,Pos(' ',dQWKT)-1) = Setup^.BoardID)
  Or (Copy(dQWKT,1,Pos(' ',dQWKT)-1) = '')
  Then
    Begin
      LastMsgId := $10000000 * User.Node + (PresentDay-(94*372)) * 86400 + PresentSecond;

      MSGBUF := New(PBuf);
      If MSGBUF = Nil Then
        Begin
          CloseFile(fQWKM);
          WriteLines(2);
          BulletError(LANG(L_NoMemory)+', '+LANG(L_Inform));
          Exit;
        End;

      IgnoreCarrier := True;
      ClearScreen;
      DoColor(COL_MODE);  WriteStringCF(SpacePad('',79-Length(LANG(L_UploadMail)))+LANG(L_UploadMail));
      WriteLines(1);
      DoColor(COL_TITLE); WriteStringCF(LANG(L_UploadTitle));
      DrawLine;
      While Not Eof(fQWKM) Do
        Begin
          FillChar(MSGBUF^,TextBufferSize,0);
          If Not BlueWave Then
            Begin
              {$I-}
              BlockRead(fQWKM,dQWKD,1);
              If IoResult<>0 Then Goto OLMSCOMMANDTAG;
              {$I+}
              Blocks := ValueString(dQWKD.Numblocks);
              If Blocks*128 > TextBufferSize Then
                Begin
                  BlockRead(fQWKM,MSGBUF^,TextBufferSize DIV 128 - 1);
                  Seek(fQWKM,Blocks-TextBufferSize DIV 128);
                  Blocks := TextBufferSize DIV 128 - 2;
                End
              Else BlockRead(fQWKM,MSGBUF^,Blocks-1);
              BufStr(dQWKD.WhoTo,WhoTo,25);
              BufStr(dQWKD.Subject,Subject,25);
              BufStr(dQWKD.WhoFrom,WhoFrom,25);
              BufStr(dQWKD.MsgTime,MsgTime,5);
              BufStr(dQWKD.MsgDate,MsgDate,8);
              ConfNum := ValueString(dQWKD.Msgnum);
              Ref := ValueString(dQWKD.MsgRefNum);
            End
          Else (* Is BlueWave *)
            Begin
              BlockRead(fQWKM,dUPLR,Min(Sizeof(dUPLR),dUPLH.Size_UPL),Ret);
              Seek(fQWKM,longint(Filepos(fQWKM))+longint(dUPLH.Size_UPL-Ret));
              WhoFrom := PString(dUPLR.WhoFrom);
              WhoTo   := PString(dUPLR.WhoTo);
              Subject := PString(dUPLR.Subject); If Subject = '' Then Subject := ' ';
              Ref     := Word(dUPLR.ReplyTo);
              If Copy(dUPLR.Echotag,1,4) <>'AREA' Then ConfNum := 65000
              Else Val(Copy(dUPLR.Echotag,5,5),ConfNum,i);
              If i <> 0 Then ConfNum := 65000;

              (* Version 2.20 support *)
              If ((dUPLH.Size_UPL=320) And (PString(dUPLR.EmailAddress)<>'')) Then
                Begin
                  If ValidConference(ConfNum) Then
                    Begin
                      Seek(fCFG,ConferenceLocation(ConfNum)-1);
                      BlockRead(fCFG,dCFG,1);
                      If (dCFG.Typ=Internet) Then Whoto := PString(dUPLR.EmailAddress);
                    End;
                End;

              If OpenFile(fDAT,PString(dUPLR.Filename),'R',1,faReadOnly+faDenyWrite) Then
                Begin
                  TextLen := Word(SizeofFile(PString(dUPLR.Filename)));
                  If TextLen>0 Then BlockRead(fDAT,MSGBUF^,TextLen);
                  CloseFile(fDAT);
                End
              Else TextLen := 0;

              If TextLen = 0 Then
                Begin
                  MSGBUF^[0] := #13;
                  TextLen := 1;
                End;

              Blocks := (TextLen-1) DIV 128 + 2;
            End;

          (* Remove ^0,^Z from uploaded text *)
          For Count := 0 To TextLen Do
            If MSGBUF^[Count] In [#0,#26] Then MSGBUF^[Count] := #32;

          If  ((UpcaseStr(WhoTo) = 'GATEWAY')
          Or  (UpcaseStr(WhoTo) = 'INTERNET')
          Or  (UpcaseStr(WhoTo) = 'UUCP'))
          And (Setup^.GatewayAddress<>'') Then
            Begin
              GatewayFix := True;
              GatewaySubject := Subject;
              WhoTo := 'UUCP';
              Subject := '@'+Setup^.GatewayAddress;
            End
          Else GatewayFix := False;

          While UpcaseStr(Copy(Subject,1,3)) = 'RE:' Do
            Begin
              Subject := StripLeadAndTrail(Copy(Subject,4,255));
            End;

          If (BlueWave And Is(dUPLR.MsgAttr,UPL_NETMAIL))
          Or ((Copy(Subject,1,1)='@') And (Pos(':',Subject) In [3..7])) Then
            Begin  (* this is netmail *)
              If ValidConference(ConfNum) Then
                Begin
                  Seek(fCFG,ConferenceLocation(ConfNum)-1);
                  BlockRead(fCFG,dCFG,1);
                  If (dCFG.Typ=Internet) Then
                    Begin
                      If Is(dUPLR.MsgAttr,UPL_NETMAIL) Then Dec(dUPLR.MsgAttr,UPL_NETMAIL);
                    End
                  Else If (dCFG.Typ<>Netmail) Then
                    Begin
                      If (dCFG.Netreply > 0) And (dCFG.Netreply <= HighConf)
                      Then ConfNum := dCFG.Netreply
                      Else ConfNum := NetmailReplyArea;
                    End;
                End;
            End;

          IC := ConferenceLocation(ConfNum);

          If (UpcaseStr(WhoTo) = 'OLMS')
          Or (UpcaseStr(WhoTo)='QMAIL')
          Or (UpcaseStr(WhoTo)='JC-QWK') Then
            Begin
               Str(IC:4,Temp);
               Logit('E','Maint. in '+Temp+' ('+Subject+')');
               DoColor(COL_CONFNUM);  WriteString(Temp+'  ');
               SplitStrings(UpcaseStr(Subject),Temp,Extra);
               DoColor(COL_CONFNAME); WriteStringCF(LANG(L_RemoteMaint)+Temp);
                    If Temp = 'DROP'    Then Human^.Flags[ConfNum] := Human^.Flags[ConfNum] And fNETWORK
               Else If Temp = 'ADD'     Then RemoteMaint(ConfNum,'A',Extra)
               Else If Temp = 'JOIN'    Then RemoteMaint(ConfNum,'A',Extra)
               Else If Temp = 'RESET'   Then RemoteMaint(ConfNum,'R',Extra)
               Else If Temp = 'KEYWORD' Then RemoteMaint(ConfNum,'K',Extra)
               Else If Temp = 'FILTER'  Then RemoteMaint(ConfNum,'F',Extra)
               Else If Temp = 'TWIT'    Then RemoteMaint(ConfNum,'T',Extra)
               Else If Temp = 'REQUEST' Then RemoteMaint(ConfNum,'G',Extra);
               Goto OLMSCOMMANDTAG;
            End;

          If Setup^.CheckDupes Then
            Begin
              Crc := $FFFFFFFF;
              If Setup^.CheckHeaderDupes Then
                Begin
                  Crc := Crc32(ConfNum,2,Crc);
                  If BlueWave
                  Then Crc := Crc32(dUPLR,Sizeof(UPL_REC),Crc)
                  Else Crc := Crc32(dQWKD,Sizeof(QWKTXTrecord),Crc);
                End;
              Crc := Crc32(MSGBUF^,Sizeof(QWKTXTrecord)*(Blocks-1),Crc);
              If Not FileExists(MainDir+'MESSAGES.DUP') Then CreateFile(MainDir+'MESSAGES.DUP');
              If OpenFile(fDUP,MainDir+'MESSAGES.DUP','R',Sizeof(Longint),faReadOnly+faDenyNone) Then
                Begin
                  Dupe := False;
                  While Not Eof(fDUP) And Not Dupe Do
                    Begin
                      BlockRead(fDUP,dDUP,100,Result);
                      For Count := 1 To Result Do
                        If Crc = dDUP[Count] Then Dupe := True;
                    End;
                  CloseFile(fDUP);
                End;
            End
          Else Dupe := False;

          If Pos('@',WhoTo)=0 Then AutoCap(WhoTo);
          If WhoTo = 'Uucp' Then WhoTo := 'UUCP';

          If (ConfNum < 1) Or (ConfNum > HighConf) Then Dupe := False;

          If Not Dupe Then
            Begin
              DoColor(COL_CONFNUM); WriteString(ZeroPad(IC,-4)+'  ');
              If ValidConference(ConfNum) Then
                Begin
                  Seek(fCFG,ConferenceLocation(ConfNum)-1);
                  BlockRead(fCFG,dCFG,1);
                  If (dCFG.Typ = Netmail) Then
                    Begin
                      Netflags := 0;
                      If Not BlueWave And Not GetAddress(Subject,Zone,Net,Node,Pnt) Then
                        Begin
                          Ok := False;
                          Logit('E','<!> Post denied! Bad netmail address "'+Subject+'"');
                        End
                      Else If BlueWave And (dUPLR.DstZone*dUPLR.DstNet=0) Then
                        Begin
                          Ok := GetAddress(Subject,Zone,Net,Node,Pnt);
                          If Not Ok Then Logit('E','<!> Post denied! Bad netmail address "'
                                                   +ZeroPad(dUPLR.DstZone,0)+':'+ZeroPad(dUPLR.DstNet,0)+
                                                   '/'+ZeroPad(dUPLR.DstNode,0)+'.'+ZeroPad(dUPLR.DstPoint,0)+'"');
                        End
                      Else If BlueWave Then
                        Begin
                          Ok   := True;
                          Zone := dUPLR.DstZone;
                          Net  := dUPLR.DstNet;
                          Node := dUPLR.DstNode;
                          Pnt  := dUPLR.DstPoint;
                          If Is(dUPLR.NetAttr,UPL_NETCRASH)     Then NetFlags := NetFlags Or nCRASH;
                          If Is(dUPLR.NetAttr,UPL_NETHOLD)      Then NetFlags := NetFlags Or nHOLD;
                          If Is(dUPLR.NetAttr,UPL_NETIMMEDIATE) Then NetFlags := NetFlags Or nIMM;
                          If Is(dUPLR.NetAttr,UPL_NETFRQ)       Then NetFlags := NetFlags Or nFREQ;
                          If Is(dUPLR.NetAttr,UPL_NETDIRECT)    Then NetFlags := NetFlags Or nDIRECT;
                          If Is(dUPLR.NetAttr,UPL_NETFILE)      Then NetFlags := NetFlags Or nFATCH;
                        End
                      Else Ok := True;

                      (* Get more flag info if on the subject line *)
                      If Subject[1]='@' Then
                        Begin
                          SplitStrings(Subject,Temp,Temp2);
                          Temp2 := ' '+UpcaseStr(Temp2);
                          If Pos(' C',Temp2)>0 Then NetFlags := NetFlags Or nCRASH;
                          If Pos(' H',Temp2)>0 Then NetFlags := NetFlags Or nHOLD;
                          If Pos(' I',Temp2)>0 Then NetFlags := NetFlags Or nIMM;
                          If Pos(' R',Temp2)>0 Then NetFlags := NetFlags Or nFREQ;
                          If Pos(' D',Temp2)>0 Then NetFlags := NetFlags Or nDIRECT;
                          If Pos(' F',Temp2)>0 Then NetFlags := NetFlags Or nFATCH;
                          If Pos(' Q',Temp2)>0 Then NetFlags := NetFlags Or nRRQ;
                        End;

                      (* Determine if we have access to the flags we asked for *)
                      If Is(NetFlags,nCRASH)  And (User.Security<Setup^.NetmailCrash)  Then Dec(NetFlags,nCRASH);
                      If Is(NetFlags,nHOLD)   And (User.Security<Setup^.NetmailHold)   Then Dec(NetFlags,nHOLD);
                      If Is(NetFlags,nIMM)    And (User.Security<Setup^.NetmailImm)    Then Dec(NetFlags,nIMM);
                      If Is(NetFlags,nFREQ)   And (User.Security<Setup^.NetmailFreq)   Then Dec(NetFlags,nFREQ);
                      If Is(NetFlags,nDIRECT) And (User.Security<Setup^.NetmailDirect) Then Dec(NetFlags,nDIRECT);
                      If Is(NetFlags,nFATCH)  And (User.Security<Setup^.NetmailFatch)  Then Dec(NetFlags,nFATCH);
                    End
                  Else Ok := True;

                  If (dCFG.Typ=EchoMail) And (WhoTo='Sysop') Then WhoTo := Setup^.Sysop;

                  If (dCFG.Typ = Netmail) Then Cost := NodeCost(Setup^.NodelistPath,Zone,Net,Node)
                  Else Cost := 0;

                  If Not Ok Or ((Cost>0) And (Cost>(User.Credits-User.Pending)) And Not User.PostBill) Then
                    Begin
                      DoColor(COL_CONFNAME);  WriteString(SpacePad(dCFG.Name,23)+'  ');
                      DoColor(COL_REPTO);     WriteString(SpacePad(WhoTo,20)+'  ');
                      DoColor(COL_ERROR);
                      If Not Ok Then WriteStringCF(LANG(L_BadNetAdr))
                      Else
                        Begin
                          WriteStringCF(LANG(L_InfCredits));
                          Logit('E','<!> Post denied! Insufficent credits');
                        End;
                      Inc(Bad);
                    End
                  Else If BlueWave And Is(dUPLR.MsgAttr,UPL_INACTIVE) Then
                    Begin
                    End
                  Else If WritableArea(dCFG,ConfNum) Then
                    Begin
                      If Is(Human^.Flags[ConfNum],fNETWORK) Then
                      Else If Is(dCFG.Attribute,cHANDLE) Then WhoFrom := User.Handle
                      Else If Is(dCFG.Attribute,cALIAS) Then
                      Else WhoFrom := User.Name;

                      AutoCap(WhoFrom);

                      TextLen := InsertTearLine(ConfNum,(Blocks-1)*Sizeof(dQWKT)-1,
                                                dCFG.Typ,dCFG.Attribute,dCFG.OriginLine,
                                                Setup^.Address[dCFG.AkaAddress].Zone,
                                                Setup^.Address[dCFG.AkaAddress].Net,
                                                Setup^.Address[dCFG.AkaAddress].Node,
                                                Setup^.Address[dCFG.AkaAddress].Point);

                      Kludge := #0;
                      While RemoveKludges(Kludge,Temp,TextLen,ConfNum) Do
                        Begin
                          Case Kludge Of
                            'S': Subject := Temp;
                            'T': WhoTo := Temp;
                          End;
                        End;

                      If(Kludge<>#0) Then
                        Begin
                          Dec(TextLen);
                          If(MSGBUF^[0] In [CR,#13]) Then Move(MSGBUF^[1],MSGBUF^[0],TextLen);
                        End;

                      If GatewayFix Then Subject := GatewaySubject;
                      Extra := Subject;

                      If dCFG.Typ = Netmail Then
                        Begin
                          If (User.Emulation = ASCII) Or Not Human^.UseHigh Then Subject := 'n)'+Subject
                          Else Subject := 'ü ' + Subject;
                        End;

                      DoColor(COL_CONFNAME); WriteString(SpacePad(dCFG.Name,23)+'  ');
                      DoColor(COL_REPTO);    WriteString(SpacePad(WhoTo,20)+'  ');
                                             WriteString(SpacePad(Subject,23)+' ');

                      Subject    := Extra;
                      HNA        := 0;
                      HMA        := HMB_LOCAL;
                      JMA        := MSG_LOCAL;
                      IsEmail    := False;

                      If dCFG.Typ = Netmail Then
                        Begin
                          HMA := HMA Or HMB_NETMAIL Or HMB_UNETMAIL;
                          JMA := JMA Or MSG_TYPENET;
                          If Setup^.KillSentNetmail Then
                            Begin
                              HNA := HNA Or HMB_KILL;
                              JMA := JMA Or MSG_KILLSENT;
                            End;

                          (* Add bits to Hudson/JAM fields *)
                          If Is(NetFlags,nCRASH)  Then Begin JMA := JMA Or MSG_CRASH;       HNA := HNA Or HMB_CRASH;  End;
                          If Is(NetFlags,nHOLD)   Then Begin JMA := JMA Or MSG_HOLD;       {HNA := HNA Or HMB_HOLD;  }End;
                          If Is(NetFlags,nIMM)    Then Begin JMA := JMA Or MSG_IMMEDIATE;  {HNA := HNA Or HMB_IMM;   }End;
                          If Is(NetFlags,nFREQ)   Then Begin JMA := JMA Or MSG_FILEREQUEST; HNA := HNA Or HMB_FREQ;   End;
                          If Is(NetFlags,nDIRECT) Then Begin JMA := JMA Or MSG_DIRECT;     {HNA := HNA Or HMB_DIRECT;}End;
                          If Is(NetFlags,nFATCH)  Then Begin{JMA := JMA Or MSG_FILEATTACH;}{HNA := HNA Or HMB_FATCH; }End;
                          If Is(NetFlags,nDIRECT) Then Begin JMA := JMA Or MSG_DIRECT;     {HNA := HNA Or HMB_DIRECT;}End;
                          If Is(NetFlags,nRRQ)    Then Begin JMA := JMA Or MSG_RECEIPTREQ; {HNA := HNA Or HMB_DIRECT;}End;
                        End
                      Else If dCFG.Typ = Echomail Then
                        Begin
                          JMA := JMA Or MSG_TYPEECHO;
                          HMA := HMA Or HMB_UECHOMAIL;
                        End
                      Else If dCFG.Typ  = Internet Then
                        Begin
                          IsEmail := True;
                          JMA := JMA Or MSG_TYPELOCAL;
                        End
                      Else If dCFG.Typ  = Usegroup Then
                        Begin
                          IsEmail := True;
                          JMA := JMA Or MSG_TYPELOCAL;
                          WhoTo := ' ';
                        End
                      Else
                        Begin
                          JMA := JMA Or MSG_TYPELOCAL;
                        End;

                      Case dCFG.MsgKinds Of
                       kPrivate: Begin
                                   HMA := HMA Or HMB_PRIVATE;
                                   JMA := JMA Or MSG_PRIVATE;
                                 End;
                        kPublic: Begin
                                 End;
                          kBoth: If (BlueWave And Is(dUPLR.MsgAttr,UPL_PRIVATE))
                                 Or (Not BlueWave And (dQWKD.Status In ['*','+']))
                                 Then
                                   Begin
                                     HMA := HMA Or HMB_PRIVATE;
                                     JMA := JMA Or MSG_PRIVATE;
                                   End;
                      End;

                      If Is(HMA,HMB_PRIVATE) Then
                        Begin
                          DoColor(COL_PRIVATE);
                          If (User.Emulation = ASCII) Or Not Human^.UseHigh Then WriteStringCF('p')
                          Else WriteStringCF('ž');
                        End
                      Else WriteLines(1);

                      OrgAdrStr := ZeroPad(Setup^.Address[dCFG.AkaAddress].Zone,0)+':'+
                                   ZeroPad(Setup^.Address[dCFG.AkaAddress].Net,0)+'/'+
                                   ZeroPad(Setup^.Address[dCFG.AkaAddress].Node,0)+'.'+
                                   ZeroPad(Setup^.Address[dCFG.AkaAddress].Point,0);

                      IdleMinutes := 0;

                      {$IFDEF MESSAGE_JAM}
                      If Is(dCFG.Attribute,cJAM)
                      Then
                      Ok := JAM_Post(WhoTo,WhoFrom,Subject,MsgTime,MsgDate,Ref,ConfNum,
                                     dCFG.JamBase,JMA,Zone,Net,Node,Pnt,Cost,TextLen,IsEmail)
                      Else
                      {$ENDIF}
                      Ok := HMB_Post(WhoTo,WhoFrom,Subject,MsgTime,MsgDate,Ref,ConfNum,
                                     TextLen,HMA,HNA,Zone,Net,Node,Pnt,Cost);

                      If Ok Then
                        Begin
                          If OpenFile(fDUP,MainDir+'MESSAGES.DUP','R',Sizeof(Longint),faReadWrite+faDenyWrite) Then
                            Begin
                              Seek(fDUP,FileSize(fDUP));
                              BlockWrite(fDUP,Crc,Sizeof(Crc));
                              CloseFile(fDUP);
                            End;
                          Subject := '';
                          If dCFG.Typ = Echomail Then User.EchomailEntered := True
                          Else if dCFG.Typ = Netmail Then
                            Begin
                              User.NetmailEntered := True;
                              Inc(User.Pending,Cost);
                              Subject := ' -> '+Zeropad(Zone,0)+':'+Zeropad(Net,0)+'/'+
                                                ZeroPad(Node,0)+'.'+Zeropad(Pnt,0)+', '+
                                                Zeropad(Cost,0)+'›';
                            End;
                          Logit('R','Posted in '+ZeroPad(IC,-4)+' - '+dCFG.Name+Subject);
                          Inc(Good);
                        End
                      Else
                        Begin
                          DoColor(COL_ERROR);
                          WriteStringCF(' '+LANG(L_MessageError)+', '+LANG(L_Inform));
                          Logit('C','<!> Could not post message');
                          Inc(Bad);
                        End;
                    End
                  Else
                    Begin
                      DoColor(COL_ERROR);
                      If dCFG.Name = '' Then
                        Begin
                          WriteStringCF(LANG(L_InvalidArea));
                          Logit('E','<!> Post denied! Invalid area #'+ZeroPad(IC,1));
                        End
                      Else
                        Begin
                          WriteStringCF(LANG(L_WriteDeny));
                          Logit('E','<!> Post denied! Restricted area #'+ZeroPad(IC,1));
                        End;
                      Inc(Bad);
                    End;
                End
              Else
                Begin
                  DoColor(COL_ERROR); WriteStringCF(LANG(L_InvalidArea));
                  Logit('E','<!> Post denied! Out of range area #'+ZeroPad(ConfNum,1)+'/'+ZeroPad(HighConf,1));
                  Inc(Bad);
                End;
            End
          Else
            Begin
              Seek(fCFG,IC-1);
              BlockRead(fCFG,dCFG,1);
              DoColor(COL_CONFNUM);  WriteString(ZeroPad(IC,-4)+'  ');
              DoColor(COL_CONFNAME); WriteString(SpacePad(dCFG.Name,23)+'  ');
              DoColor(COL_REPTO);    WriteString(SpacePad(WhoTo,20)+'  ');
              DoColor(COL_ERROR);    WriteStringCF(LANG(L_Duplicate));
              Inc(Bad);
            End;

OLMSCOMMANDTAG:

        End;
      If CanDispose(MSGBUF) Then Dispose(MSGBUF); MarkDispose(MSGBUF);
      DrawLine;
      WriteLines(1);
      User.Posts := User.Posts + Good;
      Logit('R','Posted '+ZeroPad(Good,0)+' messages');
      DisplayInfo(LANG(L_MsgIns),ZeroPad(Good,-7));
      DisplayInfo(LANG(L_MsgDeny),ZeroPad(Bad,-7));
      Writelines(1);
      If Setup^.KillRep And (Baud=0) And (Bad=0) Then KillFile(Setup^.LocalULPath+Setup^.BoardID+PacketExtension);
      WaitIt := True;
    End
  Else
    Begin
      Logit('E','Packet marked for "'+Copy(dQWKT,1,Pos(' ',dQWKT)-1)+'"');
      Bullet(COL_ERROR); WriteStringCF(LANG(L_WrongPlace1));
      Bullet(COL_ERROR); WriteStringCF(LANG(L_WrongPlace2)+Copy(dQWKT,1,Pos(' ',dQWKT)-1)+LANG(L_WrongPlace3));
      WriteLines(1);
      WaitIt := True;
    End;
  CloseFile(fQWKM);

  If BlueWave And OpenFile(fQWKM,Setup^.BoardID+'.PDQ','R',1,faReadOnly+faDenyWrite) Then
    Begin
      Logit('E','BlueWave r2 - offline configuration performed');
      BlockRead(fQWKM,dPDQH,Sizeof(dPDQH));
      Fillchar(Human^.Filters,Sizeof(Human^.Filters),0);
      Fillchar(Human^.Keywords,Sizeof(Human^.Keywords),0);
      For Ret := 1 To 10 Do
        Begin
          Human^.Keywords[Ret] := PString(dPDQH.Keywords[Ret]);
          Human^.Filters[Ret]  := PString(dPDQH.Filters[Ret]);
        End;
      If Not Eof(fQWKM) Then Fillchar(Human^.Flags,Sizeof(Human^.Flags),0);
      While Not Eof(fQWKM) Do
        Begin
          BlockRead(fQWKM,dPDQR,Sizeof(dPDQR));
          Ret := ValueString(Copy(PString(dPDQR.EchoTag),5,5));
          If (Ret>0) And (Ret<=HighConf) Then Human^.Flags[Ret] := fALL + fSELF * Byte(Not Is(dPDQH.Flags,INF_NOT_MY_MAIL));
        End;
      CloseFile(fQWKM);
    End;

   If BlueWave And OpenFile(fQWKM,Setup^.BoardID+'.REQ','R',1,faReadOnly+faDenyWrite) Then
     Begin
       While Not Eof(fQWKM) Do
         Begin
           BlockRead(fQWKM,dREQR,Sizeof(dREQR));
           RemoteMaint(0,'G',PString(dREQR.FileName));
         End;
       CloseFile(fQWKM);
     End;

  If BlueWave And OpenText(fCNF,Setup^.BoardID+'.OLC','R',faReadOnly+faDenyWrite) Then
    Begin
      Logit('E','BlueWave r3 - offline configuration performed');
      Fillchar(Human^.Filters,Sizeof(Human^.Filters),0);
      Fillchar(Human^.Keywords,Sizeof(Human^.Keywords),0);
      Good := 0;     (* Keywords *)
      Bad  := 0;     (* Filters  *)
      Ok   := False; (* Get mail from self *)
      While Not Eof(fCNF) Do
        Begin
          Readln(fCNF,Temp);
          Extra := '**';
          SplitStrings(Temp,Temp,Temp2);
          SplitStrings(Temp2,Temp2,Extra);
          Temp := UpcaseStr(Temp);
          If Copy(Temp,1,5)='[AREA' Then Ret := wValue(Copy(Temp,6,5))
          Else If (Temp = 'AREACHANGES') And (Extra='ON') Then Fillchar(Human^.Flags,Sizeof(Human^.Flags),0)
          Else If (Temp = 'NUMERICEXTENSIONS') Then Human^.NumericExtension := (Extra[2]='N')
          Else If (Temp = 'SKIPUSERMSGS') Then Ok := (Extra[2]='F')
          Else If (Temp = 'KEYWORD') And (Good<MaxKeywords) Then Begin Inc(Good); Human^.Keywords[Good] := Extra; End
          Else If (Temp = 'FILTER')  And (Bad<MaxFilters)   Then Begin Inc(Bad);  Human^.Filters[Bad]   := Extra; End
          Else If (Temp = 'NEWFILELIST') Then
            Begin
              If Extra='OFF'  Then Human^.Files := False Else Human^.Files := True;
              If Extra='TEXT' Then Human^.ColorFilelistingInBlueWave := BW_NOCOLOR Else Human^.ColorFilelistingInBluewave := 0;
            End
          Else If Temp = 'SCAN' Then
            Begin
              If (Ret > 0) And (Ret<=MaxAreas) Then
                Begin
                  If Extra = 'ALL'      Then Human^.Flags[Ret] := fALL;
                  If Extra = 'PERSONLY' Then Human^.Flags[Ret] := fPERSONAL;
                  If Extra = 'PERS+ALL' Then Human^.Flags[Ret] := fGENERAL;
                  If Ok Then Inc(Human^.Flags[Ret],fSELF);
                End;
            End;
        End;
      CloseText(fCNF);
    End;

  If (Human^.PacketType=1) And OpenText(fCNF,'TODOOR.EXT','R',faReadOnly+faDenyWrite) Then
    Begin
      Logit('E','QWKE offline configuration performed');
      While Not Eof(fCNF) Do
        Begin
          Readln(fCNF,Temp);
          SplitStrings(UpcaseStr(Temp),Temp,Extra);
          If (Temp = 'AREA') Or (Temp = 'RESET') Then
            Begin
              SplitStrings(Extra,WhoTo,Extra);
              Val(WhoTo,Ret,Result);
            End;
               If Temp = 'AREA'    Then RemoteMaint(Ret,'A',Extra)
          Else If Temp = 'RESET'   Then RemoteMaint(Ret,'R',Extra)
          Else If Temp = 'KEYWORD' Then RemoteMaint(0,'K',Extra)
          Else If Temp = 'FILTER'  Then RemoteMaint(0,'F',Extra)
          Else If Temp = 'TWIT'    Then RemoteMaint(0,'T',Extra)
          Else If Temp = 'REQUEST' Then RemoteMaint(0,'G',Extra);
        End;
      CloseText(fCNF);
    End;
  IgnoreCarrier := False;
  DownloadRequestedOnly := True;
  If DownloadRequested Then PackPacket
  Else If WaitIt Then PressSpace;
  DownloadRequestedOnly := False;
End;

Procedure MainMenu;
Var
  Key: Char;
  Temp: String[10];
  Quitting: Boolean;
  Opt, Level: Byte;
Begin
  Level := 1;
  Quitting := False;
  Repeat
    BIT7 := Not Human^.UseHigh;
    GlobalPendingFiles   := 0;
    GlobalPendingBytes   := 0;
    GlobalPendingCredits := 0;
    BarMessage := '  ScanùPack  ';
    DisplayStatusBar;
    WatchUserTime := True;
    IgnoreCarrier := False;
    BIT7 := Not Human^.UseHigh;
    Opt := Level; If Not Setup^.TwoLevelMenu Then Dec(Opt);
    Case Opt Of
      0: Display('-MAIN',Menu0);
      1: Display('-MAIN2',Menu1);
      2: Display('-PREF',Menu2);
    End;
    If (User.Emulation<>RIP) And (PushedKey=#0) Then
      Begin
        If Setup^.MinuteCol > 0 Then
          Begin
            SetColor(Setup^.MinuteCol);
            WriteCenterString(79,' '+ZeroPad(User.TimeLeft,0)+' '+LANG(L_MinLeft));
          End;
      End;
    SetColor(LightGray);

    Repeat
      Repeat
        If Not GetPushedKey(Key) Then Key := Upcase(Getchar);
      Until Not (Key In ['*',' ']);
      Case Opt Of
      0:Begin
          If      Key = Menu0[ 1] Then UnpackPacket
          Else If Key = Menu0[ 2] Then PackPacket
          Else If Key = Menu0[ 3] Then SelectFlags
          Else If Key = Menu0[ 4] Then SelectKeywords
          Else If Key = Menu0[ 5] Then ChangeArchiver
          Else If Key = Menu0[ 6] Then ChangeProtocol
          Else If Key = Menu0[ 7] Then ViewSettings(Alias,MAXPPACK,MAXPCONF)
          Else If Key = Menu0[ 8] Then DisplayTextFile(SearchBack('MAINMENU.HLP'))
          Else If Key = Menu0[ 9] Then Quitting := True
          Else If Key = Menu0[10] Then Key := GotoLogOff
          Else If Key = Menu0[11] Then Human^.Indexes := Changer('-INDEX')
          Else If Key = Menu0[12] Then Key := GotoFilescan
          Else If Key = Menu0[13] Then SelectBulletins
          Else If Key = Menu0[14] Then Human^.News := Changer('-NEWS')
          Else If Key = Menu0[15] Then Key := GotoWelcome
          Else If Key = Menu0[16] Then Human^.UseHigh := Not Changer('-7BIT')
          Else If Key = Menu0[17] Then ChangePointers
          Else If Key = Menu0[18] Then Begin If Changer('-RESTORE') Then UploadPTR; End
          Else If Key = Menu0[19] Then Human^.ShortList := Changer('-SHORT')
          Else If Key = Menu0[20] Then Human^.NumericExtension := Changer('-NUMBER')
          Else If Key = Menu0[21] Then ChangeLimits(MAXPPACK,MAXPCONF)
          Else If Key = Menu0[22] Then Human^.GlobalPersonal := Changer('-PERSON')
          Else If Key = Menu0[23] Then ChangePacketFormat
          Else Key := '*';
        End;
      1:Begin
          If      Key = Menu1[ 1] Then UnpackPacket
          Else If Key = Menu1[ 2] Then PackPacket
          Else If Key = Menu1[ 3] Then SelectFlags
          Else If Key = Menu1[ 4] Then SelectKeywords
          Else If Key = Menu1[ 5] Then Inc(Level)
          Else If Key = Menu1[ 6] Then DisplayTextFile(SearchBack('MAINMENU.HLP'))
          Else If Key = Menu1[ 7] Then Quitting := True
          Else If Key = Menu1[ 8] Then Key := GotoLogOff
          Else Key := '*';
        End;
      2:Begin
          If      Key = Menu2[ 1] Then Human^.Indexes := Changer('-INDEX')
          Else If Key = Menu2[ 2] Then Key := GotoFilescan
          Else If Key = Menu2[ 3] Then SelectBulletins
          Else If Key = Menu2[ 4] Then Human^.News := Changer('-NEWS')
          Else If Key = Menu2[ 5] Then Key := GotoWelcome
          Else If Key = Menu2[ 6] Then ChangeArchiver
          Else If Key = Menu2[ 7] Then ChangeProtocol
          Else If Key = Menu2[ 8] Then ChangePointers
          Else If Key = Menu2[ 9] Then Begin If Changer('-RESTORE') Then UploadPTR; End
          Else If Key = Menu2[10] Then Human^.ShortList := Changer('-SHORT')
          Else If Key = Menu2[11] Then Human^.NumericExtension := Changer('-NUMBER')
          Else If Key = Menu2[12] Then ChangeLimits(MAXPPACK,MAXPCONF)
          Else If Key = Menu2[13] Then Human^.GlobalPersonal := Changer('-PERSON')
          Else If Key = Menu2[14] Then Human^.UseHigh := Not Changer('-7BIT')
          Else If Key = Menu2[15] Then ViewSettings(Alias,MAXPPACK,MAXPCONF)
          Else If Key = Menu2[16] Then ChangePacketFormat
          Else If Key = Menu2[17] Then Dec(Level)
          Else Key := '*';
        End;
      End;
    Until Key <> '*';
  Until Quitting;
  CloseMessage;
End;

Procedure LoadFastIndex;
Var
  fi: File;
  c, m: Byte;
  n: Word;
Begin
  {$IFDEF PROVERSION}
  m := 1;
  FastIndex_CompletelyLoaded := False;
  FastIndex_PartlyLoaded     := False;
  If HeapSizeAllocated >= 225776 Then
    Begin
      m := 10;
      FastIndex_CompletelyLoaded := True;
    End;

  If OpenFile(fi,MainDir+'MESSAGES.IDX','R',Sizeof(FASTINDEXrecord),faReadOnly+faDenyNone) Then
    Begin
      c := 0;
      Repeat
        Inc(c);
        FastIndex[c] := New(pw1000);
        BlockRead(fi,FastIndex[c]^,1000,n);
      Until (c>=m) Or (n<>1000);
      CloseFile(fi);
      FastIndex_CurrentLow   := 1;
      FastIndex_CurrentHigh  := (c-1)*1000+n;
      FastIndex_PartlyLoaded := True;
    End;
  {$ENDIF}
End;

Procedure DisposeFastIndex;
Var
  c: Byte;
Begin
  {$IFDEF PROVERSION}
  For c := 1 To 10 Do
    If CanDispose(FastIndex[c]) Then
      Begin
        Dispose(FastIndex[c]); MarkDispose(FastIndex[c]);
      End;
  {$ENDIF}
End;

Procedure CloseIt;
Var
  c: Byte;
Begin
  ChangeDirectory(MainDir);
  If Not Closeited Then
    Begin

      If InDownloadingPacket Then
        Begin
          InDownloadingPacket := False;
          CloseFile(fQWKM);
          CloseFile(fDAT);
          CloseFile(fFTI);
        End;

      Closeited := True;
      If Control_Running Then ControlDone;
      If CanDispose(DATBUF_WAV) Then Dispose(DATBUF_WAV); MarkDispose(DATBUF_WAV);
      If CanDispose(FTIBUF_WAV) Then Dispose(FTIBUF_WAV); MarkDispose(FTIBUF_WAV);
      If CanDispose(MSGBUF)     Then Dispose(MSGBUF);     MarkDispose(MSGBUF);
      For c := 1 To MaxLang Do
        Begin
          If CanDispose(LanguageText[c]) Then Dispose(LanguageText[c]);
          MarkDispose(LanguageText[c]);
        End;

      TextAttr := Lightgray;
      Window(1,1,80,25);
      ClrScr;

      HMB_Close;
      CloseFile(fCFG);
      EraseWorkSpace;

      If Not VacationMode Then
        Begin
          SaveUser;
          If AutoName='' Then WriteDropFile Else SaveLocalUser(AutoName);
        End;

      DisposeFastIndex;
      If CanDispose(JamLastReads)  Then Dispose(JamLastReads);  MarkDispose(JamLastReads);
      If CanDispose(Setup)         Then Dispose(Setup);         MarkDispose(Setup);
      If CanDispose(Human)         Then Dispose(Human);         MarkDispose(Human);

      If BootEm And (Baud=0) Then
      Asm
        MOV ah,$05
        MOV ch,35
        MOV cl,0
        INT $16
      End;

      ChangeDirectory(StartDir);
      If MaxAvail <> HeapSizeAllocated Then
        Begin
          Writeln('<!> WARNING: A memory release error has occured');
          Sleep(3);
        End;

      Halt(ERR);
    End;
End;

Procedure FatalLoadup;
Var
  c: Byte;
Begin
  For c := 1 To MaxLang Do
    Begin
      If CanDispose(LanguageText[c]) Then Dispose(LanguageText[c]); MarkDispose(LanguageText[c]);
    End;
  Logit('C','<!> Fatal error loading startup files');
  Halt(ERR);
End;

{$F+}
Procedure CheckRTE;
Begin
  If ErrorAddr <> Nil Then
    Begin
      Logit('C','<!> Runtime error detected');
      Logit('C','    VER: '+Version);
      Logit('C','    ERR: #'+ZeroPad(ExitCode,3)+' at '+ HexStr(Seg(ErrorAddr^))
                                                   + ':' + HexStr(Ofs(ErrorAddr^)));
      ErrorAddr := Nil;
      Inc(ErrorTimes);
      If ErrorTimes = 1 Then CloseIt;
    End;
  ExitProc := ErrorExitProc;
End;
{$F-}

Procedure VacationDownload(st: String);
Label
  RedownloadVacation;
Var
  Info: SearchRec;
  Ret, Count: Word;
Begin
  ClearScreen;
  Count := 0;
  FindFirst(st+'\*.*',255-16,Info);
  While DosError = 0 Do
    Begin
      Inc(Count);
      FindNext(Info);
    End;
  If Count = 0 Then
    Begin
      Writelines(2);
      Bullet(COL_TOPACK);
      WriteStringCF(LANG(L_VacNoPackets));
      WriteLines(1);
      PressSpace;
    End
  Else
    Begin
      FindFirst(st+'\*.*',255-16,Info);
      While DosError = 0 Do
        Begin
          RedownloadVacation:
          ClearScreen;
          ChangeDirectory(st);
          Ret := TransmitFile(Info.Name);

          If Ret=0 Then
            Begin
              TransmitGood;
              KillFile(Info.Name)
            End
          Else If Ret = $FFFF Then
            Begin
              WriteLines(1);
              If Not LessWait Then PressSpace;
            End
          Else
            Begin
              If TransmitBadRetry(Ret) Then Goto RedownloadVacation;
            End;
          FindNext(Info);
        End;
    End;
End;

Procedure VacationManagerMenu;
Var
  Key: Char;
Begin
  Repeat
    Display('-VACMGR',Menu3);
    SetColor(LightGray);
    If (User.Emulation<>RIP) Then
      Begin
        If (PushedKey=#0) Then WriteCenterString(79,' '+ZeroPad(User.TimeLeft,0)+' '+LANG(L_MinLeft));
      End
    Else
      Begin
        GotoLoc(1,23);
      End;
    Repeat
      If PushedKey<>#0 Then Key := PushedKey Else Key := Upcase(Getchar);
      PushedKey := #0;
    Until Pos(Key,Menu3)>0;
    If      Key = Menu3[1] Then Begin
                                If Changer('-V!SEND')
                                Then VacationDownload(MainDir+'VACATION\'
                                                      +HexStr(Username_CRC Shr 16)
                                                      +HexStr(Word(Username_CRC)));
                                End
    Else If Key = Menu3[2] Then Begin
                                If Changer('-V!ERASE')
                                Then KillDirectory(MainDir+'VACATION\'+HexStr(Username_CRC Shr 16)+HexStr(Word(Username_CRC)));
                                End
    Else If Key = Menu3[3] Then Begin
                                  ClearLine;
                                  WriteCenterString(78,' '+LANG(L_VacOn));
                                  Sleep(3);
                                  Human^.VacationMode := True;
                                End
    Else If Key = Menu3[4] Then Begin
                                  ClearLine;
                                  WriteCenterString(78,' '+LANG(L_VacOff));
                                  Sleep(3);
                                  Human^.VacationMode := False;
                                End
    Else If Key = Menu3[5] Then ViewSettings(Alias,MAXPPACK,MAXPCONF)
    Else If Key = Menu3[6] Then DisplayTextFile(SearchBack('VACATION.HLP'))
    Else If Key = Menu3[8] Then Key := GotoLogoff;
  Until Key = Menu3[7];
End;

Begin
  SaveStat_Close;
  HeapSizeAllocated := MaxAvail;

  Human         := New(pUSERrecord);
  Setup         := New(pSETUPrecord);
  JamLastReads  := New(pJamLastReads);

  While Keypressed Do Readkey;

  DefaultSwapShellMethod := $257;
  WorkDir := UpcaseStr(GetEnv('OLMSSWAP'));
  If WorkDir <> '' Then
    Begin
      DefaultSwapShellMethod := $0;
      If Pos('D',WorkDir)>0 Then Inc(DefaultSwapShellMethod,$244);
      If Pos('E',WorkDir)>0 Then Inc(DefaultSwapShellMethod,$1);
      If Pos('X',WorkDir)>0 Then Inc(DefaultSwapShellMethod,$2);
    End;

  ClrScr;
  Closeited    := False;
  ErrorTimes   := 0;
  Randomize;                                              (* for taglines *)
  UserLoaded   := False;

  MainDir := GetPath(ParamStr(0));
  PutTrail(MainDir);
  GetDir(0,StartDir);
  PutTrail(StartDir);
  DataDir := GetEnv('OLMSDATA');
  WorkDir := GetEnv('OLMSWORK');
  If DataDir = '' Then DataDir := MainDir Else PutTrail(DataDir);
  If WorkDir = '' Then WorkDir := StartDir+'$$$'+ZeroPad(PresentSecond,5)+'.WRK'
  Else
    Begin
      PutTrail(WorkDir);
      WorkDir := WorkDir+'$$$'+ZeroPad(PresentSecond,5)+'.WRK';
    End;

  {$IFNDEF BBS_RA2}
  CrossConfiguration(MainDir);
  {$ENDIF}

  AutoName              := '';
  ComLineMode           := '        ';
  ComLineMode           := UpcaseStr(Copy(ParamStr(1),2,8));
  Setup^.LogFile        := 'ERROR.LOG';
  BootEm                := False;
  WasInReg              := False;
  Control_Running       := False;
  DownloadRequestedOnly := False;
  LessWait              := False;
  VacationMode          := False;
  VacationPointer       := 0;
  VacationManager       := False;
  MaxNodesSupported     := 10;

  PrimeDoorMaker;

  RA250 := False;

  {$IFDEF BBS_RA2}
  ProgramName := 'OLMS '+Version; {!! Changed from ShortVersion in 2.51a}
  PIDName     := 'OLMS '+Version;
  BBS_CC      := 'RA';
  {$ENDIF}

  {$IFDEF BBS_RA1}
  ProgramName := 'OLMS '+Version+'.111';
  PIDName     := 'OLMS '+Version+'.111';
  BBS_CC      := 'CC';
  {$ENDIF}

  HeapError           := @HeapFunc;
  ErrorExitProc       := ExitProc;
  ExitProc            := @CheckRTE;
  EndProcedurePointer := @FatalLoadup;

  If Copy(ComLineMode,1,2) = 'NT' Then
    Begin
      DeductUserTime := False;
      ComLineMode    := UpcaseStr(Copy(ParamStr(2),2,8));
    End
  Else If Copy(ComLineMode,1,2) = 'P=' Then
    Begin
      AutoName    := Copy(ParamStr(1),4,255);
      ComLineMode := UpcaseStr(Copy(ParamStr(2),2,8));
    End;

  {$IFDEF PROVERSION}
  If ComLineMode = 'V' Then
    Begin
      VacationMode := True;
      User.Name := 'Vacation Packing';
    End
  Else If ComLineMode[1] = 'M' Then
    Begin
      VacationManager := True;
    End;
  {$ENDIF}

  BypassDropFile := True;
  If Not VacationMode And (AutoName = '') Then
    Begin
      ReadDropFile(StartDir+'DOOR.SYS');
      ReadDropFile(StartDir+'EXITINFO.BBS');
      If Not (User.Emulation In [ASCII,ANSI]) Then User.Emulation := ANSI;
    End;
  LoadConfigFiles(TaglineSize,DefaultOriginLine);
  ValidateFiles;

  If AutoName <> '' Then
    Begin
      If Not LoadLocalUser(AutoName) Then
        Begin
          Sleep(3);
          NewHalt(1000);
        End;
      Setup^.LogHeaders := True;
      Setup^.LogFile := MainDir+'LOCAL.LOG';
    End
  Else If VacationMode Then
    Begin
      Setup^.LogHeaders := True;
      Setup^.LogFile := MainDir+'VACATION.LOG';
      Setup^.LogMode := 'C';
    End;

  Sys.Sysop  := Setup^.Sysop;
  Sys.Name   := Setup^.SystemName;

  If Setup^.LogHeaders Then AppendFile(Setup^.LogFile,'');
  LogLineTemp := '';
  If ComLineMode <> '' Then LogLineTemp := LogLineTemp + ' (/' + ComLineMode + ')';
  LogIt('C',ProgramName+' = '+User.Name+LogLineTemp);
  If Not Reg Then
    Begin
      Logit('C','EVALUATION COPY = Please register soon!');
      If (PresentDay-Setup^.Dated>60) Then
        Begin
          Logit('C','This program expired after 60 days of unregistered use!');
          Logit('C','Register online at http://www.multiboard.com/software/');
          EndDoorMaker;
        End;
    End;

  CheckShare;

  If Not Setup^.UseSlice Then SystemEnviroment := DOS4;
  TIMESLICEMAXIMUM    := Setup^.MaxSlices;
  GETSTRINGBACKGROUND := Colors[COL_INPUTBACK];

  If User.Node > MaxNodesSupported Then
    Begin
      Writeln('This version only supports ',MaxNodesSupported,' nodes.');
      Logit('C','<!> This version only supports '+ZeroPad(MaxNodesSupported,0)+' nodes.');
      Halt;
    End;

  If(Baud>0) And Setup^.AllowRip Then DetectRip := True;
  StartDoorMaker;

  LoadOLF(User.Language);
  LoadMenuKeys;

  {$IFDEF PROVERSION}
  If Setup^.ProActivated=224 Then Setup^.Dated := Setup^.ProDated;
  {$ENDIF}

  If WasInReg Then RegMessage Else EndDoorMaker;        (* PROTECT *)
  If WasInReg Then EndDoorMaker;                        (* PROTECT *)

  If CreateWorkSpace Then
    Begin

      EndProcedurePointer := @CloseIt;

      OpenMessagesConfig; {2.51b1 moved from after display screen}
      HMB_Open;
      LoadFastIndex;
      InitUserRecordSize;

      If  Setup^.Opening
      And Not (ComLineMode[1] In ['D','U','R'])
      And Not VacationMode
      Then
        Begin
          Display('-TITLE','');
          Repeat Until GetChar In [#13,HotKey[L_PressSpace],'.'];
        End;
      If Reg And (Pos(Setup^.Serial[4],Conversions)<>Length(Setup^.Sysop)+1) Then EndDoorMaker;      (* PROTECT *)
      If Reg And (Pos(Setup^.Serial[5],Conversions)<>Length(Setup^.SystemName)+1) Then EndDoorMaker; (* PROTECT *)

      If (ComLineMode[1]='L') Then LessWait := True;
      If (ComLineMode[1] In ['U','D']) And (ComLineMode[2] In ['Q','A','L'])
      Then Wait := False
      Else Wait := True;
      If VacationMode Then Wait := False;

      {$IFNDEF BBS_FILEREQUEST}
      Setup^.AllowFiles := 0;
      Setup^.AllowDownloadAttach := False;
      {$ENDIF}

      {!! Allow attached during vacation download?}

      {$IFNDEF PROVERSION}
      Setup^.AutoPackAttaches := False;
      {$ENDIF}

      {$IFDEF BBS_RA1}
      Setup^.GroupPick := False;
      {$ENDIF}

      Repeat

        VacationRecycle:
        If VacationMode Then
          Begin
            WatchUserTime := False;
            If Not VacationLoadUser(VacationLoaded) Then EndDoorMaker;
            If Not VacationLoaded Then Goto VacationRecycle;
            Setup^.LocalDLPath := MainDir+'VACATION\'+HexStr(Username_CRC Shr 16)+HexStr(Word(Username_CRC));
            MakeDirectory(MainDir+'VACATION');
            MakeDirectory(Setup^.LocalDLPath);
            PutTrail(Setup^.LocalDLPath);
          End
        Else LoadUser;

        ValidateUserFields;
        LoadLastRead;

        If Not Setup^.AllowFileScan Then Human^.Files := False;

        If VacationManager Then
          Begin
            (* Autodownload vacation packets *)
            If Copy(ComLineMode,3,1) = 'A' Then Wait := False;
            If Copy(ComLineMode,2,1) = 'L' Then LessWait := True;
            If Copy(ComLineMode,2,1) = 'D' Then VacationDownload(MainDir+'VACATION\'
                                                                +HexStr(Username_CRC Shr 16)
                                                                +HexStr(Word(Username_CRC)));

            (* Exit routines *)
            If      Copy(ComLineMode,3,1) = 'A' Then Begin End
            Else If Copy(ComLineMode,3,1) = 'L' Then GoodBye
            Else If Copy(ComLineMode,3,1) = 'Q' Then Begin WriteLines(1); AutoLogoff End
            Else VacationManagerMenu;

          End
        Else If Not VacationMode Then
          Begin
            (* Interactive/automatic command line selection *)
            If      ComLineMode[1] = 'R' Then Begin WriteLines(2); ResetAllPointers(ComLineMode) End
            Else If ComLineMode[1] = 'U' Then UnpackPacket
            Else If ComLineMode[1] = 'D' Then PackPacket
            Else MainMenu;

            (* Logoff command line selection *)
            If (ComLineMode[1] In ['U','D']) Then
              Begin
                Case ComLineMode[2] Of
                  'L': GoodBye;
                  'Q': AutoLogoff;
                End;
                If Pos('R',ComLineMode)>0 Then MainMenu;
              End;
          End
        Else (* Vacation Mode *)
          Begin
            PackPacket;
            SaveUser;
            SaveLocalUser('*'+Name);
          End;

      Until Not VacationMode;
    End;
  EndDoorMaker;
End.


ÿÿÿ