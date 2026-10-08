unit LogView;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


{ Coloured log lines for the MAIN 2 log (an owner-drawn list box).
  A line is a plain string with colour codes in it: every code switches the
  colour of the text that follows, e.g.
      'Search DA... ' + LOk + ' ' + LInfo('[0]')
  is drawn as "Search DA... " in black, "OK" in green and "[0]" in blue.
  The same unit works under Delphi (VCL) and Lazarus (LCL). }

interface

uses
{$IFDEF FPC}
  Windows, Types, SysUtils, Graphics;
{$ELSE}
  Winapi.Windows,
  System.Types,
  System.SysUtils,
  Vcl.Graphics;
{$ENDIF}

const
  LC_NORMAL = #1;
  LC_OK = #2;      { green  }
  LC_INFO = #3;    { blue   }
  LC_ERROR = #4;   { red    }
  LC_MUTED = #5;   { grey   }
  LC_WARN = #6;    { orange }

function LOk(const S: string = 'OK'): string;
function LInfo(const S: string): string;
function LErr(const S: string): string;
function LWarn(const S: string): string;
function LMuted(const S: string): string;

{ The line without colour codes (for saving / copying). }
function StripLogCodes(const S: string): string;

{ Draws one log line into R. }
procedure DrawLogLine(ACanvas: TCanvas; const R: TRect; const S: string;
  const ASelected: Boolean);

{ Pixel width of a line (for the horizontal scroll range). }
function LogLineWidth(ACanvas: TCanvas; const S: string): Integer;

implementation

function Wrap(const ACode, S: string): string;
begin
  Result := ACode + S + LC_NORMAL;
end;

function LOk(const S: string): string;
begin
  Result := Wrap(LC_OK, S);
end;

function LInfo(const S: string): string;
begin
  Result := Wrap(LC_INFO, S);
end;

function LErr(const S: string): string;
begin
  Result := Wrap(LC_ERROR, S);
end;

function LWarn(const S: string): string;
begin
  Result := Wrap(LC_WARN, S);
end;

function LMuted(const S: string): string;
begin
  Result := Wrap(LC_MUTED, S);
end;

function IsCode(const C: Char): Boolean;
begin
  Result := (C >= LC_NORMAL) and (C <= LC_WARN);
end;

function StripLogCodes(const S: string): string;
var
  I, N: Integer;
begin
  SetLength(Result, Length(S));
  N := 0;
  for I := 1 to Length(S) do
    if not IsCode(S[I]) then
    begin
      Inc(N);
      Result[N] := S[I];
    end;
  SetLength(Result, N);
end;

function CodeColor(const C: Char): TColor;
begin
  case C of
    LC_OK: Result := RGB(0, 140, 0);
    LC_INFO: Result := RGB(0, 0, 200);
    LC_ERROR: Result := RGB(220, 0, 0);
    LC_MUTED: Result := RGB(128, 128, 128);
    LC_WARN: Result := RGB(200, 110, 0);
  else
    Result := clWindowText;
  end;
end;

procedure DrawLogLine(ACanvas: TCanvas; const R: TRect; const S: string;
  const ASelected: Boolean);
var
  I, Start, X, Y: Integer;
  Color: TColor;
  Part: string;

  procedure Flush(const AUpTo: Integer);
  begin
    if AUpTo < Start then
      Exit;
    Part := Copy(S, Start, AUpTo - Start + 1);
    if ASelected then
      ACanvas.Font.Color := clHighlightText
    else
      ACanvas.Font.Color := Color;
    ACanvas.TextOut(X, Y, Part);
    Inc(X, ACanvas.TextWidth(Part));
  end;

begin
  ACanvas.Brush.Style := bsSolid;
  if ASelected then
    ACanvas.Brush.Color := clHighlight
  else
    ACanvas.Brush.Color := clWindow;
  ACanvas.FillRect(R);
  ACanvas.Brush.Style := bsClear;

  X := R.Left + 2;
  Y := R.Top + (R.Bottom - R.Top - ACanvas.TextHeight('Wg')) div 2;
  Color := clWindowText;
  Start := 1;
  for I := 1 to Length(S) do
    if IsCode(S[I]) then
    begin
      Flush(I - 1);
      Color := CodeColor(S[I]);
      Start := I + 1;
    end;
  Flush(Length(S));
  ACanvas.Brush.Style := bsSolid;
end;

function LogLineWidth(ACanvas: TCanvas; const S: string): Integer;
begin
  Result := ACanvas.TextWidth(StripLogCodes(S)) + 8;
end;

end.
