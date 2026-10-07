object frmMain2: TMain2Form
  Left = 0
  Top = 0
  Caption = 'Mobile Servicing Tools'
  ClientHeight = 680
  ClientWidth = 925
  Color = clBtnFace
  Constraints.MinHeight = 640
  Constraints.MinWidth = 900
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
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pbMenu: TPaintBox
    Left = 12
    Top = 5
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Menu'
    OnClick = pbMenuClick
    OnPaint = pbMenuPaint
  end
  object pbSettings: TPaintBox
    Left = 636
    Top = 5
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Settings'
    Anchors = [akTop, akRight]
    OnClick = pbSettingsClick
    OnPaint = pbSettingsPaint
  end
  object pbFacebook: TPaintBox
    Left = 686
    Top = 5
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Facebook'
    Anchors = [akTop, akRight]
    OnClick = pbFacebookClick
    OnPaint = pbFacebookPaint
  end
  object pbHelp: TPaintBox
    Left = 735
    Top = 5
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Help'
    Anchors = [akTop, akRight]
    OnClick = pbHelpClick
    OnPaint = pbHelpPaint
  end
  object pbChangeDevice: TPaintBox
    Left = 786
    Top = 5
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Change device'
    Anchors = [akTop, akRight]
    OnClick = pbChangeDeviceClick
    OnPaint = pbChangeDevicePaint
  end
  object pbDownload: TPaintBox
    Left = 836
    Top = 5
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Save log'
    Anchors = [akTop, akRight]
    OnClick = pbDownloadClick
    OnPaint = pbDownloadPaint
  end
  object pbNext: TPaintBox
    Left = 886
    Top = 5
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Start (runs the first job of the open tab)'
    Anchors = [akTop, akRight]
    OnClick = pbNextClick
    OnPaint = pbNextPaint
  end
  object pbProgress: TPaintBox
    Left = 8
    Top = 656
    Width = 514
    Height = 20
    Anchors = [akLeft, akRight, akBottom]
    OnPaint = pbProgressPaint
  end
  object grpPresets: TGroupBox
    Left = 8
    Top = 40
    Width = 514
    Height = 52
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Presets'
    TabOrder = 0
    object cbPresets: TComboBox
      Left = 7
      Top = 20
      Width = 498
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
    end
  end
  object grpFiles: TGroupBox
    Left = 8
    Top = 94
    Width = 514
    Height = 232
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Files'
    TabOrder = 1
    object btnScat: TButton
      Left = 7
      Top = 16
      Width = 58
      Height = 21
      Caption = 'SCAT'
      TabOrder = 0
      OnClick = btnScatClick
    end
    object edtScat: TEdit
      Left = 68
      Top = 16
      Width = 439
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 1
    end
    object btnAuth: TButton
      Left = 7
      Top = 39
      Width = 58
      Height = 21
      Caption = 'AUTH'
      TabOrder = 2
      OnClick = btnAuthClick
    end
    object edtAuth: TEdit
      Left = 68
      Top = 39
      Width = 439
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 3
    end
    object btnBin: TButton
      Left = 7
      Top = 62
      Width = 58
      Height = 21
      Hint = 'Tick "Advanced write" on the Flash tab to use a BIN file'
      Caption = 'BIN'
      TabOrder = 4
      OnClick = btnBinClick
    end
    object edtBin: TEdit
      Left = 68
      Top = 62
      Width = 439
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 5
    end
    object btnOfp: TButton
      Left = 7
      Top = 85
      Width = 58
      Height = 21
      Caption = 'OFP'
      TabOrder = 6
      OnClick = btnOfpClick
    end
    object edtOfp: TEdit
      Left = 68
      Top = 85
      Width = 439
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 7
    end
    object btnBl: TButton
      Left = 7
      Top = 108
      Width = 58
      Height = 21
      Caption = 'BL'
      TabOrder = 8
      OnClick = btnBlClick
    end
    object edtBl: TEdit
      Left = 68
      Top = 108
      Width = 439
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 9
    end
    object btnAp: TButton
      Left = 7
      Top = 131
      Width = 58
      Height = 21
      Caption = 'AP'
      TabOrder = 10
      OnClick = btnApClick
    end
    object edtAp: TEdit
      Left = 68
      Top = 131
      Width = 439
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 11
    end
    object btnCp: TButton
      Left = 7
      Top = 154
      Width = 58
      Height = 21
      Caption = 'CP'
      TabOrder = 12
      OnClick = btnCpClick
    end
    object edtCp: TEdit
      Left = 68
      Top = 154
      Width = 439
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 13
    end
    object btnCsc: TButton
      Left = 7
      Top = 177
      Width = 58
      Height = 21
      Caption = 'CSC'
      TabOrder = 14
      OnClick = btnCscClick
    end
    object edtCsc: TEdit
      Left = 68
      Top = 177
      Width = 439
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 15
    end
    object btnUser: TButton
      Left = 7
      Top = 200
      Width = 58
      Height = 21
      Caption = 'USER'
      TabOrder = 16
      OnClick = btnUserClick
    end
    object edtUser: TEdit
      Left = 68
      Top = 200
      Width = 439
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 17
    end
  end
  object grpLog: TGroupBox
    Left = 8
    Top = 328
    Width = 514
    Height = 324
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Log'
    TabOrder = 2
    object lstLog: TListBox
      Left = 2
      Top = 15
      Width = 510
      Height = 307
      Style = lbOwnerDrawFixed
      Align = alClient
      BorderStyle = bsNone
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ItemHeight = 15
      MultiSelect = True
      ParentFont = False
      PopupMenu = pmLog
      TabOrder = 0
      OnDrawItem = lstLogDrawItem
      OnKeyDown = lstLogKeyDown
    end
  end
  object pcJobs: TPageControl
    Left = 530
    Top = 40
    Width = 387
    Height = 584
    ActivePage = tsJobs
    Anchors = [akTop, akRight]
    Style = tsFlatButtons
    TabOrder = 3
    object tsJobs: TTabSheet
      Caption = 'Jobs'
      object grpConnections: TGroupBox
        Left = 4
        Top = 2
        Width = 371
        Height = 190
        Caption = 'Connections'
        TabOrder = 0
        object lblDownloadAgent: TLabel
          Left = 18
          Top = 14
          Width = 78
          Height = 13
          Caption = 'Download agent'
        end
        object lblUsbSpeed: TLabel
          Left = 18
          Top = 144
          Width = 51
          Height = 13
          Caption = 'USB Speed'
        end
        object lblBattery: TLabel
          Left = 174
          Top = 144
          Width = 36
          Height = 13
          Caption = 'Battery'
        end
        object cbDownloadAgent: TComboBox
          Left = 18
          Top = 30
          Width = 333
          Height = 21
          Style = csDropDownList
          Enabled = False
          ItemIndex = 0
          TabOrder = 0
          Items.Strings = (
            'MTK_AllInOne_DA.bin')
        end
        object chkAuthBrom: TCheckBox
          Left = 18
          Top = 54
          Width = 300
          Height = 17
          Caption = 'Advanced Authorization [BROM]'
          TabOrder = 1
        end
        object chkAuthPreloader: TCheckBox
          Left = 18
          Top = 72
          Width = 300
          Height = 17
          Caption = 'Advanced Authorization [Preloader]'
          Checked = True
          State = cbChecked
          TabOrder = 2
        end
        object chkForceBrom: TCheckBox
          Left = 18
          Top = 90
          Width = 300
          Height = 17
          Caption = 'Force BROM Mode'
          Enabled = False
          TabOrder = 3
        end
        object chkReadEmi: TCheckBox
          Left = 18
          Top = 108
          Width = 300
          Height = 17
          Caption = 'Read EMI from phone'
          Checked = True
          Enabled = False
          State = cbChecked
          TabOrder = 4
        end
        object chkReadPhoneInfo: TCheckBox
          Left = 18
          Top = 126
          Width = 300
          Height = 17
          Caption = 'Read Phone Info'
          Checked = True
          State = cbChecked
          TabOrder = 5
        end
        object cbUsbSpeed: TComboBox
          Left = 18
          Top = 159
          Width = 104
          Height = 21
          Style = csDropDownList
          ItemIndex = 0
          TabOrder = 6
          Items.Strings = (
            'High speed'
            'Full speed')
        end
        object cbBattery: TComboBox
          Left = 174
          Top = 159
          Width = 152
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
        Left = 4
        Top = 196
        Width = 371
        Height = 50
        Caption = 'Storage'
        TabOrder = 1
        object cbStorage: TComboBox
          Left = 12
          Top = 18
          Width = 347
          Height = 21
          Style = csDropDownList
          ItemIndex = 0
          TabOrder = 0
          Items.Strings = (
            'EMMC(USER) || UFS(LU2)'
            'EMMC(BOOT1) || UFS(LU0)'
            'EMMC(BOOT2) || UFS(LU1)'
            'EMMC(RPMB) || UFS(RPMB)')
        end
      end
      object pcOperations: TPageControl
        Left = 0
        Top = 250
        Width = 379
        Height = 300
        ActivePage = tsFlash
        Style = tsFlatButtons
        TabOrder = 2
        object tsFlash: TTabSheet
          Caption = 'Flash'
          object grpOptions: TGroupBox
            Left = 2
            Top = 2
            Width = 367
            Height = 262
            Caption = 'Options'
            TabOrder = 0
            object lblAddress: TLabel
              Left = 14
              Top = 139
              Width = 53
              Height = 13
              Caption = 'Address 0x'
            end
            object cbFlashMode: TComboBox
              Left = 14
              Top = 16
              Width = 335
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
              Left = 14
              Top = 42
              Width = 335
              Height = 32
              Caption = 'Write Firmware'
              Margin = 6
              Spacing = 14
              TabOrder = 1
              OnClick = btnWriteFirmwareClick
            end
            object btnRestoreBackup: TBitBtn
              Left = 14
              Top = 78
              Width = 335
              Height = 32
              Caption = 'Restore from backup'
              Margin = 6
              Spacing = 14
              TabOrder = 2
              OnClick = btnRestoreBackupClick
            end
            object chkAdvancedWrite: TCheckBox
              Left = 14
              Top = 116
              Width = 200
              Height = 17
              Caption = 'Advanced write'
              TabOrder = 3
              OnClick = chkAdvancedWriteClick
            end
            object edtAddress: TEdit
              Left = 74
              Top = 136
              Width = 124
              Height = 21
              Enabled = False
              TabOrder = 4
              Text = '00000000  00000000'
            end
            object btnWriteBin: TBitBtn
              Left = 14
              Top = 162
              Width = 335
              Height = 32
              Caption = 'Write BIN'
              Enabled = False
              Margin = 6
              Spacing = 14
              TabOrder = 5
              OnClick = btnWriteBinClick
            end
            object btnWriteOfp: TBitBtn
              Left = 14
              Top = 198
              Width = 335
              Height = 32
              Caption = 'Write OFP'
              Margin = 6
              Spacing = 14
              TabOrder = 6
              OnClick = btnWriteOfpClick
            end
          end
        end
        object tsRead: TTabSheet
          Caption = 'Read'
          ImageIndex = 1
          object grpReadOptions: TGroupBox
            Left = 2
            Top = 2
            Width = 367
            Height = 262
            Caption = 'Options'
            TabOrder = 0
            object lblReadAddress: TLabel
              Left = 14
              Top = 88
              Width = 53
              Height = 13
              Caption = 'Address 0x'
            end
            object lblReadSize: TLabel
              Left = 158
              Top = 88
              Width = 37
              Height = 13
              Caption = 'Size 0x'
            end
            object btnReadInfo: TBitBtn
              Left = 14
              Top = 16
              Width = 335
              Height = 32
              Caption = 'Read Flash Info'
              Margin = 6
              Spacing = 14
              TabOrder = 0
              OnClick = btnReadInfoClick
            end
            object btnReadPartitions: TBitBtn
              Left = 14
              Top = 52
              Width = 335
              Height = 32
              Caption = 'Read Partitions'
              Margin = 6
              Spacing = 14
              TabOrder = 1
              OnClick = btnReadPartitionsClick
            end
            object edtReadAddress: TEdit
              Left = 14
              Top = 104
              Width = 124
              Height = 21
              TabOrder = 2
              Text = '00000000  00000000'
            end
            object edtReadSize: TEdit
              Left = 158
              Top = 104
              Width = 124
              Height = 21
              TabOrder = 3
              Text = '00000000  00000000'
            end
            object btnReadBin: TBitBtn
              Left = 14
              Top = 132
              Width = 335
              Height = 32
              Caption = 'Read BIN'
              Margin = 6
              Spacing = 14
              TabOrder = 4
              OnClick = btnReadBinClick
            end
            object btnReadRegion: TBitBtn
              Left = 14
              Top = 168
              Width = 335
              Height = 32
              Caption = 'Read Region'
              Margin = 6
              Spacing = 14
              TabOrder = 5
              OnClick = btnReadRegionClick
            end
            object btnReadOtp: TBitBtn
              Left = 14
              Top = 204
              Width = 335
              Height = 32
              Caption = 'Read OTP'
              Margin = 6
              Spacing = 14
              TabOrder = 6
              OnClick = btnReadOtpClick
            end
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
        Width = 270
        Height = 13
        Caption = 'META mode options are not available yet.'
      end
    end
  end
  object pnlDeviceState: TPanel
    Left = 530
    Top = 630
    Width = 387
    Height = 44
    Anchors = [akRight, akBottom]
    BevelOuter = bvNone
    TabOrder = 4
    object lblDeviceState: TLabel
      Left = 0
      Top = 15
      Width = 347
      Height = 13
      Alignment = taRightJustify
      AutoSize = False
      Caption = 'No device'
    end
    object pbDeviceState: TPaintBox
      Left = 355
      Top = 8
      Width = 28
      Height = 28
      Hint = 'No device connected'
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
    object miSettings: TMenuItem
      Caption = 'Settings...'
      OnClick = pbSettingsClick
    end
    object miSeparator: TMenuItem
      Caption = '-'
    end
    object miExit: TMenuItem
      Caption = 'Exit'
      OnClick = miExitClick
    end
  end
  object pmLog: TPopupMenu
    Left = 640
    Top = 260
    object miLogCopy: TMenuItem
      Caption = 'Copy'
      OnClick = miLogCopyClick
    end
    object miLogCopyAll: TMenuItem
      Caption = 'Copy all'
      OnClick = miLogCopyAllClick
    end
    object miLogSelectAll: TMenuItem
      Caption = 'Select all'
      OnClick = miLogSelectAllClick
    end
    object miLogSeparator: TMenuItem
      Caption = '-'
    end
    object miLogSave: TMenuItem
      Caption = 'Save log...'
      OnClick = pbDownloadClick
    end
    object miLogClear: TMenuItem
      Caption = 'Clear log'
      OnClick = miClearLogClick
    end
  end
end
