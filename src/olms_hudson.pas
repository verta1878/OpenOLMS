{
  OpenOLMS - Hudson message-base reader
  SPDX-License-Identifier: GPL-3.0-or-later

  Copyright (C) 2026  Antonio Rico - Ecstasy BBS / Reapern66

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

  Built in Free Pascal from published format specifications.
}
unit olms_hudson;
{ ===========================================================================
  OpenOLMS — Hudson message base reader (Phase 7).

  The other base format OLMS supports. Hudson (QuickBBS/RemoteAccess) is a set
  of fixed-record binary files sharing one message store across all areas:
    MSGHDR.BBS  - array of message headers (fixed 190-byte records)
    MSGTXT.BBS  - message text, in 256-byte blocks; header points to start block
    MSGTOIDX.BBS/ MSGIDX.BBS - indexes (area/number) — optional for a full scan
  We read MSGHDR + MSGTXT, which is enough to gather messages by area.

  Implements the SAME IMsgBase seam as the JAM reader, so the door treats them
  identically. Structures from the public Hudson/QuickBBS format docs.

  Hudson MsgHdr record (190 bytes, packed):
    MsgNum      : Word          (+0)
    ReplyTo     : Word          (+2)
    SeeAlso1st  : Word          (+4)
    TimesRead   : Word          (+6)
    StartBlock  : Word          (+8)   first 256-byte block in MSGTXT.BBS
    NumBlocks   : Word          (+10)  blocks of text
    DestNet/Node/... (net fields)      (+12..+19)
    Attribute   : Byte          (+20)
    NetAttribute: Byte          (+21)
    Board       : Byte          (+22)  area number (1..200)
    PostTime    : array[0..4] Char (+23)  "HH:MM"
    PostDate    : array[0..7] Char (+28)  "MM-DD-YY"
    ToName      : String[35]    (+36)  (len byte + 35)
    FromName    : String[35]    (+72)
    Subject     : String[71]    (+108)
    = 180 bytes used; record padded to 190.
  Text in MSGTXT.BBS uses CR (#13) as newline; block 0 is unused (1-based).
  =========================================================================== }

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, Classes, olms_types, olms_msgbase;

type
  THudsonReader = class(TInterfacedObject, IMsgBase)
  private
    FHdr : TFileStream;   // MSGHDR.BBS
    FTxt : TFileStream;   // MSGTXT.BBS
    FCount : Integer;
    FArea  : Byte;        // 0 = all areas; else filter to this board
  public
    destructor Destroy; override;
    function OpenBase(const Dir: string; Area: Byte): Boolean;   // Hudson-specific
    // IMsgBase
    function Open(const BasePath: string): Boolean;   // BasePath = directory
    procedure Close;
    function MessageCount: Integer;
    function BaseMsgNum: LongInt;
    function ReadMessage(Index: Integer; M: TOlmsMessage): Boolean;
    function FormatName: string;
  end;

implementation

const
  HUDSON_HDR_SIZE = 190;
  HUDSON_BLOCK    = 256;

type
  { Packed layout for the fields we read (matching offsets above). }
  THudsonHdr = packed record
    MsgNum, ReplyTo, SeeAlso, TimesRead, StartBlock, NumBlocks : Word;  // +0..+11
    NetStuff : array[0..7] of Byte;                                     // +12..+19
    Attribute, NetAttribute, Board : Byte;                             // +20..+22
    PostTime : array[0..4] of Char;                                    // +23..+27
    PostDate : array[0..7] of Char;                                    // +28..+35
    ToLen    : Byte; ToName   : array[0..34] of Char;                  // +36..+71
    FromLen  : Byte; FromName : array[0..34] of Char;                  // +72..+107
    SubjLen  : Byte; Subject  : array[0..70] of Char;                  // +108..+179
    Pad      : array[0..9] of Byte;                                    // +180..+189
  end;

function PStr(len: Byte; const arr: array of Char): string;
var i, n: Integer;
begin
  Result := '';
  n := len; if n > Length(arr) then n := Length(arr);
  for i := 0 to n-1 do Result := Result + arr[i];
end;

destructor THudsonReader.Destroy; begin Close; inherited Destroy; end;

function THudsonReader.OpenBase(const Dir: string; Area: Byte): Boolean;
var base: string;
begin
  Result := False;
  Close;
  base := IncludeTrailingPathDelimiter(Dir);
  if not FileExists(base + 'MSGHDR.BBS') then Exit;
  if not FileExists(base + 'MSGTXT.BBS') then Exit;
  FHdr := TFileStream.Create(base + 'MSGHDR.BBS', fmOpenRead or fmShareDenyNone);
  FTxt := TFileStream.Create(base + 'MSGTXT.BBS', fmOpenRead or fmShareDenyNone);
  FCount := FHdr.Size div HUDSON_HDR_SIZE;
  FArea  := Area;
  Result := True;
end;

function THudsonReader.Open(const BasePath: string): Boolean;
begin
  // IMsgBase entry: BasePath is the directory; default to all areas.
  Result := OpenBase(BasePath, 0);
end;

procedure THudsonReader.Close;
begin
  if Assigned(FHdr) then FreeAndNil(FHdr);
  if Assigned(FTxt) then FreeAndNil(FTxt);
  FCount := 0;
end;

function THudsonReader.MessageCount: Integer; begin Result := FCount; end;
function THudsonReader.BaseMsgNum: LongInt;   begin Result := 1; end;
function THudsonReader.FormatName: string;    begin Result := 'Hudson'; end;

function THudsonReader.ReadMessage(Index: Integer; M: TOlmsMessage): Boolean;
var
  h : THudsonHdr;
  txt : AnsiString;
  toRead, got : Integer;
  blkPos : Int64;
begin
  Result := False;
  if (Index < 0) or (Index >= FCount) then Exit;
  FHdr.Position := Int64(Index) * HUDSON_HDR_SIZE;
  FHdr.ReadBuffer(h, HUDSON_HDR_SIZE);

  if (FArea <> 0) and (h.Board <> FArea) then Exit;   // area filter

  M.MsgNum    := h.MsgNum;
  M.RefNum    := h.ReplyTo;
  M.ConfNum   := h.Board;
  M.Recipient := PStr(h.ToLen,   h.ToName);
  M.Sender    := PStr(h.FromLen, h.FromName);
  M.Subject   := PStr(h.SubjLen, h.Subject);
  M.DateTime  := Now;   // Hudson stores text date/time; parse later if needed

  // text: NumBlocks * 256 starting at (StartBlock-1)*256 (block 1-based)
  if (h.NumBlocks > 0) and (h.StartBlock > 0) then
  begin
    toRead := h.NumBlocks * HUDSON_BLOCK;
    blkPos := Int64(h.StartBlock - 1) * HUDSON_BLOCK;
    if blkPos + toRead <= FTxt.Size then
    begin
      SetLength(txt, toRead);
      FTxt.Position := blkPos;
      got := FTxt.Read(txt[1], toRead);
      SetLength(txt, got);
      // Hudson uses CR as line sep; first line is often a duplicate header - keep as-is
      txt := StringReplace(txt, #13, #10, [rfReplaceAll]);
      M.Body := TrimRight(txt);
    end else M.Body := '';
  end else M.Body := '';

  Result := True;
end;

end.
