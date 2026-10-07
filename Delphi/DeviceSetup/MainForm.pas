unit MainForm;

interface

uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  System.Types,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  DeviceCatalog;

type
  TMainForm = class(TForm)
    pnlHeader: TPanel;
    lblEyebrow: TLabel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    lblStep: TLabel;
    pnlFooter: TPanel;
    lblSelectionCaption: TLabel;
    lblSelectionValue: TLabel;
    lblSelectionNote: TLabel;
    btnNext: TButton;
    pnlWorkspace: TPanel;
    pnlBrandCard: TPanel;
    lblBrandSection: TLabel;
    lblBrandCount: TLabel;
    lblBrandTitle: TLabel;
    lblBrandHelper: TLabel;
    lstBrands: TListBox;
    pnlModelCard: TPanel;
    lblModelSection: TLabel;
    lblModelCount: TLabel;
    lblModelTitle: TLabel;
    lblModelHelper: TLabel;
    lstModels: TListBox;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure lstBrandsClick(Sender: TObject);
    procedure lstModelsClick(Sender: TObject);
    procedure lstBrandsDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure lstModelsDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure btnNextClick(Sender: TObject);
  private
    FUpdatingCatalog: Boolean;
    procedure ApplyTheme;
    procedure ReflowLayout;
    procedure PopulateModels(const ABrandIndex: Integer);
    procedure RefreshSelection;
    procedure DrawCatalogItem(AListBox: TListBox; const AIndex: Integer;
      const ARect: TRect; const AState: TOwnerDrawState;
      const AShowModelCount: Boolean);
  end;

var
  frmMain: TMainForm;

implementation

{$R *.dfm}

const
  CBackground: TColor = TColor($001F120C);     { RGB(12, 18, 31) }
  CSurface: TColor = TColor($002D1D14);        { RGB(20, 29, 45) }
  CListRow: TColor = TColor($0036281D);        { RGB(29, 40, 54) }
  CSelectedRow: TColor = TColor($00433722);    { RGB(34, 55, 67) }
  CSelectedBorder: TColor = TColor($00553E2B); { RGB(43, 62, 85) }
  CPrimaryText: TColor = TColor($00FAF4F0);    { RGB(240, 244, 250) }
  CSecondaryText: TColor = TColor($00C7B5A8);  { RGB(168, 181, 199) }
  CMutedText: TColor = TColor($00998271);      { RGB(113, 130, 153) }
  CAccent: TColor = TColor($00ADDA38);         { RGB(56, 218, 173) }

procedure TMainForm.ApplyTheme;
begin
  Color := CBackground;
  Font.Name := 'Segoe UI';

  pnlHeader.Color := CBackground;
  pnlWorkspace.Color := CBackground;
  pnlFooter.Color := CBackground;
  pnlBrandCard.Color := CSurface;
  pnlModelCard.Color := CSurface;

  lblEyebrow.Font.Color := CAccent;
  lblTitle.Font.Color := CPrimaryText;
  lblSubtitle.Font.Color := CSecondaryText;
  lblStep.Font.Color := CMutedText;

  lblBrandSection.Font.Color := CAccent;
  lblBrandCount.Font.Color := CMutedText;
  lblBrandTitle.Font.Color := CPrimaryText;
  lblBrandHelper.Font.Color := CSecondaryText;

  lblModelSection.Font.Color := CAccent;
  lblModelCount.Font.Color := CMutedText;
  lblModelTitle.Font.Color := CPrimaryText;
  lblModelHelper.Font.Color := CSecondaryText;

  lblSelectionCaption.Font.Color := CAccent;
  lblSelectionValue.Font.Color := CPrimaryText;
  lblSelectionNote.Font.Color := CSecondaryText;

  lstBrands.Color := CSurface;
  lstBrands.Font.Color := CPrimaryText;
  lstModels.Color := CSurface;
  lstModels.Font.Color := CPrimaryText;

  btnNext.Color := CAccent;
  btnNext.Font.Color := CBackground;
  btnNext.StyleElements := [seFont, seBorder];
  btnNext.Cursor := crHandPoint;
  btnNext.Caption := 'NEXT  ' + #$2193;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  ApplyTheme;
  FUpdatingCatalog := True;
  try
    lstBrands.Items.BeginUpdate;
    try
      lstBrands.Items.Clear;
      for I := 0 to TDeviceCatalog.BrandCount - 1 do
        lstBrands.Items.Add(TDeviceCatalog.BrandName(I));
    finally
      lstBrands.Items.EndUpdate;
    end;

    lstBrands.ItemIndex := -1;
    lstModels.Items.Clear;
    lstModels.ItemIndex := -1;
    lstModels.Enabled := False;
  finally
    FUpdatingCatalog := False;
  end;

  lblBrandCount.Caption := Format('%d BRANDS', [TDeviceCatalog.BrandCount]);
  lblModelCount.Caption := '0 MODELS';
  lblModelHelper.Caption := 'Select a brand to load its models';
  lblSelectionValue.Caption := 'No device selected';
  lblSelectionNote.Caption := 'Select a brand, then choose a model to continue.';
  btnNext.Enabled := False;
  ReflowLayout;
  lstBrands.Invalidate;
  lstModels.Invalidate;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  ReflowLayout;
end;

procedure TMainForm.ReflowLayout;
var
  AvailableWidth: Integer;
  BrandCardWidth: Integer;
  SummaryWidth: Integer;
begin
  if not Assigned(pnlWorkspace) then
    Exit;

  AvailableWidth := pnlWorkspace.ClientWidth - pnlWorkspace.Padding.Left -
    pnlWorkspace.Padding.Right;
  BrandCardWidth := Round(AvailableWidth * 0.37);
  if BrandCardWidth < 290 then
    BrandCardWidth := 290;
  if BrandCardWidth > 430 then
    BrandCardWidth := 430;
  pnlBrandCard.Width := BrandCardWidth;

  if Assigned(btnNext) and Assigned(lblSelectionValue) and
     Assigned(lblSelectionNote) then
  begin
    SummaryWidth := btnNext.Left - lblSelectionValue.Left - 32;
    if SummaryWidth < 180 then
      SummaryWidth := 180;
    lblSelectionValue.Width := SummaryWidth;
    lblSelectionNote.Width := SummaryWidth;
  end;
end;

procedure TMainForm.PopulateModels(const ABrandIndex: Integer);
var
  I: Integer;
  ModelCount: Integer;
begin
  FUpdatingCatalog := True;
  try
    lstModels.Items.BeginUpdate;
    try
      lstModels.Items.Clear;
      lstModels.ItemIndex := -1;
      if (ABrandIndex >= 0) and
         (ABrandIndex < TDeviceCatalog.BrandCount) then
      begin
        ModelCount := TDeviceCatalog.ModelCount(ABrandIndex);
        for I := 0 to ModelCount - 1 do
          lstModels.Items.Add(TDeviceCatalog.ModelName(ABrandIndex, I));

        lblModelHelper.Caption := Format('Available models for %s',
          [TDeviceCatalog.BrandName(ABrandIndex)]);
        lblModelCount.Caption := Format('%d MODELS', [ModelCount]);
        lstModels.Enabled := True;
      end
      else
      begin
        lblModelHelper.Caption := 'Select a brand to load its models';
        lblModelCount.Caption := '0 MODELS';
        lstModels.Enabled := False;
      end;
    finally
      lstModels.Items.EndUpdate;
    end;
  finally
    FUpdatingCatalog := False;
  end;

  lstModels.Invalidate;
end;

procedure TMainForm.RefreshSelection;
var
  BrandIndex: Integer;
  ModelIndex: Integer;
begin
  BrandIndex := lstBrands.ItemIndex;
  ModelIndex := lstModels.ItemIndex;

  if (BrandIndex >= 0) and (ModelIndex >= 0) then
  begin
    lblSelectionValue.Caption := Format('%s  /  %s',
      [TDeviceCatalog.BrandName(BrandIndex),
       TDeviceCatalog.ModelName(BrandIndex, ModelIndex)]);
    lblSelectionNote.Caption := 'Device selected. Continue when you are ready.';
    btnNext.Enabled := True;
  end
  else if BrandIndex >= 0 then
  begin
    lblSelectionValue.Caption := TDeviceCatalog.BrandName(BrandIndex);
    lblSelectionNote.Caption := 'Now choose a model from the list.';
    btnNext.Enabled := False;
  end
  else
  begin
    lblSelectionValue.Caption := 'No device selected';
    lblSelectionNote.Caption := 'Select a brand, then choose a model to continue.';
    btnNext.Enabled := False;
  end;
end;

procedure TMainForm.lstBrandsClick(Sender: TObject);
begin
  if FUpdatingCatalog then
    Exit;

  PopulateModels(lstBrands.ItemIndex);
  RefreshSelection;
  lstBrands.Invalidate;
end;

procedure TMainForm.lstModelsClick(Sender: TObject);
begin
  if FUpdatingCatalog then
    Exit;
  RefreshSelection;
  lstModels.Invalidate;
end;

procedure TMainForm.DrawCatalogItem(AListBox: TListBox;
  const AIndex: Integer; const ARect: TRect; const AState: TOwnerDrawState;
  const AShowModelCount: Boolean);
var
  RowRect: TRect;
  TextRect: TRect;
  MetaRect: TRect;
  IsSelected: Boolean;
  ItemText: string;
  MetaText: string;
begin
  AListBox.Canvas.Brush.Style := bsSolid;
  AListBox.Canvas.Brush.Color := CSurface;
  AListBox.Canvas.FillRect(ARect);

  if (AIndex < 0) or (AIndex >= AListBox.Items.Count) then
    Exit;

  RowRect := ARect;
  InflateRect(RowRect, -3, -2);
  IsSelected := odSelected in AState;

  if IsSelected then
  begin
    AListBox.Canvas.Brush.Color := CSelectedRow;
    AListBox.Canvas.Pen.Color := CSelectedBorder;
  end
  else
  begin
    AListBox.Canvas.Brush.Color := CListRow;
    AListBox.Canvas.Pen.Color := CListRow;
  end;
  AListBox.Canvas.RoundRect(RowRect.Left, RowRect.Top, RowRect.Right,
    RowRect.Bottom, 10, 10);

  if IsSelected then
  begin
    AListBox.Canvas.Brush.Color := CAccent;
    AListBox.Canvas.Pen.Color := CAccent;
    AListBox.Canvas.RoundRect(RowRect.Left + 8, RowRect.Top + 12,
      RowRect.Left + 12, RowRect.Bottom - 12, 3, 3);
  end;

  ItemText := AListBox.Items[AIndex];
  TextRect := RowRect;
  TextRect.Left := RowRect.Left + 23;
  TextRect.Right := RowRect.Right - 16;

  if AShowModelCount then
  begin
    TextRect.Right := RowRect.Right - 108;
    MetaRect := RowRect;
    MetaRect.Left := RowRect.Right - 101;
    MetaRect.Right := RowRect.Right - 16;

    MetaText := Format('%d models', [TDeviceCatalog.ModelCount(AIndex)]);
    AListBox.Canvas.Font.Assign(AListBox.Font);
    AListBox.Canvas.Font.Size := 9;
    AListBox.Canvas.Font.Color := CMutedText;
    SetBkMode(AListBox.Canvas.Handle, TRANSPARENT);
    DrawText(AListBox.Canvas.Handle, PChar(MetaText), Length(MetaText),
      MetaRect, DT_VCENTER or DT_SINGLELINE or DT_RIGHT or DT_END_ELLIPSIS);
  end;

  AListBox.Canvas.Font.Assign(AListBox.Font);
  AListBox.Canvas.Font.Color := CPrimaryText;
  if IsSelected then
    AListBox.Canvas.Font.Style := [fsBold]
  else
    AListBox.Canvas.Font.Style := [];
  SetBkMode(AListBox.Canvas.Handle, TRANSPARENT);
  DrawText(AListBox.Canvas.Handle, PChar(ItemText), Length(ItemText), TextRect,
    DT_VCENTER or DT_SINGLELINE or DT_LEFT or DT_END_ELLIPSIS);

  if odFocused in AState then
    AListBox.Canvas.DrawFocusRect(RowRect);
end;

procedure TMainForm.lstBrandsDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
begin
  DrawCatalogItem(lstBrands, Index, Rect, State, True);
end;

procedure TMainForm.lstModelsDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
begin
  DrawCatalogItem(lstModels, Index, Rect, State, False);
end;

procedure TMainForm.btnNextClick(Sender: TObject);
var
  BrandIndex: Integer;
  ModelIndex: Integer;
begin
  BrandIndex := lstBrands.ItemIndex;
  ModelIndex := lstModels.ItemIndex;
  if (BrandIndex < 0) or (ModelIndex < 0) then
    Exit;

  MessageDlg(Format('%s / %s selected.%s%sThe next screen will be added in the next stage.',
    [TDeviceCatalog.BrandName(BrandIndex),
     TDeviceCatalog.ModelName(BrandIndex, ModelIndex), sLineBreak, sLineBreak]),
    mtInformation, [mbOK], 0);
end;

end.
