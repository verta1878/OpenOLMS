#!/bin/sh
# Build OpenOLMS for DOS (go32v2) -> OLMS.EXE, CONFIG.EXE
# Needs a go32v2 cross-compiler. Either:
#   A) run build/setup-dos-toolchain.sh first (builds it), or
#   B) unpack the prebuilt openolms-dos-toolchain.tar.gz and point CROSS/RTL at it.
#
# Usage:
#   CROSS=/path/to/ppcross386 RTL=/path/to/units/go32v2 sh build/build-dos.sh
# or, if a DOS-native fpc is on PATH, just: sh build/build-dos.sh
set -e
cd "$(dirname "$0")/../src"
CROSS="${CROSS:-fpc}"
RTLOPT=""
[ -n "$RTL" ] && RTLOPT="-Fu$RTL"
export PATH=/usr/local/bin:$PATH

echo "Building OLMS.EXE ..."
"$CROSS" -Tgo32v2 -O2 $RTLOPT -FE. olms.pas
echo "Building CONFIG.EXE ..."
"$CROSS" -Tgo32v2 -O2 $RTLOPT -FE. config_demo.pas
[ -f olms.exe ] && mv -f olms.exe OLMS.EXE
[ -f config_demo.exe ] && mv -f config_demo.exe CONFIG.EXE
rm -f *.o *.ppu
echo "Done: OLMS.EXE and CONFIG.EXE  (ship with dos-runtime/CWSDPMI.EXE)"
