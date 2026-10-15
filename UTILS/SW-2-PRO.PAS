Program SW_2_PRO;

Uses DM6000, Crt, Dos, U_NEW;

{$M 48000,0,0}
{$I d:\zrel\olms\BBSTYPE.INC}

{$IFDEF PROVERSION}

Type
   SW_SETUPrecord = Record
                  Version,
                  Dated                         : Word;
                  SystemName                    : String[30];
                  Sysop                         : String[35];
                  GatewayAddress                : String[20];
                  MsgBasePath,
                  MainPath,
                  FileBasePath,
                  NodelistPath,
                  NewsFile,
                  HelloFile,
                  GoodbyeFile,
                  LogFile,
                  LocalULPath,
                  LocalDLPath,
                  TagFile                       : String[60];
                  LogMode                       : Char;
                  Serial,
                  Registration                  : String[40];
                  BoardID                       : String[8];
                  PhoneNumber                   : String[20];
                  Screens                       : Byte;
                  Compress,
                  Decompress,
                  Transmit,
                  Receive                       : Array[1..6] Of String[70];
                  Bulletins                     : Array[1.. MaxBull] Of String[60];
                  TransmitKeys                  : Array[1..6] Of Char;
                  TransmitNames                 : Array[1..6] Of String[10];
                  SwappingControl               : Array[1..4] Of Array6Byte;
                  MaxPacket                     : Array[0..7] Of Word;
                  MaxConference,
                  NumberDupes,
                  GoodValue                     : Word;
                  Marked86,
                  Marked286                     : Longint;
                  RestrictTime,
                  AllowRip,
                  KillSentNetmail,
                  CheckDupes,
                  CheckHeaderDupes,
                  AllowFileScan,
                  Opening,
                  AutoInternet,
                  LogExpanded,
                  UseSlice,
                  Retear,
                  Killtag,
                  InsertTag,
                  KillRep,
                  LogHeaders,
                  AllowLogoff,
                  AllowDownloadAttach,
                  DownloadAttachFree,
                  DownloadAttachNoTime,
                  AutoPackAttaches,
                  ShortWord,
                  CapsWord,
                  TwoLevelMenu,
                  GroupPick                     : Boolean;
                  AllowFiles,
                  MaxSlices,
                  ShortStyle,
                  SingleNodeFlag,
                  DefaultPacketType             : Byte;
                  Address                       : Array[0..9] of NetAddress;
                  SysopFlags                    : Array[1..2000] Of Byte;
                  BulletinNames                 : Array[1..MaxBull] Of String[40];
                  BulletinFlags                 : Array[1..MaxBull] Of Byte;
                  ProActivated                  : Byte;
                  ProDated                      : Word;
                  UNUSED                        : Array[1..216] Of Byte;
                End;


Var
  UserAreas: Word;
  SIZE_USERS: Word;

Procedure Change_Areas(osize, nsize:Word);
Var
  fUSRDAT, fo, fn: File;
  OLDSIZE_USERS: Word;
  U: USERrecord;
Begin
  OLDSIZE_USERS := SIZE_USERS;
  UserAreas := nsize;
  SIZE_USERS := Sizeof(USERrecord) - (MaxAreas-UserAreas);
  If SizeofFile(MainDir+'USERS.DAT') MOD OLDSIZE_USERS <> 0 Then
    Begin
      Writeln('Corrupt, or already converted.');
      Halt;
    End;
  If Not OpenFile(fo,'USERS.DAT','R',OLDSIZE_USERS,faReadOnly+faDenyNone) Then
    Begin
      Writeln('Error: Cannot open USERS.DAT');
      Halt;
    End;
  If Not OpenFile(fn,'USERS.NEW','W',SIZE_USERS,faReadWrite+faDenyAll) Then
    Begin
      CloseFile(fo);
      Writeln('Error: Cannot create USERS.NEW');
      Halt;
    End;

  While Not Eof(fo) Do
    Begin
      FillChar(U,Sizeof(U),0);
      BlockRead(fo,U,1);
      BlockWrite(fn,U,1);
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
End;

Procedure UserINFScan;
Var
  fUSRDAT: File;
Begin
  UserAreas := 2000;
  SIZE_USERS := Sizeof(USERrecord) - (MaxAreas-UserAreas);
  If SizeofFile(MainDir+'USERS.DAT') MOD SIZE_USERS <> 0 Then
    Begin
      Writeln('USERS.INF corrupt size mismatch, or already converted.');
      Halt;
    End;
End;

Procedure ConvertUsers;
Begin
    Begin
      Writeln('Users: Converting from the Shareware to Professional file format.');
      UserInfScan;
      Change_Areas(2000,10000);
    End;
End;

Procedure ConvertSetup;
Var
  fo: File Of SW_SETUPrecord;
  fn: File Of SETUPrecord;
  od: SW_SETUPrecord;
  nd: SETUPrecord;
  w: Word;
Begin
  Write('Setup: ');
  If Not OpenFile(fo,'OLMS.CFG','R',Sizeof(SW_SETUPrecord),faReadOnly+faDenyNone) Then
    Begin
      Writeln('Cannot open OLMS.CFG');
      Exit;
    End;

  If SizeOfFile('OLMS.CFG') <> Sizeof(SW_SETUPrecord) Then
    Begin
      CloseFile(fo);
      Writeln('Corrupt, or already converted');
      Exit;
    End;

  If Not OpenFile(fn,'OLMS.NEW','W',Sizeof(SETUPrecord),faWriteOnly+faDenyAll) Then
    Begin
      CloseFile(fo);
      Writeln('Cannot create OLMS.NEW');
      Exit;
    End;

  Read(fo,od);
  CloseFile(fo);

  FillChar(nd,Sizeof(nd),0);
  Move(od,nd,5914);

  For w := 1 To MaxBull Do
    Begin
      nd.BulletinNames[w] := od.BulletinNames[w];
      nd.BulletinFlags[w] := od.BulletinFlags[w];
    End;

  nd.ProActivated := od.ProActivated;
  nd.ProDated     := od.ProDated;

  Write(fn,nd);
  CloseFile(fn);
  Erase(fo);
  Rename(fn,'OLMS.CFG');
  Writeln('Conversion complete.');
End;

Begin
  Writeln;
  Writeln('OLMS 2.50 Shareware -> Professional Conversion');
  Writeln('Copyright Multiboard Communications Centre and Peter Rocca, 1994-1998');
  Writeln('อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ');
  ConvertUsers;
  ConvertSetup;
{$ENDIF}
End.

