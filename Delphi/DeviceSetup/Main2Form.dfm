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
  Font.Height = -12
  Font.Name = 'Segoe UI'
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
    Left = 727
    Top = 3
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
    Top = 3
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
    Top = 3
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
    Left = 946
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
    Left = 990
    Top = 3
    Width = 28
    Height = 28
    Cursor = crHandPoint
    Hint = 'Help'
    Anchors = [akTop, akRight]
    OnClick = pbHelpClick
    OnPaint = pbHelpPaint
  end
  object grpPresets: TGroupBox
    Left = 2
    Top = 41
    Width = 656
    Height = 39
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Presets'
    TabOrder = 0
    object cbPresets: TComboBox
      Left = 8
      Top = 15
      Width = 640
      Height = 23
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
    end
  end
  object grpFiles: TGroupBox
    Left = 2
    Top = 84
    Width = 656
    Height = 104
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Files'
    TabOrder = 1
    object btnScat: TButton
      Left = 8
      Top = 13
      Width = 47
      Height = 21
      Caption = 'SCAT'
      TabOrder = 0
      OnClick = btnScatClick
    end
    object edtScat: TEdit
      Left = 58
      Top = 13
      Width = 590
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 1
    end
    object btnAuth: TButton
      Left = 8
      Top = 36
      Width = 47
      Height = 21
      Caption = 'AUTH'
      TabOrder = 2
      OnClick = btnAuthClick
    end
    object edtAuth: TEdit
      Left = 58
      Top = 36
      Width = 590
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 3
    end
    object btnBin: TButton
      Left = 8
      Top = 59
      Width = 47
      Height = 21
      Hint = 'Tick "Advanced write" on the Flash tab to use a BIN file'
      Caption = 'BIN'
      TabOrder = 4
      OnClick = btnBinClick
    end
    object edtBin: TEdit
      Left = 58
      Top = 59
      Width = 590
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 5
    end
    object btnOfp: TButton
      Left = 8
      Top = 82
      Width = 47
      Height = 21
      Caption = 'OFP'
      TabOrder = 6
      OnClick = btnOfpClick
    end
    object edtOfp: TEdit
      Left = 58
      Top = 82
      Width = 590
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 7
    end
    object btnBl: TButton
      Left = 8
      Top = 105
      Width = 47
      Height = 21
      Caption = 'BL'
      TabOrder = 8
      OnClick = btnBlClick
    end
    object edtBl: TEdit
      Left = 58
      Top = 105
      Width = 590
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 9
    end
    object btnAp: TButton
      Left = 8
      Top = 128
      Width = 47
      Height = 21
      Caption = 'AP'
      TabOrder = 10
      OnClick = btnApClick
    end
    object edtAp: TEdit
      Left = 58
      Top = 128
      Width = 590
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 11
    end
    object btnCp: TButton
      Left = 8
      Top = 151
      Width = 47
      Height = 21
      Caption = 'CP'
      TabOrder = 12
      OnClick = btnCpClick
    end
    object edtCp: TEdit
      Left = 58
      Top = 151
      Width = 590
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 13
    end
    object btnCsc: TButton
      Left = 8
      Top = 174
      Width = 47
      Height = 21
      Caption = 'CSC'
      TabOrder = 14
      OnClick = btnCscClick
    end
    object edtCsc: TEdit
      Left = 58
      Top = 174
      Width = 590
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 15
    end
    object btnUser: TButton
      Left = 8
      Top = 197
      Width = 47
      Height = 21
      Caption = 'USER'
      TabOrder = 16
      OnClick = btnUserClick
    end
    object edtUser: TEdit
      Left = 58
      Top = 197
      Width = 590
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 17
    end
  end
  object grpLog: TGroupBox
    Left = 2
    Top = 192
    Width = 656
    Height = 370
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Log'
    TabOrder = 2
    object lstLog: TListBox
      Left = 2
      Top = 17
      Width = 652
      Height = 351
      Style = lbOwnerDrawFixed
      Align = alClient
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
    end
  end
  object pbProgress: TPaintBox
    Left = 2
    Top = 566
    Width = 656
    Height = 16
    Anchors = [akLeft, akRight, akBottom]
    OnPaint = pbProgressPaint
  end
  object pcJobs: TPageControl
    Left = 660
    Top = 28
    Width = 364
    Height = 553
    ActivePage = tsJobs
    Anchors = [akTop, akRight, akBottom]
    Style = tsFlatButtons
    TabOrder = 3
    object tsJobs: TTabSheet
      Caption = 'Jobs'
      object grpConnections: TGroupBox
        Left = 1
        Top = 14
        Width = 344
        Height = 225
        Caption = 'Connections'
        TabOrder = 0
        object lblDownloadAgent: TLabel
          Left = 14
          Top = 10
          Width = 78
          Height = 13
          Caption = 'Download agent'
        end
        object cbDownloadAgent: TComboBox
          Left = 14
          Top = 24
          Width = 316
          Height = 23
          Style = csDropDownList
          Enabled = False
          TabOrder = 0
          Items.Strings = (
            'MTK_AllInOne_DA.bin')
        end
        object chkAuthBrom: TCheckBox
          Left = 14
          Top = 50
          Width = 316
          Height = 17
          Caption = 'Advanced Authorization [BROM]'
          TabOrder = 1
        end
        object chkAuthPreloader: TCheckBox
          Left = 14
          Top = 68
          Width = 316
          Height = 17
          Caption = 'Advanced Authorization [Preloader]'
          Checked = True
          State = cbChecked
          TabOrder = 2
        end
        object chkForceBrom: TCheckBox
          Left = 14
          Top = 86
          Width = 316
          Height = 17
          Caption = 'Force BROM Mode'
          Enabled = False
          TabOrder = 3
        end
        object chkReadEmi: TCheckBox
          Left = 14
          Top = 104
          Width = 316
          Height = 17
          Caption = 'Read EMI from phone'
          Checked = True
          Enabled = False
          State = cbChecked
          TabOrder = 4
        end
        object chkReadPhoneInfo: TCheckBox
          Left = 14
          Top = 122
          Width = 316
          Height = 17
          Caption = 'Read Phone Info'
          Checked = True
          State = cbChecked
          TabOrder = 5
        end
        object lblUsbSpeed: TLabel
          Left = 14
          Top = 152
          Width = 51
          Height = 13
          Caption = 'USB Speed'
        end
        object cbUsbSpeed: TComboBox
          Left = 118
          Top = 148
          Width = 212
          Height = 23
          Style = csDropDownList
          TabOrder = 6
          Items.Strings = (
            'High speed'
            'Full speed')
        end
        object lblBattery: TLabel
          Left = 14
          Top = 178
          Width = 36
          Height = 13
          Caption = 'Battery'
        end
        object cbBattery: TComboBox
          Left = 118
          Top = 174
          Width = 212
          Height = 23
          Style = csDropDownList
          TabOrder = 7
          Items.Strings = (
            'With battery'
            'Without battery'
            'Auto detect')
        end
        object lblStorage: TLabel
          Left = 14
          Top = 204
          Width = 35
          Height = 13
          Caption = 'Storage'
        end
        object cbStorage: TComboBox
          Left = 118
          Top = 200
          Width = 212
          Height = 23
          Style = csDropDownList
          TabOrder = 8
          Items.Strings = (
            'EMMC(USER) || UFS(LU2)'
            'EMMC(BOOT1) || UFS(LU0)'
            'EMMC(BOOT2) || UFS(LU1)'
            'EMMC(RPMB) || UFS(RPMB)')
        end
      end
      object pcOperations: TPageControl
        Left = 0
        Top = 241
        Width = 352
        Height = 291
        ActivePage = tsFlash
        Style = tsFlatButtons
        TabOrder = 1
        object tsFlash: TTabSheet
          Caption = 'Flash'
          object lblOptionsFlash: TLabel
            Left = 2
            Top = 4
            Width = 41
            Height = 13
            Caption = 'Options'
          end
          object cbFlashMode: TComboBox
            Left = 2
            Top = 20
            Width = 336
            Height = 23
            Style = csDropDownList
            TabOrder = 0
            Items.Strings = (
              'Download only'
              'Firmware upgrade'
              'Format all + Download')
          end
          object btnWriteFirmware: TBitBtn
            Left = 2
            Top = 46
            Width = 336
            Height = 32
            Caption = 'Write Firmware'
            Margin = 6
            Spacing = 14
            TabOrder = 1
            OnClick = btnWriteFirmwareClick
          end
          object btnRestoreBackup: TBitBtn
            Left = 2
            Top = 82
            Width = 336
            Height = 32
            Caption = 'Restore from backup'
            Margin = 6
            Spacing = 14
            TabOrder = 2
            OnClick = btnRestoreBackupClick
          end
          object chkAdvancedWrite: TCheckBox
            Left = 2
            Top = 120
            Width = 200
            Height = 17
            Caption = 'Advanced write'
            TabOrder = 3
            OnClick = chkAdvancedWriteClick
          end
          object lblAddress: TLabel
            Left = 2
            Top = 143
            Width = 53
            Height = 13
            Caption = 'Address 0x'
          end
          object edtAddress: TEdit
            Left = 62
            Top = 139
            Width = 124
            Height = 23
            Enabled = False
            TabOrder = 4
            Text = '00000000  00000000'
          end
          object btnWriteBin: TBitBtn
            Left = 2
            Top = 166
            Width = 336
            Height = 32
            Caption = 'Write BIN'
            Enabled = False
            Margin = 6
            Spacing = 14
            TabOrder = 5
            OnClick = btnWriteBinClick
          end
          object btnWriteOfp: TBitBtn
            Left = 2
            Top = 202
            Width = 336
            Height = 32
            Caption = 'Write OFP'
            Margin = 6
            Spacing = 14
            TabOrder = 6
            OnClick = btnWriteOfpClick
          end
        end
        object tsRead: TTabSheet
          Caption = 'Read'
          ImageIndex = 1
          object lblOptionsRead: TLabel
            Left = 2
            Top = 4
            Width = 41
            Height = 13
            Caption = 'Options'
          end
          object btnReadInfo: TBitBtn
            Left = 2
            Top = 20
            Width = 336
            Height = 32
            Caption = 'Read Flash info'
            Margin = 6
            Spacing = 14
            TabOrder = 0
            OnClick = btnReadInfoClick
          end
          object btnReadPartitions: TBitBtn
            Left = 2
            Top = 56
            Width = 336
            Height = 32
            Caption = 'Read Partitions'
            Margin = 6
            Spacing = 14
            TabOrder = 1
            OnClick = btnReadPartitionsClick
          end
          object lblReadAddress: TLabel
            Left = 2
            Top = 94
            Width = 53
            Height = 13
            Caption = 'Address 0x'
          end
          object edtReadAddress: TEdit
            Left = 2
            Top = 110
            Width = 124
            Height = 23
            TabOrder = 2
            Text = '00000000  00000000'
          end
          object lblReadSize: TLabel
            Left = 150
            Top = 94
            Width = 37
            Height = 13
            Caption = 'Size 0x'
          end
          object edtReadSize: TEdit
            Left = 150
            Top = 110
            Width = 124
            Height = 23
            TabOrder = 3
            Text = '00000000  00000000'
          end
          object btnReadBin: TBitBtn
            Left = 2
            Top = 140
            Width = 336
            Height = 32
            Caption = 'Read BIN'
            Margin = 6
            Spacing = 14
            TabOrder = 4
            OnClick = btnReadBinClick
          end
          object btnReadRegion: TBitBtn
            Left = 2
            Top = 176
            Width = 336
            Height = 32
            Caption = 'Read Region'
            Margin = 6
            Spacing = 14
            TabOrder = 5
            OnClick = btnReadRegionClick
          end
          object btnReadOtp: TBitBtn
            Left = 2
            Top = 212
            Width = 336
            Height = 32
            Caption = 'Read OTP'
            Margin = 6
            Spacing = 14
            TabOrder = 6
            OnClick = btnReadOtpClick
          end
        end
        object tsFormat: TTabSheet
          Caption = 'Format'
          ImageIndex = 2
          object lblOptionsFormat: TLabel
            Left = 2
            Top = 4
            Width = 41
            Height = 13
            Caption = 'Options'
          end
          object rbAutoFormat: TRadioButton
            Left = 2
            Top = 20
            Width = 100
            Height = 17
            Caption = 'Auto Format'
            Checked = True
            TabOrder = 0
          end
          object rbManualFormat: TRadioButton
            Left = 130
            Top = 20
            Width = 120
            Height = 17
            Caption = 'Manual Format'
            TabOrder = 1
          end
          object rbFormatAiFlash: TRadioButton
            Left = 2
            Top = 40
            Width = 150
            Height = 17
            Caption = 'Format AI Flash'
            Checked = True
            TabOrder = 2
          end
          object rbFormatAiExceptBootloader: TRadioButton
            Left = 2
            Top = 58
            Width = 250
            Height = 17
            Caption = 'Format AI Except Bootloader'
            TabOrder = 3
          end
          object btnFormat: TBitBtn
            Left = 2
            Top = 80
            Width = 336
            Height = 30
            Caption = 'Format'
            Margin = 6
            Spacing = 14
            TabOrder = 4
            OnClick = btnFormatClick
          end
          object chkCreateDefaultFs: TCheckBox
            Left = 2
            Top = 114
            Width = 250
            Height = 17
            Caption = 'Create Default FS'
            TabOrder = 5
          end
          object btnWipeData: TBitBtn
            Left = 2
            Top = 132
            Width = 336
            Height = 30
            Caption = 'Wipe Data'
            Margin = 6
            Spacing = 14
            TabOrder = 6
            OnClick = btnWipeDataClick
          end
          object btnWipePartitions: TBitBtn
            Left = 2
            Top = 166
            Width = 336
            Height = 30
            Caption = 'Wipe Partitions'
            Margin = 6
            Spacing = 14
            TabOrder = 7
            OnClick = btnWipePartitionsClick
          end
          object btnEraseFrp: TBitBtn
            Left = 2
            Top = 200
            Width = 336
            Height = 30
            Caption = 'Erase FRP'
            Margin = 6
            Spacing = 14
            TabOrder = 8
            OnClick = btnEraseFrpClick
          end
          object btnEraseFrpAndWipe: TBitBtn
            Left = 2
            Top = 234
            Width = 336
            Height = 30
            Caption = 'Erase FRP and Wipe'
            Margin = 6
            Spacing = 14
            TabOrder = 9
            OnClick = btnEraseFrpAndWipeClick
          end
        end
        object tsImei: TTabSheet
          Caption = 'IMEI'
          ImageIndex = 3
          object lblOptionsImei: TLabel
            Left = 2
            Top = 4
            Width = 41
            Height = 13
            Caption = 'Options'
          end
          object chkImei1: TCheckBox
            Left = 2
            Top = 20
            Width = 55
            Height = 17
            Caption = 'IMEI1'
            Checked = True
            State = cbChecked
            TabOrder = 0
          end
          object edtImei1: TEdit
            Left = 62
            Top = 16
            Width = 130
            Height = 23
            TabOrder = 1
            Text = '35646019030487'
          end
          object lblImei1Digits: TLabel
            Left = 200
            Top = 20
            Width = 20
            Height = 13
            Caption = '9'
          end
          object chkImei2: TCheckBox
            Left = 2
            Top = 40
            Width = 55
            Height = 17
            Caption = 'IMEI2'
            Checked = True
            State = cbChecked
            TabOrder = 2
          end
          object edtImei2: TEdit
            Left = 62
            Top = 36
            Width = 130
            Height = 23
            TabOrder = 3
            Text = '35646019110987'
          end
          object lblImei2Digits: TLabel
            Left = 200
            Top = 40
            Width = 20
            Height = 13
            Caption = '1'
          end
          object lblAdvancedSettings: TLabel
            Left = 2
            Top = 62
            Width = 101
            Height = 13
            Cursor = crHandPoint
            Caption = 'Advanced settings'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 16744448
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsUnderline]
            ParentFont = False
            OnClick = lblAdvancedSettingsClick
          end
          object btnRepair: TBitBtn
            Left = 2
            Top = 84
            Width = 336
            Height = 32
            Caption = 'Repair'
            Margin = 6
            Spacing = 14
            TabOrder = 4
            OnClick = btnRepairClick
          end
          object btnReadImei: TBitBtn
            Left = 2
            Top = 120
            Width = 336
            Height = 32
            Caption = 'Read IMEI'
            Margin = 6
            Spacing = 14
            TabOrder = 5
            OnClick = btnReadImeiClick
          end
        end
        object tsLocks: TTabSheet
          Caption = 'Locks'
          ImageIndex = 4
          object lblOptionsLocks: TLabel
            Left = 2
            Top = 4
            Width = 41
            Height = 13
            Caption = 'Options'
          end
          object btnUnlockBootloader: TBitBtn
            Left = 2
            Top = 20
            Width = 336
            Height = 32
            Caption = 'Unlock Bootloader'
            Margin = 6
            Spacing = 14
            TabOrder = 0
            OnClick = btnUnlockBootloaderClick
          end
          object btnRelockBootloader: TBitBtn
            Left = 2
            Top = 56
            Width = 336
            Height = 32
            Caption = 'Relock Bootloader'
            Margin = 6
            Spacing = 14
            TabOrder = 1
            OnClick = btnRelockBootloaderClick
          end
          object btnUnlockNetwork: TBitBtn
            Left = 2
            Top = 92
            Width = 336
            Height = 32
            Caption = 'Unlock Network'
            Margin = 6
            Spacing = 14
            TabOrder = 2
            OnClick = btnUnlockNetworkClick
          end
          object btnReadCodes: TBitBtn
            Left = 2
            Top = 128
            Width = 336
            Height = 32
            Caption = 'Read Codes'
            Margin = 6
            Spacing = 14
            TabOrder = 3
            OnClick = btnReadCodesClick
          end
          object btnResetPassword: TBitBtn
            Left = 2
            Top = 164
            Width = 336
            Height = 32
            Caption = 'Reset Password [SAFE WIPE]'
            Margin = 6
            Spacing = 14
            TabOrder = 4
            OnClick = btnResetPasswordClick
          end
          object btnResetAccount: TBitBtn
            Left = 2
            Top = 200
            Width = 336
            Height = 32
            Caption = 'Reset Account'
            Margin = 6
            Spacing = 14
            TabOrder = 5
            OnClick = btnResetAccountClick
          end
        end
        object tsService: TTabSheet
          Caption = 'Service'
          ImageIndex = 5
          object lblOptionsService: TLabel
            Left = 2
            Top = 4
            Width = 41
            Height = 13
            Caption = 'Options'
          end
          object btnRebootRecovery: TBitBtn
            Left = 2
            Top = 20
            Width = 336
            Height = 32
            Caption = 'Reboot to Recovery'
            Margin = 6
            Spacing = 14
            TabOrder = 0
            OnClick = btnRebootRecoveryClick
          end
          object btnDisableOta: TBitBtn
            Left = 2
            Top = 56
            Width = 336
            Height = 32
            Caption = 'Disable OTA Updates'
            Margin = 6
            Spacing = 14
            TabOrder = 1
            OnClick = btnDisableOtaClick
          end
          object btnResetDmVerity: TBitBtn
            Left = 2
            Top = 92
            Width = 336
            Height = 32
            Caption = 'Reset Dm-Verity Error'
            Margin = 6
            Spacing = 14
            TabOrder = 2
            OnClick = btnResetDmVerityClick
          end
          object btnDisableOrangeState: TBitBtn
            Left = 2
            Top = 128
            Width = 336
            Height = 32
            Caption = 'Disable Orange State'
            Margin = 6
            Spacing = 14
            TabOrder = 3
            OnClick = btnDisableOrangeStateClick
          end
          object btnSwitchSlot: TBitBtn
            Left = 2
            Top = 164
            Width = 336
            Height = 32
            Caption = 'Switch Slot'
            Margin = 6
            Spacing = 14
            TabOrder = 4
            OnClick = btnSwitchSlotClick
          end
          object btnFixDlImage: TBitBtn
            Left = 2
            Top = 200
            Width = 336
            Height = 32
            Caption = 'Fix DL Image Fail'
            Margin = 6
            Spacing = 14
            TabOrder = 5
            OnClick = btnFixDlImageClick
          end
        end
        object tsRpmb: TTabSheet
          Caption = 'RPMB'
          ImageIndex = 6
          object lblOptionsRpmb: TLabel
            Left = 2
            Top = 4
            Width = 41
            Height = 13
            Caption = 'Options'
          end
          object btnRpmbBackup: TBitBtn
            Left = 2
            Top = 20
            Width = 336
            Height = 32
            Caption = 'Backup RPMB'
            Margin = 6
            Spacing = 14
            TabOrder = 0
            OnClick = btnRpmbBackupClick
          end
          object lblRpmbAddress: TLabel
            Left = 2
            Top = 58
            Width = 53
            Height = 13
            Caption = 'Address 0x'
          end
          object edtRpmbAddress: TEdit
            Left = 62
            Top = 54
            Width = 90
            Height = 23
            TabOrder = 1
            Text = '000000'
          end
          object btnRpmbWrite: TBitBtn
            Left = 2
            Top = 80
            Width = 336
            Height = 32
            Caption = 'Write RPMB'
            Margin = 6
            Spacing = 14
            TabOrder = 2
            OnClick = btnRpmbWriteClick
          end
          object btnRpmbFormat: TBitBtn
            Left = 2
            Top = 116
            Width = 336
            Height = 32
            Caption = 'Format RPMB'
            Margin = 6
            Spacing = 14
            TabOrder = 3
            OnClick = btnRpmbFormatClick
          end
        end
      end
    end
    object tsMeta: TTabSheet
      Caption = 'META'
      ImageIndex = 1
      object grpPlatform: TGroupBox
        Left = 1
        Top = 14
        Width = 344
        Height = 120
        Caption = 'Platform'
        TabOrder = 0
        object lblPlatform: TLabel
          Left = 14
          Top = 22
          Width = 45
          Height = 13
          Caption = 'Platform'
        end
        object cbPlatform: TComboBox
          Left = 14
          Top = 38
          Width = 316
          Height = 23
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
        end
        object lblServiceMode: TLabel
          Left = 14
          Top = 70
          Width = 75
          Height = 13
          Caption = 'Service mode'
        end
        object lblServiceModeValue: TLabel
          Left = 118
          Top = 70
          Width = 34
          Height = 13
          Caption = 'META'
        end
        object lblMetaInfo: TLabel
          Left = 14
          Top = 92
          Width = 316
          Height = 20
          AutoSize = False
          WordWrap = True
          Caption = 'MediaTek service profile. This build does not communicate with a phone.'
        end
      end
    end
  end
  object lblDeviceState: TLabel
    Left = 330
    Top = 567
    Width = 292
    Height = 15
    Alignment = taRightJustify
    AutoSize = False
    Caption = 'No device'
    Visible = False
  end
  object pbDeviceState: TPaintBox
    Left = 628
    Top = 563
    Width = 24
    Height = 24
    Hint = 'No device connected'
    Visible = False
    OnPaint = pbDeviceStatePaint
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
