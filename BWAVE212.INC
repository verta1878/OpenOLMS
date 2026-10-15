(*
**  This header defines the data structures for the following files in the
**  official Blue Wave offline mail specification:
**
**      Door:       *.INF       BBS and message area information
**                  *.MIX       Quick index to *.FTI records
**                  *.FTI       Information for all packet messages
**                  *.DAT       Packet message text
**
**      Reader:     *.NET   x   NetMail reply message information
**                  *.UPI   x   Information for all other reply messages
**                  *.UPL       Reply message information (NEW)
**                  *.REQ       List of files to download from BBS
**                  *.PDQ       Offline door configuration information
**
**      Misc:       *.MSG   x   Fido-style message header (used *only* in the *.NET structure)
*)

Const
  {AreaFlags}
  INF_SELECTED      =    1;  { On=User is active for area               }
  INF_ALIASNAME     =    2;  { On=Alias name, Off=Login name            }
  INF_ANYNAME       =    4;  { On=Allow any name to be entered          }
  INF_ECHOAREA      =    8;  { On=Network area, Off=Local area          }
  INF_NETMAILAREA   =   16;  { On=Private network mail                  }
  INF_POST          =   32;  { On=User can post, Off=User CANNOT post   }
  INF_NOPRIVATE     =   64;  { On=Private messages are NOT allowed      }
  INF_NOPUBLIC      =  128;  { On=Public messages are NOT allowed       }
  INF_NOTAGLINE     =  256;  { On=Taglines are not allowed              }
  INF_NOHIGHBIT     =  512;  { On=ASCII 1-127 only, Off=ASCII 1-255     }
  INF_NOECHO        = 1024;  { On=User can prevent messages from being  }
  INF_CANFILEATTACH = 2048;  { On=User can attach files to messages     }
  INF_SELECT_PERS   = 4096;
  INF_SELECT_GENE   = 8192;

  {UserFlags}
  INF_HOTKEYS     =  1; { User uses "hotkeys" in door prompts   }
  INF_XPERT       =  2; { Short menus displayed in door         }
  INF_GRAPHICS    =  8; { Enable ANSI control sequences in door }
  INF_NOT_MY_MAIL = 16; { Do not bundle mail from user          }
  INF_SHOWKLUDGES = 32;
  INF_NUMERICEXT  = 64;

  INF_FILE_NO     =  0;
  INF_FILE_YES    =  1;
  INF_FILE_COLOR  =  2;

  {NetmailFlags}
{!!INF_CAN_CRASH   =  1; { Allow Crash status          }
{  INF_CAN_ATTACH  =  2; { Allow File Attach messages  }
{  INF_CAN_KSENT   =  4; { Allow Kill/Sent status      }
{  INF_CAN_HOLD    =  8; { Allow Hold status           }
{  INF_CAN_IMM     = 16; { Allow Immediate status      }
{  INF_CAN_FREQ    = 32; { Allow File Request messages }
{  INF_CAN_DIRECT  = 64; { Allow Direct status         }

  {NetworkType}
  INF_NET_FIDONET  = 0;  { 0=Set up for FidoNet-style network mail  }
  INF_NET_QWKNET   = 1;  { 1=Set up for QWK packet network mail     }
  INF_NET_INTERNET = 2;  { 2=Set up for Internet/Usenet mail        }

  {MessageStatus}
  FTI_MSGPRIVATE   =     1;  { Private = For addressee ONLY         }
  FTI_MSGCRASH     =     2;  { Crash = High priority mail           }
  FTI_MSGREAD      =     4;  { Read = Message read by addressee     }
  FTI_MSGSENT      =     8;  { Sent = Message sent                  }
  FTI_MSGFILE      =    16;  { File Attach = Send file(s)           }
  FTI_MSGFWD       =    32;  { Forward = Message to/from others     }
  FTI_MSGORPHAN    =    64;  { Orphan = Message destination unknown }
  FTI_MSGKILL      =   128;  { Kill/Sent = Delete after sending     }
  FTI_MSGLOCAL     =   256;  { Local = Message originated here      }
  FTI_MSGHOLD      =   512;  { Hold = Hold for pickup, don't send   }
  FTI_MSGIMMEDIATE =  1024;  { Immediate = Send message NOW         }
  FTI_MSGFRQ       =  2048;  { File Request = Request file(s)       }
  FTI_MSGDIRECT    =  4096;  { Direct = Send direct, no routing     }
  FTI_MSGURQ       = 32768;  { Update Request = Req updated file(s) }

  UPL_INACTIVE     =     1;  { Message is INACTIVE - no import!          }
  UPL_PRIVATE      =     2;  { Message is PRIVATE                        }
  UPL_NO_ECHO      =     4;  { Message is NOT to be echoed - no local?   }
  UPL_HAS_FILE     =     8;  { Message has file "attached" to it         }
  UPL_NETMAIL      =    16;  { Message is NetMail                        }

  UPL_NRES1        =      1; { RESERVED FOR FUTURE USE             }
  UPL_NETCRASH     =      2; { Crash = High priority mail          }
  UPL_NETFILE      =     16; { File Attach = Send file(s) listed   }
  UPL_NETKILL      =    128; { Kill/Sent = Delete after sending    }
  UPL_NETLOCAL     =    256; { Local = Message originated here     }
  UPL_NETHOLD      =    512; { Hold = Hold for pickup, do not send }
  UPL_NETIMMEDIATE =   1024; { Immediate = Send message NOW        }
  UPL_NETFRQ       =   2048; { File Request = Request file(s)      }
  UPL_NETDIRECT    =   4096; { Direct = Send direct, no routing    }
  UPL_NETURQ       =  32768; { Update Request = Request updated    }

{  PDQ_HOTKEYS           =  1; { Toggle "hotkeys" in prompts        }
{  PDQ_EXPERT            =  2; { Toggle expert mode (menu displays) }
{  PDQ_AREA_CHANGES      =  4; { Change active message areas        }
{  PDQ_GRAPHICS          =  8; { Toggle IBM 8-bit ASCII characters  }
{  PDQ_NOT_MY_MAIL       = 16; { Toggle bundling mail from user     }


Type
  Array80 = Array[1..80] Of Char;
  Array10 = Array[1..10] Of Char;
  Array44 = Array[1..44] Of Char;
  Array50 = Array[1..50] Of Char;
  Array78 = Array[1..78] Of Char;
  Array72 = Array[1..72] Of Char;
  Array13 = Array[1..13] Of Char;
  Array16 = Array[1..16] Of Char;
  Array43 = Array[1..43] Of Char;
  Array41 = Array[1..41] Of Char;
  Array65 = Array[1..65] Of Char;
  Array21 = Array[1..21] Of Char;
  Array20 = Array[1..20] Of Char;
  Array9  = Array[1..9]  Of Char;
  Array6  = Array[1..6]  Of Char;
  Array36 = Array[1..36] Of Char;

(************************************************************************)
(* >>>>>>>>>>>>>>>>>>>>>> Download Pkt Files <<<<<<<<<<<<<<<<<<<<<<<<<< *)
(************************************************************************)

(*----------------------------------------------------------------------*)
(* BOARDID.INF  "CreateQWK"                                    (Create) *)
(* File format:    INF_HEADER                                           *)
(*                 INF_AREA_INFO, ...                                   *)
(* Problems: Keywords max 10, Bulletins only 5                          *)


INF_HEADER =
Record
  Version: Byte;                        { Packet version type (currently 2)        }
  ReaderFiles: Array[1..5] Of Array13;  { Files to be displayed by reader          }
  Regnum: Array9;                       { User's registration number               }
  MashType: Byte;                       { Currently unused (door fills with 0)     }
  Name: Array43;                        { Name user types at BBS login             }
  Alias: Array43;                       { User's "other" name                      }
  Password: Array21;                    { Password + ASCII 10                      }
  PassType: Byte;                       { Password 0=none 1=door 2=reader 3=both   }
  Zone: Word;                           { Main network address Of host BBS         }
  Net: Word;
  Node: Word;
  Point: Word;
  SysopName: Array41;                   { Name Of SysOp Of host BBS                }
  UNUSED1: Array[1..2] Of Byte;
  SystemName: Array65;                  { Name Of host BBS                         }
  MaxFreqs: Byte;                       { Max number Of file requests allowed      }
  UNUSED2: Array[1..6] Of Byte;
  UserFlags: Word;                      { Bit-mapped door options/toggles          }
  Keywords: Array[1..10] Of Array21;    { User's entire set Of door keywords       }
  Filters: Array[1..10] Of Array21;     { User's entire set Of door filters        }
  Macros: Array[1..3] Of Array80;       { User's door bundling command macros      }
  NetmailFlags: Word;                   { Bit-mapped NetMail options               }
  NetmailCredits: Word;                 { NetMail credits                          }
  NetmailDebits: Word;                  { NetMail debits                           }
  CanForward: Boolean;                  { 0=Message forwarding not allowed         }
  Size_INF_HEADER: Word;                { Size Of INF_HEADER structure             }
  Size_INF: Word;                       { Size Of INF_AREA_INFO structure          }
  Size_MIX: Word;                       { Size Of MIX_REC structure                }
  Size_FTI: Word;                       { Size Of FTI_REC structure                }
  UPL_Supported: Boolean;
  Size_WhoFields: Byte;                 { Max. length Of the FROM: and TO: (1-35)  }
  Size_Subject: Byte;                   { Max. length Of the SUBJECT: field (1-71) }
  BoardID: Array9;
  FileList: Byte;
  UNUSED3: Array[2..234] Of Byte;
End;

INF_RECORD =
Record
  AreaNum: Array6;                 { ASCII of ConfNumber                     }
  EchoTag: Array21;                { Area tag name (*.BRD name for Telegard) }
  Title: Array50;                  { Area description/title                  }
  AreaFlags: Word;                 { Bit-mapped area options                 }
  NetworkType: Byte;               { Network mail type (if INF_ECHO set)     }
End;

(*----------------------------------------------------------------------*)
(* BOARDID.MIX  "Area totals"                                  (Create) *)
(* File format: MIX_REC,... repeated for each message area scanned      *)

MIX_RECORD =
Record
  AreaNum: Array6;               { ASCII of ConfNumber                       }
  TotMessages: Word;             { Total number Of messages for this area    }
  TotPersonal: Word;             { Total number Of personal in this area     }
  Offset: Longint;               { Pointer to first message header in *.FTI  }
End;

(*----------------------------------------------------------------------*)
(* BOARDID.FTI                                                 (Create) *)
(* File format: FTI_REC,... repeated for as many messages in packet     *)

FTI_RECORD =
Record
  WhoFrom: Array36;            { Person message is from                       }
  WhoTo: Array36;              { Person message is to                         }
  Subject: Array72;            { Subject/title Of message                     }
  Date: Array20;               { Origin date Of message                       }
  Msgnum: Word;                { Number Of THIS message on BBS                }
  PrevReply: Word;             { "This is a reply to #xx"                     }
  NextReply: Word;             { "There is a reply at #xx"                    }
  TextOffset: Longint;         { Offset to start Of message in *.DAT file     }
  TextLength: Longint;         { Length Of message text (in Bytes)            }
  Flags: Word;                 { Bit-mapped message status flags              }
  OrgZone: Word;               { Origin address Of message                    }
  OrgNet: Word;
  OrgNode: Word;
End;

(*----------------------------------------------------------------------*)
(* BOARDID.DAT                                                 (Create) *)
(* File format:    Unstructured Bytes                                   *)


(************************************************************************)
(* >>>>>>>>>>>>>>>>>>>>>> Reply Packet Files <<<<<<<<<<<<<<<<<<<<<<<<<< *)
(************************************************************************)

(*----------------------------------------------------------------------*)
(* BOARDID.UPL                                                   (Read) *)
(* File format:  UPL_HEADER                                             *)
(*               UPL_REC,...                                            *)

UPL_HEADER =
Record
  RegNum: Array10;              { Reader registration number (if desired)      }
  Vernum: Array20;              { Reader version number as a string. ASCII + 10}
  VerMajor: Byte;               { Major version Of the reader (number to the   }
  VerMinor: Byte;               { Minor version Of the reader (number to the   }
  ReaderName: Array80;          { String containing name Of the reader, such   }
  Size_UPL_HEADER: Word;        { Size Of UPL_HEADER structure                 }
  Size_UPL: Word;               { Size Of UPL_REC structure                    }
  Name: Array44;                { Name found in INF_HEADER.LOGINNAME.  This is }
  Alias: Array44;               { Name found in INF_HEADER.ALIASNAME           }
  ReaderTear: Array16;          { String containing abbreviated name Of the    }
  UNUSED: Array[1..36] Of Byte; { RESERVED FOR FUTURE USE, and to pad struct   }
End;

UPL_REC =
Record
  WhoFrom: Array36;            { Person message is from                        }
  WhoTo: Array36;              { Person message is to                          }
  Subject: Array72;            { Subject/Title Of message                      }
  DstZone: Word;               { Destination zone Of message (NetMail only)    }
  DstNet: Word;                { Destination net Of message (NetMail only)     }
  DstNode: Word;               { Destination node Of message (NetMail only)    }
  DstPoint: Word;              { Destination point Of message (NetMail only)   }
  MsgAttr: Word;               { Bit-mapped message attributes                 }
  NetAttr: Word;               { Bit-mapped NetMail message attributes         }
  UnixDate: Longint;           { Date/time Of message                          }
  Replyto: Longint;            { This unsigned long word stores the message #  }
  Filename: Array13;           { Filename the message text is in               }
  Echotag: Array21;            { Area tag the message goes in                  }
  AreaFlags: Word;             { Door Ignores this                             }
  FileAttach: Array13;         { If the UPL_HAS_FILE flag is set, this field   }
  UNUSED: Array[1..7] Of Byte; { User-defined storage.  Doors should ignore    }
  EmailAddress: Array[1..100] Of Char;
(*
  NonFidoDest: Array[1..100] Of Char; { Network destination address                   }
*)
End;


(*----------------------------------------------------------------------*)
(* BOARDIQ.REQ                                                   (Read) *)
(* File format: REQ_REC,...  repeated for as many files as requested    *)

REQ_REC =
Record
  Filename: Array13;    { Name Of file to request }
End;


(*---------------------------------------------------------------------------*)
(* BOARDID.PDQ                                                        (Read) *)
(* File format: PDQ_HEADER                                                   *)
(*              PDQ_REC,...   repeated for each selected areas, others OFF   *)

PDQ_HEADER =
Record
  Keywords: Array[1..10] Of Array21; { User's entire set Of door keywords   }
  Filters: Array[1..10] Of Array21;  { User's entire set Of door filters    }
  Macros: Array[1..3] Of Array78;    { User's door bundling command macros  }
  Password: Array[1..21] Of Char;    { Password                             }
  PassType: Byte;                    { Password type                        }
  Flags: Word;                       { Bit-mapped flags                     }
End;

PDQ_REC =
Record
  EchoTag: Array21;                  { Echo tag Of message area to activate }
End;
