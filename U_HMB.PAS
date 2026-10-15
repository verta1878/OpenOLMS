{$O+}
Unit U_HMB;

{$V-}

Interface

Uses
  DM6000, Dos, Crt, U_NEW, U_UNIT;

Var
  LastReads: LASTREADrecord;

Procedure HMB_LoadLastReads;
Procedure HMB_SaveLastReads;
Procedure HMB_SaveReceived;
Procedure HMB_ModifyPointer(Conf, Amount: Word);
Function  HMB_Post(Var WhoTo,WhoFrom,Subject,MsgTime,MsgDate: String;
                   Reply, Conf, Len, MsgAttr, NetAttr: Word;
                   Zone: Byte; Net, Node, Pnt, Cost: Word): Boolean;
Function  HMB_Open: Boolean;
Procedure HMB_Scan(Conf: Word; Flag: Byte); {C}
Function  HMB_GetAttachedPath(Conf: Word; Number: Word): String; {C}
Function  HMB_Close: Boolean;

Implementation
Uses
  FHANDLES;

Var
  fHMB: Array[0..5] Of Integer;
  HighMessageRead: Longint;

Procedure HMB_LoadLastReads;
Begin
  SeekHandle(fHMB[LRD],SEEK_SET,Longint(User.RecordNumber)*Longint(Sizeof(LASTREADrecord)));
  ReadHandle(fHMB[LRD],LastReads,Sizeof(LASTREADrecord));
  HighMessageRead := User.LastRead;
End;

Function LockFileHandle(h: Integer; On: Boolean): Integer;
Begin
  If LockHandle(h,0,1,On) Then LockFileHandle := 0 Else LockFileHandle := -1;
End;

Procedure HMB_SaveLastReads;
Begin
  SeekHandle(fHMB[LRD],SEEK_SET,Longint(User.RecordNumber)*Longint(Sizeof(LASTREADrecord)));
  WriteHandle(fHMB[LRD],LastReads,Sizeof(LASTREADrecord));
  User.LastRead := HighMessageRead;
End;

Procedure HMB_SaveReceived;
Var
  Offset: Word;
  c: Byte;
  dHDR: MSGHDRrecord;
  ReceivedString: MSGTOIDXrecord;
Begin
  Fillchar(ReceivedString,Sizeof(MSGTOIDXrecord),0); (* Clean out nicely *)
  ReceivedString := '* Received *';                  (* Received Index   *)

  For c := 1 To ReceivedMessages Do
    Begin
      If ReceivedMessageIndex[c].Conf = 0 Then       (* Hudson *)
        Begin
          (* Calculate message offset *)
          OffSet := ReceivedMessageIndex[c].Data DIV 65536; {IDEA! U:Shr 8}

          (* Write received to MSGTOIDX.BBS *)
          SeekHandle(fHMB[MTO],SEEK_SET,Longint(Offset)*Longint(Sizeof(MSGTOIDXrecord)));
          WriteHandle(fHMB[MTO],ReceivedString,sizeof(MSGTOIDXrecord));

          (* Read current Hudson header *)
          SeekHandle(fHMB[HDR],SEEK_SET,Longint(OffSet)*Longint(Sizeof(MSGHDRrecord)));
          ReadHandle(fHMB[HDR],dHDR,Sizeof(MSGHDRrecord));
          dHDR.MsgAttr := dHDR.MsgAttr Or HMB_RECEIVED;

          (* Write receive Hudson header *)
          SeekHandle(fHMB[HDR],SEEK_CUR,-Sizeof(MSGHDRrecord));
          WriteHandle(fHMB[HDR],dHDR,Sizeof(MSGHDRrecord));
        End;
    End;
End;

Procedure HMB_ModifyPointer(Conf, Amount: Word);
Var
  dIDX: Array[1..100] Of MSGIDXRecord;
  h, BlocksRead, Count: Word;
Begin
  h := 0;
  BlocksRead := SeekHandle(fHMB[IDX],SEEK_END,0) DIV Sizeof(MSGIDXrecord);
  If BlocksRead > 100 Then BlocksRead := 100;
  Repeat
    SeekHandle(fHMB[IDX],SEEK_CUR,-BlocksRead*Sizeof(MSGIDXrecord));
    BlocksRead := ReadHandle(fHMB[IDX],dIDX,Sizeof(dIDX)) DIV Sizeof(MSGIDXrecord);
    SeekHandle(fHMB[IDX],SEEK_CUR,-BlocksRead*Sizeof(MSGIDXrecord));
    For Count := BlocksRead Downto 1 Do
      Begin
        If h = Amount Then LastReads[Conf] := dIDX[Count].MsgNum;
        If dIDX[Count].Board = Conf Then Inc(h);
      End;
  Until (BlocksRead < 100) Or (h=Amount);
  If h < Amount Then LastReads[Conf] := 0;
End;

Function HMB_Post(Var WhoTo,WhoFrom,Subject,MsgTime,MsgDate: String;
                      Reply, Conf, Len, MsgAttr, NetAttr: Word;
                      Zone: Byte; Net, Node, Pnt, Cost: Word): Boolean;
Var
  dCFG: MESSAGErecord;
  dIDX: MSGIDXRecord;
  dHDR: MSGHDRRecord;
  dTXT: MSGTXTRecord;
  dNFO: MSGINFORecord;
  dMTO: MSGTOIDXRecord;
  LockAttempts, Keeper, Count, Loc, StartBlock, NumberBlocks: Word;
  Locked, Keep: Boolean;
  Kludge: Char;
  Temp: String[100];
  f: File;
Begin
  HMB_Post := False;
  If Not ValidConference(Conf) Then Exit;

  FillChar(dHDR,Sizeof(dHDR),0);
  dTXT := '';

  Seek(fCFG,ConferenceLocation(Conf)-1);
  BlockRead(fCFG,dCFG,1);

  If Is(MsgAttr,HMB_NETMAIL) Then
    Begin
      dHDR.DestZone := Zone;
      dHDR.DestNet  := Net;
      dHDR.DestNode := Node;
      dHDR.OrigZone := Setup^.Address[dCFG.AkaAddress].Zone;
      dHDR.OrigNet  := Setup^.Address[dCFG.AkaAddress].Net;
      dHDR.OrigNode := Setup^.Address[dCFG.AkaAddress].Node;
      If Setup^.Address[dCFG.AkaAddress].Point > 0
      Then dTXT := dTXT + 'FMPT '+ZeroPad(Setup^.Address[dCFG.AkaAddress].Point,0)+#13+#10;
      If Pnt > 0 Then dTXT := dTXT + 'TOPT '+ZeroPad(Pnt,0)+#13+#10;
    End;

  (* If multinode then try to lock *)
  If MultiNode Then
    Begin
      LockAttempts := 0;
      Repeat
        Locked := LockFileHandle(fHMB[NFO],True) = 0;
        If Not Locked Then
          Begin
            Delay(100);
            Inc(LockAttempts);
            If LockAttempts > 300 Then Exit;
          End;
      Until Locked Or (LockAttempts>100);
    End;

  SeekHandle(fHMB[NFO],SEEK_SET,0);
  ReadHandle(fHMB[NFO],dNFO,Sizeof(dNFO));
  If dNFO.HighMsg >= 32000 Then
    Begin
      If MultiNode Then LockFileHandle(fHMB[NFO],False);
      Exit;
    End;
  Inc(dNFO.HighMsg);
  Inc(dNFO.TotalMsgs);
  Inc(dNFO.TotalOnBoard[Conf]);
  SeekHandle(fHMB[NFO],SEEK_SET,0);
  WriteHandle(fHMB[NFO],dNFO,Sizeof(dNFO));

  SeekHandle(fHMB[IDX],SEEK_END,0);
  dIDX.MsgNum := dNFO.HighMsg;
  dIDX.Board  := Conf;
  WriteHandle(fHMB[IDX],dIDX,Sizeof(dIDX));

  StartBlock := SeekHandle(fHMB[TXT],SEEK_END,0) DIV Sizeof(dTXT);

  Inc(LastMsgId);
  dTXT := dTXT + 'PID: '+PIDName+' ['+Setup^.Serial+']';
  If Not Reg And (PresentDay-Setup^.Dated>44) Then dTXT := dTXT + ' ' +lZeroPad(PresentDay-Setup^.Dated+1,0)+' days';
  dTXT := dTXT + #13+'MSGID: '+OrgAdrStr+' '+DowncaseStr(HexStr(LastMsgId Shr 16)+HexStr(Word(LastMsgId)))+#13;
  Count := Length(dTXT);
  NumberBlocks := 0;

  SeekHandle(fHMB[MTO],SEEK_END,0);
  dMTO := Copy(WhoTo,1,35);
  WriteHandle(fHMB[MTO],dMTO,Sizeof(dMTO));

  For Loc := 0 To Len Do
    Begin
      Inc(Count);
      If MSGBUF^[Loc] = CR Then dTXT[Count] := #13
      Else dTXT[Count] := MSGBUF^[Loc];
      If Count = 255 Then
        Begin
          Inc(NumberBlocks);
          dTXT[0] := #255;
          WriteHandle(fHMB[TXT],dTXT,Sizeof(dTXT));
          Count := 0;
        End;
    End;
  If Count > 0 Then
    Begin
      Inc(NumberBlocks);
      dTXT[0] := Chr(Count);
      WriteHandle(fHMB[TXT],dTXT,Sizeof(dTXT));
    End;

  SeekHandle(fHMB[HDR],SEEK_END,0);
  dHDR.MsgNum     := dNFO.HighMsg;
  dHDR.PrevReply  := Reply;
  dHDR.StartBlock := StartBlock;
  dHDR.NumBlocks  := NumberBlocks;
  dHDR.NetAttr    := NetAttr;
  dHDR.MsgAttr    := MsgAttr;
  dHDR.Board      := Conf;
  dHDR.WhoTo      := Copy(WhoTo,1,35);
  dHDR.WhoFrom    := Copy(WhoFrom,1,35);
  dHDR.Subject    := Copy(Subject,1,72);
  dHDR.Cost       := Cost;

  If Not BlueWave And Is(Human^.Flags[Conf],fNETWORK) Then
    Begin
      dHDR.PostTime := MsgTime;
      dHDR.PostDate := MsgDate;
      dHDR.Subject  := Copy(dHDR.Subject,1,Sizeof(MSGTOIDXrecord)-2);
      dHDR.Subject[Length(Subject)+1] := 'ï'; (* QWKID *)
      dHDR.Subject[Length(Subject)+2] := Char(Human^.QWKID DIV 256);
      dHDR.Subject[Length(Subject)+3] := Char(Human^.QWKID MOD 256);
      End
  Else
    Begin
      SecondsToTime(PresentSecond,Temp);  dHDR.PostTime := Temp;
      DayToDate(PresentDay,Temp);         dHDR.PostDate := Temp;
    End;

  WriteHandle(fHMB[HDR],dHDR,Sizeof(dHDR));

  If (MsgAttr And HMB_NETMAIL) <> 0 Then Temp := 'NETMAIL.BBS'
  Else If (MsgAttr And HMB_UECHOMAIL) <> 0 Then Temp := 'ECHOMAIL.BBS'
  Else Temp := '';

  If (Temp<>'') And OpenFile(f,Setup^.MsgBasePath+Temp,'X',1,faReadWrite+faDenyWrite) Then
    Begin
      Keeper := dHDR.MsgNum-1;
      BlockWrite(f,Keeper,2);
      CloseFile(f);
    End;

  If MultiNode Then LockFileHandle(fHMB[NFO],False);
  HMB_Post := True;
End;

Function HMB_Open: Boolean;
Var
  n: Array[0..5] Of String;
  x: Byte;
  Error: Boolean;
Begin
  n[IDX] := Setup^.MsgBasePath+'MSGIDX.BBS';
  n[TXT] := Setup^.MsgBasePath+'MSGTXT.BBS';
  n[HDR] := Setup^.MsgBasePath+'MSGHDR.BBS';
  n[NFO] := Setup^.MsgBasePath+'MSGINFO.BBS';
  n[MTO] := Setup^.MsgBasePath+'MSGTOIDX.BBS';
  n[LRD] := Setup^.MsgBasePath+'LASTREAD.BBS';
  If Not FileExists(n[MTO]) Then CreateFile(n[MTO]);
  Error := False; For x := 0 To 5 Do fHMB[x] := OpenHandle(n[x]); If fHMB[x] = -1 Then Error := True;
  If Error Then   For x := 0 To 5 Do CloseHandle(fHMB[x]);
  HMB_Open := Error;
End;

Procedure HMB_Scan(Conf: Word; Flag: Byte); {C}
Var
  dIDX: Array[1..100] Of MSGIDXRecord;
  dHDR: MSGHDRRecord;
  QWKID, Pnt, MaxSize, BlocksRead, Lap, InBlock, Count, QwkBlocks, BufferLength, TextOffset: Word;
  i: Integer;
  SubLen: Byte;
  SP, Maybe, Pack, Personal: Boolean;
  WhoTo, WhoFrom, Temp: String[50];
  stBuf: String;
Begin

  If Is(Setup^.SysopFlags[Conf],sFORCED) Then
    Begin
      If Setup^.IncSelfInForced Then Flag := fALL + fSELF Else Flag := fALL;
    End;

  Lap := 0;
  MaxSize := SeekHandle(fHMB[IDX],SEEK_END,0) DIV Sizeof(MSGIDXrecord);
  SeekHandle(fHMB[IDX],SEEK_SET,0);
  BlocksRead := 100;
  While BlocksRead = 100 Do
    Begin
      BlocksRead := ReadHandle(fHMB[IDX],dIDX,Sizeof(dIDX)) DIV Sizeof(MSGIDXrecord);
      If BlocksRead > 0 Then
      For InBlock := 1 To BlocksRead Do
        Begin
          If (dIDX[InBlock].Board = Conf) And (dIDX[InBlock].MsgNum > LastReads[Conf]) Then
            Begin
              If (InBlock-1+Lap*100) > MaxSize Then Exit;

              SeekHandle(fHMB[HDR],SEEK_SET,Longint(InBlock-1+Lap*100)*Longint(Sizeof(MSGHDRrecord)));
              ReadHandle(fHMB[HDR],dHDR,Sizeof(dHDR));

              If dHDR.WhoFrom = '' Then dHDR.WhoFrom := ' ';
              If dHDR.WhoTo   = '' Then dHDR.WhoTo   := ' ';
              If dHDR.Subject = '' Then dHDR.Subject := ' ';
              If BlueWave Or (Length(dHDR.WhoTo)>25)   Then WhoTo   := dHDR.WhoTo;
              If BlueWave Or (Length(dHDR.WhoFrom)>25) Then WhoFrom := dHDR.WhoFrom;
              dHDR.WhoTo   := UpcaseStr(dHDR.WhoTo);
              dHDR.WhoFrom := UpcaseStr(dHDR.WhoFrom);

              If Not Is(dHDR.MsgAttr,HMB_DELETED) Then
                Begin

                 Wheel;

                 If (Human^.IgnoreLimits Or ((PPack < MAXPPACK) And (CPack < MAXPCONF)))
                 Then LastReads[Conf] := dHDR.MsgNum;

                 If Is(Flag,fCONNECT) Then
                   Begin
                     SubLen := Length(dHDR.Subject);
                     If dHDR.Subject[SubLen+1] = 'ï' Then
                       QWKID := Word(Byte(dHDR.Subject[SubLen+2]) * 256 + Byte(dHDR.Subject[SubLen+3]))
                     Else QWKID := 65000;
                   End
                 Else QWKID := 0;

                 If QWKID = 0 Then
                   Begin
                     CheckPackMaybe(dHDR.WhoTo, dHDR.WhoFrom, Flag, Is(dHDR.MsgAttr,HMB_PRIVATE), Pack, Maybe, Personal)
                   End
                 Else If QWKID = Human^.QWKID Then
                   Begin
                     Pack := False;
                     Maybe := False;
                   End
                 Else
                   Begin
                     Pack := True;
                     Inc(PNew);
                     Inc(CNew);
                   End;

                 If (Pack Or Maybe) Then
                   Begin
                     FillChar(MSGBUF^,TextBufferSize,0);
                     If BlueWave Then
                       Begin
                         TextOffset := 1;
                         MSGBUF^[0] := ' ';
                       End
                     Else TextOffset := 0;
                     SP := False;
                     If(Length(dHDR.WhoTo)>25)
                     Then Begin TextOffset := InsertKludge('To:',WhoTo,TextOffset); SP := True; End;
                     If(Length(dHDR.WhoFrom)>25)
                     Then Begin TextOffset := InsertKludge('From:',WhoFrom,TextOffset); SP := True; End;
                     If(Length(dHDR.Subject)>25)
                     Then Begin TextOffset := InsertKludge('Subject:',dHDR.Subject,TextOffset); SP := True; End;
                     If SP Then Begin MSGBUF^[TextOffset] := CR; Inc(TextOffset); End;

                     If dHDR.NumBlocks > 240 Then dHDR.NumBlocks := 240;
                     SeekHandle(fHMB[TXT],SEEK_SET,Longint(dHDR.StartBlock)*Longint(Sizeof(MSGTXTrecord)));
                     BufferLength := TextOffset;
                     For Count := 1 To dHDR.NumBlocks Do
                       Begin
                         ReadHandle(fHMB[TXT],stBuf,Sizeof(stBuf));
                         Move(stBuf[1],MSGBUF^[TextOffset+(Count-1)*255],Integer(stBuf[0]));
                         BufferLength := BufferLength + Integer(stBuf[0]);
                       End;
                     If Is(dHDR.MsgAttr,HMB_NETMAIL) Then
                       Begin
                         Pnt := StringInBuffer('FMPT',BufferLength);
                         If Pnt <> $FFFF Then
                           Begin
                             i := 6;
                             Temp := '';
                             While (i < 15) And (MSGBUF^[i+Pnt]<>CR) Do
                               Begin
                                 If MSGBUF^[i+Pnt] In ['0'..'9'] Then Temp := Temp + MSGBUF^[i+Pnt];
                                 Inc(i);
                               End;
                             If Temp <> '' Then
                               Begin
                                 Val(Temp,Pnt,i);
                                 If i <> 0 Then Pnt := $FFFF;
                               End
                             Else Pnt := $FFFF;
                           End;
                         If Pnt = $FFFF Then Pnt := 0;
                         If(Length(dHDR.Subject)<26) Then
                           Begin
                             If Not SP Then dHDR.Subject := dHDR.Subject + CR;
                             BufferLength := InsertBuffer(0,BufferLength,'Subject: '+dHDR.Subject+CR);
                           End;
                         PutAddress(dHDR.Subject,dHDR.OrigZone,dHDR.OrigNet,dHDR.OrigNode,Pnt);
                         If Not BlueWave Then dHDR.Subject := '@'+dHDR.Subject;
                       End;

                     CurrentBufferSize := WrapText(BufferLength,Is(dHDR.MsgAttr,HMB_NETMAIL));

                     If CheckFilterKeyword(dHDR.WhoFrom,dHDR.WhoTo,dHDR.Subject,Personal,Pack,Maybe,Conf,Flag) Then
                       Begin
                         If Isl(dHDR.NetAttr,HMB_FILE) Then AddAttach(Conf,dHDR.MsgNum);
                         If (dHDR.WhoTo = Name) Or (dHDR.WhoTo=Alias) Then
                           Begin
                             If ReceivedMessages < 255 Then Inc(ReceivedMessages);
                             ReceivedMessageIndex[ReceivedMessages].Conf := 0;
                             ReceivedMessageIndex[ReceivedMessages].Data := Longint(InBlock-1+Lap*100)
                                                                            * Longint(65536)
                                                                            + Longint(dHDR.Msgnum);
                           End;
                         PackedMessage[Conf DIV 8] := (PackedMessage[Conf DIV 8]) Or (1 Shl (Conf MOD 8));

                         If Not BlueWave Then
                           Begin
                             QwkBlocks := (CurrentBufferSize DIV 128) + Byte(CurrentBufferSize MOD 128 <> 0)+1;
                             Str(QwkBlocks,Temp);
                             StrBuf(Temp,dQWKD.NumBlocks,6);
                             Str(dHDR.MsgNum,Temp);
                             StrBuf(Temp,dQWKD.MsgNum,7);
                             StrBuf(dHDR.PostDate,dQWKD.MsgDate,8);
                             StrBuf(dHDR.PostTime,dQWKD.MsgTime,5);
                             StrBuf(dHDR.WhoTo,dQWKD.WhoTo,25);
                             StrBuf(dHDR.WhoFrom,dQWKD.WhoFrom,25);
                             StrBuf(dHDR.Subject,dQWKD.Subject,25);
                             StrBuf('',dQWKD.Password,12);
                             Str(dHDR.PrevReply,Temp);
                             StrBuf(Temp,dQWKD.MsgRefNum,8);
                             Case (dHDR.MsgAttr And 24) Of
                               0: dQWKD.Status := ' ';
                               8: dQWKD.Status := '*';
                              16: dQWKD.Status := '-';
                              24: dQWKD.Status := '+';
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
                             CString(dFTI.WhoFrom,Copy(WhoFrom,1,35));
                             CString(dFTI.WhoTo,Copy(WhoTo,1,35));
                             CString(dFTI.Subject,Copy(dHDR.Subject,1,71));
                             CString(dFTI.Date,dHDR.PostDate+' '+dHDR.PostTime);
                             dFTI.Msgnum := dHDR.Msgnum;
                             If Is(dHDR.MsgAttr,HMB_NETMAIL) Then
                               Begin
                                  dFTI.OrgZone := dHDR.OrigZone;
                                  dFTI.OrgNet  := dHDR.OrigNet;
                                  dFTI.OrgNode := dHDR.OrigNode;
                               End;
                             dFTI.PrevReply  := dHDR.PrevReply;
                             dFTI.NextReply  := dHDR.NextReply;
                             dFTI.TextOffset := BlueWaveLength;
                             dFTI.TextLength := CurrentBufferSize;
                             Inc(BlueWaveLength,CurrentBufferSize);
                             dFTI.Flags := 0;
                             If Is(dHDR.MsgAttr,HMB_PRIVATE)  Then Inc(dFTI.Flags,FTI_MSGPRIVATE);
                             If Is(dHDR.MsgAttr,HMB_RECEIVED) Then Inc(dFTI.Flags,FTI_MSGREAD);
                             If Is(dHDR.MsgAttr,HMB_LOCAL)    Then Inc(dFTI.Flags,FTI_MSGLOCAL);
                             If Is(dHDR.NetAttr,HMB_CRASH)    Then Inc(dFTI.Flags,FTI_MSGCRASH);
                             If Is(dHDR.NetAttr,HMB_SENT)     Then Inc(dFTI.Flags,FTI_MSGSENT);
                             If Is(dHDR.NetAttr,HMB_FILE)     Then Inc(dFTI.Flags,FTI_MSGFILE);
                             If Is(dHDR.NetAttr,HMB_KILL)     Then Inc(dFTI.Flags,FTI_MSGKILL);
                             Write_FTI(dFTI);
                             Write_DAT(CurrentBufferSize);
                           End;
                       End;
                   End;
                End;
            End;
        End;
      Inc(Lap);
    End;
  If LastReads[Conf] > HighMessageRead Then HighMessageRead := LastReads[Conf];
End;

Function HMB_GetAttachedPath(Conf: Word; Number: Word): String; {C}
Var
  dIDX: Array[1..100] Of MSGIDXRecord;
  dHDR: MSGHDRRecord;
  Lap, BlocksRead, InBlock: Word;
  Found: Boolean;
Begin
  Found := False;
  HMB_GetAttachedPath := '';
  SeekHandle(fHMB[IDX],SEEK_SET,0);
  BlocksRead := 100;
  Lap := 0;
  While Not Found And (BlocksRead = 100) Do
    Begin
      BlocksRead := ReadHandle(fHMB[IDX],dIDX,Sizeof(dIDX)) DIV Sizeof(MSGIDXrecord);
      For InBlock := 1 To BlocksRead Do
        Begin
          If (dIDX[InBlock].Board = Conf) And (dIDX[InBlock].MsgNum = Number) And Not Found Then
            Begin
              If SeekHandle(fHMB[HDR],SEEK_SET,Longint(InBlock-1+Lap*100)*Longint(Sizeof(MSGHDRrecord))) <> -1 Then
                Begin
                  ReadHandle(fHMB[HDR],dHDR,Sizeof(dHDR));
                  If (IsPersonal(UpcaseStr(dHDR.WhoTo))
                     Or IsWritten(UpcaseStr(dHDR.WhoFrom))
                     Or Not Is(dHDR.MsgAttr,HMB_PRIVATE)
                     Or PvtRights)
                  And Not Is(dHDR.MsgAttr,HMB_DELETED)
                  And Is(dHDR.NetAttr,HMB_FILE) Then
                    Begin
                      Found := True;
                      If dHDR.Subject<>'' Then PutTrail(dHDR.Subject);
                      HMB_GetAttachedPath := dHDR.Subject;
                    End;
                End;
            End;
        End;
      Inc(Lap);
    End;
End;

Function HMB_Close: Boolean;
Var
  x: Byte;
  Error: Boolean;
Begin
  Error := False;
  For x := 0 To 5 Do If CloseHandle(fHMB[x]) = -1 Then Error := True;
  HMB_Close := Error;
End;

End.
ÿ