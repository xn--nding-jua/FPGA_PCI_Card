unit mainfrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, AudioPlayerThreads, ComCtrls, ExtCtrls, pciFunctions,
  Math, TVicLib, Hw_Types;

type
  Tmainform = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    GroupBox1: TGroupBox;
    ScrollBar1: TScrollBar;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    GroupBox2: TGroupBox;
    Label3: TLabel;
    Label6: TLabel;
    audiofileedit: TEdit;
    Button1: TButton;
    Button2: TButton;
    ProgressBar1: TProgressBar;
    Timer1: TTimer;
    GroupBox3: TGroupBox;
    Label4: TLabel;
    Label5: TLabel;
    ioaddressedit: TEdit;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    buffersizeedit: TEdit;
    Label14: TLabel;
    volumeslider: TTrackBar;
    Label15: TLabel;
    Label16: TLabel;
    isrcalllbl: TLabel;
    pollingbtn: TRadioButton;
    irqbtn: TRadioButton;
    irqedit: TEdit;
    Label17: TLabel;
    GroupBox4: TGroupBox;
    pciinfo: TMemo;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure ScrollBar1Change(Sender: TObject);
    procedure volumesliderChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button3Click(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
    killthreads:boolean;
    irqCounter : Cardinal;
    AudioThread: TAudioThread;
  end;

var
  mainform: Tmainform;

implementation

{$R *.dfm}

procedure Tmainform.Button1Click(Sender: TObject);
var
  buffersize: word;
begin
  // limit buffersize to 400ms as we have only 32kB of SRAM per channel
  // so we can buffer maximum of 743ms
  buffersize := StrToInt(buffersizeedit.text);
  if buffersize > 700 then
    buffersize := 700;

  // start the audiothread
  killthreads := false;
  AudioThread := TAudioThread.create(StrToInt('$' + ioaddressedit.Text), buffersize, audiofileedit.Text, pollingbtn.Checked, strtoint(irqedit.Text));
  timer1.Enabled := true;

  // set volume
  AudioThread.setVolume(100 - volumeslider.Position);
end;

procedure Tmainform.Button2Click(Sender: TObject);
begin
  killthreads := true;
  timer1.Enabled := false;
end;

procedure Tmainform.Timer1Timer(Sender: TObject);
var
  bufferState : integer;
begin
  progressbar1.position := round(AudioThread.getPosition);
  label6.Caption := floattostrf(AudioThread.getPosition, ffFixed, 5, 2) + '%';

  bufferState := AudioThread.getBufferSize;
  label12.Caption := inttostr(bufferState) + ' Samples / ' + floattostrf((bufferState/44100)*1000, ffFixed, 5, 2) + 'ms';

  isrcalllbl.Caption := inttostr(irqCounter) + ' ISR-Calls';
end;

procedure Tmainform.ScrollBar1Change(Sender: TObject);
var
  ioaddress : integer;
begin
  ioaddress := StrToInt('$' + ioaddressedit.text);

  WriteIOAddress(ioaddress, round(power(2, 23) * (scrollbar1.position/1000)), 4);
end;

procedure Tmainform.volumesliderChange(Sender: TObject);
begin
  AudioThread.setVolume(100 - volumeslider.Position);
end;

procedure Tmainform.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  killthreads := true;
  timer1.Enabled := false;
end;

procedure Tmainform.Button3Click(Sender: TObject);
var
  buses,bus,dev,func : DWORD;
  Info : TPciCfg;
  hw32 : THandle;
begin
  pciinfo.Lines.Clear;
  pciinfo.Lines.Add('bus/dev/func ClassID VID PID Revision');
  pciinfo.Lines.Add('================================');

  HW32 := 0;
  HW32 := OpenTVicHW32(HW32, 'TVicHW32', 'TVicDevice1');

  buses := GetLastPciBus(HW32);
  for bus := 0 to buses do
  begin
    for dev := 0 to 31 do
    begin
      for func := 0 to 7 do
      begin
        if GetPciDeviceInfo(HW32,bus,dev,func,@Info) then
        begin
          pciinfo.Lines.Add(IntToHex(bus, 2) + '/' + IntToHex(dev, 2) + '/' + IntToHex(func, 2) +
                 ' ClassID: ' + IntToHex(Info.ClassCode, 2) +
                 ' VID: ' + IntToHex(info.VendorID, 4) +
                 ' PID: ' + IntToHex(Info.DeviceID, 4) +
                 ' Rev: ' + IntToHex(info.revisionID, 2));
        end;
      end;
    end;
  end;
  CloseTVicHW32(HW32);
end;

end.
