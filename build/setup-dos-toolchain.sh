#!/bin/sh
# Reproduce the Free Pascal go32v2 (DOS) cross-compiler on a Linux x86-64 host.
# After this, you can build OpenOLMS for DOS with build/build-dos.sh.
#
# What it does:
#   1. installs the DJGPP binutils (DOS assembler/linker) and links them to the
#      names FPC expects (i386-go32v2-as / -ld / -ar)
#   2. fetches the FPC 3.2.2 source
#   3. builds the cross-compiler (ppcross386) + the go32v2 RTL
#   4. builds the dateutils unit (used by OpenOLMS) for go32v2
#
# Requires: a native FPC 3.2.2, gcc, make, curl, unzip, sudo.
set -e

FPCVER=3.2.2
WORK="${WORK:-/tmp/fpc-dos-build}"
mkdir -p "$WORK"; cd "$WORK"

echo "[1/4] DJGPP binutils (DOS as/ld)..."
sudo apt-get update -qq && sudo apt-get install -y binutils-djgpp
for t in as ld ar; do
  sudo ln -sf "$(which i586-pc-msdosdjgpp-$t)" /usr/local/bin/i386-go32v2-$t
done
export PATH=/usr/local/bin:$PATH

echo "[2/4] fetch FPC $FPCVER source..."
[ -f fpc-src.tar.gz ] || curl -L -o fpc-src.tar.gz \
  "https://downloads.freepascal.org/fpc/dist/$FPCVER/source/fpc-$FPCVER.source.tar.gz"
[ -d "fpc-$FPCVER" ] || tar -xzf fpc-src.tar.gz

echo "[3/4] build cross-compiler + go32v2 RTL..."
cd "fpc-$FPCVER/compiler"
make cycle CPU_TARGET=i386 OS_TARGET=go32v2 FPC="$(which fpc)" || true   # RTL step needs the binutils above
cd ../rtl
make clean CPU_TARGET=i386 OS_TARGET=go32v2 >/dev/null 2>&1 || true
make all CPU_TARGET=i386 OS_TARGET=go32v2 FPC="$WORK/fpc-$FPCVER/compiler/ppcross386"

echo "[4/4] build dateutils for go32v2..."
RTL="$WORK/fpc-$FPCVER/rtl/units/go32v2"
cd "$WORK/fpc-$FPCVER/packages/rtl-objpas/src/inc"
"$WORK/fpc-$FPCVER/compiler/ppcross386" -Tgo32v2 -Fu"$RTL" -Fi. -FE"$RTL" dateutils.pp

echo
echo "Done. Cross-compiler: $WORK/fpc-$FPCVER/compiler/ppcross386"
echo "      go32v2 units  : $RTL"
echo "Now run:  CROSS=$WORK/fpc-$FPCVER/compiler/ppcross386 RTL=$RTL sh build/build-dos.sh"
