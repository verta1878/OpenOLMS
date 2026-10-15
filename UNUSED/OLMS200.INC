Const
  Version = '2.02.b2';
  ShortVersion = '2.02.b2';

  SolidLine      = '컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�';
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

  BWVERSION = 2;

  EXTTYPE : Array [1..3] Of String[4] = ('.ASC','.ANS','.RIP');

  ptQWK   = 0;
  ptQWKE  = 1;
  ptQWKX  = 2;
  ptBWAVE = 3;

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

  HMB_DELETED     =  1;
  HMB_UNETMAIL    =  2;
  HMB_NETMAIL     =  4;
  HMB_PRIVATE     =  8;
  HMB_RECEIVED    = 16;
  HMB_UECHOMAIL   = 32;
  HMB_LOCAL       = 64;
  HMB_KILL        =  1;
  HMB_SENT        =  2;
  HMB_FILE        =  4;
  HMB_CRASH       =  8;

  MonthDays : Array[1..13] Of Word = (0,31,59,90,120,151,181,212,243,273,304,334,365);

  IDX = 0;
  HDR = 1;
  TXT = 2;
  NFO = 3;
  MTO = 4;
  LRD = 5;

  FTIMAX_WAV  =    75;
  IDXMAX_WAV  =   256;
  DATMAX_WAV  = 30720;
  BUFMAX_USR  =    10;

  IDXMAX_QWK  = 256;
{  DATMAX_QWK  = 250; }

  MaxLang     = 185;
  MaxFilters  =  15;
  MaxKeywords =  15;
  MaxTwits    =  15;
  MaxRequests =  10;
  MaxColors   =  30;
  TextBufferSize = 64000;
  WheelPic: String[4] = '\|/-';
  WeekString: String[14] = 'SUMOTUWETHFRSA';
  Conversions: String[50] = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZZZZZZ';
  PacketFormatString: Array[0..3] Of String[15] = ('QWK','QWKE','QWK2 (n/a)','BlueWave');
  MaxAreas    = 2000;
  MaxGroups   = 100;
  MaxBull     = 18;

  Colors: Array[0..MaxColors] Of Byte
          = (15,4,15,15,12,4,15,7,7,14,15,7,15,7,14,14,
             11,10,8,14,14,7,14,15,11,11,11,14,7,15,14);

Type
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
                  MinPacketTime: Byte;
                  AllowRip: Boolean;
                  SingleNodeFlag: Byte;  {Must be 200 for true}
                  UNUSEDSPACE1: Array[105..122] Of Byte;
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
                  DownloadAttachFree, DownloadAttachNotime: Boolean;
                  UNUSEDSPACE2: Array[98..439] Of Byte;
                  NodelistPath: String[60];
                  Address: Array[0..9] of NetAddress;
                  SystemName: String[30];
                  Sysop: String[35];
                  MsgBasePath,
                  MainPath,
                  FileBasePath: String[60];
                  SysopFlags: Array[1..MaxAreas] Of Byte;
                  BulletinNames: Array[1..MaxBull] Of String[40];
                  BulletinFlags: Array[1..MaxBull] Of Byte;
                  ShortWord, CapsWord, GroupPick: Boolean;
                  UNUSEDSPACE3: Array[4..84] Of Byte;
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

  USERrecord =     Record
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
                     FileQueue: Array[1..MaxRequests] Of String[12];
                     FileQueueAttached: Array[1..MaxRequests] Of Boolean;
                     TodayFileDownloads: Byte;
                     UNUSED: Array[155..250] Of Byte;
                     Filters: Array[1..MaxKeywords] Of String[20];
                     Keywords: Array[1..MaxFilters] Of String[20];
                     Twits: Array[1..MaxTwits] Of String[25];
                     Flags: Array[1..MaxAreas] Of Byte;
                   End;
