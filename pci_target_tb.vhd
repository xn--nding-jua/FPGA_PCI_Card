-- Testbench for pci_target
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- leere entity
entity pci_target_tb is
end entity pci_target_tb;

architecture bhv of pci_target_tb is
	constant CLOCK_PERIOD : time := 30.30303030 ns;	-- 33 MHz Clock
	constant ioread 	: std_logic_vector(3 downto 0) := "0010";
	constant iowrite 	: std_logic_vector(3 downto 0) := "0011";
	constant memread 	: std_logic_vector(3 downto 0) := "0110";
	constant memwrite 	: std_logic_vector(3 downto 0) := "0111";
	constant confread 	: std_logic_vector(3 downto 0) := "1010";
	constant confwrite 	: std_logic_vector(3 downto 0) := "1011";

	-- declare the DUT module
	component pci_target is
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
	end component;

	signal clk_i		: std_logic; -- PCI-Clock (33MHz)
	signal nRST_i		: std_logic; -- Reset-signal
	signal AD_io		: std_logic_vector(31 downto 0); -- driven by master: Address- and Databus
	signal nCBE_io		: std_logic_vector(3 downto 0); -- driven by master: command during address-phase / byte-enable-signal during data-phase
	signal PAR_io		: std_logic;	-- driven by master: parity bit. Ensures even parity access AD[31..0] and nCBE[3..0]
	signal nFrame_io	: std_logic;	-- driven by master: driven low to indicate start and duration of transaction. Deasserted when master is ready to complete final data-phase
	signal nTRDY_io	: std_logic; 	-- driven by target: Read: driven low signal to indicate valid data / Write: driven low to indicate ready-to-read
	signal nIRDY_io	: std_logic;	-- driven by master: Write: driven low to indicate valid data / Read: driven low to indicate ready-to-read
	signal STOPn_io	: std_logic; 	-- driven by target: asserted to stop master transaction
	signal nDEVSEL_io	: std_logic; 	-- asserted by target when it decodes its address (within 6 cycles!)
	signal IDSEL_i		: std_logic; 			-- chip-select during access to configuration-register
	signal nPERR_io	: std_logic; 	-- driven by master: asserted on parity-error (address or data)
	signal nSERR_io	: std_logic; 	-- reports address parity errors and special cycle data parity errors
	signal data_o		: std_logic_vector(31 downto 0);
	signal rdy_o		: std_logic;
	signal LED_o		: std_logic;

begin
	-- create signals for simulation

	-- ============= CONFREAD =============
	--nFrame_io <= '1', '0' after CLOCK_PERIOD*5, '1' after CLOCK_PERIOD*6; -- start new communication
	--AD_io <= (others=>'Z'), "00000000000000000000000000001000" after CLOCK_PERIOD*5, (others=>'Z') after CLOCK_PERIOD*6; -- set address to 0000, to read VID and PID, or 1000 to read class-code
	--IDSEL_i <= '0', '1' after CLOCK_PERIOD*5, '0' after CLOCK_PERIOD*6; -- select this device (ChipSelect)
	--nCBE_io <= (others=>'Z'), confread after CLOCK_PERIOD*5, (others=>'1') after CLOCK_PERIOD*6, (others=>'Z') after CLOCK_PERIOD*8; -- set config-read-command
	--nIRDY_io <= 'Z', '0' after CLOCK_PERIOD*6, 'Z' after CLOCK_PERIOD*10; -- tell target, that host is ready
	
	-- ============= CONFWRITE =============
	--nFrame_io <= '1', '0' after CLOCK_PERIOD*5, '1' after CLOCK_PERIOD*7; -- start new communication
	--AD_io <= (others=>'Z'), "00000000000000000000000000001000" after CLOCK_PERIOD*5, "00000000000000000000101010101010" after CLOCK_PERIOD*6, (others=>'Z') after CLOCK_PERIOD*7;
	--IDSEL_i <= '0', '1' after CLOCK_PERIOD*5, '0' after CLOCK_PERIOD*6; -- select this device (ChipSelect)
	--nCBE_io <= (others=>'Z'), confwrite after CLOCK_PERIOD*5, (others=>'Z') after CLOCK_PERIOD*6; -- set config-write-command
	--nIRDY_io <= 'Z', '0' after CLOCK_PERIOD*6, 'Z' after CLOCK_PERIOD*10; -- tell target, that host is ready

	-- ============= IOWRITE =============
	--nFrame_io <= '1', '0' after CLOCK_PERIOD*5, '1' after CLOCK_PERIOD*7; -- start new communication
	--AD_io <= (others=>'Z'), "00000000000000000010000000000000" after CLOCK_PERIOD*5, "00000000000000000000000000000001" after CLOCK_PERIOD*6, (others=>'Z') after CLOCK_PERIOD*7; -- set IO-address to 0x2000 and turn on LED
	--IDSEL_i <= 'Z'; -- keep IDSEL deasserted
	--nCBE_io <= (others=>'Z'), iowrite after CLOCK_PERIOD*5, (others=>'Z') after CLOCK_PERIOD*6; -- set io-write-command
	--nIRDY_io <= 'Z', '0' after CLOCK_PERIOD*6, 'Z' after CLOCK_PERIOD*7; -- tell target, that host is ready

	-- ============= IOREAD =============
	nFrame_io <= '1', '0' after CLOCK_PERIOD*5, '1' after CLOCK_PERIOD*6; -- start new communication
	AD_io <= (others=>'Z'), "00000000000000000010000000000000" after CLOCK_PERIOD*5, (others=>'Z') after CLOCK_PERIOD*6; -- set address to 0x2000 to read I/O address of card
	IDSEL_i <= 'Z'; -- keep IDSEL deasserted
	nCBE_io <= (others=>'Z'), ioread after CLOCK_PERIOD*5, (others=>'1') after CLOCK_PERIOD*6, (others=>'Z') after CLOCK_PERIOD*8; -- set io-read-command
	nIRDY_io <= 'Z', '0' after CLOCK_PERIOD*6, 'Z' after CLOCK_PERIOD*10; -- tell target, that host is ready

	-- test main-process
	process
	begin
		clk_i <= '0';
		wait for CLOCK_PERIOD/2;
		clk_i <= '1';
		wait for CLOCK_PERIOD/2;
	end process;

	-- instanciate the module
	dut : pci_target
		port map (
			clk_i => clk_i,
			nRST_i => nRST_i,
			AD_io => AD_io,
			nCBE_io => nCBE_io,
			PAR_io => PAR_io,
			nFrame_io => nFrame_io,
			nTRDY_io => nTRDY_io,
			nIRDY_io => nIRDY_io,
			STOPn_io => STOPn_io,
			nDEVSEL_io => nDEVSEL_io,
			IDSEL_i => IDSEL_i,
			nPERR_io => nPERR_io,
			nSERR_io => nSERR_io,
			data_o => data_o,
			rdy_o => rdy_o,
			LED_o => LED_o
		);

end architecture;