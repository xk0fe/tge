object MainForm: TMainForm
  Left = 223
  Top = 113
  ActiveControl = BtnStart
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'TSS Configuration'
  ClientHeight = 396
  ClientWidth = 570
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  DesignSize = (
    570
    396)
  PixelsPerInch = 96
  TextHeight = 13
  object Bevel1: TBevel
    Left = 16
    Top = 338
    Width = 537
    Height = 48
    Anchors = [akLeft, akRight, akBottom]
    Shape = bsTopLine
  end
  object Label7: TLabel
    Left = 296
    Top = 304
    Width = 35
    Height = 13
    Caption = 'Details:'
  end
  object BtnCancel: TButton
    Left = 456
    Top = 353
    Width = 97
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Cancel'
    TabOrder = 0
    OnClick = BtnCancelClick
  end
  object BtnStart: TButton
    Left = 184
    Top = 354
    Width = 153
    Height = 24
    Anchors = [akRight, akBottom]
    Caption = 'Save && Start Game'
    Default = True
    TabOrder = 1
    OnClick = BtnStartClick
  end
  object VideoBox: TGroupBox
    Left = 16
    Top = 16
    Width = 265
    Height = 308
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Video'
    TabOrder = 2
    DesignSize = (
      265
      308)
    object Bevel3: TBevel
      Left = 16
      Top = 88
      Width = 233
      Height = 89
      Anchors = [akLeft, akTop, akRight]
      Shape = bsBottomLine
    end
    object Bevel2: TBevel
      Left = 16
      Top = 24
      Width = 233
      Height = 57
      Anchors = [akLeft, akTop, akRight]
      Shape = bsBottomLine
    end
    object Label1: TLabel
      Left = 16
      Top = 32
      Width = 30
      Height = 13
      Caption = 'Mode:'
    end
    object Label2: TLabel
      Left = 16
      Top = 88
      Width = 39
      Height = 13
      Caption = 'Filtering:'
    end
    object ModeCombo: TComboBox
      Left = 64
      Top = 28
      Width = 185
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      ItemHeight = 13
      ItemIndex = 5
      TabOrder = 0
      Text = '1024x768 32bit'
      Items.Strings = (
        '640x480 16bit'
        '640x480 32bit'
        '800x600 16bit'
        '800x600 32bit'
        '1024x768 16bit'
        '1024x768 32bit'
        '1280x1024 16bit'
        '1280x1024 32bit'
        '1600x1200 16bit'
        '1600x1200 32bit')
    end
    object FullScreenCheck: TCheckBox
      Left = 64
      Top = 56
      Width = 185
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      Caption = 'Fullscreen'
      Checked = True
      State = cbChecked
      TabOrder = 1
    end
    object NoneRadio: TRadioButton
      Left = 64
      Top = 88
      Width = 185
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      Caption = 'None'
      TabOrder = 2
    end
    object BilinearRadio: TRadioButton
      Left = 64
      Top = 108
      Width = 185
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      Caption = 'Bilinear'
      TabOrder = 3
    end
    object TrilinearRadio: TRadioButton
      Left = 64
      Top = 128
      Width = 185
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      Caption = 'Trilinear'
      Checked = True
      TabOrder = 4
      TabStop = True
    end
    object AnisotropicRadio: TRadioButton
      Left = 64
      Top = 148
      Width = 89
      Height = 17
      Caption = 'Anisotropic'
      TabOrder = 5
    end
    object AnisotropicCombo: TComboBox
      Left = 152
      Top = 145
      Width = 97
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      ItemHeight = 13
      ItemIndex = 2
      TabOrder = 6
      Text = '8x'
      Items.Strings = (
        '2x'
        '4x'
        '8x'
        '16x')
    end
    object DitheringCheck: TCheckBox
      Left = 64
      Top = 212
      Width = 185
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      Caption = 'Dithering'
      Checked = True
      State = cbChecked
      TabOrder = 7
    end
    object AntialiasCheck: TCheckBox
      Left = 64
      Top = 188
      Width = 89
      Height = 17
      Caption = 'Antialiasing'
      TabOrder = 8
    end
    object AntialiasCombo: TComboBox
      Left = 152
      Top = 185
      Width = 97
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      ItemHeight = 13
      ItemIndex = 1
      TabOrder = 9
      Text = '4x'
      Items.Strings = (
        '2x'
        '4x'
        '6x'
        '8x')
    end
  end
  object AudioBox: TGroupBox
    Left = 296
    Top = 16
    Width = 257
    Height = 233
    Anchors = [akTop, akRight, akBottom]
    Caption = 'Audio'
    TabOrder = 3
    DesignSize = (
      257
      233)
    object Bevel4: TBevel
      Left = 16
      Top = 20
      Width = 225
      Height = 77
      Anchors = [akLeft, akTop, akRight]
      Shape = bsBottomLine
    end
    object Label3: TLabel
      Left = 16
      Top = 32
      Width = 37
      Height = 13
      Caption = 'Device:'
    end
    object Label4: TLabel
      Left = 16
      Top = 64
      Width = 48
      Height = 13
      Caption = 'Speakers:'
    end
    object Label5: TLabel
      Left = 16
      Top = 104
      Width = 72
      Height = 13
      Caption = 'Sound Volume:'
    end
    object Label6: TLabel
      Left = 16
      Top = 160
      Width = 69
      Height = 13
      Caption = 'Music Volume:'
    end
    object AudioDeviceCombo: TComboBox
      Left = 72
      Top = 28
      Width = 169
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      ItemHeight = 13
      ItemIndex = 0
      TabOrder = 0
      Text = 'Default'
      Items.Strings = (
        'Default')
    end
    object SpeakerCombo: TComboBox
      Left = 72
      Top = 60
      Width = 169
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      ItemHeight = 13
      ItemIndex = 1
      TabOrder = 1
      Text = 'Stereo'
      Items.Strings = (
        'Mono'
        'Stereo'
        'Headphones'
        'Surround'
        'Quad'
        'Dolby Digital')
    end
    object SFXBar: TTrackBar
      Left = 16
      Top = 120
      Width = 225
      Height = 29
      Anchors = [akLeft, akTop, akRight]
      Max = 100
      PageSize = 10
      Frequency = 5
      Position = 100
      TabOrder = 2
    end
    object MusicBar: TTrackBar
      Left = 16
      Top = 176
      Width = 225
      Height = 29
      Anchors = [akLeft, akTop, akRight]
      Max = 100
      PageSize = 10
      Frequency = 5
      Position = 50
      TabOrder = 3
    end
  end
  object FPSCheck: TCheckBox
    Left = 472
    Top = 266
    Width = 81
    Height = 17
    Anchors = [akRight, akBottom]
    Caption = 'Show FPS'
    TabOrder = 4
  end
  object SaveBtn: TButton
    Left = 352
    Top = 353
    Width = 97
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Save'
    TabOrder = 5
    OnClick = SaveBtnClick
  end
  object DetailBar: TTrackBar
    Left = 344
    Top = 296
    Width = 209
    Height = 29
    Max = 3
    Position = 2
    TabOrder = 6
  end
  object XPManifest: TXPManifest
    Left = 16
    Top = 304
  end
end
