# Changelog

All notable changes to OpenOLMS. Format: [Keep a Changelog](https://keepachangelog.com/).

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
