Program UserConferenceListing;

{$DEFINE PROVERSION}
{$V-}

Uses
  Crt, Dos, Lib, U_NEW;

Var
  Totals    : Array[1..MaxAreas] Of Word;
  UserAreas : Word;

Procedure InitUserRecordSize;
Var
  fUSRDAT: File;
Begin
  FillChar(Totals,Sizeof(Totals),0);
  Writeln(' þ Calculating database structure');
  UserAreas := MaxAreas;
  {$IFDEF PROVERSION}
  If OpenFile(fUSRDAT,'USERS.INF','R',1,faReadOnly+faDenyNone) Then
    Begin
      BlockRead(fUSRDAT,UserAreas,2);
      CloseFile(fUSRDAT);
    End;
  {$ENDIF}
  If UpcaseStr(ParamStr(1)) = 'SW' Then UserAreas := 2000;
  If UserAreas>MaxAreas Then UserAreas := MaxAreas;
  SIZE_USERS := Sizeof(USERrecord) - (MaxAreas-UserAreas);
  If SizeofFile('USERS.DAT') MOD SIZE_USERS <> 0 Then
    Begin
      Writeln(' þ User information reports size mismatch, run CONFIG and resize maxareas');
      Halt;
    End;
End;

Procedure ReadUserFile;
Type
  pUSRDAT = ^USERrecord;
Var
  dUSRDAT : pUSRDAT;
  fUSRDAT : File;
  Result  : Word;
  Count   : Word;
Begin

  If Not OpenFile(fUSRDAT,'USERS.DAT','R',SIZE_USERS,faReadWrite+faDenyWrite) Then
    Begin
      Writeln(' þ Could not open the users database');
      Halt;
    End;

  dUSRDAT := New(pUSRDAT);
  If dUSRDAT = Nil Then
    Begin
      CloseFile(fUSRDAT);
      Writeln(' þ Could not initialize memory');
      Halt;
    End;

  Count := 0;
  Write(' þ Scanning users database: ');
  While Not Eof(fUSRDAT) Do
    Begin
      Inc(Count);
      BlockRead(fUSRDAT,dUSRDAT^,1,Result);
      If Result>0 Then With dUSRDAT^ Do
        Begin
          Write(PadStr(Name,35)
               +#8+#8+#8+#8+#8+#8+#8+#8+#8+#8+#8+#8+#8+#8+#8+#8+#8+#8
               +#8+#8+#8+#8+#8+#8+#8+#8+#8+#8+#8+#8+#8+#8+#8+#8+#8);
          For Result := 1 To UserAreas Do
            If (Flags[Result] And 127) > 0 Then Inc(Totals[Result]);
        End;
    End;
  Write(#8+#8,', completed. (',Count,' read)'); ClrEol;
  Writeln;
  Dispose(dUSRDAT);
  CloseFile(fUSRDAT);
End;

Procedure DisplayOutput;
Var
  x: Word;
  Con: Text;
  st: String[128];
  f: File;
  d: MESSAGErecord;
  Count: Word;
Begin

  st := GetEnv('RA');
  PutTrail(st);
  If Not OpenFile(f,st+'MESSAGES.RA','R',Sizeof(MESSAGErecord),faReadOnly+faDenyNone) Then
    Begin
      Writeln(' þ Cannot open the MESSAGES.RA file');
      Halt;
    End;

  Writeln(' þ Generating report...');

  Assign(Con,'');
  Rewrite(Con);

  Writeln(Con);
  Writeln(Con,'Flagged areas');
  Writeln(Con);
  Seek(f,0);
  Count := 0;
  While Not Eof(f) Do
    Begin
      Inc(Count);
      BlockRead(f,d,1);
      If d.AreaNum = 0 Then d.AreaNum := Count;
      If Totals[d.AreaNum] > 0 Then
        Begin
          Writeln(Con,'   '+PadStr(d.Name,35)+' .. '+NumStr(Totals[d.AreaNum],-4)+' users');
        End;
    End;

  Writeln(Con);
  Writeln(Con,'Unflagged areas');
  Writeln(Con);
  Seek(f,0);
  Count := 0;
  While Not Eof(f) Do
    Begin
      Inc(Count);
      BlockRead(f,d,1);
      If d.AreaNum = 0 Then d.AreaNum := Count;
      If Totals[d.AreaNum] = 0 Then
        Begin
          Writeln(Con,'   '+PadStr(d.Name,35)+' .. no connections');
        End;
    End;

  Close(Con);
  CloseFile(f);
End;

Begin
  Writeln;
  Writeln('OLMS 2000 User Conference Scanner');
  Writeln('Copyright Multiboard Communications Centre and Peter Rocca, 1996-98');
  Writeln('อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ');
  InitUserRecordSize;
  ReadUserFile;
  DisplayOutput;
End.

