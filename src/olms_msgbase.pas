{
  OpenOLMS - message-base seam + JAM reader
  SPDX-License-Identifier: GPL-3.0-or-later

  Copyright (C) 2026  Antonio Rico / Ecstasy BBS (github.com/verta1878)

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.

  OpenOLMS is a clean-room reimplementation of the OLMS offline-mail door,
  written from published format specifications and documentation. It contains
  no code from the original OLMS.
}
unit olms_msgbase;
{ ===========================================================================
  OpenOLMS — message-base input (the critical gap).

  IMsgBase is the reader seam (mirrors IPacketWriter on the output side). A door
  scan asks an IMsgBase for messages in an area; concrete readers (JAM now,
  Hudson next) implement it. olms.exe never hard-codes a base format.

  JAM ("Joaquim's Advanced Message base") is an OPEN, published format
  (Homrighausen/Adams/Lentz/Wittel, 1993). We implement it from that public
  spec. Files per base "area": <base>.JHR (header+fixed), .JDT (text),
  .JDX (index), .JLR (lastread). We read .JHR + .JDT (enough to gather mail).

  JAM structures (little-endian on disk):
    FixedHeaderInfoStruct (.JHR, offset 0):
      Signature  : 4 bytes 'JAM' + #0
      datecreated: u32   modcounter: u32   activemsgs: u32
      passwordCRC: u32   basemsgnum : u32   (first msg number)
      RESERVED   : 1000 bytes
    MessageHeader (.JHR, per message):
      Signature 'JAM'#0 (4) · Revision u16 · ReservedWord u16
      SubfieldLen u32 · TimesRead u32 · MSGIDcrc u32 · REPLYcrc u32
      ReplyTo u32 · Reply1st u32 · ReplyNext u32 · DateWritten u32
      DateReceived u32 · DateProcessed u32 · MessageNumber u32
      Attribute u32 · Attribute2 u32 · Offset u32 (into .JDT)
      TxtLen u32 · PasswordCRC u32 · Cost u32
      then <SubfieldLen> bytes of subfields (To/From/Subject/etc.)
    Subfield: LoID u16 · HiID u16 · DatLen u32 · Data[DatLen]
      IDs: 2=SenderName 3=RecvName 6=Subject
  =========================================================================== }

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, Classes, DateUtils, olms_types;

type
  { Reader seam. Hudson/JAM/... implement this; the door talks only to it. }
  IMsgBase = interface
    ['{0A17C0DE-0002-4000-9000-000000000002}']
    function Open(const BasePath: string): Boolean;   // path without extension
    procedure Close;
    function MessageCount: Integer;
    function BaseMsgNum: LongInt;
    // Read message at 0-based index into M (caller owns M). True if present/active.
    function ReadMessage(Index: Integer; M: TOlmsMessage): Boolean;
    function FormatName: string;
  end;

  TJamReader = class(TInterfacedObject, IMsgBase)
  private
    FHdr : TFileStream;   // .JHR
    FTxt : TFileStream;   // .JDT
    FActiveMsgs : LongWord;
    FBaseMsgNum : LongWord;
    FHdrOffsets : array of Int64;   // file offset of each MessageHeader
    procedure IndexHeaders;
  public
    destructor Destroy; override;
    function Open(const BasePath: string): Boolean;
    procedure Close;
    function MessageCount: Integer;
    function BaseMsgNum: LongInt;
    function ReadMessage(Index: Integer; M: TOlmsMessage): Boolean;
    function FormatName: string;
  end;

implementation

const
  JAM_SIG = 'JAM'#0;
  FIXEDHDR_SIZE = 1024;   // 24 bytes fields + 1000 reserved
  // JAM Attribute bits we care about
  JAM_MSG_DELETED = $80000000;
  // subfield IDs
  SF_SENDER  = 2;
  SF_RECV    = 3;
  SF_SUBJECT = 6;

function ReadU16(fs: TFileStream): Word;
begin fs.ReadBuffer(Result, 2); end;
function ReadU32(fs: TFileStream): LongWord;
begin fs.ReadBuffer(Result, 4); end;

destructor TJamReader.Destroy;
begin Close; inherited Destroy; end;

function TJamReader.Open(const BasePath: string): Boolean;
var sig: array[0..3] of Char;
begin
  Result := False;
  Close;
  if not FileExists(BasePath + '.JHR') then Exit;
  if not FileExists(BasePath + '.JDT') then Exit;
  FHdr := TFileStream.Create(BasePath + '.JHR', fmOpenRead or fmShareDenyNone);
  FTxt := TFileStream.Create(BasePath + '.JDT', fmOpenRead or fmShareDenyNone);
  // FixedHeaderInfoStruct
  FHdr.Position := 0;
  FHdr.ReadBuffer(sig, 4);
  if (sig[0]<>'J') or (sig[1]<>'A') or (sig[2]<>'M') then Exit;
  ReadU32(FHdr);                 // datecreated
  ReadU32(FHdr);                 // modcounter
  FActiveMsgs := ReadU32(FHdr);  // activemsgs
  ReadU32(FHdr);                 // passwordCRC
  FBaseMsgNum := ReadU32(FHdr);  // basemsgnum
  // (skip rest of reserved to FIXEDHDR_SIZE)
  IndexHeaders;
  Result := True;
end;

{ Walk the .JHR from the fixed header onward, recording each MessageHeader's
  offset. Each header is 76 bytes of fixed fields + SubfieldLen bytes. }
procedure TJamReader.IndexHeaders;
var
  pos, fileEnd: Int64;
  sig: array[0..3] of Char;
  subLen: LongWord;
begin
  SetLength(FHdrOffsets, 0);
  fileEnd := FHdr.Size;
  pos := FIXEDHDR_SIZE;
  while pos + 76 <= fileEnd do
  begin
    FHdr.Position := pos;
    FHdr.ReadBuffer(sig, 4);
    if (sig[0]<>'J') or (sig[1]<>'A') or (sig[2]<>'M') then Break;
    // fixed MessageHeader is 76 bytes; SubfieldLen is at offset +8 from sig
    FHdr.Position := pos + 8;
    subLen := ReadU32(FHdr);
    SetLength(FHdrOffsets, Length(FHdrOffsets)+1);
    FHdrOffsets[High(FHdrOffsets)] := pos;
    pos := pos + 76 + subLen;
  end;
end;

procedure TJamReader.Close;
begin
  if Assigned(FHdr) then FreeAndNil(FHdr);
  if Assigned(FTxt) then FreeAndNil(FTxt);
  SetLength(FHdrOffsets, 0);
  FActiveMsgs := 0; FBaseMsgNum := 0;
end;

function TJamReader.MessageCount: Integer; begin Result := Length(FHdrOffsets); end;
function TJamReader.BaseMsgNum: LongInt;   begin Result := FBaseMsgNum; end;
function TJamReader.FormatName: string;    begin Result := 'JAM'; end;

function TJamReader.ReadMessage(Index: Integer; M: TOlmsMessage): Boolean;
var
  base: Int64;
  attr, txtOffset, txtLen, msgNum, replyTo, dateW, subLen: LongWord;
  sfEnd: Int64;
  loID, hiID: Word;
  datLen: LongWord;
  buf: array of Byte;
  s: string;
  txt: AnsiString;
begin
  Result := False;
  if (Index < 0) or (Index >= Length(FHdrOffsets)) then Exit;
  base := FHdrOffsets[Index];

  // MessageHeader fixed fields (canonical JAM offsets from sig at 'base')
  FHdr.Position := base + 8;   subLen    := ReadU32(FHdr);   // +8  SubfieldLen
  FHdr.Position := base + 24;  replyTo   := ReadU32(FHdr);   // +24 ReplyTo
  FHdr.Position := base + 36;  dateW     := ReadU32(FHdr);   // +36 DateWritten
  FHdr.Position := base + 48;  msgNum    := ReadU32(FHdr);   // +48 MessageNumber
  FHdr.Position := base + 52;  attr      := ReadU32(FHdr);   // +52 Attribute
  FHdr.Position := base + 60;  txtOffset := ReadU32(FHdr);   // +60 Offset into .JDT
  FHdr.Position := base + 64;  txtLen    := ReadU32(FHdr);   // +64 TxtLen

  if (attr and JAM_MSG_DELETED) <> 0 then Exit;   // skip deleted

  M.MsgNum   := msgNum;
  M.RefNum   := replyTo;
  M.DateTime := UnixToDateTime(dateW);   // JAM dates are unix timestamps
  M.Sender := ''; M.Recipient := ''; M.Subject := '';

  // Subfields
  FHdr.Position := base + 76;
  sfEnd := base + 76 + subLen;
  while FHdr.Position + 8 <= sfEnd do
  begin
    loID := ReadU16(FHdr); hiID := ReadU16(FHdr); datLen := ReadU32(FHdr);
    if datLen > 0 then
    begin
      SetLength(buf, datLen);
      FHdr.ReadBuffer(buf[0], datLen);
      SetString(s, PAnsiChar(@buf[0]), datLen);
    end else s := '';
    case loID of
      SF_SENDER : M.Sender    := s;
      SF_RECV   : M.Recipient := s;
      SF_SUBJECT: M.Subject   := s;
    end;
  end;

  // Message text from .JDT
  if (txtLen > 0) and (txtOffset + txtLen <= FTxt.Size) then
  begin
    SetLength(buf, txtLen);
    FTxt.Position := txtOffset;
    FTxt.ReadBuffer(buf[0], txtLen);
    SetString(txt, PAnsiChar(@buf[0]), txtLen);
    // JAM text uses CR (#13) as line sep; normalize to LF for our model
    txt := StringReplace(txt, #13#10, #10, [rfReplaceAll]);
    txt := StringReplace(txt, #13, #10, [rfReplaceAll]);
    M.Body := txt;
  end else M.Body := '';

  Result := True;
end;

end.
