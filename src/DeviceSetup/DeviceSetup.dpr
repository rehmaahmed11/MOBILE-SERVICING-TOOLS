program DeviceSetup;

uses
  Vcl.Forms,
  AppInfo in 'AppInfo.pas',
  DaLoader in 'DaLoader.pas',
  MainForm in 'MainForm.pas' {frmMain},
  Main2Form in 'Main2Form.pas' {frmMain2},
  DeviceCatalog in 'DeviceCatalog.pas',
  ToolbarIcons in 'ToolbarIcons.pas',
  LogView in 'LogView.pas',
  UsbDetect in 'UsbDetect.pas',
  SettingsDialog in 'SettingsDialog.pas',
  SelfTest in 'SelfTest.pas',
  DevTypes in 'DevTypes.pas',
  CommPort in 'CommPort.pas',
  DevNotify in 'DevNotify.pas',
  DevCapture in 'DevCapture.pas',
  MtkChips in 'MtkChips.pas',
  MtkStatus in 'MtkStatus.pas',
  BromProtocol in 'BromProtocol.pas',
  DaImage in 'DaImage.pas',
  MtkDaLegacy in 'MtkDaLegacy.pas',
  SimPort in 'SimPort.pas',
  ScatterFile in 'ScatterFile.pas',
  SaharaProtocol in 'SaharaProtocol.pas',
  AdbTool in 'AdbTool.pas',
  DeviceSession in 'DeviceSession.pas',
  UnimplementedJobs in 'UnimplementedJobs.pas',
  AndroidJobs in 'AndroidJobs.pas',
  JobEngine in 'JobEngine.pas',
  CaptureForm in 'CaptureForm.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Mobile Servicing Tools';
  if SelfTestRequested then
  begin
    InstallSelfTestHandler;
    try
      Application.CreateForm(TMainForm, frmMain);
    except
      on E: TObject do
      begin
        ReportSelfTestCrash('creating MAIN 1', E);
        Halt(4);
      end;
    end;
    RunSelfTest;
  end
  else
  begin
    Application.CreateForm(TMainForm, frmMain);
    Application.Run;
  end;
end.
