unit mainfrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, AudioPlayerThreads, ComCtrls, ExtCtrls, pciFunctions,
  Math;

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
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure ScrollBar1Change(Sender: TObject);
    procedure volumesliderChange(Sender: TObject);
  private
    { Private-Deklarationen }
    AudioThread: TAudioThread;
  public
    { Public-Deklarationen }
    killthreads:boolean;
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
  AudioThread := TAudioThread.create(StrToInt('$' + ioaddressedit.Text), buffersize, audiofileedit.Text);
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

end.
