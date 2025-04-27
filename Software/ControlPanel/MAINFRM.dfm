object mainform: Tmainform
  Left = 561
  Top = 116
  BorderStyle = bsSingle
  Caption = 'DIY FPGA PCI Card'
  ClientHeight = 361
  ClientWidth = 417
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 8
    Top = 8
    Width = 401
    Height = 345
    Caption = ' Configuration of DIY FPGA PCI Card '
    TabOrder = 0
    object Label1: TLabel
      Left = 28
      Top = 32
      Width = 149
      Height = 13
      Alignment = taRightJustify
      Caption = 'Detected DIY FPGA PCI Cards:'
    end
    object cardcounterlbl: TLabel
      Left = 184
      Top = 32
      Width = 6
      Height = 13
      Caption = '0'
    end
    object Label2: TLabel
      Left = 108
      Top = 64
      Width = 69
      Height = 13
      Alignment = taRightJustify
      Caption = 'Card-Revision:'
    end
    object revisionlbl: TLabel
      Left = 184
      Top = 64
      Width = 6
      Height = 13
      Caption = '0'
    end
    object Label3: TLabel
      Left = 133
      Top = 48
      Width = 44
      Height = 13
      Alignment = taRightJustify
      Caption = 'Location:'
    end
    object locationlbl: TLabel
      Left = 184
      Top = 48
      Width = 9
      Height = 13
      Caption = '...'
    end
    object Label4: TLabel
      Left = 85
      Top = 88
      Width = 92
      Height = 13
      Alignment = taRightJustify
      Caption = 'Command-Register:'
    end
    object commandreglbl: TLabel
      Left = 184
      Top = 88
      Width = 6
      Height = 13
      Caption = '0'
    end
    object Label6: TLabel
      Left = 102
      Top = 104
      Width = 75
      Height = 13
      Alignment = taRightJustify
      Caption = 'Status-Register:'
    end
    object statusreglbl: TLabel
      Left = 184
      Top = 104
      Width = 6
      Height = 13
      Caption = '0'
    end
  end
end
