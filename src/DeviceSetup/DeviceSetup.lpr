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
  DaLoader,
  MainForm,
  Main2Form,
  DeviceCatalog,
  ToolbarIcons,
  LogView,
  UsbDetect,
  SettingsDialog,
  SelfTest,
  { device layer: capture, exclusive port lock, protocols, job engine }
  DevTypes,
  CommPort,
  UsbRaw,
  DevNotify,
  DevCapture,
  MtkChips,
  MtkStatus,
  BromProtocol,
  DaImage,
  MtkDaLegacy,
  SimPort,
  ScatterFile,
  SaharaProtocol,
  AdbTool,
  DeviceSession,
  UnimplementedJobs,
  AndroidJobs,
  JobEngine,
  CaptureForm;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title := 'Mobile Servicing Tools';
  Application.Scaled := True;
  Application.Initialize;
  Application.MainFormOnTaskBar := True;
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
