{$O+}
Unit U_JAM;

{$V-}

Interface

Uses
  DM6000, Dos, Crt, U_NEW, U_UNIT, JAM, JAMCRC32;

Type
 pJamLastReads = ^tJamLastReads;
 tJamLastReads = Array[1..MaxAreas] Of Longint;

Var
  JamLastReads: pJamLastReads;

{Function JAM_Open: Boolean;}
{Function JAM_Lock: Boolean;}
{Function JAM_RetSubString(ID, WorkBufLen: Word): String;}

Procedure JAM_SaveLastReads;
Procedure JAM_LoadLastReads;
Procedure JAM_SaveReceived;
Procedure JAM_ModifyPointer(Base: String; Conf, Amount: Word);
Function  JAM_Post(Var WhoTo,WhoFrom,Subject,MsgTime,MsgDate: String; Reply, Conf: Word; Base: String;
                   Attribute: Longint; Zone, Net, Node, Pnt, Cost, Len: Word; IsInternet: Boolean): Boolean;
Function  JAM_GetAttachedPath(Base: String; Number: Longint): String;
Procedure JAM_Scan(Conf: Word; Base: String; Flag: Byte);

Implementation

Uses
  JAMMB;

Var
  j: JAMAPI;

Function JAM_Open: Boolean;
Var
  Opened: Boolean;
  Attempts: Byte;
Begin
  JAM_Open := False;
  If Not FileExists(j.BaseName+'.JHR') Then Exit;
  Attempts := 0;
  Repeat
    Opened := j.OpenMB;
    If Not Opened Then
      Begin
        Inc(Attempts);
        If Attempts > 100 Then Exit;
        Delay(100);
      End;
  Until Opened;
  JAM_Open := True;
End;

Function JAM_Lock: Boolean;
Var
  Locked: Boolean;
  Attempts: Byte;
Begin
  JAM_Lock := False;
  If MultiNode Then
    Begin
      Attempts := 0;
      Repeat
        Locked := j.LockMB(True);
        If Not Locked Then
          Begin
            Inc(Attempts);
            If Attempts > 100 Then Exit;
            Delay(100);
          End;
      Until Locked;
    End
  Else j.HaveLock := True;
  JAM_Lock := True;
End;

Procedure JAM_SaveLastReads;
Var
  dJLR: Array[0..99] Of JAMLREAD;
  HighMessage, UserOffset: Longint;
  Position, Conf: Word;
  Found: Boolean;
  Offset, Result: Integer;
  dCFG: MESSAGErecord;
Begin
  (* Write JAM lastread pointers *)
  For Position := 1 To NumConf Do
    Begin
      Conf := ConferenceNumber(Position);
      If (JamLastReads^[Conf] >= 0) Then
        Begin
          Seek(fCFG,Position-1);
          BlockRead(fCFG,dCFG,1);
          If Is(dCFG.Attribute,cJAM) And (dCFG.Name<>'') Then {Added second part 2.51}
          Begin
          SaveStat_Display;
          j.Init;
          j.BaseName := dCFG.JAMBase;
          If JAM_Open And JAM_Lock Then
            Begin
              UserOffset := -1;
              Found := False;
              HighMessage := (j.SeekFile(j.IdxHandle,JAMSEEK_END,0) DIV Longint(Sizeof(JAMIDXREC)))+j.HdrInfo.BaseMsgNum;
              If JamLastReads^[Conf] <= HighMessage Then
                Begin
                  Repeat
                    Result := j.ReadFile(j.LrdHandle,dJLR,Sizeof(dJLR)) DIV Sizeof(JAMLREAD);
                    For Offset := 0 To Result-1 Do
                      Begin
                        Inc(UserOffset);
                        If (dJLR[Offset].UserCrc = Username_CRC) Then
                          Begin
                            dJLR[Offset].HighReadMsg := JamLastReads^[Conf];
                            dJLR[Offset].LastReadMsg := JamLastReads^[Conf];
                            If Found Then  (* Erase duplicate sigs *)
                              Begin
                                dJLR[Offset].UserCrc := $FFFFFFFF;
                                dJLR[Offset].UserID  := $FFFFFFFF;
                              End;
                            Found := True;
                            j.SeekFile(j.LrdHandle,JAMSEEK_SET,UserOffset*Longint(Sizeof(JAMLREAD)));
                            j.WriteFile(j.LrdHandle,dJLR[OffSet],Sizeof(JAMLREAD));
                          End;
                      End;
                  Until (Result<1) Or Found;
                  If Not Found Then
                    Begin
                      j.LastRead.HighReadMsg := JamLastReads^[Conf];
                      j.LastRead.LastReadMsg := JamLastReads^[Conf];
                      j.LastRead.UserCrc     := Username_CRC;
                      j.LastRead.UserID      := Username_CRC;
                      j.SeekFile(j.LrdHandle,JAMSEEK_END,0);
                      j.WriteFile(j.LrdHandle,j.LastRead,Sizeof(JAMLREAD));
                    End;
                End;
              j.UnlockMB(False);
            End;
          j.CloseMB;
          j.Done;
          End;
        End;
    End;
End;

Procedure JAM_LoadLastReads;
Var
  c: Word;
Begin
  For c := 1 To MaxAreas Do JamLastReads^[c] := -1;
End;

Procedure JAM_SaveReceived;
Var
  Conf, c, c2: Word;
  dCFG: MESSAGErecord;
Begin
  For c := 1 To ReceivedMessages Do
    Begin
      Conf := ReceivedMessageIndex[c].Conf;
      If ValidConference(Conf) Then
        Begin
          Seek(fCFG,ConferenceLocation(Conf)-1);
          BlockRead(fCFG,dCFG,1);
          If dCFG.JamBase <> '' Then
            Begin
              j.Init;
              j.BaseName := dCFG.JamBase;
              If JAM_Open Then
                Begin
                  If JAM_Lock Then
                    Begin
                      For c2 := c To ReceivedMessages Do
                      If ReceivedMessageIndex[c2].Conf = Conf Then
                        Begin
                          ReceivedMessageIndex[c2].Conf := 0;
                          If j.FetchMsgHdr(ReceivedMessageIndex[c2].Data,False) Then
                            Begin
                              j.Hdr.Attribute := j.Hdr.Attribute Or MSG_READ;
                              j.StoreMsgHdr(j.Hdr.MsgNum);
                            End;
                        End;
                      j.UnlockMB(False);
                    End;
                  j.CloseMB;
                End;
              j.Done;
            End;
        End;
    End;
End;

Procedure JAM_ModifyPointer(Base: String; Conf, Amount: Word);
Begin
  j.Init;
  j.WorkLen  := 0;
  j.BaseName := Base;
  If JAM_Open And JAM_Lock Then
    Begin
      JamLastReads^[Conf] := j.HdrInfo.BaseMsgNum-Amount-1
                            +(j.SeekFile(j.IdxHandle,JAMSEEK_END,0) DIV Longint(Sizeof(JAMIDXREC)));
      If JamLastReads^[Conf] < 0 Then JamLastReads^[Conf] := 0;
      j.UnlockMB(False);
    End;
  j.CloseMB;
  j.Done
End;

Function JAM_Post(Var WhoTo,WhoFrom,Subject,MsgTime,MsgDate: String; Reply, Conf: Word; Base: String;
                   Attribute: Longint; Zone, Net, Node, Pnt, Cost, Len: Word; IsInternet: Boolean): Boolean;
Var
  dCFG: MESSAGErecord;
  jAdr, jMsgId, jPid: Array[1..50] Of Char;
  jWhoFrom, jWhoTo, jSubject: Array[1..105] Of Char;
  High, FieldPos, SizeText, SizeHeader, SizeIndex: Longint;
  FieldBuffer: Array[1..800] Of Char;
  Adr: String[35];
  Temp: String;
  w: Word;
  i: Integer;
  DT: DateTime;
  MsgIdCrc, TD, TM: Longint;
Begin
  JAM_Post:= False;
  If Not ValidConference(Conf) Then Exit;

  Seek(fCFG,ConferenceLocation(Conf)-1);
  BlockRead(fCFG,dCFG,1);

  If Not BlueWave And Is(Human^.Flags[Conf],fNETWORK) Then
    Begin
      Val(Copy(MsgDate,1,2),DT.Month,i);
      Val(Copy(MsgDate,4,2),DT.Day,i);
      Val(Copy(MsgDate,7,2),DT.Year,i);
      Inc(DT.Year,1900); If (DT.Year<1940) Then Inc(DT.Year,100); {!Y2KOK!}
      Val(Copy(MsgTime,1,2),DT.Hour,i);
      Val(Copy(MsgTime,4,2),DT.Min,i);
      DT.Sec := 0;
    End
  Else
    Begin
      GetDate(DT.Year,DT.Month,DT.Day,w);
      GetTime(DT.Hour,DT.Min,DT.Sec,w);
    End;

  TM := (DT.Year-1970)*365 + MonthDays[DT.Month] + DT.Day;
  TM := TM + (DT.Year-1972) DIV 4;
  If ((DT.Year MOD 4) = 0) And (DT.Month<3) Then Dec(TM);
  TD := Longint(DT.Hour) * 3600 + Longint(DT.Min) * 60 + DT.Sec;
  TM := (TM * 86400) + TD + 1;

  j.Init;
  j.WorkLen := Sizeof(FieldBuffer);
  j.WorkBuf := @FieldBuffer;
  j.BaseName := Base;

  If Not FileExists(Base+'.JHR') Then
    Begin
      If CreateNewJam Then
        Begin
          If Not j.CreateMB Then
            Begin
              j.Done;
              Exit;
            End;
        End
      Else
        Begin
          j.Done;
          Exit;
        End;
    End;

  If JAM_Open And JAM_Lock Then
    Begin
    End
  Else
    Begin
      j.CloseMB;
      j.Done;
      Exit;
    End;

  SizeIndex  := j.SeekFile(j.IdxHandle,JAMSEEK_END,0);
  SizeHeader := j.SeekFile(j.HdrHandle,JAMSEEK_END,0);
  SizeText   := j.SeekFile(j.TxtHandle,JAMSEEK_END,0);

  (* Increment the change counters *)
  High := (SizeIndex DIV Sizeof(JAMIDXREC)) + j.HdrInfo.BaseMsgNum - 1;
  Inc(j.HdrInfo.Modcounter);
  Inc(j.HdrInfo.ActiveMsgs);

  (* Setup the header fields *)
  FieldPos := 1;
  If (Attribute And MSG_TYPENET) <> 0 Then
    Begin
      PutAddress(Adr,Zone,Net,Node,Pnt);
      CString(jAdr,Adr);
      j.AddField(JAMSFLD_DADDRESS,True,LenBuf(jAdr),FieldPos,jAdr);

      PutAddress(Adr,Setup^.Address[dCFG.AkaAddress].Zone,Setup^.Address[dCFG.AkaAddress].Net,
                     Setup^.Address[dCFG.AkaAddress].Node,Setup^.Address[dCFG.AkaAddress].Point);
      CString(jAdr,Adr);
      j.AddField(JAMSFLD_OADDRESS,True,LenBuf(jAdr),FieldPos,jAdr);
    End;

  Inc(LastMsgId);
  If Reg Or (PresentDay-Setup^.Dated<45)
  Then CString(jPid,PIDName+' ['+Setup^.Serial+']')
  Else CString(jPid,PIDName+' ['+Setup^.Serial+'] '+lZeroPad(PresentDay-Setup^.Dated+1,0)+' days');
  CString(jMsgid,OrgAdrStr+' '+DowncaseStr(HexStr(LastMsgId Shr 16)+HexStr(Word(LastMsgId))));
  CString(jWhoFrom,Copy(WhoFrom,1,100));
  CString(jWhoTo,Copy(WhoTo,1,100));
  CString(jSubject,Copy(Subject,1,100));
  If IsInternet Then
    Begin
{     j.AddField(0,True,LenBuf(jWhoFrom),FieldPos,jWhoFrom); !! Does not seem to be required?}
      j.AddField(1,True,LenBuf(jWhoTo),FieldPos,jWhoTo);
    End;
  j.AddField(2,True,LenBuf(jWhoFrom),FieldPos,jWhoFrom);
  j.AddField(3,True,LenBuf(jWhoTo),FieldPos,jWhoTo);
  j.AddField(6,True,LenBuf(jSubject),FieldPos,jSubject);
  j.AddField(7,True,LenBuf(jPid),FieldPos,jPid);
  j.AddField(4,True,LenBuf(jMsgid),FieldPos,jMsgid);
  If Is(Human^.Flags[Conf],fNETWORK) Then
    Begin
      Temp := 'QWKID: '+ZeroPad(Human^.QWKID,0);
      CString(jSubject,Temp);
      j.AddField(2000,True,Length(Temp),FieldPos,jSubject);
    End;
  j.LowCaseBuf(jWhoTo,LenBuf(jWhoTo));
  MsgIdCrc := crc32(jMsgId,LenBuf(jMsgId),$FFFFFFFF);

  (* Write Index *)
  j.Idx.UserCRC	      := crc32(jWhoTo,LenBuf(jWhoTo),$FFFFFFFF);
  j.Idx.HdrOffset     := SizeHeader;
  j.StoreMsgIdx(High+1);

  (* Write Text *)
  j.SeekFile(j.TxtHandle,JAMSEEK_SET,SizeText);
  j.WriteFile(j.TxtHandle,MSGBUF^,Len);

  (* Write Header *)
  Dec(FieldPos);
  j.Hdr.SubfieldLen   := FieldPos;
  j.Hdr.TimesRead     := 0;
  j.Hdr.MsgIdCRC      := MsgIdCrc; {Changed from 0 for b4}
  j.Hdr.ReplyCRC      := -1;
  j.Hdr.ReplyTo	      := 0;
  j.Hdr.Reply1st      := 0;
  j.Hdr.ReplyNext     := 0;
  j.Hdr.DateWritten   := TM;
  j.Hdr.DateReceived  := 0;
  j.Hdr.DateProcessed := 0;
  j.Hdr.Attribute     := Attribute;
  j.Hdr.TxtOffset     := SizeText;
  j.Hdr.TxtLen        := Len;
  j.Hdr.PasswordCRC   := $FFFFFFFF;
  j.Hdr.Cost          := Cost;
  j.StoreMsgHdr(High+1);
  j.WriteFile(j.HdrHandle,FieldBuffer,FieldPos);

  (* Release the files from lock *)
  j.UnlockMB(True);
  j.CloseMB;
  j.Done;

  If (Attribute And MSG_TYPENET) <> 0 Then AppendFile(Setup^.MsgBasePath+'NETMAIL.JAM',Base+' '+lZeroPad(High+1,0))
  Else If (Attribute And MSG_TYPEECHO) <> 0 Then AppendFile(Setup^.MsgBasePath+'ECHOMAIL.JAM',Base+' '+lZeroPad(High+1,0));

  JAM_Post := True;
End;

Function JAM_RetSubString(ID, WorkBufLen: Word): String;
Var
  Position: Longint;
  st: String;
Begin
  Position := 1;
  If j.FindField(ID,Position,WorkBufLen) Then
    Begin
      Move(j.WorkBuf^[Position+Sizeof(JAMBINSUBFIELD)],st[1],j.SubFieldPtr^.DatLen+1);
      st[0] := Chr(j.SubFieldPtr^.DatLen);
    End
  Else st := '';
  JAM_RetSubString := st;
End;

Procedure JAM_Scan(Conf: Word; Base: String; Flag: Byte);
Var
  JUserName: Array[1..40] Of Char;
  Temp, NodeAdr, Subject, WhoTo, WhoFrom: String[100];
  BWTo, BWFrom: String[100];
  JValue, JLastRead, JUserCrc: Longint;
  JBuffer: Array[1..4000] Of Char;
  JLRBuffer: Array[0..99] Of JAMLREAD;
  JSF: JAMBINSUBFIELD;
  lYear, lMonth, lDay, l1, l2, JT: Longint;
  JD: DateTime;
  TextOffset, WorkBufLen, QWKID, QwkBlocks, Place, Point, Readcount: Word;
  C: Char;
  i: Integer;
  w: Word;
  Ok, SP, Maybe, Pack, Personal: Boolean;
Begin

  If Base='' Then Exit;

  If Is(Setup^.SysopFlags[Conf],sFORCED) Then
    Begin
      If Setup^.IncSelfInForced Then Flag := fALL + fSELF Else Flag := fALL;
    End;

  j.Init;
  j.WorkLen := Sizeof(JBuffer)-2;
  j.WorkBuf := @JBuffer;
  j.BaseName := Base;

  If Not FileExists(j.BaseName+'.JLR') Then CreateFile(j.BaseName+'.JLR');

  If Not JAM_Open Then
    Begin
      j.Done;
      Exit;
    End;

  CString(JUserName,User.Name);
  j.LowCaseBuf(JUserName,LenBuf(JUserName));
  JUserCrc := Crc32(JUserName,LenBuf(JUserName),$FFFFFFFF);
  JLastRead := 0;
  Repeat
    i := j.ReadFile(j.LrdHandle,JLRBuffer,Sizeof(JLRBuffer));
    For JT := 0 To (i DIV Sizeof(JAMLREAD)-1) Do
      Begin
        If (JLRBuffer[JT].UserCrc = JUserCrc)
        And (JLastRead=0)
        Then JLastRead := JLRBuffer[JT].HighReadMsg;
      End;
  Until (i<1) Or (JLastRead>0);

  JValue := (j.SeekFile(j.IdxHandle,JAMSEEK_END,0) DIV Longint(Sizeof(JAMIDXREC))) + j.HdrInfo.BaseMsgNum;
  If JLastRead > JValue Then JamLastReads^[Conf] := JValue  (* Self Correcting if JLR > HMSG *)
  Else JamLastReads^[Conf] := -JLastRead;

  j.Idx.HdrOffset := $FFFFFFFF;
  If JLastRead < j.HdrInfo.BaseMsgNum Then JLastRead := j.HdrInfo.BaseMsgNum-1;
  Repeat
    Inc(JLastread);
  Until Not j.FetchMsgIdx(JLastread) Or (j.Idx.HdrOffset <> $FFFFFFFF);

  If j.Idx.HdrOffset <> $FFFFFFFF Then
  Begin
  if(j.SeekFile(j.HdrHandle,JAMSEEK_SET,j.Idx.HdrOffset)=j.Idx.HdrOffset) Then Ok := True Else Ok := False;
  While Ok And (j.ReadFile(j.HdrHandle,j.Hdr,Sizeof(JAMHDR)) = Sizeof(JAMHDR)) Do
    Begin
      If (j.Hdr.SubfieldLen>j.WorkLen)
      Then ReadCount:=WORD(j.WorkLen)
      Else ReadCount:=WORD(j.Hdr.SubfieldLen);

      If (j.ReadFile(j.HdrHandle, j.WorkBuf^, ReadCount) = ReadCount) Then Ok := True Else Ok := False;
      If (ReadCount<j.Hdr.SubfieldLen) Then j.SeekFile(j.HdrHandle,JAMSEEK_CUR,j.Hdr.SubfieldLen-Longint(ReadCount));
      {!! Check the seek, however has been working since 2.0 AFAIK}

      If Ok
      And Not Isl(j.Hdr.Attribute,MSG_DELETED)
      And (j.Hdr.PasswordCRC=$FFFFFFFF) {!! Possible option to allow the user to specify passwords?}
      Then
        Begin
          Wheel;
          WorkBufLen := j.Hdr.SubFieldLen;
          WhoFrom    := JAM_RetSubString(JAMSFLD_SENDERNAME,WorkBufLen);
          WhoTo      := JAM_RetSubString(JAMSFLD_RECVRNAME,WorkBufLen);
          Subject    := JAM_RetSubString(JAMSFLD_SUBJECT,WorkBufLen);
          If WhoFrom = '' Then WhoFrom := ' ';
          If WhoTo   = '' Then WhoTo   := ' ';
          If Subject = '' Then Subject := ' ';
          If BlueWave Then Begin TextOffSet := 1; MSGBUF^[0] := ' '; End
          Else TextOffset := 0;
          SP := False;
          If(Length(WhoTo)  >MAXLEN_WHO) Then Begin TextOffset := InsertKludge('To:',WhoTo,TextOffset); SP := True; End;
          If(Length(WhoFrom)>MAXLEN_WHO) Then Begin TextOffset := InsertKludge('From:',WhoFrom,TextOffset); SP := True; End;
          If(Length(Subject)>MAXLEN_SUB) Then Begin TextOffset := InsertKludge('Subject:',Subject,TextOffset); SP := True; End;
          If SP Then Begin MSGBUF^[TextOffset] := CR; Inc(TextOffset); End;
          If BlueWave Then
            Begin
              BWTo   := Copy(WhoTo,1,35);
              BWFrom := Copy(WhoFrom,1,35);
            End;
          WhoTo   := UpcaseStr(Copy(Whoto,1,35));
          WhoFrom := UpcaseStr(Copy(WhoFrom,1,35));

          {If Human^.KeepKludge Then {Removed 2.51.b1}
            Begin
              j.WorkPos := 1;
              While j.WorkPos < WorkBufLen Do
                Begin
                  Move(j.WorkBuf^[j.WorkPos],JSF,Sizeof(JSF));
                  Case JSF.LoID Of
                    0,
                    1,
                    2,
                    3,
                    6: Temp := '*';
                    4: Temp := 'MSGID: ';
                    5: Temp := 'REPLY: ';
                    7: Temp := 'PID: ';
                    8: Temp := 'Via: ';
                    9,
                   10,
                   12: Temp := 'FILE: ';
                   11: Temp := 'FREQ: ';
                 2000: Temp := '';
                 2001: Temp := 'SEENBY: ';
                 2002: Temp := 'PATH: ';
                 2003: Temp := 'FLAGS: ';
                 2004: Temp := 'TZUTC: ';
                  Else
                       Temp := 'JID'+ZeroPad(JSF.LoID,1)+': ';
                  End;
                  If Temp <> '*' Then
                    Begin
                      InsertBuffer(TextOffSet,TextOffSet,Temp);
                      Move(j.WorkBuf^[j.WorkPos+Sizeof(JSF)],MSGBUF^[TextOffset+Length(Temp)],JSF.DatLen);
                      TextOffset := TextOffset + Length(Temp) + JSF.DatLen + 1;
                      MSGBUF^[TextOffset-1] := CR;
                    End;
                  j.WorkPos := j.WorkPos + JSF.DatLen + Sizeof(JSF);
                End;
            End;

          If Isl(j.Hdr.Attribute,MSG_TYPENET) Then NodeAdr := JAM_RetSubString(JAMSFLD_OADDRESS,WorkBufLen);

          If (Human^.IgnoreLimits Or ((PPack < MAXPPACK) And (CPack < MAXPCONF)))
          Then JamLastReads^[Conf] := j.Hdr.MsgNum;

          CheckPackMaybe(WhoTo, WhoFrom, Flag, Isl(j.Hdr.Attribute,MSG_PRIVATE), Pack, Maybe, Personal);
          If (Pack Or Maybe) Then
            Begin
              (* Read and convert text *)
              If Longint(j.Hdr.TxtLen+TextOffset) > Longint(TextBufferSize)
              Then j.Hdr.TxtLen := Longint(TextBufferSize-TextOffset);
              j.SeekFile(j.TxtHandle,JAMSEEK_SET,j.Hdr.TxtOffset);
              j.ReadFile(j.TxtHandle,MSGBUF^[TextOffset],j.Hdr.TxtLen);
              j.Hdr.TxtLen := j.Hdr.TxtLen + Longint(TextOffset);
              FillChar(MSGBUF^[j.Hdr.TxtLen],TextBufferSize-j.Hdr.TxtLen,0);
              If Not BlueWave And Isl(j.Hdr.Attribute,MSG_TYPENET) Then
                Begin
                  If Not SP Then Subject := Subject + CR;
                  If(Length(Subject)<=MAXLEN_SUB) Then j.Hdr.TxtLen := InsertBuffer(0,j.Hdr.TxtLen,'Subject: '+Subject+CR);
                  Subject := '@'+NodeAdr;
                End;
              CurrentBufferSize := j.Hdr.TxtLen;

              If Is(Flag,fCONNECT) Then
                Begin
                  Temp := JAM_RetSubString(2000,WorkBufLen);
                  If Pos(#0,Temp) <> 0 Then Temp[0] := Char(Pos(#0,Temp)-1);
                  If Copy(Temp,1,7) = 'QWKID: ' Then
                    Begin
                      Val(Copy(Temp,8,5),QWKID,i);
                      If QWKID = Human^.QWKID Then
                        Begin
                          Dec(PNew);
                          Dec(CNew);
                        End;
                    End
                  Else QWKID := 0;
                End
              Else QWKID := 0;

               If ((QWKID=0)
               Or (QWKID<>Human^.QWKID))
              And CheckFilterKeyword(WhoFrom, WhoTo, Subject, Personal, Pack, Maybe, Conf, Flag) Then
                Begin
                  If Isl(j.Hdr.Attribute,MSG_FILEATTACH) Then AddAttach(Conf,j.Hdr.MsgNum);
                  CurrentBufferSize := WrapText(j.Hdr.TxtLen,Isl(j.Hdr.Attribute,MSG_TYPENET));
                  If (WhoTo=Name) Or (WhoTo=Alias) Then
                    Begin
                      If ReceivedMessages < 255 Then Inc(ReceivedMessages);
                      ReceivedMessageIndex[ReceivedMessages].Conf := Conf;
                      ReceivedMessageIndex[ReceivedMessages].Data := j.Hdr.MsgNum;
                    End;
                  PackedMessage[Conf DIV 8] := (PackedMessage[Conf DIV 8]) Or (1 Shl (Conf MOD 8));

                  JT       := j.Hdr.DateWritten;
                  JD.Sec   := Integer(JT MOD 60);     JT := JT DIV 60;
                  JD.Min   := Integer(JT MOD 60);     JT := JT DIV 60;
                  JD.Hour  := Integer(JT MOD 24);     JT := JT DIV 24;
                  l1       := (JT+2440601) + 68607;
                  l2       := 4 * l1 DIV 146100;
                  l1       := l1 - (146100 * l2 + 3) DIV 4;
                  lYear    := 4000 * (l1 + 1) DIV 1461001;
                  l1 	   := l1 - 1461 * lYear DIV 4 + 31;
                  lMonth   := 80 * l1 DIV 2447;
                  lDay     := l1 - 2447 * lMonth DIV 80;
                  l1       := lMonth DIV 11;
                  lMonth   := lMonth + 2 - 12 * l1;
                  lYear    := (100 * (l2 - 49) + lYear + l1) Mod 100;
                  JD.Year  := lYear;
                  JD.Month := lMonth;
                  JD.Day   := lDay;

                  If Not BlueWave Then
                   Begin
                    QwkBlocks := (CurrentBufferSize DIV 128) + Byte(CurrentBufferSize MOD 128 <> 0)+1;
                    Str(QwkBlocks,Temp);
                    StrBuf(Temp,dQWKD.NumBlocks,6);
                    Str(j.Hdr.MsgNum,Temp);
                    StrBuf(Temp,dQWKD.MsgNum,7);
                    StrBuf(ZeroPad(JD.Month,2)+'-'+ZeroPad(JD.Day,2)+'-'+ZeroPad(JD.Year Mod 100,2),dQWKD.MsgDate,8);
                    StrBuf(ZeroPad(JD.Hour,2)+':'+ZeroPad(JD.Min,2),dQWKD.MsgTime,5);
                    StrBuf(WhoTo,dQWKD.WhoTo,25);
                    StrBuf(WhoFrom,dQWKD.WhoFrom,25);
                    StrBuf(Subject,dQWKD.Subject,25);
                    StrBuf('',dQWKD.Password,12);
                    Str(j.Hdr.ReplyTo,Temp);
                    StrBuf(Temp,dQWKD.MsgRefNum,8);
                    Case (j.Hdr.Attribute And (MSG_PRIVATE+MSG_READ)) Of
                      0: dQWKD.Status := ' ';
                      MSG_PRIVATE: dQWKD.Status := '*';
                      MSG_READ: dQWKD.Status := '-';
                      MSG_READ+MSG_PRIVATE: dQWKD.Status := '+';
                    End;
                    dQWKD.Flag := 'á';
                    dQWKD.Conf := Conf;
                    dQWKD.Number := PPack;
                    dQWKD.TagLine := ' ';
                    BlockWrite(fQWKM,dQWKD,1);
                    BlockWrite(fQWKM,MSGBUF^,Longint(QwkBlocks)-1);
                    If Personal Then Write_QWKPersonalIndex(Conf,Index,QwkBlocks);
                    Write_QWKIndex(Conf,Index,QwkBlocks);
                   End
                  Else (* Is BlueWave *)
                   Begin
                    CString(dFTI.WhoFrom,Copy(BWFrom,1,35));
                    CString(dFTI.WhoTo,Copy(BWTo,1,35));
                    CString(dFTI.Subject,Copy(Subject,1,71));
                    CString(dFTI.Date,ZeroPad(JD.Month,2)+'-'+ZeroPad(JD.Day,2)+'-'+ZeroPad(JD.Year Mod 100,2)+' '
                                     +ZeroPad(JD.Hour,2)+':'+ZeroPad(JD.Min,2));
                    dFTI.Msgnum := Word(j.Hdr.Msgnum);
                    If Isl(j.Hdr.Attribute,MSG_TYPENET) Then
                      Begin
                        GetAddress('@'+NodeAdr,dFTI.OrgZone,dFTI.OrgNet,dFTI.OrgNode,w);
                      End;
                    dFTI.PrevReply := Word(j.Hdr.ReplyTo);
                    dFTI.NextReply := Word(j.Hdr.ReplyNext);
                    dFTI.TextOffset := BlueWaveLength;
                    dFTI.TextLength := CurrentBufferSize;
                    Inc(BlueWaveLength,dFTI.TextLength);
                    dFTI.Flags := 0;
                    If Isl(j.Hdr.Attribute,MSG_PRIVATE)    Then Inc(dFTI.Flags,FTI_MSGPRIVATE);
                    If Isl(j.Hdr.Attribute,MSG_READ)       Then Inc(dFTI.Flags,FTI_MSGREAD);
                    If Isl(j.Hdr.Attribute,MSG_SENT)       Then Inc(dFTI.Flags,FTI_MSGSENT);
                    If Isl(j.Hdr.Attribute,MSG_FILEATTACH) Then Inc(dFTI.Flags,FTI_MSGFILE);
                    If Isl(j.Hdr.Attribute,MSG_CRASH)      Then Inc(dFTI.Flags,FTI_MSGCRASH);
                    If Isl(j.Hdr.Attribute,MSG_ORPHAN)     Then Inc(dFTI.Flags,FTI_MSGORPHAN);
                    If Isl(j.Hdr.Attribute,MSG_KILLSENT)   Then Inc(dFTI.Flags,FTI_MSGKILL);
                    If Isl(j.Hdr.Attribute,MSG_LOCAL)      Then Inc(dFTI.Flags,FTI_MSGLOCAL);
                    If Isl(j.Hdr.Attribute,MSG_HOLD)       Then Inc(dFTI.Flags,FTI_MSGHOLD);
                    If Isl(j.Hdr.Attribute,MSG_IMMEDIATE)  Then Inc(dFTI.Flags,FTI_MSGIMMEDIATE);
                    If Isl(j.Hdr.Attribute,MSG_DIRECT)     Then Inc(dFTI.Flags,FTI_MSGDIRECT);
                    Write_FTI(dFTI);
                    Write_DAT(CurrentBufferSize);
                  End;
                End;
            End;
        End;
      End;
  End;
  j.CloseMB;
  j.Done;
End;

Function JAM_GetAttachedPath(Base: String; Number: Longint): String;
Var
  JBuffer: Array[1..4000] Of Char;
  WorkBufLen: Word;
  p: String;
Begin
  JAM_GetAttachedPath := '';
  j.Init;
  j.WorkLen := Sizeof(JBuffer)-2;
  j.WorkBuf := @JBuffer;
  j.BaseName := Base;
  If JAM_Open And j.FetchMsgHdr(Number,True) Then
    Begin
      WorkBufLen := j.Hdr.SubFieldLen;
      If (IsPersonal(UpcaseStr(Copy(JAM_RetSubString(JAMSFLD_RECVRNAME,WorkBufLen),1,35)))
          Or IsWritten(UpcaseStr(Copy(JAM_RetSubString(JAMSFLD_SENDERNAME,WorkBufLen),1,35)))
          Or Not Isl(j.Hdr.Attribute,MSG_PRIVATE)
          Or PvtRights)
         And Not Isl(j.Hdr.Attribute,MSG_DELETED)
         And Isl(j.Hdr.Attribute,MSG_FILEATTACH) Then
      Begin
        p := JAM_RetSubString(JAMSFLD_ENCLFILEWC,WorkBufLen);
        If p<>'' Then PutTrail(p);
        JAM_GetAttachedPath := p;
      End;
    End;
  j.CloseMB;
  j.Done;
End;



End.ÿ