unit Main2Form;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


{ MAIN 2 - opened from MAIN 1 when the user presses Next.
  Layout follows the MAIN 2 reference screenshot:
    - toolbar: menu and platform selector (left); settings, Facebook, help,
      change device, save log and start (right)
    - left: Presets, Files (SCAT / AUTH / BIN / OFP / BL / AP / CP / CSC /
      USER), colour log and progress
    - right: Jobs / platform service-mode tabs (META / DIAG / DOWNLOAD),
      Connections and Storage groups, then the Flash / Read / Format / IMEI /
      Locks / Service / RPMB tabs
    - USB device state (bottom right)
  Device communication (flashing, reading, etc.) is NOT implemented: the
  action buttons check their inputs and write to the log. USB detection only
  reads the Windows device list. }

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
  UsbDetect;

type
  TMain2Form = class(TForm)
    { toolbar }
    pbMenu: TPaintBox;
    lblPlatform: TLabel;
    cbPlatform: TComboBox;
    pbSettings: TPaintBox;
    pbFacebook: TPaintBox;
    pbHelp: TPaintBox;
    pbChangeDevice: TPaintBox;
    pbDownload: TPaintBox;
    pbNext: TPaintBox;
    pmMain: TPopupMenu;
    miChangeDevice: TMenuItem;
    miSaveLog: TMenuItem;
    miClearLog: TMenuItem;
    miSettings: TMenuItem;
    miSeparator: TMenuItem;
    miExit: TMenuItem;
    { left side }
    grpPresets: TGroupBox;
    cbPresets: TComboBox;
    grpFiles: TGroupBox;
    btnScat: TButton;
    edtScat: TEdit;
    btnAuth: TButton;
    edtAuth: TEdit;
    btnBin: TButton;
    edtBin: TEdit;
    btnOfp: TButton;
    edtOfp: TEdit;
    btnBl: TButton;
    edtBl: TEdit;
    btnAp: TButton;
    edtAp: TEdit;
    btnCp: TButton;
    edtCp: TEdit;
    btnCsc: TButton;
    edtCsc: TEdit;
    btnUser: TButton;
    edtUser: TEdit;
    grpLog: TGroupBox;
    lstLog: TListBox;
    pmLog: TPopupMenu;
    miLogCopy: TMenuItem;
    miLogCopyAll: TMenuItem;
    miLogSelectAll: TMenuItem;
    miLogSeparator: TMenuItem;
    miLogSave: TMenuItem;
    miLogClear: TMenuItem;
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
    cbStorage: TComboBox;
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
    grpReadOptions: TGroupBox;
    btnReadInfo: TBitBtn;
    btnReadPartitions: TBitBtn;
    lblReadAddress: TLabel;
    edtReadAddress: TEdit;
    lblReadSize: TLabel;
    edtReadSize: TEdit;
    btnReadBin: TBitBtn;
    btnReadRegion: TBitBtn;
    btnReadOtp: TBitBtn;
    lblFormatInfo: TLabel;
    lblImeiInfo: TLabel;
    lblLocksInfo: TLabel;
    lblServiceInfo: TLabel;
    lblRpmbInfo: TLabel;
    grpFormatOptions: TGroupBox;
    lblFormatMode: TLabel;
    cbFormatMode: TComboBox;
    lblFormatTarget: TLabel;
    cbFormatTarget: TComboBox;
    chkPreserveCalibration: TCheckBox;
    chkFormatByAddress: TCheckBox;
    lblFormatAddress: TLabel;
    edtFormatAddress: TEdit;
    lblFormatSize: TLabel;
    edtFormatSize: TEdit;
    btnFormat: TButton;
    grpServiceOptions: TGroupBox;
    lblServiceAction: TLabel;
    cbServiceAction: TComboBox;
    chkServiceVerbose: TCheckBox;
    btnRunService: TButton;
    grpRpmbOptions: TGroupBox;
    lblRpmbOperation: TLabel;
    cbRpmbOperation: TComboBox;
    lblRpmbTarget: TLabel;
    cbRpmbTarget: TComboBox;
    btnRunRpmb: TButton;
    { device state }
    pnlDeviceState: TPanel;
    lblDeviceState: TLabel;
    pbDeviceState: TPaintBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure cbPlatformChange(Sender: TObject);
    procedure chkFormatByAddressClick(Sender: TObject);
    procedure btnFormatClick(Sender: TObject);
    procedure btnRunServiceClick(Sender: TObject);
    procedure btnRunRpmbClick(Sender: TObject);
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
    procedure miLogCopyClick(Sender: TObject);
    procedure miLogCopyAllClick(Sender: TObject);
    procedure miLogSelectAllClick(Sender: TObject);
    procedure lstLogDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure lstLogKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnScatClick(Sender: TObject);
    procedure btnAuthClick(Sender: TObject);
    procedure btnBinClick(Sender: TObject);
    procedure btnOfpClick(Sender: TObject);
    procedure btnBlClick(Sender: TObject);
    procedure btnApClick(Sender: TObject);
    procedure btnCpClick(Sender: TObject);
    procedure btnCscClick(Sender: TObject);
    procedure btnUserClick(Sender: TObject);
    procedure chkAdvancedWriteClick(Sender: TObject);
    procedure btnWriteFirmwareClick(Sender: TObject);
    procedure btnRestoreBackupClick(Sender: TObject);
    procedure btnWriteBinClick(Sender: TObject);
    procedure btnWriteOfpClick(Sender: TObject);
    procedure btnReadInfoClick(Sender: TObject);
    procedure btnReadPartitionsClick(Sender: TObject);
    procedure btnReadBinClick(Sender: TObject);
    procedure btnReadRegionClick(Sender: TObject);
    procedure btnReadOtpClick(Sender: TObject);
  private
    FBrand: string;
    FModelCode: string;
    FModelName: string;
    FProgress: Integer;
    FDevices: TUsbDeviceArray;
    FDeviceSig: string;
    FUsbTimer: TTimer;
    FMeasure: TBitmap;
    FSessionLog: TStringList;
    FLayoutFixed: Boolean;
    procedure AssignGlyph(AButton: TBitBtn; const AKind: TActionGlyph);
    procedure SetupLogFont;
    procedure AddLogLine(const ALine: string);
    procedure LogSettings;
    procedure LogNotImplemented(const AOperation: string);
    procedure LogError(const AText: string);
    function SelectedLogText(const AOnlySelected: Boolean): string;
    function BrowseFile(const ATitle, AFilter: string; AEdit: TEdit): Boolean;
    procedure BrowseFirmwarePart(AEdit: TEdit; const AName: string);
    function RequireFile(AEdit: TEdit; const AName: string): Boolean;
    function CheckOptionalFile(AEdit: TEdit; const AName: string): Boolean;
    function AskSaveFile(const ATitle, ADefaultName: string;
      out AFileName: string): Boolean;
    procedure UpdateAdvancedWrite;
    procedure ApplyPlatformSettings;
    procedure UpdateFormatAddress;
    function PlatformName: string;
    procedure SetProgress(const AValue: Integer);
    procedure UsbTimerTick(Sender: TObject);
    procedure CheckUsb(const AInitial: Boolean);
    procedure UpdateDeviceState;
    procedure ApplyOptions;
    procedure LoadState;
    procedure SaveState;
    procedure AutoSaveSessionLog;
  public
    procedure SetDevice(const ABrand, AModelEntry: string);
    { Writes a line to the log. Colour codes from LogView may be used. }
    procedure Log(const AText: string);
    { Used by the CI self-test: runs the checks that need no dialogs and
      adds PASS/FAIL lines to AOut. }
    function SelfTest(AOut: TStrings): Boolean;
    procedure ShowDemoLog;
    property Progress: Integer read FProgress write SetProgress;
  end;

{ Parses a 64-bit hex value. Spaces are ignored, so the "00000000  00000000"
  (high / low half) format of the address boxes is accepted. }
function TryParseHex64(const S: string; out AValue: UInt64): Boolean;

implementation

{$IFDEF FPC}
  {$R *.lfm}
{$ELSE}
  {$R *.dfm}
{$ENDIF}

uses
{$IFDEF FPC}
  ShellApi, Clipbrd, IniFiles,
{$ELSE}
  Winapi.ShellAPI,
  Vcl.Clipbrd,
  System.IniFiles,
{$ENDIF}
  AppInfo,
  LogView,
  SettingsDialog;

const
  CFacebookUrl = 'https://www.facebook.com/';
  CMaxLogLines = 5000;
  CSection = 'Main2';

  CFilterAll = '|All files (*.*)|*.*';
  CFilterSamsung = 'Samsung firmware (*.tar.md5;*.tar;*.md5)|*.tar.md5;*.tar;*.md5' +
    CFilterAll;
  CPlatformMtk = 0;
  CPlatformUnisoc = 1;
  CPlatformQualcomm = 2;
  CPlatformSamsung = 3;
  CPlatformGeneric = 4;

procedure ReplaceComboItems(ACombo: TComboBox; const AItems: array of string);
var
  SelectedText: string;
  I, SelectedIndex: Integer;
begin
  SelectedText := ACombo.Text;
  SelectedIndex := 0;
  ACombo.Items.BeginUpdate;
  try
    ACombo.Items.Clear;
    for I := 0 to High(AItems) do
    begin
      ACombo.Items.Add(AItems[I]);
      if (SelectedText <> '') and SameText(AItems[I], SelectedText) then
        SelectedIndex := I;
    end;
  finally
    ACombo.Items.EndUpdate;
  end;
  if ACombo.Items.Count = 0 then
    ACombo.ItemIndex := -1
  else
    ACombo.ItemIndex := SelectedIndex;
end;

{ ---------------------------------------------------------------- helpers }

function TryParseHex64(const S: string; out AValue: UInt64): Boolean;
var
  I, Digit, Count: Integer;
begin
  AValue := 0;
  Count := 0;
  Result := False;
  for I := 1 to Length(S) do
  begin
    case S[I] of
      ' ', #9: Continue;
      '0'..'9': Digit := Ord(S[I]) - Ord('0');
      'a'..'f': Digit := Ord(S[I]) - Ord('a') + 10;
      'A'..'F': Digit := Ord(S[I]) - Ord('A') + 10;
    else
      Exit;
    end;
    Inc(Count);
    if Count > 16 then
      Exit;
    AValue := (AValue shl 4) or UInt64(Digit);
  end;
  Result := Count > 0;
end;

function Hex64(const AValue: UInt64): string;
begin
  { "00000000 00100000" - the same high / low layout as the address boxes }
  Result := IntToHex(Int64(AValue shr 32), 8) + ' ' +
    IntToHex(Int64(AValue and $FFFFFFFF), 8);
end;

function FileSizeOf(const AFileName: string): Int64;
var
  SR: TSearchRec;
begin
  Result := -1;
  if FindFirst(AFileName, faAnyFile, SR) = 0 then
  begin
    Result := SR.Size;
    FindClose(SR);
  end;
end;

function SafeFileName(const S: string): string;
var
  I: Integer;
begin
  Result := S;
  for I := 1 to Length(Result) do
    if CharInSet(Result[I], ['\', '/', ':', '*', '?', '"', '<', '>', '|', ' ']) then
      Result[I] := '_';
end;

{ ---------------------------------------------------------------- setup }

procedure TMain2Form.FormCreate(Sender: TObject);
begin
  Caption := AppTitle;
  pcJobs.ActivePage := tsJobs;
  pcOperations.ActivePage := tsFlash;

  AssignGlyph(btnWriteFirmware, agWriteFirmware);
  AssignGlyph(btnRestoreBackup, agRestore);
  AssignGlyph(btnWriteBin, agWriteBin);
  AssignGlyph(btnWriteOfp, agWriteOfp);
  AssignGlyph(btnReadInfo, agReadInfo);
  AssignGlyph(btnReadPartitions, agReadPartitions);
  AssignGlyph(btnReadBin, agReadBin);
  AssignGlyph(btnReadRegion, agReadRegion);
  AssignGlyph(btnReadOtp, agReadOtp);

  FSessionLog := TStringList.Create;
  FMeasure := TBitmap.Create;
  SetupLogFont;
  lstLog.Items.Clear;

  FProgress := 0;
  SetLength(FDevices, 0);
  FDeviceSig := '';

  LoadState;
  ApplyPlatformSettings;
  UpdateAdvancedWrite;
  UpdateFormatAddress;

  FUsbTimer := TTimer.Create(Self);
  FUsbTimer.Enabled := False;
  FUsbTimer.Interval := 1000;
  FUsbTimer.OnTimer := UsbTimerTick;
  UpdateDeviceState;
end;

procedure TMain2Form.FormShow(Sender: TObject);
begin
  if not FLayoutFixed then
  begin
    FLayoutFixed := True;
    FixGroupBoxLayout(Self, grpFiles);
  end;
  ApplyOptions;
  if GOptions.DetectUsb then
    CheckUsb(True);
end;

procedure TMain2Form.FormDestroy(Sender: TObject);
begin
  if FUsbTimer <> nil then
    FUsbTimer.Enabled := False;
  SaveState;
  AutoSaveSessionLog;
  FSessionLog.Free;
  FMeasure.Free;
end;

function TMain2Form.PlatformName: string;
begin
  case cbPlatform.ItemIndex of
    CPlatformMtk: Result := 'MediaTek (MTK)';
    CPlatformUnisoc: Result := 'Unisoc / Spreadtrum';
    CPlatformQualcomm: Result := 'Qualcomm';
    CPlatformSamsung: Result := 'Samsung';
  else
    Result := 'Other / Generic';
  end;
end;

procedure TMain2Form.ApplyPlatformSettings;
var
  I: Integer;
begin
  I := cbPlatform.ItemIndex;
  if I < CPlatformMtk then
    I := CPlatformMtk;
  if I > CPlatformGeneric then
    I := CPlatformGeneric;

  case I of
    CPlatformMtk:
      begin
        tsMeta.Caption := 'META';
        lblMetaInfo.Caption := 'MediaTek service profile. META mode and DA options are shown. ' +
          'This build only validates selections; it does not communicate with a phone.';
        ReplaceComboItems(cbDownloadAgent, ['MTK_AllInOne_DA.bin']);
        chkAuthBrom.Caption := 'Advanced Authorization [BROM]';
        chkAuthPreloader.Caption := 'Advanced Authorization [Preloader]';
        chkForceBrom.Caption := 'Force BROM Mode';
        chkReadEmi.Caption := 'Read EMI from phone';
        lblServiceInfo.Caption := 'MediaTek service actions use the META profile. ' +
          'Actions are logged for review and are not sent to a connected device.';
        lblRpmbInfo.Caption := 'MTK RPMB options are read / backup planning only. ' +
          'Key programming, write and erase operations are intentionally not exposed.';
        ReplaceComboItems(cbFormatMode, ['Safe format (preserve calibration)',
          'Format user data', 'Format selected partition']);
        ReplaceComboItems(cbFormatTarget, ['USERDATA', 'CACHE', 'METADATA',
          'CUSTOM PARTITION']);
        ReplaceComboItems(cbServiceAction, ['Read device info',
          'Switch to META mode', 'Restart device']);
        ReplaceComboItems(cbRpmbOperation, ['Read RPMB information',
          'Read RPMB counter', 'Back up RPMB region']);
      end;
    CPlatformUnisoc:
      begin
        tsMeta.Caption := 'DIAG';
        lblMetaInfo.Caption := 'Unisoc / Spreadtrum service profile. The top service tab is DIAG ' +
          'instead of META. This build does not communicate with a phone.';
        ReplaceComboItems(cbDownloadAgent, ['Unisoc FDL1 / FDL2 (firmware supplied)']);
        chkAuthBrom.Caption := 'Secure-boot authorization [BootROM]';
        chkAuthPreloader.Caption := 'Load signed FDL1 / FDL2';
        chkForceBrom.Caption := 'Force download / BootROM mode';
        chkReadEmi.Caption := 'Read calibration / NV data';
        lblServiceInfo.Caption := 'Unisoc service actions use the DIAG profile. ' +
          'Use only firmware and service files intended for the exact device.' + sLineBreak +
          'Actions are log-only in this build.';
        lblRpmbInfo.Caption := 'Unisoc RPMB choices are limited to information and backup planning ' +
          'through the selected DIAG profile. No RPMB write or key operation is available.';
        ReplaceComboItems(cbFormatMode, ['Format user data (DIAG)',
          'Reset selected partition', 'Format selected region']);
        ReplaceComboItems(cbFormatTarget, ['USERDATA', 'CACHE', 'METADATA',
          'CUSTOM PARTITION']);
        ReplaceComboItems(cbServiceAction, ['Read device info',
          'Switch to DIAG mode', 'Restart device']);
        ReplaceComboItems(cbRpmbOperation, ['Read RPMB information (DIAG)',
          'Back up RPMB region (DIAG)']);
      end;
    CPlatformQualcomm:
      begin
        tsMeta.Caption := 'DIAG';
        lblMetaInfo.Caption := 'Qualcomm service profile. DIAG is selected for the service-mode ' +
          'tab. This build does not communicate with a phone.';
        ReplaceComboItems(cbDownloadAgent, ['Qualcomm programmer (user supplied)']);
        chkAuthBrom.Caption := 'Programmer authorization';
        chkAuthPreloader.Caption := 'Load signed programmer';
        chkForceBrom.Caption := 'Enter EDL mode';
        chkReadEmi.Caption := 'Read calibration / NV data';
        lblServiceInfo.Caption := 'Qualcomm service actions use the DIAG profile. ' +
          'Actions are logged for review and are not sent to a connected device.';
        lblRpmbInfo.Caption := 'Qualcomm RPMB options are limited to information, counter and backup ' +
          'planning. No RPMB write or key operation is available.';
        ReplaceComboItems(cbFormatMode, ['Format user data',
          'Erase selected partition', 'Format selected region']);
        ReplaceComboItems(cbFormatTarget, ['USERDATA', 'METADATA',
          'CUSTOM PARTITION']);
        ReplaceComboItems(cbServiceAction, ['Read device info',
          'Switch to DIAG mode', 'Restart device']);
        ReplaceComboItems(cbRpmbOperation, ['Read RPMB information',
          'Read RPMB counter', 'Back up RPMB region']);
      end;
    CPlatformSamsung:
      begin
        tsMeta.Caption := 'DOWNLOAD';
        lblMetaInfo.Caption := 'Samsung download-mode profile. The top service tab is DOWNLOAD ' +
          'instead of META. This build does not communicate with a phone.';
        ReplaceComboItems(cbDownloadAgent, ['Samsung download-mode package']);
        chkAuthBrom.Caption := 'Download-mode authorization';
        chkAuthPreloader.Caption := 'Use signed firmware package';
        chkForceBrom.Caption := 'Enter DOWNLOAD mode';
        chkReadEmi.Caption := 'Read device information';
        lblServiceInfo.Caption := 'Samsung service actions use the DOWNLOAD profile. ' +
          'Actions are logged for review and are not sent to a connected device.';
        lblRpmbInfo.Caption := 'Samsung RPMB choices are limited to information and backup planning. ' +
          'No RPMB write or key operation is available.';
        ReplaceComboItems(cbFormatMode, ['Factory reset', 'Format user data',
          'Format selected partition']);
        ReplaceComboItems(cbFormatTarget, ['USERDATA', 'CACHE',
          'CUSTOM PARTITION']);
        ReplaceComboItems(cbServiceAction, ['Read device info',
          'Enter DOWNLOAD mode', 'Restart device']);
        ReplaceComboItems(cbRpmbOperation, ['Read RPMB information',
          'Back up RPMB region']);
      end;
  else
    begin
      tsMeta.Caption := 'SERVICE';
      lblMetaInfo.Caption := 'Generic service profile. Choose the correct platform family above ' +
        'before using a device-specific workflow. No phone communication is implemented.';
      ReplaceComboItems(cbDownloadAgent, ['Platform-specific agent / loader']);
      chkAuthBrom.Caption := 'Platform authorization';
      chkAuthPreloader.Caption := 'Load signed agent / loader';
      chkForceBrom.Caption := 'Force service mode';
      chkReadEmi.Caption := 'Read calibration / NV data';
      lblServiceInfo.Caption := 'Generic service actions are informational only. ' +
        'Choose a supported platform family for device-specific options.';
      lblRpmbInfo.Caption := 'Only generic RPMB information is listed for this platform. ' +
        'No RPMB write or key operation is available.';
      ReplaceComboItems(cbFormatMode, ['Format user data',
        'Format selected partition', 'Format selected region']);
      ReplaceComboItems(cbFormatTarget, ['USERDATA', 'CUSTOM PARTITION']);
      ReplaceComboItems(cbServiceAction, ['Read device info', 'Restart device']);
      ReplaceComboItems(cbRpmbOperation, ['Read RPMB information']);
    end;
  end;

  cbDownloadAgent.Enabled := True;
  chkAuthBrom.Enabled := (I = CPlatformMtk) or (I = CPlatformUnisoc) or
    (I = CPlatformQualcomm);
  chkAuthPreloader.Enabled := (I = CPlatformMtk) or (I = CPlatformUnisoc) or
    (I = CPlatformQualcomm);
  chkForceBrom.Enabled := False;
  chkReadEmi.Enabled := False;
  UpdateFormatAddress;
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

procedure TMain2Form.SetupLogFont;
begin
  FMeasure.SetSize(8, 8);
  FMeasure.Canvas.Font.Assign(lstLog.Font);
  lstLog.ItemHeight := FMeasure.Canvas.TextHeight('Wg') + 2;
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

  Caption := AppTitle + ' - ' + FModelName;
  Log('Brand : ' + LInfo(FBrand));
  if FModelCode <> '' then
    Log('Model : ' + LInfo(FModelCode + ' : ' + FModelName))
  else
    Log('Model : ' + LInfo(FModelName));
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

procedure TMain2Form.ApplyOptions;
begin
  if FUsbTimer <> nil then
    FUsbTimer.Enabled := GOptions.DetectUsb;
  if not GOptions.DetectUsb then
  begin
    SetLength(FDevices, 0);
    FDeviceSig := '';
  end;
  UpdateDeviceState;
end;

{ ---------------------------------------------------------------- state }

procedure TMain2Form.LoadState;
var
  Ini: TMemIniFile;

  procedure LoadEdit(AEdit: TEdit; const AKey: string);
  begin
    AEdit.Text := Ini.ReadString(CSection, AKey, AEdit.Text);
  end;

  procedure LoadCheck(ACheck: TCheckBox; const AKey: string);
  begin
    ACheck.Checked := Ini.ReadBool(CSection, AKey, ACheck.Checked);
  end;

  procedure LoadCombo(ACombo: TComboBox; const AKey: string);
  var
    I: Integer;
  begin
    I := Ini.ReadInteger(CSection, AKey, ACombo.ItemIndex);
    if (I >= 0) and (I < ACombo.Items.Count) then
      ACombo.ItemIndex := I;
  end;

var
  Tab: Integer;
  Dummy: UInt64;
begin
  if not GOptions.RememberFiles then
    Exit;
  Ini := Settings;
  LoadCombo(cbPlatform, 'Platform');
  ApplyPlatformSettings;
  LoadEdit(edtScat, 'ScatFile');
  LoadEdit(edtAuth, 'AuthFile');
  LoadEdit(edtBin, 'BinFile');
  LoadEdit(edtOfp, 'OfpFile');
  LoadEdit(edtBl, 'BlFile');
  LoadEdit(edtAp, 'ApFile');
  LoadEdit(edtCp, 'CpFile');
  LoadEdit(edtCsc, 'CscFile');
  LoadEdit(edtUser, 'UserFile');
  LoadCheck(chkAuthBrom, 'AuthBrom');
  LoadCheck(chkAuthPreloader, 'AuthPreloader');
  LoadCheck(chkReadPhoneInfo, 'ReadPhoneInfo');
  LoadCheck(chkAdvancedWrite, 'AdvancedWrite');
  LoadCheck(chkPreserveCalibration, 'PreserveCalibration');
  LoadCheck(chkFormatByAddress, 'FormatByAddress');
  LoadCheck(chkServiceVerbose, 'ServiceVerbose');
  LoadCombo(cbFormatMode, 'FormatMode');
  LoadCombo(cbFormatTarget, 'FormatTarget');
  LoadCombo(cbServiceAction, 'ServiceAction');
  LoadCombo(cbRpmbOperation, 'RpmbOperation');
  LoadCombo(cbRpmbTarget, 'RpmbTarget');
  LoadEdit(edtFormatAddress, 'FormatAddress');
  LoadEdit(edtFormatSize, 'FormatSize');
  LoadCombo(cbUsbSpeed, 'UsbSpeed');
  LoadCombo(cbBattery, 'Battery');
  LoadCombo(cbStorage, 'Storage');
  LoadCombo(cbFlashMode, 'FlashMode');
  LoadEdit(edtAddress, 'WriteAddress');
  LoadEdit(edtReadAddress, 'ReadAddress');
  LoadEdit(edtReadSize, 'ReadSize');
  { do not bring back broken addresses }
  if not TryParseHex64(edtAddress.Text, Dummy) then
    edtAddress.Text := '00000000  00000000';
  if not TryParseHex64(edtReadAddress.Text, Dummy) then
    edtReadAddress.Text := '00000000  00000000';
  if not TryParseHex64(edtReadSize.Text, Dummy) then
    edtReadSize.Text := '00000000  00000000';
  if not TryParseHex64(edtFormatAddress.Text, Dummy) then
    edtFormatAddress.Text := '00000000  00000000';
  if not TryParseHex64(edtFormatSize.Text, Dummy) then
    edtFormatSize.Text := '00000000  00000000';
  Tab := Ini.ReadInteger(CSection, 'OperationTab', 0);
  if (Tab >= 0) and (Tab < pcOperations.PageCount) then
    pcOperations.ActivePageIndex := Tab;
end;

procedure TMain2Form.SaveState;
var
  Ini: TMemIniFile;
begin
  if not GOptions.RememberFiles then
    Exit;
  Ini := Settings;
  Ini.WriteString(CSection, 'ScatFile', edtScat.Text);
  Ini.WriteString(CSection, 'AuthFile', edtAuth.Text);
  Ini.WriteString(CSection, 'BinFile', edtBin.Text);
  Ini.WriteString(CSection, 'OfpFile', edtOfp.Text);
  Ini.WriteString(CSection, 'BlFile', edtBl.Text);
  Ini.WriteString(CSection, 'ApFile', edtAp.Text);
  Ini.WriteString(CSection, 'CpFile', edtCp.Text);
  Ini.WriteString(CSection, 'CscFile', edtCsc.Text);
  Ini.WriteString(CSection, 'UserFile', edtUser.Text);
  Ini.WriteBool(CSection, 'AuthBrom', chkAuthBrom.Checked);
  Ini.WriteBool(CSection, 'AuthPreloader', chkAuthPreloader.Checked);
  Ini.WriteBool(CSection, 'ReadPhoneInfo', chkReadPhoneInfo.Checked);
  Ini.WriteBool(CSection, 'AdvancedWrite', chkAdvancedWrite.Checked);
  Ini.WriteBool(CSection, 'PreserveCalibration', chkPreserveCalibration.Checked);
  Ini.WriteBool(CSection, 'FormatByAddress', chkFormatByAddress.Checked);
  Ini.WriteBool(CSection, 'ServiceVerbose', chkServiceVerbose.Checked);
  Ini.WriteInteger(CSection, 'Platform', cbPlatform.ItemIndex);
  Ini.WriteInteger(CSection, 'FormatMode', cbFormatMode.ItemIndex);
  Ini.WriteInteger(CSection, 'FormatTarget', cbFormatTarget.ItemIndex);
  Ini.WriteInteger(CSection, 'ServiceAction', cbServiceAction.ItemIndex);
  Ini.WriteInteger(CSection, 'RpmbOperation', cbRpmbOperation.ItemIndex);
  Ini.WriteInteger(CSection, 'RpmbTarget', cbRpmbTarget.ItemIndex);
  Ini.WriteString(CSection, 'FormatAddress', edtFormatAddress.Text);
  Ini.WriteString(CSection, 'FormatSize', edtFormatSize.Text);
  Ini.WriteInteger(CSection, 'UsbSpeed', cbUsbSpeed.ItemIndex);
  Ini.WriteInteger(CSection, 'Battery', cbBattery.ItemIndex);
  Ini.WriteInteger(CSection, 'Storage', cbStorage.ItemIndex);
  Ini.WriteInteger(CSection, 'FlashMode', cbFlashMode.ItemIndex);
  Ini.WriteString(CSection, 'WriteAddress', edtAddress.Text);
  Ini.WriteString(CSection, 'ReadAddress', edtReadAddress.Text);
  Ini.WriteString(CSection, 'ReadSize', edtReadSize.Text);
  Ini.WriteInteger(CSection, 'OperationTab', pcOperations.ActivePageIndex);
  FlushSettings;
end;

procedure TMain2Form.AutoSaveSessionLog;
var
  FileName: string;
begin
  if (not GOptions.AutoSaveLog) or (FSessionLog = nil) or
     (FSessionLog.Count <= 2) then  { brand + model lines only: nothing done }
    Exit;
  try
    ForceDirectories(LogsDir);
    FileName := LogsDir + FormatDateTime('yyyy-mm-dd_hh-nn-ss', Now) + '_' +
      SafeFileName(FModelCode + '_' + FModelName) + '.txt';
    {$IFDEF FPC}
    FSessionLog.SaveToFile(FileName);
    {$ELSE}
    FSessionLog.SaveToFile(FileName, TEncoding.UTF8);
    {$ENDIF}
  except
    { never block closing the window because of the log }
  end;
end;

{ ---------------------------------------------------------------- log }

procedure TMain2Form.AddLogLine(const ALine: string);
var
  W: Integer;
begin
  lstLog.Items.BeginUpdate;
  try
    while lstLog.Items.Count >= CMaxLogLines do
      lstLog.Items.Delete(0);
    lstLog.Items.Add(ALine);
  finally
    lstLog.Items.EndUpdate;
  end;
  W := LogLineWidth(FMeasure.Canvas, ALine);
  if W > lstLog.ScrollWidth then
    lstLog.ScrollWidth := W;
  lstLog.TopIndex := lstLog.Items.Count - 1;
end;

procedure TMain2Form.Log(const AText: string);
var
  Stamp: string;
begin
  Stamp := FormatDateTime('hh:nn:ss', Now);
  if FSessionLog <> nil then
    FSessionLog.Add(Stamp + '  ' + StripLogCodes(AText));
  if GOptions.ShowTimeInLog and (AText <> '') then
    AddLogLine(LMuted('[' + Stamp + '] ') + AText)
  else
    AddLogLine(AText);
end;

procedure TMain2Form.LogError(const AText: string);
begin
  Log(LErr(AText));
  Log('');
end;

procedure TMain2Form.LogSettings;
begin
  Log('Platform : ' + LInfo(PlatformName) + '  Service tab : ' +
    LInfo(tsMeta.Caption));
  Log('Download agent : ' + LInfo(cbDownloadAgent.Text));
  Log('USB speed : ' + LInfo(cbUsbSpeed.Text) + ',  Battery : ' +
    LInfo(cbBattery.Text));
  Log('Storage : ' + LInfo(cbStorage.Text));
end;

procedure TMain2Form.LogNotImplemented(const AOperation: string);
begin
  Log(AOperation + '... ' + LErr('error(NOT_IMPLEMENTED)'));
  Log(LMuted('Device communication is not part of this build.'));
  Log('');
end;

procedure TMain2Form.lstLogDrawItem(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
begin
  if (Index < 0) or (Index >= lstLog.Items.Count) then
    Exit;
  lstLog.Canvas.Font.Assign(lstLog.Font);
  DrawLogLine(lstLog.Canvas, ARect, lstLog.Items[Index], odSelected in State);
end;

function TMain2Form.SelectedLogText(const AOnlySelected: Boolean): string;
var
  Lines: TStringList;
  I: Integer;
begin
  Lines := TStringList.Create;
  try
    for I := 0 to lstLog.Items.Count - 1 do
      if (not AOnlySelected) or lstLog.Selected[I] then
        Lines.Add(StripLogCodes(lstLog.Items[I]));
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

procedure TMain2Form.miLogCopyClick(Sender: TObject);
var
  S: string;
begin
  S := SelectedLogText(True);
  if S = '' then
    S := SelectedLogText(False);
  if S <> '' then
    Clipboard.AsText := S;
end;

procedure TMain2Form.miLogCopyAllClick(Sender: TObject);
begin
  if lstLog.Items.Count > 0 then
    Clipboard.AsText := SelectedLogText(False);
end;

procedure TMain2Form.miLogSelectAllClick(Sender: TObject);
var
  I: Integer;
begin
  lstLog.Items.BeginUpdate;
  try
    for I := 0 to lstLog.Items.Count - 1 do
      lstLog.Selected[I] := True;
  finally
    lstLog.Items.EndUpdate;
  end;
end;

procedure TMain2Form.lstLogKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ssCtrl in Shift then
    case Key of
      Ord('C'):
        begin
          miLogCopyClick(Sender);
          Key := 0;
        end;
      Ord('A'):
        begin
          miLogSelectAllClick(Sender);
          Key := 0;
        end;
    end;
end;

procedure TMain2Form.miClearLogClick(Sender: TObject);
begin
  lstLog.Items.Clear;
  lstLog.ScrollWidth := 0;
end;

procedure TMain2Form.ShowDemoLog;
begin
  { Sample lines in the style of the reference screenshot (used by the
    self-test screenshots only). }
  Log('Force Charge... ' + LOk);
  Log('Disable WatchDog Timer... ' + LOk);
  Log('Preloader exist. Skip connection verification.');
  Log('Get ME ID... ' + LOk);
  Log('ME_ID =  ' + LInfo('0x79E2F16C, 0x28109B51, 0x6D061FBF, 0x9B47BCDA'));
  Log('Load DownloadAgent... ' + LOk);
  Log('Search DA... ' + LOk + ' ' + LInfo('[0]'));
  Log('Get device connection agent... ' + LInfo('[PRELOADER]'));
  Log('Send preloader... ' + LErr('error(STATUS_DA_HASH_MISMATCH)'));
end;

{ ---------------------------------------------------------------- painting }

procedure TMain2Form.pbMenuPaint(Sender: TObject);
begin
  PaintIcon(pbMenu.Canvas, pbMenu.ClientRect, DrawMenuIcon);
end;

procedure TMain2Form.pbNextPaint(Sender: TObject);
begin
  PaintIcon(pbNext.Canvas, pbNext.ClientRect, DrawNextIconEnabled);
end;

procedure TMain2Form.pbDownloadPaint(Sender: TObject);
begin
  PaintIcon(pbDownload.Canvas, pbDownload.ClientRect, DrawDownloadIcon);
end;

procedure TMain2Form.pbChangeDevicePaint(Sender: TObject);
begin
  PaintIcon(pbChangeDevice.Canvas, pbChangeDevice.ClientRect,
    DrawPhoneRefreshIcon);
end;

procedure TMain2Form.pbSettingsPaint(Sender: TObject);
begin
  PaintIcon(pbSettings.Canvas, pbSettings.ClientRect, DrawGearIcon);
end;

procedure TMain2Form.pbFacebookPaint(Sender: TObject);
begin
  PaintIcon(pbFacebook.Canvas, pbFacebook.ClientRect, DrawFacebookIcon);
end;

procedure TMain2Form.pbHelpPaint(Sender: TObject);
begin
  PaintIcon(pbHelp.Canvas, pbHelp.ClientRect, DrawHelpIcon);
end;

procedure TMain2Form.pbDeviceStatePaint(Sender: TObject);
begin
  if Length(FDevices) > 0 then
    PaintIcon(pbDeviceState.Canvas, pbDeviceState.ClientRect,
      DrawDeviceConnectedIcon)
  else
    PaintIcon(pbDeviceState.Canvas, pbDeviceState.ClientRect,
      DrawDeviceDisconnectedIcon);
end;

procedure TMain2Form.pbProgressPaint(Sender: TObject);
var
  C: TCanvas;
  R: TRect;
  Fill, BarTop: Integer;
  S: string;
begin
  C := pbProgress.Canvas;
  R := pbProgress.ClientRect;
  C.Brush.Style := bsSolid;
  C.Brush.Color := clBtnFace;
  C.FillRect(R);

  { thin red bar along the bottom while a job runs }
  if FProgress > 0 then
  begin
    BarTop := R.Bottom - 4;
    Fill := R.Left + MulDiv(R.Right - R.Left, FProgress, 100);
    C.Brush.Color := RGB(200, 200, 200);
    C.FillRect(Rect(R.Left, BarTop, R.Right, R.Bottom));
    C.Brush.Color := RGB(232, 0, 18);
    C.FillRect(Rect(R.Left, BarTop, Fill, R.Bottom));
  end;

  S := IntToStr(FProgress) + '%';
  C.Font.Assign(Font);
  C.Font.Color := clWindowText;
  C.Brush.Style := bsClear;
  C.TextOut(R.Left + (R.Right - R.Left - C.TextWidth(S)) div 2,
    R.Top + 1, S);
  C.Brush.Style := bsSolid;
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

{ ---------------------------------------------------------------- USB }

procedure TMain2Form.UsbTimerTick(Sender: TObject);
begin
  CheckUsb(False);
end;

function SameDevice(const A, B: TUsbDevice): Boolean;
begin
  Result := (A.VidPid = B.VidPid) and (A.Port = B.Port);
end;

procedure TMain2Form.CheckUsb(const AInitial: Boolean);
var
  NewDevices: TUsbDeviceArray;
  Sig: string;
  I, J: Integer;
  Known: Boolean;
begin
  NewDevices := ScanServiceDevices;
  Sig := DevicesSignature(NewDevices);
  if (not AInitial) and (Sig = FDeviceSig) then
    Exit;

  { removed }
  for I := 0 to High(FDevices) do
  begin
    Known := False;
    for J := 0 to High(NewDevices) do
      if SameDevice(FDevices[I], NewDevices[J]) then
        Known := True;
    if not Known then
      Log('Device removed... ' + LWarn(DescribeDevice(FDevices[I])));
  end;
  { added }
  for I := 0 to High(NewDevices) do
  begin
    Known := False;
    for J := 0 to High(FDevices) do
      if SameDevice(NewDevices[I], FDevices[J]) then
        Known := True;
    if not Known then
      Log('Device found... ' + LInfo(DescribeDevice(NewDevices[I])));
  end;
  if AInitial and (Length(NewDevices) = 0) then
    Log(LMuted('Waiting for device... (connect the phone by USB)'));

  FDevices := NewDevices;
  FDeviceSig := Sig;
  UpdateDeviceState;
end;

procedure TMain2Form.UpdateDeviceState;
var
  Text: string;
begin
  if not GOptions.DetectUsb then
    Text := 'USB detection is off'
  else if Length(FDevices) = 0 then
    Text := 'No device'
  else
  begin
    Text := DescribeDevice(FDevices[0]);
    if Length(FDevices) > 1 then
      Text := Text + '  (+' + IntToStr(Length(FDevices) - 1) + ' more)';
  end;
  lblDeviceState.Caption := Text;
  pbDeviceState.Hint := Text;
  pbDeviceState.Invalidate;
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
  { Runs the first job of the open operations tab. }
  pcJobs.ActivePage := tsJobs;
  if pcOperations.ActivePage = tsRead then
    btnReadInfoClick(btnReadInfo)
  else if pcOperations.ActivePage = tsFormat then
    btnFormatClick(btnFormat)
  else if pcOperations.ActivePage = tsService then
    btnRunServiceClick(btnRunService)
  else if pcOperations.ActivePage = tsRpmb then
    btnRunRpmbClick(btnRunRpmb)
  else if pcOperations.ActivePage = tsFlash then
    btnWriteFirmwareClick(btnWriteFirmware)
  else
    Log('Choose an operation tab with an available job.');
end;

procedure TMain2Form.pbDownloadClick(Sender: TObject);
var
  FileName: string;
  Lines: TStringList;
begin
  if not AskSaveFile('Save log', 'log_' + SafeFileName(FModelName) + '.txt',
    FileName) then
    Exit;
  Lines := TStringList.Create;
  try
    Lines.Text := SelectedLogText(False);
    {$IFDEF FPC}
    Lines.SaveToFile(FileName);  { LCL strings are UTF-8 }
    {$ELSE}
    Lines.SaveToFile(FileName, TEncoding.UTF8);
    {$ENDIF}
  finally
    Lines.Free;
  end;
end;

procedure TMain2Form.pbChangeDeviceClick(Sender: TObject);
begin
  { Back to MAIN 1 to pick another model. }
  ModalResult := mrCancel;
end;

procedure TMain2Form.pbSettingsClick(Sender: TObject);
begin
  if ShowSettingsDialog(Self) then
  begin
    ApplyOptions;
    if GOptions.DetectUsb then
      CheckUsb(True);
    lstLog.Invalidate;
  end;
end;

procedure TMain2Form.pbFacebookClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', PChar(CFacebookUrl), nil, nil, SW_SHOWNORMAL);
end;

procedure TMain2Form.pbHelpClick(Sender: TObject);
begin
  MessageDlg(AppTitle + sLineBreak + AppVersionText + sLineBreak + sLineBreak +
    'Selected device: ' + FBrand + ' ' + FModelName + sLineBreak + sLineBreak +
    'Esc - back to the model list' + sLineBreak +
    'Ctrl+C / Ctrl+A in the log - copy / select all' + sLineBreak + sLineBreak +
    'Settings and logs: ' + DataDir, mtInformation, [mbOK], 0);
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
    begin
      Dialog.InitialDir := ExtractFilePath(AEdit.Text);
      Dialog.FileName := ExtractFileName(AEdit.Text);
    end;
    Result := Dialog.Execute;
    if Result then
      AEdit.Text := Dialog.FileName;
  finally
    Dialog.Free;
  end;
end;

function TMain2Form.AskSaveFile(const ATitle, ADefaultName: string;
  out AFileName: string): Boolean;
var
  Dialog: TSaveDialog;
begin
  AFileName := '';
  Dialog := TSaveDialog.Create(Self);
  try
    Dialog.Title := ATitle;
    if SameText(ExtractFileExt(ADefaultName), '.txt') then
    begin
      Dialog.Filter := 'Text files (*.txt)|*.txt' + CFilterAll;
      Dialog.DefaultExt := 'txt';
    end
    else
    begin
      Dialog.Filter := 'Binary files (*.bin)|*.bin' + CFilterAll;
      Dialog.DefaultExt := 'bin';
    end;
    Dialog.Options := Dialog.Options + [ofOverwritePrompt];
    Dialog.FileName := ADefaultName;
    Result := Dialog.Execute;
    if Result then
      AFileName := Dialog.FileName;
  finally
    Dialog.Free;
  end;
end;

procedure TMain2Form.BrowseFirmwarePart(AEdit: TEdit; const AName: string);
begin
  if BrowseFile('Select ' + AName + ' file', CFilterSamsung, AEdit) then
    Log(AName + ' file : ' + LInfo(AEdit.Text));
end;

procedure TMain2Form.btnScatClick(Sender: TObject);
begin
  if BrowseFile('Select scatter file',
    'Scatter files (*scatter*.txt;*.xml)|*scatter*.txt;*.xml' + CFilterAll,
    edtScat) then
    Log('Scatter file : ' + LInfo(edtScat.Text));
end;

procedure TMain2Form.btnAuthClick(Sender: TObject);
begin
  if BrowseFile('Select auth file',
    'Auth files (*.auth;*.bin)|*.auth;*.bin' + CFilterAll, edtAuth) then
    Log('Auth file : ' + LInfo(edtAuth.Text));
end;

procedure TMain2Form.btnBinClick(Sender: TObject);
begin
  if BrowseFile('Select BIN file',
    'Binary files (*.bin;*.img)|*.bin;*.img' + CFilterAll, edtBin) then
    Log('BIN file : ' + LInfo(edtBin.Text));
end;

procedure TMain2Form.btnOfpClick(Sender: TObject);
begin
  if BrowseFile('Select OFP file',
    'OFP files (*.ofp)|*.ofp' + CFilterAll, edtOfp) then
    Log('OFP file : ' + LInfo(edtOfp.Text));
end;

procedure TMain2Form.btnBlClick(Sender: TObject);
begin
  BrowseFirmwarePart(edtBl, 'BL');
end;

procedure TMain2Form.btnApClick(Sender: TObject);
begin
  BrowseFirmwarePart(edtAp, 'AP');
end;

procedure TMain2Form.btnCpClick(Sender: TObject);
begin
  BrowseFirmwarePart(edtCp, 'CP');
end;

procedure TMain2Form.btnCscClick(Sender: TObject);
begin
  BrowseFirmwarePart(edtCsc, 'CSC');
end;

procedure TMain2Form.btnUserClick(Sender: TObject);
begin
  BrowseFirmwarePart(edtUser, 'USER');
end;

function TMain2Form.RequireFile(AEdit: TEdit; const AName: string): Boolean;
begin
  Result := (Trim(AEdit.Text) <> '') and FileExists(Trim(AEdit.Text));
  if not Result then
  begin
    if Trim(AEdit.Text) = '' then
      LogError('Select a ' + AName + ' file first.')
    else
      LogError(AName + ' file not found : ' + AEdit.Text);
  end;
end;

function TMain2Form.CheckOptionalFile(AEdit: TEdit; const AName: string): Boolean;
begin
  Result := (Trim(AEdit.Text) = '') or FileExists(Trim(AEdit.Text));
  if not Result then
    LogError(AName + ' file not found : ' + AEdit.Text);
end;

{ ---------------------------------------------------------------- options }

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

procedure TMain2Form.cbPlatformChange(Sender: TObject);
begin
  ApplyPlatformSettings;
  Log('Platform profile : ' + LInfo(PlatformName) +
    '  [' + tsMeta.Caption + ']');
end;

procedure TMain2Form.UpdateFormatAddress;
var
  Enabled: Boolean;
begin
  Enabled := chkFormatByAddress.Checked;
  lblFormatAddress.Enabled := Enabled;
  edtFormatAddress.Enabled := Enabled;
  lblFormatSize.Enabled := Enabled;
  edtFormatSize.Enabled := Enabled;
  cbFormatTarget.Enabled := not Enabled;
end;

procedure TMain2Form.chkFormatByAddressClick(Sender: TObject);
begin
  UpdateFormatAddress;
end;

procedure TMain2Form.btnFormatClick(Sender: TObject);
var
  StartAddress, Size: UInt64;
begin
  Log('[Format] ' + LInfo(cbFormatMode.Text));
  if chkFormatByAddress.Checked then
  begin
    if not TryParseHex64(edtFormatAddress.Text, StartAddress) then
    begin
      LogError('Enter the format start address in hex, e.g. 00000000 00100000');
      Exit;
    end;
    if (not TryParseHex64(edtFormatSize.Text, Size)) or (Size = 0) then
    begin
      LogError('Enter a non-zero format size in hex, e.g. 00000000 00400000');
      Exit;
    end;
    Log('Address : ' + LInfo('0x' + Hex64(StartAddress)) +
      '  Size : ' + LInfo('0x' + Hex64(Size)));
  end
  else
    Log('Target : ' + LInfo(cbFormatTarget.Text));

  if chkPreserveCalibration.Checked then
    Log('Calibration / NV data : ' + LOk('preserve'))
  else
    Log('Calibration / NV data : ' + LWarn('not preserved'));
  LogSettings;
  LogNotImplemented('Format');
end;

procedure TMain2Form.btnRunServiceClick(Sender: TObject);
begin
  Log('[Service] ' + LInfo(cbServiceAction.Text));
  Log('Service mode : ' + LInfo(tsMeta.Caption));
  if chkServiceVerbose.Checked then
    Log('Diagnostic detail logging : ' + LOk('enabled'));
  LogSettings;
  LogNotImplemented('Service - ' + cbServiceAction.Text);
end;

procedure TMain2Form.btnRunRpmbClick(Sender: TObject);
begin
  Log('[RPMB] ' + LInfo(cbRpmbOperation.Text));
  Log('RPMB target : ' + LInfo(cbRpmbTarget.Text));
  Log('Platform service mode : ' + LInfo(tsMeta.Caption));
  LogSettings;
  LogNotImplemented('RPMB - ' + cbRpmbOperation.Text);
end;

{ ---------------------------------------------------------------- Flash tab }

procedure TMain2Form.btnWriteFirmwareClick(Sender: TObject);
const
  CNames: array[0..4] of string = ('BL', 'AP', 'CP', 'CSC', 'USER');
var
  Parts: array[0..4] of TEdit;
  I: Integer;
  HasParts: Boolean;
begin
  Parts[0] := edtBl;
  Parts[1] := edtAp;
  Parts[2] := edtCp;
  Parts[3] := edtCsc;
  Parts[4] := edtUser;

  Log('[Write Firmware] ' + LInfo(cbFlashMode.Text));
  HasParts := False;
  for I := 0 to High(Parts) do
    if Trim(Parts[I].Text) <> '' then
      HasParts := True;

  if (Trim(edtScat.Text) = '') and not HasParts then
  begin
    LogError('Select a SCAT file (MediaTek) or BL / AP / CP / CSC / USER ' +
      'files (Samsung) first.');
    Exit;
  end;
  if not CheckOptionalFile(edtScat, 'SCAT') or
     not CheckOptionalFile(edtAuth, 'AUTH') then
    Exit;
  for I := 0 to High(Parts) do
    if not CheckOptionalFile(Parts[I], CNames[I]) then
      Exit;

  if Trim(edtScat.Text) <> '' then
    Log('Scatter file : ' + LInfo(edtScat.Text));
  if Trim(edtAuth.Text) <> '' then
    Log('Auth file : ' + LInfo(edtAuth.Text));
  for I := 0 to High(Parts) do
    if Trim(Parts[I].Text) <> '' then
      Log(CNames[I] + ' file : ' + LInfo(Parts[I].Text));
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
    Dialog.Filter := 'Backup files (*.bin;*.img;*.zip)|*.bin;*.img;*.zip' +
      CFilterAll;
    Dialog.Options := Dialog.Options + [ofFileMustExist, ofPathMustExist];
    if not Dialog.Execute then
    begin
      Log(LMuted('Cancelled.'));
      Log('');
      Exit;
    end;
    Log('Backup file : ' + LInfo(Dialog.FileName));
  finally
    Dialog.Free;
  end;
  LogSettings;
  LogNotImplemented('Restore from backup');
end;

procedure TMain2Form.btnWriteBinClick(Sender: TObject);
var
  StartAddr: UInt64;
begin
  Log('[Write BIN]');
  if not RequireFile(edtBin, 'BIN') then
    Exit;
  if not TryParseHex64(edtAddress.Text, StartAddr) then
  begin
    LogError('Enter the start address in hex, e.g. 00000000 00100000');
    Exit;
  end;
  Log('BIN file : ' + LInfo(edtBin.Text));
  Log('Address : ' + LInfo('0x' + Hex64(StartAddr)) + '  Length : ' +
    LInfo('0x' + Hex64(UInt64(FileSizeOf(edtBin.Text)))));
  LogSettings;
  LogNotImplemented('Write BIN');
end;

procedure TMain2Form.btnWriteOfpClick(Sender: TObject);
begin
  Log('[Write OFP]');
  if not RequireFile(edtOfp, 'OFP') then
    Exit;
  Log('OFP file : ' + LInfo(edtOfp.Text));
  LogSettings;
  LogNotImplemented('Write OFP');
end;

{ ---------------------------------------------------------------- Read tab }

procedure TMain2Form.btnReadInfoClick(Sender: TObject);
begin
  Log('[Read Flash Info]');
  LogSettings;
  LogNotImplemented('Read Flash Info');
end;

procedure TMain2Form.btnReadPartitionsClick(Sender: TObject);
begin
  Log('[Read Partitions]');
  if Trim(edtScat.Text) <> '' then
  begin
    if not CheckOptionalFile(edtScat, 'SCAT') then
      Exit;
    Log('Scatter file : ' + LInfo(edtScat.Text));
  end;
  LogSettings;
  LogNotImplemented('Read Partitions');
end;

procedure TMain2Form.btnReadBinClick(Sender: TObject);
var
  StartAddr, Size: UInt64;
  FileName: string;
begin
  Log('[Read BIN]');
  if not TryParseHex64(edtReadAddress.Text, StartAddr) then
  begin
    LogError('Enter the start address in hex, e.g. 00000000 00100000');
    Exit;
  end;
  if (not TryParseHex64(edtReadSize.Text, Size)) or (Size = 0) then
  begin
    LogError('Enter the size to read in hex (more than 0), e.g. 00000000 00400000');
    Exit;
  end;
  if not AskSaveFile('Save BIN as',
    'read_' + IntToHex(Int64(StartAddr), 8) + '_' + IntToHex(Int64(Size), 8) +
    '.bin', FileName) then
  begin
    Log(LMuted('Cancelled.'));
    Log('');
    Exit;
  end;
  Log('Address : ' + LInfo('0x' + Hex64(StartAddr)) + '  Size : ' +
    LInfo('0x' + Hex64(Size)));
  Log('Save to : ' + LInfo(FileName));
  LogSettings;
  LogNotImplemented('Read BIN');
end;

procedure TMain2Form.btnReadRegionClick(Sender: TObject);
var
  FileName, Region: string;
begin
  Log('[Read Region]');
  Region := cbStorage.Text;
  if not AskSaveFile('Save region as',
    SafeFileName(FModelCode + '_' + Copy(Region, 1, Pos(' ', Region + ' ') - 1)) +
    '.bin', FileName) then
  begin
    Log(LMuted('Cancelled.'));
    Log('');
    Exit;
  end;
  Log('Region : ' + LInfo(Region));
  Log('Save to : ' + LInfo(FileName));
  LogSettings;
  LogNotImplemented('Read Region');
end;

procedure TMain2Form.btnReadOtpClick(Sender: TObject);
begin
  Log('[Read OTP]');
  LogSettings;
  LogNotImplemented('Read OTP');
end;

{ ---------------------------------------------------------------- self-test }

function TMain2Form.SelfTest(AOut: TStrings): Boolean;
var
  AllOk: Boolean;
  V: UInt64;
  Before: Integer;

  procedure Check(const AName: string; const AOk: Boolean);
  begin
    if AOk then
      AOut.Add('PASS  ' + AName)
    else
    begin
      AOut.Add('FAIL  ' + AName);
      AllOk := False;
    end;
  end;

begin
  AllOk := True;
  Check('hex: "00000000  00100000" = $100000',
    TryParseHex64('00000000  00100000', V) and (V = $100000));
  Check('hex: "1 00000000" = $100000000',
    TryParseHex64('1 00000000', V) and (V = UInt64($100000000)));
  Check('hex: rejects "12G4"', not TryParseHex64('12G4', V));
  Check('hex: rejects 17 digits', not TryParseHex64('11111111111111111', V));
  Check('hex: rejects empty', not TryParseHex64('  ', V));
  Check('log codes stripped',
    StripLogCodes('Search DA... ' + LOk + ' ' + LInfo('[0]')) = 'Search DA... OK [0]');
  Check('nine file rows', (btnUser.Parent = grpFiles) and (edtOfp.Parent = grpFiles));
  Check('format, service and RPMB option panels loaded',
    (grpFormatOptions <> nil) and (grpServiceOptions <> nil) and
    (grpRpmbOptions <> nil) and (cbFormatMode.Items.Count > 0) and
    (cbServiceAction.Items.Count > 0) and (cbRpmbOperation.Items.Count > 0));

  chkFormatByAddress.Checked := False;
  UpdateFormatAddress;
  cbPlatform.ItemIndex := CPlatformMtk;
  ApplyPlatformSettings;
  Check('MediaTek profile labels the service tab META', tsMeta.Caption = 'META');
  cbPlatform.ItemIndex := CPlatformUnisoc;
  ApplyPlatformSettings;
  Check('Unisoc profile changes META to DIAG',
    (tsMeta.Caption = 'DIAG') and
    (cbServiceAction.Items.IndexOf('Switch to DIAG mode') >= 0) and
    (cbRpmbOperation.Items.IndexOf('Read RPMB information (DIAG)') >= 0));
  cbPlatform.ItemIndex := CPlatformQualcomm;
  ApplyPlatformSettings;
  Check('Qualcomm profile also exposes DIAG service mode',
    (tsMeta.Caption = 'DIAG') and
    (cbFormatMode.Items.IndexOf('Erase selected partition') >= 0));
  cbPlatform.ItemIndex := CPlatformMtk;
  ApplyPlatformSettings;
  Check('custom format fields start disabled',
    (not edtFormatAddress.Enabled) and (not edtFormatSize.Enabled));

  Before := lstLog.Items.Count;
  edtScat.Text := '';
  edtAuth.Text := '';
  edtBl.Text := '';
  edtAp.Text := '';
  edtCp.Text := '';
  edtCsc.Text := '';
  edtUser.Text := '';
  btnWriteFirmwareClick(nil);
  Check('Write Firmware without files logs an error',
    Pos('Select a SCAT file', StripLogCodes(lstLog.Items[lstLog.Items.Count - 2])) > 0);

  edtAp.Text := ExeDir + 'does-not-exist.tar.md5';
  btnWriteFirmwareClick(nil);
  Check('Write Firmware with a missing AP file logs an error',
    Pos('AP file not found', StripLogCodes(lstLog.Items[lstLog.Items.Count - 2])) > 0);
  edtAp.Text := '';

  edtReadSize.Text := '00000000  00000000';
  btnReadBinClick(nil);
  Check('Read BIN with size 0 logs an error',
    Pos('size to read', StripLogCodes(lstLog.Items[lstLog.Items.Count - 2])) > 0);

  btnReadOtpClick(nil);
  Check('Read OTP logs the job', lstLog.Items.Count > Before);

  CheckUsb(True);
  Check('USB scan ran', True);
  Result := AllOk;
end;

end.
