unit CommPort;

{$IFDEF FPC}
  {$MODE DELPHI}
  {$PACKRECORDS C}
{$ENDIF}

{ Transport layer for talking to a phone.

  TCommPort owns ONE thing: an exclusive handle to a device port.

  When Open succeeds, the port is opened with dwShareMode = 0, which is the
  Windows equivalent of "this port belongs to me now". Any other program -
  another copy of this tool, SP Flash Tool, a terminal, the vendor suite -
  gets ERROR_SHARING_VIOLATION until ClosePort runs. That is the lock: the
  device is grabbed the moment Windows hands it to us, and it is not let go
  until the job that took it has finished, failed or been cancelled.

  TCommTransport is the abstract byte pipe the protocols use. Two concrete
  implementations exist:
    TCommPort - a real \\.\COMx handle (this unit)
    TSimPort  - an in-process simulated phone (SimPort.pas) used by the
                self-test so the whole stack is exercised without hardware

  The protocols never call CreateFile themselves, so they cannot leak a
  handle or forget to release the lock. }

interface

uses
{$IFDEF FPC}
  Windows, Classes, SysUtils;
{$ELSE}
  Winapi.Windows,
  System.Classes,
  System.SysUtils;
{$ENDIF}

type
  { Abstract byte pipe. All protocol units depend only on this. }
  TCommTransport = class(TObject)
  public
    function OpenPort(out AError: string): Boolean; virtual; abstract;
    procedure ClosePort; virtual; abstract;
    function PortOpen: Boolean; virtual; abstract;
    { Writes all of AData. Returns the number of bytes accepted. }
    function WriteData(const AData; ACount: Integer): Integer; virtual; abstract;
    { Reads up to ACount bytes, waiting at most ATimeoutMs. Returns how many
      bytes arrived; 0 means "timed out with nothing read". }
    function ReadData(var ABuffer; ACount, ATimeoutMs: Integer): Integer;
      virtual; abstract;
    function PortName: string; virtual; abstract;
    { True when this transport is a simulation rather than a real phone. }
    function IsSimulated: Boolean; virtual;
  end;

  { A real serial (CDC-ACM / VCOM) port, held exclusively. }
  TCommPort = class(TCommTransport)
  private
    FHandle: THandle;
    FPortName: string;
    FBaud: DWORD;
    FTimeoutMs: Integer;
    FEvent: THandle;
    FExclusive: Boolean;
    FBytesIn: Int64;
    FBytesOut: Int64;
    FLastError: string;
    function ApplyLineCoding: Boolean;
    function OverlappedIo(AWrite: Boolean; const ABuffer; ACount: Integer;
      ATimeoutMs: Integer; out ADone: DWORD): Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    { COM5, \\.\COM5 and 5 all mean the same port. }
    procedure SetPort(const AName: string);
    procedure SetBaud(ABaud: DWORD);
    procedure SetTimeout(ATimeoutMs: Integer);
    { When False the port is opened shared - only used by the "is somebody
      else holding it?" probe. The lock always uses True. }
    property Exclusive: Boolean read FExclusive write FExclusive;

    function OpenPort(out AError: string): Boolean; override;
    procedure ClosePort; override;
    function PortOpen: Boolean; override;
    function WriteData(const AData; ACount: Integer): Integer; override;
    function ReadData(var ABuffer; ACount, ATimeoutMs: Integer): Integer; override;
    function PortName: string; override;
    function IsSimulated: Boolean; override;

    { Drops everything the device sent but we did not read yet. }
    procedure FlushInput;
    { True when another process already holds the port (sharing violation). }
    function IsHeldBySomeoneElse: Boolean;

    property Handle: THandle read FHandle;
    property BytesIn: Int64 read FBytesIn;
    property BytesOut: Int64 read FBytesOut;
    property LastError: string read FLastError;
  end;

{ Normalises 'COM5' / '\\.\COM5' / '5' into the CreateFile device path. }
function CommDevicePath(const AName: string): string;
{ True when AText names something that could be a COM port. }
function LooksLikeComPort(const AText: string): Boolean;
{ Windows message for the last failure, e.g. 'Access is denied (5)'. }
function LastWinErrorText: string;

implementation

type
  { Declared here instead of relying on the Windows unit: the FPC and Delphi
    declarations differ in field names across versions, and this one is
    checked against the Win32 ABI directly. }
  TCommDcb = record
    DCBlength: DWORD;
    BaudRate: DWORD;
    Flags: DWORD;      { bitfield: fBinary..fAbortOnError packed into 32 bits }
    wReserved: Word;
    XonLim: Word;
    XoffLim: Word;
    ByteSize: Byte;
    Parity: Byte;
    StopBits: Byte;
    XonChar: AnsiChar;
    XoffChar: AnsiChar;
    ErrorChar: AnsiChar;
    EofChar: AnsiChar;
    EvtChar: AnsiChar;
    wReserved1: Word;
  end;

  TCommOverlapped = record
    Internal: NativeUInt;
    InternalHigh: NativeUInt;
    Offset: DWORD;
    OffsetHigh: DWORD;
    hEvent: THandle;
  end;

const
  { DCB bit positions from winbase.h. Only the ones we actually set are
    declared; every other flag stays cleared (see ApplyLineCoding). }
  DCB_fBinary = 0;             { must be 1 on Win32 }
  DCB_DTR_SHIFT = 4;           { bits 4-5  = fDtrControl }
  DCB_RTS_SHIFT = 12;          { bits 12-13 = fRtsControl }
  DTR_CONTROL_ENABLE = 1;
  RTS_CONTROL_ENABLE = 1;

  PURGE_RXABORT = $0002;
  PURGE_RXCLEAR = $0008;
  PURGE_TXABORT = $0001;
  PURGE_TXCLEAR = $0004;

function SetCommStateWin(hFile: THandle; var ADcb: TCommDcb): BOOL; stdcall;
  external kernel32 name 'SetCommState';
function GetCommStateWin(hFile: THandle; var ADcb: TCommDcb): BOOL; stdcall;
  external kernel32 name 'GetCommState';
function SetupCommWin(hFile: THandle; InSize, OutSize: DWORD): BOOL; stdcall;
  external kernel32 name 'SetupComm';
function PurgeCommWin(hFile: THandle; Flags: DWORD): BOOL; stdcall;
  external kernel32 name 'PurgeComm';
function EscapeCommFunctionWin(hFile: THandle; Func: DWORD): BOOL; stdcall;
  external kernel32 name 'EscapeCommFunction';
function ClearCommErrorWin(hFile: THandle; Errors: PDWORD;
  Stat: Pointer): BOOL; stdcall; external kernel32 name 'ClearCommError';

const
  SETRTS = 3;
  CLRRTS = 4;

function LastWinErrorText: string;
var
  E: DWORD;
begin
  E := GetLastError;
  case E of
    0: Result := 'no error';
    2: Result := 'Port not found (2)';
    3: Result := 'Path not found (3)';
    5: Result := 'Access is denied (5) - the port is held by another program';
    32: Result := 'Sharing violation (32) - the device is locked by another program';
    121: Result := 'Semaphore timeout (121) - the device stopped answering';
  else
    Result := 'Windows error ' + IntToStr(E);
  end;
end;

function CommDevicePath(const AName: string): string;
var
  S: string;
begin
  S := Trim(AName);
  if S = '' then
    Exit('');
  { Accept the bare number, 'COM5' and the full device path. }
  if (Length(S) > 0) and (S[1] >= '0') and (S[1] <= '9') then
    S := 'COM' + S;
  if Copy(UpperCase(S), 1, 4) <> '\\.\' then
    S := '\\.\' + S;
  Result := S;
end;

function LooksLikeComPort(const AText: string): Boolean;
begin
  Result := Pos('COM', UpperCase(AText)) > 0;
end;

{ ------------------------------------------------------------ TCommTransport }

function TCommTransport.IsSimulated: Boolean;
begin
  Result := False;
end;

{ ------------------------------------------------------------------ TCommPort }

constructor TCommPort.Create;
begin
  inherited Create;
  FHandle := INVALID_HANDLE_VALUE;
  FEvent := 0;
  FBaud := 115200;
  FTimeoutMs := 2000;
  FExclusive := True;
  FLastError := '';
end;

destructor TCommPort.Destroy;
begin
  ClosePort;
  inherited Destroy;
end;

procedure TCommPort.SetPort(const AName: string);
begin
  FPortName := AName;
end;

procedure TCommPort.SetBaud(ABaud: DWORD);
begin
  if ABaud > 0 then
    FBaud := ABaud;
end;

procedure TCommPort.SetTimeout(ATimeoutMs: Integer);
begin
  if ATimeoutMs > 0 then
    FTimeoutMs := ATimeoutMs;
end;

function TCommPort.PortName: string;
begin
  Result := FPortName;
end;

function TCommPort.IsSimulated: Boolean;
begin
  Result := False;
end;

function TCommPort.PortOpen: Boolean;
begin
  Result := (FHandle <> INVALID_HANDLE_VALUE) and (FHandle <> 0);
end;

function TCommPort.ApplyLineCoding: Boolean;
var
  Dcb: TCommDcb;
  Flags: DWORD;
begin
  FillChar(Dcb, SizeOf(Dcb), 0);
  Dcb.DCBlength := SizeOf(Dcb);
  if not GetCommStateWin(FHandle, Dcb) then
  begin
    FLastError := 'GetCommState failed: ' + LastWinErrorText;
    Result := False;
    Exit;
  end;
  Dcb.BaudRate := FBaud;
  Dcb.ByteSize := 8;
  Dcb.Parity := 0;      { NOPARITY }
  Dcb.StopBits := 0;    { ONESTOPBIT }

  { Rebuild the bitfield. Hardware flow control must stay OFF: a phone in
    BROM/preloader mode never asserts CTS/DSR, and with fOutxCtsFlow set every
    write would block forever - the classic "tool hangs on connect" bug. }
  Flags := 0;
  Flags := Flags or (1 shl DCB_fBinary);            { Win32 requires this }
  Flags := Flags or (DTR_CONTROL_ENABLE shl DCB_DTR_SHIFT);
  Flags := Flags or (RTS_CONTROL_ENABLE shl DCB_RTS_SHIFT);
  { fParity, fOutxCtsFlow, fOutxDsrFlow, fDsrSensitivity, fTXContinueOnXoff,
    fOutX, fInX, fErrorChar, fNull, fAbortOnError all stay cleared. }
  Dcb.Flags := Flags;
  Dcb.XonLim := 0;
  Dcb.XoffLim := 0;

  Result := SetCommStateWin(FHandle, Dcb);
  if not Result then
    FLastError := 'SetCommState failed: ' + LastWinErrorText;
  if Result then
    SetupCommWin(FHandle, 65536, 65536);
end;

function TCommPort.OpenPort(out AError: string): Boolean;
var
  Path: string;
  ShareMode: DWORD;
begin
  AError := '';
  FLastError := '';
  if FPortName = '' then
  begin
    AError := 'No port name';
    Exit(False);
  end;
  ClosePort;
  Path := CommDevicePath(FPortName);

  { THE LOCK. dwShareMode = 0 means: no other handle may be opened on this
    device while ours lives. Windows answers every later CreateFile with
    ERROR_SHARING_VIOLATION, so Device Manager, a vendor tool or a second
    copy of this app cannot grab the phone in the middle of a read/write. }
  if FExclusive then
    ShareMode := 0
  else
    ShareMode := FILE_SHARE_READ or FILE_SHARE_WRITE;

  FHandle := CreateFile(PChar(Path), GENERIC_READ or GENERIC_WRITE,
    ShareMode, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_OVERLAPPED, 0);
  if FHandle = INVALID_HANDLE_VALUE then
  begin
    FHandle := 0;
    FLastError := LastWinErrorText;
    AError := 'Cannot open ' + Path + ': ' + FLastError;
    Exit(False);
  end;

  FEvent := CreateEvent(nil, True, False, nil);
  if FEvent = 0 then
  begin
    FLastError := 'Cannot create I/O event: ' + LastWinErrorText;
    ClosePort;
    AError := FLastError;
    Exit(False);
  end;

  if not ApplyLineCoding then
  begin
    AError := FLastError;
    ClosePort;
    Exit(False);
  end;

  PurgeCommWin(FHandle, PURGE_RXCLEAR or PURGE_TXCLEAR);
  EscapeCommFunctionWin(FHandle, SETRTS);
  FBytesIn := 0;
  FBytesOut := 0;
  Result := True;
end;

procedure TCommPort.ClosePort;
begin
  { THE RELEASE. Closing the handle is what hands the phone back; after this
    another program can open it again. }
  if FHandle <> INVALID_HANDLE_VALUE then
  begin
    if FHandle <> 0 then
    begin
      PurgeCommWin(FHandle, PURGE_RXABORT or PURGE_TXABORT or
        PURGE_RXCLEAR or PURGE_TXCLEAR);
      CloseHandle(FHandle);
    end;
    FHandle := INVALID_HANDLE_VALUE;
  end;
  if FEvent <> 0 then
  begin
    CloseHandle(FEvent);
    FEvent := 0;
  end;
end;

procedure TCommPort.FlushInput;
begin
  if PortOpen then
    PurgeCommWin(FHandle, PURGE_RXABORT or PURGE_RXCLEAR);
end;

function TCommPort.IsHeldBySomeoneElse: Boolean;
var
  H: THandle;
begin
  Result := False;
  if FPortName = '' then
    Exit;
  { Ask for a shared read. If somebody owns the port exclusively this fails
    with a sharing violation, which is exactly the answer we want. }
  H := CreateFile(PChar(CommDevicePath(FPortName)), GENERIC_READ,
    FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
  if H = INVALID_HANDLE_VALUE then
    Result := GetLastError = ERROR_SHARING_VIOLATION
  else
    CloseHandle(H);
end;

function TCommPort.OverlappedIo(AWrite: Boolean; const ABuffer;
  ACount: Integer; ATimeoutMs: Integer; out ADone: DWORD): Boolean;
var
  Ov: TCommOverlapped;
  WaitRes: DWORD;
  Ok: BOOL;
begin
  ADone := 0;
  Result := False;
  if not PortOpen or (ACount <= 0) then
    Exit;
  FillChar(Ov, SizeOf(Ov), 0);
  Ov.hEvent := FEvent;
  ResetEvent(FEvent);

  if AWrite then
    Ok := WriteFile(FHandle, ABuffer, DWORD(ACount), ADone, @Ov)
  else
    Ok := ReadFile(FHandle, ABuffer, DWORD(ACount), ADone, @Ov);

  if Ok then
    Exit(True);
  if GetLastError <> ERROR_IO_PENDING then
  begin
    FLastError := LastWinErrorText;
    Exit(False);
  end;

  WaitRes := WaitForSingleObject(FEvent, DWORD(ATimeoutMs));
  if WaitRes = WAIT_OBJECT_0 then
  begin
    ADone := 0;
    { BOOL is LongBool under FPC, so test it instead of assigning it to the
      Boolean Result: the two are convertible but only one way is portable. }
    if GetOverlappedResult(FHandle, POverlapped(@Ov), ADone, False) then
      Result := True
    else
      Result := False;
    if not Result then
      FLastError := LastWinErrorText;
  end
  else
  begin
    { Timed out: cancel this request so the port stays usable, then report 0
      bytes. Callers treat that as "device stopped answering". }
    CancelIo(FHandle);
    WaitForSingleObject(FEvent, 500);
    ADone := 0;
    GetOverlappedResult(FHandle, POverlapped(@Ov), ADone, False);
    if WaitRes = WAIT_TIMEOUT then
      FLastError := 'Timeout after ' + IntToStr(ATimeoutMs) + ' ms'
    else
      FLastError := LastWinErrorText;
    Result := False;
  end;
end;

function TCommPort.WriteData(const AData; ACount: Integer): Integer;
var
  Done: DWORD;
begin
  Result := 0;
  if OverlappedIo(True, AData, ACount, FTimeoutMs, Done) then
  begin
    Result := Integer(Done);
    Inc(FBytesOut, Done);
  end;
end;

function TCommPort.ReadData(var ABuffer; ACount, ATimeoutMs: Integer): Integer;
var
  Done: DWORD;
  T: Integer;
begin
  T := ATimeoutMs;
  if T <= 0 then
    T := FTimeoutMs;
  Result := 0;
  if OverlappedIo(False, ABuffer, ACount, T, Done) then
  begin
    Result := Integer(Done);
    Inc(FBytesIn, Done);
  end
  else if Done > 0 then
  begin
    { Timed out but some bytes did arrive - hand them over. }
    Result := Integer(Done);
    Inc(FBytesIn, Done);
  end;
end;

end.
