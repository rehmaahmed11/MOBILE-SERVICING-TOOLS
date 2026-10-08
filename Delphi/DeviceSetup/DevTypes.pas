unit DevTypes;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

{ Shared vocabulary of the device layer.

  Every action button of MAIN 2 is described by a TJobKind. A job is built
  from the current UI state, handed to the job engine, and executed by the
  platform back end that matches the selected profile. Keeping the kinds in
  one place lets the CI contract test prove that no button is left unwired:
  JobKindNames must hold exactly one name per TJobKind value.

  Nothing in this unit talks to hardware. It only names things. }

interface

uses
{$IFDEF FPC}
  SysUtils;
{$ELSE}
  System.SysUtils;
{$ENDIF}

type
  { One name for a raw byte buffer, shared by the whole device layer. }
  TBytesArray = array of Byte;

  { Chip family / service profile. The order MUST match the items of
    cbPlatform on MAIN 2 (MediaTek, Unisoc, Qualcomm, Samsung, Generic) and
    the CPlatform* constants declared in Main2Form. }
  TDevPlatform = (dpMtk, dpUnisoc, dpQualcomm, dpSamsung, dpGeneric);

  { Every operation the app offers. jkNone means "no job". }
  TJobKind = (
    jkNone,
    { Flash }
    jkWriteFirmware, jkRestoreBackup, jkWriteBin, jkWriteOfp,
    { Read }
    jkReadFlashInfo, jkReadPartitions, jkReadBin, jkReadRegion, jkReadOtp,
    { Format }
    jkFormat, jkWipeData, jkWipePartitions, jkEraseFrp, jkEraseFrpAndWipe,
    { IMEI }
    jkRepairImei, jkReadImei,
    { Locks }
    jkUnlockBootloader, jkRelockBootloader, jkUnlockNetwork, jkReadCodes,
    jkResetPassword, jkResetAccount,
    { Service }
    jkRebootRecovery, jkDisableOta, jkResetDmVerity, jkDisableOrangeState,
    jkSwitchSlot, jkFixDlImageFail,
    { RPMB }
    jkRpmbBackup, jkRpmbWrite, jkRpmbFormat,
    { Connections }
    jkDownloadAgent, jkAuthBrom, jkAuthPreloader, jkForceBrom, jkReadEmi,
    jkReadPhoneInfo);

  { Where a job is in its life cycle. jsLocked means the app owns the device
    port exclusively; nothing else may touch it until the job finishes. }
  TJobState = (jsIdle, jsPreparing, jsCapturing, jsLocked, jsRunning,
    jsDone, jsFailed, jsCancelled);

  { What the back end has to do before it can run the operation.
    coNone        - offline job, no phone needed (validation / file work)
    coCapture     - wait for the phone, grab its port exclusively
    coHandshake   - capture, then run the BROM/BootROM handshake
    coBootloader  - handshake, then load the download agent (DA/FDL/Sahara)
    coNormalMode  - the phone must be booted; talk to it through adb/fastboot }
  TCaptureNeed = (coNone, coCapture, coHandshake, coBootloader, coNormalMode);

  { Result of one job. }
  TJobOutcome = record
    State: TJobState;
    Message: string;      { human readable reason, '' when successful }
    Code: string;         { short machine code, e.g. 'OK', 'TIMEOUT' }
    BytesMoved: Int64;
    ElapsedMs: Int64;
    Simulated: Boolean;   { True when no real phone was involved }
  end;

  { Everything a job may need. Filled from the UI before the job starts; the
    worker thread only reads it. Strings are the only heap data, so no
    lifetime problems across threads. }
  TJobParams = record
    Kind: TJobKind;
    Platform: TDevPlatform;
    Brand: string;
    ModelCode: string;
    ModelName: string;
    ServiceMode: string;     { 'META', 'DIAG', 'DOWNLOAD', 'SERVICE' }
    FlashMode: string;       { 'Download only', 'Upgrade', ... }
    Storage: string;         { 'EMMC(USER) || UFS(LU2)', ... }
    UsbSpeed: string;
    Battery: string;
    DownloadAgent: string;
    ScatFile: string;
    AuthFile: string;
    BinFile: string;
    OfpFile: string;
    BlFile: string;
    ApFile: string;
    CpFile: string;
    CscFile: string;
    UserFile: string;
    BackupFile: string;
    OutFile: string;
    Address: UInt64;
    Size: UInt64;
    RpmbAddress: UInt64;
    Imei1: string;
    Imei2: string;
    AdvancedWrite: Boolean;
    ManualFormat: Boolean;
    ExceptBootloader: Boolean;
    CreateDefaultFs: Boolean;
    AuthBrom: Boolean;
    AuthPreloader: Boolean;
    ForceBrom: Boolean;
    ReadEmi: Boolean;
    ReadPhoneInfo: Boolean;
    TimeoutMs: Integer;
  end;

  { Progress / log reporting. Both are called from the worker thread; the job
    engine marshals them to the main thread before the UI is touched. }
  TJobProgressEvent = procedure(Sender: TObject; APercent: Integer;
    const AText: string) of object;
  TJobLogEvent = procedure(Sender: TObject; const AText: string) of object;

const
  CPlatformCount = 5;
  CJobKindCount = Ord(High(TJobKind)) + 1;

  { Default time we wait for the user to plug the phone in. Long enough for
    "power off, hold volume keys, connect USB". }
  CDefaultCaptureTimeoutMs = 180000;
  { How long a single read/write reply may take before we call it dead. }
  CDefaultIoTimeoutMs = 5000;

  { Legacy download-agent protocol constants. They live here, not in the
    simulator, so the real protocol units never depend on SimPort. }
  DA_ACK = $5A;
  DA_NACK = $A5;
  DA_CONT = $69;
  DA_SYNC = $C0;
  DA_STOP = $96;
  DA_UNKNOWN_CMD = $BB;

  DA_CMD_SDMMC_SWITCH_PART = $60;
  DA_CMD_SDMMC_WRITE_IMAGE = $61;
  DA_CMD_SDMMC_WRITE_DATA = $62;
  DA_CMD_USB_SETUP_PORT = $70;
  DA_CMD_USB_LOOPBACK = $71;
  DA_CMD_USB_CHECK_STATUS = $72;
  DA_CMD_FORMAT = $D4;
  DA_CMD_WRITE = $D5;
  DA_CMD_READ = $D6;
  DA_CMD_FINISH = $D9;
  DA_CMD_OTP_READ = $EB;

  { The stage-2 configuration block a chip expects after its sync. The host
    (MtkDaLegacy) and the simulated device (SimPort) both build it from this
    one table, so they can never disagree about a chip's layout. Values and
    sizes follow the public per-chip table in mtkclient's legacy DA. }
  MTK_STAGE2_EXTRA_NONE = 0;
  MTK_STAGE2_EXTRA_GPT = 1;      { MT6592: dword is_gpt_solution }
  MTK_STAGE2_EXTRA_SLC = 2;      { MT6580 / MT8163: dword slc + 20 bytes }
  MTK_STAGE2_EXTRA_DRAM = 3;     { MT6583 / MT6589: dword forcedram }
  MTK_STAGE2_EXTRA_SKIPDL = 4;   { MT8127: two dwords }
  MTK_STAGE2_EXTRA_COMBO = 5;    { MT6582: dword newcombo }

  { eMMC hardware partitions, as the download agent expects them. These are the
    PARTITION_ACCESS_CONFIG values of the eMMC spec (EXT_CSD[179]): 0 and 8
    both mean the user area, 1/2 are the boot partitions, 3..6 the general
    purpose partitions and 7 the RPMB partition. }
  MTK_PART_BOOT1 = 1;
  MTK_PART_BOOT2 = 2;
  MTK_PART_GP1 = 3;
  MTK_PART_GP2 = 4;
  MTK_PART_GP3 = 5;
  MTK_PART_GP4 = 6;
  MTK_PART_RPMB = 7;
  MTK_PART_USER = 8;

  { Storage type bytes. }
  MTK_STORAGE_NOR = $00;
  MTK_STORAGE_NAND = $01;
  MTK_STORAGE_EMMC = $02;
  MTK_STORAGE_SDC = $03;
  MTK_STORAGE_UFS = $05;

  MTK_HOST_WINDOWS = $0B;
  MTK_HOST_LINUX = $0C;

  CPlatformNames: array[TDevPlatform] of string =
    ('MediaTek', 'Unisoc / Spreadtrum', 'Qualcomm', 'Samsung', 'Generic');

  JobKindNames: array[TJobKind] of string = (
    'None',
    'Write Firmware', 'Restore from backup', 'Write BIN', 'Write OFP',
    'Read Flash Info', 'Read Partitions', 'Read BIN', 'Read Region', 'Read OTP',
    'Format', 'Wipe Data', 'Wipe Partitions', 'Erase FRP', 'Erase FRP and Wipe',
    'Repair IMEI', 'Read IMEI',
    'Unlock Bootloader', 'Relock Bootloader', 'Unlock Network', 'Read Codes',
    'Reset Password', 'Reset Account',
    'Reboot to Recovery', 'Disable OTA Updates', 'Reset Dm-Verity Error',
    'Disable Orange State', 'Switch Slot', 'Fix DL Image Fail',
    'Backup RPMB', 'Write RPMB', 'Format RPMB',
    'Download Agent', 'BROM Authorization', 'Preloader Authorization',
    'Force BROM', 'Read EMI', 'Read Phone Info');

{ Human readable name of a job kind, e.g. 'Read BIN'. }
function JobName(AKind: TJobKind): string;
{ Platform name, e.g. 'MediaTek'. }
function PlatformLabel(AP: TDevPlatform): string;
{ Default (empty) parameters - every field cleared. }
function EmptyJobParams: TJobParams;
{ Successful / failed / cancelled outcomes. }
function OutcomeOk(const AMessage: string = ''; ABytes: Int64 = 0): TJobOutcome;
function OutcomeFail(const ACode, AMessage: string): TJobOutcome;
function OutcomeCancelled: TJobOutcome;
{ True when the job needs a phone at all. }
function NeedsDevice(AKind: TJobKind): Boolean;

{ One line per job state, for the log and the progress strip. }
function JobStateName(AState: TJobState): string;

{ Which stage-2 extra block a chip needs, and how many bytes it is. Shared by
  the host and the simulator so both sides of the wire agree. }
function Stage2ExtraKind(AHwCode: Word): Integer;
function Stage2ExtraSize(AKind: Integer): Integer;

{ How the app reaches the phone: real hardware through an exclusive COM
  handle, or the in-process simulated device used by --selftest and CI. }
type
  TDevBackend = (bkReal, bkSimulated);

{ "00000000 00100000" - the same high / low layout as the address boxes on
  MAIN 2. }
function Hex64(const AValue: UInt64): string;
{ Size of a file in bytes, or -1 when it cannot be found. }
function FileSizeOf(const AFileName: string): Int64;
{ Replaces every character Windows forbids in a file name with '_'. }
function SafeFileName(const S: string): string;
{ How many digits a string holds - an IMEI needs 14 or 15. }
function ImeiDigits(const AText: string): Integer;
{ Int64 max of two values, without pulling in System.Math. }
function MaxInt64(const A, B: Int64): Int64;

implementation

function JobName(AKind: TJobKind): string;
begin
  Result := JobKindNames[AKind];
end;

function PlatformLabel(AP: TDevPlatform): string;
begin
  Result := CPlatformNames[AP];
end;

function EmptyJobParams: TJobParams;
begin
  { Assigned field by field: TJobParams holds strings, and FillChar on a
    record with string fields leaks whatever they pointed at. }
  Result.Kind := jkNone;
  Result.Platform := dpMtk;
  Result.Brand := '';
  Result.ModelCode := '';
  Result.ModelName := '';
  Result.ServiceMode := '';
  Result.FlashMode := '';
  Result.Storage := '';
  Result.UsbSpeed := '';
  Result.Battery := '';
  Result.DownloadAgent := '';
  Result.ScatFile := '';
  Result.AuthFile := '';
  Result.BinFile := '';
  Result.OfpFile := '';
  Result.BlFile := '';
  Result.ApFile := '';
  Result.CpFile := '';
  Result.CscFile := '';
  Result.UserFile := '';
  Result.BackupFile := '';
  Result.OutFile := '';
  Result.Address := 0;
  Result.Size := 0;
  Result.RpmbAddress := 0;
  Result.Imei1 := '';
  Result.Imei2 := '';
  Result.AdvancedWrite := False;
  Result.ManualFormat := False;
  Result.ExceptBootloader := False;
  Result.CreateDefaultFs := False;
  Result.AuthBrom := False;
  Result.AuthPreloader := False;
  Result.ForceBrom := False;
  Result.ReadEmi := False;
  Result.ReadPhoneInfo := False;
  Result.TimeoutMs := CDefaultCaptureTimeoutMs;
end;

function OutcomeOk(const AMessage: string; ABytes: Int64): TJobOutcome;
begin
  Result.State := jsDone;
  Result.Simulated := False;
  Result.ElapsedMs := 0;
  Result.BytesMoved := ABytes;
  Result.Message := AMessage;
  Result.Code := 'OK';
  Result.BytesMoved := ABytes;
end;

function OutcomeFail(const ACode, AMessage: string): TJobOutcome;
begin
  Result.State := jsFailed;
  Result.BytesMoved := 0;
  Result.ElapsedMs := 0;
  Result.Simulated := False;
  Result.Message := AMessage;
  Result.Code := ACode;
end;

function OutcomeCancelled: TJobOutcome;
begin
  Result.State := jsCancelled;
  Result.BytesMoved := 0;
  Result.ElapsedMs := 0;
  Result.Simulated := False;
  Result.Code := 'CANCELLED';
  Result.Message := 'Cancelled by the user.';
end;

function NeedsDevice(AKind: TJobKind): Boolean;
begin
  Result := AKind <> jkNone;
end;

function JobStateName(AState: TJobState): string;
begin
  case AState of
    jsIdle: Result := 'idle';
    jsPreparing: Result := 'preparing';
    jsCapturing: Result := 'waiting for the device';
    jsLocked: Result := 'device locked';
    jsRunning: Result := 'running';
    jsDone: Result := 'done';
    jsFailed: Result := 'failed';
    jsCancelled: Result := 'cancelled';
  else
    Result := 'unknown';
  end;
end;

function Stage2ExtraKind(AHwCode: Word): Integer;
begin
  case AHwCode of
    $6592: Result := MTK_STAGE2_EXTRA_GPT;
    $6580, $8163: Result := MTK_STAGE2_EXTRA_SLC;
    $8127: Result := MTK_STAGE2_EXTRA_SKIPDL;
    $6583, $6589: Result := MTK_STAGE2_EXTRA_DRAM;
    $6582: Result := MTK_STAGE2_EXTRA_COMBO;
  else
    Result := MTK_STAGE2_EXTRA_NONE;
  end;
end;

function Stage2ExtraSize(AKind: Integer): Integer;
begin
  case AKind of
    MTK_STAGE2_EXTRA_GPT: Result := 4;
    MTK_STAGE2_EXTRA_SLC: Result := 24;
    MTK_STAGE2_EXTRA_DRAM: Result := 4;
    MTK_STAGE2_EXTRA_SKIPDL: Result := 8;
    MTK_STAGE2_EXTRA_COMBO: Result := 4;
  else
    Result := 0;
  end;
end;

function Hex64(const AValue: UInt64): string;
begin
  Result := IntToHex(Int64(AValue shr 32), 8) + ' ' +
    IntToHex(Int64(AValue and $FFFFFFFF), 8);
end;

function FileSizeOf(const AFileName: string): Int64;
var
  SR: TSearchRec;
begin
  Result := -1;
  if FindFirst(AFileName, faAnyFile, SR) = 0 then
  begin
    Result := SR.Size;
    FindClose(SR);
  end;
end;

function SafeFileName(const S: string): string;
var
  I: Integer;
begin
  Result := S;
  for I := 1 to Length(Result) do
    if CharInSet(Result[I], ['\', '/', ':', '*', '?', '"', '<', '>', '|', ' ']) then
      Result[I] := '_';
end;

function ImeiDigits(const AText: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to Length(AText) do
    if CharInSet(AText[I], ['0'..'9']) then
      Inc(Result);
end;

function MaxInt64(const A, B: Int64): Int64;
begin
  if A > B then
    Result := A
  else
    Result := B;
end;

end.
