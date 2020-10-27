---------------------------------------------------------
--
-- Controlador de VGA
-- Version actualizada a 07/06/2016
--
-- Modulos:
--    vga_sync
--    gen_pixels
--
---------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_ctrl is
	port(
	    sys_clk: in std_logic;
		rst: in std_logic;
		--sw: in std_logic_vector (2 downto 0);-- parece que no se usa esta variable
		hsync , vsync : out std_logic;
		red : out std_logic_vector(3 downto 0);
		green : out std_logic_vector(3 downto 0);
		blue : out std_logic_vector(3 downto 0);
		pixel_clock : out std_logic;
        video_read_add : out std_logic_vector(18 downto 0);
        pix_value : in std_logic_vector(0 downto 0);
        frame_tick : out std_logic
		-- agregar puertos para interactuar con la video mem: pix_clk, video_add y pixel_value
	);
	
	-- attribute LOC: string;
	-- attribute LOC of clk: signal is "C9";
	-- attribute LOC of rst: signal is "D18";
	-- attribute LOC of sw: signal is "H18 L14 L13";
	-- attribute LOC of hsync: signal is "F15";
	-- attribute LOC of vsync: signal is "F14";
	-- attribute LOC of rgb: signal is "H14 H15 G15";

end vga_ctrl;

architecture vga_ctrl_arch of vga_ctrl is

	signal rgb_reg: std_logic_vector(2 downto 0);-- parece que no se usa
	signal pixel_x, pixel_y: std_logic_vector(9 downto 0);
	signal video_on: std_logic;
	signal pix_clock : std_logic;
    signal add_video_mem : std_logic_vector (18 downto 0);
    --signal pixel_value : std_logic_vector (0 downto 0);
    signal pixel : std_logic_vector (2 downto 0);
    signal clk50 : std_logic;
    signal frame : std_logic := '1';
    
    --clock_unit_wrapper
    component clk_wiz_0 is
  port (
    clk_in1 : in STD_LOGIC;
    clk_out1 : out STD_LOGIC;
    locked : out STD_LOGIC;
    reset : in STD_LOGIC
  );
end component;

begin
    --clock_unit: clock_unit_wrapper
    clock_unit: clk_wiz_0
        port map (
        clk_out1 => clk50,
        locked => open,
        reset => rst,
        clk_in1 => sys_clk
        );
	-- instanciacion del controlador VGA
	vga_sync_unit: entity work.vga_sync
		port map(
			clk 	=> clk50,
			rst 	=> rst,
			hsync 	=> hsync,
			vsync 	=> vsync,
			vidon	=> video_on,
			p_tick 	=> pix_clock,
			pixel_x => pixel_x,
			pixel_y => pixel_y
		);

	pixeles: entity work.gen_pixels
		port map(
			clk		=> clk50,
			reset	=> rst,
			sw		=> pixel,
			pixel_x	=> pixel_x,
			pixel_y	=> pixel_y,
			ena		=> video_on,
			red		=> red,
			green  => green,
			blue   => blue
		);
		
-- contador para generar el address (controlado por pixel_clock y reseteado por pixel_x y pixel_y)
process (pix_clock,rst, pixel_x,pixel_y)
    variable conteo : integer := 0;
    begin
    if ((rst = '1') or ((pixel_x = "0000000000") and (pixel_y = "0000000000"))) then
        conteo := 0;
        frame<='0';
    else
        if (rising_edge (pix_clock)) then
            conteo := conteo + 1;
        end if;
        if (conteo = 384000) then   -- 800*480=384000
            frame <='1';
        end if;
        --if (conteo = 384100) then   --384100
        --    frame <='0';
        --end if;
        if (conteo >= 420000) then   -- 800*525
            conteo := 0;
        end if;
    end if;
    add_video_mem <= std_logic_vector(to_unsigned(conteo,add_video_mem'length));
end process;

pixel <= pix_value(0) & pix_value(0) & pix_value(0); 	
pixel_clock<=pix_clock;
video_read_add<=add_video_mem;
frame_tick <= frame;
	
end vga_ctrl_arch;