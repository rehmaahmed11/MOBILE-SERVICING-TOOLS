object frmMain: TMainForm
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
  OldCreateOrder = False
  Position = poScreenCenter
  ShowHint = True
  ActiveControl = cbSearch
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pbMenu: TPaintBox
    Left = 14
    Top = 2
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Menu'
    OnClick = pbMenuClick
    OnPaint = pbMenuPaint
  end
  object pbNext: TPaintBox
    Left = 922
    Top = 4
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Next'
    Anchors = [akTop, akRight]
    OnClick = pbNextClick
    OnPaint = pbNextPaint
  end
  object pbDownload: TPaintBox
    Left = 962
    Top = 4
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Save model list'
    Anchors = [akTop, akRight]
    OnClick = pbDownloadClick
    OnPaint = pbDownloadPaint
  end
  object cbSearch: TComboBox
    Left = 16
    Top = 47
    Width = 661
    Height = 21
    TabOrder = 0
    Text = 'Quick search'
    OnChange = cbSearchChange
    OnEnter = cbSearchEnter
    OnExit = cbSearchExit
    OnKeyDown = cbSearchKeyDown
  end
  object lstBrands: TListBox
    Left = 16
    Top = 70
    Width = 124
    Height = 478
    Anchors = [akLeft, akTop, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ItemHeight = 16
    ParentFont = False
    TabOrder = 1
    OnClick = lstBrandsClick
  end
  object lstModels: TListBox
    Left = 144
    Top = 70
    Width = 533
    Height = 478
    Anchors = [akLeft, akTop, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ItemHeight = 16
    ParentFont = False
    TabOrder = 2
    OnClick = lstModelsClick
    OnDblClick = lstModelsDblClick
    OnKeyDown = lstModelsKeyDown
  end
  object pmMain: TPopupMenu
    Left = 760
    Top = 120
    object miNext: TMenuItem
      Caption = 'Next'
      OnClick = pbNextClick
    end
    object miSaveList: TMenuItem
      Caption = 'Save model list...'
      OnClick = pbDownloadClick
    end
    object miSeparator: TMenuItem
      Caption = '-'
    end
    object miReloadModels: TMenuItem
      Caption = 'Reload models'
      OnClick = miReloadModelsClick
    end
    object miExportModels: TMenuItem
      Caption = 'Export models.csv...'
      OnClick = miExportModelsClick
    end
    object miSettings: TMenuItem
      Caption = 'Settings...'
      OnClick = miSettingsClick
    end
    object miSeparator2: TMenuItem
      Caption = '-'
    end
    object miExit: TMenuItem
      Caption = 'Exit'
      OnClick = miExitClick
    end
  end
end
