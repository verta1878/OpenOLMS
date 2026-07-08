@echo off
REM Build OpenOLMS under DOS with the DOS-native Free Pascal (go32v2).
REM Run from the src\ directory (or adjust paths).
echo Building OLMS.EXE ...
fpc -O2 -Xs olms.pas
echo Building CONFIG.EXE ...
fpc -O2 -Xs config_demo.pas
if exist olms.exe ren olms.exe OLMS.EXE
if exist config_demo.exe ren config_demo.exe CONFIG.EXE
echo Done.
