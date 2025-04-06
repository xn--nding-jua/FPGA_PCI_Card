-- FIFO RingBuffer RAM-Controller
-- v1.0.0 built on 06.04.2025
-- (c) 2025 Chris Noeding
-- https://github.com/xn-nding-jua/FPGA_PCI_Card
--
-- Parts of this code by Jonas Julian Jensen, 17.06.2019
-- https://vhdlwhiz.com/ring-buffer-fifo/

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity ringbufram_stereo is
	generic (
		RAM_SIZE	: natural := 15; -- 15 bit Address
		RAM_WIDTH	: natural := 16 -- 16 bit DATA
	);
	port (
		clk			: in std_logic;
		rst			: in std_logic;
		
		-- Write port
		wr_en		: in std_logic;
		wr_data_l	: in std_logic_vector(RAM_WIDTH - 1 downto 0); -- SRAM supports 16 bit only
		wr_data_r	: in std_logic_vector(RAM_WIDTH - 1 downto 0); -- SRAM supports 16 bit only
		
		-- Read port
		rd_en		: in std_logic;
		rd_valid	: out std_logic;
		rd_data_l	: out std_logic_vector(RAM_WIDTH - 1 downto 0); -- SRAM supports 16 bit only
		rd_data_r	: out std_logic_vector(RAM_WIDTH - 1 downto 0); -- SRAM supports 16 bit only
		
		-- Flags
		empty		: out std_logic;
		empty_next	: out std_logic;
		full		: out std_logic;
		full_next	: out std_logic;
		
		-- The number of elements in the FIFO
		fill_count	: out unsigned(RAM_SIZE - 1 downto 0);
		
		-- signals to external SRAM
		ram_ad		: out std_logic_vector(RAM_SIZE - 1 downto 0); -- RAM-address
		ram_data_l	: inout std_logic_vector(RAM_WIDTH - 1 downto 0); -- RAM-data
		ram_data_r	: inout std_logic_vector(RAM_WIDTH - 1 downto 0); -- RAM-data
		ram_par_l	: inout std_logic_vector(1 downto 0); -- parity. Not used here
		ram_par_r	: inout std_logic_vector(1 downto 0); -- parity. Not used here
		ram_nADSP	: out std_logic; --
		ram_nADSC	: out std_logic; --
		ram_nWH		: out std_logic; -- WriteEnable High-Byte
		ram_nWL		: out std_logic; -- WriteEnable Low-Byte
		ram_nADV	: out std_logic; -- automatic address incrementation. Not used here
		ram_nOE		: out std_logic; -- output enable
		ram_nCS		: out std_logic -- ChipSelect
	);
end ringbufram_stereo;

architecture rtl of ringbufram_stereo is
	type t_SM_Ringbuffer is (s_Idle, s_ReadPrepare, s_Read);
	signal s_SM_Ringbuffer : t_SM_Ringbuffer := s_Idle;

	subtype index_type is integer range 0 to (2**RAM_SIZE - 1);
	signal head		: index_type;
	signal tail		: index_type;
	
	signal empty_i	: std_logic;
	signal full_i	: std_logic;
	signal fill_count_i	: integer range 0 to (2**RAM_SIZE - 1);

	signal rd_queued			: std_logic;
	
	-- Increment and wrap
	procedure incr(signal index : inout index_type) is
	begin
		if index = index_type'high then
			index <= index_type'low;
		else
		index <= index + 1;
		end if;
	end procedure;
begin
	-- Copy internal signals to output
	empty <= empty_i;
	full <= full_i;
	fill_count <= to_unsigned(fill_count_i, fill_count'length);
	
	-- set the flags
	empty_i <= '1' when fill_count_i = 0 else '0';
	empty_next <= '1' when fill_count_i <= 1 else '0';
	full_i <= '1' when fill_count_i >= (2**RAM_SIZE - 1) else '0';
	full_next <= '1' when fill_count_i >= (2**RAM_SIZE - 2) else '0';

	-- process the RAM-functions
	proc_ram : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				-- reset outputs
				rd_valid <= '0';
			else
				if (s_SM_Ringbuffer = s_Idle) then
					-- nothing to do here
					rd_valid <= '0';
				elsif (s_SM_Ringbuffer = s_ReadPrepare) then
					-- wait that RAM reads the desired address
					rd_valid <= '0';
				elsif (s_SM_Ringbuffer = s_Read) then
					-- read data from RAM
					rd_data_l <= ram_data_l;
					rd_data_r <= ram_data_r;
					rd_valid <= '1';
				end if;
			end if;
		end if;
		
		if falling_edge(clk) then
			if rst = '1' then
				-- reset internal signals
				head <= 0;
				tail <= 0;

				-- reset outputs to RAM
				ram_data <= (others => 'Z');
				ram_nADSP <= '1';
				ram_nADSC <= '1';
				ram_nWH <= '1';
				ram_nWL <= '1';
				ram_nADV <= '1';
				ram_nOE <= '1';
				ram_nCS <= '1';

				-- reset state-machine
				s_SM_Ringbuffer <= s_Idle;
			else
				if (s_SM_Ringbuffer = s_Idle) then
					-- check if we have to write to RAM
					if wr_en = '1' and full_i = '0' then
						-- write data to RAM
						ram_ad <= std_logic_vector(to_unsigned(head, ram_ad'length));
						ram_data_l <= wr_data_l;
						ram_data_r <= wr_data_r;
						ram_nCS <= '0';
						ram_nADSC <= '0';
						ram_nWH <= '0';
						ram_nWL <= '0';
						ram_nOE <= '1';
						incr(head);

						-- as write takes precidence over read, we queue any read-request
						if (rd_en = '1') then
							rd_queued <= '1';
						end if;
					elsif (rd_en = '1' or rd_queued = '1') and empty_i = '0' then
						-- we have a current or queued read-request
						rd_queued <= '0';
						
						-- set desired address and enable RAM
						ram_ad <= std_logic_vector(to_unsigned(tail, ram_ad'length));
						ram_nCS <= '0';
						ram_nADSC <= '0';
						ram_nWH <= '1';
						ram_nWL <= '1';
						ram_nOE <= '0';
						incr(tail);
						
						s_SM_Ringbuffer <= s_ReadPrepare;
					else
						-- no read or write, so nothing to do -> turnoff outputs and set all values to default
						ram_data <= (others => 'Z');
						ram_nCS <= '1';
						ram_nADSC <= '1';
						ram_nWH <= '1';
						ram_nWL <= '1';
						ram_nOE <= '1';
					end if;
				elsif (s_SM_Ringbuffer = s_ReadPrepare) then
					-- RAM has read the desired address, so go to read-state
					s_SM_Ringbuffer <= s_Read;
				elsif (s_SM_Ringbuffer = s_Read) then
					-- read is done on rising edge
					s_SM_Ringbuffer <= s_Idle;
				end if;
			end if;
		end if;
	end process;

	-- update the fill count
	proc_count : process(head, tail)
	begin
		if head < tail then
			fill_count_i <= head - tail + 2**RAM_SIZE;
		else
			fill_count_i <= head - tail;
		end if;
	end process;
end rtl;
