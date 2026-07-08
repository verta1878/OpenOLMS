# DOS runtime — CWSDPMI (with source)

The DOS build of OpenOLMS is a 32-bit go32v2 program and needs a **DPMI host**
at runtime: **CWSDPMI** by Charles W. Sandmann. It is bundled here as both the
runtime binary and its complete source, so the DOS release is fully
GPL-compliant with nothing to fetch separately.

## Contents

    CWSDPMI.EXE      the DPMI host (r7, official, unmodified)
    CWSDPR0.EXE      ring-0 variant (optional)
    CWSDPMI.DOC      CWSDPMI documentation / redistribution terms
    cwsdpmi-src/     complete CWSDPMI source code (GPLv2)
      COPYING        the GNU General Public License v2
      COPYING.CWS    Sandmann's copyright addendum (distribute verbatim)
      *.c *.h *.asm *.inc  the sources
      makefile

## Usage

Ship `CWSDPMI.EXE` alongside `OLMS.EXE` / `CONFIG.EXE` in the DOS release. The
program loads the DPMI host automatically when run on bare DOS.

## License

CWSDPMI is Copyright (C) 1995-2010 Charles W. Sandmann, licensed under the
**GNU General Public License v2** (see `cwsdpmi-src/COPYING` and
`cwsdpmi-src/COPYING.CWS`). The binaries are the official, unmodified releases.
The complete corresponding source is included in `cwsdpmi-src/`.

Source (this copy) is redistributed as part of the OpenOLMS repository:
  https://github.com/verta1878/openolms   (dos-runtime/cwsdpmi-src/)
Upstream / updates:
  https://www.delorie.com/djgpp/

CWSDPMI is a separate program from OpenOLMS. OpenOLMS is GPLv3; CWSDPMI is
GPLv2. Both are GPL-family works, bundled together only so the DOS build runs
out of the box.
