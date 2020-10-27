---------------------------------------------------------
--
-- Generador de pixeles para la VGA
-- Version actualizada a 07/06/2016
--
-- Modulos:
-- 
--
---------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gen_pixels is
	port(
		clk, reset: in std_logic;
		sw: in std_logic_vector (2 downto 0);
		pixel_x, pixel_y : in std_logic_vector (9 downto 0);
		ena: in std_logic;
		red : out std_logic_vector(3 downto 0);
		green : out std_logic_vector(3 downto 0);
		blue : out std_logic_vector(3 downto 0)
	);
	
end gen_pixels;

architecture gen_pixels_arch of gen_pixels is

	--signal rgb_reg: std_logic_vector(2 downto 0);
    signal red_reg: std_logic_vector (3 downto 0);
    signal green_reg: std_logic_vector (3 downto 0);
    signal blue_reg: std_logic_vector (3 downto 0);
begin

	process(clk, reset)
	begin
		if reset = '1' then
			--rgb_reg <= (others => '0');
			red_reg <= "0000";
			green_reg <= "0000";
			blue_reg <= "0000";
		elsif rising_edge(clk) then
--			if (to_integer(unsigned(pixel_x)) mod 16 = 0) or (to_integer(unsigned(pixel_y)) mod 16 = 0) then
--				--rgb_reg <= "111";
--				red_reg <= "1111";
--                green_reg <= "1111";
--                blue_reg <= "1111";
--			else
				--rgb_reg <= sw;
				red_reg <= sw(0) & sw(0) & sw(0) & sw(0);
                green_reg <=  sw(1) & sw(1) & sw(1) & sw(1);
                blue_reg <=  sw(2) & sw(2) & '1' & sw(2);
--			end if;
		end if;
	end process;

	--rgb <= rgb_reg when ena = '1' else "000";
	red <= red_reg when ena ='1' else "0000";
	green <= green_reg when ena ='1' else "0000";
    blue <= blue_reg when ena ='1' else "0000";
        

end gen_pixels_arch;