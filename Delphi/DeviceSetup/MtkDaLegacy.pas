unit MtkDaLegacy;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

{ The legacy MediaTek download-agent protocol.

  This is the stage that runs after BromProtocol.JumpDa has started the
  download agent on the phone. It is the one almost every MediaTek handset in
  service shops uses, and it is what makes flash read, write and format
  possible.

  Bring-up sequence
  -----------------
    1. Read the sync byte $C0. Without it the DA did not start.
    2. The DA reports what it found: NOR info (28 bytes), NAND info (17 bytes
       plus 2 bytes per NAND id), eMMC info (92 bytes), SD info (28 bytes),
       configuration info (38 bytes) and a 10-byte pass block whose first byte
       is $5A when all of it worked.
    3. The host acks and reads three bytes.
    4. The host writes the stage-2 configuration: BootROM version, bootloader
       version, NOR chip select, NAND access timing, the BMT settings for this
       chip, force-charge, reset-keys, external clock and the MSDC boot
       channel - plus a chip-specific extra block (see Stage2ExtraKind). The
       DA answers with 4 bytes: 0 means the DRAM is already configured, $BC3
       means it needs the EMI configuration out of the preloader.
    5. Stage 2 (DA2) is uploaded in packets: address, size, packet size, then
       packet / $5A until everything is in.
    6. The DA reports the flash it now sees, with the same structures as in 2.

  Flash commands
  --------------
    Read    $D6 + host id + storage type + BE64 address + BE64 length +
            BE32 packet size, then per packet: data, BE16 checksum, host ack.
    Write   $62 + storage type + partition + BE64 address + BE64 length +
            BE32 packet size; per packet the host sends ack, data, BE16
            checksum and the DA answers $69 (continue) or $5A (last).
    Format  $D4 + storage type + erase/validation/address-type + BE64 address
            + BE64 length, then progress blocks of ack, ack, BE32, percent.
    Finish  $D9 + BE32 boot mode: the DA disconnects and releases the port.

  Derived from the publicly documented legacy DA protocol
  (bkerler/mtkclient, GPLv3: Library/DA/legacy/dalegacy_lib.py).

  What this unit does NOT do: xflash (DA v5/v6 on newer chips) and the XML DA
  dialect are separate protocols and are reported as such rather than faked. }

interface

uses
{$IFDEF FPC}
  Classes, SysUtils,
{$ELSE}
  System.Classes,
  System.SysUtils,
{$ENDIF}
  DevTypes, CommPort, BromProtocol, MtkChips, MtkStatus, DaImage;

type
  TMtkStorageKind = (skUnknown, skNor, skNand, skEmmc, skSdc, skUfs);

  { What the DA reported about the flash it found. }
  TMtkFlashInfo = record
    Kind: TMtkStorageKind;
    FlashSize: UInt64;
    Boot1Size: UInt64;
    Boot2Size: UInt64;
    RpmbSize: UInt64;
    UserAreaSize: UInt64;
    SdcSize: UInt64;
    NandPageSize: Word;
    NandSpareSize: Word;
    Cid: string;
    FirmwareVersion: string;
    ExtRamType: Byte;
    ExtRamSize: UInt64;
    InternalSramSize: UInt32;
  end;

  { Called for every packet so the progress bar moves. }
  TDaProgressEvent = procedure(Sender: TObject; ADone, ATotal: Int64) of object;
  TDaLogEvent = procedure(Sender: TObject; const AText: string) of object;

  TMtkDaLegacy = class(TObject)
  private
    FBrom: TBromProtocol;
    FTransport: TCommTransport;
    FInfo: TMtkFlashInfo;
    FConnected: Boolean;
    FCancelled: Boolean;
    FLastError: string;
    FOnProgress: TDaProgressEvent;
    FOnLog: TDaLogEvent;
    FPacketSize: Integer;
    FSimulated: Boolean;

    function WriteAck: Boolean;
    function WriteByteRaw(AValue: Byte): Boolean;
    function WriteBytesRaw(const AData: TBytesArray): Boolean;
    function WriteWordBe(AValue: Word): Boolean;
    function WriteDwordBe(AValue: UInt32): Boolean;
    function WriteQwordBe(AValue: UInt64): Boolean;
    function ReadBytesRaw(ACount: Integer; out AData: TBytesArray): Boolean;
    function ReadDwordBeRaw(out AValue: UInt32): Boolean;
    function ParseStorageInfo: Boolean;
    function ParseLegacyInfo(ALastBlock: Boolean): Boolean;
    procedure DoLog(const AText: string);
    procedure Progress(ADone, ATotal: Int64);
    function StorageByte: Byte;
    function PartTypeByte(APartition: Integer): Byte;
    function Stage2ConfigBytes: TBytesArray;
  public
    constructor Create(ABrom: TBromProtocol; ATransport: TCommTransport);

    { Runs the whole bring-up. ADa supplies stage 2; when it is nil the DA is
      assumed to be one that answers the flash commands directly (the
      simulated device does this when FullDaSequence is off). }
    function Connect(ADa: TDaImage): Boolean;

    function ReadFlash(AAddr, ALength: UInt64; AOut: TStream;
      APartition: Integer = 8): Boolean;
    function WriteFlash(AAddr, ALength: UInt64; AIn: TStream;
      AOffset: Int64 = 0; APartition: Integer = 8): Boolean;
    function FormatFlash(AAddr, ALength: UInt64; APartition: Integer = 8): Boolean;
    { $D9: 0 normal, 1 home screen, 2 fastboot. Releases the device. }
    function Shutdown(ABootMode: Integer = 0): Boolean;

    { Reads the flash into memory instead of a stream. Used by Read OTP and
      small region reads. }
    function ReadFlashBytes(AAddr, ALength: UInt64; out AData: TBytesArray;
      APartition: Integer = 8): Boolean;

    procedure Cancel;
    procedure ResetCancel;

    property Info: TMtkFlashInfo read FInfo;
    property Connected: Boolean read FConnected;
    property LastError: string read FLastError;
    property PacketSize: Integer read FPacketSize write FPacketSize;
    property Simulated: Boolean read FSimulated write FSimulated;
    property OnProgress: TDaProgressEvent read FOnProgress write FOnProgress;
    property OnLog: TDaLogEvent read FOnLog write FOnLog;
  end;

{ The wire constants - MTK_PART_..., MTK_STORAGE_..., MTK_HOST_... and
  DA_CMD_... - live in DevTypes, so every protocol unit agrees on one value. }

function StorageKindName(AKind: TMtkStorageKind): string;
function EmptyFlashInfo: TMtkFlashInfo;

implementation

function StorageKindName(AKind: TMtkStorageKind): string;
begin
  case AKind of
    skNor: Result := 'NOR';
    skNand: Result := 'NAND';
    skEmmc: Result := 'eMMC';
    skSdc: Result := 'SD card';
    skUfs: Result := 'UFS';
  else
    Result := 'unknown';
  end;
end;

function EmptyFlashInfo: TMtkFlashInfo;
begin
  Result.Kind := skUnknown;
  Result.FlashSize := 0;
  Result.Boot1Size := 0;
  Result.Boot2Size := 0;
  Result.RpmbSize := 0;
  Result.UserAreaSize := 0;
  Result.SdcSize := 0;
  Result.NandPageSize := 0;
  Result.NandSpareSize := 0;
  Result.Cid := '';
  Result.FirmwareVersion := '';
  Result.ExtRamType := 0;
  Result.ExtRamSize := 0;
  Result.InternalSramSize := 0;
end;

{ -------------------------------------------------------------- TMtkDaLegacy }

constructor TMtkDaLegacy.Create(ABrom: TBromProtocol; ATransport: TCommTransport);
begin
  inherited Create;
  FBrom := ABrom;
  FTransport := ATransport;
  FInfo := EmptyFlashInfo;
  FConnected := False;
  FCancelled := False;
  FLastError := '';
  FPacketSize := $100000;   { 1 MiB, what the vendor tools use }
  FSimulated := False;
end;

procedure TMtkDaLegacy.Cancel;
begin
  FCancelled := True;
end;

procedure TMtkDaLegacy.ResetCancel;
begin
  FCancelled := False;
end;

procedure TMtkDaLegacy.DoLog(const AText: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, AText);
end;

procedure TMtkDaLegacy.Progress(ADone, ATotal: Int64);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Self, ADone, ATotal);
end;

{ ------------------------------------------------------------- raw io helpers }

function TMtkDaLegacy.WriteByteRaw(AValue: Byte): Boolean;
begin
  Result := (FTransport <> nil) and (not FCancelled) and
    (FTransport.WriteData(AValue, 1) = 1);
  if not Result then
    FLastError := 'The device stopped accepting data';
end;

function TMtkDaLegacy.WriteBytesRaw(const AData: TBytesArray): Boolean;
var
  N: Integer;
begin
  N := Length(AData);
  if N = 0 then
    Exit(True);
  Result := (FTransport <> nil) and (not FCancelled) and
    (FTransport.WriteData(AData[0], N) = N);
  if not Result then
    FLastError := 'The device stopped accepting data';
end;

function TMtkDaLegacy.WriteWordBe(AValue: Word): Boolean;
var
  D: TBytesArray;
begin
  SetLength(D, 2);
  D[0] := Byte(AValue shr 8);
  D[1] := Byte(AValue and $FF);
  Result := WriteBytesRaw(D);
end;

function TMtkDaLegacy.WriteDwordBe(AValue: UInt32): Boolean;
var
  D: TBytesArray;
begin
  SetLength(D, 4);
  D[0] := Byte(AValue shr 24);
  D[1] := Byte((AValue shr 16) and $FF);
  D[2] := Byte((AValue shr 8) and $FF);
  D[3] := Byte(AValue and $FF);
  Result := WriteBytesRaw(D);
end;

function TMtkDaLegacy.WriteQwordBe(AValue: UInt64): Boolean;
begin
  Result := WriteDwordBe(UInt32(AValue shr 32)) and
    WriteDwordBe(UInt32(AValue and $FFFFFFFF));
end;

function TMtkDaLegacy.ReadBytesRaw(ACount: Integer;
  out AData: TBytesArray): Boolean;
var
  Total, Got: Integer;
  B: Byte;
begin
  SetLength(AData, 0);
  if ACount <= 0 then
    Exit(True);
  SetLength(AData, ACount);
  Total := 0;
  while Total < ACount do
  begin
    if FCancelled then
    begin
      FLastError := 'Cancelled';
      SetLength(AData, 0);
      Exit(False);
    end;
    Got := FTransport.ReadData(B, 1, FBrom.TimeoutMs);
    if Got <> 1 then
    begin
      SetLength(AData, 0);
      FLastError := 'Short read from the download agent: wanted ' +
        IntToStr(ACount) + ' byte(s), got ' + IntToStr(Total);
      Exit(False);
    end;
    AData[Total] := B;
    Inc(Total);
  end;
  Result := True;
end;

function TMtkDaLegacy.ReadDwordBeRaw(out AValue: UInt32): Boolean;
var
  D: TBytesArray;
begin
  AValue := 0;
  if not ReadBytesRaw(4, D) then
    Exit(False);
  AValue := (UInt32(D[0]) shl 24) or (UInt32(D[1]) shl 16) or
    (UInt32(D[2]) shl 8) or UInt32(D[3]);
  Result := True;
end;

function TMtkDaLegacy.WriteAck: Boolean;
begin
  Result := WriteByteRaw(DA_ACK);
end;

{ ------------------------------------------------------------- storage report }

function TMtkDaLegacy.ParseStorageInfo: Boolean;
begin
  Result := ParseLegacyInfo(False);
end;

function TMtkDaLegacy.ParseLegacyInfo(ALastBlock: Boolean): Boolean;
var
  Nor, Nand, Emmc, Sdc, Cfg, Pass: TBytesArray;
  Ids, IdCount, I: Integer;
  DevCodes: TBytesArray;
  Hex: string;
begin
  Result := False;

  { NOR info, 28 bytes. }
  if not ReadBytesRaw(28, Nor) then
    Exit;
  { NAND info, 17 bytes, then 2 bytes per NAND id. }
  if not ReadBytesRaw(17, Nand) then
    Exit;
  IdCount := (Integer(Nand[15]) shl 8) or Integer(Nand[16]);
  if IdCount > 0 then
  begin
    if IdCount > 32 then
      IdCount := 32;
    if not ReadBytesRaw(IdCount * 2, DevCodes) then
      Exit;
  end;
  { NAND info part 2, 9 bytes. }
  if not ReadBytesRaw(9, Nand) then
    Exit
  else
  begin
    FInfo.NandPageSize := (Word(Nand[0]) shl 8) or Word(Nand[1]);
    FInfo.NandSpareSize := (Word(Nand[2]) shl 8) or Word(Nand[3]);
  end;
  { eMMC info, 92 bytes. }
  if not ReadBytesRaw(92, Emmc) then
    Exit;
  { SD info, 28 bytes. }
  if not ReadBytesRaw(28, Sdc) then
    Exit;
  { Configuration info, 38 bytes. }
  if not ReadBytesRaw(38, Cfg) then
    Exit;
  { Pass info, 10 bytes. }
  if not ReadBytesRaw(10, Pass) then
    Exit;

  FInfo.Boot1Size := (UInt64(Emmc[4]) shl 56) or (UInt64(Emmc[5]) shl 48) or
    (UInt64(Emmc[6]) shl 40) or (UInt64(Emmc[7]) shl 32) or
    (UInt64(Emmc[8]) shl 24) or (UInt64(Emmc[9]) shl 16) or
    (UInt64(Emmc[10]) shl 8) or UInt64(Emmc[11]);
  FInfo.Boot2Size := (UInt64(Emmc[12]) shl 56) or (UInt64(Emmc[13]) shl 48) or
    (UInt64(Emmc[14]) shl 40) or (UInt64(Emmc[15]) shl 32) or
    (UInt64(Emmc[16]) shl 24) or (UInt64(Emmc[17]) shl 16) or
    (UInt64(Emmc[18]) shl 8) or UInt64(Emmc[19]);
  FInfo.RpmbSize := (UInt64(Emmc[20]) shl 56) or (UInt64(Emmc[21]) shl 48) or
    (UInt64(Emmc[22]) shl 40) or (UInt64(Emmc[23]) shl 32) or
    (UInt64(Emmc[24]) shl 24) or (UInt64(Emmc[25]) shl 16) or
    (UInt64(Emmc[26]) shl 8) or UInt64(Emmc[27]);
  { gp1..gp4 occupy 28..59, user area 60..67. }
  FInfo.UserAreaSize := (UInt64(Emmc[60]) shl 56) or (UInt64(Emmc[61]) shl 48) or
    (UInt64(Emmc[62]) shl 40) or (UInt64(Emmc[63]) shl 32) or
    (UInt64(Emmc[64]) shl 24) or (UInt64(Emmc[65]) shl 16) or
    (UInt64(Emmc[66]) shl 8) or UInt64(Emmc[67]);
  Hex := '';
  for I := 68 to 83 do
    Hex := Hex + IntToHex(Emmc[I], 2);
  FInfo.Cid := Hex;
  Hex := '';
  for I := 84 to 91 do
    Hex := Hex + IntToHex(Emmc[I], 2);
  FInfo.FirmwareVersion := Hex;

  FInfo.SdcSize := (UInt64(Sdc[4]) shl 56) or (UInt64(Sdc[5]) shl 48) or
    (UInt64(Sdc[6]) shl 40) or (UInt64(Sdc[7]) shl 32) or
    (UInt64(Sdc[8]) shl 24) or (UInt64(Sdc[9]) shl 16) or
    (UInt64(Sdc[10]) shl 8) or UInt64(Sdc[11]);

  FInfo.InternalSramSize := (UInt32(Cfg[4]) shl 24) or (UInt32(Cfg[5]) shl 16) or
    (UInt32(Cfg[6]) shl 8) or UInt32(Cfg[7]);
  FInfo.ExtRamType := Cfg[12];
  FInfo.ExtRamSize := (UInt64(Cfg[14]) shl 56) or (UInt64(Cfg[15]) shl 48) or
    (UInt64(Cfg[16]) shl 40) or (UInt64(Cfg[17]) shl 32) or
    (UInt64(Cfg[18]) shl 24) or (UInt64(Cfg[19]) shl 16) or
    (UInt64(Cfg[20]) shl 8) or UInt64(Cfg[21]);

  Ids := (Integer(Nand[6]) shl 8) or Integer(Nand[7]);
  if Ids <> 0 then
    FInfo.Kind := skNand
  else if FInfo.UserAreaSize <> 0 then
    FInfo.Kind := skEmmc
  else if FInfo.SdcSize <> 0 then
    FInfo.Kind := skSdc
  else
    FInfo.Kind := skNor;

  case FInfo.Kind of
    skNand: FInfo.FlashSize := (UInt64(Nand[7]) shl 56) or
      (UInt64(Nand[8]) shl 48) or (UInt64(Nand[9]) shl 40) or
      (UInt64(Nand[10]) shl 32) or (UInt64(Nand[11]) shl 24) or
      (UInt64(Nand[12]) shl 16) or (UInt64(Nand[13]) shl 8) or
      UInt64(Nand[14]);
    skEmmc: FInfo.FlashSize := FInfo.UserAreaSize;
    skSdc: FInfo.FlashSize := FInfo.SdcSize;
  else
    FInfo.FlashSize := (UInt64(Nor[12]) shl 24) or (UInt64(Nor[13]) shl 16) or
      (UInt64(Nor[14]) shl 8) or UInt64(Nor[15]);
  end;

  if Pass[0] <> DA_ACK then
  begin
    FLastError := 'The download agent rejected the storage report (pass byte $' +
      IntToHex(Pass[0], 2) + ')';
    Exit;
  end;
  Result := True;
end;

{ ------------------------------------------------------------------ bring-up }

function TMtkDaLegacy.StorageByte: Byte;
begin
  case FInfo.Kind of
    skNor: Result := MTK_STORAGE_NOR;
    skNand: Result := MTK_STORAGE_NAND;
    skSdc: Result := MTK_STORAGE_SDC;
    skUfs: Result := MTK_STORAGE_UFS;
  else
    Result := MTK_STORAGE_EMMC;
  end;
end;

function TMtkDaLegacy.PartTypeByte(APartition: Integer): Byte;
begin
  if (APartition < 0) or (APartition > 255) then
    Result := MTK_PART_USER
  else
    Result := Byte(APartition);
end;

function TMtkDaLegacy.Stage2ConfigBytes: TBytesArray;
var
  P: Integer;
  Kind, I: Integer;
  Chip: TMtkChipInfo;
begin
  { bromver, blver, nor chip (BE16), nor chip select, nand acccon (BE32),
    bmt flag, bmt part size (BE32), force charge, reset keys, ext clock,
    msdc boot channel - then the chip-specific extra block. }
  Kind := Stage2ExtraKind(FBrom.HwCode);
  SetLength(Result, 14 + Stage2ExtraSize(Kind));
  for I := 0 to High(Result) do
    Result[I] := 0;
  P := 0;
  Result[P] := Byte(FBrom.BromVer); Inc(P);
  Result[P] := Byte(FBrom.BlVer); Inc(P);
  Result[P] := $00; Result[P + 1] := $08; Inc(P, 2);   { m_nor_chip }
  Result[P] := $00; Inc(P);                            { m_nor_chip_select }
  Result[P] := $70; Result[P + 1] := $07;
  Result[P + 2] := $FF; Result[P + 3] := $FF; Inc(P, 4); { nand acccon }

  Chip := FBrom.Chip;
  if (FBrom.HwCode = $6592) or (FBrom.HwCode = $8127) or
     (FBrom.HwCode = $6571) then
  begin
    Result[P] := $01;                                  { bmt flag }
    Result[P + 1] := $00; Result[P + 2] := $15;
    Result[P + 3] := $00; Result[P + 4] := $00; Inc(P, 5);
  end
  else
  begin
    Result[P] := $01;                                  { bmt flag }
    Result[P + 1] := $00; Result[P + 2] := $00;
    Result[P + 3] := $00; Result[P + 4] := $00; Inc(P, 5);
  end;
  if Chip.MiscLock = 0 then
    Result[P - 5] := $01;

  Result[P] := $01; Inc(P);                            { force charge: on }
  if FBrom.HwCode = $6583 then
    Result[P] := $00
  else
    Result[P] := $01;                                  { reset keys }
  Inc(P);
  Result[P] := $02; Inc(P);                            { ext clock: 26 MHz }
  Result[P] := $00; Inc(P);                            { msdc boot channel }

  case Kind of
    MTK_STAGE2_EXTRA_GPT:
      begin
        Result[P] := 0; Result[P + 1] := 0;
        Result[P + 2] := 0; Result[P + 3] := 0;
      end;
    MTK_STAGE2_EXTRA_SLC:
      begin
        Result[P + 3] := $01;                          { slc percent }
        Result[P + 4] := $46; Result[P + 5] := $46;
        Result[P + 20] := $FF;
      end;
    MTK_STAGE2_EXTRA_DRAM:
      if FBrom.HwCode = $6589 then
        Result[P + 3] := $01;
    MTK_STAGE2_EXTRA_SKIPDL:
      begin
        Result[P + 3] := $00;
        Result[P + 7] := $00;
      end;
    MTK_STAGE2_EXTRA_COMBO:
      Result[P + 3] := $01;
  end;
end;

function TMtkDaLegacy.Connect(ADa: TDaImage): Boolean;
var
  Sync: TBytesArray;
  Ack3: TBytesArray;
  Cfg: TBytesArray;
  DramInfo: UInt32;
  Da2: TBytesArray;
  Da2Addr: UInt32;
  Packet, Pos, N: Integer;
  Speed: TBytesArray;
  Ok: Boolean;
begin
  Result := False;
  FLastError := '';
  FConnected := False;
  if FTransport = nil then
  begin
    FLastError := 'No transport';
    Exit;
  end;

  { 1. Sync byte. }
  if not ReadBytesRaw(1, Sync) then
  begin
    FLastError := 'The download agent did not start (no sync byte). ' + FLastError;
    Exit;
  end;
  if Sync[0] <> DA_SYNC then
  begin
    FLastError := 'Download agent sync failed: got $' + IntToHex(Sync[0], 2) +
      ' instead of $C0';
    Exit;
  end;
  DoLog('Download agent sync ($C0) received.');

  if ADa = nil then
  begin
    { A DA that answers the flash commands straight away. }
    FConnected := True;
    Result := True;
    Exit;
  end;

  { 2. First storage report. }
  if not ParseLegacyInfo(False) then
  begin
    if FLastError = '' then
      FLastError := 'Could not read the storage report from the download agent';
    Exit;
  end;
  DoLog('Storage report 1: ' + StorageKindName(FInfo.Kind) + ', ' +
    IntToStr(FInfo.FlashSize div (1024 * 1024)) + ' MiB');

  { 3. Ack and read three bytes. }
  if not WriteAck then
    Exit;
  if not ReadBytesRaw(3, Ack3) then
    Exit;

  { 4. Stage-2 configuration. }
  Cfg := Stage2ConfigBytes;
  if not WriteBytesRaw(Cfg) then
    Exit;
  Sleep(350);
  if not ReadDwordBeRaw(DramInfo) then
    Exit;
  if DramInfo = $BC3 then
  begin
    FLastError := 'The download agent needs the EMI/DRAM configuration from ' +
      'the matching preloader ($BC3). Select the preloader for this exact ' +
      'board in the Files box and try again.';
    DoLog(FLastError);
    Exit;
  end;
  if DramInfo <> 0 then
  begin
    FLastError := 'Stage-2 configuration failed: ' + StatusText(Word(DramInfo));
    Exit;
  end;
  DoLog('Stage-2 configuration accepted (DRAM already initialised).');

  { 5. Upload stage 2. }
  Da2 := ADa.Stage2Data;
  Da2Addr := ADa.Stage2Address;
  if Length(Da2) = 0 then
  begin
    FLastError := 'The download agent has no stage 2 region to upload';
    Exit;
  end;
  DoLog('Uploading stage 2: ' + IntToStr(Length(Da2)) + ' bytes to $' +
    IntToHex(Da2Addr, 8));
  if not WriteDwordBe(Da2Addr) then
    Exit;
  if not WriteDwordBe(UInt32(Length(Da2))) then
    Exit;
  Packet := $1000;
  if not WriteDwordBe(UInt32(Packet)) then
    Exit;
  if not ReadBytesRaw(1, Sync) then
    Exit;
  if Sync[0] <> DA_ACK then
  begin
    FLastError := 'Stage-2 upload refused ($' + IntToHex(Sync[0], 2) + ')';
    Exit;
  end;
  Pos := 0;
  while Pos < Length(Da2) do
  begin
    if FCancelled then
    begin
      FLastError := 'Cancelled';
      Exit;
    end;
    N := Length(Da2) - Pos;
    if N > Packet then
      N := Packet;
    SetLength(Cfg, N);
    Move(Da2[Pos], Cfg[0], N);
    if not WriteBytesRaw(Cfg) then
      Exit;
    if not ReadBytesRaw(1, Sync) then
      Exit;
    if Sync[0] <> DA_ACK then
    begin
      FLastError := 'Stage-2 packet at offset ' + IntToStr(Pos) +
        ' was refused ($' + IntToHex(Sync[0], 2) + ')';
      Exit;
    end;
    Inc(Pos, N);
    Progress(Pos, Length(Da2));
  end;
  Sleep(500);
  if not WriteAck then
    Exit;
  if not ReadBytesRaw(1, Sync) then
    Exit;
  if Sync[0] <> DA_ACK then
  begin
    FLastError := 'Stage 2 did not start ($' + IntToHex(Sync[0], 2) + ')';
    Exit;
  end;
  DoLog('Stage 2 uploaded and running.');

  { 6. Second storage report - now with the real flash behind stage 2. }
  FInfo := EmptyFlashInfo;
  if not ParseLegacyInfo(True) then
  begin
    if FLastError = '' then
      FLastError := 'Could not read the flash information after stage 2';
    Exit;
  end;
  DoLog('Storage report 2: ' + StorageKindName(FInfo.Kind) + ', ' +
    IntToStr(FInfo.FlashSize div (1024 * 1024)) + ' MiB' +
    ', CID ' + FInfo.Cid);

  { USB speed check. }
  if WriteByteRaw(DA_CMD_USB_CHECK_STATUS) then
  begin
    if ReadBytesRaw(1, Speed) and (Speed[0] = DA_ACK) then
    begin
      if ReadBytesRaw(1, Speed) then
        DoLog('USB speed class reported by the DA: ' + IntToStr(Speed[0]));
    end;
  end;

  Ok := True;
  FConnected := Ok;
  Result := Ok;
end;

{ ------------------------------------------------------------- flash access }

function TMtkDaLegacy.ReadFlashBytes(AAddr, ALength: UInt64;
  out AData: TBytesArray; APartition: Integer): Boolean;
var
  MS: TMemoryStream;
  N: Int64;
begin
  SetLength(AData, 0);
  MS := TMemoryStream.Create;
  try
    Result := ReadFlash(AAddr, ALength, MS, APartition);
    if Result then
    begin
      N := MS.Size;
      SetLength(AData, N);
      if N > 0 then
      begin
        MS.Position := 0;
        MS.ReadBuffer(AData[0], N);
      end;
    end;
  finally
    MS.Free;
  end;
end;

function TMtkDaLegacy.ReadFlash(AAddr, ALength: UInt64; AOut: TStream;
  APartition: Integer): Boolean;
var
  Packet: TBytesArray;
  Ack: TBytesArray;
  Chunk: UInt64;
  N, I: Integer;
  Done: UInt64;
  Sum, Check: Word;
begin
  Result := False;
  FLastError := '';
  if not FConnected then
  begin
    FLastError := 'Not connected to the download agent';
    Exit;
  end;
  if ALength = 0 then
  begin
    FLastError := 'Nothing to read: the length is 0';
    Exit;
  end;
  if (FInfo.FlashSize > 0) and (AAddr + ALength > FInfo.FlashSize) then
  begin
    FLastError := 'Read range $' + IntToHex(AAddr, 8) + ' + ' +
      IntToStr(ALength) + ' bytes is past the end of the ' +
      StorageKindName(FInfo.Kind) + ' (' + IntToStr(FInfo.FlashSize) + ' bytes)';
    Exit;
  end;

  { Switch to the wanted hardware partition first. }
  if StorageByte = MTK_STORAGE_EMMC then
  begin
    if not WriteByteRaw(DA_CMD_SDMMC_SWITCH_PART) then
      Exit;
    if not ReadBytesRaw(1, Ack) then
      Exit;
    if Ack[0] <> DA_ACK then
    begin
      FLastError := 'Switching to partition ' + IntToStr(APartition) +
        ' was refused';
      Exit;
    end;
    if not WriteByteRaw(PartTypeByte(APartition)) then
      Exit;
    if not ReadBytesRaw(1, Ack) then
      Exit;
    if Ack[0] <> DA_ACK then
    begin
      FLastError := 'Partition ' + IntToStr(APartition) + ' is not available';
      Exit;
    end;
  end;

  if not WriteByteRaw(DA_CMD_READ) then
    Exit;
  if not WriteByteRaw(MTK_HOST_WINDOWS) then
    Exit;
  if not WriteByteRaw(StorageByte) then
    Exit;
  if not WriteQwordBe(AAddr) then
    Exit;
  if not WriteQwordBe(ALength) then
    Exit;
  if not WriteDwordBe(UInt32(FPacketSize)) then
    Exit;
  if not ReadBytesRaw(1, Ack) then
    Exit;
  if Ack[0] <> DA_ACK then
  begin
    FLastError := 'The download agent refused the read (answer $' +
      IntToHex(Ack[0], 2) + ')';
    Exit;
  end;

  Done := 0;
  while Done < ALength do
  begin
    if FCancelled then
    begin
      FLastError := 'Cancelled';
      Exit;
    end;
    Chunk := ALength - Done;
    if Chunk > UInt64(FPacketSize) then
      Chunk := UInt64(FPacketSize);
    N := Integer(Chunk);
    if not ReadBytesRaw(N, Packet) then
      Exit;
    { Two checksum bytes follow each packet. }
    if not ReadBytesRaw(2, Ack) then
      Exit;
    { The DA sends a big-endian sum of the packet bytes; verify it and log a
      mismatch instead of silently keeping corrupt data. }
    Sum := (Word(Ack[0]) shl 8) or Word(Ack[1]);
    Check := 0;
    for I := 0 to N - 1 do
      Check := Word(Check + Word(Packet[I])) and $FFFF;
    if (Sum <> 0) and (Sum <> Check) then
      DoLog('Warning: packet checksum at offset ' + IntToStr(Done) +
        ' is $' + IntToHex(Sum, 4) + ', computed $' + IntToHex(Check, 4));
    AOut.Write(Packet[0], N);
    Inc(Done, UInt64(N));
    Progress(Int64(Done), Int64(ALength));
    if not WriteAck then
      Exit;
  end;
  Result := True;
end;

function TMtkDaLegacy.WriteFlash(AAddr, ALength: UInt64; AIn: TStream;
  AOffset: Int64; APartition: Integer): Boolean;
var
  Packet: TBytesArray;
  Ack: TBytesArray;
  Chunk: UInt64;
  N, I: Integer;
  Done: UInt64;
  Sum: Word;
begin
  Result := False;
  FLastError := '';
  if not FConnected then
  begin
    FLastError := 'Not connected to the download agent';
    Exit;
  end;
  if ALength = 0 then
  begin
    FLastError := 'Nothing to write: the length is 0';
    Exit;
  end;
  if (FInfo.FlashSize > 0) and (AAddr + ALength > FInfo.FlashSize) then
  begin
    FLastError := 'Write range is past the end of the ' +
      StorageKindName(FInfo.Kind);
    Exit;
  end;

  if StorageByte = MTK_STORAGE_EMMC then
  begin
    if not WriteByteRaw(DA_CMD_SDMMC_SWITCH_PART) then
      Exit;
    if not ReadBytesRaw(1, Ack) then
      Exit;
    if Ack[0] <> DA_ACK then
    begin
      FLastError := 'Switching to partition ' + IntToStr(APartition) +
        ' was refused';
      Exit;
    end;
    if not WriteByteRaw(PartTypeByte(APartition)) then
      Exit;
    if not ReadBytesRaw(1, Ack) then
      Exit;
    if Ack[0] <> DA_ACK then
    begin
      FLastError := 'Partition ' + IntToStr(APartition) + ' is not available';
      Exit;
    end;
  end;

  if not WriteByteRaw(DA_CMD_SDMMC_WRITE_DATA) then
    Exit;
  if not WriteByteRaw(StorageByte) then
    Exit;
  if not WriteByteRaw(PartTypeByte(APartition)) then
    Exit;
  if not WriteQwordBe(AAddr) then
    Exit;
  if not WriteQwordBe(ALength) then
    Exit;
  if not WriteDwordBe(UInt32(FPacketSize)) then
    Exit;
  if not ReadBytesRaw(1, Ack) then
    Exit;
  if Ack[0] <> DA_ACK then
  begin
    FLastError := 'The download agent refused the write (answer $' +
      IntToHex(Ack[0], 2) + ')';
    Exit;
  end;

  AIn.Position := AOffset;
  Done := 0;
  while Done < ALength do
  begin
    if FCancelled then
    begin
      FLastError := 'Cancelled';
      Exit;
    end;
    if not WriteAck then
      Exit;
    Chunk := ALength - Done;
    if Chunk > UInt64(FPacketSize) then
      Chunk := UInt64(FPacketSize);
    N := Integer(Chunk);
    SetLength(Packet, N);
    if AIn.Read(Packet[0], N) <> N then
    begin
      FLastError := 'The source file ended after ' + IntToStr(Done) + ' bytes';
      Exit;
    end;
    { Pad to a 512-byte boundary, as the DA expects. }
    if (N mod 512) <> 0 then
    begin
      SetLength(Packet, N + (512 - (N mod 512)));
      for I := N to High(Packet) do
        Packet[I] := 0;
      N := Length(Packet);
    end;
    Sum := 0;
    for I := 0 to N - 1 do
      Sum := Word(Sum + Word(Packet[I])) and $FFFF;
    if not WriteBytesRaw(Packet) then
      Exit;
    if not WriteWordBe(Sum) then
      Exit;
    if not ReadBytesRaw(1, Ack) then
      Exit;
    Inc(Done, Chunk);
    Progress(Int64(Done), Int64(ALength));
    if Done >= ALength then
    begin
      if Ack[0] <> DA_ACK then
      begin
        FLastError := 'The last write packet was refused ($' +
          IntToHex(Ack[0], 2) + ')';
        Exit;
      end;
    end
    else if Ack[0] <> DA_CONT then
    begin
      FLastError := 'The download agent stopped the write after ' +
        IntToStr(Done) + ' bytes (answer $' + IntToHex(Ack[0], 2) + ')';
      Exit;
    end;
  end;
  Result := True;
end;

function TMtkDaLegacy.FormatFlash(AAddr, ALength: UInt64;
  APartition: Integer): Boolean;
var
  Ack: TBytesArray;
  Percent: Byte;
  ProgressBytes: UInt32;
begin
  Result := False;
  FLastError := '';
  if not FConnected then
  begin
    FLastError := 'Not connected to the download agent';
    Exit;
  end;
  if ALength = 0 then
  begin
    FLastError := 'Nothing to format: the length is 0';
    Exit;
  end;

  if StorageByte = MTK_STORAGE_EMMC then
  begin
    if not WriteByteRaw(DA_CMD_SDMMC_SWITCH_PART) then
      Exit;
    if not ReadBytesRaw(1, Ack) then
      Exit;
    if Ack[0] <> DA_ACK then
    begin
      FLastError := 'Switching to partition ' + IntToStr(APartition) +
        ' was refused';
      Exit;
    end;
    if not WriteByteRaw(PartTypeByte(APartition)) then
      Exit;
    if not ReadBytesRaw(1, Ack) then
      Exit;
    if Ack[0] <> DA_ACK then
    begin
      FLastError := 'Partition ' + IntToStr(APartition) + ' is not available';
      Exit;
    end;
  end;

  if not WriteByteRaw(DA_CMD_FORMAT) then
    Exit;
  if not WriteByteRaw(StorageByte) then
    Exit;
  if not WriteByteRaw($00) then      { NUTIL erase }
    Exit;
  if not WriteByteRaw($00) then      { no validation }
    Exit;
  if not WriteByteRaw($00) then      { logical addressing }
    Exit;
  if not WriteQwordBe(AAddr) then
    Exit;
  if not WriteQwordBe(ALength) then
    Exit;

  Percent := 0;
  while Percent < 100 do
  begin
    if FCancelled then
    begin
      FLastError := 'Cancelled';
      Exit;
    end;
    if not ReadBytesRaw(1, Ack) then
      Exit;
    if Ack[0] <> DA_ACK then
    begin
      FLastError := 'Format refused (answer $' + IntToHex(Ack[0], 2) + ')';
      Exit;
    end;
    if not ReadBytesRaw(1, Ack) then
      Exit;
    if Ack[0] <> DA_ACK then
    begin
      FLastError := 'Format refused (answer $' + IntToHex(Ack[0], 2) + ')';
      Exit;
    end;
    if not ReadBytesRaw(4, Ack) then     { PROGRESS_INIT }
      Exit;
    ProgressBytes := (UInt32(Ack[0]) shl 24) or (UInt32(Ack[1]) shl 16) or
      (UInt32(Ack[2]) shl 8) or UInt32(Ack[3]);
    if not ReadBytesRaw(1, Ack) then
      Exit;
    Percent := Ack[0];
    Progress(Int64(Percent), 100);
    if not WriteAck then
      Exit;
    if Percent = 100 then
    begin
      if not ReadBytesRaw(1, Ack) then
        Exit;
      if Ack[0] <> DA_ACK then
      begin
        FLastError := 'Format did not complete (answer $' +
          IntToHex(Ack[0], 2) + ')';
        Exit;
      end;
      if not ReadBytesRaw(1, Ack) then
        Exit;
      if Ack[0] <> DA_ACK then
      begin
        FLastError := 'Format did not complete (answer $' +
          IntToHex(Ack[0], 2) + ')';
        Exit;
      end;
    end;
  end;
  DoLog('Formatted ' + IntToStr(ALength) + ' bytes at $' +
    IntToHex(AAddr, 8));
  Result := True;
end;

function TMtkDaLegacy.Shutdown(ABootMode: Integer): Boolean;
begin
  Result := False;
  if not WriteByteRaw(DA_CMD_FINISH) then
    Exit;
  if not WriteAck then
    Exit;
  Result := True;
  { The device answers with an ack, then disconnects. Reading it is optional:
    the port is going away either way. }
end;

end.
