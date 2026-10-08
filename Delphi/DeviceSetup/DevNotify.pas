unit DevNotify;

{$IFDEF FPC}
  {$MODE DELPHI}
  {$PACKRECORDS C}
{$ENDIF}

{ Instant device-arrival notification.

  UsbDetect polls the device list once a second. That is fine for logging
  "a phone was plugged in", but far too slow for capturing BROM: the MediaTek
  BootROM only listens for a fraction of a second after the cable goes in, so
  the next poll can easily run after the window has already closed.

  This unit registers a message-only window for WM_DEVICECHANGE and raises an
  event the moment Windows reports DBT_DEVICEARRIVAL or
  DBT_DEVICEREMOVECOMPLETE. The capture loop uses both sources: the
  notification wakes it up immediately, the poll covers the case where the
  message was missed.

  Windows plays its "device connected" sound on exactly this event, so the
  sound the user hears and our attempt to grab the port are driven by the same
  thing.

  Everything Win32 is imported explicitly and the window procedure is a plain
  static callback with the object pointer in GWLP_USERDATA, so the unit
  compiles unchanged with Delphi and Free Pascal, Win32 and Win64, without
  MakeObjectInstance or LCL/VCL message records. }

interface

uses
{$IFDEF FPC}
  Windows, Classes, SysUtils;
{$ELSE}
  Winapi.Windows,
  System.Classes,
  System.SysUtils;
{$ENDIF}

const
  CWM_DEVICECHANGE = $0219;
  CDBT_DEVICEARRIVAL = $8000;
  CDBT_DEVICEREMOVECOMPLETE = $8004;
  CDBT_DEVNODES_CHANGED = $0007;
  CDBT_DEVTYP_DEVICEINTERFACE = $00000005;
  CDEVICE_NOTIFY_ALL_INTERFACE_CLASSES = $00000004;
  CGWLP_USERDATA = -21;
  CHWND_MESSAGE = HWND(-3);

type
  TDevChangeKind = (dcArrival, dcRemoval, dcNodesChanged);

  TDevChangeNotify = procedure(Sender: TObject; AKind: TDevChangeKind;
    const ADescription: string) of object;

  TDeviceNotifier = class(TObject)
  private
    FWnd: HWND;
    FNotification: THandle;
    FActive: Boolean;
    FEnabled: Boolean;
    FOnChange: TDevChangeNotify;
    procedure HandleMessage(AMsg: UINT; AWParam: WPARAM; ALParam: LPARAM);
  public
    constructor Create;
    destructor Destroy; override;

    { Creates the message-only window and asks for interface notifications.
      AParent may be 0. Returns False when the window could not be created;
      callers then rely on polling alone. }
    function Start(AParent: HWND = 0): Boolean;
    procedure Stop;

    { True while listening. }
    property Active: Boolean read FActive;
    { Set to False to keep the window but ignore events (used while a job
      already owns the device, so a removal does not confuse the capture). }
    property Enabled: Boolean read FEnabled write FEnabled;
    property OnChange: TDevChangeNotify read FOnChange write FOnChange;
  end;

{ Describes a WM_DEVICECHANGE lParam payload for the log. }
function DescribeDeviceChange(ALParam: LPARAM; out AKind: TDevChangeKind): string;

implementation

type
  TDevBroadcastHdr = record
    dbch_size: DWORD;
    dbch_devicetype: DWORD;
    dbch_reserved: DWORD;
  end;
  PDevBroadcastHdr = ^TDevBroadcastHdr;

  TDevBroadcastIntf = record
    dbcc_size: DWORD;
    dbcc_devicetype: DWORD;
    dbcc_reserved: DWORD;
    dbcc_classguid: TGUID;
    dbcc_name: array[0..0] of WideChar;
  end;
  PDevBroadcastIntf = ^TDevBroadcastIntf;

function RegisterClassWin(var AClass: TWndClassW): ATOM; stdcall;
  external user32 name 'RegisterClassW';
{ FPC declares GetClassInfoW with an LPWNDCLASSW parameter and Delphi with an
  `out TWndClassW` one, so `Wc` compiles on one and `@Wc` on the other.
  Declaring it here with a `var` record - which both compilers pass as a
  pointer - makes the call site identical on either. }
function GetClassInfoWin(Instance: HINST; ClassName: PWideChar;
  var AClass: TWndClassW): BOOL; stdcall; external user32 name 'GetClassInfoW';
function CreateWindowExWin(ExStyle: DWORD; ClassName, WindowName: PWideChar;
  Style: DWORD; X, Y, W, H: Integer; Parent: HWND; Menu: HMENU;
  Inst: HINST; Param: Pointer): HWND; stdcall; external user32 name
  'CreateWindowExW';
function DefWindowProcWin(H: HWND; Msg: UINT; W: WPARAM; L: LPARAM): LRESULT;
  stdcall; external user32 name 'DefWindowProcW';
function SetWindowLongPtrWin(H: HWND; Index: Integer; Value: LONG_PTR): LONG_PTR;
  stdcall; external user32 name
{$IFDEF CPU64}
  'SetWindowLongPtrW';
{$ELSE}
  'SetWindowLongW';   { Win32 has no SetWindowLongPtr export }
{$ENDIF}
function GetWindowLongPtrWin(H: HWND; Index: Integer): LONG_PTR; stdcall;
  external user32 name
{$IFDEF CPU64}
  'GetWindowLongPtrW';
{$ELSE}
  'GetWindowLongW';
{$ENDIF}
function RegisterDeviceNotificationWin(H: THandle; Filter: Pointer;
  Flags: DWORD): THandle; stdcall; external user32 name
  'RegisterDeviceNotificationW';
function UnregisterDeviceNotificationWin(H: THandle): BOOL; stdcall;
  external user32 name 'UnregisterDeviceNotification';

var
  GNotifierCount: Integer = 0;

function DescribeDeviceChange(ALParam: LPARAM; out AKind: TDevChangeKind): string;
var
  Hdr: PDevBroadcastHdr;
  Intf: PDevBroadcastIntf;
begin
  Result := '';
  AKind := dcArrival;   { the caller knows the real kind from wParam }
  Hdr := PDevBroadcastHdr(ALParam);
  if Hdr = nil then
    Exit;
  case Hdr^.dbch_devicetype of
    CDBT_DEVTYP_DEVICEINTERFACE:
      begin
        Intf := PDevBroadcastIntf(ALParam);
        Result := PWideChar(@Intf^.dbcc_name);
      end;
  else
    Result := 'devtype $' + IntToHex(Hdr^.dbch_devicetype, 8);
  end;
end;

{ Static window procedure. The object that owns the window is kept in
  GWLP_USERDATA, so several notifiers can exist at once. }
function NotifierWndProc(H: HWND; Msg: UINT; W: WPARAM; L: LPARAM): LRESULT;
  stdcall;
var
  Self_: TDeviceNotifier;
begin
  Self_ := TDeviceNotifier(GetWindowLongPtrWin(H, CGWLP_USERDATA));
  if Assigned(Self_) then
  begin
    Self_.HandleMessage(Msg, W, L);
    if Msg = CWM_DEVICECHANGE then
    begin
      Result := 1;
      Exit;
    end;
  end;
  Result := DefWindowProcWin(H, Msg, W, L);
end;

procedure TDeviceNotifier.HandleMessage(AMsg: UINT; AWParam: WPARAM;
  ALParam: LPARAM);
var
  Kind: TDevChangeKind;
  Desc: string;
begin
  if AMsg <> CWM_DEVICECHANGE then
    Exit;
  if not FEnabled then
    Exit;

  case AWParam of
    CDBT_DEVICEARRIVAL: Kind := dcArrival;
    CDBT_DEVICEREMOVECOMPLETE: Kind := dcRemoval;
    CDBT_DEVNODES_CHANGED: Kind := dcNodesChanged;
  else
    Exit;
  end;

  Desc := DescribeDeviceChange(ALParam, Kind);
  if Assigned(FOnChange) then
  begin
    try
      FOnChange(Self, Kind, Desc);
    except
      { A stray notification must never take the application down. }
    end;
  end;
end;

constructor TDeviceNotifier.Create;
begin
  inherited Create;
  FWnd := 0;
  FNotification := 0;
  FActive := False;
  FEnabled := True;
  Inc(GNotifierCount);
end;

destructor TDeviceNotifier.Destroy;
begin
  Stop;
  Dec(GNotifierCount);
  inherited Destroy;
end;

function TDeviceNotifier.Start(AParent: HWND): Boolean;
const
  CClassName: UnicodeString = 'MSTDeviceNotifierWnd';
var
  Wc: TWndClassW;
  Filter: TDevBroadcastHdr;
  UniqueName: UnicodeString;
begin
  if FActive then
    Exit(True);

  FillChar(Wc, SizeOf(Wc), 0);
  if GetClassInfoWin(HInstance, PWideChar(CClassName), Wc) = 0 then
  begin
    FillChar(Wc, SizeOf(Wc), 0);
    Wc.lpfnWndProc := @NotifierWndProc;
    Wc.hInstance := HInstance;
    Wc.lpszClassName := PWideChar(CClassName);
    if RegisterClassWin(Wc) = 0 then
      Exit(False);
  end;

  { Each window gets a unique title so two forms can own one at the same time. }
  UniqueName := CClassName + '_' + IntToStr(GNotifierCount);
  FWnd := CreateWindowExWin(0, PWideChar(CClassName), PWideChar(UniqueName),
    0, 0, 0, 0, 0, CHWND_MESSAGE, 0, HInstance, nil);
  if FWnd = 0 then
    Exit(False);

  SetWindowLongPtrWin(FWnd, CGWLP_USERDATA, LONG_PTR(Self));

  FillChar(Filter, SizeOf(Filter), 0);
  Filter.dbch_size := SizeOf(Filter);
  Filter.dbch_devicetype := CDBT_DEVTYP_DEVICEINTERFACE;
  FNotification := RegisterDeviceNotificationWin(FWnd, @Filter,
    CDEVICE_NOTIFY_ALL_INTERFACE_CLASSES);
  { Even when the explicit registration is refused the window still receives
    the broadcast WM_DEVICECHANGE messages, so keep listening either way. }
  FActive := True;
  Result := True;
end;

procedure TDeviceNotifier.Stop;
begin
  if FWnd <> 0 then
    SetWindowLongPtrWin(FWnd, CGWLP_USERDATA, 0);
  if FNotification <> 0 then
  begin
    UnregisterDeviceNotificationWin(FNotification);
    FNotification := 0;
  end;
  if FWnd <> 0 then
  begin
    DestroyWindow(FWnd);
    FWnd := 0;
  end;
  FActive := False;
end;

end.
