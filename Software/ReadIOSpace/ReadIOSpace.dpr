program ReadIOSpace;

uses
  Forms,
  mainfrm in 'mainfrm.pas' {mainform},
  pci_functions in 'pci_functions.pas',
  gwiopm in 'gwiopm.pas',
  gwportio in 'gwportio.pas',
  InpOut32 in 'InpOut32.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'FPGA Test';
  Application.CreateForm(Tmainform, mainform);
  Application.Run;
end.
