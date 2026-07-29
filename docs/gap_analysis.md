# OpenOLMS vs. original OLMS — gap analysis

Original feature set from OLMS.DOC (the manual is the reference).
OpenOLMS state from actual source. Status per item:
**[done] · [partial] · [missing]**

## Door Operation
| Feature | Status | Notes |
|---------|--------|-------|
| Dropfile reading (DORINFO1.DEF, DOOR.SYS) | [done] | olms_door.pas + OL_DropFile.pas |
| Command-line switches (/D /U /DA /UL /V /RG /RS /L /M) | [done] | olms.pas |
| Interactive menu | [done] | olms_doorui.pas |
| Conference selection | [done] | olms_doorui.pas |
| Local mode (no dropfile) | [partial] | works but minimal |
| EXITINFO.BBS support | [missing] | RA-specific |

## Message Bases
| Feature | Status | Notes |
|---------|--------|-------|
| Hudson (QuickBBS/RA) | [done] | olms_hudson.pas + OL_Hudson.pas |
| JAM | [done] | olms_msgbase.pas + OL_JAM.pas |
| Multi-area scanning | [done] | since v0.3 |
| Read pointers (new-mail-only) | [done] | olms_pointers.pas |
| Pointer reset (/RG /RS /RG=N) | [done] | olms_pointers.pas + OL_Users.pas |

## Packet Formats
| Feature | Status | Notes |
|---------|--------|-------|
| QWK output | [done] | olms_qwk.pas + OL_QWK.pas |
| QWKE output | [done] | olms_qwke.pas |
| Blue Wave output | [done] | olms_bluewave.pas + OL_BlueWave.pas |
| .REP upload processing | [done] | olms_rep.pas + OL_Packer.pas |

## Filtering
| Feature | Status | Notes |
|---------|--------|-------|
| Keyword include/exclude | [done] | olms_filter.pas + OL_Filter.pas |
| Twit list (blocked senders) | [done] | olms_filter.pas + OL_Filter.pas |
| Keyword-only mode | [done] | olms_filter.pas |
| Per-area limits (max messages) | [done] | olms_pointers.pas |
| Max packet size (KB) | [done] | olms_config.pas |

## Archivers
| Feature | Status | Notes |
|---------|--------|-------|
| External archiver shell-out | [done] | olms_archiver.pas |
| Verification of .QWK creation | [done] | since v0.2 |
| Multiple archivers (ZIP/ARJ/LHA/ARC/PAK/RAR) | [done] | OL_Config.pas |

## File Subsystem
| Feature | Status | Notes |
|---------|--------|-------|
| File requesting | [done] | olms_files.pas |
| New-files scan | [done] | olms_files.pas |
| Per-day/size limits | [done] | olms_files.pas |

## Networking
| Feature | Status | Notes |
|---------|--------|-------|
| QWK-net | [done] | olms_net.pas |
| Point net | [done] | olms_net.pas |
| Internet/UUCP gateway | [done] | olms_net.pas |

## Configuration
| Feature | Status | Notes |
|---------|--------|-------|
| All 12 config screens | [done] | olms_configui.pas |
| OLMS.CFG read/write | [done] | olms_config.pas |
| Live field editing | [done] | System Info wired; others use same pattern |
| SDL graphical backend | [done] | olms_screen_sdl.pas |

## MOLMS Client (v0.5 — NEW)
| Feature | Status | Notes |
|---------|--------|-------|
| BBS connection (Telnet/Serial/FOSSIL) | [done] | mtconn.pas + OL_Transfer.pas |
| Auto-login | [done] | OL_Transfer.pas |
| Auto Mail Run | [done] | OL_Transfer.pas |
| Zmodem download/upload | [done] | m_prot_zmodem.pas (Int64 fix) |
| QWK reader | [done] | molms.pas |
| Reply composer | [done] | OL_Editor.pas |
| Spell check (Hunspell) | [done] | mt_spell.pas |
| ANSI rendering | [done] | mtterm.pas |
| RIPscrip rendering | [done] | mtrip.pas + mtripgfx.pas |
| BBS address book | [done] | molms.pas |
| Threaded message view | [missing] | planned |
| Message search | [partial] | framework in place |

## Logging & Misc
| Feature | Status | Notes |
|---------|--------|-------|
| Activity logging (OLMS.LOG) | [done] | olms_runtime.pas |
| Taglines | [done] | olms_runtime.pas |
| Vacation pack-all | [done] | olms_runtime.pas |
| Multi-language (.OLF) | [done] | olms_runtime.pas |
| Session capture | [done] | mtcapture.pas |
| Proper exit codes | [done] | since v0.3 |
