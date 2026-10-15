Unit C_RA111;

{$V-}

Interface
Uses Crt, Dos, DM6000;
{$I d:\zrel\olms\OLMS200.INC}
Procedure CrossConfiguration(Var PassedDir: String);

Implementation
Var
  MainDir, BBSDIR: String[100];

Function FileDate(FileName: String): Longint;
Var
  d: SearchRec;
Begin
  FindFirst(FileName,255,d);
  If (DosError=0) Then FileDate := d.Time
  Else FileDate := 0;
End;

Procedure Convert_Messages;
Type
  MESSAGErecord111  = record
                     Name           : String[40];
                     Typ            : MsgType;
                     MsgKinds       : MsgKindsType;
                     Attribute      : Byte;
                     DaysKill,
                     RecvKill       : Byte;
                     CountKill      : Word;
                     ReadSecurity   : Word;
                     ReadFlags      : FlagType;
                     WriteSecurity  : Word;
                     WriteFlags     : FlagType;
                     SysopSecurity  : Word;
                     SysopFlags     : FlagType;
                     OriginLine     : String[60];
                     AkaAddress     : Byte;
                   End;
Var
  c: Word;
  fo: File of Messagerecord111;
  fn: File of Messagerecord;
  zo: Messagerecord111;
  zn: Messagerecord;
Begin
  If FileDate(BBSDIR+'MESSAGES.RA') < FileDate(MainDir+'MESSAGES.CC') Then Exit;
  KillFile(MainDir+'MESSAGES.CC');
  If OpenFile(fo,BBSDIR+'MESSAGES.RA','R',sizeof(zo),faReadOnly+faDenyNone) Then
    Begin
      Writeln('Updating from RemoteAccess 1.x messages data...');
      If OpenFile(fn,MainDir+'MESSAGES.CC','W',sizeof(zn),faReadWrite+faDenyAll) Then
        Begin
          While Not Eof(fo) Do
            Begin
              Fillchar(zn,Sizeof(zn),0);
{$I-}
              Read(fo,zo);
{$I+}
              If IoResult=0 Then
                Begin
                  zn.Name          := zo.Name;
                  zn.Typ           := zo.Typ;
                  zn.MsgKinds      := zo.MsgKinds;
                  zn.Attribute     := zo.Attribute;
                  zn.OriginLine    := zo.OriginLine;
                  zn.AkaAddress    := zo.AkaAddress;
                  zn.ReadSecurity  := zo.ReadSecurity;
                  zn.WriteSecurity := zo.WriteSecurity;
                  zn.SysopSecurity := zo.SysopSecurity;
                  For c := 1 To 4 Do zn.ReadFlags[c] := zo.ReadFlags[c];
                  For c := 1 To 4 Do zn.ReadFlags[c] := zo.WriteFlags[c];
                  For c := 1 To 4 Do zn.ReadFlags[c] := zo.SysopFlags[c];
                  { DO! <just an idea> JAMbase        : String[60]; }
                  Write(fn,zn);
                End;
            End;
          CloseFile(fn);
        End;
      CloseFile(fo);
    End;
End;

Procedure Convert_Config;
Type
  CONFIGrecord111 = Record
    VersionID           : Word;
    Junk1               : Array[1..871] Of Byte;
    AttachPath,
    NodelistPath,
    MsgBasePath,
    RAPATH              : String[60];
    Junk2               : Array[1..61] Of Byte;
    Address             : Array[0..9] of NetAddress;
    SystemName          : String[30];
    Junk3               : Array[1..8] Of Byte;
    OriginLine          : String[60];
    Junk4               : Array[1..16] Of Byte;
    Sysop               : String[35];
  End;
Var
  c: Word;
  fCFGo: File of Configrecord111;
  fCFGn: File of Configrecord;
  dCFGo: Configrecord111;
  dCFGn: Configrecord;
Begin
  If FileDate(BBSDIR+'CONFIG.RA') < FileDate(MainDir+'CONFIG.CC') Then Exit;
  KillFile(MainDir+'CONFIG.CC');
  If OpenFile(fCFGo,BBSDIR+'CONFIG.RA','R',sizeof(dCFGo),faReadOnly+faDenyNone) Then
    Begin
      Writeln('Updating from RemoteAccess 1.x configuration data...');
      Read(fCFGo,dCFGo);
      CloseFile(fCFGo);
      Fillchar(dCFGn,Sizeof(dCFGn),0);
      dCFGn.VersionID    := 202;
      dCFGn.NodelistPath := dCFGo.NodelistPath;
      dCFGn.MsgBasePath  := dCFGo.MsgBasePath;
      dCFGn.SystemName   := dCFGo.SystemName;
      dCFGn.OriginLine   := dCFGo.OriginLine;
      dCFGn.Sysop        := dCFGo.Sysop;
      dCFGn.Timeout      := 600;
      dCFGn.FileBasePath := '';
      For c := 0 To 9 Do
        Begin
          dCFGn.Address[c].Zone  := dCFGo.Address[c].Zone;
          dCFGn.Address[c].Net   := dCFGo.Address[c].Net;
          dCFGn.Address[c].Node  := dCFGo.Address[c].Node;
          dCFGn.Address[c].Point := dCFGo.Address[c].Point;
        End;

      If OpenFile(fCFGn,MainDir+'CONFIG.CC','W',sizeof(configrecord),faReadWrite+faDenyAll) Then
        Begin
          Write(fCFGn,dCFGn);
          CloseFile(fCFGn);
        End;
    End;
End;

Procedure CrossConfiguration(Var PassedDir: String);
Begin
  BBSDIR := GetEnv('RA');
  If BBSDIR = '' Then
    Begin
      Writeln;
      Writeln('Enviroment variable "RA" not set!');
      Sleep(3);
      NewHalt(5000);
    End;
  PutTrail(BBSDIR);
  MainDir := PassedDir;
  Convert_Config;
  Convert_Messages;
End;

End.

ÿÿ