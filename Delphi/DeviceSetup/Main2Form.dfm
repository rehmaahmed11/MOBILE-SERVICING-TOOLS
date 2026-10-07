object frmMain2: TMain2Form
  Left = 0
  Top = 0
  Caption = 'Mobile Servicing Tools'
  ClientHeight = 560
  ClientWidth = 1008
  Color = clBtnFace
  Constraints.MinHeight = 400
  Constraints.MinWidth = 720
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  ShowHint = True
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object pbBack: TPaintBox
    Left = 14
    Top = 2
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Back'
    OnClick = pbBackClick
    OnPaint = pbBackPaint
  end
  object grpDevice: TGroupBox
    Left = 16
    Top = 47
    Width = 661
    Height = 110
    Caption = ' Selected device '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    object lblBrandCaption: TLabel
      Left = 16
      Top = 26
      Width = 40
      Height = 16
      Caption = 'Brand :'
    end
    object lblBrandValue: TLabel
      Left = 110
      Top = 26
      Width = 530
      Height = 16
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblModelCaption: TLabel
      Left = 16
      Top = 50
      Width = 42
      Height = 16
      Caption = 'Model :'
    end
    object lblModelValue: TLabel
      Left = 110
      Top = 50
      Width = 530
      Height = 16
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblCodeCaption: TLabel
      Left = 16
      Top = 74
      Width = 79
      Height = 16
      Caption = 'Model code :'
    end
    object lblCodeValue: TLabel
      Left = 110
      Top = 74
      Width = 530
      Height = 16
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object btnBack: TButton
    Left = 16
    Top = 516
    Width = 90
    Height = 28
    Anchors = [akLeft, akBottom]
    Cancel = True
    Caption = '< Back'
    ModalResult = 2
    TabOrder = 1
  end
end
