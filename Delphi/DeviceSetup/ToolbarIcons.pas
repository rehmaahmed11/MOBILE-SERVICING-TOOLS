unit ToolbarIcons;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


{ Vector-drawn icons shared by MAIN 1 and MAIN 2, so the project needs no
  binary image resources.

  Every icon is described in a fixed "design space" (28x28 for the toolbar
  icons, 24x32 for the device state icon) and then mapped onto whatever
  rectangle it is asked to draw into. That keeps the icons correct when
  Windows scales the form for a high DPI monitor, or when a paint box is
  resized. At the design size the mapping is exactly 1:1, so the icons look
  the same as they did before. }

interface

uses
{$IFDEF FPC}
  Windows, Types, Graphics;
{$ELSE}
  Winapi.Windows,
  System.Types,
  Vcl.Graphics;
{$ENDIF}

const
  CIconDesignSize = 28;

type
  TActionGlyph = (agWriteFirmware, agRestore, agWriteBin, agWriteOfp);

  { Maps a fixed design space onto a target rectangle. All drawing helpers
    take design coordinates. }
  TIconBox = record
    C: TCanvas;
    L, T, W, H: Integer;
    DW, DH: Integer;
    procedure Init(ACanvas: TCanvas; const R: TRect;
      const ADesignW: Integer = CIconDesignSize;
      const ADesignH: Integer = CIconDesignSize);
    procedure Clear;
    function PX(const AX: Integer): Integer;
    function PY(const AY: Integer): Integer;
    function P(const AX, AY: Integer): TPoint;
    function Rct(const AX1, AY1, AX2, AY2: Integer): TRect;
    function SZ(const AValue: Integer): Integer;
    procedure PenW(const AWidth: Integer);
    procedure Fill(const AX1, AY1, AX2, AY2: Integer);
    procedure Frame(const AX1, AY1, AX2, AY2: Integer);
    procedure RRect(const AX1, AY1, AX2, AY2, ARX, ARY: Integer);
    procedure Ellipse(const AX1, AY1, AX2, AY2: Integer);
    procedure Arc(const AX1, AY1, AX2, AY2, ASX, ASY, AEX, AEY: Integer);
    procedure Line(const AX1, AY1, AX2, AY2: Integer);
    procedure Poly(const AXY: array of Integer);
    procedure TextCentered(const S: string; const AX1, AY1, AX2, AY2,
      AFontHeight: Integer; const AColor: TColor);
  end;

procedure DrawMenuIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawNextIcon(ACanvas: TCanvas; const R: TRect; const AEnabled: Boolean);
procedure DrawDownloadIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawPhoneRefreshIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawGearIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawFacebookIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawHelpIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawBackIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawDeviceStateIcon(ACanvas: TCanvas; const R: TRect;
  const AConnected: Boolean);
procedure DrawGear(ACanvas: TCanvas; const CX, CY, ROuter, RInner,
  Teeth: Integer; const AColor, AHoleColor: TColor);

{ Creates a 24x24 glyph for TBitBtn. clFuchsia is the transparent colour.
  The caller owns the returned bitmap. }
function CreateActionGlyph(const AKind: TActionGlyph): TBitmap;

implementation

uses
{$IFDEF FPC}
  Math;
{$ELSE}
  System.Math;
{$ENDIF}

{ ------------------------------------------------------------ icon box }

procedure TIconBox.Init(ACanvas: TCanvas; const R: TRect;
  const ADesignW, ADesignH: Integer);
begin
  C := ACanvas;
  L := R.Left;
  T := R.Top;
  W := R.Right - R.Left;
  H := R.Bottom - R.Top;
  DW := ADesignW;
  DH := ADesignH;
  if DW <= 0 then
    DW := CIconDesignSize;
  if DH <= 0 then
    DH := CIconDesignSize;
  if W <= 0 then
    W := DW;
  if H <= 0 then
    H := DH;
end;

procedure TIconBox.Clear;
begin
  C.Pen.Width := 1;
  C.Pen.Style := psSolid;
  C.Brush.Style := bsSolid;
  C.Brush.Color := clBtnFace;
  C.FillRect(Rect(L, T, L + W, T + H));
end;

function TIconBox.PX(const AX: Integer): Integer;
begin
  Result := L + MulDiv(AX, W, DW);
end;

function TIconBox.PY(const AY: Integer): Integer;
begin
  Result := T + MulDiv(AY, H, DH);
end;

function TIconBox.P(const AX, AY: Integer): TPoint;
begin
  Result.X := PX(AX);
  Result.Y := PY(AY);
end;

function TIconBox.Rct(const AX1, AY1, AX2, AY2: Integer): TRect;
begin
  Result.Left := PX(AX1);
  Result.Top := PY(AY1);
  Result.Right := PX(AX2);
  Result.Bottom := PY(AY2);
end;

function TIconBox.SZ(const AValue: Integer): Integer;
begin
  { Scale a length (font height, pen width, radius) with the icon. }
  Result := MulDiv(AValue, W + H, DW + DH);
  if (AValue > 0) and (Result < 1) then
    Result := 1;
end;

procedure TIconBox.PenW(const AWidth: Integer);
begin
  C.Pen.Width := Max(1, SZ(AWidth));
end;

procedure TIconBox.Fill(const AX1, AY1, AX2, AY2: Integer);
begin
  C.Brush.Style := bsSolid;
  C.FillRect(Rct(AX1, AY1, AX2, AY2));
end;

procedure TIconBox.Frame(const AX1, AY1, AX2, AY2: Integer);
begin
  { Leaves the brush style alone: callers that want an outline only set
    bsClear first. }
  C.Rectangle(Rct(AX1, AY1, AX2, AY2));
end;

procedure TIconBox.RRect(const AX1, AY1, AX2, AY2, ARX, ARY: Integer);
begin
  C.Brush.Style := bsSolid;
  C.RoundRect(PX(AX1), PY(AY1), PX(AX2), PY(AY2), SZ(ARX), SZ(ARY));
end;

procedure TIconBox.Ellipse(const AX1, AY1, AX2, AY2: Integer);
begin
  { Leaves the brush style alone, like Frame. }
  C.Ellipse(Rct(AX1, AY1, AX2, AY2));
end;

procedure TIconBox.Arc(const AX1, AY1, AX2, AY2, ASX, ASY, AEX, AEY: Integer);
begin
  C.Arc(PX(AX1), PY(AY1), PX(AX2), PY(AY2),
    PX(ASX), PY(ASY), PX(AEX), PY(AEY));
end;

procedure TIconBox.Line(const AX1, AY1, AX2, AY2: Integer);
begin
  C.MoveTo(PX(AX1), PY(AY1));
  C.LineTo(PX(AX2), PY(AY2));
end;

procedure TIconBox.Poly(const AXY: array of Integer);
var
  Pts: array of TPoint;
  I, N: Integer;
begin
  N := Length(AXY) div 2;
  if N < 2 then
    Exit;
  SetLength(Pts, N);
  for I := 0 to N - 1 do
    Pts[I] := P(AXY[I * 2], AXY[I * 2 + 1]);
  C.Brush.Style := bsSolid;
  C.Polygon(Pts);
end;

procedure TIconBox.TextCentered(const S: string; const AX1, AY1, AX2, AY2,
  AFontHeight: Integer; const AColor: TColor);
var
  R: TRect;
  W, H: Integer;
begin
  C.Font.Name := 'Arial';
  C.Font.Style := [fsBold];
  C.Font.Height := -Max(6, SZ(AFontHeight));
  C.Font.Color := AColor;
  C.Brush.Style := bsClear;
  R := Rct(AX1, AY1, AX2, AY2);
  W := C.TextWidth(S);
  H := C.TextHeight(S);
  C.TextOut(R.Left + (R.Right - R.Left - W) div 2,
    R.Top + (R.Bottom - R.Top - H) div 2, S);
  C.Brush.Style := bsSolid;
end;

{ ------------------------------------------------------------ gear shape }

procedure DrawGear(ACanvas: TCanvas; const CX, CY, ROuter, RInner,
  Teeth: Integer; const AColor, AHoleColor: TColor);
var
  Pts: array of TPoint;
  I, N: Integer;
  A, Step, Rad: Double;
  Hole: Integer;
begin
  N := Teeth * 4;
  SetLength(Pts, N);
  Step := 2 * Pi / N;
  for I := 0 to N - 1 do
  begin
    A := I * Step - Pi / 2;
    if (I mod 4) in [0, 1] then
      Rad := ROuter
    else
      Rad := RInner;
    Pts[I] := Point(CX + Round(Rad * Cos(A)), CY + Round(Rad * Sin(A)));
  end;
  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Color := AColor;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := AColor;
  ACanvas.Polygon(Pts);
  Hole := Max(1, Round(RInner * 0.45));
  ACanvas.Brush.Color := AHoleColor;
  ACanvas.Pen.Color := AHoleColor;
  ACanvas.Ellipse(CX - Hole, CY - Hole, CX + Hole + 1, CY + Hole + 1);
end;

{ ------------------------------------------------------------ icons }

procedure DrawMenuIcon(ACanvas: TCanvas; const R: TRect);
var
  B: TIconBox;
  I, Y: Integer;
begin
  B.Init(ACanvas, R);
  B.Clear;
  ACanvas.Pen.Color := RGB(16, 82, 168);
  ACanvas.Brush.Color := RGB(36, 120, 214);
  for I := 0 to 2 do
  begin
    Y := 3 + I * 8;
    B.RRect(3, Y, 25, Y + 7, 4, 4);
  end;
end;

procedure DrawNextIcon(ACanvas: TCanvas; const R: TRect; const AEnabled: Boolean);
var
  B: TIconBox;
  FrameColor, FillColor, Arrow, ArrowEdge: TColor;
begin
  B.Init(ACanvas, R);
  B.Clear;
  if AEnabled then
  begin
    FrameColor := RGB(70, 70, 70);
    FillColor := clWhite;
    Arrow := RGB(38, 170, 64);
    ArrowEdge := RGB(22, 118, 42);
  end
  else
  begin
    FrameColor := RGB(150, 150, 150);
    FillColor := RGB(235, 235, 235);
    Arrow := RGB(170, 200, 175);
    ArrowEdge := RGB(140, 165, 145);
  end;
  ACanvas.Pen.Color := FrameColor;
  ACanvas.Brush.Color := FillColor;
  B.Frame(3, 3, 21, 21);
  { dark band across the top of the button }
  ACanvas.Brush.Color := FrameColor;
  B.Fill(3, 3, 21, 7);
  ACanvas.Pen.Color := ArrowEdge;
  ACanvas.Brush.Color := Arrow;
  B.Poly([12, 10, 12, 26, 25, 18]);
end;

procedure DrawDownloadIcon(ACanvas: TCanvas; const R: TRect);
var
  B: TIconBox;
begin
  B.Init(ACanvas, R);
  B.Clear;
  ACanvas.Pen.Color := RGB(200, 60, 20);
  ACanvas.Brush.Color := RGB(242, 92, 34);
  B.Frame(11, 2, 18, 12);
  B.Poly([5, 12, 23, 12, 14, 21]);
  B.Frame(4, 23, 25, 27);
end;

procedure DrawPhoneRefreshIcon(ACanvas: TCanvas; const R: TRect);
var
  B: TIconBox;
begin
  B.Init(ACanvas, R);
  B.Clear;
  { phone body }
  ACanvas.Pen.Color := RGB(22, 96, 170);
  ACanvas.Brush.Color := clWhite;
  B.PenW(2);
  B.RRect(6, 2, 22, 27, 5, 5);
  B.PenW(1);
  ACanvas.Brush.Color := RGB(22, 96, 170);
  B.Fill(11, 23, 17, 25);
  { circular arrow }
  ACanvas.Pen.Color := RGB(0, 150, 200);
  ACanvas.Brush.Style := bsClear;
  B.PenW(2);
  B.Arc(9, 7, 20, 19, 20, 10, 13, 19);
  B.PenW(1);
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := RGB(0, 150, 200);
  ACanvas.Pen.Color := RGB(0, 150, 200);
  B.Poly([17, 6, 21, 12, 15, 11]);
end;

procedure DrawGearIcon(ACanvas: TCanvas; const R: TRect);
var
  B: TIconBox;
begin
  B.Init(ACanvas, R);
  B.Clear;
  DrawGear(ACanvas, B.PX(14), B.PY(14), B.SZ(12), B.SZ(9), 8,
    RGB(105, 105, 105), clBtnFace);
end;

procedure DrawFacebookIcon(ACanvas: TCanvas; const R: TRect);
var
  B: TIconBox;
begin
  B.Init(ACanvas, R);
  B.Clear;
  ACanvas.Pen.Color := RGB(59, 89, 152);
  ACanvas.Brush.Color := RGB(59, 89, 152);
  B.RRect(3, 3, 26, 26, 4, 4);
  B.TextCentered('f', 8, 6, 26, 28, 21, clWhite);
end;

procedure DrawHelpIcon(ACanvas: TCanvas; const R: TRect);
var
  B: TIconBox;
begin
  B.Init(ACanvas, R);
  B.Clear;
  { soft shadow + purple question mark }
  B.TextCentered('?', 2, 1, 30, 29, 26, RGB(200, 185, 215));
  B.TextCentered('?', 0, 0, 28, 28, 26, RGB(126, 76, 160));
end;

procedure DrawBackIcon(ACanvas: TCanvas; const R: TRect);
var
  B: TIconBox;
begin
  B.Init(ACanvas, R);
  B.Clear;
  ACanvas.Pen.Color := RGB(16, 82, 168);
  ACanvas.Brush.Color := RGB(36, 120, 214);
  B.Poly([3, 14, 13, 4, 13, 10, 25, 10, 25, 18, 13, 18, 13, 24]);
end;

procedure DrawDeviceStateIcon(ACanvas: TCanvas; const R: TRect;
  const AConnected: Boolean);
var
  B: TIconBox;
  Mark: TColor;
begin
  { This icon is designed for the 24x32 device state panel. }
  B.Init(ACanvas, R, 24, 32);
  B.Clear;
  ACanvas.Pen.Color := RGB(60, 60, 60);
  ACanvas.Brush.Color := clWhite;
  B.RRect(6, 1, 20, 29, 4, 4);
  ACanvas.Brush.Color := RGB(60, 60, 60);
  B.Fill(6, 23, 20, 29);
  if AConnected then
    Mark := RGB(30, 160, 60)
  else
    Mark := RGB(225, 30, 30);
  { USB plug mark }
  ACanvas.Pen.Color := Mark;
  ACanvas.Brush.Style := bsClear;
  B.Frame(1, 9, 9, 16);
  B.Line(9, 12, 15, 12);
  B.Ellipse(12, 14, 19, 21);
  ACanvas.Brush.Style := bsSolid;
end;

{ ------------------------------------------------------------ button glyphs }

procedure DrawGlyphPhone(ACanvas: TCanvas);
begin
  ACanvas.Pen.Color := RGB(60, 60, 60);
  ACanvas.Brush.Color := clWhite;
  ACanvas.RoundRect(9, 0, 22, 24, 4, 4);
  ACanvas.Brush.Color := RGB(60, 60, 60);
  ACanvas.FillRect(Rect(9, 19, 22, 24));
  ACanvas.FillRect(Rect(9, 0, 22, 3));
end;

procedure DrawGlyphArrow(ACanvas: TCanvas; const AFill, AEdge: TColor);
begin
  ACanvas.Pen.Color := AEdge;
  ACanvas.Brush.Color := AFill;
  ACanvas.Polygon([Point(0, 9), Point(7, 9), Point(7, 4), Point(15, 12),
    Point(7, 20), Point(7, 15), Point(0, 15)]);
end;

function CreateActionGlyph(const AKind: TActionGlyph): TBitmap;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.SetSize(24, 24);
  Result.Canvas.Brush.Color := clFuchsia;
  Result.Canvas.FillRect(Rect(0, 0, 24, 24));
  DrawGlyphPhone(Result.Canvas);
  case AKind of
    agWriteFirmware:
      DrawGlyphArrow(Result.Canvas, RGB(0, 160, 110), RGB(0, 110, 76));
    agRestore:
      DrawGear(Result.Canvas, 10, 12, 8, 6, 7, RGB(140, 150, 160), clWhite);
    agWriteBin:
      DrawGlyphArrow(Result.Canvas, RGB(120, 120, 120), RGB(80, 80, 80));
    agWriteOfp:
      DrawGlyphArrow(Result.Canvas, RGB(122, 96, 204), RGB(84, 62, 150));
  end;
  { keep bottom-left pixel transparent for TBitBtn }
  Result.Canvas.Pixels[0, 23] := clFuchsia;
  Result.TransparentColor := clFuchsia;
  Result.Transparent := True;
end;

end.
