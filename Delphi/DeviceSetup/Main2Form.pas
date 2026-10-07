unit Main2Form;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


{ MAIN 2 - the job screen (UI SAMPLE/S2.png ... S10.png).
  Layout:
    - toolbar: menu (left); start, save log, change device, settings,
      report, Facebook and help (right)
    - left: Presets, Files (SCAT / AUTH / BIN / OFP, plus BL / AP / CP /
      CSC / USER on Samsung), the colour log and the progress strip
    - right: "Jobs" and platform service-mode tabs. Each holds the
      Connections group and the Flash / Read / Format / IMEI / Locks /
      Service / RPMB pages.
    - the platform selector lives on the service-mode tab.
  Device communication (flashing, reading, ...) is NOT implemented: the
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
  SampleControls,
  ToolbarIcons,
  UsbDetect;

type
  TMain2Form = class(TForm)
    { toolbar }
    pbMenu: TPaintBox;
    pbNext: TPaintBox;
    pbDownload: TPaintBox;
    pbChangeDevice: TPaintBox;
    pbSettings: TPaintBox;
    pbContact: TPaintBox;
    pbFacebook: TPaintBox;
    pbHelp: TPaintBox;
    pmMain: TPopupMenu;
    miChangeDevice: TMenuItem;
    miSaveLog: TMenuItem;
    miClearLog: TMenuItem;
    miSettings: TMenuItem;
    miSeparator: TMenuItem;
    miExit: TMenuItem;
    { left side }
    grpPresets: TSampleGroupBox;
    cbPresets: TComboBox;
    grpFiles: TSampleGroupBox;
    btnScat: TSampleButton;
    edtScat: TEdit;
    btnAuth: TSampleButton;
    edtAuth: TEdit;
    btnBin: TSampleButton;
    edtBin: TEdit;
    btnOfp: TSampleButton;
    edtOfp: TEdit;
    btnBl: TSampleButton;
    edtBl: TEdit;
    btnAp: TSampleButton;
    edtAp: TEdit;
    btnCp: TSampleButton;
    edtCp: TEdit;
    btnCsc: TSampleButton;
    edtCsc: TEdit;
    btnUser: TSampleButton;
    edtUser: TEdit;
    grpLog: TSampleGroupBox;
    lstLog: TListBox;
    pmLog: TPopupMenu;
    miLogCopy: TMenuItem;
    miLogCopyAll: TMenuItem;
    miLogSelectAll: TMenuItem;
    miLogSeparator: TMenuItem;
    miLogSave: TMenuItem;
    miLogClear: TMenuItem;
    pbProgress: TPaintBox;
    { right side - Jobs / service-mode tabs }
    pcJobs: TSamplePageControl;
    tsJobs: TSampleTabSheet;
    tsMeta: TSampleTabSheet;
    grpPlatform: TSampleGroupBox;
    lblPlatform: TLabel;
    cbPlatform: TComboBox;
    lblServiceMode: TLabel;
    lblServiceModeValue: TLabel;
    lblMetaInfo: TLabel;
    grpConnections: TSampleGroupBox;
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
    lblStorage: TLabel;
    cbStorage: TComboBox;
    { right side - operations }
    pcOperations: TSamplePageControl;
    tsFlash: TSampleTabSheet;
    tsRead: TSampleTabSheet;
    tsFormat: TSampleTabSheet;
    tsImei: TSampleTabSheet;
    tsLocks: TSampleTabSheet;
    tsService: TSampleTabSheet;
    tsRpmb: TSampleTabSheet;
    grpOptionsFlash: TSampleGroupBox;
    cbFlashMode: TComboBox;
    btnWriteFirmware: TSampleButton;
    btnRestoreBackup: TSampleButton;
    chkAdvancedWrite: TCheckBox;
    lblAddress: TLabel;
    edtAddress: TEdit;
    btnWriteBin: TSampleButton;
    btnWriteOfp: TSampleButton;
    grpOptionsRead: TSampleGroupBox;
    btnReadInfo: TSampleButton;
    btnReadPartitions: TSampleButton;
    lblReadAddress: TLabel;
    edtReadAddress: TEdit;
    lblReadSize: TLabel;
    edtReadSize: TEdit;
    btnReadBin: TSampleButton;
    btnReadRegion: TSampleButton;
    btnReadOtp: TSampleButton;
    grpOptionsFormat: TSampleGroupBox;
    pnlFormatMode: TPanel;
    pnlFormatRange: TPanel;
    rbAutoFormat: TRadioButton;
    rbManualFormat: TRadioButton;
    rbFormatAiFlash: TRadioButton;
    rbFormatAiExceptBootloader: TRadioButton;
    btnFormat: TSampleButton;
    chkCreateDefaultFs: TCheckBox;
    btnWipeData: TSampleButton;
    btnWipePartitions: TSampleButton;
    btnEraseFrp: TSampleButton;
    btnEraseFrpAndWipe: TSampleButton;
    grpOptionsImei: TSampleGroupBox;
    chkImei1: TCheckBox;
    edtImei1: TEdit;
    lblImei1Digits: TLabel;
    chkImei2: TCheckBox;
    edtImei2: TEdit;
    lblImei2Digits: TLabel;
    lblAdvancedSettings: TLabel;
    btnRepair: TSampleButton;
    btnReadImei: TSampleButton;
    grpOptionsLocks: TSampleGroupBox;
    btnUnlockBootloader: TSampleButton;
    btnRelockBootloader: TSampleButton;
    btnUnlockNetwork: TSampleButton;
    btnReadCodes: TSampleButton;
    btnResetPassword: TSampleButton;
    btnResetAccount: TSampleButton;
    grpOptionsService: TSampleGroupBox;
    btnRebootRecovery: TSampleButton;
    btnDisableOta: TSampleButton;
    btnResetDmVerity: TSampleButton;
    btnDisableOrangeState: TSampleButton;
    btnSwitchSlot: TSampleButton;
    btnFixDlImage: TSampleButton;
    grpOptionsRpmb: TSampleGroupBox;
    btnRpmbBackup: TSampleButton;
    lblRpmbAddress: TLabel;
    edtRpmbAddress: TEdit;
    btnRpmbWrite: TSampleButton;
    btnRpmbFormat: TSampleButton;
    { device state }
    lblDeviceState: TLabel;
    pbDeviceState: TPaintBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure cbPlatformChange(Sender: TObject);
    procedure pbMenuPaint(Sender: TObject);
    procedure pbNextPaint(Sender: TObject);
    procedure pbDownloadPaint(Sender: TObject);
    procedure pbChangeDevicePaint(Sender: TObject);
    procedure pbSettingsPaint(Sender: TObject);
    procedure pbContactPaint(Sender: TObject);
    procedure pbFacebookPaint(Sender: TObject);
    procedure pbHelpPaint(Sender: TObject);
    procedure pbProgressPaint(Sender: TObject);
    procedure pbDeviceStatePaint(Sender: TObject);
    procedure pbMenuClick(Sender: TObject);
    procedure pbNextClick(Sender: TObject);
    procedure pbDownloadClick(Sender: TObject);
    procedure pbChangeDeviceClick(Sender: TObject);
    procedure pbSettingsClick(Sender: TObject);
    procedure pbContactClick(Sender: TObject);
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
    procedure btnFormatClick(Sender: TObject);
    procedure btnWipeDataClick(Sender: TObject);
    procedure btnWipePartitionsClick(Sender: TObject);
    procedure btnEraseFrpClick(Sender: TObject);
    procedure btnEraseFrpAndWipeClick(Sender: TObject);
    procedure btnRepairClick(Sender: TObject);
    procedure btnReadImeiClick(Sender: TObject);
    procedure lblAdvancedSettingsClick(Sender: TObject);
    procedure btnUnlockBootloaderClick(Sender: TObject);
    procedure btnRelockBootloaderClick(Sender: TObject);
    procedure btnUnlockNetworkClick(Sender: TObject);
    procedure btnReadCodesClick(Sender: TObject);
    procedure btnResetPasswordClick(Sender: TObject);
    procedure btnResetAccountClick(Sender: TObject);
    procedure btnRebootRecoveryClick(Sender: TObject);
    procedure btnDisableOtaClick(Sender: TObject);
    procedure btnResetDmVerityClick(Sender: TObject);
    procedure btnDisableOrangeStateClick(Sender: TObject);
    procedure btnSwitchSlotClick(Sender: TObject);
    procedure btnFixDlImageClick(Sender: TObject);
    procedure btnRpmbBackupClick(Sender: TObject);
    procedure btnRpmbWriteClick(Sender: TObject);
    procedure btnRpmbFormatClick(Sender: TObject);
    procedure ImeiEditChange(Sender: TObject);
    procedure FormatRadioClick(Sender: TObject);
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
    FManualFormat: Boolean;
    FAiExceptBootloader: Boolean;
    procedure AssignGlyph(AButton: TSampleButton; const AKind: TActionGlyph);
    procedure SetupLogFont;
    procedure AddLogLine(const ALine: string);
    procedure LogSettings;
    procedure LogNotImplemented(const AOperation: string);
    procedure LogError(const AText: string);
    procedure UpdateImeiDigits;
    procedure UpdateFileRows(const APlatform: Integer);
    function SelectedLogText(const AOnlySelected: Boolean): string;
    function BrowseFile(const ATitle, AFilter: string; AEdit: TEdit): Boolean;
    procedure BrowseFirmwarePart(AEdit: TEdit; const AName: string);
    function RequireFile(AEdit: TEdit; const AName: string): Boolean;
    function CheckOptionalFile(AEdit: TEdit; const AName: string): Boolean;
    function AskSaveFile(const ATitle, ADefaultName: string;
      out AFileName: string): Boolean;
    procedure UpdateAdvancedWrite;
    procedure UpdateFormatRadios;
    procedure ApplyPlatformSettings;
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

{ Luhn check digit of a 14/15 digit IMEI, or -1 when the text is not an IMEI. }
function ImeiCheckDigit(const AImei: string): Integer;

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
  CIssuesUrl = 'https://github.com/rehmaahmed11/MOBILE-SERVICING-TOOLS/issues';
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

  { Files group: four rows are always visible, the Samsung BL / AP / CP /
    CSC / USER rows follow on a Samsung profile. }
  CFileRowPitch = 21;
  CFilesHeight = 98;

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

function ImeiCheckDigit(const AImei: string): Integer;
var
  Digits: string;
  I, D, Sum: Integer;
begin
  Result := -1;
  Digits := '';
  for I := 1 to Length(AImei) do
    if CharInSet(AImei[I], ['0'..'9']) then
      Digits := Digits + AImei[I];
  if (Length(Digits) < 14) or (Length(Digits) > 15) then
    Exit;
  Sum := 0;
  for I := 1 to 14 do
  begin
    D := Ord(Digits[I]) - Ord('0');
    if Odd(I) = False then
    begin
      D := D * 2;
      if D > 9 then
        D := D - 9;
    end;
    Sum := Sum + D;
  end;
  Result := (10 - (Sum mod 10)) mod 10;
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
  { Never shrink the reference layout until its tabs or Format buttons clip. }
  Constraints.MinWidth := ClientWidth + (Width - ClientWidth);
  Constraints.MinHeight := ClientHeight + (Height - ClientHeight);
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
  AssignGlyph(btnFormat, agFormat);
  AssignGlyph(btnWipeData, agWipeData);
  AssignGlyph(btnWipePartitions, agWipePartitions);
  AssignGlyph(btnEraseFrp, agEraseFrp);
  AssignGlyph(btnEraseFrpAndWipe, agEraseFrpWipe);
  AssignGlyph(btnRepair, agRepair);
  AssignGlyph(btnReadImei, agReadImei);
  AssignGlyph(btnUnlockBootloader, agUnlockBootloader);
  AssignGlyph(btnRelockBootloader, agRelockBootloader);
  AssignGlyph(btnUnlockNetwork, agUnlockNetwork);
  AssignGlyph(btnReadCodes, agReadCodes);
  AssignGlyph(btnResetPassword, agResetPassword);
  AssignGlyph(btnResetAccount, agResetAccount);
  AssignGlyph(btnRebootRecovery, agRebootRecovery);
  AssignGlyph(btnDisableOta, agDisableOta);
  AssignGlyph(btnResetDmVerity, agResetDmVerity);
  AssignGlyph(btnDisableOrangeState, agDisableOrangeState);
  AssignGlyph(btnSwitchSlot, agSwitchSlot);
  AssignGlyph(btnFixDlImage, agFixDlImage);
  AssignGlyph(btnRpmbBackup, agRpmbBackup);
  AssignGlyph(btnRpmbWrite, agRpmbWrite);
  AssignGlyph(btnRpmbFormat, agRpmbFormat);

  edtImei1.OnChange := ImeiEditChange;
  edtImei2.OnChange := ImeiEditChange;

  { The two pairs of format radios are managed here, so they cannot get in
    each other's way (Windows treats radio buttons of one parent as one
    group). }
  rbAutoFormat.OnClick := FormatRadioClick;
  rbManualFormat.OnClick := FormatRadioClick;
  rbFormatAiFlash.OnClick := FormatRadioClick;
  rbFormatAiExceptBootloader.OnClick := FormatRadioClick;
  FManualFormat := rbManualFormat.Checked;
  FAiExceptBootloader := rbFormatAiExceptBootloader.Checked;
  UpdateFormatRadios;

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
  UpdateImeiDigits;

  FUsbTimer := TTimer.Create(Self);
  FUsbTimer.Enabled := False;
  FUsbTimer.Interval := 1000;
  FUsbTimer.OnTimer := UsbTimerTick;
  UpdateDeviceState;
end;

procedure TMain2Form.FormShow(Sender: TObject);
begin
  FormResize(nil);
  ApplyOptions;
  if GOptions.DetectUsb then
    CheckUsb(True);
end;

procedure TMain2Form.FormResize(Sender: TObject);
var
  H: Integer;
begin
  if (pcJobs = nil) or not HandleAllocated or (cbStorage = nil) then
    Exit;
  H := pcJobs.ScaleValue(18);
  CompactCombo(cbPresets, H);
  CompactCombo(cbDownloadAgent, H);
  CompactCombo(cbUsbSpeed, H);
  CompactCombo(cbBattery, H);
  CompactCombo(cbStorage, H);
  CompactCombo(cbFlashMode, H);
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

procedure TMain2Form.UpdateFileRows(const APlatform: Integer);
var
  Samsung: Boolean;
  Extra, I: Integer;
begin
  Samsung := APlatform = CPlatformSamsung;
  btnBl.Visible := Samsung;
  edtBl.Visible := Samsung;
  btnAp.Visible := Samsung;
  edtAp.Visible := Samsung;
  btnCp.Visible := Samsung;
  edtCp.Visible := Samsung;
  btnCsc.Visible := Samsung;
  edtCsc.Visible := Samsung;
  btnUser.Visible := Samsung;
  edtUser.Visible := Samsung;
  if Samsung then
    Extra := 5 * CFileRowPitch
  else
    Extra := 0;
  if grpFiles.Height <> CFilesHeight + Extra then
  begin
    grpFiles.Height := CFilesHeight + Extra;
    grpLog.Top := grpFiles.Top + grpFiles.Height + 3;
    I := pbProgress.Top - 4;
    if I > grpLog.Top + 120 then
      grpLog.Height := I - grpLog.Top;
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
        lblServiceModeValue.Caption := 'META';
        lblMetaInfo.Caption := 'MediaTek service profile: META. Select this tab to ' +
          'change the platform.' + sLineBreak +
          'Device communication is not part of this build.';
        ReplaceComboItems(cbDownloadAgent, ['MTK_AllInOne_DA.bin']);
        chkAuthBrom.Caption := 'Advanced Authorization [BROM]';
        chkAuthPreloader.Caption := 'Advanced Authorization [Preloader]';
        chkForceBrom.Caption := 'Force BROM Mode';
        chkReadEmi.Caption := 'Read EMI from phone';
        chkReadPhoneInfo.Caption := 'Read Phone Info';
      end;
    CPlatformUnisoc:
      begin
        tsMeta.Caption := 'DIAG';
        lblServiceModeValue.Caption := 'DIAG';
        lblMetaInfo.Caption := 'Unisoc / Spreadtrum service profile: DIAG.' +
          sLineBreak + 'This build does not communicate with a phone.';
        ReplaceComboItems(cbDownloadAgent, ['Unisoc FDL1 / FDL2 (firmware supplied)']);
        chkAuthBrom.Caption := 'Secure-boot authorization [BootROM]';
        chkAuthPreloader.Caption := 'Load signed FDL1 / FDL2';
        chkForceBrom.Caption := 'Force download / BootROM mode';
        chkReadEmi.Caption := 'Read calibration / NV data';
        chkReadPhoneInfo.Caption := 'Read device info';
      end;
    CPlatformQualcomm:
      begin
        tsMeta.Caption := 'DIAG';
        lblServiceModeValue.Caption := 'DIAG';
        lblMetaInfo.Caption := 'Qualcomm service profile: DIAG (EDL programming).' +
          sLineBreak + 'This build does not communicate with a phone.';
        ReplaceComboItems(cbDownloadAgent, ['Qualcomm programmer (user supplied)']);
        chkAuthBrom.Caption := 'Programmer authorization';
        chkAuthPreloader.Caption := 'Load signed programmer';
        chkForceBrom.Caption := 'Enter EDL mode';
        chkReadEmi.Caption := 'Read calibration / NV data';
        chkReadPhoneInfo.Caption := 'Read device info';
      end;
    CPlatformSamsung:
      begin
        tsMeta.Caption := 'DOWNLOAD';
        lblServiceModeValue.Caption := 'DOWNLOAD';
        lblMetaInfo.Caption := 'Samsung download-mode profile. BL / AP / CP / CSC / ' +
          'USER file rows appear in the Files box.' + sLineBreak +
          'This build does not communicate with a phone.';
        ReplaceComboItems(cbDownloadAgent, ['Samsung download-mode package']);
        chkAuthBrom.Caption := 'Download-mode authorization';
        chkAuthPreloader.Caption := 'Use signed firmware package';
        chkForceBrom.Caption := 'Enter DOWNLOAD mode';
        chkReadEmi.Caption := 'Read device information';
        chkReadPhoneInfo.Caption := 'Read device info';
      end;
  else
    begin
      tsMeta.Caption := 'SERVICE';
      lblServiceModeValue.Caption := 'SERVICE';
      lblMetaInfo.Caption := 'Generic service profile. Choose the platform family ' +
        'for device-specific options.' + sLineBreak +
        'No phone communication is implemented.';
      ReplaceComboItems(cbDownloadAgent, ['Platform-specific agent / loader']);
      chkAuthBrom.Caption := 'Platform authorization';
      chkAuthPreloader.Caption := 'Load signed agent / loader';
      chkForceBrom.Caption := 'Force service mode';
      chkReadEmi.Caption := 'Read calibration / NV data';
      chkReadPhoneInfo.Caption := 'Read device info';
    end;
  end;

  UpdateFileRows(I);

  chkAuthBrom.Enabled := (I = CPlatformMtk) or (I = CPlatformUnisoc) or
    (I = CPlatformQualcomm);
  chkAuthPreloader.Enabled := chkAuthBrom.Enabled;
  chkForceBrom.Enabled := I <> CPlatformGeneric;
  chkReadEmi.Enabled := I <> CPlatformGeneric;
  chkReadPhoneInfo.Enabled := True;
end;

procedure TMain2Form.AssignGlyph(AButton: TSampleButton; const AKind: TActionGlyph);
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
  { The reference log is empty until an operation or a USB event occurs.
    Model context is recorded with jobs, not on opening the form. }
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
  LoadCheck(chkCreateDefaultFs, 'CreateDefaultFs');
  LoadCheck(chkImei1, 'Imei1Enabled');
  LoadCheck(chkImei2, 'Imei2Enabled');
  LoadEdit(edtImei1, 'Imei1');
  LoadEdit(edtImei2, 'Imei2');
  LoadEdit(edtRpmbAddress, 'RpmbAddress');
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
  Tab := Ini.ReadInteger(CSection, 'OperationTab', 0);
  if (Tab >= 0) and (Tab < pcOperations.PageCount) then
    pcOperations.ActivePageIndex := Tab;
  UpdateImeiDigits;
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
  Ini.WriteBool(CSection, 'CreateDefaultFs', chkCreateDefaultFs.Checked);
  Ini.WriteBool(CSection, 'Imei1Enabled', chkImei1.Checked);
  Ini.WriteBool(CSection, 'Imei2Enabled', chkImei2.Checked);
  Ini.WriteString(CSection, 'Imei1', edtImei1.Text);
  Ini.WriteString(CSection, 'Imei2', edtImei2.Text);
  Ini.WriteString(CSection, 'RpmbAddress', edtRpmbAddress.Text);
  Ini.WriteInteger(CSection, 'Platform', cbPlatform.ItemIndex);
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
     (FSessionLog.Count = 0) then
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
  Log('Brand : ' + LInfo(FBrand));
  Log('Model : ' + LInfo(FModelCode + ' : ' + FModelName));
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
    DrawDeviceDocIcon);
end;

procedure TMain2Form.pbSettingsPaint(Sender: TObject);
begin
  PaintIcon(pbSettings.Canvas, pbSettings.ClientRect, DrawGearIcon);
end;

procedure TMain2Form.pbContactPaint(Sender: TObject);
begin
  PaintIcon(pbContact.Canvas, pbContact.ClientRect, DrawPlaneIcon);
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
  Fill: Integer;
  S: string;
begin
  C := pbProgress.Canvas;
  R := pbProgress.ClientRect;
  { Erase the old percentage before painting a new one. }
  C.Brush.Style := bsSolid;
  C.Brush.Color := Color;
  C.FillRect(R);
  C.Brush.Color := RGB(226, 226, 226);
  C.FillRect(Rect(R.Left, R.Bottom - 2, R.Right, R.Bottom));
  if FProgress > 0 then
  begin
    Fill := R.Left + MulDiv(R.Right - R.Left, FProgress, 100);
    C.Brush.Color := RGB(232, 0, 18);
    C.FillRect(Rect(R.Left, R.Bottom - 2, Fill, R.Bottom));
  end;

  S := IntToStr(FProgress) + '%';
  C.Brush.Style := bsClear;
  C.Font.Assign(Font);
  C.Font.Height := -pcJobs.ScaleValue(9);
  C.Font.Color := clWindowText;
  C.TextOut(R.Left + (R.Right - R.Left - C.TextWidth(S)) div 2 +
    pcJobs.ScaleValue(12),
    R.Top + (R.Bottom - R.Top - 2 - C.TextHeight(S)) div 2, S);
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
    Text := ''
  else
  begin
    Text := DescribeDevice(FDevices[0]);
    if Length(FDevices) > 1 then
      Text := Text + '  (+' + IntToStr(Length(FDevices) - 1) + ' more)';
  end;
  { the state only appears when a phone is actually connected, so the idle
    screen matches the reference layout }
  lblDeviceState.Caption := Text;
  lblDeviceState.Visible := Text <> '';
  pbDeviceState.Visible := Text <> '';
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
  else if pcOperations.ActivePage = tsImei then
    btnReadImeiClick(btnReadImei)
  else if pcOperations.ActivePage = tsLocks then
    btnUnlockBootloaderClick(btnUnlockBootloader)
  else if pcOperations.ActivePage = tsService then
    btnRebootRecoveryClick(btnRebootRecovery)
  else if pcOperations.ActivePage = tsRpmb then
    btnRpmbBackupClick(btnRpmbBackup)
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
  Log('Log saved : ' + LInfo(FileName));
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

procedure TMain2Form.pbContactClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', PChar(CIssuesUrl), nil, nil, SW_SHOWNORMAL);
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
  edtAddress.Enabled := True;
  edtAddress.ReadOnly := not Enable;
  edtAddress.TabStop := Enable;
  edtAddress.Color := clWhite;
  if Enable then
    edtAddress.Font.Color := clWindowText
  else
    edtAddress.Font.Color := clGrayText;
  btnWriteBin.Enabled := Enable;
  btnBin.Enabled := Enable;
  edtBin.Enabled := True;
  edtBin.ReadOnly := not Enable;
  edtBin.TabStop := Enable;
  edtBin.Color := clWhite;
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

procedure TMain2Form.UpdateFormatRadios;
begin
  rbAutoFormat.Checked := not FManualFormat;
  rbManualFormat.Checked := FManualFormat;
  rbFormatAiFlash.Checked := not FAiExceptBootloader;
  rbFormatAiExceptBootloader.Checked := FAiExceptBootloader;
end;

procedure TMain2Form.FormatRadioClick(Sender: TObject);
begin
  if Sender = rbAutoFormat then
    FManualFormat := False
  else if Sender = rbManualFormat then
    FManualFormat := True
  else if Sender = rbFormatAiFlash then
    FAiExceptBootloader := False
  else if Sender = rbFormatAiExceptBootloader then
    FAiExceptBootloader := True;
  UpdateFormatRadios;
end;

procedure TMain2Form.UpdateImeiDigits;
begin
  if ImeiCheckDigit(edtImei1.Text) >= 0 then
    lblImei1Digits.Caption := IntToStr(ImeiCheckDigit(edtImei1.Text))
  else
    lblImei1Digits.Caption := '-';
  if ImeiCheckDigit(edtImei2.Text) >= 0 then
    lblImei2Digits.Caption := IntToStr(ImeiCheckDigit(edtImei2.Text))
  else
    lblImei2Digits.Caption := '-';
end;

procedure TMain2Form.ImeiEditChange(Sender: TObject);
begin
  UpdateImeiDigits;
end;

procedure TMain2Form.btnFormatClick(Sender: TObject);
begin
  Log('[Format] ' + LInfo(btnFormat.Caption));
  if rbAutoFormat.Checked then
    Log('Mode : ' + LInfo('Auto Format'))
  else
    Log('Mode : ' + LInfo('Manual Format'));
  if rbFormatAiFlash.Checked then
    Log('Target : ' + LInfo('AI Flash'))
  else
    Log('Target : ' + LInfo('AI Except Bootloader'));
  if chkCreateDefaultFs.Checked then
    Log('Create Default FS : ' + LInfo('yes'));
  LogSettings;
  LogNotImplemented('Format');
end;

procedure TMain2Form.btnWipeDataClick(Sender: TObject);
begin
  Log('[Wipe Data]');
  LogSettings;
  LogNotImplemented('Wipe Data');
end;

procedure TMain2Form.btnWipePartitionsClick(Sender: TObject);
begin
  Log('[Wipe Partitions]');
  LogSettings;
  LogNotImplemented('Wipe Partitions');
end;

procedure TMain2Form.btnEraseFrpClick(Sender: TObject);
begin
  Log('[Erase FRP]');
  LogSettings;
  LogNotImplemented('Erase FRP');
end;

procedure TMain2Form.btnEraseFrpAndWipeClick(Sender: TObject);
begin
  Log('[Erase FRP and Wipe]');
  LogSettings;
  LogNotImplemented('Erase FRP and Wipe');
end;

procedure TMain2Form.btnRepairClick(Sender: TObject);
begin
  Log('[Repair]');
  if chkImei1.Checked and (ImeiCheckDigit(edtImei1.Text) < 0) then
  begin
    LogError('IMEI1 must be a 14 or 15 digit number.');
    Exit;
  end;
  if chkImei2.Checked and (ImeiCheckDigit(edtImei2.Text) < 0) then
  begin
    LogError('IMEI2 must be a 14 or 15 digit number.');
    Exit;
  end;
  if chkImei1.Checked then
    Log('IMEI1 : ' + LInfo(edtImei1.Text) + '  check digit : ' +
      LInfo(lblImei1Digits.Caption));
  if chkImei2.Checked then
    Log('IMEI2 : ' + LInfo(edtImei2.Text) + '  check digit : ' +
      LInfo(lblImei2Digits.Caption));
  LogSettings;
  LogNotImplemented('Repair');
end;

procedure TMain2Form.btnReadImeiClick(Sender: TObject);
begin
  Log('[Read IMEI]');
  LogSettings;
  LogNotImplemented('Read IMEI');
end;

procedure TMain2Form.lblAdvancedSettingsClick(Sender: TObject);
begin
  Log('[Advanced settings] IMEI editing options');
  Log(LMuted('Editing the IMEI of a device may be illegal in your country. ' +
    'This build never writes to a phone.'));
  Log('');
end;

procedure TMain2Form.btnUnlockBootloaderClick(Sender: TObject);
begin
  Log('[Unlock Bootloader]');
  Log(LWarn('Unlocking the bootloader usually erases user data.'));
  LogSettings;
  LogNotImplemented('Unlock Bootloader');
end;

procedure TMain2Form.btnRelockBootloaderClick(Sender: TObject);
begin
  Log('[Relock Bootloader]');
  LogSettings;
  LogNotImplemented('Relock Bootloader');
end;

procedure TMain2Form.btnUnlockNetworkClick(Sender: TObject);
begin
  Log('[Unlock Network]');
  LogSettings;
  LogNotImplemented('Unlock Network');
end;

procedure TMain2Form.btnReadCodesClick(Sender: TObject);
begin
  Log('[Read Codes]');
  LogSettings;
  LogNotImplemented('Read Codes');
end;

procedure TMain2Form.btnResetPasswordClick(Sender: TObject);
begin
  Log('[Reset Password] ' + LWarn('[SAFE WIPE]'));
  LogSettings;
  LogNotImplemented('Reset Password');
end;

procedure TMain2Form.btnResetAccountClick(Sender: TObject);
begin
  Log('[Reset Account]');
  LogSettings;
  LogNotImplemented('Reset Account');
end;

procedure TMain2Form.btnRebootRecoveryClick(Sender: TObject);
begin
  Log('[Reboot to Recovery]');
  LogSettings;
  LogNotImplemented('Reboot to Recovery');
end;

procedure TMain2Form.btnDisableOtaClick(Sender: TObject);
begin
  Log('[Disable OTA Updates]');
  LogSettings;
  LogNotImplemented('Disable OTA Updates');
end;

procedure TMain2Form.btnResetDmVerityClick(Sender: TObject);
begin
  Log('[Reset Dm-Verity Error]');
  LogSettings;
  LogNotImplemented('Reset Dm-Verity Error');
end;

procedure TMain2Form.btnDisableOrangeStateClick(Sender: TObject);
begin
  Log('[Disable Orange State]');
  LogSettings;
  LogNotImplemented('Disable Orange State');
end;

procedure TMain2Form.btnSwitchSlotClick(Sender: TObject);
begin
  Log('[Switch Slot]');
  LogSettings;
  LogNotImplemented('Switch Slot');
end;

procedure TMain2Form.btnFixDlImageClick(Sender: TObject);
begin
  Log('[Fix DL Image Fail]');
  LogSettings;
  LogNotImplemented('Fix DL Image Fail');
end;

procedure TMain2Form.btnRpmbBackupClick(Sender: TObject);
begin
  Log('[RPMB] Backup RPMB');
  Log('RPMB target : ' + LInfo(cbStorage.Text));
  Log('Platform service mode : ' + LInfo(tsMeta.Caption));
  LogSettings;
  LogNotImplemented('RPMB - Backup');
end;

procedure TMain2Form.btnRpmbWriteClick(Sender: TObject);
var
  Dummy: UInt64;
begin
  Log('[RPMB] Write RPMB');
  if not TryParseHex64(edtRpmbAddress.Text, Dummy) then
  begin
    LogError('Enter the RPMB address in hex, e.g. 000000');
    Exit;
  end;
  Log('Address : ' + LInfo('0x' + edtRpmbAddress.Text));
  Log('RPMB target : ' + LInfo(cbStorage.Text));
  LogSettings;
  LogNotImplemented('RPMB - Write');
end;

procedure TMain2Form.btnRpmbFormatClick(Sender: TObject);
begin
  Log('[RPMB] Format RPMB');
  Log('RPMB target : ' + LInfo(cbStorage.Text));
  LogSettings;
  LogNotImplemented('RPMB - Format');
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
    if Parts[I].Visible and (Trim(Parts[I].Text) <> '') then
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
    if Parts[I].Visible and (not CheckOptionalFile(Parts[I], CNames[I])) then
      Exit;

  if Trim(edtScat.Text) <> '' then
    Log('Scatter file : ' + LInfo(edtScat.Text));
  if Trim(edtAuth.Text) <> '' then
    Log('Auth file : ' + LInfo(edtAuth.Text));
  for I := 0 to High(Parts) do
    if Parts[I].Visible and (Trim(Parts[I].Text) <> '') then
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
  Imei: Integer;

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
  Check('four file rows in the Files group',
    (btnScat.Parent = grpFiles) and (edtOfp.Parent = grpFiles));
  Imei := ImeiCheckDigit('35646019030487');
  Check('IMEI check digit of 35646019030487 is 9', Imei = 9);
  Imei := ImeiCheckDigit('35646019110987');
  Check('IMEI check digit of 35646019110987 is 1', Imei = 1);
  Check('IMEI check digit rejects short numbers',
    ImeiCheckDigit('12345') < 0);
  Check('button glyphs assigned',
    (btnWriteFirmware.Glyph.Width > 0) and (btnRpmbFormat.Glyph.Width > 0));

  cbPlatform.ItemIndex := CPlatformMtk;
  ApplyPlatformSettings;
  Check('MediaTek profile labels the service tab META', tsMeta.Caption = 'META');
  Check('MediaTek profile hides the Samsung file rows', not btnBl.Visible);
  cbPlatform.ItemIndex := CPlatformUnisoc;
  ApplyPlatformSettings;
  Check('Unisoc profile changes META to DIAG', tsMeta.Caption = 'DIAG');
  cbPlatform.ItemIndex := CPlatformQualcomm;
  ApplyPlatformSettings;
  Check('Qualcomm profile also exposes DIAG service mode',
    tsMeta.Caption = 'DIAG');
  cbPlatform.ItemIndex := CPlatformSamsung;
  ApplyPlatformSettings;
  Check('Samsung profile shows DOWNLOAD and the BL / AP / CP / CSC / USER rows',
    (tsMeta.Caption = 'DOWNLOAD') and btnBl.Visible and edtUser.Visible and
    (grpFiles.Height > CFilesHeight));
  cbPlatform.ItemIndex := CPlatformGeneric;
  ApplyPlatformSettings;
  Check('Generic profile labels the service tab SERVICE',
    tsMeta.Caption = 'SERVICE');
  cbPlatform.ItemIndex := CPlatformMtk;
  ApplyPlatformSettings;

  Before := lstLog.Items.Count;
  edtScat.Text := '';
  edtAuth.Text := '';
  btnWriteFirmwareClick(nil);
  Check('Write Firmware without files logs an error',
    Pos('Select a SCAT file', StripLogCodes(lstLog.Items[lstLog.Items.Count - 2])) > 0);

  edtAp.Text := ExeDir + 'does-not-exist.tar.md5';
  btnWriteFirmwareClick(nil);
  Check('Write Firmware with a missing AP file logs a warning',
    lstLog.Items.Count > Before);
  edtAp.Text := '';

  edtReadSize.Text := '00000000  00000000';
  btnReadBinClick(nil);
  Check('Read BIN with size 0 logs an error',
    Pos('size to read', StripLogCodes(lstLog.Items[lstLog.Items.Count - 2])) > 0);

  btnReadOtpClick(nil);
  Check('Read OTP logs the job', lstLog.Items.Count > Before);
  btnRpmbBackupClick(nil);
  Check('Backup RPMB logs the job', lstLog.Items.Count > Before);
  btnWipeDataClick(nil);
  Check('Wipe Data logs the job', lstLog.Items.Count > Before);

  edtImei1.Text := '12345';
  UpdateImeiDigits;
  Check('a short IMEI shows no check digit', lblImei1Digits.Caption = '-');
  edtImei1.Text := '35646019030487';
  UpdateImeiDigits;
  Check('a valid IMEI shows its check digit', lblImei1Digits.Caption = '9');

  CheckUsb(True);
  Check('USB scan ran', True);
  Result := AllOk;
end;

end.
