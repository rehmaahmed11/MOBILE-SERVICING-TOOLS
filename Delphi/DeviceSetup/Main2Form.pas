unit Main2Form;

{ MAIN 2 - opened from MAIN 1 when the user presses Next.
  Shows the device chosen on MAIN 1. The full MAIN 2 layout will be built
  to match its reference screenshot once that design is supplied. }

interface

uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  System.Types,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.StdCtrls,
  Vcl.ExtCtrls;

type
  TMain2Form = class(TForm)
    pbBack: TPaintBox;
    grpDevice: TGroupBox;
    lblBrandCaption: TLabel;
    lblBrandValue: TLabel;
    lblModelCaption: TLabel;
    lblModelValue: TLabel;
    lblCodeCaption: TLabel;
    lblCodeValue: TLabel;
    btnBack: TButton;
    procedure pbBackPaint(Sender: TObject);
    procedure pbBackClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  public
    procedure SetDevice(const ABrand, AModelEntry: string);
  end;

implementation

{$R *.dfm}

procedure TMain2Form.SetDevice(const ABrand, AModelEntry: string);
var
  SepPos: Integer;
  Code, ModelTitle: string;
begin
  { Model entries look like "RMX3382 : Realme 8s 5G". }
  SepPos := Pos(' : ', AModelEntry);
  if SepPos > 0 then
  begin
    Code := Trim(Copy(AModelEntry, 1, SepPos - 1));
    ModelTitle := Trim(Copy(AModelEntry, SepPos + 3, MaxInt));
  end
  else
  begin
    Code := '';
    ModelTitle := AModelEntry;
  end;

  Caption := 'Mobile Servicing Tools - ' + ABrand + ' ' + ModelTitle;
  lblBrandValue.Caption := ABrand;
  lblModelValue.Caption := ModelTitle;
  lblCodeValue.Caption := Code;
end;

procedure TMain2Form.pbBackPaint(Sender: TObject);
var
  C: TCanvas;
  L, T: Integer;
begin
  C := pbBack.Canvas;
  C.Brush.Style := bsSolid;
  C.Brush.Color := clBtnFace;
  C.FillRect(pbBack.ClientRect);
  L := 0;
  T := 0;
  C.Pen.Color := RGB(16, 82, 168);
  C.Brush.Color := RGB(36, 120, 214);
  C.Polygon([Point(L + 3, T + 14), Point(L + 13, T + 4), Point(L + 13, T + 10),
    Point(L + 25, T + 10), Point(L + 25, T + 18), Point(L + 13, T + 18),
    Point(L + 13, T + 24)]);
end;

procedure TMain2Form.pbBackClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TMain2Form.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    ModalResult := mrCancel;
  end;
end;

end.
