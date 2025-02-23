/*
  Bitstream-Loader for Altera Flex 10k Devices
  Target-Device: ESP8266 with SD-Card

    GPIO    NodeMCU   Name  |   Uno
   ===================================
     15       D8       SS   |   D10
     13       D7      MOSI  |   D11
     12       D6      MISO  |   D12
     14       D5      SCK   |   D13

    Note: If the ESP is booting at a moment when the SPI Master has the Select line HIGH (deselected)
    the ESP8266 WILL FAIL to boot!
*/
#include "SPI.h"

void configureFpga() {
  for(int i=0; i<sizeof buff; i++)
  {
    SPI.transfer(buff[i]);
  }
}


void setup() {
  SPI.begin();
}

void loop() {

}