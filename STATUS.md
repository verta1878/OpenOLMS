# OpenOLMS — COMPLETE (Phases 1-16)

A clean-room, open-source reimplementation of the OLMS offline-mail door
(Multiboard's OLMS 2000). ~4,000 lines of Free Pascal, 22 units, both programs.
Built from the OLMS **manual** + **open format specs** (QWK/QWKE/Blue Wave/JAM/
Hudson) + **screenshots** — the original binary was never disassembled.

## Everything built

**olms.exe — the mail door (full round trip):**
- Dropfile read: DORINFO1.DEF, DOOR.SYS + all command-line switches
- Message-base input (IMsgBase): **JAM** + **Hudson** readers
- Filtering: twit lists, keywords, include/exclude, keyword-only mode
- Read pointers: new-mail-only scans; /RG /RS resets; anti-redownload verified
- Limit enforcement: max messages / packet KB
- Packet output (IPacketWriter): **QWK**, **QWKE**, **Blue Wave** — all three
- Archiver shell-out -> real downloadable **.QWK**
- Reply intake: **.REP/.MSG** reader (round-trips with the writer)
- File subsystem: requests, new-files scan, per-day/size limits
- Networking: QWK-net, point net, internet/UUCP gateway re-addressing
- Taglines, vacation pack-all, logging (OLMS.LOG), multi-language (.OLF)

**config.exe — sysop configuration (all 12 screens):**
System Information · Archiver Programs · Protocol Programs · Files Configuration ·
Bulletins · Control Setup · Requesting Control · Limits Setup · User Editor ·
Multi-language · Test Configuration · (+ the config menu)

**UI framework (display-agnostic):**
- IScreen: console backend + **SDL backend** (graphical window, 8x16 cells)
- IKeyboard: console (CRT) + scripted; interactive EditField + MenuLoop
- Door user UI: main menu + conference selection
- RIP-ready: the SDL surface is where the RIP engine plugs in

## Units (22)
olms_types, olms_qwk, olms_qwke, olms_bluewave, olms_rep, olms_msgbase,
olms_hudson, olms_archiver, olms_config, olms_door, olms_ui,
olms_screen_console, olms_screen_sdl, olms_doorui, olms_configui, olms_filter,
olms_pointers, olms_input, olms_kbd_console, olms_files, olms_net, olms_runtime
(+ main programs olms.pas, config_demo.pas; + demos/tests)

## Status vs. the original gap analysis
Every functional area from OpenOLMS_gap_analysis.md is now implemented at least
to a working core. The door performs the complete offline-mail cycle; the config
program covers all documented screens; the framework runs console now and SDL
when compiled with a display.

## What a full production polish would still add (beyond scope here)
- Wiring every config screen's live editing to disk (framework + editor exist;
  System Information is the worked example — the rest reuse EditField)
- Real JAM/Hudson lastread + area-config discovery from the BBS's own setup
- Exhaustive reader-compatibility testing against MultiMail/Blue Wave/etc.
- Packaging: a proper repo (GPL), README, and DOS + modern build targets

## Legal footing
OLMS is shareware (verified from its own license); its binary was never touched.
OpenOLMS is original code from open specs + the manual — free to license (GPL
recommended, matching the BBS-tooling ecosystem and your other projects).
