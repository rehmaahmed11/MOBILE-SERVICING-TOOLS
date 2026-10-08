unit CaptureForm;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


{ The capture window.

  This is the window the user asked for: pressing an action button opens it,
  it tells the technician how to get the phone into the right service mode,
  it waits for the Windows device notification, and the moment the phone
  appears it takes the COM port with an exclusive handle. The port is then
  held for the whole operation and only released when the job is finished -
  the Close button does not even respond until then, so nothing can pull the
  device out from under a running write.

  Built in code like SettingsDialog, so there is no form file to keep in sync
  between Delphi and Lazarus. }

interface

uses
{$IFDEF FPC}
  Windows, Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Graphics,
  ComCtrls, Buttons,
{$ELSE}
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.Graphics,
  Vcl.ComCtrls,
  Vcl.Buttons,
{$ENDIF}
  DevTypes;

const
  { VCL has no clOrange before recent versions, and the LCL naming differs. }
  CAmber = TColor($0080FF);

type
  TForwardLine = procedure(const ALine: string) of object;

  { Modal capture + job window. }
  TCaptureForm = class(TForm)
  private
    FEngine: TObject;   { TJobEngine - kept as TObject so the interface of
                          this unit does not depend on JobEngine }
    FFinished: Boolean;
    FForward: TForwardLine;
    FHeading: TLabel;
    FHint: TLabel;
    FStep: TLabel;
    FBar: TProgressBar;
    FPercent: TLabel;
    FLog: TMemo;
    FBtnCancel: TButton;
    FBtnClose: TButton;
    FBtnSave: TButton;
    FStatePanel: TPanel;
    FStateDot: TPaintBox;
    FStateText: TLabel;
    FStartedAt: Int64;
    FLogLimit: Integer;
    procedure BuildControls;
    procedure DoCancelClick(Sender: TObject);
    procedure DoCloseClick(Sender: TObject);
    procedure DoSaveClick(Sender: TObject);
    procedure DoStatePaint(Sender: TObject);
    procedure DoFormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure SetPercent(APercent: Integer);
    function S(const AValue: Integer): Integer;
  public
    constructor CreateCapture(AOwner: TComponent);

    { Shows the window and runs one job to completion inside it. The call
      blocks until the device has been released again, exactly like ShowModal.
      The engine belongs to the caller and is NOT freed here, so MAIN 2 keeps
      its state. Returns True when the job finished successfully.

      The window closes itself after a successful job. After a failure or a
      cancel it stays open with the Close button enabled, so the technician can
      read what went wrong; nothing is holding the phone by then. }
    function RunJob(AEngine: TObject; const AParams: TJobParams): Boolean;

    { Where every log line is also written to (the MAIN 2 log). }
    property ForwardLine: TForwardLine read FForward write FForward;
    { True once the job finished, whatever the outcome. }
    property Finished: Boolean read FFinished;
  end;

{ True when this job has to wait for a phone and therefore deserves the modal
  capture window. Jobs that only run adb, or that only explain something, are
  better logged straight into MAIN 2. }
function JobWantsCaptureWindow(AKind: TJobKind): Boolean;

implementation

uses
{$IFDEF FPC}
  StrUtils, Dialogs, Clipbrd,
{$ELSE}
  System.StrUtils,
  Vcl.Dialogs,
  Vcl.Clipbrd,
{$ENDIF}
  DevCapture, DeviceSession, JobEngine, LogView;

const
  CFormWidth = 620;
  CFormHeight = 470;
  CLogHeight = 250;

function JobWantsCaptureWindow(AKind: TJobKind): Boolean;
begin
  Result := CaptureNeedOf(TJobKind(AKind)) in
    [coCapture, coHandshake, coBootloader];
end;

{ The engine is passed as TObject so that this unit and JobEngine do not have
  to know about each other at interface level. These wrappers give the real
  type back. }
function EngineOf(AEngine: TObject): TJobEngine;
begin
  if AEngine is TJobEngine then
    Result := TJobEngine(AEngine)
  else
    Result := nil;
end;

{ ------------------------------------------------------------------ the form }

function TCaptureForm.S(const AValue: Integer): Integer;
begin
  { controls made in code are not scaled automatically on high-DPI screens }
  Result := MulDiv(AValue, Screen.PixelsPerInch, 96);
end;

constructor TCaptureForm.CreateCapture(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := 'Device capture';
  BorderStyle := bsDialog;
  Position := poOwnerFormCenter;
  ClientWidth := S(CFormWidth);
  ClientHeight := S(CFormHeight);
  Font.Name := 'Tahoma';
  Font.Size := 8;
  Color := clWhite;
  FEngine := nil;
  FFinished := False;
  FForward := nil;
  FLogLimit := 2000;
  BuildControls;
  OnCloseQuery := DoFormCloseQuery;
end;

procedure TCaptureForm.BuildControls;
begin
  FHeading := TLabel.Create(Self);
  FHeading.Parent := Self;
  FHeading.SetBounds(S(16), S(12), S(CFormWidth - 32), S(18));
  FHeading.Font.Size := 10;
  FHeading.Font.Style := [fsBold];
  FHeading.Caption := 'Waiting for the device';

  FHint := TLabel.Create(Self);
  FHint.Parent := Self;
  FHint.SetBounds(S(16), S(34), S(CFormWidth - 32), S(46));
  FHint.AutoSize := False;
  FHint.WordWrap := True;
  FHint.Caption := 'Put the phone in the service mode this job needs and plug ' +
    'in the USB cable. As soon as Windows reports the device, this app takes ' +
    'its port and holds it until the job is finished.';

  FStatePanel := TPanel.Create(Self);
  FStatePanel.Parent := Self;
  FStatePanel.SetBounds(S(16), S(86), S(CFormWidth - 32), S(26));
  FStatePanel.BevelOuter := bvNone;
  FStatePanel.Color := clWhite;

  FStateDot := TPaintBox.Create(Self);
  FStateDot.Parent := FStatePanel;
  FStateDot.SetBounds(S(2), S(6), S(14), S(14));
  FStateDot.OnPaint := DoStatePaint;

  FStateText := TLabel.Create(Self);
  FStateText.Parent := FStatePanel;
  FStateText.SetBounds(S(22), S(6), S(CFormWidth - 70), S(16));
  FStateText.Caption := 'no device';

  FStep := TLabel.Create(Self);
  FStep.Parent := Self;
  FStep.SetBounds(S(16), S(120), S(CFormWidth - 100), S(16));
  FStep.Caption := 'starting';

  FPercent := TLabel.Create(Self);
  FPercent.Parent := Self;
  FPercent.SetBounds(S(CFormWidth - 76), S(120), S(60), S(16));
  FPercent.Alignment := taRightJustify;
  FPercent.AutoSize := False;
  FPercent.Caption := '';

  FBar := TProgressBar.Create(Self);
  FBar.Parent := Self;
  FBar.SetBounds(S(16), S(140), S(CFormWidth - 32), S(16));
  FBar.Min := 0;
  FBar.Max := 100;
  FBar.Position := 0;
  FBar.Smooth := True;

  FLog := TMemo.Create(Self);
  FLog.Parent := Self;
  FLog.SetBounds(S(16), S(166), S(CFormWidth - 32), S(CLogHeight));
  FLog.ReadOnly := True;
  FLog.ScrollBars := ssVertical;
  FLog.Font.Name := 'Consolas';
  FLog.Font.Size := 8;
  FLog.HideSelection := False;
  FLog.TabStop := False;

  FBtnSave := TButton.Create(Self);
  FBtnSave.Parent := Self;
  FBtnSave.SetBounds(S(16), S(CFormHeight - 44), S(110), S(28));
  FBtnSave.Caption := 'Copy log';
  FBtnSave.OnClick := DoSaveClick;

  FBtnCancel := TButton.Create(Self);
  FBtnCancel.Parent := Self;
  FBtnCancel.SetBounds(S(CFormWidth - 216), S(CFormHeight - 44), S(96), S(28));
  FBtnCancel.Caption := 'Cancel';
  FBtnCancel.OnClick := DoCancelClick;

  FBtnClose := TButton.Create(Self);
  FBtnClose.Parent := Self;
  FBtnClose.SetBounds(S(CFormWidth - 112), S(CFormHeight - 44), S(96), S(28));
  FBtnClose.Caption := 'Close';
  FBtnClose.Enabled := False;
  FBtnClose.OnClick := DoCloseClick;
end;

procedure TCaptureForm.SetPercent(APercent: Integer);
begin
  if APercent < 0 then
  begin
    { an indeterminate step: show movement without pretending to know how far }
    if FBar.Position >= 95 then
      FBar.Position := 5
    else
      FBar.Position := FBar.Position + 5;
    FPercent.Caption := '';
    Exit;
  end;
  if APercent > 100 then
    APercent := 100;
  FBar.Position := APercent;
  FPercent.Caption := IntToStr(APercent) + ' %';
end;

procedure TCaptureForm.DoStatePaint(Sender: TObject);
var
  DotColor: TColor;
  Eng: TJobEngine;
begin
  DotColor := clSilver;
  Eng := EngineOf(FEngine);
  if Eng <> nil then
  begin
    if Eng.DeviceLocked then
      DotColor := clGreen
    else if Eng.Busy then
      DotColor := CAmber
  end;
  if FFinished then
    DotColor := clGray;
  FStateDot.Canvas.Brush.Color := DotColor;
  FStateDot.Canvas.Pen.Color := DotColor;
  FStateDot.Canvas.Ellipse(0, 0, FStateDot.Width, FStateDot.Height);
end;

procedure TCaptureForm.DoCancelClick(Sender: TObject);
var
  Eng: TJobEngine;
begin
  Eng := EngineOf(FEngine);
  if (Eng = nil) or FFinished then
  begin
    ModalResult := mrCancel;
    Exit;
  end;
  if Eng.DeviceLocked and (MessageDlg(
    'The device port is locked and the job is running. Cancelling now can ' +
    'leave the phone with a half-written partition.' + sLineBreak + sLineBreak +
    'Cancel anyway?', mtWarning, [mbYes, mbNo], 0) <> mrYes) then
    Exit;
  FLog.Lines.Add('Cancelling - the port is released as soon as the current ' +
    'step returns.');
  Eng.Cancel;
end;

procedure TCaptureForm.DoCloseClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TCaptureForm.DoSaveClick(Sender: TObject);
begin
  Clipboard.AsText := FLog.Lines.Text;
  FBtnSave.Caption := 'Copied';
end;

procedure TCaptureForm.DoFormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  Eng: TJobEngine;
begin
  Eng := EngineOf(FEngine);
  CanClose := FFinished or (Eng = nil);
  if not CanClose then
  begin
    { Alt+F4 or the system menu must not drop the device mid-write }
    FLog.Lines.Add('The window stays open until the job has released the ' +
      'device. Use Cancel to stop it.');
    Eng.Cancel;
  end;
end;

function TCaptureForm.RunJob(AEngine: TObject;
  const AParams: TJobParams): Boolean;
var
  Eng: TJobEngine;
  Outcome: TJobOutcome;
  Elapsed: Int64;

  procedure AddLine(const ALine: string);
  begin
    if FLog.Lines.Count > FLogLimit then
      FLog.Lines.Delete(0);
    FLog.Lines.Add(StripLogCodes(ALine));
    if Assigned(FForward) then
      FForward(ALine);
  end;

  procedure EngineLog(Sender: TObject; const AText: string);
  begin
    AddLine(AText);
  end;

  procedure EngineProgress(Sender: TObject; APercent: Integer;
    const AText: string);
  begin
    SetPercent(APercent);
    if AText <> '' then
      FStep.Caption := AText;
    Elapsed := TicksSince(FStartedAt);
    FStateText.Caption := Format('%s   %d.%d s',
      [FStep.Caption, Elapsed div 1000, (Elapsed mod 1000) div 100]);
    FStateDot.Invalidate;
    Application.ProcessMessages;
  end;

  procedure EngineStateChanged(Sender: TObject);
  var
    Text: string;
  begin
    Text := JobStateName(Eng.State);
    if Eng.DeviceLocked then
      Text := Text + ' - port ' + Eng.Session.PortName + ' held exclusively';
    FStateText.Caption := Text;
    FStateDot.Invalidate;
    FBtnCancel.Enabled := Eng.Busy;
    Application.ProcessMessages;
  end;

begin
  Result := False;
  Eng := EngineOf(AEngine);
  if Eng = nil then
  begin
    FLog.Lines.Add('Internal error: no job engine was passed to the capture ' +
      'window.');
    FFinished := True;
    FBtnClose.Enabled := True;
    Exit;
  end;
  FEngine := Eng;
  FFinished := False;
  FStartedAt := Tick64;
  FLog.Lines.Clear;

  Caption := JobName(AParams.Kind) + ' - device capture';
  FHeading.Caption := JobName(AParams.Kind);
  FHint.Caption := CaptureHint(AParams.Platform, AParams.ForceBrom);
  if AParams.Brand <> '' then
    FStateText.Caption := AParams.Brand + ' ' + AParams.ModelName
  else
    FStateText.Caption := 'no device';

  { The engine logs and reports through this window while it runs. }
  Eng.OnLog := EngineLog;
  Eng.OnProgress := EngineProgress;
  Eng.OnStateChanged := EngineStateChanged;

  AddLine('[' + JobName(AParams.Kind) + ']  ' +
    PlatformLabel(AParams.Platform) + '  ' + AParams.Brand + ' ' +
    AParams.ModelCode + ' : ' + AParams.ModelName);
  if Eng.AllowSimulated then
    AddLine('SIMULATION MODE - no phone is required and every result below is ' +
      'flagged as simulated.');

  FBtnCancel.Enabled := True;
  FBtnClose.Enabled := False;
  { The window must be on screen and painting before the synchronous capture
    starts, or the technician stares at a frozen rectangle for the whole
    timeout. Show + ProcessMessages gets it there without a modal loop that
    could not return until the job was over. }
  Show;
  Application.ProcessMessages;

  Outcome := Eng.RunJob(AParams);

  Elapsed := TicksSince(FStartedAt);
  case Outcome.State of
    jsDone:
      begin
        SetPercent(100);
        AddLine('OK  ' + Outcome.Message +
          IfThenStr(Outcome.Simulated, '   [SIMULATED]', ''));
        if Outcome.BytesMoved > 0 then
          AddLine(Format('%d bytes moved in %d.%d s', [Outcome.BytesMoved,
            Elapsed div 1000, (Elapsed mod 1000) div 100]));
      end;
    jsCancelled:
      begin
        AddLine('CANCELLED  ' + Outcome.Message);
        AddLine('The device port has been released.');
      end;
  else
    AddLine('FAILED [' + Outcome.Code + ']  ' + Outcome.Message);
    AddLine('The device port has been released.');
  end;
  AddLine('Device held for ' + Format('%d.%d s',
    [Elapsed div 1000, (Elapsed mod 1000) div 100]) + '.');

  FFinished := True;
  Result := Outcome.State = jsDone;
  FBtnCancel.Enabled := False;
  FBtnClose.Enabled := True;
  FBtnClose.Caption := 'Close';
  FBtnClose.Default := True;
  FStateDot.Invalidate;
  Application.ProcessMessages;

  { MAIN 2 keeps its own log handlers }
  Eng.OnLog := nil;
  Eng.OnProgress := nil;
  Eng.OnStateChanged := nil;

  if Result then
    Close;   { the device is released, so nothing is lost by closing }
end;

end.
