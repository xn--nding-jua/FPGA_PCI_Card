unit mycpl;

interface

const
  // source of this constants: microsoft.github.io/windows-docs-rs/doc/windows/Win32/UI/Shell/index.html
  CPL_DBLCLK = 5;
  CPL_STARTWPARMS = 10;
  CPL_INIT = 1;
  CPL_STOP = 6;
  CPL_GETCOUNT = 2;
  CPL_NEWINQUIRE = 8;
  CPL_INQUIRE = 3;

type
  tagCPLINFO = packed record
    idIcon : Integer;
    idName : Integer;
    idInfo : Integer;
    lData : LongInt;
  end;
  TCPLInfo = tagCPLINFO;
  PCPLINFO = ^TCPLInfo;

implementation

end.
