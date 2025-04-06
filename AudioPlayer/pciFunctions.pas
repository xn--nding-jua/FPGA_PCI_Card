unit pciFunctions;

interface

uses windows;

procedure WriteIOAddress(Addr: DWORD; value: DWORD; size: byte);
function ReadIOAddress(Addr: DWORD; size: byte): DWORD;
procedure WritePCIMemory(VirtAddr: DWORD; value: DWORD);
function ReadPCIMemory(VirtAddr: DWORD; size: byte): DWORD;

implementation

procedure WriteIOAddress(Addr: DWORD; value: DWORD; size: byte);
begin
  if (size = 1) then
  begin
    asm
      push EAX; // Sichern des EAX-Registers
  
      mov EAX, Addr; // Adresse in EAX laden
      mov DX, AX; // Untere 16 Bit der Adresse in DX laden
  
      mov AL, byte(value); // load value to AL
      out DX, AL; // write 8-bit value
  
      pop EAX; // EAX-Register wiederherstellen
    end; {asm}
  end else if (size = 2) then
  begin
    asm
      push EAX; // Sichern des EAX-Registers
  
      mov EAX, Addr; // Adresse in EAX laden
      mov DX, AX; // Untere 16 Bit der Adresse in DX laden
  
      mov AX, word(value); // load value to AX
      out DX, AX; // write 16-bit value
  
      pop EAX; // EAX-Register wiederherstellen
    end; {asm}
  end else if (size = 4) then
  begin
    asm
      push EAX; // Sichern des EAX-Registers
  
      mov EAX, Addr; // Adresse in EAX laden
      mov DX, AX; // Untere 16 Bit der Adresse in DX laden
  
      mov EAX, value; // load value to EAX
      out DX, EAX; // write 32-bit value ("out" uses DX for the address and EAX for the value)

      pop EAX; // EAX-Register wiederherstellen
    end; {asm}
  end;
end;

function ReadIOAddress(Addr: DWORD; size: byte): DWORD;
var
  b: byte;
  w: word;
begin
  if (size = 1) then
  begin
    asm
      push EAX; // Sichern des EAX-Registers

      mov EAX, Addr; // Adresse in EAX laden
      mov DX, AX; // Untere 16 Bit der Adresse in DX laden

      // read byte
      in  AL, DX; // read value to 8-bit AL
      mov b, AL; // AL in a speichern

      pop EAX; // EAX-Register wiederherstellen
    end; {asm}
    ReadIOAddress := b;
  end else if (size = 2) then
  begin
    asm
      push EAX; // Sichern des EAX-Registers

      mov EAX, Addr; // Adresse in EAX laden
      mov DX, AX; // Untere 16 Bit der Adresse in DX laden

      // read word
      in  AX, DX; // read value to 16-bit AX
      mov w, AX; // AX in w speichern

      pop EAX; // EAX-Register wiederherstellen
    end; {asm}
    ReadIOAddress := w;
  end else if (size = 4) then
  begin
    asm
      push EAX; // Sichern des EAX-Registers

      mov EAX, Addr; // Adresse in EAX laden
      mov DX, AX; // Untere 16 Bit der Adresse in DX laden

      // read DWORD
      in  EAX, DX; // read value to 32-bit EAX
      mov @Result, EAX;

      pop EAX; // EAX-Register wiederherstellen
    end; {asm}
  end;
end;

procedure WritePCIMemory(VirtAddr: DWORD; value: DWORD);
begin
  asm
    push EAX; // Sichern des EAX-Registers
	
    mov EAX, VirtAddr; // Adresse in EAX laden
    mov EBX, value; // Wert in EBX laden
	
    mov EDI, EAX; // Zieladresse in EDI (Zielindexregister für Speicherzugriffe) speichern
    mov ESI, EBX; // Wert in ESI (Quellindexregister für Speicherzugriffe) speichern
	
    mov [EDI], ESI; // 32-Bit-Wert an die Zieladresse schreiben (Klammern = Registerinhalt als Speicheradresse verwenden)
	
    pop EAX; // EAX-Register wiederherstellen
  end; {asm}
end;

function ReadPCIMemory(VirtAddr: DWORD; size: byte): DWORD;
var
  b: byte;
  w: word;
begin
  if (size = 1) then
  begin
    asm
      push EAX; // Sichern des EAX-Registers
  	
      mov EAX, VirtAddr; // Adresse in EAX laden
  
      // 8-bit-Wert lesen
      mov AL, [EAX]; // Wert aus Zieladresse lesen (Klammern = Registerinhalt als Speicheradresse verwenden)
      mov b, AL; // 8-bit-Wert aus Ergebnisregister lesen
      
      pop EAX; // EAX-Register wiederherstellen
    end; {asm}
    ReadPCIMemory := b;
  end else if (size = 2) then
  begin
    asm
      push EAX; // Sichern des EAX-Registers
  	
      mov EAX, VirtAddr; // Adresse in EAX laden
  
      // 16-bit-Wert lesen
      mov AX, [EAX]; // Wert aus Zieladresse lesen (Klammern = Registerinhalt als Speicheradresse verwenden)
      mov w, AX; // 16-bit-Wert aus Ergebnisregister lesen

      pop EAX; // EAX-Register wiederherstellen
    end; {asm}
    ReadPCIMemory := w;
  end else if (size = 4) then
  begin
    asm
      push EAX; // Sichern des EAX-Registers
  	
      mov EAX, VirtAddr; // Adresse in EAX laden
  	
      // 32-bit-Wert lesen
      mov EAX, [EAX]; // Wert aus Zieladresse lesen (Klammern = Registerinhalt als Speicheradresse verwenden)
      mov @Result, EAX; // 32-bit-Wert aus Ergebnisregister lesen
  
      pop EAX; // EAX-Register wiederherstellen
    end; {asm}
  end;
end;

end.