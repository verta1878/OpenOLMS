# OpenOLMS

An open-source **OLMS** — a QWK / QWKE / Blue Wave offline-mail door for DOS
bulletin board systems. Built in Free Pascal from published format
specifications.

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

Full instructions for both targets are in **[docs/BUILD.md](docs/BUILD.md)**
(Linux native, and DOS via the go32v2 cross-compiler). Prebuilt DOS binaries
(`OLMS.EXE`, `CONFIG.EXE`) are in `releases/`, and a ready-to-run DOS bundle is
attached to the GitHub Release.

Quick version:

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
dos-runtime/  CWSDPMI DPMI host (binary + full GPLv2 source) for the DOS build
```

## Status

All core areas implemented and compiling: message input (JAM/Hudson), filtering,
pointers/limits, three packet formats, archiver compression, reply intake, file
requests, networking/gateway, both programs, and the console + SDL UI backends.
See `STATUS.md` for the full feature list and what a production polish would add.


## Credits

Built by Antonio Rico / Ecstasy BBS.
