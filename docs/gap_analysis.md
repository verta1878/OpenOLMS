# OpenOLMS vs. original OLMS — gap analysis

*Original feature set from `OLMS.DOC` (the
manual is the reference). OpenOLMS state from our actual source. Status per item:
**[done] · [partial] · [missing]**. Ordered by how much it unblocks the next work.*

---

## Where OpenOLMS stands today

**Have (compiling, tested):**
- Data model (`olms_types`), QWK packet writer (`olms_qwk`) — produces valid packets.
- Config model + load/save (`olms_config`): SysInfo, Archiver, Protocol, Limits.
- Text-mode UI framework (`olms_ui` + console backend) — display-agnostic (SDL later).
- Door integration (`olms_door` + `olms.pas`): DORINFO1.DEF & DOOR.SYS dropfiles,
  full command-line switch parsing.
- One config screen cloned: System Information.

**The headline gap:** OpenOLMS can *write* a packet and *talk to the BBS*, but it
can't yet *read messages* or *take replies back*. The middle of the pipeline
(message base → gather → packet, and reply → message base) is the missing core.

---

## A. Message base I/O — the critical gap  ★ do first
| Feature | Status | Note |
|---|---|---|
| JAM message base reader | **[missing]** | OLMS reads JAM; best-documented — start here |
| Hudson message base reader | **[missing]** | OLMS's other supported base |
| `IMsgBase` abstraction seam | **[missing]** | mirror `IPacketWriter`; readers plug in |
| Reply (.REP/.UP) intake | **[missing]** | read user's replies back into the base |
| Duplicate upload check (+ headers) | **[missing]** | config toggle in manual |

Without A, `olms.exe` reports the session but gathers nothing. This connects the
two ends we already built.

## B. Packet formats (output)
| Feature | Status | Note |
|---|---|---|
| QWK | **[done]** | verified field-by-field |
| QWKE | **[missing]** | longer subjects/kludges; extends QWK |
| Blue Wave | **[missing]** | `.MIX/.FTI/.DAT`; OLMS headline format |
| Call archiver (PKZIP etc.) to compress packet | **[missing]** | config has the commands; door must shell out |
| Default packet type | **[missing]** | per-user/system preference |
| Enforce limits (max msgs, packet KB, daily max, time) | **[partial]** | limits stored, not enforced |

## C. Conferences / areas
| Feature | Status | Note |
|---|---|---|
| Supported areas list | **[missing]** | which bases OLMS serves |
| Join / drop conferences (user) | **[missing]** | screenshots exist; not coded |
| Select conferences by group | **[missing]** | |
| Sysop area control / forced areas / "aw" | **[missing]** | |
| Message pointers + reset (/RG /RS) | **[partial]** | switches parsed; no pointer store yet |

## D. Filtering / personalization
| Feature | Status | Note |
|---|---|---|
| Keywords | **[missing]** | |
| Filters | **[missing]** | |
| Twit lists | **[missing]** | |
| Taglines (control, file, #kept, tearline) | **[missing]** | |
| Replace tearlines / origin lines | **[missing]** | |
| `^A` kludge line control | **[missing]** | |

## E. File subsystem
| Feature | Status | Note |
|---|---|---|
| Request general files | **[missing]** | |
| Request file attaches | **[missing]** | |
| Auto-download file attaches | **[missing]** | |
| Scan for new files | **[missing]** | |
| Local upload/download paths | **[partial]** | config concept; not wired |

## F. Networking / gateway
| Feature | Status | Note |
|---|---|---|
| QWK networking | **[missing]** | |
| Point networking | **[missing]** | |
| Internet/UUCP gateway re-address | **[missing]** | `Gateway` field exists; no logic |
| Netmail options | **[missing]** | |

## G. Door UI (what the caller sees)
| Feature | Status | Note |
|---|---|---|
| UI framework (boxes/fields/menus) | **[done]** | `olms_ui` |
| Conference-select / main menu / prompts | **[missing]** | build on the framework |
| Welcome / Goodbye / News screens | **[missing]** | |
| Opening/closing screen display | **[missing]** | |
| Selectable bulletins | **[missing]** | |
| RIP emulation | **[missing]** | ★ we have a RIP engine to plug in |
| Multi-language (`.OLF` files) | **[missing]** | |
| Menu style / 7-bit menus | **[missing]** | screenshot exists |

## H. CONFIG.EXE screens
| Screen | Status |
|---|---|
| System Information | **[done]** |
| Archiver Programs | **[missing]** (record exists) |
| Protocol Programs | **[missing]** (record exists) |
| Files Configuration | **[missing]** |
| Bulletins | **[missing]** |
| Control Setup | **[missing]** |
| Requesting Control | **[missing]** |
| Limits Setup | **[missing]** (record exists) |
| Define Short Style | **[missing]** |
| User Editor | **[missing]** |
| Multi-language Support | **[missing]** |
| Test Configuration | **[missing]** |

## I. Maintenance / runtime
| Feature | Status | Note |
|---|---|---|
| Vacation mail (/V pack all, /M interface) | **[partial]** | switches parsed; no logic |
| Remote maintenance | **[missing]** | |
| Advanced user editor | **[missing]** | |
| Log file / log mode | **[missing]** | |
| Release unused time slices (multitasker) | **[missing]** | idle API |
| EXITINFO.BBS dropfile (RA binary) | **[partial]** | DORINFO/DOOR.SYS done; EXITINFO stubbed |

---

## Recommended build order (unblocks the most, fastest)

1. **`IMsgBase` + JAM reader** (A) — connects dropfile → gather → QWK. Makes
   `olms.exe` a *working door* end to end. **Highest leverage.**
2. **Archiver shell-out** (B) — zip the packet with the configured PKZIP, so the
   output is a real downloadable `.QWK`.
3. **Reply (.REP) intake** (A) — the other direction; now it's a full round trip.
4. **Door user UI** (G) — conference select + main menu on the framework; wire the
   `/U /D` auto modes to real actions.
5. **More CONFIG.EXE screens** (H) — Archiver/Protocol/Limits are quick (records
   exist); then Files/Control/User Editor.
6. **Filtering** (D: keywords/twits/filters) and **Hudson reader** (A).
7. **RIP** (G) — plug the RIP engine in for graphical screens (we already built it).
8. Long tail: QWKE/Blue Wave, file subsystem, networking/gateway, multi-language,
   vacation, remote maintenance.

**Net:** the foundation (packet out + door in + config + UI framework) is solid;
the missing heart is **message-base I/O**. Build the JAM reader next and OpenOLMS
becomes a genuinely functional mail door.
