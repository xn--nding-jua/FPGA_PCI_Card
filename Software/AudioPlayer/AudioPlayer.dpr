program AudioPlayer;

uses
  Forms,
  mainfrm in 'mainfrm.pas' {mainform},
  audioPlayerThreads in 'audioPlayerThreads.pas',
  pciFunctions in 'pciFunctions.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(Tmainform, mainform);
  Application.Run;
end.
