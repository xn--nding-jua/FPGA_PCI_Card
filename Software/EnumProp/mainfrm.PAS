unit Mainfrm;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls;

type
  Tmainform = class(TForm)
    Button1: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure Button1Click(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  mainform: Tmainform;

implementation

{$R *.DFM}

procedure Tmainform.Button1Click(Sender: TObject);
begin
  ShowMessage('Well, that''s working - obviously :)');
end;

end.
