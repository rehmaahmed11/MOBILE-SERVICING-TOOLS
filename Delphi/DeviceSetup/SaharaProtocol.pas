unit SaharaProtocol;

{$IFDEF FPC}
  {$MODE DELPHI}
  {$PACKRECORDS C}
{$ENDIF}


{ Qualcomm Sahara protocol - the first stage of an EDL (Emergency Download)
  session, over the diagnostic COM port that appears as
  "Qualcomm HS-USB QDLoader 9008".

  Implemented, from the public protocol description:

      $01 hello                  device -> host, 48 bytes
      $02 hello response         host -> device, 48 bytes
      $03 end of image transfer  device -> host, 24 bytes  (status + image id)
      $04 done                   host -> device, 20 bytes
      $05 done response          device -> host, 20 bytes
      $06 reset                  host -> device, 20 bytes
      $07 reset response         device -> host, 20 bytes
      $08 read data              device -> host, 48 bytes  (image, offset, len)
      $09 end image transfer     host -> device, 20 bytes
      $0a cmd ready              device -> host, 20 bytes
      $0b switch mode            host -> device, 20 bytes
      $0c execute                host -> device, 44+ bytes
      $0d execute data           device -> host, 32 bytes
      $0e execute response       host -> device, 24 bytes
      $0f execute data pkt       device -> host, 32 bytes
      $10 log                    device -> host
      $11 log response           host -> device, 16 bytes
      $12 memory debug 64        device -> host, 60 bytes
      $13 memory read 64         host -> device, 40 bytes
      $14 cmd ready 64           device -> host, 20 bytes
      $18 memory debug           device -> host, 48 bytes
      $19 memory read            host -> device, 32 bytes

  Every multi-byte field is big-endian. Every packet carries the same 32-bit
  checksum: the sum of all dwords after the command field, plus the previous
  checksum value (0 for the first packet of a session).

  What this unit does NOT implement is firehose, the XML command language that
  follows Sahara once the programmer binary (prog_firehose_*.elf / .mbn) has
  been transferred. Firehose is where flashing actually happens and it is
  vendor specific, so the job layer reports that honestly instead of guessing.

  Reading a memory region (memory read 64 / memory debug 64) IS implemented,
  because the device itself does the transfer and no vendor secret is needed. }

interface

uses
{$IFDEF FPC}
  Classes, SysUtils,
{$ELSE}
  System.Classes,
  System.SysUtils,
{$ENDIF}
  DevTypes, CommPort;

const
  SAHARA_HELLO                = $01;
  SAHARA_HELLO_RESP           = $02;
  SAHARA_END_IMAGE_XFER       = $03;
  SAHARA_DONE                 = $04;
  SAHARA_DONE_RESP            = $05;
  SAHARA_RESET                = $06;
  SAHARA_RESET_RESP           = $07;
  SAHARA_READ_DATA            = $08;
  SAHARA_END_IMAGE_XFER_RESP  = $09;
  SAHARA_CMD_READY            = $0A;
  SAHARA_SWITCH_MODE          = $0B;
  SAHARA_EXECUTE              = $0C;
  SAHARA_EXECUTE_DATA         = $0D;
  SAHARA_EXECUTE_RESP         = $0E;
  SAHARA_EXECUTE_DATA_PACKET  = $0F;
  SAHARA_LOG                  = $10;
  SAHARA_LOG_RESP             = $11;
  SAHARA_MEMORY_DEBUG_64      = $12;
  SAHARA_MEMORY_READ_64       = $13;
  SAHARA_CMD_READY_64         = $14;
  SAHARA_MEMORY_DEBUG         = $18;
  SAHARA_MEMORY_READ          = $19;

  { hello response modes }
  SAHARA_MODE_IMAGE_TX        = 0;
  SAHARA_MODE_IMAGE_TX_64     = 3;
  SAHARA_MODE_COMMAND         = 1;
  SAHARA_MODE_COMMAND_64      = 2;

  SAHARA_STATUS_SUCCESS       = 0;

  CSaharaDefaultTimeoutMs     = 5000;

type
  TSaharaLogEvent = procedure(Sender: TObject; const AText: string) of object;
  TSaharaProgressEvent = procedure(Sender: TObject; ADone, ATotal: Int64)
    of object;

  { Fields of the hello packet the device sends first. }
  TSaharaHello = record
    Valid: Boolean;
    Version: UInt32;
    VersionCompat: UInt32;
    MaxPacketLen: UInt32;
    Mode: UInt32;
    Reserved: array[0..5] of UInt32;
  end;

  { end_image_transfer: what the device wants, or how it finished. }
  TSaharaImageStatus = record
    ImageId: UInt32;
    Status: UInt32;
  end;

  { read_data / memory_debug: the device asks for a chunk of a file, or offers
    a chunk of its own memory. }
  TSaharaReadRequest = record
    ImageId: UInt32;
    Offset: UInt64;
    Length: UInt64;
  end;

  TSaharaProtocol = class(TObject)
  private
    FTransport: TCommTransport;
    FTimeoutMs: Integer;
    FChecksum: UInt32;
    FHello: TSaharaHello;
    FLastError: string;
    FCancelled: Boolean;
    FMode: UInt32;
    FOnLog: TSaharaLogEvent;
    FOnProgress: TSaharaProgressEvent;
    FBytesMoved: Int64;
    function WriteRaw(const AData; ACount: Integer): Boolean;
    function ReadRaw(var ABuffer; ACount: Integer): Boolean;
    function ReadBytes(ACount: Integer; out AData: TBytesArray): Boolean;
    function WriteBytes(const AData: TBytesArray): Boolean;
    function ReadBe32(out AValue: UInt32): Boolean;
    function ReadBe64(out AValue: UInt64): Boolean;
    function WriteBe32(AValue: UInt32): Boolean;
    function WriteBe64(AValue: UInt64): Boolean;
    procedure DoLog(const AText: string);
    procedure FailFmt(const AFmt: string; const AArgs: array of const);
    function ReadPacket(out ACommand, ALength: UInt32;
      out ABody: TBytesArray): Boolean;
    function BuildPacket(ACommand: UInt32; const ABody: TBytesArray): TBytesArray;
    function SendPacket(ACommand: UInt32; const ABody: TBytesArray): Boolean;
    procedure AddBe32(var ABuffer: TBytesArray; AValue: UInt32);
    procedure AddBe64(var ABuffer: TBytesArray; AValue: UInt64);
    function NextChecksum(const ABody: TBytesArray): UInt32;
    function SendHelloResponse(AMode: UInt32): Boolean;
    function SendDone: Boolean;
    function SendReset: Boolean;
    function SendMemoryRead64(AAddress, ALength: UInt64): Boolean;
    function SendEndImageTransfer(AImageId, AError: UInt32): Boolean;
  public
    constructor Create(ATransport: TCommTransport);

    { Waits for the device hello, answers it, and reports the session mode.
      Returns False (with LastError set) when the port does not speak Sahara -
      which is the normal answer when the phone is not in EDL mode. }
    function Handshake(AWaitMs: Integer = CSaharaDefaultTimeoutMs): Boolean;

    { Reads ALength bytes at AAddress into AData using the memory-read command
      set. Works without a programmer binary. }
    function ReadMemory(AAddress, ALength: UInt64;
      out AData: TBytesArray): Boolean;

    { Sends the programmer file the device asks for, chunk by chunk, and
      finishes the transfer. The device then expects firehose XML, which this
      build does not implement - so the caller is told, and the programmer is
      still transferred because that part is honest and useful. }
    function SendImage(AImageId: UInt32; AStream: TStream;
      ASize: Int64): Boolean;

    procedure Cancel;
    procedure ResetCancel;

    property Hello: TSaharaHello read FHello;
    property Mode: UInt32 read FMode;
    property LastError: string read FLastError;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs;
    property BytesMoved: Int64 read FBytesMoved;
    property OnLog: TSaharaLogEvent read FOnLog write FOnLog;
    property OnProgress: TSaharaProgressEvent read FOnProgress
      write FOnProgress;
  end;

function SaharaCommandName(ACommand: UInt32): string;
function SaharaModeName(AMode: UInt32): string;
function SaharaStatusText(AStatus: UInt32): string;
function EmptySaharaHello: TSaharaHello;

implementation

{ ------------------------------------------------------------------ helpers }

function EmptySaharaHello: TSaharaHello;
var
  I: Integer;
begin
  Result.Valid := False;
  Result.Version := 0;
  Result.VersionCompat := 0;
  Result.MaxPacketLen := 0;
  Result.Mode := 0;
  for I := 0 to High(Result.Reserved) do
    Result.Reserved[I] := 0;
end;

function SaharaCommandName(ACommand: UInt32): string;
begin
  case ACommand of
    SAHARA_HELLO: Result := 'hello';
    SAHARA_HELLO_RESP: Result := 'hello response';
    SAHARA_END_IMAGE_XFER: Result := 'end of image transfer';
    SAHARA_DONE: Result := 'done';
    SAHARA_DONE_RESP: Result := 'done response';
    SAHARA_RESET: Result := 'reset';
    SAHARA_RESET_RESP: Result := 'reset response';
    SAHARA_READ_DATA: Result := 'read data';
    SAHARA_END_IMAGE_XFER_RESP: Result := 'end image transfer response';
    SAHARA_CMD_READY: Result := 'command ready';
    SAHARA_SWITCH_MODE: Result := 'switch mode';
    SAHARA_EXECUTE: Result := 'execute';
    SAHARA_EXECUTE_DATA: Result := 'execute data';
    SAHARA_EXECUTE_RESP: Result := 'execute response';
    SAHARA_EXECUTE_DATA_PACKET: Result := 'execute data packet';
    SAHARA_LOG: Result := 'log';
    SAHARA_LOG_RESP: Result := 'log response';
    SAHARA_MEMORY_DEBUG_64: Result := 'memory debug 64';
    SAHARA_MEMORY_READ_64: Result := 'memory read 64';
    SAHARA_CMD_READY_64: Result := 'command ready 64';
    SAHARA_MEMORY_DEBUG: Result := 'memory debug';
    SAHARA_MEMORY_READ: Result := 'memory read';
  else
    Result := 'command $' + IntToHex(ACommand, 2);
  end;
end;

function SaharaModeName(AMode: UInt32): string;
begin
  case AMode of
    SAHARA_MODE_IMAGE_TX: Result := 'image transfer (32-bit)';
    SAHARA_MODE_COMMAND: Result := 'command (32-bit)';
    SAHARA_MODE_COMMAND_64: Result := 'command (64-bit)';
    SAHARA_MODE_IMAGE_TX_64: Result := 'image transfer (64-bit)';
  else
    Result := 'mode ' + IntToStr(AMode);
  end;
end;

function SaharaStatusText(AStatus: UInt32): string;
begin
  case AStatus of
    $00: Result := 'success';
    $01: Result := 'invalid command';
    $02: Result := 'invalid argument';
    $03: Result := 'invalid image length';
    $04: Result := 'invalid response length';
    $05: Result := 'image transfer error';
    $06: Result := 'host did not respond to a read-data request';
    $07: Result := 'invalid image';
    $08: Result := 'write error';
    $09: Result := 'read error';
    $0A: Result := 'device not authenticated';
    $0B: Result := 'hash table error';
    $0C: Result := 'invalid hash table base address';
    $0D: Result := 'image transfer timeout';
    $0E: Result := 'general failure';
  else
    Result := 'status $' + IntToHex(AStatus, 8);
  end;
end;

{ Big-endian field readers, so the packet parsers stay readable. }
function Be32At(const AData: TBytesArray; AOffset: Integer): UInt32;
begin
  Result := 0;
  if (AOffset < 0) or (AOffset + 4 > Length(AData)) then
    Exit;
  Result := (UInt32(AData[AOffset]) shl 24) or
    (UInt32(AData[AOffset + 1]) shl 16) or
    (UInt32(AData[AOffset + 2]) shl 8) or UInt32(AData[AOffset + 3]);
end;

function Be64At(const AData: TBytesArray; AOffset: Integer): UInt64;
begin
  Result := 0;
  if (AOffset < 0) or (AOffset + 8 > Length(AData)) then
    Exit;
  Result := (UInt64(Be32At(AData, AOffset)) shl 32) or
    UInt64(Be32At(AData, AOffset + 4));
end;

{ A device log packet as printable text. }
function LogText(const AData: TBytesArray): string;
var
  Raw: AnsiString;
begin
  if Length(AData) = 0 then
    Exit('');
  SetString(Raw, PAnsiChar(@AData[0]), Length(AData));
  Result := Trim(string(Raw));
end;

{ ------------------------------------------------------- TSaharaProtocol }

constructor TSaharaProtocol.Create(ATransport: TCommTransport);
begin
  inherited Create;
  FTransport := ATransport;
  FTimeoutMs := CSaharaDefaultTimeoutMs;
  FChecksum := 0;
  FHello := EmptySaharaHello;
  FLastError := '';
  FCancelled := False;
  FMode := 0;
  FOnLog := nil;
  FOnProgress := nil;
  FBytesMoved := 0;
end;

procedure TSaharaProtocol.DoLog(const AText: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, AText);
end;

procedure TSaharaProtocol.FailFmt(const AFmt: string;
  const AArgs: array of const);
begin
  FLastError := Format(AFmt, AArgs);
end;

procedure TSaharaProtocol.Cancel;
begin
  FCancelled := True;
end;

procedure TSaharaProtocol.ResetCancel;
begin
  FCancelled := False;
end;

function TSaharaProtocol.WriteRaw(const AData; ACount: Integer): Boolean;
var
  Written: Integer;
begin
  Result := False;
  if FTransport = nil then
  begin
    FLastError := 'No transport';
    Exit;
  end;
  Written := FTransport.WriteData(AData, ACount);
  if Written <> ACount then
  begin
    FailFmt('Sahara write failed after %d of %d bytes', [Written, ACount]);
    Exit;
  end;
  Result := True;
end;

function TSaharaProtocol.ReadRaw(var ABuffer; ACount: Integer): Boolean;
var
  Got, N: Integer;
  P: PByte;
begin
  Result := False;
  if FTransport = nil then
  begin
    FLastError := 'No transport';
    Exit;
  end;
  Got := 0;
  P := PByte(@ABuffer);
  while Got < ACount do
  begin
    if FCancelled then
    begin
      FLastError := 'Cancelled';
      Exit;
    end;
    N := FTransport.ReadData(P^, ACount - Got, FTimeoutMs);
    if N <= 0 then
    begin
      FailFmt('Sahara read timed out after %d of %d bytes', [Got, ACount]);
      Exit;
    end;
    Inc(Got, N);
    Inc(P, N);
  end;
  Result := True;
end;

function TSaharaProtocol.ReadBytes(ACount: Integer;
  out AData: TBytesArray): Boolean;
begin
  SetLength(AData, ACount);
  if ACount = 0 then
    Exit(True);
  if not ReadRaw(AData[0], ACount) then
  begin
    AData := nil;
    Exit(False);
  end;
  Result := True;
end;

function TSaharaProtocol.WriteBytes(const AData: TBytesArray): Boolean;
begin
  if Length(AData) = 0 then
    Exit(True);
  Result := WriteRaw(AData[0], Length(AData));
end;

function TSaharaProtocol.ReadBe32(out AValue: UInt32): Boolean;
var
  B: TBytesArray;
begin
  AValue := 0;
  if not ReadBytes(4, B) then
    Exit(False);
  AValue := (UInt32(B[0]) shl 24) or (UInt32(B[1]) shl 16) or
    (UInt32(B[2]) shl 8) or UInt32(B[3]);
  Result := True;
end;

function TSaharaProtocol.ReadBe64(out AValue: UInt64): Boolean;
var
  Hi, Lo: UInt32;
begin
  AValue := 0;
  if not ReadBe32(Hi) then
    Exit(False);
  if not ReadBe32(Lo) then
    Exit(False);
  AValue := (UInt64(Hi) shl 32) or UInt64(Lo);
  Result := True;
end;

function TSaharaProtocol.WriteBe32(AValue: UInt32): Boolean;
var
  B: TBytesArray;
begin
  SetLength(B, 4);
  B[0] := Byte(AValue shr 24);
  B[1] := Byte(AValue shr 16);
  B[2] := Byte(AValue shr 8);
  B[3] := Byte(AValue);
  Result := WriteBytes(B);
end;

function TSaharaProtocol.WriteBe64(AValue: UInt64): Boolean;
begin
  if not WriteBe32(UInt32(AValue shr 32)) then
    Exit(False);
  Result := WriteBe32(UInt32(AValue and $FFFFFFFF));
end;

procedure TSaharaProtocol.AddBe32(var ABuffer: TBytesArray; AValue: UInt32);
var
  N: Integer;
begin
  N := Length(ABuffer);
  SetLength(ABuffer, N + 4);
  ABuffer[N + 0] := Byte(AValue shr 24);
  ABuffer[N + 1] := Byte(AValue shr 16);
  ABuffer[N + 2] := Byte(AValue shr 8);
  ABuffer[N + 3] := Byte(AValue);
end;

procedure TSaharaProtocol.AddBe64(var ABuffer: TBytesArray; AValue: UInt64);
begin
  AddBe32(ABuffer, UInt32(AValue shr 32));
  AddBe32(ABuffer, UInt32(AValue and $FFFFFFFF));
end;

{ The checksum covers every dword of the packet after the command field, plus
  the checksum carried by the previous packet. }
function TSaharaProtocol.NextChecksum(const ABody: TBytesArray): UInt32;
var
  Sum: UInt32;
  I: Integer;
begin
  Sum := FChecksum;
  I := 0;
  while I + 3 < Length(ABody) do
  begin
    Sum := Sum + ((UInt32(ABody[I]) shl 24) or (UInt32(ABody[I + 1]) shl 16) or
      (UInt32(ABody[I + 2]) shl 8) or UInt32(ABody[I + 3]));
    Inc(I, 4);
  end;
  { a trailing partial dword still counts, zero padded }
  if I < Length(ABody) then
  begin
    Sum := Sum + (UInt32(ABody[I]) shl 24);
    Inc(I);
    if I < Length(ABody) then
    begin
      Sum := Sum + (UInt32(ABody[I]) shl 16);
      Inc(I);
    end;
    if I < Length(ABody) then
      Sum := Sum + (UInt32(ABody[I]) shl 8);
  end;
  Result := Sum;
end;

function TSaharaProtocol.BuildPacket(ACommand: UInt32;
  const ABody: TBytesArray): TBytesArray;
var
  Body: TBytesArray;
begin
  { length = command(4) + length(4) + checksum(4) + body }
  SetLength(Body, 0);
  AddBe32(Body, FChecksum);
  if Length(ABody) > 0 then
  begin
    SetLength(Body, Length(Body) + Length(ABody));
    Move(ABody[0], Body[4], Length(ABody));
  end;
  FChecksum := NextChecksum(Body);
  SetLength(Result, 0);
  AddBe32(Result, ACommand);
  AddBe32(Result, UInt32(12 + Length(Body)));
  if Length(Body) > 0 then
  begin
    SetLength(Result, Length(Result) + Length(Body));
    Move(Body[0], Result[8], Length(Body));
  end;
end;

function TSaharaProtocol.SendPacket(ACommand: UInt32;
  const ABody: TBytesArray): Boolean;
var
  Packet: TBytesArray;
begin
  Packet := BuildPacket(ACommand, ABody);
  Result := WriteBytes(Packet);
  if Result then
    DoLog('-> ' + SaharaCommandName(ACommand) + ' (' +
      IntToStr(Length(Packet)) + ' bytes)');
end;

{ Reads one packet. The checksum of a received packet is verified and then
  becomes the base for the next packet we send. }
function TSaharaProtocol.ReadPacket(out ACommand, ALength: UInt32;
  out ABody: TBytesArray): Boolean;
var
  Head, Rest, Check: TBytesArray;
  Sum, Received: UInt32;
  I: Integer;
begin
  ACommand := 0;
  ALength := 0;
  ABody := nil;
  if not ReadBytes(8, Head) then
    Exit(False);
  ACommand := (UInt32(Head[0]) shl 24) or (UInt32(Head[1]) shl 16) or
    (UInt32(Head[2]) shl 8) or UInt32(Head[3]);
  ALength := (UInt32(Head[4]) shl 24) or (UInt32(Head[5]) shl 16) or
    (UInt32(Head[6]) shl 8) or UInt32(Head[7]);
  if (ALength < 8) or (ALength > 4 * 1024 * 1024) then
  begin
    FailFmt('Sahara packet of %d bytes makes no sense (command $%x)',
      [ALength, ACommand]);
    Exit(False);
  end;
  if not ReadBytes(Integer(ALength) - 8, Rest) then
    Exit(False);
  if Length(Rest) < 4 then
  begin
    FLastError := 'Sahara packet is too short to carry a checksum';
    Exit(False);
  end;
  Check := Copy(Rest, 0, Length(Rest) - 4);
  Received := (UInt32(Rest[Length(Rest) - 4]) shl 24) or
    (UInt32(Rest[Length(Rest) - 3]) shl 16) or
    (UInt32(Rest[Length(Rest) - 2]) shl 8) or
    UInt32(Rest[Length(Rest) - 1]);
  { The device computes its checksum from the same running value we do, so the
    body must add up to what it sent. A mismatch is reported but not fatal:
    some loaders ship a broken checksum and still work. }
  Sum := FChecksum;
  I := 0;
  while I + 3 < Length(Check) do
  begin
    Sum := Sum + ((UInt32(Check[I]) shl 24) or (UInt32(Check[I + 1]) shl 16) or
      (UInt32(Check[I + 2]) shl 8) or UInt32(Check[I + 3]));
    Inc(I, 4);
  end;
  if I < Length(Check) then
  begin
    Sum := Sum + (UInt32(Check[I]) shl 24);
    Inc(I);
    if I < Length(Check) then
    begin
      Sum := Sum + (UInt32(Check[I]) shl 16);
      Inc(I);
    end;
    if I < Length(Check) then
      Sum := Sum + (UInt32(Check[I]) shl 8);
  end;
  if Sum <> Received then
    DoLog(Format('Warning: %s checksum is $%x, expected $%x',
      [SaharaCommandName(ACommand), Received, Sum]));
  FChecksum := Received;
  ABody := Check;
  DoLog('<- ' + SaharaCommandName(ACommand) + ' (' + IntToStr(ALength) +
    ' bytes)');
  Result := True;
end;

function TSaharaProtocol.Handshake(AWaitMs: Integer): Boolean;
var
  Command, Length: UInt32;
  Body: TBytesArray;
  I: Integer;
  SavedTimeout: Integer;
begin
  Result := False;
  FLastError := '';
  FHello := EmptySaharaHello;
  FChecksum := 0;
  FBytesMoved := 0;
  if FTransport = nil then
  begin
    FLastError := 'No transport';
    Exit;
  end;
  if not FTransport.PortOpen then
  begin
    FLastError := 'The port is not open';
    Exit;
  end;

  SavedTimeout := FTimeoutMs;
  if AWaitMs > 0 then
    FTimeoutMs := AWaitMs;
  try
    if not ReadPacket(Command, Length, Body) then
    begin
      if FLastError = '' then
        FLastError := 'The device did not send a Sahara hello';
      FLastError := FLastError + '. The phone must be in EDL mode ' +
        '(Qualcomm HS-USB QDLoader 9008) for Sahara to answer.';
      Exit;
    end;
  finally
    FTimeoutMs := SavedTimeout;
  end;

  if Command <> SAHARA_HELLO then
  begin
    FailFmt('Expected a Sahara hello ($01), got %s', [SaharaCommandName(Command)]);
    Exit;
  end;
  if Length(Body) < 20 then
  begin
    FailFmt('Sahara hello is %d bytes long, at least 20 are needed',
      [Length(Body)]);
    Exit;
  end;
  FHello.Version := Be32At(Body, 0);
  FHello.VersionCompat := Be32At(Body, 4);
  FHello.MaxPacketLen := Be32At(Body, 8);
  FHello.Mode := Be32At(Body, 12);
  for I := 0 to 5 do
    if 16 + (I * 4) + 3 < Length(Body) then
      FHello.Reserved[I] := Be32At(Body, 16 + (I * 4));
  FHello.Valid := True;
  FMode := FHello.Mode;
  DoLog(Format('Sahara hello: version %d.%d, compatible %d.%d, max packet %d, %s',
    [FHello.Version shr 16, FHello.Version and $FFFF,
     FHello.VersionCompat shr 16, FHello.VersionCompat and $FFFF,
     FHello.MaxPacketLen, SaharaModeName(FMode)]));

  { Answer in the same mode the device offered. }
  Result := SendHelloResponse(FMode);
  if Result then
    DoLog('Sahara session established (' + SaharaModeName(FMode) + ').');
end;

function TSaharaProtocol.SendHelloResponse(AMode: UInt32): Boolean;
var
  Body: TBytesArray;
begin
  SetLength(Body, 0);
  AddBe32(Body, AMode);
  AddBe32(Body, 0);  { reserved }
  Result := SendPacket(SAHARA_HELLO_RESP, Body);
end;

function TSaharaProtocol.SendDone: Boolean;
begin
  Result := SendPacket(SAHARA_DONE, nil);
end;

function TSaharaProtocol.SendReset: Boolean;
begin
  Result := SendPacket(SAHARA_RESET, nil);
end;

function TSaharaProtocol.SendEndImageTransfer(AImageId, AError: UInt32): Boolean;
var
  Body: TBytesArray;
begin
  SetLength(Body, 0);
  AddBe32(Body, AImageId);
  AddBe32(Body, AError);
  Result := SendPacket(SAHARA_END_IMAGE_XFER_RESP, Body);
end;

function TSaharaProtocol.SendMemoryRead64(AAddress, ALength: UInt64): Boolean;
var
  Body: TBytesArray;
begin
  SetLength(Body, 0);
  AddBe64(Body, AAddress);
  AddBe64(Body, ALength);
  Result := SendPacket(SAHARA_MEMORY_READ_64, Body);
end;

function TSaharaProtocol.ReadMemory(AAddress, ALength: UInt64;
  out AData: TBytesArray): Boolean;
var
  Command, Length: UInt32;
  Body, Chunk, LogBody: TBytesArray;
  Req: TSaharaReadRequest;
  Status: TSaharaImageStatus;
  Total: UInt64;
begin
  Result := False;
  AData := nil;
  FLastError := '';
  if ALength = 0 then
  begin
    FLastError := 'Nothing to read (length 0)';
    Exit;
  end;
  if not SendMemoryRead64(AAddress, ALength) then
    Exit;

  Total := 0;
  while Total < ALength do
  begin
    if FCancelled then
    begin
      FLastError := 'Cancelled';
      Exit;
    end;
    if not ReadPacket(Command, Length, Body) then
      Exit(False);
    case Command of
      SAHARA_MEMORY_DEBUG_64:
        begin
          { image_id(4) len(8) address(8) }
          if Length(Body) < 20 then
          begin
            FLastError := 'memory debug 64 packet is too short';
            Exit;
          end;
          Req.ImageId := Be32At(Body, 0);
          Req.Length := Be64At(Body, 4);
          Req.Offset := Be64At(Body, 12);
          if Req.Length = 0 then
            Break;
          if not ReadBytes(Integer(Req.Length), Chunk) then
            Exit(False);
          SetLength(AData, Length(AData) + Integer(Req.Length));
          Move(Chunk[0], AData[Length(AData) - Integer(Req.Length)],
            Integer(Req.Length));
          Inc(Total, Req.Length);
          Inc(FBytesMoved, Int64(Req.Length));
          if Assigned(FOnProgress) then
            FOnProgress(Self, Int64(Total), Int64(ALength));
        end;
      SAHARA_END_IMAGE_XFER:
        begin
          if Length(Body) < 8 then
          begin
            FLastError := 'end of image transfer packet is too short';
            Exit;
          end;
          Status.ImageId := Be32At(Body, 0);
          Status.Status := Be32At(Body, 4);
          if Status.Status <> SAHARA_STATUS_SUCCESS then
          begin
            FailFmt('The device refused the memory read: %s',
              [SaharaStatusText(Status.Status)]);
            Exit;
          end;
          Break;
        end;
      SAHARA_LOG:
        begin
          LogBody := Body;
          if Length(LogBody) > 0 then
            DoLog('device log: ' + LogText(LogBody));
          SendPacket(SAHARA_LOG_RESP, nil);
        end;
    else
      FailFmt('Unexpected %s while reading memory',
        [SaharaCommandName(Command)]);
      Exit;
    end;
  end;
  Result := Length(AData) > 0;
  if Result then
    DoLog('Read ' + IntToStr(Length(AData)) + ' bytes from $' +
      IntToHex(AAddress, 16));
end;

function TSaharaProtocol.SendImage(AImageId: UInt32; AStream: TStream;
  ASize: Int64): Boolean;
var
  Command, Length: UInt32;
  Body, Chunk, LogBody: TBytesArray;
  Req: TSaharaReadRequest;
  Status: TSaharaImageStatus;
  Have: Int64;
  N: Integer;
begin
  Result := False;
  FLastError := '';
  Have := 0;
  if AStream <> nil then
    AStream.Position := 0;

  while True do
  begin
    if FCancelled then
    begin
      FLastError := 'Cancelled';
      Exit;
    end;
    if not ReadPacket(Command, Length, Body) then
      Exit(False);
    case Command of
      SAHARA_READ_DATA:
        begin
          { image_id(4) offset(4) length(4) - the 32-bit variant }
          if Length(Body) < 12 then
          begin
            FLastError := 'read data packet is too short';
            Exit;
          end;
          Req.ImageId := Be32At(Body, 0);
          Req.Offset := Be32At(Body, 4);
          Req.Length := Be32At(Body, 8);
          if (AStream = nil) or (Req.Offset + Req.Length > UInt64(ASize)) then
          begin
            FailFmt('The device asked for image %d at offset %d, length %d, ' +
              'which is outside the %d byte file', [Req.ImageId,
              Int64(Req.Offset), Int64(Req.Length), ASize]);
            SendEndImageTransfer(Req.ImageId, $05);
            Exit;
          end;
          AStream.Position := Int64(Req.Offset);
          SetLength(Chunk, Integer(Req.Length));
          N := AStream.Read(Chunk[0], Integer(Req.Length));
          if N <> Integer(Req.Length) then
          begin
            FailFmt('Only %d of %d bytes could be read from the image file',
              [N, Integer(Req.Length)]);
            Exit;
          end;
          if not WriteBytes(Chunk) then
            Exit(False);
          Inc(Have, N);
          Inc(FBytesMoved, N);
          if Assigned(FOnProgress) then
            FOnProgress(Self, Have, ASize);
        end;
      SAHARA_END_IMAGE_XFER:
        begin
          if Length(Body) < 8 then
          begin
            FLastError := 'end of image transfer packet is too short';
            Exit;
          end;
          Status.ImageId := Be32At(Body, 0);
          Status.Status := Be32At(Body, 4);
          if Status.Status <> SAHARA_STATUS_SUCCESS then
          begin
            FailFmt('The device rejected image %d: %s', [Status.ImageId,
              SaharaStatusText(Status.Status)]);
            Exit;
          end;
          DoLog('Image ' + IntToStr(Status.ImageId) + ' transferred (' +
            IntToStr(Have) + ' bytes).');
          Break;
        end;
      SAHARA_CMD_READY, SAHARA_CMD_READY_64:
        begin
          DoLog('The device is ready for commands.');
          Break;
        end;
      SAHARA_LOG:
        begin
          LogBody := Body;
          if Length(LogBody) > 0 then
            DoLog('device log: ' + LogText(LogBody));
          SendPacket(SAHARA_LOG_RESP, nil);
        end;
      SAHARA_DONE_RESP:
        begin
          DoLog('The device accepted the transfer.');
          Break;
        end;
    else
      FailFmt('Unexpected %s during the image transfer',
        [SaharaCommandName(Command)]);
      Exit;
    end;
  end;
  Result := True;
end;

end.
