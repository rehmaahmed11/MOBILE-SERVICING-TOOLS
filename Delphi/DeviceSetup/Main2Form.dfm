object frmMain2: TMain2Form
  Left = 0
  Top = 0
  Caption = 'Mobile Servicing Tools'
  ClientHeight = 585
  ClientWidth = 1026
  Color = 15790320
  Constraints.MinHeight = 560
  Constraints.MinWidth = 980
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -10
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
  TextHeight = 15
  OnResize = FormResize
  object pbMenu: TPaintBox
    Left = 7
    Top = 0
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Menu'
    OnClick = pbMenuClick
    OnPaint = pbMenuPaint
  end
  object pbNext: TPaintBox
    Left = 727
    Top = 0
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Start (runs the first job of the open tab)'
    Anchors = [akTop, akRight]
    OnClick = pbNextClick
    OnPaint = pbNextPaint
  end
  object pbDownload: TPaintBox
    Left = 771
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
    Left = 814
    Top = 0
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Change device (back to the model list)'
    Anchors = [akTop, akRight]
    OnClick = pbChangeDeviceClick
    OnPaint = pbChangeDevicePaint
  end
  object pbSettings: TPaintBox
    Left = 858
    Top = 0
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
    Top = 0
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Report a problem'
    Anchors = [akTop, akRight]
    OnClick = pbContactClick
    OnPaint = pbContactPaint
  end
  object pbFacebook: TPaintBox
    Left = 946
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
    Left = 990
    Top = 0
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Help'
    Anchors = [akTop, akRight]
    OnClick = pbHelpClick
    OnPaint = pbHelpPaint
  end
  object grpPresets: TSampleGroupBox
    Left = 3
    Top = 36
    Width = 661
    Height = 45
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Presets'
    TabOrder = 0
    CaptionInset = 6
    object cbPresets: TComboBox
      Left = 7
      Top = 18
      Width = 648
      Height = 18
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
    end
  end
  object grpFiles: TSampleGroupBox
    Left = 3
    Top = 82
    Width = 661
    Height = 98
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Files'
    TabOrder = 1
    CaptionInset = 6
    object btnScat: TSampleButton
      Left = 7
      Top = 14
      Width = 47
      Height = 18
      Caption = 'SCAT'
      TabOrder = 0
      OnClick = btnScatClick
      Margin = 2
      Spacing = 8
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ReferenceHeight = 18
    end
    object edtScat: TEdit
      Left = 55
      Top = 14
      Width = 600
      Height = 18
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 1
      AutoSize = False
    end
    object btnAuth: TSampleButton
      Left = 7
      Top = 35
      Width = 47
      Height = 18
      Caption = 'AUTH'
      TabOrder = 2
      OnClick = btnAuthClick
      Margin = 2
      Spacing = 8
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ReferenceHeight = 18
    end
    object edtAuth: TEdit
      Left = 55
      Top = 35
      Width = 600
      Height = 18
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 3
      AutoSize = False
    end
    object btnBin: TSampleButton
      Left = 7
      Top = 56
      Width = 47
      Height = 18
      Hint = 'Tick "Advanced write" on the Flash tab to use a BIN file'
      Caption = 'BIN'
      TabOrder = 4
      OnClick = btnBinClick
      Margin = 2
      Spacing = 8
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ReferenceHeight = 18
    end
    object edtBin: TEdit
      Left = 55
      Top = 56
      Width = 600
      Height = 18
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 5
      AutoSize = False
    end
    object btnOfp: TSampleButton
      Left = 7
      Top = 77
      Width = 47
      Height = 18
      Caption = 'OFP'
      TabOrder = 6
      OnClick = btnOfpClick
      Margin = 2
      Spacing = 8
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ReferenceHeight = 18
    end
    object edtOfp: TEdit
      Left = 55
      Top = 77
      Width = 600
      Height = 18
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 7
      AutoSize = False
    end
    object btnBl: TSampleButton
      Left = 7
      Top = 98
      Width = 47
      Height = 18
      Caption = 'BL'
      TabOrder = 8
      OnClick = btnBlClick
      Margin = 2
      Spacing = 8
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ReferenceHeight = 18
    end
    object edtBl: TEdit
      Left = 55
      Top = 98
      Width = 600
      Height = 18
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 9
      AutoSize = False
    end
    object btnAp: TSampleButton
      Left = 7
      Top = 119
      Width = 47
      Height = 18
      Caption = 'AP'
      TabOrder = 10
      OnClick = btnApClick
      Margin = 2
      Spacing = 8
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ReferenceHeight = 18
    end
    object edtAp: TEdit
      Left = 55
      Top = 119
      Width = 600
      Height = 18
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 11
      AutoSize = False
    end
    object btnCp: TSampleButton
      Left = 7
      Top = 140
      Width = 47
      Height = 18
      Caption = 'CP'
      TabOrder = 12
      OnClick = btnCpClick
      Margin = 2
      Spacing = 8
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ReferenceHeight = 18
    end
    object edtCp: TEdit
      Left = 55
      Top = 140
      Width = 600
      Height = 18
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 13
      AutoSize = False
    end
    object btnCsc: TSampleButton
      Left = 7
      Top = 161
      Width = 47
      Height = 18
      Caption = 'CSC'
      TabOrder = 14
      OnClick = btnCscClick
      Margin = 2
      Spacing = 8
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ReferenceHeight = 18
    end
    object edtCsc: TEdit
      Left = 55
      Top = 161
      Width = 600
      Height = 18
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 15
      AutoSize = False
    end
    object btnUser: TSampleButton
      Left = 7
      Top = 182
      Width = 47
      Height = 18
      Caption = 'USER'
      TabOrder = 16
      OnClick = btnUserClick
      Margin = 2
      Spacing = 8
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ReferenceHeight = 18
    end
    object edtUser: TEdit
      Left = 55
      Top = 182
      Width = 600
      Height = 18
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 17
      AutoSize = False
    end
  end
  object grpLog: TSampleGroupBox
    Left = 3
    Top = 183
    Width = 661
    Height = 379
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Log'
    TabOrder = 2
    CaptionInset = 6
    object lstLog: TListBox
      Left = 4
      Top = 13
      Width = 650
      Height = 362
      Style = lbOwnerDrawFixed
      BorderStyle = bsNone
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Consolas'
      Font.Style = []
      ItemHeight = 15
      MultiSelect = True
      ParentFont = False
      PopupMenu = pmLog
      TabOrder = 0
      OnDrawItem = lstLogDrawItem
      OnKeyDown = lstLogKeyDown
      Anchors = [akLeft, akTop, akRight, akBottom]
    end
  end
  object pbProgress: TPaintBox
    Left = 3
    Top = 566
    Width = 661
    Height = 17
    Anchors = [akLeft, akRight, akBottom]
    OnPaint = pbProgressPaint
  end
  object pcJobs: TSamplePageControl
    Left = 672
    Top = 37
    Width = 337
    Height = 526
    ActivePage = tsJobs
    Anchors = [akTop, akRight, akBottom]
    TabOrder = 3
    object tsJobs: TSampleTabSheet
      Caption = 'Jobs'
      object grpConnections: TSampleGroupBox
        Left = 8
        Top = 3
        Width = 328
        Height = 190
        Caption = 'Connections'
        TabOrder = 0
        Anchors = [akLeft, akTop, akRight]
        object lblDownloadAgent: TLabel
          Left = 8
          Top = 18
          Width = 90
          Height = 13
          Caption = 'Download agent'
        end
        object cbDownloadAgent: TComboBox
          Left = 106
          Top = 16
          Width = 208
          Height = 18
          Style = csDropDownList
          Enabled = False
          TabOrder = 0
          Items.Strings = (
          'MTK_AllInOne_DA.bin')
          ItemIndex = 0
        end
        object chkAuthBrom: TCheckBox
          Left = 8
          Top = 37
          Width = 306
          Height = 16
          Caption = 'Advanced Authorization [BROM]'
          TabOrder = 1
          Checked = True
          State = cbChecked
        end
        object chkAuthPreloader: TCheckBox
          Left = 8
          Top = 53
          Width = 306
          Height = 16
          Caption = 'Advanced Authorization [Preloader]'
          TabOrder = 2
        end
        object chkForceBrom: TCheckBox
          Left = 8
          Top = 69
          Width = 306
          Height = 16
          Caption = 'Force BROM Mode'
          Enabled = True
          TabOrder = 3
        end
        object chkReadEmi: TCheckBox
          Left = 8
          Top = 85
          Width = 306
          Height = 16
          Caption = 'Read EMI from phone'
          Checked = True
          Enabled = True
          State = cbChecked
          TabOrder = 4
        end
        object chkReadPhoneInfo: TCheckBox
          Left = 8
          Top = 101
          Width = 306
          Height = 16
          Caption = 'Read Phone Info'
          Checked = True
          State = cbChecked
          TabOrder = 5
        end
        object lblUsbSpeed: TLabel
          Left = 8
          Top = 122
          Width = 90
          Height = 13
          Caption = 'USB Speed'
        end
        object cbUsbSpeed: TComboBox
          Left = 106
          Top = 118
          Width = 208
          Height = 18
          Style = csDropDownList
          TabOrder = 6
          Items.Strings = (
          'High speed'
          'Full speed')
          ItemIndex = 0
        end
        object lblBattery: TLabel
          Left = 8
          Top = 144
          Width = 90
          Height = 13
          Caption = 'Battery'
        end
        object cbBattery: TComboBox
          Left = 106
          Top = 140
          Width = 208
          Height = 18
          Style = csDropDownList
          TabOrder = 7
          Items.Strings = (
          'With battery'
          'Without battery'
          'Auto detect')
          ItemIndex = 0
        end
        object lblStorage: TLabel
          Left = 8
          Top = 166
          Width = 90
          Height = 13
          Caption = 'Storage'
        end
        object cbStorage: TComboBox
          Left = 106
          Top = 162
          Width = 208
          Height = 18
          Style = csDropDownList
          TabOrder = 8
          Items.Strings = (
          'EMMC(USER) || UFS(LU2)'
          'EMMC(BOOT1) || UFS(LU0)'
          'EMMC(BOOT2) || UFS(LU1)'
          'EMMC(RPMB) || UFS(RPMB)')
          ItemIndex = 0
        end
      end
      object pcOperations: TSamplePageControl
        Left = 0
        Top = 201
        Width = 337
        Height = 305
        ActivePage = tsFlash
        TabOrder = 1
        Anchors = [akLeft, akTop, akRight, akBottom]
        TabWidth = 47
        object tsFlash: TSampleTabSheet
          Caption = 'Flash'
          object grpOptionsFlash: TSampleGroupBox
            Left = 8
            Top = 3
            Width = 328
            Height = 226
            Caption = 'Options'
            Anchors = [akLeft, akTop, akRight]
            TabOrder = 0
            CaptionInset = 6
            object cbFlashMode: TComboBox
              Left = 14
              Top = 17
              Width = 300
              Height = 18
              Style = csDropDownList
              TabOrder = 0
              Items.Strings = (
              'Download only'
              'Upgrade'
              'Format all + download')
              ItemIndex = 0
            end
            object btnWriteFirmware: TSampleButton
              Left = 14
              Top = 38
              Width = 300
              Height = 34
              Caption = 'Write Firmware'
              Margin = 2
              Spacing = 8
              TabOrder = 1
              OnClick = btnWriteFirmwareClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnRestoreBackup: TSampleButton
              Left = 14
              Top = 74
              Width = 300
              Height = 34
              Caption = 'Restore from backup'
              Margin = 2
              Spacing = 8
              TabOrder = 2
              OnClick = btnRestoreBackupClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object chkAdvancedWrite: TCheckBox
              Left = 14
              Top = 110
              Width = 200
              Height = 17
              Caption = 'Advanced write'
              TabOrder = 3
              OnClick = chkAdvancedWriteClick
            end
            object lblAddress: TLabel
              Left = 14
              Top = 129
              Width = 53
              Height = 13
              Caption = 'Address 0x'
            end
            object edtAddress: TEdit
              Left = 68
              Top = 127
              Width = 101
              Height = 18
              Enabled = False
              TabOrder = 4
              Text = '00000000  00000000'
              AutoSize = False
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnWriteBin: TSampleButton
              Left = 14
              Top = 150
              Width = 300
              Height = 34
              Caption = 'Write BIN'
              Enabled = False
              Margin = 2
              Spacing = 8
              TabOrder = 5
              OnClick = btnWriteBinClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnWriteOfp: TSampleButton
              Left = 14
              Top = 186
              Width = 300
              Height = 34
              Caption = 'Write OFP'
              Margin = 2
              Spacing = 8
              TabOrder = 6
              OnClick = btnWriteOfpClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
          end
        end
        object tsRead: TSampleTabSheet
          Caption = 'Read'
          ImageIndex = 1
          object grpOptionsRead: TSampleGroupBox
            Left = 8
            Top = 3
            Width = 328
            Height = 242
            Caption = 'Options'
            Anchors = [akLeft, akTop, akRight]
            TabOrder = 0
            CaptionInset = 6
            object btnReadInfo: TSampleButton
              Left = 14
              Top = 18
              Width = 300
              Height = 34
              Caption = 'Read Flash info'
              Margin = 2
              Spacing = 8
              TabOrder = 0
              OnClick = btnReadInfoClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnReadPartitions: TSampleButton
              Left = 14
              Top = 54
              Width = 300
              Height = 34
              Caption = 'Read Partitions'
              Margin = 2
              Spacing = 8
              TabOrder = 1
              OnClick = btnReadPartitionsClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object lblReadAddress: TLabel
              Left = 14
              Top = 92
              Width = 80
              Height = 13
              Caption = 'Address 0x'
            end
            object edtReadAddress: TEdit
              Left = 14
              Top = 106
              Width = 100
              Height = 18
              TabOrder = 2
              Text = '00000000  00000000'
              AutoSize = False
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object lblReadSize: TLabel
              Left = 141
              Top = 92
              Width = 50
              Height = 13
              Caption = 'Size 0x'
            end
            object edtReadSize: TEdit
              Left = 141
              Top = 106
              Width = 100
              Height = 18
              TabOrder = 3
              Text = '00000000  00000000'
              AutoSize = False
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnReadBin: TSampleButton
              Left = 14
              Top = 130
              Width = 300
              Height = 34
              Caption = 'Read BIN'
              Margin = 2
              Spacing = 8
              TabOrder = 4
              OnClick = btnReadBinClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnReadRegion: TSampleButton
              Left = 14
              Top = 166
              Width = 300
              Height = 34
              Caption = 'Read Region'
              Margin = 2
              Spacing = 8
              TabOrder = 5
              OnClick = btnReadRegionClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnReadOtp: TSampleButton
              Left = 14
              Top = 202
              Width = 300
              Height = 34
              Caption = 'Read OTP'
              Margin = 2
              Spacing = 8
              TabOrder = 6
              OnClick = btnReadOtpClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
          end
        end
        object tsFormat: TSampleTabSheet
          Caption = 'Format'
          ImageIndex = 2
          object grpOptionsFormat: TSampleGroupBox
            Left = 8
            Top = 3
            Width = 328
            Height = 284
            Caption = 'Options'
            Anchors = [akLeft, akTop, akRight]
            TabOrder = 0
            CaptionInset = 6
            object pnlFormatRange: TPanel
              Left = 28
              Top = 39
              Width = 286
              Height = 40
              BevelOuter = bvNone
              Color = 15790320
              TabOrder = 1
              object rbFormatAiFlash: TRadioButton
                Left = 0
                Top = 0
                Width = 230
                Height = 17
                Caption = 'Format All Flash'
                Checked = True
                TabOrder = 2
              end
              object rbFormatAiExceptBootloader: TRadioButton
                Left = 0
                Top = 20
                Width = 270
                Height = 17
                Caption = 'Format All Except Bootloader'
                TabOrder = 3
              end
            end
            object pnlFormatMode: TPanel
              Left = 14
              Top = 14
              Width = 300
              Height = 20
              BevelOuter = bvNone
              Color = 15790320
              TabOrder = 0
              object rbAutoFormat: TRadioButton
                Left = 0
                Top = 0
                Width = 112
                Height = 17
                Caption = 'Auto Format'
                Checked = True
                TabOrder = 0
              end
              object rbManualFormat: TRadioButton
                Left = 116
                Top = 0
                Width = 165
                Height = 17
                Caption = 'Manual Format'
                TabOrder = 1
              end
            end
            object btnFormat: TSampleButton
              Left = 14
              Top = 80
              Width = 300
              Height = 34
              Caption = 'Format'
              Margin = 2
              Spacing = 8
              TabOrder = 4
              OnClick = btnFormatClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object chkCreateDefaultFs: TCheckBox
              Left = 14
              Top = 116
              Width = 250
              Height = 17
              Caption = 'Create Default FS'
              TabOrder = 5
            end
            object btnWipeData: TSampleButton
              Left = 14
              Top = 134
              Width = 300
              Height = 34
              Caption = 'Wipe Data'
              Margin = 2
              Spacing = 8
              TabOrder = 6
              OnClick = btnWipeDataClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnWipePartitions: TSampleButton
              Left = 14
              Top = 170
              Width = 300
              Height = 34
              Caption = 'Wipe Partitions'
              Margin = 2
              Spacing = 8
              TabOrder = 7
              OnClick = btnWipePartitionsClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnEraseFrp: TSampleButton
              Left = 14
              Top = 206
              Width = 300
              Height = 34
              Caption = 'Erase FRP'
              Margin = 2
              Spacing = 8
              TabOrder = 8
              OnClick = btnEraseFrpClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnEraseFrpAndWipe: TSampleButton
              Left = 14
              Top = 242
              Width = 300
              Height = 34
              Caption = 'Erase FRP and Wipe'
              Margin = 2
              Spacing = 8
              TabOrder = 9
              OnClick = btnEraseFrpAndWipeClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
          end
        end
        object tsImei: TSampleTabSheet
          Caption = 'IMEI'
          ImageIndex = 3
          object grpOptionsImei: TSampleGroupBox
            Left = 8
            Top = 3
            Width = 328
            Height = 152
            Caption = 'Options'
            Anchors = [akLeft, akTop, akRight]
            TabOrder = 0
            CaptionInset = 6
            object chkImei1: TCheckBox
              Left = 14
              Top = 14
              Width = 48
              Height = 17
              Caption = 'IMEI1'
              Checked = True
              State = cbChecked
              TabOrder = 0
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -11
              Font.Name = 'Times New Roman'
              Font.Style = []
              ParentFont = False
            end
            object edtImei1: TEdit
              Left = 62
              Top = 16
              Width = 86
              Height = 18
              TabOrder = 1
              Text = '35646019030487'
              AutoSize = False
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -11
              Font.Name = 'Times New Roman'
              Font.Style = []
              ParentFont = False
            end
            object lblImei1Digits: TLabel
              Left = 153
              Top = 16
              Width = 13
              Height = 18
              Caption = '9'
              AutoSize = False
              Color = clWhite
              Transparent = False
              Alignment = taCenter
              Layout = tlCenter
              Font.Color = clGrayText
              ParentFont = False
            end
            object chkImei2: TCheckBox
              Left = 14
              Top = 36
              Width = 48
              Height = 17
              Caption = 'IMEI2'
              Checked = True
              State = cbChecked
              TabOrder = 2
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -11
              Font.Name = 'Times New Roman'
              Font.Style = []
              ParentFont = False
            end
            object edtImei2: TEdit
              Left = 62
              Top = 38
              Width = 86
              Height = 18
              TabOrder = 3
              Text = '35646019110987'
              AutoSize = False
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -11
              Font.Name = 'Times New Roman'
              Font.Style = []
              ParentFont = False
            end
            object lblImei2Digits: TLabel
              Left = 153
              Top = 38
              Width = 13
              Height = 18
              Caption = '1'
              AutoSize = False
              Color = clWhite
              Transparent = False
              Alignment = taCenter
              Layout = tlCenter
              Font.Color = clGrayText
              ParentFont = False
            end
            object lblAdvancedSettings: TLabel
              Left = 14
              Top = 62
              Width = 110
              Height = 13
              Cursor = crHandPoint
              Caption = 'Advanced settings'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = 8804864
              Font.Height = -10
              Font.Name = 'Tahoma'
              Font.Style = [fsBold, fsUnderline]
              ParentFont = False
              OnClick = lblAdvancedSettingsClick
            end
            object btnRepair: TSampleButton
              Left = 14
              Top = 77
              Width = 300
              Height = 34
              Caption = 'Repair'
              Margin = 2
              Spacing = 8
              TabOrder = 4
              OnClick = btnRepairClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnReadImei: TSampleButton
              Left = 14
              Top = 113
              Width = 300
              Height = 34
              Caption = 'Read IMEI'
              Margin = 2
              Spacing = 8
              TabOrder = 5
              OnClick = btnReadImeiClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
          end
        end
        object tsLocks: TSampleTabSheet
          Caption = 'Locks'
          ImageIndex = 4
          object grpOptionsLocks: TSampleGroupBox
            Left = 8
            Top = 3
            Width = 328
            Height = 240
            Caption = 'Options'
            Anchors = [akLeft, akTop, akRight]
            TabOrder = 0
            CaptionInset = 6
            object btnUnlockBootloader: TSampleButton
              Left = 14
              Top = 18
              Width = 300
              Height = 34
              Caption = 'Unlock Bootloader'
              Margin = 2
              Spacing = 8
              TabOrder = 0
              OnClick = btnUnlockBootloaderClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnRelockBootloader: TSampleButton
              Left = 14
              Top = 54
              Width = 300
              Height = 34
              Caption = 'Relock Bootloader'
              Margin = 2
              Spacing = 8
              TabOrder = 1
              OnClick = btnRelockBootloaderClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnUnlockNetwork: TSampleButton
              Left = 14
              Top = 90
              Width = 300
              Height = 34
              Caption = 'Unlock Network'
              Margin = 2
              Spacing = 8
              TabOrder = 2
              OnClick = btnUnlockNetworkClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnReadCodes: TSampleButton
              Left = 14
              Top = 126
              Width = 300
              Height = 34
              Caption = 'Read Codes'
              Margin = 2
              Spacing = 8
              TabOrder = 3
              OnClick = btnReadCodesClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnResetPassword: TSampleButton
              Left = 14
              Top = 162
              Width = 300
              Height = 34
              Caption = 'Reset Password [SAFE WIPE]'
              Margin = 2
              Spacing = 8
              TabOrder = 4
              OnClick = btnResetPasswordClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnResetAccount: TSampleButton
              Left = 14
              Top = 198
              Width = 300
              Height = 34
              Caption = 'Reset Account'
              Margin = 2
              Spacing = 8
              TabOrder = 5
              OnClick = btnResetAccountClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
          end
        end
        object tsService: TSampleTabSheet
          Caption = 'Service'
          ImageIndex = 5
          object grpOptionsService: TSampleGroupBox
            Left = 8
            Top = 3
            Width = 328
            Height = 242
            Caption = 'Options'
            Anchors = [akLeft, akTop, akRight]
            TabOrder = 0
            CaptionInset = 6
            object btnRebootRecovery: TSampleButton
              Left = 14
              Top = 18
              Width = 300
              Height = 34
              Caption = 'Reboot to Recovery'
              Margin = 2
              Spacing = 8
              TabOrder = 0
              OnClick = btnRebootRecoveryClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnDisableOta: TSampleButton
              Left = 14
              Top = 54
              Width = 300
              Height = 34
              Caption = 'Disable OTA Updates'
              Margin = 2
              Spacing = 8
              TabOrder = 1
              OnClick = btnDisableOtaClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnResetDmVerity: TSampleButton
              Left = 14
              Top = 90
              Width = 300
              Height = 34
              Caption = 'Reset Dm-Verity Error'
              Margin = 2
              Spacing = 8
              TabOrder = 2
              OnClick = btnResetDmVerityClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnDisableOrangeState: TSampleButton
              Left = 14
              Top = 126
              Width = 300
              Height = 34
              Caption = 'Disable Orange State'
              Margin = 2
              Spacing = 8
              TabOrder = 3
              OnClick = btnDisableOrangeStateClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnSwitchSlot: TSampleButton
              Left = 14
              Top = 162
              Width = 300
              Height = 34
              Caption = 'Switch Slot'
              Margin = 2
              Spacing = 8
              TabOrder = 4
              OnClick = btnSwitchSlotClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnFixDlImage: TSampleButton
              Left = 14
              Top = 198
              Width = 300
              Height = 34
              Caption = 'Fix DL Image Fail'
              Margin = 2
              Spacing = 8
              TabOrder = 5
              OnClick = btnFixDlImageClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
          end
        end
        object tsRpmb: TSampleTabSheet
          Caption = 'RPMB'
          ImageIndex = 6
          object grpOptionsRpmb: TSampleGroupBox
            Left = 8
            Top = 3
            Width = 328
            Height = 152
            Caption = 'Options'
            Anchors = [akLeft, akTop, akRight]
            TabOrder = 0
            CaptionInset = 6
            object btnRpmbBackup: TSampleButton
              Left = 14
              Top = 18
              Width = 300
              Height = 34
              Caption = 'Backup RPMB'
              Margin = 2
              Spacing = 8
              TabOrder = 0
              OnClick = btnRpmbBackupClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object lblRpmbAddress: TLabel
              Left = 14
              Top = 56
              Width = 70
              Height = 13
              Caption = 'Address 0x'
            end
            object edtRpmbAddress: TEdit
              Left = 86
              Top = 56
              Width = 59
              Height = 18
              TabOrder = 1
              Text = '000000'
              AutoSize = False
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnRpmbWrite: TSampleButton
              Left = 14
              Top = 77
              Width = 300
              Height = 34
              Caption = 'Write RPMB'
              Margin = 2
              Spacing = 8
              TabOrder = 2
              OnClick = btnRpmbWriteClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object btnRpmbFormat: TSampleButton
              Left = 14
              Top = 113
              Width = 300
              Height = 34
              Caption = 'Format RPMB'
              Margin = 2
              Spacing = 8
              TabOrder = 3
              OnClick = btnRpmbFormatClick
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -9
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
          end
        end
      end
    end
    object tsMeta: TSampleTabSheet
      Caption = 'META'
      ImageIndex = 1
      object grpPlatform: TSampleGroupBox
        Left = 8
        Top = 5
        Width = 328
        Height = 148
        Caption = 'Platform'
        TabOrder = 0
        object lblPlatform: TLabel
          Left = 14
          Top = 18
          Width = 80
          Height = 13
          Caption = 'Platform'
        end
        object cbPlatform: TComboBox
          Left = 14
          Top = 34
          Width = 300
          Height = 21
          Hint = 'Choose the chipset family. Unisoc changes META to DIAG.'
          Style = csDropDownList
          TabOrder = 0
          OnChange = cbPlatformChange
          Items.Strings = (
          'MediaTek (MTK)'
          'Unisoc / Spreadtrum'
          'Qualcomm'
          'Samsung'
          'Other / Generic')
          ItemIndex = 0
        end
        object lblServiceMode: TLabel
          Left = 14
          Top = 66
          Width = 100
          Height = 13
          Caption = 'Service mode'
        end
        object lblServiceModeValue: TLabel
          Left = 118
          Top = 66
          Width = 100
          Height = 13
          Caption = 'META'
        end
        object lblMetaInfo: TLabel
          Left = 14
          Top = 88
          Width = 300
          Height = 50
          AutoSize = False
          WordWrap = True
          Caption = 'MediaTek service profile. This build does not communicate with a phone.'
        end
      end
    end
  end
  object lblDeviceState: TLabel
    Left = 351
    Top = 566
    Width = 280
    Height = 16
    Alignment = taRightJustify
    AutoSize = False
    Caption = 'No device'
    Visible = False
    Anchors = [akRight, akBottom]
  end
  object pbDeviceState: TPaintBox
    Left = 636
    Top = 562
    Width = 24
    Height = 24
    Hint = 'No device connected'
    Visible = False
    OnPaint = pbDeviceStatePaint
    Anchors = [akRight, akBottom]
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
