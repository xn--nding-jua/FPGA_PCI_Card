unit mainfrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, gwiopm, gwportio, InpOut32, pciFunctions, ExtCtrls, Math;

type
  IntAsBytes = packed record
    b0, b1, b2, b3: byte;
  end;

  Tmainform = class(TForm)
    GroupBox1: TGroupBox;
    Button1: TButton;
    win9x_ioaddress: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    win9x_iorange: TEdit;
    win9x_result: TMemo;
    GroupBox2: TGroupBox;
    Label3: TLabel;
    Label4: TLabel;
    Button2: TButton;
    ioaddress: TEdit;
    iorange: TEdit;
    gwportio_result: TMemo;
    Button3: TButton;
    Button4: TButton;
    GroupBox3: TGroupBox;
    Label5: TLabel;
    Label6: TLabel;
    Button6: TButton;
    inpout_ioaddress: TEdit;
    inpout_iorange: TEdit;
    inpout_result: TMemo;
    Label7: TLabel;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    RadioButton3: TRadioButton;
    GroupBox4: TGroupBox;
    Button5: TButton;
    Button7: TButton;
    Label8: TLabel;
    output_ioaddress: TEdit;
    Label9: TLabel;
    Label10: TLabel;
    Button8: TButton;
    Button9: TButton;
    Button10: TButton;
    Button11: TButton;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    GroupBox5: TGroupBox;
    Button12: TButton;
    ScrollBar1: TScrollBar;
    Label19: TLabel;
    Edit1: TEdit;
    Label20: TLabel;
    Label21: TLabel;
    Edit2: TEdit;
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure Button11Click(Sender: TObject);
    procedure Button12Click(Sender: TObject);
    procedure ScrollBar1Change(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  mainform: Tmainform;

implementation

{$R *.dfm}

{
  Windows9x allows access to IO-Ports directly if they are not occupied by a
  driver. If a driver is using an IO-Port, Windows traps the access to the
  IO-port.

  inp()
  outp()  
}

procedure Tmainform.Button1Click(Sender: TObject);
var
  i : integer;
  byteToRead : integer;
  iostart, ioend : integer;
begin
  iostart := StrToInt('$' + win9x_ioaddress.text);
  ioend := iostart + StrToInt('$' + win9x_iorange.text);

  if RadioButton1.Checked then
  begin
    byteToRead := 1;
  end else if RadioButton2.Checked then
  begin
    byteToRead := 2;
  end else if RadioButton3.Checked then
  begin
    byteToRead := 4;
  end else
  begin
    byteToRead := 4;
  end;

  i := iostart;
  repeat
    win9x_result.Lines.Add('0x' + inttohex(i, 4) + ' = 0x' + inttohex(ReadIOAddress(i, byteToRead), byteToRead*2));

    // increase address for next reading
    i := i + byteToRead;
  until i >= ioend;
end;

procedure Tmainform.Button3Click(Sender: TObject);
begin
  gwportio_result.lines.add('Opening SCM...');
  gwportio_result.Lines.Add('  ' + GWIOPM_Driver.ErrorLookup(GWIOPM_Driver.OpenSCM));

  gwportio_result.lines.add('Installing driver...');
  gwportio_result.Lines.Add('  ' + GWIOPM_Driver.ErrorLookup(GWIOPM_Driver.Install(''))); // new driver-path ('' for default)

  gwportio_result.lines.add('Starting driver...');
  gwportio_result.Lines.Add('  ' + GWIOPM_Driver.ErrorLookup(GWIOPM_Driver.Start));

  gwportio_result.lines.add('Opening device...');
  gwportio_result.Lines.Add('  ' + GWIOPM_Driver.ErrorLookup(GWIOPM_Driver.DeviceOpen));
end;

procedure Tmainform.Button4Click(Sender: TObject);
begin
  gwportio_result.lines.add('Closing device...');
  gwportio_result.Lines.Add('  ' + GWIOPM_Driver.ErrorLookup(GWIOPM_Driver.DeviceClose));

  gwportio_result.lines.add('Stopping driver...');
  gwportio_result.Lines.Add('  ' + GWIOPM_Driver.ErrorLookup(GWIOPM_Driver.Stop));

  gwportio_result.lines.add('Removing driver...');
  gwportio_result.Lines.Add('  ' + GWIOPM_Driver.ErrorLookup(GWIOPM_Driver.Remove));

  gwportio_result.lines.add('Closing SCM...');
  gwportio_result.Lines.Add('  ' + GWIOPM_Driver.ErrorLookup(GWIOPM_Driver.CloseSCM));
end;

procedure Tmainform.Button2Click(Sender: TObject);
var
  i : integer;
  b : byte;
  iostart, ioend : integer;
begin
  iostart := StrToInt('$' + ioaddress.text);
  ioend := iostart + StrToInt('$' + iorange.text);

  // increment byte-wise over all io-adresses in the given range
  for i := iostart to ioend do
  begin
    GWIOPM_Driver.IOCTL_IOPMD_GET_LIOPMB(i, b);
    gwportio_result.Lines.Add('0x' + inttohex(i, 4) + ' = 0x' + inttohex(b, 2));
  end;
end;

procedure Tmainform.Button6Click(Sender: TObject);
var
  i : integer;
  iostart, ioend : integer;
begin
  iostart := StrToInt('$' + inpout_ioaddress.text);
  ioend := iostart + StrToInt('$' + inpout_iorange.text);

  // increment byte-wise over all io-adresses in the given range
  for i := iostart to ioend do
  begin
    inpout_result.Lines.Add('0x' + inttohex(i, 4) + ' = 0x' + inttohex(Inp32(i), 2));
  end;

  if IsInpOutDriverOpen then
    ShowMessage('OK');
end;

procedure Tmainform.Button7Click(Sender: TObject);
var
  ioaddress : integer;
begin
  ioaddress := StrToInt('$' + output_ioaddress.text);
  Out32(ioaddress, 0);
end;

procedure Tmainform.Button5Click(Sender: TObject);
var
  ioaddress : integer;
begin
  ioaddress := StrToInt('$' + output_ioaddress.text);
  Out32(ioaddress, 255);
end;

procedure Tmainform.Button8Click(Sender: TObject);
var
  ioaddress : integer;
begin
  ioaddress := StrToInt('$' + output_ioaddress.text);
  GWIOPM_Driver.IOCTL_IOPMD_SET_LIOPM(ioaddress, 0);
end;

procedure Tmainform.Button9Click(Sender: TObject);
var
  ioaddress : integer;
begin
  ioaddress := StrToInt('$' + output_ioaddress.text);
  GWIOPM_Driver.IOCTL_IOPMD_SET_LIOPM(ioaddress, 255);
end;

procedure Tmainform.Button10Click(Sender: TObject);
var
  ioaddress : integer;
begin
  ioaddress := StrToInt('$' + output_ioaddress.text);
  WriteIOAddress(ioaddress, 0, 4);
end;

procedure Tmainform.Button11Click(Sender: TObject);
var
  ioaddress : integer;
begin
  ioaddress := StrToInt('$' + output_ioaddress.text);
  WriteIOAddress(ioaddress, 255, 4);
end;

procedure Tmainform.Button12Click(Sender: TObject);
var
  ioaddress : integer;
  i, periodes : integer;
  t, value, amplitude, freq : single;
begin
  ioaddress := StrToInt('$' + output_ioaddress.text);

  amplitude := StrToInt(edit1.text) / 100;
  periodes := 100000;
  freq := StrToFloat(edit2.Text);
  for i:=0 to 20 * periodes do
  begin
    t := (i/1000); // convert to ms
    value := amplitude * sin(2 * 3.141 * freq * t);
    WriteIOAddress(ioaddress, round(value * power(2, 23)), 4);
  end;
end;

procedure Tmainform.ScrollBar1Change(Sender: TObject);
var
  ioaddress : integer;
begin
  ioaddress := StrToInt('$' + output_ioaddress.text);

  WriteIOAddress(ioaddress, round(power(2, 23) * (scrollbar1.position/1000)), 4);
end;

end.
