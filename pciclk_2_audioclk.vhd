LIBRARY IEEE;    
USE IEEE.STD_LOGIC_1164.ALL;    

entity pciclk_2_audioclk is
	generic(
		samplerate : integer range 0 to 65535 := 44100
	);
    port (
        clk_in : in std_logic;
        clk_out : out std_logic
    );
end pciclk_2_audioclk;

architecture Behavioral of pciclk_2_audioclk is
    signal count : integer := 0;
begin
    process(clk_in)     
    begin
        if (rising_edge(clk_in)) then
            count <= count + 1;

			-- 33 MHz to 48kHz -> 687,5
            if (count = (33000000 / samplerate)) then
                clk_out <= '1';
                count <= 0;
            else
				clk_out <= '0';
            end if;
        end if;
    end process;
end;
