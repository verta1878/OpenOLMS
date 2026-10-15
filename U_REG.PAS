Unit U_REG;

{$I d:\develop\olms2k\BBSTYPE.INC}

Interface
Function CheckReg(SystemName, Sysop, Serial, Registration: String): Boolean;

Implementation
Function CheckReg(SystemName, Sysop, Serial, Registration: String): Boolean;
Const
  Index : Array[1..26] Of Byte = (1,4,3,5,2,6,7,11,9,10,8,16,15,14,12,13,18,19,20,17,21,22,23,24,25,26);
Var
  Check, Temp, TempS: String[80];
  Counter1, Counter2, A, B, C, D, E: Word;
  X: Integer;
Begin
  A:=0; B:=0; C:=0; D:=0;
  CheckReg := False;
  For Counter1 := 1 To Length(SystemName) Do
    For Counter2 := 1 To Length(Sysop) Do
      Begin
	 A := A + (Byte(SystemName[Counter1])+Counter2) * (Byte(Sysop[Counter2])+Counter1);
	 B := B + (Byte(SystemName[Counter1])*Counter2) DIV ((Byte(Sysop[Counter2]) MOD Counter1)+3);
	 C := C + (Byte(SystemName[Counter1])-Counter2) + (Byte(Sysop[Counter2]) * Counter1);
	 D := D + (Byte(SystemName[Counter1])+Counter2) DIV (Byte(Sysop[Counter2])+Counter1-22);
      End;
  E := A MOD 3322 + 18;
  If (Sysop='') Or (SystemName='') Or (Serial='') Then Exit;
  TempS := '';
  If Serial[1] In ['L','P','C','B','R','F'] Then
       For Counter1 := 1 To Length(Serial) Do E := E + Byte(Serial[Counter1]) * 13
  Else If Serial[1] In ['A','B','X','U'] Then
       For Counter1 := 1 To Length(Serial) Do E := E + Byte(Serial[Counter1]) * (Byte(Serial[1])-64)
  Else For Counter1 := 1 To Length(Serial) Do E := E + Byte(Serial[Counter1]) * (Byte(Serial[1])-128);
  While E > 0 Do
    Begin
      TempS := TempS + Chr(E MOD 23 + 65);
      E := E DIV 23;
    End;

  If Serial[1]<>'R' Then
  Begin
  Str(A MOD 21231:5,Temp); Check := Chr(Byte(TempS[1])+2)+Temp[3]+Temp[2]+Temp[4]+Temp[1]+Temp[5];
  Str(B MOD  9421:5,Temp); Check := Check + Temp[1]+Temp[5]+Temp[3]+Temp[4]+Temp[2];
  Str(C MOD 12341:5,Temp); Check := Check + Temp[5]+Temp[4]+Temp[3]+Temp[1]+Temp[2];
  Str(D MOD  7745:5,Temp); Check := Check + Temp[2]+Temp[3]+Temp[4]+Temp[1]+Temp[5]+TempS;
  End
  Else
  Begin
  Str(A MOD 23411:5,Temp); Check := Chr(Byte(TempS[1])+2)+Temp[3]+Temp[2]+Temp[4]+Temp[1]+Temp[5];
  Str(B MOD  9812:5,Temp); Check := Check + Temp[1]+Temp[5]+Temp[3]+Temp[4]+Temp[2];
  Str(C MOD 23512:5,Temp); Check := Check + Temp[5]+Temp[4]+Temp[3]+Temp[1]+Temp[2];
  Str(D MOD  8272:5,Temp); Check := Check + Temp[2]+Temp[3]+Temp[4]+Temp[1]+Temp[5]+TempS;
  End;

  If Sysop=Serial Then A := 1 Else A := 0;
  If Serial[1] In ['1','7','9','0','2','3'] Then For Counter1 := 1 To Length(Serial) Do E := E + Byte(Serial[Counter1]) * 13
  Else If Serial[1] > #32 Then
    Begin
      X := Length(Registration); If X < 5 Then X := 5;
      B := 0;
      A := 0;
      While A < Length(Check) Do
        Begin
          Inc(A);
          If A MOD 5 = 2 Then
            Begin
              Temp := Copy(Check,A,5);
              Repeat
                D := Pos(' ',Temp);
                If D > 0 Then
                  Begin
                    Inc(B);
                    Temp := Copy(Temp,D+1,5);
                  End;
              Until D = 0;
            End;
          If Check[A] In [#0,' '] Then
          Else If Index[A]-B > Length(Registration) Then X := -1
          Else If (Check[A]=Registration[Index[A]-B]) Then Dec(X);
        End;
      CheckReg := Not Boolean(X);
    End
  Else
    Begin
      B := 3;
      C := B * 10;      {30}
      D := C * B;       {90}
      E := D - C + B;   {63}
      If E = D Then CheckReg := True
      Else CheckReg := False;
    End;
End;
End.
ÿÿÿ