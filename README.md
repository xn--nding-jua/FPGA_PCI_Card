# FPGA_PCI_Card
FPGA PCI Card for Retro-Computers using Altera FLEX10K FPGAs

## General information

This repository contains the first steps of creating a DIY-PCI Card using a retro FPGA: the Altera FLEX10K EPF10K50RC240-3. I've found an old Eval-Card on eBay with three of these FPGAs and I started thinking of what I can do with it. The general idea is, to create a DIY-PCI-Card with multiple functions and drivers for DOS, Win3.11 and/or Win9x.

Here is the progress I've already made with this card and project:
[x] General reverse engineering of the Altera ARC-PCI Rev. 1.1 card from 1998/1999
[x] Download of Altera Quartus 9.0 to synthesize logic for the Altera FLEX10K EPF10K50RC240-3
[x] Working toolchain using Altera USB Blaster connected to the JTAG-connector and uploading test-logic
[x] First design of a PCI-target in VHDL with ioread, iowrite and confread to support Plug&Play-functions
[ ] Testing the onboard-PLL with 33 MHz clock
[ ] Reverse-engineering full pin-out of all three FPGAs
[ ] Testing PCI-card in computer (I built up a Intel Pentium MMX 233 MHz system for this project)
[ ] Writing Windows95 application and communicating with the card
[ ] Implementing memory-read/write using on-board EDO-RAM
[ ] Implementing Audio-Output, UART, or something else to get an idea what is possible with this card


So lot of things have to be done until this project is usable :)