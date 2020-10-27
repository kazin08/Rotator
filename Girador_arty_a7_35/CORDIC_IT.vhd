library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity CORDIC_IT is
    Generic (   N_bits : natural := 8;
		iteration : natural := 0;
		angle_step : signed(31 downto 0) := "00100000000000000000000000000000" 
                );
    Port ( clk : in STD_LOGIC;
       ena : in STD_LOGIC; 
	   ai : in STD_LOGIC_VECTOR (N_bits-1 downto 0);
	   xi : in STD_LOGIC_VECTOR (N_bits downto 0);
	   yi : in STD_LOGIC_VECTOR (N_bits downto 0);
	   ao : out STD_LOGIC_VECTOR (N_bits-1 downto 0);
           xo : out STD_LOGIC_VECTOR (N_bits downto 0);
           yo : out STD_LOGIC_VECTOR (N_bits downto 0)
           );
end CORDIC_IT;
architecture Behavioral of CORDIC_IT is
    begin
    process(clk,ena)
	begin
	if rising_edge(clk) then
	if ena='1' then
  	     if iteration=0 then
			if signed(ai)>0 then
				ao <= STD_LOGIC_VECTOR(signed(ai) - angle_step(31 downto 32-N_bits));
     				xo <= STD_LOGIC_VECTOR(signed(xi) - signed(yi));
    				yo <= STD_LOGIC_VECTOR(signed(yi) + signed(xi));
  			else   
				ao <= STD_LOGIC_VECTOR(signed(ai) + angle_step(31 downto 32-N_bits));
     				xo <= STD_LOGIC_VECTOR(signed(xi) + signed(yi));
      				yo <= STD_LOGIC_VECTOR(signed(yi) - signed(xi));
   			end if;
 	      else
			if signed(ai) > 0 then
                    		ao <= STD_LOGIC_VECTOR(signed(ai) - angle_step(31 downto 32-N_bits));
                    		xo <= STD_LOGIC_VECTOR(signed(xi) - shift_right(signed(yi),iteration));
                    		yo <= STD_LOGIC_VECTOR(signed(yi) + shift_right(signed(xi),iteration));
                	else
	            		ao <= STD_LOGIC_VECTOR(signed(ai) + angle_step(31 downto 32-N_bits));
               	    		xo <= STD_LOGIC_VECTOR(signed(xi) + shift_right(signed(yi),iteration));
                    		yo <= STD_LOGIC_VECTOR(signed(yi) - shift_right(signed(xi),iteration));
                	end if;
		end if;
	end if;
	end if;
    end process;
end Behavioral;