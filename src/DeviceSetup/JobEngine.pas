unit JobEngine;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


{ The job engine: what happens between "the user pressed the button" and "the
  log says it is finished".

      RunJob(Params)
        ->  decide what the job needs (nothing / capture / BROM handshake /
            download agent / a booted Android)
        ->  open a TDeviceSession, which waits for the phone and takes its COM
            port with an EXCLUSIVE handle
        ->  run the operation, reporting progress and logging every step
        ->  close the session, which releases the port

  The port is held for the whole operation and released from a finally block,
  so a crash, a cancel or an error cannot leave the phone locked by this app.

  Three kinds of job live here:

    * MediaTek download-agent jobs - fully implemented against the legacy DA
      protocol: read / write / format any region, read the flash and partition
      tables, back up RPMB, boot the DA, send AUTH, read the EMI.
    * Android jobs - fully implemented by running the bundled adb.exe and
      fastboot.exe: phone info, IMEI read, reboot to recovery, bootloader
      unlock / relock, slot switch, dm-verity, OTA disable.
    * Jobs whose vendor protocol is not public - Unisoc Diag/SPD flashing,
      Samsung Loke/Odin, Qualcomm firehose, RPMB key programming, network
      codes, account reset. These run the same lifecycle and then log exactly
      what is missing. They never report success for work they did not do. }

interface

uses
{$IFDEF FPC}
  Classes, SysUtils, StrUtils,
{$ELSE}
  System.Classes,
  System.SysUtils,
  System.StrUtils,
{$ENDIF}
  DevTypes, CommPort, UsbDetect, DevCapture, DeviceSession,
  BromProtocol, MtkDaLegacy, DaImage, MtkChips, MtkStatus, ScatterFile,
  AdbTool, SaharaProtocol, AndroidJobs, UnimplementedJobs;

type
  TJobEngine = class(TObject)
  private
    FSession: TDeviceSession;
    FAdb: TAdbTool;
    FParams: TJobParams;
    FState: TJobState;
    FCancelled: Boolean;
    FOnLog: TJobLogEvent;
    FOnProgress: TJobProgressEvent;
    FOnStateChanged: TNotifyEvent;
    FLastOutcome: TJobOutcome;
    FAllowSimulated: Boolean;
    FBackend: TDevBackend;
    FJobCount: Integer;
    procedure DoLog(const AText: string);
    procedure DoProgress(APercent: Integer; const AText: string);
    procedure SetState(AState: TJobState);
    function NeedOf(AKind: TJobKind): TCaptureNeed;
    function DaRequired(AKind: TJobKind): Boolean;
    function StartSession(ANeed: TCaptureNeed): Boolean;
    function Finish(const AOutcome: TJobOutcome): TJobOutcome;
    procedure SessionLog(Sender: TObject; const AText: string);
    procedure SessionProgress(Sender: TObject; APercent: Integer;
      const AText: string);
    { adb / fastboot log sink: TAndroidLog has no Sender parameter. }
    procedure ToolLog(const AText: string);
    { TAdbTool.OnLog is a TJobLogEvent, which does carry a Sender, so the tool
      gets this adapter and AndroidJobs/UnimplementedJobs keep ToolLog. }
    procedure AdbLog(Sender: TObject; const AText: string);
    procedure ToolProgress(APercent: Integer; const AText: string);
    function RunAndroidJob: TJobOutcome;
    function RunOfflineJob: TJobOutcome;
    function RunMtkJob: TJobOutcome;
    function RunCaptureOnlyJob: TJobOutcome;
    { MediaTek operations }
    function JobReadFlashInfo: TJobOutcome;
    function JobReadPartitions: TJobOutcome;
    function JobReadBin: TJobOutcome;
    function JobReadRegion: TJobOutcome;
    function JobReadOtp: TJobOutcome;
    function JobReadEmi: TJobOutcome;
    function JobFormat: TJobOutcome;
    function JobWipeData: TJobOutcome;
    function JobWipePartitions: TJobOutcome;
    function JobEraseFrp(AButAlsoWipe: Boolean): TJobOutcome;
    function JobWriteFirmware: TJobOutcome;
    function JobWriteBin: TJobOutcome;
    function JobRestoreBackup: TJobOutcome;
    function JobWriteOfp: TJobOutcome;
    function JobRpmbBackup: TJobOutcome;
    function JobRpmbWrite: TJobOutcome;
    function JobRpmbFormat: TJobOutcome;
    function JobDownloadAgent: TJobOutcome;
    function JobAuth(ABromStage: Boolean): TJobOutcome;
    function JobReadPhoneInfoBrom: TJobOutcome;
    function JobReadImeiNvram: TJobOutcome;
    function JobRepairImei: TJobOutcome;
    function JobFixDlImageFail: TJobOutcome;
    { helpers }
    function Da: TMtkDaLegacy;
    function RequireDa(const AJob: string; out AOutcome: TJobOutcome): Boolean;
    function RegionPartition(const ARegion: string): Integer;
    function OpenOutFile(const AFileName: string; out AStream: TFileStream;
      out AError: string): Boolean;
    function OpenInFile(const AFileName: string; out AStream: TFileStream;
      out AError: string): Boolean;
    function ReadGpt(ALines: TStrings; out AError: string): Boolean;
    function BackupPartition(const AName: string; AOutDir: string;
      out ASavedTo: string; out AError: string): Boolean;
    procedure LogFlashInfo;
  public
    constructor Create;
    destructor Destroy; override;

    { Runs a job to completion. Synchronous; the UI pumps messages through
      TPump.KeepAlive while it runs. Always releases the device first. }
    function RunJob(const AParams: TJobParams): TJobOutcome;

    { Convenience for the UI: fills the platform/brand/model fields that every
      job needs and runs it. }
    function Start(AKind: TJobKind; APlatform: TDevPlatform; const ABrand,
      AModelCode, AModelName: string): TJobOutcome;

    procedure Cancel;
    procedure ResetCancel;

    { True when no job is running and the device is free. }
    function Idle: Boolean;
    { True while a job holds the phone. The UI disables its controls then. }
    function Busy: Boolean;
    function DeviceLocked: Boolean;

    property Params: TJobParams read FParams;
    property State: TJobState read FState;
    property LastOutcome: TJobOutcome read FLastOutcome;
    property Session: TDeviceSession read FSession;
    property Adb: TAdbTool read FAdb;
    { True when a simulated device may stand in for real hardware. The UI sets
      this only for the self-test and the demo mode, and every result is then
      flagged Simulated. }
    property AllowSimulated: Boolean read FAllowSimulated write FAllowSimulated;
    property Backend: TDevBackend read FBackend write FBackend;
    property JobsRun: Integer read FJobCount;
    property OnLog: TJobLogEvent read FOnLog write FOnLog;
    property OnProgress: TJobProgressEvent read FOnProgress write FOnProgress;
    property OnStateChanged: TNotifyEvent read FOnStateChanged
      write FOnStateChanged;
  end;

{ What a job needs before it can run. Exposed so the UI can decide whether to
  open the capture window at all. }
function CaptureNeedOf(AKind: TJobKind): TCaptureNeed;
{ True when the job needs the MediaTek download agent to be up. }
function JobNeedsDa(AKind: TJobKind): Boolean;
{ True when the job is served by adb / fastboot on a booted phone. }
function JobIsAndroid(AKind: TJobKind): Boolean;

implementation

{ ------------------------------------------------------------------ helpers }

function CaptureNeedOf(AKind: TJobKind): TCaptureNeed;
begin
  case AKind of
    jkNone: Result := coNone;
    jkReadPhoneInfo, jkReadImei, jkRebootRecovery, jkDisableOta,
    jkResetDmVerity, jkUnlockBootloader, jkRelockBootloader,
    jkSwitchSlot: Result := coNormalMode;
    { the EMI lives inside the preloader image, which is read through the
      download agent when one is available }
    jkReadEmi: Result := coBootloader;
    jkForceBrom, jkDisableOrangeState, jkUnlockNetwork, jkReadCodes,
    jkResetPassword, jkResetAccount, jkFixDlImageFail: Result := coNone;
  else
    if JobNeedsDa(AKind) then
      Result := coBootloader
    else
      Result := coHandshake;
  end;
end;

function JobNeedsDa(AKind: TJobKind): Boolean;
begin
  Result := AKind in [jkWriteFirmware, jkRestoreBackup, jkWriteBin,
    jkWriteOfp, jkReadFlashInfo, jkReadPartitions, jkReadBin, jkReadRegion,
    jkReadOtp, jkFormat, jkWipeData, jkWipePartitions, jkEraseFrp,
    jkEraseFrpAndWipe, jkRpmbBackup, jkRpmbWrite, jkRpmbFormat,
    jkDownloadAgent];
end;

function JobIsAndroid(AKind: TJobKind): Boolean;
begin
  Result := CaptureNeedOf(AKind) = coNormalMode;
end;

{ ------------------------------------------------------------- TJobEngine }

constructor TJobEngine.Create;
begin
  inherited Create;
  FSession := TDeviceSession.Create;
  FSession.OnLog := SessionLog;
  FSession.OnProgress := SessionProgress;
  FAdb := TAdbTool.Create;
  FAdb.OnLog := AdbLog;   { every adb/fastboot command line lands in the log }
  FParams := EmptyJobParams;
  FState := jsIdle;
  FCancelled := False;
  FOnLog := nil;
  FOnProgress := nil;
  FOnStateChanged := nil;
  FLastOutcome := OutcomeOk('');
  FLastOutcome.State := jsIdle;
  FAllowSimulated := False;
  FBackend := bkReal;
  FJobCount := 0;
  FAdb.OnLog := nil;
end;

destructor TJobEngine.Destroy;
begin
  Cancel;
  FSession.Close;
  FAdb.Free;
  FSession.Free;
  inherited Destroy;
end;

procedure TJobEngine.DoLog(const AText: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, AText);
end;

procedure TJobEngine.DoProgress(APercent: Integer; const AText: string);
begin
  TPump.KeepAlive;
  if Assigned(FOnProgress) then
    FOnProgress(Self, APercent, AText);
end;

procedure TJobEngine.SetState(AState: TJobState);
begin
  if FState = AState then
    Exit;
  FState := AState;
  if Assigned(FOnStateChanged) then
    FOnStateChanged(Self);
end;

procedure TJobEngine.SessionLog(Sender: TObject; const AText: string);
begin
  DoLog(AText);
end;

procedure TJobEngine.SessionProgress(Sender: TObject; APercent: Integer;
  const AText: string);
begin
  DoProgress(APercent, AText);
end;

procedure TJobEngine.ToolLog(const AText: string);
begin
  DoLog(AText);
end;

procedure TJobEngine.AdbLog(Sender: TObject; const AText: string);
begin
  DoLog(AText);
end;

procedure TJobEngine.ToolProgress(APercent: Integer; const AText: string);
begin
  DoProgress(APercent, AText);
end;

function TJobEngine.Idle: Boolean;
begin
  Result := FState in [jsIdle, jsDone, jsFailed, jsCancelled];
end;

function TJobEngine.Busy: Boolean;
begin
  Result := not Idle;
end;

function TJobEngine.DeviceLocked: Boolean;
begin
  Result := FSession.Locked;
end;

procedure TJobEngine.Cancel;
begin
  FCancelled := True;
  FSession.Cancel;
end;

procedure TJobEngine.ResetCancel;
begin
  FCancelled := False;
  FSession.ResetCancel;
end;

function TJobEngine.NeedOf(AKind: TJobKind): TCaptureNeed;
begin
  Result := CaptureNeedOf(AKind);
end;

function TJobEngine.DaRequired(AKind: TJobKind): Boolean;
begin
  Result := JobNeedsDa(AKind);
end;

function TJobEngine.Finish(const AOutcome: TJobOutcome): TJobOutcome;
begin
  Result := AOutcome;
  Result.Simulated := FSession.Simulated or (FBackend = bkSimulated);
  case Result.State of
    jsDone: SetState(jsDone);
    jsFailed: SetState(jsFailed);
    jsCancelled: SetState(jsCancelled);
  else
    SetState(jsIdle);
  end;
  FLastOutcome := Result;
end;

function TJobEngine.StartSession(ANeed: TCaptureNeed): Boolean;
begin
  SetState(jsCapturing);
  Result := FSession.Open(FParams.Platform, ANeed, FParams.ForceBrom,
    FParams.DownloadAgent, FParams.AuthFile, FParams.ScatFile,
    FParams.TimeoutMs, FAllowSimulated);
  if Result then
  begin
    SetState(jsLocked);
    if FSession.Locked then
      DoLog('Device locked on ' + FSession.PortName +
        '. It stays locked until this job finishes.');
  end
  else
    SetState(jsFailed);
end;

function TJobEngine.Da: TMtkDaLegacy;
begin
  Result := FSession.Da;
end;

function TJobEngine.RequireDa(const AJob: string;
  out AOutcome: TJobOutcome): Boolean;
begin
  Result := FSession.DaAvailable;
  if not Result then
  begin
    AOutcome := OutcomeFail('NO_DA', AJob + ' needs the download agent, which ' +
      'is not running: ' + FSession.LastError);
    DoLog(AOutcome.Message);
  end;
end;

function TJobEngine.RegionPartition(const ARegion: string): Integer;
var
  R: TScatterRegion;
begin
  R := RegionOfName(ARegion);
  Result := RegionPartitionByte(R);
  if Result < 0 then
    Result := MTK_PART_USER;
end;

function TJobEngine.OpenOutFile(const AFileName: string;
  out AStream: TFileStream; out AError: string): Boolean;
begin
  AStream := nil;
  AError := '';
  Result := False;
  if Trim(AFileName) = '' then
  begin
    AError := 'No output file was chosen';
    Exit;
  end;
  try
    AStream := TFileStream.Create(AFileName, fmCreate or fmShareExclusive);
    Result := True;
  except
    on E: Exception do
      AError := 'Cannot create ' + AFileName + ': ' + E.Message;
  end;
end;

function TJobEngine.OpenInFile(const AFileName: string;
  out AStream: TFileStream; out AError: string): Boolean;
begin
  AStream := nil;
  AError := '';
  Result := False;
  if Trim(AFileName) = '' then
  begin
    AError := 'No input file was chosen';
    Exit;
  end;
  if not FileExists(AFileName) then
  begin
    AError := 'File not found: ' + AFileName;
    Exit;
  end;
  try
    AStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
    Result := True;
  except
    on E: Exception do
      AError := 'Cannot open ' + AFileName + ': ' + E.Message;
  end;
end;

{ ------------------------------------------------------------------ dispatch }

function TJobEngine.Start(AKind: TJobKind; APlatform: TDevPlatform;
  const ABrand, AModelCode, AModelName: string): TJobOutcome;
begin
  FParams := EmptyJobParams;
  FParams.Kind := AKind;
  FParams.Platform := APlatform;
  FParams.Brand := ABrand;
  FParams.ModelCode := AModelCode;
  FParams.ModelName := AModelName;
  Result := RunJob(FParams);
end;

function TJobEngine.RunJob(const AParams: TJobParams): TJobOutcome;
var
  Need: TCaptureNeed;
  T0: Int64;
begin
  FParams := AParams;
  if FParams.TimeoutMs <= 0 then
    FParams.TimeoutMs := CDefaultCaptureTimeoutMs;
  FCancelled := False;
  ResetCancel;
  Inc(FJobCount);
  T0 := Tick64;

  SetState(jsPreparing);
  DoProgress(0, JobName(FParams.Kind));
  DoLog('Job: ' + JobName(FParams.Kind) + '  [' +
    PlatformLabel(FParams.Platform) + ']');
  if FAllowSimulated then
    DoLog('SIMULATION MODE: no phone is required and every result is flagged ' +
      'as simulated.');

  Need := NeedOf(FParams.Kind);
  case Need of
    coNone:
      Result := RunOfflineJob;
    coNormalMode:
      Result := RunAndroidJob;
  else
    begin
      if not StartSession(Need) then
      begin
        Result := OutcomeFail('SESSION', FSession.LastError);
        if FCancelled then
          Result := OutcomeCancelled;
      end
      else
      begin
        SetState(jsRunning);
        if FParams.Platform = dpMtk then
          Result := RunMtkJob
        else
          Result := RunCaptureOnlyJob;
      end;
    end;
  end;

  if FCancelled and (Result.State = jsDone) then
    Result := OutcomeCancelled;
  Result.ElapsedMs := TicksSince(T0);
  if Result.BytesMoved = 0 then
    Result.BytesMoved := FSession.BytesMoved;
  if Result.Simulated or FSession.Simulated then
    Result.Simulated := True;
  Result := Finish(Result);

  { always release the phone, whatever happened }
  FSession.Close;
  SetState(Result.State);
  if Result.State = jsDone then
    DoLog('Finished in ' + IntToStr(Result.ElapsedMs div 1000) + '.' +
      IntToStr((Result.ElapsedMs mod 1000) div 100) + ' s' +
      IfThenStr(Result.BytesMoved > 0, ', ' + IntToStr(Result.BytesMoved) +
        ' bytes moved', '') + '.')
  else if Result.State = jsCancelled then
    DoLog('Cancelled. Any acquired device port handle has been released.')
  else
    DoLog('Failed: ' + Result.Message);
  DoProgress(100, JobName(FParams.Kind) + ' - ' + JobStateName(Result.State));
end;

function TJobEngine.RunOfflineJob: TJobOutcome;
var
  Msg: string;
begin
  case FParams.Kind of
    jkForceBrom:
      begin
        DoLog('Force BROM mode is a switch, not an operation: it tells the ' +
          'capture window to accept only the MediaTek boot ROM ' +
          '(VID_0E8D&PID_0003 / 2000) and to ignore a phone that is already ' +
          'past it in preloader or DA mode.');
        DoLog('To put the phone in BROM by hand: switch it off, hold Volume ' +
          'Down (some boards Volume Up, or both), then plug in the USB cable. ' +
          'On a phone with a removable battery, take the battery out, hold ' +
          'Volume Down and plug in the cable.');
        DoLog('If the phone keeps landing in preloader mode instead, use ' +
          '"Force BROM" together with a powered-off phone, or short the ' +
          'test point marked BROM/KCOL0 on the board while plugging in.');
        Msg := 'Force BROM is armed for the next capture. ' +
          'No device was touched.';
        Result := OutcomeOk(Msg);
      end;
    jkFixDlImageFail:
      Result := JobFixDlImageFail;
    jkDisableOrangeState:
      Result := RunAndroidOffline(jkDisableOrangeState, FAdb, ToolLog);
  else
    Result := UnimplementedOutcome(FParams.Kind, FParams.Platform, ToolLog);
  end;
end;

function TJobEngine.RunAndroidJob: TJobOutcome;
var
  Missing: string;
begin
  DoLog('This job talks to a booted Android through the platform tools.');
  Missing := FAdb.MissingToolMessage(FParams.Kind in
    [jkUnlockBootloader, jkRelockBootloader, jkSwitchSlot]);
  if Missing <> '' then
  begin
    DoLog(Missing);
    Result := OutcomeFail('NO_TOOLS', Missing);
    Exit;
  end;
  FAdb.TimeoutMs := CDefaultIoTimeoutMs * 6;
  Result := RunAndroidOperation(FParams.Kind, FAdb, FParams, ToolLog,
    ToolProgress);
  if Result.State = jsDone then
    Result.Simulated := FBackend = bkSimulated;
end;

function TJobEngine.RunCaptureOnlyJob: TJobOutcome;
var
  Detail: string;
begin
  { The session is open and the port is locked, but this platform has no
    implemented bring-up. Report exactly that, and what did work. }
  Detail := '';
  if FSession.Locked then
    Detail := 'the phone was captured and its port ' + FSession.PortName +
      ' was locked exclusively';
  if FSession.Simulated then
    Detail := Detail + ' (simulated device)';
  Result := UnimplementedOutcome(FParams.Kind, FParams.Platform, ToolLog,
    Detail);
end;

function TJobEngine.RunMtkJob: TJobOutcome;
begin
  if FCancelled then
    Exit(OutcomeCancelled);
  case FParams.Kind of
    jkReadFlashInfo: Result := JobReadFlashInfo;
    jkReadPartitions: Result := JobReadPartitions;
    jkReadBin: Result := JobReadBin;
    jkReadRegion: Result := JobReadRegion;
    jkReadOtp: Result := JobReadOtp;
    jkReadEmi: Result := JobReadEmi;
    jkReadPhoneInfo: Result := JobReadPhoneInfoBrom;
    jkReadImei: Result := JobReadImeiNvram;
    jkRepairImei: Result := JobRepairImei;
    jkFormat: Result := JobFormat;
    jkWipeData: Result := JobWipeData;
    jkWipePartitions: Result := JobWipePartitions;
    jkEraseFrp: Result := JobEraseFrp(False);
    jkEraseFrpAndWipe: Result := JobEraseFrp(True);
    jkWriteFirmware: Result := JobWriteFirmware;
    jkWriteBin: Result := JobWriteBin;
    jkRestoreBackup: Result := JobRestoreBackup;
    jkWriteOfp: Result := JobWriteOfp;
    jkRpmbBackup: Result := JobRpmbBackup;
    jkRpmbWrite: Result := JobRpmbWrite;
    jkRpmbFormat: Result := JobRpmbFormat;
    jkDownloadAgent: Result := JobDownloadAgent;
    jkAuthBrom: Result := JobAuth(True);
    jkAuthPreloader: Result := JobAuth(False);
  else
    Result := UnimplementedOutcome(FParams.Kind, FParams.Platform, ToolLog);
  end;
end;

{ ------------------------------------------------------------ MediaTek jobs }

procedure TJobEngine.LogFlashInfo;
var
  Info: TMtkFlashInfo;
begin
  Info := FSession.FlashInfo;
  DoLog('Storage          : ' + StorageKindName(Info.Kind));
  DoLog('Flash size       : ' + FormatScatterSize(Info.FlashSize));
  DoLog('User area        : ' + FormatScatterSize(Info.UserAreaSize));
  DoLog('Boot 1 / Boot 2  : ' + FormatScatterSize(Info.Boot1Size) + ' / ' +
    FormatScatterSize(Info.Boot2Size));
  DoLog('RPMB             : ' + FormatScatterSize(Info.RpmbSize));
  if Info.SdcSize > 0 then
    DoLog('SD card          : ' + FormatScatterSize(Info.SdcSize));
  if Info.NandPageSize > 0 then
    DoLog('NAND page/spare  : ' + IntToStr(Info.NandPageSize) + ' / ' +
      IntToStr(Info.NandSpareSize));
  if Info.Cid <> '' then
    DoLog('CID              : ' + Info.Cid);
  if Info.FirmwareVersion <> '' then
    DoLog('Firmware version : ' + Info.FirmwareVersion);
  if Info.ExtRamSize > 0 then
    DoLog('External RAM     : type ' + IntToStr(Info.ExtRamType) + ', ' +
      FormatScatterSize(Info.ExtRamSize));
  if Info.InternalSramSize > 0 then
    DoLog('Internal SRAM    : ' + FormatScatterSize(Info.InternalSramSize));
end;

function TJobEngine.JobReadFlashInfo: TJobOutcome;
begin
  if not RequireDa('Read Flash Info', Result) then
    Exit;
  DoLog('--- flash information ---');
  LogFlashInfo;
  if FSession.ChipLabel <> '' then
    DoLog('Chip             : ' + FSession.ChipLabel);
  DoLog('Port             : ' + FSession.PortName +
    IfThenStr(FSession.Simulated, ' (simulated)', ''));
  Result := OutcomeOk('Flash information read',
    Int64(FSession.FlashInfo.FlashSize));
end;

function TJobEngine.ReadGpt(ALines: TStrings; out AError: string): Boolean;
const
  CSector = 512;
  CEntrySize = 128;
var
  Header, Entries: TBytesArray;
  Sig: AnsiString;
  EntryLba, EntryCount, EntrySize, FirstUsable, LastUsable: UInt64;
  EntryBytes, I, P, NameAt: Integer;
  Name: string;
  NameW: UnicodeString;
  Ch: Word;
  StartLba, EndLba: UInt64;
begin
  Result := False;
  AError := '';
  if not FSession.Da.ReadFlashBytes(CSector, CSector, Header,
    MTK_PART_USER) then
  begin
    AError := FSession.Da.LastError;
    Exit;
  end;
  if Length(Header) < 92 then
  begin
    AError := 'The GPT header is too short (' + IntToStr(Length(Header)) +
      ' bytes)';
    Exit;
  end;
  SetString(Sig, PAnsiChar(@Header[0]), 8);
  if string(Sig) <> 'EFI PART' then
  begin
    AError := 'No GPT signature at LBA 1 (found "' + string(Sig) +
      '"). The flash is not partitioned with GPT, or the storage is NAND ' +
      'with a MediaTek partition table instead.';
    Exit;
  end;
  { revision 24, header size 28, crc 32, reserved 36, current lba 40,
    backup lba 48, first usable 56, last usable 64, disk guid 72 (16),
    entry lba 88, entry count 92, entry size 96 }
  FirstUsable := 0;
  LastUsable := 0;
  for I := 0 to 7 do
  begin
    FirstUsable := (FirstUsable shl 8) or Header[56 + I];
    LastUsable := (LastUsable shl 8) or Header[64 + I];
  end;
  EntryLba := 0;
  for I := 0 to 7 do
    EntryLba := (EntryLba shl 8) or Header[88 + I];
  EntryCount := (UInt64(Header[95]) shl 24) or (UInt64(Header[94]) shl 16) or
    (UInt64(Header[93]) shl 8) or UInt64(Header[92]);
  EntrySize := (UInt64(Header[99]) shl 24) or (UInt64(Header[98]) shl 16) or
    (UInt64(Header[97]) shl 8) or UInt64(Header[96]);
  if (EntrySize = 0) or (EntryCount = 0) or (EntryCount > 512) then
  begin
    AError := 'The GPT header reports ' + IntToStr(EntryCount) +
      ' entries of ' + IntToStr(EntrySize) + ' bytes, which is not usable';
    Exit;
  end;
  DoLog(Format('GPT: %d entries of %d bytes at LBA %d, usable LBA %d..%d',
    [Int64(EntryCount), Int64(EntrySize), Int64(EntryLba),
     Int64(FirstUsable), Int64(LastUsable)]));

  EntryBytes := Integer(EntryCount) * Integer(EntrySize);
  if not FSession.Da.ReadFlashBytes(EntryLba * CSector, UInt64(EntryBytes),
    Entries, MTK_PART_USER) then
  begin
    AError := 'Could not read the GPT entry array: ' + FSession.Da.LastError;
    Exit;
  end;
  ALines.Add(Format('%-4s %-24s %-16s %-16s %s',
    ['#', 'name', 'start LBA', 'end LBA', 'size']));
  for I := 0 to Integer(EntryCount) - 1 do
  begin
    P := I * Integer(EntrySize);
    if P + CEntrySize > Length(Entries) then
      Break;
    StartLba := 0;
    EndLba := 0;
    for NameAt := 0 to 7 do
    begin
      StartLba := (StartLba shl 8) or Entries[P + 32 + NameAt];
      EndLba := (EndLba shl 8) or Entries[P + 40 + NameAt];
    end;
    { an entry with no LBAs is an unused slot }
    if (StartLba = 0) and (EndLba = 0) then
      Continue;
    { the entry name is UTF-16LE; collect it as such and convert once, because
      appending a WideChar to an AnsiString is a type error under FPC }
    NameW := '';
    NameAt := P + 56;
    while NameAt + 1 < P + 56 + 72 do
    begin
      Ch := Word(Entries[NameAt]) or (Word(Entries[NameAt + 1]) shl 8);
      if Ch = 0 then
        Break;
      NameW := NameW + WideChar(Ch);
      Inc(NameAt, 2);
    end;
    Name := string(NameW);
    if Name = '' then
      Name := '(unnamed)';
    { Int64 casts: FPC passes a UInt64 to an open array as vtQWord, which
      Format('%d') refuses, while Delphi passes it as vtInt64. }
    ALines.Add(Format('%-4d %-24s %-16d %-16d %s',
      [I, Name, Int64(StartLba), Int64(EndLba),
       FormatScatterSize((EndLba - StartLba + 1) * CSector)]));
  end;
  Result := ALines.Count > 1;
  if not Result then
    AError := 'The GPT entry array is empty';
end;

function TJobEngine.JobReadPartitions: TJobOutcome;
var
  Lines: TStringList;
  Err: string;
  I: Integer;
  D: TScatterEntryArray;
begin
  Lines := TStringList.Create;
  try
    if FSession.Scatter.Valid then
    begin
      DoLog('Partition table from the scatter file:');
      FSession.Scatter.AppendTableTo(Lines);
      D := FSession.Scatter.Downloadable;
      DoLog(IntToStr(Length(D)) +
        ' of them are marked for download by this ROM.');
    end
    else
    begin
      if Trim(FParams.ScatFile) <> '' then
        DoLog('The scatter file could not be used (' +
          FSession.Scatter.Message + '); reading the GPT from the flash.');
      if not RequireDa('Read Partitions', Result) then
        Exit;
      DoLog('Partition table read from the flash (GPT at LBA 1):');
      if not ReadGpt(Lines, Err) then
      begin
        DoLog(Err);
        Result := OutcomeFail('NO_GPT', Err);
        Exit;
      end;
    end;
    for I := 0 to Lines.Count - 1 do
      DoLog(Lines[I]);
    Result := OutcomeOk(IntToStr(Lines.Count - 1) + ' partition(s) listed',
      Int64(Lines.Count));
    Result.BytesMoved := Int64(Lines.Count);
  finally
    Lines.Free;
  end;
end;

function TJobEngine.JobReadBin: TJobOutcome;
var
  Stream: TFileStream;
  Err: string;
begin
  if not RequireDa('Read BIN', Result) then
    Exit;
  if (FParams.Size = 0) then
  begin
    Result := OutcomeFail('BAD_SIZE', 'The size to read is 0');
    DoLog(Result.Message);
    Exit;
  end;
  if not OpenOutFile(FParams.OutFile, Stream, Err) then
  begin
    Result := OutcomeFail('NO_FILE', Err);
    DoLog(Err);
    Exit;
  end;
  try
    DoLog(Format('Reading %s from 0x%s ...',
      [FormatScatterSize(FParams.Size), IntToHex(FParams.Address, 8)]));
    DoProgress(0, 'Reading');
    if not FSession.Da.ReadFlash(FParams.Address, FParams.Size, Stream,
      MTK_PART_USER) then
    begin
      Result := OutcomeFail('READ', FSession.Da.LastError);
      DoLog(Result.Message);
      Exit;
    end;
    Result := OutcomeOk('Read ' + FormatScatterSize(UInt64(Stream.Size)) +
      ' to ' + FParams.OutFile, Stream.Size);
  finally
    Stream.Free;
  end;
end;

function TJobEngine.JobReadRegion: TJobOutcome;
var
  Stream: TFileStream;
  Err, Region: string;
  Part: Integer;
  Size, Start: UInt64;
  Info: TMtkFlashInfo;
begin
  if not RequireDa('Read Region', Result) then
    Exit;
  Region := FParams.Storage;
  Part := RegionPartition(Region);
  Info := FSession.FlashInfo;
  case Part of
    MTK_PART_BOOT1: Size := Info.Boot1Size;
    MTK_PART_BOOT2: Size := Info.Boot2Size;
    MTK_PART_RPMB: Size := Info.RpmbSize;
  else
    Size := Info.UserAreaSize;
  end;
  if Size = 0 then
  begin
    { fall back to the scatter table when the DA did not report a size }
    Start := 0;
    if FSession.Scatter.Valid and
       FSession.Scatter.RangeOf(Region, Start, Size) then
      DoLog('Size taken from the scatter file.')
    else
      Size := Info.FlashSize;
  end;
  if Size = 0 then
  begin
    Result := OutcomeFail('NO_SIZE', 'The size of region ' + Region +
      ' is unknown. Use Read BIN with an explicit address and size.');
    DoLog(Result.Message);
    Exit;
  end;
  if not OpenOutFile(FParams.OutFile, Stream, Err) then
  begin
    Result := OutcomeFail('NO_FILE', Err);
    DoLog(Err);
    Exit;
  end;
  try
    DoLog('Reading region ' + Region + ' (' + FormatScatterSize(Size) +
      ', partition byte ' + IntToStr(Part) + ') ...');
    DoProgress(0, 'Reading ' + Region);
    if not FSession.Da.ReadFlash(0, Size, Stream, Part) then
    begin
      Result := OutcomeFail('READ', FSession.Da.LastError);
      DoLog(Result.Message);
      Exit;
    end;
    Result := OutcomeOk('Region ' + Region + ' saved to ' + FParams.OutFile,
      Stream.Size);
  finally
    Stream.Free;
  end;
end;

function TJobEngine.JobReadOtp: TJobOutcome;
var
  Data: TBytesArray;
  I: Integer;
  Line: string;
begin
  if not RequireDa('Read OTP', Result) then
    Exit;
  DoLog('Reading the OTP region through the download agent ...');
  DoLog('Note: most legacy download agents answer the OTP read command only ' +
    'when the board exposes an OTP area at all. MediaTek reports ' +
    '"DA OTP not supported" ($C0040100) when it does not.');
  if not FSession.Da.ReadFlashBytes(0, $800, Data, MTK_PART_RPMB) then
  begin
    Result := OutcomeFail('OTP', 'OTP read failed: ' + FSession.Da.LastError);
    DoLog(Result.Message);
    Exit;
  end;
  for I := 0 to (Length(Data) div 16) - 1 do
  begin
    Line := IntToHex(I * 16, 4) + ': ';
    DoLog(Line + HexDump(Copy(Data, I * 16, 16), 16));
  end;
  Result := OutcomeOk(IntToStr(Length(Data)) + ' OTP bytes read',
    Int64(Length(Data)));
end;

function TJobEngine.JobReadEmi: TJobOutcome;
var
  Data: TBytesArray;
  Stream: TFileStream;
  Err: string;
  Boot1: UInt64;
begin
  if not (FSession.Stage in [ssHandshake, ssDa, ssReady]) then
  begin
    Result := OutcomeFail('NO_BROM',
      'Reading the EMI needs at least a boot ROM connection');
    DoLog(Result.Message);
    Exit;
  end;
  Boot1 := FSession.FlashInfo.Boot1Size;
  if Boot1 = 0 then
    Boot1 := $40000;
  DoLog('Reading the preloader region (boot1, ' + FormatScatterSize(Boot1) +
    ') - the EMI/DRAM configuration lives inside it.');
  if FSession.DaAvailable then
  begin
    if not FSession.Da.ReadFlashBytes(0, Boot1, Data, MTK_PART_BOOT1) then
    begin
      Result := OutcomeFail('EMI', 'Could not read the preloader: ' +
        FSession.Da.LastError);
      DoLog(Result.Message);
      Exit;
    end;
  end
  else
  begin
    DoLog('The download agent is not running, so the preloader is read ' +
      'through the boot ROM memory commands instead.');
    if FSession.Brom = nil then
    begin
      Result := OutcomeFail('EMI', 'No boot ROM connection');
      Exit;
    end;
    if not FSession.Brom.ReadMem($200000, $1000, Data) then
    begin
      Result := OutcomeFail('EMI', 'Boot ROM memory read failed: ' +
        FSession.Brom.LastError + '. Reading the EMI needs the download ' +
        'agent on most boards.');
      DoLog(Result.Message);
      Exit;
    end;
  end;
  if Trim(FParams.OutFile) <> '' then
  begin
    if not OpenOutFile(FParams.OutFile, Stream, Err) then
    begin
      Result := OutcomeFail('NO_FILE', Err);
      DoLog(Err);
      Exit;
    end;
    try
      if Length(Data) > 0 then
        Stream.WriteBuffer(Data[0], Length(Data));
    finally
      Stream.Free;
    end;
    DoLog('Saved to ' + FParams.OutFile);
  end
  else
    DoLog('First bytes: ' + HexDump(Data, 64));
  Result := OutcomeOk(IntToStr(Length(Data)) +
    ' bytes of preloader / EMI data read', Int64(Length(Data)));
end;

function TJobEngine.JobFormat: TJobOutcome;
var
  Start, Size, BootEnd: UInt64;
  Entry: TScatterEntry;
begin
  if not RequireDa('Format', Result) then
    Exit;
  Start := 0;
  Size := FSession.FlashInfo.UserAreaSize;
  if Size = 0 then
    Size := FSession.FlashInfo.FlashSize;
  if Size = 0 then
  begin
    Result := OutcomeFail('NO_SIZE',
      'The download agent did not report a flash size, so there is nothing ' +
      'to format safely. Use Read Flash Info first.');
    DoLog(Result.Message);
    Exit;
  end;

  if FParams.ExceptBootloader then
  begin
    BootEnd := 0;
    if FSession.Scatter.FindByName('preloader', Entry) then
      BootEnd := Entry.StartAddr + Entry.Size;
    if BootEnd = 0 then
      BootEnd := $100000;   { 1 MiB, the usual preloader allowance }
    Start := BootEnd;
    Size := Size - Start;
    DoLog('Keeping the bootloader: formatting from 0x' +
      IntToHex(Start, 8) + ' to the end of the user area.');
  end
  else if FParams.ManualFormat then
  begin
    Start := FParams.Address;
    Size := FParams.Size;
    if Size = 0 then
      Size := FSession.FlashInfo.UserAreaSize - Start;
    DoLog('Manual range: 0x' + IntToHex(Start, 8) + ' + ' +
      FormatScatterSize(Size));
  end
  else
    DoLog('Auto format of the whole user area (' + FormatScatterSize(Size) +
      ').');

  if FParams.CreateDefaultFs then
    DoLog('"Create default FS" was asked for. The download agent formats the ' +
      'raw area; the file system itself is created by the ROM images, so ' +
      'write a firmware or let Android recreate it on first boot.');

  DoProgress(0, 'Formatting');
  if not FSession.Da.FormatFlash(Start, Size, MTK_PART_USER) then
  begin
    Result := OutcomeFail('FORMAT', FSession.Da.LastError);
    DoLog(Result.Message);
    Exit;
  end;
  Result := OutcomeOk('Formatted ' + FormatScatterSize(Size) +
    ' of the user area', Int64(Size));
end;

function TJobEngine.JobWipeData: TJobOutcome;
var
  Start, Size: UInt64;
begin
  if not RequireDa('Wipe Data', Result) then
    Exit;
  if not FSession.Scatter.RangeOf('userdata', Start, Size) then
  begin
    Result := OutcomeFail('NO_SCATTER',
      'Wipe Data erases the "userdata" partition, which is only known from ' +
      'the scatter file. Select the scatter file of this ROM, or use Format ' +
      'with a manual range.');
    DoLog(Result.Message);
    Exit;
  end;
  DoLog('Erasing userdata at 0x' + IntToHex(Start, 8) + ' (' +
    FormatScatterSize(Size) + ') ...');
  DoProgress(0, 'Erasing userdata');
  if not FSession.Da.FormatFlash(Start, Size, MTK_PART_USER) then
  begin
    Result := OutcomeFail('FORMAT', FSession.Da.LastError);
    DoLog(Result.Message);
    Exit;
  end;
  Result := OutcomeOk('userdata erased (' + FormatScatterSize(Size) + ')',
    Int64(Size));
end;

function TJobEngine.JobWipePartitions: TJobOutcome;
const
  CParts: array[0..5] of string = ('cache', 'userdata', 'metadata',
    'frp', 'persist', 'cust');
var
  I: Integer;
  Start, Size, Done: UInt64;
  Found: Boolean;
begin
  if not RequireDa('Wipe Partitions', Result) then
    Exit;
  if not FSession.Scatter.Valid then
  begin
    Result := OutcomeFail('NO_SCATTER',
      'Wipe Partitions needs the scatter file of this ROM to know where ' +
      'cache, userdata, metadata, frp, persist and cust live. Select it ' +
      'first.');
    DoLog(Result.Message);
    Exit;
  end;
  Done := 0;
  Found := False;
  for I := 0 to High(CParts) do
  begin
    if FCancelled then
      Exit(OutcomeCancelled);
    if FSession.Scatter.RangeOf(CParts[I], Start, Size) and (Size > 0) then
    begin
      Found := True;
      DoLog('Erasing ' + CParts[I] + ' at 0x' + IntToHex(Start, 8) + ' (' +
        FormatScatterSize(Size) + ')');
      DoProgress((I * 100) div (High(CParts) + 1), 'Erasing ' + CParts[I]);
      if not FSession.Da.FormatFlash(Start, Size, MTK_PART_USER) then
      begin
        Result := OutcomeFail('FORMAT', CParts[I] + ': ' +
          FSession.Da.LastError);
        DoLog(Result.Message);
        Exit;
      end;
      Inc(Done, Size);
    end
    else
      DoLog(CParts[I] + ' is not in the scatter file - skipped.');
  end;
  if not Found then
  begin
    Result := OutcomeFail('NO_PARTS',
      'None of the wipeable partitions are in the scatter file.');
    DoLog(Result.Message);
    Exit;
  end;
  Result := OutcomeOk('Wiped ' + FormatScatterSize(Done), Int64(Done));
end;

function TJobEngine.JobEraseFrp(AButAlsoWipe: Boolean): TJobOutcome;
var
  Start, Size, Done: UInt64;
begin
  if not RequireDa('Erase FRP', Result) then
    Exit;
  if not FSession.Scatter.RangeOf('frp', Start, Size) then
  begin
    Result := OutcomeFail('NO_FRP',
      'The scatter file has no "frp" partition. On some boards it is called ' +
      '"persist" or lives in a raw offset - use Read Partitions to find it, ' +
      'then Write BIN a zero image over it.');
    DoLog(Result.Message);
    Exit;
  end;
  if Size = 0 then
    Size := $100000;
  DoLog('Erasing frp at 0x' + IntToHex(Start, 8) + ' (' +
    FormatScatterSize(Size) + ') ...');
  DoProgress(10, 'Erasing frp');
  if not FSession.Da.FormatFlash(Start, Size, MTK_PART_USER) then
  begin
    Result := OutcomeFail('FORMAT', FSession.Da.LastError);
    DoLog(Result.Message);
    Exit;
  end;
  Done := Size;
  if AButAlsoWipe then
  begin
    DoProgress(50, 'Erasing userdata');
    if FSession.Scatter.RangeOf('userdata', Start, Size) and (Size > 0) then
    begin
      DoLog('Erasing userdata at 0x' + IntToHex(Start, 8) + ' (' +
        FormatScatterSize(Size) + ') ...');
      if not FSession.Da.FormatFlash(Start, Size, MTK_PART_USER) then
      begin
        Result := OutcomeFail('FORMAT', 'userdata: ' + FSession.Da.LastError);
        DoLog(Result.Message);
        Exit;
      end;
      Inc(Done, Size);
    end
    else
      DoLog('No userdata partition in the scatter file - only frp was erased.');
  end;
  Result := OutcomeOk('Erased ' + FormatScatterSize(Done), Int64(Done));
end;

function TJobEngine.JobWriteFirmware: TJobOutcome;
var
  List: TScatterEntryArray;
  I: Integer;
  Entry: TScatterEntry;
  FileName, Dir, Err: string;
  Stream: TFileStream;
  Part: Integer;
  Total, Moved: Int64;
  Written, Skipped: Integer;
begin
  if not RequireDa('Write Firmware', Result) then
    Exit;
  if not FSession.Scatter.Valid then
  begin
    Result := OutcomeFail('NO_SCATTER',
      'Writing firmware needs the scatter file of this ROM: it is the only ' +
      'thing that says which image goes to which address. Select it in the ' +
      'Files box.');
    DoLog(Result.Message);
    Exit;
  end;
  List := FSession.Scatter.Downloadable;
  if Length(List) = 0 then
  begin
    Result := OutcomeFail('NO_IMAGES',
      'The scatter file marks no partition for download.');
    DoLog(Result.Message);
    Exit;
  end;
  Dir := ExtractFilePath(FParams.ScatFile);
  Total := 0;
  for I := 0 to High(List) do
    if List[I].FileName <> '' then
      Inc(Total, Int64(List[I].Size));
  DoLog(IntToStr(Length(List)) + ' partition(s) to write, ' +
    FormatScatterSize(UInt64(Total)) + ' in total.');

  Moved := 0;
  Written := 0;
  Skipped := 0;
  for I := 0 to High(List) do
  begin
    if FCancelled then
      Exit(OutcomeCancelled);
    Entry := List[I];
    if Entry.FileName = '' then
    begin
      DoLog(Entry.Name + ': the ROM carries no image for it - skipped.');
      Inc(Skipped);
      Continue;
    end;
    FileName := Entry.FileName;
    if (Length(FileName) < 2) or (FileName[2] <> ':') then
      FileName := Dir + FileName;
    if not FileExists(FileName) then
    begin
      DoLog(Entry.Name + ': image ' + ExtractFileName(FileName) +
        ' is not next to the scatter file - skipped.');
      Inc(Skipped);
      Continue;
    end;
    if SameText(Entry.Name, 'preloader') then
      Part := MTK_PART_BOOT1
    else
      Part := RegionPartitionByte(Entry.Region);
    if Part < 0 then
      Part := MTK_PART_USER;
    if not OpenInFile(FileName, Stream, Err) then
    begin
      DoLog(Entry.Name + ': ' + Err);
      Inc(Skipped);
      Continue;
    end;
    try
      DoLog(Format('Writing %-16s %10s to 0x%s (partition %d)',
        [Entry.Name, FormatScatterSize(UInt64(Stream.Size)),
         IntToHex(Entry.StartAddr, 8), Part]));
      if not FSession.Da.WriteFlash(Entry.StartAddr, UInt64(Stream.Size),
        Stream, 0, Part) then
      begin
        Result := OutcomeFail('WRITE', Entry.Name + ': ' +
          FSession.Da.LastError);
        DoLog(Result.Message);
        Exit;
      end;
      Inc(Moved, Stream.Size);
      Inc(Written);
      DoProgress(Integer((Moved * 100) div MaxInt64(Total, 1)),
        'Written ' + IntToStr(Written) + '/' + IntToStr(Length(List)) +
        ' - ' + Entry.Name);
    finally
      Stream.Free;
    end;
  end;
  DoProgress(100, 'Write complete');
  if Written = 0 then
  begin
    Result := OutcomeFail('NO_IMAGES',
      'No image of this ROM was found next to the scatter file, so nothing ' +
      'was written. ' + IntToStr(Skipped) + ' partition(s) were skipped.');
    DoLog(Result.Message);
    Exit;
  end;
  Result := OutcomeOk(IntToStr(Written) + ' partition(s) written, ' +
    FormatScatterSize(UInt64(Moved)) +
    IfThenStr(Skipped > 0, ', ' + IntToStr(Skipped) + ' skipped', ''), Moved);
end;

function TJobEngine.JobWriteBin: TJobOutcome;
var
  Stream: TFileStream;
  Err: string;
  Part: Integer;
begin
  if not RequireDa('Write BIN', Result) then
    Exit;
  if not OpenInFile(FParams.BinFile, Stream, Err) then
  begin
    Result := OutcomeFail('NO_FILE', Err);
    DoLog(Err);
    Exit;
  end;
  try
    Part := MTK_PART_USER;
    if FParams.Size > 0 then
      DoLog('Writing ' + FormatScatterSize(UInt64(Stream.Size)) +
        ' to 0x' + IntToHex(FParams.Address, 8) + ' (limit ' +
        FormatScatterSize(FParams.Size) + ')')
    else
      DoLog('Writing ' + FormatScatterSize(UInt64(Stream.Size)) +
        ' to 0x' + IntToHex(FParams.Address, 8));
    DoProgress(0, 'Writing');
    if not FSession.Da.WriteFlash(FParams.Address, UInt64(Stream.Size),
      Stream, 0, Part) then
    begin
      Result := OutcomeFail('WRITE', FSession.Da.LastError);
      DoLog(Result.Message);
      Exit;
    end;
    Result := OutcomeOk('Written to 0x' + IntToHex(FParams.Address, 8),
      Stream.Size);
  finally
    Stream.Free;
  end;
end;

function TJobEngine.JobRestoreBackup: TJobOutcome;
var
  Stream: TFileStream;
  Err: string;
  Size: UInt64;
begin
  if not RequireDa('Restore from backup', Result) then
    Exit;
  if not OpenInFile(FParams.BackupFile, Stream, Err) then
  begin
    Result := OutcomeFail('NO_FILE', Err);
    DoLog(Err);
    Exit;
  end;
  try
    Size := UInt64(Stream.Size);
    if FParams.Size > 0 then
    begin
      DoLog('This is a single image. It is restored to 0x' +
        IntToHex(FParams.Address, 8) + '.');
      DoProgress(0, 'Restoring');
      if not FSession.Da.WriteFlash(FParams.Address, Size, Stream, 0,
        MTK_PART_USER) then
      begin
        Result := OutcomeFail('WRITE', FSession.Da.LastError);
        DoLog(Result.Message);
        Exit;
      end;
      Result := OutcomeOk('Restored ' + FormatScatterSize(Size) + ' to 0x' +
        IntToHex(FParams.Address, 8), Stream.Size);
      Exit;
    end;
    Result := OutcomeFail('NO_LAYOUT',
      'A whole-flash backup can only be restored partition by partition, ' +
      'because the app has to know which part of the file belongs to which ' +
      'address. Restore it one image at a time with Write BIN, or select the ' +
      'scatter file that matches the backup so the layout is known.');
    DoLog(Result.Message);
  finally
    Stream.Free;
  end;
end;

function TJobEngine.JobWriteOfp: TJobOutcome;
var
  Data: TBytesArray;
  Inner: TBytesArray;
  InnerName: string;
begin
  if not RequireDa('Write OFP', Result) then
    Exit;
  if not LoadFileBytes(FParams.OfpFile, Data) then
  begin
    Result := OutcomeFail('NO_FILE', 'Cannot read ' + FParams.OfpFile);
    DoLog(Result.Message);
    Exit;
  end;
  DoLog('OFP container: ' + IntToStr(Length(Data)) + ' bytes.');
  if IsTarContainer(Data) and UnwrapTar(Data, Inner, InnerName) then
  begin
    DoLog('It is a TAR container; the first member is "' + InnerName +
      '" (' + IntToStr(Length(Inner)) + ' bytes).');
    Data := Inner;
  end;
  if LooksLikeDaHeader(Data) then
  begin
    DoLog('The first member looks like a download agent header, not a flash ' +
      'image. An OFP holds an XML program file plus per-partition images; ' +
      'unpack it and write the images with Write BIN, or flash the ROM with ' +
      'the vendor tool.');
  end;
  Result := OutcomeFail('OFP',
    'The OFP container format (the XML program file and the encrypted ' +
    'per-partition images OPPO and Realme ship) is not implemented in this ' +
    'build, and guessing at the layout would risk bricking the phone. Unpack ' +
    'the OFP and write its images with Write BIN, using the addresses from ' +
    'the program file.');
  DoLog(Result.Message);
end;

function TJobEngine.JobRpmbBackup: TJobOutcome;
var
  Data: TBytesArray;
  Size: UInt64;
  Stream: TFileStream;
  Err: string;
begin
  if not RequireDa('Backup RPMB', Result) then
    Exit;
  Size := FSession.FlashInfo.RpmbSize;
  if Size = 0 then
    Size := $400000;   { 4 MiB, the usual RPMB allocation }
  if FParams.Size > 0 then
    Size := FParams.Size;
  DoLog('Reading ' + FormatScatterSize(Size) + ' of RPMB (partition byte ' +
    IntToStr(MTK_PART_RPMB) + ') ...');
  DoProgress(0, 'Reading RPMB');
  if not FSession.Da.ReadFlashBytes(FParams.RpmbAddress, Size, Data,
    MTK_PART_RPMB) then
  begin
    Result := OutcomeFail('RPMB', 'RPMB read failed: ' +
      FSession.Da.LastError + '. RPMB is key protected: many download agents ' +
      'answer it only with the matching key provisioned.');
    DoLog(Result.Message);
    Exit;
  end;
  if not OpenOutFile(FParams.OutFile, Stream, Err) then
  begin
    Result := OutcomeFail('NO_FILE', Err);
    DoLog(Err);
    Exit;
  end;
  try
    if Length(Data) > 0 then
      Stream.WriteBuffer(Data[0], Length(Data));
    Result := OutcomeOk('RPMB saved to ' + FParams.OutFile + ' (' +
      FormatScatterSize(UInt64(Length(Data))) + ')', Int64(Length(Data)));
  finally
    Stream.Free;
  end;
end;

function TJobEngine.JobRpmbWrite: TJobOutcome;
begin
  DoLog('RPMB is a replay-protected partition: every write has to be signed ' +
    'with the 256-bit key that was provisioned into this exact device, and ' +
    'the counter in the frame has to be higher than the one already stored.');
  Result := OutcomeFail('RPMB_KEY',
    'Writing RPMB is not implemented in this build. The legacy download agent ' +
    'offers no RPMB key programming command, and writing frames without the ' +
    'device key would corrupt the partition permanently. Use Backup RPMB to ' +
    'read it, and the vendor tool that holds the key to write it.');
  DoLog(Result.Message);
end;

function TJobEngine.JobRpmbFormat: TJobOutcome;
begin
  Result := OutcomeFail('RPMB_RO',
    'RPMB cannot be formatted. It is one-time programmable and replay ' +
    'protected: there is no erase command, and the stored counter can never ' +
    'go back. Nothing was sent to the device.');
  DoLog(Result.Message);
end;

function TJobEngine.JobDownloadAgent: TJobOutcome;
begin
  if FSession.DaAvailable then
  begin
    DoLog('The download agent is already running on this session.');
    LogFlashInfo;
    Result := OutcomeOk('Download agent running', 0);
    Exit;
  end;
  Result := OutcomeFail('DA', 'The download agent did not start: ' +
    FSession.LastError);
  DoLog(Result.Message);
end;

function TJobEngine.JobAuth(ABromStage: Boolean): TJobOutcome;
var
  Auth: TBytesArray;
  Msg: string;
begin
  if Trim(FParams.AuthFile) = '' then
  begin
    Result := OutcomeFail('NO_AUTH',
      'No authorization file was selected. Choose the .auth that belongs to ' +
      'this board in the Files box.');
    DoLog(Result.Message);
    Exit;
  end;
  if not LoadFileBytes(FParams.AuthFile, Auth) then
  begin
    Result := OutcomeFail('AUTH', 'Cannot read ' + FParams.AuthFile);
    DoLog(Result.Message);
    Exit;
  end;
  if ABromStage then
    Msg := 'BROM authorization'
  else
    Msg := 'Preloader authorization';
  DoLog(Msg + ': sending ' + IntToStr(Length(Auth)) + ' bytes ...');
  if FSession.Brom = nil then
  begin
    Result := OutcomeFail('NO_BROM', 'The boot ROM is not connected');
    DoLog(Result.Message);
    Exit;
  end;
  if not FSession.Brom.SendAuth(Auth) then
  begin
    Result := OutcomeFail('AUTH', Msg + ' was refused: ' +
      FSession.Brom.LastError);
    DoLog(Result.Message);
    Exit;
  end;
  Result := OutcomeOk(Msg + ' accepted', Int64(Length(Auth)));
end;

function TJobEngine.JobReadPhoneInfoBrom: TJobOutcome;
var
  MeId, SocId: TBytesArray;
  Code: UInt32;
begin
  if FSession.Brom = nil then
  begin
    Result := OutcomeFail('NO_BROM', 'The boot ROM is not connected');
    Exit;
  end;
  DoLog('--- phone information (boot ROM) ---');
  DoLog('Chip      : ' + IfThenStr(FSession.Brom.ChipKnown,
    FSession.ChipLabel, 'unknown'));
  if FSession.Brom.GetHwCode(Code) then
    DoLog('HW code   : $' + IntToHex(Code and $FFFF, 4));
  DoLog('HW ver    : $' + IntToHex(FSession.Brom.HwVer, 4));
  DoLog('SW ver    : $' + IntToHex(FSession.Brom.SwVer, 4));
  DoLog('BROM ver  : ' + IntToStr(FSession.Brom.BromVer));
  DoLog('BL ver    : ' + IntToStr(FSession.Brom.BlVer));
  DoLog('Target    : ' + TargetConfigText(FSession.Brom.Target));
  if FSession.Brom.GetMeId(MeId) then
    DoLog('ME ID     : ' + HexDump(MeId, Length(MeId)));
  if FSession.Brom.GetSocId(SocId) then
    DoLog('SOC ID    : ' + HexDump(SocId, Length(SocId)));
  if FSession.DaAvailable then
  begin
    DoLog('--- storage ---');
    LogFlashInfo;
  end;
  Result := OutcomeOk('Phone information read', 0);
end;

function TJobEngine.BackupPartition(const AName: string; AOutDir: string;
  out ASavedTo: string; out AError: string): Boolean;
var
  Start, Size: UInt64;
  Stream: TFileStream;
begin
  Result := False;
  ASavedTo := '';
  AError := '';
  if not FSession.Scatter.RangeOf(AName, Start, Size) or (Size = 0) then
  begin
    AError := 'The scatter file has no "' + AName + '" partition';
    Exit;
  end;
  if Size > (64 * 1024 * 1024) then
  begin
    AError := AName + ' is ' + FormatScatterSize(Size) +
      ' - too big to back up as part of this job';
    Exit;
  end;
  if AOutDir = '' then
    AOutDir := ExtractFilePath(ParamStr(0));
  ASavedTo := IncludeTrailingPathDelimiter(AOutDir) +
    FParams.ModelCode + '_' + AName + '.bin';
  Stream := TFileStream.Create(ASavedTo, fmCreate);
  try
    DoLog('Backing up ' + AName + ' (' + FormatScatterSize(Size) +
      ') to ' + ASavedTo);
    if not FSession.Da.ReadFlash(Start, Size, Stream, MTK_PART_USER) then
    begin
      AError := AName + ': ' + FSession.Da.LastError;
      Exit;
    end;
  finally
    Stream.Free;
  end;
  Result := True;
end;

function TJobEngine.JobReadImeiNvram: TJobOutcome;
var
  Saved, Err: string;
  Backed: Integer;
begin
  if not RequireDa('Read IMEI', Result) then
    Exit;
  DoLog('The IMEI is stored in the NVRAM / NVDATA partition in a ' +
    'chip-specific encoding.');
  Backed := 0;
  if FSession.Scatter.Valid then
  begin
    if BackupPartition('nvram', '', Saved, Err) then
    begin
      DoLog('nvram saved: ' + Saved);
      Inc(Backed);
    end
    else
      DoLog('nvram: ' + Err);
    if BackupPartition('nvdata', '', Saved, Err) then
    begin
      DoLog('nvdata saved: ' + Saved);
      Inc(Backed);
    end
    else
      DoLog('nvdata: ' + Err);
  end
  else
    DoLog('No scatter file was selected, so the NVRAM partitions cannot be ' +
      'located. Select the scatter file of this ROM, or read the IMEI from a ' +
      'booted phone instead (it uses adb and needs no download mode).');

  Result := OutcomeFail('IMEI_CODEC',
    'Reading the IMEI out of NVRAM needs the MediaTek NVRAM record codec for ' +
    'this exact chip, which is not public and is not implemented here. ' +
    IfThenStr(Backed > 0, IntToStr(Backed) +
      ' NVRAM partition(s) were backed up so the IMEI can be read with a tool ' +
      'that has the codec.', 'No partition could be backed up.'));
  DoLog(Result.Message);
end;

function TJobEngine.JobRepairImei: TJobOutcome;
var
  Saved, Err: string;
  Backed: Integer;
begin
  if not RequireDa('Repair IMEI', Result) then
    Exit;
  if (FParams.Imei1 <> '') and (ImeiDigits(FParams.Imei1) < 14) then
  begin
    Result := OutcomeFail('BAD_IMEI', 'IMEI1 is not a 14 or 15 digit number');
    DoLog(Result.Message);
    Exit;
  end;
  if (FParams.Imei2 <> '') and (ImeiDigits(FParams.Imei2) < 14) then
  begin
    Result := OutcomeFail('BAD_IMEI', 'IMEI2 is not a 14 or 15 digit number');
    DoLog(Result.Message);
    Exit;
  end;
  DoLog('A repair writes the IMEI records into NVRAM / NVDATA. That is ' +
    'destructive if it goes wrong, so the partitions are backed up first.');
  Backed := 0;
  if FSession.Scatter.Valid then
  begin
    if BackupPartition('nvram', '', Saved, Err) then
    begin
      DoLog('nvram backed up: ' + Saved);
      Inc(Backed);
    end
    else
      DoLog('nvram: ' + Err);
    if BackupPartition('nvdata', '', Saved, Err) then
    begin
      DoLog('nvdata backed up: ' + Saved);
      Inc(Backed);
    end
    else
      DoLog('nvdata: ' + Err);
    if BackupPartition('nvcfg', '', Saved, Err) then
    begin
      DoLog('nvcfg backed up: ' + Saved);
      Inc(Backed);
    end
    else
      DoLog('nvcfg: ' + Err);
  end
  else
    DoLog('No scatter file was selected, so nothing could be backed up.');

  Result := OutcomeFail('IMEI_CODEC',
    'Writing the IMEI needs the MediaTek NVRAM record codec and the checksum ' +
    'layout for this exact chip. They are not public and are not implemented ' +
    'here, so the app refuses to write rather than corrupt the NVRAM. ' +
    IfThenStr(Backed > 0, IntToStr(Backed) +
      ' partition(s) were backed up first, so a repair with a tool that has ' +
      'the codec can be undone.', 'Nothing was written.'));
  DoLog(Result.Message);
  DoLog('Changing an IMEI is illegal in many countries. Only restore the ' +
    'original number of the device.');
end;

function TJobEngine.JobFixDlImageFail: TJobOutcome;
var
  Need: TCaptureNeed;
begin
  DoLog('"DL IMAGE FAIL" comes from the download agent when the image it was ' +
    'given does not match the board, or when the security checks reject it.');
  DoLog('The usual causes, in order:');
  DoLog('  1. the DA belongs to another chip - check the hwcode it reports ' +
    'against the one the phone reports;');
  DoLog('  2. the DA is an encrypted vendor container instead of an unpacked ' +
    '.bin;');
  DoLog('  3. the board demands SLA/DAA and no AUTH file was selected;');
  DoLog('  4. the preloader is newer than the DA (DRAM init mismatch, $BC3);');
  DoLog('  5. the phone is in preloader or META mode instead of BROM.');
  Need := coHandshake;
  DoLog('Connecting to the phone to see which of these it is ...');
  if not StartSession(Need) then
  begin
    Result := OutcomeFail('SESSION',
      'Could not connect to diagnose: ' + FSession.LastError);
    Exit;
  end;
  if FSession.Brom <> nil then
  begin
    DoLog('Chip reported by the phone : ' + IfThenStr(FSession.Brom.ChipKnown,
      FSession.ChipLabel, 'unknown'));
    DoLog('HW code                    : $' + IntToHex(FSession.Brom.HwCode, 4));
    DoLog('Target config              : ' +
      TargetConfigText(FSession.Brom.Target));
    if FSession.Brom.Target.Sla then
      DoLog('=> This board demands SLA. Without the vendor SLA key the ' +
        'download agent will always be rejected.');
    if FSession.Brom.Target.Daa or FSession.Brom.Target.Cert then
      DoLog('=> This board demands DA authentication. Select the matching ' +
        'AUTH file.');
    if FSession.DaImage <> nil then
    begin
      DoLog('Download agent in use      : ' + FSession.DaImage.Describe);
      if FSession.Brom.ChipKnown and
         (not FSession.DaImage.MatchesChip(FSession.Brom.HwCode)) then
        DoLog('=> MISMATCH: the DA is for hwcode $' +
          IntToHex(FSession.DaImage.HwCode, 4) + ' but the phone reports $' +
          IntToHex(FSession.Brom.HwCode, 4) + '. That is the DL IMAGE FAIL.');
    end;
  end;
  Result := OutcomeOk('Diagnosis finished', 0);
end;

end.
