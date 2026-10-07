unit AppSettings;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


{ Application-wide folders, INI settings and log writing.

  Everything is stored under %APPDATA%\MobileServicingTools so the EXE can be
  run from anywhere (Downloads, a USB stick, a read-only share) and still
  remember the technician's settings, presets and logs:

    %APPDATA%\MobileServicingTools\settings.ini   remembered options + presets
    %APPDATA%\MobileServicingTools\logs\          daily log + error reports
    %APPDATA%\MobileServicingTools\Data\          extra brand/model .txt files

  A Data folder next to the EXE is read as well, so a whole setup can also be
  kept portable in one folder.

  Writes are buffered in memory; call Save (done automatically when the app
  closes) to push them to disk. Nothing in this unit ever raises - a missing
  or read-only profile only means settings are not remembered.

  Compiles unchanged under Delphi (RAD Studio) and Lazarus / Free Pascal. }

interface

uses
{$IFDEF FPC}
  Classes, SysUtils, IniFiles;
{$ELSE}
  System.Classes,
  System.SysUtils,
  System.IniFiles;
{$ENDIF}

const
  CAppName = 'Mobile Servicing Tools';
  CAppFolderName = 'MobileServicingTools';
  CAppVersion = '1.1';

type
  TAppSettings = class
  public
    class function ExeFolder: string;
    class function ConfigDir: string;
    class function LogDir: string;
    class function DataDir: string;
    class function ExeDataDir: string;
    class function IniFileName: string;
    class function DailyLogFileName: string;

    class function ReadString(const ASection, AName, ADefault: string): string;
    class procedure WriteString(const ASection, AName, AValue: string);
    class function ReadBool(const ASection, AName: string;
      const ADefault: Boolean): Boolean;
    class procedure WriteBool(const ASection, AName: string;
      const AValue: Boolean);
    class function ReadInt(const ASection, AName: string;
      const ADefault: Integer): Integer;
    class procedure WriteInt(const ASection, AName: string;
      const AValue: Integer);
    class procedure DeleteValue(const ASection, AName: string);
    class procedure EraseSection(const ASection: string);
    class procedure ReadSection(const ASection: string; AStrings: TStrings);
    class procedure Save;

    { Log files. Never raise. }
    class procedure AppendToDailyLog(const AText: string);
    class procedure WriteErrorReport(const AContext, AMessage: string);
    class function OpenFolder(const APath: string): Boolean;
  end;

implementation

uses
{$IFDEF FPC}
  Windows, ShellApi;      { SW_SHOWNORMAL lives in Windows under Free Pascal }
{$ELSE}
  Winapi.Windows,
  Winapi.ShellAPI;
{$ENDIF}

var
  GIni: TMemIniFile = nil;
  GIniFailed: Boolean = False;
  GConfigDir: string = '';

function StripSlash(const APath: string): string;
begin
  Result := APath;
  while (Result <> '') and
        ((Result[Length(Result)] = '\') or (Result[Length(Result)] = '/')) do
    Delete(Result, Length(Result), 1);
end;

function EnsureDir(const APath: string): Boolean;
begin
  Result := False;
  if APath = '' then
    Exit;
  try
    if DirectoryExists(APath) then
      Result := True
    else
      Result := ForceDirectories(APath);
  except
    Result := DirectoryExists(APath);
  end;
end;

{ Returns nil when the settings file cannot be used at all. }
function Ini: TMemIniFile;
begin
  if (GIni = nil) and (not GIniFailed) then
  begin
    EnsureDir(TAppSettings.ConfigDir);
    try
      GIni := TMemIniFile.Create(TAppSettings.IniFileName);
    except
      GIni := nil;
      GIniFailed := True;
    end;
  end;
  Result := GIni;
end;

{ ------------------------------------------------------------ folders }

class function TAppSettings.ExeFolder: string;
begin
  Result := ExtractFilePath(ParamStr(0));
end;

class function TAppSettings.ConfigDir: string;
var
  Base: string;
begin
  if GConfigDir = '' then
  begin
    { Qualified: the Windows unit also exports a GetEnvironmentVariable. }
    Base := StripSlash(SysUtils.GetEnvironmentVariable('APPDATA'));
    if Base = '' then
      Base := StripSlash(ExeFolder);
    GConfigDir := IncludeTrailingPathDelimiter(Base + PathDelim + CAppFolderName);
  end;
  Result := GConfigDir;
end;

class function TAppSettings.LogDir: string;
begin
  Result := ConfigDir + 'logs' + PathDelim;
end;

class function TAppSettings.DataDir: string;
begin
  Result := ConfigDir + 'Data' + PathDelim;
end;

class function TAppSettings.ExeDataDir: string;
begin
  Result := ExeFolder + 'Data' + PathDelim;
end;

class function TAppSettings.IniFileName: string;
begin
  Result := ConfigDir + 'settings.ini';
end;

class function TAppSettings.DailyLogFileName: string;
begin
  Result := LogDir + FormatDateTime('yyyymmdd', Now) + '.txt';
end;

{ ------------------------------------------------------------ settings }

class function TAppSettings.ReadString(const ASection, AName,
  ADefault: string): string;
begin
  Result := ADefault;
  if Ini = nil then
    Exit;
  try
    Result := Ini.ReadString(ASection, AName, ADefault);
  except
    Result := ADefault;
  end;
end;

class procedure TAppSettings.WriteString(const ASection, AName,
  AValue: string);
begin
  if Ini = nil then
    Exit;
  try
    Ini.WriteString(ASection, AName, AValue);
  except
  end;
end;

class function TAppSettings.ReadBool(const ASection, AName: string;
  const ADefault: Boolean): Boolean;
begin
  Result := ADefault;
  if Ini = nil then
    Exit;
  try
    Result := Ini.ReadBool(ASection, AName, ADefault);
  except
    Result := ADefault;
  end;
end;

class procedure TAppSettings.WriteBool(const ASection, AName: string;
  const AValue: Boolean);
begin
  WriteString(ASection, AName, BoolToStr(AValue, True));
end;

class function TAppSettings.ReadInt(const ASection, AName: string;
  const ADefault: Integer): Integer;
begin
  Result := ADefault;
  if Ini = nil then
    Exit;
  try
    Result := Ini.ReadInteger(ASection, AName, ADefault);
  except
    Result := ADefault;
  end;
end;

class procedure TAppSettings.WriteInt(const ASection, AName: string;
  const AValue: Integer);
begin
  WriteString(ASection, AName, IntToStr(AValue));
end;

class procedure TAppSettings.DeleteValue(const ASection, AName: string);
begin
  if Ini = nil then
    Exit;
  try
    Ini.DeleteKey(ASection, AName);
  except
  end;
end;

class procedure TAppSettings.EraseSection(const ASection: string);
begin
  if Ini = nil then
    Exit;
  try
    Ini.EraseSection(ASection);
  except
  end;
end;

class procedure TAppSettings.ReadSection(const ASection: string;
  AStrings: TStrings);
begin
  if AStrings = nil then
    Exit;
  AStrings.Clear;
  if Ini = nil then
    Exit;
  try
    Ini.ReadSection(ASection, AStrings);
  except
    AStrings.Clear;
  end;
end;

class procedure TAppSettings.Save;
begin
  if GIni = nil then
    Exit;
  try
    if GIni.FileName <> '' then
      GIni.UpdateFile;
  except
  end;
end;

{ ------------------------------------------------------------ log files }

procedure AppendTextToFile(const AFileName, AText: string);
var
  FS: TFileStream;
  U: UTF8String;
  Existed: Boolean;

  procedure WriteStr(const S: string);
  begin
    U := UTF8Encode(S);
    if Length(U) > 0 then
      FS.WriteBuffer(U[1], Length(U));
  end;

begin
  if AFileName = '' then
    Exit;
  try
    Existed := FileExists(AFileName);
    FS := nil;
    if Existed then
    begin
      FS := TFileStream.Create(AFileName, fmOpenWrite or fmShareDenyNone);
      FS.Seek(0, soEnd);
    end
    else
      FS := TFileStream.Create(AFileName, fmCreate);
    try
      if not Existed then
        WriteStr(CAppName + ' log - ' +
          FormatDateTime('yyyy-mm-dd', Now) + sLineBreak);
      WriteStr(AText + sLineBreak);
    finally
      FS.Free;
    end;
  except
    { A locked or read-only log file must never break the app. }
  end;
end;

class procedure TAppSettings.AppendToDailyLog(const AText: string);
begin
  EnsureDir(LogDir);
  AppendTextToFile(DailyLogFileName, AText);
end;

class procedure TAppSettings.WriteErrorReport(const AContext,
  AMessage: string);
var
  FileName: string;
begin
  EnsureDir(LogDir);
  FileName := LogDir + 'error-' + FormatDateTime('yyyymmdd-hhnnss', Now) + '.txt';
  AppendTextToFile(FileName,
    CAppName + ' ' + CAppVersion + sLineBreak +
    'When    : ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + sLineBreak +
    'Where   : ' + AContext + sLineBreak +
    'Problem : ' + AMessage + sLineBreak +
    'EXE     : ' + ParamStr(0));
end;

class function TAppSettings.OpenFolder(const APath: string): Boolean;
var
  Target: string;
begin
  Target := StripSlash(APath);
  if (Target <> '') and (not DirectoryExists(Target)) then
    EnsureDir(Target);
  if (Target = '') or (not DirectoryExists(Target)) then
  begin
    Result := False;
    Exit;
  end;
  Result := NativeInt(ShellExecute(0, 'open', PChar('explorer.exe'),
    PChar('"' + Target + '"'), nil, SW_SHOWNORMAL)) > 32;
end;

initialization

finalization
  TAppSettings.Save;
  FreeAndNil(GIni);

end.
