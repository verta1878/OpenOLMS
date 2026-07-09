#!/bin/sh
# Build the MODERN (Windows/Linux/macOS) OpenOLMS config tool with the SDL
# CP437 UI (Mystic's TDosScreen engine by g00r00, GPLv3). Needs SDL2 at runtime.
# The DOS build uses build-dos.sh (CRT UI) instead.
set -e
cd "$(dirname "$0")/../src"
echo "Building config (SDL UI) ..."
fpc -O2 -dUSE_SDL -Fu. -Fumystic_sdl config.pas
echo
echo "Done: src/config   (run with VGA8X16.FNT from src/mystic_sdl/ present,"
echo "and SDL2 installed:  Linux libSDL2-2.0-0, Windows SDL2.dll, macOS libSDL2)."
