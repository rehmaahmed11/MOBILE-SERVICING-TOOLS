unit SettingsDialog;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


{ Settings window (gear icon on MAIN 2). Built in code, so there is no
  form file to keep in sync between Delphi and Lazarus. Edits GOptions. }

interface

uses
{$IFDEF FPC}
  Classes, Forms;
{$ELSE}
  System.Classes,
  Vcl.Forms;
{$ENDIF}

{ True when the user pressed OK (GOptions is then updated and saved). }
function ShowSettingsDialog(AOwner: TComponent): Boolean;

implementation

uses
{$IFDEF FPC}
  Windows, SysUtils, Controls, StdCtrls, Dialogs, ShellApi,
{$ELSE}
  Winapi.Windows,
  Winapi.ShellAPI,
  System.SysUtils,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.Dialogs,
{$ENDIF}
  AppInfo;

type
  TSettingsForm = class(TForm)
  private
    FTime, FAutoSave, FRemember, FUsb: TCheckBox;
    FInfo: TLabel;
    procedure OpenFolderClick(Sender: TObject);
    function S(const AValue: Integer): Integer;
    function AddCheck(const ATop: Integer; const ACaption: string;
      const AChecked: Boolean): TCheckBox;
    function AddButton(const ALeft, ATop, AWidth: Integer;
      const ACaption: string): TButton;
  public
    constructor CreateDialog(AOwner: TComponent);
  end;

function TSettingsForm.S(const AValue: Integer): Integer;
begin
  { controls made in code are not scaled automatically on high-DPI screens }
  Result := MulDiv(AValue, Screen.PixelsPerInch, 96);
end;

function TSettingsForm.AddCheck(const ATop: Integer; const ACaption: string;
  const AChecked: Boolean): TCheckBox;
begin
  Result := TCheckBox.Create(Self);
  Result.Parent := Self;
  Result.SetBounds(S(16), S(ATop), S(330), S(20));
  Result.Caption := ACaption;
  Result.Checked := AChecked;
end;

function TSettingsForm.AddButton(const ALeft, ATop, AWidth: Integer;
  const ACaption: string): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := Self;
  Result.SetBounds(S(ALeft), S(ATop), S(AWidth), S(25));
  Result.Caption := ACaption;
end;

constructor TSettingsForm.CreateDialog(AOwner: TComponent);
var
  Btn: TButton;
begin
  inherited CreateNew(AOwner);
  Caption := 'Settings';
  BorderStyle := bsDialog;
  Position := poOwnerFormCenter;
  ClientWidth := S(362);
  ClientHeight := S(206);
  Font.Name := 'Tahoma';
  Font.Size := 8;

  FTime := AddCheck(14, 'Show the time in front of every log line',
    GOptions.ShowTimeInLog);
  FAutoSave := AddCheck(38, 'Save every session log to the "logs" folder',
    GOptions.AutoSaveLog);
  FRemember := AddCheck(62, 'Remember file paths and job options',
    GOptions.RememberFiles);
  FUsb := AddCheck(86, 'Detect phones connected by USB (read only)',
    GOptions.DetectUsb);

  FInfo := TLabel.Create(Self);
  FInfo.Parent := Self;
  FInfo.SetBounds(S(16), S(116), S(330), S(30));
  FInfo.AutoSize := False;
  FInfo.WordWrap := True;
  FInfo.Caption := 'Settings and logs are kept in: ' + DataDir;

  Btn := AddButton(16, 168, 120, 'Open data folder');
  Btn.OnClick := OpenFolderClick;

  Btn := AddButton(196, 168, 72, 'OK');
  Btn.ModalResult := mrOk;
  Btn.Default := True;

  Btn := AddButton(274, 168, 72, 'Cancel');
  Btn.ModalResult := mrCancel;
  Btn.Cancel := True;
end;

procedure TSettingsForm.OpenFolderClick(Sender: TObject);
begin
  ForceDirectories(DataDir);
  ShellExecute(Handle, 'open', PChar(DataDir), nil, nil, SW_SHOWNORMAL);
end;

function ShowSettingsDialog(AOwner: TComponent): Boolean;
var
  F: TSettingsForm;
begin
  F := TSettingsForm.CreateDialog(AOwner);
  try
    Result := F.ShowModal = mrOk;
    if Result then
    begin
      GOptions.ShowTimeInLog := F.FTime.Checked;
      GOptions.AutoSaveLog := F.FAutoSave.Checked;
      GOptions.RememberFiles := F.FRemember.Checked;
      GOptions.DetectUsb := F.FUsb.Checked;
      SaveOptions;
    end;
  finally
    F.Free;
  end;
end;

end.
