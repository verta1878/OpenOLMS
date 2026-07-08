# DOS runtime — CWSDPMI

The DOS build of OpenOLMS is a 32-bit go32v2 program and needs a **DPMI host**
at runtime. The standard one is **CWSDPMI** by Charles W. Sandmann.

## What to place here

Drop these two files into this folder (unmodified):

    CWSDPMI.EXE   the DPMI host
    CWSDPMI.DOC   its license/documentation  (REQUIRED to redistribute the EXE)

Then ship them alongside OLMS.EXE / CONFIG.EXE in the DOS release.

## Where to get them

Official DJGPP archive:
  https://www.delorie.com/djgpp/  (v2 / current, "csdpmi*b.zip")
FreeDOS also bundles CWSDPMI.

Use the current release (r7) or any recent version. Do not modify the EXE
(configuration via CWSPARAM only, if needed).

## License

CWSDPMI is Copyright (C) Charles W. Sandmann, released under the GNU GPL v2.
Its binary may be redistributed provided CWSDPMI.DOC accompanies CWSDPMI.EXE,
the EXE is unmodified, and users are informed of their right to the CWSDPMI
source code. The CWSDPMI source is available from the DJGPP archive above.

This is a separate program from OpenOLMS; OpenOLMS is GPLv3. CWSDPMI (GPLv2) is
bundled only as the DOS runtime host. The two are independent, GPL-family works.
