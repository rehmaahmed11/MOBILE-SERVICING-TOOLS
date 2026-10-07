unit ToolbarIcons;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


{ Vector-drawn icons shared by MAIN 1 and MAIN 2, so the project needs no
  binary image resources. All toolbar icons are drawn into a 28x28 area,
  button glyphs into a 24x24 area, matching the look of the UI samples
  (UI SAMPLE/S1.png ... S10.png). }

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
  { Small picture drawn on the left of a job button. }
  TActionGlyph = (agWriteFirmware, agRestore, agWriteBin, agWriteOfp,
    agReadInfo, agReadPartitions, agReadBin, agReadRegion, agReadOtp,
    agFormat, agWipeData, agWipePartitions, agEraseFrp, agEraseFrpWipe,
    agRepair, agReadImei,
    agUnlockBootloader, agRelockBootloader, agUnlockNetwork, agReadCodes,
    agResetPassword, agResetAccount,
    agRebootRecovery, agDisableOta, agResetDmVerity, agDisableOrangeState,
    agSwitchSlot, agFixDlImage,
    agRpmbBackup, agRpmbWrite, agRpmbFormat,
    agSaveLog, agChangeDevice, agSettings, agFacebook, agHelp, agSelect);

  { Every Draw*Icon routine draws into a 28x28 area. }
  TIconProc = procedure(ACanvas: TCanvas; const R: TRect);

{ Draws an icon into ADest. If ADest is not 28x28 (e.g. the form was scaled
  for a high-DPI screen) the icon is drawn at 28x28 and smoothly stretched. }
procedure PaintIcon(ACanvas: TCanvas; const ADest: TRect; AProc: TIconProc);
procedure DrawNextIconEnabled(ACanvas: TCanvas; const R: TRect);
procedure DrawNextIconDisabled(ACanvas: TCanvas; const R: TRect);
procedure DrawDeviceConnectedIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawDeviceDisconnectedIcon(ACanvas: TCanvas; const R: TRect);

{ toolbar icons, left to right as in the samples }
procedure DrawMenuIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawNextIcon(ACanvas: TCanvas; const R: TRect; const AEnabled: Boolean);
procedure DrawStartIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawDownloadIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawDeviceDocIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawGearIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawPlaneIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawFacebookIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawHelpIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawBackIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawDeviceStateIcon(ACanvas: TCanvas; const R: TRect;
  const AConnected: Boolean);
procedure DrawPhoneRefreshIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawGear(ACanvas: TCanvas; const CX, CY, ROuter, RInner,
  Teeth: Integer; const AColor, AHoleColor: TColor);
procedure DrawSelectIcon(ACanvas: TCanvas; const R: TRect);

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

const
  { Palette taken from the UI samples. TColor literals are $00BBGGRR. }
  CGreen         = $004FBB21;  { RGB( 33, 187,  79) }
  CGreenDark     = $003A8A12;  { RGB( 18, 138,  58) }
  COrange        = $001281FD;  { RGB(253, 129,  18) }
  COrangeDark    = $00065CC8;  { RGB(200,  92,   6) }
  CDocGreen      = $004AA018;  { RGB( 24, 160,  74) }
  CDocGreenDark  = $00367610;  { RGB( 16, 118,  54) }
  CGearBlue      = $00D9B457;  { RGB( 87, 180, 217) }
  CGearBlueDark  = $00B48A34;  { RGB( 52, 138, 180) }
  CPlaneBlue     = $00E19500;  { RGB(  0, 149, 225) }
  CPlaneBlueDark = $00AF6C00;  { RGB(  0, 108, 175) }
  CFbBlue        = $00E57C40;  { RGB( 64, 124, 229) }
  CHelpPurple    = $00CD7A96;  { RGB(150, 122, 205) }
  CShadow        = $00CDCDCD;  { RGB(205, 205, 205) }
  CGrayIcon      = $00787878;  { RGB(120, 120, 120) }
  CCardWhite     = $00FCFCFC;  { RGB(252, 252, 252) }
  CCardEdge      = $00D6D6D6;  { RGB(214, 214, 214) }

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

{ Every toolbar icon sits on a white card with a light edge and a soft
  shadow below the bottom-right corner, as in the samples. }
procedure DrawCard(ACanvas: TCanvas; const R: TRect);
begin
  ClearIcon(ACanvas, R);
  ACanvas.Pen.Color := CShadow;
  ACanvas.Brush.Color := CShadow;
  ACanvas.RoundRect(R.Left + 2, R.Top + 2, R.Right - 1, R.Bottom - 1, 6, 6);
  ACanvas.Pen.Color := CCardEdge;
  ACanvas.Brush.Color := CCardWhite;
  ACanvas.RoundRect(R.Left + 1, R.Top + 1, R.Right - 3, R.Bottom - 3, 6, 6);
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
    Y := R.Top + 4 + I * 8;
    ACanvas.RoundRect(R.Left + 2, Y, R.Right - 5, Y + 6, 3, 3);
  end;
end;

procedure DrawStartIcon(ACanvas: TCanvas; const R: TRect);
var
  L, T: Integer;
begin
  DrawCard(ACanvas, R);
  L := R.Left;
  T := R.Top;
  { grey window }
  ACanvas.Pen.Color := RGB(120, 120, 120);
  ACanvas.Brush.Color := RGB(170, 170, 170);
  ACanvas.Rectangle(L + 6, T + 5, L + 22, T + 23);
  ACanvas.Brush.Color := RGB(120, 120, 120);
  ACanvas.FillRect(Rect(L + 6, T + 5, L + 22, T + 9));
  { green play triangle, overlapping the window }
  ACanvas.Pen.Color := CGreenDark;
  ACanvas.Brush.Color := CGreen;
  ACanvas.Polygon([Point(L + 12, T + 10), Point(L + 12, T + 24),
    Point(L + 25, T + 17)]);
end;

procedure DrawNextIcon(ACanvas: TCanvas; const R: TRect; const AEnabled: Boolean);
begin
  if AEnabled then
    DrawStartIcon(ACanvas, R)
  else
  begin
    DrawCard(ACanvas, R);
    ACanvas.Pen.Color := RGB(160, 160, 160);
    ACanvas.Brush.Color := RGB(205, 205, 205);
    ACanvas.Rectangle(R.Left + 6, R.Top + 5, R.Left + 22, R.Top + 23);
    ACanvas.Pen.Color := RGB(170, 200, 178);
    ACanvas.Brush.Color := RGB(196, 222, 202);
    ACanvas.Polygon([Point(R.Left + 12, R.Top + 10),
      Point(R.Left + 12, R.Top + 24), Point(R.Left + 25, R.Top + 17)]);
  end;
end;

procedure DrawDownloadIcon(ACanvas: TCanvas; const R: TRect);
var
  L, T: Integer;
begin
  DrawCard(ACanvas, R);
  L := R.Left;
  T := R.Top;
  { orange cube with a down arrow }
  ACanvas.Pen.Color := COrangeDark;
  ACanvas.Brush.Color := COrange;
  ACanvas.Rectangle(L + 8, T + 11, L + 22, T + 22);
  ACanvas.Brush.Color := RGB(253, 180, 60);
  ACanvas.FillRect(Rect(L + 8, T + 11, L + 22, T + 15));
  { arrow on top }
  ACanvas.Pen.Color := COrangeDark;
  ACanvas.Brush.Color := COrange;
  ACanvas.FillRect(Rect(L + 13, T + 3, L + 18, T + 9));
  ACanvas.Polygon([Point(L + 9, T + 8), Point(L + 22, T + 8),
    Point(L + 15, T + 15)]);
  { base line }
  ACanvas.Brush.Color := COrangeDark;
  ACanvas.FillRect(Rect(L + 5, T + 23, L + 25, T + 25));
end;

procedure DrawDeviceDocIcon(ACanvas: TCanvas; const R: TRect);
var
  L, T: Integer;
begin
  DrawCard(ACanvas, R);
  L := R.Left;
  T := R.Top;
  { green document }
  ACanvas.Pen.Color := CDocGreenDark;
  ACanvas.Brush.Color := CDocGreen;
  ACanvas.Rectangle(L + 6, T + 4, L + 21, T + 24);
  ACanvas.Brush.Color := RGB(180, 235, 195);
  ACanvas.FillRect(Rect(L + 9, T + 8, L + 18, T + 10));
  ACanvas.FillRect(Rect(L + 9, T + 12, L + 18, T + 14));
  { blue refresh arrow over the document }
  ACanvas.Pen.Color := CPlaneBlue;
  ACanvas.Pen.Width := 2;
  ACanvas.Brush.Style := bsClear;
  ACanvas.Arc(L + 12, T + 12, L + 25, T + 24, L + 25, T + 14, L + 15, T + 23);
  ACanvas.Pen.Width := 1;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := CPlaneBlue;
  ACanvas.Pen.Color := CPlaneBlue;
  ACanvas.Polygon([Point(L + 22, T + 11), Point(L + 26, T + 17),
    Point(L + 20, T + 17)]);
end;

procedure DrawPhoneRefreshIcon(ACanvas: TCanvas; const R: TRect);
begin
  DrawDeviceDocIcon(ACanvas, R);
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
  DrawCard(ACanvas, R);
  DrawGear(ACanvas, R.Left + 15, R.Top + 16, 10, 8, 7, CGearBlue, CCardWhite);
  DrawGear(ACanvas, R.Left + 15, R.Top + 16, 7, 6, 7, CGearBlueDark, CCardWhite);
  DrawGear(ACanvas, R.Left + 15, R.Top + 16, 4, 3, 7, CGearBlue, CCardWhite);
end;

procedure DrawPlaneIcon(ACanvas: TCanvas; const R: TRect);
var
  L, T: Integer;
begin
  DrawCard(ACanvas, R);
  L := R.Left;
  T := R.Top;
  ACanvas.Pen.Color := CPlaneBlueDark;
  ACanvas.Brush.Color := CPlaneBlue;
  ACanvas.Polygon([Point(L + 3, T + 13), Point(L + 26, T + 4),
    Point(L + 17, T + 25), Point(L + 12, T + 16)]);
  ACanvas.Pen.Color := RGB(240, 250, 255);
  ACanvas.MoveTo(L + 12, T + 16);
  ACanvas.LineTo(L + 26, T + 4);
end;

procedure DrawFacebookIcon(ACanvas: TCanvas; const R: TRect);
var
  TextR: TRect;
  S: string;
begin
  DrawCard(ACanvas, R);
  ACanvas.Font.Name := 'Arial';
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Height := -22;
  ACanvas.Font.Color := CFbBlue;
  ACanvas.Brush.Style := bsClear;
  S := 'f';
  TextR := Rect(R.Left + 2, R.Top + 3, R.Right - 2, R.Bottom - 1);
  DrawCenteredText(ACanvas, TextR, S);
  ACanvas.Brush.Style := bsSolid;
end;

procedure DrawHelpIcon(ACanvas: TCanvas; const R: TRect);
var
  TextR: TRect;
  S: string;
begin
  DrawCard(ACanvas, R);
  ACanvas.Font.Name := 'Arial';
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Height := -22;
  ACanvas.Brush.Style := bsClear;
  S := '?';
  ACanvas.Font.Color := RGB(206, 196, 226);
  TextR := Rect(R.Left + 2, R.Top + 2, R.Right - 1, R.Bottom - 2);
  DrawCenteredText(ACanvas, TextR, S);
  ACanvas.Font.Color := CHelpPurple;
  TextR := R;
  DrawCenteredText(ACanvas, TextR, S);
  ACanvas.Brush.Style := bsSolid;
end;

procedure DrawSelectIcon(ACanvas: TCanvas; const R: TRect);
begin
  { green tick, used on the MAIN 1 "Select" button }
  ClearIcon(ACanvas, R);
  ACanvas.Pen.Color := CGreenDark;
  ACanvas.Brush.Color := CGreen;
  ACanvas.Pen.Width := 4;
  ACanvas.MoveTo(R.Left + 6, R.Top + 15);
  ACanvas.LineTo(R.Left + 12, R.Top + 21);
  ACanvas.LineTo(R.Left + 23, R.Top + 7);
  ACanvas.Pen.Width := 1;
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
    Mark := CGreen
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

{ ------------------------------------------------------- button glyphs }

procedure DrawGlyphPhone(ACanvas: TCanvas);
begin
  ACanvas.Pen.Color := RGB(60, 60, 60);
  ACanvas.Brush.Color := clWhite;
  ACanvas.RoundRect(9, 0, 22, 24, 4, 4);
  ACanvas.Brush.Color := RGB(60, 60, 60);
  ACanvas.FillRect(Rect(9, 19, 22, 24));
  ACanvas.FillRect(Rect(9, 0, 22, 3));
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

procedure DrawGlyphArrow(ACanvas: TCanvas; const AFill, AEdge: TColor);
begin
  ACanvas.Pen.Color := AEdge;
  ACanvas.Brush.Color := AFill;
  ACanvas.Polygon([Point(0, 9), Point(7, 9), Point(7, 4), Point(15, 12),
    Point(7, 20), Point(7, 15), Point(0, 15)]);
end;

procedure DrawGlyphArrowOut(ACanvas: TCanvas; const AFill, AEdge: TColor);
begin
  ACanvas.Pen.Color := AEdge;
  ACanvas.Brush.Color := AFill;
  ACanvas.Polygon([Point(7, 9), Point(14, 9), Point(14, 4), Point(23, 12),
    Point(14, 20), Point(14, 15), Point(7, 15)]);
end;

{ a folder with an arrow, used by the file / partition jobs }
procedure DrawGlyphFolder(ACanvas: TCanvas; const AFill, AEdge: TColor);
begin
  ACanvas.Pen.Color := RGB(130, 130, 130);
  ACanvas.Brush.Color := RGB(238, 202, 110);
  ACanvas.Rectangle(0, 4, 11, 22);
  ACanvas.Polygon([Point(0, 4), Point(5, 0), Point(9, 0), Point(12, 4)]);
  ACanvas.Pen.Color := AEdge;
  ACanvas.Brush.Color := AFill;
  ACanvas.Polygon([Point(10, 8), Point(17, 8), Point(17, 3), Point(24, 12),
    Point(17, 21), Point(17, 16), Point(10, 16)]);
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

{ Android-style robot head, used by the wipe / reboot / fix jobs }
procedure DrawGlyphRobot(ACanvas: TCanvas; const AColor: TColor);
begin
  ACanvas.Pen.Color := AColor;
  ACanvas.Brush.Color := AColor;
  ACanvas.RoundRect(4, 7, 20, 19, 4, 4);
  ACanvas.Brush.Color := clWhite;
  ACanvas.FillRect(Rect(8, 11, 10, 14));
  ACanvas.FillRect(Rect(14, 11, 16, 14));
  ACanvas.Brush.Color := AColor;
  ACanvas.Pen.Width := 2;
  ACanvas.MoveTo(8, 3);
  ACanvas.LineTo(10, 6);
  ACanvas.MoveTo(16, 3);
  ACanvas.LineTo(14, 6);
  ACanvas.MoveTo(2, 12);
  ACanvas.LineTo(2, 17);
  ACanvas.MoveTo(22, 12);
  ACanvas.LineTo(22, 17);
  ACanvas.Pen.Width := 1;
end;

{ a red / coloured cross badge, used by the destructive jobs }
procedure DrawGlyphCross(ACanvas: TCanvas; const AColor: TColor);
begin
  ACanvas.Pen.Color := AColor;
  ACanvas.Brush.Color := AColor;
  ACanvas.Polygon([Point(12, 0), Point(15, 8), Point(23, 4), Point(19, 12),
    Point(24, 17), Point(15, 16), Point(12, 24), Point(9, 16), Point(0, 19),
    Point(5, 12), Point(0, 4), Point(9, 8)]);
  ACanvas.Brush.Color := clWhite;
  ACanvas.Ellipse(8, 8, 16, 16);
end;

{ a small label with text, e.g. "FRP" or "IMEI" }
procedure DrawGlyphLabel(ACanvas: TCanvas; const AText: string;
  const ABg, AFg: TColor);
var
  R: TRect;
begin
  ACanvas.Pen.Color := ABg;
  ACanvas.Brush.Color := ABg;
  ACanvas.Rectangle(0, 3, 24, 21);
  ACanvas.Font.Name := 'Arial';
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Height := -9;
  ACanvas.Font.Color := AFg;
  R := Rect(0, 3, 25, 21);
  DrawCenteredText(ACanvas, R, AText);
  ACanvas.Font.Style := [];
end;

{ green robot with a brush: wipe data / partitions }
procedure DrawGlyphWipe(ACanvas: TCanvas; const AWithSlash: Boolean);
begin
  DrawGlyphRobot(ACanvas, CDocGreen);
  ACanvas.Pen.Color := RGB(240, 240, 240);
  ACanvas.Brush.Color := RGB(250, 250, 250);
  ACanvas.Polygon([Point(2, 20), Point(9, 13), Point(13, 17), Point(6, 24)]);
  ACanvas.Pen.Color := RGB(190, 190, 190);
  ACanvas.Brush.Color := RGB(120, 120, 120);
  ACanvas.FillRect(Rect(9, 16, 14, 18));
  if AWithSlash then
  begin
    ACanvas.Pen.Color := CDocGreenDark;
    ACanvas.Pen.Width := 2;
    ACanvas.MoveTo(5, 23);
    ACanvas.LineTo(21, 7);
    ACanvas.Pen.Width := 1;
  end;
end;

{ coloured disc with white symbol lines }
procedure DrawGlyphDisc(ACanvas: TCanvas; const AFill, AEdge: TColor);
begin
  ACanvas.Pen.Color := AEdge;
  ACanvas.Brush.Color := AFill;
  ACanvas.Ellipse(1, 1, 23, 23);
end;

procedure DrawGlyphPadlock(ACanvas: TCanvas; const AFill, AEdge: TColor;
  const AOpen: Boolean);
begin
  ACanvas.Pen.Color := AEdge;
  ACanvas.Brush.Color := AFill;
  ACanvas.Rectangle(5, 11, 19, 23);
  ACanvas.Pen.Width := 3;
  ACanvas.Brush.Style := bsClear;
  if AOpen then
    ACanvas.Arc(9, 1, 23, 15, 21, 8, 13, 2)
  else
    ACanvas.Arc(7, 1, 17, 15, 17, 8, 7, 8);
  ACanvas.Pen.Width := 1;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Pen.Color := clWhite;
  ACanvas.Brush.Color := clWhite;
  ACanvas.Ellipse(11, 15, 14, 18);
  ACanvas.FillRect(Rect(12, 17, 13, 20));
end;

procedure DrawGlyphGlobe(ACanvas: TCanvas);
begin
  DrawGlyphDisc(ACanvas, CPlaneBlue, CPlaneBlueDark);
  ACanvas.Pen.Color := clWhite;
  ACanvas.Brush.Style := bsClear;
  ACanvas.Ellipse(8, 3, 16, 21);
  ACanvas.MoveTo(3, 12);
  ACanvas.LineTo(21, 12);
  ACanvas.Arc(2, 4, 22, 20, 21, 12, 1, 12);
  ACanvas.Brush.Style := bsSolid;
end;

procedure DrawGlyphPerson(ACanvas: TCanvas; const AFill, AEdge: TColor);
begin
  ACanvas.Pen.Color := AEdge;
  ACanvas.Brush.Color := AFill;
  ACanvas.Ellipse(8, 2, 17, 11);
  ACanvas.Polygon([Point(3, 23), Point(5, 13), Point(20, 13), Point(22, 23)]);
end;

procedure DrawGlyphCircularArrow(ACanvas: TCanvas; const AColor: TColor;
  const ACW: Boolean);
begin
  ACanvas.Pen.Color := AColor;
  ACanvas.Pen.Width := 3;
  ACanvas.Brush.Style := bsClear;
  ACanvas.Arc(2, 2, 22, 22, 22, 12, 2, 12);
  ACanvas.Pen.Width := 1;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := AColor;
  ACanvas.Pen.Color := AColor;
  if ACW then
    ACanvas.Polygon([Point(19, 0), Point(24, 7), Point(16, 7)])
  else
    ACanvas.Polygon([Point(5, 0), Point(8, 7), Point(0, 7)]);
end;

procedure DrawGlyphWrench(ACanvas: TCanvas);
begin
  ACanvas.Pen.Color := CPlaneBlueDark;
  ACanvas.Brush.Color := CPlaneBlue;
  ACanvas.Polygon([Point(2, 2), Point(9, 2), Point(11, 6), Point(22, 17),
    Point(18, 22), Point(7, 11), Point(3, 9)]);
  ACanvas.Brush.Color := clWhite;
  ACanvas.Ellipse(1, 1, 8, 7);
  ACanvas.Pen.Color := RGB(150, 190, 225);
  ACanvas.MoveTo(3, 20);
  ACanvas.LineTo(21, 3);
end;

procedure DrawGlyphRecovery(ACanvas: TCanvas);
begin
  DrawGlyphRobot(ACanvas, CDocGreen);
  ACanvas.Pen.Color := CGearBlueDark;
  ACanvas.Brush.Color := CGearBlue;
  ACanvas.Ellipse(14, 14, 23, 23);
  ACanvas.Pen.Color := clWhite;
  ACanvas.Brush.Color := clWhite;
  ACanvas.FillRect(Rect(18, 16, 20, 21));
  ACanvas.FillRect(Rect(16, 18, 22, 20));
end;

procedure DrawGlyphOrangeState(ACanvas: TCanvas);
begin
  ACanvas.Pen.Color := RGB(230, 140, 20);
  ACanvas.Brush.Color := RGB(250, 170, 40);
  ACanvas.Polygon([Point(12, 1), Point(23, 21), Point(1, 21)]);
  ACanvas.Pen.Color := clWhite;
  ACanvas.Pen.Width := 2;
  ACanvas.MoveTo(12, 8);
  ACanvas.LineTo(12, 14);
  ACanvas.MoveTo(12, 17);
  ACanvas.LineTo(12, 18);
  ACanvas.Pen.Width := 1;
end;

procedure DrawGlyphSwitchSlot(ACanvas: TCanvas);
begin
  DrawGlyphCircularArrow(ACanvas, CDocGreen, True);
  DrawGlyphCircularArrow(ACanvas, CDocGreenDark, False);
end;

procedure DrawGlyphBox(ACanvas: TCanvas; const AFill, AEdge: TColor);
begin
  ACanvas.Pen.Color := AEdge;
  ACanvas.Brush.Color := AFill;
  ACanvas.Rectangle(4, 8, 20, 23);
  ACanvas.Brush.Color := clWhite;
  ACanvas.FillRect(Rect(4, 11, 20, 13));
  ACanvas.Pen.Color := RGB(150, 150, 150);
  ACanvas.MoveTo(4, 8);
  ACanvas.LineTo(10, 3);
  ACanvas.LineTo(23, 3);
  ACanvas.LineTo(20, 8);
end;

function CreateActionGlyph(const AKind: TActionGlyph): TBitmap;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.SetSize(24, 24);
  Result.Canvas.Brush.Color := clFuchsia;
  Result.Canvas.FillRect(Rect(0, 0, 24, 24));
  case AKind of
    agWriteFirmware, agRestore, agWriteBin, agWriteOfp, agReadOtp:
      begin
        DrawGlyphFolder(Result.Canvas, RGB(238, 202, 110), RGB(180, 140, 40));
        if AKind = agRestore then
        begin
          Result.Canvas.Brush.Color := clWhite;
          Result.Canvas.FillRect(Rect(0, 4, 11, 22));
          Result.Canvas.Pen.Color := RGB(180, 180, 180);
          Result.Canvas.Rectangle(0, 4, 11, 22);
        end;
      end;
    agReadPartitions, agReadBin, agReadRegion:
      DrawGlyphPhoneLeft(Result.Canvas);
  end;
  case AKind of
    agWriteFirmware:
      begin
        DrawGlyphFolder(Result.Canvas, RGB(240, 240, 240), RGB(190, 190, 190));
        DrawGlyphArrow(Result.Canvas, CDocGreen, CDocGreenDark);
      end;
    agRestore:
      begin
        DrawGlyphBox(Result.Canvas, RGB(200, 214, 228), RGB(120, 150, 180));
        DrawGlyphCircularArrow(Result.Canvas, RGB(120, 150, 180), True);
      end;
    agWriteBin:
      DrawGlyphArrow(Result.Canvas, RGB(130, 130, 130), RGB(80, 80, 80));
    agWriteOfp:
      DrawGlyphArrow(Result.Canvas, RGB(122, 96, 204), RGB(84, 62, 150));
    agReadInfo:
      DrawGlyphMagnifier(Result.Canvas);
    agReadPartitions:
      DrawGlyphArrowOut(Result.Canvas, CGreen, CGreenDark);
    agReadBin:
      DrawGlyphArrowOut(Result.Canvas, CPlaneBlue, CPlaneBlueDark);
    agReadRegion:
      DrawGlyphArrowOut(Result.Canvas, RGB(250, 200, 20), RGB(190, 140, 0));
    agReadOtp:
      DrawGlyphBarcode(Result.Canvas);
    agFormat:
      DrawGlyphCross(Result.Canvas, RGB(228, 60, 50));
    agWipeData:
      DrawGlyphWipe(Result.Canvas, False);
    agWipePartitions:
      DrawGlyphWipe(Result.Canvas, True);
    agEraseFrp:
      DrawGlyphLabel(Result.Canvas, 'FRP', RGB(232, 120, 30), clWhite);
    agEraseFrpWipe:
      begin
        DrawGlyphLabel(Result.Canvas, 'FRP', RGB(232, 120, 30), clWhite);
        DrawGlyphWipe(Result.Canvas, True);
      end;
    agRepair:
      DrawGlyphWrench(Result.Canvas);
    agReadImei:
      DrawGlyphLabel(Result.Canvas, 'IMEI', RGB(60, 60, 60), clWhite);
    agUnlockBootloader:
      DrawGlyphPadlock(Result.Canvas, CDocGreen, CDocGreenDark, True);
    agRelockBootloader:
      DrawGlyphPadlock(Result.Canvas, RGB(232, 120, 30), RGB(180, 86, 16), False);
    agUnlockNetwork:
      DrawGlyphGlobe(Result.Canvas);
    agReadCodes:
      begin
        Result.Canvas.Brush.Color := clWhite;
        Result.Canvas.Pen.Color := RGB(150, 150, 150);
        Result.Canvas.Rectangle(0, 2, 24, 22);
        Result.Canvas.Brush.Color := RGB(90, 90, 90);
        Result.Canvas.FillRect(Rect(3, 5, 5, 19));
        Result.Canvas.FillRect(Rect(7, 5, 8, 19));
        Result.Canvas.FillRect(Rect(10, 5, 13, 19));
        Result.Canvas.FillRect(Rect(15, 5, 16, 19));
        Result.Canvas.FillRect(Rect(18, 5, 20, 19));
        Result.Canvas.Brush.Color := RGB(230, 230, 230);
        Result.Canvas.FillRect(Rect(0, 19, 24, 22));
      end;
    agResetPassword:
      begin
        DrawGlyphPadlock(Result.Canvas, CGearBlue, CGearBlueDark, False);
        Result.Canvas.Pen.Color := RGB(250, 190, 40);
        Result.Canvas.Brush.Color := RGB(250, 190, 40);
        Result.Canvas.FillRect(Rect(0, 4, 6, 8));
        Result.Canvas.FillRect(Rect(0, 4, 2, 12));
        Result.Canvas.FillRect(Rect(0, 10, 4, 12));
      end;
    agResetAccount:
      DrawGlyphPerson(Result.Canvas, RGB(250, 170, 40), RGB(200, 120, 10));
    agRebootRecovery:
      DrawGlyphRecovery(Result.Canvas);
    agDisableOta:
      DrawGlyphCircularArrow(Result.Canvas, RGB(232, 120, 30), True);
    agResetDmVerity:
      DrawGlyphRecovery(Result.Canvas);
    agDisableOrangeState:
      DrawGlyphOrangeState(Result.Canvas);
    agSwitchSlot:
      DrawGlyphSwitchSlot(Result.Canvas);
    agFixDlImage:
      begin
        DrawGlyphRobot(Result.Canvas, CDocGreen);
        Result.Canvas.Pen.Width := 1;
        Result.Canvas.Pen.Color := RGB(60, 60, 60);
        Result.Canvas.Brush.Color := clWhite;
        Result.Canvas.Rectangle(14, 14, 23, 23);
        Result.Canvas.Pen.Color := RGB(228, 60, 50);
        Result.Canvas.Pen.Width := 2;
        Result.Canvas.MoveTo(15, 15);
        Result.Canvas.LineTo(22, 22);
        Result.Canvas.MoveTo(22, 15);
        Result.Canvas.LineTo(15, 22);
        Result.Canvas.Pen.Width := 1;
      end;
    agRpmbBackup:
      begin
        DrawGlyphBox(Result.Canvas, RGB(200, 214, 228), RGB(120, 150, 180));
        DrawGlyphArrowOut(Result.Canvas, RGB(120, 150, 180), RGB(90, 120, 150));
      end;
    agRpmbWrite:
      DrawGlyphArrow(Result.Canvas, CPlaneBlue, CPlaneBlueDark);
    agRpmbFormat:
      DrawGlyphCross(Result.Canvas, RGB(228, 60, 50));
    agSaveLog:
      begin
        Result.Canvas.Pen.Color := COrangeDark;
        Result.Canvas.Brush.Color := COrange;
        Result.Canvas.Rectangle(6, 10, 19, 22);
        Result.Canvas.Brush.Color := clWhite;
        Result.Canvas.FillRect(Rect(7, 11, 18, 15));
        Result.Canvas.Pen.Color := COrangeDark;
        Result.Canvas.Brush.Color := COrange;
        Result.Canvas.FillRect(Rect(10, 1, 15, 7));
        Result.Canvas.Polygon([Point(6, 6), Point(19, 6), Point(12, 13)]);
      end;
    agChangeDevice:
      begin
        Result.Canvas.Pen.Color := CDocGreenDark;
        Result.Canvas.Brush.Color := CDocGreen;
        Result.Canvas.Rectangle(4, 2, 19, 22);
        Result.Canvas.Pen.Color := CPlaneBlue;
        Result.Canvas.Pen.Width := 2;
        Result.Canvas.Brush.Style := bsClear;
        Result.Canvas.Arc(10, 10, 23, 23, 23, 12, 13, 22);
        Result.Canvas.Pen.Width := 1;
        Result.Canvas.Brush.Style := bsSolid;
        Result.Canvas.Brush.Color := CPlaneBlue;
        Result.Canvas.Pen.Color := CPlaneBlue;
        Result.Canvas.Polygon([Point(20, 9), Point(24, 15), Point(18, 15)]);
      end;
    agSettings:
      DrawGear(Result.Canvas, 12, 16, 10, 8, 7, CGearBlue, clWhite);
    agFacebook:
      begin
        Result.Canvas.Font.Name := 'Arial';
        Result.Canvas.Font.Style := [fsBold];
        Result.Canvas.Font.Height := -22;
        Result.Canvas.Font.Color := CFbBlue;
        Result.Canvas.Brush.Style := bsClear;
        DrawCenteredText(Result.Canvas, Rect(0, 0, 25, 24), 'f');
        Result.Canvas.Brush.Style := bsSolid;
      end;
    agHelp:
      begin
        Result.Canvas.Font.Name := 'Arial';
        Result.Canvas.Font.Style := [fsBold];
        Result.Canvas.Font.Height := -22;
        Result.Canvas.Font.Color := CHelpPurple;
        Result.Canvas.Brush.Style := bsClear;
        DrawCenteredText(Result.Canvas, Rect(0, 0, 24, 24), '?');
        Result.Canvas.Brush.Style := bsSolid;
      end;
    agSelect:
      begin
        Result.Canvas.Pen.Color := CGreenDark;
        Result.Canvas.Brush.Color := CGreen;
        Result.Canvas.Pen.Width := 5;
        Result.Canvas.MoveTo(4, 12);
        Result.Canvas.LineTo(10, 19);
        Result.Canvas.LineTo(21, 4);
        Result.Canvas.Pen.Width := 1;
      end;
  end;
  { keep bottom-left pixel transparent for TBitBtn }
  Result.Canvas.Pixels[0, 23] := clFuchsia;
  Result.TransparentColor := clFuchsia;
  Result.Transparent := True;
end;

end.
