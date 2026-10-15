# OpenOLMS — Online Message System

OLMS 2001 source code released
by the original author. Preserved and maintained by the crew (verta1878) as OpenOLMS under GPLv3.

## What This Is

OLMS (Online Message System) is a BBS door program that provides
offline mail reading and writing for BBS callers. It supports Hudson
(HMB) and JAM message bases, BlueWave offline mail packets, file
requests, vacation messaging, multi-language support, and full-screen
chat.

## Source

Original author source received 2026-10-15. Turbo Pascal, uses
DM6000 (Doorman BBS door framework). 22 Pascal source files,
14,257 lines.

### Programs

| Program | Source | Lines | What |
|---------|--------|-------|------|
| OLMS2001.EXE | OLMS2001.PAS | 3,849 | Main door — offline mail, message reading/writing |
| CONFIG.EXE | CONFIG.PAS | 2,867 | Sysop configuration tool |
| (maintenance) | MAINTAIN.PAS | 733 | Database maintenance |
| (editor) | EDITOR.PAS | 965 | Message editor |

### Units

| Unit | Source | Lines | What |
|------|--------|-------|------|
| U_UNIT | U_UNIT.PAS | 2,513 | Core utility functions |
| U_NEW | U_NEW.PAS | 1,336 | New user handling |
| U_JAM | U_JAM.PAS | 709 | JAM message base support |
| U_HMB | U_HMB.PAS | 539 | Hudson Message Base support |
| U_LANG | U_LANG.PAS | 365 | Multi-language support |
| U_REG | U_REG.PAS | — | Registration |

### Includes

| File | Lines | What |
|------|-------|------|
| BBSTYPE.INC | 10 | Build switch — BBS_RA1 or BBS_RA2 |
| DROPTYPE.INC | 201 | BBS drop file data structures (RA 1.x + 2.x, EXITINFO) |
| BWAVE212.INC | 294 | BlueWave 2.12 offline mail packet structures |

### Build Switches (BBSTYPE.INC)

| Define | 0 (disabled) | 1 (enabled) |
|--------|-------------|-------------|
| BBS_RA1 | Not targeting RemoteAccess 1.x | Build for RA 1.11 (uses C_RA111 unit) |
| BBS_RA2 | Not targeting RemoteAccess 2.x | Build for RA 2.x (default, enables all features) |
| LOWMEMORY | Normal memory mode | Reduced memory footprint |
| BBS_FILEREQUEST | No file request support | File request/download support (auto-enabled by BBS_RA2) |
| MESSAGE_JAM | No JAM support | JAM message base support (auto-enabled by BBS_RA2) |
| PROVERSION | Compile error | Pro version features (auto-enabled by BBS_RA2) |

## Compiler

Turbo Pascal 7.0. Requires:
- DM6000 unit (Doorman BBS door framework)
- JAMCRC32 + JAM units (JAM message base library)
- Crt, Dos (standard TP units)

## Screens

Full ANSI/ASCII/RIP screen set in `SCR/` (20 screens x 3 formats = 60 files).
Language files: English, French, Spanish.

## Utilities

| Tool | What |
|------|------|
| 20XTO250.PAS | Upgrade user data from 2.0x to 2.50 format |
| PRO-2-SW.PAS | Convert ProBoard to SuperWild format |
| SW-2-PRO.PAS | Convert SuperWild to ProBoard format |
| USERCONF.PAS | User configuration tool |

## Documentation

| File | What |
|------|------|
| OLMS.DOC | User manual |
| HISTORY.DOC | Version history (1.00.10 through 2.00.1 beta 3) |
| UPGRADE.DOC | Upgrade instructions |
| SUPPORT.DOC | Support information |
| PROBOARD.DOC | ProBoard integration notes |
| TODO.!!! | Open items and known issues |

## History

This source was preserved by the crew (verta1878) after the original
author made contact and shared it. An earlier clean-room recreation
(OpenOLMS) existed before this source was available — that work is
archived in the attic/ directory as historical reference.

## Checksums

See `CHECKSUMS.md` for source + binary hashes, `MD5SUMS.txt` and
`SHA256SUMS.txt` for all 142 files.

## License

GPLv3. Original author source released with permission.
