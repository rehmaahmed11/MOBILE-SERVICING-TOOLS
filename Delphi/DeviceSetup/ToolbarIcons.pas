unit ToolbarIcons;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


{ Vector-drawn icons shared by MAIN 1 and MAIN 2, so the project needs no
  binary image resources. All toolbar icons are drawn into a 28x28 area. }

interface

uses
{$IFDEF FPC}
  Windows, Types, Graphics;
{$ELSE}
  Winapi.Windows,
  System.Types,
  Vcl.Graphics;
{$ENDIF}

type
  TActionGlyph = (agWriteFirmware, agRestore, agWriteBin, agWriteOfp,
    agReadInfo, agReadPartitions, agReadBin, agReadRegion, agReadOtp);

  { Every Draw*Icon routine draws into a 28x28 area. }
  TIconProc = procedure(ACanvas: TCanvas; const R: TRect);

{ Draws an icon into ADest. If ADest is not 28x28 (e.g. the form was scaled
  for a high-DPI screen) the icon is drawn at 28x28 and smoothly stretched. }
procedure PaintIcon(ACanvas: TCanvas; const ADest: TRect; AProc: TIconProc);
procedure DrawNextIconEnabled(ACanvas: TCanvas; const R: TRect);
procedure DrawNextIconDisabled(ACanvas: TCanvas; const R: TRect);
procedure DrawDeviceConnectedIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawDeviceDisconnectedIcon(ACanvas: TCanvas; const R: TRect);

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

procedure DrawCenteredText(ACanvas: TCanvas; const R: TRect; const S: string);
var
  W, H: Integer;
begin
  W := ACanvas.TextWidth(S);
  H := ACanvas.TextHeight(S);
  ACanvas.Brush.Style := bsClear;
  ACanvas.TextOut(R.Left + (R.Right - R.Left - W) div 2,
    R.Top + (R.Bottom - R.Top - H) div 2, S);
end;

procedure ClearIcon(ACanvas: TCanvas; const R: TRect);
begin
  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Style := psSolid;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := clBtnFace;
  ACanvas.FillRect(R);
end;

procedure DrawMenuIcon(ACanvas: TCanvas; const R: TRect);
var
  I, Y: Integer;
begin
  ClearIcon(ACanvas, R);
  ACanvas.Pen.Color := RGB(16, 82, 168);
  ACanvas.Brush.Color := RGB(36, 120, 214);
  for I := 0 to 2 do
  begin
    Y := R.Top + 3 + I * 8;
    ACanvas.RoundRect(R.Left + 3, Y, R.Right - 3, Y + 7, 4, 4);
  end;
end;

procedure DrawNextIcon(ACanvas: TCanvas; const R: TRect; const AEnabled: Boolean);
var
  L, T: Integer;
  Frame, Fill, Arrow, ArrowEdge: TColor;
begin
  ClearIcon(ACanvas, R);
  L := R.Left;
  T := R.Top;
  if AEnabled then
  begin
    Frame := RGB(70, 70, 70);
    Fill := clWhite;
    Arrow := RGB(38, 170, 64);
    ArrowEdge := RGB(22, 118, 42);
  end
  else
  begin
    Frame := RGB(150, 150, 150);
    Fill := RGB(235, 235, 235);
    Arrow := RGB(170, 200, 175);
    ArrowEdge := RGB(140, 165, 145);
  end;
  ACanvas.Pen.Color := Frame;
  ACanvas.Brush.Color := Fill;
  ACanvas.Rectangle(L + 3, T + 3, L + 21, T + 21);
  ACanvas.Brush.Color := Frame;
  ACanvas.FillRect(Rect(L + 3, T + 3, L + 21, T + 7));
  ACanvas.Pen.Color := ArrowEdge;
  ACanvas.Brush.Color := Arrow;
  ACanvas.Polygon([Point(L + 12, T + 10), Point(L + 12, T + 26),
    Point(L + 25, T + 18)]);
end;

procedure DrawDownloadIcon(ACanvas: TCanvas; const R: TRect);
var
  L, T: Integer;
begin
  ClearIcon(ACanvas, R);
  L := R.Left;
  T := R.Top;
  ACanvas.Pen.Color := RGB(200, 60, 20);
  ACanvas.Brush.Color := RGB(242, 92, 34);
  ACanvas.Rectangle(L + 11, T + 2, L + 18, T + 12);
  ACanvas.Polygon([Point(L + 5, T + 12), Point(L + 23, T + 12),
    Point(L + 14, T + 21)]);
  ACanvas.Rectangle(L + 4, T + 23, L + 25, T + 27);
end;

procedure DrawPhoneRefreshIcon(ACanvas: TCanvas; const R: TRect);
var
  L, T: Integer;
begin
  ClearIcon(ACanvas, R);
  L := R.Left;
  T := R.Top;
  { phone body }
  ACanvas.Pen.Color := RGB(22, 96, 170);
  ACanvas.Pen.Width := 2;
  ACanvas.Brush.Color := clWhite;
  ACanvas.RoundRect(L + 6, T + 2, L + 22, T + 27, 5, 5);
  ACanvas.Pen.Width := 1;
  ACanvas.Brush.Color := RGB(22, 96, 170);
  ACanvas.FillRect(Rect(L + 11, T + 23, L + 17, T + 25));
  { circular arrow }
  ACanvas.Pen.Color := RGB(0, 150, 200);
  ACanvas.Pen.Width := 2;
  ACanvas.Brush.Style := bsClear;
  ACanvas.Arc(L + 9, T + 7, L + 20, T + 19, L + 20, T + 10, L + 13, T + 19);
  ACanvas.Pen.Width := 1;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := RGB(0, 150, 200);
  ACanvas.Pen.Color := RGB(0, 150, 200);
  ACanvas.Polygon([Point(L + 17, T + 6), Point(L + 21, T + 12),
    Point(L + 15, T + 11)]);
end;

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

procedure DrawGearIcon(ACanvas: TCanvas; const R: TRect);
begin
  ClearIcon(ACanvas, R);
  DrawGear(ACanvas, R.Left + 14, R.Top + 14, 12, 9, 8, RGB(105, 105, 105),
    clBtnFace);
end;

procedure DrawFacebookIcon(ACanvas: TCanvas; const R: TRect);
var
  TextR: TRect;
  S: string;
begin
  ClearIcon(ACanvas, R);
  ACanvas.Pen.Color := RGB(59, 89, 152);
  ACanvas.Brush.Color := RGB(59, 89, 152);
  ACanvas.RoundRect(R.Left + 3, R.Top + 3, R.Left + 26, R.Top + 26, 4, 4);
  ACanvas.Font.Name := 'Arial';
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Height := -21;
  ACanvas.Font.Color := clWhite;
  ACanvas.Brush.Style := bsClear;
  TextR := Rect(R.Left + 8, R.Top + 6, R.Left + 26, R.Top + 28);
  S := 'f';
  DrawCenteredText(ACanvas, TextR, S);
  ACanvas.Brush.Style := bsSolid;
end;

procedure DrawHelpIcon(ACanvas: TCanvas; const R: TRect);
var
  TextR: TRect;
  S: string;
begin
  ClearIcon(ACanvas, R);
  ACanvas.Font.Name := 'Arial';
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Height := -26;
  ACanvas.Brush.Style := bsClear;
  S := '?';
  { soft shadow + purple question mark }
  ACanvas.Font.Color := RGB(200, 185, 215);
  TextR := Rect(R.Left + 2, R.Top + 1, R.Right + 2, R.Bottom + 1);
  DrawCenteredText(ACanvas, TextR, S);
  ACanvas.Font.Color := RGB(126, 76, 160);
  TextR := R;
  DrawCenteredText(ACanvas, TextR, S);
  ACanvas.Brush.Style := bsSolid;
end;

procedure DrawBackIcon(ACanvas: TCanvas; const R: TRect);
var
  L, T: Integer;
begin
  ClearIcon(ACanvas, R);
  L := R.Left;
  T := R.Top;
  ACanvas.Pen.Color := RGB(16, 82, 168);
  ACanvas.Brush.Color := RGB(36, 120, 214);
  ACanvas.Polygon([Point(L + 3, T + 14), Point(L + 13, T + 4), Point(L + 13, T + 10),
    Point(L + 25, T + 10), Point(L + 25, T + 18), Point(L + 13, T + 18),
    Point(L + 13, T + 24)]);
end;

procedure DrawDeviceStateIcon(ACanvas: TCanvas; const R: TRect;
  const AConnected: Boolean);
var
  L, T: Integer;
  Mark: TColor;
begin
  ClearIcon(ACanvas, R);
  L := R.Left;
  T := R.Top;
  ACanvas.Pen.Color := RGB(60, 60, 60);
  ACanvas.Brush.Color := clWhite;
  ACanvas.RoundRect(L + 6, T + 1, L + 20, T + 29, 4, 4);
  ACanvas.Brush.Color := RGB(60, 60, 60);
  ACanvas.FillRect(Rect(L + 6, T + 23, L + 20, T + 29));
  if AConnected then
    Mark := RGB(30, 160, 60)
  else
    Mark := RGB(225, 30, 30);
  { USB plug mark }
  ACanvas.Pen.Color := Mark;
  ACanvas.Brush.Style := bsClear;
  ACanvas.Rectangle(L + 1, T + 9, L + 9, T + 16);
  ACanvas.MoveTo(L + 9, T + 12);
  ACanvas.LineTo(L + 15, T + 12);
  ACanvas.Ellipse(L + 12, T + 14, L + 19, T + 21);
  ACanvas.Brush.Style := bsSolid;
end;

procedure DrawNextIconEnabled(ACanvas: TCanvas; const R: TRect);
begin
  DrawNextIcon(ACanvas, R, True);
end;

procedure DrawNextIconDisabled(ACanvas: TCanvas; const R: TRect);
begin
  DrawNextIcon(ACanvas, R, False);
end;

procedure DrawDeviceConnectedIcon(ACanvas: TCanvas; const R: TRect);
begin
  DrawDeviceStateIcon(ACanvas, R, True);
end;

procedure DrawDeviceDisconnectedIcon(ACanvas: TCanvas; const R: TRect);
begin
  DrawDeviceStateIcon(ACanvas, R, False);
end;

procedure PaintIcon(ACanvas: TCanvas; const ADest: TRect; AProc: TIconProc);
const
  CSize = 28;
var
  Bmp: TBitmap;
  W, H, Side, X, Y: Integer;
begin
  W := ADest.Right - ADest.Left;
  H := ADest.Bottom - ADest.Top;
  if (W = CSize) and (H = CSize) then
  begin
    AProc(ACanvas, ADest);
    Exit;
  end;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := clBtnFace;
  ACanvas.FillRect(ADest);
  Side := Min(W, H);
  if Side <= 0 then
    Exit;
  Bmp := TBitmap.Create;
  try
    Bmp.PixelFormat := pf24bit;
    Bmp.SetSize(CSize, CSize);
    AProc(Bmp.Canvas, Rect(0, 0, CSize, CSize));
    X := ADest.Left + (W - Side) div 2;
    Y := ADest.Top + (H - Side) div 2;
    SetStretchBltMode(ACanvas.Handle, HALFTONE);
    SetBrushOrgEx(ACanvas.Handle, 0, 0, nil);
    StretchBlt(ACanvas.Handle, X, Y, Side, Side, Bmp.Canvas.Handle,
      0, 0, CSize, CSize, SRCCOPY);
  finally
    Bmp.Free;
  end;
end;

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

{ phone on the left, for the "read" glyphs (data comes out of the phone) }
procedure DrawGlyphPhoneLeft(ACanvas: TCanvas);
begin
  ACanvas.Pen.Color := RGB(60, 60, 60);
  ACanvas.Brush.Color := clWhite;
  ACanvas.RoundRect(1, 0, 14, 24, 4, 4);
  ACanvas.Brush.Color := RGB(60, 60, 60);
  ACanvas.FillRect(Rect(1, 19, 14, 24));
  ACanvas.FillRect(Rect(1, 0, 14, 3));
end;

procedure DrawGlyphArrowOut(ACanvas: TCanvas; const AFill, AEdge: TColor);
begin
  ACanvas.Pen.Color := AEdge;
  ACanvas.Brush.Color := AFill;
  ACanvas.Polygon([Point(7, 9), Point(14, 9), Point(14, 4), Point(23, 12),
    Point(14, 20), Point(14, 15), Point(7, 15)]);
end;

procedure DrawGlyphMagnifier(ACanvas: TCanvas);
begin
  { handle }
  ACanvas.Pen.Color := RGB(200, 100, 20);
  ACanvas.Pen.Width := 4;
  ACanvas.MoveTo(14, 14);
  ACanvas.LineTo(21, 22);
  { lens }
  ACanvas.Pen.Width := 3;
  ACanvas.Pen.Color := RGB(245, 140, 30);
  ACanvas.Brush.Color := clWhite;
  ACanvas.Ellipse(2, 1, 18, 17);
  ACanvas.Pen.Width := 1;
  { tiny phone inside the lens }
  ACanvas.Pen.Color := RGB(90, 90, 90);
  ACanvas.Brush.Color := RGB(210, 225, 240);
  ACanvas.Rectangle(7, 5, 13, 13);
end;

procedure DrawGlyphBarcode(ACanvas: TCanvas);
const
  Bars: array[0..12] of Integer = (1, 2, 1, 1, 3, 1, 2, 1, 1, 2, 1, 3, 1);
var
  I, X: Integer;
begin
  ACanvas.Pen.Color := RGB(120, 120, 120);
  ACanvas.Brush.Color := clWhite;
  ACanvas.Rectangle(0, 2, 24, 22);
  { not pure black: the LCL can treat clBlack glyph pixels as transparent }
  ACanvas.Brush.Color := RGB(25, 25, 25);
  X := 2;
  for I := Low(Bars) to High(Bars) do
  begin
    if not Odd(I) then
      ACanvas.FillRect(Rect(X, 4, X + Bars[I], 17));
    Inc(X, Bars[I]);
    if X > 21 then
      Break;
  end;
  { digits under the bars }
  for I := 0 to 4 do
    ACanvas.FillRect(Rect(3 + I * 4, 18, 5 + I * 4, 20));
end;

function CreateActionGlyph(const AKind: TActionGlyph): TBitmap;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.SetSize(24, 24);
  Result.Canvas.Brush.Color := clFuchsia;
  Result.Canvas.FillRect(Rect(0, 0, 24, 24));
  case AKind of
    agWriteFirmware, agRestore, agWriteBin, agWriteOfp:
      DrawGlyphPhone(Result.Canvas);
    agReadPartitions, agReadBin, agReadRegion:
      DrawGlyphPhoneLeft(Result.Canvas);
  end;
  case AKind of
    agWriteFirmware:
      DrawGlyphArrow(Result.Canvas, RGB(0, 160, 110), RGB(0, 110, 76));
    agRestore:
      DrawGear(Result.Canvas, 10, 12, 8, 6, 7, RGB(140, 150, 160), clWhite);
    agWriteBin:
      DrawGlyphArrow(Result.Canvas, RGB(120, 120, 120), RGB(80, 80, 80));
    agWriteOfp:
      DrawGlyphArrow(Result.Canvas, RGB(122, 96, 204), RGB(84, 62, 150));
    agReadInfo:
      DrawGlyphMagnifier(Result.Canvas);
    agReadPartitions:
      DrawGlyphArrowOut(Result.Canvas, RGB(40, 180, 70), RGB(20, 120, 40));
    agReadBin:
      DrawGlyphArrowOut(Result.Canvas, RGB(30, 130, 230), RGB(15, 80, 160));
    agReadRegion:
      DrawGlyphArrowOut(Result.Canvas, RGB(250, 200, 20), RGB(190, 140, 0));
    agReadOtp:
      DrawGlyphBarcode(Result.Canvas);
  end;
  { keep bottom-left pixel transparent for TBitBtn }
  Result.Canvas.Pixels[0, 23] := clFuchsia;
  Result.TransparentColor := clFuchsia;
  Result.Transparent := True;
end;

end.
