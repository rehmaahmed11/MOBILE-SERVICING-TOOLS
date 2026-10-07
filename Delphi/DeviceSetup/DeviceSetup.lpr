program DeviceSetup;

{ Lazarus / Free Pascal entry point. Uses the same units as DeviceSetup.dpr
  (Delphi). The .lfm form files are generated from the .dfm files by
  tools/dfm2lfm.py before building. Icon, version info and the DPI-aware
  manifest come from DeviceSetup.lpi (compiled into DeviceSetup.res). }

{$MODE DELPHI}

uses
  Interfaces,
  Forms,
  AppInfo,
  MainForm,
  Main2Form,
  DeviceCatalog,
  ToolbarIcons,
  LogView,
  UsbDetect,
  SettingsDialog,
  SelfTest;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title := 'Mobile Servicing Tools';
  Application.Scaled := True;
  Application.Initialize;
  Application.MainFormOnTaskBar := True;
  if SelfTestRequested then
    InstallSelfTestHandler;
  Application.CreateForm(TMainForm, frmMain);
  if SelfTestRequested then
    RunSelfTest
  else
    Application.Run;
end.
