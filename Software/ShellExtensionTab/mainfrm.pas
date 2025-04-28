unit mainfrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, TVicLib, Hw_Types, ExtCtrls;

type
  Tmainform = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    cardcounterlbl: TLabel;
    Label2: TLabel;
    revisionlbl: TLabel;
    Label3: TLabel;
    locationlbl: TLabel;
    Label4: TLabel;
    commandreglbl: TLabel;
    Label6: TLabel;
    statusreglbl: TLabel;
    Button1: TButton;
    Image1: TImage;
    Label5: TLabel;
    Label7: TLabel;
    procedure Button1Click(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  mainform: Tmainform;

implementation

{$R *.dfm}

procedure Tmainform.Button1Click(Sender: TObject);
var
  buses,bus,dev,func : DWORD;
  Info : TPciCfg;
  hw32 : THandle;
  cardCounter : byte;
begin
  cardCounter := 0;

  HW32 := 0;
  HW32 := OpenTVicHW32(HW32, 'TVicHW32', 'TVicDevice1');

  buses := GetLastPciBus(HW32);
  for bus := 0 to buses do
  begin
    for dev := 0 to 31 do
    begin
      for func := 0 to 7 do
      begin
        if GetPciDeviceInfo(HW32,bus,dev,func,@Info) then
        begin
          // check if this card has the expected VID and VID
          if (info.VendorID = $1172) then
          begin
            // this card has the expected vendor. Now check the ProductID
            if (info.DeviceID = $2524) then
            begin
              cardCounter := cardCounter + 1;
              locationlbl.Caption := 'Bus: ' + inttostr(bus) + ' / Device: ' + inttostr(dev) + ' / Function: ' + inttostr(func);

              commandreglbl.Caption := '0x' + IntToHex(info.command_reg, 4);
              statusreglbl.caption := '0x' + IntToHex(info.status_reg, 4);
              revisionlbl.Caption := IntToHex(info.revisionID, 2);
            end;
          end;
        end;
      end;
    end;
  end;
  CloseTVicHW32(HW32);

  cardcounterlbl.caption := inttostr(cardCounter);
end;

end.
