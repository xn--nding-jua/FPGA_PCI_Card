/*
  Intel FPGA Passive Mode driver using SPI
  Hardware-Target: ESP8266

  Pinout:
  |=====================================================|
  | Description | GPIO | Pin | Pin | GPIO | Description |
  |=============|======|=====|=====|======|=============|
  | Reset       |      | RST | Tx  |  1   | TxD0        |
  | ADC         |      | A0  | Rx  |  3   | RxD0        |
  | Wake        | 16   | D0  | D1  |  5   | I2C SCL     | nSTATUS
  | SCLK        | 14   | D5  | D2  |  4   | I2C SDA     | nCONFIG
  | MISO        | 12   | D6  | D3  |  0   | Flash       | DCLK
  | MOSI        | 13   | D7  | D4  |  2   | TxD1        | DATA0
  | CS / TxD2   | 15   | D8  | GND |      | GND         |
  | 3V3         |      | 3V3 | 5V  |      | VCC         |
  |=====================================================|


  Used Libraries:
  - SoftSPIB by Andriy Golovnya v1.1.1


  Passive Serial Interface for Intel FPGAs:
  ================================================================
  nSTATUS   -> high when starting transmission (inverted ChipSelect)
  DATA0     -> Data Output to FPGA
  DCLK      -> Data Clock to FPGA
  CONF_DONE -> high when FPGA is configured
  INIT_DONE -> high when FPGA is initialized

  A Linux driver can be found here: https://github.com/torvalds/linux/blob/master/drivers/fpga/altera-ps-spi.c
*/

const char* versionstring = "v1.0.0";
const char compile_date[] = __DATE__ " " __TIME__;

#include "Ticker.h"
#include "SdFat.h"
#include <SoftSPIB.h>

#define SPI_MISO      12
#define SPI_MOSI      13
#define SPI_SCK       14
#define SD_CS         15

#define FPGA_nCONFIG  4
#define FPGA_nSTATUS  5
#define FPGA_DATA0    2
#define FPGA_DCLK     0

Ticker TimerSeconds;
SdFat32 SD;
File32 file;
SoftSPIB FPGA_SPI(FPGA_DATA0, -1, FPGA_DCLK); // MOSI, MISO, SCK

void TimerSecondsFcn() {
  digitalWrite(LED_BUILTIN, !digitalRead(LED_BUILTIN));
}

void setup() {
  Serial.begin(115200);

  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(FPGA_nSTATUS, OUTPUT);
  digitalWrite(FPGA_nSTATUS, LOW);

  SD.begin(SD_CS);

  FPGA_SPI.begin();
  FPGA_SPI.setBitOrder(MSBFIRST);

  TimerSeconds.attach_ms(1000, TimerSecondsFcn);
}

void fpgaProgram(String filename) {
  file = SD.open(filename, FILE_READ);
  uint8_t data;

  digitalWrite(FPGA_nSTATUS, HIGH);
  delay(500);

  // read file from SD-card
  while (file.available()) {
    data = file.read(); // read single byte from SD-Card
    FPGA_SPI.transfer(data); // write single byte to FPGA
  }
  file.close();

  FPGA_SPI.transfer(0); // write more data as requested by FPGA
  FPGA_SPI.transfer(0); // write more data as requested by FPGA
  delay(500);
  digitalWrite(FPGA_nSTATUS, LOW);
}

void fileRead(String filename) {
  file = SD.open(filename, FILE_READ);

  // read file from SD-card
  while (file.available()) {
    Serial.write(file.read()); // read single byte from SD-Card
  }
  file.close();
}

void serialHandle() {
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n'); // we are using both CR/LF but we have to read until LF
    command.trim();

    Serial.println(executeCommand(command));
  }
}

// command-interpreter
String executeCommand(String command) {
  String Answer;

  if (command.length() > 2){
    // we got a new command. Lets find out what we have to do today...

    if (command.indexOf("*IDN?") > -1) {
      Answer = "FPGA PS Programmer " + String(versionstring) + " built on " + String(compile_date);
    }else if (command.indexOf("fpga:program") > -1) {
      // fpga:program@fpga.ttf
      String file = command.substring(command.indexOf("@") + 1);
      fpgaProgram("fpga.ttf");

      Answer = "OK";
    }else if (command.indexOf("file:read") > -1) {
      // file:read@fpga.ttf
      String file = command.substring(command.indexOf("@") + 1);
      fileRead("test.txt");
      Answer = "OK";
    }else{
      // unknown command
      Answer = "UNKNOWN_CMD";
    }
  }else{
    Answer = "ERROR";
  }

  return Answer;
}

void loop() {
  serialHandle();
}



/*
  if (!updateMode) {
    if (Serial.available() >= 9) {
      // expecting binary sequence: START
      uint8_t rxData[9];
      Serial.readBytes(rxData, 9);
      if ((rxData[0] = 'S') && (rxData[1] = 'T') && (rxData[2] = 'A') && (rxData[3] = 'R') && (rxData[4] = 'T')) {
        // read the bitstream-size
        memcpy(&bitstreamSize, &rxData[5], 4);

        updateMode = true; // from now on all read bytes will be transmitted via SPI. If the counter is above 1.5 megabytes, the updatemode is left
        SPI.begin(); // SPI uses 12MHz clock
      }
    }
  }else{
    // we are in update-mode: passthrough all data to SPI
    if (byteCounter > (bitstreamSize+1)) {
      SPI.end();
      updateMode = false;
    }else{
      SPI.transfer(Serial.read());
      byteCounter += 1;
    }
  }
*/
