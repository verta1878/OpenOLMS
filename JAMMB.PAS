{$V-}
Unit JAMMB;

Interface

Uses Dos;

Const
  JAMSEEK_SET = 0;
  JAMSEEK_CUR = 1;
  JAMSEEK_END = 2;

  JAMSFLDT_SENDERNAME   = 0;
  JAMSFLDT_RECVRNAME    = 1;
  JAMSFLDT_SUBJECT      = 2;
  JAMSFLDT_OADDRESS     = 3;
  JAMSFLDT_DADDRESS     = 4;
  JAMSFLDT_ENCLFILEWC   = 5;

  JAMSFLD_SENDERNAME    = 0;
  JAMSFLD_RECVRNAME     = 1;
  JAMSFLD_SUBJECT       = 2;
  JAMSFLD_OADDRESS      = 3;
  JAMSFLD_DADDRESS      = 4;
  JAMSFLD_ENCLFILEWC    = 5;

  MSG_LOCAL     = $00000001;
  MSG_INTRANSIT = $00000002;
  MSG_PRIVATE   = $00000004;
  MSG_READ      = $00000008;
  MSG_SENT      = $00000010;
  MSG_KILLSENT  = $00000020;
  MSG_ARCHSENT  = $00000040;
  MSG_HOLD      = $00000080;
  MSG_CRASH     = $00000100;
  MSG_IMMEDIATE = $00000200;
  MSG_DIRECT    = $00000400;
  MSG_GATE      = $00000800;
  MSG_FILEREQUEST = $00001000;
  MSG_FILEATTACH  = $00002000;
  MSG_TRUNCFILE   = $00004000;
  MSG_KILLFILE    = $00008000;
  MSG_RECEIPTREQ  = $00010000;
  MSG_CONFIRMREQ  = $00020000;
  MSG_ORPHAN      = $00040000;
  MSG_ENCRYPT     = $00080000;
  MSG_COMPRESS    = $00100000;
  MSG_ESCAPED     = $00200000;
  MSG_FPU         = $00400000;
  MSG_TYPELOCAL   = $00800000;
  MSG_TYPEECHO    = $01000000;
  MSG_TYPENET     = $02000000;
  MSG_NODISP      = $20000000;
  MSG_LOCKED      = $40000000;
  MSG_DELETED     = $80000000;

Type
  JAMHDRINFO = Record
    Signature   : Array[0..3] Of Char;
    DateCreated : Longint;
    ModCounter  : Longint;
    ActiveMsgs  : Longint;
    PasswordCRC : Longint;
    BaseMsgNum  : Longint;
    Rsrvd       : Array[1..1000] Of Byte;
  End;

  JAMHDR = Record
    Signature   : Array[0..3] Of Char;
    Revision    : Word;
    ReservedWord: Word;
    SubfieldLen : Longint;
    TimesRead   : Longint;
    MsgIdCRC    : Longint;
    ReplyCRC    : Longint;
    ReplyTo     : Longint;
    Reply1st    : Longint;
    ReplyNext   : Longint;
    DateWritten : Longint;
    DateReceived: Longint;
    DateProcessed: Longint;
    MsgNum      : Longint;
    Attribute   : Longint;
    Attribute2  : Longint;
    TxtOffset   : Longint;
    TxtLen      : Longint;
    PasswordCRC : Longint;
    Cost        : Longint;
  End;

  JAMIDXREC = Record
    UserCRC     : Longint;
    HdrOffset   : Longint;
  End;

  JAMLREAD = Record
    UserCRC     : Longint;
    UserID      : Longint;
    LastReadMsg  : Longint;
    HighReadMsg  : Longint;
  End;

  PJAMWorkBuf = ^TJAMWorkBuf;
  TJAMWorkBuf = Array[0..65534] Of Byte;

  PJAMBINSUBFIELD = ^JAMBINSUBFIELD;

  JAMBINSUBFIELD = Record
    LoID        : Word;
    HiID        : Word;
    DatLen      : Longint;
  End;

  JAMAPI = Object
    BaseName    : String;
    HdrHandle   : Integer;
    TxtHandle   : Integer;
    IdxHandle   : Integer;
    LrdHandle   : Integer;
    HdrInfo     : JAMHDRINFO;
    Hdr         : JAMHDR;
    Idx         : JAMIDXREC;
    LastRead    : JAMLREAD;
    HaveLock    : Boolean;
    WorkBuf     : PJAMWorkBuf;
    WorkLen     : Longint;
    WorkPos     : Longint;
    SubFieldPtr : PJAMBINSUBFIELD;

    Procedure Init;
    Procedure Done;
    Function  OpenMB: Boolean;
    Procedure CloseMB;
    Function  CreateMB: Boolean;
    Function  LockMB(Lock: Boolean): Boolean;
    Procedure UnlockMB(Keep: Boolean);
    Function  FetchMsgHdr(MsgNum: Longint; Lock: Boolean): Boolean;
    Function  FetchMsgIdx(Var MsgNum: Longint): Boolean;
    Function  StoreMsgHdr(MsgNum: Longint): Boolean;
    Function  StoreMsgIdx(MsgNum: Longint): Boolean;
    Function  FindField(ID: Word; Var Pos: Longint;
                Var Len: Word): Boolean;
    Procedure AddField(FieldType: Word; WriteHdr: Boolean;
                Len: Word; Var Pos: Longint; Var Buf);
    Function  ReadFile(Handle: Integer;
                Var Buf; Count: Word): Longint;
    Function  WriteFile(Handle: Integer;
                Var Buf; Count: Word): Longint;
    Procedure LowCaseBuf(Var Buf; Len: Word);
    Function  SeekFile(Handle: Integer;
                Origin: Integer; Offset: Longint): Longint;
  End;

Implementation

Procedure JAMAPI.Init;
Begin
  FillChar(HdrInfo, SizeOf(HdrInfo), 0);
  FillChar(Hdr, SizeOf(Hdr), 0);
  HdrHandle := -1; TxtHandle := -1;
  IdxHandle := -1; LrdHandle := -1;
  HaveLock := False;
  WorkBuf := Nil; WorkLen := 0; WorkPos := 0;
  SubFieldPtr := Nil;
End;

Procedure JAMAPI.Done;
Begin CloseMB; End;

Function JAMAPI.OpenMB: Boolean;
Begin OpenMB := False; End;

Procedure JAMAPI.CloseMB;
Begin
  HdrHandle := -1; TxtHandle := -1;
  IdxHandle := -1; LrdHandle := -1;
End;

Function JAMAPI.CreateMB: Boolean;
Begin CreateMB := False; End;

Function JAMAPI.LockMB(Lock: Boolean): Boolean;
Begin LockMB := True; End;

Procedure JAMAPI.UnlockMB(Keep: Boolean);
Begin HaveLock := False; End;

Function JAMAPI.FetchMsgHdr(MsgNum: Longint; Lock: Boolean): Boolean;
Begin FetchMsgHdr := False; End;

Function JAMAPI.FetchMsgIdx(Var MsgNum: Longint): Boolean;
Begin FetchMsgIdx := False; End;

Function JAMAPI.StoreMsgHdr(MsgNum: Longint): Boolean;
Begin StoreMsgHdr := False; End;

Function JAMAPI.StoreMsgIdx(MsgNum: Longint): Boolean;
Begin StoreMsgIdx := False; End;

Function JAMAPI.FindField(ID: Word; Var Pos: Longint;
  Var Len: Word): Boolean;
Begin FindField := False; End;

Procedure JAMAPI.AddField(FieldType: Word; WriteHdr: Boolean;
  Len: Word; Var Pos: Longint; Var Buf);
Begin End;

Function JAMAPI.ReadFile(Handle: Integer;
  Var Buf; Count: Word): Longint;
Var Regs: Registers;
Begin
  Regs.AH := $3F; Regs.BX := Handle; Regs.CX := Count;
  Regs.DS := Seg(Buf); Regs.DX := Ofs(Buf);
  Intr($21, Regs);
  If Regs.Flags And FCarry <> 0 Then ReadFile := 0
  Else ReadFile := Regs.AX;
End;

Function JAMAPI.WriteFile(Handle: Integer;
  Var Buf; Count: Word): Longint;
Var Regs: Registers;
Begin
  Regs.AH := $40; Regs.BX := Handle; Regs.CX := Count;
  Regs.DS := Seg(Buf); Regs.DX := Ofs(Buf);
  Intr($21, Regs);
  If Regs.Flags And FCarry <> 0 Then WriteFile := 0
  Else WriteFile := Regs.AX;
End;

Procedure JAMAPI.LowCaseBuf(Var Buf; Len: Word);
Type BA = Array[0..65534] Of Byte;
Var i: Word;
Begin
  For i := 0 To Len-1 Do
    If BA(Buf)[i] In [65..90] Then Inc(BA(Buf)[i], 32);
End;

Function JAMAPI.SeekFile(Handle: Integer;
  Origin: Integer; Offset: Longint): Longint;
Var Regs: Registers;
Begin
  Regs.AH := $42; Regs.AL := Lo(Origin);
  Regs.BX := Handle;
  Regs.CX := Word(Offset Shr 16);
  Regs.DX := Word(Offset);
  Intr($21, Regs);
  If Regs.Flags And FCarry <> 0 Then SeekFile := 0
  Else SeekFile := Longint(Regs.DX) Shl 16 + Regs.AX;
End;

End.
