library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.funciones.all;

--* SIPO Serial Input Parallel Output
--*
--* Toma como entrada "PARALLEL_WIDTH" palabras de "WORD_WIDTH" cada
--* una y devuelve una palabra de "PARALLEL_WIDTH * WORD_WIDTH".
--* La logica de sincronismo debe ser externa. En esta arquitectura
--* se apunta a la simplicidad de la logica.
--* La salida "p_out" se vuelve valida un clock despues de levantar 
--* "read_en" y entrega lo que se haya cargado hasta ese momento en el 
--* registro de desplazamiento
--* "BIG_ENDIAN" en true implica:
--* 
--* "s_in" : 0,1,2,3 -> entra primero 0
--* "p_out": (0123) -> MSW es 0
--* 
--* "BIG_ENDIAN" en false implica:
--* 
--* "s_in" : 0,1,2,3 -> entra primero 0"
--* "p_out": (3210) -> MSW es 3
--* 

entity sipo is
  generic (
    WORD_WIDTH     : natural;
    PARALLEL_WIDTH : natural;
    BIG_ENDIAN     : boolean := true
    );
  port (
    clk : in std_logic;
    rst : in std_logic;

    s_in  : in std_logic_vector (WORD_WIDTH-1 downto 0);
    wr_en : in std_logic;

    p_out : out std_logic_vector (PARALLEL_WIDTH*WORD_WIDTH-1 downto 0);
    rd_en : in  std_logic
    );
end entity;

architecture rtl of sipo is

  type array_of_stdlv is
    array (PARALLEL_WIDTH -1 downto 0) of std_logic_vector(WORD_WIDTH-1 downto 0);

  signal tmp        : array_of_stdlv;
  signal p_out_next : std_logic_vector (PARALLEL_WIDTH*WORD_WIDTH-1 downto 0);

  component delay_en_1 is
    generic (
      WORD_WIDTH : natural;
      RST_VALUE  : std_logic_vector
      );
    port (
      clk       : in  std_logic;
      rst       : in  std_logic;
      en        : in  std_logic;
      s         : in  std_logic_vector (WORD_WIDTH - 1 downto 0);
      s_delayed : out std_logic_vector (WORD_WIDTH - 1 downto 0)
      );
  end component;

begin
  
  delay_gen:
  for i in 0 to PARALLEL_WIDTH - 2 generate
    dly_gen : delay_en_1
      generic map(
        WORD_WIDTH => WORD_WIDTH,
        RST_VALUE  => zeros(WORD_WIDTH)
        )
      port map(
        clk       => clk,
        rst       => rst,
        en        => wr_en,
        s         => tmp(i),
        s_delayed => tmp(i + 1)
        );

    big_endian_if :
    if BIG_ENDIAN generate
      p_out_next((i + 1)*WORD_WIDTH-1 downto i*WORD_WIDTH)                           <= tmp(i);
      p_out_next(PARALLEL_WIDTH*WORD_WIDTH-1 downto (PARALLEL_WIDTH - 1)*WORD_WIDTH) <= tmp(PARALLEL_WIDTH - 1);
    end generate;

    little_endian_if :
    if not BIG_ENDIAN generate
      p_out_next((PARALLEL_WIDTH - i)*WORD_WIDTH-1 downto (PARALLEL_WIDTH - i - 1)*WORD_WIDTH) <= tmp(i);
      p_out_next(WORD_WIDTH - 1 downto 0)                                                      <= tmp(PARALLEL_WIDTH - 1);
    end generate;
    
  end generate;

  process(clk)
  begin
    if (clk'event and clk = '1') then
      if (rst = '1') then
        p_out  <= (others => '0');
        tmp(0) <= (others => '0');
      else
        if(wr_en = '1') then
          tmp(0) <= s_in;
        end if;

        if rd_en = '1' then
          p_out <= p_out_next;
        end if;
      end if;
    end if;
  end process;

end architecture;
