object mainform: Tmainform
  Left = 174
  Top = 122
  BorderStyle = bsSingle
  Caption = 'AudioPlayer'
  ClientHeight = 250
  ClientWidth = 462
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
    Caption = 'v1.0.0 built on 05.04.2025'
  end
  object Label3: TLabel
    Left = 8
    Top = 96
    Width = 200
    Height = 13
    Caption = 'Audio-File (only 8-bit and 16-bit supported):'
  end
  object Label4: TLabel
    Left = 8
    Top = 48
    Width = 112
    Height = 13
    Caption = 'IO-Address of PCI-Card:'
  end
  object Label5: TLabel
    Left = 8
    Top = 66
    Width = 11
    Height = 13
    Caption = '0x'
  end
  object Label6: TLabel
    Left = 232
    Top = 136
    Width = 9
    Height = 13
    Caption = '...'
  end
  object audiofileedit: TEdit
    Left = 8
    Top = 112
    Width = 217
    Height = 21
    TabOrder = 0
    Text = 'c:\temp\test.wav'
  end
  object Button1: TButton
    Left = 8
    Top = 160
    Width = 75
    Height = 25
    Caption = 'Play'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 88
    Top = 160
    Width = 75
    Height = 25
    Caption = 'Stop'
    TabOrder = 2
    OnClick = Button2Click
  end
  object ioaddressedit: TEdit
    Left = 24
    Top = 64
    Width = 49
    Height = 21
    TabOrder = 3
    Text = '6300'
  end
  object ProgressBar1: TProgressBar
    Left = 8
    Top = 136
    Width = 217
    Height = 17
    TabOrder = 4
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 500
    OnTimer = Timer1Timer
    Left = 192
    Top = 128
  end
end
