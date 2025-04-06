-- PCI-Target - A PCI 2.3 compliance target
-- v0.3, 02.04.2025
-- (c) 2025 Chris Noeding (christian@noeding-online.de)
-- https://www.github.com/xn--nding-jua/pci_card
-- 
-- This file implements a PCI Target device 
-- 
-- 
-- 
-- 
-- All PCI devices (except host bus bridges) are required to respond as a target to 
-- configuration (read and write) commands. All other commands are optional.
-- 
-- Address-lines contain different information:
-- 	Address-Phase: 				physical 32-bit address
-- 	IO:							byte-address
-- 	Configuration and Memory:	DWORD-address
-- 	Data-Phase:					AD[7..0] contains LSB and [AD31..24] contains MSB
-- 
-- Python-script under linux to dump PCI-configuration-space:
-- sudo python chipsec_util.py pci dump 0 0x1f 0
--
-- List of PCI Vendor IDs: https://pci-ids.ucw.cz
-- 
-- ==========================================================================
--               WITHOUT WAITSTATES
-- ==========================================================================
--             ___     ___     ___     ___     ___     ___
-- CLK     ___|   |___|   |___|   |___|   |___|   |___|   |___
-- 
--         _______                                   _________
-- nFRAME         |_________________________________|
-- 
--                 ______  _______  ______  ______  ______
-- AD      -------<______><_______><______><______><______>---
--                 Address  Data1    Data2   Data3   Data4
-- 
--                 ______  _______________________________
-- nC/BE   -------<______><_______________________________>---
--                 Command   Byte Enable Signals
-- 
--          ____________                                   ___
-- nIRDY                |_________________________________|
-- 
--          _____________                                  ___
-- nTRDY                 |________________________________|
-- 
--          ______________                                 ___
-- nDEVSEL                |_______________________________|
-- 
-- 
-- ==========================================================================
--               NOW WITH WAITSTATES
-- ==========================================================================
--                          [1]              [2]        [3]
--             ___     ___     ___     ___     ___     ___     ___     ___
-- CLK     ___|   |___|   |___|   |___|   |___|   |___|   |___|   |___|   |__
-- 
--         _______                                                  _________
-- nFRAME         |________________________________________________|
-- 
--                                    A               B               C
--                 ______           ______________  ______  _____________
-- AD      -------<______>---------<______________><______><_____________>---
--                 Address           Data1           Data2   Data3
-- 
--                 ______  ______________________________________________
-- nC/BE   -------<______><______________________________________________>---
--                 Command   Byte Enable Signals
-- 
--                                                          Wait
--          ____________                                    _____         ___
-- nIRDY                |__________________________________|     |_______|
-- 
--                         Wait            Wait
--          ______________________         ______                         ___
-- nTRDY                          |_______|      |_______________________|
-- 
--          ______________                                                ___
-- nDEVSEL                |______________________________________________|
-- 
-- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pci_target is
	generic(
		ioport		: integer range 0 to 65535 := 25344; -- in a future release this value will be taken from BAR0 within config-space
		iorange		: integer range 0 to 65535 := 16 -- range of IO space in bytes
	);
	port (
		-- system-pins
		clk_i		: in std_logic; -- PCI-Clock (33MHz)
		nRST_i		: in std_logic; -- Reset-signal

		-- address- and data-pins
		AD_io		: inout std_logic_vector(31 downto 0) := (others => 'Z'); -- driven by master: Address- and Databus
		nCBE_io		: inout std_logic_vector(3 downto 0) := (others => 'Z'); -- driven by master: command during address-phase / byte-enable-signal during data-phase
		PAR_io		: inout std_logic := 'Z';	-- driven by master: parity bit. Ensures even parity access AD[31..0] and nCBE[3..0]

		-- interface-control-pins
		nFrame_io	: inout std_logic := 'Z';	-- driven by master: driven low to indicate start and duration of transaction. Deasserted when master is ready to complete final data-phase
		nTRDY_io	: inout std_logic := 'Z'; 	-- driven by target: Read: driven low signal to indicate valid data / Write: driven low to indicate ready-to-read
		nIRDY_io	: inout std_logic := 'Z';	-- driven by master: Write: driven low to indicate valid data / Read: driven low to indicate ready-to-read
		nSTOP_io	: inout std_logic := 'Z'; 	-- driven by target: asserted to stop master transaction
		nDEVSEL_io	: inout std_logic := 'Z'; 	-- asserted by target when it decodes its address (within 6 cycles!)
		IDSEL_i		: in std_logic; 			-- chip-select during access to configuration-register
		
		-- error-reporting-pins
		nPERR_io	: inout std_logic := 'Z'; 	-- driven by master: asserted on parity-error (address or data)
		nSERR_io	: inout std_logic := 'Z'; 	-- reports address parity errors and special cycle data parity errors

		-- arbitration-pins (master only)
		nREQ_o		: out std_logic := 'Z'; 	-- driven by target: requesting dedicated access to bus
		nGNT_i		: in std_logic; 			-- driven by arbiter: tells master that it is granted bus control
		
		nIRQA		: out std_logic := 'Z';
		nLOCK		: inout std_logic := 'Z';
		
		
		
		-- interface to outside
		data0_i		: in std_logic_vector(31 downto 0);
		data1_i		: in std_logic_vector(31 downto 0);
		data2_i		: in std_logic_vector(31 downto 0);
		data3_i		: in std_logic_vector(31 downto 0);

		data0_o		: out std_logic_vector(31 downto 0);
		data1_o		: out std_logic_vector(31 downto 0);
		data2_o		: out std_logic_vector(31 downto 0);
		data3_o		: out std_logic_vector(31 downto 0);
		rdy0_o		: out std_logic;
		rdy1_o		: out std_logic;
		rdy2_o		: out std_logic;
		rdy3_o		: out std_logic;
		
		LED_o		: out std_logic := 'Z';
		
		-- some debug outputs
		debug		: out std_logic_vector(15 downto 0)
	);
end pci_target;

architecture Behavioral of pci_target is
	type t_SM_Transaction is (s_Idle, s_confreadTurn, s_confread, s_confwrite, s_confwriteEnd, s_ioreadTurn, s_ioread, s_iowrite, s_iowriteEnd, s_Parity);
	signal s_SM_Transaction : t_SM_Transaction := s_Idle;
	
	signal AD		 	: std_logic_vector(31 downto 0);
	signal command		: std_logic_vector(3 downto 0);
	
	constant confread 	: std_logic_vector(3 downto 0) := "1010";
	constant confwrite 	: std_logic_vector(3 downto 0) := "1011";
	constant ioread 	: std_logic_vector(3 downto 0) := "0010";
	constant iowrite	: std_logic_vector(3 downto 0) := "0011";
	constant memread 	: std_logic_vector(3 downto 0) := "0110";
	constant memwrite 	: std_logic_vector(3 downto 0) := "0111";

	signal dataPointer 	: integer range 0 to 65535 := 0; -- 16-bit pointer

	type t_conf_frame is array (0 to 63) of std_logic_vector(7 downto 0); -- 64 bytes seems to be minimum for correct PnP-enumeration
	signal conf_frame	: t_conf_frame;
	--signal ioport_bar	: integer range 0 to 65535 := 0; -- 16-bit start-address for io-port from BAR0
	
	signal AD_o			: std_logic_vector(31 downto 0);
	signal AD_oe		: std_logic := '0';
	signal PAR_calc		: std_logic := '0';
	signal zBE			: std_logic_vector(3 downto 0);
	signal PAR, zPAR	: std_logic := '0';
	signal PAR_o		: std_logic;
	signal PAR_oe		: std_logic := '0';
	
	signal stateCounter	: integer range 0 to 10 := 0;
begin
    process(clk_i)
    begin
		-- process for reading signals on rising edge
		if (rising_edge(clk_i)) then
			if nRST_i = '0' then
				-- disable all outputs
				AD_oe <= '0';
				PAR_oe <= '0';
				PAR_calc <= '0';
				nTRDY_io <= 'Z'; -- set outputs (bi-directional-pins) to High-Z
				nDEVSEL_io <= 'Z'; -- set outputs (bi-directional-pins) to High-Z
				nSTOP_io <= 'Z';

				-- "type 0" configuration-command (AD[1..0] = 00
				-- for this the following command structure is valid
				-- 31............11   10.....8   7......2   1..0
				-- --- RESERVED ---   FCN NMBR   REG NMBR   TYPE
				--
				-- "type 1" requests are sent to another bus-segment:
				-- 31....24    23....16   15....11    10.....8   7......2    1..0
				-- RESERVED    BUS NMBR   DEV NMBR    FCN NMBR   REG NMBR    TYPE
				
			
				-- Address     Bit 32      16   15           0
				-- 
				-- 00          Unit ID        | Manufacturer ID
				-- 04          Status         | Command
				-- 08          Class Code               | Revision
				-- 0C          BIST  | Header | Latency | CLS
				-- 10-24            Base Address Register 0..5
				-- 28          Reserved
				-- 2C          Reserved
				-- 30          Expansion ROM Base Address
				-- 34          Reserved
				-- 38          Reserved
				-- 3C          MaxLat|MnGNT   | INT-pin | INT-line
				-- 40-FF       available for PCI unit
				conf_frame(0) <= x"72";  -- VID = 0x1172 = Altera
				conf_frame(1) <= x"11";
				conf_frame(2) <= x"24";  -- PID = 0x2524
				conf_frame(3) <= x"25";
				
				--conf_frame(4) <= x"01";  -- command = 0x01 (b0=responses to io-space, b1=responses to mem-space, b10 = interrupt disable)
				conf_frame(4) <= x"03";  -- command = 0x03 (b0=responses to io-space, b1=responses to mem-space, b10 = interrupt disable)
				conf_frame(5) <= x"00"; -- 0x04 for no interrupts
				conf_frame(6) <= x"00";  -- status = 0x00 (b10..b9: DEVSEL-timing 00=fast, 01=medium, 10=slow | b5=66MHz capable)
				conf_frame(7) <= x"00";
				
				conf_frame(8) <= x"B2";  -- revision ID = 0xB2
				conf_frame(9) <= x"00";  -- Class Code: register class code
				conf_frame(10) <= x"80"; -- Class Code: sub class code (0x80 = other device, 0x00 .. 0x?? for specific devices of base-class)
				conf_frame(11) <= x"04"; -- Class Code: base class code (0x00 = unknown, 0x02 network, 0x04 = multimedia, 0x07 simple communication controller, 0x09 = input device, 0xff unspecified)
				
				conf_frame(12) <= x"00"; -- Cache Line Size (CLS)
				conf_frame(13) <= x"00"; -- Latency Timer
				conf_frame(14) <= x"00"; -- Header type (0x00 = Standard Header type and device has single function)
				conf_frame(15) <= x"00"; -- BIST
				
				-- all remaining bytes of the 256 bytes are not used for now and can be set to zero
				-- register 1MB memory with 0xFFF00000
				-- if Memory: b3: prefetchable | b2..b1: 00=locate anywhere in 32-bit, 10=locate anywhere in 64-bit | b0: set to 0 for MemorySpace
				-- if IO: b1: reserved | b0: set to 1 for IO-Space
				
				-- in this code we are using IO-Space, so b0 is set to 1, b1 to 0
				-- b5..2 are set to 0 to request 4 bytes of IO-space
				
				-- BAR0 will contain the IO-Address:
				-- for example: 0x6300 ... 0x630F will show up like this:
				-- conf_frame(16) = 00000001 <- bit0 is set, so use IO-Address-Space
				-- conf_frame(17) = 01100011 = 0x63
				-- conf_frame(18) = 00000000 = 0x00
				-- conf_frame(19) = 00000000 = 0x00
				conf_frame(16) <= x"00"; -- BAR0 (Base Address Register)
				conf_frame(17) <= x"00"; -- BAR0 (Base Address Register)
				conf_frame(18) <= x"00"; -- BAR0 (Base Address Register)
				conf_frame(19) <= x"00"; -- BAR0 (Base Address Register)

				-- register 1MB bytes in memory-space with 0xFFF00000
				conf_frame(20) <= x"00"; -- BAR1 (Base Address Register)
				conf_frame(21) <= x"00"; -- BAR1 (Base Address Register)
				conf_frame(22) <= x"00"; -- BAR1 (Base Address Register)
				conf_frame(23) <= x"00"; -- BAR1 (Base Address Register)
				
				-- reserve no further memory
				conf_frame(24) <= x"00"; -- BAR2 (Base Address Register)
				conf_frame(25) <= x"00"; -- BAR2 (Base Address Register)
				conf_frame(26) <= x"00"; -- BAR2 (Base Address Register)
				conf_frame(27) <= x"00"; -- BAR2 (Base Address Register)
				
				conf_frame(28) <= x"00"; -- BAR3 (Base Address Register)
				conf_frame(29) <= x"00"; -- BAR3 (Base Address Register)
				conf_frame(30) <= x"00"; -- BAR3 (Base Address Register)
				conf_frame(31) <= x"00"; -- BAR3 (Base Address Register)
				
				conf_frame(32) <= x"00"; -- BAR4 (Base Address Register)
				conf_frame(33) <= x"00"; -- BAR4 (Base Address Register)
				conf_frame(34) <= x"00"; -- BAR4 (Base Address Register)
				conf_frame(35) <= x"00"; -- BAR4 (Base Address Register)
				
				conf_frame(36) <= x"00"; -- BAR5 (Base Address Register)
				conf_frame(37) <= x"00"; -- BAR5 (Base Address Register)
				conf_frame(38) <= x"00"; -- BAR5 (Base Address Register)
				conf_frame(39) <= x"00"; -- BAR5 (Base Address Register)
				
				conf_frame(40) <= x"00"; -- CardBus CIS Pointer
				conf_frame(41) <= x"00"; -- 
				conf_frame(42) <= x"00"; -- 
				conf_frame(43) <= x"00"; -- 
				
				conf_frame(44) <= x"72"; -- System Vendor ID (0x1172)
				conf_frame(45) <= x"11"; -- 
				conf_frame(46) <= x"00"; -- Subsystem ID (0x0000)
				conf_frame(47) <= x"00"; -- 
				
				conf_frame(48) <= x"00"; -- Expansion ROM Base Address
				conf_frame(49) <= x"00"; -- 
				conf_frame(50) <= x"00"; -- 
				conf_frame(51) <= x"00"; -- 
				
				conf_frame(52) <= x"00"; -- Capabilities Pointer
				conf_frame(53) <= x"00"; -- Reserved
				conf_frame(54) <= x"00"; -- 
				conf_frame(55) <= x"00"; -- 
				
				conf_frame(56) <= x"00"; -- 
				conf_frame(57) <= x"00"; -- 
				conf_frame(58) <= x"00"; -- 
				conf_frame(59) <= x"00"; -- 
				
				conf_frame(60) <= x"00"; -- Interrupt Line
				conf_frame(61) <= x"02"; -- Interrupt Pin
				conf_frame(62) <= x"00"; -- Min_Gnt
				conf_frame(63) <= x"00"; -- Max_Lat

				s_SM_Transaction <= s_Idle;
				rdy0_o <= '0';
				rdy1_o <= '0';
				rdy2_o <= '0';
				rdy3_o <= '0';
			else
				-- regular operation
				if (s_SM_Transaction = s_Idle) then
					-- stay in Idle until we received a start of bus cycle at nFrame

					-- disable all outputs
					AD_oe <= '0';
					PAR_oe <= '0';
					PAR_calc <= '0';
					nTRDY_io <= 'Z'; -- set outputs (bi-directional-pins) to High-Z
					nDEVSEL_io <= 'Z'; -- set outputs (bi-directional-pins) to High-Z
					nSTOP_io <= 'Z';
					rdy0_o <= '0';
					rdy1_o <= '0';
					rdy2_o <= '0';
					rdy3_o <= '0';

					if (nFrame_io = '0') then -- start of bus cycle is detected
						AD <= AD_io;		-- read address
						command <= nCBE_io;		-- read command (only valid during deasserting nFRAME)
					
						if (nCBE_io = confread and IDSEL_i = '1' and AD_io(1 downto 0) = "00") then
							-- take the absolute address of the configuration-space:
							-- during this phase AD[1..0] is 0x00
							-- AD[7..2] contains address of one of the 64 DWORD registers
							dataPointer <= to_integer(unsigned(AD_io(7 downto 0))); -- we take an address for a DWORD between 0x00 and 0xFB
							s_SM_Transaction <= s_confreadTurn;
							
						elsif (nCBE_io = confwrite and IDSEL_i = '1' and AD_io(1 downto 0) = "00") then
							-- we are not using confwrite, but we have to support it to meet the PCI specification
							-- master wants to write some data -> check if this is our address							

							-- take the absolute address of the configuration-space:
							-- during this phase AD[1..0] is 0x00
							-- AD[7..2] contains address of one of the 64 DWORD registers
							dataPointer <= to_integer(unsigned(AD_io(7 downto 0))); -- we take an address for a DWORD between 0x00 and 0xFB
							s_SM_Transaction <= s_confwrite;

						elsif (nCBE_io = ioread) then
							-- master wants to read some data -> check if this is our address							
							if ((unsigned(AD_io) >= to_unsigned(ioport, AD_io'length)) and (unsigned(AD_io) < (to_unsigned(ioport + iorange, AD_io'length)))) then
							--if ((ioport_bar > 0) and (unsigned(AD_io) >= to_unsigned(ioport_bar, AD_io'length)) and (unsigned(AD_io) < (to_unsigned(ioport_bar + iorange, AD_io'length)))) then
								-- calculate memory-offset based on given ioport
								-- during this phase, AD[31..0] contains a physical 32-bit address
								-- byteEnable indicates the size of the transfer
								dataPointer <= to_integer(unsigned(AD_io));
								s_SM_Transaction <= s_ioreadTurn;
							end if;
							
						elsif (nCBE_io = iowrite) then
							-- master wants to write some data -> check if this is our address							
							if ((unsigned(AD_io) >= to_unsigned(ioport, AD_io'length)) and (unsigned(AD_io) < (to_unsigned(ioport + iorange, AD_io'length)))) then
							--if ((ioport_bar > 0) and (unsigned(AD_io) >= to_unsigned(ioport_bar, AD_io'length)) and (unsigned(AD_io) < (to_unsigned(ioport_bar + iorange, AD_io'length)))) then
								-- calculate memory-offset based on given ioport
								-- during this phase, AD[31..0] contains a physical 32-bit address
								-- nCBE indicates the size of the transfer
								dataPointer <= to_integer(unsigned(AD_io));
								s_SM_Transaction <= s_iowrite;
							end if;

--						elsif (nCBE_io = memread) then
--							-- master wants to read some data -> check if this is our address							
--							if (AD_io = std_logic_vector(to_unsigned(ioport, AD_io'length))) then
--								-- calculate memory-offset based on given ioport
--								-- during this phase, AD[31..0] contains a physical 32-bit address
--								-- nCBE indicates the size of the transfer
--								dataPointer <= to_integer(unsigned(AD_io));
--								s_SM_Transaction <= s_memreadTurn;
--							end if;
--							
--						elsif (nCBE_io = memwrite) then
--							-- master wants to write some data -> check if this is our address							
--							if (AD_io = std_logic_vector(to_unsigned(ioport, AD_io'length))) then
--								-- calculate memory-offset based on given ioport
--								-- during this phase, AD[31..0] contains a physical 32-bit address
--								-- nCBE indicates the size of the transfer
--								dataPointer <= to_integer(unsigned(AD_io));
--								s_SM_Transaction <= s_memwrite;
--							end if;
--							
						end if;
					end if;
					
					
				-- ===============================================================================
				-- Configuration-Space-Functions
				-- ===============================================================================
					
					
				elsif (s_SM_Transaction = s_confreadTurn) then
					-- wait one clock for the turnaround-cycle
					nDEVSEL_io <= '1';	-- deassert nDEVSEL
					nTRDY_io <= '1'; -- deassert nTRDY
					nSTOP_io <= '1';

					-- wait for nIRDY to be asserted
					if (nIRDY_io = '0') then
						stateCounter <= 0;
						s_SM_Transaction <= s_confread;
					end if;
					
				elsif (s_SM_Transaction = s_confread) then
					if (stateCounter = 0) then
						nDEVSEL_io <= '0';	-- assert nDEVSEL to tell master that we take this transaction
					elsif (stateCounter = 1) then
						nTRDY_io <= '0';	-- assert nTRDY to tell master that we are ready to send
					end if;

					-- enable outputs
					AD_oe <= '1';
					-- set outputs
					nSTOP_io <= '1';

					-- next lines are working partially. Only the first DWORD is transmitted
					if (dataPointer <= 60) then
						-- dataPointer points to internal DWORD-address 0...x of conf-register and is incremented in risingEdge-process
						--AD_o <= conf_frame(dataPointer+3) & conf_frame(dataPointer+2) & conf_frame(dataPointer+1) & conf_frame(dataPointer); -- set data to output as DWORD ignoring byte-enable-signal
						AD_o <= (conf_frame(dataPointer+3) and (7 downto 0 => (not nCBE_io(3)))) &
							(conf_frame(dataPointer+2) and (7 downto 0 => (not nCBE_io(2)))) &
							(conf_frame(dataPointer+1) and (7 downto 0 => (not nCBE_io(1)))) &
							(conf_frame(dataPointer) and (7 downto 0 => (not nCBE_io(0)))); -- set data to output as DWORD using byte-enable-signal
					else
						-- write zeros as we have no information in the higher bytes of the configuration-space yet
						AD_o <= (others => '0');
					end if;
					zBE <= nCBE_io;
					
					if (PAR_calc = '1') then -- one clock delay
						-- calculate parity and output it
						PAR_oe <= '1';
						
						-- calculate parity over previous data
						PAR_o <= (AD_o(0)  xor AD_o(1)  xor AD_o(2)  xor AD_o(3)  xor AD_o(4)  xor AD_o(5)  xor AD_o(6)  xor AD_o(7)  xor
							AD_o(8)  xor AD_o(9)  xor AD_o(10) xor AD_o(11) xor AD_o(12) xor AD_o(13) xor AD_o(14) xor AD_o(15) xor
							AD_o(16) xor AD_o(17) xor AD_o(18) xor AD_o(19) xor AD_o(20) xor AD_o(21) xor AD_o(22) xor AD_o(23) xor
							AD_o(24) xor AD_o(25) xor AD_o(26) xor AD_o(27) xor AD_o(28) xor AD_o(29) xor AD_o(30) xor AD_o(31)) xor
							(zBE(0) xor zBE(1) xor zBE(2) xor zBE(3));
					end if;
					if (nIRDY_io = '0' and stateCounter >= 1) then
						PAR_calc <= '1'; -- enable calculation of parity on next falling clock
					end if;

					if (nIRDY_io = '0' and nTRDY_io = '0') then
						if (nFRAME_io = '0') then
							-- during consecutive reading, we are using a linear DWORD-increment of dataPointer
							dataPointer <= dataPointer + 4; -- increase dataPointer by four bytes
							s_SM_Transaction <= s_confread; -- stay in confread on next clock
						else
							-- end of transmission with parity-bit
							dataPointer <= 0;
							s_SM_Transaction <= s_Parity;
						end if;
					else
						-- wait for PCI-host
						s_SM_Transaction <= s_confread;
					end if;
					stateCounter <= stateCounter + 1;

				elsif (s_SM_Transaction = s_confwrite) then
					-- set outputs
					nDEVSEL_io <= '0';	-- assert nDEVSEL to tell master that we take this transaction
					nTRDY_io <= '0';	-- assert nTRDY to tell master that we are ready to receive
					nSTOP_io <= '1';

					-- wait here until nIRDY is asserted (write-data is valid)
					if (nIRDY_io = '0') then
						-- write one (standard-mode) or multiple (burst-mode) 32-bit data

--						if (dataPointer = 4) then -- DWORD-address = 1
--							if (nCBE_io(1 downto 0) = "00") then
--								conf_frame(4) <= AD_io(7 downto 0); -- command LSB
--								conf_frame(5) <= AD_io(15 downto 8); -- command MSB
--							end if;
--							if (nCBE_io(3 downto 2) = "00") then
--								conf_frame(6) <= AD_io(23 downto 16); -- status LSB
--								conf_frame(7) <= AD_io(31 downto 24); -- status MSB
--							end if;
--						end if;
--						if (dataPointer = 8) then -- DWORD-address = 2
--							if (nCBE_io(3 downto 0) = "0000") then
--								conf_frame(8) <= AD_io(7 downto 0); -- revision ID
--								conf_frame(9) <= AD_io(15 downto 8); -- Class Code: register class code
--								conf_frame(10) <= AD_io(23 downto 16); -- Class Code: sub class code
--								conf_frame(11) <= AD_io(31 downto 24); -- Class Code: base class code
--							end if;
--						end if;
--						if (dataPointer = 12) then -- DWORD-address = 3
--							if (nCBE_io(3 downto 0) = "0000") then
--								conf_frame(12) <= AD_io(7 downto 0); -- Cache Line Size (CLS)
--								conf_frame(13) <= AD_io(15 downto 8); -- Latency Timer
--								conf_frame(14) <= AD_io(23 downto 16); -- Header type
--								conf_frame(15) <= AD_io(31 downto 24); -- BIST
--							end if;
--						end if;
						if (dataPointer = 16) then -- DWORD-address = 4
							-- write to Base Address Register 0 to receive the Address from BIOS
							if (nCBE_io(3 downto 0) = "0000") then
								-- request 64 bytes IO-Space by setting 4 bits to 0
								-- request 16 bytes IO-Space by setting 2 bits to 0
								-- request 8 bytes IO-Space by setting 1 bit to 0
								conf_frame(16) <= AD_io(7 downto 4) & "00" & "01"; -- BAR0
								conf_frame(17) <= AD_io(15 downto 8); -- BAR0
								conf_frame(18) <= AD_io(23 downto 16); -- BAR0
								conf_frame(19) <= AD_io(31 downto 24); -- BAR0
								
								--ioport_bar <= to_integer(shift_left(resize(unsigned(AD_io(31 downto 4)), AD_io'length), 4)); -- receive the Start-IO-Address
							end if;
						end if;
						if (dataPointer = 20) then -- DWORD-address = 5
							-- write to Base Address Register 1 to receive the Address from BIOS
							if (nCBE_io(3 downto 0) = "0000") then
								-- request 1 MByte Memory-Space by setting BAR1 to 0xFFF00008
								conf_frame(20) <= "0000" & "1000"; -- BAR1, 32-bit prefetchable Memory-Space
								conf_frame(21) <= "00000000"; -- BAR1
								conf_frame(22) <= AD_io(23 downto 20) & "0000"; -- BAR1
								conf_frame(23) <= AD_io(31 downto 24); -- BAR1
							end if;
						end if;
--						if (dataPointer = 60) then
--							if (nCBE_io(0) = '0') then
--								conf_frame(60) <= AD_io(7 downto 0); -- INTLINE
--							end if;
--							if (nCBE_io(1) = '0') then
--								conf_frame(61) <= AD_io(15 downto 8); -- INTPIN
--							end if;
--						end if;

						if (nFRAME_io = '0') then
							-- during consecutive writing, we are using a linear DWORD-increment of dataPointer
							dataPointer <= dataPointer + 4; -- increae dataPointer by four byte
							s_SM_Transaction <= s_confwrite; -- stay in confwrite with next clock
						else
							-- we reached end of transmission
							dataPointer <= 0; 	-- reset dataPointer
							s_SM_Transaction <= s_confwriteEnd; -- end this transaction
						end if;
					else
						-- wait for PCI-host
						s_SM_Transaction <= s_confwrite; -- stay in this state
					end if;
					
				elsif (s_SM_Transaction = s_confwriteEnd) then
					-- deassert outputs
					nTRDY_io <= '1'; -- High, not High-Z!
					nDEVSEL_io <= '1'; -- High, not High-Z!
					nSTOP_io <= '1';
					s_SM_Transaction <= s_Idle;
				

				
				-- ===============================================================================
				-- IO-Space Functions
				-- ===============================================================================
				
				
				
				elsif (s_SM_Transaction = s_ioreadTurn) then
					-- wait one clock for the turnaround-cycle
					nDEVSEL_io <= '1';	-- deassert nDEVSEL
					nTRDY_io <= '1'; -- deassert nTRDY
					nSTOP_io <= '1';
					
					-- wait for nIRDY to be asserted
					if (nIRDY_io = '0') then
						stateCounter <= 0;
						s_SM_Transaction <= s_ioread;
					end if;
					
				elsif (s_SM_Transaction = s_ioread) then
					if (stateCounter = 0) then
						nDEVSEL_io <= '0';	-- assert nDEVSEL to tell master that we take this transaction
					elsif (stateCounter = 1) then
						nTRDY_io <= '0';	-- assert nTRDY to tell master that we are ready to send
					end if;

					-- enable outputs
					AD_oe <= '1';
					-- set outputs
					nSTOP_io <= '1';

					if ((dataPointer >= ioport) and (dataPointer <= (ioport + 3))) then
						--AD_o <= std_logic_vector(to_unsigned(42, 32)); -- output constant value "42"
						AD_o <= data0_i;
					elsif ((dataPointer >= (ioport + 4)) and (dataPointer <= (ioport + 7))) then
						--AD_o <= std_logic_vector(to_unsigned(43, 32)); -- output constant value "43"
						AD_o <= data1_i;
					elsif ((dataPointer >= (ioport + 8)) and (dataPointer <= (ioport + 11))) then
						AD_o <= conf_frame(19) & conf_frame(18) & conf_frame(17) & conf_frame(16);
						--AD_o <= data2_i;
					elsif ((dataPointer >= (ioport + 12)) and (dataPointer <= (ioport + 15))) then
						AD_o <= conf_frame(23) & conf_frame(22) & conf_frame(21) & conf_frame(20);
						--AD_o <= data3_i;
					else
						AD_o <= (others => '0');
					end if;
					zBE <= nCBE_io;
					
					if (PAR_calc = '1') then -- one clock delay
						-- calculate parity and output it
						PAR_oe <= '1';
						
						-- calculate parity over previous data
						PAR_o <= (AD_o(0)  xor AD_o(1)  xor AD_o(2)  xor AD_o(3)  xor AD_o(4)  xor AD_o(5)  xor AD_o(6)  xor AD_o(7)  xor
							AD_o(8)  xor AD_o(9)  xor AD_o(10) xor AD_o(11) xor AD_o(12) xor AD_o(13) xor AD_o(14) xor AD_o(15) xor
							AD_o(16) xor AD_o(17) xor AD_o(18) xor AD_o(19) xor AD_o(20) xor AD_o(21) xor AD_o(22) xor AD_o(23) xor
							AD_o(24) xor AD_o(25) xor AD_o(26) xor AD_o(27) xor AD_o(28) xor AD_o(29) xor AD_o(30) xor AD_o(31)) xor
							(zBE(0) xor zBE(1) xor zBE(2) xor zBE(3));
					end if;
					if (nIRDY_io = '0' and stateCounter >= 1) then
						PAR_calc <= '1'; -- enable calculation of parity on next falling clock
					end if;

					if (nIRDY_io = '0' and nTRDY_io = '0') then
						if (nFRAME_io = '0') then
							-- during consecutive reading, we are using a linear DWORD-increment of dataPointer
							dataPointer <= dataPointer + 4; -- increase dataPointer by one DWORD
							s_SM_Transaction <= s_ioread; -- stay in confread on next clock
						else
							-- end of transmission with parity-bit
							dataPointer <= 0;
							s_SM_Transaction <= s_Parity;
						end if;
					else
						-- wait for PCI-host
						s_SM_Transaction <= s_ioread;
					end if;
					stateCounter <= stateCounter + 1;

				elsif (s_SM_Transaction = s_iowrite) then
					-- set outputs
					nDEVSEL_io <= '0';	-- assert nDEVSEL to tell master that we take this transaction
					nTRDY_io <= '0';	-- assert nTRDY to tell master that we are ready to receive
					nSTOP_io <= '1';

					-- wait here until nIRDY is asserted (write-data is valid)
					if (nIRDY_io = '0') then
						-- write one (standard-mode) or multiple (burst-mode) 32-bit data
						
						-- copy full DWORD to output
						if (dataPointer = ioport) then
							-- we are receiving four bytes here
							data0_o <= AD_io; -- copy all 32 bit
							rdy0_o <= '1';
							
							-- set LED
							LED_o <= AD_io(0); -- bit 0 of byte 0
							--LED_o <= AD_io(8); -- bit 0 of byte 1
							--LED_o <= AD_io(16); -- bit 0 of byte 2
							--LED_o <= AD_io(25); -- bit 0 of byte 3
						elsif (dataPointer = (ioport + 4)) then
							-- we are receiving four bytes here
							data1_o <= AD_io; -- copy all 32 bit
							rdy1_o <= '1';
						elsif (dataPointer = (ioport + 8)) then
							-- we are receiving four bytes here
							data2_o <= AD_io; -- copy all 32 bit
							rdy2_o <= '1';
						elsif (dataPointer = (ioport + 12)) then
							-- we are receiving four bytes here
							data3_o <= AD_io; -- copy all 32 bit
							rdy3_o <= '1';
						else
							-- do nothing
						end if;

						if (nFRAME_io = '0') then
							-- during consecutive writing, we are using a linear DWORD-increment of dataPointer
							dataPointer <= dataPointer + 4; -- increae dataPointer by one DWORD
							s_SM_Transaction <= s_iowrite; -- stay in iowrite with next clock
						else
							-- we reached end of transmission
							dataPointer <= 0; 	-- reset dataPointer
							s_SM_Transaction <= s_iowriteEnd; -- end this transaction
						end if;
					else
						-- wait for PCI-host
						s_SM_Transaction <= s_iowrite; -- stay in this state
					end if;

				elsif (s_SM_Transaction = s_iowriteEnd) then
					-- deassert outputs
					nTRDY_io <= '1'; -- High, not High-Z!
					nDEVSEL_io <= '1'; -- High, not High-Z!
					nSTOP_io <= '1';

					rdy0_o <= '0';
					rdy1_o <= '0';
					rdy2_o <= '0';
					rdy3_o <= '0';
					s_SM_Transaction <= s_Idle;



				-- ===============================================================================
				-- Special-Functions
				-- ===============================================================================


				elsif (s_SM_Transaction = s_Parity) then
					-- output last Paritybit if in read-mode (both confread and ioread)

					-- calculate parity and output it
					PAR_oe <= '1';
					
					-- calculate parity over previous data
					PAR_o <= (AD_o(0)  xor AD_o(1)  xor AD_o(2)  xor AD_o(3)  xor AD_o(4)  xor AD_o(5)  xor AD_o(6)  xor AD_o(7)  xor
						AD_o(8)  xor AD_o(9)  xor AD_o(10) xor AD_o(11) xor AD_o(12) xor AD_o(13) xor AD_o(14) xor AD_o(15) xor
						AD_o(16) xor AD_o(17) xor AD_o(18) xor AD_o(19) xor AD_o(20) xor AD_o(21) xor AD_o(22) xor AD_o(23) xor
						AD_o(24) xor AD_o(25) xor AD_o(26) xor AD_o(27) xor AD_o(28) xor AD_o(29) xor AD_o(30) xor AD_o(31)) xor
						(zBE(0) xor zBE(1) xor zBE(2) xor zBE(3));
					
					-- disable all outputs (except parity-bit)
					AD_oe <= '0';
					-- set outputs
					nDEVSEL_io <= '1'; -- High, not High-Z!
					nTRDY_io <= '1'; -- High, not High-Z!
					nSTOP_io <= '1';
					AD_o <= (others => 'Z');

					s_SM_Transaction <= s_Idle;
				
				end if;
			end if;
		end if;
	end process;

	-- only output to bidirectional pin if we want to write valid data. Otherwise High-Z-mode
	AD_io <= AD_o when AD_oe = '1' else (others => 'Z');
	PAR_io <= PAR_o when PAR_oe = '1' else 'Z';
	
	-- set unused bidirectional pins to High-Z
	nCBE_io <= (others => 'Z');
	nFRAME_io <= 'Z';
	nIRDY_io <= 'Z';
	nPERR_io <= 'Z';
	nSERR_io <= 'Z';
	nREQ_o <= 'Z';
	nIRQA <= 'Z';
	nLOCK <= 'Z';
	
	-- output some debug information
	debug(0) <= nFRAME_io;
	debug(1) <= IDSEL_i;
	debug(2) <= nIRDY_io;
	debug(3) <= nTRDY_io;
	debug(4) <= nDEVSEL_io;
	debug(5) <= nCBE_io(0);
	debug(6) <= nCBE_io(1);
	debug(7) <= nCBE_io(2);
	debug(8) <= nCBE_io(3);
	debug(9) <= AD_io(2);
	debug(10) <= AD_io(3);
	debug(11) <= AD_io(4);
	debug(12) <= AD_io(5);
	debug(13) <= AD_io(6);
	debug(14) <= AD_io(7);
	debug(15) <= AD_io(8);
end;
