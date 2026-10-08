unit SimPort;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

{ A simulated MediaTek phone.

  Why this exists
  ---------------
  The capture / lock / handshake / download-agent / flash pipeline has to be
  provably correct, but a CI runner has no phone plugged in. TSimPort is an
  in-process transport that answers with the real protocol: the A0 0A 50 05
  handshake and its complement, command echo, GET_HW_CODE, GET_TARGET_CONFIG,
  READ32 / WRITE32, SEND_DA with checksum verification, JUMP_DA, the DA sync
  byte, the legacy storage-info dumps, the stage-2 upload and the legacy flash
  read / write / format commands against a simulated eMMC.

  So the exact same host code that drives a real phone runs end to end on
  every build. Everything it produces is flagged Simulated = True and the log
  says so, so a simulated run can never be mistaken for a real one.

  It also models the thing this app is about: the port is held exclusively.
  CreateSimTransport refuses to hand out a second live instance, exactly like
  Windows refuses a second CreateFile on a COM port somebody already owns.

  Byte-level state machine
  ------------------------
  FPayloadLeft > 0  : a SEND_DA / SEND_AUTH / stage-2 packet is streaming in.
  FCollectLeft > 0  : the next N bytes are an argument block, echoed back
                      when FEchoCollect is set; FOnCollect says what to do
                      when it is full.
  FWriteLeft > 0    : a flash write packet is streaming in.
  FAwait <> awNone  : exactly one byte is expected that is NOT a command
                      (the host's ACK before each write packet, or before
                      each format progress step). This matters because in the
                      DA phase $5A would otherwise be indistinguishable from a
                      command byte.
  otherwise         : the byte is a command. }

interface

uses
{$IFDEF FPC}
  Classes, SysUtils, StrUtils,
{$ELSE}
  System.Classes,
  System.SysUtils,
  System.StrUtils,
{$ENDIF}
  DevTypes, CommPort, BromProtocol;

const
  CSimFlashSize = 16 * 1024 * 1024;   { simulated eMMC user area }
  CSimMemorySize = 4 * 1024 * 1024;   { simulated addressable memory window }
  CSimMemoryBase = $00200000;

  { MTK_STAGE2_EXTRA_* and Stage2ExtraKind/Size live in DevTypes, so the host
    side (MtkDaLegacy) and this simulated device share one table. }

type
  TSimPhase = (spBootRom, spDa);

  { What the argument collector runs once it is full. }
  TSimCollect = (
    scNone,
    { BROM }
    scReadAddr, scReadCount, scWriteAddr, scWriteCount, scWriteValues,
    scDaAddr, scDaSize, scDaSigLen, scDaPayload,
    scJumpAddr, scJump64Addr, scJump64Flag,
    scAuthLen, scAuthPayload, scCertLen, scCertPayload,
    { legacy DA }
    scUsbSetupMode, scSwitchPart,
    scWriteHeader, scWriteData,
    scReadHeader,
    scFormatHeader,
    scStage2Config, scStage2Addr, scStage2Size, scStage2PacketSize,
    scStage2Packet, scFinishValue);

  { A single non-command byte we are waiting for. }
  TSimAwait = (awNone, awWriteAck, awFormatAck, awReadFinalAck,
    awStage2FinalAck);

  TSimPort = class(TCommTransport)
  private
    FOpen: Boolean;
    FInBuf: TBytesArray;   { answers waiting to be read by the host }
    FInLen: Integer;
    FOutPos: Integer;

    FPhase: TSimPhase;
    FHandshakeIndex: Integer;
    FInHandshake: Boolean;

    FPendingCmd: Byte;
    FOnCollect: TSimCollect;
    FCollect: TBytesArray;
    FCollectLen: Integer;
    FCollectLeft: Integer;
    FEchoCollect: Boolean;

    FPayload: TBytesArray;
    FPayloadLeft: Integer;
    FPayloadPos: Integer;
    FPayloadKind: TSimCollect;

    FAwait: TSimAwait;

    FHwCode: Word;
    FHwVer: Word;
    FBromVer: Byte;
    FTargetConfig: UInt32;
    FDemandSla: Boolean;

    FMem: TBytesArray;
    FFlash: TBytesArray;
    FMemBase: UInt32;

    FBromAddr: UInt32;
    FBromWriteIs16: Boolean;
    FDaAddress: UInt32;
    FDaSize: Integer;
    FDaSigLen: Integer;
    FSwitchedPart: Byte;
    FFullDa: Boolean;
    FStage2Address: UInt32;
    FStage2Size: Integer;
    FStage2Packet: Integer;
    FStage2Done: Integer;

    FWriteAddr: UInt64;
    FWriteLength: UInt64;
    FWritePacket: Integer;
    FWriteDone: UInt64;
    FWriteLeft: Integer;
    FWriteChunkPos: Integer;

    FReadAddr: UInt64;
    FReadLength: UInt64;
    FReadPacket: Integer;
    FReadDone: UInt64;

    FFormatAddr: UInt64;
    FFormatLength: UInt64;
    FFormatStep: Integer;

    FBytesIn: Int64;
    FBytesOut: Int64;

    procedure Emit(AByte: Byte);
    procedure EmitBytes(const AData: TBytesArray);
    procedure EmitRepeat(AByte: Byte; ACount: Integer);
    procedure EmitWordBe(AValue: Word);
    procedure EmitDwordBe(AValue: UInt32);
    procedure EmitQwordBe(AValue: UInt64);
    procedure EmitStatus(AStatus: Word);
    procedure EmitAck;
    procedure EmitNack;
    procedure EmitCont;

    procedure StartCollect(AKind: TSimCollect; ACount: Integer; AEcho: Boolean);
    procedure StartPayload(AKind: TSimCollect; ACount: Integer);
    procedure CollectByte(B: Byte);
    procedure PayloadByte(B: Byte);
    procedure CollectDone;
    procedure PayloadDone;
    procedure AwaitByte(B: Byte);

    procedure HandleCommand(B: Byte);
    procedure HandleBromCommand(B: Byte);
    procedure HandleDaCommand(B: Byte);
    procedure EmitHandshakeAnswer(B: Byte);
    procedure EnterDa;
    procedure EmitLegacyStorageInfo;
    procedure EmitReadPacket;
    procedure EmitFormatStep;
    procedure MemoryRead(AAddr: UInt32; ADwords: Integer);
    procedure MemoryWrite(AAddr: UInt32; const AValues: TBytesArray);
    function CollectDwordBe(AOffset: Integer): UInt32;
    function CollectQwordBe(AOffset: Integer): UInt64;
    function PayloadChecksum: Word;
    function FlashByte(AOffset: UInt64): Byte;
    procedure SetFlashByte(AOffset: UInt64; AValue: Byte);
    procedure Compact;
  public
    constructor Create;
    destructor Destroy; override;

    function OpenPort(out AError: string): Boolean; override;
    procedure ClosePort; override;
    function PortOpen: Boolean; override;
    function WriteData(const AData; ACount: Integer): Integer; override;
    function ReadData(var ABuffer; ACount, ATimeoutMs: Integer): Integer; override;
    function PortName: string; override;
    function IsSimulated: Boolean; override;

    { The simulated chip. Defaults to hwcode $0706 = MT6765 / MT8768t
      (Helio P35/G35), one of the most common service cases. }
    property HwCode: Word read FHwCode write FHwCode;
    property HwVer: Word read FHwVer write FHwVer;
    property BromVersion: Byte read FBromVer write FBromVer;
    { Security flags answered by GET_TARGET_CONFIG. Default $61: SBC plus
      memory read and memory write allowed, no SLA and no DAA, so the whole
      pipeline can run without vendor keys. }
    property TargetConfig: UInt32 read FTargetConfig write FTargetConfig;
    { True makes the device demand SLA, to check that the app reports it
      honestly instead of pretending to continue. }
    property DemandSla: Boolean read FDemandSla write FDemandSla;
    { True makes the DA run the full legacy bring-up (storage info dumps and
      stage-2 upload) instead of going straight to the flash commands. }
    property FullDaSequence: Boolean read FFullDa write FFullDa;

    property Phase: TSimPhase read FPhase;
    property Flash: TBytesArray read FFlash;
    property Memory: TBytesArray read FMem;
    property MemoryBase: UInt32 read FMemBase write FMemBase;
    property DaAddress: UInt32 read FDaAddress;
    property DaSize: Integer read FDaSize;
    property Stage2Address: UInt32 read FStage2Address;
    property Stage2Uploaded: Integer read FStage2Done;
    property SwitchedPartition: Byte read FSwitchedPart;
    property BytesIn: Int64 read FBytesIn;
    property BytesOut: Int64 read FBytesOut;
  end;

{ Factory installed into DevCapture for the no-hardware path. }
function CreateSimTransport: TCommTransport;
{ True while a simulated port is live - models the exclusive lock. }
function SimPortInUse: Boolean;
procedure ResetSimPortGuard;

{ Builds a small download agent with a valid header and two stages, so the
  whole stage-1 / stage-2 path can be exercised without a vendor binary. }
function BuildSyntheticDa(AHwCode: Word): TBytesArray;

{ Settings the next simulated device is created with. The self-test turns
  GSimFullDaSequence on so the storage report, the stage-2 configuration and
  the stage-2 upload are all exercised, and GSimDemandSla on to check that the
  app reports a secure-link demand instead of pretending to continue. }
var
  GSimDemandSla: Boolean = False;
  GSimFullDaSequence: Boolean = False;

{ Writes a scatter file and the image files it names into ADir, describing the
  simulated phone: a 4 MiB boot1, a 16 MiB user area with preloader, lk, boot,
  recovery and userdata. AScatterFile receives the full path of the scatter
  file. Returns False when the files could not be written.

  This is what lets the self-test drive Write Firmware and Read Partitions end
  to end: the job engine resolves every image from the scatter table exactly
  as it would for a real ROM. }
function BuildSimScatter(const ADir: string; out AScatterFile: string): Boolean;

implementation

var
  GSimInUse: Boolean = False;

function SimPortInUse: Boolean;
begin
  Result := GSimInUse;
end;

procedure ResetSimPortGuard;
begin
  GSimInUse := False;
end;

function CreateSimTransport: TCommTransport;
begin
  { Models ERROR_SHARING_VIOLATION: only one owner at a time. }
  if GSimInUse then
  begin
    Result := nil;
    Exit;
  end;
  GSimInUse := True;
  Result := TSimPort.Create;
  Result.DemandSla := GSimDemandSla;
  Result.FullDaSequence := GSimFullDaSequence;
end;

procedure PutLeWord(var AData: TBytesArray; AOffset: Integer; AValue: Word);
begin
  AData[AOffset] := Byte(AValue and $FF);
  AData[AOffset + 1] := Byte(AValue shr 8);
end;

procedure PutLeDword(var AData: TBytesArray; AOffset: Integer; AValue: UInt32);
begin
  AData[AOffset] := Byte(AValue and $FF);
  AData[AOffset + 1] := Byte((AValue shr 8) and $FF);
  AData[AOffset + 2] := Byte((AValue shr 16) and $FF);
  AData[AOffset + 3] := Byte((AValue shr 24) and $FF);
end;

function BuildSyntheticDa(AHwCode: Word): TBytesArray;
const
  CDa1Size = $2000;
  CDa2Size = $4000;
  CSigLen = $100;
  CHeader = 20 + 3 * 20;
var
  I: Integer;
begin
  { A download agent with a complete header region table: entry index 1 is
    stage 1, index 2 is stage 2. This is the shape DaImage.pas parses. }
  SetLength(Result, CHeader + CDa1Size + CDa2Size);
  for I := 0 to High(Result) do
    Result[I] := 0;

  PutLeWord(Result, 0, $8888);        { magic }
  PutLeWord(Result, 2, AHwCode);      { hw code }
  PutLeWord(Result, 4, $0000);        { hw sub code }
  PutLeWord(Result, 6, $CA01);        { hw version }
  PutLeWord(Result, 8, $FFFF);        { sw version }
  PutLeWord(Result, 10, $0000);       { reserved }
  PutLeWord(Result, 12, $0200);       { page size 512 }
  PutLeWord(Result, 14, $0000);       { reserved }
  PutLeWord(Result, 16, 1);           { entry region index }
  PutLeWord(Result, 18, 3);           { entry region count }

  { Region 0: environment block, never uploaded. }
  PutLeDword(Result, 20, $00001000);
  PutLeDword(Result, 24, $00000100);
  PutLeDword(Result, 28, $00200000);
  PutLeDword(Result, 32, CHeader);
  PutLeDword(Result, 36, 0);

  { Region 1: stage 1. }
  PutLeDword(Result, 40, $00001000);
  PutLeDword(Result, 44, CDa1Size);
  PutLeDword(Result, 48, $00201000);
  PutLeDword(Result, 52, CHeader);
  PutLeDword(Result, 56, CSigLen);

  { Region 2: stage 2. }
  PutLeDword(Result, 60, $00003000);
  PutLeDword(Result, 64, CDa2Size);
  PutLeDword(Result, 68, $00203000);
  PutLeDword(Result, 72, CHeader + CDa1Size);
  PutLeDword(Result, 76, CSigLen);

  for I := 0 to CDa1Size - 1 do
    Result[CHeader + I] := Byte((I * 7 + 3) and $FF);
  for I := 0 to CDa2Size - 1 do
    Result[CHeader + CDa1Size + I] := Byte((I * 11 + 5) and $FF);
end;

{ ------------------------------------------------------------------- TSimPort }

constructor TSimPort.Create;
var
  I: Integer;
begin
  inherited Create;
  FOpen := False;
  FInLen := 0;
  FOutPos := 0;
  SetLength(FInBuf, 0);

  FPhase := spBootRom;
  FHandshakeIndex := 0;
  FInHandshake := True;

  FPendingCmd := 0;
  FOnCollect := scNone;
  FCollectLen := 0;
  FCollectLeft := 0;
  FEchoCollect := False;
  SetLength(FCollect, 64);
  FPayloadLeft := 0;
  FPayloadPos := 0;
  FPayloadKind := scNone;
  SetLength(FPayload, 0);
  FAwait := awNone;

  FHwCode := $0706;
  FHwVer := $CA01;
  FBromVer := $01;
  FTargetConfig := $00000061;
  FDemandSla := False;

  FMemBase := CSimMemoryBase;
  SetLength(FMem, CSimMemorySize);
  SetLength(FFlash, CSimFlashSize);
  for I := 0 to CSimMemorySize - 1 do
    FMem[I] := 0;
  { A recognisable pattern, so a read back can be verified byte for byte. }
  for I := 0 to CSimFlashSize - 1 do
    FFlash[I] := Byte((I div 512 + I) and $FF);

  FBromAddr := 0;
  FBromWriteIs16 := False;
  FDaAddress := 0;
  FDaSize := 0;
  FDaSigLen := 0;
  FSwitchedPart := 8;
  FFullDa := True;
  FStage2Address := 0;
  FStage2Size := 0;
  FStage2Packet := $1000;
  FStage2Done := 0;

  FWriteAddr := 0;
  FWriteLength := 0;
  FWritePacket := $100000;
  FWriteDone := 0;
  FWriteLeft := 0;
  FWriteChunkPos := 0;

  FReadAddr := 0;
  FReadLength := 0;
  FReadPacket := $100000;
  FReadDone := 0;

  FFormatAddr := 0;
  FFormatLength := 0;
  FFormatStep := 0;

  FBytesIn := 0;
  FBytesOut := 0;
end;

destructor TSimPort.Destroy;
begin
  ClosePort;
  inherited Destroy;
end;

function TSimPort.IsSimulated: Boolean;
begin
  Result := True;
end;

function TSimPort.PortName: string;
begin
  Result := 'SIM';
end;

function TSimPort.OpenPort(out AError: string): Boolean;
begin
  AError := '';
  if GSimInUse and (not FOpen) then
  begin
    { Somebody else already owns it - the same answer Windows gives for a COM
      port held with dwShareMode = 0. }
    AError := 'Sharing violation (32) - the device is locked by another program';
    Result := False;
    Exit;
  end;
  GSimInUse := True;
  FOpen := True;
  Result := True;
end;

procedure TSimPort.ClosePort;
begin
  if FOpen then
  begin
    FOpen := False;
    GSimInUse := False;
  end;
end;

function TSimPort.PortOpen: Boolean;
begin
  Result := FOpen;
end;

{ ---------------------------------------------------------------- output side }

procedure TSimPort.Compact;
var
  I: Integer;
begin
  if FOutPos = 0 then
    Exit;
  if FOutPos >= FInLen then
  begin
    FInLen := 0;
    FOutPos := 0;
    Exit;
  end;
  for I := FOutPos to FInLen - 1 do
    FInBuf[I - FOutPos] := FInBuf[I];
  Dec(FInLen, FOutPos);
  FOutPos := 0;
end;

procedure TSimPort.Emit(AByte: Byte);
begin
  if FInLen >= Length(FInBuf) then
    SetLength(FInBuf, Length(FInBuf) + 131072);
  FInBuf[FInLen] := AByte;
  Inc(FInLen);
end;

procedure TSimPort.EmitBytes(const AData: TBytesArray);
var
  I: Integer;
begin
  for I := 0 to High(AData) do
    Emit(AData[I]);
end;

procedure TSimPort.EmitRepeat(AByte: Byte; ACount: Integer);
var
  I: Integer;
begin
  for I := 1 to ACount do
    Emit(AByte);
end;

procedure TSimPort.EmitWordBe(AValue: Word);
begin
  Emit(Byte(AValue shr 8));
  Emit(Byte(AValue and $FF));
end;

procedure TSimPort.EmitDwordBe(AValue: UInt32);
begin
  Emit(Byte(AValue shr 24));
  Emit(Byte((AValue shr 16) and $FF));
  Emit(Byte((AValue shr 8) and $FF));
  Emit(Byte(AValue and $FF));
end;

procedure TSimPort.EmitQwordBe(AValue: UInt64);
begin
  EmitDwordBe(UInt32(AValue shr 32));
  EmitDwordBe(UInt32(AValue and $FFFFFFFF));
end;

procedure TSimPort.EmitStatus(AStatus: Word);
begin
  EmitWordBe(AStatus);
end;

procedure TSimPort.EmitAck;
begin
  Emit(DA_ACK);
end;

procedure TSimPort.EmitNack;
begin
  Emit(DA_NACK);
end;

procedure TSimPort.EmitCont;
begin
  Emit(DA_CONT);
end;

{ ------------------------------------------------------------------ accessors }

function TSimPort.CollectDwordBe(AOffset: Integer): UInt32;
begin
  Result := (UInt32(FCollect[AOffset]) shl 24) or
    (UInt32(FCollect[AOffset + 1]) shl 16) or
    (UInt32(FCollect[AOffset + 2]) shl 8) or UInt32(FCollect[AOffset + 3]);
end;

function TSimPort.CollectQwordBe(AOffset: Integer): UInt64;
begin
  Result := (UInt64(CollectDwordBe(AOffset)) shl 32) or
    UInt64(CollectDwordBe(AOffset + 4));
end;

function TSimPort.FlashByte(AOffset: UInt64): Byte;
begin
  if AOffset < UInt64(Length(FFlash)) then
    Result := FFlash[AOffset]
  else
    Result := $00;
end;

procedure TSimPort.SetFlashByte(AOffset: UInt64; AValue: Byte);
begin
  if AOffset < UInt64(Length(FFlash)) then
    FFlash[AOffset] := AValue;
end;

function TSimPort.PayloadChecksum: Word;
var
  I: Integer;
begin
  Result := 0;
  I := 0;
  while I + 1 < Length(FPayload) do
  begin
    Result := Result xor (Word(FPayload[I]) or (Word(FPayload[I + 1]) shl 8));
    Inc(I, 2);
  end;
end;

procedure TSimPort.MemoryRead(AAddr: UInt32; ADwords: Integer);
var
  I, Offset: Integer;
  V: UInt32;
begin
  for I := 0 to ADwords - 1 do
  begin
    Offset := Integer(AAddr + UInt32(I * 4)) - Integer(FMemBase);
    if (Offset >= 0) and (Offset + 3 < Length(FMem)) then
      V := (UInt32(FMem[Offset]) shl 24) or (UInt32(FMem[Offset + 1]) shl 16) or
        (UInt32(FMem[Offset + 2]) shl 8) or UInt32(FMem[Offset + 3])
    else
      V := 0;
    EmitDwordBe(V);
  end;
end;

procedure TSimPort.MemoryWrite(AAddr: UInt32; const AValues: TBytesArray);
var
  Offset: Integer;
  V: UInt32;
  J: Integer;
begin
  { Values arrive big-endian, as the host echoed them. The simulated memory is
    byte addressed, so a 16-bit write stores the word big-endian too and a
    32-bit write stores the dword - which is what a read back must return. }
  if FBromWriteIs16 then
  begin
    J := 0;
    while J + 1 < Length(AValues) do
    begin
      V := (UInt32(AValues[J]) shl 8) or UInt32(AValues[J + 1]);
      Offset := Integer(AAddr + UInt32(J)) - Integer(FMemBase);
      if (Offset >= 0) and (Offset + 3 < Length(FMem)) then
      begin
        FMem[Offset] := Byte(V shr 24);
        FMem[Offset + 1] := Byte((V shr 16) and $FF);
        FMem[Offset + 2] := Byte((V shr 8) and $FF);
        FMem[Offset + 3] := Byte(V and $FF);
      end;
      Inc(J, 2);
    end;
    Exit;
  end;
  J := 0;
  while J + 3 < Length(AValues) do
  begin
    V := (UInt32(AValues[J]) shl 24) or (UInt32(AValues[J + 1]) shl 16) or
      (UInt32(AValues[J + 2]) shl 8) or UInt32(AValues[J + 3]);
    Offset := Integer(AAddr + UInt32(J)) - Integer(FMemBase);
    if (Offset >= 0) and (Offset + 3 < Length(FMem)) then
    begin
      FMem[Offset] := Byte(V shr 24);
      FMem[Offset + 1] := Byte((V shr 16) and $FF);
      FMem[Offset + 2] := Byte((V shr 8) and $FF);
      FMem[Offset + 3] := Byte(V and $FF);
    end;
    Inc(J, 4);
  end;
end;

{ ------------------------------------------------------------- legacy DA info }

procedure TSimPort.EmitLegacyStorageInfo;
var
  I: Integer;
begin
  { NOR info, 28 bytes. }
  EmitDwordBe($00000000);
  EmitRepeat($00, 2);
  EmitWordBe($0000);
  EmitDwordBe($00000000);
  EmitWordBe($0000);
  EmitDwordBe($00000000);
  EmitDwordBe($00000000);
  EmitDwordBe($00000000);

  { NAND info, 17 bytes with an id count of 0, so no device codes follow. }
  EmitDwordBe($00000000);
  Emit($00);
  EmitWordBe($0000);
  EmitQwordBe(0);
  EmitWordBe($0000);

  { eMMC info, 92 bytes. A non-zero user-area size is what makes the DA report
    eMMC storage. }
  EmitDwordBe($00000000);
  EmitQwordBe(UInt64(4) * 1024 * 1024);          { boot1 }
  EmitQwordBe(UInt64(4) * 1024 * 1024);          { boot2 }
  EmitQwordBe(UInt64(4) * 1024 * 1024);          { rpmb }
  for I := 0 to 3 do
    EmitQwordBe(0);                              { gp1..gp4 }
  EmitQwordBe(UInt64(Length(FFlash)));           { user area }
  for I := 0 to 15 do
    Emit(Byte($90 + I));                         { CID }
  EmitRepeat($00, 8);                            { firmware version }

  { SDC info, 28 bytes. }
  EmitDwordBe($00000000);
  EmitQwordBe(0);
  EmitQwordBe(0);
  EmitQwordBe(0);

  { Config info, 38 bytes. }
  EmitDwordBe($00000000);
  EmitDwordBe($00040000);
  EmitDwordBe($00000000);
  Emit($01);
  Emit($00);
  EmitQwordBe(UInt64(4) * 1024 * 1024 * 1024);
  EmitQwordBe($1122334455667788);
  EmitQwordBe($99AABBCCDDEEFF00);

  { Pass info, 10 bytes: the ack byte first. }
  Emit(DA_ACK);
  EmitRepeat($00, 9);
end;

procedure TSimPort.EnterDa;
begin
  FPhase := spDa;
  FInHandshake := False;
  FOnCollect := scNone;
  FCollectLeft := 0;
  FPayloadLeft := 0;
  FAwait := awNone;
  Emit(DA_SYNC);
  if FFullDa then
  begin
    EmitLegacyStorageInfo;
    { The host acks the dump, then reads three bytes. }
    Emit(DA_ACK);
    Emit(DA_ACK);
    Emit(DA_ACK);
    { The host now writes the stage-2 configuration; collect the fixed part. }
    StartCollect(scStage2Config, 14 + Stage2ExtraSize(Stage2ExtraKind(FHwCode)),
      False);
  end;
end;

procedure TSimPort.EmitReadPacket;
var
  N, I: Integer;
  Sum: Word;
  B: Byte;
begin
  if FReadDone >= FReadLength then
    Exit;
  N := FReadPacket;
  if Int64(N) > Int64(FReadLength) - Int64(FReadDone) then
    N := Integer(Int64(FReadLength) - Int64(FReadDone));
  Sum := 0;
  for I := 0 to N - 1 do
  begin
    B := FlashByte(FReadAddr + UInt64(FReadDone) + UInt64(I));
    Emit(B);
    Sum := Word(Sum + Word(B));
  end;
  EmitWordBe(Sum);
  Inc(FReadDone, UInt64(N));
end;

procedure TSimPort.EmitFormatStep;
var
  Progress: Byte;
  I: Integer;
begin
  { Zero the simulated region once, then report progress in 10 % steps. }
  if FFormatStep = 0 then
  begin
    I := 0;
    while (UInt64(I) < FFormatLength) and
          (FFormatAddr + UInt64(I) < UInt64(Length(FFlash))) do
    begin
      FFlash[FFormatAddr + UInt64(I)] := $00;
      Inc(I, 4096);
    end;
  end;
  Inc(FFormatStep);
  Progress := Byte(FFormatStep * 10);
  if Progress > 100 then
    Progress := 100;
  EmitAck;
  EmitAck;
  EmitDwordBe($00000000);       { PROGRESS_INIT }
  Emit(Progress);
  FAwait := awFormatAck;
  if Progress = 100 then
  begin
    EmitAck;
    EmitAck;
    FAwait := awNone;
    FOnCollect := scNone;
  end;
end;

{ ----------------------------------------------------------------- handshake }

procedure TSimPort.EmitHandshakeAnswer(B: Byte);
begin
  if B = BROM_HANDSHAKE[FHandshakeIndex] then
  begin
    Emit(Byte(not B));
    Inc(FHandshakeIndex);
    if FHandshakeIndex > High(BROM_HANDSHAKE) then
    begin
      FHandshakeIndex := 0;
      FInHandshake := False;   { from now on the bytes are commands }
    end;
  end
  else
    { A wrong byte gets no answer at all, which is what makes the host restart
      the whole sequence. }
    FHandshakeIndex := 0;
end;

{ --------------------------------------------------------------- collectors }

procedure TSimPort.StartCollect(AKind: TSimCollect; ACount: Integer;
  AEcho: Boolean);
begin
  FOnCollect := AKind;
  FCollectLen := 0;
  FCollectLeft := ACount;
  FEchoCollect := AEcho;
  if Length(FCollect) < ACount then
    SetLength(FCollect, ACount);
end;

procedure TSimPort.StartPayload(AKind: TSimCollect; ACount: Integer);
begin
  FPayloadKind := AKind;
  FPayloadLeft := ACount;
  FPayloadPos := 0;
  SetLength(FPayload, ACount);
end;

procedure TSimPort.CollectByte(B: Byte);
begin
  if FEchoCollect then
    Emit(B);
  if FCollectLen < Length(FCollect) then
  begin
    FCollect[FCollectLen] := B;
    Inc(FCollectLen);
  end;
  Dec(FCollectLeft);
  if FCollectLeft <= 0 then
    CollectDone;
end;

procedure TSimPort.PayloadByte(B: Byte);
begin
  if FPayloadPos < Length(FPayload) then
  begin
    FPayload[FPayloadPos] := B;
    Inc(FPayloadPos);
  end;
  Dec(FPayloadLeft);
  if FPayloadLeft <= 0 then
    PayloadDone;
end;

procedure TSimPort.PayloadDone;
begin
  case FPayloadKind of
    scDaPayload:
      begin
        EmitWordBe(PayloadChecksum);
        EmitStatus(S_BROM_OK);
      end;
    scAuthPayload, scCertPayload:
      begin
        EmitWordBe(PayloadChecksum);
        EmitStatus(S_BROM_OK);
      end;
    scStage2Packet:
      begin
        Inc(FStage2Done, FPayloadPos);
        EmitAck;
        if FStage2Done < FStage2Size then
          StartPayload(scStage2Packet, FStage2Packet)
        else
        begin
          FOnCollect := scNone;
          { The host acks once more; only then does the DA report the flash. }
          FAwait := awStage2FinalAck;
        end;
      end;
  else
    { nothing }
  end;
  FPayloadLeft := 0;
  if FPayloadKind <> scStage2Packet then
    FPayloadKind := scNone;
end;

procedure TSimPort.AwaitByte(B: Byte);
var
  SavedAwait: TSimAwait;
begin
  SavedAwait := FAwait;
  FAwait := awNone;
  case SavedAwait of
    awWriteAck:
      begin
        if B <> DA_ACK then
        begin
          { Not the ACK we asked for: refuse and drop out of the write. }
          EmitNack;
          FWriteLeft := 0;
          FOnCollect := scNone;
          Exit;
        end;
        if FWriteDone >= FWriteLength then
        begin
          FOnCollect := scNone;
          Exit;
        end;
        FWriteLeft := FWritePacket;
        if Int64(FWriteLeft) > Int64(FWriteLength) - Int64(FWriteDone) then
          FWriteLeft := Integer(Int64(FWriteLength) - Int64(FWriteDone));
        FWriteChunkPos := 0;
        { The packet body plus its two trailing checksum bytes. }
        StartCollect(scWriteData, FWriteLeft + 2, False);
        Exit;
      end;
    awFormatAck:
      EmitFormatStep;
    awReadFinalAck:
      begin
        { The host acks the last packet; the read is over. }
        FOnCollect := scNone;
      end;
    awStage2FinalAck:
      begin
        { Stage 2 is in and running: now the DA reports the flash behind it. }
        FOnCollect := scNone;
        if FFullDa then
          EmitLegacyStorageInfo;
      end;
  else
    { nothing }
  end;
end;

procedure TSimPort.CollectDone;
var
  Count, Addr: UInt32;
  N, I: Integer;
  Sum: Word;
begin
  case FOnCollect of
    scReadAddr:
      begin
        FBromAddr := CollectDwordBe(0);
        StartCollect(scReadCount, 4, True);
        Exit;
      end;
    scReadCount:
      begin
        Count := CollectDwordBe(0);
        if Count > 4096 then
          Count := 4096;
        EmitStatus(S_BROM_OK);
        if FPendingCmd = CMD_READ16_A2 then
        begin
          { CMD_READ16_A2 answers one big-endian word. }
          EmitWordBe($0000);
        end
        else
          MemoryRead(FBromAddr, Integer(Count));
        EmitStatus(S_BROM_OK);
      end;
    scWriteAddr:
      begin
        FBromAddr := CollectDwordBe(0);
        StartCollect(scWriteCount, 4, True);
        Exit;
      end;
    scWriteCount:
      begin
        Count := CollectDwordBe(0);
        if Count > 4096 then
          Count := 4096;
        EmitStatus(S_BROM_OK);
        if FBromWriteIs16 then
          N := Integer(Count) * 2
        else
          N := Integer(Count) * 4;
        StartCollect(scWriteValues, N, True);
        Exit;
      end;
    scWriteValues:
      begin
        SetLength(FPayload, FCollectLen);
        for I := 0 to FCollectLen - 1 do
          FPayload[I] := FCollect[I];
        MemoryWrite(FBromAddr, FPayload);
        EmitStatus(S_BROM_OK);
      end;
    scDaAddr:
      begin
        FDaAddress := CollectDwordBe(0);
        StartCollect(scDaSize, 4, True);
        Exit;
      end;
    scDaSize:
      begin
        FDaSize := Integer(CollectDwordBe(0));
        StartCollect(scDaSigLen, 4, True);
        Exit;
      end;
    scDaSigLen:
      begin
        FDaSigLen := Integer(CollectDwordBe(0));
        EmitStatus(S_BROM_OK);
        if (FDaSize > 0) and (FDaSize <= 32 * 1024 * 1024) then
          StartPayload(scDaPayload, FDaSize)
        else
          FOnCollect := scNone;
        Exit;
      end;
    scJumpAddr, scJump64Addr:
      begin
        Addr := CollectDwordBe(0);
        EmitDwordBe(Addr);
        FDaAddress := Addr;
        if FOnCollect = scJump64Addr then
        begin
          { JUMP_DA64 sends one flag byte before the status. }
          StartCollect(scJump64Flag, 1, True);
          Exit;
        end;
        EmitStatus(S_BROM_OK);
        EnterDa;
      end;
    scJump64Flag:
      begin
        EmitStatus(S_BROM_OK);
        EnterDa;
      end;
    scAuthLen:
      begin
        N := Integer(CollectDwordBe(0));
        EmitDwordBe(UInt32(N));
        EmitStatus(S_BROM_OK);
        if (N > 0) and (N <= 1024 * 1024) then
          StartPayload(scAuthPayload, N);
        Exit;
      end;
    scCertLen:
      begin
        N := Integer(CollectDwordBe(0));
        EmitStatus(S_BROM_OK);
        if (N > 0) and (N <= 1024 * 1024) then
          StartPayload(scCertPayload, N);
        Exit;
      end;

    { --------------------------------------------------- legacy DA side }
    scUsbSetupMode:
      EmitAck;
    scSwitchPart:
      begin
        FSwitchedPart := FCollect[0];
        EmitAck;
      end;
    scWriteHeader:
      begin
        FSwitchedPart := FCollect[1];
        FWriteAddr := CollectQwordBe(2);
        FWriteLength := CollectQwordBe(10);
        FWritePacket := Integer(CollectDwordBe(18));
        if FWritePacket <= 0 then
          FWritePacket := $100000;
        FWriteDone := 0;
        EmitAck;
        FAwait := awWriteAck;
        FOnCollect := scNone;
        Exit;
      end;
    scWriteData:
      begin
        { The packet body is in FCollect, the trailing two bytes are its
          big-endian checksum. }
        N := FCollectLen - 2;
        if N < 0 then
          N := 0;
        Sum := 0;
        for I := 0 to N - 1 do
        begin
          SetFlashByte(FWriteAddr + UInt64(FWriteDone) + UInt64(I), FCollect[I]);
          Sum := Word(Sum + Word(FCollect[I])) and $FFFF;
        end;
        Inc(FWriteDone, UInt64(N));
        if FWriteDone >= FWriteLength then
        begin
          EmitAck;
          FOnCollect := scNone;
          FAwait := awNone;
        end
        else
        begin
          EmitCont;
          FAwait := awWriteAck;
          FOnCollect := scNone;
        end;
        Exit;
      end;
    scReadHeader:
      begin
        FSwitchedPart := FCollect[1];
        FReadAddr := CollectQwordBe(2);
        FReadLength := CollectQwordBe(10);
        FReadPacket := Integer(CollectDwordBe(18));
        if FReadPacket <= 0 then
          FReadPacket := $100000;
        FReadDone := 0;
        EmitAck;
        EmitReadPacket;
        FOnCollect := scNone;
        if FReadDone >= FReadLength then
          FAwait := awReadFinalAck;
        Exit;
      end;
    scFormatHeader:
      begin
        FFormatAddr := CollectQwordBe(4);
        FFormatLength := CollectQwordBe(12);
        FFormatStep := 0;
        FOnCollect := scNone;
        EmitFormatStep;
        Exit;
      end;
    scStage2Config:
      begin
        { bromver, blver, nor chip, chip select, nand acccon, bmt flag,
          bmt part size, force charge, reset keys, ext clock, msdc boot ch
          and the chip-specific extra block. Answer with the DRAM info. }
        EmitDwordBe($00000000);
        StartCollect(scStage2Addr, 4, False);
        Exit;
      end;
    scStage2Addr:
      begin
        FStage2Address := CollectDwordBe(0);
        StartCollect(scStage2Size, 4, False);
        Exit;
      end;
    scStage2Size:
      begin
        FStage2Size := Integer(CollectDwordBe(0));
        FStage2Done := 0;
        StartCollect(scStage2PacketSize, 4, False);
        Exit;
      end;
    scStage2PacketSize:
      begin
        FStage2Packet := Integer(CollectDwordBe(0));
        if FStage2Packet <= 0 then
          FStage2Packet := $1000;
        EmitAck;
        StartPayload(scStage2Packet, FStage2Packet);
        Exit;
      end;
    scFinishValue:
      EmitAck;
  else
    { nothing }
  end;
  FOnCollect := scNone;
  FCollectLeft := 0;
end;

{ --------------------------------------------------------------- command entry }

procedure TSimPort.HandleBromCommand(B: Byte);
begin
  { Every BROM command is echoed back. }
  Emit(B);
  FPendingCmd := B;
  case B of
    CMD_GET_HW_CODE:
      EmitDwordBe((UInt32(FHwCode) shl 16) or UInt32(FHwVer));
    CMD_GET_BL_VER:
      Emit(CMD_GET_BL_VER);   { the cmd itself means "still in BROM" }
    CMD_GET_VERSION:
      Emit(FBromVer);
    CMD_GET_TARGET_CONFIG:
      begin
        EmitDwordBe(FTargetConfig);
        EmitStatus(S_BROM_OK);
      end;
    CMD_GET_HW_SW_VER:
      begin
        EmitWordBe($0000);
        EmitWordBe(FHwVer);
        EmitWordBe($0100);
        EmitWordBe($0000);
      end;
    CMD_GET_ME_ID, CMD_GET_SOC_ID:
      begin
        EmitDwordBe(16);
        EmitRepeat($A0, 16);
        EmitWordBe($0000);      { little-endian status 0 }
      end;
    CMD_READ32:
      begin
        FBromWriteIs16 := False;
        StartCollect(scReadAddr, 4, True);
      end;
    CMD_READ16, CMD_READ16_A2:
      begin
        FBromWriteIs16 := True;
        StartCollect(scReadAddr, 4, True);
      end;
    CMD_WRITE32:
      begin
        FBromWriteIs16 := False;
        StartCollect(scWriteAddr, 4, True);
      end;
    CMD_WRITE16:
      begin
        FBromWriteIs16 := True;
        StartCollect(scWriteAddr, 4, True);
      end;
    CMD_SEND_DA:
      if FDemandSla then
      begin
        EmitStatus(S_BROM_SLA_REQUIRED);
        FOnCollect := scNone;
      end
      else
        StartCollect(scDaAddr, 4, True);
    CMD_JUMP_DA:
      StartCollect(scJumpAddr, 4, False);
    CMD_JUMP_DA64:
      StartCollect(scJump64Addr, 4, False);
    CMD_JUMP_BL:
      begin
        EmitStatus(S_BROM_OK);
        EmitStatus(S_BROM_OK);
      end;
    CMD_SEND_AUTH:
      StartCollect(scAuthLen, 4, False);
    CMD_SEND_CERT:
      StartCollect(scCertLen, 4, True);
    CMD_SLA:
      EmitStatus(S_DA_SLA_REQUIRED);
    CMD_CACHE_CTRL:
      EmitStatus(S_BROM_OK);
  else
    EmitStatus($03E9);   { UNDEFINED_ERROR }
  end;
end;

procedure TSimPort.HandleDaCommand(B: Byte);
begin
  case B of
    DA_CMD_USB_CHECK_STATUS:
      begin
        EmitAck;
        Emit($00);            { 0 = keep the current speed }
      end;
    DA_CMD_USB_SETUP_PORT:
      StartCollect(scUsbSetupMode, 1, False);
    DA_CMD_SDMMC_SWITCH_PART:
      begin
        EmitAck;
        StartCollect(scSwitchPart, 1, False);
      end;
    DA_CMD_SDMMC_WRITE_DATA:
      StartCollect(scWriteHeader, 22, False);
    DA_CMD_READ:
      StartCollect(scReadHeader, 22, False);
    DA_CMD_FORMAT:
      StartCollect(scFormatHeader, 20, False);
    DA_CMD_FINISH:
      begin
        EmitAck;
        StartCollect(scFinishValue, 4, False);
      end;
  else
    EmitNack;
  end;
end;

procedure TSimPort.HandleCommand(B: Byte);
begin
  if FPhase = spBootRom then
    HandleBromCommand(B)
  else
    HandleDaCommand(B);
end;

{ ----------------------------------------------------------------- byte pump }

function TSimPort.WriteData(const AData; ACount: Integer): Integer;
var
  P: PByte;
  I: Integer;
  B: Byte;
begin
  Result := 0;
  if not FOpen then
    Exit;
  P := PByte(@AData);
  for I := 0 to ACount - 1 do
  begin
    B := P^;
    Inc(P);
    Inc(FBytesOut);
    if FPayloadLeft > 0 then
      PayloadByte(B)
    else if FCollectLeft > 0 then
      CollectByte(B)
    else if FAwait <> awNone then
      AwaitByte(B)
    else if FInHandshake and (FPhase = spBootRom) then
      EmitHandshakeAnswer(B)
    else
      HandleCommand(B);
  end;
  Result := ACount;
end;

function TSimPort.ReadData(var ABuffer; ACount, ATimeoutMs: Integer): Integer;
var
  P: PByte;
  I: Integer;
begin
  Result := 0;
  if not FOpen then
    Exit;
  P := PByte(@ABuffer);
  for I := 1 to ACount do
  begin
    if FOutPos >= FInLen then
      Break;
    P^ := FInBuf[FOutPos];
    Inc(P);
    Inc(FOutPos);
    Inc(Result);
    Inc(FBytesIn);
  end;
  if FOutPos >= FInLen then
    Compact;
end;

{ ------------------------------------------------------- simulated scatter }

function BuildSimScatter(const ADir: string; out AScatterFile: string): Boolean;
type
  TSimPart = record
    Name: string;
    FileName: string;
    Region: string;
    Start: UInt64;
    Size: UInt64;
    Kind: string;
    Operation: string;
  end;
var
  { a local const block may hold strings, a unit-level typed constant may not }
  CParts: array[0..4] of TSimPart = (
    (Name: 'preloader'; FileName: 'sim_preloader.bin'; Region: 'EMMC_BOOT_1';
     Start: 0;        Size: $40000;  Kind: 'SV5_BL_BIN';
     Operation: 'BOOTLOADERS'),
    (Name: 'lk'; FileName: 'sim_lk.bin'; Region: 'EMMC_USER';
     Start: $100000;  Size: $80000;  Kind: 'NORMAL_ROM';
     Operation: 'UPDATE'),
    (Name: 'boot'; FileName: 'sim_boot.bin'; Region: 'EMMC_USER';
     Start: $200000;  Size: $400000; Kind: 'NORMAL_ROM';
     Operation: 'UPDATE'),
    (Name: 'recovery'; FileName: 'sim_recovery.bin'; Region: 'EMMC_USER';
     Start: $600000;  Size: $400000; Kind: 'NORMAL_ROM';
     Operation: 'UPDATE'),
    (Name: 'userdata'; FileName: ''; Region: 'EMMC_USER';
     Start: $A00000;  Size: $600000; Kind: 'NORMAL_ROM';
     Operation: 'UPDATE'));
  Lines: TStringList;
  Data: TBytesArray;
  Stream: TFileStream;
  I, J: Integer;
  Dir: string;
begin
  Result := False;
  AScatterFile := '';
  Dir := IncludeTrailingPathDelimiter(ADir);
  if not ForceDirectories(Dir) then
    Exit;

  Lines := TStringList.Create;
  try
    Lines.Add('# Simulated scatter file, written by SimPort.BuildSimScatter.');
    Lines.Add('# It describes the built-in simulated phone so the whole');
    Lines.Add('# scatter -> image -> write path can be tested without hardware.');
    Lines.Add('chip: MT6765');
    Lines.Add('platform: MT6765');
    Lines.Add('project: simulated');
    Lines.Add('storage: HW_STORAGE_EMMC');
    Lines.Add('boot_channel: EMMC_BOOT_1');
    Lines.Add('da_address: 0x200000');
    Lines.Add('flashtool_version: SIMULATED');
    Lines.Add('');
    for I := 0 to High(CParts) do
    begin
      Lines.Add('- partition_index: SYS' + IntToStr(I));
      Lines.Add('  partition_name: ' + CParts[I].Name);
      Lines.Add('  file_name: ' + CParts[I].FileName);
      Lines.Add('  is_download: ' +
        IfThenStr(CParts[I].FileName <> '', 'true', 'false'));
      Lines.Add('  type: ' + CParts[I].Kind);
      Lines.Add('  physical_start_addr: 0x' + IntToHex(Int64(CParts[I].Start), 1));
      Lines.Add('  partition_size: 0x' + IntToHex(Int64(CParts[I].Size), 1));
      Lines.Add('  region: ' + CParts[I].Region);
      Lines.Add('  storage: HW_STORAGE_EMMC');
      Lines.Add('  boundary_check: true');
      Lines.Add('  is_reserved: false');
      Lines.Add('  operation_type: ' + CParts[I].Operation);
      Lines.Add('');
    end;
    AScatterFile := Dir + 'MT6765_Android_scatter.txt';
    try
      Lines.SaveToFile(AScatterFile);
    except
      on E: Exception do
      begin
        AScatterFile := '';
        Exit;
      end;
    end;
  finally
    Lines.Free;
  end;

  { a recognisable payload per image, so a read-back can be compared }
  for I := 0 to High(CParts) do
  begin
    if CParts[I].FileName = '' then
      Continue;
    SetLength(Data, Integer(CParts[I].Size));
    for J := 0 to High(Data) do
      Data[J] := Byte((I + 1) * 17 + (J mod 251));
    try
      Stream := TFileStream.Create(Dir + CParts[I].FileName, fmCreate);
      try
        Stream.WriteBuffer(Data[0], Length(Data));
      finally
        Stream.Free;
      end;
    except
      on E: Exception do
        Exit;
    end;
  end;
  Result := True;
end;

end.
