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
  the action buttons check their inputs and write to the log.

  What this screen does do for real:
    - watches the USB bus and reports the phone when it is plugged in
      (MediaTek BROM / preloader / META, Qualcomm EDL, Unisoc, Samsung
      download mode, ADB, fastboot) - the phone icon at the bottom right
      turns green and the log records every arrival and removal;
    - timestamps every log line and copies the log to
      %APPDATA%\MobileServicingTools\logs\<date>.txt;
    - remembers all of the job options and file paths between runs;
    - saves and loads named presets (the Presets combo at the top left). }

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
  ToolbarIcons,
  DeviceWatch;

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
    miSavePreset: TMenuItem;
    miDeletePreset: TMenuItem;
    miPresetSeparator: TMenuItem;
    miChangeDevice: TMenuItem;
    miSaveLog: TMenuItem;
    miClearLog: TMenuItem;
    miOpenLogFolder: TMenuItem;
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
    procedure FormDestroy(Sender: TObject);
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
    procedure miSavePresetClick(Sender: TObject);
    procedure miDeletePresetClick(Sender: TObject);
    procedure miOpenLogFolderClick(Sender: TObject);
    procedure miClearLogClick(Sender: TObject);
    procedure miExitClick(Sender: TObject);
    procedure cbPresetsChange(Sender: TObject);
    procedure btnScatClick(Sender: TObject);
    procedure btnAuthClick(Sender: TObject);
    procedure btnBinClick(Sender: TObject);
    procedure btnOfpClick(Sender: TObject);
    procedure edtScatChange(Sender: TObject);
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
    FWatcher: TDeviceWatcher;
    FLoadingPreset: Boolean;
    FLogToFile: Boolean;
    procedure AssignGlyph(AButton: TBitBtn; const AKind: TActionGlyph);
    procedure Log(const AText: string);
    procedure LogSettings;
    procedure LogNotImplemented(const AOperation: string);
    function BrowseFile(const ATitle, AFilter: string; AEdit: TEdit): Boolean;
    function RequireFile(AEdit: TEdit; const AName: string): Boolean;
    function ParseAddress(out AStart, ALength: UInt64): Boolean;
    procedure UpdateAdvancedWrite;
    procedure UpdateReadyState;
    procedure FillRegions;
    procedure SetProgress(const AValue: Integer);
    procedure LoadJobSettings(const ASection: string);
    procedure SaveJobSettings(const ASection: string);
    procedure LoadPresetNames;
    procedure DevicesChanged(Sender: TObject);
    procedure DeviceArrivedOrLeft(Sender: TObject;
      const ADevice: TDetectedDevice; const AArrived: Boolean);
    procedure LogDeviceState;
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
  Math, ShellApi,
{$ELSE}
  System.Math,
  Winapi.ShellAPI,
{$ENDIF}
  AppSettings;

const
  CFacebookUrl = 'https://www.facebook.com/';
  CJobSection = 'Job';
  CPresetSection = 'Presets';
  CDefaultAddress = '00000000  00000000';

function PresetSection(const APresetName: string): string;
begin
  Result := 'Preset_' + APresetName;
end;

function OpenWithShell(const ATarget: string): Boolean;
begin
  Result := False;
  if ATarget = '' then
    Exit;
  Result := NativeInt(ShellExecute(0, 'open', PChar(ATarget), nil, nil,
    SW_SHOWNORMAL)) > 32;
end;

{ ---------------------------------------------------------------- setup }

procedure TMain2Form.FormCreate(Sender: TObject);
begin
  pcJobs.ActivePage := tsJobs;
  pcOperations.ActivePage := tsFlash;

  AssignGlyph(btnWriteFirmware, agWriteFirmware);
  AssignGlyph(btnRestoreBackup, agRestore);
  AssignGlyph(btnWriteBin, agWriteBin);
  AssignGlyph(btnWriteOfp, agWriteOfp);

  FProgress := 0;
  FDeviceConnected := False;
  FLoadingPreset := True;
  FLogToFile := TAppSettings.ReadBool(CJobSection, 'LogToFile', True);
  memLog.Clear;

  FillRegions;
  LoadJobSettings(CJobSection);
  UpdateAdvancedWrite;
  UpdateReadyState;
  LoadPresetNames;
  FLoadingPreset := False;

  FWatcher := TDeviceWatcher.Create;
  FWatcher.OnDevicesChange := DevicesChanged;
  FWatcher.OnDeviceChange := DeviceArrivedOrLeft;
  DevicesChanged(FWatcher);
  FWatcher.Start;
end;

procedure TMain2Form.FormDestroy(Sender: TObject);
begin
  if not FLoadingPreset then
    SaveJobSettings(CJobSection);
  if FWatcher <> nil then
  begin
    FWatcher.Stop;
    FreeAndNil(FWatcher);
  end;
  TAppSettings.Save;
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

  Caption := CAppName + ' - ' + FModelName;
  memLog.Clear;
  Log('Brand : ' + FBrand);
  if FModelCode <> '' then
    Log('Model : ' + FModelCode + ' : ' + FModelName)
  else
    Log('Model : ' + FModelName);
  LogDeviceState;
end;

procedure TMain2Form.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    SaveJobSettings(CJobSection);
    ModalResult := mrCancel;
  end;
end;

{ ---------------------------------------------------------------- log }

procedure TMain2Form.Log(const AText: string);
var
  Line: string;
begin
  if AText = '' then
    Line := ''
  else
    Line := '[' + FormatDateTime('hh:nn:ss', Now) + '] ' + AText;
  memLog.Lines.Add(Line);
  memLog.SelStart := Length(memLog.Text);
  memLog.SelLength := 0;
  if FLogToFile then
    TAppSettings.AppendToDailyLog(Line);
end;

procedure TMain2Form.LogSettings;
begin
  Log('Download agent : ' + cbDownloadAgent.Text);
  Log('USB speed : ' + cbUsbSpeed.Text + ',  Battery : ' + cbBattery.Text);
  Log('Storage : ' + cbStorageType.Text + ' / ' + cbRegion.Text);
  if chkAuthBrom.Checked then
    Log('Advanced authorization [BROM] : on');
  if chkForceBrom.Checked then
    Log('Force BROM mode : on');
  if chkReadEmi.Checked then
    Log('Read EMI from phone : on');
  if chkReadPhoneInfo.Checked then
    Log('Read phone info : on');
end;

procedure TMain2Form.LogNotImplemented(const AOperation: string);
begin
  Log(AOperation + ' : device communication is not implemented in this build.');
  Log('');
end;

procedure TMain2Form.miClearLogClick(Sender: TObject);
begin
  memLog.Clear;
  if FLogToFile then
    TAppSettings.AppendToDailyLog('--- log cleared on screen ---');
end;

{ ---------------------------------------------------------------- devices }

procedure TMain2Form.DevicesChanged(Sender: TObject);
var
  Text: string;
begin
  if FWatcher = nil then
    Exit;
  FDeviceConnected := FWatcher.Connected;
  if FDeviceConnected then
    Text := FWatcher.Summary
  else
    Text := 'No device connected';
  pbDeviceState.Hint := Text;
  pnlDeviceState.Hint := Text;
  pbDeviceState.Invalidate;
end;

procedure TMain2Form.DeviceArrivedOrLeft(Sender: TObject;
  const ADevice: TDetectedDevice; const AArrived: Boolean);
begin
  if AArrived then
    Log('Device connected : ' + ADevice.Caption)
  else
    Log('Device removed : ' + ADevice.KindText + ' (' +
      IntToHex(ADevice.Vid, 4) + ':' + IntToHex(ADevice.Pid, 4) + ')');
end;

procedure TMain2Form.LogDeviceState;
begin
  if (FWatcher <> nil) and FWatcher.Connected then
    Log('Device : ' + FWatcher.Summary)
  else
    Log('Device : none detected - connect the phone (BROM / download mode)');
end;

{ ---------------------------------------------------------------- painting }

procedure TMain2Form.pbMenuPaint(Sender: TObject);
begin
  DrawMenuIcon(pbMenu.Canvas, pbMenu.ClientRect);
end;

procedure TMain2Form.pbNextPaint(Sender: TObject);
begin
  DrawNextIcon(pbNext.Canvas, pbNext.ClientRect,
    Trim(edtScat.Text) <> '');
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
  Knob := Max(3, (R.Bottom - R.Top) div 2 - 1);
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

procedure TMain2Form.UpdateReadyState;
begin
  if Trim(edtScat.Text) <> '' then
    pbNext.Hint := 'Start (Write Firmware)'
  else
    pbNext.Hint := 'Start (Write Firmware) - choose a SCAT file first';
  pbNext.Invalidate;
end;

procedure TMain2Form.edtScatChange(Sender: TObject);
begin
  UpdateReadyState;
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
  Suggested, LastFolder: string;
begin
  Dialog := TSaveDialog.Create(Self);
  try
    Dialog.Title := 'Save log';
    Dialog.Filter := 'Text files (*.txt)|*.txt|All files (*.*)|*.*';
    Dialog.DefaultExt := 'txt';
    Dialog.Options := Dialog.Options + [ofOverwritePrompt];
    Suggested := 'log ' + FormatDateTime('yyyymmdd-hhnn', Now);
    if FModelCode <> '' then
      Suggested := FModelCode + ' ' + Suggested;
    Dialog.FileName := Suggested + '.txt';
    LastFolder := TAppSettings.ReadString(CJobSection, 'LastFolder', '');
    if DirectoryExists(LastFolder) then
      Dialog.InitialDir := LastFolder;
    if not Dialog.Execute then
      Exit;
    try
      {$IFDEF FPC}
      memLog.Lines.SaveToFile(Dialog.FileName);  { LCL strings are UTF-8 }
      {$ELSE}
      memLog.Lines.SaveToFile(Dialog.FileName, TEncoding.UTF8);
      {$ENDIF}
      TAppSettings.WriteString(CJobSection, 'LastFolder',
        IncludeTrailingPathDelimiter(ExtractFilePath(Dialog.FileName)));
      Log('Log saved : ' + Dialog.FileName);
    except
      on E: Exception do
      begin
        TAppSettings.WriteErrorReport('MAIN 2 - save log', E.Message);
        MessageDlg('The log could not be saved.' + sLineBreak + E.Message,
          mtError, [mbOK], 0);
      end;
    end;
  finally
    Dialog.Free;
  end;
end;

procedure TMain2Form.pbChangeDeviceClick(Sender: TObject);
begin
  { Back to MAIN 1 to pick another model. }
  SaveJobSettings(CJobSection);
  ModalResult := mrCancel;
end;

procedure TMain2Form.pbSettingsClick(Sender: TObject);
var
  Msg: string;
begin
  Msg := 'Where this build keeps its data' + sLineBreak + sLineBreak +
    'Settings : ' + TAppSettings.IniFileName + sLineBreak +
    'Log file  : ' + TAppSettings.DailyLogFileName + sLineBreak +
    'Models   : ' + TAppSettings.DataDir + sLineBreak +
    '              ' + TAppSettings.ExeDataDir + sLineBreak + sLineBreak;
  if FLogToFile then
    Msg := Msg + 'Every log line is copied to the daily log file.'
  else
    Msg := Msg + 'The log is only shown on screen.';
  Msg := Msg + sLineBreak + sLineBreak +
    'A full settings dialog is not built yet - use the menu to open the ' +
    'log folder.';
  MessageDlg(Msg, mtInformation, [mbOK], 0);
end;

procedure TMain2Form.pbFacebookClick(Sender: TObject);
begin
  if not OpenWithShell(CFacebookUrl) then
  begin
    Log('The browser could not be opened for ' + CFacebookUrl);
    MessageDlg('The browser could not be opened.' + sLineBreak + CFacebookUrl,
      mtWarning, [mbOK], 0);
  end;
end;

procedure TMain2Form.pbHelpClick(Sender: TObject);
var
  Msg: string;
begin
  Msg := 'Mobile Servicing Tools ' + CAppVersion + sLineBreak + sLineBreak +
    'Selected device: ' + FBrand + ' ' + FModelName + sLineBreak;
  if FModelCode <> '' then
    Msg := Msg + 'Model code: ' + FModelCode + sLineBreak;
  Msg := Msg + sLineBreak + 'USB: ';
  if (FWatcher <> nil) and FWatcher.Connected then
    Msg := Msg + FWatcher.Summary
  else
    Msg := Msg + 'no device detected';
  Msg := Msg + sLineBreak + sLineBreak +
    'Writing to a phone is not implemented in this build. The action buttons ' +
    'check their inputs and write the job to the log.';
  MessageDlg(Msg, mtInformation, [mbOK], 0);
end;

procedure TMain2Form.miOpenLogFolderClick(Sender: TObject);
begin
  if not TAppSettings.OpenFolder(TAppSettings.LogDir) then
    MessageDlg('The log folder could not be opened:' + sLineBreak +
      TAppSettings.LogDir, mtWarning, [mbOK], 0);
end;

procedure TMain2Form.miExitClick(Sender: TObject);
begin
  SaveJobSettings(CJobSection);
  Application.Terminate;
  ModalResult := mrCancel;
end;

{ ---------------------------------------------------------------- presets }

procedure TMain2Form.LoadPresetNames;
var
  Names: TStringList;
  I, Idx: Integer;
  Current: string;
begin
  Names := TStringList.Create;
  try
    TAppSettings.ReadSection(CPresetSection, Names);
    Names.Sort;
    FLoadingPreset := True;
    try
      Current := cbPresets.Text;
      cbPresets.Items.Clear;
      for I := 0 to Names.Count - 1 do
        cbPresets.Items.Add(Names[I]);
      if Current = '' then
        Current := TAppSettings.ReadString(CJobSection, 'LastPreset', '');
      Idx := cbPresets.Items.IndexOf(Current);
      if Idx >= 0 then
        cbPresets.ItemIndex := Idx
      else
        cbPresets.ItemIndex := -1;
    finally
      FLoadingPreset := False;
    end;
  finally
    Names.Free;
  end;
  if cbPresets.Items.Count = 0 then
    cbPresets.Hint := 'Presets - use the menu icon to save the current job as a preset'
  else
    cbPresets.Hint := 'Presets - select one to load it, or save a new one from the menu';
end;

procedure TMain2Form.cbPresetsChange(Sender: TObject);
begin
  if FLoadingPreset then
    Exit;
  if cbPresets.ItemIndex < 0 then
    Exit;
  LoadJobSettings(PresetSection(cbPresets.Text));
  TAppSettings.WriteString(CJobSection, 'LastPreset', cbPresets.Text);
  Log('Preset loaded : ' + cbPresets.Text);
  UpdateAdvancedWrite;
  UpdateReadyState;
end;

procedure TMain2Form.miSavePresetClick(Sender: TObject);
var
  Name: string;
begin
  Name := cbPresets.Text;
  if not InputQuery('Save preset', 'Preset name:', Name) then
    Exit;
  Name := Trim(Name);
  if Name = '' then
  begin
    Log('A preset needs a name.');
    Exit;
  end;
  SaveJobSettings(PresetSection(Name));
  TAppSettings.WriteString(CPresetSection, Name, Name);
  TAppSettings.WriteString(CJobSection, 'LastPreset', Name);
  TAppSettings.Save;
  LoadPresetNames;
  FLoadingPreset := True;
  try
    cbPresets.ItemIndex := cbPresets.Items.IndexOf(Name);
  finally
    FLoadingPreset := False;
  end;
  Log('Preset saved : ' + Name);
end;

procedure TMain2Form.miDeletePresetClick(Sender: TObject);
var
  Name: string;
begin
  if cbPresets.ItemIndex < 0 then
  begin
    Log('Select a preset first.');
    Exit;
  end;
  Name := cbPresets.Text;
  if MessageDlg('Delete the preset "' + Name + '"?', mtConfirmation,
    [mbYes, mbNo], 0) <> mrYes then
    Exit;
  TAppSettings.EraseSection(PresetSection(Name));
  TAppSettings.DeleteValue(CPresetSection, Name);
  if SameText(TAppSettings.ReadString(CJobSection, 'LastPreset', ''), Name) then
    TAppSettings.DeleteValue(CJobSection, 'LastPreset');
  TAppSettings.Save;
  LoadPresetNames;
  Log('Preset deleted : ' + Name);
end;

{ ---------------------------------------------------------------- files }

function TMain2Form.BrowseFile(const ATitle, AFilter: string;
  AEdit: TEdit): Boolean;
var
  Dialog: TOpenDialog;
  LastFolder: string;
begin
  Dialog := TOpenDialog.Create(Self);
  try
    Dialog.Title := ATitle;
    Dialog.Filter := AFilter;
    Dialog.Options := Dialog.Options + [ofFileMustExist, ofPathMustExist];
    if AEdit.Text <> '' then
      Dialog.FileName := AEdit.Text
    else
    begin
      LastFolder := TAppSettings.ReadString(CJobSection, 'LastFolder', '');
      if DirectoryExists(LastFolder) then
        Dialog.InitialDir := LastFolder;
    end;
    Result := Dialog.Execute;
    if Result then
    begin
      AEdit.Text := Dialog.FileName;
      TAppSettings.WriteString(CJobSection, 'LastFolder',
        IncludeTrailingPathDelimiter(ExtractFilePath(Dialog.FileName)));
    end;
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

{ ---------------------------------------------------------------- settings }

procedure SelectComboByIndex(ACombo: TComboBox; AIndex: Integer);
begin
  if ACombo.Items.Count = 0 then
    Exit;
  if AIndex < 0 then
    AIndex := 0;
  if AIndex > ACombo.Items.Count - 1 then
    AIndex := ACombo.Items.Count - 1;
  ACombo.ItemIndex := AIndex;
end;

procedure SelectComboByText(ACombo: TComboBox; const AText: string);
var
  Idx: Integer;
begin
  Idx := ACombo.Items.IndexOf(AText);
  if Idx >= 0 then
    ACombo.ItemIndex := Idx;
end;

procedure TMain2Form.LoadJobSettings(const ASection: string);
begin
  FLoadingPreset := True;
  try
    edtScat.Text := TAppSettings.ReadString(ASection, 'Scat', '');
    edtAuth.Text := TAppSettings.ReadString(ASection, 'Auth', '');
    edtBin.Text := TAppSettings.ReadString(ASection, 'Bin', '');
    edtOfp.Text := TAppSettings.ReadString(ASection, 'Ofp', '');

    SelectComboByText(cbDownloadAgent,
      TAppSettings.ReadString(ASection, 'Agent', cbDownloadAgent.Text));
    chkAuthBrom.Checked := TAppSettings.ReadBool(ASection, 'AuthBrom', True);
    chkAuthPreloader.Checked :=
      TAppSettings.ReadBool(ASection, 'AuthPreloader', False);
    chkForceBrom.Checked := TAppSettings.ReadBool(ASection, 'ForceBrom', True);
    chkReadEmi.Checked := TAppSettings.ReadBool(ASection, 'ReadEmi', True);
    chkReadPhoneInfo.Checked :=
      TAppSettings.ReadBool(ASection, 'ReadPhoneInfo', True);
    SelectComboByIndex(cbUsbSpeed, TAppSettings.ReadInt(ASection, 'UsbSpeed', 0));
    SelectComboByIndex(cbBattery, TAppSettings.ReadInt(ASection, 'Battery', 0));

    SelectComboByIndex(cbStorageType,
      TAppSettings.ReadInt(ASection, 'StorageType', 0));
    FillRegions;
    SelectComboByText(cbRegion, TAppSettings.ReadString(ASection, 'Region', ''));

    SelectComboByIndex(cbFlashMode,
      TAppSettings.ReadInt(ASection, 'FlashMode', 0));
    chkAdvancedWrite.Checked :=
      TAppSettings.ReadBool(ASection, 'AdvancedWrite', False);
    edtAddress.Text :=
      TAppSettings.ReadString(ASection, 'Address', CDefaultAddress);
  finally
    FLoadingPreset := False;
  end;
end;

procedure TMain2Form.SaveJobSettings(const ASection: string);
begin
  TAppSettings.WriteString(ASection, 'Scat', edtScat.Text);
  TAppSettings.WriteString(ASection, 'Auth', edtAuth.Text);
  TAppSettings.WriteString(ASection, 'Bin', edtBin.Text);
  TAppSettings.WriteString(ASection, 'Ofp', edtOfp.Text);
  TAppSettings.WriteString(ASection, 'Agent', cbDownloadAgent.Text);
  TAppSettings.WriteBool(ASection, 'AuthBrom', chkAuthBrom.Checked);
  TAppSettings.WriteBool(ASection, 'AuthPreloader', chkAuthPreloader.Checked);
  TAppSettings.WriteBool(ASection, 'ForceBrom', chkForceBrom.Checked);
  TAppSettings.WriteBool(ASection, 'ReadEmi', chkReadEmi.Checked);
  TAppSettings.WriteBool(ASection, 'ReadPhoneInfo', chkReadPhoneInfo.Checked);
  TAppSettings.WriteInt(ASection, 'UsbSpeed', cbUsbSpeed.ItemIndex);
  TAppSettings.WriteInt(ASection, 'Battery', cbBattery.ItemIndex);
  TAppSettings.WriteInt(ASection, 'StorageType', cbStorageType.ItemIndex);
  TAppSettings.WriteString(ASection, 'Region', cbRegion.Text);
  TAppSettings.WriteInt(ASection, 'FlashMode', cbFlashMode.ItemIndex);
  TAppSettings.WriteBool(ASection, 'AdvancedWrite', chkAdvancedWrite.Checked);
  TAppSettings.WriteString(ASection, 'Address', edtAddress.Text);
  if ASection = CJobSection then
    TAppSettings.WriteString(ASection, 'LogToFile',
      BoolToStr(FLogToFile, True));
end;

{ ---------------------------------------------------------------- actions }

procedure TMain2Form.btnWriteFirmwareClick(Sender: TObject);
begin
  try
    Log('[Write Firmware] ' + cbFlashMode.Text);
    if not RequireFile(edtScat, 'SCAT') then
      Exit;
    Log('Scatter file : ' + edtScat.Text);
    if Trim(edtAuth.Text) <> '' then
      Log('Auth file : ' + edtAuth.Text);
    LogDeviceState;
    LogSettings;
    LogNotImplemented('Write Firmware');
  except
    on E: Exception do
    begin
      TAppSettings.WriteErrorReport('MAIN 2 - Write Firmware', E.Message);
      Log('Error : ' + E.Message);
    end;
  end;
end;

procedure TMain2Form.btnRestoreBackupClick(Sender: TObject);
var
  Dialog: TOpenDialog;
begin
  try
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
    LogDeviceState;
    LogSettings;
    LogNotImplemented('Restore from backup');
  except
    on E: Exception do
    begin
      TAppSettings.WriteErrorReport('MAIN 2 - Restore from backup', E.Message);
      Log('Error : ' + E.Message);
    end;
  end;
end;

procedure TMain2Form.btnWriteBinClick(Sender: TObject);
var
  StartAddr, Len: UInt64;
begin
  try
    Log('[Write BIN]');
    if not RequireFile(edtBin, 'BIN') then
      Exit;
    if not ParseAddress(StartAddr, Len) then
    begin
      Log('Enter the address as two hex values: start and length, e.g. 00000000 00100000');
      Log('');
      Exit;
    end;
    if Len = 0 then
    begin
      Log('The length must be more than zero.');
      Log('');
      Exit;
    end;
    Log(Format('BIN file : %s', [edtBin.Text]));
    Log('Address : 0x' + IntToHex(StartAddr, 8) + '  Length : 0x' + IntToHex(Len, 8));
    LogDeviceState;
    LogSettings;
    LogNotImplemented('Write BIN');
  except
    on E: Exception do
    begin
      TAppSettings.WriteErrorReport('MAIN 2 - Write BIN', E.Message);
      Log('Error : ' + E.Message);
    end;
  end;
end;

procedure TMain2Form.btnWriteOfpClick(Sender: TObject);
begin
  try
    Log('[Write OFP]');
    if not RequireFile(edtOfp, 'OFP') then
      Exit;
    Log('OFP file : ' + edtOfp.Text);
    LogDeviceState;
    LogSettings;
    LogNotImplemented('Write OFP');
  except
    on E: Exception do
    begin
      TAppSettings.WriteErrorReport('MAIN 2 - Write OFP', E.Message);
      Log('Error : ' + E.Message);
    end;
  end;
end;

end.
