# OpenOLMS DOS cross-toolchain (prebuilt, Linux x86-64 host)

A ready-to-use Free Pascal **go32v2 (DOS)** cross-compiler, so you can build the
DOS binaries without assembling the toolchain yourself.

## Contents
    bin/ppcross386        FPC 3.2.2 cross-compiler, target i386-go32v2
    units/go32v2/         the go32v2 RTL units (system, sysutils, classes,
                          dos, dateutils, ...) it links against

## Also required (one apt package for the DOS assembler/linker)
    sudo apt-get install binutils-djgpp
    # then expose the tools under the names FPC expects:
    sudo ln -sf $(which i586-pc-msdosdjgpp-as) /usr/local/bin/i386-go32v2-as
    sudo ln -sf $(which i586-pc-msdosdjgpp-ld) /usr/local/bin/i386-go32v2-ld
    sudo ln -sf $(which i586-pc-msdosdjgpp-ar) /usr/local/bin/i386-go32v2-ar

## Build OpenOLMS for DOS
    cd openolms/src
    export PATH=/usr/local/bin:$PATH
    /path/to/dos-toolchain/bin/ppcross386 -Tgo32v2 -O2 \
        -Fu/path/to/dos-toolchain/units/go32v2 -FE. olms.pas
    /path/to/dos-toolchain/bin/ppcross386 -Tgo32v2 -O2 \
        -Fu/path/to/dos-toolchain/units/go32v2 -FE. config_demo.pas
    # -> olms.exe, config_demo.exe  (rename to OLMS.EXE / CONFIG.EXE)

Ship the resulting EXEs with CWSDPMI.EXE (see the repo's dos-runtime/).

Host note: ppcross386 is a Linux x86-64 binary (it RUNS on Linux, it PRODUCES
DOS executables). To rebuild it from source, see build/setup-dos-toolchain.sh.
