# OpenOLMS — Status (v0.5)

An OLMS offline-mail door + MOLMS offline mail client.
~12,400 lines of Free Pascal, 37 units, 5 programs.
Built from published format specifications (QWK/QWKE/Blue Wave/JAM/Hudson).

## Programs

| Program | Lines | Target | What |
|---------|-------|--------|------|
| olms.exe | 319 + 25 units | DOS go32v2 (276K) | Mail door — full round trip |
| config.exe | 326 + UI units | DOS go32v2 (237K) | Sysop config editor (12 screens) |
| molms.exe | 742 | Win32 FV (442K) | MOLMS offline mail client |
| openolms_dos.exe | 353 | DOS go32v2 (336K) | Pure ANSI door (alternate) |
| olmsmnt.exe | 131 | DOS go32v2 (129K) | CLI maintenance |

## Door (olms.exe) — complete

- Dropfile: DORINFO1.DEF, DOOR.SYS + all command-line switches
- Message bases: JAM + Hudson readers (IMsgBase interface)
- Filtering: twit lists, keywords, include/exclude, keyword-only mode
- Read pointers: new-mail-only scans, /RG /RS resets, anti-redownload
- Limits: max messages per area, max packet KB
- Packet output: QWK, QWKE, Blue Wave (IPacketWriter interface)
- Archiver shell-out with verification
- Reply intake: .REP/.MSG reader (round-trips with writer)
- File subsystem: requests, new-files scan, per-day/size limits
- Networking: QWK-net, point net, internet/UUCP gateway
- Taglines, vacation pack-all, logging (OLMS.LOG), multi-language (.OLF)

## Config (config.exe) — complete

All 12 screens: System Information, Archiver Programs, Protocol Programs,
Files Configuration, Bulletins, Control Setup, Requesting Control,
Limits Setup, User Editor, Multi-language, Test Configuration, menu.

## MOLMS client (molms.exe) — v0.5 new

- Connect to BBS via Telnet, Serial/Modem, FOSSIL
- Auto-login (username, password, door command)
- Auto Mail Run: one-key connect/login/download/upload cycle
- Zmodem download QWK, upload REP (Int64 >2GB fix)
- Ymodem batch, Xmodem 1K/CRC, Kermit sliding window
- QWK packet reader with message viewer
- Reply composer with word wrap, quoting, spell check (Hunspell)
- BBS address book
- ANSI terminal rendering for color-coded messages
- RIPscrip v1.54 graphics engine (640x350 EGA canvas)
- Session capture logging

## UI framework

- IScreen: console backend + SDL backend (graphical, 8x16 cells)
- IKeyboard: console (CRT) + scripted; EditField + MenuLoop
- FV (Free Vision) TUI for MOLMS client
- Pure ANSI for DOS door (OL_ANSI)

## Units (37)

### Door core (25)
olms_types, olms_qwk, olms_qwke, olms_bluewave, olms_rep, olms_msgbase,
olms_hudson, olms_archiver, olms_config, olms_door, olms_ui,
olms_screen_console, olms_screen_crt, olms_screen_sdl, olms_doorui,
olms_configui, olms_filter, olms_pointers, olms_input, olms_kbd_console,
olms_kbd_sdl, olms_files, olms_net, olms_runtime, olms_ver

### MOLMS + shared (12)
OL_QWK, OL_Config, OL_DropFile, OL_MsgCtl, OL_Users, OL_Hudson, OL_JAM,
OL_Packer, OL_Filter, OL_BlueWave, OL_Editor, OL_Transfer

### Terminal + connection
mtterm, mtrip, mtripgfx, mtconn, mtserial, mtphone, mtxfer, mtcapture,
mtconfig, OL_ANSI, OL_MDL, mt_spell

### Protocol stack (g00r00, GPLv3)
m_prot_base, m_prot_zmodem, m_protocol_xmodem, m_protocol_ymodem,
m_protocol_kermit, m_protocol_queue, m_crc
