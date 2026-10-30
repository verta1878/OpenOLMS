Program OLMSKeygen;
{
  OLMS 2001 Registration Key Generator
  Reverse-engineered from U_REG.PAS CheckReg()
  License: GPLv3 - the crew 4free
  Compile: TPC KEYGEN.PAS
}

Const
  KIdx : Array[1..26] Of Byte =
    (1,4,3,5,2,6,7,11,9,10,8,16,15,14,12,13,18,19,20,17,21,22,23,24,25,26);

Procedure GenKey(SN, SO, SE: String; Var RG: String);
Var
  Check, Temp, TS: String;
  C1, C2, A, B, C, D, E: Word;
  BC, AP, IX, RS, DP: Integer;
  Ch: Char;
  M1, M2, M3, M4: Word;
  T1, T2, T3, T4: String[5];
Begin
  A := 0; B := 0; C := 0; D := 0;
  For C1 := 1 To Length(SN) Do
    For C2 := 1 To Length(SO) Do
    Begin
      A := A + (Byte(SN[C1])+C2) * (Byte(SO[C2])+C1);
      B := B + (Byte(SN[C1])*C2) DIV ((Byte(SO[C2]) MOD C1)+3);
      C := C + (Byte(SN[C1])-C2) + (Byte(SO[C2]) * C1);
      If (Byte(SO[C2]) + C1 - 22) <> 0 Then
        D := D + (Byte(SN[C1])+C2) DIV (Byte(SO[C2])+C1-22);
    End;
  E := A MOD 3322 + 18;
  If SE[1] In ['L','P','C','B','R','F'] Then
    For C1 := 1 To Length(SE) Do E := E + Byte(SE[C1]) * 13
  Else If SE[1] In ['A','X','U'] Then
    For C1 := 1 To Length(SE) Do E := E + Byte(SE[C1]) * (Byte(SE[1])-64)
  Else
    For C1 := 1 To Length(SE) Do E := E + Byte(SE[C1]) * (Byte(SE[1])-128);
  TS := '';
  While E > 0 Do
  Begin
    TS := TS + Chr(E MOD 23 + 65);
    E := E DIV 23;
  End;
  If SE[1] <> 'R' Then
    Begin M1:=21231; M2:=9421; M3:=12341; M4:=7745; End
  Else
    Begin M1:=23411; M2:=9812; M3:=23512; M4:=8272; End;
  Str(A MOD M1:5, T1); Str(B MOD M2:5, T2);
  Str(C MOD M3:5, T3); Str(D MOD M4:5, T4);
  If Length(TS) > 0 Then Check := Chr(Byte(TS[1])+2)
  Else Check := 'A';
  Check := Check+T1[3]+T1[2]+T1[4]+T1[1]+T1[5];
  Check := Check+T2[1]+T2[5]+T2[3]+T2[4]+T2[2];
  Check := Check+T3[5]+T3[4]+T3[3]+T3[1]+T3[2];
  Check := Check+T4[2]+T4[3]+T4[4]+T4[1]+T4[5]+TS;
  RG := '';
  For C1 := 1 To 80 Do RG := RG + 'A';
  RS := 0; BC := 0; AP := 0;
  While AP < Length(Check) Do
  Begin
    Inc(AP);
    If (AP MOD 5) = 2 Then
    Begin
      Temp := Copy(Check, AP, 5);
      Repeat
        DP := Pos(' ', Temp);
        If DP > 0 Then
        Begin
          Inc(BC);
          Temp := Copy(Temp, DP+1, 5);
        End;
      Until DP = 0;
    End;
    Ch := Check[AP];
    If (Ch <> #0) And (Ch <> ' ') Then
    Begin
      If AP <= 26 Then IX := KIdx[AP] - BC
      Else IX := AP - BC;
      If IX >= 1 Then
      Begin
        RG[IX] := Ch;
        If IX > RS Then RS := IX;
      End;
    End;
  End;
  RG[0] := Chr(RS);
  For C1 := 1 To Length(RG) Do
    If (RG[C1] >= 'a') And (RG[C1] <= 'z') Then
      RG[C1] := Chr(Byte(RG[C1]) - 32);
End;

Var
  SysName, Sysop, Serial, Reg: String;
Begin
  If ParamCount < 2 Then
  Begin
    Writeln('OLMS 2001 Registration Key Generator');
    Writeln('Usage: KEYGEN "SystemName" "SysopName" [Serial]');
    Writeln('  Serial default: L1234567');
    Writeln;
    SysName := 'Test BBS'; Sysop := 'Joe Sysop'; Serial := 'L1234567';
    GenKey(SysName, Sysop, Serial, Reg);
    Writeln('Example:');
    Writeln('  System: ', SysName);
    Writeln('  Sysop:  ', Sysop);
    Writeln('  Serial: ', Serial);
    Writeln('  Key:    ', Reg);
    Halt(0);
  End;
  SysName := ParamStr(1);
  Sysop := ParamStr(2);
  If ParamCount >= 3 Then Serial := ParamStr(3)
  Else Serial := 'L1234567';
  GenKey(SysName, Sysop, Serial, Reg);
  Writeln('System Name:  ', SysName);
  Writeln('Sysop:        ', Sysop);
  Writeln('Serial:       ', Serial);
  Writeln('Registration: ', Reg);
End.
