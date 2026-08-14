# OLMS Version 2000 — Binary Analysis

**Analyst:** evga
**Date:** 2026-08-13
**Original:** Peter Rocca, Multiboard Communications Centre, 1994-1998
**Compiler:** Borland/Turbo Pascal 7.0, real-mode DOS (16-bit)

---

## 1. Binary Inventory

| Binary | Size | Strings | Purpose |
|--------|------|---------|---------|
| OLMS.EXE | 194,496 | 570 | Main BBS door (QWK/QWKE/BlueWave) |
| CONFIG.EXE | 117,856 | 668 | Configuration editor (12 screens) |
| EDITOR.EXE | 41,296 | 193 | Standalone message editor |
| MAINTAIN.EXE | 49,120 | 228 | Database maintenance/packing |
| USERCONF.EXE | 12,608 | 48 | User self-configuration |
| UPGRADE1.EXE | 10,960 | 36 | Config + area upgrade to v2000 |
| UPGRADE2.EXE | 9,264 | 34 | User database upgrade to v2000 |
| **Total** | **435,600** | **1,777** | |

## 2. Data File Formats

### OLMS.CFG — Main Configuration (14,889 bytes)

Single record. Version 200 (v2000). Signature 0xABC0.

```
Offset  Size  Type         Field                    Sample Value
------  ----  -----------  ----------------------   ------------------
0x0000     2  Word         ConfigVersion            200
0x0002     2  Word         Signature                0xABC0
0x0004    31  String[30]   SystemName               "Cosmo's Castle BBS"
0x0023    57  String[56]   SysopName                "Leslie Given"
0x005C    61  String[60]   MsgbasePath              "C:\RA\MSGBASE\"
0x0099    61  String[60]   RAPath                   "C:\RA\"
0x00D6    61  String[60]   FDBPath                  "C:\RA\FDB\"
0x0113    61  String[60]   NodelistPath             "C:\FD\NODELIST\"
0x0150    61  String[60]   WelcomeFile              "...\WELCOME.ANS"
0x018D    61  String[60]   LogoFile                 "...\LOGO.ANS"
0x01CA    61  String[60]   GoodbyeFile              "...\GOODBYE.ANS"
0x0207    61  String[60]   LogFile                  "C:\RA\OLMS.LOG"
0x0244    61  String[60]   UploadPath               "C:\RA\OLMS\UPLOAD\"
0x0281    61  String[60]   DownloadPath             "C:\RA\OLMS\DOWN\"
0x02BE    61  String[60]   TagFile                  "C:\RA\OLMS.TAG"
0x02FB     1  Byte         MaxAreas                 82 (0x52)
0x02FC    31  String[30]   BoardID                  "DEMO"
0x031B    30  Bytes        SerialNumber area        (zero = unregistered)
0x0339     1  Byte         Flags1                   0x01
0x033A     1  Byte         Registered               0x30 ('0' = no)
0x034E     9  String[8]    DefaultLanguage          "DEFAULT"
0x0357    21  String[20]   PhoneFormat              "(XXX)YYY-ZZZZ"
0x036C     1  Byte         ArchiverFlags            0x01
0x036D   426  6×String[70] CompressCmd[1..6]        ARJ/LHA/ZIP/ARC/PAK/RAR
0x0517   426  6×String[70] DecompressCmd[1..6]      same order
0x06C1   426  6×String[70] ProtocolSendCmd[1..6]    DSZ sx/sb/sz
0x086B   426  6×String[70] ProtocolRecvCmd[1..6]    DSZ rx/rb/rz
0x0A15  1098  Bytes        BulletinConfig           (all zeros in sample)
0x0E5F     7  Bytes        ProtocolLetters          "XYZ   " (enabled)
0x0E66    66  6×String[10] ProtocolName[1..6]       Xmodem/Ymodem/Zmodem
0x0EA1     6  Bytes        Padding/flags            (zeros)
0x0EA7    20  20×Boolean   ControlFlags             (all TRUE in sample)
0x0EBB     4  Bytes        MoreFlags
0x0EBF     2  Bytes        TimeLimitData
0x0EC1   112  Words        BaudRateTable            300,700,1000,1500...
                           + FidoNet addresses
                           + Netmail config
0x0F31 11000  Bytes        PerAreaSettings          383 × ~28 bytes
                           (mostly zeros in sample)
```

**Bugs found:** SysopName was documented as String[30] in our
OL_Compat.pas but is actually String[56]. Fixed.

### MESSAGES.CTL — Conference Areas (24,512 bytes)

383 records × 64 bytes each.

```
Offset  Size  Type        Field              Sample
------  ----  ----------  ----------------   ------
0x00    36   String[35]   AreaTag            "NETMAIL FIDONET..."
0x24     1   Byte         AreaType           1=Netmail, 2=Echo
0x25     1   Byte         MsgBaseType        1=Hudson, 2=JAM
0x26     2   Word         AreaNumber         193
0x28     2   Word         BoardNumber        (Hudson board #)
0x2A     2   Word         ReadAccess         security level
0x2C     2   Word         WriteAccess        security level
0x2E     4   LongInt      NetmailDest        FidoNet address
0x32     2   Word         MaxMsgs            500 (default)
0x34    12   Bytes        Reserved           flags/settings
```

### USERS.DAT — User Database (14,340 bytes)

30 records × 478 bytes each.

```
Offset  Size  Type        Field              Sample
------  ----  ----------  ----------------   ------
0x000    2   Word         Status             13520 (packed flags)
0x002    2   Word         AccessLevel        305
0x004   31   String[30]   UserName           "Leslie Given"
0x023   14   String[13]   Alias              (empty)
0x031    9   String[8]    LastDate           "10-02-16"
0x03A    9   String[8]    LastTime           "18:09"
0x043    2   Bytes        Gap                0x0000
0x045    4   Bytes        Password/ID        "BIZZ" (not length-prefixed)
0x049    2   Word         CRC/PackedDate     0xCE96
0x04B    5   Bytes        Reserved           zeros
0x050  383   Byte[383]    AreaFlags          1=selected, 0xFF=special
0x1CF   15   Bytes        Tail               zeros
```

**Note:** Areas 18-21 have flag 0xFF (255) — possibly "force scan"
or "mandatory" marker.

### USERS.IDX — User Index (4 bytes)

```
Word  TotalUsers    1
Word  Reserved      0
```

### MESSAGES.IDX — Area Quick Index (762 bytes)

381 × Word entries. Maps area → offset.

### MESSAGES.INF — Message Info (6 bytes)

```
Word  TotalAreas    (count)
Word  TotalMsgs     (count)
Word  Reserved
```

### SCREENS.DAT — TUI Screens (65,808 bytes)

Pre-rendered screen templates. 65808 / 4000 ≈ 16 screens
(80×25 × 2 bytes = 4000 per screen: char + attribute).
Used by CONFIG.EXE for the 12 configuration screens.

---

## 3. Feature Coverage

### OLMS.EXE Features

| Feature | Binary | Source | Status |
|---------|--------|--------|--------|
| QWK packet generation | ✓ | OL_QWK.pas | ✅ |
| QWKE extended format | ✓ | OL_QWK.pas | ✅ |
| BlueWave format | ✓ | OL_BlueWave.pas | ✅ |
| Hudson message base | ✓ | OL_Hudson.pas | ✅ |
| JAM message base | ✓ | OL_JAM.pas | ✅ |
| Keyword filtering | ✓ | OL_Filter.pas | ✅ |
| Twit list | ✓ | OL_Filter.pas | ✅ |
| File request | ✓ | openolms_dos.pas | ✅ |
| New file scan | ✓ | openolms_dos.pas | ✅ |
| Bulletins | ✓ | openolms_dos.pas | ✅ |
| RIP graphics | ✓ | mtrip.pas | ✅ |
| ANSI display | ✓ | mtterm.pas | ✅ |
| Multi-language | ✓ | olmscfg.pas | ✅ |
| Vacation mail | ✓ | openolms_dos.pas | ✅ |
| Drop file parsing | ✓ | OL_DropFile.pas | ✅ |
| Auto download | ✓ | openolms.pas | ✅ |
| Auto upload | ✓ | openolms.pas | ✅ |
| Netmail support | ✓ | OL_Packer.pas | ✅ |
| FMPT kludge lines | ✓ | OL_Packer.pas | ✅ |
| Internet gateway | ✓ | OL_Packer.pas | ✅ |
| QWK networking | ✓ | OL_QWK.pas | ✅ |
| Remote maintenance | ✓ | openolms_dos.pas | ✅ |
| Registration check | ✓ | openolms_dos.pas | ✅ |
| EMS/XMS swap | ✓ | (TP runtime) | N/A |
| SHARE.EXE check | ✓ | (DOS-only) | N/A |
| Sysop credit control | ✓ | OL_Users.pas | ✅ |
| Short name style | ✓ | olmscfg.pas | ✅ |
| Message pointers reset | ✓ | openolms.pas | ✅ |

### CONFIG.EXE Features (12 screens)

| Screen | Binary | Source | Status |
|--------|--------|--------|--------|
| System Information | ✓ | olmscfg.pas | ✅ |
| Archiver Programs | ✓ | olmscfg.pas | ✅ |
| Protocol Programs | ✓ | olmscfg.pas | ✅ |
| Files Configuration | ✓ | olmscfg.pas | ✅ |
| Bulletins (cfg) | ✓ | olmscfg.pas | ✅ |
| Control Setup | ✓ | olmscfg.pas | ✅ |
| Requesting Control | ✓ | olmscfg.pas | ✅ |
| Limits Setup | ✓ | olmscfg.pas | ✅ |
| Define Shortname Style | ✓ | olmscfg.pas | ✅ |
| User Editor | ✓ | olmscfg.pas | ✅ |
| Multi-language Support | ✓ | olmscfg.pas | ✅ |
| Test Configuration | ✓ | olmscfg.pas | ✅ |

### Other Programs

| Program | Features | Source | Status |
|---------|----------|--------|--------|
| EDITOR.EXE | Word wrap, search, quote | editor.pas | ✅ |
| MAINTAIN.EXE | Reindex, pack, purge, sort, list, stats | olmsmnt.pas | ✅ |
| USERCONF.EXE | Archiver, protocol, areas | userconf.pas | ✅ |
| UPGRADE1.EXE | Config upgrade | upgrade1.pas | ✅ |
| UPGRADE2.EXE | User DB upgrade | upgrade2.pas | ✅ |

---

## 4. Command Line Parameters

### OLMS.EXE
```
/D   Auto download          /U   Auto upload
/DA  Download no waits       /UA  Upload no waits
/DL  Download + logoff       /UL  Upload + logoff
/DQ  Download + ask logoff   /UQ  Upload + ask logoff
/L   Less prompts            /V   Pack vacation mail
/M   Vacation interface      /RG  Reset all pointers
/RS  Reset selected          /RG=N Reset back N messages
```

### MAINTAIN.EXE
```
/P   Pack user database      /R   Reindex files
/S   Sort users              /D   Delete inactive users
/I   Rebuild MESSAGES.IDX    /U   Rebuild USERS.IDX
```

---

## 5. Bugs Found in Original

| Bug | Binary | Severity | Description |
|-----|--------|----------|-------------|
| OL-1 | OLMS.EXE | INFO | Anti-piracy message in binary (registration check) |
| OL-2 | OLMS.EXE | LOW | "Copyrighted by" string has leading "9" (typo) |
| OL-3 | MAINTAIN.EXE | LOW | "Out of memory sorting user list" — no recovery |
| OL-4 | EDITOR.EXE | MEDIUM | "Corrupt USERS.DAT" concatenated with "Cannot open" |
| OL-5 | CONFIG.EXE | LOW | "Testing for external programs existance" (typo: existence) |

---

## 6. Implementation Status

```
Source files:        38 Pascal units
Total lines:     15,178
Data formats:     6 reversed (OLMS.CFG, USERS.DAT, MESSAGES.CTL/IDX/INF, USERS.IDX)
Binary compat:    OL_Compat.pas (421 lines, packed records)
Bug found:        SysopName String[30] → String[56] (FIXED)
```
