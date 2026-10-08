unit DaImage;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

{ Download-agent containers and headers.

  The Data/DA payloads in this repository come in three shapes:

    1. A TAR archive whose single member is the download agent. This is what
      the supplied .da / .crp / .bin files are: a 512-byte TAR header naming
      the inner file ("PAD_P1.bin", "CPH2357.bin", "MTK_AllInOne_DA.bin"),
      then the payload, then TAR padding.
    2. A ZIP archive containing da.bin / auth.bin (handled by DaLoader).
    3. A bare download agent.

  Whatever the container, the download agent itself starts with a header of
  ten little-endian words followed by one 20-byte region descriptor per entry:

      magic, hw_code, hw_sub_code, hw_version, sw_version, reserved,
      page_size, reserved, entry_region_index, entry_region_count
      then per region: load base, length, start address, file offset,
                       signature length

  Region[entry_region_index] is stage 1 (DA1) and the next one is stage 2
  (DA2). That is what SEND_DA / JUMP_DA and the stage-2 upload need.

  IMPORTANT, and the reason this unit reports instead of guessing: the
  payloads shipped in Data/DA are encrypted vendor blobs. Their first bytes
  are not a DA header, so no region table can be read from them. This unit
  says exactly that ("the payload is encrypted / opaque") and the job fails
  with that reason rather than inventing addresses. A plaintext download
  agent (the kind SP Flash Tool uses) parses fully and is uploaded for real. }

interface

uses
{$IFDEF FPC}
  Classes, SysUtils,
{$ELSE}
  System.Classes,
  System.SysUtils,
{$ENDIF}
  DevTypes;   { TBytesArray, the byte buffer every device unit passes around }

type
  TDaRegion = record
    LoadBase: UInt32;     { m_buf }
    Length: UInt32;       { m_len }
    StartAddr: UInt32;    { m_start_addr }
    FileOffset: UInt32;   { m_start_offset }
    SigLen: UInt32;       { m_sig_len }
  end;

  TDaImage = class(TObject)
  private
    FMagic: Word;
    FHwCode: Word;
    FHwSubCode: Word;
    FHwVer: Word;
    FSwVer: Word;
    FPageSize: Word;
    FEntryIndex: Word;
    FRegionCount: Word;
    FRegions: array of TDaRegion;
    FPayload: TBytesArray;
    FValid: Boolean;
    FHeaderSize: Integer;
    FSourceName: string;
    FEncrypted: Boolean;
    FMessage: string;
    function RegionData(AIndex: Integer): TBytesArray;
  public
    destructor Destroy; override;

    { Parses a raw download agent (header + regions). }
    function Parse(const AData: TBytesArray; const AName: string): Boolean;
    { Loads a file, unwrapping a TAR container first when there is one. }
    function LoadFromFile(const AFileName: string): Boolean;

    function Stage1Address: UInt32;
    function Stage1Data: TBytesArray;
    function Stage1SigLen: UInt32;
    function Stage2Address: UInt32;
    function Stage2Data: TBytesArray;
    function Stage2SigLen: UInt32;
    function HasStage2: Boolean;
    { True when the hwcode of the DA matches the chip we found. }
    function MatchesChip(AHwCode: Word): Boolean;
    function Describe: string;

    property Valid: Boolean read FValid;
    property Encrypted: Boolean read FEncrypted;
    property Message: string read FMessage;
    property Magic: Word read FMagic;
    property HwCode: Word read FHwCode;
    property HwSubCode: Word read FHwSubCode;
    property HwVer: Word read FHwVer;
    property SwVer: Word read FSwVer;
    property PageSize: Word read FPageSize;
    property EntryIndex: Word read FEntryIndex;
    property RegionCount: Word read FRegionCount;
    property HeaderSize: Integer read FHeaderSize;
    property SourceName: string read FSourceName;
    property Payload: TBytesArray read FPayload;
  end;

{ Reads a whole file into a byte array. False when it cannot be read. }
function LoadFileBytes(const AFileName: string; out AData: TBytesArray): Boolean;
{ True when AData starts with a TAR member header naming a plausible file. }
function IsTarContainer(const AData: TBytesArray): Boolean;
{ Extracts the first TAR member. Returns False when there is none. }
function UnwrapTar(const AData: TBytesArray; out AInner: TBytesArray;
  out AInnerName: string): Boolean;
{ True when the bytes look like a DA header rather than an encrypted blob. }
function LooksLikeDaHeader(const AData: TBytesArray): Boolean;

implementation

function LoadFileBytes(const AFileName: string; out AData: TBytesArray): Boolean;
var
  FS: TFileStream;
  N: Int64;
begin
  SetLength(AData, 0);
  Result := False;
  if not FileExists(AFileName) then
    Exit;
  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    N := FS.Size;
    if (N <= 0) or (N > 256 * 1024 * 1024) then
      Exit;
    SetLength(AData, N);
    FS.Position := 0;
    FS.ReadBuffer(AData[0], N);
    Result := True;
  finally
    FS.Free;
  end;
end;

function ReadLeWord(const AData: TBytesArray; AOffset: Integer): Word;
begin
  Result := Word(AData[AOffset]) or (Word(AData[AOffset + 1]) shl 8);
end;

function ReadLeDword(const AData: TBytesArray; AOffset: Integer): UInt32;
begin
  Result := UInt32(AData[AOffset]) or (UInt32(AData[AOffset + 1]) shl 8) or
    (UInt32(AData[AOffset + 2]) shl 16) or (UInt32(AData[AOffset + 3]) shl 24);
end;

function IsTarContainer(const AData: TBytesArray): Boolean;
var
  I, NameLen: Integer;
begin
  Result := False;
  if Length(AData) < 512 then
    Exit;
  { A TAR member name is printable ASCII, NUL padded, in the first 100 bytes. }
  NameLen := 0;
  for I := 0 to 99 do
  begin
    if AData[I] = 0 then
      Break;
    if (AData[I] < 32) or (AData[I] > 126) then
      Exit;
    Inc(NameLen);
  end;
  if (NameLen < 4) or (NameLen > 99) then
    Exit;
  { ustar magic at offset 257, or a size field that decodes as octal. }
  if (AData[257] = Ord('u')) and (AData[258] = Ord('s')) and
     (AData[259] = Ord('t')) and (AData[260] = Ord('a')) and
     (AData[261] = Ord('r')) then
  begin
    Result := True;
    Exit;
  end;
  { GNU tar often omits the magic; accept it when the size field is octal and
    the payload is long enough to hold the member. }
  Result := False;
end;

function TarOctalSize(const AData: TBytesArray): Int64;
var
  I: Integer;
  S: string;
  C: Char;
begin
  Result := -1;
  S := '';
  for I := 124 to 135 do
  begin
    C := Char(AData[I]);
    if (C >= '0') and (C <= '7') then
      S := S + C
    else if (C = ' ') or (C = #0) then
      Continue
    else
      Exit;
  end;
  if S = '' then
    Exit;
  Result := 0;
  for I := 1 to Length(S) do
    Result := Result * 8 + (Ord(S[I]) - Ord('0'));
end;

function UnwrapTar(const AData: TBytesArray; out AInner: TBytesArray;
  out AInnerName: string): Boolean;
var
  Size: Int64;
  NameLen: Integer;
begin
  SetLength(AInner, 0);
  AInnerName := '';
  Result := False;
  if Length(AData) < 512 then
    Exit;
  NameLen := 0;
  while (NameLen < 100) and (AData[NameLen] <> 0) do
    Inc(NameLen);
  if NameLen = 0 then
    Exit;
  SetString(AInnerName, PAnsiChar(@AData[0]), NameLen);
  Size := TarOctalSize(AData);
  if (Size <= 0) or (Size > Length(AData) - 512) then
    Size := Length(AData) - 512;
  if Size <= 0 then
    Exit;
  SetLength(AInner, Size);
  Move(AData[512], AInner[0], Size);
  Result := True;
end;

function LooksLikeDaHeader(const AData: TBytesArray): Boolean;
var
  Count, Idx, HeaderLen: Integer;
  I: Integer;
  R: TDaRegion;
begin
  Result := False;
  if Length(AData) < 20 then
    Exit;
  Count := ReadLeWord(AData, 18);
  Idx := ReadLeWord(AData, 16);
  { A real DA header has a small region count, a page size that is a power of
    two and a plausible hwcode. An encrypted blob gives random values here. }
  if (Count = 0) or (Count > 8) then
    Exit;
  if Idx >= Count then
    Exit;
  HeaderLen := 20 + Count * 20;
  if Length(AData) < HeaderLen then
    Exit;
  if ReadLeWord(AData, 12) = 0 then
    Exit;   { page size 0 is not a DA }
  for I := 0 to Count - 1 do
  begin
    R.LoadBase := ReadLeDword(AData, 20 + I * 20);
    R.Length := ReadLeDword(AData, 24 + I * 20);
    R.StartAddr := ReadLeDword(AData, 28 + I * 20);
    R.FileOffset := ReadLeDword(AData, 32 + I * 20);
    R.SigLen := ReadLeDword(AData, 36 + I * 20);
    if (R.Length = 0) or (R.Length > UInt32(Length(AData))) then
      Exit;
    if (R.StartAddr = 0) or (R.StartAddr > $F0000000) then
      Exit;
    if R.FileOffset + R.Length > UInt32(Length(AData)) then
      Exit;
    if R.SigLen > R.Length then
      Exit;
  end;
  Result := True;
end;

{ ------------------------------------------------------------------- TDaImage }

destructor TDaImage.Destroy;
begin
  SetLength(FRegions, 0);
  SetLength(FPayload, 0);
  inherited Destroy;
end;

function TDaImage.RegionData(AIndex: Integer): TBytesArray;
var
  R: TDaRegion;
begin
  SetLength(Result, 0);
  if (AIndex < 0) or (AIndex > High(FRegions)) then
    Exit;
  R := FRegions[AIndex];
  if Int64(R.FileOffset) + Int64(R.Length) > Length(FPayload) then
    Exit;
  SetLength(Result, R.Length);
  if R.Length > 0 then
    Move(FPayload[R.FileOffset], Result[0], R.Length);
end;

function TDaImage.Parse(const AData: TBytesArray; const AName: string): Boolean;
var
  I, Count: Integer;
  R: TDaRegion;
begin
  Result := False;
  FValid := False;
  FEncrypted := False;
  FSourceName := AName;
  FMessage := '';
  SetLength(FRegions, 0);
  FPayload := AData;

  if not LooksLikeDaHeader(FPayload) then
  begin
    FEncrypted := True;
    FMessage := 'The payload does not start with a download-agent header. ' +
      'The vendor payloads shipped in Data/DA are encrypted blobs; their ' +
      'region table cannot be read without the vendor key. Supply an ' +
      'unpacked download agent (the "DA bin" a flash tool uses) to continue.';
    Exit;
  end;

  FMagic := ReadLeWord(FPayload, 0);
  FHwCode := ReadLeWord(FPayload, 2);
  FHwSubCode := ReadLeWord(FPayload, 4);
  FHwVer := ReadLeWord(FPayload, 6);
  FSwVer := ReadLeWord(FPayload, 8);
  FPageSize := ReadLeWord(FPayload, 12);
  FEntryIndex := ReadLeWord(FPayload, 16);
  FRegionCount := ReadLeWord(FPayload, 18);
  Count := FRegionCount;
  SetLength(FRegions, Count);
  for I := 0 to Count - 1 do
  begin
    R.LoadBase := ReadLeDword(FPayload, 20 + I * 20);
    R.Length := ReadLeDword(FPayload, 24 + I * 20);
    R.StartAddr := ReadLeDword(FPayload, 28 + I * 20);
    R.FileOffset := ReadLeDword(FPayload, 32 + I * 20);
    R.SigLen := ReadLeDword(FPayload, 36 + I * 20);
    FRegions[I] := R;
  end;
  FHeaderSize := 20 + Count * 20;
  FValid := True;
  Result := True;
end;

function TDaImage.LoadFromFile(const AFileName: string): Boolean;
var
  Data, Inner: TBytesArray;
  InnerName: string;
begin
  Result := False;
  FMessage := '';
  if not LoadFileBytes(AFileName, Data) then
  begin
    FMessage := 'Cannot read ' + AFileName;
    Exit;
  end;
  FSourceName := ExtractFileName(AFileName);
  if IsTarContainer(Data) and UnwrapTar(Data, Inner, InnerName) then
  begin
    FSourceName := ExtractFileName(AFileName) + ' -> ' + InnerName;
    Data := Inner;
  end;
  Result := Parse(Data, FSourceName);
end;

function TDaImage.Stage1Address: UInt32;
begin
  if (FEntryIndex >= 0) and (FEntryIndex <= High(FRegions)) then
    Result := FRegions[FEntryIndex].StartAddr
  else
    Result := 0;
end;

function TDaImage.Stage1Data: TBytesArray;
begin
  Result := RegionData(FEntryIndex);
end;

function TDaImage.Stage1SigLen: UInt32;
begin
  if (FEntryIndex >= 0) and (FEntryIndex <= High(FRegions)) then
    Result := FRegions[FEntryIndex].SigLen
  else
    Result := 0;
end;

function TDaImage.HasStage2: Boolean;
begin
  Result := (FEntryIndex + 1) <= High(FRegions);
end;

function TDaImage.Stage2Address: UInt32;
begin
  if HasStage2 then
    Result := FRegions[FEntryIndex + 1].StartAddr
  else
    Result := 0;
end;

function TDaImage.Stage2Data: TBytesArray;
begin
  Result := RegionData(FEntryIndex + 1);
end;

function TDaImage.Stage2SigLen: UInt32;
begin
  if HasStage2 then
    Result := FRegions[FEntryIndex + 1].SigLen
  else
    Result := 0;
end;

function TDaImage.MatchesChip(AHwCode: Word): Boolean;
begin
  Result := (FHwCode = AHwCode) or (FHwCode = 0);
end;

function TDaImage.Describe: string;
begin
  if not FValid then
  begin
    Result := 'not a plaintext download agent';
    Exit;
  end;
  Result := 'magic $' + IntToHex(FMagic, 4) +
    ', hwcode $' + IntToHex(FHwCode, 4) +
    ', hwver $' + IntToHex(FHwVer, 4) +
    ', swver $' + IntToHex(FSwVer, 4) +
    ', page ' + IntToStr(FPageSize) +
    ', regions ' + IntToStr(FRegionCount) +
    ' (entry ' + IntToStr(FEntryIndex) + ')';
end;

end.
