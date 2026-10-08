unit ToolbarIcons;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

{ Shared artwork from data/ui-reference/S1.png ... S10.png. Unlike the previous
  vector approximations these toolbar cards, shadows and action glyphs are
  the actual reference pixels. SampleAssets links the BMPs into the EXE. }

interface

uses
{$IFDEF FPC}
  Windows, Types, Graphics;
{$ELSE}
  Winapi.Windows, System.Types, Vcl.Graphics;
{$ENDIF}

type
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

  TIconProc = procedure(ACanvas: TCanvas; const R: TRect);

procedure PaintIcon(ACanvas: TCanvas; const ADest: TRect; AProc: TIconProc);
procedure DrawMenuIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawNextIconEnabled(ACanvas: TCanvas; const R: TRect);
procedure DrawNextIconDisabled(ACanvas: TCanvas; const R: TRect);
procedure DrawDownloadIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawDeviceDocIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawGearIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawPlaneIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawFacebookIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawHelpIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawDeviceConnectedIcon(ACanvas: TCanvas; const R: TRect);
procedure DrawDeviceDisconnectedIcon(ACanvas: TCanvas; const R: TRect);
function CreateActionGlyph(const AKind: TActionGlyph): TBitmap;

implementation

uses
  SampleAssets;

const
  CActionNames: array[TActionGlyph] of string = (
    'UI_WRITE_FIRMWARE', 'UI_RESTORE', 'UI_WRITE_BIN', 'UI_WRITE_OFP',
    'UI_READ_INFO', 'UI_READ_PARTITIONS', 'UI_READ_BIN', 'UI_READ_REGION',
    'UI_READ_OTP', 'UI_FORMAT', 'UI_WIPE_DATA', 'UI_WIPE_PARTITIONS',
    'UI_ERASE_FRP', 'UI_ERASE_FRP_WIPE', 'UI_REPAIR', 'UI_READ_IMEI',
    'UI_UNLOCK_BOOTLOADER', 'UI_RELOCK_BOOTLOADER', 'UI_UNLOCK_NETWORK',
    'UI_READ_CODES', 'UI_RESET_PASSWORD', 'UI_RESET_ACCOUNT',
    'UI_REBOOT_RECOVERY', 'UI_DISABLE_OTA', 'UI_RESET_DM_VERITY',
    'UI_DISABLE_ORANGE_STATE', 'UI_SWITCH_SLOT', 'UI_FIX_DL_IMAGE',
    'UI_RPMB_BACKUP', 'UI_RPMB_WRITE', 'UI_RPMB_FORMAT',
    'UI_DOWNLOAD', 'UI_DOCUMENT', 'UI_SETTINGS', 'UI_FACEBOOK', 'UI_HELP',
    'UI_SELECT');

procedure DrawMenuIcon(ACanvas: TCanvas; const R: TRect);
begin
  DrawSampleBitmap(ACanvas, R, 'UI_MENU');
end;

procedure DrawNextIconEnabled(ACanvas: TCanvas; const R: TRect);
begin
  DrawSampleBitmap(ACanvas, R, 'UI_START');
end;

procedure DrawNextIconDisabled(ACanvas: TCanvas; const R: TRect);
begin
  DrawSampleBitmap(ACanvas, R, 'UI_START_DISABLED');
end;

procedure DrawDownloadIcon(ACanvas: TCanvas; const R: TRect);
begin
  DrawSampleBitmap(ACanvas, R, 'UI_DOWNLOAD');
end;

procedure DrawDeviceDocIcon(ACanvas: TCanvas; const R: TRect);
begin
  DrawSampleBitmap(ACanvas, R, 'UI_DOCUMENT');
end;

procedure DrawGearIcon(ACanvas: TCanvas; const R: TRect);
begin
  DrawSampleBitmap(ACanvas, R, 'UI_SETTINGS');
end;

procedure DrawPlaneIcon(ACanvas: TCanvas; const R: TRect);
begin
  DrawSampleBitmap(ACanvas, R, 'UI_REPORT');
end;

procedure DrawFacebookIcon(ACanvas: TCanvas; const R: TRect);
begin
  DrawSampleBitmap(ACanvas, R, 'UI_FACEBOOK');
end;

procedure DrawHelpIcon(ACanvas: TCanvas; const R: TRect);
begin
  DrawSampleBitmap(ACanvas, R, 'UI_HELP');
end;

procedure DrawDeviceStateIcon(ACanvas: TCanvas; const R: TRect;
  const AConnected: Boolean);
var
  L, T: Integer;
  Mark: TColor;
begin
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := $00F0F0F0;
  ACanvas.FillRect(R);
  L := R.Left;
  T := R.Top;
  ACanvas.Pen.Color := RGB(60, 60, 60);
  ACanvas.Brush.Color := clWhite;
  ACanvas.RoundRect(L + 6, T + 1, L + 20, T + 27, 4, 4);
  ACanvas.Brush.Color := RGB(60, 60, 60);
  ACanvas.FillRect(Rect(L + 6, T + 22, L + 20, T + 27));
  if AConnected then
    Mark := RGB(33, 187, 79)
  else
    Mark := RGB(225, 30, 30);
  ACanvas.Pen.Color := Mark;
  ACanvas.Brush.Style := bsClear;
  ACanvas.Rectangle(L + 1, T + 9, L + 9, T + 16);
  ACanvas.MoveTo(L + 9, T + 12);
  ACanvas.LineTo(L + 15, T + 12);
  ACanvas.Ellipse(L + 12, T + 14, L + 19, T + 21);
  ACanvas.Brush.Style := bsSolid;
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
  B: TBitmap;
  OldMode: Integer;
begin
  if (ADest.Right - ADest.Left = CSize) and
    (ADest.Bottom - ADest.Top = CSize) then
  begin
    AProc(ACanvas, ADest);
    Exit;
  end;
  B := TBitmap.Create;
  try
    B.PixelFormat := pf24bit;
    B.SetSize(CSize, CSize);
    B.Canvas.Brush.Color := $00F0F0F0;
    B.Canvas.FillRect(Rect(0, 0, CSize, CSize));
    AProc(B.Canvas, Rect(0, 0, CSize, CSize));
    OldMode := SetStretchBltMode(ACanvas.Handle, HALFTONE);
    try
      ACanvas.StretchDraw(ADest, B);
    finally
      SetStretchBltMode(ACanvas.Handle, OldMode);
    end;
  finally
    B.Free;
  end;
end;

function CreateActionGlyph(const AKind: TActionGlyph): TBitmap;
begin
  Result := TBitmap.Create;
  Result.Assign(SampleBitmap(CActionNames[AKind]));
  Result.TransparentColor := clFuchsia;
  Result.Transparent := True;
end;

end.
