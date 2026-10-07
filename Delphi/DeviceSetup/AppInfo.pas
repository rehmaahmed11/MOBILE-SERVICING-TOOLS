unit AppInfo;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


{ Application-wide information and settings:
    - version / build id (shown in the title bar and Help)
    - where data files live (settings, logs, models.csv)
    - the user options edited in the Settings dialog
  Settings are kept in DeviceSetup.ini next to the EXE (portable). If that
  folder is not writable (e.g. Program Files), %APPDATA%\MobileServicingTools
  is used instead. }

interface

uses
{$IFDEF FPC}
  Windows, Classes, SysUtils, IniFiles, Controls, StdCtrls, Forms;
{$ELSE}
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  System.IniFiles,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.Forms;
{$ENDIF}

const
  CAppName = 'Mobile Servicing Tools';
  CAppVersion = '1.1.0';
  {$I BuildInfo.inc}

type
  TAppOptions = record
    ShowTimeInLog: Boolean;   { "[12:34:56]" in front of every log line }
    AutoSaveLog: Boolean;     { save each MAIN 2 session to the logs folder }
    RememberFiles: Boolean;   { remember file paths and job options }
    DetectUsb: Boolean;       { watch for phones in service modes }
  end;

var
  GOptions: TAppOptions;

function AppTitle: string;
function AppVersionText: string;

function ExeDir: string;
function DataDir: string;
function LogsDir: string;
function SettingsFileName: string;

{ Shared settings file. Changes are written by FlushSettings. }
function Settings: TMemIniFile;
procedure FlushSettings;

procedure LoadOptions;
procedure SaveOptions;

{ Lazarus only (no-op in Delphi): in the LCL a group box's client area starts
  below its caption, while the .dfm positions are measured from the top of
  the box (VCL). This moves the contents of every group box on the form back
  up so both builds look the same. AReference must be a visible group box.
  Call once, when the form is shown. }
procedure FixGroupBoxLayout(AForm: TForm; AReference: TGroupBox);

implementation

var
  GSettings: TMemIniFile;
  GDataDir: string;

function AppTitle: string;
begin
  Result := CAppName + ' v' + CAppVersion;
end;

function AppVersionText: string;
begin
  Result := 'Version ' + CAppVersion + ' (build ' + CAppBuild + ')';
end;

function ExeDir: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName));
end;

function DirIsWritable(const ADir: string): Boolean;
var
  TestFile: string;
  H: THandle;
begin
  TestFile := ADir + '~write-test.tmp';
  H := FileCreate(TestFile);
  Result := H <> THandle(-1);
  if Result then
  begin
    FileClose(H);
    DeleteFile(TestFile);
  end;
end;

function DataDir: string;
var
  AppData: string;
begin
  if GDataDir = '' then
  begin
    GDataDir := ExeDir;
    if not DirIsWritable(GDataDir) then
    begin
      AppData := GetEnvironmentVariable('APPDATA');
      if AppData <> '' then
      begin
        GDataDir := IncludeTrailingPathDelimiter(AppData) +
          'MobileServicingTools' + PathDelim;
        ForceDirectories(GDataDir);
      end;
    end;
  end;
  Result := GDataDir;
end;

function LogsDir: string;
begin
  Result := DataDir + 'logs' + PathDelim;
end;

function SettingsFileName: string;
begin
  Result := DataDir + 'DeviceSetup.ini';
end;

function Settings: TMemIniFile;
begin
  if GSettings = nil then
  begin
    {$IFDEF FPC}
    GSettings := TMemIniFile.Create(SettingsFileName);  { LCL strings are UTF-8 }
    {$ELSE}
    GSettings := TMemIniFile.Create(SettingsFileName, TEncoding.UTF8);
    {$ENDIF}
  end;
  Result := GSettings;
end;

procedure FlushSettings;
begin
  if GSettings = nil then
    Exit;
  try
    GSettings.UpdateFile;
  except
    { read-only folder or file in use: settings are simply not saved }
  end;
end;

procedure LoadOptions;
var
  Ini: TMemIniFile;
begin
  Ini := Settings;
  GOptions.ShowTimeInLog := Ini.ReadBool('Options', 'ShowTimeInLog', False);
  GOptions.AutoSaveLog := Ini.ReadBool('Options', 'AutoSaveLog', True);
  GOptions.RememberFiles := Ini.ReadBool('Options', 'RememberFiles', True);
  GOptions.DetectUsb := Ini.ReadBool('Options', 'DetectUsb', True);
end;

procedure SaveOptions;
var
  Ini: TMemIniFile;
begin
  Ini := Settings;
  Ini.WriteBool('Options', 'ShowTimeInLog', GOptions.ShowTimeInLog);
  Ini.WriteBool('Options', 'AutoSaveLog', GOptions.AutoSaveLog);
  Ini.WriteBool('Options', 'RememberFiles', GOptions.RememberFiles);
  Ini.WriteBool('Options', 'DetectUsb', GOptions.DetectUsb);
  FlushSettings;
end;

procedure FixGroupBoxLayout(AForm: TForm; AReference: TGroupBox);
{$IFDEF FPC}
var
  P: TPoint;
  DX, DY, Shift, MinTop, I, J: Integer;
  G: TGroupBox;
  C: TControl;
begin
  P := AReference.Parent.ClientToScreen(Point(AReference.Left, AReference.Top));
  DY := AReference.ClientOrigin.Y - P.Y;
  DX := AReference.ClientOrigin.X - P.X;
  if (DY <= 0) or (DY > 40) then
    Exit;  { client area already starts at the top: nothing to fix }
  if (DX < 0) or (DX > 8) then
    DX := 0;
  for I := 0 to AForm.ComponentCount - 1 do
    if AForm.Components[I] is TGroupBox then
    begin
      G := TGroupBox(AForm.Components[I]);
      { never move a control above the client area }
      MinTop := MaxInt;
      for J := 0 to G.ControlCount - 1 do
        if (G.Controls[J].Align = alNone) and (G.Controls[J].Top < MinTop) then
          MinTop := G.Controls[J].Top;
      if MinTop = MaxInt then
        Continue;
      Shift := DY;
      if Shift > MinTop then
        Shift := MinTop;
      G.DisableAlign;
      try
        for J := 0 to G.ControlCount - 1 do
        begin
          C := G.Controls[J];
          if C.Align = alNone then
            C.SetBounds(C.Left - DX, C.Top - Shift, C.Width, C.Height);
        end;
      finally
        G.EnableAlign;
      end;
    end;
end;
{$ELSE}
begin
  { VCL: positions already match the .dfm }
end;
{$ENDIF}

initialization

finalization
  FlushSettings;
  FreeAndNil(GSettings);

end.
