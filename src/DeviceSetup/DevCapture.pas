unit DevCapture;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

{ Device capture and the exclusive lock.

  This unit implements the behaviour the tool is supposed to have:

    1. An operation is started (Read, Write, Format, ...).
    2. Capture begins: the app waits for the phone to appear in the right
       service mode, watching both the Windows arrival notification and the
       polled device list, so it reacts the instant Device Manager picks the
       device up.
    3. The moment a candidate port is seen the app opens it with
       dwShareMode = 0 (TCommPort.Exclusive). Windows then answers every other
       open request with ERROR_SHARING_VIOLATION - the device is ours and no
       other program can take it away mid-operation.
    4. The lock is held for the whole job. It is released only by Release,
       which every job path calls from a finally block: after success, after a
       failure and after a cancel.

  Nothing here sends protocol data; it only finds and owns the port. }

interface

uses
{$IFDEF FPC}
  Windows, Classes, SysUtils,
{$ELSE}
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
{$ENDIF}
  DevTypes, CommPort, UsbDetect, DevNotify;

type
  { Factory for the simulated transport used by the self-test. Installed by
    SimPort so this unit does not depend on it. }
  TSimTransportFactory = function: TCommTransport;

  { A port we tried to take, and what happened. }
  TGrabbedPort = record
    Found: Boolean;
    PortName: string;       { 'COM5', '' for a phone without a COM port }
    Device: TUsbDevice;
    LockError: string;      { why it could not be locked, '' when ok }
    HeldByOther: Boolean;   { another process owns the port }
    Simulated: Boolean;     { no phone: a simulated transport was attached }
  end;

  TCaptureProgress = procedure(Sender: TObject; const AText: string;
    ASecondsLeft: Integer) of object;

  TDeviceCapture = class(TObject)
  private
    FPort: TCommPort;
    FTransport: TCommTransport;
    FLocked: Boolean;
    FDevice: TUsbDevice;
    FHaveDevice: Boolean;
    FCancel: Boolean;
    FGrabbedAt: Int64;
    FNotifier: TDeviceNotifier;
    FNotifyTick: Boolean;
    FOnProgress: TCaptureProgress;
    FSimulated: Boolean;
    procedure NotifierChange(Sender: TObject; AKind: TDevChangeKind;
      const ADescription: string);
    function TryGrab(const APortName: string; const ADev: TUsbDevice;
      out AError: string): Boolean;
    procedure NoteDevice(const ADev: TUsbDevice; APortName: string;
      ASimulated: Boolean);
  public
    constructor Create;
    destructor Destroy; override;

    { Waits up to ATimeoutMs for a phone matching APlatform, then locks its
      port exclusively. When AAllowSimulated is True (self-test / demo) and no
      hardware appears, a simulated transport is attached instead so the rest
      of the pipeline can still be exercised - the outcome is flagged
      Simulated and every log line says so. }
    function WaitForDevice(APlatform: TDevPlatform; ATimeoutMs: Integer;
      AAllowSimulated: Boolean): TGrabbedPort;

    { One non-blocking attempt: scan, grab, done. Used by the capture dialog's
      timer so the UI keeps repainting while we wait. }
    function PollOnce(APlatform: TDevPlatform; out AGrab: TGrabbedPort): Boolean;

    { Gives the device back. Safe to call twice. }
    procedure Release;

    procedure Cancel;
    procedure ResetCancel;

    { The locked transport. Owned by this object - do not free it; Release
      closes it. nil when nothing is locked. }
    function TakeTransport: TCommTransport;

    property Locked: Boolean read FLocked;
    property Device: TUsbDevice read FDevice;
    property HasDevice: Boolean read FHaveDevice;
    property CommPort: TCommPort read FPort;
    property Simulated: Boolean read FSimulated;
    property Cancelled: Boolean read FCancel;
    property OnProgress: TCaptureProgress read FOnProgress write FOnProgress;
  end;

procedure InstallSimTransportFactory(AFactory: TSimTransportFactory);
function SimTransportFactory: TSimTransportFactory;

{ Modes worth waiting for on each platform. }
function ModesForPlatform(AP: TDevPlatform): string;
function AcceptableMode(AP: TDevPlatform; const AMode: string): Boolean;
{ Tells the user how to get the phone into the mode we are waiting for. }
function CaptureHint(AP: TDevPlatform; AForceBrom: Boolean): string;
{ Empty record, built field by field (it contains strings, so FillChar on it
  would leak). }
function EmptyGrabbedPort: TGrabbedPort;

implementation

var
  GSimFactory: TSimTransportFactory = nil;

procedure InstallSimTransportFactory(AFactory: TSimTransportFactory);
begin
  GSimFactory := AFactory;
end;

function SimTransportFactory: TSimTransportFactory;
begin
  Result := GSimFactory;
end;

function EmptyGrabbedPort: TGrabbedPort;
begin
  Result.Found := False;
  Result.PortName := '';
  Result.LockError := '';
  Result.HeldByOther := False;
  Result.Simulated := False;
  Result.Device.VidPid := '';
  Result.Device.Mode := '';
  Result.Device.Name := '';
  Result.Device.Port := '';
end;

function ContainsMode(const AList, AMode: string): Boolean;
begin
  Result := Pos(',' + UpperCase(AMode) + ',', ',' + UpperCase(AList) + ',') > 0;
end;

function ModesForPlatform(AP: TDevPlatform): string;
begin
  case AP of
    dpMtk: Result := 'BROM,PRELOADER,DA,META,MTK';
    dpUnisoc: Result := 'SPD,DIAG';
    dpQualcomm: Result := 'EDL,DIAG';
    dpSamsung: Result := 'DOWNLOAD,ANDROID';
  else
    { Generic accepts anything that looks like a phone. }
    Result := 'BROM,PRELOADER,DA,META,MTK,EDL,DIAG,DOWNLOAD,SPD,FASTBOOT,ANDROID';
  end;
end;

function AcceptableMode(AP: TDevPlatform; const AMode: string): Boolean;
begin
  Result := ContainsMode(ModesForPlatform(AP), AMode);
end;

function CaptureHint(AP: TDevPlatform; AForceBrom: Boolean): string;
begin
  case AP of
    dpMtk:
      if AForceBrom then
        Result := 'Power the phone OFF, hold Volume Up + Volume Down and ' +
          'connect the USB cable to enter BROM.'
      else
        Result := 'Power the phone OFF and connect the USB cable. Do not ' +
          'press any key to stay in Preloader mode.';
    dpUnisoc:
      Result := 'Power the phone OFF, hold Volume Up and connect the USB ' +
        'cable to enter the Spreadtrum download mode.';
    dpQualcomm:
      Result := 'Enter EDL (9008): power off, hold Volume Up + Volume Down ' +
        'and connect USB, or use the test point.';
    dpSamsung:
      Result := 'Power the phone OFF, hold Volume Down (+ Home) and connect ' +
        'USB to enter DOWNLOAD mode.';
  else
    Result := 'Connect the phone in its service mode, or boot it normally ' +
      'for adb / fastboot operations.';
  end;
end;

{ ------------------------------------------------------------- TDeviceCapture }

constructor TDeviceCapture.Create;
begin
  inherited Create;
  FPort := TCommPort.Create;
  FTransport := nil;
  FLocked := False;
  FHaveDevice := False;
  FCancel := False;
  FSimulated := False;
  FNotifyTick := False;
  FGrabbedAt := 0;
  FDevice.VidPid := '';
  FDevice.Mode := '';
  FDevice.Name := '';
  FDevice.Port := '';
  FNotifier := TDeviceNotifier.Create;
  FNotifier.OnChange := NotifierChange;
  FNotifier.Start(0);
end;

destructor TDeviceCapture.Destroy;
begin
  Release;
  FNotifier.Free;
  FPort.Free;
  inherited Destroy;
end;

procedure TDeviceCapture.NotifierChange(Sender: TObject; AKind: TDevChangeKind;
  const ADescription: string);
begin
  { Do the work in the polling loop, not inside the message handler: opening a
    port must not happen while Windows is still delivering the notification.
    The flag only makes the loop run immediately. }
  FNotifyTick := True;
end;

procedure TDeviceCapture.NoteDevice(const ADev: TUsbDevice;
  APortName: string; ASimulated: Boolean);
begin
  FDevice := ADev;
  FHaveDevice := True;
  FSimulated := ASimulated;
  FGrabbedAt := Tick64;
end;

function TDeviceCapture.TryGrab(const APortName: string;
  const ADev: TUsbDevice; out AError: string): Boolean;
begin
  AError := '';
  FPort.SetPort(APortName);
  FPort.Exclusive := True;   { dwShareMode = 0 - this is the lock }
  if FPort.OpenPort(AError) then
  begin
    NoteDevice(ADev, APortName, False);
    FLocked := True;
    FTransport := FPort;
    Result := True;
    Exit;
  end;
  Result := False;
end;

function TDeviceCapture.PollOnce(APlatform: TDevPlatform;
  out AGrab: TGrabbedPort): Boolean;
var
  Devs: TUsbDeviceArray;
  I: Integer;
  Err: string;
begin
  Result := False;
  AGrab := EmptyGrabbedPort;
  if FLocked or (FHaveDevice and not FSimulated) then
  begin
    AGrab.Found := True;
    AGrab.PortName := FDevice.Port;
    AGrab.Device := FDevice;
    AGrab.Simulated := FSimulated;
    Exit(True);
  end;

  Devs := ScanServiceDevices;
  for I := 0 to High(Devs) do
  begin
    if not AcceptableMode(APlatform, Devs[I].Mode) then
      Continue;
    AGrab.Device := Devs[I];
    if Devs[I].Port = '' then
    begin
      { A phone without a COM port (WinUSB interface, fastboot, adb). There is
        no serial handle to take exclusively; remember the device and let the
        platform back end reach it through its own driver path. }
      NoteDevice(Devs[I], '', False);
      FLocked := False;
      FTransport := nil;
      AGrab.Found := True;
      AGrab.PortName := '';
      Exit(True);
    end;
    if TryGrab(Devs[I].Port, Devs[I], Err) then
    begin
      AGrab.Found := True;
      AGrab.PortName := Devs[I].Port;
      Exit(True);
    end;
    AGrab.LockError := Err;
    FPort.SetPort(Devs[I].Port);
    FPort.Exclusive := False;
    AGrab.HeldByOther := FPort.IsHeldBySomeoneElse;
  end;
  Result := False;
end;

function TDeviceCapture.WaitForDevice(APlatform: TDevPlatform;
  ATimeoutMs: Integer; AAllowSimulated: Boolean): TGrabbedPort;
var
  Deadline, NextPoll, NowTick: Int64;
  Grab: TGrabbedPort;
  Left: Integer;
  SimError: string;
begin
  Result := EmptyGrabbedPort;
  if ATimeoutMs <= 0 then
    ATimeoutMs := CDefaultCaptureTimeoutMs;

  { When the caller asked for the simulated device, use it right away. It
    exists so the pipeline can run with no hardware at all (self-test, CI,
    demo), and waiting out the whole timeout for a phone that is not there
    would only make those runs slow. A real job never sets AAllowSimulated, so
    it still waits for hardware and fails honestly when none appears.

    This has to happen BEFORE the deadline is worked out: with the deadline
    already set from the caller's timeout, the loop below polls for hardware
    that is not there for the whole window - three minutes by default - before
    it ever reaches the simulator. }
  if AAllowSimulated and Assigned(GSimFactory) then
    ATimeoutMs := 0;

  NowTick := Tick64;
  Deadline := NowTick + ATimeoutMs;
  NextPoll := 0;
  FNotifier.Enabled := True;

  while True do
  begin
    if FCancel then
    begin
      Result.LockError := 'Cancelled';
      Exit;
    end;
    NowTick := Tick64;
    if NowTick >= Deadline then
    begin
      Result.LockError := 'Timeout';
      Break;
    end;

    if (NowTick >= NextPoll) or FNotifyTick then
    begin
      FNotifyTick := False;
      NextPoll := NowTick + 100;
      if PollOnce(APlatform, Grab) then
        Exit(Grab)
      else
      begin
        Result.LockError := Grab.LockError;
        Result.HeldByOther := Grab.HeldByOther;
      end;
    end;

    Left := Integer((Deadline - NowTick) div 1000);
    if Assigned(FOnProgress) then
      FOnProgress(Self, '', Left);
    Sleep(20);
  end;

  { No hardware appeared. Only the self-test / demo path may continue without
    a phone; a real job has to fail honestly. }
  if AAllowSimulated and Assigned(GSimFactory) then
  begin
    FTransport := GSimFactory;
    if FTransport = nil then
      Exit;
    SimError := '';
    if not FTransport.OpenPort(SimError) then
    begin
      FreeAndNil(FTransport);
      Result.LockError := SimError;
      Exit;
    end;
    FDevice.VidPid := 'VID_0000&PID_0000';
    FDevice.Mode := 'SIMULATED';
    FDevice.Name := 'Simulated device (no phone connected)';
    FDevice.Port := 'SIM';
    NoteDevice(FDevice, 'SIM', True);
    FLocked := True;
    Result := EmptyGrabbedPort;
    Result.Found := True;
    Result.Simulated := True;
    Result.PortName := 'SIM';
    Result.Device := FDevice;
  end;
end;

procedure TDeviceCapture.Release;
begin
  { THE RELEASE. Called from a finally block on every job path, so the phone
    is handed back after success, failure and cancel alike. }
  FLocked := False;
  if (FTransport <> nil) and (FTransport <> FPort) then
    FreeAndNil(FTransport);
  FTransport := nil;
  FPort.ClosePort;
  FSimulated := False;
end;

procedure TDeviceCapture.Cancel;
begin
  FCancel := True;
end;

procedure TDeviceCapture.ResetCancel;
begin
  FCancel := False;
end;

function TDeviceCapture.TakeTransport: TCommTransport;
begin
  Result := FTransport;
end;

end.
