{ ===========================================================================
  OpenOLMS -- Open Offline Mail System
  GPLv3 -- Copyright (C) 2026 verta1878, sysop/0, wrench, kiddo, evga.
  Clean-room re{ Write a new message to JAM message base }



implementation. No original source code used.
  =========================================================================== }

unit OL_JAM;
{ ===========================================================================
  OpenOLMS -- JAM message base reader
  ---------------------------------------------------------------------------
  JAM (Joaquim-Andrew-Mats) message base format, 1993. Used by many
  FidoNet-capable BBS packages. Four files per area:

    .JHR  -- fixed-size header records (TJAMHeader)
    .JDT  -- message body text (variable-length, offset from header)
    .JDX  -- index records (CRC32 of recipient + offset into .JHR)
    .JLR  -- last-read pointers per user

  Each header is 76 bytes. The body is stored at a byte offset in
  .JDT with a length from the header. Subfields follow the header
  in .JHR -- variable-length tagged data (from, to, subject, msgid,
  reply, origin, etc).

  Reference: JAM specification by Joaquim Homrighausen,
  Andrew Milner, Mats Birch, Mats Wallin -- 1993.
  =========================================================================== }

{$MODE OBJFPC}{$H+}

interface

const
  JAM_SIGNATURE = 'JAM'#0;
  JAM_HDR_SIZE  = 76;

  { JAM attribute bits }
  JAM_LOCAL    = $00000001;
  JAM_INTRANS  = $00000002;
  JAM_PRIVATE  = $00000004;
  JAM_READ     = $00000008;
  JAM_SENT     = $00000010;
  JAM_KILLSENT = $00000020;
  JAM_HOLD     = $00000080;
  JAM_DELETED  = $80000000;

  { JAM subfield types }
  JAMSFLD_OADDRESS    = 0;
  JAMSFLD_DADDRESS    = 1;
  JAMSFLD_SENDERNAME  = 2;
  JAMSFLD_RECVRNAME   = 3;
  JAMSFLD_MSGID       = 4;
  JAMSFLD_REPLYID     = 5;
  JAMSFLD_SUBJECT     = 6;
  JAMSFLD_PID         = 7;
  JAMSFLD_TRACE       = 8;
  JAMSFLD_ENCLFILE    = 9;
  JAMSFLD_ENCLFREQ    = 10;
  JAMSFLD_ENCLOSEDFILE= 11;
  JAMSFLD_ENCLOSEDFRE = 12;
  JAMSFLD_FTSKLUDGE   = 2000;

type
  { JAM fixed header -- 76 bytes }
  TJAMHeader = packed record
    Signature   : array[0..3] of Char;   {  4 -- 'JAM\0' }
    Revision    : Word;                   {  2 -- spec revision }
    ReservedWord: Word;                   {  2 }
    SubfieldLen : LongInt;                {  4 -- total bytes of subfields }
    TimesRead   : LongInt;                {  4 }
    MSGIDcrc    : LongInt;                {  4 -- CRC-32 of MSGID }
    REPLYcrc    : LongInt;                {  4 -- CRC-32 of REPLY }
    ReplyTo     : LongInt;                {  4 -- msg number of parent }
    Reply1st    : LongInt;                {  4 -- first reply }
    ReplyNext   : LongInt;                {  4 -- next reply in chain }
    DateWritten : LongInt;                {  4 -- Unix timestamp }
    DateReceived: LongInt;                {  4 }
    DateProcessed: LongInt;               {  4 }
    MsgNum      : LongInt;                {  4 }
    Attr        : LongInt;                {  4 -- attribute bits }
    Attr2       : LongInt;                {  4 }
    TxtOffset   : LongInt;                {  4 -- offset into .JDT }
    TxtLen      : LongInt;                {  4 -- length in .JDT }
    PasswordCRC : LongInt;                {  4 }
    Cost        : LongInt;                {  4 }
  end;                                    { = 76 bytes }

  { JAM subfield header -- variable length }
  TJAMSubfield = packed record
    LoID    : Word;       { subfield type }
    HiID    : Word;       { unused (0) }
    DataLen : LongInt;    { length of data following this header }
  end;

  { JAM index record }
  TJAMIndex = packed record
    UserCRC : LongInt;    { CRC-32 of lowercase recipient name }
    HdrOfs  : LongInt;    { byte offset into .JHR }
  end;

  { JAM last-read record }
  TJAMLast = packed record
    UserCRC  : LongInt;   { CRC-32 of lowercase user name }
    UserID   : LongInt;   { user number (BBS-specific) }
    LastRead : LongInt;   { last message number read }
    HighRead : LongInt;   { highest message number read }
  end;

  { Parsed JAM message for OpenOLMS use }
  TJAMMessage = record
    MsgNum    : LongInt;
    MsgTo     : String;
    MsgFrom   : String;
    Subject   : String;
    DateStr   : String;
    Body      : String;
    IsPrivate : Boolean;
    IsDeleted : Boolean;
    ReplyTo   : LongInt;
    Attr      : LongInt;
  end;

{ Read messages from a JAM area.
  BaseName is the path+name without extension (e.g. 'C:\MSG\GENERAL').
  Returns count of messages read into the Messages array. }
function JAMReadArea(const BaseName: String;
  StartMsg: LongInt; MaxMsgs: Integer;
  var Messages: array of TJAMMessage): Integer;

{ Read a single message by number }
function JAMReadMessage(const BaseName: String; MsgNum: LongInt;
  var Msg: TJAMMessage): Boolean;

{ Get the last-read pointer for a user }
function JAMGetLastRead(const BaseName: String;
  const UserName: String): LongInt;

{ Set the last-read pointer for a user }
procedure JAMSetLastRead(const BaseName: String;
  const UserName: String; LastRead: LongInt);

{ CRC-32 of a lowercase string (used for user matching in JAM) }
function JAMCRC32(const S: String): LongInt;
function JAMWriteMessage(const BaseName: String;
  const MsgTo, MsgFrom, Subject, Body: String;
  Attr: LongInt): Boolean;



implementation

uses SysUtils;

function JAMUnixToDateTime(UnixTime: LongInt): TDateTime;
const UNIX_EPOCH: TDateTime = 25569.0;
begin Result := UNIX_EPOCH + (UnixTime / 86400.0); end;

const
  CRC32_POLY = LongInt($EDB88320);

var
  CRC32_TABLE: array[0..255] of LongInt;
  CRC32_INIT: Boolean = False;

procedure InitCRC32Table;
var I, J: Integer; CRC: LongInt;
begin
  for I := 0 to 255 do
  begin
    CRC := I;
    for J := 0 to 7 do
      if (CRC and 1) <> 0 then CRC := (CRC shr 1) xor CRC32_POLY
      else CRC := CRC shr 1;
    CRC32_TABLE[I] := CRC;
  end;
  CRC32_INIT := True;
end;


function JAMCRC32(const S: String): LongInt;
var
  I: Integer;
  CRC: LongInt;
  C: Byte;
begin
  if not CRC32_INIT then InitCRC32Table;
  CRC := LongInt($FFFFFFFF);
  for I := 1 to Length(S) do
  begin
    C := Ord(LowerCase(S[I]));
    CRC := CRC32_TABLE[Byte(CRC) xor C] xor (CRC shr 8);
  end;
  Result := CRC xor LongInt($FFFFFFFF);
end;

function JAMReadMessage(const BaseName: String; MsgNum: LongInt;
  var Msg: TJAMMessage): Boolean;
var
  FHdr, FDat: File;
  Hdr: TJAMHeader;
  Sub: TJAMSubfield;
  SubData: String;
  BytesRead: LongInt;
  SubBytesLeft: LongInt;
  Buf: array[0..4095] of Byte;
begin
  Result := False;

  { Open .JHR }
  AssignFile(FHdr, BaseName + '.JHR');
  {$I-} Reset(FHdr, 1); {$I+}
  if IOResult <> 0 then Exit;

  try
    { Scan for the message number }
    while not EOF(FHdr) do
    begin
      FillChar(Hdr, SizeOf(Hdr), 0);
      BlockRead(FHdr, Hdr, JAM_HDR_SIZE, BytesRead);
      if BytesRead <> JAM_HDR_SIZE then Break;

      { Read subfields even if not our message (to advance file pos) }
      SubBytesLeft := Hdr.SubfieldLen;
      Msg.MsgFrom := '';
      Msg.MsgTo := '';
      Msg.Subject := '';

      while SubBytesLeft > SizeOf(TJAMSubfield) do
      begin
        BlockRead(FHdr, Sub, SizeOf(TJAMSubfield), BytesRead);
        if BytesRead <> SizeOf(TJAMSubfield) then Break;
        Dec(SubBytesLeft, SizeOf(TJAMSubfield));

        if Sub.DataLen > 0 then
        begin
          if Sub.DataLen > 4096 then
          begin
            Seek(FHdr, FilePos(FHdr) + Sub.DataLen);
            Dec(SubBytesLeft, Sub.DataLen);
            Continue;
          end;
          FillChar(Buf, SizeOf(Buf), 0);
          BlockRead(FHdr, Buf, Sub.DataLen);
          Dec(SubBytesLeft, Sub.DataLen);
          SetLength(SubData, Sub.DataLen);
          Move(Buf[0], SubData[1], Sub.DataLen);
        end else
          SubData := '';

        if Hdr.MsgNum = MsgNum then
        begin
          case Sub.LoID of
            JAMSFLD_SENDERNAME: Msg.MsgFrom := SubData;
            JAMSFLD_RECVRNAME: Msg.MsgTo := SubData;
            JAMSFLD_SUBJECT:   Msg.Subject := SubData;
          end;
        end;
      end;

      if Hdr.MsgNum = MsgNum then
      begin
        Msg.MsgNum    := Hdr.MsgNum;
        Msg.IsPrivate := (Hdr.Attr and JAM_PRIVATE) <> 0;
        Msg.IsDeleted := (Hdr.Attr and JAM_DELETED) <> 0;
        Msg.ReplyTo   := Hdr.ReplyTo;
        Msg.Attr      := Hdr.Attr;
        Msg.DateStr   := FormatDateTime('mm-dd-yy',
          JAMUnixToDateTime(Hdr.DateWritten));

        { Read body from .JDT }
        Msg.Body := '';
        if (Hdr.TxtLen > 0) and FileExists(BaseName + '.JDT') then
        begin
          AssignFile(FDat, BaseName + '.JDT');
          {$I-} Reset(FDat, 1); {$I+}
          if IOResult = 0 then
          try
            Seek(FDat, Hdr.TxtOffset);
            SetLength(Msg.Body, Hdr.TxtLen);
            BlockRead(FDat, Msg.Body[1], Hdr.TxtLen);
          finally
            CloseFile(FDat);
          end;
        end;

        Result := True;
        Exit;
      end;
    end;
  finally
    CloseFile(FHdr);
  end;
end;

function JAMReadArea(const BaseName: String;
  StartMsg: LongInt; MaxMsgs: Integer;
  var Messages: array of TJAMMessage): Integer;
var
  FHdr: File;
  Hdr: TJAMHeader;
  BytesRead: LongInt;
  Count: Integer;
begin
  Result := 0;
  Count := 0;

  AssignFile(FHdr, BaseName + '.JHR');
  {$I-} Reset(FHdr, 1); {$I+}
  if IOResult <> 0 then Exit;

  try
    while not EOF(FHdr) do
    begin
      FillChar(Hdr, SizeOf(Hdr), 0);
      BlockRead(FHdr, Hdr, JAM_HDR_SIZE, BytesRead);
      if BytesRead <> JAM_HDR_SIZE then Break;

      { Skip subfields -- we read them fully in JAMReadMessage }
      if Hdr.SubfieldLen > 0 then
        Seek(FHdr, FilePos(FHdr) + Hdr.SubfieldLen);

      { Filter }
      if (Hdr.Attr and JAM_DELETED) <> 0 then Continue;
      if Hdr.MsgNum < StartMsg then Continue;
      if Count > High(Messages) then Break;
      if (MaxMsgs > 0) and (Count >= MaxMsgs) then Break;

      { Lightweight record -- body is read lazily during packing }
      Messages[Count].MsgNum    := Hdr.MsgNum;
      Messages[Count].IsPrivate := (Hdr.Attr and JAM_PRIVATE) <> 0;
      Messages[Count].IsDeleted := False;
      Messages[Count].ReplyTo   := Hdr.ReplyTo;
      Messages[Count].Attr      := Hdr.Attr;
      Messages[Count].DateStr   := FormatDateTime('mm-dd-yy',
        JAMUnixToDateTime(Hdr.DateWritten));
      Messages[Count].Body      := '';
      Messages[Count].MsgFrom   := '';
      Messages[Count].MsgTo     := '';
      Messages[Count].Subject   := '';

      Inc(Count);
    end;
  finally
    CloseFile(FHdr);
  end;
  Result := Count;
end;

function JAMGetLastRead(const BaseName: String;
  const UserName: String): LongInt;
var
  F: File;
  LR: TJAMLast;
  UserCRC: LongInt;
  BytesRead: LongInt;
begin
  Result := 0;
  UserCRC := JAMCRC32(UserName);

  AssignFile(F, BaseName + '.JLR');
  {$I-} Reset(F, 1); {$I+}
  if IOResult <> 0 then Exit;

  try
    while not EOF(F) do
    begin
      BlockRead(F, LR, SizeOf(LR), BytesRead);
      if BytesRead <> SizeOf(LR) then Break;
      if LR.UserCRC = UserCRC then
      begin
        Result := LR.LastRead;
        Exit;
      end;
    end;
  finally
    CloseFile(F);
  end;
end;

procedure JAMSetLastRead(const BaseName: String;
  const UserName: String; LastRead: LongInt);
var
  F: File;
  LR: TJAMLast;
  UserCRC: LongInt;
  BytesRead: LongInt;
  Found: Boolean;
begin
  UserCRC := JAMCRC32(UserName);
  Found := False;

  AssignFile(F, BaseName + '.JLR');
  {$I-} Reset(F, 1); {$I+}
  if IOResult <> 0 then
  begin
    {$I-} Rewrite(F, 1); {$I+}
    if IOResult <> 0 then Exit;
  end;

  try
    while not EOF(F) do
    begin
      BlockRead(F, LR, SizeOf(LR), BytesRead);
      if BytesRead <> SizeOf(LR) then Break;
      if LR.UserCRC = UserCRC then
      begin
        LR.LastRead := LastRead;
        if LastRead > LR.HighRead then
          LR.HighRead := LastRead;
        Seek(F, FilePos(F) - SizeOf(LR));
        BlockWrite(F, LR, SizeOf(LR));
        Found := True;
        Break;
      end;
    end;

    if not Found then
    begin
      { Append new record }
      LR.UserCRC  := UserCRC;
      LR.UserID   := 0;
      LR.LastRead := LastRead;
      LR.HighRead := LastRead;
      Seek(F, FileSize(F));
      BlockWrite(F, LR, SizeOf(LR));
    end;
  finally
    CloseFile(F);
  end;
end;

function JAMWriteMessage(const BaseName: String;
  const MsgTo, MsgFrom, Subject, Body: String;
  Attr: LongInt): Boolean;
var
  FHdr, FTxt, FIdx: File;
  UnixNow: LongInt;
  InfoHdr: array[0..1023] of Byte;
  ActiveBuf: array[0..3] of Byte;
  JHR: array[0..75] of Byte;   { JAM header fixed part = 76 bytes }
  SubField: array[0..511] of Byte;
  SubLen: Integer;
  TxtOfs, TxtLen: LongInt;
  MsgNum: LongInt;
  HdrOfs: LongInt;
  IdxRec: array[0..7] of Byte;  { JAM index = 8 bytes }
  JCRC: LongInt;
begin
  Result := False;

  { Write message text to .JDT }
  AssignFile(FTxt, BaseName + '.JDT');
  {$I-} Reset(FTxt, 1); {$I+}
  if IOResult <> 0 then Rewrite(FTxt, 1);
  Seek(FTxt, FileSize(FTxt));
  TxtOfs := FilePos(FTxt);
  TxtLen := Length(Body);
  BlockWrite(FTxt, Body[1], TxtLen);
  CloseFile(FTxt);

  { Build subfields: SENDERNAME(0), RECEIVERNAME(1), SUBJECT(2) }
  SubLen := 0;

  { Subfield header: LoID(2) + HiID(2) + DatLen(4) + Data }
  { SENDERNAME = LoID 0, HiID 0 }
  SubField[SubLen] := 0; SubField[SubLen+1] := 0;  { LoID = 0 }
  SubField[SubLen+2] := 0; SubField[SubLen+3] := 0; { HiID = 0 }
  SubField[SubLen+4] := Length(MsgFrom) and $FF;
  SubField[SubLen+5] := (Length(MsgFrom) shr 8) and $FF;
  SubField[SubLen+6] := 0; SubField[SubLen+7] := 0;
  Move(MsgFrom[1], SubField[SubLen+8], Length(MsgFrom));
  Inc(SubLen, 8 + Length(MsgFrom));

  { RECEIVERNAME = LoID 1 }
  SubField[SubLen] := 1; SubField[SubLen+1] := 0;
  SubField[SubLen+2] := 0; SubField[SubLen+3] := 0;
  SubField[SubLen+4] := Length(MsgTo) and $FF;
  SubField[SubLen+5] := (Length(MsgTo) shr 8) and $FF;
  SubField[SubLen+6] := 0; SubField[SubLen+7] := 0;
  Move(MsgTo[1], SubField[SubLen+8], Length(MsgTo));
  Inc(SubLen, 8 + Length(MsgTo));

  { SUBJECT = LoID 2 }
  SubField[SubLen] := 2; SubField[SubLen+1] := 0;
  SubField[SubLen+2] := 0; SubField[SubLen+3] := 0;
  SubField[SubLen+4] := Length(Subject) and $FF;
  SubField[SubLen+5] := (Length(Subject) shr 8) and $FF;
  SubField[SubLen+6] := 0; SubField[SubLen+7] := 0;
  Move(Subject[1], SubField[SubLen+8], Length(Subject));
  Inc(SubLen, 8 + Length(Subject));

  { Build JAM header fixed part (76 bytes)
    Offset  Size  Field
    0       4     Signature "JAM "
    4       2     Revision (1)
    6       2     ReservedWord
    8       4     SubfieldLen
    12      4     TimesRead
    16      4     MSGIDcrc
    20      4     REPLYcrc
    24      4     ReplyTo
    28      4     Reply1st
    32      4     ReplyNext
    36      4     DateWritten (Unix timestamp)
    40      4     DateReceived
    44      4     DateProcessed
    48      4     MessageNumber
    52      4     Attribute
    56      4     Attribute2
    60      4     TxtOffset
    64      4     TxtLen
    68      4     PasswordCRC
    72      4     Cost }

  FillChar(JHR, SizeOf(JHR), 0);
  JHR[0] := Ord('J'); JHR[1] := Ord('A'); JHR[2] := Ord('M'); JHR[3] := 0;
  JHR[4] := 1; JHR[5] := 0;  { Revision 1 }

  { SubfieldLen }
  JHR[8] := SubLen and $FF;
  JHR[9] := (SubLen shr 8) and $FF;

  { DateWritten = current Unix timestamp }
  { UnixNow declared at top }
  UnixNow := Round((Now - EncodeDate(1970, 1, 1)) * 86400);
  JHR[36] := UnixNow and $FF;
  JHR[37] := (UnixNow shr 8) and $FF;
  JHR[38] := (UnixNow shr 16) and $FF;
  JHR[39] := (UnixNow shr 24) and $FF;

  { Attribute }
  JHR[52] := Attr and $FF;
  JHR[53] := (Attr shr 8) and $FF;

  { TxtOffset }
  JHR[60] := TxtOfs and $FF;
  JHR[61] := (TxtOfs shr 8) and $FF;
  JHR[62] := (TxtOfs shr 16) and $FF;
  JHR[63] := (TxtOfs shr 24) and $FF;

  { TxtLen }
  JHR[64] := TxtLen and $FF;
  JHR[65] := (TxtLen shr 8) and $FF;

  { Write header + subfields to .JHR }
  AssignFile(FHdr, BaseName + '.JHR');
  {$I-} Reset(FHdr, 1); {$I+}
  if IOResult <> 0 then Rewrite(FHdr, 1);

  { Skip fixed header info (1024 bytes) if file is new }
  if FileSize(FHdr) < 1024 then
  begin
    { InfoHdr declared at top }
    FillChar(InfoHdr, 1024, 0);
    InfoHdr[0] := Ord('J'); InfoHdr[1] := Ord('A');
    InfoHdr[2] := Ord('M'); InfoHdr[3] := 0;
    BlockWrite(FHdr, InfoHdr, 1024);
  end;

  Seek(FHdr, FileSize(FHdr));
  HdrOfs := FilePos(FHdr);
  BlockWrite(FHdr, JHR, 76);
  BlockWrite(FHdr, SubField, SubLen);

  { Read MsgNum from header info block (offset 12 = ActiveMsgs) }
  Seek(FHdr, 12);
  { ActiveBuf declared at top }
  BlockRead(FHdr, ActiveBuf, 4);
  MsgNum := ActiveBuf[0] or (ActiveBuf[1] shl 8) or
            (ActiveBuf[2] shl 16) or (ActiveBuf[3] shl 24);
  Inc(MsgNum);
  ActiveBuf[0] := MsgNum and $FF;
  ActiveBuf[1] := (MsgNum shr 8) and $FF;
  ActiveBuf[2] := (MsgNum shr 16) and $FF;
  ActiveBuf[3] := (MsgNum shr 24) and $FF;
  Seek(FHdr, 12);
  BlockWrite(FHdr, ActiveBuf, 4);
  CloseFile(FHdr);

  { Write index to .JDX }
  AssignFile(FIdx, BaseName + '.JDX');
  {$I-} Reset(FIdx, 1); {$I+}
  if IOResult <> 0 then Rewrite(FIdx, 1);
  Seek(FIdx, FileSize(FIdx));

  { Index entry: UserCRC(4) + HdrOffset(4) }
  JCRC := JAMCRC32(LowerCase(MsgTo));
  IdxRec[0] := JCRC and $FF;
  IdxRec[1] := (JCRC shr 8) and $FF;
  IdxRec[2] := (JCRC shr 16) and $FF;
  IdxRec[3] := (JCRC shr 24) and $FF;
  IdxRec[4] := HdrOfs and $FF;
  IdxRec[5] := (HdrOfs shr 8) and $FF;
  IdxRec[6] := (HdrOfs shr 16) and $FF;
  IdxRec[7] := (HdrOfs shr 24) and $FF;
  BlockWrite(FIdx, IdxRec, 8);
  CloseFile(FIdx);

  Result := True;
end;

end.
