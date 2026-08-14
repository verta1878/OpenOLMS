{ ===========================================================================
  OL_Screens — SCREENS.DAT reader
  ===========================================================================
  SCREENS.DAT is a packed language file archive containing 67 ANSI/ASCII/RIP
  screen files used by OLMS for the user interface.

  File format (reversed from binary):
    Directory: 67 × 17-byte entries
      Byte  0:     TP String length (1-12)
      Bytes 1-12:  Filename (padded with zeros)
      Bytes 13-14: Word — absolute file offset of screen data
      Bytes 15-16: Word — always 0 (reserved)

    Data section: starts at offset 1139 (67 × 17)
      Raw ANSI/ASCII/RIP screen data at the offsets specified in directory.
      Each screen runs until the next screen's offset.

  Screen naming convention:
    -MAIN.ANS     Main menu (ANSI)
    -MAIN.ASC     Main menu (ASCII)
    -MAIN.RIP     Main menu (RIP)
    -ARC.ANS      Archiver selection
    -PROT.ANS     Protocol selection
    -PREF.ANS     Preferences
    -INDEX.ANS    Area index
    -LIMIT.ANS    Limits display
    -SHORT.ANS    Short name style
    -TITLE.ANS    Title screen
    -TYPE.ANS     Message type selection
    -NEWS.ANS     News bulletin
    -NEW.ANS      New files scan
    -NUMBER.ANS   Number entry
    -PERSON.ANS   Personal mail
    -MODIFY.ANS   Modify settings
    -RESTORE.ANS  Restore pointers
    -GETWELL.ANS  Get well / goodbye
    -FILES.ANS    File request
    -VACMGR.ANS   Vacation manager
    -V!SEND.ANS   Vacation send
    -V!ERASE.ANS  Vacation erase
    -7BIT.ANS     7-bit mode
    DEFAULT.OLF   Default language strings
  =========================================================================== }

unit OL_Screens;

{$MODE OBJFPC}{$H+}
{$PACKRECORDS 1}

interface

uses
  SysUtils, Classes;

const
  SCREENS_DIR_ENTRY_SIZE = 17;
  SCREENS_MAX_ENTRIES    = 100;
  SCREENS_FNAME_MAX      = 12;

type
  TScreenDirEntry = packed record
    NameLen  : Byte;
    NameData : array[1..SCREENS_FNAME_MAX] of Byte;
    Offset   : Word;       { Absolute file offset of screen data }
    Reserved : Word;       { Always 0 }
  end;

  TScreenEntry = record
    Name     : String;
    Offset   : LongInt;
    Size     : LongInt;    { Computed from next entry's offset }
    Data     : String;     { Raw screen data }
  end;

  TScreenArchive = record
    Entries  : array of TScreenEntry;
    Count    : Integer;
    RawData  : array of Byte;
    RawSize  : LongInt;
  end;

{ Load SCREENS.DAT into memory }
function LoadScreens(const Filename: String;
  var Archive: TScreenArchive): Boolean;

{ Find a screen by name (case-insensitive) }
function FindScreen(const Archive: TScreenArchive;
  const Name: String): Integer;

{ Get screen data as string }
function GetScreenData(const Archive: TScreenArchive;
  Index: Integer): String;

{ Get screen for current terminal mode (ANS/ASC/RIP) }
function GetScreenForMode(const Archive: TScreenArchive;
  const BaseName: String; Mode: Integer): String;

const
  SCREEN_MODE_ANS = 0;
  SCREEN_MODE_ASC = 1;
  SCREEN_MODE_RIP = 2;

implementation

function LoadScreens(const Filename: String;
  var Archive: TScreenArchive): Boolean;
var
  F: File;
  DirEntry: TScreenDirEntry;
  BytesRead: Integer;
  I, J: Integer;
  MinNext: LongInt;
begin
  Result := False;
  Archive.Count := 0;

  if not FileExists(Filename) then Exit;

  AssignFile(F, Filename);
  {$I-} Reset(F, 1); {$I+}
  if IOResult <> 0 then Exit;

  { Get file size }
  Archive.RawSize := FileSize(F);
  SetLength(Archive.RawData, Archive.RawSize);
  BlockRead(F, Archive.RawData[0], Archive.RawSize, BytesRead);
  CloseFile(F);

  if BytesRead <> Archive.RawSize then Exit;

  { Read directory entries }
  I := 0;
  while (I * SCREENS_DIR_ENTRY_SIZE + SCREENS_DIR_ENTRY_SIZE <= Archive.RawSize) and
        (I < SCREENS_MAX_ENTRIES) do
  begin
    Move(Archive.RawData[I * SCREENS_DIR_ENTRY_SIZE],
         DirEntry, SCREENS_DIR_ENTRY_SIZE);

    { Stop if name length is 0 or > 12 }
    if (DirEntry.NameLen = 0) or (DirEntry.NameLen > SCREENS_FNAME_MAX) then
      Break;

    SetLength(Archive.Entries, I + 1);
    SetString(Archive.Entries[I].Name,
      PAnsiChar(@DirEntry.NameData[1]), DirEntry.NameLen);
    Archive.Entries[I].Offset := DirEntry.Offset;
    Archive.Entries[I].Size := 0;

    Inc(I);
  end;

  Archive.Count := I;

  { Compute sizes from offset gaps }
  for I := 0 to Archive.Count - 2 do
  begin
    { Find next higher offset to compute this entry's size }
    Archive.Entries[I].Size :=
      Archive.RawSize - Archive.Entries[I].Offset;

    { Better: find the minimum offset that's > this offset }
    MinNext := Archive.RawSize;
    for J := 0 to Archive.Count - 1 do
      if (Archive.Entries[J].Offset > Archive.Entries[I].Offset) and
         (Archive.Entries[J].Offset < MinNext) then
        MinNext := Archive.Entries[J].Offset;
    Archive.Entries[I].Size := MinNext - Archive.Entries[I].Offset;
  end;

  { Last entry goes to EOF }
  if Archive.Count > 0 then
    Archive.Entries[Archive.Count - 1].Size :=
      Archive.RawSize - Archive.Entries[Archive.Count - 1].Offset;

  Result := Archive.Count > 0;
end;

function FindScreen(const Archive: TScreenArchive;
  const Name: String): Integer;
var I: Integer;
begin
  for I := 0 to Archive.Count - 1 do
    if SameText(Archive.Entries[I].Name, Name) then
    begin
      Result := I;
      Exit;
    end;
  Result := -1;
end;

function GetScreenData(const Archive: TScreenArchive;
  Index: Integer): String;
var
  Off, Sz: LongInt;
begin
  Result := '';
  if (Index < 0) or (Index >= Archive.Count) then Exit;

  Off := Archive.Entries[Index].Offset;
  Sz := Archive.Entries[Index].Size;

  if (Off + Sz <= Archive.RawSize) and (Sz > 0) then
    SetString(Result, PAnsiChar(@Archive.RawData[Off]), Sz);
end;

function GetScreenForMode(const Archive: TScreenArchive;
  const BaseName: String; Mode: Integer): String;
var
  Ext: String;
  Idx: Integer;
begin
  case Mode of
    SCREEN_MODE_ANS: Ext := '.ANS';
    SCREEN_MODE_ASC: Ext := '.ASC';
    SCREEN_MODE_RIP: Ext := '.RIP';
  else
    Ext := '.ANS';
  end;

  Idx := FindScreen(Archive, BaseName + Ext);
  if Idx >= 0 then
    Result := GetScreenData(Archive, Idx)
  else
  begin
    { Fall back to ANS if requested mode not found }
    Idx := FindScreen(Archive, BaseName + '.ANS');
    if Idx >= 0 then
      Result := GetScreenData(Archive, Idx)
    else
      Result := '';
  end;
end;

end.
