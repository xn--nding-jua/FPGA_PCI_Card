unit fpgaShellExTab;

{$R 'DLG.res'}

interface

uses
  Windows, ActiveX, Classes, ComObj, CommCtrl, ShlObj, SysUtils, Messages,
  Dialogs, ComCtrls, Graphics, ExtCtrls, Registry, mainfrm;

type
  TPropertySheet = class(TComObject, IShellExtInit, IShellPropSheetExt)
  private
    function IShellExtInit.Initialize = InitShellExtension;
  protected
    { IShellExtInit }
    function InitShellExtension(pidlFolder: PItemIDList; lpdobj: IDataObject;
      hKeyProgID: HKEY): HResult; stdcall;
    { IShellPropSheetExt }
    function AddPages(lpfnAddPage: TFNAddPropSheetPage;
      lParam: LPARAM): HResult; stdcall;
    function ReplacePage(uPageID: UINT; lpfnReplaceWith: TFNAddPropSheetPage;
      lParam: LPARAM): HResult; stdcall;
  end;

  TPropertySheetFactory = class(TComObjectFactory)
  public
    procedure UpdateRegistry(Register: Boolean); override;
  end;

const
  Class_DiyFpgaPropertySheet: TGUID = '{21C1AC3C-8392-4E9C-A8DD-4D3EEEF5729C}';

implementation

uses ComServ, ShellAPI, AxCtrls, Controls;

const
  IDD_EMPTYSHEET = 100;  // empty dialog
  IDD_ICON       = 110;

  // following components are only for testing
  IDD_PROPSHEET  = 120;  // test-dialog
  IDC_LISTBOX    = 130;
  IDC_OPENBTN    = 140;

function PropertySheetDlgProc(hDlg: HWND; uMessage: UINT;
  wParam: WPARAM; lParam: LPARAM): Boolean; stdcall;
//var
  //psp: PPropSheetPage;
  //Sheet: TPropertySheet;
  //FName : PChar;
  //buffer: array[0..255] of char;
begin
  Result := True;

  case uMessage of
    WM_INITDIALOG:
    begin
      // create parented VCL-Form and inject it into the calling handle
      mainform := Tmainform.CreateParented(hDlg);
      mainform.Show;

      // get the current property sheet
      //psp := PPropSheetPage(lParam);
      //Sheet := TPropertySheet(psp.lParam);

      // here code to do something with the property sheet page
      // Write some text to Listbox (tested)
      //ZeroMemory(@buffer, sizeof(buffer));
      //lstrcpy(buffer, PChar('Hello From my Code!'));
      //SendDlgItemMessage(hDlg, IDC_LISTBOX, LB_ADDSTRING, 0, integer(@buffer));

      // here some more examples on how to interact with components (yet untested)
      //MyListbox := GetDlgItem(hDlg, 2); // with this we can access dialog-items
      //New(FName);
      //SendMessage(MyListbox, LB_ADDSTRING, 0, Integer(FName));
      //FName:=nil;
      //SendMessage(MyListbox, LB_SETHORIZONTALEXTENT, 500, 0);
    end;

{
    // WM_COMMAND is used, when we are not using the VCL-forms, but the Resource-File
    // for our form
    WM_COMMAND:
    begin
      if (HIWORD(wParam) = BN_CLICKED) then
      begin
        case (LOWORD(wParam)) of
          IDC_OPENBTN:
          begin
            MessageBox(HInstance, PChar('Button Clicked!'), PChar('Yeah!'), MB_ICONINFORMATION or MB_OK);
          end;
        end;
      end;
      Result := False; // not used at the moment
    end;
}

    WM_NOTIFY:
    begin
      if (PNMHDR(lParam).code = PSN_APPLY) then
      begin
        // the "OK"-Button of the Parent-Dialog has been clicked
        //MessageBox(HInstance, PChar('Apply-Button clicked!'), PChar('Yeah!'), MB_ICONINFORMATION or MB_OK);
      end;
    end;

    else
      Result := False;
  end;
end;

function PropertySheetCallback(hWnd: HWND; uMessage: UINT;
  var psp: TPropSheetPage): UINT; stdcall;
begin
  case uMessage of
    PSPCB_RELEASE:
      if psp.lParam <> 0 then
        // Allow the class to be released
        TPropertySheet(psp.lParam)._Release;
  end;
  Result := 1;
end;

{ TPropertySheet }
function TPropertySheet.InitShellExtension(pidlFolder: PItemIDList;
  lpdobj: IDataObject; hKeyProgID: HKEY): HResult; stdcall;
begin
  Result := NOERROR;
end;

function TPropertySheet.AddPages(lpfnAddPage: TFNAddPropSheetPage;
  lParam: LPARAM): HResult;
var
  psp: TPropSheetPage;
  hPage: HPropSheetPage;
begin
  FillChar(psp, SizeOf(psp), 0);
  psp.dwSize := SizeOf(psp);
  psp.dwFlags := PSP_USETITLE or PSP_USECALLBACK;
  psp.hInstance := HInstance;
  psp.pszTemplate := MAKEINTRESOURCE(IDD_EMPTYSHEET);
  psp.pszTitle := PChar('DIY FPGA PCI Card');
  psp.pszIcon := MAKEINTRESOURCE(IDD_ICON);
  //psp.hIcon := LoadImage(hInstance, MAKEINTRESOURCE(IDD_ICON), IMAGE_ICON, 0, 0, 0);
  //psp.hIcon := LoadImage(hInstance, PChar('C:\Chris\ShellExtensionTab\Icon.ico'), IMAGE_ICON, 0, 0, LR_DEFAULTSIZE or LR_LOADFROMFILE);
  psp.pfnDlgProc := @PropertySheetDlgProc;
  psp.pfnCallback := @PropertySheetCallback;
  psp.lParam := Integer(Self); // points to the TPropertySheet instance

  hPage := CreatePropertySheetPage(psp);

  if hPage <> nil then
  begin
    if not lpfnAddPage(hPage, lParam) then
    begin
      DestroyPropertySheetPage(hPage);
    end;
  end;

   // Prevent the class from being destroyed before the COM server is destroyed.
  _AddRef;

  Result := NOERROR;
end;

function TPropertySheet.ReplacePage(uPageID: UINT;
  lpfnReplaceWith: TFNAddPropSheetPage; lParam: LPARAM): HResult;
begin
  Result := E_NOTIMPL;
end;

{ TPropertySheetFactory }

procedure TPropertySheetFactory.UpdateRegistry(Register: Boolean);
const
  //Key = '*\shellex\PropertySheetHandlers\';
  Key = 'Software\Microsoft\Windows\CurrentVersion\Controls Folder\Display\shellex\PropertySheetHandlers\';
var
  Registry : TRegistry;
begin
  inherited UpdateRegistry(Register);
{
  // write to HKEY_CLASSES_ROOT
  if Register then
    CreateRegKey(Key + ClassName, '', GUIDToString(ClassID))
  else
    DeleteRegKey(Key + ClassName);
}

  // write to HKEY_LOCAL_MACHINE
  Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_LOCAL_MACHINE;
    if Registry.OpenKey(Key + ClassName, true) then
    begin
      Registry.WriteString('', GUIDToString(ClassID));
    end;
  finally
    Registry.Free;
  end;
end;

initialization
  TPropertySheetFactory.Create(ComServer, TPropertySheet, Class_DiyFpgaPropertySheet,
    'DiyFpgaPropertySheet', 'DIY FPGA', ciMultiInstance, tmApartment);

finalization

end.
