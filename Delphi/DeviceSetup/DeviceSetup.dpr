program DeviceSetup;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {frmMain},
  Main2Form in 'Main2Form.pas' {frmMain2},
  DeviceCatalog in 'DeviceCatalog.pas',
  ToolbarIcons in 'ToolbarIcons.pas',
  AppSettings in 'AppSettings.pas',
  DeviceWatch in 'DeviceWatch.pas';

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Mobile Servicing Tools';
  Application.CreateForm(TMainForm, frmMain);
  { Unexpected errors are written to %APPDATA%\MobileServicingTools\logs
    instead of only showing a raw Windows error. }
  Application.OnException := frmMain.HandleAppException;
  Application.Run;
end.
