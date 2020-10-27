library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.my_library.all;
entity delay is
    port (i_in : in  t_punto;
	  clk : in std_logic;
	  ena : in std_logic;
	  o_out : out t_punto);
end delay;
architecture delay_arq of delay is
begin
process (clk)
begin
if rising_edge(clk) then
if ena='1' then
o_out <= i_in;
end if;
end if;
end process;
end delay_arq;