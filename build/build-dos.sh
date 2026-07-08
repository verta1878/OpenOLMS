#!/bin/sh
# Build OpenOLMS for DOS (32-bit, go32v2) with Free Pascal.
# Requires: FPC with the i386-go32v2 cross target installed
#   (from freepascal.org; Debian/Ubuntu's fpc does NOT include it by default).
# Produces: OLMS.EXE and CONFIG.EXE  (real DOS executables)
#
# The SDL screen backend is DOS-incompatible and is simply not referenced by
# the DOS build (the console backend is used, which is what a DOS door wants).
set -e
cd "$(dirname "$0")/../src"
echo "Building OLMS.EXE (go32v2)..."
fpc -Tgo32v2 -O2 -Xs olms.pas
echo "Building CONFIG.EXE (go32v2)..."
fpc -Tgo32v2 -O2 -Xs config_demo.pas
mv -f olms OLMS.EXE 2>/dev/null || mv -f olms.exe OLMS.EXE 2>/dev/null || true
mv -f config_demo CONFIG.EXE 2>/dev/null || mv -f config_demo.exe CONFIG.EXE 2>/dev/null || true
echo "Done: OLMS.EXE and CONFIG.EXE"
