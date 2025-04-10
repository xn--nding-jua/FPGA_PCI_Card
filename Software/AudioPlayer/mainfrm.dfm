object mainform: Tmainform
  Left = 368
  Top = 217
  BorderStyle = bsSingle
  Caption = 'AudioPlayer'
  ClientHeight = 256
  ClientWidth = 448
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 224
    Height = 13
    Caption = 'AudioPlayer for the DIY FPGA PCI Card'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 8
    Top = 24
    Width = 124
    Height = 13
    Caption = 'v1.0.1 built on 06.04.2025'
  end
  object GroupBox1: TGroupBox
    Left = 160
    Top = 48
    Width = 281
    Height = 73
    Caption = ' Debug section '
    TabOrder = 0
    object Label7: TLabel
      Left = 8
      Top = 24
      Width = 71
      Height = 13
      Caption = 'Manual output:'
    end
    object Label8: TLabel
      Left = 8
      Top = 56
      Width = 13
      Height = 13
      Caption = '0V'
    end
    object Label9: TLabel
      Left = 128
      Top = 56
      Width = 28
      Height = 13
      Caption = '1.65V'
    end
    object Label10: TLabel
      Left = 256
      Top = 56
      Width = 22
      Height = 13
      Caption = '3.3V'
    end
    object ScrollBar1: TScrollBar
      Left = 8
      Top = 40
      Width = 265
      Height = 16
      Max = 980
      Min = -980
      PageSize = 0
      TabOrder = 0
      OnChange = ScrollBar1Change
    end
  end
  object GroupBox2: TGroupBox
    Left = 8
    Top = 128
    Width = 433
    Height = 121
    Caption = ' Audioplayer '
    TabOrder = 1
    object Label3: TLabel
      Left = 8
      Top = 24
      Width = 200
      Height = 13
      Caption = 'Audio-File (only 8-bit and 16-bit supported):'
    end
    object Label6: TLabel
      Left = 232
      Top = 64
      Width = 9
      Height = 13
      Caption = '...'
    end
    object Label11: TLabel
      Left = 232
      Top = 86
      Width = 84
      Height = 13
      Caption = 'Samples in buffer:'
    end
    object Label12: TLabel
      Left = 232
      Top = 102
      Width = 79
      Height = 13
      Caption = '0 Samples / 0ms'
    end
    object Label13: TLabel
      Left = 232
      Top = 24
      Width = 49
      Height = 13
      Caption = 'Buffersize:'
    end
    object Label14: TLabel
      Left = 278
      Top = 43
      Width = 13
      Height = 13
      Caption = 'ms'
    end
    object Label15: TLabel
      Left = 366
      Top = 12
      Width = 26
      Height = 13
      Caption = '100%'
    end
    object Label16: TLabel
      Left = 379
      Top = 95
      Width = 14
      Height = 13
      Caption = '0%'
    end
    object audiofileedit: TEdit
      Left = 8
      Top = 40
      Width = 217
      Height = 21
      TabOrder = 0
      Text = 'c:\chris\test.wav'
    end
    object Button1: TButton
      Left = 8
      Top = 88
      Width = 75
      Height = 25
      Caption = 'Play'
      TabOrder = 1
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 88
      Top = 88
      Width = 75
      Height = 25
      Caption = 'Stop'
      TabOrder = 2
      OnClick = Button2Click
    end
    object ProgressBar1: TProgressBar
      Left = 8
      Top = 64
      Width = 217
      Height = 17
      TabOrder = 3
    end
    object buffersizeedit: TEdit
      Left = 232
      Top = 40
      Width = 41
      Height = 21
      TabOrder = 4
      Text = '300'
    end
    object volumeslider: TTrackBar
      Left = 392
      Top = 8
      Width = 33
      Height = 105
      Max = 100
      Orientation = trVertical
      TabOrder = 5
      TickMarks = tmBoth
      TickStyle = tsManual
      OnChange = volumesliderChange
    end
  end
  object GroupBox3: TGroupBox
    Left = 8
    Top = 48
    Width = 145
    Height = 73
    Caption = ' Configuration '
    TabOrder = 2
    object Label4: TLabel
      Left = 8
      Top = 24
      Width = 112
      Height = 13
      Caption = 'IO-Address of PCI-Card:'
    end
    object Label5: TLabel
      Left = 8
      Top = 43
      Width = 11
      Height = 13
      Caption = '0x'
    end
    object ioaddressedit: TEdit
      Left = 24
      Top = 40
      Width = 49
      Height = 21
      TabOrder = 0
      Text = '6300'
    end
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 100
    OnTimer = Timer1Timer
    Left = 336
    Top = 144
  end
end
