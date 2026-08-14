# Changelog

All notable changes to OpenOLMS (Open Offline Mail System). Format: [Keep a Changelog](https://keepachangelog.com/).

## [1.0] - 2026-08-07

### Added — Binary Compatibility
- OL_Compat.pas: packed record types matching original OLMS v2000
  - TOLMSConfigRaw: 14,889 bytes raw buffer with 18 accessor functions
  - TOLMSUser: 478 bytes packed record (SizeOf MATCH)
  - TOLMSArea: 64 bytes packed record (SizeOf MATCH)
  - ReadTPStr/WriteTPStr: Turbo Pascal ShortString I/O (exported)
  - CfgGet/CfgSet accessors for all known config fields
- editor.pas (EDITOR.EXE): 203 lines, full-screen CRT message editor
  - Arrow keys, PgUp/PgDn, Home/End, Ctrl-W save, Ctrl-Q quit
  - Ctrl-K spell check, Ctrl-Y delete line, quote support (/Q:file)
  - Uses OL_Editor engine + Hunspell
- userconf.pas (USERCONF.EXE): 348 lines, user self-configuration
  - Archiver selection (ARJ/LHA/ZIP/ARC/PAK/RAR)
  - Protocol selection (Xmodem/Ymodem/Zmodem)
  - Message area toggles (383 areas, Space to toggle)
  - Reads/writes original USERS.DAT via OL_Compat
- upgrade1.pas (UPGRADE1.EXE): 192 lines
  - Upgrades OLMS.CFG + MESSAGES.CTL to v2000 format
  - Creates MESSAGES.INF + USERS.IDX if missing
  - Auto-backup of originals before modifying
- upgrade2.pas (UPGRADE2.EXE): 247 lines
  - Upgrades USERS.DAT to v2000 (478 bytes/record, 30 slots)
  - Auto-detects old record size (scan 50..1000)
  - Creates WORK1/WORK2 directories, checks SCREENS.DAT
  - Auto-backup of originals before modifying
- OL_Editor: Lines property, SetLine, DeleteLine, InsertLineAt methods
- STATUS.md: full v1.0 status with compatibility phases + known issues
- TODO.TXT: prioritized v1.1 roadmap
- INSTALL.TXT: new/upgrade installation guide
- LICENSE: GPLv3 with Peter Rocca credit
- FILE_ID.DIZ: BBS file description

### Fixed
- FPC Lo(200) nibble bug: Lo() on Byte constant returns low nibble (8),
  not low byte (0xC8). Changed to (V and $FF) for version write.
- ArchiverSel array overflow in userconf: clamp to 0..5, show "Unknown"
  for out-of-range values from old data files.
- WStart unused in spell check: now reports column position in output.
- upgrade2 record size detection: widened scan from 200..500 to 50..1000.
- OL_Compat nested comment warning: removed directive from comment block.
- openolms.pas + olmscfg.pas: class(TApplication) → object(TApplication)
  to fix FreeVision object inheritance in FPC OBJFPC mode.

### Verified
- Config round-trip: load original OLMS.CFG, save, binary diff = 0
- All data files created with correct sizes by upgrade tools
- Version 200 reads back correctly after write
- All 8 programs compile (5 standalone clean, 2 main door + config, 1 client)
- Peter Rocca's permission: GPLv3 clean-room reimplementation

## [0.5] - 2026-07-28

### Added
- MOLMS offline mail client (molms.exe, 742 lines, Win32 FV TUI)
  - Connect to BBS via Telnet, Serial/Modem, FOSSIL
  - Auto-login sequence (username, password, door command)
  - Auto Mail Run: one-key connect/login/download/upload cycle
  - QWK packet reader with message viewer (header + body dialog)
  - Reply composer with pre-filled To/Subject, Spell button
  - BBS address book (add, list, select)
  - Area navigation (next/prev message, next/prev area)
  - Area list with per-conference message counts
- OL_Transfer.pas: automated connection/login/door/Zmodem bridge
  - SendString with inter-character delay
  - WaitFor with timeout and pattern matching
  - AutoLogin, EnterDoor, DownloadQWK, UploadREP, AutoMailRun
- ANSI terminal rendering for BBS messages (mtterm.pas, 419 lines)
  - Full CSI/SGR: cursor, color, scroll, clear, 1000-line scrollback
- RIPscrip v1.54 graphics engine (mtrip.pas + mtripgfx.pas, 676 lines)
  - 640x350 EGA canvas, Bresenham line, circle, ellipse, arc
  - Flood fill (stack-based), bar, pixel, text, BMP export
- Hunspell spell check (mt_spell.pas, dynamic loading, optional)
- Reply editor (OL_Editor.pas): word wrap at 72, quote prefix, spell check
- Zmodem with Int64 fix (>2GB file transfers)
- Ymodem batch, Xmodem 1K/CRC, Kermit sliding window protocols
- Connection stack from mterm: mtconn, mtserial, mtphone, mtxfer
- Session capture logging (mtcapture.pas)
- openolms_dos.exe: pure ANSI DOS door (alternate to olms.exe)
- olmsmnt.exe: CLI maintenance (list users, stats, purge, rebuild)
- GPLv3 headers on all files with team credits
- WHATSNEW.TXT with version history v0.1-v0.5

### Changed
- Copyright line: verta1878, sysop/0, wrench, kiddo, evga
- Protocol code credited to kiddo
- Removed all "pending license" language — our code is GPLv3,
  clean-room from published docs, no original source code used

## [0.4] - 2026-07-09

### Fixed
- CONFIG.EXE: fixed duplicated field labels / one-row screen shift on DOS
- DOS text files now use CRLF line endings
- README.TXT rewritten with clear sections

### Added
- TODO.TXT, INSTALL.TXT, WHATSNEW.TXT

## [0.3] - 2026-07-09

### Added
- Multi-area scanning (JAM and Hudson) via CONFIG.EXE area editor
- CONFIG.EXE Message Areas editor (add / edit / delete)
- Honest archiver reporting (no false "compressed" without PKZIP)
- Proper exit codes (0 = ok, 1 = error) for BBS batch files
- Activity logging to OLMS.LOG
- /U processes uploaded .REP reply packets
- Full command-line switch set; DOS /?; --version
- BBS identity from OLMS.CFG

## [0.2] - 2026-07-08

### Fixed
- CONFIG.EXE became a real interactive editor (was render-only demo)
- Archiver verifies .QWK was actually produced

### Added
- Live CRT screen backend for interactive DOS console editing

## [0.1] - 2026-07-08

### Added
- First release: QWK/QWKE/Blue Wave offline-mail door for DOS
- Door: dropfile, IMsgBase (JAM + Hudson), IPacketWriter (QWK/QWKE/BW)
- Filtering, read pointers, limits, archiver, .REP reader
- File subsystem, networking, taglines, vacation, logging, multi-language
- Config tool: all 12 screens, IScreen (console + SDL), IKeyboard
- Door user UI: main menu, conference selection

## [1.0.1] - 2026-08-08

### Updated — mterm RIP Engine (kiddo)
- mtrip.pas: 267 → 632 lines — full RIPscrip v1.54 command dispatcher
- mtripgfx.pas: 409 → 840 lines — complete BGI-compatible rendering engine
- Added mtrip_test.pas (55 lines) — smoke test harness
- Added rip_font8x8.inc — 8x8 bitmap font data

### New RIP Engine Features
- 49 RIPscrip commands dispatched (was ~20 with stubs, now 0 stubs)
- Bresenham line drawing (all angles, all octants)
- FloodFill with viewport clipping
- Bezier curve rendering
- CHR vector fonts (BGI-compatible, sizes 1-10)
- 8x8 bitmap font rendering via rip_font8x8.inc
- Mouse fields with hit test and click-to-send host commands
- ButtonStyle rendering (|1B set style + |1U draw button)
- Fill patterns: empty, solid, line, slash, backslash, cross, hatched
- Line styles: solid, dotted, center, dashed
- Viewport clipping on all drawing operations
- 640x350 EGA canvas with 16-color palette

### RIP Engine Phases (all complete)
- MT-1: Core rendering (Bresenham, FloodFill, Bezier, patterns)
- MT-2: Font system (CHR fonts, 8x8 bitmap, TextWidth/Height)
- MT-3: Extended commands (19 stubs → full implementations)
- MT-4: Protocol (| separator, |! comment, |# no-more, 49 dispatch)
- MT-5: Terminal features (mouse fields, hit test, click-to-send)
- MT-6: Debug & fix (compile clean, smoke test, gap closure)

### Smoke Test Results
| Test | Diff | Status |
|------|------|--------|
| F_FILL1 | 0.0% | pixel-perfect |
| F_FILL2 | 0.6% | good |
| DRAGON01 | 2.5% | good |
| ICONS | 1.9% | matches ripviewer |
| v_VIEW | 8.5% | FloodFill viewport fix |
| S_FILL | 7.9% | bar fill patterns |
