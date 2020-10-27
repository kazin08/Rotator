library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--* compAndCount
--*
--* Compara con '\n' para saber cuando termina la entrada en UART
--* cuenta hasta el fin de numeros que pueda almacenar para despues borrar a SIPO
--* 

entity compandcount is
  generic (
    WORD_WIDTH		: natural;
    COUNT			: natural := 12;
    COMP		    : natural := 10   --10 o 13 es el ENTER en UART
    );
  port (
    clk : in std_logic;
    rst : in std_logic;

    in_nchars  : in std_logic;		-- entrada para contar caracteres recibidos
	in_char    : in std_logic_vector (WORD_WIDTH-1 downto 0);	--entrada para comparar caracteres

    coun_out : out std_logic	-- se pone en 1 cuando llego a la maxima cuenta de caracteres
    --to_zero : out  std_logic	-- se pone en 1 cuando compara y se recibe un '\n' para resetear a SIPO
    );
end entity;

architecture arch of compandcount is
signal COMP_std : std_logic_vector (WORD_WIDTH-1 downto 0);

begin
-- This line demonstrates how to convert positive integers
COMP_std <= std_logic_vector(to_unsigned(COMP, COMP_std'length));

  process(clk,rst)
  variable conteo : integer := 0;
  
  begin
    if (clk'event and clk = '1') then
      if (rst = '1') then
        coun_out  <= '0';
        --to_zero <= (others => '0');
		conteo := 0;
      else
        if(in_nchars = '1') then
		  conteo := conteo + 1;
		  
          if (conteo > COUNT) then
			coun_out <= '1';
		  end if;
		  
		  if (in_char = COMP_std) then
			coun_out <= '1';
		  end if;
		  
        end if;
      end if;
    end if;
  end process;

end architecture;