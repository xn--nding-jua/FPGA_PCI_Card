LIBRARY IEEE;    
USE IEEE.STD_LOGIC_1164.ALL;    

entity toggle is
    port (
		clk_in	: in std_logic;
        input	: in std_logic;
        output	: out std_logic
    );
end toggle;

architecture Behavioral of toggle is
	signal b : std_logic := '0';
begin
    process(clk_in)     
    begin
        if (rising_edge(clk_in)) then
            if (input = '1') then
                b <= not b;
            end if;
        end if;
    end process;

    output <= b;
end;
