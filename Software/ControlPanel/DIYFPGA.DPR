// Compile Icon to RES-file: brcc32 Icon.rc

library DIYFPGA;

uses
  Windows,
  mainfrm in 'mainfrm.pas' {mainform},
  myCpl in 'mycpl.pas';

{$E cpl}

{$R Icon.res}

resourcestring
  Name = 'DIY FPGA PCI Card';
  Description = 'Configuration for the DIY FPGA PCI Card';

procedure Start(const Handle: HWND);
begin
  mainform := Tmainform.Create(nil);
  mainform.ShowModal;
  mainform.Free;
end;

function CPlApplet(hwndCpl: HWND; msg: UINT;
  lParam1: LPARAM; lParam2: LPARAM): integer; stdcall;
begin
  case msg of
    CPL_DBLCLK,
    CPL_STARTWPARMS:
      Start(hwndCpl);
    CPL_INIT,
    CPL_STOP,
    CPL_GETCOUNT,
    CPL_NEWINQUIRE:
      begin
        Result := 1;
        exit;
      end;
    CPL_INQUIRE:
      with PCPLINFO(lParam2)^ do begin
        idIcon := 1;
        idName := PResStringRec(@Name)^.Identifier;
        idInfo := PResStringRec(@Description)^.Identifier;
        lData := 0;
      end;
  end;
  Result := 0;
end;

exports
  CPlApplet;

begin
end.
