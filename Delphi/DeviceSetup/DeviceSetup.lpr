program DeviceSetup;

{ Lazarus / Free Pascal entry point. Uses the same units as DeviceSetup.dpr
  (Delphi). The .lfm form files are generated from the .dfm files by
  tools/dfm2lfm.py before building.

  "DeviceSetup.exe /selftest" builds both forms, checks the catalog and exits
  with 0 (or 1 plus an error report in the log folder). The build pipeline runs
  it, because a form-streaming problem is invisible to the compiler. }

{$MODE DELPHI}

uses
  Interfaces,
  Forms,
  MainForm,
  Main2Form,
  DeviceCatalog,
  ToolbarIcons,
  AppSettings,
  DeviceWatch;

begin
  if SelfTestRequested then
    Halt(RunSelfTest);

  RequireDerivedFormResource := True;
  Application.Title := 'Mobile Servicing Tools';
  Application.Initialize;
  Application.MainFormOnTaskBar := True;
  Application.CreateForm(TMainForm, frmMain);
  { Unexpected errors are written to %APPDATA%/MobileServicingTools/logs
    instead of only showing a raw Windows error. }
  Application.OnException := frmMain.HandleAppException;
  Application.Run;
end.
