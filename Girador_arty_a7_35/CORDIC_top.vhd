library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.my_library.all;

entity CORDIC_top is
    Generic(	N_bits : natural := 8;  -- m�ximo 32
                N_steps: natural := 8); -- m�ximo 16
    Port(	clk : in STD_LOGIC;
           	enable : in STD_LOGIC;
		degrees : in STD_LOGIC_VECTOR (N_bits-1 downto 0);
		x_in : in STD_LOGIC_VECTOR (N_bits-1 downto 0);
		y_in : in STD_LOGIC_VECTOR (N_bits-1 downto 0);
           	x_out : out STD_LOGIC_VECTOR (N_bits-1 downto 0);
           	y_out : out STD_LOGIC_VECTOR (N_bits-1 downto 0));
end CORDIC_top;

architecture Behavioral of CORDIC_top is
    component CORDIC_IT is 
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
    end component;
    --**** Tipos de datos utilizados en la entidad ****
    type t_table is array(0 to 15) of signed(31 downto 0);
    type t_tuple is 
	record
	    a : STD_LOGIC_VECTOR(N_bits-1 downto 0); 
	    x : STD_LOGIC_VECTOR(N_bits downto 0);
	    y : STD_LOGIC_VECTOR(N_bits downto 0);
	end record;
    type t_iter is array(0 to N_steps) of t_tuple;
    --**** Constantes ****
    constant right_angle :  signed(N_bits-1 downto 0):= (N_bits-2 => '1', others => '0');
    constant straight_angle : signed(N_bits-1 downto 0):= (N_bits-1 => '1', others => '0');
    -- Valores iniciales
    constant xo : signed(N_bits downto 0):=to_signed(2**(N_bits-1)-1,N_bits+1);
    constant yo : signed(N_bits downto 0):=to_signed(0,N_bits+1);
    constant ao : signed(N_bits-1 downto 0):=to_signed(0,N_bits);
    constant tuple_init : t_tuple := (a => STD_LOGIC_VECTOR(ao), x => STD_LOGIC_VECTOR(yo), y => STD_LOGIC_VECTOR(yo));
    --**** Tablas ****
    constant K : t_table := (	to_signed(1518500249,32), 
                           	to_signed(1358187913,32),
                               	to_signed(1317635817,32), 
                              	to_signed(1307460871,32), 
                               	to_signed(1304914694,32),
                               	to_signed(1304277994,32), 
                               	to_signed(1304118810,32), 
                              	to_signed(1304079013,32), 
                              	to_signed(1304069064,32), 
                               	to_signed(1304066577,32),
                               	to_signed(1304065955,32), 
                               	to_signed(1304065799,32), 
                               	to_signed(1304065761,32), 
                              	to_signed(1304065751,32), 
                             	to_signed(1304065748,32),
                               	to_signed(1304065748,32));
    constant angle_steps : t_table := (   "00100000000000000000000000000000",-- 45.000 * (1/180) * 2 ^ 31 
                                  "00010010111001000000010100011101",-- 26.565 * (1/180) * 2 ^ 31
                                  "00001001111110110011100001011011",-- 14.036 * (1/180) * 2 ^ 31
                                  "00000101000100010001000111010100",--  7.125 * (1/180) * 2 ^ 31
                                  "00000010100010110000110101000011",--  3.576 * (1/180) * 2 ^ 31
                                  "00000001010001011101011111100001",--  1.790 * (1/180) * 2 ^ 31
                                  "00000000101000101111011000011110",--  0.895 * (1/180) * 2 ^ 31
                                  "00000000010100010111110001010101",--  0.448 * (1/180) * 2 ^ 31
                                  "00000000001010001011111001010011",--  0.224 * (1/180) * 2 ^ 31
                                  "00000000000101000101111100101110",--  0.112 * (1/180) * 2 ^ 31
                                  "00000000000010100010111110011000",--  0.056 * (1/180) * 2 ^ 31
                                  "00000000000001010001011111001100",--  0.028 * (1/180) * 2 ^ 31
                                  "00000000000000101000101111100110",--  0.014 * (1/180) * 2 ^ 31
                                  "00000000000000010100010111110011",--  0.007 * (1/180) * 2 ^ 31
                                  "00000000000000001010001011111001",--  0.004 * (1/180) * 2 ^ 31
                                  "00000000000000000101000101111100");-- 0.002 * (1/180) * 2 ^ 31 
    --**** Variables ****
    signal iteration_data : t_iter := 	(others => tuple_init);
begin
--iteration_data(0).a <= STD_LOGIC_VECTOR(resize(signed(degrees),N_bits+1));
x_out <= STD_LOGIC_VECTOR(resize(signed(iteration_data(N_steps).x),N_bits));
y_out <= STD_LOGIC_VECTOR(resize(signed(iteration_data(N_steps).y),N_bits));

rotation_start : process(clk,enable)
    begin
	if ((rising_edge(clk))and(enable = '1')) then
	    if signed(degrees) < right_angle then
		if signed(degrees) > -right_angle then
		    iteration_data(0).x <= STD_LOGIC_VECTOR(resize(signed(x_in),N_bits+1));
		    iteration_data(0).y <= STD_LOGIC_VECTOR(resize(signed(y_in),N_bits+1));
		    iteration_data(0).a <= STD_LOGIC_VECTOR(signed(degrees));
		else
		    iteration_data(0).x <= STD_LOGIC_VECTOR(resize(-signed(x_in),N_bits+1));
		    iteration_data(0).y <= STD_LOGIC_VECTOR(resize(-signed(y_in),N_bits+1));
		    iteration_data(0).a <= STD_LOGIC_VECTOR(signed(degrees) + straight_angle);
		end if;
	    else
		iteration_data(0).x <= STD_LOGIC_VECTOR(resize(-signed(x_in),N_bits+1));
		iteration_data(0).y <= STD_LOGIC_VECTOR(resize(-signed(y_in),N_bits+1));
		iteration_data(0).a <= STD_LOGIC_VECTOR(signed(degrees) - straight_angle);
	    end if;
	end if;
    end process;

iterations: for i in 0 to N_steps-2 generate
	iteration_inst: CORDIC_IT 
	    generic map(N_bits,i,angle_steps(i))
	    port map(clk=>clk,
	             ena=>enable,  
	             ai=>iteration_data(i).a,
	             xi=>iteration_data(i).x,
	             yi=>iteration_data(i).y,
	             ao=>iteration_data(i+1).a,
	             xo=>iteration_data(i+1).x,
	             yo=>iteration_data(i+1).y);
    end generate;

scaling: process(clk)
    variable aux1 : signed(N_bits downto 0);
    variable aux2 : signed(2*(N_bits+1)-1 downto 0);
    begin
        if rising_edge(clk) then
		aux1 := signed(iteration_data(N_steps-1).x);
		aux2 := aux1 * (resize(K(N_steps-1)(31 downto 32-N_bits),N_bits+1));
		iteration_data(N_steps).x <= STD_LOGIC_VECTOR(aux2(N_bits+N_bits-1 downto N_bits-1));
		aux1 := signed(iteration_data(N_steps-1).y);
		aux2 := aux1 * (resize(K(N_steps-1)(31 downto 32-N_bits),N_bits+1));
		iteration_data(N_steps).y <= STD_LOGIC_VECTOR(aux2(N_bits+N_bits-1 downto N_bits-1));
	    end if;
    end process;
end Behavioral;
