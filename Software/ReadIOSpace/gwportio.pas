unit gwportio;
{-----------------------------------------------
Functions for accessing I/O Ports with Delphi 2 and 3.
These work as-is under Win95 (and presumably Win98).

However, use of I/O instructions by "user-mode" applications
under NT is blocked by by the IO Permissions mechanism.
To get around that, use gwiopm unit etc.

Revisions
----------
98-05-23 GW original

------------------------------------------------}
interface
uses windows, winsvc;

//-----------------------------------
// lowest-complexity I/O port functions
//-----------------------------------

function  PortIn(  PortNum: Word)  : byte;
procedure PortOut( PortNum: Word; a: byte);

function  PortInW( PortNum: Word)  : word;
procedure PortOutW(PortNum: Word; a: word);

function  PortInL( PortNum: Word)  : longint;
procedure PortOutL(PortNum: Word; a: longint);

//-------------------------------------------
implementation
//-------------------------------------------

//-----------------------------------------
function  PortIn( PortNum: Word): byte;
//-----------------------------------------
Var a : byte;
Begin
  asm
    mov DX, PortNum;
    in  AL, DX;
    mov a, AL;
  end; {asm}
  PortIn := a;
end;

//-----------------------------------------
procedure PortOut( PortNum: Word; a: byte);
//-----------------------------------------
Begin
  asm
    mov DX, PortNum;
    mov AL, a;
    out DX, AL;
  end; {asm}
end;

//-----------------------------------------
function  PortInW( PortNum: Word): word;
//-----------------------------------------
Var a : word;
Begin
  asm
    mov DX, PortNum;
    in  AX, DX;
    mov a, AX;
  end; {asm}
  PortInW := a;
end;

//-----------------------------------------
procedure PortOutW( PortNum: Word; a: word);
//-----------------------------------------
Begin
  asm
    mov DX, PortNum;
    mov AX, a;
    out DX, AX;
  end; {asm}
end;

//-----------------------------------------
function  PortInL( PortNum: Word): longint;
//-----------------------------------------
Var a : longint;
Begin
  asm
    mov DX, PortNum;
    in  EAX, DX;
    mov a, EAX;
  end; {asm}
  PortInL := a;
end;

//-----------------------------------------
procedure PortOutL( PortNum: Word; a: longint);
//-----------------------------------------
Begin
  asm
    mov DX, PortNum;
    mov EAX, a;
    out DX, EAX;
  end; {asm}
end;

end.

