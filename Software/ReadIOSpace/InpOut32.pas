{Get the two important inpout32.dll entries}
unit InpOut32;
interface
function Inp32(address:Word):Byte;stdcall;
procedure Out32(address:Word; value:Byte);stdcall;
function IsInpOutDriverOpen:Boolean;stdcall;

implementation
{$IFDEF WIN64}
 const DllName='InpOutX64';
{$ELSE}
 const DllName='InpOut32';
{$ENDIF}
function Inp32(address:Word):Byte;stdcall; external DllName index 1;
procedure Out32(address:Word; value:Byte);stdcall; external DllName index 2;
function IsInpOutDriverOpen:Boolean;stdcall; external DllName index 3;
{The "index" reduces executable size a bit.}

end.
