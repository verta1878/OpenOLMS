Program C20XTO250;

Uses DM6000, Crt, Dos, U_NEW;

{$M 48000,0,0}
{$I d:\zrel\olms\BBSTYPE.INC}

Type

  OLDSETUPrecord = Record
                  Version, Dated: Word;
                  Marked86: Longint;
                  Serial, Registration: String[40];
                  BoardID: String[8];
                  PhoneNumber: String[20];
                  KillSentNetmail,
                  CheckDupes,
                  CheckHeaderDupes,
                  AllowFileScan,
                  Opening: Boolean;
                  Screens: Byte;
                  Compress,
                  Decompress,
                  Transmit,
                  Receive: Array[1..6] Of String[70];
                  NewsFile,
                  HelloFile,
                  GoodbyeFile,
                  LogFile: String[60];
                  Bulletins: Array[1.. MaxBull] Of String[60];
                  TwoLevelMenu: Boolean;
                  Marked286: Longint;
                  TransmitKeys : Array[1..6] Of Char;
                  TransmitNames: Array[1..6] Of String[10];
                  SwappingControl: Array[1..4] Of Array6Byte;
                  RestrictTime, AllowRip: Boolean;
                  SingleNodeFlag, DefaultPacketType: Byte;  {Must be 200 for true}
                  UNUSEDSPACE1: Array[106..122] Of Byte;
                  LocalULPath, LocalDLPath: String[60];
                  MaxPacket: Array[0..7] Of Word;
                  MaxConference, NumberDupes: Word;
                  LogMode: Char;
                  ShortStyle: Byte;
                  GoodValue: Word;
                  AutoInternet, LogExpanded, UseSlice,
                  Retear, Killtag, InsertTag: Boolean;
                  TagFile: String[60];
                  MaxSlices: Byte;
                  KillRep, LogHeaders, AllowLogoff: Boolean;
                  AllowFiles: Byte;
                  AllowDownloadAttach: Boolean;
                  GatewayAddress: String[20];
                  DownloadAttachFree, DownloadAttachNoTime, AutoPackAttaches: Boolean;
                  UNUSEDSPACE2: Array[99..439] Of Byte;
                  NodelistPath: String[60];
                  Address: Array[0..9] of NetAddress;
                  SystemName: String[30];
                  Sysop: String[35];
                  MsgBasePath,
                  MainPath,
                  FileBasePath: String[60];
                  SysopFlags: Array[1..2000] Of Byte;
                  BulletinNames: Array[1..MaxBull] Of String[40];
                  BulletinFlags: Array[1..MaxBull] Of Byte;
                  ShortWord, CapsWord, GroupPick: Boolean;
                  UNUSEDSPACE3: Array[4..84] Of Byte;
                End;

  OLDUSERrecord =  Record
                     Name: String[35];
                     LocalName: String[8];
                     LastDateDownload: Date;
                     LastTimeDownload: Time;
                     LastFileScan: Longint;
                     TotalFilesDownloaded,
                     TotalDownloads: Word;
                     Archiver, Protocol: Char;
                     QWKID, RecordNumber: Word;
                     Password: String[10];      {DO!}
                     MaxPacket, MaxConference: Word;
                     Indexes, Files, UNUSED_Bulletins,
                     KeepKludge, News,
                     GlobalKeywords, GlobalPersonal,
                     FilterPersonal, TwitPersonal,
                     ShortList, Del, IgnoreLimits,
                     NumericExtension: Boolean;
                     CurrentExtension: Word;
                     Revision: Longint;
                     PacketType: Byte;
                     UseHigh, GetWelcome: Boolean;
                     Bulletins: Array[0..3] Of Byte;
                     TodayDownloads: Byte;
                     FilesQueued: Byte;
                     FileQueue: Array[1..10] Of String[12];
                     FileQueueAttached: Array[1..10] Of Boolean;
                     TodayFileDownloads: Byte;
                     UNUSED: Array[155..250] Of Byte;
                     Filters: Array[1..15] Of String[20];
                     Keywords: Array[1..15] Of String[20];
                     Twits: Array[1..15] Of String[25];
                     Flags: Array[1..2000] Of Byte;
                   End;

Procedure ConvertUsers;
Var
  fo: File Of OLDuserrecord;
  fn: File of userrecord;
  od: OLDuserrecord;
  nd: userrecord;
  w: Word;
Begin
  Write('Users: ');
  If Not OpenFile(fo,'USERS.DAT','R',Sizeof(OLDuserrecord),faReadOnly+faDenyNone) Then
    Begin
      Writeln('Cannot open USERS.DAT');
      Exit;
    End;

  If SizeOfFile('USERS.DAT') MOD Sizeof(olduserrecord) <> 0 Then
    Begin
      CloseFile(fo);
      Writeln('Corrupt, or already converted');
      Exit;
    End;

  If Not OpenFile(fn,'USERS.NEW','W',Sizeof(userrecord),faWriteOnly+faDenyAll) Then
    Begin
      CloseFile(fo);
      Writeln('Cannot create USERS.NEW');
      Exit;
    End;

  While Not Eof(fo) Do
    Begin
      Read(fo,od);
      Write(#13+'Converting อ '+SpacePad(od.Name,35));
      FillChar(nd,Sizeof(nd),0);
      nd.Revision               := od.Revision;
      nd.Name                   := od.Name;
      nd.LocalName              := od.LocalName;
      nd.LastDateDownload       := od.LastDateDownload;
      nd.LastTimeDownload       := od.LastTimeDownload;
      nd.LastFileScan           := od.LastFileScan;
      nd.Archiver		:= od.Archiver;
      nd.Protocol               := od.Protocol;
      nd.QWKID			:= od.QWKID;
      nd.RecordNumber		:= od.RecordNumber;
      nd.MaxPacket		:= od.MaxPacket;
      nd.MaxConference		:= od.MaxConference;
      nd.TotalFilesDownloaded	:= od.TotalFilesDownloaded;
      nd.TotalDownloads		:= od.TotalDownloads;
      nd.CurrentExtension       := od.CurrentExtension;
      nd.Indexes		:= od.Indexes;
      nd.Files			:= od.Files;
      nd.KeepKludge		:= od.KeepKludge;
      nd.News			:= od.News;
      nd.GlobalKeywords		:= od.GlobalKeywords;
      nd.GlobalPersonal		:= od.GlobalPersonal;
      nd.FilterPersonal		:= od.FilterPersonal;
      nd.TwitPersonal		:= od.TwitPersonal;
      nd.ShortList		:= od.ShortList;
      nd.Del			:= od.Del;
      nd.IgnoreLimits		:= od.IgnoreLimits;
      nd.UseHigh		:= od.UseHigh;
      nd.GetWelcome		:= od.GetWelcome;
      nd.NumericExtension       := od.NumericExtension;
      nd.PacketType		:= od.PacketType;
      nd.TodayDownloads		:= od.TodayDownloads;
      nd.TodayFileDownloads	:= od.TodayFileDownloads;
      nd.FilesQueued            := od.FilesQueued;

      for w := 1 To    3 Do nd.Bulletins[w] := od.Bulletins[w];
      for w := 1 To    3 Do nd.Bulletins[w] := od.Bulletins[w];
      for w := 1 To   10 Do nd.FileQueue[w] := od.FileQueue[w];
      for w := 1 To   10 Do nd.FileQueueAttached[w] := od.FileQueueAttached[w];
      for w := 1 To   15 Do nd.Filters[w]   := od.Filters[w];
      for w := 1 To   15 Do nd.Keywords[w]  := od.Keywords[w];
      for w := 1 To   15 Do nd.Twits[w]     := od.Twits[w];
      for w := 1 To 2000 Do nd.Flags[w]     := od.Flags[w];

      Write(fn,nd);
    End;
  Writeln(#13+'Users: Conversion complete.                       ');

  CloseFile(fn);
  CloseFile(fo);
  Erase(fo);
  Rename(fn,'USERS.DAT');
End;

Procedure ConvertSetup;
Var
  fn: File Of SETUPrecord;
  fo: File Of OLDSETUPrecord;
  nd: SETUPrecord;
  od: OLDSETUPrecord;
  w: Word;
Begin

  Write('Setup: ');
  If Not OpenFile(fo,'OLMS.CFG','R',Sizeof(OLDSETUPrecord),faReadOnly+faDenyNone) Then
    Begin
      Writeln('Cannot open OLMS.CFG');
      Exit;
    End;

  If SizeOfFile('OLMS.CFG') <> Sizeof(OLDSETUPrecord) Then
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

  nd.AllowDownloadAttach         := od.AllowDownloadAttach;
  nd.AllowFiles                  := od.AllowFiles;
  nd.AllowFileScan               := od.AllowFileScan;
  nd.AllowLogoff                 := od.AllowLogoff;
  nd.AllowRip                    := od.AllowRip;
  nd.AutoInternet                := od.AutoInternet;
  nd.AutoPackAttaches            := od.AutoPackAttaches;
  nd.BoardID                     := od.BoardID;
  nd.CapsWord                    := od.CapsWord;
  nd.CheckDupes                  := od.CheckDupes;
  nd.CheckHeaderDupes            := od.CheckHeaderDupes;
  nd.Dated                       := od.Dated;
  nd.DefaultPacketType           := od.DefaultPacketType;
  nd.DownloadAttachFree          := od.DownloadAttachFree;
  nd.DownloadAttachNoTime        := od.DownloadAttachNoTime;
  nd.FileBasePath                := od.FileBasePath;
  nd.GatewayAddress              := od.GatewayAddress;
  nd.GoodbyeFile                 := od.GoodbyeFile;
  nd.GoodValue                   := od.GoodValue;
  nd.GroupPick                   := od.GroupPick;
  nd.HelloFile                   := od.HelloFile;
  nd.InsertTag                   := od.InsertTag;
  nd.KillRep                     := od.KillRep;
  nd.KillSentNetmail             := od.KillSentNetmail;
  nd.Killtag                     := od.Killtag;
  nd.LocalDLPath                 := od.LocalDLPath;
  nd.LocalULPath                 := od.LocalULPath;
  nd.LogExpanded                 := od.LogExpanded;
  nd.LogFile                     := od.LogFile;
  nd.LogHeaders                  := od.LogHeaders;
  nd.LogMode                     := od.LogMode;
  nd.MainPath                    := od.MainPath;
  nd.Marked286                   := od.Marked286;
  nd.Marked86                    := od.Marked86;
  nd.MaxConference               := od.MaxConference;
  nd.MaxSlices                   := od.MaxSlices;
  nd.MsgBasePath                 := od.MsgBasePath;
  nd.NewsFile                    := od.NewsFile;
  nd.NodelistPath                := od.NodelistPath;
  nd.NumberDupes                 := od.NumberDupes;
  nd.Opening                     := od.Opening;
  nd.PhoneNumber                 := od.PhoneNumber;
  nd.Registration                := od.Registration;
  nd.RestrictTime                := od.RestrictTime;
  nd.Retear                      := od.Retear;
  nd.Screens                     := od.Screens;
  nd.Serial                      := od.Serial;
  nd.ShortStyle                  := od.ShortStyle;
  nd.ShortWord                   := od.ShortWord;
  nd.SingleNodeFlag              := od.SingleNodeFlag;
  nd.Sysop                       := od.Sysop;
  nd.SystemName                  := od.SystemName;
  nd.TagFile                     := od.TagFile;
  nd.TwoLevelMenu                := od.TwoLevelMenu;
  nd.UseSlice                    := od.UseSlice;
  nd.Version                     := od.Version;

  For w := 1 To 6 Do
    Begin
      nd.Compress[w]                    := od.Compress[w];
      nd.Decompress[w]                  := od.Decompress[w];
      nd.Transmit[w]                    := od.Transmit[w];
      nd.Receive[w]                     := od.Receive[w];
      nd.TransmitKeys[w]                := od.TransmitKeys[w];
      nd.TransmitNames[w]               := od.TransmitNames[w];
    End;

  For w := 1 To MaxBull Do
    Begin
      nd.Bulletins[w]                   := od.Bulletins[w];
      nd.BulletinNames[w]               := od.BulletinNames[w];
      nd.BulletinFlags[w]               := od.BulletinFlags[w];
    End;

  Move(od.SwappingControl,nd.SwappingControl,Sizeof(od.SwappingControl));

  For w := 1 To 7 Do nd.MaxPacket[w]     := od.MaxPacket[w];
  For w := 0 To 9 Do nd.Address[w]       := od.Address[w];
  For w := 1 To 2000 Do nd.SysopFlags[w] := od.SysopFlags[w];

  Write(fn,nd);
  CloseFile(fn);
  Erase(fo);
  Rename(fn,'OLMS.CFG');
  Writeln('Conversion complete.');

End;

Begin
  Writeln;
  {$IFDEF PROVERSION}
  Writeln('OLMS 2.0x/Shareware -> 2.50/Professional Evaluation Upgrade program');
  {$ELSE}
  Writeln('OLMS 2.0x/Shareware -> 2.50/Shareware Upgrade program');
  {$ENDIF}
  Writeln('Copyright Multiboard Communications Centre and Pete Rocca, 1994-1995');
  Writeln('อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ');
  ConvertUsers;
  ConvertSetup;
End.