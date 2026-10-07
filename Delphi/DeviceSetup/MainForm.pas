unit MainForm;

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
    miExit: TMenuItem;
    procedure FormCreate(Sender: TObject);
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
  end;

var
  frmMain: TMainForm;

implementation

{$R *.dfm}

uses
  Main2Form,
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
var
  I: Integer;
begin
  LoadBrands;
  cbSearch.Text := CSearchPlaceholder;

  { Start on Realme, as in the reference screen. }
  for I := 0 to lstBrands.Items.Count - 1 do
    if SameText(lstBrands.Items[I], 'Realme') then
    begin
      lstBrands.ItemIndex := I;
      Break;
    end;
  if lstBrands.ItemIndex < 0 then
    lstBrands.ItemIndex := 0;
  LoadBrandModels(lstBrands.ItemIndex);
  UpdateNextState;
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
      lstModels.Items.SaveToFile(Dialog.FileName, TEncoding.UTF8);
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
