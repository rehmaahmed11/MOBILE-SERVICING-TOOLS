unit DeviceSession;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


{ One session with one phone.

  This is the piece the whole app was missing: the lifecycle that starts when
  the user presses an action button and ends when the operation is finished.

      Open  ->  wait for the phone in the right service mode
            ->  lock it: its COM port with an EXCLUSIVE handle, or - for a
                MediaTek phone Windows did not expose as a COM port - its
                USB bulk interface claimed through the bundled libusb
            ->  run the platform bring-up (MediaTek: BROM handshake, then the
                download agent)
      ...   ->  the job runs against the held session
      Close ->  release the port, always, from a finally block

  The port is never released while a job is running. Windows only hands an
  exclusive handle to one process, so as long as the session is open no other
  program - and no other part of this app - can talk to the phone behind our
  back.

  Everything is synchronous and runs on the main thread. The UI stays alive
  because TPump.KeepAlive is called between packets; the capture form shows
  the wait and the progress.

  Platforms without a public protocol reference (Unisoc Diag/SPD, Samsung
  Loke/Odin, Qualcomm firehose) still get the full lifecycle - capture,
  exclusive lock, progress, release - but the bring-up step reports honestly
  that the vendor protocol is not implemented instead of pretending. }

interface

uses
{$IFDEF FPC}
  Windows, Classes, SysUtils, StrUtils,
{$ELSE}
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  System.StrUtils,
{$ENDIF}
  DevTypes, CommPort, UsbDetect, DevCapture, DevNotify,
  BromProtocol, MtkChips, MtkStatus, DaImage, MtkDaLegacy, ScatterFile;

type
  TSessionStage = (ssClosed, ssCapturing, ssLocked, ssHandshake, ssDa,
    ssReady);

  TSessionLogEvent = procedure(Sender: TObject; const AText: string) of object;
  TSessionProgressEvent = procedure(Sender: TObject; APercent: Integer;
    const AText: string) of object;

  { Lets the message loop run while a long synchronous step is in progress, so
    the capture form keeps repainting. Installed by the UI layer; nil in the
    self-test, where there is nothing to repaint. }
  TKeepAliveProc = procedure of object;

  { Builds a stand-in download agent for the simulated device. Installed from
    SimPort.BuildSyntheticDa at start-up so that no protocol unit has to depend
    on the simulator. }
  TSyntheticDaFactory = function(AHwCode: Word): TBytesArray;

  TPump = class(TObject)
  public
    class procedure KeepAlive;
    { nil when nothing is pumping messages (self-test, CI). }
    class var Handler: TKeepAliveProc;
  end;

  TDeviceSession = class(TObject)
  private
    FCapture: TDeviceCapture;
    FTransport: TCommTransport;
    FOwnTransport: Boolean;
    FBrom: TBromProtocol;
    FDa: TMtkDaLegacy;
    FDaImage: TDaImage;
    FScatter: TScatterFile;
    FStage: TSessionStage;
    FLastError: string;
    FSimulated: Boolean;
    FCancelled: Boolean;
    FPlatform: TDevPlatform;
    FForceBrom: Boolean;
    FGrab: TGrabbedPort;
    FOnLog: TSessionLogEvent;
    FOnProgress: TSessionProgressEvent;
    FBytesMoved: Int64;
    FCaptureTimeout: Integer;
    function GetLocked: Boolean;
    function GetPortName: string;
    function GetReady: Boolean;
    function GetConnected: Boolean;
    function GetFlashInfo: TMtkFlashInfo;
    function GetChipLabel: string;
    function MissingTransportMessage(const ADevice: TUsbDevice): string;
    procedure DoLog(const AText: string);
    procedure DoProgress(APercent: Integer; const AText: string);
    procedure CaptureProgress(Sender: TObject; const AText: string;
      ASecondsLeft: Integer);
    procedure BromLog(Sender: TObject; const AText: string);
    procedure DaLog(Sender: TObject; const AText: string);
    procedure DaProgress(Sender: TObject; ADone, ATotal: Int64);
    function OpenMtk(ANeed: TCaptureNeed; const ADaFile, AAuthFile,
      AScatFile: string): Boolean;
    function OpenComPlatform(ANeed: TCaptureNeed): Boolean;
    function BootDa(const ADaFile, AAuthFile: string): Boolean;
    function LoadAuth(const AAuthFile: string; out AAuth: TBytesArray;
      out AMessage: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    { Waits for the phone, locks its port and brings the platform up to the
      level ANeed asks for. Fills LastError and returns False on any failure -
      including an honest "protocol not implemented" for platforms we cannot
      drive. The port stays locked until Close. }
    function Open(APlatform: TDevPlatform; ANeed: TCaptureNeed;
      AForceBrom: Boolean; const ADaFile, AAuthFile, AScatFile: string;
      ATimeoutMs: Integer; AAllowSimulated: Boolean): Boolean;

    { Releases the port. Safe to call twice and safe to call when Open failed.
      Every caller must reach this from a finally block. }
    procedure Close;

    procedure Cancel;
    procedure ResetCancel;

    { True when the session is usable for the MediaTek flash commands. }
    function DaAvailable: Boolean;
    { Runs DA_CMD_FINISH so the phone leaves download mode, then releases. }
    procedure ShutdownDevice(ABootMode: Integer);

    property Stage: TSessionStage read FStage;
    property Locked: Boolean read GetLocked;
    property Ready: Boolean read GetReady;
    property Connected: Boolean read GetConnected;
    property PortName: string read GetPortName;
    property LastError: string read FLastError;
    property Simulated: Boolean read FSimulated;
    property Cancelled: Boolean read FCancelled;
    property Platform: TDevPlatform read FPlatform;
    property Grab: TGrabbedPort read FGrab;
    property Device: TUsbDevice read FGrab.Device;
    { Bytes the DA moved during this session, for the job summary. }
    property BytesMoved: Int64 read FBytesMoved;
    property FlashInfo: TMtkFlashInfo read GetFlashInfo;
    property ChipLabel: string read GetChipLabel;

    property Transport: TCommTransport read FTransport;
    property Brom: TBromProtocol read FBrom;
    property Da: TMtkDaLegacy read FDa;
    property DaImage: TDaImage read FDaImage;
    property Scatter: TScatterFile read FScatter;

    property OnLog: TSessionLogEvent read FOnLog write FOnLog;
    property OnProgress: TSessionProgressEvent read FOnProgress
      write FOnProgress;
  end;

function StageName(AStage: TSessionStage): string;
{ True when the job needs the download agent, not just the BROM handshake. }
function NeedBootloader(ANeed: TCaptureNeed): Boolean;

{ Installs the simulated transport factory from SimPort without making every
  unit depend on it. Called once at start-up by the UI / self-test layer. }
procedure InstallSimulatedDevice(AFactory: TSimTransportFactory);
{ Also installs the synthetic download-agent builder used for the simulated
  device, so this unit never has to depend on SimPort. }
procedure InstallSyntheticDaFactory(AFactory: TSyntheticDaFactory);

implementation

uses
  UsbRaw;

{ -------------------------------------------------------------------- TPump }

var
  GSyntheticDa: TSyntheticDaFactory = nil;

class procedure TPump.KeepAlive;
begin
  if Assigned(Handler) then
    Handler;
end;

{ ------------------------------------------------------------ small helpers }

function StageName(AStage: TSessionStage): string;
begin
  case AStage of
    ssClosed: Result := 'closed';
    ssCapturing: Result := 'waiting for the device';
    ssLocked: Result := 'port locked';
    ssHandshake: Result := 'boot ROM handshake';
    ssDa: Result := 'download agent';
    ssReady: Result := 'ready';
  else
    Result := 'unknown';
  end;
end;

function NeedBootloader(ANeed: TCaptureNeed): Boolean;
begin
  Result := ANeed in [coBootloader];
end;

procedure InstallSimulatedDevice(AFactory: TSimTransportFactory);
begin
  InstallSimTransportFactory(AFactory);
end;

procedure InstallSyntheticDaFactory(AFactory: TSyntheticDaFactory);
begin
  GSyntheticDa := AFactory;
end;

{ --------------------------------------------------------- TDeviceSession }

constructor TDeviceSession.Create;
begin
  inherited Create;
  FCapture := TDeviceCapture.Create;
  FCapture.OnProgress := CaptureProgress;
  FTransport := nil;
  FOwnTransport := False;
  FBrom := nil;
  FDa := nil;
  FDaImage := nil;
  FScatter := TScatterFile.Create;
  FStage := ssClosed;
  FLastError := '';
  FSimulated := False;
  FCancelled := False;
  FPlatform := dpGeneric;
  FForceBrom := False;
  FGrab := EmptyGrabbedPort;
  FOnLog := nil;
  FOnProgress := nil;
  FBytesMoved := 0;
  FCaptureTimeout := CDefaultCaptureTimeoutMs;
end;

destructor TDeviceSession.Destroy;
begin
  Close;
  FScatter.Free;
  FDaImage.Free;
  FDa.Free;
  FBrom.Free;
  FCapture.Free;
  inherited Destroy;
end;

function TDeviceSession.GetLocked: Boolean;
begin
  Result := (FCapture <> nil) and FCapture.Locked;
end;

function TDeviceSession.GetPortName: string;
begin
  if FGrab.Found then
    Result := FGrab.PortName
  else
    Result := '';
end;

function TDeviceSession.GetReady: Boolean;
begin
  Result := FStage = ssReady;
end;

function TDeviceSession.GetConnected: Boolean;
begin
  Result := (FDa <> nil) and FDa.Connected;
end;

function TDeviceSession.GetFlashInfo: TMtkFlashInfo;
begin
  if FDa <> nil then
    Result := FDa.Info
  else
    Result := EmptyFlashInfo;
end;

function TDeviceSession.GetChipLabel: string;
begin
  if (FBrom <> nil) and FBrom.ChipKnown then
    Result := MtkChips.ChipLabel(FBrom.Chip)
  else
    Result := '';
end;

function TDeviceSession.MissingTransportMessage(
  const ADevice: TUsbDevice): string;
var
  Identity, AccessHint: string;
begin
  Identity := ADevice.VidPid;
  if ADevice.Name <> '' then
  begin
    if Identity <> '' then
      Identity := Identity + ' - ';
    Identity := Identity + ADevice.Name;
  end;
  if Identity = '' then
    Identity := 'the detected USB device';

  if FPlatform = dpMtk then
    AccessHint := 'Two transports were tried: the Windows VCOM COM port and '
      + 'a raw USB bind through the bundled libusb. Install or repair a '
      + 'compatible MediaTek USB VCOM/Preloader driver (a COM number in '
      + 'Device Manager) or the libusb WinUSB filter driver (install-filter '
      + 'is in the libusb folder of the support tree) so one of them can '
      + 'claim the device.'
  else
    AccessHint := 'Install the service driver that exposes this interface as '
      + 'a COM port, or use a supported transport.';

  Result := PlatformLabel(FPlatform) + ' device detected (' + Identity +
    ') but neither a COM/VCOM port nor a raw USB interface could be claimed. '
    + 'VID/PID detection alone is '
    + 'not a device lock. No protocol bytes were sent. ' + AccessHint;
end;

procedure TDeviceSession.DoLog(const AText: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, AText);
end;

procedure TDeviceSession.DoProgress(APercent: Integer; const AText: string);
begin
  TPump.KeepAlive;
  if Assigned(FOnProgress) then
    FOnProgress(Self, APercent, AText);
end;

procedure TDeviceSession.CaptureProgress(Sender: TObject; const AText: string;
  ASecondsLeft: Integer);
begin
  if ASecondsLeft > 0 then
    DoProgress(-1, AText + ' (' + IntToStr(ASecondsLeft) + 's left)')
  else
    DoProgress(-1, AText);
end;

procedure TDeviceSession.BromLog(Sender: TObject; const AText: string);
begin
  DoLog(AText);
end;

procedure TDeviceSession.DaLog(Sender: TObject; const AText: string);
begin
  DoLog(AText);
end;

procedure TDeviceSession.DaProgress(Sender: TObject; ADone, ATotal: Int64);
var
  Percent: Integer;
begin
  if ATotal > 0 then
    Percent := Integer((ADone * 100) div ATotal)
  else
    Percent := 0;
  FBytesMoved := ADone;
  DoProgress(Percent, Format('%s / %s',
    [IntToStr(ADone), IntToStr(ATotal)]));
end;

procedure TDeviceSession.Cancel;
begin
  FCancelled := True;
  if FCapture <> nil then
    FCapture.Cancel;
  if FBrom <> nil then
    FBrom.Cancel;
  if FDa <> nil then
    FDa.Cancel;
end;

procedure TDeviceSession.ResetCancel;
begin
  FCancelled := False;
  if FCapture <> nil then
    FCapture.ResetCancel;
  if FBrom <> nil then
    FBrom.ResetCancel;
  if FDa <> nil then
    FDa.ResetCancel;
end;

function TDeviceSession.DaAvailable: Boolean;
begin
  Result := (FDa <> nil) and FDa.Connected and (FTransport <> nil);
end;

procedure TDeviceSession.ShutdownDevice(ABootMode: Integer);
begin
  if not DaAvailable then
    Exit;
  if FDa.Shutdown(ABootMode) then
    DoLog('Device released by the download agent (finish command).')
  else
    DoLog('Finish command failed: ' + FDa.LastError);
end;

{ ------------------------------------------------------------------ bring-up }

function TDeviceSession.LoadAuth(const AAuthFile: string;
  out AAuth: TBytesArray; out AMessage: string): Boolean;
begin
  AAuth := nil;
  AMessage := '';
  if Trim(AAuthFile) = '' then
    Exit(True);
  if not FileExists(AAuthFile) then
  begin
    AMessage := 'Authorization file not found: ' + AAuthFile;
    Exit(False);
  end;
  if not LoadFileBytes(AAuthFile, AAuth) then
  begin
    AMessage := 'Authorization file could not be read: ' + AAuthFile;
    Exit(False);
  end;
  if Length(AAuth) = 0 then
  begin
    AMessage := 'Authorization file is empty: ' + AAuthFile;
    Exit(False);
  end;
  Result := True;
end;

function TDeviceSession.BootDa(const ADaFile, AAuthFile: string): Boolean;
var
  Da: TDaImage;
  Data: TBytesArray;
  Auth: TBytesArray;
  Msg: string;
  ChipMode: TDaMode;
begin
  Result := False;
  FStage := ssDa;
  if FBrom = nil then
  begin
    FLastError := 'No boot ROM connection to load the download agent onto';
    Exit;
  end;

  { Check the chip's DA dialect before sending AUTH or touching the selected
    payload. In particular, MT6761/MT6762 devices (hwcode $0717, including
    devices such as the Infinix Hot 8 X650C) use XFLASH, not the legacy DA
    implemented by this build. }
  ChipMode := dmLegacy;
  if FBrom.ChipKnown then
    ChipMode := FBrom.Chip.DaMode;
  if ChipMode <> dmLegacy then
  begin
    FLastError := 'This chip (' + MtkChips.ChipLabel(FBrom.Chip) +
      ', hwcode $' + IntToHex(FBrom.HwCode, 4) + ') uses the ' +
      DaModeLabel(ChipMode) + ' download-agent protocol. Only the legacy ' +
      'DA protocol is implemented in this build. No AUTH or DA was sent; a '
      + 'compatible XFLASH/XML implementation and a usable plaintext DA are '
      + 'required before flash operations can work.';
    DoLog(FLastError);
    Exit;
  end;

  Da := TDaImage.Create;
  try
    if Trim(ADaFile) <> '' then
    begin
      if not Da.LoadFromFile(ADaFile) then
      begin
        FLastError := 'Download agent "' + ExtractFileName(ADaFile) +
          '" could not be used: ' + Da.Message;
        DoLog(FLastError);
        if Da.Encrypted then
          DoLog('The supplied payload is an encrypted vendor container. An ' +
            'unpacked DA .bin for this exact chip is needed to continue.');
        Exit;
      end;
      if FBrom.ChipKnown and (not Da.MatchesChip(FBrom.HwCode)) then
        DoLog('Warning: the DA is built for hwcode $' +
          IntToHex(Da.HwCode, 4) + ' but the phone reports $' +
          IntToHex(FBrom.HwCode, 4) + '. Continuing anyway.');
      DoLog('Download agent: ' + Da.Describe);
    end
    else
    begin
      { No file: build a synthetic agent. It has a valid header and two stages
        but contains no vendor code, so it only works against the simulated
        device. Say so, loudly. }
      if not FSimulated then
      begin
        FLastError := 'No download agent selected. Choose the DA that belongs ' +
          'to this board in the Files box (the .bin the scatter file names, or ' +
          'the brand payload).';
        DoLog(FLastError);
        Exit;
      end;
      if not Assigned(GSyntheticDa) then
      begin
        FLastError := 'No simulated download-agent builder is installed, so ' +
          'the simulated device cannot be brought up.';
        DoLog(FLastError);
        Exit;
      end;
      Data := GSyntheticDa(FBrom.HwCode);
      if not Da.Parse(Data, 'synthetic-da') then
      begin
        FLastError := 'Could not build the synthetic download agent: ' +
          Da.Message;
        DoLog(FLastError);
        Exit;
      end;
      DoLog('Simulated device: using a synthetic download agent (' +
        IntToStr(Length(Data)) + ' bytes). It carries no vendor code.');
    end;

    { Send authorization only after the selected payload has parsed, but
      before stage 1 is sent to or started on the target. }
    if not LoadAuth(AAuthFile, Auth, Msg) then
    begin
      FLastError := Msg;
      Exit;
    end;
    if Length(Auth) > 0 then
    begin
      DoLog('Sending the authorization file (' + IntToStr(Length(Auth)) +
        ' bytes).');
      if not FBrom.SendAuth(Auth) then
      begin
        FLastError := 'BROM authorization failed: ' + FBrom.LastError;
        DoLog(FLastError);
        Exit;
      end;
      DoLog('BROM authorization accepted.');
    end
    else if FBrom.Target.Daa or FBrom.Target.Cert then
    begin
      FLastError := 'This device demands download-agent authentication ' +
        '(target config ' + TargetConfigText(FBrom.Target) + ') but no AUTH ' +
        'file was selected. Choose the .auth file that belongs to this board.';
      DoLog(FLastError);
      Exit;
    end;

    { Stage 1: send and jump. }
    if not FBrom.SendDa(Da.Stage1Address, Da.Stage1Data,
      Integer(Da.Stage1SigLen)) then
    begin
      FLastError := 'Sending the download agent failed: ' + FBrom.LastError;
      DoLog(FLastError);
      Exit;
    end;
    DoLog('Stage 1 sent to $' + IntToHex(Da.Stage1Address, 8) + ' (' +
      IntToStr(Length(Da.Stage1Data)) + ' bytes).');
    if FBrom.Chip.Has64Bit then
    begin
      if not FBrom.JumpDa64(Da.Stage1Address) then
      begin
        FLastError := 'Jumping to the download agent failed: ' +
          FBrom.LastError;
        DoLog(FLastError);
        Exit;
      end;
    end
    else if not FBrom.JumpDa(Da.Stage1Address) then
    begin
      FLastError := 'Jumping to the download agent failed: ' + FBrom.LastError;
      DoLog(FLastError);
      Exit;
    end;
    DoLog('Jumped to the download agent.');

    { Hand over the image so the job layer can inspect it later. }
    FDaImage.Free;
    FDaImage := Da;
    Da := nil;
  finally
    Da.Free;
  end;

  FDa := TMtkDaLegacy.Create(FBrom, FTransport);
  FDa.OnLog := DaLog;
  FDa.OnProgress := DaProgress;
  FDa.Simulated := FSimulated;
  if not FDa.Connect(FDaImage) then
  begin
    FLastError := FDa.LastError;
    DoLog('Download agent bring-up failed: ' + FLastError);
    Exit;
  end;

  DoLog('Download agent ready. Storage: ' +
    StorageKindName(FDa.Info.Kind) + ', flash ' +
    IntToStr(FDa.Info.FlashSize div (1024 * 1024)) + ' MiB' +
    ', user area ' + IntToStr(FDa.Info.UserAreaSize div (1024 * 1024)) +
    ' MiB, RPMB ' + IntToStr(FDa.Info.RpmbSize div 1024) + ' KiB.');
  FStage := ssReady;
  Result := True;
end;

function TDeviceSession.OpenMtk(ANeed: TCaptureNeed; const ADaFile,
  AAuthFile, AScatFile: string): Boolean;
begin
  Result := False;
  FStage := ssCapturing;
  DoLog('Waiting for a MediaTek phone in ' +
    ModesForPlatform(dpMtk) + ' mode' +
    IfThenStr(FForceBrom, ' (BROM forced)', '') + '...');
  DoLog(CaptureHint(dpMtk, FForceBrom));

  FGrab := FCapture.WaitForDevice(dpMtk, FCaptureTimeout, FSimulated);
  if FCancelled then
  begin
    FLastError := 'Cancelled';
    Exit;
  end;
  if not FGrab.Found then
  begin
    FLastError := FGrab.LockError;
    if FLastError = '' then
      FLastError := 'No MediaTek service device appeared within ' +
        IntToStr(FCaptureTimeout div 1000) + ' s';
    DoLog(FLastError);
    Exit;
  end;

  FSimulated := FGrab.Simulated;
  FTransport := FCapture.TakeTransport;
  if FGrab.Device.Mode <> '' then
    DoLog('Device: ' + DescribeDevice(FGrab.Device));

  { A matching VID/PID is only detection. A lock exists only after TDeviceCapture
    acquired something real: an exclusive COM handle, or - for a MediaTek
    phone with no COM port - a successful libusb interface claim, which is
    what PortOpen on the raw USB transport means. Never label a VID/PID-only
    candidate as a locked port. }
  if (FTransport = nil) or (not FTransport.PortOpen) or
     (not FCapture.Locked) then
  begin
    if FSimulated then
      FLastError := 'The simulated device transport did not open.'
    else
      FLastError := MissingTransportMessage(FGrab.Device);
    FGrab.LockError := FLastError;
    DoLog(FLastError);
    Exit;
  end;

  FStage := ssLocked;
  if FSimulated then
    DoLog('Simulated device attached instead of a phone. Every result of this ' +
      'session is flagged SIMULATED.')
  else if FTransport is TUsbTransport then
    DoLog('USB device ' + FGrab.PortName + ' is now claimed exclusively ' +
      '(libusb interface ' +
      IntToStr(TUsbTransport(FTransport).InterfaceNumber) + '). No other ' +
      'program can use it until this job finishes.')
  else
    DoLog('Port ' + FGrab.PortName + ' is now held exclusively. No other ' +
      'program can open it until this job finishes.');

  if ANeed = coCapture then
  begin
    FStage := ssReady;
    Exit(True);
  end;

  FStage := ssHandshake;
  FBrom := TBromProtocol.Create(FTransport);
  FBrom.OnLog := BromLog;
  FBrom.TimeoutMs := CDefaultIoTimeoutMs;
  { The simulated device answers in the same call that writes to it, so it can
    never need the real five-second window. Keeping it short bounds the
    unattended self-test: a protocol step the simulation does not answer costs
    a second instead of five. }
  if FSimulated then
    FBrom.TimeoutMs := 1000;
  if not FBrom.Handshake then
  begin
    FLastError := 'Boot ROM handshake failed: ' + FBrom.LastError;
    DoLog(FLastError);
    if FForceBrom then
      DoLog('"Force BROM" was on. If the phone was already past the boot ROM ' +
        '(preloader or DA running), switch it off and retry.');
    Exit;
  end;
  if not FBrom.Connect then
  begin
    FLastError := 'Boot ROM connection failed: ' + FBrom.LastError;
    DoLog(FLastError);
    Exit;
  end;

  DoLog('Chip: ' + IfThenStr(FBrom.ChipKnown, MtkChips.ChipLabel(FBrom.Chip),
    'unknown hwcode $' + IntToHex(FBrom.HwCode, 4)) +
    ', hwver $' + IntToHex(FBrom.HwVer, 4) +
    ', BROM ' + IntToStr(FBrom.BromVer) +
    ', BL ' + IntToStr(FBrom.BlVer));
  DoLog('Target config: ' + TargetConfigText(FBrom.Target));

  if ANeed = coHandshake then
  begin
    FStage := ssReady;
    Exit(True);
  end;

  if Trim(AScatFile) <> '' then
  begin
    if FScatter.LoadFromFile(AScatFile) then
      DoLog(FScatter.Describe)
    else
      DoLog('Scatter file not usable: ' + FScatter.Message);
  end;

  Result := BootDa(ADaFile, AAuthFile);
end;

function TDeviceSession.OpenComPlatform(ANeed: TCaptureNeed): Boolean;
begin
  Result := False;
  FStage := ssCapturing;
  DoLog('Waiting for a ' + PlatformLabel(FPlatform) + ' phone in ' +
    ModesForPlatform(FPlatform) + ' mode...');
  DoLog(CaptureHint(FPlatform, False));

  FGrab := FCapture.WaitForDevice(FPlatform, FCaptureTimeout, FSimulated);
  if FCancelled then
  begin
    FLastError := 'Cancelled';
    Exit;
  end;
  if not FGrab.Found then
  begin
    FLastError := FGrab.LockError;
    if FLastError = '' then
      FLastError := 'No ' + PlatformLabel(FPlatform) +
        ' service device appeared';
    DoLog(FLastError);
    Exit;
  end;

  FSimulated := FGrab.Simulated;
  FTransport := FCapture.TakeTransport;
  if FGrab.Device.Mode <> '' then
    DoLog('Device: ' + DescribeDevice(FGrab.Device));

  if (FTransport = nil) or (not FTransport.PortOpen) or
     (not FCapture.Locked) then
  begin
    if FSimulated then
      FLastError := 'The simulated device transport did not open.'
    else
      FLastError := MissingTransportMessage(FGrab.Device);
    FGrab.LockError := FLastError;
    DoLog(FLastError);
    Exit;
  end;

  FStage := ssLocked;
  if FSimulated then
    DoLog('Simulated device attached instead of a phone. Every result of this ' +
      'session is flagged SIMULATED.')
  else
    DoLog('Port ' + FGrab.PortName + ' is now held exclusively.');

  if ANeed = coCapture then
  begin
    FStage := ssReady;
    Exit(True);
  end;

  { The vendor bring-up for these platforms is not implemented. Report it
    instead of faking a connection - the port is still locked, so the user
    sees exactly where the session stopped. }
  case FPlatform of
    dpUnisoc:
      FLastError := 'The phone was captured and its port is locked, but the ' +
        'Unisoc / Spreadtrum Diag + FDL bring-up is not implemented in this ' +
        'build. The FDL1/FDL2 payloads bundled with the app are catalogued, ' +
        'not parsed: their protocol is not public.';
    dpQualcomm:
      FLastError := 'The phone was captured in EDL mode and its port is ' +
        'locked, but the Qualcomm Sahara / firehose bring-up is not ' +
        'implemented in this build. Firehose needs the vendor programmer ' +
        '(prog_firehose) for this exact chipset.';
    dpSamsung:
      FLastError := 'The phone was captured in download mode and its port is ' +
        'locked, but the Samsung Loke / Odin protocol is not implemented in ' +
        'this build. It is not public, and guessing at it could brick the ' +
        'device.';
  else
    FLastError := 'This platform has no service protocol to bring up.';
  end;
  DoLog(FLastError);
end;

function TDeviceSession.Open(APlatform: TDevPlatform; ANeed: TCaptureNeed;
  AForceBrom: Boolean; const ADaFile, AAuthFile, AScatFile: string;
  ATimeoutMs: Integer; AAllowSimulated: Boolean): Boolean;
begin
  Result := False;
  Close;
  FLastError := '';
  FPlatform := APlatform;
  FForceBrom := AForceBrom;
  FSimulated := AAllowSimulated and (SimTransportFactory <> nil);
  FCancelled := False;
  FBytesMoved := 0;
  if ATimeoutMs > 0 then
    FCaptureTimeout := ATimeoutMs
  else
    FCaptureTimeout := CDefaultCaptureTimeoutMs;
  ResetCancel;

  if ANeed = coNone then
  begin
    FStage := ssReady;
    Exit(True);
  end;
  if ANeed = coNormalMode then
  begin
    { No COM port: the job talks to adb / fastboot instead. }
    FStage := ssReady;
    Exit(True);
  end;

  case APlatform of
    dpMtk:
      Result := OpenMtk(ANeed, ADaFile, AAuthFile, AScatFile);
  else
    Result := OpenComPlatform(ANeed);
  end;

  if not Result then
    DoLog('Session stopped at "' + StageName(FStage) +
      '". Any open port handle is being released.');
end;

procedure TDeviceSession.Close;
begin
  FreeAndNil(FDa);
  FreeAndNil(FBrom);
  if FTransport <> nil then
  begin
    if FOwnTransport then
      FreeAndNil(FTransport)
    else
      FTransport := nil;
    FOwnTransport := False;
  end;
  if FCapture <> nil then
    FCapture.Release;
  FGrab := EmptyGrabbedPort;
  FStage := ssClosed;
  FSimulated := False;
end;

end.
