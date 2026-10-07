object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Mobile Servicing Tools - Device Setup'
  ClientHeight = 780
  ClientWidth = 1160
  Color = clBtnFace
  Constraints.MinHeight = 650
  Constraints.MinWidth = 900
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Align = alTop
    Height = 150
    BevelOuter = bvNone
    Color = clBtnFace
    DoubleBuffered = True
    ParentBackground = False
    TabOrder = 0
    object lblEyebrow: TLabel
      Left = 44
      Top = 21
      Width = 390
      Height = 17
      Caption = 'MOBILE SERVICING TOOLS    /    DEVICE SETUP'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -10
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object lblTitle: TLabel
      Left = 42
      Top = 46
      Width = 650
      Height = 43
      Caption = 'Choose your device'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -29
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object lblSubtitle: TLabel
      Left = 44
      Top = 99
      Width = 680
      Height = 24
      Caption = 'Select a brand, then choose a model to continue.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object lblStep: TLabel
      Left = 926
      Top = 58
      Width = 190
      Height = 24
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      Caption = 'STEP 01   /   DEVICE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -10
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
      Layout = tlCenter
    end
  end
  object pnlFooter: TPanel
    Align = alBottom
    Height = 108
    BevelOuter = bvNone
    Color = clBtnFace
    DoubleBuffered = True
    ParentBackground = False
    TabOrder = 1
    object lblSelectionCaption: TLabel
      Left = 44
      Top = 19
      Width = 280
      Height = 16
      Caption = 'CURRENT SELECTION'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object lblSelectionValue: TLabel
      Left = 44
      Top = 40
      Width = 640
      Height = 23
      Caption = 'No device selected'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -14
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object lblSelectionNote: TLabel
      Left = 44
      Top = 68
      Width = 640
      Height = 18
      Caption = 'Select a brand, then choose a model to continue.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -10
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object btnNext: TButton
      Left = 936
      Top = 25
      Width = 180
      Height = 56
      Anchors = [akTop, akRight]
      Caption = 'NEXT'
      Enabled = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      OnClick = btnNextClick
    end
  end
  object pnlWorkspace: TPanel
    Align = alClient
    BevelOuter = bvNone
    Color = clBtnFace
    DoubleBuffered = True
    Padding.Left = 40
    Padding.Top = 4
    Padding.Right = 40
    Padding.Bottom = 20
    ParentBackground = False
    TabOrder = 2
    object pnlBrandCard: TPanel
      Align = alLeft
      Width = 380
      Margins.Left = 0
      Margins.Top = 2
      Margins.Right = 18
      Margins.Bottom = 0
      AlignWithMargins = True
      BevelOuter = bvNone
      Color = clBtnFace
      DoubleBuffered = True
      ParentBackground = False
      TabOrder = 0
      object lblBrandSection: TLabel
        Left = 22
        Top = 21
        Width = 180
        Height = 17
        Caption = '01   /   BRAND'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -10
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object lblBrandCount: TLabel
        Left = 242
        Top = 21
        Width = 104
        Height = 17
        Alignment = taRightJustify
        Anchors = [akTop, akRight]
        Caption = '0 BRANDS'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object lblBrandTitle: TLabel
        Left = 22
        Top = 48
        Width = 300
        Height = 29
        Caption = 'Choose a brand'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object lblBrandHelper: TLabel
        Left = 23
        Top = 82
        Width = 320
        Height = 20
        Caption = 'Select your device manufacturer'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -10
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        Transparent = True
      end
      object lstBrands: TListBox
        Align = alClient
        Margins.Left = 16
        Margins.Top = 126
        Margins.Right = 16
        Margins.Bottom = 16
        AlignWithMargins = True
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        Color = clWindow
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        IntegralHeight = False
        ItemHeight = 52
        ParentFont = False
        Style = lbOwnerDrawFixed
        TabOrder = 0
        OnClick = lstBrandsClick
        OnDrawItem = lstBrandsDrawItem
      end
    end
    object pnlModelCard: TPanel
      Align = alClient
      Margins.Left = 0
      Margins.Top = 2
      Margins.Right = 0
      Margins.Bottom = 0
      AlignWithMargins = True
      BevelOuter = bvNone
      Color = clBtnFace
      DoubleBuffered = True
      ParentBackground = False
      TabOrder = 1
      object lblModelSection: TLabel
        Left = 24
        Top = 21
        Width = 180
        Height = 17
        Caption = '02   /   MODEL'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -10
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object lblModelCount: TLabel
        Left = 542
        Top = 21
        Width = 120
        Height = 17
        Alignment = taRightJustify
        Anchors = [akTop, akRight]
        Caption = '0 MODELS'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object lblModelTitle: TLabel
        Left = 24
        Top = 48
        Width = 440
        Height = 29
        Caption = 'Choose a model'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object lblModelHelper: TLabel
        Left = 25
        Top = 82
        Width = 620
        Height = 20
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Select a brand to load its models'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -10
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        Transparent = True
      end
      object lstModels: TListBox
        Align = alClient
        Margins.Left = 18
        Margins.Top = 126
        Margins.Right = 18
        Margins.Bottom = 16
        AlignWithMargins = True
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        Color = clWindow
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        IntegralHeight = False
        ItemHeight = 52
        ParentFont = False
        Style = lbOwnerDrawFixed
        TabOrder = 0
        OnClick = lstModelsClick
        OnDrawItem = lstModelsDrawItem
      end
    end
  end
end
