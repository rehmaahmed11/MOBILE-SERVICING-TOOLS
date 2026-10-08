unit AdbTool;

{$IFDEF FPC}
  {$MODE DELPHI}
  {$PACKRECORDS C}
{$ENDIF}


{ Runs the bundled Android platform tools (adb.exe, fastboot.exe) and collects
  their output.

  These are the operations that genuinely work on a booted phone without any
  vendor secret: reboot to recovery, read the properties, unlock / relock the
  bootloader through fastboot, switch an A/B slot, disable OTA packages.

  The executable is searched next to the EXE, in the reference application
  folder that ships with this repository, and finally on PATH. When it is not
  there the tool says so instead of inventing a result.

  Output is read through pipes with PeekNamedPipe, so the UI keeps repainting
  and a command that never answers is killed after its timeout instead of
  hanging the app. }

interface

uses
{$IFDEF FPC}
  Windows, Classes, SysUtils, Forms,
{$ELSE}
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  Vcl.Forms,
{$ENDIF}
  DevTypes;

type
  TCmdResult = record
    Ran: Boolean;       { the executable was found and started }
    Ok: Boolean;        { exit code 0 }
    ExitCode: Integer;
    Output: string;     { stdout + stderr, as the tool wrote it }
    Error: string;      { why it could not run, '' when it ran }
    ElapsedMs: Int64;
  end;

  TAndroidState = (asUnknown, asNoTool, asNoDevice, asOffline, asDevice,
    asRecovery, asBootloader, asSideload, asUnauthorized);

  { adb.exe / fastboot.exe runner. One instance per job; stateless apart from
    the resolved executable paths. }
  TAdbTool = class(TObject)
  private
    FAdbPath: string;
    FFastbootPath: string;
    FSerial: string;
    FTimeoutMs: Integer;
    FOnLog: TJobLogEvent;
    procedure DoLog(const AText: string);
    function RunExe(const AExe, AArgs: string; ATimeoutMs: Integer;
      out AResult: TCmdResult): Boolean;
  public
    constructor Create;

    { Locates adb.exe. Returns '' when it is not installed. }
    function AdbExe: string;
    function FastbootExe: string;
    function HasAdb: Boolean;
    function HasFastboot: Boolean;
    { One line for the log explaining what is missing, or '' when all is well. }
    function MissingToolMessage(AWantFastboot: Boolean): string;

    { Runs an adb subcommand ('shell getprop ro.product.model'). }
    function Adb(const AArgs: string; out AResult: TCmdResult): Boolean;
    function Fastboot(const AArgs: string; out AResult: TCmdResult): Boolean;
    { Runs any command, for the self-test. }
    function Run(const AExe, AArgs: string; out AResult: TCmdResult): Boolean;

    { 'adb devices' state of the first device, or asNoDevice. }
    function DeviceState: TAndroidState;
    function HasDevice: Boolean;
    { 'adb shell getprop AName', trimmed. '' when unavailable. }
    function GetProp(const AName: string): string;
    function Shell(const ACommand: string; out AResult: TCmdResult): Boolean;
    function RebootTo(const ATarget: string; out AResult: TCmdResult): Boolean;
    { 'fastboot devices' answered? }
    function FastbootDevice: Boolean;
    { Waits up to ATimeoutMs for a device in AState to appear. }
    function WaitForState(AState: TAndroidState; ATimeoutMs: Integer): Boolean;
    { Kills a stuck adb server so the port is free for the exclusive lock. }
    procedure KillServer;

    property Serial: string read FSerial write FSerial;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs;
    property OnLog: TJobLogEvent read FOnLog write FOnLog;
  end;

function StateName(AState: TAndroidState): string;
{ Parses the first serial / state pair out of 'adb devices' output. }
function ParseAdbDevices(const AOutput: string; out ASerial: string;
  out AState: TAndroidState): Boolean;
function EmptyCmdResult: TCmdResult;
{ First non-empty line of a command output, trimmed. }
function FirstLineOf(const AText: string): string;
{ Searches the usual places for AExeName ('adb.exe'). '' when not found. }
function FindTool(const AExeName: string): string;

implementation

uses
{$IFDEF FPC}
  StrUtils;
{$ELSE}
  System.StrUtils;
{$ENDIF}

const
  CToolTimeoutMs = 30000;
  { exit code reported when a command had to be killed }
  CKilledExitCode = 124;

{ Reference application folder shipped with this repository. The tools sit in
  "FULL APP STRUCTURE\MOBILO TOOLZ" relative to the repository root, which is
  two or three levels above the Delphi project when the EXE runs from a source
  checkout, and next to the EXE in an installed layout. }
function CandidateDirs: TStringList;
var
  Exe: string;
begin
  Result := TStringList.Create;
  Exe := ExtractFilePath(Application.ExeName);
  Result.Add(Exe);
  Result.Add(Exe + 'tools' + PathDelim);
  Result.Add(Exe + 'platform-tools' + PathDelim);
  Result.Add(Exe + '..' + PathDelim + '..' + PathDelim +
    'FULL APP STRUCTURE' + PathDelim + 'MOBILO TOOLZ' + PathDelim);
  Result.Add(Exe + '..' + PathDelim + '..' + PathDelim + '..' + PathDelim +
    'FULL APP STRUCTURE' + PathDelim + 'MOBILO TOOLZ' + PathDelim);
  Result.Add('C:\platform-tools' + PathDelim);
  Result.Add(GetEnvironmentVariable('LOCALAPPDATA') + PathDelim +
    'Android' + PathDelim + 'Sdk' + PathDelim + 'platform-tools' + PathDelim);
end;

function FindTool(const AExeName: string): string;
var
  Dirs: TStringList;
  I: Integer;
  Candidate: string;
begin
  Result := AExeName;
  Dirs := CandidateDirs;
  try
    for I := 0 to Dirs.Count - 1 do
    begin
      Candidate := Dirs[I] + AExeName;
      if FileExists(Candidate) then
        Exit(ExpandFileName(Candidate));
    end;
  finally
    Dirs.Free;
  end;
  { Last resort: search PATH, so HasAdb can answer honestly instead of leaving
    CreateProcess to find something we could not verify. }
  Dirs := TStringList.Create;
  try
    Dirs.Delimiter := ';';
    Dirs.StrictDelimiter := True;
    Dirs.DelimitedText := GetEnvironmentVariable('PATH');
    for I := 0 to Dirs.Count - 1 do
    begin
      Candidate := IncludeTrailingPathDelimiter(Trim(Dirs[I])) + AExeName;
      if FileExists(Candidate) then
        Exit(ExpandFileName(Candidate));
    end;
  finally
    Dirs.Free;
  end;
end;

{ Milliseconds since ATick, coping with the 49-day GetTickCount64 wrap. }
function TicksSince(ATick: Int64): Int64;
begin
  Result := Int64(GetTickCount64) - ATick;
  if Result < 0 then
    Result := 0;
end;

function EmptyCmdResult: TCmdResult;
begin
  Result.Ran := False;
  Result.Ok := False;
  Result.ExitCode := -1;
  Result.Output := '';
  Result.Error := '';
  Result.ElapsedMs := 0;
end;

function FirstLineOf(const AText: string): string;
var
  P: Integer;
begin
  Result := Trim(AText);
  P := Pos(#13, Result);
  if P = 0 then
    P := Pos(#10, Result);
  if P > 0 then
    Result := Trim(Copy(Result, 1, P - 1));
end;

function StateName(AState: TAndroidState): string;
begin
  case AState of
    asNoTool: Result := 'platform-tools not found';
    asNoDevice: Result := 'no device';
    asOffline: Result := 'offline';
    asDevice: Result := 'device';
    asRecovery: Result := 'recovery';
    asBootloader: Result := 'bootloader / fastboot';
    asSideload: Result := 'sideload';
    asUnauthorized: Result := 'unauthorized (accept the RSA prompt on the phone)';
  else
    Result := 'unknown';
  end;
end;

function ParseAdbDevices(const AOutput: string; out ASerial: string;
  out AState: TAndroidState): Boolean;
var
  Lines: TStringList;
  I, P: Integer;
  Line, State: string;
begin
  ASerial := '';
  AState := asNoDevice;
  Result := False;
  Lines := TStringList.Create;
  try
    Lines.Text := AOutput;
    for I := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[I]);
      if (Line = '') or (Pos('List of devices', Line) = 1) or
         (Pos('*', Line) = 1) then
        Continue;
      P := Pos(#9, Line);
      if P = 0 then
        P := Pos('  ', Line);
      if P <= 0 then
        Continue;
      ASerial := Trim(Copy(Line, 1, P - 1));
      State := LowerCase(Trim(Copy(Line, P + 1, MaxInt)));
      if Pos('unauthorized', State) > 0 then
        AState := asUnauthorized
      else if Pos('offline', State) > 0 then
        AState := asOffline
      else if Pos('recovery', State) > 0 then
        AState := asRecovery
      else if Pos('sideload', State) > 0 then
        AState := asSideload
      else if Pos('bootloader', State) > 0 then
        AState := asBootloader
      else if Pos('device', State) > 0 then
        AState := asDevice
      else
        AState := asUnknown;
      Result := ASerial <> '';
      if Result then
        Break;
    end;
  finally
    Lines.Free;
  end;
end;

{ ------------------------------------------------------------------ TAdbTool }

constructor TAdbTool.Create;
begin
  inherited Create;
  FAdbPath := '';
  FFastbootPath := '';
  FSerial := '';
  FTimeoutMs := CToolTimeoutMs;
  FOnLog := nil;
end;

procedure TAdbTool.DoLog(const AText: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, AText);
end;

function TAdbTool.AdbExe: string;
begin
  if FAdbPath = '' then
    FAdbPath := FindTool('adb.exe');
  Result := FAdbPath;
end;

function TAdbTool.FastbootExe: string;
begin
  if FFastbootPath = '' then
    FFastbootPath := FindTool('fastboot.exe');
  Result := FFastbootPath;
end;

function TAdbTool.HasAdb: Boolean;
begin
  Result := FileExists(AdbExe);
end;

function TAdbTool.HasFastboot: Boolean;
begin
  Result := FileExists(FastbootExe);
end;

function TAdbTool.MissingToolMessage(AWantFastboot: Boolean): string;
begin
  Result := '';
  if not HasAdb then
    Result := 'adb.exe was not found next to the application, in ' +
      '"FULL APP STRUCTURE\MOBILO TOOLZ", in %LOCALAPPDATA%\Android\Sdk\' +
      'platform-tools or on PATH. Install the Android platform-tools and ' +
      'start again.';
  if AWantFastboot and (not HasFastboot) then
  begin
    if Result <> '' then
      Result := Result + ' ';
    Result := Result + 'fastboot.exe was not found. It ships with the same ' +
      'platform-tools package as adb.exe.';
  end;
end;

function TAdbTool.RunExe(const AExe, AArgs: string; ATimeoutMs: Integer;
  out AResult: TCmdResult): Boolean;
var
  SecAttr: TSecurityAttributes;
  Startup: TStartupInfo;
  ProcessInfo: TProcessInformation;
  ReadPipe, WritePipe, ErrPipe: THandle;
  Buffer: array[0..4095] of AnsiChar;
  Chunk: AnsiString;
  BytesRead, BytesAvail, ExitCode: DWORD;
  Exited, Drained: Boolean;
  T0, TNow: Int64;
  CmdLine: string;
begin
  AResult := EmptyCmdResult;
  Result := False;

  if not FileExists(AExe) then
  begin
    AResult.Error := AExe + ' was not found';
    Exit;
  end;

  SecAttr.nLength := SizeOf(SecAttr);
  SecAttr.lpSecurityDescriptor := nil;
  SecAttr.bInheritHandle := True;
  ReadPipe := 0;
  WritePipe := 0;
  ErrPipe := 0;
  if not CreatePipe(ReadPipe, WritePipe, @SecAttr, 0) then
  begin
    AResult.Error := 'Cannot create the output pipe (Windows error ' +
      IntToStr(GetLastError) + ')';
    Exit;
  end;
  ErrPipe := WritePipe;
  { the child must not inherit our reading end, or the pipe never signals EOF }
  SetHandleInformation(ReadPipe, HANDLE_FLAG_INHERIT, 0);

  FillChar(Startup, SizeOf(Startup), 0);
  Startup.cb := SizeOf(Startup);
  Startup.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
  Startup.wShowWindow := SW_HIDE;
  Startup.hStdOutput := WritePipe;
  Startup.hStdError := ErrPipe;
  Startup.hStdInput := GetStdHandle(STD_INPUT_HANDLE);

  FillChar(ProcessInfo, SizeOf(ProcessInfo), 0);
  CmdLine := '"' + AExe + '" ' + AArgs;
  DoLog('$ ' + CmdLine);
  { `not <BOOL>` instead of assigning it to a Boolean: FPC maps BOOL to
    LongBool, which is a boolean type and cannot be compared with an integer. }
  if not CreateProcess(nil, PChar(CmdLine), nil, nil, True, CREATE_NO_WINDOW,
    nil, PChar(ExtractFilePath(AExe)), Startup, ProcessInfo) then
  begin
    AResult.Error := 'Cannot start ' + ExtractFileName(AExe) +
      ' (Windows error ' + IntToStr(GetLastError) + ')';
    CloseHandle(ReadPipe);
    CloseHandle(WritePipe);
    Exit;
  end;
  { our copy of the write end must be closed, or ReadFile never returns 0 }
  CloseHandle(WritePipe);
  WritePipe := 0;

  T0 := GetTickCount64;
  Exited := False;
  Drained := False;
  AResult.Output := '';
  while not Drained do
  begin
    Application.ProcessMessages;
    BytesAvail := 0;
    if PeekNamedPipe(ReadPipe, nil, 0, nil, @BytesAvail, nil) then
    begin
      while BytesAvail > 0 do
      begin
        if BytesAvail > SizeOf(Buffer) then
          BytesAvail := SizeOf(Buffer);
        BytesRead := 0;
        if not ReadFile(ReadPipe, Buffer, BytesAvail, BytesRead, nil) then
          Break;
        if BytesRead = 0 then
          Break;
        SetString(Chunk, PAnsiChar(@Buffer[0]), Integer(BytesRead));
        AResult.Output := AResult.Output + string(Chunk);
        BytesAvail := 0;
        PeekNamedPipe(ReadPipe, nil, 0, nil, @BytesAvail, nil);
      end;
    end
    else
    begin
      { broken pipe: the child closed its end and is done writing }
      Drained := True;
    end;

    if not Exited then
      Exited := WaitForSingleObject(ProcessInfo.hProcess, 0) = WAIT_OBJECT_0;
    if Exited and (BytesAvail = 0) then
      Drained := True;
    TNow := TicksSince(T0);
    if (not Exited) and (ATimeoutMs > 0) and (TNow > Int64(ATimeoutMs)) then
    begin
      TerminateProcess(ProcessInfo.hProcess, DWORD(CKilledExitCode));
      AResult.ExitCode := CKilledExitCode;
      AResult.Error := 'Timed out after ' + IntToStr(ATimeoutMs div 1000) +
        ' s and was killed';
      Drained := True;
    end;
    if not Drained then
      Sleep(10);
  end;

  WaitForSingleObject(ProcessInfo.hProcess, 2000);
  ExitCode := 0;
  GetExitCodeProcess(ProcessInfo.hProcess, ExitCode);
  CloseHandle(ProcessInfo.hProcess);
  CloseHandle(ProcessInfo.hThread);
  CloseHandle(ReadPipe);

  AResult.Ran := True;
  if AResult.Error = '' then
    AResult.ExitCode := Integer(ExitCode);
  AResult.Ok := (AResult.ExitCode = 0) and (AResult.Error = '');
  AResult.ElapsedMs := TicksSince(T0);
  if AResult.Ok then
    DoLog('exit ' + IntToStr(AResult.ExitCode) + ' in ' +
      IntToStr(AResult.ElapsedMs) + ' ms')
  else
    DoLog('exit ' + IntToStr(AResult.ExitCode) +
      IfThen(AResult.Error = '', '', ' - ' + AResult.Error));
  Result := True;
end;

function TAdbTool.Run(const AExe, AArgs: string; out AResult: TCmdResult): Boolean;
begin
  Result := RunExe(AExe, AArgs, FTimeoutMs, AResult);
end;

function TAdbTool.Adb(const AArgs: string; out AResult: TCmdResult): Boolean;
var
  Args: string;
begin
  Args := AArgs;
  if (FSerial <> '') and (Pos(' devices', ' ' + Args) = 0) and
     (Pos('start-server', Args) = 0) and (Pos('kill-server', Args) = 0) then
    Args := '-s ' + FSerial + ' ' + Args;
  Result := RunExe(AdbExe, Args, FTimeoutMs, AResult);
end;

function TAdbTool.Fastboot(const AArgs: string;
  out AResult: TCmdResult): Boolean;
var
  Args: string;
begin
  Args := AArgs;
  if FSerial <> '' then
    Args := '-s ' + FSerial + ' ' + Args;
  Result := RunExe(FastbootExe, Args, FTimeoutMs, AResult);
end;

function TAdbTool.DeviceState: TAndroidState;
var
  Res: TCmdResult;
  Serial: string;
begin
  Result := asUnknown;
  if not HasAdb then
    Exit(asNoTool);
  if not Adb('devices', Res) then
    Exit(asUnknown);
  if ParseAdbDevices(Res.Output, Serial, Result) then
  begin
    if (FSerial = '') and (Serial <> '') then
      FSerial := Serial;
  end
  else
    Result := asNoDevice;
end;

function TAdbTool.HasDevice: Boolean;
begin
  Result := DeviceState = asDevice;
end;

function TAdbTool.FastbootDevice: Boolean;
var
  Res: TCmdResult;
begin
  Result := False;
  if not HasFastboot then
    Exit;
  if not Fastboot('devices', Res) then
    Exit;
  Result := Trim(Res.Output) <> '';
end;

function TAdbTool.GetProp(const AName: string): string;
var
  Res: TCmdResult;
begin
  Result := '';
  if not HasDevice then
    Exit;
  if Adb('shell getprop ' + AName, Res) and Res.Ok then
    Result := Trim(FirstLineOf(Res.Output));
end;

function TAdbTool.Shell(const ACommand: string;
  out AResult: TCmdResult): Boolean;
begin
  Result := Adb('shell ' + ACommand, AResult);
end;

function TAdbTool.RebootTo(const ATarget: string;
  out AResult: TCmdResult): Boolean;
begin
  if ATarget = '' then
    Result := Adb('reboot', AResult)
  else
    Result := Adb('reboot ' + ATarget, AResult);
end;

function TAdbTool.WaitForState(AState: TAndroidState;
  ATimeoutMs: Integer): Boolean;
var
  T0: Int64;
begin
  Result := False;
  T0 := GetTickCount64;
  while True do
  begin
    Application.ProcessMessages;
    if DeviceState = AState then
      Exit(True);
    if TicksSince(T0) > Int64(ATimeoutMs) then
      Exit(False);
    Sleep(250);
  end;
end;

procedure TAdbTool.KillServer;
var
  Res: TCmdResult;
begin
  if not HasAdb then
    Exit;
  Adb('kill-server', Res);
end;

end.
