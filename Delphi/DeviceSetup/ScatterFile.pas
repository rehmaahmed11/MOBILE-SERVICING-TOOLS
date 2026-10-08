unit ScatterFile;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


{ MediaTek scatter file (the "-Android_scatter.txt" a flash tool ships with a
  ROM) reader.

  A scatter file is a YAML-ish list of partitions:

      partition_index: SYS0
      partition_name: preloader
      file_name: preloader_k71v1_64_bsp.bin
      is_download: true
      type: SV5_BL_BIN
      physical_start_addr: 0x0
      partition_size: 0x40000
      region: EMMC_BOOT_1
      storage: HW_STORAGE_EMMC
      boundary_check: true
      is_reserved: false
      operation_type: BOOTLOADERS
      reserve: 0x00

  The two things the job engine needs are (a) name -> (region, physical start,
  size) so an operation can be aimed at one partition, and (b) the preloader
  file name, because the BROM boot needs the matching preloader / DA.

  Only the fields above are read. Anything unrecognised is kept as an extra so
  a newer scatter format still loads instead of failing. }

interface

uses
{$IFDEF FPC}
  Classes, SysUtils,
{$ELSE}
  System.Classes,
  System.SysUtils,
{$ENDIF}
  DevTypes;

type
  { Flash region a partition lives in. The order matches the legacy DA
    partition selector used by MtkDaLegacy (MTK_PART_* in DevTypes). }
  TScatterRegion = (srUnknown, srBoot1, srBoot2, srRpmb, srGp1, srGp2,
    srGp3, srGp4, srUser);

  TScatterEntry = record
    Index: Integer;          { partition_index order, 0-based }
    Name: string;            { partition_name }
    FileName: string;        { file_name, '' when the ROM does not carry it }
    Download: Boolean;       { is_download }
    Kind: string;            { type, e.g. SV5_BL_BIN, NORMAL_ROM }
    StartAddr: UInt64;       { physical_start_addr }
    Size: UInt64;            { partition_size }
    LinearAddr: UInt64;      { linear_start_addr when present }
    Region: TScatterRegion;  { region }
    Storage: string;         { storage, e.g. HW_STORAGE_EMMC }
    Operation: string;       { operation_type }
    Reserved: Boolean;       { is_reserved }
    BoundaryCheck: Boolean;
  end;
  TScatterEntryArray = array of TScatterEntry;

  TScatterFile = class(TObject)
  private
    FEntries: TScatterEntryArray;
    FValid: Boolean;
    FMessage: string;
    FFileName: string;
    FChip: string;
    FProject: string;
    FPlatform: string;
    FStorage: string;
    FBootChannel: string;
    FFlashToolVersion: string;
    FDaAddress: UInt64;
    FPreloaderName: string;
    function GetCount: Integer;
    function GetEntry(const AIndex: Integer): TScatterEntry;
    procedure SetText(const AText: string);
  public
    constructor Create;
    { Reads and parses a scatter file. Returns False and fills Message when
      the file cannot be read or holds no partitions. }
    function LoadFromFile(const AFileName: string): Boolean;
    { Parses text already in memory (used by the self-test). }
    procedure Parse(const AText: string);

    { Finds a partition by name ('preloader', 'nvram', 'frp'...). AName may be
      written with or without the exact case used by the ROM. }
    function FindByName(const AName: string; out AEntry: TScatterEntry): Boolean;
    { Address and size of a partition, or False when it is not in the table. }
    function RangeOf(const AName: string; out AStart, ASize: UInt64): Boolean;
    { Region selector byte for the legacy DA (MTK_PART_USER_DATA and friends),
      or -1 when the region is unknown. }
    function PartitionByteOf(const AName: string): Integer;
    { Absolute address of a partition inside the user area. Boot partitions in
      the scatter file are addressed from 0 within their own region, so the
      user-area offset has to be added by the caller when the DA is told to
      use the user region. }
    function AbsoluteStartOf(const AName: string; out AStart: UInt64): Boolean;
    { Every partition that the ROM asks to download, in scatter order. }
    function Downloadable: TScatterEntryArray;
    { One line per partition, for the log. }
    function Describe: string;
    { Table for the "Read Partitions" job. }
    procedure AppendTableTo(ALines: TStrings);

    property Count: Integer read GetCount;
    property Entries[const AIndex: Integer]: TScatterEntry read GetEntry;
    property Valid: Boolean read FValid;
    property Message: string read FMessage;
    property SourceName: string read FFileName;
    property Chip: string read FChip;
    property Project: string read FProject;
    property PlatformName: string read FPlatform;
    property StorageName: string read FStorage;
    property BootChannel: string read FBootChannel;
    property FlashToolVersion: string read FFlashToolVersion;
    { DA download address from the header, 0 when the scatter does not say. }
    property DaAddress: UInt64 read FDaAddress;
    { file_name of the preloader partition, '' when there is none. }
    property PreloaderName: string read FPreloaderName;
  end;

{ 'EMMC_BOOT_1' -> srBoot1. Unknown names give srUnknown. }
function RegionOfName(const AName: string): TScatterRegion;
function RegionName(ARegion: TScatterRegion): string;
{ Legacy DA partition byte for a region (MTK_PART_... in DevTypes), or -1. }
function RegionPartitionByte(ARegion: TScatterRegion): Integer;
{ 'HW_STORAGE_EMMC' -> 'EMMC'. }
function StorageShortName(const AStorage: string): string;
{ Formats a byte count the way the log does elsewhere: '2.5 MiB'. }
function FormatScatterSize(ABytes: UInt64): string;
function EmptyScatterEntry: TScatterEntry;

implementation

{ ------------------------------------------------------------------ helpers }

function EmptyScatterEntry: TScatterEntry;
begin
  Result.Index := 0;
  Result.Name := '';
  Result.FileName := '';
  Result.Download := False;
  Result.Kind := '';
  Result.StartAddr := 0;
  Result.Size := 0;
  Result.LinearAddr := 0;
  Result.Region := srUnknown;
  Result.Storage := '';
  Result.Operation := '';
  Result.Reserved := False;
  Result.BoundaryCheck := False;
end;

function RegionName(ARegion: TScatterRegion): string;
begin
  case ARegion of
    srBoot1: Result := 'BOOT_1';
    srBoot2: Result := 'BOOT_2';
    srRpmb: Result := 'RPMB';
    srGp1: Result := 'GP1';
    srGp2: Result := 'GP2';
    srGp3: Result := 'GP3';
    srGp4: Result := 'GP4';
    srUser: Result := 'USER';
  else
    Result := 'UNKNOWN';
  end;
end;

function RegionOfName(const AName: string): TScatterRegion;
var
  S: string;
begin
  S := UpperCase(Trim(AName));
  { scatter files write 'EMMC_BOOT_1', 'UFS_LU0', 'BOOT_1' or just 'USER' }
  if Pos('UFS_LU', S) > 0 then
  begin
    if S = 'UFS_LU0_BOOT1' then
      Exit(srBoot1);
    if Pos('BOOT1', S) > 0 then
      Exit(srBoot1);
    if Pos('BOOT2', S) > 0 then
      Exit(srBoot2);
    if Pos('RPMB', S) > 0 then
      Exit(srRpmb);
    if Pos('_LU1', S) > 0 then
      Exit(srGp1);
    if Pos('_LU2', S) > 0 then
      Exit(srGp2);
    if Pos('_LU3', S) > 0 then
      Exit(srGp3);
    if Pos('_LU4', S) > 0 then
      Exit(srGp4);
    Exit(srUser);
  end;
  if Pos('BOOT_1', S) > 0 then
    Exit(srBoot1);
  if Pos('BOOT_2', S) > 0 then
    Exit(srBoot2);
  if Pos('BOOT1', S) > 0 then
    Exit(srBoot1);
  if Pos('BOOT2', S) > 0 then
    Exit(srBoot2);
  if Pos('RPMB', S) > 0 then
    Exit(srRpmb);
  if (Pos('GP_1', S) > 0) or (Pos('GP1', S) > 0) then
    Exit(srGp1);
  if (Pos('GP_2', S) > 0) or (Pos('GP2', S) > 0) then
    Exit(srGp2);
  if (Pos('GP_3', S) > 0) or (Pos('GP3', S) > 0) then
    Exit(srGp3);
  if (Pos('GP_4', S) > 0) or (Pos('GP4', S) > 0) then
    Exit(srGp4);
  if (Pos('USER', S) > 0) or (Pos('EMMC', S) > 0) then
    Exit(srUser);
  Result := srUnknown;
end;

function RegionPartitionByte(ARegion: TScatterRegion): Integer;
begin
  case ARegion of
    srBoot1: Result := MTK_PART_BOOT1;
    srBoot2: Result := MTK_PART_BOOT2;
    srRpmb: Result := MTK_PART_RPMB;
    srGp1: Result := MTK_PART_GP1;
    srGp2: Result := MTK_PART_GP2;
    srGp3: Result := MTK_PART_GP3;
    srGp4: Result := MTK_PART_GP4;
    srUser: Result := MTK_PART_USER;
  else
    Result := -1;
  end;
end;

function StorageShortName(const AStorage: string): string;
var
  S: string;
begin
  S := UpperCase(Trim(AStorage));
  if Pos('HW_STORAGE_', S) = 1 then
    Delete(S, 1, Length('HW_STORAGE_'));
  if Pos('EMMC', S) > 0 then
    Result := 'EMMC'
  else if Pos('UFS', S) > 0 then
    Result := 'UFS'
  else if Pos('NAND', S) > 0 then
    Result := 'NAND'
  else if Pos('SDMMC', S) > 0 then
    Result := 'SD'
  else if Pos('NOR', S) > 0 then
    Result := 'NOR'
  else
    Result := Trim(AStorage);
end;

function FormatScatterSize(ABytes: UInt64): string;
const
  CUnits: array[0..4] of string = ('B', 'KiB', 'MiB', 'GiB', 'TiB');
var
  Value: Double;
  UnitIndex: Integer;
begin
  Value := Double(ABytes);
  UnitIndex := 0;
  while (Value >= 1024) and (UnitIndex < High(CUnits)) do
  begin
    Value := Value / 1024;
    Inc(UnitIndex);
  end;
  if UnitIndex = 0 then
    Result := IntToStr(ABytes) + ' ' + CUnits[0]
  else
    Result := Format('%.1f %s', [Value, CUnits[UnitIndex]]);
end;

{ Removes surrounding quotes and trailing whitespace from a YAML value. }
function CleanValue(const AValue: string): string;
var
  S: string;
begin
  S := Trim(AValue);
  { a comment may follow the value: `is_download: true  # comment` }
  if Pos('#', S) > 0 then
    S := Trim(Copy(S, 1, Pos('#', S) - 1));
  if (Length(S) >= 2) and
     (((S[1] = '"') and (S[Length(S)] = '"')) or
      ((S[1] = '''') and (S[Length(S)] = ''''))) then
    S := Copy(S, 2, Length(S) - 2);
  Result := Trim(S);
end;

{ Accepts 0x..., decimal, and the plain hex some tools write. }
function ParseNumber(const AText: string; out AValue: UInt64): Boolean;
var
  S: string;
  I, Digit: Integer;
  Base: Integer;
begin
  AValue := 0;
  Result := False;
  S := CleanValue(AText);
  if S = '' then
    Exit;
  Base := 10;
  if (Length(S) > 2) and (S[1] = '0') and ((S[2] = 'x') or (S[2] = 'X')) then
  begin
    Delete(S, 1, 2);
    Base := 16;
  end;
  if Base = 10 then
  begin
    for I := 1 to Length(S) do
      if not (S[I] in ['0'..'9']) then
      begin
        { a bare hex number without the 0x prefix }
        Base := 16;
        Break;
      end;
  end;
  for I := 1 to Length(S) do
  begin
    case S[I] of
      '0'..'9': Digit := Ord(S[I]) - Ord('0');
      'a'..'f': if Base = 16 then Digit := Ord(S[I]) - Ord('a') + 10 else Exit;
      'A'..'F': if Base = 16 then Digit := Ord(S[I]) - Ord('A') + 10 else Exit;
      '_', ' ': Continue;
    else
      Exit;
    end;
    if Digit >= Base then
      Exit;
    AValue := (AValue * UInt64(Base)) + UInt64(Digit);
  end;
  Result := True;
end;

function ParseBool(const AText: string): Boolean;
var
  S: string;
begin
  S := LowerCase(CleanValue(AText));
  Result := (S = 'true') or (S = 'yes') or (S = '1') or (S = 'on');
end;

{ ------------------------------------------------------------ TScatterFile }

constructor TScatterFile.Create;
begin
  inherited Create;
  FEntries := nil;
  FValid := False;
  FMessage := '';
  FFileName := '';
  FChip := '';
  FProject := '';
  FPlatform := '';
  FStorage := '';
  FBootChannel := '';
  FFlashToolVersion := '';
  FDaAddress := 0;
  FPreloaderName := '';
end;

function TScatterFile.GetCount: Integer;
begin
  Result := Length(FEntries);
end;

function TScatterFile.GetEntry(const AIndex: Integer): TScatterEntry;
begin
  if (AIndex >= 0) and (AIndex < Length(FEntries)) then
    Result := FEntries[AIndex]
  else
    Result := EmptyScatterEntry;
end;

procedure TScatterFile.SetText(const AText: string);
begin
  Parse(AText);
end;

function TScatterFile.LoadFromFile(const AFileName: string): Boolean;
var
  Lines: TStringList;
begin
  FFileName := AFileName;
  Lines := TStringList.Create;
  try
    try
      Lines.LoadFromFile(AFileName);
    except
      on E: Exception do
      begin
        FValid := False;
        FMessage := 'Cannot read scatter file: ' + E.Message;
        Exit(False);
      end;
    end;
    Parse(Lines.Text);
  finally
    Lines.Free;
  end;
  Result := FValid;
end;

procedure TScatterFile.Parse(const AText: string);
var
  Lines: TStringList;
  I, Pos_: Integer;
  Line, Key, Value: string;
  Current: TScatterEntry;
  HaveCurrent: Boolean;
  HeaderDone: Boolean;

  procedure FlushEntry;
  begin
    if not HaveCurrent then
      Exit;
    { only a partition block has a name; header keys are collected separately }
    if Current.Name <> '' then
    begin
      Current.Index := Length(FEntries);
      SetLength(FEntries, Length(FEntries) + 1);
      FEntries[High(FEntries)] := Current;
      if SameText(Current.Name, 'preloader') then
        FPreloaderName := Current.FileName;
      if FStorage = '' then
        FStorage := StorageShortName(Current.Storage);
    end;
    Current := EmptyScatterEntry;
    HaveCurrent := False;
  end;

begin
  FEntries := nil;
  FValid := False;
  FMessage := '';
  FChip := '';
  FProject := '';
  FPlatform := '';
  FStorage := '';
  FBootChannel := '';
  FFlashToolVersion := '';
  FDaAddress := 0;
  FPreloaderName := '';
  Current := EmptyScatterEntry;
  HaveCurrent := False;
  HeaderDone := False;

  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    for I := 0 to Lines.Count - 1 do
    begin
      Line := Lines[I];
      { A leading '-' starts a new YAML list item, i.e. a new partition.
        Remove the dash and the whitespace after it only: Delete past the first
        ':' would throw away the key of "- partition_index: SYS0". }
      if (Length(Trim(Line)) > 0) and (Trim(Line)[1] = '-') then
      begin
        FlushEntry;
        HeaderDone := True;
        Pos_ := Pos('-', Line) + 1;
        while (Pos_ <= Length(Line)) and
              ((Line[Pos_] = ' ') or (Line[Pos_] = #9)) do
          Inc(Pos_);
        Delete(Line, 1, Pos_ - 1);
      end;
      Pos_ := Pos(':', Line);
      if Pos_ <= 0 then
        Continue;
      Key := LowerCase(Trim(Copy(Line, 1, Pos_ - 1)));
      Value := Copy(Line, Pos_ + 1, MaxInt);
      if Key = 'partition_name' then
      begin
        { a new partition block starts here in files that have no '-' items }
        FlushEntry;
        HeaderDone := True;
        HaveCurrent := True;
        Current.Name := CleanValue(Value);
        Continue;
      end;
      if Key = 'partition_index' then
      begin
        if not HaveCurrent then
        begin
          FlushEntry;
          HaveCurrent := True;
        end;
        HeaderDone := True;
        Continue;
      end;

      if HaveCurrent then
      begin
        if Key = 'file_name' then
          Current.FileName := CleanValue(Value)
        else if Key = 'is_download' then
          Current.Download := ParseBool(Value)
        else if Key = 'type' then
          Current.Kind := CleanValue(Value)
        else if Key = 'physical_start_addr' then
          ParseNumber(Value, Current.StartAddr)
        else if Key = 'linear_start_addr' then
          ParseNumber(Value, Current.LinearAddr)
        else if Key = 'partition_size' then
          ParseNumber(Value, Current.Size)
        else if Key = 'region' then
          Current.Region := RegionOfName(Value)
        else if Key = 'storage' then
          Current.Storage := CleanValue(Value)
        else if Key = 'operation_type' then
          Current.Operation := CleanValue(Value)
        else if Key = 'is_reserved' then
          Current.Reserved := ParseBool(Value)
        else if Key = 'boundary_check' then
          Current.BoundaryCheck := ParseBool(Value);
        Continue;
      end;

      { header keys, before the first partition }
      if not HeaderDone then
      begin
        if Key = 'chip' then
          FChip := CleanValue(Value)
        else if Key = 'project' then
          FProject := CleanValue(Value)
        else if Key = 'platform' then
          FPlatform := CleanValue(Value)
        else if Key = 'storage' then
          FStorage := StorageShortName(Value)
        else if Key = 'boot_channel' then
          FBootChannel := CleanValue(Value)
        else if Key = 'flashtool_version' then
          FFlashToolVersion := CleanValue(Value)
        else if (Key = 'da_address') or (Key = 'download_agent_addr') or
                (Key = 'da_start_addr') then
          ParseNumber(Value, FDaAddress);
      end;
    end;
    FlushEntry;
  finally
    Lines.Free;
  end;

  FValid := Length(FEntries) > 0;
  if FValid then
    FMessage := IntToStr(Length(FEntries)) + ' partition(s)'
  else
    FMessage := 'No partition entries found in the scatter file';
end;

function TScatterFile.FindByName(const AName: string;
  out AEntry: TScatterEntry): Boolean;
var
  I: Integer;
begin
  AEntry := EmptyScatterEntry;
  for I := 0 to High(FEntries) do
    if SameText(FEntries[I].Name, AName) then
    begin
      AEntry := FEntries[I];
      Exit(True);
    end;
  { some ROMs prefix the name ('lk_a', 'boot_a'); accept a slot suffix }
  for I := 0 to High(FEntries) do
    if SameText(FEntries[I].Name, AName + '_a') or
       SameText(FEntries[I].Name, AName + '_b') then
    begin
      AEntry := FEntries[I];
      Exit(True);
    end;
  Result := False;
end;

function TScatterFile.RangeOf(const AName: string;
  out AStart, ASize: UInt64): Boolean;
var
  Entry: TScatterEntry;
begin
  AStart := 0;
  ASize := 0;
  if not FindByName(AName, Entry) then
    Exit(False);
  AStart := Entry.StartAddr;
  ASize := Entry.Size;
  Result := True;
end;

function TScatterFile.PartitionByteOf(const AName: string): Integer;
var
  Entry: TScatterEntry;
begin
  if FindByName(AName, Entry) then
    Result := RegionPartitionByte(Entry.Region)
  else
    Result := RegionPartitionByte(srUser);
end;

function TScatterFile.AbsoluteStartOf(const AName: string;
  out AStart: UInt64): Boolean;
var
  Entry: TScatterEntry;
begin
  AStart := 0;
  if not FindByName(AName, Entry) then
    Exit(False);
  AStart := Entry.StartAddr;
  Result := True;
end;

function TScatterFile.Downloadable: TScatterEntryArray;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to High(FEntries) do
    if FEntries[I].Download and (not FEntries[I].Reserved) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := FEntries[I];
    end;
end;

function TScatterFile.Describe: string;
var
  I: Integer;
  DownloadCount: Integer;
begin
  if not FValid then
    Exit('scatter: ' + FMessage);
  DownloadCount := 0;
  for I := 0 to High(FEntries) do
    if FEntries[I].Download then
      Inc(DownloadCount);
  Result := 'scatter: ' + IntToStr(Length(FEntries)) + ' partition(s), ' +
    IntToStr(DownloadCount) + ' to download';
  if FChip <> '' then
    Result := Result + ', chip ' + FChip;
  if FPlatform <> '' then
    Result := Result + ', platform ' + FPlatform;
  if FStorage <> '' then
    Result := Result + ', storage ' + FStorage;
  if FPreloaderName <> '' then
    Result := Result + ', preloader ' + FPreloaderName;
end;

procedure TScatterFile.AppendTableTo(ALines: TStrings);
var
  I: Integer;
  E: TScatterEntry;
begin
  if ALines = nil then
    Exit;
  if not FValid then
  begin
    ALines.Add(FMessage);
    Exit;
  end;
  ALines.Add(Format('%-4s %-22s %-8s %-18s %-18s %s',
    ['#', 'name', 'region', 'start', 'size', 'file']));
  for I := 0 to High(FEntries) do
  begin
    E := FEntries[I];
    ALines.Add(Format('%-4d %-22s %-8s %-18s %-18s %s',
      [I, E.Name, RegionName(E.Region),
       '0x' + IntToHex(Int64(E.StartAddr), 8),
       FormatScatterSize(E.Size),
       E.FileName]));
  end;
end;

end.
