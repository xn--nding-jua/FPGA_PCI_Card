unit mainfrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, AudioPlayerThreads, ComCtrls, ExtCtrls;

type
  Tmainform = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    audiofileedit: TEdit;
    Label3: TLabel;
    Button1: TButton;
    Button2: TButton;
    Label4: TLabel;
    ioaddressedit: TEdit;
    Label5: TLabel;
    Timer1: TTimer;
    ProgressBar1: TProgressBar;
    Label6: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
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
begin
  // start the audiothread
  killthreads := false;
  AudioThread := TAudioThread.create(StrToInt('$' + ioaddressedit.Text), audiofileedit.Text);
  timer1.Enabled := true;
end;

procedure Tmainform.Button2Click(Sender: TObject);
begin
  killthreads := true;
  timer1.Enabled := false;
end;

procedure Tmainform.Timer1Timer(Sender: TObject);
begin
  progressbar1.position := round(AudioThread.getPosition);
  label6.Caption := floattostrf(AudioThread.getPosition, ffFixed, 5, 2) + '%';
end;

end.
