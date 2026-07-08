# Toolchain provenance

This bundle contains the DOS (go32v2) cross-compiler used to build OpenOLMS's
DOS binaries, TOGETHER WITH the complete source it was built from.

## Binaries (in bin/ and units/)
    bin/ppcross386        FPC cross-compiler, target i386-go32v2
    units/go32v2/         the go32v2 RTL units it links against

## Source of those binaries
    fpc-3.2.2.source.tar.gz   Free Pascal Compiler 3.2.2, complete source,
                              UNMODIFIED upstream.
    Upstream: https://downloads.freepascal.org/fpc/dist/3.2.2/source/

## Were any modifications made to FPC to build this?
No. The cross-compiler is built from stock, unmodified FPC 3.2.2. The go32v2
target is produced entirely through FPC's normal cross-build path:

    make cycle CPU_TARGET=i386 OS_TARGET=go32v2      (builds ppcross386 + RTL)

plus the DOS assembler/linker from the Debian `binutils-djgpp` package, exposed
under the names FPC expects (i386-go32v2-as / -ld / -ar). See
build/setup-dos-toolchain.sh in the OpenOLMS repo for the exact, reproducible
steps.

## Philosophy
If a DOS binary ever needs a change, the fix goes in SOURCE and the binary is
rebuilt — never patched. The OpenOLMS source (GPLv3) is in the main repo; the
compiler source (FPC, its own GPL/LGPL license) is here; the DPMI runtime source
(CWSDPMI, GPLv2) is in the repo's dos-runtime/cwsdpmi-src/. Every binary in the
release is reproducible from source that ships with it.

## Licenses
- Free Pascal: compiler under GPL, RTL/units under LGPL with static-linking
  exception. See the source tree's COPYING* files.
- This bundle redistributes FPC unmodified.
