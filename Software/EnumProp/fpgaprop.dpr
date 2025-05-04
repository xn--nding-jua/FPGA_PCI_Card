library fpgaprop;

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, ShellApi, Dialogs,
  Mainfrm in 'MAINFRM.PAS' {mainform};

{$R Dlg.res}

{ENABLE FAR COMPILING}
{$F+}

const
  PSP_USETITLE = $00000008;
  PSP_USECALLBACK = $00000080;

  WM_NOTIFY = $004E;
  PSPCB_RELEASE = 1;

  IDC_ICON = 100;
  IDD_EMPTYSHEET = 110;
  IDC_TESTBTN = 120;

type
{
  DWORD = Cardinal;
  UINT = Cardinal;
  WPARAM = Word;
  LPARAM = Longint;
  HDEVINFO = Longint;
  ULONG_PTR = Cardinal;
}
  DWORD = LongInt;
  UINT = LongInt;
  WPARAM = Word;
  LPARAM = Longint;
  HDEVINFO = Longint;
  ULONG_PTR = LongInt;

  TGUID = record
    D1: DWORD;
    D2: Word;
    D3: Word;
    D4: array[0..7] of Byte;
  end;

{
  SP_DEVINFO_DATA = packed record
    cbSize : DWORD;
    ClassGuid : TGUID;
    DevInst : DWORD;
    Reserved : ULONG_PTR;
  end;
  TSPDevInfoData = SP_DEVINFO_DATA;
  PSPDevInfoData = ^TSPDevInfoData;

  SP_PROPSHEETPAGE_REQUEST = packed record
    cbSize : DWORD;
    PageRequested : DWORD;
    DeviceInfoSet : HDEVINFO;
    DeviceInfoData : PSPDevInfoData;
  end;
  TSPPropSheetPageRequest = SP_PROPSHEETPAGE_REQUEST;
  PSPPropSheetPageRequest = ^TSPPropSheetPageRequest;

  SP_SETUPINFO = packed record
    DeviceInfoSet : HDEVINFO;
    DeviceInfoData : PSPDevInfoData;
  end;
  TSPSetupInfo = SP_SETUPINFO;
  PSPSetupInfo = ^TSPSetupInfo;
}

  {BLOCK CHECKED AGAINST COMMCTRL.PAS FROM DELPHI7}
  HPropSheetPage = LongInt;
  LPFNADDPROPSHEETPAGE = function(hPSP: HPropSheetPage;
    lParam: LPARAM): Bool;
  TFNAddPropSheetPage = LPFNADDPROPSHEETPAGE;

  {BLOCK CHECKED AGAINST COMMCTRL.PAS FROM DELPHI7}
  PPropSheetPage = ^TPropSheetPage;
  LPFNPSPCALLBACK = function(Wnd: HWND; Msg: UINT;
    PPSP: PPropSheetPage): Integer;
  TFNPSPCallback = LPFNPSPCALLBACK;

  TPropSheetPage = record
    dwSize: LongInt;
    dwFlags: LongInt;
    hInstance: THandle;
    case THandle of
      0: (
        pszTemplate: PChar);
      1: (
        pResource: LongInt;
        case LongInt of
          0: (
            hIcon: THandle);
          1: (
            pszIcon: PChar;
            pszTitle: PChar;
            pfnDlgProc: LongInt;
            lParam: LongInt;
            pfnCallback: TFNPSPCallback;
            pcRefParent: PLongInt;
            pszHeaderTitle: PChar;
            pszHeaderSubTitle: PChar));
  end;

{
var
  info : TSPSetupInfo;
}

function CreatePropertySheetPage(var PSP: TPropSheetPage) : HPropSheetPage; far;
  external 'COMMCTRL.DLL' name 'CreatePropertySheetPage';

function DestroyPropertySheetPage(hPSP: HPropSheetPage) : Bool; far;
  external 'COMMCTRL.DLL' name 'DestroyPropertySheetPage';

{
Win32-API shows different definition. This seems to be right for Win98:
BOOL CALLBACK DlgProc(HWND HDlg, UINT Msg, WPARAM wParam, LPARAM lParam
}
function PropertySheetDlgProc(hDlg: HWND; uMessage: UINT;
  wParam: Word; lParam: Cardinal): BOOL; far;
begin
  Result := True;

  {MessageBox(hDlg, PChar('PropertySheetDlgProc called!'), PChar('Info'), MB_ICONINFORMATION or MB_OK);}

  case uMessage of
    WM_INITDIALOG:
    begin
      {MessageBox(0, PChar('WM_INITDIALOG called!'), PChar('Info'), MB_ICONINFORMATION or MB_OK);}
    end;

    WM_COMMAND:
    begin
      MessageBox(0, PChar('Button Clicked!'), PChar('Yeah!'), MB_ICONINFORMATION or MB_OK);
      {
      16-bit Windows:
      LOWORD(lParam) = 16-bit Handle to Window
      HIWORD(lParam) = Benachrichtigungsnachricht (BN_CLICKED)
      wParam = Bezeichner des Schalters

      32-bit Windows:
      LOWORD(wParam) = ButtonID
      HIWORD(wParam) = notification code
      lParam = handle to the Button
      }
      if (HIWORD(wParam) = BN_CLICKED) then
      begin
        MessageBox(0, PChar('Button Clicked!'), PChar('Yeah!'), MB_ICONINFORMATION or MB_OK);
        case (LOWORD(wParam)) of
          IDC_TESTBTN:
          begin
            MessageBox(0, PChar('Button Clicked!'), PChar('Yeah!'), MB_ICONINFORMATION or MB_OK);
          end;
        end;
      end;
    end;

    else
      Result := False;
  end;
end;

function PropertySheetCallback(Wnd: HWND; Msg: UINT;
  PPSP: PPropSheetPage) : Integer; far;
begin
  MessageBox(0, PChar('PropertySheetCallback is called!'), PChar('Info'), 0);
{
  case Msg of
    PSPCB_RELEASE:
      if PPSP^.lParam <> 0 then
        Dispose(PSPSetupInfo(PPSP^.lParam));
  end;
}
  Result := 1;
end;

{
function FpgaEnumPropPages(p: PSPPropSheetPageRequest;
  lpfnAddPage: TFNAddPropSheetPage; lParam: LPARAM) : BOOL; export;
}
function FpgaEnumPropPages(lpvoid: LongInt;
  lpfnAddPage: TFNAddPropSheetPage; lParam: LPARAM) : BOOL; export;
var
  psp: TPropSheetPage;
  hPage: HPropSheetPage;
begin
  FillChar(psp, SizeOf(psp), 0);
  psp.dwSize := SizeOf(psp);
  {psp.dwFlags := PSP_USETITLE or PSP_USECALLBACK;}
  psp.dwFlags := PSP_USETITLE;

  psp.hInstance := HInstance;
  psp.pszTemplate := MAKEINTRESOURCE(IDD_EMPTYSHEET);

  psp.pszIcon := MAKEINTRESOURCE(IDC_ICON);
  psp.pszTitle := PChar('DIY FPGA PCI Card');
  psp.pfnDlgProc := LongInt(@PropertySheetDlgProc);
  psp.pfnCallback := nil; {TFNPSPCallback;}
  psp.pszHeaderTitle := PChar('TEST');
  psp.pszHeaderSubTitle := PChar('TEST');

{
  info.DeviceInfoSet := p^.DeviceInfoSet;
  info.DeviceInfoData := p^.DeviceInfoData;
  psp.lParam := Integer(@info);
}
  psp.lParam := 42; {send user-defined data to PropertySheetDlgProc}

  hPage := CreatePropertySheetPage(psp);

  if (hPage <> 0) then
  begin
{
    MessageBox(0, PChar('hPage created successfully'), PChar('Hello :-)'), 0);

    ShowMessage('Pointer to hPage = ' + inttostr(Longint(hPage)) + #10#13 +
      'Pointer to pfnDlgProc = ' + inttostr(Longint(psp.pfnDlgProc)));
}
{
    mainform := Tmainform.Create(nil);
    mainform.Show;
}

    if not lpfnAddPage(hPage, lParam) then
    begin
      MessageBox(0, PChar('Something went wrong -> DestroyPropertySheetPage called'), PChar('Hello :-)'), 0);
      DestroyPropertySheetPage(hPage);
    end;
  end else
  begin
    MessageBox(0, PChar('Failed to create hPage'), PChar('Hello :-)'), 0);
  end;

  Result := TRUE;
end;

exports
  FpgaEnumPropPages;

begin

end.
