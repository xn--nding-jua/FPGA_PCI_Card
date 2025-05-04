// This COM server defines a new PropertyPage shell extension.
// It allows the user to control the DIY FPGA PCI Card through
// the regular Windows-property-windows

library fpgatab;

uses
  ComServ,
  fpgaShellExTab in 'fpgaShellExTab.pas',
  mainfrm in 'mainfrm.pas' {mainform};

exports
  DllGetClassObject,
  DllCanUnloadNow,
  DllRegisterServer,
  DllUnregisterServer;
begin
end.
