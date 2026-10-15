TYPE
  FlagType       = Array[1..4] of Byte;
  Time           = String[5];
  Date           = String[8];

  COMBINEDrecord = Array[1..200] of Word;

  MSGTOIDXrecord = String[35];

  USERSrecord    = Record
		     Name           : MSGTOIDXrecord;
		     Location       : String[25];
		     Organisation,
		     Address1,
		     Address2,
		     Address3       : String[50];
		     Handle         : String[35];
		     Comment        : String[80];
		     PasswordCRC    : LongInt;
		     DataPhone,
		     VoicePhone     : String[15];
		     LastTime       : Time;
		     LastDate       : Date;
		     Attribute,
		     Attribute2     : Byte;
		     Flags          : FlagType;
                     Credit,
                     Pending        : LongInt;
		     MsgsPosted,
		     Security       : Word;
                     LastRead,
                     NoCalls,
		     Uploads,
                     Downloads,
		     UploadsK,
                     DownloadsK,
                     TodayK         : LongInt;
                     Elapsed        : Integer;
                     ScreenLength   : Word;
                     LastPwdChange  : Byte;
                     Group          : Word;
                     CombinedInfo   : COMBINEDrecord;
                     FirstDate,
                     BirthDate,
                     SubDate        : Date;
                     ScreenWidth,
                     Language,
                     DateFormat     : Byte;
		     ForwardTo      : String[35];
		     MsgArea,
		     FileArea       : Word;
		     DefaultProtocol: Char;
		     FileGroup      : Word;
		     LastDOBCheck   : Byte;
		     Sex            : Byte;
		     XIrecord       : LongInt;
		     MsgGroup       : Word;
		     FreeSpace      : Array[1..48] of Byte;
		   end;

  USERSXIrecord  = record
                     FreeSpace      : Array[1..200] of Byte;
                   end;

  SYSINFOrecord  = record
                     TotalCalls     : LongInt;
                     LastCaller     : MSGTOIDXrecord;
                     ExtraSpace     : array[1..128] of Byte;
		   end;

  TIMELOGrecord  = record
                     StartDate      : Date;
		     BusyPerHour    : array[0..23] of Word;
		     BusyPerDay     : array[0..6] of Word;
		   end;

  EVENTrecord    = record
		     Status         : Byte;
		     StartTime      : Time;
		     ErrorLevel     : Byte;
                     Days           : Byte;
                     Forced         : Boolean;
                     LastTimeRun    : Date;
                   end;

  USERSXIrecord111 = Record
                     Handle         : String[35];
                     Comment        : String[80];
                     FirstDate      : Date;
                     CombinedInfo   : COMBINEDrecord;
                     BirthDate,
                     SubDate        : Date;
                     ScreenWidth,
                     MsgArea,
                     FileArea,
                     Language,
                     DateFormat     : Byte;
                     ForwardTo      : String[35];
                     ExtraSpace     : Array[1..43] of Byte;
                   End;


  USERSrecord111    = record
                     Name           : MSGTOIDXrecord;
                     Location       : String[25];
                     Password       : String[15];
                     DataPhone,
                     VoicePhone     : String[12];
                     LastTime       : Time;
                     LastDate       : Date;
                     Attribute      : Byte;
                     Flags          : FlagType;
                     Credit,
                     Pending        : Word;
                     MsgsPosted,
                     LastRead,
                     Security,
                     NoCalls,
                     Uploads,
                     Downloads,
                     UploadsK,
                     DownloadsK     : Word;
                     TodayK,
                     Elapsed        : Integer;
                     ScreenLength   : Word;
                     LastPwdChange,
                     Attribute2,
                     Group          : Byte;
                     XIrecord       : Word;
                     ExtraSpace     : array[1..3] of Byte;
                   end;

  EXITINFOrecord111 = record
                     Baud             : Word;
                     SysInfo          : SYSINFOrecord;
                     TimeLogInfo      : TIMELOGrecord;
                     U                : USERSrecord111;
                     EventInfo        : EVENTrecord;
                     NetMailEntered,
                     EchoMailEntered  : Boolean;
                     LoginTime        : Time;
                     LoginDate        : Date;
                     TimeLimit        : Word;
                     LoginSec,
                     Credit           : LongInt;
                     UserRecord       : Integer;
                     ReadThru,
                     NumberPages,
                     DownloadLimit    : Word;
                     TimeOfCreation   : Time;
                     LogonPassword    : String[15];
                     WantChat         : Boolean;
                     DeductedTime     : Integer;
                     MenuStack        : Array[1..50] of String[8];
                     MenuStackPointer : Byte;
                     UI               : USERSXIrecord111;
                     ErrorFreeConnect,
                     SysopNext        : Boolean;
                     EMSI_Session     : Boolean;        { These fields hold  }
                     EMSI_Crtdef,                       { data related to an }
                     EMSI_Protocols,                    { EMSI session       }
                     EMSI_Capabilities,
                     EMSI_Requests,
                     EMSI_Software    : String[40];
                     Hold_Attr1,
                     Hold_Attr2,
                     Hold_Len         : Byte;
                     ExtraSpace       : Array[1..100] of Byte;
                 end;

  EXITINFOrecord = record
                     Baud             : Word;
                     SysInfo          : SYSINFOrecord;
		     TimeLogInfo      : TIMELOGrecord;
		     U                : USERSrecord;
                     EventInfo        : EVENTrecord;
                     NetMailEntered,
		     EchoMailEntered  : Boolean;
                     LoginTime        : Time;
                     LoginDate        : Date;
		     TimeLimit        : Word;
                     LoginSec         : LongInt;
		     UserRecord       : Integer;
                     ReadThru,
                     NumberPages,
                     DownloadLimit    : Word;
                     TimeOfCreation   : Time;
                     LogonPasswordCRC : LongInt;
                     WantChat         : Boolean;

                     DeductedTime     : Integer;
                     MenuStack        : Array[1..50] of String[8];
                     MenuStackPointer : Byte;
		     UserXIinfo       : USERSXIrecord;
		     ErrorFreeConnect,
                     SysopNext        : Boolean;

		     EMSI_Session     : Boolean;
		     EMSI_Crtdef,
		     EMSI_Protocols,
		     EMSI_Capabilities,
                     EMSI_Requests,
                     EMSI_Software    : String[40];
                     Hold_Attr1,
                     Hold_Attr2,
                     Hold_Len         : Byte;

                     PageReason       : String[80];
                     StatusLine       : Byte;
                     LastCostMenu     : String[8];
                     MenuCostPerMin   : Word;

                     DoesAVT,
		     RIPmode          : Boolean;

		     ExtraSpace       : Array[1..86] of Byte;
		 end;
