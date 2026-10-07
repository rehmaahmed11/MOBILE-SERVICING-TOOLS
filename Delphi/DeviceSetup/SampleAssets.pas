unit SampleAssets;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

{ Small bitmap resources taken from the supplied UI samples. They are linked
  into the EXE; the portable app has no image-directory dependency. This is
  artwork only, never a screenshot used in place of interactive controls. }

interface

uses
{$IFDEF FPC}
  Windows, Classes, SysUtils, Types, Graphics;
{$ELSE}
  Winapi.Windows, System.Classes, System.SysUtils, System.Types, Vcl.Graphics;
{$ENDIF}

function SampleBitmap(const AName: string): TBitmap;
procedure DrawSampleBitmap(ACanvas: TCanvas; const R: TRect;
  const AName: string);

implementation

{$R SampleAssets.res}

var
  GBitmaps: TStringList;

function SampleBitmap(const AName: string): TBitmap;
var
  I: Integer;
begin
  if GBitmaps = nil then
    GBitmaps := TStringList.Create;
  I := GBitmaps.IndexOf(AName);
  if I >= 0 then
    Exit(TBitmap(GBitmaps.Objects[I]));
  Result := TBitmap.Create;
  try
    Result.LoadFromResourceName(HInstance, AName);
    Result.TransparentColor := clFuchsia;
    Result.Transparent := True;
    GBitmaps.AddObject(AName, Result);
  except
    Result.Free;
    raise;
  end;
end;

procedure DrawSampleBitmap(ACanvas: TCanvas; const R: TRect;
  const AName: string);
var
  B: TBitmap;
  OldMode: Integer;
begin
  B := SampleBitmap(AName);
  if (R.Right - R.Left = B.Width) and (R.Bottom - R.Top = B.Height) then
    ACanvas.Draw(R.Left, R.Top, B)
  else
  begin
    OldMode := SetStretchBltMode(ACanvas.Handle, HALFTONE);
    try
      ACanvas.StretchDraw(R, B);
    finally
      SetStretchBltMode(ACanvas.Handle, OldMode);
    end;
  end;
end;

procedure FreeBitmaps;
var
  I: Integer;
begin
  if GBitmaps = nil then
    Exit;
  for I := 0 to GBitmaps.Count - 1 do
    GBitmaps.Objects[I].Free;
  FreeAndNil(GBitmaps);
end;

finalization
  FreeBitmaps;

end.
