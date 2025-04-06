object mainform: Tmainform
  Left = 230
  Top = 113
  BorderStyle = bsSingle
  Caption = 'FPGA Test'
  ClientHeight = 410
  ClientWidth = 750
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
  object GroupBox1: TGroupBox
    Left = 8
    Top = 8
    Width = 161
    Height = 393
    Caption = ' Windows 9x Controls '
    TabOrder = 0
    object Label1: TLabel
      Left = 8
      Top = 280
      Width = 55
      Height = 13
      Caption = 'IO-Address:'
    end
    object Label2: TLabel
      Left = 88
      Top = 280
      Width = 49
      Height = 13
      Caption = 'IO-Range:'
    end
    object Label7: TLabel
      Left = 8
      Top = 320
      Width = 80
      Height = 13
      Caption = 'Number of bytes:'
    end
    object Label12: TLabel
      Left = 8
      Top = 299
      Width = 11
      Height = 13
      Caption = '0x'
    end
    object Label13: TLabel
      Left = 91
      Top = 299
      Width = 11
      Height = 13
      Caption = '0x'
    end
    object Button1: TButton
      Left = 8
      Top = 360
      Width = 145
      Height = 25
      Caption = 'Read Data ASM'
      TabOrder = 0
      OnClick = Button1Click
    end
    object win9x_ioaddress: TEdit
      Left = 24
      Top = 296
      Width = 57
      Height = 21
      TabOrder = 1
      Text = '6300'
    end
    object win9x_iorange: TEdit
      Left = 104
      Top = 296
      Width = 49
      Height = 21
      TabOrder = 2
      Text = '10'
    end
    object win9x_result: TMemo
      Left = 8
      Top = 24
      Width = 145
      Height = 249
      TabOrder = 3
    end
    object RadioButton1: TRadioButton
      Left = 8
      Top = 336
      Width = 41
      Height = 17
      Caption = '1'
      TabOrder = 4
    end
    object RadioButton2: TRadioButton
      Left = 48
      Top = 336
      Width = 49
      Height = 17
      Caption = '2'
      TabOrder = 5
    end
    object RadioButton3: TRadioButton
      Left = 96
      Top = 336
      Width = 57
      Height = 17
      Caption = '4'
      Checked = True
      TabOrder = 6
      TabStop = True
    end
  end
  object GroupBox2: TGroupBox
    Left = 176
    Top = 8
    Width = 217
    Height = 393
    Caption = ' GwPortIO Controls '
    TabOrder = 1
    object Label3: TLabel
      Left = 8
      Top = 280
      Width = 55
      Height = 13
      Caption = 'IO-Address:'
    end
    object Label4: TLabel
      Left = 88
      Top = 280
      Width = 49
      Height = 13
      Caption = 'IO-Range:'
    end
    object Label14: TLabel
      Left = 91
      Top = 299
      Width = 11
      Height = 13
      Caption = '0x'
    end
    object Label15: TLabel
      Left = 8
      Top = 299
      Width = 11
      Height = 13
      Caption = '0x'
    end
    object Button2: TButton
      Left = 8
      Top = 360
      Width = 201
      Height = 25
      Caption = 'Read Data'
      TabOrder = 0
      OnClick = Button2Click
    end
    object ioaddress: TEdit
      Left = 24
      Top = 296
      Width = 57
      Height = 21
      TabOrder = 1
      Text = '6300'
    end
    object iorange: TEdit
      Left = 104
      Top = 296
      Width = 49
      Height = 21
      TabOrder = 2
      Text = '10'
    end
    object gwportio_result: TMemo
      Left = 8
      Top = 56
      Width = 201
      Height = 217
      TabOrder = 3
    end
    object Button3: TButton
      Left = 8
      Top = 24
      Width = 97
      Height = 25
      Caption = 'Load driver'
      TabOrder = 4
      OnClick = Button3Click
    end
    object Button4: TButton
      Left = 112
      Top = 24
      Width = 97
      Height = 25
      Caption = 'Unload driver'
      TabOrder = 5
      OnClick = Button4Click
    end
  end
  object GroupBox3: TGroupBox
    Left = 400
    Top = 8
    Width = 161
    Height = 393
    Caption = ' Inpout32 Controls '
    TabOrder = 2
    object Label5: TLabel
      Left = 8
      Top = 280
      Width = 55
      Height = 13
      Caption = 'IO-Address:'
    end
    object Label6: TLabel
      Left = 88
      Top = 280
      Width = 49
      Height = 13
      Caption = 'IO-Range:'
    end
    object Label16: TLabel
      Left = 91
      Top = 299
      Width = 11
      Height = 13
      Caption = '0x'
    end
    object Label17: TLabel
      Left = 8
      Top = 299
      Width = 11
      Height = 13
      Caption = '0x'
    end
    object Button6: TButton
      Left = 8
      Top = 360
      Width = 145
      Height = 25
      Caption = 'Read Data'
      TabOrder = 0
      OnClick = Button6Click
    end
    object inpout_ioaddress: TEdit
      Left = 24
      Top = 296
      Width = 57
      Height = 21
      TabOrder = 1
      Text = '6300'
    end
    object inpout_iorange: TEdit
      Left = 104
      Top = 296
      Width = 49
      Height = 21
      TabOrder = 2
      Text = '10'
    end
    object inpout_result: TMemo
      Left = 8
      Top = 24
      Width = 145
      Height = 249
      TabOrder = 3
    end
  end
  object GroupBox4: TGroupBox
    Left = 568
    Top = 8
    Width = 177
    Height = 233
    Caption = ' Output '
    TabOrder = 3
    object Label8: TLabel
      Left = 8
      Top = 20
      Width = 55
      Height = 13
      Caption = 'IO-Address:'
    end
    object Label9: TLabel
      Left = 8
      Top = 128
      Width = 153
      Height = 13
      Caption = '------------------  Inpout32 ----------------'
    end
    object Label10: TLabel
      Left = 8
      Top = 184
      Width = 157
      Height = 13
      Caption = '------------------  GwPortIO ----------------'
    end
    object Label11: TLabel
      Left = 8
      Top = 72
      Width = 139
      Height = 13
      Caption = '------------------  Direct ----------------'
    end
    object Label18: TLabel
      Left = 9
      Top = 40
      Width = 11
      Height = 13
      Caption = '0x'
    end
    object Button5: TButton
      Left = 88
      Top = 144
      Width = 75
      Height = 25
      Caption = 'Set to 0xFF'
      TabOrder = 0
      OnClick = Button5Click
    end
    object Button7: TButton
      Left = 8
      Top = 144
      Width = 75
      Height = 25
      Caption = 'Set to 0x00'
      TabOrder = 1
      OnClick = Button7Click
    end
    object output_ioaddress: TEdit
      Left = 24
      Top = 36
      Width = 57
      Height = 21
      TabOrder = 2
      Text = '6300'
    end
    object Button8: TButton
      Left = 8
      Top = 200
      Width = 75
      Height = 25
      Caption = 'Set to 0x00'
      TabOrder = 3
      OnClick = Button8Click
    end
    object Button9: TButton
      Left = 88
      Top = 200
      Width = 75
      Height = 25
      Caption = 'Set to 0xFF'
      TabOrder = 4
      OnClick = Button9Click
    end
    object Button10: TButton
      Left = 8
      Top = 88
      Width = 75
      Height = 25
      Caption = 'Set to 0x00'
      TabOrder = 5
      OnClick = Button10Click
    end
    object Button11: TButton
      Left = 88
      Top = 88
      Width = 75
      Height = 25
      Caption = 'Set to 0xFF'
      TabOrder = 6
      OnClick = Button11Click
    end
  end
  object GroupBox5: TGroupBox
    Left = 568
    Top = 248
    Width = 177
    Height = 153
    Caption = ' Additional functions '
    TabOrder = 4
    object Label19: TLabel
      Left = 8
      Top = 112
      Width = 38
      Height = 13
      Caption = 'Manual:'
    end
    object Label20: TLabel
      Left = 8
      Top = 24
      Width = 49
      Height = 13
      Caption = 'Amplitude:'
    end
    object Label21: TLabel
      Left = 8
      Top = 48
      Width = 24
      Height = 13
      Caption = 'Freq:'
    end
    object Button12: TButton
      Left = 8
      Top = 72
      Width = 153
      Height = 25
      Caption = 'Output sine-wave'
      TabOrder = 0
      OnClick = Button12Click
    end
    object ScrollBar1: TScrollBar
      Left = 8
      Top = 128
      Width = 153
      Height = 16
      Max = 1000
      Min = -1000
      PageSize = 0
      TabOrder = 1
      OnChange = ScrollBar1Change
    end
    object Edit1: TEdit
      Left = 64
      Top = 24
      Width = 97
      Height = 21
      TabOrder = 2
      Text = '90'
    end
    object Edit2: TEdit
      Left = 64
      Top = 48
      Width = 97
      Height = 21
      TabOrder = 3
      Text = '1,0'
    end
  end
end
