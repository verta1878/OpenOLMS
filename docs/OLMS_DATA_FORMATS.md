# OLMS Data File Formats — Binary Analysis

Reversed from OLMS Version 2000 distribution (Peter Rocca, MCC 1994-98).
All structures are Borland/Turbo Pascal packed records, little-endian.

---

## OLMS.CFG — Main Configuration (14,889 bytes)

Single record. TP ShortStrings (length byte + chars, fixed allocation).

```pascal
TOLMSConfig = record
  { Header — 4 bytes }
  ConfigVersion : Word;          { 0x0000  200 = Version 2000        }
  Signature     : Word;          { 0x0002  0xABC0 = valid config     }

  { System Information — 12 config screen }
  SystemName    : String[30];    { 0x0004  BBS name from CONFIG.RA   }
  SysopName     : String[56];    { 0x0023  Sysop name from CONFIG.RA }

  { Paths — 13 x String[60] }
  MsgbasePath   : String[60];    { 0x005C  Hudson/JAM message base   }
  RAPath        : String[60];    { 0x0099  RemoteAccess home dir     }
  FDBPath       : String[60];    { 0x00D6  RA File Database path     }
  NodelistPath  : String[60];    { 0x0113  FidoNet nodelist path     }
  WelcomeFile   : String[60];    { 0x0150  Welcome screen file      }
  LogoFile      : String[60];    { 0x018D  Logo/title screen file    }
  GoodbyeFile   : String[60];    { 0x01CA  Goodbye screen file      }
  LogFile       : String[60];    { 0x0207  Activity log path         }
  UploadPath    : String[60];    { 0x0244  REP upload directory      }
  DownloadPath  : String[60];    { 0x0281  QWK download directory    }
  TagFile       : String[60];    { 0x02BE  Tagline file path         }

  { Registration — offset 0x02FB }
  MaxAreas      : Word;          { 0x02FB  Max areas (82 = 0x52)     }
  BoardID       : String[30];    { 0x02FD  Board ID (1-8 chars)      }
  SerialNumber  : String[30];    { 0x031C  Registration serial       }
  RegNumber     : String[30];    { 0x033B  Registration key          }

  { Defaults — offset 0x034E }
  DefaultLang   : String[8];     { 0x034F  Default language name     }
  PhoneFormat   : String[20];    { 0x0358  Phone number mask         }

  { Archiver Commands — 6 compress + 6 decompress }
  { Each String[70], offset 0x036D }
  CompressCmd   : array[1..6] of String[70];   { ARJ,LHA,ZIP,ARC,PAK,RAR }
  DecompressCmd : array[1..6] of String[70];   { same order               }

  { Protocol Commands — 6 send + 6 receive }
  { Each String[70], offset 0x06C1 }
  SendCmd       : array[1..6] of String[70];   { Xmodem,Ymodem,Zmodem,... }
  RecvCmd       : array[1..6] of String[70];   { same order               }

  { Protocol Names — 6 x String[10] }
  { Offset ~0x0E5F }
  ProtocolName  : array[1..6] of String[10];

  { Control Setup, Requesting, Limits — Boolean/Word fields }
  { (remaining ~4000 bytes of flags, limits, netmail config) }

  { ... additional fields TBD from deeper hex analysis ... }
end;
```

### Field spacing verification:
```
SystemName:  31 bytes (String[30])   0x0004..0x0022
SysopName:   57 bytes (String[56])   0x0023..0x005B
MsgbasePath: 61 bytes (String[60])   0x005C..0x0098
RAPath:      61 bytes (String[60])   0x0099..0x00D5
...pattern continues at 61-byte intervals...
```

### Archiver command mapping:
```
Index  Compress                      Decompress
1      ARJ.EXE a                     ARJ.EXE e
2      LHA.EXE a /m                  LHA.EXE e /m
3      PKZIP.EXE -ex                 PKUNZIP.EXE -o
4      PKARC.COM A                   PKXARC.COM -ER
5      PAK.EXE A /I                  PAK.EXE E /I /WA
6      RAR.EXE a                     RAR.EXE e -o+
```

### Protocol command mapping:
```
Index  Send                           Receive
1      DSZ.EXE port *P sx             DSZ.EXE port *P rx
2      DSZ.EXE port *P sb             DSZ.EXE port *P rb
3      DSZ.EXE port *P sz -rr         DSZ.EXE port *P rz
4-6    (empty)                         (empty)
```

---

## MESSAGES.CTL — Conference Area List (24,512 bytes)

64-byte records. 383 entries (24512 / 64 = 383).
First record is area #0, NOT a header.

```pascal
TMessageArea = record
  { Area tag — String[35] }
  AreaTag      : String[35];     { 0x00  QWK conference tag name     }
                                 {       e.g. "NETMAIL", "PUBLIC"     }
                                 {       TP ShortString: [0]=length   }

  { Flags and settings — bytes 36..63 }
  AreaFlags    : Byte;           { 0x24  Bit flags (active, etc.)    }
  MsgBaseType  : Byte;           { 0x25  1=Hudson, 2=JAM             }
  AreaNumber   : Word;           { 0x26  RA conference number        }
  BoardNumber  : Word;           { 0x28  Hudson board number (1-200) }
  ReadAccess   : Word;           { 0x2A  Security level to read      }
  WriteAccess  : Word;           { 0x2C  Security level to write     }
  NetmailDest  : LongInt;        { 0x2E  Netmail destination addr    }
  MaxMsgs      : Word;           { 0x32  Max messages to pack        }
  Reserved     : array[0..11]    { 0x34  Padding to 64 bytes         }
               of Byte;
end;
```

### Sample records:
```
#0: "NETMAIL FIDONET <-> INTERNET GATEWAY"  type=1(Hudson) board=193
#1: "PUBLIC"                                 type=2(JAM)    board=138
#2: "THE_TOASTER_OVEN"                       type=2(JAM)    board=136
```

### AreaFlags bits:
```
Bit 0: Active (area is enabled)
Bit 1: Netmail area
Bit 2: Read-only
Bit 3: Private messages only
Bit 4: Include in default scan
Bit 5: Force scan (always include)
Bit 6: Internet gateway area
Bit 7: Reserved
```

---

## USERS.DAT — User Database (14,340 bytes)

Record size candidates: 60 (239 users) or 239 (60 users) or 478 (30 users).

From hex analysis of first record:
```
0x0000: D0 34 31 01  — header/pointer (Word + Word?)
0x0004: 0C           — String length = 12
0x0005: "Leslie Given" (12 chars)
...padding to offset 0x0030...
0x0031: 08           — String length = 8
0x0032: "10-02-16"   — Last date (MM-DD-YY)
0x003A: 05           — String length = 5
0x003B: "18:09"      — Last time (HH:MM)
0x0041: 00 00        — padding
0x0043: "BIZZ"       — 4-char string (password? board ID?)
```

Record header bytes D0 34 = 13520, 31 01 = 305.
If record size = 239: 14340 / 239 = 60 users exactly.

```pascal
TUserRecord = record
  { Header — 4 bytes }
  RecordSize   : Word;           { 0x00  Record size or pointer      }
  UserIndex    : Word;           { 0x02  User index number           }

  { User name — String[36] }
  UserName     : String[36];     { 0x04  User's full name            }

  { Timestamps }
  LastDate     : String[8];      { 0x29  Last access date MM-DD-YY   }
  LastTime     : String[5];      { 0x32  Last access time HH:MM      }

  { User settings }
  Password     : String[8];     { 0x38  Password or Board ID         }
  Archiver     : Byte;          { 0x41  Preferred archiver (1-6)     }
  Protocol     : Byte;          { 0x42  Preferred protocol (1-6)     }
  MsgFormat    : Byte;          { 0x43  QWK=0, BlueWave=1            }
  Flags        : Word;          { 0x44  User flags                   }

  { Per-area message pointers }
  { Remaining bytes: area high-water marks }
  { Size depends on MaxAreas in OLMS.CFG }
  HighMsgPtr   : array[0..??] of LongInt;
                                { Last read message per area          }
  { ... exact layout TBD from MaxAreas ... }
end;
```

### User flags:
```
Bit 0:  Active user
Bit 1:  Keyword filter enabled
Bit 2:  Twit filter enabled
Bit 3:  Include new files list
Bit 4:  Vacation mode
Bit 5:  Deleted
Bit 6:  Expert mode
Bit 7:  ANSI color
Bit 8:  RIP graphics
Bit 9:  Full headers in messages
Bit 10: Auto-download
```

---

## USERS.IDX — User Index (4 bytes)

Minimal index — likely just a record count or hash pointer.

```
Hex: 01 00 00 00 = LongInt 1 (one active user)
```

---

## MESSAGES.IDX — Message Area Index (762 bytes)

Quick-lookup index for MESSAGES.CTL. 762 / 2 = 381 entries (Word).
Maps area number → CTL record offset.

---

## MESSAGES.INF — Message Info (6 bytes)

Small metadata file. Possibly: area count (Word) + flags.
```
Hex dump needed for exact format.
```

---

## SCREENS.DAT — TUI Screen Templates (65,808 bytes)

Pre-rendered ANSI/ASCII screens used by CONFIG.EXE.
Contains the 12 configuration editor screens plus menu templates.

65808 / 4000 = ~16 screens (80x25 = 2000 chars × 2 attr bytes = 4000 per screen).
Or 65808 / 2000 = ~33 screens (ASCII only, no attributes).

---

## ARCHIVES.BBS — Archiver Definitions (715 bytes)

Text file listing available archivers and their file extensions.
Used to determine which decompressor to call for each archive type.

---

## Companion Files

| File | Format | Purpose |
|------|--------|---------|
| *.KEY | Text, 1 per line | Keyword filter (per user) |
| *.TWT | Text, 1 per line | Twit list (per user) |
| *.QWK | ZIP archive | Downloaded mail packet |
| *.REP | ZIP archive | Uploaded reply packet |
| DORINFO1.DEF | Text, 12 lines | BBS drop file |
| DOOR.SYS | Text, 20+ lines | PCBoard drop file |
| EXITINFO.BBS | Binary, 1090 bytes | RA extended drop file |
| *.HLP | Text | Context help files |
| WELCOME.(N) | Text | Welcome screen per node |
| DEFAULT.OLF | Binary | Default language file |
