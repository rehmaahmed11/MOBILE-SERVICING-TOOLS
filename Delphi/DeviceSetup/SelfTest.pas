unit SelfTest;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


{ "DeviceSetup.exe --selftest" - used by the CI build.
  Opens MAIN 1 and MAIN 2 (which checks that the forms load), runs the
  checks that need no dialogs, saves screenshots of the screens and writes
  selftest\selftest.log next to the EXE. Exit code 0 = all passed.
  Normal users never see this. }

interface

function SelfTestRequested: Boolean;
procedure InstallSelfTestHandler;
procedure RunSelfTest;
{ Writes an exception that stopped the self-test before it could start. }
procedure ReportSelfTestCrash(const AWhere: string; E: TObject);

implementation

uses
{$IFDEF FPC}
  Windows, Classes, SysUtils, Forms, Graphics,
{$ELSE}
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  Vcl.Forms,
  Vcl.Graphics,
{$ENDIF}
  AppInfo,
  DeviceCatalog,
  UsbDetect,
  MainForm,
  Main2Form;

const
  PW_RENDERFULLCONTENT = 2;

function PrintWindow(hwnd: HWND; hdcBlt: HDC; nFlags: UINT): BOOL; stdcall;
  external 'user32.dll' name 'PrintWindow';

type
  TSelfTestHandler = class
    procedure AppException(Sender: TObject; E: Exception);
  end;

var
  GHandler: TSelfTestHandler;

function OutDir: string;
begin
  Result := ExeDir + 'selftest' + PathDelim;
end;

function SelfTestRequested: Boolean;
var
  I: Integer;
  S: string;
begin
  { accepts --selftest, -selftest and /selftest }
  Result := False;
  for I := 1 to ParamCount do
  begin
    S := LowerCase(ParamStr(I));
    if (S = '--selftest') or (S = '-selftest') or (S = '/selftest') then
      Result := True;
  end;
end;

procedure TSelfTestHandler.AppException(Sender: TObject; E: Exception);
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.Add('EXCEPTION ' + E.ClassName + ': ' + E.Message);
    ForceDirectories(OutDir);
    L.SaveToFile(OutDir + 'selftest.log');
  finally
    L.Free;
  end;
  Halt(3);
end;

procedure ReportSelfTestCrash(const AWhere: string; E: TObject);
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    if E is Exception then
      L.Add('EXCEPTION in ' + AWhere + ': ' + E.ClassName + ': ' +
        Exception(E).Message)
    else
      L.Add('EXCEPTION in ' + AWhere);
    L.Add('SELFTEST FAILED');
    ForceDirectories(OutDir);
    L.SaveToFile(OutDir + 'selftest.log');
  finally
    L.Free;
  end;
end;

procedure InstallSelfTestHandler;
begin
  GHandler := TSelfTestHandler.Create;
  Application.OnException := GHandler.AppException;
end;

procedure Pump;
var
  I: Integer;
begin
  for I := 1 to 15 do
  begin
    Application.ProcessMessages;
    Sleep(20);
  end;
end;

procedure Capture(AForm: TForm; const AName: string);
var
  Bmp: TBitmap;
  R: TRect;
begin
  Pump;
  GetWindowRect(AForm.Handle, R);
  Bmp := TBitmap.Create;
  try
    Bmp.PixelFormat := pf24bit;
    Bmp.SetSize(R.Right - R.Left, R.Bottom - R.Top);
    Bmp.Canvas.Brush.Color := clWhite;
    Bmp.Canvas.FillRect(Rect(0, 0, Bmp.Width, Bmp.Height));
    PrintWindow(AForm.Handle, Bmp.Canvas.Handle, PW_RENDERFULLCONTENT);
    Bmp.SaveToFile(OutDir + AName + '.bmp');
  finally
    Bmp.Free;
  end;
end;

procedure RunSelfTest;
var
  Out: TStringList;
  AllOk: Boolean;
  Main2: TMain2Form;
  Skipped, Brands, Models: Integer;
  Error: string;
  Devices: TUsbDeviceArray;
  I: Integer;

  procedure Check(const AName: string; const AOk: Boolean);
  begin
    if AOk then
      Out.Add('PASS  ' + AName)
    else
    begin
      Out.Add('FAIL  ' + AName);
      AllOk := False;
    end;
  end;

begin
  AllOk := True;
  ForceDirectories(OutDir);
  Out := TStringList.Create;
  try
    try
      Out.Add(AppTitle + '  ' + AppVersionText);
      Out.Add('Data folder: ' + DataDir);

      { catalog: export, load back, compare }
      Brands := TDeviceCatalog.BrandCount;
      Models := TDeviceCatalog.TotalModels;
      Check('built-in catalog has brands and models', (Brands > 0) and (Models > 0));
      TDeviceCatalog.ExportToFile(OutDir + 'models.csv');
      Check('models.csv loads back',
        TDeviceCatalog.LoadFromFile(OutDir + 'models.csv', Skipped, Error));
      Check(Format('models.csv round trip (%d brands, %d models, %d skipped)',
        [TDeviceCatalog.BrandCount, TDeviceCatalog.TotalModels, Skipped]),
        (TDeviceCatalog.BrandCount = Brands) and
        (TDeviceCatalog.TotalModels = Models) and (Skipped = 0));
      Check('Realme present after reload',
        TDeviceCatalog.FindBrand('Realme') >= 0);
      TDeviceCatalog.ResetToBuiltIn;

      { USB / SetupAPI }
      Check(Format('SetupAPI lists present devices (%d)', [CountPresentDevices]),
        CountPresentDevices > 0);
      Devices := ScanServiceDevices;
      Out.Add(Format('INFO  %d phone(s) in service mode', [Length(Devices)]));
      for I := 0 to High(Devices) do
        Out.Add('INFO  ' + DescribeDevice(Devices[I]));

      { MAIN 1 }
      frmMain.Show;
      Capture(frmMain, 'main1');
      frmMain.cbSearch.Text := 'RMX35';
      frmMain.cbSearchChange(nil);
      Check(Format('MAIN 1 search "RMX35" finds models (%d)',
        [frmMain.lstModels.Items.Count]), frmMain.lstModels.Items.Count > 0);
      Capture(frmMain, 'main1-search');
      frmMain.cbSearch.Text := '';
      frmMain.cbSearchChange(nil);

      { MAIN 2 }
      Main2 := TMain2Form.Create(frmMain);
      try
        Main2.SetDevice('Realme', 'RMX3511 : Realme C35');
        Main2.Show;
        Pump;
        Check('MAIN 2 self-test', Main2.SelfTest(Out));
        Main2.ShowDemoLog;
        Main2.pcOperations.ActivePage := Main2.tsFlash;
        Capture(Main2, 'main2-flash');
        Main2.pcOperations.ActivePage := Main2.tsRead;
        Capture(Main2, 'main2-read');
        Main2.Progress := 40;
        Main2.chkAdvancedWrite.Checked := True;
        Main2.pcOperations.ActivePage := Main2.tsFlash;
        Capture(Main2, 'main2-flash-advanced');
        Main2.Progress := 0;
        Main2.chkAdvancedWrite.Checked := False;
      finally
        Main2.Free;  { saves settings + session log }
      end;
      Check('session log saved in logs folder',
        FileExists(SettingsFileName) and DirectoryExists(LogsDir));
    except
      on E: Exception do
      begin
        Out.Add('EXCEPTION ' + E.ClassName + ': ' + E.Message);
        AllOk := False;
      end;
    end;
    if AllOk then
      Out.Add('SELFTEST OK')
    else
      Out.Add('SELFTEST FAILED');
    Out.SaveToFile(OutDir + 'selftest.log');
  finally
    Out.Free;
  end;
  if AllOk then
    ExitCode := 0
  else
    ExitCode := 1;
end;

initialization

finalization
  GHandler.Free;

end.
