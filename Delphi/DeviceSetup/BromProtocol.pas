unit BromProtocol;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

{ MediaTek BootROM / Preloader protocol.

  What actually happens on the wire, and where it comes from:

  HANDSHAKE
    The BootROM listens for a fraction of a second after the cable goes in.
    The host sends $A0 $0A $50 $05 one byte at a time; the BootROM answers
    each byte with its bitwise complement ($5F $F5 $AF $FA). A wrong answer
    restarts the sequence. This is the "device detected" moment - and the
    reason the port has to be locked before anything else: if another program
    drains those four bytes the window is gone and the phone boots on.

  COMMAND ECHO
    Every command is echoed back by the device. So is every argument, sent
    big-endian. A command is therefore: write, read the same byte back.
    After the arguments comes a 16-bit big-endian status; values up to $00FF
    mean "accepted", anything above is an error whose name is in MtkStatus.

  IDENTIFICATION
    $FD GET_HW_CODE   -> dword: low word = hw version, high word = hw code.
                         The hw code identifies the chip (MtkChips).
    $FE GET_BL_VER    -> 1 byte. If the answer is $FE itself we are still in
                         the BootROM; otherwise it is the preloader version.
    $FF GET_VERSION   -> 1 byte, BootROM version.
    $F8 GET_TARGET_CONFIG -> dword of security flags + status.
    $FC GET_HW_SW_VER -> 4 big-endian words: subcode, hw ver, sw ver.
    $E1 GET_ME_ID, $E7 GET_SOC_ID -> echo, dword length, data, word status.

  MEMORY
    $D1 READ32  / $D0 READ16  / $D3 WRITE32 / $D2 WRITE16:
      echo cmd, echo address (BE32), echo count (BE32), read status word;
      reads then return the values followed by a second status word, writes
      echo each value (BE) followed by a second status word.

  DOWNLOAD AGENT
    $D7 SEND_DA: echo cmd, address, size, signature length; status; then the
      payload and a 16-bit XOR checksum over little-endian word pairs.
    $D5 JUMP_DA / $DE JUMP_DA64: echo cmd, address, read the address back,
      read status 0. The device is now running the DA.

  SECURITY
    $E2 SEND_AUTH and $E0 SEND_CERT upload the vendor authentication and
      root-certificate blobs the Files box asks for.
    $E3 SLA is the Secure Link Authentication challenge. It needs an RSA
      private key that ships with the vendor tool and is not part of this
      repository; when a device demands it we report exactly that instead of
      pretending to succeed.

  Derived from the publicly documented MediaTek BootROM protocol
  (bkerler/mtkclient, GPLv3: Library/Port.py, Library/mtk_preloader.py). }

interface

uses
{$IFDEF FPC}
  Classes, SysUtils,
{$ELSE}
  System.Classes,
  System.SysUtils,
{$ENDIF}
  DevTypes, CommPort, MtkChips, MtkStatus;

type
  TBromLogEvent = procedure(Sender: TObject; const AText: string) of object;

  { Security flags reported by GET_TARGET_CONFIG ($F8). }
  TTargetConfig = record
    Raw: UInt32;
    Sbc: Boolean;        { secure boot control }
    Sla: Boolean;        { secure link authentication required }
    Daa: Boolean;        { download agent authentication required }
    SwJtag: Boolean;
    Epp: Boolean;        { EPP_PARAM at $600 after EMMC_BOOT/SDMMC_BOOT }
    Cert: Boolean;       { root certificate required }
    MemReadAuth: Boolean;
    MemWriteAuth: Boolean;
    CmdC8Blocked: Boolean;
  end;

  TBromProtocol = class(TObject)
  private
    FTransport: TCommTransport;
    FTimeout: Integer;
    FOnLog: TBromLogEvent;
    FLastError: string;
    FLastStatus: Word;
    FHwCode: Word;
    FHwVer: Word;
    FHwSubCode: Word;
    FSwVer: Word;
    FBlVer: Integer;
    FBromVer: Integer;
    FIsBrom: Boolean;
    FChip: TMtkChipInfo;
    FChipKnown: Boolean;
    FTarget: TTargetConfig;
    FHandshook: Boolean;
    FCancelled: Boolean;

    { --- wire primitives --- }
    function WriteRaw(const AData; ACount: Integer): Boolean;
    function WriteBytes(const AData: TBytesArray): Boolean;
    function ReadBytes(ACount: Integer; out AData: TBytesArray): Boolean;
    function ReadByte(out AValue: Byte): Boolean;
    function WriteByte(AValue: Byte): Boolean;
    function ReadWordBe(out AValue: Word): Boolean;
    function ReadDwordBe(out AValue: UInt32): Boolean;
    function WriteWordBe(AValue: Word): Boolean;
    function WriteDwordBe(AValue: UInt32): Boolean;
    function EchoByte(AValue: Byte): Boolean;
    function EchoBytes(const AData: TBytesArray): Boolean;
    function EchoDwordBe(AValue: UInt32): Boolean;

    procedure DoLog(const AText: string);
    procedure FailFmt(const AFmt: string; const AArgs: array of const);
    function ReadValues(AAddr: UInt32; ACount: Integer; AWordSize: Integer;
      out AValues: TBytesArray): Boolean;
    function WriteValues(AAddr: UInt32; const AValues: TBytesArray;
      AWordSize: Integer): Boolean;
    function GetIdBlob(ACmd: Byte; out ABlob: TBytesArray): Boolean;
    function UploadPayload(const AData: TBytesArray; AChecksum: Word): Boolean;
    function PrepareChecksum(var AData: TBytesArray): Word;
    function SlaRequired: Boolean;
  public
    constructor Create(ATransport: TCommTransport);

    { The A0 0A 50 05 / 5F F5 AF FA exchange. ARetries attempts. }
    function Handshake(ARetries: Integer = 40): Boolean;
    { Handshake + identify the chip + read the target configuration. }
    function Connect: Boolean;

    function GetHwCode(out AValue: UInt32): Boolean;
    function GetBlVer: Integer;
    function GetBromVer: Integer;
    function GetTargetConfig(out AConfig: TTargetConfig): Boolean;
    function GetHwSwVer(out ASubCode, AHwVer, ASwVer: Word): Boolean;
    function GetMeId(out AMeId: TBytesArray): Boolean;
    function GetSocId(out ASocId: TBytesArray): Boolean;

    function DisableWatchdog: Boolean;
    function Read16(AAddr: UInt32; ACount: Integer; out AValues: TBytesArray): Boolean;
    function Read32(AAddr: UInt32; ACount: Integer; out AValues: TBytesArray): Boolean;
    function Write16(AAddr: UInt32; const AValues: TBytesArray): Boolean;
    function Write32(AAddr: UInt32; const AValues: TBytesArray): Boolean;
    { AData is padded to a multiple of 4 with zeros. }
    function WriteMem(AAddr: UInt32; const AData: TBytesArray): Boolean;
    function ReadMem(AAddr: UInt32; ALength: Integer; out AData: TBytesArray): Boolean;

    function SendAuth(const AAuth: TBytesArray): Boolean;
    function SendCert(const ACert: TBytesArray): Boolean;
    function SendDa(AAddress: UInt32; const ADa: TBytesArray; ASigLen: Integer): Boolean;
    function JumpDa(AAddress: UInt32): Boolean;
    function JumpDa64(AAddress: UInt32): Boolean;
    function JumpBl: Boolean;

    procedure Cancel;
    procedure ResetCancel;

    property Transport: TCommTransport read FTransport;
    property TimeoutMs: Integer read FTimeout write FTimeout;
    property OnLog: TBromLogEvent read FOnLog write FOnLog;
    property LastError: string read FLastError;
    property LastStatus: Word read FLastStatus;
    property HwCode: Word read FHwCode;
    property HwVer: Word read FHwVer;
    property HwSubCode: Word read FHwSubCode;
    property SwVer: Word read FSwVer;
    property BlVer: Integer read FBlVer;
    property BromVer: Integer read FBromVer;
    property IsBrom: Boolean read FIsBrom;
    property Chip: TMtkChipInfo read FChip;
    property ChipKnown: Boolean read FChipKnown;
    property Target: TTargetConfig read FTarget;
    property Handshook: Boolean read FHandshook;
  end;

const
  { BootROM / Preloader commands.

    Every value here is taken from the public command table in mtkclient's
    mtk_preloader.py (class Cmd). Commands whose value that table does not
    define are deliberately absent: an invented byte would be sent to a real
    phone and could put its boot ROM into an undefined state.

    Corrections this table encodes, because a wrong byte fails silently:
      WRITE32 is $D4, not $D3 ($D3 is WRITE16_NO_ECHO)
      JUMP_BL is $D6, not $A9
      GET_TARGET_CONFIG is $D8, not $F8
      JUMP_DA64 is $DE
      JUMP_MAUI is $B7 (the table lists it beside I2C_DEINIT_EX) }
  SEND_PARTITION_DATA = $70;   { with CFG_PRELOADER_AS_DA }
  JUMP_TO_PARTITION   = $71;
  CMD_USB_CHECK_STATUS = $72;  { CHECK_USB_CMD }
  STAY_STILL          = $80;
  CMD_READ16_A2       = $A2;
  CMD_JUMP_MAUI       = $B7;   { I2C_DEINIT_EX in the public table }
  OLD_SLA_SEND_AUTH   = $C1;
  OLD_SLA_GET_RN      = $C2;
  OLD_SLA_VERIFY_RN   = $C3;
  CMD_PWR_INIT1       = $C4;   { PWR_INIT }
  CMD_PWR_INIT2       = $C5;   { PWR_DEINIT }
  CMD_PWR_READ16      = $C6;
  CMD_PWR_WRITE16     = $C7;
  CMD_CACHE_CTRL      = $C8;   { CMD_C8 }
  CMD_READ16          = $D0;
  CMD_READ32          = $D1;
  CMD_WRITE16         = $D2;
  CMD_WRITE16_NO_ECHO = $D3;
  CMD_WRITE32         = $D4;
  CMD_JUMP_DA         = $D5;
  CMD_JUMP_BL         = $D6;
  CMD_SEND_DA         = $D7;
  CMD_GET_TARGET_CONFIG = $D8;
  CMD_SEND_ENV_PREPARE  = $D9;
  CMD_BROM_REGISTER_ACCESS = $DA;
  CMD_UART1_LOG_EN    = $DB;
  CMD_UART1_SET_BAUDRATE = $DC;
  CMD_BROM_DEBUGLOG   = $DD;
  CMD_JUMP_DA64       = $DE;
  CMD_GET_BROM_LOG_NEW = $DF;
  CMD_SEND_CERT       = $E0;   { DA_CHK_PC_SEC_INFO_CMD }
  CMD_GET_ME_ID       = $E1;
  CMD_SEND_AUTH       = $E2;
  CMD_SLA             = $E3;
  CMD_GET_SOC_ID      = $E7;
  CMD_ZEROIZATION     = $F0;
  CMD_GET_PL_CAP      = $FB;
  CMD_GET_HW_SW_VER   = $FC;
  CMD_GET_HW_CODE     = $FD;
  CMD_GET_BL_VER      = $FE;
  CMD_GET_VERSION     = $FF;

  { Boot-loader response codes (class Rsp). }
  RSP_NONE = $00;
  RSP_CONF = $69;
  RSP_STOP = $96;
  RSP_ACK  = $5A;
  RSP_NACK = $A5;

  { PL_CAP0 bits (class Cap). }
  PL_CAP0_XFLASH_SUPPORT = 1 shl 0;
  PL_CAP0_MEID_SUPPORT   = 1 shl 1;
  PL_CAP0_SOCID_SUPPORT  = 1 shl 2;

  { The four-byte BootROM wake-up and its complement. }
  BROM_HANDSHAKE: array[0..3] of Byte = ($A0, $0A, $50, $05);
  BROM_HANDSHAKE_ACK: array[0..3] of Byte = ($5F, $F5, $AF, $FA);

  S_BROM_OK = $0000;
  S_BROM_SLT_FAIL = $100A;
  S_BROM_SLA_REQUIRED = $1D0D;
  S_DA_SLA_REQUIRED = $7017;
  S_DA_IMAGE_SIG_VERIFY_FAIL = $2001;

{ 'A0 0A 50 05' style dump of a byte buffer, at most AMax bytes shown. }
function HexDump(const AData: TBytesArray; AMax: Integer = 32): string;
function BytesOfStream(AStream: TStream): TBytesArray;
function TargetConfigText(const AConfig: TTargetConfig): string;

implementation

function HexDump(const AData: TBytesArray; AMax: Integer): string;
var
  I, N: Integer;
begin
  Result := '';
  N := Length(AData);
  if N > AMax then
    N := AMax;
  for I := 0 to N - 1 do
  begin
    if I > 0 then
      Result := Result + ' ';
    Result := Result + IntToHex(AData[I], 2);
  end;
  if Length(AData) > AMax then
    Result := Result + ' ... (' + IntToStr(Length(AData)) + ' bytes)';
end;

function BytesOfStream(AStream: TStream): TBytesArray;
var
  N: Int64;
begin
  SetLength(Result, 0);
  if AStream = nil then
    Exit;
  AStream.Position := 0;
  N := AStream.Size;
  if (N <= 0) or (N > 512 * 1024 * 1024) then
    Exit;
  SetLength(Result, N);
  if N > 0 then
    AStream.ReadBuffer(Result[0], N);
end;

function TargetConfigText(const AConfig: TTargetConfig): string;
begin
  Result := 'target config $' + IntToHex(AConfig.Raw, 8) + ':' +
    ' SBC=' + BoolToStr(AConfig.Sbc, True) +
    ' SLA=' + BoolToStr(AConfig.Sla, True) +
    ' DAA=' + BoolToStr(AConfig.Daa, True) +
    ' SWJTAG=' + BoolToStr(AConfig.SwJtag, True) +
    ' EPP=' + BoolToStr(AConfig.Epp, True) +
    ' CERT=' + BoolToStr(AConfig.Cert, True) +
    ' MEMREAD=' + BoolToStr(AConfig.MemReadAuth, True) +
    ' MEMWRITE=' + BoolToStr(AConfig.MemWriteAuth, True) +
    ' C8BLOCKED=' + BoolToStr(AConfig.CmdC8Blocked, True);
end;

{ ------------------------------------------------------------- TBromProtocol }

constructor TBromProtocol.Create(ATransport: TCommTransport);
begin
  inherited Create;
  FTransport := ATransport;
  FTimeout := CDefaultIoTimeoutMs;
  FLastError := '';
  FLastStatus := 0;
  FHwCode := 0;
  FHwVer := 0;
  FHwSubCode := 0;
  FSwVer := 0;
  FBlVer := -1;
  FBromVer := -1;
  FIsBrom := False;
  FChipKnown := False;
  FHandshook := False;
  FCancelled := False;
  FChip := CGenericChip;
end;

procedure TBromProtocol.Cancel;
begin
  FCancelled := True;
end;

procedure TBromProtocol.ResetCancel;
begin
  FCancelled := False;
end;

procedure TBromProtocol.DoLog(const AText: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, AText);
end;

procedure TBromProtocol.FailFmt(const AFmt: string; const AArgs: array of const);
begin
  FLastError := Format(AFmt, AArgs);
end;

{ ------------------------------------------------------------ wire primitives }

function TBromProtocol.WriteRaw(const AData; ACount: Integer): Boolean;
begin
  if FCancelled or (FTransport = nil) then
    Exit(False);
  Result := FTransport.WriteData(AData, ACount) = ACount;
  if not Result then
    FLastError := 'Write failed after ' + IntToStr(ACount) + ' byte(s)';
end;

function TBromProtocol.WriteBytes(const AData: TBytesArray): Boolean;
begin
  if Length(AData) = 0 then
    Exit(True);
  Result := WriteRaw(AData[0], Length(AData));
end;

function TBromProtocol.ReadByte(out AValue: Byte): Boolean;
var
  N: Integer;
begin
  AValue := 0;
  if FCancelled or (FTransport = nil) then
    Exit(False);
  N := FTransport.ReadData(AValue, 1, FTimeout);
  Result := N = 1;
  if not Result then
    FLastError := 'No answer from the device (' + IntToStr(FTimeout) + ' ms timeout)';
end;

function TBromProtocol.WriteByte(AValue: Byte): Boolean;
begin
  Result := WriteRaw(AValue, 1);
end;

function TBromProtocol.ReadBytes(ACount: Integer; out AData: TBytesArray): Boolean;
var
  Got, Total: Integer;
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
      SetLength(AData, 0);
      Exit(False);
    end;
    { One byte at a time: the transport returns as soon as something arrives,
      and a short read must not be mistaken for the end of the answer. }
    Got := FTransport.ReadData(B, 1, FTimeout);
    if Got <> 1 then
    begin
      SetLength(AData, 0);
      FLastError := 'Short read: wanted ' + IntToStr(ACount) + ' byte(s), got ' +
        IntToStr(Total);
      Exit(False);
    end;
    AData[Total] := B;
    Inc(Total);
  end;
  Result := True;
end;

function TBromProtocol.ReadWordBe(out AValue: Word): Boolean;
var
  D: TBytesArray;
begin
  AValue := 0;
  if not ReadBytes(2, D) then
    Exit(False);
  AValue := (Word(D[0]) shl 8) or Word(D[1]);
  Result := True;
end;

function TBromProtocol.ReadDwordBe(out AValue: UInt32): Boolean;
var
  D: TBytesArray;
begin
  AValue := 0;
  if not ReadBytes(4, D) then
    Exit(False);
  AValue := (UInt32(D[0]) shl 24) or (UInt32(D[1]) shl 16) or
    (UInt32(D[2]) shl 8) or UInt32(D[3]);
  Result := True;
end;

function TBromProtocol.WriteWordBe(AValue: Word): Boolean;
var
  D: TBytesArray;
begin
  SetLength(D, 2);
  D[0] := Byte(AValue shr 8);
  D[1] := Byte(AValue and $FF);
  Result := WriteBytes(D);
end;

function TBromProtocol.WriteDwordBe(AValue: UInt32): Boolean;
var
  D: TBytesArray;
begin
  SetLength(D, 4);
  D[0] := Byte(AValue shr 24);
  D[1] := Byte((AValue shr 16) and $FF);
  D[2] := Byte((AValue shr 8) and $FF);
  D[3] := Byte(AValue and $FF);
  Result := WriteBytes(D);
end;

{ Writes one byte and checks that the device echoes the same byte back. This
  is the backbone of the protocol: every command and every argument is echoed. }
function TBromProtocol.EchoByte(AValue: Byte): Boolean;
var
  B: Byte;
begin
  if not WriteByte(AValue) then
    Exit(False);
  if not ReadByte(B) then
    Exit(False);
  if B <> AValue then
  begin
    FailFmt('Echo mismatch: sent $%02X, got $%02X', [AValue, B]);
    Exit(False);
  end;
  Result := True;
end;

function TBromProtocol.EchoBytes(const AData: TBytesArray): Boolean;
var
  I: Integer;
begin
  for I := 0 to High(AData) do
    if not EchoByte(AData[I]) then
      Exit(False);
  Result := True;
end;

function TBromProtocol.EchoDwordBe(AValue: UInt32): Boolean;
var
  D: TBytesArray;
begin
  SetLength(D, 4);
  D[0] := Byte(AValue shr 24);
  D[1] := Byte((AValue shr 16) and $FF);
  D[2] := Byte((AValue shr 8) and $FF);
  D[3] := Byte(AValue and $FF);
  Result := EchoBytes(D);
end;

{ ----------------------------------------------------------------- handshake }

function TBromProtocol.Handshake(ARetries: Integer): Boolean;
var
  Attempt, I: Integer;
  Sent: Byte;
  Answer: Byte;
begin
  Result := False;
  FLastError := '';
  if FTransport = nil then
  begin
    FLastError := 'No transport attached';
    Exit;
  end;
  if not FTransport.PortOpen then
  begin
    FLastError := 'The device port is not open';
    Exit;
  end;
  if ARetries < 1 then
    ARetries := 1;

  for Attempt := 1 to ARetries do
  begin
    if FCancelled then
    begin
      FLastError := 'Cancelled';
      Exit;
    end;
    I := 0;
    while I <= High(BROM_HANDSHAKE) do
    begin
      Sent := BROM_HANDSHAKE[I];
      if not WriteByte(Sent) then
      begin
        I := 0;
        Break;
      end;
      Answer := 0;
      if FTransport.ReadData(Answer, 1, 200) <> 1 then
      begin
        { The BootROM window closed, or the phone is not in BROM yet. Start
          the whole sequence again - a partial handshake never recovers. }
        I := 0;
        Break;
      end;
      if Answer = Byte(not Sent) then
        Inc(I)
      else
        I := 0;
    end;
    if I > High(BROM_HANDSHAKE) then
    begin
      FHandshook := True;
      DoLog('Handshake successful: A0 0A 50 05 -> 5F F5 AF FA');
      Exit(True);
    end;
    Sleep(10);
  end;
  FHandshook := False;
  if FLastError = '' then
    FLastError := 'Handshake failed after ' + IntToStr(ARetries) +
      ' attempt(s). Is the phone powered off and in BROM/Preloader mode?';
end;

function TBromProtocol.GetHwCode(out AValue: UInt32): Boolean;
begin
  AValue := 0;
  Result := EchoByte(CMD_GET_HW_CODE) and ReadDwordBe(AValue);
  if not Result then
    DoLog('GET_HW_CODE: ' + FLastError);
end;

function TBromProtocol.GetBlVer: Integer;
var
  B: Byte;
begin
  FBlVer := -1;
  if not WriteByte(CMD_GET_BL_VER) then
    Exit(-1);
  if not ReadByte(B) then
    Exit(-1);
  if B = CMD_GET_BL_VER then
  begin
    { The BootROM answers with the command itself: no bootloader yet. }
    FIsBrom := True;
    FBlVer := 0;
  end
  else
  begin
    FIsBrom := False;
    FBlVer := B;
  end;
  Result := FBlVer;
end;

function TBromProtocol.GetBromVer: Integer;
var
  B: Byte;
begin
  FBromVer := -1;
  if WriteByte(CMD_GET_VERSION) and ReadByte(B) then
    FBromVer := B;
  Result := FBromVer;
end;

function TBromProtocol.GetTargetConfig(out AConfig: TTargetConfig): Boolean;
var
  Raw: UInt32;
  Status: Word;
begin
  AConfig.Raw := 0;
  AConfig.Sbc := False;
  AConfig.Sla := False;
  AConfig.Daa := False;
  AConfig.SwJtag := False;
  AConfig.Epp := False;
  AConfig.Cert := False;
  AConfig.MemReadAuth := False;
  AConfig.MemWriteAuth := False;
  AConfig.CmdC8Blocked := False;

  if not EchoByte(CMD_GET_TARGET_CONFIG) then
    Exit(False);
  if not ReadDwordBe(Raw) then
    Exit(False);
  if not ReadWordBe(Status) then
    Exit(False);
  FLastStatus := Status;
  if not StatusIsOk(Status) then
  begin
    FailFmt('GET_TARGET_CONFIG rejected: %s', [StatusText(Status)]);
    Exit(False);
  end;

  AConfig.Raw := Raw;
  AConfig.Sbc := (Raw and $01) <> 0;
  AConfig.Sla := (Raw and $02) <> 0;
  AConfig.Daa := (Raw and $04) <> 0;
  AConfig.SwJtag := (Raw and $06) <> 0;
  AConfig.Epp := (Raw and $08) <> 0;
  AConfig.Cert := (Raw and $10) <> 0;
  AConfig.MemReadAuth := (Raw and $20) <> 0;
  AConfig.MemWriteAuth := (Raw and $40) <> 0;
  AConfig.CmdC8Blocked := (Raw and $80) <> 0;
  FTarget := AConfig;
  Result := True;
end;

function TBromProtocol.GetHwSwVer(out ASubCode, AHwVer, ASwVer: Word): Boolean;
var
  W: array[0..3] of Word;
  I: Integer;
begin
  ASubCode := 0;
  AHwVer := 0;
  ASwVer := 0;
  if not EchoByte(CMD_GET_HW_SW_VER) then
    Exit(False);
  for I := 0 to 3 do
    if not ReadWordBe(W[I]) then
      Exit(False);
  FHwSubCode := W[0];
  FHwVer := W[1];
  FSwVer := W[2];
  ASubCode := W[0];
  AHwVer := W[1];
  ASwVer := W[2];
  Result := True;
end;

function TBromProtocol.GetIdBlob(ACmd: Byte; out ABlob: TBytesArray): Boolean;
var
  Len: UInt32;
  Status: Word;
  B: Byte;
  Tail: TBytesArray;
begin
  SetLength(ABlob, 0);
  if not WriteByte(ACmd) then
    Exit(False);
  if not ReadByte(B) then
    Exit(False);
  if B <> ACmd then
  begin
    FailFmt('GET_ID $%02X: unexpected echo $%02X', [ACmd, B]);
    Exit(False);
  end;
  if not ReadDwordBe(Len) then
    Exit(False);
  if (Len = 0) or (Len > 4096) then
  begin
    FailFmt('GET_ID $%02X: implausible length %d', [ACmd, Len]);
    Exit(False);
  end;
  if not ReadBytes(Integer(Len), ABlob) then
    Exit(False);
  { The trailing status word of these two commands is little-endian. }
  if not ReadBytes(2, Tail) then
    Exit(False);
  Status := Word(Tail[0]) or (Word(Tail[1]) shl 8);
  FLastStatus := Status;
  if Status <> 0 then
  begin
    FailFmt('GET_ID $%02X failed: %s', [ACmd, StatusText(Status)]);
    SetLength(ABlob, 0);
    Exit(False);
  end;
  Result := True;
end;

function TBromProtocol.GetMeId(out AMeId: TBytesArray): Boolean;
begin
  Result := GetIdBlob(CMD_GET_ME_ID, AMeId);
end;

function TBromProtocol.GetSocId(out ASocId: TBytesArray): Boolean;
begin
  Result := GetIdBlob(CMD_GET_SOC_ID, ASocId);
end;

{ ------------------------------------------------------------------- memory }

function TBromProtocol.ReadValues(AAddr: UInt32; ACount: Integer;
  AWordSize: Integer; out AValues: TBytesArray): Boolean;
var
  Cmd: Byte;
  Status: Word;
  ByteCount: Integer;
begin
  SetLength(AValues, 0);
  if ACount <= 0 then
    Exit(True);
  if AWordSize = 16 then
    Cmd := CMD_READ16
  else
    Cmd := CMD_READ32;

  if not EchoByte(Cmd) then
    Exit(False);
  if not EchoDwordBe(AAddr) then
    Exit(False);
  if not EchoDwordBe(UInt32(ACount)) then
    Exit(False);
  if not ReadWordBe(Status) then
    Exit(False);
  FLastStatus := Status;
  if Status > $00FF then
  begin
    FailFmt('READ%d at $%08X failed: %s', [AWordSize, AAddr, StatusText(Status)]);
    Exit(False);
  end;

  ByteCount := ACount * (AWordSize div 8);
  if not ReadBytes(ByteCount, AValues) then
    Exit(False);
  if not ReadWordBe(Status) then
    Exit(False);
  FLastStatus := Status;
  if Status > $00FF then
  begin
    FailFmt('READ%d at $%08X completed with %s',
      [AWordSize, AAddr, StatusText(Status)]);
    Exit(False);
  end;
  Result := True;
end;

function TBromProtocol.WriteValues(AAddr: UInt32; const AValues: TBytesArray;
  AWordSize: Integer): Boolean;
var
  Cmd: Byte;
  Status: Word;
  ElemSize, Count, I: Integer;
  WordValue: Word;
  DwordValue: UInt32;
begin
  ElemSize := AWordSize div 8;
  if Length(AValues) = 0 then
    Exit(True);
  if (Length(AValues) mod ElemSize) <> 0 then
  begin
    FLastError := 'WRITE' + IntToStr(AWordSize) + ': data is not a multiple of ' +
      IntToStr(ElemSize) + ' bytes';
    Exit(False);
  end;
  Count := Length(AValues) div ElemSize;
  if AWordSize = 16 then
    Cmd := CMD_WRITE16
  else
    Cmd := CMD_WRITE32;

  if not EchoByte(Cmd) then
    Exit(False);
  if not EchoDwordBe(AAddr) then
    Exit(False);
  if not EchoDwordBe(UInt32(Count)) then
    Exit(False);
  if not ReadWordBe(Status) then
    Exit(False);
  FLastStatus := Status;
  if Status > 3 then
  begin
    FailFmt('WRITE%d at $%08X refused: %s',
      [AWordSize, AAddr, StatusText(Status)]);
    Exit(False);
  end;

  for I := 0 to Count - 1 do
  begin
    if AWordSize = 16 then
    begin
      WordValue := (Word(AValues[I * 2]) shl 8) or Word(AValues[I * 2 + 1]);
      if not WriteWordBe(WordValue) then
        Exit(False);
    end
    else
    begin
      DwordValue := (UInt32(AValues[I * 4]) shl 24) or
        (UInt32(AValues[I * 4 + 1]) shl 16) or
        (UInt32(AValues[I * 4 + 2]) shl 8) or UInt32(AValues[I * 4 + 3]);
      if not WriteDwordBe(DwordValue) then
        Exit(False);
    end;
  end;

  if not ReadWordBe(Status) then
    Exit(False);
  FLastStatus := Status;
  if Status > $00FF then
  begin
    FailFmt('WRITE%d at $%08X failed: %s',
      [AWordSize, AAddr, StatusText(Status)]);
    Exit(False);
  end;
  Result := True;
end;

function TBromProtocol.Read16(AAddr: UInt32; ACount: Integer;
  out AValues: TBytesArray): Boolean;
begin
  Result := ReadValues(AAddr, ACount, 16, AValues);
end;

function TBromProtocol.Read32(AAddr: UInt32; ACount: Integer;
  out AValues: TBytesArray): Boolean;
begin
  Result := ReadValues(AAddr, ACount, 32, AValues);
end;

function TBromProtocol.Write16(AAddr: UInt32; const AValues: TBytesArray): Boolean;
begin
  Result := WriteValues(AAddr, AValues, 16);
end;

function TBromProtocol.Write32(AAddr: UInt32; const AValues: TBytesArray): Boolean;
begin
  Result := WriteValues(AAddr, AValues, 32);
end;

function TBromProtocol.WriteMem(AAddr: UInt32; const AData: TBytesArray): Boolean;
var
  Padded: TBytesArray;
  N, I: Integer;
begin
  N := Length(AData);
  if N = 0 then
    Exit(True);
  if (N mod 4) <> 0 then
    N := N + (4 - (N mod 4));
  SetLength(Padded, N);
  for I := 0 to N - 1 do
    if I < Length(AData) then
      Padded[I] := AData[I]
    else
      Padded[I] := 0;
  Result := Write32(AAddr, Padded);
end;

function TBromProtocol.ReadMem(AAddr: UInt32; ALength: Integer;
  out AData: TBytesArray): Boolean;
var
  Chunk, Offset, Count: Integer;
  Part: TBytesArray;
  I: Integer;
begin
  SetLength(AData, 0);
  if ALength <= 0 then
    Exit(True);
  SetLength(AData, ALength);
  Offset := 0;
  { BootROM answers at most a few hundred dwords per command. }
  while Offset < ALength do
  begin
    Count := ALength - Offset;
    if Count > 512 then
      Count := 512;
    Chunk := (Count + 3) div 4;
    if not Read32(AAddr + UInt32(Offset), Chunk, Part) then
      Exit(False);
    for I := 0 to Count - 1 do
      AData[Offset + I] := Part[I];
    Inc(Offset, Chunk * 4);
  end;
  SetLength(AData, ALength);
  Result := True;
end;

function TBromProtocol.DisableWatchdog: Boolean;
var
  Values: TBytesArray;
  Reg: UInt32;
begin
  { SetReg_DisableWatchDogTimer: the watchdog has to be stopped or the phone
    resets in the middle of a long transfer. }
  if (FHwCode = $2625) or (FHwCode = $2523) or (FHwCode = $7682) or
     (FHwCode = $7686) or (FHwCode = $5932) then
  begin
    SetLength(Values, 2);
    Values[0] := $22;
    Values[1] := $00;
    Result := Write16($A2050000, Values);
  end
  else
  begin
    Reg := FChip.Watchdog;
    if Reg = 0 then
      Reg := $10007000;
    SetLength(Values, 4);
    Values[0] := $22;
    Values[1] := $00;
    Values[2] := $00;
    Values[3] := $00;
    Result := Write32(Reg, Values);
  end;
  if Result then
    DoLog('Watchdog disabled.')
  else
    DoLog('Could not disable the watchdog: ' + FLastError);
end;

{ ------------------------------------------------------------------- uploads }

function TBromProtocol.PrepareChecksum(var AData: TBytesArray): Word;
var
  Sum: Word;
  I: Integer;
  W: Word;
begin
  { Odd length is padded with one zero byte, then every little-endian word is
    XORed together. This is the checksum the BootROM compares against. }
  if (Length(AData) mod 2) <> 0 then
  begin
    SetLength(AData, Length(AData) + 1);
    AData[High(AData)] := 0;
  end;
  Sum := 0;
  I := 0;
  while I < Length(AData) - 1 do
  begin
    W := Word(AData[I]) or (Word(AData[I + 1]) shl 8);
    Sum := Sum xor W;
    Inc(I, 2);
  end;
  Result := Sum;
end;

function TBromProtocol.UploadPayload(const AData: TBytesArray; AChecksum: Word): Boolean;
var
  Chunk, Pos, N: Integer;
  GotChecksum, Status: Word;
  Empty: TBytesArray;
begin
  SetLength(Empty, 0);
  N := Length(AData);
  Pos := 0;
  Chunk := $400;
  while Pos < N do
  begin
    if FCancelled then
      Exit(False);
    if N - Pos < Chunk then
      Chunk := N - Pos;
    if not WriteRaw(AData[Pos], Chunk) then
      Exit(False);
    Inc(Pos, Chunk);
    if (Pos mod $2000) = 0 then
      WriteBytes(Empty);   { zero-length packet: flush the pipe }
  end;
  WriteBytes(Empty);
  Sleep(120);

  if not ReadWordBe(GotChecksum) then
    Exit(False);
  if not ReadWordBe(Status) then
    Exit(False);
  FLastStatus := Status;
  if (GotChecksum <> AChecksum) and (GotChecksum <> 0) then
    DoLog('Warning: upload checksum $' + IntToHex(GotChecksum, 4) +
      ' does not match the computed $' + IntToHex(AChecksum, 4));
  if not StatusIsOk(Status) then
  begin
    FailFmt('Upload rejected: %s', [StatusText(Status)]);
    Exit(False);
  end;
  Result := True;
end;

function TBromProtocol.SendDa(AAddress: UInt32; const ADa: TBytesArray;
  ASigLen: Integer): Boolean;
var
  Payload: TBytesArray;
  Checksum: Word;
  Status: Word;
  N, I: Integer;
begin
  Result := False;
  N := Length(ADa);
  if N = 0 then
  begin
    FLastError := 'The download agent is empty';
    Exit;
  end;
  if (ASigLen < 0) or (ASigLen > N) then
    ASigLen := 0;

  SetLength(Payload, N);
  for I := 0 to N - 1 do
    Payload[I] := ADa[I];
  Checksum := PrepareChecksum(Payload);

  if not EchoByte(CMD_SEND_DA) then
    Exit;
  if not EchoDwordBe(AAddress) then
    Exit;
  if not EchoDwordBe(UInt32(Length(Payload))) then
    Exit;
  if not EchoDwordBe(UInt32(ASigLen)) then
    Exit;
  if not ReadWordBe(Status) then
    Exit;
  FLastStatus := Status;

  if Status = S_BROM_SLA_REQUIRED then
  begin
    if SlaRequired then
      Exit;
    Status := 0;
  end;
  if not StatusIsOk(Status) then
  begin
    FailFmt('SEND_DA refused: %s', [StatusText(Status)]);
    Exit;
  end;

  DoLog('Uploading download agent: ' + IntToStr(Length(Payload)) +
    ' bytes to $' + IntToHex(AAddress, 8) + ', checksum $' +
    IntToHex(Checksum, 4));
  if not UploadPayload(Payload, Checksum) then
    Exit;
  Result := True;
end;

function TBromProtocol.SlaRequired: Boolean;
var
  Status, Dummy: Word;
  Len: UInt32;
  Challenge: TBytesArray;
begin
  { Secure Link Authentication. The challenge has to be signed with an RSA
    key that only the vendor tool ships with; it is not in this repository, so
    we report it plainly instead of pretending to have passed. }
  Result := False;
  DoLog('The device requires SLA (Secure Link Authentication).');
  if not EchoByte(CMD_SLA) then
    Exit;
  if not ReadWordBe(Status) then
    Exit;
  if Status = S_DA_SLA_REQUIRED then
  begin
    FLastError := 'SLA already satisfied';
    Exit(True);
  end;
  if not StatusIsOk(Status) then
  begin
    FailFmt('SLA refused: %s', [StatusText(Status)]);
    Exit;
  end;
  if not ReadDwordBe(Len) then
    Exit;
  if (Len > 0) and (Len < 4096) then
  begin
    if not ReadBytes(Integer(Len), Challenge) then
      Exit;
    DoLog('SLA challenge: ' + IntToStr(Len) + ' bytes (' +
      HexDump(Challenge, 16) + ')');
  end;
  FLastError := 'SLA authentication is required. It needs the vendor RSA key, ' +
    'which is not part of this build - the operation cannot continue.';
  if ReadWordBe(Dummy) then
    FLastStatus := Dummy;
end;

function TBromProtocol.SendAuth(const AAuth: TBytesArray): Boolean;
var
  Payload: TBytesArray;
  Checksum: Word;
  Status: Word;
  RLen: UInt32;
  N, I: Integer;
begin
  Result := False;
  N := Length(AAuth);
  if N = 0 then
  begin
    FLastError := 'No AUTH data to send';
    Exit;
  end;
  SetLength(Payload, N);
  for I := 0 to N - 1 do
    Payload[I] := AAuth[I];
  Checksum := PrepareChecksum(Payload);

  if not EchoByte(CMD_SEND_AUTH) then
    Exit;
  if not WriteDwordBe(UInt32(Length(Payload))) then
    Exit;
  if not ReadDwordBe(RLen) then
    Exit;
  if RLen <> UInt32(Length(Payload)) then
  begin
    FailFmt('SEND_AUTH length mismatch: sent %d, device wants %d',
      [Length(Payload), RLen]);
    Exit;
  end;
  if not ReadWordBe(Status) then
    Exit;
  FLastStatus := Status;
  if not StatusIsOk(Status) then
  begin
    FailFmt('SEND_AUTH refused: %s', [StatusText(Status)]);
    Exit;
  end;
  Result := UploadPayload(Payload, Checksum);
end;

function TBromProtocol.SendCert(const ACert: TBytesArray): Boolean;
var
  Payload: TBytesArray;
  Checksum: Word;
  Status: Word;
  N, I: Integer;
begin
  Result := False;
  N := Length(ACert);
  if N = 0 then
  begin
    FLastError := 'No certificate data to send';
    Exit;
  end;
  SetLength(Payload, N);
  for I := 0 to N - 1 do
    Payload[I] := ACert[I];
  Checksum := PrepareChecksum(Payload);

  if not EchoByte(CMD_SEND_CERT) then
    Exit;
  if not EchoDwordBe(UInt32(Length(Payload))) then
    Exit;
  if not ReadWordBe(Status) then
    Exit;
  FLastStatus := Status;
  if not StatusIsOk(Status) then
  begin
    FailFmt('SEND_CERT refused: %s', [StatusText(Status)]);
    Exit;
  end;
  Result := UploadPayload(Payload, Checksum);
end;

function TBromProtocol.JumpDa(AAddress: UInt32): Boolean;
var
  Echo: UInt32;
  Status: Word;
begin
  Result := False;
  if not EchoByte(CMD_JUMP_DA) then
    Exit;
  if not WriteDwordBe(AAddress) then
    Exit;
  if not ReadDwordBe(Echo) then
    Exit;
  if Echo <> AAddress then
  begin
    FailFmt('JUMP_DA answered with $%08X instead of $%08X', [Echo, AAddress]);
    Exit;
  end;
  if not ReadWordBe(Status) then
    Exit;
  FLastStatus := Status;
  Sleep(100);
  if Status <> 0 then
  begin
    FailFmt('JUMP_DA failed: %s', [StatusText(Status)]);
    Exit;
  end;
  DoLog('Jumped to the download agent at $' + IntToHex(AAddress, 8));
  Result := True;
end;

function TBromProtocol.JumpDa64(AAddress: UInt32): Boolean;
var
  Echo: UInt32;
  Status: Word;
begin
  Result := False;
  if not EchoByte(CMD_JUMP_DA64) then
    Exit;
  if not WriteDwordBe(AAddress) then
    Exit;
  if not ReadDwordBe(Echo) then
    Exit;
  if Echo <> AAddress then
  begin
    FailFmt('JUMP_DA64 answered with $%08X instead of $%08X', [Echo, AAddress]);
    Exit;
  end;
  if not EchoByte($01) then   { 1 = 64-bit DA, 0 = 32-bit }
    Exit;
  if not ReadWordBe(Status) then
    Exit;
  FLastStatus := Status;
  if Status <> 0 then
  begin
    FailFmt('JUMP_DA64 failed: %s', [StatusText(Status)]);
    Exit;
  end;
  DoLog('Jumped to the 64-bit download agent at $' + IntToHex(AAddress, 8));
  Result := True;
end;

function TBromProtocol.JumpBl: Boolean;
var
  Status: Word;
begin
  Result := False;
  if not EchoByte(CMD_JUMP_BL) then
    Exit;
  if not ReadWordBe(Status) then
    Exit;
  if Status > $00FF then
  begin
    FailFmt('JUMP_BL failed: %s', [StatusText(Status)]);
    Exit;
  end;
  if not ReadWordBe(Status) then
    Exit;
  if Status > $00FF then
  begin
    FailFmt('JUMP_BL failed: %s', [StatusText(Status)]);
    Exit;
  end;
  Result := True;
end;

{ -------------------------------------------------------------------- connect }

function TBromProtocol.Connect: Boolean;
var
  Hw: UInt32;
  SubCode, HwVer, SwVer: Word;
  Values: TBytesArray;
begin
  Result := False;
  FLastError := '';
  if not Handshake then
    Exit;

  if not GetHwCode(Hw) then
  begin
    if FLastError = '' then
      FLastError := 'GET_HW_CODE did not answer - the device left BROM mode';
    Exit;
  end;

  if Hw = 0 then
  begin
    { IoT / feature-phone branch: the identification registers are read
      straight from memory instead. }
    SetLength(Values, 0);
    if ReadValues($80000000, 1, 16, Values) and (Length(Values) = 2) then
      FHwVer := (Word(Values[0]) shl 8) or Word(Values[1]);
    if ReadValues($80000008, 1, 16, Values) and (Length(Values) = 2) then
      FHwCode := (Word(Values[0]) shl 8) or Word(Values[1]);
    if ReadValues($8000000C, 1, 16, Values) and (Length(Values) = 2) then
      FHwSubCode := (Word(Values[0]) shl 8) or Word(Values[1]);
  end
  else
  begin
    FHwCode := Word(Hw shr 16);
    FHwVer := Word(Hw and $FFFF);
  end;

  FChip := ChipByHwCode(FHwCode, FChipKnown);
  DoLog('HW code $' + IntToHex(FHwCode, 4) + ', HW version $' +
    IntToHex(FHwVer, 4) + ' -> ' + ChipLabel(FChip) +
    ', DA mode ' + DaModeLabel(FChip.DaMode));
  if not FChipKnown then
    DoLog('Warning: hwcode $' + IntToHex(FHwCode, 4) +
      ' is not in the chip table, using the generic legacy profile.');

  DisableWatchdog;

  if not GetTargetConfig(FTarget) then
    DoLog('GET_TARGET_CONFIG: ' + FLastError)
  else
    DoLog(TargetConfigText(FTarget));

  GetBlVer;
  if FIsBrom then
    DoLog('BROM mode detected (bootloader version 0).')
  else
    DoLog('Bootloader version ' + IntToStr(FBlVer));
  GetBromVer;
  if FBromVer >= 0 then
    DoLog('BootROM version ' + IntToStr(FBromVer));

  if GetHwSwVer(SubCode, HwVer, SwVer) then
    DoLog('HW subcode $' + IntToHex(SubCode, 4) + ', HW ver $' +
      IntToHex(HwVer, 4) + ', SW ver $' + IntToHex(SwVer, 4))
  else
    DoLog('GET_HW_SW_VER did not answer (older BootROM).');

  Result := True;
end;

end.
