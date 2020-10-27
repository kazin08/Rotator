library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package my_library is
    constant N_bits :natural:=11;
    type t_punto is record 
        x : STD_LOGIC_VECTOR(N_bits-1 downto 0);
        y : STD_LOGIC_VECTOR(N_bits-1 downto 0);
    end record;
    type t_array_punto is array(integer range <>) of t_punto;
    constant zero : std_logic_vector(N_bits-1 downto 0) := (others => '0');
    constant origen : t_punto := (x=>zero, y=>zero);
    constant gr_max : std_logic_vector(N_bits-1 downto 0) := (N_bits-3 => '1' ,others => '0');
    constant gr_min : std_logic_vector(N_bits-1 downto 0) := std_logic_vector(-signed(gr_max));
end my_library;