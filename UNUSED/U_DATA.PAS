Unit U_DATA;

Interface
{$I d:\zrel\olms\OLMS200.INC}
Type
  RPbuf = ^RTbuf;
  RTbuf = String;
  LanguageTextType = Array[1..MaxLang] Of RPbuf;

Var
  PIDName: String[35];
  LanguageText: LanguageTextType;
  ScreenDir: String[128];
  HotKey: Array[1..24] Of Char;
  Setup: SETUPrecord;
  Human: USERrecord;
  DownloadRequestedOnly, Bootem, Reg, FLAG_BufferFull, Wait: Boolean;
  BaudRange: Byte;
  MultiNode, NotReg, CreateNewJam: Boolean;
  Menu0, Menu1, Menu2, OrgAdrStr: String[25];
  StartDir, DataDir, WorkDir, MainDir: String[100];
  UserAge, HighMessageGroup: Byte;
  RA250, XorReg, WasInReg: Boolean;
  Groups: Array[0..MaxGroups] Of Byte;
  GroupNames: Array[0..MaxGroups] Of String[40];
  GlobalPendingFiles: Byte;
  WhoCaresReg: Boolean;
  OldBreak, OldStep, OldPrint: Procedure;
  Username_CRC, GlobalPendingBytes, GlobalPendingCredits: Longint;
  ProtString, ArcString: String[6];
  BBS_CC: String[5];
  FILEBUF: PBuf;
  HighConf, NumConf: Word;

Implementation
End.
ÿÿ