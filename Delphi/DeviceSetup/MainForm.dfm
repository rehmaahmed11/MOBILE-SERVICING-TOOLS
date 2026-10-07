object frmMain: TMainForm
  Left = 0
  Top = 0
  Caption = 'Mobile Servicing Tools'
  ClientHeight = 575
  ClientWidth = 1023
  Color = 15790320
  Constraints.MinHeight = 430
  Constraints.MinWidth = 780
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  ShowHint = True
  ActiveControl = cbSearch
  OnCreate = FormCreate
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object pbMenu: TPaintBox
    Left = 12
    Top = 3
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Menu'
    OnClick = pbMenuClick
    OnPaint = pbMenuPaint
  end
  object pbNext: TPaintBox
    Left = 730
    Top = 3
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Next (opens the job screen for the selected model)'
    Anchors = [akTop, akRight]
    OnClick = pbNextClick
    OnPaint = pbNextPaint
  end
  object pbDownload: TPaintBox
    Left = 772
    Top = 3
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Save model list'
    Anchors = [akTop, akRight]
    OnClick = pbDownloadClick
    OnPaint = pbDownloadPaint
  end
  object pbReload: TPaintBox
    Left = 812
    Top = 3
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Reload models'
    Anchors = [akTop, akRight]
    OnClick = pbReloadClick
    OnPaint = pbReloadPaint
  end
  object pbSettings: TPaintBox
    Left = 856
    Top = 3
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Settings'
    Anchors = [akTop, akRight]
    OnClick = pbSettingsClick
    OnPaint = pbSettingsPaint
  end
  object pbContact: TPaintBox
    Left = 902
    Top = 3
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Report a problem'
    Anchors = [akTop, akRight]
    OnClick = pbContactClick
    OnPaint = pbContactPaint
  end
  object pbFacebook: TPaintBox
    Left = 948
    Top = 3
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Facebook'
    Anchors = [akTop, akRight]
    OnClick = pbFacebookClick
    OnPaint = pbFacebookPaint
  end
  object pbHelp: TPaintBox
    Left = 992
    Top = 3
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Help'
    Anchors = [akTop, akRight]
    OnClick = pbHelpClick
    OnPaint = pbHelpPaint
  end
  object pbLogo: TPaintBox
    Left = 432
    Top = 47
    Width = 583
    Height = 468
    Anchors = [akLeft, akTop, akRight, akBottom]
    OnPaint = pbLogoPaint
  end
  object cbSearch: TComboBox
    Left = 2
    Top = 36
    Width = 421
    Height = 23
    TabOrder = 0
    Text = 'Quick search'
    OnChange = cbSearchChange
    OnEnter = cbSearchEnter
    OnExit = cbSearchExit
    OnKeyDown = cbSearchKeyDown
  end
  object lstBrands: TListBox
    Left = 2
    Top = 62
    Width = 128
    Height = 456
    Anchors = [akLeft, akTop, akBottom]
    ItemHeight = 14
    TabOrder = 1
    OnClick = lstBrandsClick
  end
  object lstModels: TListBox
    Left = 135
    Top = 62
    Width = 288
    Height = 456
    Anchors = [akLeft, akTop, akBottom]
    ItemHeight = 14
    TabOrder = 2
    OnClick = lstModelsClick
    OnDblClick = lstModelsDblClick
    OnKeyDown = lstModelsKeyDown
  end
  object btnSelect: TBitBtn
    Left = 2
    Top = 524
    Width = 421
    Height = 30
    Anchors = [akLeft, akBottom]
    Caption = 'Select'
    Margin = 12
    Spacing = 10
    TabOrder = 3
    OnClick = pbNextClick
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
      OnClick = pbReloadClick
    end
    object miExportModels: TMenuItem
      Caption = 'Export models.csv...'
      OnClick = miExportModelsClick
    end
    object miSettings: TMenuItem
      Caption = 'Settings...'
      OnClick = pbSettingsClick
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
