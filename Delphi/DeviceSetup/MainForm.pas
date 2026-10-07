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
  opens MAIN 2 for the selected device. }

interface

uses
{$IFDEF FPC}
  Windows, LCLType, Classes, SysUtils, StrUtils, Types,
  Controls, Dialogs, Forms, Graphics, Menus, StdCtrls, ExtCtrls,
{$ELSE}
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  System.StrUtils,
  System.Types,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.Menus,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
{$ENDIF}
  DeviceCatalog;

type
  TMainForm = class(TForm)
    pbMenu: TPaintBox;
    pbNext: TPaintBox;
    pbDownload: TPaintBox;
    cbSearch: TComboBox;
    lstBrands: TListBox;
    lstModels: TListBox;
    pmMain: TPopupMenu;
    miNext: TMenuItem;
    miSaveList: TMenuItem;
    miSeparator: TMenuItem;
    miReloadModels: TMenuItem;
    miExportModels: TMenuItem;
    miSettings: TMenuItem;
    miSeparator2: TMenuItem;
    miExit: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure miReloadModelsClick(Sender: TObject);
    procedure miExportModelsClick(Sender: TObject);
    procedure miSettingsClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
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
    procedure miExitClick(Sender: TObject);
  private
    FUpdating: Boolean;
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
    procedure UpdateTitle;
    procedure LoadModelsFile(const AShowResult: Boolean);
    procedure SelectBrandAndModel(const ABrand, AModel: string);
    procedure RestoreWindow;
    procedure SaveWindowAndSelection;
  public
    { the models.csv looked for next to the EXE }
    function ModelsFileName: string;
  end;

var
  frmMain: TMainForm;

implementation

{$IFDEF FPC}
  {$R *.lfm}
{$ELSE}
  {$R *.dfm}
{$ENDIF}

uses
{$IFDEF FPC}
  IniFiles,
{$ELSE}
  System.IniFiles,
{$ENDIF}
  AppInfo,
  Main2Form,
  SettingsDialog,
  ToolbarIcons;

const
  CSearchPlaceholder = 'Quick search';
  CRefFactor = 65536;

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

{ ---------------------------------------------------------------- form }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  LoadOptions;
  LoadModelsFile(False);
  LoadBrands;
  cbSearch.Text := CSearchPlaceholder;

  { Start on the last used model, or on Realme as in the reference screen. }
  SelectBrandAndModel(
    Settings.ReadString('Main1', 'Brand', 'Realme'),
    Settings.ReadString('Main1', 'Model', ''));
  RestoreWindow;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  { Saved here and not in OnDestroy: the main form is destroyed during
    program shutdown, after the settings object is gone. }
  SaveWindowAndSelection;
end;

function TMainForm.ModelsFileName: string;
begin
  Result := ExeDir + 'models.csv';
end;

procedure TMainForm.LoadModelsFile(const AShowResult: Boolean);
var
  Skipped: Integer;
  Error, Msg: string;
begin
  if not FileExists(ModelsFileName) then
  begin
    TDeviceCatalog.ResetToBuiltIn;
    if AShowResult then
      MessageDlg('No models.csv next to the EXE - using the built-in list.' +
        sLineBreak + sLineBreak +
        'Use Menu > Export models.csv to create one.', mtInformation, [mbOK], 0);
    Exit;
  end;
  if TDeviceCatalog.LoadFromFile(ModelsFileName, Skipped, Error) then
  begin
    if AShowResult or (Skipped > 0) then
    begin
      Msg := Format('Loaded %d models (%d brands) from models.csv.',
        [TDeviceCatalog.TotalModels, TDeviceCatalog.BrandCount]);
      if Skipped > 0 then
        Msg := Msg + sLineBreak + Format('%d line(s) could not be read and ' +
          'were skipped. Each line should look like: Brand,Model code,Name',
          [Skipped]);
      MessageDlg(Msg, mtInformation, [mbOK], 0);
    end;
  end
  else
  begin
    TDeviceCatalog.ResetToBuiltIn;
    MessageDlg('models.csv could not be used - the built-in list is shown.' +
      sLineBreak + sLineBreak + Error, mtWarning, [mbOK], 0);
  end;
end;

procedure TMainForm.SelectBrandAndModel(const ABrand, AModel: string);
var
  I, B: Integer;
begin
  B := TDeviceCatalog.FindBrand(ABrand);
  if B < 0 then
    B := TDeviceCatalog.FindBrand('Realme');
  if B < 0 then
    B := 0;
  lstBrands.ItemIndex := B;
  LoadBrandModels(B);
  if AModel <> '' then
    for I := 0 to lstModels.Items.Count - 1 do
      if lstModels.Items[I] = AModel then
      begin
        lstModels.ItemIndex := I;
        Break;
      end;
  UpdateNextState;
end;

procedure TMainForm.RestoreWindow;
var
  Ini: TMemIniFile;
  L, T, W, H: Integer;
begin
  Ini := Settings;
  W := Ini.ReadInteger('Main1', 'Width', 0);
  H := Ini.ReadInteger('Main1', 'Height', 0);
  if (W < Constraints.MinWidth) or (H < Constraints.MinHeight) then
    Exit;
  L := Ini.ReadInteger('Main1', 'Left', 0);
  T := Ini.ReadInteger('Main1', 'Top', 0);
  { only if the window would still be on a screen }
  if (L + 100 > Screen.DesktopLeft + Screen.DesktopWidth) or
     (T + 50 > Screen.DesktopTop + Screen.DesktopHeight) or
     (L + W < Screen.DesktopLeft + 100) or (T < Screen.DesktopTop - 10) then
    Exit;
  Position := poDesigned;
  SetBounds(L, T, W, H);
  if Ini.ReadBool('Main1', 'Maximized', False) then
    WindowState := wsMaximized;
end;

procedure TMainForm.SaveWindowAndSelection;
var
  Ini: TMemIniFile;
  B, M: Integer;
begin
  Ini := Settings;
  if SelectedDevice(B, M) then
  begin
    Ini.WriteString('Main1', 'Brand', TDeviceCatalog.BrandName(B));
    Ini.WriteString('Main1', 'Model', TDeviceCatalog.ModelName(B, M));
  end
  else if lstBrands.ItemIndex >= 0 then
  begin
    Ini.WriteString('Main1', 'Brand', lstBrands.Items[lstBrands.ItemIndex]);
    Ini.WriteString('Main1', 'Model', '');
  end;
  Ini.WriteBool('Main1', 'Maximized', WindowState = wsMaximized);
  if WindowState = wsNormal then
  begin
    Ini.WriteInteger('Main1', 'Left', Left);
    Ini.WriteInteger('Main1', 'Top', Top);
    Ini.WriteInteger('Main1', 'Width', Width);
    Ini.WriteInteger('Main1', 'Height', Height);
  end;
  FlushSettings;
end;

procedure TMainForm.UpdateTitle;
var
  Info: string;
begin
  if SearchText <> '' then
    Info := Format('%d result(s) for "%s"', [lstModels.Items.Count, SearchText])
  else if lstBrands.ItemIndex >= 0 then
    Info := Format('%s : %d model(s)', [lstBrands.Items[lstBrands.ItemIndex],
      lstModels.Items.Count])
  else
    Info := '';
  if Info <> '' then
    Caption := AppTitle + '  -  ' + Info
  else
    Caption := AppTitle;
end;

procedure TMainForm.miReloadModelsClick(Sender: TObject);
var
  B, M: Integer;
  Brand, Model: string;
begin
  Brand := 'Realme';
  Model := '';
  if SelectedDevice(B, M) then
  begin
    Brand := TDeviceCatalog.BrandName(B);
    Model := TDeviceCatalog.ModelName(B, M);
  end
  else if lstBrands.ItemIndex >= 0 then
    Brand := lstBrands.Items[lstBrands.ItemIndex];
  LoadModelsFile(True);
  FUpdating := True;
  try
    cbSearch.Text := CSearchPlaceholder;
  finally
    FUpdating := False;
  end;
  LoadBrands;
  SelectBrandAndModel(Brand, Model);
end;

procedure TMainForm.miExportModelsClick(Sender: TObject);
var
  Dialog: TSaveDialog;
begin
  Dialog := TSaveDialog.Create(Self);
  try
    Dialog.Title := 'Export model list';
    Dialog.Filter := 'CSV files (*.csv)|*.csv|All files (*.*)|*.*';
    Dialog.DefaultExt := 'csv';
    Dialog.Options := Dialog.Options + [ofOverwritePrompt];
    Dialog.InitialDir := ExeDir;
    Dialog.FileName := 'models.csv';
    if not Dialog.Execute then
      Exit;
    TDeviceCatalog.ExportToFile(Dialog.FileName);
    MessageDlg(Format('Saved %d models to:', [TDeviceCatalog.TotalModels]) +
      sLineBreak + Dialog.FileName + sLineBreak + sLineBreak +
      'Edit it in Notepad or Excel (Brand,Model code,Name), keep it next to ' +
      'the EXE as models.csv, then use Menu > Reload models.',
      mtInformation, [mbOK], 0);
  finally
    Dialog.Free;
  end;
end;

procedure TMainForm.miSettingsClick(Sender: TObject);
begin
  ShowSettingsDialog(Self);
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  if cbSearch.CanFocus then
  begin
    cbSearch.SetFocus;
    cbSearch.SelectAll;
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
  UpdateTitle;
end;

procedure TMainForm.LoadSearchResults(const AText: string);
var
  B, M: Integer;
  BrandMatches: Boolean;
begin
  FUpdating := True;
  try
    lstModels.Items.BeginUpdate;
    try
      lstModels.Items.Clear;
      for B := 0 to TDeviceCatalog.BrandCount - 1 do
      begin
        BrandMatches := ContainsText(TDeviceCatalog.BrandName(B), AText);
        for M := 0 to TDeviceCatalog.ModelCount(B) - 1 do
          if BrandMatches or
             ContainsText(TDeviceCatalog.ModelName(B, M), AText) then
            AddModelItem(B, M, True);
      end;
      lstModels.ItemIndex := -1;
    finally
      lstModels.Items.EndUpdate;
    end;
  finally
    FUpdating := False;
  end;
  UpdateNextState;
  UpdateTitle;
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
        cbSearch.Text := '';
        cbSearchChange(cbSearch);
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
  PaintIcon(pbMenu.Canvas, pbMenu.ClientRect, DrawMenuIcon);
end;

procedure TMainForm.pbNextPaint(Sender: TObject);
begin
  if pbNext.Enabled then
    PaintIcon(pbNext.Canvas, pbNext.ClientRect, DrawNextIconEnabled)
  else
    PaintIcon(pbNext.Canvas, pbNext.ClientRect, DrawNextIconDisabled);
end;

procedure TMainForm.pbDownloadPaint(Sender: TObject);
begin
  PaintIcon(pbDownload.Canvas, pbDownload.ClientRect, DrawDownloadIcon);
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
begin
  if lstModels.Items.Count = 0 then
    Exit;
  Dialog := TSaveDialog.Create(Self);
  try
    Dialog.Title := 'Save model list';
    Dialog.Filter := 'Text files (*.txt)|*.txt|All files (*.*)|*.*';
    Dialog.DefaultExt := 'txt';
    Dialog.Options := Dialog.Options + [ofOverwritePrompt];
    if lstBrands.ItemIndex >= 0 then
      Dialog.FileName := lstBrands.Items[lstBrands.ItemIndex] + ' models.txt';
    if Dialog.Execute then
      {$IFDEF FPC}
      lstModels.Items.SaveToFile(Dialog.FileName);  { LCL strings are UTF-8 }
      {$ELSE}
      lstModels.Items.SaveToFile(Dialog.FileName, TEncoding.UTF8);
      {$ENDIF}
  finally
    Dialog.Free;
  end;
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

  SaveWindowAndSelection;
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
