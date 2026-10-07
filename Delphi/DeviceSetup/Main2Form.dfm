object frmMain2: TMain2Form
  Left = 0
  Top = 0
  Caption = 'Mobile Servicing Tools'
  ClientHeight = 543
  ClientWidth = 1157
  Color = clBtnFace
  Constraints.MinHeight = 560
  Constraints.MinWidth = 1000
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
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object pbMenu: TPaintBox
    Left = 4
    Top = 0
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Menu'
    OnClick = pbMenuClick
    OnPaint = pbMenuPaint
  end
  object pbNext: TPaintBox
    Left = 911
    Top = 0
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Start (Write Firmware)'
    Anchors = [akTop, akRight]
    OnClick = pbNextClick
    OnPaint = pbNextPaint
  end
  object pbDownload: TPaintBox
    Left = 952
    Top = 0
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Save log'
    Anchors = [akTop, akRight]
    OnClick = pbDownloadClick
    OnPaint = pbDownloadPaint
  end
  object pbChangeDevice: TPaintBox
    Left = 994
    Top = 0
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Change device'
    Anchors = [akTop, akRight]
    OnClick = pbChangeDeviceClick
    OnPaint = pbChangeDevicePaint
  end
  object pbSettings: TPaintBox
    Left = 1037
    Top = 0
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Settings'
    Anchors = [akTop, akRight]
    OnClick = pbSettingsClick
    OnPaint = pbSettingsPaint
  end
  object pbFacebook: TPaintBox
    Left = 1079
    Top = 0
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Facebook'
    Anchors = [akTop, akRight]
    OnClick = pbFacebookClick
    OnPaint = pbFacebookPaint
  end
  object pbHelp: TPaintBox
    Left = 1121
    Top = 0
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Help'
    Anchors = [akTop, akRight]
    OnClick = pbHelpClick
    OnPaint = pbHelpPaint
  end
  object lblPresets: TLabel
    Left = 7
    Top = 33
    Width = 38
    Height = 13
    Caption = 'Presets'
  end
  object bvlPresets: TBevel
    Left = 50
    Top = 40
    Width = 772
    Height = 2
    Anchors = [akLeft, akTop, akRight]
    Shape = bsTopLine
  end
  object lblFiles: TLabel
    Left = 7
    Top = 77
    Width = 24
    Height = 13
    Caption = 'Files'
  end
  object bvlFiles: TBevel
    Left = 36
    Top = 84
    Width = 786
    Height = 2
    Anchors = [akLeft, akTop, akRight]
    Shape = bsTopLine
  end
  object lblLog: TLabel
    Left = 7
    Top = 174
    Width = 17
    Height = 13
    Caption = 'Log'
  end
  object bvlLog: TBevel
    Left = 30
    Top = 181
    Width = 792
    Height = 2
    Anchors = [akLeft, akTop, akRight]
    Shape = bsTopLine
  end
  object pbProgress: TPaintBox
    Left = 8
    Top = 524
    Width = 1137
    Height = 14
    Anchors = [akLeft, akRight, akBottom]
    OnPaint = pbProgressPaint
  end
  object cbPresets: TComboBox
    Left = 8
    Top = 52
    Width = 807
    Height = 21
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    Enabled = False
    TabOrder = 0
  end
  object btnScat: TButton
    Left = 8
    Top = 92
    Width = 46
    Height = 18
    Caption = 'SCAT'
    TabOrder = 1
    OnClick = btnScatClick
  end
  object edtScat: TEdit
    Left = 58
    Top = 92
    Width = 758
    Height = 18
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    TabOrder = 2
  end
  object btnAuth: TButton
    Left = 8
    Top = 112
    Width = 46
    Height = 18
    Caption = 'AUTH'
    TabOrder = 3
    OnClick = btnAuthClick
  end
  object edtAuth: TEdit
    Left = 58
    Top = 112
    Width = 758
    Height = 18
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    TabOrder = 4
  end
  object btnBin: TButton
    Left = 8
    Top = 131
    Width = 46
    Height = 18
    Caption = 'BIN'
    Enabled = False
    TabOrder = 5
    OnClick = btnBinClick
  end
  object edtBin: TEdit
    Left = 58
    Top = 131
    Width = 758
    Height = 18
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Enabled = False
    TabOrder = 6
  end
  object btnOfp: TButton
    Left = 8
    Top = 151
    Width = 46
    Height = 18
    Caption = 'OFP'
    TabOrder = 7
    OnClick = btnOfpClick
  end
  object edtOfp: TEdit
    Left = 58
    Top = 151
    Width = 758
    Height = 18
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    TabOrder = 8
  end
  object memLog: TMemo
    Left = 0
    Top = 189
    Width = 822
    Height = 330
    Anchors = [akLeft, akTop, akRight, akBottom]
    BorderStyle = bsNone
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 9
  end
  object pcJobs: TPageControl
    Left = 830
    Top = 33
    Width = 304
    Height = 472
    ActivePage = tsJobs
    Anchors = [akTop, akRight]
    Style = tsFlatButtons
    TabOrder = 10
    object tsJobs: TTabSheet
      Caption = 'Jobs'
      object grpConnections: TGroupBox
        Left = 2
        Top = 4
        Width = 290
        Height = 157
        Caption = 'Connections'
        TabOrder = 0
        object lblDownloadAgent: TLabel
          Left = 12
          Top = 16
          Width = 79
          Height = 13
          Caption = 'Download agent'
        end
        object lblUsbSpeed: TLabel
          Left = 12
          Top = 124
          Width = 51
          Height = 13
          Caption = 'USB Speed'
        end
        object lblBattery: TLabel
          Left = 144
          Top = 124
          Width = 37
          Height = 13
          Caption = 'Battery'
        end
        object cbDownloadAgent: TComboBox
          Left = 12
          Top = 29
          Width = 264
          Height = 21
          Style = csDropDownList
          Enabled = False
          ItemIndex = 0
          TabOrder = 0
          Items.Strings = (
            'MTK_AllInOne_DA.bin')
        end
        object chkAuthBrom: TCheckBox
          Left = 12
          Top = 50
          Width = 264
          Height = 15
          Caption = 'Advanced Authorization [BROM]'
          Checked = True
          State = cbChecked
          TabOrder = 1
        end
        object chkAuthPreloader: TCheckBox
          Left = 12
          Top = 65
          Width = 264
          Height = 15
          Caption = 'Advanced Authorization [Preloader]'
          Enabled = False
          TabOrder = 2
        end
        object chkForceBrom: TCheckBox
          Left = 12
          Top = 80
          Width = 264
          Height = 15
          Caption = 'Force BROM Mode'
          Checked = True
          State = cbChecked
          TabOrder = 3
        end
        object chkReadEmi: TCheckBox
          Left = 12
          Top = 95
          Width = 264
          Height = 15
          Caption = 'Read EMI from phone'
          Checked = True
          State = cbChecked
          TabOrder = 4
        end
        object chkReadPhoneInfo: TCheckBox
          Left = 12
          Top = 110
          Width = 264
          Height = 15
          Caption = 'Read Phone Info'
          Checked = True
          State = cbChecked
          TabOrder = 5
        end
        object cbUsbSpeed: TComboBox
          Left = 12
          Top = 137
          Width = 90
          Height = 21
          Style = csDropDownList
          ItemIndex = 0
          TabOrder = 6
          Items.Strings = (
            'High speed'
            'Full speed')
        end
        object cbBattery: TComboBox
          Left = 144
          Top = 137
          Width = 132
          Height = 21
          Style = csDropDownList
          ItemIndex = 0
          TabOrder = 7
          Items.Strings = (
            'With battery'
            'Without battery'
            'Auto detect')
        end
      end
      object grpStorage: TGroupBox
        Left = 2
        Top = 163
        Width = 290
        Height = 52
        Caption = 'Storage'
        TabOrder = 1
        object lblStorageType: TLabel
          Left = 12
          Top = 12
          Width = 24
          Height = 13
          Caption = 'Type'
        end
        object lblRegion: TLabel
          Left = 144
          Top = 12
          Width = 33
          Height = 13
          Caption = 'Region'
        end
        object cbStorageType: TComboBox
          Left = 12
          Top = 25
          Width = 90
          Height = 21
          Style = csDropDownList
          ItemIndex = 0
          TabOrder = 0
          OnChange = cbStorageTypeChange
          Items.Strings = (
            'EMMC'
            'UFS')
        end
        object cbRegion: TComboBox
          Left = 144
          Top = 25
          Width = 132
          Height = 21
          Style = csDropDownList
          TabOrder = 1
        end
      end
      object pcOperations: TPageControl
        Left = 0
        Top = 219
        Width = 296
        Height = 225
        ActivePage = tsFlash
        Style = tsFlatButtons
        TabOrder = 2
        object tsFlash: TTabSheet
          Caption = 'Flash'
          object grpOptions: TGroupBox
            Left = 2
            Top = 2
            Width = 286
            Height = 200
            Caption = 'Options'
            TabOrder = 0
            object lblAddress: TLabel
              Left = 12
              Top = 119
              Width = 51
              Height = 13
              Caption = 'Address 0x'
            end
            object cbFlashMode: TComboBox
              Left = 12
              Top = 17
              Width = 264
              Height = 21
              Style = csDropDownList
              ItemIndex = 0
              TabOrder = 0
              Items.Strings = (
                'Download only'
                'Firmware upgrade'
                'Format all + Download')
            end
            object btnWriteFirmware: TBitBtn
              Left = 12
              Top = 40
              Width = 264
              Height = 27
              Caption = 'Write Firmware'
              Margin = 2
              Spacing = 14
              TabOrder = 1
              OnClick = btnWriteFirmwareClick
            end
            object btnRestoreBackup: TBitBtn
              Left = 12
              Top = 71
              Width = 264
              Height = 27
              Caption = 'Restore from backup'
              Margin = 2
              Spacing = 14
              TabOrder = 2
              OnClick = btnRestoreBackupClick
            end
            object chkAdvancedWrite: TCheckBox
              Left = 12
              Top = 101
              Width = 264
              Height = 15
              Caption = 'Advanced write'
              TabOrder = 3
              OnClick = chkAdvancedWriteClick
            end
            object edtAddress: TEdit
              Left = 64
              Top = 117
              Width = 106
              Height = 18
              AutoSize = False
              Enabled = False
              TabOrder = 4
              Text = '00000000  00000000'
            end
            object btnWriteBin: TBitBtn
              Left = 12
              Top = 141
              Width = 264
              Height = 27
              Caption = 'Write BIN'
              Enabled = False
              Margin = 2
              Spacing = 14
              TabOrder = 5
              OnClick = btnWriteBinClick
            end
            object btnWriteOfp: TBitBtn
              Left = 12
              Top = 171
              Width = 264
              Height = 27
              Caption = 'Write OFP'
              Margin = 2
              Spacing = 14
              TabOrder = 6
              OnClick = btnWriteOfpClick
            end
          end
        end
        object tsRead: TTabSheet
          Caption = 'Read'
          ImageIndex = 1
          object lblReadInfo: TLabel
            Left = 8
            Top = 8
            Width = 270
            Height = 13
            Caption = 'Read options are not available yet.'
          end
        end
        object tsFormat: TTabSheet
          Caption = 'Format'
          ImageIndex = 2
          object lblFormatInfo: TLabel
            Left = 8
            Top = 8
            Width = 270
            Height = 13
            Caption = 'Format options are not available yet.'
          end
        end
        object tsImei: TTabSheet
          Caption = 'IMEI'
          ImageIndex = 3
          object lblImeiInfo: TLabel
            Left = 8
            Top = 8
            Width = 270
            Height = 13
            Caption = 'IMEI options are not available yet.'
          end
        end
        object tsLocks: TTabSheet
          Caption = 'Locks'
          ImageIndex = 4
          object lblLocksInfo: TLabel
            Left = 8
            Top = 8
            Width = 270
            Height = 13
            Caption = 'Lock options are not available yet.'
          end
        end
        object tsService: TTabSheet
          Caption = 'Service'
          ImageIndex = 5
          object lblServiceInfo: TLabel
            Left = 8
            Top = 8
            Width = 270
            Height = 13
            Caption = 'Service options are not available yet.'
          end
        end
        object tsRpmb: TTabSheet
          Caption = 'RPMB'
          ImageIndex = 6
          object lblRpmbInfo: TLabel
            Left = 8
            Top = 8
            Width = 270
            Height = 13
            Caption = 'RPMB options are not available yet.'
          end
        end
      end
    end
    object tsMeta: TTabSheet
      Caption = 'META'
      ImageIndex = 1
      object lblMetaInfo: TLabel
        Left = 8
        Top = 8
        Width = 280
        Height = 13
        Caption = 'META mode options are not available yet.'
      end
    end
  end
  object pnlDeviceState: TPanel
    Left = 1112
    Top = 474
    Width = 24
    Height = 32
    Anchors = [akTop, akRight]
    BevelOuter = bvNone
    Color = clBtnFace
    ParentBackground = False
    TabOrder = 11
    object pbDeviceState: TPaintBox
      Left = 0
      Top = 0
      Width = 24
      Height = 32
      Hint = 'No device connected'
      Align = alClient
      OnPaint = pbDeviceStatePaint
    end
  end
  object pmMain: TPopupMenu
    Left = 600
    Top = 260
    object miChangeDevice: TMenuItem
      Caption = 'Change device...'
      OnClick = pbChangeDeviceClick
    end
    object miSaveLog: TMenuItem
      Caption = 'Save log...'
      OnClick = pbDownloadClick
    end
    object miClearLog: TMenuItem
      Caption = 'Clear log'
      OnClick = miClearLogClick
    end
    object miSeparator: TMenuItem
      Caption = '-'
    end
    object miExit: TMenuItem
      Caption = 'Exit'
      OnClick = miExitClick
    end
  end
end
