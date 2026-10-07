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
  Windows, Classes, SysUtils, Types, Forms, Controls, Graphics,
{$ELSE}
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  System.Types,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Forms,
{$ENDIF}
  SampleControls,
  SampleAssets,
  AppInfo,
  DeviceCatalog,
  UsbDetect,
  MainForm,
  Main2Form;

const
  PW_CLIENTONLY = 1;
  PW_RENDERFULLCONTENT = 2;

function PrintWindow(hwnd: HWND; hdcBlt: HDC; nFlags: UINT): BOOL; stdcall;
  external 'user32.dll' name 'PrintWindow';

type
  TSelfTestHandler = class
    ButtonClicks: Integer;
    procedure ButtonClicked(Sender: TObject);
    procedure AppException(Sender: TObject; E: Exception);
  end;

  TButtonInteractionProbe = class(TSampleButton)
  public
    procedure PressKey(const AKey: Word);
    procedure ReleaseKey(const AKey: Word);
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

procedure TSelfTestHandler.ButtonClicked(Sender: TObject);
begin
  Inc(ButtonClicks);
end;

procedure TButtonInteractionProbe.PressKey(const AKey: Word);
var
  K: Word;
begin
  K := AKey;
  KeyDown(K, []);
end;

procedure TButtonInteractionProbe.ReleaseKey(const AKey: Word);
var
  K: Word;
begin
  K := AKey;
  KeyUp(K, []);
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

{ Captures the window with plain GDI calls and writes a 24-bit BMP
  (an LCL TBitmap does not pick up what PrintWindow draws into its DC). }
procedure Capture(AForm: TForm; const AName: string;
  const AIncludePopup: Boolean = False);
var
  R: TRect;
  Origin: TPoint;
  W, H, RowSize: Integer;
  ScreenDC, MemDC: HDC;
  Bmp, OldBmp: HBITMAP;
  Info: TBitmapInfo;
  Pixels: array of Byte;
  FileHdr: TBitmapFileHeader;
  Stream: TFileStream;
begin
  AForm.BringToFront;
  Pump;
  { References are client-area crops, not windows with a title bar. }
  GetClientRect(AForm.Handle, R);
  Origin := AForm.ClientToScreen(Point(0, 0));
  W := R.Right - R.Left;
  H := R.Bottom - R.Top;
  if (W <= 0) or (H <= 0) then
    Exit;
  ScreenDC := GetDC(0);
  MemDC := CreateCompatibleDC(ScreenDC);
  Bmp := CreateCompatibleBitmap(ScreenDC, W, H);
  OldBmp := SelectObject(MemDC, Bmp);
  try
    if AIncludePopup then
      BitBlt(MemDC, 0, 0, W, H, ScreenDC, Origin.X, Origin.Y, SRCCOPY)
    else if not PrintWindow(AForm.Handle, MemDC,
      PW_CLIENTONLY or PW_RENDERFULLCONTENT) then
      BitBlt(MemDC, 0, 0, W, H, ScreenDC, Origin.X, Origin.Y, SRCCOPY);
    SelectObject(MemDC, OldBmp);

    FillChar(Info, SizeOf(Info), 0);
    Info.bmiHeader.biSize := SizeOf(TBitmapInfoHeader);
    Info.bmiHeader.biWidth := W;
    Info.bmiHeader.biHeight := H;  { bottom-up, as BMP files expect }
    Info.bmiHeader.biPlanes := 1;
    Info.bmiHeader.biBitCount := 24;
    Info.bmiHeader.biCompression := BI_RGB;
    RowSize := ((W * 3) + 3) and not 3;
    SetLength(Pixels, RowSize * H);
    GetDIBits(MemDC, Bmp, 0, H, @Pixels[0], Info, DIB_RGB_COLORS);

    FillChar(FileHdr, SizeOf(FileHdr), 0);
    FileHdr.bfType := $4D42;  { 'BM' }
    FileHdr.bfOffBits := SizeOf(TBitmapFileHeader) + SizeOf(TBitmapInfoHeader);
    FileHdr.bfSize := FileHdr.bfOffBits + DWORD(Length(Pixels));
    Stream := TFileStream.Create(OutDir + AName + '.bmp', fmCreate);
    try
      Stream.WriteBuffer(FileHdr, SizeOf(FileHdr));
      Stream.WriteBuffer(Info.bmiHeader, SizeOf(TBitmapInfoHeader));
      Stream.WriteBuffer(Pixels[0], Length(Pixels));
    finally
      Stream.Free;
    end;
  finally
    DeleteObject(Bmp);
    DeleteDC(MemDC);
    ReleaseDC(0, ScreenDC);
  end;
end;

{ Actual runtime bounds, not just successful compilation. This catches
  native-widget sizing, LCL offsets, hidden final tabs and bottom clipping. }
function CheckLayout(AForm: TForm; AOut: TStrings; const AState: string): Boolean;
var
  I: Integer;
  C: TControl;
  M: TMain2Form;
  R: TRect;
begin
  Result := True;
  for I := 0 to AForm.ComponentCount - 1 do
    if (AForm.Components[I] is TSampleButton) or
       (AForm.Components[I] is TSampleGroupBox) then
    begin
      C := TControl(AForm.Components[I]);
      if not C.Visible or (C.Parent = nil) then
        Continue;
      if (C.Left < 0) or (C.Top < 0) or
         (C.Left + C.Width > C.Parent.ClientWidth) or
         (C.Top + C.Height > C.Parent.ClientHeight) then
      begin
        AOut.Add(Format('FAIL  %s: %s [%d,%d,%d,%d] outside %s [%d,%d]',
          [AState, C.Name, C.Left, C.Top, C.Width, C.Height, C.Parent.Name,
           C.Parent.ClientWidth, C.Parent.ClientHeight]));
        Result := False;
      end;
    end;
  if AForm is TMain2Form then
  begin
    M := TMain2Form(AForm);
    for I := 0 to M.pcOperations.PageCount - 1 do
    begin
      R := M.pcOperations.TabRect(I);
      if (R.Right > M.pcOperations.ClientWidth) or (R.Bottom <= R.Top) then
      begin
        AOut.Add('FAIL  ' + AState + ': operation tab clipped: ' +
          M.pcOperations.Pages[I].Caption);
        Result := False;
      end;
    end;
  end;
  if Result then
    AOut.Add('PASS  ' + AState + ': controls and all tabs fit');
end;

procedure RunSelfTest;
var
  Out: TStringList;
  AllOk: Boolean;
  Main2, Dpi2: TMain2Form;
  ButtonProbe: TButtonInteractionProbe;
  Measure: TBitmap;
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
      I := TDeviceCatalog.FindBrand('Alps');
      Check('empty sample brand categories survive CSV round trip',
        (I >= 0) and (TDeviceCatalog.ModelCount(I) = 0));
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
      Pump;
      Check('MAIN 1 brand list starts at Alcatel like S1',
        (frmMain.lstBrands.TopIndex = 0) and
        (frmMain.lstBrands.Items[0] = 'Alcatel'));
      Check('MAIN 1 client matches S1 (1023x575)',
        (frmMain.ClientWidth = 1023) and (frmMain.ClientHeight = 575));
      Check('MAIN 1 uses the original OPPO wordmark',
        (SampleBitmap('UI_OPPO').Width = 270) and
        (frmMain.lstBrands.Items[frmMain.lstBrands.ItemIndex] = 'Oppo'));
      Check('MAIN 1 layout', CheckLayout(frmMain, Out, 'MAIN 1 / 96 DPI'));
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
        Check('MAIN 2 client matches the base sample (1026x585)',
          (Main2.ClientWidth = 1026) and (Main2.ClientHeight = 585));
        Check('MAIN 2 layout', CheckLayout(Main2, Out, 'MAIN 2 / 96 DPI'));
        Check('MAIN 2 idle log is empty', Main2.lstLog.Items.Count = 0);
        Measure := TBitmap.Create;
        try
          Measure.SetSize(1, 1);
          Measure.Canvas.Font.Assign(Main2.edtImei1.Font);
          Check('all 14 IMEI digits fit in the visible input',
            Measure.Canvas.TextWidth(Main2.edtImei1.Text) <=
            Main2.edtImei1.ClientWidth);
        finally
          Measure.Free;
        end;
        Check('both independent Format radio groups retain their selection',
          Main2.rbAutoFormat.Checked and Main2.rbFormatAiFlash.Checked and
          (Main2.rbAutoFormat.Parent <> Main2.rbFormatAiFlash.Parent));
        Check('connection defaults match the samples',
          Main2.chkAuthBrom.Checked and not Main2.chkAuthPreloader.Checked and
          (Main2.cbUsbSpeed.Text = 'High speed') and
          (Main2.cbBattery.Text = 'With battery'));

        { Capture clean, real UI states first. Functional tests and the demo
          log used to pollute every reference screenshot with error output. }
        Main2.pcJobs.ActivePage := Main2.tsJobs;
        Main2.pcOperations.ActivePage := Main2.tsImei;
        Capture(Main2, 'main2-imei');                  { S2 / S7 }
        Main2.pcOperations.ActivePage := Main2.tsFlash;
        Capture(Main2, 'main2-flash');                 { S3 }
        Main2.cbFlashMode.DroppedDown := True;
        Capture(Main2, 'main2-flash-modes', True);      { S4 }
        Main2.cbFlashMode.DroppedDown := False;
        Main2.pcOperations.ActivePage := Main2.tsRead;
        Capture(Main2, 'main2-read');                  { S5 }
        Main2.pcOperations.ActivePage := Main2.tsFormat;
        Capture(Main2, 'main2-format');                { S6 }
        Main2.pcOperations.ActivePage := Main2.tsLocks;
        Capture(Main2, 'main2-locks');                 { S8 }
        Main2.pcOperations.ActivePage := Main2.tsService;
        Capture(Main2, 'main2-service');               { S9 }
        Main2.pcOperations.ActivePage := Main2.tsRpmb;
        Capture(Main2, 'main2-rpmb');                  { S10 }
        Main2.pcJobs.ActivePage := Main2.tsMeta;
        Capture(Main2, 'main2-meta');
        Main2.cbPlatform.ItemIndex := 1;
        Main2.cbPlatformChange(nil);
        Capture(Main2, 'main2-unisoc-diag');
        Main2.cbPlatform.ItemIndex := 0;
        Main2.cbPlatformChange(nil);
        Main2.pcJobs.ActivePage := Main2.tsJobs;
        Main2.chkAdvancedWrite.Checked := True;
        Main2.chkAdvancedWriteClick(nil);
        Main2.pcOperations.ActivePage := Main2.tsFlash;
        Capture(Main2, 'main2-flash-advanced');
        Main2.chkAdvancedWrite.Checked := False;
        Main2.chkAdvancedWriteClick(nil);
        Main2.pcOperations.ActivePage := Main2.tsImei;
        Main2.Progress := 40;
        Capture(Main2, 'main2-progress');
        Main2.Progress := 0;

        Check('MAIN 2 self-test', Main2.SelfTest(Out));
        ButtonProbe := TButtonInteractionProbe.Create(nil);
        try
          ButtonProbe.Parent := Main2;
          ButtonProbe.Visible := False;
          ButtonProbe.OnClick := GHandler.ButtonClicked;
          GHandler.ButtonClicks := 0;
          ButtonProbe.PressKey(VK_RETURN);
          Check('sample action button activates with Enter', GHandler.ButtonClicks = 1);
          ButtonProbe.PressKey(VK_SPACE);
          Check('Space waits for key release', GHandler.ButtonClicks = 1);
          ButtonProbe.ReleaseKey(VK_SPACE);
          Check('sample action button activates with Space', GHandler.ButtonClicks = 2);
          ButtonProbe.Enabled := False;
          ButtonProbe.PressKey(VK_RETURN);
          Check('disabled sample action button does not activate', GHandler.ButtonClicks = 2);
          Check('Enter is requested by the button dialog-key handler',
            (SendMessage(ButtonProbe.Handle, WM_GETDLGCODE, VK_RETURN, 0) and
             DLGC_WANTALLKEYS) <> 0);
          Check('sample action buttons preserve Tab navigation',
            (SendMessage(ButtonProbe.Handle, WM_GETDLGCODE, VK_TAB, 0) and
             DLGC_WANTTAB) = 0);
        finally
          ButtonProbe.Free;
        end;
        Main2.miClearLogClick(nil);
        Main2.ShowDemoLog;
        Capture(Main2, 'main2-log');
        Main2.miClearLogClick(nil);

        { Larger font/layout scales also keep RPMB and the last Format job
          visible. These are additional checks, not replacements for the
          reference-size captures. }
        Main2.pcOperations.ActivePage := Main2.tsFormat;
        Main2.ScaleBy(3, 2);
        Main2.FormResize(nil);
        Pump;
        Check('MAIN 2 144-DPI layout', CheckLayout(Main2, Out, 'MAIN 2 / 144 DPI'));
        Capture(Main2, 'main2-dpi144');
        { A fresh 2x scale models a real 192-DPI startup rather than
          accumulating rounding errors from 96 -> 144 -> 192. }
        Dpi2 := TMain2Form.Create(frmMain);
        try
          Dpi2.SetDevice('Realme', 'RMX3511 : Realme C35');
          Dpi2.Show;
          Dpi2.pcOperations.ActivePage := Dpi2.tsFormat;
          Dpi2.ScaleBy(2, 1);
          Dpi2.FormResize(nil);
          Pump;
          Check('MAIN 2 192-DPI layout', CheckLayout(Dpi2, Out, 'MAIN 2 / 192 DPI'));
          Capture(Dpi2, 'main2-dpi192');
        finally
          Dpi2.Free;
        end;
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
