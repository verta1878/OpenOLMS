{
  OpenOLMS - core data model
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
unit olms_types;
{ ===========================================================================
  OpenOLMS — core data model.

  Format-neutral in-memory representation of a mail scan: conferences and
  messages the door has gathered for a user. The packet writers (QWK now;
  QWKE / Blue Wave later) consume this via IPacketWriter, so door logic never
  hard-codes a packet format.

  Clean-room: modelled from the OLMS manual's concepts and the open packet
  specs, not from the original binary.
  =========================================================================== }

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, Classes;

type
  { One message gathered for the packet. }
  TOlmsMessage = class
    MsgNum   : LongInt;      // message number in its conference
    RefNum   : LongInt;      // reference (reply-to) number, 0 = none
    ConfNum  : Word;         // conference this belongs to
    DateTime : TDateTime;    // when written
    Sender   : string;       // From
    Recipient: string;       // To
    Subject  : string;
    Body     : string;       // message text (LF-separated lines)
    Private_ : Boolean;      // private flag
  end;

  { A conference (message area) the user is joined to. }
  TOlmsConference = class
    Number : Word;
    Name   : string;         // <= 13 chars used by QWK CONTROL.DAT
    Msgs   : TList;          // of TOlmsMessage
    constructor Create;
    destructor Destroy; override;
    procedure AddMessage(M: TOlmsMessage);
    function  Count: Integer;
    function  Msg(Idx: Integer): TOlmsMessage;
  end;

  { Identifying info about the BBS producing the packet (for CONTROL.DAT). }
  TOlmsBbsInfo = record
    BBSName   : string;
    City      : string;      // "City, State"
    Phone     : string;
    SysopName : string;
    BBSID     : string;      // packet id / QWK filename base (<= 8 chars)
    UserName  : string;      // the caller
    Serial    : string;      // door serial line (informational)
  end;

  { The whole scan: BBS info + a set of conferences. }
  TOlmsPacket = class
    Info  : TOlmsBbsInfo;
    Confs : TList;           // of TOlmsConference
    constructor Create;
    destructor Destroy; override;
    function  AddConference(ANum: Word; const AName: string): TOlmsConference;
    function  Count: Integer;
    function  Conf(Idx: Integer): TOlmsConference;
    function  TotalMessages: Integer;
  end;

  { The packet-writer seam. QWK, QWKE, Blue Wave each implement this. }
  IPacketWriter = interface
    ['{0A17C0DE-0001-4000-9000-000000000001}']
    // Write the packet's files into OutputDir. Returns True on success.
    function WritePacket(P: TOlmsPacket; const OutputDir: string): Boolean;
    function FormatName: string;
  end;

implementation

{ TOlmsConference }
constructor TOlmsConference.Create;
begin inherited Create; Msgs := TList.Create; end;

destructor TOlmsConference.Destroy;
var i: Integer;
begin
  for i := 0 to Msgs.Count-1 do TOlmsMessage(Msgs[i]).Free;
  Msgs.Free;
  inherited Destroy;
end;

procedure TOlmsConference.AddMessage(M: TOlmsMessage); begin Msgs.Add(M); end;
function TOlmsConference.Count: Integer; begin Result := Msgs.Count; end;
function TOlmsConference.Msg(Idx: Integer): TOlmsMessage; begin Result := TOlmsMessage(Msgs[Idx]); end;

{ TOlmsPacket }
constructor TOlmsPacket.Create;
begin inherited Create; Confs := TList.Create; end;

destructor TOlmsPacket.Destroy;
var i: Integer;
begin
  for i := 0 to Confs.Count-1 do TOlmsConference(Confs[i]).Free;
  Confs.Free;
  inherited Destroy;
end;

function TOlmsPacket.AddConference(ANum: Word; const AName: string): TOlmsConference;
begin
  Result := TOlmsConference.Create;
  Result.Number := ANum; Result.Name := AName;
  Confs.Add(Result);
end;

function TOlmsPacket.Count: Integer; begin Result := Confs.Count; end;
function TOlmsPacket.Conf(Idx: Integer): TOlmsConference; begin Result := TOlmsConference(Confs[Idx]); end;

function TOlmsPacket.TotalMessages: Integer;
var i: Integer;
begin
  Result := 0;
  for i := 0 to Confs.Count-1 do Inc(Result, TOlmsConference(Confs[i]).Count);
end;

end.
