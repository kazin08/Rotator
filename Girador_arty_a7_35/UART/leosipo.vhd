library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--* LEOSIPO
--*
--* Interpreta lo ingresado por UART luego de pasar por SIPO
--* Las salidas son 4:
--*		I = izquierda, antihorario
--*		D = derecha, horario
--*		ang = angulo a girar
--*		C = si es continuo (1) o no (0)
--* las letra que se usan estan en MAYUS del UART para comparar
--* 

entity leosipo is
  generic (
    WORD_WIDTH		: natural;	-- 8, ancho de la letra
	PARALLEL_WIDTH  : natural;	-- 9, letras en total
    LETRA_R			: natural := 82;
	LETRA_O			: natural := 79;
	LETRA_T			: natural := 84;
	LETRA_C			: natural := 67;
	LETRA_A			: natural := 65;
	LETRA_H			: natural := 72;
	LETRA_ESP		: natural := 32	--espacio
    --COMP		    : natural := 10   --10 o 13 es el ENTER en UART
    );
  port (
    clk : in std_logic;
    rst : in std_logic;

    p_in : in std_logic_vector (PARALLEL_WIDTH*WORD_WIDTH-1 downto 0);	--entrada de palabras a comparar

    I : out std_logic;	-- gira en sentido antihorario
	D : out std_logic;	-- gira en sentido horario
	ang : out std_logic_vector (3*WORD_WIDTH-1 downto 0);	-- angulo a girar
	C : out std_logic	-- continuo o no
    --to_zero : out  std_logic	-- se pone en 1 cuando compara y se recibe un '\n' para resetear a SIPO
    );
end entity;

architecture arch of leosipo is
signal LETRA_R_std 	: std_logic_vector (WORD_WIDTH-1 downto 0);
signal LETRA_O_std	: std_logic_vector (WORD_WIDTH-1 downto 0);
signal LETRA_T_std 	: std_logic_vector (WORD_WIDTH-1 downto 0);
signal LETRA_C_std 	: std_logic_vector (WORD_WIDTH-1 downto 0);
signal LETRA_A_std 	: std_logic_vector (WORD_WIDTH-1 downto 0);
signal LETRA_H_std 	: std_logic_vector (WORD_WIDTH-1 downto 0);
signal LETRA_ESP_std 	: std_logic_vector (WORD_WIDTH-1 downto 0);

signal ROT_C_H		: std_logic_vector (7*WORD_WIDTH-1 downto 0);	--rot continua horario (derecha)
signal ROT_C_A		: std_logic_vector (7*WORD_WIDTH-1 downto 0);	--rot continua antihorario (izquierda)

signal ROT_A		: std_logic_vector (6*WORD_WIDTH-1 downto 0);	--rot de una vez con angulo xxx

signal COMPARO_C	: std_logic_vector (7*WORD_WIDTH-1 downto 0);	--senal para comparar cargando los valores de entrada
signal COMPARO_A	: std_logic_vector (6*WORD_WIDTH-1 downto 0);	--senal para comparar cargando los valores de entrada


begin
-- This line demonstrates how to convert positive integers
LETRA_R_std <= std_logic_vector(to_unsigned(LETRA_R, LETRA_R_std'length));
LETRA_O_std <= std_logic_vector(to_unsigned(LETRA_O, LETRA_O_std'length));
LETRA_T_std <= std_logic_vector(to_unsigned(LETRA_T, LETRA_T_std'length));
LETRA_C_std <= std_logic_vector(to_unsigned(LETRA_C, LETRA_C_std'length));
LETRA_A_std <= std_logic_vector(to_unsigned(LETRA_A, LETRA_A_std'length));
LETRA_H_std <= std_logic_vector(to_unsigned(LETRA_H, LETRA_H_std'length));
LETRA_ESP_std <= std_logic_vector(to_unsigned(LETRA_ESP, LETRA_ESP_std'length));


  process(clk,rst)
  variable conteo : integer := 0;
  
  --slv64 <= (slv16_4, slv16_3, slv16_2, slv16_1);
  --firstpart <= allparts(15 downto 8);
  
  begin
    if (clk'event and clk = '1') then
      if (rst = '1') then
        I  <= '0';
		D  <= '0';
		ang  <= (others => '0');
		C  <= '0';
		--p_in <= (others => '0');
		conteo := 0;
      else
        --if vector_slv = (vector_slv'range => '0') then
        if not(p_in = (p_in'range => '0')) then
			-- comparo para ver si gira en sentido horario y en continuo
			if ((COMPARO_C <= (p_in(55 downto 0))) = (ROT_C_H <= (LETRA_R_std & LETRA_O_std & LETRA_T_std & LETRA_ESP_std & LETRA_C_std & LETRA_ESP_std & LETRA_H_std))) then
				I <= '0';
				D <= '1';
				ang <= (others => '0');
				C <= '1';
			end if;
			-- comparo para ver si gira en sentido antihorario y en continuo
			if ((COMPARO_C <= (p_in(55 downto 0))) = (ROT_C_A <= (LETRA_R_std & LETRA_O_std & LETRA_T_std & LETRA_ESP_std & LETRA_C_std & LETRA_ESP_std & LETRA_A_std))) then
				I <= '1';
				D <= '0';
				ang <= (others => '0');
				C <= '1';
			end if;
			
			-- comparo para ver si gira un cierto angulo
			if ((COMPARO_A <= (p_in(47 downto 0))) = (ROT_A <= (LETRA_R_std & LETRA_O_std & LETRA_T_std & LETRA_ESP_std & LETRA_A_std & LETRA_ESP_std))) then
				I <= '0';
				D <= '1';
				ang <= p_in(PARALLEL_WIDTH*WORD_WIDTH-1 downto 48);
				C <= '0';
			end if;			
		  
        end if;
      end if;
    end if;
  end process;

end architecture;