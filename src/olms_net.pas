{
  OpenOLMS - networking and gateway
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
unit olms_net;
{ ===========================================================================
  OpenOLMS — networking & gateway (Phase 15).

  Handles mail bound to/from external networks, per OLMS.DOC (QWK networking,
  point networking, internet gateway, netmail options):

  * QWK networking : messages tagged for another QWK system are bundled with a
    network tag so the upstream hub routes them.
  * Point networking : the caller is a "point" of a FidoNet-style node; replies
    carry point-address kludges.
  * Internet/UUCP gateway : re-address between BBS "user name" style and internet
    "user@host" style, using the configured gateway target. Adds/strips the
    gateway kludges so a message can cross the boundary.

  Kept transport-light: it rewrites addresses and adds kludge lines on the
  message model; actual packet transport is the archiver/upload path already
  built.
  =========================================================================== }

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, olms_types;

type
  TNetKind = (nkLocal, nkQwkNet, nkPoint, nkInternet);

  TNetConfig = record
    Kind        : TNetKind;
    GatewayAddr : string;   // e.g. 'gateway@ecstasy.org' or a QWKnet BBSID
    PointAddr   : string;   // e.g. '1:2401/305.7'
    Origin      : string;   // origin line text
  end;

  TNetGateway = class
  private
    FCfg : TNetConfig;
  public
    constructor Create(const Cfg: TNetConfig);
    { True if the recipient looks like an internet address (user@host). }
    class function IsInternetAddr(const S: string): Boolean;
    { Outbound: prepare a locally-written message to cross the gateway. Adds the
      appropriate kludge/origin so the upstream routes it. }
    procedure PrepareOutbound(M: TOlmsMessage);
    { Inbound: normalize a message arriving from the gateway into local form
      (strip kludges, set a display recipient). }
    procedure NormalizeInbound(M: TOlmsMessage);
    { Compose the origin/tearline block appended to outbound net mail. }
    function OriginBlock: string;
  end;

implementation

constructor TNetGateway.Create(const Cfg: TNetConfig);
begin inherited Create; FCfg := Cfg; end;

class function TNetGateway.IsInternetAddr(const S: string): Boolean;
var at, dot: Integer;
begin
  at := Pos('@', S);
  dot := Pos('.', S);
  Result := (at > 1) and (dot > at + 1);
end;

function TNetGateway.OriginBlock: string;
begin
  Result := '';
  case FCfg.Kind of
    nkQwkNet   : Result := #10'--- OpenOLMS QWKnet'#10' * Origin: ' + FCfg.Origin;
    nkPoint    : Result := #10'--- OpenOLMS'#10' * Origin: ' + FCfg.Origin +
                           ' (' + FCfg.PointAddr + ')';
    nkInternet : Result := #10'--- OpenOLMS internet gateway'#10;
  else Result := '';
  end;
end;

procedure TNetGateway.PrepareOutbound(M: TOlmsMessage);
begin
  case FCfg.Kind of
    nkInternet:
      begin
        // if recipient is an internet address, add the gateway routing kludge
        if IsInternetAddr(M.Recipient) then
        begin
          // ^A kludges are conventionally CTRL-A (#1) prefixed; use a visible
          // TO: line the gateway understands, plus keep the address.
          M.Body := #1'INTL ' + FCfg.GatewayAddr + #10 +
                    'To: ' + M.Recipient + #10 + M.Body;
          M.Recipient := 'UUCP';   // route to the gateway agent
        end;
      end;
    nkPoint:
      M.Body := #1'FMPT ' + FCfg.PointAddr + #10 + M.Body;
    nkQwkNet:
      M.Body := M.Body;  // hub routes by conference tag; no per-msg kludge
  end;
  if OriginBlock <> '' then M.Body := M.Body + OriginBlock;
end;

procedure TNetGateway.NormalizeInbound(M: TOlmsMessage);
var p, e: Integer; line: string;
begin
  // pull a leading "To: user@host" the gateway inserted back into Recipient
  if Copy(M.Body, 1, 3) = 'To:' then
  begin
    e := Pos(#10, M.Body);
    if e > 0 then
    begin
      line := Trim(Copy(M.Body, 4, e-4));
      if IsInternetAddr(line) then M.Recipient := line;
      Delete(M.Body, 1, e);
    end;
  end;
  // strip CTRL-A kludge lines
  while (Length(M.Body) > 0) and (M.Body[1] = #1) do
  begin
    p := Pos(#10, M.Body);
    if p = 0 then Break;
    Delete(M.Body, 1, p);
  end;
end;

end.
