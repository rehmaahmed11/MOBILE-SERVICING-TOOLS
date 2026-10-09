unit UsbRaw;

{$IFDEF FPC}
  {$MODE DELPHI}
  {$PACKRECORDS C}
{$ENDIF}

{ Raw USB transport for MediaTek service-mode phones - the mtkclient way.

  The VCOM path (TCommPort) needs Windows to expose the phone as a COM port,
  which needs the vendor USB-serial driver. bkerler/mtkclient does not use a
  serial driver at all: it finds the phone as a raw USB device, claims its
  interface with libusb and speaks the BootROM protocol over bulk endpoints.
  This unit is that path, wired into the same TCommTransport abstraction, so
  the whole existing stack - the $A0 $0A $50 $05 handshake (BromProtocol),
  the download-agent upload and the legacy DA read/flash commands
  (MtkDaLegacy) - runs unchanged over USB bulk instead of a COM port.

  The flow, mirroring mtkclient's Library/Connection/usblib.py connect():

    DETECT   enumerate the USB device list and match the MediaTek service
             VID/PID (VID_0E8D, PIDs $0003 BROM / $2000 Preloader /
             $2001 DA / $2006 META - the same table UsbDetect matches).
    BIND     libusb_open the device, make sure it is configured, detach the
             kernel driver when one is attached (best effort), then
             libusb_claim_interface. The claim IS the exclusive lock: while
             we hold it, no other program can open the interface, exactly
             like dwShareMode = 0 does for a COM port.
    ENDPOINTS  walk the raw configuration descriptor and take the first
             bulk OUT / bulk IN pair, preferring a vendor-specific ($FF) or
             CDC ($02) interface, the way mtkclient picks its endpoints.
    TALK     libusb_bulk_transfer with a timeout, in both directions.

  The libusb DLL is the one bundled in the support tree
  (libusb\<arch>\libusb0.dll - the libusb-win32 package, which also exports
  the libusb 1.0 API this unit binds to). It is loaded dynamically, with
  the architecture-specific name picked at compile time, so a Win32 build
  loads libusb\x86\libusb0_x86.dll and a Win64 build loads
  libusb\amd64\libusb0.dll. Nothing is linked at build time and nothing is
  sent to any device unless a claim succeeded.

  Error honesty: when the DLL is missing, the device is gone, the interface
  is claimed by another program, or Windows denies access, OpenPort fails
  with the specific reason and the caller keeps the "detected but not
  locked" behaviour - detection alone is never reported as a lock. }

interface

uses
{$IFDEF FPC}
  Windows, SysUtils,
{$ELSE}
  Winapi.Windows,
  System.SysUtils,
{$ENDIF}
  DevTypes, CommPort;

type
  { libusb_device_descriptor, 18 bytes, no pointer fields - the layout is
    fixed by the USB spec and safe to declare on both compilers. }
  TLibusbDeviceDescriptor = record
    bLength: Byte;
    bDescriptorType: Byte;
    bcdUSB: Word;
    bDeviceClass: Byte;
    bDeviceSubClass: Byte;
    bDeviceProtocol: Byte;
    bMaxPacketSize0: Byte;
    idVendor: Word;
    idProduct: Word;
    bcdDevice: Word;
    iManufacturer: Byte;
    iProduct: Byte;
    iSerialNumber: Byte;
    bNumConfigurations: Byte;
  end;

  { libusb 1.0 entry points (LIBUSB_CALL = stdcall on Windows). Resolved
    from the DLL at run time; the optional ones may stay nil. }
  TLibusbInitFn = function(out AContext: Pointer): Integer; stdcall;
  TLibusbExitFn = procedure(AContext: Pointer); stdcall;
  TLibusbGetDeviceListFn = function(AContext: Pointer;
    out AList: Pointer): NativeInt; stdcall;
  TLibusbFreeDeviceListFn = procedure(AList: Pointer;
    AUnrefDevices: Integer); stdcall;
  TLibusbGetDeviceDescriptorFn = function(ADevice: Pointer;
    out ADesc: TLibusbDeviceDescriptor): Integer; stdcall;
  TLibusbGetDescriptorFn = function(ADevice: Pointer; ADescType,
    ADescIndex: Byte; AData: PByte; ALength: Integer): Integer; stdcall;
  TLibusbOpenFn = function(ADevice: Pointer; out AHandle: Pointer): Integer;
    stdcall;
  TLibusbCloseFn = procedure(AHandle: Pointer); stdcall;
  TLibusbClaimInterfaceFn = function(AHandle: Pointer;
    AInterface: Integer): Integer; stdcall;
  TLibusbReleaseInterfaceFn = function(AHandle: Pointer;
    AInterface: Integer): Integer; stdcall;
  TLibusbBulkTransferFn = function(AHandle: Pointer; AEndpoint: Byte;
    AData: PByte; ALength: Integer; out ATransferred: Integer;
    ATimeout: Cardinal): Integer; stdcall;
  TLibusbGetConfigurationFn = function(AHandle: Pointer;
    out AConfig: Integer): Integer; stdcall;
  TLibusbSetConfigurationFn = function(AHandle: Pointer;
    AConfig: Integer): Integer; stdcall;
  TLibusbDetachKernelDriverFn = function(AHandle: Pointer;
    AInterface: Integer): Integer; stdcall;
  TLibusbSetAutoDetachFn = function(AHandle: Pointer;
    AEnable: Integer): Integer; stdcall;

  PPPointer = ^Pointer;

  { A raw USB bulk pipe to one MediaTek service-mode device, held by an
    exclusive interface claim. Drop-in TCommTransport: the protocols above
    this unit cannot tell it apart from a COM port. }
  TUsbTransport = class(TCommTransport)
  private
    FDll: THandle;
    FContext: Pointer;
    FDevice: Pointer;
    FDeviceHandle: Pointer;
    FClaimed: Boolean;
    FInterface: Integer;
    FEpIn: Byte;
    FEpOut: Byte;
    FVid: Word;
    FPid: Word;
    FPortName: string;
    FSetError: string;
    FTimeoutMs: Integer;
    FBytesIn: Int64;
    FBytesOut: Int64;
    FLastError: string;
    FInit: TLibusbInitFn;
    FExit: TLibusbExitFn;
    FGetDeviceList: TLibusbGetDeviceListFn;
    FFreeDeviceList: TLibusbFreeDeviceListFn;
    FGetDeviceDescriptor: TLibusbGetDeviceDescriptorFn;
    FGetDescriptor: TLibusbGetDescriptorFn;
    FOpen: TLibusbOpenFn;
    FClose: TLibusbCloseFn;
    FClaimInterface: TLibusbClaimInterfaceFn;
    FReleaseInterface: TLibusbReleaseInterfaceFn;
    FBulkTransfer: TLibusbBulkTransferFn;
    FGetConfiguration: TLibusbGetConfigurationFn;
    FSetConfiguration: TLibusbSetConfigurationFn;
    FDetachKernelDriver: TLibusbDetachKernelDriverFn;
    FSetAutoDetach: TLibusbSetAutoDetachFn;
    function LoadApi(out AError: string): Boolean;
    function FindAndOpenDevice(out AError: string): Boolean;
    function EnsureConfigured(out AError: string): Boolean;
    function DiscoverEndpoints(out AError: string): Boolean;
    function ClaimInterface(out AError: string): Boolean;
    procedure ReleaseAll;
    function ErrorText(AError: Integer): string;
  public
    constructor Create;
    destructor Destroy; override;

    { 'VID_0E8D&PID_0003' - the same string UsbDetect reports. Must be one of
      the MediaTek service ids (IsMtkServiceVidPid). }
    procedure SetVidPid(const AVidPid: string);
    procedure SetTimeout(ATimeoutMs: Integer);

    { DETECT + BIND. Succeeds only when the interface claim succeeded - that
      claim is the exclusive lock. }
    function OpenPort(out AError: string): Boolean; override;
    procedure ClosePort; override;
    function PortOpen: Boolean; override;
    function WriteData(const AData; ACount: Integer): Integer; override;
    function ReadData(var ABuffer; ACount, ATimeoutMs: Integer): Integer;
      override;
    function PortName: string; override;

    property Vid: Word read FVid;
    property Pid: Word read FPid;
    property InterfaceNumber: Integer read FInterface;
    property LastError: string read FLastError;
    property BytesIn: Int64 read FBytesIn;
    property BytesOut: Int64 read FBytesOut;
  end;

{ Parses 'VID_0E8D&PID_0003' into numbers. False when malformed. }
function ParseVidPid(const AVidPid: string; out AVid, APid: Word): Boolean;
{ True for the MediaTek service-mode ids this build can drive over raw USB
  (mirrors the VID_0E8D entries of UsbDetect's known-id table and the VID/PID
  list mtkclient's usblib connects to). }
function IsMtkServiceVidPid(AVid, APid: Word): Boolean;
{ 'BROM', 'PRELOADER', 'DA', 'META' or 'MTK' for a known MediaTek pid. }
function MtkModeLabel(APid: Word): string;
{ Full path of the bundled libusb DLL for this CPU, or '' when none of the
  candidate locations has it (the caller then tries the system search path). }
function FindLibUsbDll: string;

implementation

const
  { MediaTek USB ids. VID $0E8D is MediaTek; $0003 is the "MTK USB Port"
    the BootROM and the preloader expose, $2000/$2001 the preloader and
    download-agent VCOM parents, $2006 the META composite. }
  CMtkVid = $0E8D;

  { libusb error codes (libusb 1.0). }
  CLibUsbErrorIo = -1;
  CLibUsbErrorAccess = -3;
  CLibUsbErrorNoDevice = -4;
  CLibUsbErrorNotFound = -5;
  CLibUsbErrorBusy = -6;
  CLibUsbErrorTimeout = -7;
  CLibUsbErrorOverflow = -8;
  CLibUsbErrorOther = -99;

  { USB descriptor types and endpoint fields. }
  CDtConfig = $02;
  CDtInterface = $04;
  CDtEndpoint = $05;
  CTransferTypeBulk = $02;
  CEpDirIn = $80;
  CIfClassCdc = $02;
  CIfClassVendor = $FF;

  { How far up from the EXE the support tree may sit (installed bundle:
    beside the EXE; development checkout: data\support\MOBILO TOOLZ). }
  CMaxUpLevels = 12;

{ ------------------------------------------------------------- small helpers }

function LibUsbErrorName(AError: Integer): string;
begin
  case AError of
    CLibUsbErrorIo: Result := 'LIBUSB_ERROR_IO';
    -2: Result := 'LIBUSB_ERROR_INVALID_PARAM';
    CLibUsbErrorAccess: Result := 'LIBUSB_ERROR_ACCESS';
    CLibUsbErrorNoDevice: Result := 'LIBUSB_ERROR_NO_DEVICE';
    CLibUsbErrorNotFound: Result := 'LIBUSB_ERROR_NOT_FOUND';
    CLibUsbErrorBusy: Result := 'LIBUSB_ERROR_BUSY';
    CLibUsbErrorTimeout: Result := 'LIBUSB_ERROR_TIMEOUT';
    CLibUsbErrorOverflow: Result := 'LIBUSB_ERROR_OVERFLOW';
    -9: Result := 'LIBUSB_ERROR_PIPE';
    -10: Result := 'LIBUSB_ERROR_INTERRUPTED';
    -11: Result := 'LIBUSB_ERROR_NO_MEM';
    -12: Result := 'LIBUSB_ERROR_NOT_SUPPORTED';
    CLibUsbErrorOther: Result := 'LIBUSB_ERROR_OTHER';
  else
    Result := 'libusb error ' + IntToStr(AError);
  end;
end;

function IsHex4(const S: string): Boolean;
var
  I: Integer;
begin
  Result := Length(S) = 4;
  if not Result then
    Exit;
  for I := 1 to 4 do
    if not CharInSet(S[I], ['0'..'9', 'A'..'F']) then
      Exit(False);
end;

function ParseVidPid(const AVidPid: string; out AVid, APid: Word): Boolean;
var
  S, V, P: string;
  PidPos: Integer;
begin
  Result := False;
  AVid := 0;
  APid := 0;
  S := UpperCase(Trim(AVidPid));
  if Pos('VID_', S) = 0 then
    Exit;
  PidPos := Pos('&PID_', S);
  if PidPos = 0 then
    Exit;
  V := Copy(S, Pos('VID_', S) + 4, 4);
  P := Copy(S, PidPos + 5, 4);
  if not IsHex4(V) or not IsHex4(P) then
    Exit;
  AVid := Word(StrToInt('$' + V));
  APid := Word(StrToInt('$' + P));
  Result := True;
end;

function IsMtkServiceVidPid(AVid, APid: Word): Boolean;
begin
  Result := (AVid = CMtkVid) and
    (APid in [$0003, $2000, $2001, $2006]);
end;

function MtkModeLabel(APid: Word): string;
begin
  case APid of
    $0003: Result := 'BROM';
    $2000: Result := 'PRELOADER';
    $2001: Result := 'DA';
    $2006: Result := 'META';
  else
    Result := 'MTK';
  end;
end;

function AppExeDir: string;
begin
  { ParamStr(0), not Application.ExeName: this unit is part of the device
    layer and must stay free of VCL/LCL dependencies. }
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

function ParentDirOf(const ADir: string): string;
var
  S: string;
begin
  S := ExcludeTrailingPathDelimiter(ADir);
  if S = '' then
    Exit('');
  Result := ExtractFilePath(S);
  if Result = S + PathDelim then
    Result := '';
end;

{ The architecture-specific DLL name and subfolder of the bundled libusb
  tree. The support tree ships libusb\amd64\libusb0.dll (Win64),
  libusb\x86\libusb0_x86.dll (Win32) and libusb\arm64\libusb0.dll. }
procedure LibUsbArch(out ASubDir, ADllName: string);
begin
{$IFDEF CPUAARCH64}
  ASubDir := 'arm64';
  ADllName := 'libusb0.dll';
{$ELSE}
{$IFDEF CPU64}
  ASubDir := 'amd64';
  ADllName := 'libusb0.dll';
{$ELSE}
  ASubDir := 'x86';
  ADllName := 'libusb0_x86.dll';
{$ENDIF}
{$ENDIF}
end;

function FindLibUsbDll: string;
var
  SubDir, DllName: string;
  Current, Candidate: string;
  I: Integer;
begin
  Result := '';
  LibUsbArch(SubDir, DllName);
  Current := AppExeDir;
  for I := 0 to CMaxUpLevels do
  begin
    { Installed bundle / portable ZIP: the whole support tree, including
      libusb\<arch>, sits beside the EXE. }
    Candidate := IncludeTrailingPathDelimiter(Current) + 'libusb' +
      PathDelim + SubDir + PathDelim + DllName;
    if FileExists(Candidate) then
      Exit(Candidate);

    { Development checkout: the support tree lives under the repository's
      data folder (the same layout DaLoader searches for Data). }
    Candidate := IncludeTrailingPathDelimiter(Current) + 'data' +
      PathDelim + 'support' + PathDelim + 'MOBILO TOOLZ' + PathDelim +
      'libusb' + PathDelim + SubDir + PathDelim + DllName;
    if FileExists(Candidate) then
      Exit(Candidate);

    { Flat deployment: the DLL directly beside the EXE. }
    Candidate := IncludeTrailingPathDelimiter(Current) + DllName;
    if FileExists(Candidate) then
      Exit(Candidate);

    Current := ParentDirOf(Current);
    if Current = '' then
      Break;
  end;
end;

{ ------------------------------------------------------------ TUsbTransport }

constructor TUsbTransport.Create;
begin
  inherited Create;
  FDll := 0;
  FContext := nil;
  FDevice := nil;
  FDeviceHandle := nil;
  FClaimed := False;
  FInterface := -1;
  FEpIn := 0;
  FEpOut := 0;
  FVid := 0;
  FPid := 0;
  FPortName := '';
  FSetError := '';
  FTimeoutMs := CDefaultIoTimeoutMs;
  FBytesIn := 0;
  FBytesOut := 0;
  FLastError := '';
end;

destructor TUsbTransport.Destroy;
begin
  ClosePort;
  inherited Destroy;
end;

procedure TUsbTransport.SetVidPid(const AVidPid: string);
var
  V, P: Word;
begin
  FSetError := '';
  FVid := 0;
  FPid := 0;
  if not ParseVidPid(AVidPid, V, P) then
  begin
    FSetError := '"' + AVidPid + '" is not a VID_xxxx&PID_yyyy id';
    Exit;
  end;
  if not IsMtkServiceVidPid(V, P) then
  begin
    FSetError := 'VID_' + IntToHex(V, 4) + '&PID_' + IntToHex(P, 4) +
      ' is not a MediaTek service-mode id this build can drive over raw USB';
    Exit;
  end;
  FVid := V;
  FPid := P;
end;

procedure TUsbTransport.SetTimeout(ATimeoutMs: Integer);
begin
  if ATimeoutMs > 0 then
    FTimeoutMs := ATimeoutMs;
end;

function TUsbTransport.PortName: string;
begin
  Result := FPortName;
end;

function TUsbTransport.PortOpen: Boolean;
begin
  Result := FDeviceHandle <> nil;
end;

function TUsbTransport.ErrorText(AError: Integer): string;
begin
  Result := LibUsbErrorName(AError);
end;

function TUsbTransport.LoadApi(out AError: string): Boolean;
var
  Path, SubDir, DllName: string;
  W: WideString;

  function Need(const AName: string): Pointer;
  begin
    Result := GetProcAddress(FDll, PAnsiChar(AnsiString(AName)));
  end;

begin
  Result := False;
  AError := '';
  Path := FindLibUsbDll;
  if Path = '' then
  begin
    LibUsbArch(SubDir, DllName);
    AError := 'The bundled libusb DLL was not found (expected libusb\' +
      SubDir + '\' + DllName + ' beside the EXE, or libusb0 on the system ' +
      'search path)';
    Exit;
  end;
  W := Path;   { string -> WideString conversion on both compilers }
  FDll := LoadLibraryW(PWideChar(W));
  if FDll = 0 then
  begin
    AError := 'LoadLibrary failed for ' + Path + ': ' +
      SysErrorMessage(GetLastError);
    Exit;
  end;

  FInit := TLibusbInitFn(Need('libusb_init'));
  FExit := TLibusbExitFn(Need('libusb_exit'));
  FGetDeviceList := TLibusbGetDeviceListFn(Need('libusb_get_device_list'));
  FFreeDeviceList := TLibusbFreeDeviceListFn(Need('libusb_free_device_list'));
  FGetDeviceDescriptor :=
    TLibusbGetDeviceDescriptorFn(Need('libusb_get_device_descriptor'));
  FGetDescriptor := TLibusbGetDescriptorFn(Need('libusb_get_descriptor'));
  FOpen := TLibusbOpenFn(Need('libusb_open'));
  FClose := TLibusbCloseFn(Need('libusb_close'));
  FClaimInterface := TLibusbClaimInterfaceFn(Need('libusb_claim_interface'));
  FReleaseInterface :=
    TLibusbReleaseInterfaceFn(Need('libusb_release_interface'));
  FBulkTransfer := TLibusbBulkTransferFn(Need('libusb_bulk_transfer'));

  { Optional: configuration management and kernel-driver detach exist on
    every libusb 1.0 backend we care about, but the bind below degrades to
    a clear claim error when they are absent. }
  FGetConfiguration :=
    TLibusbGetConfigurationFn(Need('libusb_get_configuration'));
  FSetConfiguration :=
    TLibusbSetConfigurationFn(Need('libusb_set_configuration'));
  FDetachKernelDriver :=
    TLibusbDetachKernelDriverFn(Need('libusb_detach_kernel_driver'));
  FSetAutoDetach :=
    TLibusbSetAutoDetachFn(Need('libusb_set_auto_detach_kernel_driver'));

  if (not Assigned(FInit)) or (not Assigned(FExit)) or
     (not Assigned(FGetDeviceList)) or (not Assigned(FFreeDeviceList)) or
     (not Assigned(FGetDeviceDescriptor)) or (not Assigned(FGetDescriptor)) or
     (not Assigned(FOpen)) or (not Assigned(FClose)) or
     (not Assigned(FClaimInterface)) or (not Assigned(FReleaseInterface)) or
     (not Assigned(FBulkTransfer)) then
  begin
    AError := Path + ' does not export the libusb 1.0 API this build ' +
      'needs (it is too old or the wrong package - the support tree ships ' +
      'the libusb-win32 libusb0.dll, which exports it)';
    FreeLibrary(FDll);
    FDll := 0;
    Exit;
  end;
  Result := True;
end;

{ DETECT: walk the USB device list and open the first device whose VID/PID
  matches. The opened handle keeps the device alive after the list is freed. }
function TUsbTransport.FindAndOpenDevice(out AError: string): Boolean;
var
  List: Pointer;
  Count: NativeInt;
  PP: PPPointer;
  Desc: TLibusbDeviceDescriptor;
  Rc: Integer;
begin
  Result := False;
  AError := '';
  FDevice := nil;
  FDeviceHandle := nil;
  List := nil;
  Count := FGetDeviceList(FContext, List);
  if Count < 0 then
  begin
    AError := 'libusb_get_device_list failed: ' + ErrorText(Integer(Count));
    Exit;
  end;
  try
    if (List = nil) or (Count = 0) then
    begin
      AError := 'No USB devices are present at all';
      Exit;
    end;
    PP := PPPointer(List);
    while PP^ <> nil do
    begin
      Rc := FGetDeviceDescriptor(PP^, Desc);
      if (Rc = 0) and (Desc.idVendor = FVid) and (Desc.idProduct = FPid) then
      begin
        Rc := FOpen(PP^, FDeviceHandle);
        if Rc <> 0 then
        begin
          AError := 'libusb_open failed for VID_' + IntToHex(FVid, 4) +
            '&PID_' + IntToHex(FPid, 4) + ': ' + ErrorText(Rc);
          Exit;
        end;
        FDevice := PP^;
        Exit(True);
      end;
      Inc(PP);
    end;
    AError := 'No USB device VID_' + IntToHex(FVid, 4) + '&PID_' +
      IntToHex(FPid, 4) + ' is present (it may have left service mode)';
  finally
    if List <> nil then
      FFreeDeviceList(List, 1);
  end;
end;

{ The device must be configured before its interface can be claimed. On
  Windows it always is (WinUSB / the libusb filter driver configure it); on
  an unconfigured device we set configuration 1, like mtkclient's
  set_configuration() after "Configuration not set". }
function TUsbTransport.EnsureConfigured(out AError: string): Boolean;
var
  Cfg, Rc: Integer;
begin
  Result := True;
  AError := '';
  if not Assigned(FGetConfiguration) then
    Exit;
  Cfg := 0;
  Rc := FGetConfiguration(FDeviceHandle, Cfg);
  if (Rc = 0) and (Cfg > 0) then
    Exit;
  if not Assigned(FSetConfiguration) then
    Exit;
  Rc := FSetConfiguration(FDeviceHandle, 1);
  if Rc <> 0 then
  begin
    AError := 'libusb_set_configuration failed: ' + ErrorText(Rc);
    Result := False;
  end;
end;

{ ENDPOINTS: read the raw configuration descriptor with a control transfer
  (works before the claim) and walk it byte by byte. For every interface we
  remember its first bulk IN and OUT endpoint; the pair on a vendor-specific
  ($FF) or CDC ($02) interface wins over any other, the way mtkclient picks
  the interface to talk to. }
function TUsbTransport.DiscoverEndpoints(out AError: string): Boolean;
type
  TEpSlot = record
    Used: Boolean;
    EpClass: Integer;
    EpIn: Byte;
    EpOut: Byte;
  end;
var
  Buf: TBytesArray;
  Slots: array[0..7] of TEpSlot;
  N, Total, Pos, Len, DType: Integer;
  CurIf, CurClass, I, Slot: Integer;
  EpAddr: Byte;
  PickIn, PickOut, PickIf: Integer;
begin
  Result := False;
  AError := '';
  FEpIn := 0;
  FEpOut := 0;
  FInterface := -1;
  for I := 0 to 7 do
  begin
    Slots[I].Used := False;
    Slots[I].EpClass := -1;
    Slots[I].EpIn := 0;
    Slots[I].EpOut := 0;
  end;

  SetLength(Buf, 4096);
  N := FGetDescriptor(FDevice, CDtConfig, 0, @Buf[0], Length(Buf));
  if N < 0 then
  begin
    AError := 'Reading the USB configuration descriptor failed: ' +
      ErrorText(N);
    SetLength(Buf, 0);
    Exit;
  end;
  if N < 9 then
  begin
    AError := 'The USB configuration descriptor is truncated';
    SetLength(Buf, 0);
    Exit;
  end;
  Total := Buf[2] or (Buf[3] shl 8);
  if Total > N then
    Total := N;

  Pos := 0;
  CurIf := -1;
  CurClass := -1;
  while Pos + 2 <= Total do
  begin
    Len := Buf[Pos];
    DType := Buf[Pos + 1];
    if Len < 2 then
      Break;
    if Pos + Len > Total then
      Break;
    if (DType = CDtInterface) and (Len >= 9) then
    begin
      CurIf := Buf[Pos + 2];
      CurClass := Buf[Pos + 5];
      if (CurIf >= 0) and (CurIf <= 7) then
      begin
        Slots[CurIf].Used := True;
        Slots[CurIf].EpClass := CurClass;
      end;
    end
    else if (DType = CDtEndpoint) and (Len >= 7) then
    begin
      if (CurIf >= 0) and (CurIf <= 7) and
         ((Buf[Pos + 3] and $03) = CTransferTypeBulk) then
      begin
        EpAddr := Buf[Pos + 2];
        Slot := CurIf;
        if (EpAddr and CEpDirIn) <> 0 then
        begin
          if Slots[Slot].EpIn = 0 then
            Slots[Slot].EpIn := EpAddr;
        end
        else
        begin
          if Slots[Slot].EpOut = 0 then
            Slots[Slot].EpOut := EpAddr;
        end;
      end;
    end;
    Inc(Pos, Len);
  end;
  SetLength(Buf, 0);

  { Prefer a vendor-specific or CDC interface that has the full pair. }
  PickIn := 0;
  PickOut := 0;
  PickIf := -1;
  for I := 0 to 7 do
    if Slots[I].Used and (Slots[I].EpIn <> 0) and (Slots[I].EpOut <> 0) and
       ((Slots[I].EpClass = CIfClassVendor) or
        (Slots[I].EpClass = CIfClassCdc)) then
    begin
      PickIn := Slots[I].EpIn;
      PickOut := Slots[I].EpOut;
      PickIf := I;
      Break;
    end;
  { Fall back to the first interface with a full pair. }
  if PickIf < 0 then
    for I := 0 to 7 do
      if Slots[I].Used and (Slots[I].EpIn <> 0) and (Slots[I].EpOut <> 0) then
      begin
        PickIn := Slots[I].EpIn;
        PickOut := Slots[I].EpOut;
        PickIf := I;
        Break;
      end;

  if (PickIf < 0) or (PickIn = 0) or (PickOut = 0) then
  begin
    AError := 'VID_' + IntToHex(FVid, 4) + '&PID_' + IntToHex(FPid, 4) +
      ' exposes no bulk IN/OUT endpoint pair to talk to';
    Exit;
  end;
  FEpIn := Byte(PickIn);
  FEpOut := Byte(PickOut);
  FInterface := PickIf;
  Result := True;
end;

{ BIND: the claim is the exclusive lock. A kernel driver in the way is
  detached first, best effort - on Windows the libusb filter driver
  (libusb0.sys, install-filter in the support tree) or WinUSB makes the
  claim work even with a driver attached. }
function TUsbTransport.ClaimInterface(out AError: string): Boolean;
var
  Rc: Integer;
begin
  Result := False;
  AError := '';
  if Assigned(FSetAutoDetach) then
    FSetAutoDetach(FDeviceHandle, 1);
  if Assigned(FDetachKernelDriver) then
    FDetachKernelDriver(FDeviceHandle, FInterface);
  Rc := FClaimInterface(FDeviceHandle, FInterface);
  if Rc = 0 then
  begin
    FClaimed := True;
    Result := True;
    Exit;
  end;
  case Rc of
    CLibUsbErrorBusy:
      AError := 'The USB interface ' + IntToStr(FInterface) + ' of VID_' +
        IntToHex(FVid, 4) + '&PID_' + IntToHex(FPid, 4) +
        ' is already claimed by another program';
    CLibUsbErrorAccess:
      AError := 'Windows denied access to the USB interface of VID_' +
        IntToHex(FVid, 4) + '&PID_' + IntToHex(FPid, 4) +
        '. Install the libusb WinUSB filter driver for this device ' +
        '(install-filter is in the libusb folder of the support tree) or ' +
        'the MediaTek VCOM driver and use the COM port instead';
  else
    AError := 'libusb_claim_interface(' + IntToStr(FInterface) +
      ') failed: ' + ErrorText(Rc);
  end;
end;

procedure TUsbTransport.ReleaseAll;
begin
  { THE RELEASE. Undo the bind in the opposite order; every step is safe
    when the one before it never happened. }
  if FDeviceHandle <> nil then
  begin
    if FClaimed and Assigned(FReleaseInterface) then
      FReleaseInterface(FDeviceHandle, FInterface);
    FClaimed := False;
    if Assigned(FClose) then
      FClose(FDeviceHandle);
    FDeviceHandle := nil;
  end;
  FDevice := nil;
  if FContext <> nil then
  begin
    if Assigned(FExit) then
      FExit(FContext);
    FContext := nil;
  end;
  if FDll <> 0 then
  begin
    FreeLibrary(FDll);
    FDll := 0;
  end;
  FInit := nil;
  FExit := nil;
  FGetDeviceList := nil;
  FFreeDeviceList := nil;
  FGetDeviceDescriptor := nil;
  FGetDescriptor := nil;
  FOpen := nil;
  FClose := nil;
  FClaimInterface := nil;
  FReleaseInterface := nil;
  FBulkTransfer := nil;
  FGetConfiguration := nil;
  FSetConfiguration := nil;
  FDetachKernelDriver := nil;
  FSetAutoDetach := nil;
end;

function TUsbTransport.OpenPort(out AError: string): Boolean;
var
  Rc: Integer;
begin
  Result := False;
  AError := '';
  FLastError := '';
  ClosePort;
  if FSetError <> '' then
  begin
    AError := FSetError;
    Exit;
  end;
  if (FVid = 0) or (FPid = 0) then
  begin
    AError := 'No MediaTek USB VID/PID was set on the transport';
    Exit;
  end;
  if not LoadApi(AError) then
    Exit;
  Rc := FInit(FContext);
  if Rc <> 0 then
  begin
    AError := 'libusb_init failed: ' + ErrorText(Rc);
    FContext := nil;
    Exit;
  end;
  try
    Result := FindAndOpenDevice(AError) and EnsureConfigured(AError) and
      DiscoverEndpoints(AError) and ClaimInterface(AError);
  except
    on E: Exception do
    begin
      AError := 'USB bind failed: ' + E.Message;
      Result := False;
    end;
  end;
  if not Result then
  begin
    ReleaseAll;
    Exit;
  end;
  FPortName := 'USB VID_' + IntToHex(FVid, 4) + '&PID_' + IntToHex(FPid, 4) +
    ' (' + MtkModeLabel(FPid) + ')';
end;

procedure TUsbTransport.ClosePort;
begin
  ReleaseAll;
  FEpIn := 0;
  FEpOut := 0;
  FInterface := -1;
end;

function TUsbTransport.WriteData(const AData; ACount: Integer): Integer;
var
  Transferred: Integer;
  Rc: Integer;
begin
  Result := 0;
  if not PortOpen then
    Exit;
  if ACount <= 0 then
    Exit;
  Transferred := 0;
  { One bulk transfer: libusb splits it into USB packets internally and
    returns only when everything was accepted (or an error/timeout hit). }
  Rc := FBulkTransfer(FDeviceHandle, FEpOut, PByte(@AData), ACount,
    Transferred, Cardinal(FTimeoutMs));
  if Rc <> 0 then
  begin
    FLastError := 'USB write failed: ' + ErrorText(Rc);
    Exit;
  end;
  Result := Transferred;
  Inc(FBytesOut, Transferred);
end;

function TUsbTransport.ReadData(var ABuffer; ACount, ATimeoutMs: Integer): Integer;
var
  Transferred: Integer;
  Rc: Integer;
begin
  Result := 0;
  if not PortOpen then
    Exit;
  if ACount <= 0 then
    Exit;
  if ATimeoutMs <= 0 then
    ATimeoutMs := FTimeoutMs;
  Transferred := 0;
  { One bulk transfer returns as soon as the device answers - a short packet
    completes the transfer - which is exactly the TCommTransport contract:
    "how many bytes arrived; 0 means timed out with nothing read". }
  Rc := FBulkTransfer(FDeviceHandle, FEpIn, PByte(@ABuffer), ACount,
    Transferred, Cardinal(ATimeoutMs));
  if Rc = 0 then
  begin
    Result := Transferred;
    Inc(FBytesIn, Transferred);
  end
  else if Rc = CLibUsbErrorTimeout then
  begin
    FLastError := 'USB read timed out after ' + IntToStr(ATimeoutMs) + ' ms';
  end
  else if Rc = CLibUsbErrorOverflow then
  begin
    { The device sent more than asked for; the requested bytes arrived. }
    Result := Transferred;
    Inc(FBytesIn, Transferred);
  end
  else
  begin
    FLastError := 'USB read failed: ' + ErrorText(Rc);
  end;
end;

end.
