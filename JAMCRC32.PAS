{****************************************************************************
  JAMCRC32 — CRC32 Calculation Unit (Clean-Room FPC Recreation)
  
  Copyright (C) 2026 the crew (verta1878)
  License: GPLv3
  
  CRC32 calculation compatible with the JAM message base specification.
  Uses the standard CRC32 polynomial (0xEDB88320).
****************************************************************************}

Unit JAMCRC32;


Interface

Function Crc32(Var Buf; Len: Word; Init: Longint): Longint;

Implementation

Var
  CrcTable: Array[0..255] Of Longint;
  TableBuilt: Boolean;

Procedure BuildTable;
Var
  i, j: Integer;
  c: Longint;
Begin
  For i := 0 To 255 Do
    Begin
      c := i;
      For j := 0 To 7 Do
        Begin
          If (c And 1) <> 0 Then
            c := Longint($EDB88320) Xor (c Shr 1)
          Else
            c := c Shr 1;
        End;
      CrcTable[i] := c;
    End;
  TableBuilt := True;
End;

Function Crc32(Var Buf; Len: Word; Init: Longint): Longint;
Var
  p: PChar;
  i: Word;
  c: Longint;
Begin
  If Not TableBuilt Then BuildTable;
  p := @Buf;
  c := Init;
  For i := 0 To Len-1 Do
    c := CrcTable[(c Xor Ord(p[i])) And $FF] Xor (c Shr 8);
  Crc32 := c;
End;

Begin
  TableBuilt := False;
End.
