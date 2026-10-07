unit SampleControls;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

{ Theme-independent controls for the supplied servicing UI. Native edit,
  combo, check, radio and list controls still handle user input. These small
  painted controls make the frames, button faces and compact tab strip the
  same in Delphi VCL and Lazarus, including unthemed Windows CI runners.
  Children use ordinary client coordinates: there is no LCL group-caption
  offset or native tab padding to compensate for. }

interface

uses
{$IFDEF FPC}
  Windows, Classes, SysUtils, Types, Controls, Graphics, StdCtrls, LMessages;
{$ELSE}
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls;
{$ENDIF}

type
{$IFDEF FPC}
  TNativeControlMessage = TLMessage;
{$ELSE}
  TNativeControlMessage = TMessage;
{$ENDIF}

  TSamplePageControl = class;

  TSampleGroupBox = class(TCustomControl)
  private
    FTitle: string;
    FCaptionInset: Integer;
    procedure SetTitle(const AValue: string);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Caption: string read FTitle write SetTitle;
    property CaptionInset: Integer read FCaptionInset write FCaptionInset default 5;
    property Align;
    property Anchors;
    property Color;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property TabOrder;
    property TabStop;
    property Visible;
    property ShowHint;
    property Hint;
  end;

  TSampleButton = class(TCustomControl)
  private
    FTitle: string;
    FGlyph: TBitmap;
    FDisabledGlyph: TBitmap;
    FMargin: Integer;
    FSpacing: Integer;
    FNumGlyphs: Integer;
    FCentered: Boolean;
    FPressed: Boolean;
    FReferenceHeight: Integer;
    procedure WMGetDlgCode(var AMessage: TNativeControlMessage); message WM_GETDLGCODE;
    procedure SetTitle(const AValue: string);
    procedure SetGlyph(AValue: TBitmap);
    procedure GlyphChanged(Sender: TObject);
    procedure SetCentered(const AValue: Boolean);
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure DoEnter; override;
    procedure DoExit; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Caption: string read FTitle write SetTitle;
    property Glyph: TBitmap read FGlyph write SetGlyph;
    property Margin: Integer read FMargin write FMargin default 2;
    property Spacing: Integer read FSpacing write FSpacing default 8;
    property NumGlyphs: Integer read FNumGlyphs write FNumGlyphs default 1;
    property ReferenceHeight: Integer read FReferenceHeight write FReferenceHeight default 34;
    property Centered: Boolean read FCentered write SetCentered default False;
    property Align;
    property Anchors;
    property Enabled;
    property Font;
    property ParentFont;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property Cursor;
    property Hint;
    property ShowHint;
    property OnClick;
    property OnKeyDown;
  end;

  TSampleTabSheet = class(TCustomControl)
  private
    FPageControl: TSamplePageControl;
    FTitle: string;
    FImageIndex: Integer;
    procedure SetTitle(const AValue: string);
  protected
    procedure SetParent(AParent: TWinControl); override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property PageControl: TSamplePageControl read FPageControl;
  published
    property Caption: string read FTitle write SetTitle;
    property ImageIndex: Integer read FImageIndex write FImageIndex default -1;
    property Font;
    property ParentFont;
    property TabOrder;
    property TabStop;
  end;

  TSamplePageControl = class(TCustomControl)
  private
    FPages: TList;
    FActivePage: TSampleTabSheet;
    FTabWidth: Integer;
    FOnChange: TNotifyEvent;
    procedure WMGetDlgCode(var AMessage: TNativeControlMessage); message WM_GETDLGCODE;
    function GetPageCount: Integer;
    function GetPage(const AIndex: Integer): TSampleTabSheet;
    function GetActivePageIndex: Integer;
    procedure SetActivePage(AValue: TSampleTabSheet);
    procedure SetActivePageIndex(const AValue: Integer);
    procedure AddPage(APage: TSampleTabSheet);
    procedure RemovePage(APage: TSampleTabSheet);
    procedure LayoutPages;
    procedure SetTabWidth(const AValue: Integer);
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure Loaded; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function TabRect(const AIndex: Integer): TRect;
    function HeaderHeight: Integer;
    function ScaleValue(const AValue: Integer): Integer;
    procedure RefreshLayout;
    property PageCount: Integer read GetPageCount;
    property Pages[const AIndex: Integer]: TSampleTabSheet read GetPage;
    property ActivePageIndex: Integer read GetActivePageIndex
      write SetActivePageIndex;
  published
    property ActivePage: TSampleTabSheet read FActivePage write SetActivePage;
    { Zero = content-sized Jobs / META tabs; 47 = the seven operation tabs. }
    property TabWidth: Integer read FTabWidth write SetTabWidth default 0;
    property Align;
    property Anchors;
    property Enabled;
    property Font;
    property ParentFont;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

procedure CompactCombo(ACombo: TComboBox; const AHeight: Integer);

implementation

function ScaleFont(AFont: TFont; const AValue: Integer): Integer;
var
  H: Integer;
begin
  { The reference controls use a 10-pixel Tahoma font at 96 DPI. Scaling
    with the font also works with Form.ScaleBy in the 144/192-DPI tests. }
  H := Abs(AFont.Height);
  if H <= 0 then
    H := 10;
  Result := MulDiv(AValue, H, 10);
  if (AValue > 0) and (Result < 1) then
    Result := 1;
end;

constructor TSampleGroupBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls, csOpaque];
  Color := $00F0F0F0;
  ParentColor := True;
  ParentFont := True;
  FCaptionInset := 5;
  TabStop := False;
end;

procedure TSampleGroupBox.SetTitle(const AValue: string);
begin
  FTitle := AValue;
  SetTextBuf(PChar(AValue));
  Invalidate;
end;

procedure TSampleGroupBox.Paint;
var
  Y, X, W, I: Integer;
  E: TEdit;
begin
  Canvas.Font.Assign(Font);
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);
  Y := (Canvas.TextHeight('Wg') - 1) div 2;
  Canvas.Pen.Color := $00E0E0E0;
  Canvas.Pen.Width := 1;
  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(0, Y, ClientWidth, ClientHeight);
  X := ScaleFont(Font, FCaptionInset);
  W := Canvas.TextWidth(FTitle);
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(Rect(X - 2, 0, X + W + 2, Y * 2));
  Canvas.TextOut(X, 0, FTitle);
  for I := 0 to ControlCount - 1 do
    if Controls[I] is TEdit then
    begin
      E := TEdit(Controls[I]);
      if E.BorderStyle = bsNone then
      begin
        Canvas.Pen.Color := $00BBBBBB;
        Canvas.MoveTo(E.Left, E.Top + E.Height);
        Canvas.LineTo(E.Left + E.Width, E.Top + E.Height);
      end;
    end;
end;

constructor TSampleButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csClickEvents, csCaptureMouse];
  TabStop := True;
  Width := 300;
  Height := 34;
  FMargin := 2;
  FSpacing := 8;
  FNumGlyphs := 1;
  FReferenceHeight := 34;
  ParentFont := True;
  FGlyph := TBitmap.Create;
  FGlyph.OnChange := GlyphChanged;
  FDisabledGlyph := TBitmap.Create;
end;

destructor TSampleButton.Destroy;
begin
  FGlyph.OnChange := nil;
  FGlyph.Free;
  FDisabledGlyph.Free;
  inherited Destroy;
end;

procedure TSampleButton.SetTitle(const AValue: string);
begin
  FTitle := AValue;
  SetTextBuf(PChar(AValue));
  Invalidate;
end;

procedure TSampleButton.SetGlyph(AValue: TBitmap);
begin
  FGlyph.Assign(AValue);
end;

procedure TSampleButton.SetCentered(const AValue: Boolean);
begin
  FCentered := AValue;
  Invalidate;
end;

procedure TSampleButton.GlyphChanged(Sender: TObject);
var
  X, Y, Gray: Integer;
  C: TColor;
begin
  FDisabledGlyph.Assign(FGlyph);
  if not FGlyph.Empty then
  begin
    FDisabledGlyph.PixelFormat := pf24bit;
    for Y := 0 to FDisabledGlyph.Height - 1 do
      for X := 0 to FDisabledGlyph.Width - 1 do
      begin
        C := ColorToRGB(FGlyph.Canvas.Pixels[X, Y]);
        if C <> ColorToRGB(clFuchsia) then
        begin
          Gray := (GetRValue(C) * 30 + GetGValue(C) * 59 +
            GetBValue(C) * 11) div 100;
          Gray := (Gray + 232) div 2;
          FDisabledGlyph.Canvas.Pixels[X, Y] := RGB(Gray, Gray, Gray);
        end;
      end;
    FDisabledGlyph.TransparentColor := clFuchsia;
    FDisabledGlyph.Transparent := True;
  end;
  Invalidate;
end;

procedure TSampleButton.Paint;
var
  R, IconRect: TRect;
  X, Y, GW, GH, Gap, TextW, TextH, Offset: Integer;
  B: TBitmap;

  function Scale(const AValue: Integer): Integer;
  begin
    Result := MulDiv(AValue, ClientHeight, FReferenceHeight);
  end;

begin
  Canvas.Font.Assign(Font);
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := $00F0F0F0;
  Canvas.FillRect(ClientRect);
  if FPressed and Enabled then
    Canvas.Brush.Color := $00DADADA
  else
    Canvas.Brush.Color := $00E8E8E8;
  Canvas.Pen.Color := $00AAAAAA;
  Canvas.Pen.Width := 1;
  Canvas.RoundRect(0, 0, ClientWidth, ClientHeight,
    Scale(4), Scale(4));
  if not Enabled then
    Canvas.Font.Color := $00989898;
  TextW := Canvas.TextWidth(FTitle);
  TextH := Canvas.TextHeight(FTitle);
  Offset := Ord(FPressed and Enabled);
  GW := 0;
  GH := 0;
  Gap := 0;
  if not FGlyph.Empty then
  begin
    GW := Scale(FGlyph.Width);
    GH := Scale(FGlyph.Height);
    Gap := Scale(FSpacing);
  end;
  if FCentered or FGlyph.Empty then
    X := (ClientWidth - GW - Gap - TextW) div 2
  else
    X := Scale(FMargin);
  if GW > 0 then
  begin
    Y := (ClientHeight - GH) div 2;
    IconRect := Rect(X + Offset, Y + Offset, X + GW + Offset, Y + GH + Offset);
    if Enabled then
      B := FGlyph
    else
      B := FDisabledGlyph;
    if (GW = B.Width) and (GH = B.Height) then
      Canvas.Draw(IconRect.Left, IconRect.Top, B)
    else
      Canvas.StretchDraw(IconRect, B);
    Inc(X, GW + Gap);
  end;
  Canvas.Brush.Style := bsClear;
  Canvas.TextOut(X + Offset, (ClientHeight - TextH) div 2 + Offset, FTitle);
  Canvas.Brush.Style := bsSolid;
  if Focused then
  begin
    R := Rect(3, 3, ClientWidth - 3, ClientHeight - 3);
    Canvas.DrawFocusRect(R);
  end;
end;

procedure TSampleButton.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    if CanFocus then
      SetFocus;
    FPressed := True;
    Invalidate;
  end;
end;

procedure TSampleButton.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  FPressed := False;
  Invalidate;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TSampleButton.WMGetDlgCode(var AMessage: TNativeControlMessage);
begin
  AMessage.Result := DLGC_BUTTON;
  if AMessage.WParam in [VK_SPACE, VK_RETURN] then
    AMessage.Result := AMessage.Result or DLGC_WANTALLKEYS;
end;

procedure TSampleButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if not Enabled then
    Exit;
  if Key = VK_SPACE then
  begin
    FPressed := True;
    Invalidate;
    Key := 0;
  end
  else if Key = VK_RETURN then
  begin
    Key := 0;
    Click;
  end;
end;

procedure TSampleButton.KeyUp(var Key: Word; Shift: TShiftState);
var
  Activate: Boolean;
begin
  inherited KeyUp(Key, Shift);
  if Key = VK_SPACE then
  begin
    Activate := FPressed and Enabled;
    FPressed := False;
    Invalidate;
    Key := 0;
    if Activate then
      Click;
  end;
end;

procedure TSampleButton.DoEnter;
begin
  inherited DoEnter;
  Invalidate;
end;

procedure TSampleButton.DoExit;
begin
  FPressed := False;
  inherited DoExit;
  Invalidate;
end;

constructor TSampleTabSheet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls, csOpaque];
  Color := $00F0F0F0;
  FImageIndex := -1;
  ParentFont := True;
  TabStop := False;
end;

destructor TSampleTabSheet.Destroy;
begin
  if FPageControl <> nil then
    FPageControl.RemovePage(Self);
  inherited Destroy;
end;

procedure TSampleTabSheet.SetParent(AParent: TWinControl);
begin
  if Parent = AParent then
    Exit;
  if FPageControl <> nil then
    FPageControl.RemovePage(Self);
  FPageControl := nil;
  inherited SetParent(AParent);
  if AParent is TSamplePageControl then
  begin
    FPageControl := TSamplePageControl(AParent);
    FPageControl.AddPage(Self);
  end;
end;

procedure TSampleTabSheet.SetTitle(const AValue: string);
begin
  FTitle := AValue;
  SetTextBuf(PChar(AValue));
  if FPageControl <> nil then
    FPageControl.Invalidate;
end;

procedure TSampleTabSheet.Paint;
begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);
end;

constructor TSamplePageControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls, csOpaque];
  FPages := TList.Create;
  ParentFont := True;
  Color := $00F0F0F0;
  TabStop := True;
  Width := 337;
  Height := 300;
end;

destructor TSamplePageControl.Destroy;
var
  I: Integer;
begin
  { Forms own the pages; detach the list before those children are freed. }
  for I := 0 to FPages.Count - 1 do
    TSampleTabSheet(FPages[I]).FPageControl := nil;
  FreeAndNil(FPages);
  inherited Destroy;
end;

function TSamplePageControl.GetPageCount: Integer;
begin
  if FPages = nil then
    Result := 0
  else
    Result := FPages.Count;
end;

function TSamplePageControl.GetPage(const AIndex: Integer): TSampleTabSheet;
begin
  Result := TSampleTabSheet(FPages[AIndex]);
end;

function TSamplePageControl.GetActivePageIndex: Integer;
begin
  if FPages = nil then
    Result := -1
  else
    Result := FPages.IndexOf(FActivePage);
end;

function TSamplePageControl.ScaleValue(const AValue: Integer): Integer;
begin
  { The right column stays fixed when the window is resized. Its width
    scales with DPI, unlike integer font-point metrics which round again. }
  Result := MulDiv(AValue, ClientWidth, 337);
end;

function TSamplePageControl.HeaderHeight: Integer;
begin
  Result := ScaleValue(18);
end;

function TSamplePageControl.TabRect(const AIndex: Integer): TRect;
var
  I, X, W: Integer;
begin
  Result := Rect(0, 0, 0, 0);
  if (AIndex < 0) or (AIndex >= PageCount) then
    Exit;
  Canvas.Font.Assign(Font);
  X := ScaleValue(1);
  if FTabWidth > 0 then
    X := ScaleValue(5);
  for I := 0 to AIndex do
  begin
    if FTabWidth > 0 then
      W := ScaleValue(FTabWidth)
    else if I = 0 then
      W := ScaleValue(35)
    else
      W := Canvas.TextWidth(Pages[I].Caption) + ScaleValue(14);
    if I = AIndex then
      Result := Rect(X, 0, X + W, HeaderHeight - ScaleValue(2));
    Inc(X, W);
  end;
end;

procedure TSamplePageControl.SetTabWidth(const AValue: Integer);
begin
  FTabWidth := AValue;
  Invalidate;
end;

procedure TSamplePageControl.AddPage(APage: TSampleTabSheet);
begin
  if FPages.IndexOf(APage) >= 0 then
    Exit;
  FPages.Add(APage);
  if FActivePage = nil then
    FActivePage := APage;
  LayoutPages;
end;

procedure TSamplePageControl.RemovePage(APage: TSampleTabSheet);
begin
  if FPages = nil then
    Exit;
  FPages.Remove(APage);
  if FActivePage = APage then
  begin
    FActivePage := nil;
    if FPages.Count > 0 then
      FActivePage := Pages[0];
  end;
  if not (csDestroying in ComponentState) then
    LayoutPages;
end;

procedure TSamplePageControl.SetActivePage(AValue: TSampleTabSheet);
begin
  if (AValue <> nil) and (AValue.FPageControl <> Self) then
    Exit;
  if FActivePage = AValue then
    Exit;
  FActivePage := AValue;
  LayoutPages;
  if Assigned(FOnChange) and not (csLoading in ComponentState) then
    FOnChange(Self);
end;

procedure TSamplePageControl.SetActivePageIndex(const AValue: Integer);
begin
  if (AValue >= 0) and (AValue < PageCount) then
    SetActivePage(Pages[AValue]);
end;

procedure TSamplePageControl.LayoutPages;
var
  I, H: Integer;
begin
  if FPages = nil then
    Exit;
  H := HeaderHeight;
  for I := 0 to FPages.Count - 1 do
  begin
    Pages[I].SetBounds(0, H, ClientWidth, ClientHeight - H);
    Pages[I].Visible := Pages[I] = FActivePage;
  end;
  Invalidate;
end;

procedure TSamplePageControl.RefreshLayout;
var
  I, J: Integer;
  C: TControl;
begin
  LayoutPages;
  { At 150% DPI, independently rounded child positions/heights can add a
    pixel to an Options frame. Keep its actual bottom inside the page; job
    buttons retain their reference sizes and generous bottom clearance. }
  for I := 0 to PageCount - 1 do
    for J := 0 to Pages[I].ControlCount - 1 do
    begin
      C := Pages[I].Controls[J];
      if (C is TSampleGroupBox) and
        (C.Top + C.Height > Pages[I].ClientHeight) then
        C.Height := Pages[I].ClientHeight - C.Top;
    end;
end;

procedure TSamplePageControl.Resize;
begin
  inherited Resize;
  LayoutPages;
end;

procedure TSamplePageControl.Loaded;
begin
  inherited Loaded;
  LayoutPages;
end;

procedure TSamplePageControl.Paint;
const
  { Native reference headers do not centre every word identically. These
    small insets match the Flash/Read/Format/IMEI/Locks/Service/RPMB row. }
  CTextInsets: array[0..6] of Integer = (3, 5, 5, 9, 1, 5, 3);
var
  I, X, Y: Integer;
  R: TRect;
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);
  for I := 0 to PageCount - 1 do
  begin
    Canvas.Font.Assign(Font);
    R := TabRect(I);
    if (FTabWidth > 0) and (Pages[I].Caption = 'IMEI') then
    begin
      Canvas.Font.Name := 'Times New Roman';
      Canvas.Font.Height := -ScaleValue(11);
    end;
    if Pages[I] = FActivePage then
    begin
      Canvas.Brush.Color := $00D0D0D0;
      Canvas.FillRect(R);
    end;
    X := ScaleValue(2);
    Y := ScaleValue(2);
    if I = 0 then
      X := ScaleValue(1);
    if (FTabWidth > 0) and (I <= High(CTextInsets)) then
    begin
      X := ScaleValue(CTextInsets[I]);
      Y := ScaleValue(1);
      if Pages[I].Caption = 'IMEI' then
        Y := 0;
    end;
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(R.Left + X, Y, Pages[I].Caption);
    Canvas.Brush.Style := bsSolid;
  end;
end;

procedure TSamplePageControl.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button <> mbLeft) or not Enabled then
    Exit;
  for I := 0 to PageCount - 1 do
    if PtInRect(TabRect(I), Point(X, Y)) then
    begin
      if CanFocus then
        SetFocus;
      ActivePageIndex := I;
      Break;
    end;
end;

procedure TSamplePageControl.WMGetDlgCode(var AMessage: TNativeControlMessage);
begin
  AMessage.Result := DLGC_WANTARROWS;
  if AMessage.WParam in [VK_HOME, VK_END] then
    AMessage.Result := AMessage.Result or DLGC_WANTALLKEYS;
end;

procedure TSamplePageControl.KeyDown(var Key: Word; Shift: TShiftState);
var
  I: Integer;
begin
  inherited KeyDown(Key, Shift);
  if PageCount = 0 then
    Exit;
  I := ActivePageIndex;
  case Key of
    VK_LEFT: I := (I + PageCount - 1) mod PageCount;
    VK_RIGHT: I := (I + 1) mod PageCount;
    VK_HOME: I := 0;
    VK_END: I := PageCount - 1;
  else
    Exit;
  end;
  ActivePageIndex := I;
  Key := 0;
end;

procedure CompactCombo(ACombo: TComboBox; const AHeight: Integer);
var
  EditHandle: HWND;
begin
  if ACombo = nil then
    Exit;
  { Win32 otherwise replaces the DFM height with a font-dependent closed
    field height. The references have compact 18-pixel fields. }
  SendMessage(ACombo.Handle, CB_SETITEMHEIGHT, WPARAM(-1), AHeight - 6);
  ACombo.Height := AHeight;
  if ACombo.Style = csDropDown then
  begin
    EditHandle := FindWindowEx(ACombo.Handle, 0, 'Edit', nil);
    if EditHandle <> 0 then
      SendMessage(EditHandle, EM_SETMARGINS, EC_LEFTMARGIN or EC_RIGHTMARGIN, 0);
  end;
end;

initialization
  RegisterClasses([TSampleGroupBox, TSampleButton, TSamplePageControl,
    TSampleTabSheet]);

end.
