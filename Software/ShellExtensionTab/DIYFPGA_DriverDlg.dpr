// This COM server defines a new PropertyPage shell extension.
// It allows the user to control the DIY FPGA PCI Card through
// the regular Windows-property-windows

library DIYFPGA_DriverDlg;

uses
  ComServ,
  DIYFPGA_ShellExTab in 'DIYFPGA_ShellExTab.pas',
  mainfrm in 'mainfrm.pas' {mainform};

exports
  DllGetClassObject,
  DllCanUnloadNow,
  DllRegisterServer,
  DllUnregisterServer;

begin
end.
