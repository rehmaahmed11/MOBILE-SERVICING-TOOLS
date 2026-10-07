program DeviceSetup;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {frmMain},
  Main2Form in 'Main2Form.pas' {frmMain2},
  DeviceCatalog in 'DeviceCatalog.pas';

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Mobile Servicing Tools';
  Application.CreateForm(TMainForm, frmMain);
  Application.Run;
end.
