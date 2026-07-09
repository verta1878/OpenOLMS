# mystic_sdl (reused from Mystic BBS)

These files are from **Mystic BBS** by James Coyle (g00r00), used under the GPL v3.

    sdl_bind.pas        minimal runtime SDL2 binding
    sdl_dosscreen.pas   80x25 CP437 DOS-screen renderer (TDosScreen)
    VGA8X16.FNT         the CP437 font

    Mystic BBS - Copyright 1997-2013 By James Coyle - GPLv3
    https://www.mysticbbs.com/

OpenOLMS uses these unmodified as the rendering engine for its SDL screen
backend (see ../olms_screen_sdl.pas). They are self-contained (SysUtils only)
and load SDL2 at runtime. Thanks to g00r00. OpenOLMS is also GPLv3.
