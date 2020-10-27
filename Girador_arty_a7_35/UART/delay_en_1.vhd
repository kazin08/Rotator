library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

--* Genera un delay de una muestra 
--* 
--* Permite latchearlo por medio de la senal "en"

entity delay_en_1 is
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
end entity;

architecture rtl of delay_en_1 is

  signal s_next : std_logic_vector(WORD_WIDTH - 1 downto 0);
  signal s_reg  : std_logic_vector(WORD_WIDTH - 1 downto 0);

begin

  delay:
  process(clk, rst)
  begin
    if (clk = '1' and clk'event) then
      if rst = '1' then
        s_reg <= RST_VALUE;
      elsif (en = '1') then
        s_reg <= s_next;
      end if;
    end if;
  end process;

  s_next    <= s;
  s_delayed <= s_reg;
  
end architecture;
