unit audioPlayerThreads;

interface

uses Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, pciFunctions, TVicLib, Hw_Types;

type
  TWavRiffHeader = packed record
    ID: array[0..3] of ansichar;        // "RIFF" for little-endian, "RIFX" for big-endian
    ChunkSize: LongInt;                 // Filesize - 8
    RiffType: array[0..3] of ansiChar;  // "WAVE"
  end;

  TWavFmtSubchunk = packed record
    ID: array[0..3] of ansichar;  // "fmt "
    SubChunkSize: LongInt;   // 16
    AudioFormat: SmallInt;   // PCM = 1 --> uncompressed
    NumChannels: SmallInt;   // Mono = 1, Stereo = 2
    SampleRate: LongInt;     // 8000, 44100 etc.
    ByteRate: LongInt;       // SampleRate * NumChannels * BitsPerSample / 8
    BlockAlign: SmallInt;    // NumChannels * BitsPerSample / 8
    BitsPerSample: SmallInt; // 8, 16
  end;

  TWavDataSubchunk = packed record
    ID: array[0..3] of ansichar;  // "data"
    DataSize: LongInt;            // NumSamples * NumChannels * BitsPerSample / 8
                                  // or: size of following data part.
  end;

  TAudioThread = class(TThread)
  private
    audioBigEndian: Boolean;
    audioHeader : TWavFmtSubchunk;
    numSamples: Integer;
    sampleCounter : Cardinal;

    // variables for IRQ-Access
    hw32 : THandle;
    ClearRec : TIrqClearRec;

    function readAudioFormat(AStream: TStream):boolean;
    function readAudioHeader(AStream: TStream):boolean;
    function seekAudioData(AStream: TStream):Integer; // returns number of samples
    function readAudioSample(AStream: TStream; var sample: SmallInt):boolean;
  protected
    _ioaddress: DWORD;
    _audiofile: String;
    _volume: byte;
    _pollingMode : boolean; // true = pollingMode, false = irqMode
    _irq : byte;
    bufferSizeSamples: Word;
    audioPosition, audioSize: integer;
    audioStream: TStream;

    procedure openPciDriver;
    procedure closePciDriver;
    procedure Execute; override;
  public
    constructor create(ioaddress: DWORD; bufferSizeMillis: Word; audiofile: String; pollingMode: Boolean; IRQ: byte);
    function getPosition:single;
    function getBufferSize:integer;
    procedure setVolume(volume: byte);
    function txAudioDataChunk:boolean;
  end;

implementation

uses mainfrm;

// more information: https://github.com/wp-xyz/WavViewer/blob/master/source/wvmain.pas
function TAudioThread.readAudioFormat(AStream: TStream):boolean;
var
  riff: TWavRiffHeader;
begin
  Result := false;

  if AStream.Read(riff{%H-}, SizeOf(riff)) <> SizeOf(riff) then
  begin
    MessageBox(0, PChar(Format('File "%s" is damaged!', [_audiofile])), PChar('Fehler'), MB_OK);
    exit;
  end;

  if not (riff.ID[0] = 'R') and (riff.ID[1] = 'I') and (riff.ID[2] = 'F') then
  begin
    MessageBox(0, PChar(Format('File "%s" is not a valid WAVE-file!', [_audiofile])), PChar('Fehler'), MB_OK);
    exit;
  end;

  if riff.ID[3] = 'F' then       // 'RIFF' --> little endian
    audioBigEndian := false
  else if riff.ID[3] = 'X' then  // 'RIFX' --> big endian
    audioBigEndian := true
  else
  begin
    MessageBox(0, PChar(Format('File "%s" is not a valid WAVE-file!', [_audiofile])), PChar('Fehler'), MB_OK);
    exit;
  end;

  if not ((riff.RiffType[0]='W') and (riff.RiffType[1]='A') and (riff.RiffType[2]='V') and (riff.RiffType[3]='E')) then
  begin
    MessageBox(0, PChar(Format('File "%s" is not a valid WAVE-file!', [_audiofile])), PChar('Fehler'), MB_OK);
    exit;
  end;

  Result := true;
end;

function TAudioThread.readAudioHeader(AStream: TStream):boolean;
var
  n: Int64;
begin
  Result := false;

  // Read the header
  n := AStream.Read(audioHeader, SizeOf(audioHeader));

  // Check the header
  if n <> SizeOf(audioHeader) then begin
    MessageBox(0, PChar(Format('File "%s" is damaged!', [_audiofile])), PChar('Fehler'), MB_OK);
    exit;
  end;
  if not ((audioHeader.ID[0]='f') and (audioHeader.ID[1]='m') and (audioHeader.ID[2]='t') and (audioHeader.ID[3]=' ')) then
  begin
    MessageBox(0, PChar(Format('File "%s" is not a valid WAVE-file!', [_audiofile])), PChar('Fehler'), MB_OK);
    exit;
  end;

{
  // Fix endianness, if needed
  if audioBigEndian then
  begin
    audioHeader.SubChunkSize := BEToN(FHeader.SubChunkSize);
    audioHeader.AudioFormat := BEToN(FHeader.AudioFormat);
    audioHeader.NumChannels := BEToN(FHeader.NumChannels);
    audioHeader.SampleRate := BEToN(FHeader.SampleRate);
    audioHeader.ByteRate := BEToN(FHeader.ByteRate);
    audioHeader.BitsPerSample := BEToN(FHeader.BitsPerSample);
  end;

  // Display header information
  if FHeader.AudioFormat = 1 then
    edAudioFormat.Text := 'PCM (uncompressed)'
  else
    edAudioFormat.Text := '[not supported]';
  edNumChannels.Text := IntToStr(audioHeader.NumChannels);
  edSampleRate.Text := IntToStr(audioHeader.SampleRate);
  edByteRate.Text := IntToStr(audioHeader.ByteRate);
  edBlockAlign.Text := IntToStr(audioHeader.BlockAlign);
  edBitsPerSample.Text := IntToStr(audioHeader.BitsPerSample);
}

  if not (audioHeader.BitsPerSample in [8, 16]) then
  begin
    MessageBox(0, PChar('Bits per sample supported only with values 8 or 16'), PChar('Fehler'), MB_OK);
    exit;
  end;

  Result := true;
end;

function TAudioThread.seekAudioData(AStream: TStream):Integer;
var
  data: TWavDataSubChunk;
  n: Int64;
  P: Int64;

  function IsData: Boolean;
  begin
    Result := (data.ID[0]='d') and (data.ID[1]='a') and (data.ID[2]='t') and (data.ID[3]='a');
  end;
begin
  Result := -1;

  // Seek data-section
  repeat
    P := AStream.Position;

    // Read the data subchunk
    n := AStream.Read(data, SizeOf(data));

    // Check data
    if n <> SizeOf(data) then
    begin
      MessageBox(0, PChar(Format('File "%s" is damaged!', [_audiofile])), PChar('Fehler'), MB_OK);
      exit;
    end;
    if AStream.Position >= AStream.Size then
    begin
      MessageBox(0, PChar(Format('File "%s" is not a valid WAVE-file!', [_audiofile])), PChar('Fehler'), MB_OK);
      exit;
    end;

    //if audioBigEndian then
    //  data.DataSize := BEToN(data.DataSize);

    if IsData then
      // when current chunk had been the data chunk we're done.
      break
    else
      // otherwise proceed with the next chunk.
      AStream.Position := P + 8 + data.DataSize;
  until false;

  Result := data.DataSize;
end;

function TAudioThread.readAudioSample(AStream: TStream; var sample: SmallInt):boolean;
var
  buffer8: ShortInt;
  buffer16: SmallInt;
begin
  // read sample
  case audioHeader.BitsPerSample of
    8:
    begin
      if AStream.Read(buffer8, SizeOf(buffer8)) = SizeOf(buffer8) then
      begin
        // everything OK: copy 8-bit-data to 32-bit-sample-variable
        sample := SmallInt(buffer8) shl 8; // convert to 16-bit
      end else
      begin
        MessageBox(0, PChar('Sample could not be read completely. Aborting.'), PChar('Fehler'), MB_OK);
      end;
    end;
    16:
    begin
      if Astream.Read(buffer16, SizeOf(buffer16)) = SizeOf(buffer16) then
      begin
        // everything OK: copy 16-bit-data to 32-bit-sample-variable
        sample := buffer16; // keep as 16-bit SmallInt
      end else
      begin
        MessageBox(0, PChar('Sample could not be read completely. Aborting.'), PChar('Fehler'), MB_OK);
      end;
    end;
{
    // 24-bit and 32-bit are using special type of broadcasting WAVE-file. Not supported yet.
    24:
    begin
    end:
    32:
    begin
    end:
}
  end;

  Result := true;
end;

constructor TAudioThread.Create(ioaddress: DWORD; bufferSizeMillis: Word; audiofile: String; pollingMode: Boolean; IRQ: byte);
begin
  inherited create(false);
  Priority := tpNormal;
  FreeOnTerminate := true;

  // copy variables
  _ioaddress := ioaddress;
  _audiofile := audiofile;
  _volume := 100;
  _pollingMode := pollingMode;
  _irq := IRQ;
  bufferSizeSamples := round(bufferSizeMillis * 48000/1000);
end;

function TAudioThread.getPosition:single;
begin
  if ((audioStream <> nil) and (numSamples > 0)) then
    Result := (sampleCounter / numSamples) * 100
  else
    Result := 0;
end;

function TAudioThread.getBufferSize:integer;
begin
  Result := ReadIOAddress(_ioaddress, 4);
end;

procedure TAudioThread.setVolume(volume: byte);
begin
  _volume := volume;
end;

function TAudioThread.txAudioDataChunk:boolean;
var
  i:integer;
  sampleL, sampleR: SmallInt;
  data:array[0..3] of byte;
  c:Cardinal;
begin
  if (mainform.killthreads or (sampleCounter >= numSamples)) then
    result := false;

  // transmit data
  for i:=0 to (bufferSizeSamples div 2) do
  begin
    // read all channels
    if (audioHeader.NumChannels = 1) then
    begin
      // just Mono
      if readAudioSample(audioStream, sampleL) then
      begin
        // write sample for left channel to both channels to PCI Card
        sampleL := round(sampleL * _volume/100);
        move(sampleL, data[0], 2);
        move(sampleL, data[2], 2);
        move(data[0], c, 4);
        WriteIOAddress(_ioaddress, c, 4);
      end else
      begin
        // something is wrong -> abort
        MessageBox(0, PChar('An Error on reading the data occurred!'), PChar('Error'), MB_OK);
        sampleCounter := numSamples + 1; // let the thread exit
      end;
      // exit for-loop on EOF
      if (sampleCounter >= numSamples) then
        break;
    end else if (audioHeader.NumChannels = 2) then
    begin
      // Stereo
      if not readAudioSample(audioStream, sampleL) then
      begin
        // something is wrong -> abort
        MessageBox(0, PChar('An Error on reading the data occurred!'), PChar('Error'), MB_OK);
        sampleCounter := numSamples + 1; // let the thread exit
      end else
      begin
        // reading sample for left was successful. Now read right-channel
        if readAudioSample(audioStream, sampleR) then
        begin
          // write Audio-Samples for both channels to PCI Card
          sampleL := round(sampleL * _volume/100);
          sampleR := round(sampleR * _volume/100);
          move(sampleL, data[0], 2);
          move(sampleR, data[2], 2);
          move(data[0], c, 4);
          WriteIOAddress(_ioaddress, c, 4);
        end else
        begin
          // something is wrong -> abort
          MessageBox(0, PChar('An Error on reading the data occurred!'), PChar('Error'), MB_OK);
          sampleCounter := numSamples + 1; // let the thread exit
        end;
      end;

      // exit for-loop on EOF
      if (sampleCounter >= numSamples) then
        break;
    end else
    begin
      // unsupported channel-number
    end;

    // increase sample counter and exit when last sample has been read
    sampleCounter := sampleCounter + 1;

    // exit for-loop on EOF
    if (sampleCounter >= numSamples) then
      break;
  end;

  if (mainform.killthreads or (sampleCounter >= numSamples)) then
    result := false
  else
    result := true;
end;

procedure PerformanceDelay(delay: byte);
var
  hrRes, hrT1, hrT2, dif: Int64;
begin
  if QueryPerformanceFrequency(hrRes) then
  begin
    QueryPerformanceCounter(hrT1);
    repeat
      QueryPerformanceCounter(hrT2);
      dif := (hrT2 - hrT1) * 10000000 div hrRes;
    until dif > delay;
  end;
end;

procedure OnHWInterrupt(IRQNumber:WORD); stdcall;
begin
  if (IRQNumber = mainform.AudioThread._irq) then
  begin
    // this is the expected interrupt
    mainform.irqCounter := mainform.irqCounter + 1;

    // write next chunk of audio-data
    if not mainform.AudioThread.txAudioDataChunk then
    begin
      // we have reached the end of the audio-file
      // clear IRQ by writing into ioport with offset 0x04
      WriteIOAddress(mainform.AudioThread._ioaddress + 4, 0, 4);
    end;
  end;
end;

procedure TAudioThread.openPciDriver;
var
  IrqShared : byte;
begin
  // first open the driver
  HW32 := OpenTVicHW32(HW32, 'TVicHW32', 'TVicDevice0');

  // read IRQ-number from PCI Configuration Space
  //_irq := 10; // TODO: implement reading of PCI-Configuration-Space to identify IRQ-Number automatically

  // reset irq counter
  mainform.irqCounter := 0;

  // extended IRQ-handling
  // clear IRQ
  FillChar(ClearRec,SizeOf(ClearRec), 0);
  ClearRec.ClearIrq := 1; // 1 - Irq must be cleared, 0 - not
  ClearRec.TypeOfRegister := 1; // 0 - memory, 1 - ioport
  ClearRec.WideOfRegister := 4; // 1 - Byte, 2 - Word, 4 - Double Word
  ClearRec.ReadOrWrite := 1; // 0 - read register to clear Irq, 1 - write
  ClearRec.RegBaseAddress := _ioaddress+4; // Memory or port i/o register base address to clear
  ClearRec.RegOffset := 0; // Register offset
  ClearRec.ValueToWrite := $00000000; // Value to write (if ReadOrWrite=1)

  IrqShared := 1;
  UnmaskIRQEx(HW32, _irq, IrqShared, @OnHWInterrupt, @ClearRec);
end;

procedure TAudioThread.closePciDriver;
begin
  MaskIRQ(HW32, _irq);
  HW32 := CloseTVicHW32(HW32);
end;

procedure TAudioThread.Execute;
var
  dataSize: Integer;
  fifostate : integer;
begin
  inherited;

  try
    // open audiostream
    audioStream := TMemoryStream.Create;
    TMemoryStream(audioStream).LoadFromFile(_audiofile);

    // check audiodata
    audioStream.Position := 0;
    if not readAudioFormat(audioStream) then
      exit;

    // Read Subchunk header
    if not readAudioHeader(audioStream) then
      exit;

    dataSize := seekAudioData(audioStream);
    if dataSize = -1 then
      exit;

    // numSamples contains all samples of a single channel
    numSamples := (dataSize * 8) div (audioHeader.BitsPerSample * audioHeader.NumChannels);

    //MessageBox(0, PChar('Current position = ' + inttostr(audioStream.Position) + ' and dataSize = ' + inttostr(dataSize)), PChar('Info'), MB_OK);
    //MessageBox(0, PChar('Wave has ' + inttostr(audioHeader.NumChannels) + ' channels'), PChar('Info'), MB_OK);
    //MessageBox(0, PChar('Wave has ' + inttostr(numSamples) + ' samples'), PChar('Info'), MB_OK);

    if (_pollingMode) then
    begin
      // Polling-Mode
      // check the buffer-level and transmit new audio-data if buffer is
      // below a specific threshold
      //
      // Polling-Mode is working without any special tools or libraries under
      // Windows9x. Just pure IO-Access using Assembler.

      repeat
        // check state of FIFO-Buffer in PCI Card
        // at 48kHz we need at least 48 samples per 1ms and channel
        // if samples in FIFO is below 50 samples, transmit data for 2ms
        fifostate := ReadIOAddress(_ioaddress, 4);
        if (fifostate < (bufferSizeSamples div 2)) then
        begin
          txAudioDataChunk;
        end;

        // wait 20.83 microseconds (bad audio-performance)
        //PerformanceDelay(75); // will produce 100% CPU Load

        // sleep thread to keep CPU-load low
        sleep(1); // minimum time for Windows
      until (mainform.killthreads or (sampleCounter >= numSamples));
    end else
    begin
      // IRQ-mode
      // Send the first chunk of audio-data and wait until an IRQ is received
      // first chunk of data will be sent to device, but
      // more data will be sent within the ISR
      //
      // IRQ-Mode uses the TVicHW32-driver-framework to access the IRQs and
      // PCI-Card at Ring0-Access of Windows9x up to WindowsXP

      openPciDriver;

      txAudioDataChunk;

      // in IRQ-Mode the audio-file is read within the ISR, so wait here until
      // the audiofile is played
      repeat
        // sleep thread to keep CPU-load low
        sleep(1); // minimum time for Windows
      until (mainform.killthreads or (sampleCounter >= numSamples));
    end;

    // now close the driver
    closePciDriver;

    // close audiostream gracefully
    audioStream.Free;
  except
  end;

  Terminate;
end;

end.
