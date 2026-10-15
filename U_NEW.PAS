Unit U_NEW;

Interface

Uses DM6000;

{$I BBSTYPE.INC}
{$I BWAVE212.INC}

Const
  {$IFDEF PROVERSION}
  Version = '2001';
  ShortVersion = '2001';
  {$ELSE}
  DO NOT COMPILE IN NON-PRO VERSION
  Version = '2.8.b1';
  ShortVersion = '2.8.b1';
  {$ENDIF}

  SolidLine      = 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ';
  DottedLine     = '-------------------------------------------------------------------------------';

  WRAP_TEXT_THRESH = 79;

  MSG_EVALUATE   = 'Evaluation';

  typeCompress   = 1;
  typeDecompress = 2;
  typeTransmit   = 3;
  typeReceive    = 4;

  COL_INPUTFORE  = 0;
  COL_INPUTBACK  = 1;
  COL_PRESSSPACE = 2;
  COL_TITLE      = 3;
  COL_ERROR      = 4;
  COL_LINE       = 5;
  COL_QUESTION   = 6;
  COL_DATA       = 7;
  COL_PROMPT     = 8;
  COL_CONFNUM    = 9;
  COL_CONFNAME   = 10;
  COL_CONFFLAG   = 11;
  COL_TEXT       = 12;
  COL_OPTION     = 13;
  COL_MODE       = 14;
  COL_SPIN       = 15;
  COL_LOGOFF     = 16;
  COL_GOOD       = 17;
  COL_LASTTIME   = 18;
  COL_NEW        = 19;
  COL_PACK       = 20;
  COL_HOW        = 21;
  COL_INFO       = 22;
  COL_VALUE      = 23;
  COL_NOPACK     = 24;
  COL_TOPACK     = 25;
  COL_FILES      = 26;
  COL_WORK       = 27;
  COL_REPTO      = 28;
  COL_YESNO      = 29;
  COL_PRIVATE    = 30;

  BWVERSION = 3;

  EXTTYPE : Array [1..3] Of String[4] = ('.ASC','.ANS','.RIP');

  ptQWK     = 0;
  ptQWKE    = 1;
  ptQWKX    = 2;
  ptBWAVE   = 3;

  nCRASH    =   1;
  nFATCH    =   2;
  nHOLD     =   4;
  nIMM      =   8;
  nDIRECT   =  16;
  nFREQ     =  32;
  nUNKNOWN  = 128;  (* Used to flag not determined yet *)
  nRRQ      = 256;

  fGENERAL  =   1;
  fPERSONAL =   2;
  fALL      =   4;
  fSELF     =   8;
  fKEYWORD  =  16;
  fFILTER   =  32;
  fCONNECT  =  64;
  fNETWORK  = 128;

  bINACTIVE =   0;
  bNORMAL   =   1;
  bFORCED   =   2;
  bNEWONLY  =   3;

  sFORCED   =   1;
  sBLOCKED  =   2;
  sHIDDEN   =   4;
  sNOTAG    =   8;
  sKEEPTO   =  16;
  sDEFAULT  =  32;

  cFATCH    =   4;
  cALIAS    =   8;
  cSOFTCR   =  16;
  cHANDLE   =  32;
  cJAM      = 128;
  cAGROUPS  =   1;

  HMB_DELETED     =   1;
  HMB_UNETMAIL    =   2;
  HMB_NETMAIL     =   4;
  HMB_PRIVATE     =   8;
  HMB_RECEIVED    =  16;
  HMB_UECHOMAIL   =  32;
  HMB_LOCAL       =  64;
  HMB_KILL        =   1;
  HMB_SENT        =   2;
  HMB_FILE        =   4;
  HMB_CRASH       =   8;
  HMB_FREQ        = 128;

  BW_NOCOLOR      =  72;

  MonthDays : Array[1..13] Of Word = (0,31,59,90,120,151,181,212,243,273,304,334,365);

  IDX = 0;
  HDR = 1;
  TXT = 2;
  NFO = 3;
  MTO = 4;
  LRD = 5;

  FTIMAX_WAV  =    50;
  IDXMAX_WAV  =   256;
  DATMAX_WAV  = 30720;
  BUFMAX_USR  =  8192;
  IDXMAX_QWK  =   256;

  MaxLang     = 185;
  MaxFilters  =  45;
  MaxKeywords =  45;
  MaxTwits    =  45;
  MaxRequests =  30;
  MaxColors   =  30;
  TextBufferSize = 64000;
  WeekString: String[14] = 'SUMOTUWETHFRSA';
  Conversions: String[50] = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZZZZZZ';
  PacketFormatString: Array[0..3] Of String[12] = ('QWK','QWKE','QWK2 (n/a)','BlueWave');
  {$IFDEF PROVERSION}
    {$IFDEF LOWMEMORY}
    MaxAreas =  5000;
    {$ELSE}
    MaxAreas = 10000;
    {$ENDIF}
  {$ELSE}
  MaxAreas    = 2000;
  {$ENDIF}
  MaxGroups   = 100;
  MaxBull     = 18;

  Colors: Array[0..MaxColors] Of Byte
          = (15,4,15,15,12,4,15,7,7,14,15,7,15,7,14,14,
             11,10,8,14,14,7,14,15,11,11,11,14,7,15,14);

Type
  pFTIBUF_WAV = ^tFTIBUF_WAV;
  tFTIBUF_WAV = Array[0..FTIMAX_WAV*Sizeof(FTI_RECORD)] Of Char;

  pDATBUF_WAV = ^tDATBUF_WAV;
  tDATBUF_WAV = Array[0..DATMAX_WAV] Of Char;

  Pbuf = ^Tbuf;
  TBuf = Array[0..TextBufferSize+1500] Of Char;

  Time           = String[5];
  Date           = String[8];
  MsgType        = (LocalMail, NetMail, EchoMail, Internet, Usegroup );
  MsgKindsType   = (kBoth, kPrivate, kPublic, kReadOnly, kNoReply);
  FlagType       = Array[1..4] of Byte;
  Array6Byte     = Array[1..6] Of Byte;
  MSB            = Array[0..3] Of Byte;

  RECEIVEDIDXrecord = Record
                       Conf: Word;
                       Data: Longint;  {either NNNN (jam) or NNOO (hudson)}
                     End;

  LASTREADrecord = array[1..200] of Word;

  FASTINDEXrecord =  Word;

  MESSAGECONTROLrecord = Record
                           Name           : String[40];
                           Typ            : MsgType;
                           MsgKinds       : MsgKindsType;
                           Age,
                           Attribute,
                           Attribute2     : Byte;
                           Group          : Word;
                           AltGroup       : Array[1..3] of Word;
                           Security       : Word;
                           Flag,
                           NotFlag        : FlagType;
                         End;

  OLFrecord      = Record
                     Name: String[20];
                     Filename, ScreenPath: String[60];
                     DateMade, DateEdit: String[8];
                     Active: Boolean;
                     Extra: Array[1..94] Of Byte;
                   End;

  NetAddress     = Record
                     Zone,
                     Net,
                     Node,
                     Point          : Word;
                   End;

  CONFIGrecord =   Record
    VersionID           : Word;
    Junk1               : Array[1..932] Of Byte;
    NodelistPath        : String[60];
    MsgBasePath         : String[60];
    Junk2               : Array[1..122] Of Byte;
    Address             : Array[0..9] of NetAddress;
    SystemName          : String[30];
    Junk3               : Array[1..8] Of Byte;
    OriginLine          : String[60];
    Junk4               : Array[1..16] Of Byte;
    Sysop               : String[35];
    Junk5               : Array[1..69] Of Byte;
    Timeout             : Word;
    Junk5a              : Array[72..137] Of Byte;
    LogStyle            : Byte;
    Junk6               : Array[139..1679] Of Byte;
    FileBasePath        : String[60];
  End;

  SETUPrecord = Record
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
                  {$IFDEF LOWMEMORY}
                  SysopFlags                    : Array[1..10000] Of Byte;
                  {$ELSE}
                  SysopFlags                    : Array[1..MaxAreas] Of Byte;
                  {$ENDIF}
                  BulletinNames                 : Array[1..MaxBull] Of String[40];
                  BulletinFlags                 : Array[1..MaxBull] Of Byte;
                  ProActivated                  : Byte;
                  ProDated                      : Word;
                  KeepKludges                   : Byte;    (* 0 = No, 1 = Yes, 2 = Yes/BW *)
                  IncSelfInForced               : Boolean; (* No = a...F, Yes = aw..F *)
                  NetmailCrash                  ,
                  NetmailFatch                  ,
                  NetmailHold                   ,
                  NetmailImm                    ,
                  NetmailFreq                   ,
                  NetmailDirect                 : Word;
                  Gloat                         : Boolean;
                  MinuteCol                     : Byte;
                  UNUSED                        : Array[17..216] Of Byte;
                End;

  USERrecord =     Record
                     Revision                   : Longint;
                     Name                       : String[35];
                     LocalName                  : String[8];
                     LastDateDownload           : Date;
                     LastTimeDownload           : Time;
                     LastFileScan               : Longint;
                     Archiver,
                     Protocol                   : Char;
                     QWKID,
                     RecordNumber,
                     MaxPacket,
                     MaxConference,
                     TotalFilesDownloaded,
                     TotalDownloads,
                     CurrentExtension           : Word;
                     Indexes,
                     Files,
                     KeepKludge,
                     News,
                     GlobalKeywords,
                     GlobalPersonal,
                     FilterPersonal,
                     TwitPersonal,
                     ShortList,
                     Del,
                     IgnoreLimits,
                     UseHigh,
                     GetWelcome,
                     NumericExtension           : Boolean;
                     Bulletins                  : Array[0..3] Of Byte;
                     PacketType,
                     TodayDownloads,
                     TodayFileDownloads,
                     FilesQueued                : Byte;
                     VacationMode               : Boolean;
                     ColorFilelistingInBlueWave : Byte; (* 72 = No *)
                     UNUSED                     : Array[2..753] Of Byte;
                     FileQueue                  : Array[1..MaxRequests] Of String[12];
                     FileQueueAttached          : Array[1..MaxRequests] Of Boolean;
                     Filters                    : Array[1..MaxFilters] Of String[20];
                     Keywords                   : Array[1..MaxKeywords] Of String[20];
                     Twits                      : Array[1..MaxTwits] Of String[25];
                     Flags                      : Array[1..MaxAreas] Of Byte;
                   End;



  MESSAGErecord  = Record
                     AreaNum        : Word;
                     FreeSpace1     : Word;
                     Name           : String[40];
                     Typ            : MsgType;
                     MsgKinds       : MsgKindsType;
                     Attribute      : Byte;
                     DaysKill,
                     RecvKill       : Byte;
                     CountKill      : Word;

                     ReadSecurity   : Word;
                     ReadFlags,
                     ReadNotFlags   : FlagType;

                     WriteSecurity  : Word;
                     WriteFlags,
                     WriteNotFlags  : FlagType;

                     SysopSecurity  : Word;
                     SysopFlags,
                     SysopNotFlags  : FlagType;

                     OriginLine     : String[60];
                     AkaAddress     : Byte;
                     Age            : Byte;
                     JAMbase        : String[60];
                     Group          : Word;
                     AltGroup       : Array[1..3] of Word;
                     Attribute2     : Byte;
                     Netreply       : Word;
                     FreeSpace2     : Array[3..9] of Byte;
                   End;


  MSGINFOrecord  = Record
                     LowMsg,
                     HighMsg,
                     TotalMsgs      : Word;
                     TotalOnBoard   : array[1..200] of Word;
                   End;

  MSGIDXrecord   = Record
                     MsgNum         : Integer;
                     Board          : Byte;
                   End;

  MSGTOIDXrecord = String[35];

  MSGHDRrecord   = Record
                     MsgNum         : Integer;
                     PrevReply,
                     NextReply,
                     TimesRead      : Word;
                     StartBlock     : Word;
                     NumBlocks,
                     DestNet,
                     DestNode,
                     OrigNet,
                     OrigNode       : Word;
                     DestZone,
                     OrigZone       : Byte;
                     Cost           : Word;
                     MsgAttr,
                     NetAttr,
                     Board          : Byte;
                     PostTime       : Time;
                     PostDate       : Date;
                     WhoTo,
                     WhoFrom        : MSGTOIDXrecord;
                     Subject        : String[72];
                   End;

  MSGTXTrecord   = String[255];

  LIMITSrecord   = Record
                     Security,
                     LTime,
                     L300,
                     L1200,
                     L2400,
                     L4800,
                     L7200,
                     L9600,
                     L12000,
                     L14400,
                     L16800,
                     L19200,
                     L38400,
                     LLocal,
                     RatioNum,
                     RatioK         : Word;
                     PerMinCost     : Real;
                     FreeSpace      : Array[1..42] Of Byte;
                   End;

  GROUPrecord    = Record
                     AreaNum        : Word;
                     Name           : String[40];
                     Security       : Word;
                     Flags,
                     NotFlagsMask   : FlagType;
                     FreeSpace      : Array[1..100] Of Byte;
                   End;

  FILESrecord    = Record
                     AreaNum        : Word;
                     Unused         : Array[1..2] Of Byte;
                     Name           : String[40];
                     Attrib         : Byte;  { d8 = CDROM}
                     FilePath       : String[40];
                     KillDaysDL,
                     KillDaysFD     : Word;
                     Password       : String[15];
                     MoveArea       : Word;
                     Age,
                     ConvertExt     : Byte;
                     Group          : Word;
                     Attrib2        : Byte;
                     DefCost,
                     UploadArea,
                     UploadSecurity : Word;
                     UploadFlags,
                     UploadNotFlags : FlagType;
                     Security       : Word;
                     Flags,
                     NotFlags       : FlagType;
                     ListSecurity   : Word;
                     ListFlags,
                     ListNotFlags   : FlagType;
                     AltGroup       : Array[1..3] Of Word;
                     Device         : Byte;
                     FreeSpace      : Array[1..13] Of Byte;
                   End;

  FILESHDRrecord = Record
                     Name           : String[12];
                     Size,
                     CRC32          : LongInt;
                     Uploader       : String[35];
                     UploadDate,
                     FileDate,
                     LastDL         : LongInt;
                     TimesDL        : Word;
                     Attrib         : Byte;
                     Password       : String[15];
                     KeyWord        : Array[1..5] Of String[15];
                     Cost           : Word;
                     LongDescPtr    : LongInt;
                     FreeSpace      : Array[1..20] Of Byte;
                   End;

  QWKTXTrecord   = Array[0..127] Of Char;

  QWKDATrecord   = Record
                     Status: Char;
                     MsgNum: Array[0..6] Of Char;
                     MsgDate: Array[0..7] Of Char;
                     MsgTime: Array[0..4] Of Char;
                     WhoTo, WhoFrom, Subject: Array[0..24] Of Char;
                     Password: Array[0..11] Of Char;
                     MsgRefNum: Array[0..7] Of Char;
                     NumBlocks: Array[0..5] Of Char;
                     Flag: Char;
                     Conf, Number: Word;
                     TagLine: Char;
                   End;

  QWKIDXrecord   = Record
                     Pos: MSB;
                     Conf: Byte;
                   End;

Type
  RPbuf = ^RTbuf;
  RTbuf = String[160];
  LanguageTextType = Array[1..MaxLang] Of RPbuf;

  pw1000 = ^tw1000;
  tw1000 = Array [1..1000] Of Word;
  FastIndexType = Array[1..MaxAreas DIV 1000] Of pw1000;

  pUSERrecord = ^USERrecord;
  pSETUPrecord = ^SETUPrecord;

Var
  MaxNodesSupported: Byte;
  SIZE_USERS: Word;
  FastIndex_PartlyLoaded, FastIndex_CompletelyLoaded: Boolean;
  FastIndex_CurrentLow, FastIndex_CurrentHigh: Word;
  FastIndex: FastIndexType;
  DATMEM_WAV: Word;
  fCFG: File;
  ReceivedMessageIndex: Array[1..255] Of RECEIVEDIDXrecord;
  ReceivedMessages: Byte;
  dRDX: Array[1..MaxAreas] Of Word;
  MSGBUF: Pbuf;
  DefaultOriginLine: String[60];
  LastMsgId: Longint;
  MAXLEN_WHO, MAXLEN_SUB: Byte;
  CR: Char;
  MAXPCONF, CNew, CPack, CPersonal, CKeyword, CFilter: Word;
  MAXPPACK, PPack, PPersonal: Word;
  PNew, PKeyword, PFilter: Longint;
  CurrentBufferSize: Word;
  Alias, Name: String[35];
  PvtRights, BlueWave: Boolean;
  PackedMessage: Array[0..MaxAreas DIV 8 +1] Of Byte;
  fDAT, fFTI: File;
  fQWKM: File;
  dQWKD: QWKDATrecord;
  dQWKT: QWKTXTrecord;
  dFTI : FTI_RECORD;
  Index: Real;
  FTIBUF_WAV: pFTIBUF_WAV;
  FTILOC_WAV: Word;
  DATBUF_WAV: pDATBUF_WAV;
  DATLOC_WAV: Word;
  IDXBUF_WAV: Array[1..IDXMAX_WAV] Of MIX_RECORD;
  IDXLOC_WAV: Word;
  IDXCNF_QWK: Word;
  IDXBUF_QWK: Array[1..IDXMAX_QWK] Of QWKIDXrecord;
  IDXLOC_QWK: Word;
  BlueWaveLength: Longint;

  PIDName: String[35];
  LanguageText: LanguageTextType;
  ScreenDir: String[128];
  HotKey: Array[1..24] Of Char;
  Setup: pSETUPrecord;
  Human: pUSERrecord;
  DownloadRequestedOnly, Bootem, Reg, FLAG_BufferFull, Wait: Boolean;
  BaudRange: Byte;
  MultiNode, NotReg, CreateNewJam: Boolean;
  Menu0, Menu1, Menu2, Menu3, Menu4, OrgAdrStr: String[25];
  StartDir, DataDir, WorkDir, MainDir: String[100];
  UserAge, HighMessageGroup: Byte;
  RA250, XorReg, WasInReg: Boolean;
  Groups: Array[0..MaxGroups] Of Byte;
  GroupNames: Array[0..MaxGroups] Of String[40];
  GlobalPendingFiles: Byte;
  WhoCaresReg: Boolean;
  Username_CRC, GlobalPendingBytes, GlobalPendingCredits: Longint;
  ProtString, ArcString: String[6];
  BBS_CC: String[5];
  HighConf, NumConf: Word;
  DefaultSwapShellMethod: Word;
  SS_Value, SS_Increment: Word;
  SS_Active: Boolean;

Function  Is(a,b: Word): Boolean;
Function  Isl(a,b: Longint): Boolean;
Function  ConferenceNumber(w: Word): Word;
Function  ConferenceLocation(w: Word): Word;
Function  ValidConference(w: Word): Boolean;
Function  GetAddress(st: String; Var Zone, Net, Node, Pnt: Word): Boolean;
Function  PutAddress(Var st: String; Zone, Net, Node, Pnt: Word): Boolean;
Function  LenBuf(Var Buffer: Array Of Char): Word;
Procedure CString(Var Buffer: Array Of Char; Convert: String);
Function  PString(Var Buffer: Array Of Char): String;
Function  InsertBuffer(Loc, Len: Word; st: String): Word;
Function  InsertKludge(Name: String; Var Data: String; Offset: Word): Word;
Function  IsKeyworded(Var WhoFrom, WhoTo: String; Subject: String): Boolean;
Function  IsFiltered(Var WhoFrom, WhoTo: String; Subject: String): Boolean;
Function  IsTwited(WhoFrom: String): Boolean;
Function  IsWritten(WhoFrom: String): Boolean;
Function  IsPersonal(WhoTo: String): Boolean;
Function  CheckFilterKeyword(Var WhoFrom, WhoTo, Subject: String;
                            Personal, Pack, Maybe: Boolean; Conf: Word; Flags: Byte): Boolean;
Function  StringInBuffer(Data: String; Size: Word): Word;
Procedure UpdatePackStatus;
Function  WrapText(Len: Word; IsNetmail: Boolean): Word;     (* cannot exceed 64k message *)
Procedure StrBuf(st: String; Var Buf: Array Of Char; Len: Byte);
Procedure BufStr(Var Buf: Array Of Char; Var st: String; Len: Byte);
Procedure DiskWrite_MIX;
Procedure Write_MIX(Conf,TotMsg,PerMsg,MsgOffSet: Word);
Procedure DiskWrite_FTI;
Procedure Write_FTI(Var d: FTI_RECORD);
Procedure DiskWrite_DAT;
Procedure Write_DAT(l: Word);
Procedure Write_QWKPersonalIndex(Conf: Word; Index: Real; Blocks: Word);
Procedure DiskWrite_QWKIndex;
Procedure Write_QWKIndex(Conf: Word; Var Index: Real; Blocks: Word);
Procedure RealToMSB(rValue: Real; Var mBuffer: MSB);
Procedure AddAttach(c: Word; n: Longint);

Procedure SaveStat_Init;
Procedure SaveStat_Close;
Procedure SaveStat_Display;
Procedure SaveStat_Complete;

Implementation

Function Is(a,b: Word): Boolean;
Begin
  Is := (A And B) = B;
End;

Function Isl(a,b: Longint): Boolean;
Begin
  Isl := (A And B) = B;
End;

Function ConferenceNumber(w: Word): Word;
Var
  CN, c, n: Word;
  fi: File;
Begin
  If RA250 Then
    Begin
      CN := 0;
      {$IFDEF PROVERSION}
      If FastIndex_CompletelyLoaded Then
        Begin
          CN := FastIndex[(w-1) DIV 1000+1]^[(w-1) MOD 1000+1];
        End
      Else If FastIndex_PartlyLoaded Then
        Begin
          If (w<FastIndex_CurrentLow) Or (w>FastIndex_CurrentHigh) Then
            Begin
              If OpenFile(fi,MainDir+'MESSAGES.IDX','R',Sizeof(FASTINDEXrecord),faReadOnly+faDenyNone) Then
                Begin
                  Seek(fi,w-1);
                  BlockRead(fi,FastIndex[1]^,1000,n);
                  CloseFile(fi);
                  FastIndex_CurrentLow  := w;
                  FastIndex_CurrentHigh := w + n - 1;
                  CN := FastIndex[1]^[1];
                End;
            End
          Else
            Begin
              CN := FastIndex[1]^[w-FastIndex_CurrentLow+1];
            End;
        End;
      {$ENDIF}

      If CN = 0 Then
        Begin
          n := 0;
          For c := 1 To HighConf Do If dRDX[c]=w Then
            Begin
              n := c;
              c := HighConf;
            End;
          CN := n;
        End;
    End
  Else CN := w;

  ConferenceNumber := CN;
End;

Function ConferenceLocation(w: Word): Word;
Begin
  If (w<1) Or (w>HighConf) Then ConferenceLocation := 0
  Else If RA250 Then ConferenceLocation := dRDX[w]
  Else ConferenceLocation := w;
End;

Function ValidConference(w: Word): Boolean;
Var
  x: Word;
Begin
  x := ConferenceLocation(w);
  If (x<1) Or (x>NumConf) Then ValidConference := False
                          Else ValidConference := True;
End;

Function GetAddress(st: String; Var Zone, Net, Node, Pnt: Word): Boolean;
Var
  a,b,c: Byte;
  i: Integer;
Begin
  GetAddress := False;
  If Pos(' ',st) <> 0 Then st := Copy(st,1,Pos(' ',st)-1);
  For a := 1 To Length(st) Do If st[a] = '\' Then st[a] := '/';
  If st[1] <> '@' Then Exit;
  a := Pos(':',st);
  b := Pos('/',st);
  c := Pos('.',st);
  Val(Copy(st,2,a-2),Zone,i);        If i <> 0 Then Exit;
  Val(Copy(st,a+1,b-a-1),Net,i);     If i <> 0 Then Exit;
  If c = 0 Then
    Begin
      Val(Copy(st,b+1,255),Node,i);  If i <> 0 Then Exit;
      Pnt := 0;
    End
  Else
    Begin
      Val(Copy(st,b+1,c-b-1),Node,i); If i <> 0 Then Exit;
      Val(Copy(st,c+1,255),Pnt,i);    If i <> 0 Then Exit;
    End;
  GetAddress := True;
End;

Function PutAddress(Var st: String; Zone, Net, Node, Pnt: Word): Boolean;
Var
  Adr: String[35];
Begin
  Adr := Zeropad(Zone,0)+':'+ZeroPad(Net,0)+'/'+ZeroPad(Node,0);
  If Pnt > 0 Then Adr := Adr + '.' + Zeropad(Pnt,0);
  st := Adr;
  PutAddress := True;
End;

Function LenBuf(Var Buffer: Array Of Char): Word;
Var
  Counter: Word;
Begin
  Counter := 0;
  While Buffer[Counter] <> #0 Do Inc(Counter);
  LenBuf := Counter;
End;

Procedure CString(Var Buffer: Array Of Char; Convert: String);
Var
  Counter: Word;
Begin
  For Counter := 1 To Length(Convert) Do Buffer[Counter-1] := Convert[Counter];
  Buffer[Counter] := #0;
End;

Function PString(Var Buffer: Array Of Char): String;
Var
  Len: Word;
  st: String;
Begin
  Len := LenBuf(Buffer);
  Move(Buffer,st[1],Len);
  st[0] := Chr(Byte(Len));
  PString := st;
End;

(*
Function InsertBuffer(Loc, Len: Word; st: String): Word;
Var
  Offset, C: Word;
Begin
  Offset := Length(st);
  For C := Len+Offset-1 Downto Loc+Offset-1 Do MSGBUF^[C] := MSGBUF^[C-Offset];
  For C := Loc To Loc+Offset-1 Do MSGBUF^[C-1] := st[C-Loc+1];
  InsertBuffer := Len + Offset; {IDEA! Speed up, Movemem?}
End;
*)

Function InsertBuffer(Loc, Len: Word; st: String): Word;
Var
  Offset, C: Word;
Begin
  Offset := Length(st);
  Move(MSGBUF^[Loc],MSGBUF^[Loc+Offset],Len-Loc+1);
  Move(st[1],MSGBUF^[Loc],Offset);
  InsertBuffer := Len + Offset;
End;

Function InsertKludge(Name: String; Var Data: String; Offset: Word): Word;
Var
  d: String;
Begin
  d := Name+' '+Data+CR;
  InsertKludge := InsertBuffer(OffSet,OffSet,d);
End;

Function IsKeyworded(Var WhoFrom, WhoTo: String; Subject: String): Boolean;
Var
  Keyworded: Boolean;
  Place: Byte;
Begin
  Subject := UpcaseStr(Subject);
  Keyworded := False;
  For Place := 1 To MaxKeywords Do
    Begin
      If (Human^.Keywords[Place][0] <> #0) And Not Keyworded Then
        Begin
          If Pos(Human^.Keywords[Place],Subject) <> 0 Then Keyworded := True
          Else If Pos(Human^.Keywords[Place],WhoFrom) <> 0 Then Keyworded := True
          Else If Pos(Human^.Keywords[Place],WhoTo) <> 0 Then Keyworded := True
          Else Keyworded := (StringInBuffer(Human^.Keywords[Place],CurrentBufferSize) <> $FFFF);
        End;
    End;
  IsKeyworded := Keyworded;
End;

Function IsFiltered(Var WhoFrom, WhoTo: String; Subject: String): Boolean;
Var
  Filtered: Boolean;
  Place: Byte;
Begin
  Subject := UpcaseStr(Subject);
  Filtered := False;
  For Place := 1 To MaxFilters Do
    Begin
      If (Human^.Filters[Place][0] <> #0) And Not Filtered Then
        Begin
          If Pos(Human^.Filters[Place],Subject) <> 0 Then Filtered := True
          Else If Pos(Human^.Filters[Place],WhoFrom) <> 0 Then Filtered := True
          Else If Pos(Human^.Filters[Place],WhoTo) <> 0 Then Filtered := True
          Else Filtered := (StringInBuffer(Human^.Filters[Place],CurrentBufferSize) <> $FFFF);
        End;
    End;
  IsFiltered := Filtered;
End;

Function IsTwited(WhoFrom: String): Boolean;
Var
  Twited: Boolean;
  Place: Byte;
Begin
  Twited := False;
  For Place := 1 To MaxTwits Do
    If (Human^.Twits[Place] <> '') And (WhoFrom=Human^.Twits[Place]) Then Twited := True;
  IsTwited := Twited;
End;

Function IsWritten(WhoFrom: String): Boolean;
Begin
  If (WhoFrom = Name) Or (WhoFrom = Alias) Then IsWritten := True Else IsWritten := False;
End;

Function IsPersonal(WhoTo: String): Boolean;
Begin
  If (WhoTo = Name) Or (WhoTo = Alias) Then IsPersonal := True Else IsPersonal := False;
End;

Function CheckFilterKeyword(Var WhoFrom, WhoTo, Subject: String;
                            Personal, Pack, Maybe: Boolean; Conf: Word; Flags: Byte): Boolean;
Var
  Filtered, Keyworded: Boolean;
Begin
   If IsTwited(WhoFrom)
  And (Not Personal Or Human^.TwitPersonal)
  And Not Is(Setup^.SysopFlags[Conf],sFORCED) Then
    Begin
      Inc(PFilter);
      Inc(CFilter);
      CheckFilterKeyword := False;
      Exit;
    End;

  If Is(Flags,fFILTER) Then
    Begin
      If Not Personal Or Human^.FilterPersonal Then Filtered := IsFiltered(WhoFrom,WhoTo,Subject)
      Else Filtered := False;
    End
  Else Filtered := False;

  If Is(Flags,fKEYWORD) Or Human^.GlobalKeywords Then
    Begin
      If Filtered Or (Maybe And Not Pack) Then
        Begin
          Keyworded := IsKeyworded(WhoFrom,WhoTo,Subject);
          If Keyworded Then Filtered := False;
        End
      Else Keyworded := False;
    End
  Else Keyworded := False;

  If Filtered Then
    Begin
      Inc(PFilter);
      Inc(CFilter);
      Pack := False;
    End
  Else If Keyworded Then
    Begin
      Inc(PKeyword);
      Inc(CKeyword);
      Pack := True;
    End;

  If Pack And Personal Then
    Begin
      Inc(PPersonal);
      Inc(CPersonal);
    End;

  If Pack Then
    Begin
      Inc(PPack);
      Inc(CPack);
      UpdatePackStatus;
    End;

  CheckFilterKeyword := Pack;
End;

Function StringInBuffer(Data: String; Size: Word): Word;
Var
  Match, Count: Word;
  Len: Byte;
  OFF, DTA, MSG: Word;
Begin
  Len := Byte(Data[0]);
  Count := Size-Len+1;
  MSG := Seg(MSGBUF^);
  DTA := Seg(Data[1]);
  OFF := Ofs(Data[1]);

  Asm
    push ds
    push es

    MOV  cx,Count                               (* cx = Size-Len        *)
    MOV  bx,0                                   (* bx = Count           *)
    MOV  ah,Len                                 (* ah = Len Data        *)
    MOV  ds,MSG
    MOV  es,DTA

  @@Next:
    XOR  al,al                                  (* al = #Correct        *)
    MOV  di,OFF
    XOR  si,si
    ADD  si,bx

  @@Compare:
    MOV  dh,ds:[si]
    CMP  dh,'a'
    JL   @@SkipUpper
    CMP  dh,'z'
    JG   @@SkipUpper
    SUB  dh,20h

  @@SkipUpper:
    CMP  dh,es:[di]
    JNE  @@Skip
    INC  al                                     (* number correct++     *)
    CMP  al,ah                                  (* matches Len?         *)
    JGE  @@Match
    INC  si                                     (* array offset++       *)
    INC  di                                     (* string offset++      *)
    JMP @@Compare                               (* get next char        *)

  @@Skip:
    INC  bx                                     (* bx = Count++         *)
    LOOP @@Next
    MOV  Match,$FFFF                            (* Not found            *)
    JMP  @@End

  @@Match:
    MOV  Match,bx                               (* Found at offset..    *)

  @@End:
    pop es
    pop ds
  End;
  StringInBuffer := Match;
End;

Procedure UpdatePackStatus;
Begin
  BarMessage := lZeroPad(PNew,-6) + 'ù' + ZeroPad(PPack,0);
  DisplayStatusBar;
End;

Function WrapText(Len: Word; IsNetmail: Boolean): Word;     (* cannot exceed 64k message *)
Const
  KLUDGE_KEEP    = 0;
  KLUDGE_DELETE  = 1;
  KLUDGE_MSGID   = 2;
  KLUDGE_CONVERT = 3;
Label
  KillKludge;
Var
  st: String[10];
  LastSpace, Offset, Counter, Holder: Word;
  Keep, Xpos: Byte;
  Del: Boolean;
Begin

   If (Human^.KeepKludge)
   Or ((Setup^.KeepKludges = 1))
   Or ((Setup^.KeepKludges = 2) And BlueWave)
   Then
     Begin
       If BlueWave Then Keep := KLUDGE_KEEP Else Keep := KLUDGE_CONVERT;
     End
   Else
     Begin
       If (BlueWave And IsNetmail) Then Keep := KLUDGE_MSGID Else Keep := KLUDGE_DELETE;
     End;

  Inc(Len);
  MSGBUF^[Len] := #13;
  Xpos         := 0;
  LastSpace    := 0;
  Offset       := 0;

  While Offset <= Len Do
    Begin

      (* Removes LF and soft-CR's from text *)
      If MSGBUF^[Offset] In [#141,#10] Then
        Begin
          Move(MSGBUF^[Offset+1],MSGBUF^[Offset],Len-Offset);
          If Len > 0 Then Dec(Len);
        End;

      (* Replaces CR with QWK-CR 'ã' : NOTE Must be kept seperate from *)
      (* the above, otherise CR following a LF or sCR are not replaced *)
      If MSGBUF^[Offset] = #13 Then MSGBUF^[Offset] := CR;

      (* Handle ^A kludges *)
KillKludge:
      If (MSGBUF^[Offset] = #1) Then
        Begin

          Del := False;
          Case Keep Of
            KLUDGE_CONVERT : MSGBUF^[Offset] := '@';
            KLUDGE_DELETE  : Del := True;
            KLUDGE_MSGID   : Begin
                             st[0] := #6;
                             Move(MSGBUF^[Offset+1],st[1],6);
                             If st <> 'MSGID:' Then Del := True;
                             End;
          End;

          If Del Then
            Begin  (* delete the kludge line *)
              For Counter := Offset+1 To Len Do
                Begin
                  If MSGBUF^[Counter] In [CR,#13] Then
                    Begin
                      Move(MSGBUF^[Counter+1],MSGBUF^[Offset],Len-Counter+1);
                      Holder := Len-(Counter-Offset+1);
                      Counter := Len;
                      Len := Holder;
                      If MSGBUF^[Offset] = #13 Then MSGBUF^[Offset] := CR;
                    End;
                End;
              Goto KillKludge;
            End;
        End;

      (* It's a real character, increase Xpos *)
      Inc(Xpos);
      If MSGBUF^[Offset] In [' ',CR] Then
        Begin
          If (Xpos > WRAP_TEXT_THRESH) Then     (* word wrap *)
            Begin
              MSGBUF^[LastSpace] := CR;
              Xpos := Offset-LastSpace;
            End
          Else If MSGBUF^[Offset]=CR Then Xpos := 0;
          LastSpace := Offset;
        End;

      (* Next char *)
      Inc(Offset);
    End;

  (* Clear 128 characters after the end of the text, just in case *)
  FillChar(MSGBUF^[Abs(Len-2)],128,#32);

  (* Return new length *)
  WrapText := Len;
End;

Procedure StrBuf(st: String; Var Buf: Array Of Char; Len: Byte);
Var
  Remain, Count: Byte;
Begin
  If Length(st)>Len Then st := Copy(st,1,Len);
  If Length(st) > 0 Then For Count := 1 To Length(st) Do Buf[Count-1] := st[Count]
  Else Count := 0;
  For Remain := Count+1 To Len Do Buf[Remain-1] := #32;
End;

Procedure BufStr(Var Buf: Array Of Char; Var st: String; Len: Byte);
Var
  LastChar, Count: Byte;
  Temp: String;
Begin
  Temp := '';
  LastChar := 0;
  For Count := 1 To Len Do
    Begin
      Temp := Temp + Buf[Count-1];
      If Buf[Count-1] <> #32 Then LastChar := Count;
    End;
  st := Copy(Temp,1,LastChar);
End;

Procedure DiskWrite_MIX;
Var
  fMIX: File;
Begin
  If IDXLOC_WAV = 0 Then Exit;
  If OpenFile(fMIX,Setup^.BoardID+'.MIX','X',Sizeof(MIX_RECORD),faReadWrite+faDenyAll) Then
    Begin
      BlockWrite(fMIX,IDXBUF_WAV,IDXLOC_WAV);
      CloseFile(fMIX);
    End;
  IDXLOC_WAV := 0;
End;

Procedure Write_MIX(Conf,TotMsg,PerMsg,MsgOffSet: Word);
Begin
  Inc(IDXLOC_WAV);
  CString(IDXBUF_WAV[IDXLOC_WAV].AreaNum,ZeroPad(Conf,0));
  IDXBUF_WAV[IDXLOC_WAV].TotMessages := TotMsg;
  IDXBUF_WAV[IDXLOC_WAV].TotPersonal := PerMsg;
  IDXBUF_WAV[IDXLOC_WAV].OffSet      := Longint(Sizeof(FTI_RECORD)) * Longint(MsgOffSet);
  If IDXLOC_WAV >= IDXMAX_WAV Then DiskWrite_MIX;
End;

Procedure DiskWrite_FTI;
Begin
  If FTILOC_WAV = 0 Then Exit;
  BlockWrite(fFTI,FTIBUF_WAV^,FTILOC_WAV);
  FTILOC_WAV := 0;
End;

Procedure Write_FTI(Var d: FTI_RECORD);
Begin
  Move(d,FTIBUF_WAV^[FTILOC_WAV*Sizeof(FTI_RECORD)],Sizeof(FTI_RECORD));
  Inc(FTILOC_WAV);
  If FTILOC_WAV >= FTIMAX_WAV Then DiskWrite_FTI;
End;

Procedure DiskWrite_DAT;
Begin
  If DATLOC_WAV = 0 Then Exit;
  BlockWrite(fDAT,DATBUF_WAV^,DATLOC_WAV);
  DATLOC_WAV := 0;
End;

Procedure Write_DAT(l: Word);
Begin
  If l>=DATMEM_WAV Then
    Begin
      DiskWrite_DAT;
      BlockWrite(fDAT,MSGBUF^,l);
      {$IFDEF REALDEBUG}
      Logit('D','DEBUG: DFW L='+lZeroPad(l,-10));
      If DebugTest <> $12345678 Then Logit('C','DEBUG: Memory corruption detected');
      {$ENDIF}
    End
  Else
    Begin
      If (Longint(l)+Longint(DATLOC_WAV)>=Longint(DATMEM_WAV)) Then
        Begin
          {$IFDEF REALDEBUG}
          Logit('D','DEBUG: PWD L='+ZeroPad(l,-10) +' O='+ZeroPad(DATLOC_WAV,-10));
          {$ENDIF}
          DiskWrite_DAT;
        End;
      Move(MSGBUF^,DATBUF_WAV^[DATLOC_WAV],l);
      Inc(DATLOC_WAV,l);
      {$IFDEF REALDEBUG}
      If DebugTest <> $12345678 Then Logit('C','DEBUG: Memory corruption detected');
      {$ENDIF}
    End;
End;

Procedure Write_QWKPersonalIndex(Conf: Word; Index: Real; Blocks: Word);
Var
  fQWKI: File;
  dQWKI: QWKIDXrecord;
Begin
  If Human^.Indexes Then
    Begin
      If OpenFile(fQWKI,'PERSONAL.NDX','X',Sizeof(QWKIDXrecord),faReadWrite+faDenyAll) Then
        Begin
          dQWKI.Conf := Conf;
          RealToMSB(Index,dQWKi.Pos);
          BlockWrite(fQWKI,dQWKI,1);
          CloseFile(fQWKI);
        End;
    End;
End;

Procedure DiskWrite_QWKIndex;
Var
  fQWKI: File;
Begin
  If IDXLOC_QWK = 0 Then Exit;
  If OpenFile(fQWKI,ZeroPad(IDXCNF_QWK,3)+'.NDX','X',Sizeof(QWKIDXrecord),faReadWrite+faDenyAll) Then
    Begin
      BlockWrite(fQWKI,IDXBUF_QWK,IDXLOC_QWK);
      CloseFile(fQWKI);
    End;
  IDXLOC_QWK := 0;
End;

Procedure Write_QWKIndex(Conf: Word; Var Index: Real; Blocks: Word);
Begin
  If Human^.Indexes Then
    Begin
      If Conf <> IDXCNF_QWK Then
        Begin
          DiskWrite_QWKIndex;
          IDXCNF_QWK := Conf;
        End;
      Inc(IDXLOC_QWK);
      IDXBUF_QWK[IDXLOC_QWK].Conf := Conf;
      RealToMSB(Index,IDXBUF_QWK[IDXLOC_QWK].Pos);
      If IDXLOC_QWK >= IDXMAX_QWK Then DiskWrite_QWKIndex;
    End;
  Index := Index + Blocks;
End;

Procedure RealToMSB(rValue: Real; Var mBuffer: MSB);
Var
  rBuffer: Array [0..5] Of Byte Absolute rValue;
Begin
  mBuffer[3] := rBuffer[0];
  Move(rBuffer[3],mBuffer[0],3);
End;

Procedure AddAttach(c: Word; n: Longint);
Begin
  If Setup^.AutoPackAttaches Then
    Begin
      If Human^.FilesQueued >= MaxRequests Then
        Begin
          FLAG_BufferFull := True;
        End
      Else
        Begin
          Inc(Human^.FilesQueued);
          Human^.FileQueue[Human^.FilesQueued] := Zeropad(c,0)+' '+lZeroPad(n,0);
          Human^.FileQueueAttached[Human^.FilesQueued] := True;
        End;
    End;
End;

Procedure SaveStat_Init;
Begin
  SS_Increment := 10000 DIV (NumConf*2);
  SS_Value     := 0;
  SS_Active    := True;
End;

Procedure SaveStat_Close;
Begin
  SS_Active := False;
End;

Procedure SaveStat_Display;
Begin
  If SS_Active Then
    Begin
      Inc(SS_Value,SS_Increment);
      WriteString(#8+#8+#8+#8+ZeroPad(SS_Value DIV 100,-3)+'%');
    End;
End;

Procedure SaveStat_Complete;
Begin
  If SS_Active Then
    Begin
      WriteString(#8+#8+#8+#8+'100%');
    End;
End;

End.
