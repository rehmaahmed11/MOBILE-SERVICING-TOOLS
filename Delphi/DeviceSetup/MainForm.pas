unit MainForm;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


{ MAIN 1 - first screen.
  Layout (matching the reference screenshot):
    - blue menu icon top-left
    - "next" (green play) and "save" (orange arrow) icons top-right
    - "Quick search" combo box
    - brand list on the left, "<code> : <name>" model list on the right
  Pressing the green Next icon (or double-clicking / Enter on a model)
  opens MAIN 2 for the selected device.

  On top of the reference screen this unit also:
    - searches every word of the query, so "note 11" finds "Redmi Note 11"
      and "realme c35" finds the model whichever way round it is typed;
    - remembers the last brand and model (settings.ini) and restores them;
    - reloads the brand/model catalog from the Data folders with Ctrl+R or
      from the menu;
    - shows the live USB device (MediaTek BROM, Qualcomm EDL, ADB...) in the
      menu, using the same watcher MAIN 2 uses. }

interface

uses
{$IFDEF FPC}
  Windows, LCLType, Classes, SysUtils, Types,
  Controls, Dialogs, Forms, Graphics, Menus, StdCtrls, ExtCtrls,
{$ELSE}
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  System.Types,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.Menus,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
{$ENDIF}
  DeviceCatalog,
  DeviceWatch;

type
  TMainForm = class(TForm)
    pbMenu: TPaintBox;
    pbNext: TPaintBox;
    pbDownload: TPaintBox;
    cbSearch: TComboBox;
    lstBrands: TListBox;
    lstModels: TListBox;
    pmMain: TPopupMenu;
    miDeviceStatus: TMenuItem;
    miStatusSeparator: TMenuItem;
    miNext: TMenuItem;
    miSaveList: TMenuItem;
    miReloadList: TMenuItem;
    miOpenDataFolder: TMenuItem;
    miSeparator: TMenuItem;
    miExit: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure pbMenuPaint(Sender: TObject);
    procedure pbNextPaint(Sender: TObject);
    procedure pbDownloadPaint(Sender: TObject);
    procedure pbMenuClick(Sender: TObject);
    procedure pbNextClick(Sender: TObject);
    procedure pbDownloadClick(Sender: TObject);
    procedure cbSearchChange(Sender: TObject);
    procedure cbSearchEnter(Sender: TObject);
    procedure cbSearchExit(Sender: TObject);
    procedure cbSearchKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure lstBrandsClick(Sender: TObject);
    procedure lstModelsClick(Sender: TObject);
    procedure lstModelsDblClick(Sender: TObject);
    procedure lstModelsKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure miReloadListClick(Sender: TObject);
    procedure miOpenDataFolderClick(Sender: TObject);
    procedure miExitClick(Sender: TObject);
  private
    FUpdating: Boolean;
    FWatcher: TDeviceWatcher;
    FFirstShow: Boolean;
    function SearchText: string;
    procedure LoadBrands;
    procedure LoadBrandModels(const ABrandIndex: Integer);
    procedure LoadSearchResults(const AText: string);
    procedure AddModelItem(const ABrandIndex, AModelIndex: Integer;
      const AWithBrand: Boolean);
    function SelectedDevice(out ABrandIndex, AModelIndex: Integer): Boolean;
    procedure UpdateNextState;
    procedure OpenMain2;
    procedure SaveModelList;
    procedure UpdateCatalogCaption;
    procedure RestoreLastSelection;
    procedure RememberSelection;
    procedure DevicesChanged(Sender: TObject);
    procedure DeviceArrivedOrLeft(Sender: TObject;
      const ADevice: TDetectedDevice; const AArrived: Boolean);
  public
    { Assigned to Application.OnException in the project file, so an
      unexpected error is reported with a written error report instead of a
      raw Windows dialog. }
    procedure HandleAppException(Sender: TObject; E: Exception);
  end;

var
  frmMain: TMainForm;

{ Command-line self test. "DeviceSetup.exe /selftest" builds both forms,
  checks that the catalog loaded and that MAIN 2 accepted the device, then
  exits with 0 (or 1, after writing an error report). The compiler cannot see
  form-streaming problems - a component in the .dfm/.lfm that does not match
  the form class only fails at run time - so the build pipeline runs this. }
function SelfTestRequested: Boolean;
function RunSelfTest: Integer;

implementation

{$IFDEF FPC}
  {$R *.lfm}
{$ELSE}
  {$R *.dfm}
{$ENDIF}

uses
{$IFDEF FPC}
  Math,
{$ELSE}
  System.Math,
{$ENDIF}
  Main2Form,
  ToolbarIcons,
  AppSettings;

const
  CSearchPlaceholder = 'Quick search';
  CRefFactor = 65536;
  CSettingsSection = 'Main1';

function PackRef(const ABrandIndex, AModelIndex: Integer): TObject;
begin
  Result := TObject(Pointer(NativeInt(ABrandIndex) * CRefFactor + AModelIndex));
end;

procedure UnpackRef(const ARef: TObject; out ABrandIndex, AModelIndex: Integer);
var
  Value: NativeInt;
begin
  Value := NativeInt(Pointer(ARef));
  ABrandIndex := Integer(Value div CRefFactor);
  AModelIndex := Integer(Value mod CRefFactor);
end;

procedure SplitTokens(const AText: string; ATokens: TStrings);
var
  I, StartPos: Integer;
begin
  ATokens.Clear;
  StartPos := 1;
  for I := 1 to Length(AText) + 1 do
    if (I > Length(AText)) or (AText[I] = ' ') or (AText[I] = #9) then
    begin
      if I > StartPos then
        ATokens.Add(Copy(AText, StartPos, I - StartPos));
      StartPos := I + 1;
    end;
end;

{ True when every word of the query appears somewhere in the text. }
function MatchesTokens(const AText: string; ATokens: TStrings): Boolean;
var
  I: Integer;
  Haystack: string;
begin
  Result := True;
  if ATokens.Count = 0 then
    Exit;
  Haystack := UpperCase(AText);
  for I := 0 to ATokens.Count - 1 do
    if Pos(UpperCase(ATokens[I]), Haystack) = 0 then
      Exit(False);
end;

{ ---------------------------------------------------------------- form }

procedure TMainForm.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  FFirstShow := True;
  LoadBrands;
  cbSearch.Text := CSearchPlaceholder;

  { Start on the last brand used, or on Realme as in the reference screen. }
  I := TDeviceCatalog.BrandIndex(
    TAppSettings.ReadString(CSettingsSection, 'LastBrand', ''));
  if I < 0 then
    I := TDeviceCatalog.BrandIndex('Realme');
  if (I < 0) or (I >= lstBrands.Items.Count) then
    I := 0;
  lstBrands.ItemIndex := I;
  LoadBrandModels(lstBrands.ItemIndex);
  RestoreLastSelection;
  UpdateNextState;
  UpdateCatalogCaption;

  FWatcher := TDeviceWatcher.Create;
  FWatcher.OnDevicesChange := DevicesChanged;
  FWatcher.OnDeviceChange := DeviceArrivedOrLeft;
  DevicesChanged(FWatcher);
  FWatcher.Start;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  if FFirstShow then
  begin
    FFirstShow := False;
    if cbSearch.CanFocus then
    begin
      cbSearch.SetFocus;
      cbSearch.SelectAll;
    end;
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  RememberSelection;
  if FWatcher <> nil then
  begin
    FWatcher.Stop;
    FreeAndNil(FWatcher);
  end;
  TAppSettings.Save;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = Ord('R')) and (ssCtrl in Shift) then
  begin
    Key := 0;
    miReloadListClick(Self);
  end;
end;

procedure TMainForm.LoadBrands;
var
  I: Integer;
begin
  FUpdating := True;
  try
    lstBrands.Items.BeginUpdate;
    try
      lstBrands.Items.Clear;
      for I := 0 to TDeviceCatalog.BrandCount - 1 do
        lstBrands.Items.Add(TDeviceCatalog.BrandName(I));
    finally
      lstBrands.Items.EndUpdate;
    end;
  finally
    FUpdating := False;
  end;
end;

procedure TMainForm.AddModelItem(const ABrandIndex, AModelIndex: Integer;
  const AWithBrand: Boolean);
var
  ItemText: string;
begin
  ItemText := TDeviceCatalog.ModelName(ABrandIndex, AModelIndex);
  if AWithBrand then
    ItemText := ItemText + '  [' + TDeviceCatalog.BrandName(ABrandIndex) + ']';
  lstModels.Items.AddObject(ItemText, PackRef(ABrandIndex, AModelIndex));
end;

procedure TMainForm.LoadBrandModels(const ABrandIndex: Integer);
var
  I: Integer;
begin
  FUpdating := True;
  try
    lstModels.Items.BeginUpdate;
    try
      lstModels.Items.Clear;
      if (ABrandIndex >= 0) and (ABrandIndex < TDeviceCatalog.BrandCount) then
        for I := 0 to TDeviceCatalog.ModelCount(ABrandIndex) - 1 do
          AddModelItem(ABrandIndex, I, False);
      lstModels.ItemIndex := -1;
    finally
      lstModels.Items.EndUpdate;
    end;
  finally
    FUpdating := False;
  end;
  UpdateNextState;
end;

procedure TMainForm.LoadSearchResults(const AText: string);
var
  B, M: Integer;
  Tokens: TStringList;
begin
  Tokens := TStringList.Create;
  try
    SplitTokens(AText, Tokens);
    FUpdating := True;
    try
      lstModels.Items.BeginUpdate;
      try
        lstModels.Items.Clear;
        for B := 0 to TDeviceCatalog.BrandCount - 1 do
          for M := 0 to TDeviceCatalog.ModelCount(B) - 1 do
            if MatchesTokens(TDeviceCatalog.ModelName(B, M) + ' ' +
               TDeviceCatalog.BrandName(B), Tokens) then
              AddModelItem(B, M, True);
        lstModels.ItemIndex := -1;
      finally
        lstModels.Items.EndUpdate;
      end;
    finally
      FUpdating := False;
    end;
  finally
    Tokens.Free;
  end;
  UpdateNextState;
end;

function TMainForm.SearchText: string;
begin
  Result := Trim(cbSearch.Text);
  if SameText(Result, CSearchPlaceholder) then
    Result := '';
end;

function TMainForm.SelectedDevice(out ABrandIndex,
  AModelIndex: Integer): Boolean;
begin
  ABrandIndex := -1;
  AModelIndex := -1;
  Result := lstModels.ItemIndex >= 0;
  if Result then
    UnpackRef(lstModels.Items.Objects[lstModels.ItemIndex],
      ABrandIndex, AModelIndex);
end;

procedure TMainForm.UpdateNextState;
var
  B, M: Integer;
begin
  pbNext.Enabled := SelectedDevice(B, M);
  miNext.Enabled := pbNext.Enabled;
  pbNext.Invalidate;
end;

{ ---------------------------------------------------------------- state }

procedure TMainForm.RestoreLastSelection;
var
  B, M, Scan: Integer;
  Entry: string;
begin
  B := lstBrands.ItemIndex;
  if B < 0 then
    Exit;
  Entry := TAppSettings.ReadString(CSettingsSection, 'LastModel', '');
  if Entry = '' then
    Exit;
  M := TDeviceCatalog.ModelIndexOf(B, Entry);
  if M < 0 then
  begin
    { The model may now live in another brand (the Data folders changed). }
    for Scan := 0 to TDeviceCatalog.BrandCount - 1 do
    begin
      M := TDeviceCatalog.ModelIndexOf(Scan, Entry);
      if M >= 0 then
      begin
        B := Scan;
        lstBrands.ItemIndex := B;
        LoadBrandModels(B);
        Break;
      end;
    end;
  end;
  if M >= 0 then
  begin
    FUpdating := True;
    try
      lstModels.ItemIndex := M;
      lstModels.TopIndex := Max(0, M - 5);
    finally
      FUpdating := False;
    end;
  end;
end;

procedure TMainForm.RememberSelection;
var
  B, M: Integer;
begin
  if lstBrands.ItemIndex >= 0 then
    TAppSettings.WriteString(CSettingsSection, 'LastBrand',
      lstBrands.Items[lstBrands.ItemIndex]);
  if SelectedDevice(B, M) then
    TAppSettings.WriteString(CSettingsSection, 'LastModel',
      TDeviceCatalog.ModelName(B, M));
end;

procedure TMainForm.UpdateCatalogCaption;
begin
  miReloadList.Caption := 'Reload model list  (Ctrl+R, ' +
    TDeviceCatalog.Summary + ')';
end;

procedure TMainForm.miReloadListClick(Sender: TObject);
var
  BrandName, ModelEntry: string;
  B, M: Integer;
begin
  BrandName := '';
  if lstBrands.ItemIndex >= 0 then
    BrandName := lstBrands.Items[lstBrands.ItemIndex];
  ModelEntry := '';
  if SelectedDevice(B, M) then
    ModelEntry := TDeviceCatalog.ModelName(B, M);

  TDeviceCatalog.Reload;
  LoadBrands;
  B := TDeviceCatalog.BrandIndex(BrandName);
  if B < 0 then
    B := 0;
  lstBrands.ItemIndex := B;
  LoadBrandModels(B);
  M := TDeviceCatalog.ModelIndexOf(B, ModelEntry);
  if M >= 0 then
  begin
    FUpdating := True;
    try
      lstModels.ItemIndex := M;
    finally
      FUpdating := False;
    end;
  end;
  UpdateNextState;
  UpdateCatalogCaption;
end;

procedure TMainForm.miOpenDataFolderClick(Sender: TObject);
begin
  if not TAppSettings.OpenFolder(TAppSettings.DataDir) then
    MessageDlg('The model data folder could not be opened:' + sLineBreak +
      TAppSettings.DataDir, mtWarning, [mbOK], 0);
end;

{ ---------------------------------------------------------------- search }

procedure TMainForm.cbSearchChange(Sender: TObject);
var
  Query: string;
begin
  if FUpdating then
    Exit;
  Query := SearchText;
  if Query = '' then
    LoadBrandModels(lstBrands.ItemIndex)
  else
    LoadSearchResults(Query);
end;

procedure TMainForm.cbSearchEnter(Sender: TObject);
begin
  if SameText(cbSearch.Text, CSearchPlaceholder) then
    cbSearch.SelectAll;
end;

procedure TMainForm.cbSearchExit(Sender: TObject);
var
  Query: string;
begin
  Query := SearchText;
  if Query = '' then
  begin
    FUpdating := True;
    try
      cbSearch.Text := CSearchPlaceholder;
    finally
      FUpdating := False;
    end;
  end
  else if cbSearch.Items.IndexOf(Query) < 0 then
    cbSearch.Items.Insert(0, Query);
end;

procedure TMainForm.cbSearchKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_RETURN, VK_DOWN:
      if (not cbSearch.DroppedDown) and (lstModels.Items.Count > 0) then
      begin
        Key := 0;
        if (SearchText <> '') and (cbSearch.Items.IndexOf(SearchText) < 0) then
          cbSearch.Items.Insert(0, SearchText);
        lstModels.SetFocus;
        if lstModels.ItemIndex < 0 then
          lstModels.ItemIndex := 0;
        UpdateNextState;
      end;
    VK_ESCAPE:
      begin
        Key := 0;
        FUpdating := True;
        try
          cbSearch.Text := CSearchPlaceholder;
        finally
          FUpdating := False;
        end;
        LoadBrandModels(lstBrands.ItemIndex);
      end;
  end;
end;

{ ---------------------------------------------------------------- lists }

procedure TMainForm.lstBrandsClick(Sender: TObject);
begin
  if FUpdating then
    Exit;
  if SearchText <> '' then
  begin
    FUpdating := True;
    try
      cbSearch.Text := CSearchPlaceholder;
    finally
      FUpdating := False;
    end;
  end;
  LoadBrandModels(lstBrands.ItemIndex);
  if lstModels.Items.Count > 0 then
    lstModels.TopIndex := 0;
end;

procedure TMainForm.lstModelsClick(Sender: TObject);
var
  B, M: Integer;
begin
  if FUpdating then
    Exit;
  { Keep the brand list in sync with the selected model (search results
    can come from any brand). }
  if SelectedDevice(B, M) and (lstBrands.ItemIndex <> B) then
  begin
    FUpdating := True;
    try
      lstBrands.ItemIndex := B;
    finally
      FUpdating := False;
    end;
  end;
  UpdateNextState;
  RememberSelection;
end;

procedure TMainForm.lstModelsDblClick(Sender: TObject);
begin
  if lstModels.ItemIndex >= 0 then
    OpenMain2;
end;

procedure TMainForm.lstModelsKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (lstModels.ItemIndex >= 0) then
  begin
    Key := 0;
    OpenMain2;
  end;
end;

{ ---------------------------------------------------------------- toolbar }

procedure TMainForm.pbMenuPaint(Sender: TObject);
begin
  DrawMenuIcon(pbMenu.Canvas, pbMenu.ClientRect);
end;

procedure TMainForm.pbNextPaint(Sender: TObject);
begin
  DrawNextIcon(pbNext.Canvas, pbNext.ClientRect, pbNext.Enabled);
end;

procedure TMainForm.pbDownloadPaint(Sender: TObject);
begin
  DrawDownloadIcon(pbDownload.Canvas, pbDownload.ClientRect);
end;

procedure TMainForm.pbMenuClick(Sender: TObject);
var
  P: TPoint;
begin
  P := pbMenu.ClientToScreen(Point(0, pbMenu.Height));
  pmMain.Popup(P.X, P.Y);
end;

procedure TMainForm.pbNextClick(Sender: TObject);
begin
  OpenMain2;
end;

procedure TMainForm.pbDownloadClick(Sender: TObject);
begin
  SaveModelList;
end;

procedure TMainForm.miExitClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.SaveModelList;
var
  Dialog: TSaveDialog;
  LastFolder: string;
begin
  if lstModels.Items.Count = 0 then
  begin
    MessageDlg('There is nothing to save - the model list is empty.',
      mtInformation, [mbOK], 0);
    Exit;
  end;
  Dialog := TSaveDialog.Create(Self);
  try
    Dialog.Title := 'Save model list';
    Dialog.Filter := 'Text files (*.txt)|*.txt|All files (*.*)|*.*';
    Dialog.DefaultExt := 'txt';
    Dialog.Options := Dialog.Options + [ofOverwritePrompt];
    LastFolder := TAppSettings.ReadString(CSettingsSection, 'LastFolder', '');
    if DirectoryExists(LastFolder) then
      Dialog.InitialDir := LastFolder;
    if lstBrands.ItemIndex >= 0 then
      Dialog.FileName := lstBrands.Items[lstBrands.ItemIndex] + ' models.txt';
    if not Dialog.Execute then
      Exit;
    try
      {$IFDEF FPC}
      lstModels.Items.SaveToFile(Dialog.FileName);  { LCL strings are UTF-8 }
      {$ELSE}
      lstModels.Items.SaveToFile(Dialog.FileName, TEncoding.UTF8);
      {$ENDIF}
      TAppSettings.WriteString(CSettingsSection, 'LastFolder',
        IncludeTrailingPathDelimiter(ExtractFilePath(Dialog.FileName)));
    except
      on E: Exception do
      begin
        TAppSettings.WriteErrorReport('MAIN 1 - save model list', E.Message);
        MessageDlg('The model list could not be saved.' + sLineBreak +
          E.Message, mtError, [mbOK], 0);
      end;
    end;
  finally
    Dialog.Free;
  end;
end;

{ ---------------------------------------------------------------- devices }

procedure TMainForm.DevicesChanged(Sender: TObject);
begin
  if FWatcher = nil then
    Exit;
  miDeviceStatus.Caption := FWatcher.StatusLine;
  pbMenu.Hint := 'Menu' + sLineBreak + FWatcher.StatusLine;
end;

procedure TMainForm.DeviceArrivedOrLeft(Sender: TObject;
  const ADevice: TDetectedDevice; const AArrived: Boolean);
begin
  { MAIN 1 only reflects the state in its menu; MAIN 2 writes the log. }
  DevicesChanged(Sender);
end;

function SelfTestRequested: Boolean;
begin
  Result := (ParamCount >= 1) and SameText(ParamStr(1), '/selftest');
end;

function RunSelfTest: Integer;
var
  Form1: TMainForm;
  Form2: TMain2Form;
  BrandCount, ModelCount: Integer;
begin
  Result := 0;
  Form1 := nil;
  Form2 := nil;
  try
    {$IFDEF FPC}
    { Without this the LCL does not stream the .lfm into the form and every
      component field stays nil. The normal start-up path sets it in the
      project file; the self test runs before that. }
    RequireDerivedFormResource := True;
    {$ENDIF}
    Application.Initialize;

    if TDeviceCatalog.BrandCount <= 0 then
      raise Exception.Create('The model catalog has no brands.');
    BrandCount := TDeviceCatalog.BrandCount;
    ModelCount := TDeviceCatalog.TotalModelCount;
    if ModelCount <= 0 then
      raise Exception.Create('The model catalog has no models.');

    { MAIN 1: streams the form, fills both lists, starts the device watcher. }
    Form1 := TMainForm.Create(nil);
    if Form1.lstBrands.Items.Count <> BrandCount then
      raise Exception.Create(Format(
        'MAIN 1 listed %d brands but the catalog has %d.',
        [Form1.lstBrands.Items.Count, BrandCount]));
    if Form1.lstModels.Items.Count = 0 then
      raise Exception.Create('MAIN 1 shows no models for the start-up brand.');

    { MAIN 2: the larger form, only streamed when the user presses Next. }
    Form2 := TMain2Form.Create(nil);
    Form2.SetDevice('Realme', 'RMX3511 : Realme C35');
    if Pos('Realme C35', Form2.Caption) = 0 then
      raise Exception.Create('MAIN 2 did not accept the selected device.');
  except
    on E: Exception do
    begin
      TAppSettings.WriteErrorReport('Self test',
        string(E.ClassName) + ': ' + E.Message);
      Result := 1;
    end;
  end;
  Form2.Free;
  Form1.Free;
  TAppSettings.Save;
end;

procedure TMainForm.HandleAppException(Sender: TObject; E: Exception);
begin
  if E is EAbort then
    Exit;
  TAppSettings.WriteErrorReport('Unhandled error',
    string(E.ClassName) + ': ' + E.Message);
  MessageDlg(CAppName + ' hit an unexpected problem.' + sLineBreak + sLineBreak +
    E.Message + sLineBreak + sLineBreak +
    'A report was written to:' + sLineBreak + TAppSettings.LogDir,
    mtError, [mbOK], 0);
end;

procedure TMainForm.OpenMain2;
var
  B, M: Integer;
  Screen2: TMain2Form;
begin
  if not SelectedDevice(B, M) then
  begin
    MessageDlg('Select a model first.', mtInformation, [mbOK], 0);
    Exit;
  end;
  RememberSelection;

  Screen2 := TMain2Form.Create(Self);
  try
    Screen2.SetDevice(TDeviceCatalog.BrandName(B),
      TDeviceCatalog.ModelName(B, M));
    Screen2.Position := poOwnerFormCenter;
    if WindowState = wsMaximized then
      Screen2.WindowState := wsMaximized;
    Screen2.ShowModal;
  finally
    Screen2.Free;
  end;
end;

end.
