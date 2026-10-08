unit UsbDetect;

{$IFDEF FPC}
  {$MODE DELPHI}
  {$PACKRECORDS C}
{$ENDIF}


{ Detects phones connected in service modes (MediaTek BROM / Preloader / DA,
  Qualcomm EDL, Samsung Download, Unisoc, Fastboot...).
  It only reads the Windows device list through SetupAPI - nothing is ever
  sent to the phone. }

interface

uses
{$IFDEF FPC}
  Windows, SysUtils;
{$ELSE}
  Winapi.Windows,
  System.SysUtils;
{$ENDIF}

type
  TUsbDevice = record
    VidPid: string;  { 'VID_0E8D&PID_2000' }
    Mode: string;    { 'PRELOADER', 'BROM', 'EDL', ... }
    Name: string;    { friendly name from Windows, e.g. 'MediaTek PreLoader USB VCOM (Android) (COM5)' }
    Port: string;    { 'COM5' or '' }
  end;
  TUsbDeviceArray = array of TUsbDevice;

{ Present USB devices that match a known phone / service-mode id. }
function ScanServiceDevices: TUsbDeviceArray;
{ One-line text for the log, e.g. '[PRELOADER] MediaTek PreLoader USB VCOM (COM5)'. }
function DescribeDevice(const D: TUsbDevice): string;
{ Changes whenever the set of detected devices changes. }
function DevicesSignature(const A: TUsbDeviceArray): string;
{ Number of present devices of any kind (used by the self-test to check that
  the SetupAPI calls work on this platform). }
function CountPresentDevices: Integer;

implementation

const
  SetupApiDll = 'setupapi.dll';
  DIGCF_PRESENT = $00000002;
  DIGCF_ALLCLASSES = $00000004;
  SPDRP_DEVICEDESC = $00000000;
  SPDRP_HARDWAREID = $00000001;
  SPDRP_FRIENDLYNAME = $0000000C;

type
  HDEVINFO = NativeUInt;
  TSPDevInfoData = record
    cbSize: DWORD;
    ClassGuid: TGUID;
    DevInst: DWORD;
    Reserved: NativeUInt;
  end;

function SetupDiGetClassDevsW(ClassGuid: PGUID; Enumerator: PWideChar;
  hwndParent: HWND; Flags: DWORD): HDEVINFO; stdcall;
  external SetupApiDll name 'SetupDiGetClassDevsW';
function SetupDiEnumDeviceInfo(DeviceInfoSet: HDEVINFO; MemberIndex: DWORD;
  var DeviceInfoData: TSPDevInfoData): BOOL; stdcall;
  external SetupApiDll name 'SetupDiEnumDeviceInfo';
function SetupDiGetDeviceRegistryPropertyW(DeviceInfoSet: HDEVINFO;
  var DeviceInfoData: TSPDevInfoData; Prop: DWORD; PropertyRegDataType: PDWORD;
  PropertyBuffer: PByte; PropertyBufferSize: DWORD;
  RequiredSize: PDWORD): BOOL; stdcall;
  external SetupApiDll name 'SetupDiGetDeviceRegistryPropertyW';
function SetupDiDestroyDeviceInfoList(DeviceInfoSet: HDEVINFO): BOOL; stdcall;
  external SetupApiDll name 'SetupDiDestroyDeviceInfoList';

type
  TKnownId = record
    Id: string;    { 'VID_xxxx&PID_yyyy', or just 'VID_xxxx' for any product }
    Mode: string;
    Name: string;
  end;

const
  { Most specific entries first. }
  CKnownIds: array[0..15] of TKnownId = (
    (Id: 'VID_0E8D&PID_0003'; Mode: 'BROM';      Name: 'MediaTek USB Port (BROM)'),
    (Id: 'VID_0E8D&PID_2000'; Mode: 'PRELOADER'; Name: 'MediaTek PreLoader USB VCOM'),
    (Id: 'VID_0E8D&PID_2001'; Mode: 'DA';        Name: 'MediaTek DA USB VCOM'),
    (Id: 'VID_0E8D&PID_2006'; Mode: 'META';      Name: 'MediaTek META / Composite'),
    (Id: 'VID_0E8D';          Mode: 'MTK';       Name: 'MediaTek device'),
    (Id: 'VID_05C6&PID_9008'; Mode: 'EDL';       Name: 'Qualcomm HS-USB QDLoader 9008'),
    (Id: 'VID_05C6&PID_900E'; Mode: 'DIAG';      Name: 'Qualcomm HS-USB Diagnostics 900E'),
    (Id: 'VID_04E8&PID_685D'; Mode: 'DOWNLOAD';  Name: 'Samsung Download mode'),
    (Id: 'VID_04E8&PID_6860'; Mode: 'ANDROID';   Name: 'Samsung Android phone'),
    (Id: 'VID_1782&PID_4D00'; Mode: 'SPD';       Name: 'Unisoc / Spreadtrum download port'),
    (Id: 'VID_18D1&PID_D00D'; Mode: 'FASTBOOT';  Name: 'Android Fastboot'),
    (Id: 'VID_18D1';          Mode: 'ANDROID';   Name: 'Android phone (ADB / MTP)'),
    (Id: 'VID_22D9';          Mode: 'ANDROID';   Name: 'Oppo / Realme phone'),
    (Id: 'VID_2717';          Mode: 'ANDROID';   Name: 'Xiaomi phone'),
    (Id: 'VID_2A70';          Mode: 'ANDROID';   Name: 'OnePlus phone'),
    (Id: 'VID_12D1';          Mode: 'ANDROID';   Name: 'Huawei phone'));

function ReadProperty(ASet: HDEVINFO; var AData: TSPDevInfoData;
  AProp: DWORD): string;
var
  Buf: array[0..1023] of WideChar;
  W: UnicodeString;
begin
  Result := '';
  FillChar(Buf, SizeOf(Buf), 0);
  if SetupDiGetDeviceRegistryPropertyW(ASet, AData, AProp, nil, @Buf[0],
    SizeOf(Buf) - SizeOf(WideChar), nil) then
  begin
    { REG_MULTI_SZ values: the first string is the most specific one }
    W := PWideChar(@Buf[0]);
    Result := string(W);
  end;
end;

function ExtractVidPid(const AHardwareId: string): string;
var
  P: Integer;
  U: string;
begin
  Result := '';
  U := UpperCase(AHardwareId);
  P := Pos('VID_', U);
  if P = 0 then
    Exit;
  Result := Copy(U, P, 8);                       { VID_xxxx }
  if Copy(U, P + 8, 5) = '&PID_' then
    Result := Copy(U, P, 17);                    { VID_xxxx&PID_yyyy }
end;

function ExtractPort(const AName: string): string;
var
  P, Q: Integer;
begin
  Result := '';
  P := Pos('(COM', UpperCase(AName));
  if P = 0 then
    Exit;
  Q := P + 1;
  while (Q <= Length(AName)) and (AName[Q] <> ')') do
    Inc(Q);
  Result := Copy(AName, P + 1, Q - P - 1);
end;

function FindKnown(const AVidPid: string; out AKnown: TKnownId): Boolean;
var
  I: Integer;
begin
  for I := Low(CKnownIds) to High(CKnownIds) do
    if (AVidPid = CKnownIds[I].Id) or
       ((Length(CKnownIds[I].Id) = 8) and (Copy(AVidPid, 1, 8) = CKnownIds[I].Id)) then
    begin
      AKnown := CKnownIds[I];
      Result := True;
      Exit;
    end;
  Result := False;
end;

function Score(const D: TUsbDevice): Integer;
begin
  Result := 0;
  if D.Port <> '' then
    Inc(Result, 2);
  if (D.Name <> '') and (Pos('COMPOSITE', UpperCase(D.Name)) = 0) then
    Inc(Result);
end;

function ScanServiceDevices: TUsbDeviceArray;
var
  DevSet: HDEVINFO;
  Data: TSPDevInfoData;
  Index: DWORD;
  Dev: TUsbDevice;
  Known: TKnownId;
  I, Found: Integer;
  Enumerator: UnicodeString;
begin
  SetLength(Result, 0);
  Enumerator := 'USB';
  DevSet := SetupDiGetClassDevsW(nil, PWideChar(Enumerator), 0,
    DIGCF_PRESENT or DIGCF_ALLCLASSES);
  if DevSet = HDEVINFO(INVALID_HANDLE_VALUE) then
    Exit;
  try
    Index := 0;
    FillChar(Data, SizeOf(Data), 0);
    Data.cbSize := SizeOf(Data);
    while SetupDiEnumDeviceInfo(DevSet, Index, Data) do
    begin
      Inc(Index);
      Dev.VidPid := ExtractVidPid(ReadProperty(DevSet, Data, SPDRP_HARDWAREID));
      if (Dev.VidPid <> '') and FindKnown(Dev.VidPid, Known) then
      begin
        Dev.Mode := Known.Mode;
        Dev.Name := ReadProperty(DevSet, Data, SPDRP_FRIENDLYNAME);
        if Dev.Name = '' then
          Dev.Name := ReadProperty(DevSet, Data, SPDRP_DEVICEDESC);
        if Dev.Name = '' then
          Dev.Name := Known.Name;
        Dev.Port := ExtractPort(Dev.Name);

        { Composite devices show up several times (parent + interfaces):
          keep one entry per VID/PID, preferring the one with a COM port. }
        Found := -1;
        for I := 0 to High(Result) do
          if Result[I].VidPid = Dev.VidPid then
          begin
            Found := I;
            Break;
          end;
        if Found < 0 then
        begin
          SetLength(Result, Length(Result) + 1);
          Result[High(Result)] := Dev;
        end
        else if Score(Dev) > Score(Result[Found]) then
          Result[Found] := Dev;
      end;
      FillChar(Data, SizeOf(Data), 0);
      Data.cbSize := SizeOf(Data);
    end;
  finally
    SetupDiDestroyDeviceInfoList(DevSet);
  end;
end;

function DescribeDevice(const D: TUsbDevice): string;
begin
  Result := '[' + D.Mode + '] ' + D.Name;
  if (D.Port <> '') and (Pos(D.Port, D.Name) = 0) then
    Result := Result + ' (' + D.Port + ')';
end;

function DevicesSignature(const A: TUsbDeviceArray): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(A) do
    Result := Result + A[I].VidPid + '|' + A[I].Port + ';';
end;

function CountPresentDevices: Integer;
var
  DevSet: HDEVINFO;
  Data: TSPDevInfoData;
begin
  Result := 0;
  DevSet := SetupDiGetClassDevsW(nil, nil, 0, DIGCF_PRESENT or DIGCF_ALLCLASSES);
  if DevSet = HDEVINFO(INVALID_HANDLE_VALUE) then
    Exit;
  try
    FillChar(Data, SizeOf(Data), 0);
    Data.cbSize := SizeOf(Data);
    while SetupDiEnumDeviceInfo(DevSet, DWORD(Result), Data) do
      Inc(Result);
  finally
    SetupDiDestroyDeviceInfoList(DevSet);
  end;
end;

end.
