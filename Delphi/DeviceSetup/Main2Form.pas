unit Main2Form;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


{ MAIN 2 - opened from MAIN 1 when the user presses Next.
  Layout follows the MAIN 2 reference screenshot:
    - toolbar: menu (left); next, save, change device, settings,
      Facebook and help (right)
    - left: Presets, Files (SCAT / AUTH / BIN / OFP), Log
    - right: Jobs / META tabs with Connections and Storage groups, then the
      Flash / Read / Format / IMEI / Locks / Service / RPMB tabs
    - red progress bar along the bottom
  Device communication (flashing, reading, etc.) is NOT implemented here:
  the action buttons check their inputs and write to the log. }

interface

uses
{$IFDEF FPC}
  Windows, LCLType, Classes, SysUtils, Types,
  Buttons, ComCtrls, Controls, Dialogs, ExtCtrls, Forms, Graphics, Menus,
  StdCtrls,
{$ELSE}
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  System.Types,
  Vcl.Buttons,
  Vcl.ComCtrls,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.Menus,
  Vcl.StdCtrls,
{$ENDIF}
  ToolbarIcons;

type
  TMain2Form = class(TForm)
    { toolbar }
    pbMenu: TPaintBox;
    pbNext: TPaintBox;
    pbDownload: TPaintBox;
    pbChangeDevice: TPaintBox;
    pbSettings: TPaintBox;
    pbFacebook: TPaintBox;
    pbHelp: TPaintBox;
    pmMain: TPopupMenu;
    miChangeDevice: TMenuItem;
    miSaveLog: TMenuItem;
    miClearLog: TMenuItem;
    miSeparator: TMenuItem;
    miExit: TMenuItem;
    { left side }
    lblPresets: TLabel;
    bvlPresets: TBevel;
    cbPresets: TComboBox;
    lblFiles: TLabel;
    bvlFiles: TBevel;
    btnScat: TButton;
    edtScat: TEdit;
    btnAuth: TButton;
    edtAuth: TEdit;
    btnBin: TButton;
    edtBin: TEdit;
    btnOfp: TButton;
    edtOfp: TEdit;
    lblLog: TLabel;
    bvlLog: TBevel;
    memLog: TMemo;
    pbProgress: TPaintBox;
    { right side - Jobs / META }
    pcJobs: TPageControl;
    tsJobs: TTabSheet;
    tsMeta: TTabSheet;
    grpConnections: TGroupBox;
    lblDownloadAgent: TLabel;
    cbDownloadAgent: TComboBox;
    chkAuthBrom: TCheckBox;
    chkAuthPreloader: TCheckBox;
    chkForceBrom: TCheckBox;
    chkReadEmi: TCheckBox;
    chkReadPhoneInfo: TCheckBox;
    lblUsbSpeed: TLabel;
    cbUsbSpeed: TComboBox;
    lblBattery: TLabel;
    cbBattery: TComboBox;
    grpStorage: TGroupBox;
    lblStorageType: TLabel;
    cbStorageType: TComboBox;
    lblRegion: TLabel;
    cbRegion: TComboBox;
    lblMetaInfo: TLabel;
    { right side - operations }
    pcOperations: TPageControl;
    tsFlash: TTabSheet;
    tsRead: TTabSheet;
    tsFormat: TTabSheet;
    tsImei: TTabSheet;
    tsLocks: TTabSheet;
    tsService: TTabSheet;
    tsRpmb: TTabSheet;
    grpOptions: TGroupBox;
    cbFlashMode: TComboBox;
    btnWriteFirmware: TBitBtn;
    btnRestoreBackup: TBitBtn;
    chkAdvancedWrite: TCheckBox;
    lblAddress: TLabel;
    edtAddress: TEdit;
    btnWriteBin: TBitBtn;
    btnWriteOfp: TBitBtn;
    lblReadInfo: TLabel;
    lblFormatInfo: TLabel;
    lblImeiInfo: TLabel;
    lblLocksInfo: TLabel;
    lblServiceInfo: TLabel;
    lblRpmbInfo: TLabel;
    { device state }
    pnlDeviceState: TPanel;
    pbDeviceState: TPaintBox;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure pbMenuPaint(Sender: TObject);
    procedure pbNextPaint(Sender: TObject);
    procedure pbDownloadPaint(Sender: TObject);
    procedure pbChangeDevicePaint(Sender: TObject);
    procedure pbSettingsPaint(Sender: TObject);
    procedure pbFacebookPaint(Sender: TObject);
    procedure pbHelpPaint(Sender: TObject);
    procedure pbProgressPaint(Sender: TObject);
    procedure pbDeviceStatePaint(Sender: TObject);
    procedure pbMenuClick(Sender: TObject);
    procedure pbNextClick(Sender: TObject);
    procedure pbDownloadClick(Sender: TObject);
    procedure pbChangeDeviceClick(Sender: TObject);
    procedure pbSettingsClick(Sender: TObject);
    procedure pbFacebookClick(Sender: TObject);
    procedure pbHelpClick(Sender: TObject);
    procedure miClearLogClick(Sender: TObject);
    procedure miExitClick(Sender: TObject);
    procedure btnScatClick(Sender: TObject);
    procedure btnAuthClick(Sender: TObject);
    procedure btnBinClick(Sender: TObject);
    procedure btnOfpClick(Sender: TObject);
    procedure cbStorageTypeChange(Sender: TObject);
    procedure chkAdvancedWriteClick(Sender: TObject);
    procedure btnWriteFirmwareClick(Sender: TObject);
    procedure btnRestoreBackupClick(Sender: TObject);
    procedure btnWriteBinClick(Sender: TObject);
    procedure btnWriteOfpClick(Sender: TObject);
  private
    FBrand: string;
    FModelCode: string;
    FModelName: string;
    FProgress: Integer;
    FDeviceConnected: Boolean;
    procedure AssignGlyph(AButton: TBitBtn; const AKind: TActionGlyph);
    procedure Log(const AText: string);
    procedure LogSettings;
    procedure LogNotImplemented(const AOperation: string);
    function BrowseFile(const ATitle, AFilter: string; AEdit: TEdit): Boolean;
    function RequireFile(AEdit: TEdit; const AName: string): Boolean;
    function ParseAddress(out AStart, ALength: UInt64): Boolean;
    procedure UpdateAdvancedWrite;
    procedure FillRegions;
    procedure SetProgress(const AValue: Integer);
  public
    procedure SetDevice(const ABrand, AModelEntry: string);
    property Progress: Integer read FProgress write SetProgress;
  end;

implementation

{$IFDEF FPC}
  {$R *.lfm}
{$ELSE}
  {$R *.dfm}
{$ENDIF}

uses
{$IFDEF FPC}
  ShellApi;
{$ELSE}
  Winapi.ShellAPI;
{$ENDIF}

const
  CFacebookUrl = 'https://www.facebook.com/';

{ ---------------------------------------------------------------- setup }

procedure TMain2Form.FormCreate(Sender: TObject);
begin
  pcJobs.ActivePage := tsJobs;
  pcOperations.ActivePage := tsFlash;

  AssignGlyph(btnWriteFirmware, agWriteFirmware);
  AssignGlyph(btnRestoreBackup, agRestore);
  AssignGlyph(btnWriteBin, agWriteBin);
  AssignGlyph(btnWriteOfp, agWriteOfp);

  FillRegions;
  UpdateAdvancedWrite;
  FProgress := 0;
  FDeviceConnected := False;
  memLog.Clear;
end;

procedure TMain2Form.AssignGlyph(AButton: TBitBtn; const AKind: TActionGlyph);
var
  Glyph: TBitmap;
begin
  Glyph := CreateActionGlyph(AKind);
  try
    AButton.Glyph.Assign(Glyph);
    AButton.NumGlyphs := 1;
  finally
    Glyph.Free;
  end;
end;

procedure TMain2Form.SetDevice(const ABrand, AModelEntry: string);
var
  SepPos: Integer;
begin
  { Model entries look like "RMX3382 : Realme 8s 5G". }
  FBrand := ABrand;
  SepPos := Pos(' : ', AModelEntry);
  if SepPos > 0 then
  begin
    FModelCode := Trim(Copy(AModelEntry, 1, SepPos - 1));
    FModelName := Trim(Copy(AModelEntry, SepPos + 3, MaxInt));
  end
  else
  begin
    FModelCode := '';
    FModelName := AModelEntry;
  end;

  Caption := 'Mobile Servicing Tools - ' + FModelName;
  memLog.Clear;
  Log('Brand : ' + FBrand);
  if FModelCode <> '' then
    Log('Model : ' + FModelCode + ' : ' + FModelName)
  else
    Log('Model : ' + FModelName);
end;

procedure TMain2Form.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    ModalResult := mrCancel;
  end;
end;

{ ---------------------------------------------------------------- log }

procedure TMain2Form.Log(const AText: string);
begin
  memLog.Lines.Add(AText);
  memLog.SelStart := Length(memLog.Text);
  memLog.SelLength := 0;
end;

procedure TMain2Form.LogSettings;
begin
  Log('Download agent : ' + cbDownloadAgent.Text);
  Log('USB speed : ' + cbUsbSpeed.Text + ',  Battery : ' + cbBattery.Text);
  Log('Storage : ' + cbStorageType.Text + ' / ' + cbRegion.Text);
end;

procedure TMain2Form.LogNotImplemented(const AOperation: string);
begin
  Log(AOperation + ' : device communication is not implemented in this build.');
  Log('');
end;

procedure TMain2Form.miClearLogClick(Sender: TObject);
begin
  memLog.Clear;
end;

{ ---------------------------------------------------------------- painting }

procedure TMain2Form.pbMenuPaint(Sender: TObject);
begin
  DrawMenuIcon(pbMenu.Canvas, pbMenu.ClientRect);
end;

procedure TMain2Form.pbNextPaint(Sender: TObject);
begin
  DrawNextIcon(pbNext.Canvas, pbNext.ClientRect, True);
end;

procedure TMain2Form.pbDownloadPaint(Sender: TObject);
begin
  DrawDownloadIcon(pbDownload.Canvas, pbDownload.ClientRect);
end;

procedure TMain2Form.pbChangeDevicePaint(Sender: TObject);
begin
  DrawPhoneRefreshIcon(pbChangeDevice.Canvas, pbChangeDevice.ClientRect);
end;

procedure TMain2Form.pbSettingsPaint(Sender: TObject);
begin
  DrawGearIcon(pbSettings.Canvas, pbSettings.ClientRect);
end;

procedure TMain2Form.pbFacebookPaint(Sender: TObject);
begin
  DrawFacebookIcon(pbFacebook.Canvas, pbFacebook.ClientRect);
end;

procedure TMain2Form.pbHelpPaint(Sender: TObject);
begin
  DrawHelpIcon(pbHelp.Canvas, pbHelp.ClientRect);
end;

procedure TMain2Form.pbDeviceStatePaint(Sender: TObject);
begin
  DrawDeviceStateIcon(pbDeviceState.Canvas, pbDeviceState.ClientRect,
    FDeviceConnected);
end;

procedure TMain2Form.pbProgressPaint(Sender: TObject);
var
  C: TCanvas;
  R: TRect;
  Mid, Fill, Knob: Integer;
begin
  C := pbProgress.Canvas;
  R := pbProgress.ClientRect;
  C.Brush.Style := bsSolid;
  C.Brush.Color := clBtnFace;
  C.FillRect(R);

  Mid := (R.Top + R.Bottom) div 2;
  Knob := 6;
  Fill := R.Left + Knob + MulDiv(R.Width - 2 * Knob, FProgress, 100);

  { track }
  C.Brush.Color := RGB(170, 170, 170);
  C.FillRect(Rect(R.Left, Mid - 2, R.Right, Mid + 2));
  { filled part: red, fading to pink at the leading edge }
  if Fill > R.Left then
  begin
    C.Brush.Color := RGB(232, 0, 18);
    C.FillRect(Rect(R.Left, Mid - 2, Fill, Mid + 2));
    if Fill - R.Left > 60 then
    begin
      C.Brush.Color := RGB(236, 20, 90);
      C.FillRect(Rect(Fill - 40, Mid - 2, Fill, Mid + 2));
    end;
  end;
  { knob }
  C.Pen.Color := RGB(210, 0, 18);
  C.Brush.Color := RGB(232, 0, 18);
  C.Ellipse(Fill - Knob, Mid - Knob, Fill + Knob, Mid + Knob);
end;

procedure TMain2Form.SetProgress(const AValue: Integer);
var
  V: Integer;
begin
  V := AValue;
  if V < 0 then
    V := 0;
  if V > 100 then
    V := 100;
  if V <> FProgress then
  begin
    FProgress := V;
    pbProgress.Invalidate;
  end;
end;

{ ---------------------------------------------------------------- toolbar }

procedure TMain2Form.pbMenuClick(Sender: TObject);
var
  P: TPoint;
begin
  P := pbMenu.ClientToScreen(Point(0, pbMenu.Height));
  pmMain.Popup(P.X, P.Y);
end;

procedure TMain2Form.pbNextClick(Sender: TObject);
begin
  { Runs the action of the Flash tab's main button. }
  pcJobs.ActivePage := tsJobs;
  pcOperations.ActivePage := tsFlash;
  btnWriteFirmwareClick(btnWriteFirmware);
end;

procedure TMain2Form.pbDownloadClick(Sender: TObject);
var
  Dialog: TSaveDialog;
begin
  Dialog := TSaveDialog.Create(Self);
  try
    Dialog.Title := 'Save log';
    Dialog.Filter := 'Text files (*.txt)|*.txt|All files (*.*)|*.*';
    Dialog.DefaultExt := 'txt';
    Dialog.Options := Dialog.Options + [ofOverwritePrompt];
    Dialog.FileName := 'log.txt';
    if Dialog.Execute then
      {$IFDEF FPC}
      memLog.Lines.SaveToFile(Dialog.FileName);  { LCL strings are UTF-8 }
      {$ELSE}
      memLog.Lines.SaveToFile(Dialog.FileName, TEncoding.UTF8);
      {$ENDIF}
  finally
    Dialog.Free;
  end;
end;

procedure TMain2Form.pbChangeDeviceClick(Sender: TObject);
begin
  { Back to MAIN 1 to pick another model. }
  ModalResult := mrCancel;
end;

procedure TMain2Form.pbSettingsClick(Sender: TObject);
begin
  MessageDlg('Settings are not available yet.', mtInformation, [mbOK], 0);
end;

procedure TMain2Form.pbFacebookClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', PChar(CFacebookUrl), nil, nil, SW_SHOWNORMAL);
end;

procedure TMain2Form.pbHelpClick(Sender: TObject);
begin
  MessageDlg('Mobile Servicing Tools' + sLineBreak + sLineBreak +
    'Selected device: ' + FBrand + ' ' + FModelName, mtInformation, [mbOK], 0);
end;

procedure TMain2Form.miExitClick(Sender: TObject);
begin
  Application.Terminate;
  ModalResult := mrCancel;
end;

{ ---------------------------------------------------------------- files }

function TMain2Form.BrowseFile(const ATitle, AFilter: string;
  AEdit: TEdit): Boolean;
var
  Dialog: TOpenDialog;
begin
  Dialog := TOpenDialog.Create(Self);
  try
    Dialog.Title := ATitle;
    Dialog.Filter := AFilter;
    Dialog.Options := Dialog.Options + [ofFileMustExist, ofPathMustExist];
    if AEdit.Text <> '' then
      Dialog.FileName := AEdit.Text;
    Result := Dialog.Execute;
    if Result then
      AEdit.Text := Dialog.FileName;
  finally
    Dialog.Free;
  end;
end;

procedure TMain2Form.btnScatClick(Sender: TObject);
begin
  if BrowseFile('Select scatter file',
    'Scatter files (*scatter*.txt;*.xml)|*scatter*.txt;*.xml|All files (*.*)|*.*',
    edtScat) then
    Log('Scatter file : ' + edtScat.Text);
end;

procedure TMain2Form.btnAuthClick(Sender: TObject);
begin
  if BrowseFile('Select auth file',
    'Auth files (*.auth;*.bin)|*.auth;*.bin|All files (*.*)|*.*', edtAuth) then
    Log('Auth file : ' + edtAuth.Text);
end;

procedure TMain2Form.btnBinClick(Sender: TObject);
begin
  if BrowseFile('Select BIN file',
    'Binary files (*.bin;*.img)|*.bin;*.img|All files (*.*)|*.*', edtBin) then
    Log('BIN file : ' + edtBin.Text);
end;

procedure TMain2Form.btnOfpClick(Sender: TObject);
begin
  if BrowseFile('Select OFP file',
    'OFP files (*.ofp)|*.ofp|All files (*.*)|*.*', edtOfp) then
    Log('OFP file : ' + edtOfp.Text);
end;

function TMain2Form.RequireFile(AEdit: TEdit; const AName: string): Boolean;
begin
  Result := (Trim(AEdit.Text) <> '') and FileExists(Trim(AEdit.Text));
  if not Result then
  begin
    if Trim(AEdit.Text) = '' then
      Log('Select a ' + AName + ' file first.')
    else
      Log(AName + ' file not found : ' + AEdit.Text);
    Log('');
  end;
end;

{ ---------------------------------------------------------------- options }

procedure TMain2Form.FillRegions;
begin
  cbRegion.Items.BeginUpdate;
  try
    cbRegion.Items.Clear;
    if SameText(cbStorageType.Text, 'UFS') then
    begin
      cbRegion.Items.Add('UFS_LU0');
      cbRegion.Items.Add('UFS_LU1');
      cbRegion.Items.Add('UFS_LU2');
    end
    else
    begin
      cbRegion.Items.Add('EMMC_USER');
      cbRegion.Items.Add('EMMC_BOOT1');
      cbRegion.Items.Add('EMMC_BOOT2');
      cbRegion.Items.Add('EMMC_RPMB');
    end;
  finally
    cbRegion.Items.EndUpdate;
  end;
  cbRegion.ItemIndex := 0;
end;

procedure TMain2Form.cbStorageTypeChange(Sender: TObject);
begin
  FillRegions;
end;

procedure TMain2Form.UpdateAdvancedWrite;
var
  Enable: Boolean;
begin
  Enable := chkAdvancedWrite.Checked;
  edtAddress.Enabled := Enable;
  btnWriteBin.Enabled := Enable;
  btnBin.Enabled := Enable;
  edtBin.Enabled := Enable;
end;

procedure TMain2Form.chkAdvancedWriteClick(Sender: TObject);
begin
  UpdateAdvancedWrite;
end;

function TryParseHex(const S: string; out AValue: UInt64): Boolean;
var
  I: Integer;
  Digit: Integer;
begin
  AValue := 0;
  Result := (Length(S) > 0) and (Length(S) <= 16);
  if not Result then
    Exit;
  for I := 1 to Length(S) do
  begin
    case S[I] of
      '0'..'9': Digit := Ord(S[I]) - Ord('0');
      'a'..'f': Digit := Ord(S[I]) - Ord('a') + 10;
      'A'..'F': Digit := Ord(S[I]) - Ord('A') + 10;
    else
      Result := False;
      Exit;
    end;
    AValue := (AValue shl 4) or UInt64(Digit);
  end;
end;

function TMain2Form.ParseAddress(out AStart, ALength: UInt64): Boolean;
var
  Clean: string;
  SpacePos: Integer;
begin
  AStart := 0;
  ALength := 0;
  Clean := Trim(edtAddress.Text);
  SpacePos := Pos(' ', Clean);
  Result := (SpacePos > 0) and
    TryParseHex(Trim(Copy(Clean, 1, SpacePos - 1)), AStart) and
    TryParseHex(Trim(Copy(Clean, SpacePos + 1, MaxInt)), ALength);
end;

{ ---------------------------------------------------------------- actions }

procedure TMain2Form.btnWriteFirmwareClick(Sender: TObject);
begin
  Log('[Write Firmware] ' + cbFlashMode.Text);
  if not RequireFile(edtScat, 'SCAT') then
    Exit;
  Log('Scatter file : ' + edtScat.Text);
  if Trim(edtAuth.Text) <> '' then
    Log('Auth file : ' + edtAuth.Text);
  LogSettings;
  LogNotImplemented('Write Firmware');
end;

procedure TMain2Form.btnRestoreBackupClick(Sender: TObject);
var
  Dialog: TOpenDialog;
begin
  Log('[Restore from backup]');
  Dialog := TOpenDialog.Create(Self);
  try
    Dialog.Title := 'Select backup file';
    Dialog.Filter := 'Backup files (*.bin;*.img;*.zip)|*.bin;*.img;*.zip|All files (*.*)|*.*';
    Dialog.Options := Dialog.Options + [ofFileMustExist, ofPathMustExist];
    if not Dialog.Execute then
    begin
      Log('Cancelled.');
      Log('');
      Exit;
    end;
    Log('Backup file : ' + Dialog.FileName);
  finally
    Dialog.Free;
  end;
  LogSettings;
  LogNotImplemented('Restore from backup');
end;

procedure TMain2Form.btnWriteBinClick(Sender: TObject);
var
  StartAddr, Len: UInt64;
begin
  Log('[Write BIN]');
  if not RequireFile(edtBin, 'BIN') then
    Exit;
  if not ParseAddress(StartAddr, Len) then
  begin
    Log('Enter the address as two hex values: start and length, e.g. 00000000 00100000');
    Log('');
    Exit;
  end;
  Log(Format('BIN file : %s', [edtBin.Text]));
  Log('Address : 0x' + IntToHex(StartAddr, 8) + '  Length : 0x' + IntToHex(Len, 8));
  LogSettings;
  LogNotImplemented('Write BIN');
end;

procedure TMain2Form.btnWriteOfpClick(Sender: TObject);
begin
  Log('[Write OFP]');
  if not RequireFile(edtOfp, 'OFP') then
    Exit;
  Log('OFP file : ' + edtOfp.Text);
  LogSettings;
  LogNotImplemented('Write OFP');
end;

end.
