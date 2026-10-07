program DeviceSetup;

uses
  Vcl.Forms,
  AppInfo in 'AppInfo.pas',
  MainForm in 'MainForm.pas' {frmMain},
  Main2Form in 'Main2Form.pas' {frmMain2},
  DeviceCatalog in 'DeviceCatalog.pas',
  ToolbarIcons in 'ToolbarIcons.pas',
  LogView in 'LogView.pas',
  UsbDetect in 'UsbDetect.pas',
  SettingsDialog in 'SettingsDialog.pas',
  SelfTest in 'SelfTest.pas';

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
