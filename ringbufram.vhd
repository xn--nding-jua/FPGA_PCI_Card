-- FIFO for Audio-data
-- Author: Jonas Julian Jensen, 17.06.2019
-- Source: https://vhdlwhiz.com/ring-buffer-fifo/

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

entity ringbufram is
	generic (
		RAM_SIZE	: natural := 15; -- 15 bit Address
		RAM_WIDTH	: natural := 16 -- 16 bit DATA
	);
	port (
		clk			: in std_logic;
		rst			: in std_logic;
		
		-- Write port
		wr_en		: in std_logic;
		wr_data		: in std_logic_vector(RAM_WIDTH - 1 downto 0); -- SRAM supports 16 bit only
		
		-- Read port
		rd_en		: in std_logic;
		rd_valid	: out std_logic;
		rd_data		: out std_logic_vector(RAM_WIDTH - 1 downto 0); -- SRAM supports 16 bit only
		
		-- Flags
		empty		: out std_logic;
		empty_next	: out std_logic;
		full		: out std_logic;
		full_next	: out std_logic;
		
		-- The number of elements in the FIFO
		fill_count	: out unsigned(RAM_SIZE - 1 downto 0);
		
		-- signals to external SRAM
		ram_ad		: out std_logic_vector(RAM_SIZE - 1 downto 0);
		ram_data	: inout std_logic_vector(RAM_WIDTH - 1 downto 0);
		ram_par		: inout std_logic_vector(1 downto 0);
		ram_nADSP	: out std_logic;
		ram_nADSC	: out std_logic;
		ram_nWH		: out std_logic;
		ram_nWL		: out std_logic;
		ram_nADV	: out std_logic;
		ram_nOE		: out std_logic;
		ram_nCS		: out std_logic
	);
end ringbufram;

architecture rtl of ringbufram is
	type t_SM_Ringbuffer is (s_Idle, s_Write, s_PrepareRead, s_Read);
	signal s_SM_Ringbuffer : t_SM_Ringbuffer := s_Idle;

	subtype index_type is integer range 0 to (2**RAM_SIZE - 1);
	signal head		: index_type;
	signal tail		: index_type;
	
	signal empty_i	: std_logic;
	signal full_i	: std_logic;
	signal fill_count_i	: integer range 0 to (2**RAM_SIZE - 1);

	signal queueRead	: std_logic;
	signal readData		: std_logic;
	
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
	
	-- Set the flags
	empty_i <= '1' when fill_count_i = 0 else '0';
	empty_next <= '1' when fill_count_i <= 1 else '0';
	full_i <= '1' when fill_count_i >= (2**RAM_SIZE - 1) else '0';
	full_next <= '1' when fill_count_i >= (2**RAM_SIZE - 2) else '0';
	
	proc_ram : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				head <= 0;

				tail <= 0;
				rd_valid <= '0';

				readData <= '0';

				-- reset RAM-outputs
				ram_nADSP <= '1';
				ram_nADSC <= '1';
				ram_nWH <= '1';
				ram_nWL <= '1';
				ram_nADV <= '1';
				ram_nOE <= '1';
				ram_nCS <= '1';

				s_SM_Ringbuffer <= s_Idle;
			else
				if (s_SM_Ringbuffer = s_Idle) then
					rd_valid <= '0';
					
					if wr_en = '1' and full_i = '0' then
						-- write data to RAM. Write takes precidence over read
						ram_ad <= std_logic_vector(to_unsigned(head, ram_ad'length));
						ram_data <= wr_data;
						ram_nCS <= '0';
						ram_nADSC <= '0';
						ram_nWH <= '0';
						ram_nWL <= '0';
						ram_nOE <= '1';
						
						incr(head);

						-- if a read-request occurs right here, queue it
						queueRead <= rd_en;
					else
						-- turn-off outputs
						ram_data <= (others => 'Z');
						
						-- check if we need to read from RAM
						if (rd_en = '1' or queueRead = '1') and empty_i = '0' then
							-- we have a pending read-operation
							queueRead <= '0';

							ram_ad <= std_logic_vector(to_unsigned(tail, ram_ad'length));
							ram_nCS <= '0';
							ram_nADSC <= '0';
							s_SM_Ringbuffer <= s_Read;
						else
							-- no read or write operation
							ram_nCS <= '1';
							ram_nADSC <= '1';
						end if;

						readData <= '0';
						ram_nWH <= '1';
						ram_nWL <= '1';
						ram_nOE <= '0';
					end if;
				elsif (s_SM_Ringbuffer = s_Read) then
					rd_data <= ram_data;
				
					incr(tail);
					rd_valid <= '1';
				end if;
			end if;
		end if;
	end process;

--	-- Update the fill count
--	proc_count : process(head, tail)
--	begin
--		if head < tail then
--			fill_count_i <= head - tail + RAM_DEPTH;
--		else
--			fill_count_i <= head - tail;
--		end if;
--	end process;
end rtl;
