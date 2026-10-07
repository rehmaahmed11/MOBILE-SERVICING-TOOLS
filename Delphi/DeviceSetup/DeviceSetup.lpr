program DeviceSetup;

{ Lazarus / Free Pascal entry point. Uses the same units as DeviceSetup.dpr
  (Delphi). The .lfm form files are generated from the .dfm files by
  tools/dfm2lfm.py before building. }

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
