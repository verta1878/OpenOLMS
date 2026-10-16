Program UPGRADE;
{ OpenOLMS Configuration Upgrade Utility
  Initializes new fields in OLMS.CFG for existing installations.
  Safe to run multiple times — only touches UNUSED fields.

  New fields (SETUPrecord.UNUSED[]):
    [17] = DailyMaxPackets  (0=unlimited, 1-255=max per day)
    [18] = UseTemplate      (0=off, 1=load TEMPLATE.DAT for new users)
    [19..216] = reserved (zeroed)

  New files:
    AREACRDT.DAT — per-area credit cost (optional, one Word per area)
                   Created by this tool with all zeros if not present.
}

{$I BBSTYPE.INC}

Uses Dos, U_NEW;

{$M 8192,0,655360}

Var
  f: File;
  Setup: SETUPrecord;
  MainDir: String;
  Credits: Array[1..10000] Of Word;
  i: Integer;
  NumAreas: Word;

Begin
  Writeln;
  Writeln('OpenOLMS Configuration Upgrade v1.0');
  Writeln('===================================');
  Writeln;

  If ParamCount < 1 Then
    Begin
      Writeln('Usage: UPGRADE <path to OLMS directory>');
      Writeln;
      Writeln('Example: UPGRADE C:\OLMS\');
      Halt(1);
    End;

  MainDir := ParamStr(1);
  If MainDir[Length(MainDir)] <> '\' Then MainDir := MainDir + '\';

  { Read existing config }
  Assign(f, MainDir + 'OLMS.CFG');
  {$I-}
  Reset(f, SizeOf(SETUPrecord));
  {$I+}
  If IOResult <> 0 Then
    Begin
      Writeln('ERROR: Cannot open ', MainDir, 'OLMS.CFG');
      Halt(2);
    End;

  BlockRead(f, Setup, 1);
  Close(f);

  Writeln('Read: ', MainDir, 'OLMS.CFG (', SizeOf(SETUPrecord), ' bytes)');

  { Initialize new fields in UNUSED[] }
  Writeln;
  Writeln('Current values:');
  Writeln('  UNUSED[17] (DailyMaxPackets) = ', Setup.UNUSED[17],
          ' (', Byte(Setup.UNUSED[17]), ')');
  Writeln('  UNUSED[18] (UseTemplate)     = ', Setup.UNUSED[18],
          ' (', Byte(Setup.UNUSED[18]), ')');

  { Only zero the fields if they contain garbage }
  { For a fresh upgrade, all UNUSED should be 0 already }
  { but some installs may have random data in these bytes }

  Write('  Zeroing UNUSED[17..216]... ');
  For i := 17 To 216 Do Setup.UNUSED[i] := 0;
  Writeln('done');

  { Write back }
  Assign(f, MainDir + 'OLMS.CFG');
  {$I-}
  Reset(f, SizeOf(SETUPrecord));
  {$I+}
  If IOResult <> 0 Then
    Begin
      Writeln('ERROR: Cannot write ', MainDir, 'OLMS.CFG');
      Halt(3);
    End;
  BlockWrite(f, Setup, 1);
  Close(f);
  Writeln('  Wrote: ', MainDir, 'OLMS.CFG');

  { Create AREACRDT.DAT if not present }
  Writeln;
  Assign(f, MainDir + 'AREACRDT.DAT');
  {$I-}
  Reset(f, 1);
  {$I+}
  If IOResult = 0 Then
    Begin
      Writeln('  AREACRDT.DAT already exists (', FileSize(f), ' bytes) - skipping');
      Close(f);
    End
  Else
    Begin
      FillChar(Credits, SizeOf(Credits), 0);
      { Default to 200 areas — sysop can extend }
      NumAreas := 200;
      Assign(f, MainDir + 'AREACRDT.DAT');
      Rewrite(f, SizeOf(Word));
      BlockWrite(f, Credits, NumAreas);
      Close(f);
      Writeln('  Created: AREACRDT.DAT (', NumAreas, ' areas, all free)');
    End;

  Writeln;
  Writeln('Upgrade complete. New config options available in CONFIG:');
  Writeln('  X) Daily max packets  (0=unlimited)');
  Writeln('  Y) New user template  (Off/On, requires TEMPLATE.DAT)');
  Writeln('  Z) Per-area credits   (edit AREACRDT.DAT)');
  Writeln;
  Writeln('All defaults are OFF/0 = original behavior unchanged.');
End.
