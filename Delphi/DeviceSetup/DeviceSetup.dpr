program DeviceSetup;

{ Delphi / RAD Studio entry point. The Lazarus equivalent is DeviceSetup.lpr,
  which uses exactly the same units.

  "DeviceSetup.exe /selftest" builds both forms, checks the catalog and exits
  with 0 (or 1 plus an error report in the log folder). The build pipeline runs
  it, because a form-streaming problem is invisible to the compiler. }

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {frmMain},
  Main2Form in 'Main2Form.pas' {frmMain2},
  DeviceCatalog in 'DeviceCatalog.pas',
  ToolbarIcons in 'ToolbarIcons.pas',
  AppSettings in 'AppSettings.pas',
  DeviceWatch in 'DeviceWatch.pas';

begin
  if SelfTestRequested then
    Halt(RunSelfTest);

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Mobile Servicing Tools';
  Application.CreateForm(TMainForm, frmMain);
  { Unexpected errors are written to %APPDATA%\MobileServicingTools\logs
    instead of only showing a raw Windows error. }
  Application.OnException := frmMain.HandleAppException;
  Application.Run;
end.
