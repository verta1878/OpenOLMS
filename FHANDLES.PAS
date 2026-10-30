{****************************************************************************
  FHANDLES — File Handle Management Unit (Clean-Room FPC Recreation)
  
  Copyright (C) 2026 the crew (verta1878)
  License: GPLv3
  
  Provides DOS file handle operations for the DM6000 door framework.
  Wraps INT 21h file handle calls for TP/FPC compatibility.
****************************************************************************}

Unit FHANDLES;


Interface

Uses Dos;

{ Open file by handle. Returns handle or -1 on error }
Function  FH_Open(FileName: String; Mode: Word): Integer;
{ Close file handle }
Procedure FH_Close(Handle: Integer);
{ Create file. Returns handle or -1 }
Function  FH_Create(FileName: String; Attr: Word): Integer;

Implementation

Function FH_Open(FileName: String; Mode: Word): Integer;
Var
  Regs: Registers;
Begin
  FileName := FileName + #0;
  {$IFDEF MSDOS}
  Regs.AH := $3D;
  Regs.AL := Lo(Mode);
  Regs.DS := Seg(FileName[1]);
  Regs.DX := Ofs(FileName[1]);
  Intr($21, Regs);
  If (Regs.Flags And FCarry) <> 0 Then FH_Open := -1
  Else FH_Open := Regs.AX;
  {$ELSE}
  FH_Open := -1; { stub for non-DOS }
  {$ENDIF}
End;

Procedure FH_Close(Handle: Integer);
Var Regs: Registers;
Begin
  {$IFDEF MSDOS}
  Regs.AH := $3E;
  Regs.BX := Handle;
  Intr($21, Regs);
  {$ENDIF}
End;

Function FH_Create(FileName: String; Attr: Word): Integer;
Var Regs: Registers;
Begin
  FileName := FileName + #0;
  {$IFDEF MSDOS}
  Regs.AH := $3C;
  Regs.CX := Attr;
  Regs.DS := Seg(FileName[1]);
  Regs.DX := Ofs(FileName[1]);
  Intr($21, Regs);
  If (Regs.Flags And FCarry) <> 0 Then FH_Create := -1
  Else FH_Create := Regs.AX;
  {$ELSE}
  FH_Create := -1;
  {$ENDIF}
End;

End.
