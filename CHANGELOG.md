# Changelog

All notable changes to OpenOLMS. Format: [Keep a Changelog](https://keepachangelog.com/).

## [0.2] - 2026-07-08

### Fixed
- CONFIG.EXE is now a real interactive editor: loads OLMS.CFG, lets the sysop
  edit System Information / Archiver / Limits on live screens, and saves. (0.1
  shipped a render-only demo by mistake.)
- Archiver now reports true success/failure: it verifies the .QWK was actually
  produced instead of trusting the DOS COMMAND.COM exit code, which reported
  success even when the archiver (e.g. PKZIP) was not found.

### Added
- Live CRT screen backend (olms_screen_crt) for interactive DOS console editing.


## [Unreleased]

Initial implementation of the OLMS offline-mail door.

### Added
- Door (`olms`): dropfile reading (DORINFO1.DEF, DOOR.SYS) + command-line switches
- Message-base input behind `IMsgBase`: JAM and Hudson readers
- Filtering: twit lists, keywords, include/exclude, keyword-only mode
- Read pointers (new-mail-only scans) with `/RG` `/RS` reset support
- Limit enforcement (max messages, packet KB)
- Packet writers behind `IPacketWriter`: QWK, QWKE, Blue Wave
- Archiver shell-out to produce a downloadable `.QWK`
- Reply intake: `.REP` / `.MSG` reader
- File subsystem: requests, new-files scan, per-day/size limits
- Networking: QWK-net, point, internet/UUCP gateway re-addressing
- Runtime: taglines, vacation pack-all, logging, multi-language (`.OLF`)
- Config tool (`config`): all 12 configuration screens
- UI framework: `IScreen` (console + SDL backends), `IKeyboard` with live editing
- Door user UI: main menu, conference selection

### Notes
- Per-screen live-edit-to-disk wiring is complete for System Information; the
  remaining screens reuse the same `EditField` pattern.
