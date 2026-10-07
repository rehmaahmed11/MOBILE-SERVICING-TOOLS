unit DeviceWatch;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


{ Detects the USB devices a phone presents while it is being serviced.

  It answers "is something plugged in, and what is it?" - MediaTek BROM /
  preloader / META ports, Qualcomm EDL (9008), Unisoc, Samsung download mode,
  ADB and fastboot - together with the COM port Windows gave them.

  Only devices that are present *now* are reported (SetupAPI is called with
  DIGCF_PRESENT), so a phone that was plugged in yesterday and never removed
  cleanly is not mistaken for a live connection. No data is ever sent to the
  device: this is pure enumeration, which makes it safe to run at all times.

  MAIN 1 and MAIN 2 both use one watcher; the phone icon turns green and the
  log records the arrival and removal of each device.

  Compiles unchanged under Delphi (RAD Studio) and Lazarus / Free Pascal. }

interface

uses
{$IFDEF FPC}
  Windows, Classes, SysUtils, ExtCtrls;
{$ELSE}
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  Vcl.ExtCtrls;
{$ENDIF}

type
  TDeviceKind = (dkNone, dkMtkBrom, dkMtkPreloader, dkMtkMeta, dkQualcommEdl,
    dkQualcommOther, dkUnisoc, dkSamsungDownload, dkAdb, dkFastboot, dkOther);

  TDetectedDevice = record
    Kind: TDeviceKind;
    KindText: string;
    Vid: Integer;
    Pid: Integer;
    InstanceId: string;
    Serial: string;
    Description: string;
    PortName: string;
    function Caption: string;
    function IdText: string;
  end;

  TDeviceArray = array of TDetectedDevice;

  TDeviceChangeEvent = procedure(Sender: TObject;
    const ADevice: TDetectedDevice; const AArrived: Boolean) of object;

  TDeviceWatcher = class
  private
    FTimer: TTimer;
    FDevices: TDeviceArray;
    FSignature: string;
    FInterval: Integer;
    FActive: Boolean;
    FOnDevicesChange: TNotifyEvent;
    FOnDeviceChange: TDeviceChangeEvent;
    procedure Poll(Sender: TObject);
    procedure ApplyScan;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    procedure Refresh;
    function Count: Integer;
    function Device(const AIndex: Integer): TDetectedDevice;
    function Connected: Boolean;
    function Summary: string;
    { Short text for a menu line or status bar. }
    function StatusLine: string;
    property Interval: Integer read FInterval write FInterval;
    property Active: Boolean read FActive;
    property OnDevicesChange: TNotifyEvent read FOnDevicesChange
      write FOnDevicesChange;
    property OnDeviceChange: TDeviceChangeEvent read FOnDeviceChange
      write FOnDeviceChange;
  end;

{ One-shot scan, handy for tests or a manual "refresh". }
function ScanUsbDevices: TDeviceArray;

function DeviceKindText(const AKind: TDeviceKind): string;

implementation

const
  { SetupAPI }
  DIGCF_PRESENT = $00000002;
  DIGCF_ALLCLASSES = $00000004;
  SPDRP_DEVICEDESC = $00000000;
  SPDRP_HARDWAREID = $00000001;
  SPDRP_FRIENDLYNAME = $0000000C;

  CDefaultInterval = 1500;

  { Vendors whose USB devices are interesting for phone servicing. Anything
    else on the bus (mouse, keyboard, printer, ...) is ignored. }
  CVendorIds: array[0..23] of Integer = (
    $0E8D,  { MediaTek }
    $05C6,  { Qualcomm }
    $1782,  { Unisoc / Spreadtrum }
    $04E8,  { Samsung }
    $18D1,  { Google / Android reference }
    $2717,  { Xiaomi }
    $22D9,  { Oppo / Realme }
    $2A70,  { OnePlus }
    $2A45,  { Meizu }
    $2D4E,  { Vivo }
    $12D1,  { Huawei }
    $0BB4,  { HTC }
    $17EF,  { Lenovo }
    $1004,  { LG }
    $0421,  { Nokia }
    $2E04,  { HMD (Nokia) }
    $19D2,  { ZTE }
    $0B05,  { Asus }
    $2207,  { Rockchip }
    $1F3A,  { Allwinner }
    $0525,  { Linux-USB gadget (maskrom / serial) }
    $0489,  { Foxconn }
    $2345,  { Tecno / Infinix variants }
    $1BBB); { Alcatel / TCT }

type
  HDEVINFO = Pointer;

  TSpDevInfoData = record
    cbSize: DWORD;
    ClassGuid: TGUID;
    DevInst: DWORD;
    Reserved: ULONG_PTR;
  end;

function SetupDiGetClassDevsW(ClassGuid: PGUID; AEnumerator: PWideChar;
  hwndParent: HWND; Flags: DWORD): HDEVINFO; stdcall;
  external 'setupapi.dll' name 'SetupDiGetClassDevsW';
function SetupDiEnumDeviceInfo(DeviceInfoSet: HDEVINFO;
  const MemberIndex: DWORD; var DeviceInfoData: TSpDevInfoData): BOOL; stdcall;
  external 'setupapi.dll' name 'SetupDiEnumDeviceInfo';
function SetupDiGetDeviceRegistryPropertyW(DeviceInfoSet: HDEVINFO;
  var DeviceInfoData: TSpDevInfoData; const AProperty: DWORD;
  var PropertyRegDataType: DWORD; PropertyBuffer: Pointer;
  const PropertyBufferSize: DWORD; var RequiredSize: DWORD): BOOL; stdcall;
  external 'setupapi.dll' name 'SetupDiGetDeviceRegistryPropertyW';
function SetupDiGetDeviceInstanceIdW(DeviceInfoSet: HDEVINFO;
  var DeviceInfoData: TSpDevInfoData; DeviceInstanceId: PWideChar;
  const DeviceInstanceIdSize: DWORD; var RequiredSize: DWORD): BOOL; stdcall;
  external 'setupapi.dll' name 'SetupDiGetDeviceInstanceIdW';
function SetupDiDestroyDeviceInfoList(DeviceInfoSet: HDEVINFO): BOOL; stdcall;
  external 'setupapi.dll' name 'SetupDiDestroyDeviceInfoList';

{ ------------------------------------------------------------ helpers }

function WideToAppString(const ABuf: PWideChar): string;
var
  US: UnicodeString;
begin
  US := ABuf;
  Result := string(US);
end;

function ReadProperty(ADevInfo: HDEVINFO; var AData: TSpDevInfoData;
  const AProperty: DWORD): string;
var
  Buf: array[0..1023] of WideChar;
  RegType, Required: DWORD;
begin
  Result := '';
  FillChar(Buf, SizeOf(Buf), 0);
  RegType := 0;
  Required := 0;
  if SetupDiGetDeviceRegistryPropertyW(ADevInfo, AData, AProperty, RegType,
    @Buf[0], DWORD(SizeOf(Buf)), Required) then
    Result := WideToAppString(@Buf[0]);
end;

function ReadInstanceId(ADevInfo: HDEVINFO;
  var AData: TSpDevInfoData): string;
var
  Buf: array[0..255] of WideChar;
  Required: DWORD;
begin
  Result := '';
  FillChar(Buf, SizeOf(Buf), 0);
  Required := 0;
  if SetupDiGetDeviceInstanceIdW(ADevInfo, AData, @Buf[0], DWORD(SizeOf(Buf)),
    Required) then
    Result := WideToAppString(@Buf[0]);
end;

function HexNibble(const S: string; const AIndex: Integer;
  out AValue: Integer): Boolean;
begin
  Result := True;
  case S[AIndex] of
    '0'..'9': AValue := Ord(S[AIndex]) - Ord('0');
    'A'..'F': AValue := Ord(S[AIndex]) - Ord('A') + 10;
    'a'..'f': AValue := Ord(S[AIndex]) - Ord('a') + 10;
  else
    AValue := 0;
    Result := False;
  end;
end;

function Hex4(const S: string; const APos: Integer): Integer;
var
  I, Digit: Integer;
begin
  Result := -1;
  if (APos < 1) or (APos + 3 > Length(S)) then
    Exit;
  Result := 0;
  for I := 0 to 3 do
  begin
    if not HexNibble(S, APos + I, Digit) then
    begin
      Result := -1;
      Exit;
    end;
    Result := Result * 16 + Digit;
  end;
end;

function ParseVidPid(const AHardwareId: string; out AVid,
  APid: Integer): Boolean;
var
  S: string;
begin
  AVid := -1;
  APid := -1;
  Result := False;
  S := UpperCase(AHardwareId);
  AVid := Hex4(S, Pos('VID_', S) + 4);
  if Pos('VID_', S) = 0 then
    AVid := -1;
  APid := Hex4(S, Pos('PID_', S) + 4);
  if Pos('PID_', S) = 0 then
    APid := -1;
  Result := (AVid >= 0) and (APid >= 0);
end;

function KnownVendor(const AVid: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := Low(CVendorIds) to High(CVendorIds) do
    if CVendorIds[I] = AVid then
      Exit(True);
end;

function ContainsAny(const AText: string;
  const AWords: array of string): Boolean;
var
  I: Integer;
  S: string;
begin
  Result := False;
  S := UpperCase(AText);
  if S = '' then
    Exit;
  for I := 0 to Length(AWords) - 1 do
    if Pos(UpperCase(AWords[I]), S) > 0 then
      Exit(True);
end;

{ "USB\VID_0E8D&PID_0003\ABC123" -> "ABC123" }
function InstanceSerial(const AInstanceId: string): string;
var
  P: Integer;
begin
  P := LastDelimiter('\', AInstanceId);
  if (P > 0) and (P < Length(AInstanceId)) then
    Result := Copy(AInstanceId, P + 1, Length(AInstanceId))
  else
    Result := '';
end;

function ExtractComPort(const AText: string): string;
var
  S: string;
  P, I: Integer;
begin
  Result := '';
  S := UpperCase(AText);
  P := Pos('(COM', S);
  if P = 0 then
    P := Pos('COM', S);
  if P = 0 then
    Exit;
  if S[P] = '(' then
    Inc(P);
  Result := 'COM';
  I := P + 3;
  while (I <= Length(S)) and (S[I] >= '0') and (S[I] <= '9') do
  begin
    Result := Result + S[I];
    Inc(I);
  end;
  if Length(Result) <= 3 then
    Result := '';
end;

{ Clean Windows strings of the form "@oem12.inf,%dev%;MediaTek USB Port". }
function CleanDescription(const AText: string): string;
var
  P: Integer;
begin
  Result := Trim(AText);
  if (Result <> '') and (Result[1] = '@') then
  begin
    P := Pos(';', Result);
    if P > 0 then
      Result := Trim(Copy(Result, P + 1, Length(Result)))
    else
      Result := '';
  end;
end;

function DeviceKindText(const AKind: TDeviceKind): string;
begin
  case AKind of
    dkMtkBrom: Result := 'MediaTek BROM (download mode)';
    dkMtkPreloader: Result := 'MediaTek Preloader (VCOM)';
    dkMtkMeta: Result := 'MediaTek META / DA port';
    dkQualcommEdl: Result := 'Qualcomm EDL 9008';
    dkQualcommOther: Result := 'Qualcomm USB device';
    dkUnisoc: Result := 'Unisoc / Spreadtrum device';
    dkSamsungDownload: Result := 'Samsung download mode (Odin)';
    dkAdb: Result := 'Android ADB interface';
    dkFastboot: Result := 'Android fastboot';
    dkOther: Result := 'USB device';
  else
    Result := 'Unknown device';
  end;
end;

function ClassifyDevice(const AVid, APid: Integer; const AText: string): TDeviceKind;
begin
  Result := dkOther;

  { exact VID/PID first }
  if (AVid = $0E8D) and (APid = $0003) then
    Exit(dkMtkBrom);
  if (AVid = $0E8D) and (APid = $2000) then
    Exit(dkMtkPreloader);
  if (AVid = $0E8D) and ((APid = $2001) or (APid = $2004)) then
    Exit(dkMtkMeta);
  if (AVid = $05C6) and (APid = $9008) then
    Exit(dkQualcommEdl);
  if (AVid = $05C6) then
    Exit(dkQualcommOther);
  if (AVid = $1782) then
    Exit(dkUnisoc);
  if (AVid = $04E8) and ((APid = $685D) or (APid = $685E)) then
    Exit(dkSamsungDownload);
  if (AVid = $18D1) and (APid = $D00D) then
    Exit(dkFastboot);
  if (AVid = $18D1) and ((APid = $4EE7) or (APid = $4EE2) or (APid = $4E42) or
     (APid = $4EE0) or (APid = $2EE2)) then
    Exit(dkAdb);

  { fall back to what Windows calls the device }
  if ContainsAny(AText, ['QDLOADER', 'EDL', '9008']) then
    Exit(dkQualcommEdl);
  if ContainsAny(AText, ['BROM']) then
    Exit(dkMtkBrom);
  if ContainsAny(AText, ['PRELOADER']) then
    Exit(dkMtkPreloader);
  if ContainsAny(AText, ['ODIN', 'DOWNLOAD MODE']) then
    Exit(dkSamsungDownload);
  if ContainsAny(AText, ['FASTBOOT', 'BOOTLOADER']) then
    Exit(dkFastboot);
  if ContainsAny(AText, ['ADB', 'ANDROID COMPOSITE', 'ANDROID PHONE']) then
    Exit(dkAdb);
  if ContainsAny(AText, ['SPRD', 'SPREADTRUM', 'UNISOC']) then
    Exit(dkUnisoc);
  if ContainsAny(AText, ['MEDIATEK', 'MT65', 'MT67', 'MT68', 'MT81', 'MTK']) then
    Exit(dkMtkMeta);
end;

function IsInteresting(const AVid: Integer; const AText: string): Boolean;
begin
  Result := KnownVendor(AVid) or
    ContainsAny(AText, ['PRELOADER', 'BROM', 'QDLOADER', 'EDL', 'ODIN',
      'FASTBOOT', 'ADB', 'MEDIATEK', 'SPRD', 'SPREADTRUM', 'UNISOC',
      'USB VCOM', 'MOBILE USB PORT', 'DIAG']);
end;

{ ------------------------------------------------------------ scanning }

function ScanUsbDevices: TDeviceArray;
var
  DevInfo: HDEVINFO;
  Data: TSpDevInfoData;
  EnumFilter: UnicodeString;
  Index: DWORD;
  HardwareId, Friendly, Description, InstanceId, DevText, Serial: string;
  Vid, Pid: Integer;
  Dev: TDetectedDevice;
  N: Integer;
begin
  SetLength(Result, 0);
  N := 0;
  EnumFilter := 'USB';
  DevInfo := SetupDiGetClassDevsW(nil, PWideChar(EnumFilter), 0,
    DIGCF_PRESENT or DIGCF_ALLCLASSES);
  { HDEVINFO is a pointer: INVALID_HANDLE_VALUE must be cast before comparing. }
  if (DevInfo = nil) or (DevInfo = Pointer(INVALID_HANDLE_VALUE)) then
    Exit;
  try
    Index := 0;
    while Index < 4096 do
    begin
      FillChar(Data, SizeOf(Data), 0);
      Data.cbSize := SizeOf(Data);
      if not SetupDiEnumDeviceInfo(DevInfo, Index, Data) then
        Break;
      Inc(Index);

      HardwareId := ReadProperty(DevInfo, Data, SPDRP_HARDWAREID);
      if not ParseVidPid(HardwareId, Vid, Pid) then
        Continue;

      Friendly := CleanDescription(ReadProperty(DevInfo, Data, SPDRP_FRIENDLYNAME));
      Description := CleanDescription(ReadProperty(DevInfo, Data, SPDRP_DEVICEDESC));
      if Friendly <> '' then
        DevText := Friendly
      else
        DevText := Description;

      if not IsInteresting(Vid, DevText) then
        Continue;

      InstanceId := ReadInstanceId(DevInfo, Data);
      Serial := InstanceSerial(InstanceId);

      Dev.Kind := ClassifyDevice(Vid, Pid, DevText + ' ' + Description);
      Dev.KindText := DeviceKindText(Dev.Kind);
      Dev.Vid := Vid;
      Dev.Pid := Pid;
      Dev.InstanceId := InstanceId;
      Dev.Serial := Serial;
      Dev.Description := DevText;
      Dev.PortName := ExtractComPort(Friendly);

      if N = Length(Result) then
        SetLength(Result, Length(Result) + 8);
      Result[N] := Dev;
      Inc(N);
    end;
  finally
    SetupDiDestroyDeviceInfoList(DevInfo);
  end;
  SetLength(Result, N);
end;

{ ------------------------------------------------------------ record }

function TDetectedDevice.IdText: string;
begin
  Result := IntToHex(Vid, 4) + ':' + IntToHex(Pid, 4);
  if Serial <> '' then
    Result := Result + ' [' + Serial + ']';
end;

function TDetectedDevice.Caption: string;
begin
  { A phone in its normal (MTP/ADB-off) mode is still worth showing, but the
    name Windows gives it says more than "USB device". }
  if (Kind = dkOther) and (Description <> '') then
    Result := Description
  else
    Result := KindText;
  Result := Result + ' (' + IntToHex(Vid, 4) + ':' + IntToHex(Pid, 4) + ')';
  if PortName <> '' then
    Result := Result + ' on ' + PortName;
end;

{ ------------------------------------------------------------ watcher }

constructor TDeviceWatcher.Create;
begin
  inherited Create;
  FInterval := CDefaultInterval;
  FActive := False;
  FSignature := '';
  SetLength(FDevices, 0);
  FTimer := TTimer.Create(nil);
  FTimer.Enabled := False;
  FTimer.Interval := FInterval;
  FTimer.OnTimer := Poll;
end;

destructor TDeviceWatcher.Destroy;
begin
  Stop;
  FreeAndNil(FTimer);
  inherited Destroy;
end;

procedure TDeviceWatcher.Start;
begin
  FActive := True;
  if FInterval < 250 then
    FInterval := 250;
  FTimer.Interval := FInterval;
  FTimer.Enabled := True;
  ApplyScan;          { show what is already plugged in straight away }
end;

procedure TDeviceWatcher.Stop;
begin
  FActive := False;
  FTimer.Enabled := False;
end;

procedure TDeviceWatcher.Refresh;
begin
  ApplyScan;
end;

procedure TDeviceWatcher.Poll(Sender: TObject);
begin
  ApplyScan;
end;

procedure TDeviceWatcher.ApplyScan;
var
  Found: TDeviceArray;
  Signature: string;
  I, J: Integer;
  Matched: Boolean;
  Dev: TDetectedDevice;
begin
  Found := ScanUsbDevices;

  Signature := '';
  for I := 0 to Length(Found) - 1 do
    Signature := Signature + '|' + Found[I].InstanceId + '#' +
      IntToHex(Found[I].Vid, 4) + ':' + IntToHex(Found[I].Pid, 4) + '#' +
      Found[I].PortName;

  if Signature = FSignature then
    Exit;
  FSignature := Signature;

  { report arrivals and removals }
  for I := 0 to Length(Found) - 1 do
  begin
    Matched := False;
    for J := 0 to Length(FDevices) - 1 do
      if (FDevices[J].InstanceId = Found[I].InstanceId) and
         (FDevices[J].Pid = Found[I].Pid) then
      begin
        Matched := True;
        Break;
      end;
    if (not Matched) and Assigned(FOnDeviceChange) then
      FOnDeviceChange(Self, Found[I], True);
  end;

  for I := 0 to Length(FDevices) - 1 do
  begin
    Matched := False;
    for J := 0 to Length(Found) - 1 do
      if (Found[J].InstanceId = FDevices[I].InstanceId) and
         (Found[J].Pid = FDevices[I].Pid) then
      begin
        Matched := True;
        Break;
      end;
    if (not Matched) and Assigned(FOnDeviceChange) then
    begin
      Dev := FDevices[I];
      FOnDeviceChange(Self, Dev, False);
    end;
  end;

  FDevices := Found;

  if Assigned(FOnDevicesChange) then
    FOnDevicesChange(Self);
end;

function TDeviceWatcher.Count: Integer;
begin
  Result := Length(FDevices);
end;

function TDeviceWatcher.Device(const AIndex: Integer): TDetectedDevice;
begin
  if (AIndex >= 0) and (AIndex < Length(FDevices)) then
    Result := FDevices[AIndex]
  else
  begin
    Result.Kind := dkNone;
    Result.KindText := '';
    Result.Vid := 0;
    Result.Pid := 0;
    Result.InstanceId := '';
    Result.Serial := '';
    Result.Description := '';
    Result.PortName := '';
  end;
end;

function TDeviceWatcher.Connected: Boolean;
begin
  Result := Length(FDevices) > 0;
end;

function TDeviceWatcher.Summary: string;
begin
  if Length(FDevices) = 0 then
    Result := 'No device connected'
  else
  begin
    Result := FDevices[0].Caption;
    if Length(FDevices) > 1 then
      Result := Result + '  (+' + IntToStr(Length(FDevices) - 1) + ' more)';
  end;
end;

function TDeviceWatcher.StatusLine: string;
begin
  if Length(FDevices) = 0 then
    Result := 'Device: none detected'
  else if Length(FDevices) = 1 then
    Result := 'Device: ' + FDevices[0].Caption
  else
    Result := 'Device: ' + FDevices[0].Caption + '  (+' +
      IntToStr(Length(FDevices) - 1) + ' more)';
end;

end.
