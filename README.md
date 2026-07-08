# OpenOLMS

An open-source, clean-room reimplementation of **OLMS** — the QWK / QWKE /
Blue Wave offline-mail door for DOS bulletin board systems (originally by
Multiboard Communications). OpenOLMS speaks the same formats and fills the same
role, written entirely from **published format specifications** and the OLMS
**manual** — it contains no code from the original program.

Written in Free Pascal. Runs as two programs, like the original:

- **`olms`** — the mail door the BBS runs for a caller
- **`config`** — the sysop configuration tool

## Why

OLMS is shareware whose registration is no longer obtainable, so old boards that
relied on it can't bring it back cleanly. OpenOLMS is a fresh, freely-licensed
implementation of the same offline-mail workflow, so a revived BBS can offer
QWK/Blue Wave mail without the original.

## What it does

**The door (`olms`):**
- Reads BBS **dropfiles** (DORINFO1.DEF, DOOR.SYS) + OLMS command-line switches
- Reads messages from **JAM** and **Hudson** message bases
- **Filtering**: twit lists, keyword scans, include/exclude filters
- **Read pointers** so callers only get new mail (`/RG` `/RS` resets supported)
- Writes **QWK**, **QWKE**, and **Blue Wave** packets
- Compresses to a downloadable `.QWK` via the configured archiver
- Reads **`.REP`** replies back in
- File requests + new-files scanning
- QWK-net / point / internet-gateway re-addressing
- Taglines, vacation mail, logging, multi-language (`.OLF`) screens

**The config tool (`config`):**
- All the OLMS configuration screens (System Information, Archivers, Protocols,
  Files, Bulletins, Control, Requesting, Limits, User Editor, Multi-language,
  Test) on a text-mode UI framework

**UI framework:** display-agnostic — a console backend today and an **SDL2**
backend for a graphical window; the SDL surface is also where RIP support plugs
in.

## Build

Requires Free Pascal (`fpc` 3.x). No external Pascal libraries; the SDL backend
links `libSDL2` and the archiver step calls an external zip/PKZIP.

```sh
cd src
fpc -O2 olms.pas          # the door
fpc -O2 config_demo.pas   # the config tool
```

Run the door the way a BBS would (needs a dropfile + a message base in the dir):

```sh
./olms --dir <path> /DA   # auto-download: scan -> packet -> .QWK
```

See `examples/` for a self-contained JAM→QWK pipeline demo.

## Layout

```
src/        library units + the two programs
examples/   runnable demos (JAM pipeline, sample QWK packet)
docs/       design notes
LICENSE     GNU GPL v3
```

## Status

All core areas implemented and compiling: message input (JAM/Hudson), filtering,
pointers/limits, three packet formats, archiver compression, reply intake, file
requests, networking/gateway, both programs, and the console + SDL UI backends.
See `STATUS.md` for the full feature list and what a production polish would add.

## Legal

OpenOLMS is original work under the **GPL-3.0-or-later**. It is a clean-room
reimplementation from open specs (QWK/QWKE/Blue Wave/JAM/Hudson) and the OLMS
manual; the original OLMS binary was never disassembled. "OLMS" is used only to
describe the software OpenOLMS is compatible with.

## Credits

Built by Antonio Rico / Ecstasy BBS. Format specifications by their respective
authors (QWK by Mark Herring; JAM by Homrighausen/Adams/Lentz/Wittel; Blue Wave
by Cutting Edge Computing; and the QWKE and Hudson community specs).
