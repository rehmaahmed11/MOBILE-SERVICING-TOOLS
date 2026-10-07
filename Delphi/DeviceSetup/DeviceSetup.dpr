program DeviceSetup;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas';

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Mobile Servicing Tools';
  Application.CreateForm(TMainForm, frmMain);
  Application.Run;
end.
