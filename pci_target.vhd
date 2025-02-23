-- PCI-Target - A PCI 2.3 compliance target
-- v0.1, 23.02.2025
-- (c) 2025 Christian Nöding (christian@noeding-online.de)
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
-- 	IO:								byte-address
-- 	Configuration and Memory:	DWORD-address
-- 	Data-Phase:						AD[7..0] contains LSB and [AD31..24] contains MSB
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
--
-- Calculating the Parity-Data
-- ============================================================================================= 
--	pardat 	<= d(0)  xor d(1)  xor d(2)  xor d(3)  xor d(4)  xor d(5)  xor d(6)  xor d(7)  xor
--			   d(8)  xor d(9)  xor d(10) xor d(11) xor d(12) xor d(13) xor d(14) xor d(15) xor
--			   d(16) xor d(17) xor d(18) xor d(19) xor d(20) xor d(21) xor d(22) xor d(23) xor
--			   d(24) xor d(25) xor d(26) xor d(27) xor d(28) xor d(29) xor d(30) xor d(31);
--
--	parcbe 	<= cbe_i(0) xor cbe_i(1) xor cbe_i(2) xor cbe_i(3);
--
--	par <= pardat xor parcbe;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pci_target is
	generic(
		ioport	: integer := 8192 -- 8192 = 0x2000
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
		STOPn_io	: inout std_logic := 'Z'; 	-- driven by target: asserted to stop master transaction
		nDEVSEL_io	: inout std_logic := 'Z'; 	-- asserted by target when it decodes its address (within 6 cycles!)
		IDSEL_i		: in std_logic; 			-- chip-select during access to configuration-register
		
		-- error-reporting-pins
		nPERR_io	: inout std_logic := 'Z'; 	-- driven by master: asserted on parity-error (address or data)
		nSERR_io	: inout std_logic := 'Z'; 	-- reports address parity errors and special cycle data parity errors

		-- arbitration-pins (master only)
		--nREQ_io	: inout std_logic := 'Z'; 	-- driven by target: requesting dedicated access to bus
		--nGNT_i	: in std_logic; 			-- driven by arbiter: tells master that it is granted bus control
		
		data_o		: out std_logic_vector(31 downto 0);
		rdy_o		: out std_logic;
		LED_o		: out std_logic
	);
end pci_target;

architecture Behavioral of pci_target is
	type t_SM_Transaction is (s_Idle, s_iowrite, s_ioreadTurn, s_ioread, s_confwrite, s_confreadTurn, s_confread, s_setOutput, s_End);
	signal s_SM_Transaction : t_SM_Transaction := s_Idle;
	
	signal address 		: std_logic_vector(31 downto 0);
	signal command 		: std_logic_vector(3 downto 0);
	
	constant ioread 	: std_logic_vector(3 downto 0) := "0010";
	constant iowrite 	: std_logic_vector(3 downto 0) := "0011";
	constant memread 	: std_logic_vector(3 downto 0) := "0110";
	constant memwrite 	: std_logic_vector(3 downto 0) := "0111";
	constant confread 	: std_logic_vector(3 downto 0) := "1010";
	constant confwrite 	: std_logic_vector(3 downto 0) := "1011";

	type t_data_frame is array (0 to 10) of std_logic_vector(31 downto 0);
	signal data_frame	: t_data_frame;
	signal dataPointer 	: integer range 0 to 500 := 0;

	type t_conf_frame is array (0 to 63) of std_logic_vector(7 downto 0); -- 64 bytes seems to be minimum for correct PnP-enumeration
	signal conf_frame	: t_conf_frame;
	
	signal AD_o			: std_logic_vector(31 downto 0);
	signal AD_oe		: std_logic := '0';
begin
    process(clk_i)     
    begin
		-- process for reading signals on rising edge
		if (rising_edge(clk_i)) then
			if nRST_i = '0' then
				-- do reset
				s_SM_Transaction <= s_Idle;
				rdy_o <= '0';
			else
				-- regular operation
				if (s_SM_Transaction = s_Idle) then
					-- stay in Idle until we received a start of bus cycle at nFrame
					
					if (nFrame_io = '0') then -- start of bus cycle is detected
						address <= AD_io;		-- read address
						command <= nCBE_io;		-- read command
					
						if (nCBE_io = iowrite) then
							-- master wants to write some data -> check if this is our address							
							if (AD_io = std_logic_vector(to_unsigned(ioport, address'length))) then
								-- calculate memory-offset based on given ioport
								-- during this phase, AD[31..0] contains a physical 32-bit address
								-- nCBE indicates the size of the transfer
								dataPointer <= to_integer(unsigned(AD_io)) - ioport;
								s_SM_Transaction <= s_iowrite;
							end if;
							
						elsif (nCBE_io = ioread) then
							-- master wants to read some data -> check if this is our address							
							if (AD_io = std_logic_vector(to_unsigned(ioport, address'length))) then
								-- dataPointer will be set in turnaround-cycle-step
								s_SM_Transaction <= s_ioreadTurn;
							end if;
							
						elsif (nCBE_io = confwrite and IDSEL_i = '1' and AD_io(1 downto 0) = "00") then
							-- we are not using confwrite, but we have to support it to meet the PCI specification
							-- master wants to write some data -> check if this is our address							

							-- take the absolute address of the configuration-space:
							-- during this phase AD[1..0] is 0x00
							-- AD[7..2] contains address of one of the 64 DWORD registers
							dataPointer <= to_integer(unsigned(AD_io(7 downto 0))); -- we take an address for a DWORD between 0x00 and 0xFB
							s_SM_Transaction <= s_confwrite;

						elsif (nCBE_io = confread and IDSEL_i = '1' and AD_io(1 downto 0) = "00") then
							-- we received a "type 0" configuration-command (AD[1..0] = 00
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
							conf_frame(4) <= x"01";  -- command = 0x0001 (b0=responses to io-space, b1=responses to mem-space)
							conf_frame(5) <= x"00";
							conf_frame(6) <= x"00";  -- status = 0x0000
							conf_frame(7) <= x"00";
							conf_frame(8) <= x"00";  -- revision = 0x00
							conf_frame(9) <= x"00";  -- Class Code: register class code
							conf_frame(10) <= x"80"; -- Class Code: sub class code (0x00 = video multimedia, 0x01 = audio multimedia, 0x80 = other multimedia)
							conf_frame(11) <= x"04"; -- Class Code: base class code (0x00 = unknown, 0x02 network, 0x04 = multimedia, 0x07 simple communication controller, 0x09 = input device)
							conf_frame(12) <= x"00"; -- Cache Line Size (CLS)
							conf_frame(13) <= x"00"; -- Latency Timer
							conf_frame(14) <= x"00"; -- Header type (0x00 = Standard Header type and device has single function)
							conf_frame(15) <= x"00"; -- BIST
							-- all remaining bytes of the 256 bytes are not used for now and can be set to zero
							conf_frame(16) <= x"00"; -- BAR0 (Base Address Register)
							conf_frame(17) <= x"00"; -- BAR0 (Base Address Register)
							conf_frame(18) <= x"00"; -- BAR0 (Base Address Register)
							conf_frame(19) <= x"00"; -- BAR0 (Base Address Register)
							conf_frame(20) <= x"00"; -- BAR1 (Base Address Register)
							conf_frame(21) <= x"00"; -- BAR1 (Base Address Register)
							conf_frame(22) <= x"00"; -- BAR1 (Base Address Register)
							conf_frame(23) <= x"00"; -- BAR1 (Base Address Register)
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
							conf_frame(61) <= x"00"; -- Interrupt Pin
							conf_frame(62) <= x"00"; -- Min_Gnt
							conf_frame(63) <= x"00"; -- Max_Lat
							
							-- dataPointer will be set in turnaround-cycle-step
							s_SM_Transaction <= s_confreadTurn;
							
						end if;
					end if;
					
				elsif (s_SM_Transaction = s_iowrite) then
					-- wait here until nIRDY is asserted (write-data is valid)
					if (nIRDY_io = '0') then
						-- signal "address" can be used to identify the current io-address
						
						-- read one (standard-mode) or multiple (burst-mode) 32-bit data
						data_frame(dataPointer) <= AD_io;

						if (nFrame_io = '1') then
							-- we reached end of transmission
							dataPointer <= 0; 	-- reset dataPointer
							s_SM_Transaction <= s_setOutput;
						else
							-- during consecutive writing, we are using a linear increment of dataPointer
							dataPointer <= dataPointer + 1; -- increase dataPointer
						end if;
					end if;
					
				elsif (s_SM_Transaction = s_ioreadTurn) then
					-- wait one clock for the turnaround-cycle
					
					-- calculate memory-offset based on given ioport
					-- during this phase, AD[31..0] contains a physical 32-bit address
					-- nCBE indicates the size of the transfer
					dataPointer <= to_integer(unsigned(address)) - ioport;
					s_SM_Transaction <= s_ioread;
					
				elsif (s_SM_Transaction = s_ioread) then
					if (nFRAME_io = '0') then
						if (nIRDY_io = '0') then
							-- during consecutive writing, we are using a linear increment of dataPointer
							dataPointer <= dataPointer + 1; -- increase dataPointer
						end if;
					else
						-- end of transmission
						s_SM_Transaction <= s_Idle;
					end if;

				elsif (s_SM_Transaction = s_confwrite) then
					-- wait here until nIRDY is asserted (write-data is valid)
					if (nIRDY_io = '0') then
						-- read one (standard-mode) or multiple (burst-mode) 32-bit data
						--conf_frame(dataPointer) <= AD_io; -- at the moment we are not supporting writing to config-space

						if (nFrame_io = '1') then
							-- we reached end of transmission
							dataPointer <= 0; 	-- reset dataPointer
							s_SM_Transaction <= s_Idle;
						else
							-- during consecutive writing, we are using a linear increment of dataPointer
							dataPointer <= dataPointer + 4; -- increment by 4 bytes as we are reading DWORD-values
						end if;
					end if;
					
				elsif (s_SM_Transaction = s_confreadTurn) then
					-- wait one clock for the turnaround-cycle
					
					-- take the absolute address of the configuration-space:
					-- during this phase AD[1..0] is 0x00
					-- AD[7..2] contains address of one of the 64 DWORD registers
					dataPointer <= to_integer(unsigned(address(7 downto 0))); -- we take an address for a DWORD between 0x00 and 0xFB
					s_SM_Transaction <= s_confread;

				elsif (s_SM_Transaction = s_confread) then
					if (nFRAME_io = '0') then
						if (nIRDY_io = '0') then
							-- during consecutive writing, we are using a linear increment of dataPointer
							dataPointer <= dataPointer + 4; -- increment by 4 bytes as we are reading DWORD-values
						end if;
					else
						-- end of transmission
						s_SM_Transaction <= s_Idle;
					end if;
					
				elsif (s_SM_Transaction = s_setOutput) then
					-- check if the data is for us and set output
					data_o <= data_frame(0);
					LED_o <= data_frame(0)(0);
					rdy_o <= '1';
					s_SM_Transaction <= s_End;
					
				elsif (s_SM_Transaction = s_End) then
					rdy_o <= '0';
					
					-- wait until ready- and devsel-signals went high again
					if (nFrame_io = '1' and nIRDY_io = '1') then
						dataPointer <= 0;
						s_SM_Transaction <= s_Idle;
					end if;
					
				end if;
			end if;
		end if;
	end process;

	-- process for setting signals on falling edge (read-operations)
	process(clk_i)     
	begin
		if (falling_edge(clk_i)) then
			if nRST_i = '0' then
				-- disable all outputs
				AD_oe <= '0';
				-- set outputs (bi-directional-pins) to High-Z
				nTRDY_io <= 'Z';
				nDEVSEL_io <= 'Z';
				AD_o <= (others => 'Z');
				PAR_io <= 'Z';
			else
				-- regular operation
				if (s_SM_Transaction = s_iowrite) then
					-- set outputs
					nTRDY_io <= '0';	-- assert nTRDY to tell master that we are ready to receive
					nDEVSEL_io <= '0';	-- assert nDEVSEL to tell master that we are at this address
				
				elsif (s_SM_Transaction = s_ioreadTurn) then
					-- set outputs
					nTRDY_io <= '0';	-- assert nTRDY to tell master that we are ready to send
					nDEVSEL_io <= '0';	-- assert nDEVSEL to tell master that we are at this address
					
				elsif (s_SM_Transaction = s_ioread) then
					-- enable outputs
					AD_oe <= '1';
					-- set outputs
					--AD_o <= std_logic_vector(to_unsigned(datapointer, 32)); -- dataPointer points to internal address 0...x and is incremented in risingEdge-process
					AD_o <= std_logic_vector(to_unsigned(42, 32)); -- output constant value "42"
					
				elsif (s_SM_Transaction = s_confwrite) then
					-- set outputs
					nTRDY_io <= '0';	-- assert nTRDY to tell master that we are ready to receive
					nDEVSEL_io <= '0';	-- assert nDEVSEL to tell master that we are at this address

				elsif (s_SM_Transaction = s_confreadTurn) then
					-- set outputs
					nTRDY_io <= '0';	-- assert nTRDY to tell master that we are ready to send
					nDEVSEL_io <= '0';	-- assert nDEVSEL to tell master that we are at this address

				elsif (s_SM_Transaction = s_confread) then
					-- enable outputs
					AD_oe <= '1';
					-- set outputs
					if (dataPointer <= 60) then
						-- dataPointer points to internal DWORD-address 0...x of conf-register and is incremented in risingEdge-process
						AD_o <= conf_frame(dataPointer+3) & conf_frame(dataPointer+2) & conf_frame(dataPointer+1) & conf_frame(dataPointer); -- set data to output as DWORD
					else
						-- write zeros as we have no information in the higher bytes of the configuration-space yet
						AD_o <= (others => '0');
					end if;
					
				else
					-- this state includes s_setOutput and s_End

					-- disable all outputs
					AD_oe <= '0';
					-- set outputs (bi-directional-pins) to High-Z
					nTRDY_io <= 'Z';
					nDEVSEL_io <= 'Z';
					AD_o <= (others => 'Z');
					PAR_io <= 'Z';
				
				end if;
			end if;
		end if;
	end process;
	
	-- only output to bidirectional pin if we want to write valid data. Otherwise High-Z-mode
	AD_io <= AD_o when AD_oe = '1' else (others => 'Z');
end;
