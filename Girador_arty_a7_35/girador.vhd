library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
use work.my_library.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


entity girador is
  Port ( 
    --VGA
    sys_clk: in std_logic;
    rst: in std_logic;
    hsync , vsync : out std_logic;
    red : out std_logic_vector(3 downto 0);
    green : out std_logic_vector(3 downto 0);
    blue : out std_logic_vector(3 downto 0);
    --UART input/output
    rxd_pin : in std_logic;
    txd_pin : out std_logic;
    -- Tal vez necesite botones
    sw : in std_logic_vector(2 downto 0);
    --LEDS para debug
    led: out std_logic_vector(3 downto 0)
  );
  
  --pines
--  	attribute LOC: string;
--	attribute IOSTANDARD:string;
--	attribute LOC of rxd_pin: signal is "D10";  --U6
--	attribute IOSTANDARD of rxd_pin: signal is "LVCMOS33";
    
  
end girador;

architecture gir_arq of girador is
    -- COMPONENTES
--    component fontrom --evaluar si es necesaria
--        generic(
--            N: integer:= 6;
--            M: integer:= 3;
--            W: integer:= 8
--        );
--        port(
--            char_address: in std_logic_vector(5 downto 0);
--            font_row, font_col: in std_logic_vector(M-1 downto 0);
--            rom_out: out std_logic
--        );
--    end component;

component video_mem_wrapper is
  port (
    addra_0 : in STD_LOGIC_VECTOR ( 18 downto 0 );
    addrb_0 : in STD_LOGIC_VECTOR ( 18 downto 0 );
    clka_0 : in STD_LOGIC;
    clkb_0 : in STD_LOGIC;
    dina_0 : in STD_LOGIC_VECTOR ( 0 to 0 );
    doutb_0 : out STD_LOGIC_VECTOR ( 0 to 0 );
    ena_0 : in STD_LOGIC;
    enb_0 : in STD_LOGIC;
    wea_0 : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
end component;

    component vga_ctrl is
        port(
            sys_clk: in std_logic;
            rst: in std_logic;
            --sw: in std_logic_vector (2 downto 0);
            hsync , vsync : out std_logic;
            red : out std_logic_vector(3 downto 0);
            green : out std_logic_vector(3 downto 0);
            blue : out std_logic_vector(3 downto 0);
            -- agregar conexionado para interactuar con memoria
            pixel_clock : out std_logic;
            video_read_add : out std_logic_vector(18 downto 0);
            pix_value : in std_logic_vector(0 downto 0);
            frame_tick : out std_logic
        );
    end component;
    
    component uart_rx is
        generic(
            BAUD_RATE: integer := 115200; 	-- Baud rate
            CLOCK_RATE: integer := 50E6
        );
    
        port(
            -- Write side inputs
            clk_rx: in std_logic;       				-- Clock input
            rst_clk_rx: in std_logic;   				-- Active HIGH reset - synchronous to clk_rx
                            
            rxd_i: in std_logic;        				-- RS232 RXD pin - Directly from pad
            rxd_clk_rx: out std_logic;					-- RXD pin after synchronization to clk_rx
        
            rx_data: out std_logic_vector(7 downto 0);	-- 8 bit data output
                                                        --  - valid when rx_data_rdy is asserted
            rx_data_rdy: out std_logic;  				-- Ready signal for rx_data
            frm_err: out std_logic       				-- The STOP bit was not detected	
        );
    end component;

-- componente de uart
--    component uart is
--	generic (
--		F : natural := 50000;	-- Device clock frequency [KHz].
--		min_baud : natural := 1200;
--		num_data_bits : natural := 8
--	);
--	port (
--		Rx	: in std_logic;
--		Tx	: out std_logic;
--		Din	: in std_logic_vector(7 downto 0);
--		StartTx	: in std_logic;
--		TxBusy	: out std_logic;
--		Dout	: out std_logic_vector(7 downto 0);
--		RxRdy	: out std_logic;
--		RxErr	: out std_logic;
--		Divisor	: in std_logic_vector;
--		clk	: in std_logic;
--		rst	: in std_logic
--	);
--    end component;


-- componente sipo    
    component sipo is
      generic (
        WORD_WIDTH     : natural := 8;
        PARALLEL_WIDTH : natural := 9;
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
   end component;
   
   
-- componente leo sipo
    component leosipo is
      generic (
        WORD_WIDTH		: natural := 8;	-- 8, ancho de la letra
        PARALLEL_WIDTH  : natural := 9;	-- 9, letras en total
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
    end component; 
    
    
-- componente comp/count
    component compandcount is
      generic (
        WORD_WIDTH		: natural := 8;
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
    end component;  

-- pulsadores    
    component meta_harden is
        port(
            clk_dst:     in std_logic;    -- Destination clock
            rst_dst:     in std_logic;    -- Reset - synchronous to destination clock
            signal_src: in std_logic;    -- Asynchronous signal to be synchronized
            signal_dst: out std_logic    -- Synchronized signal
        );
    end component;
    
    component CORDIC_top is
        Generic(	N_bits : natural := 8;  -- máximo 32
                    N_steps: natural := 8); -- máximo 16
        Port(	clk : in STD_LOGIC;
                enable : in STD_LOGIC;
                degrees : in STD_LOGIC_VECTOR (N_bits-1 downto 0);
                x_in : in STD_LOGIC_VECTOR (N_bits-1 downto 0);
                y_in : in STD_LOGIC_VECTOR (N_bits-1 downto 0);
                x_out : out STD_LOGIC_VECTOR (N_bits-1 downto 0);
                y_out : out STD_LOGIC_VECTOR (N_bits-1 downto 0));
    end component;
    
    component delay is
        port ( i_in : in  t_punto;
	           clk : in std_logic;
	           ena : in std_logic;
	           o_out : out t_punto);
    end component;
    -- Constantes
    --constant N_bits : natural := 9;
    constant N_steps : natural := 10;  --11
    constant N_points : natural := 240;  --240
--    -- Tipos personalizados (están en la biblioteca)
--    type t_punto is record 
--        x : STD_LOGIC_VECTOR(N_bits-1 downto 0);
--        y : STD_LOGIC_VECTOR(N_bits-1 downto 0);
--    end record;
--    type t_array_punto is array(0 to N_points) of t_punto;
    -- VARIABLES
    -- VGA
    signal pixel_value_reg : std_logic_vector (0 downto 0);--este es para setear deberÃ­a irse
    signal add_video_mem_load : std_logic_vector (18 downto 0);--deberÃ­a irse
    signal pixel : std_logic_vector (2 downto 0);
    signal pixel_in : std_logic_vector (0 downto 0);
    signal pixel_value : std_logic_vector(0 downto 0);
    signal add_video_mem : std_logic_vector(18 downto 0);
    signal pix_clock : std_logic;
    --signal pantalla : std_logic;--no usado
    --signal char_add : std_logic_vector(5 downto 0);--esto no se necesita
    --signal font_row : std_logic_vector(2 downto 0);--not needed
    --signal font_column : std_logic_vector(2 downto 0);--not needed
    --signal rom_out : std_logic;--not needed
    signal fr_tick : std_logic;
    -- UART
    signal rst_clk_rx: std_logic;
--    signal rx_data: std_logic_vector(7 downto 0);     -- Data output of uart_rx
--    signal rx_data_rdy: std_logic;                  -- Data ready output of uart_rx
    -- PUNTOS
    -- Aca va un array con los puntos que se van a girar para ver una recta
    constant puntos : t_array_punto(0 to N_points-1) := (0 => (x => std_logic_vector(to_signed(   0*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         1 => (x => std_logic_vector(to_signed(   1*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         2 => (x => std_logic_vector(to_signed(   2*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         3 => (x => std_logic_vector(to_signed(   3*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         4 => (x => std_logic_vector(to_signed(   4*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         5 => (x => std_logic_vector(to_signed(   5*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         6 => (x => std_logic_vector(to_signed(   6*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         7 => (x => std_logic_vector(to_signed(   7*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         8 => (x => std_logic_vector(to_signed(   8*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         9 => (x => std_logic_vector(to_signed(   9*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         10 => (x => std_logic_vector(to_signed( 10*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         11 => (x => std_logic_vector(to_signed( 11*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         12 => (x => std_logic_vector(to_signed( 12*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         13 => (x => std_logic_vector(to_signed( 13*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         14 => (x => std_logic_vector(to_signed( 14*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         15 => (x => std_logic_vector(to_signed( 15*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         16 => (x => std_logic_vector(to_signed( 16*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         17 => (x => std_logic_vector(to_signed( 17*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         18 => (x => std_logic_vector(to_signed( 18*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         19 => (x => std_logic_vector(to_signed( 19*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         20 => (x => std_logic_vector(to_signed(  20*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         21 => (x => std_logic_vector(to_signed(  21*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         22 => (x => std_logic_vector(to_signed(  22*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         23 => (x => std_logic_vector(to_signed(  23*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         24 => (x => std_logic_vector(to_signed(  24*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         25 => (x => std_logic_vector(to_signed(  25*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         26 => (x => std_logic_vector(to_signed(  26*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         27 => (x => std_logic_vector(to_signed(  27*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         28 => (x => std_logic_vector(to_signed(  28*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         29 => (x => std_logic_vector(to_signed(  29*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         30 => (x => std_logic_vector(to_signed( 30*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         31 => (x => std_logic_vector(to_signed( 31*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         32 => (x => std_logic_vector(to_signed( 32*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         33 => (x => std_logic_vector(to_signed( 33*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         34 => (x => std_logic_vector(to_signed( 34*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         35 => (x => std_logic_vector(to_signed( 35*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         36 => (x => std_logic_vector(to_signed( 36*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         37 => (x => std_logic_vector(to_signed( 37*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         38 => (x => std_logic_vector(to_signed( 38*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         39 => (x => std_logic_vector(to_signed( 39*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         40 => (x => std_logic_vector(to_signed( 40*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         41 => (x => std_logic_vector(to_signed( 41*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         42 => (x => std_logic_vector(to_signed( 42*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         43 => (x => std_logic_vector(to_signed( 43*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         44 => (x => std_logic_vector(to_signed( 44*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         45 => (x => std_logic_vector(to_signed( 45*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         46 => (x => std_logic_vector(to_signed(  46*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         47 => (x => std_logic_vector(to_signed(  47*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         48 => (x => std_logic_vector(to_signed(  48*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         49 => (x => std_logic_vector(to_signed(  49*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         50 => (x => std_logic_vector(to_signed( 50*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         51 => (x => std_logic_vector(to_signed( 51*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         52 => (x => std_logic_vector(to_signed( 52*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         53 => (x => std_logic_vector(to_signed( 53*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         54 => (x => std_logic_vector(to_signed( 54*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         55 => (x => std_logic_vector(to_signed( 55*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         56 => (x => std_logic_vector(to_signed( 56*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         57 => (x => std_logic_vector(to_signed( 57*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         58 => (x => std_logic_vector(to_signed( 58*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         59 => (x => std_logic_vector(to_signed( 59*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         60 => (x => std_logic_vector(to_signed(   60*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         61 => (x => std_logic_vector(to_signed(   61*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         62 => (x => std_logic_vector(to_signed(   62*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         63 => (x => std_logic_vector(to_signed(   63*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         64 => (x => std_logic_vector(to_signed(   64*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         65 => (x => std_logic_vector(to_signed(   65*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         66 => (x => std_logic_vector(to_signed(   66*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         67 => (x => std_logic_vector(to_signed(   67*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         68 => (x => std_logic_vector(to_signed(   68*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         69 => (x => std_logic_vector(to_signed(   69*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         70 => (x => std_logic_vector(to_signed( 70*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         71 => (x => std_logic_vector(to_signed( 71*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         72 => (x => std_logic_vector(to_signed( 72*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         73 => (x => std_logic_vector(to_signed( 73*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         74 => (x => std_logic_vector(to_signed( 74*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         75 => (x => std_logic_vector(to_signed( 75*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         76 => (x => std_logic_vector(to_signed( 76*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         77 => (x => std_logic_vector(to_signed( 77*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         78 => (x => std_logic_vector(to_signed( 78*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         79 => (x => std_logic_vector(to_signed( 79*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         80 => (x => std_logic_vector(to_signed( 80*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         81 => (x => std_logic_vector(to_signed( 81*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         82 => (x => std_logic_vector(to_signed( 82*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         83 => (x => std_logic_vector(to_signed( 83*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         84 => (x => std_logic_vector(to_signed( 84*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         85 => (x => std_logic_vector(to_signed( 85*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         86 => (x => std_logic_vector(to_signed( 86*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         87 => (x => std_logic_vector(to_signed( 87*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         88 => (x => std_logic_vector(to_signed( 88*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         89 => (x => std_logic_vector(to_signed( 89*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         90 => (x => std_logic_vector(to_signed( 90*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         91 => (x => std_logic_vector(to_signed( 91*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         92 => (x => std_logic_vector(to_signed( 92*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         93 => (x => std_logic_vector(to_signed( 93*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         94 => (x => std_logic_vector(to_signed( 94*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         95 => (x => std_logic_vector(to_signed( 95*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         96 => (x => std_logic_vector(to_signed( 96*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         97 => (x => std_logic_vector(to_signed( 97*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         98 => (x => std_logic_vector(to_signed( 98*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         99 => (x => std_logic_vector(to_signed( 99*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         100 => (x => std_logic_vector(to_signed(100*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         101 => (x => std_logic_vector(to_signed(101*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         102 => (x => std_logic_vector(to_signed(102*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         103 => (x => std_logic_vector(to_signed(103*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         104 => (x => std_logic_vector(to_signed(104*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         105 => (x => std_logic_vector(to_signed(105*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         106 => (x => std_logic_vector(to_signed(106*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         107 => (x => std_logic_vector(to_signed(107*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         108 => (x => std_logic_vector(to_signed(108*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         109 => (x => std_logic_vector(to_signed(109*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         110 => (x => std_logic_vector(to_signed(110*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         111 => (x => std_logic_vector(to_signed(111*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         112 => (x => std_logic_vector(to_signed(112*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         113 => (x => std_logic_vector(to_signed(113*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         114 => (x => std_logic_vector(to_signed(114*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         115 => (x => std_logic_vector(to_signed(115*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         116 => (x => std_logic_vector(to_signed(116*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         117 => (x => std_logic_vector(to_signed(117*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         118 => (x => std_logic_vector(to_signed(118*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         119 => (x => std_logic_vector(to_signed(119*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         120 => (x => std_logic_vector(to_signed(120*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         121 => (x => std_logic_vector(to_signed(121*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         122 => (x => std_logic_vector(to_signed(122*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         123 => (x => std_logic_vector(to_signed(123*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         124 => (x => std_logic_vector(to_signed(124*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         125 => (x => std_logic_vector(to_signed(125*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         126 => (x => std_logic_vector(to_signed(126*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         127 => (x => std_logic_vector(to_signed(127*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         128 => (x => std_logic_vector(to_signed(128*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         129 => (x => std_logic_vector(to_signed(129*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         130 => (x => std_logic_vector(to_signed(130*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         131 => (x => std_logic_vector(to_signed(131*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         132 => (x => std_logic_vector(to_signed(132*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         133 => (x => std_logic_vector(to_signed(133*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         134 => (x => std_logic_vector(to_signed(134*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         135 => (x => std_logic_vector(to_signed(135*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         136 => (x => std_logic_vector(to_signed(136*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         137 => (x => std_logic_vector(to_signed(137*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         138 => (x => std_logic_vector(to_signed(138*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         139 => (x => std_logic_vector(to_signed(139*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         140 => (x => std_logic_vector(to_signed(140*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         141 => (x => std_logic_vector(to_signed(141*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         142 => (x => std_logic_vector(to_signed(142*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         143 => (x => std_logic_vector(to_signed(143*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         144 => (x => std_logic_vector(to_signed(144*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         145 => (x => std_logic_vector(to_signed(145*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         146 => (x => std_logic_vector(to_signed(146*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         147 => (x => std_logic_vector(to_signed(147*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         148 => (x => std_logic_vector(to_signed(148*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         149 => (x => std_logic_vector(to_signed(149*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         150 => (x => std_logic_vector(to_signed(150*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         151 => (x => std_logic_vector(to_signed(151*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         152 => (x => std_logic_vector(to_signed(152*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         153 => (x => std_logic_vector(to_signed(153*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         154 => (x => std_logic_vector(to_signed(154*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         155 => (x => std_logic_vector(to_signed(155*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         156 => (x => std_logic_vector(to_signed(156*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         157 => (x => std_logic_vector(to_signed(157*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         158 => (x => std_logic_vector(to_signed(158*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         159 => (x => std_logic_vector(to_signed(159*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         160 => (x => std_logic_vector(to_signed(160*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         161 => (x => std_logic_vector(to_signed(161*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         162 => (x => std_logic_vector(to_signed(162*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         163 => (x => std_logic_vector(to_signed(163*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         164 => (x => std_logic_vector(to_signed(164*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         165 => (x => std_logic_vector(to_signed(165*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         166 => (x => std_logic_vector(to_signed(166*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         167 => (x => std_logic_vector(to_signed(167*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         168 => (x => std_logic_vector(to_signed(168*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         169 => (x => std_logic_vector(to_signed(169*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         170 => (x => std_logic_vector(to_signed(170*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         171 => (x => std_logic_vector(to_signed(171*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         172 => (x => std_logic_vector(to_signed(172*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         173 => (x => std_logic_vector(to_signed(173*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         174 => (x => std_logic_vector(to_signed(174*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         175 => (x => std_logic_vector(to_signed(175*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         176 => (x => std_logic_vector(to_signed(176*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         177 => (x => std_logic_vector(to_signed(177*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         178 => (x => std_logic_vector(to_signed(178*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         179 => (x => std_logic_vector(to_signed(179*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         180 => (x => std_logic_vector(to_signed(180*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         181 => (x => std_logic_vector(to_signed(181*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         182 => (x => std_logic_vector(to_signed(182*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         183 => (x => std_logic_vector(to_signed(183*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         184 => (x => std_logic_vector(to_signed(184*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         185 => (x => std_logic_vector(to_signed(185*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         186 => (x => std_logic_vector(to_signed(186*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         187 => (x => std_logic_vector(to_signed(187*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         188 => (x => std_logic_vector(to_signed(188*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         189 => (x => std_logic_vector(to_signed(189*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         190 => (x => std_logic_vector(to_signed(190*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         191 => (x => std_logic_vector(to_signed(191*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         192 => (x => std_logic_vector(to_signed(192*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         193 => (x => std_logic_vector(to_signed(193*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         194 => (x => std_logic_vector(to_signed(194*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         195 => (x => std_logic_vector(to_signed(195*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         196 => (x => std_logic_vector(to_signed(196*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         197 => (x => std_logic_vector(to_signed(197*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         198 => (x => std_logic_vector(to_signed(198*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         199 => (x => std_logic_vector(to_signed(199*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         200 => (x => std_logic_vector(to_signed(200*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         201 => (x => std_logic_vector(to_signed(201*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         202 => (x => std_logic_vector(to_signed(202*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         203 => (x => std_logic_vector(to_signed(203*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         204 => (x => std_logic_vector(to_signed(204*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         205 => (x => std_logic_vector(to_signed(205*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         206 => (x => std_logic_vector(to_signed(206*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         207 => (x => std_logic_vector(to_signed(207*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         208 => (x => std_logic_vector(to_signed(208*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         209 => (x => std_logic_vector(to_signed(209*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         210 => (x => std_logic_vector(to_signed(210*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         211 => (x => std_logic_vector(to_signed(211*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         212 => (x => std_logic_vector(to_signed(212*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         213 => (x => std_logic_vector(to_signed(213*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         214 => (x => std_logic_vector(to_signed(214*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         215 => (x => std_logic_vector(to_signed(215*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         216 => (x => std_logic_vector(to_signed(216*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         217 => (x => std_logic_vector(to_signed(217*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         218 => (x => std_logic_vector(to_signed(218*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         219 => (x => std_logic_vector(to_signed(219*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         220 => (x => std_logic_vector(to_signed(220*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         221 => (x => std_logic_vector(to_signed(221*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         222 => (x => std_logic_vector(to_signed(222*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         223 => (x => std_logic_vector(to_signed(223*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         224 => (x => std_logic_vector(to_signed(224*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         225 => (x => std_logic_vector(to_signed(225*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         226 => (x => std_logic_vector(to_signed(226*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         227 => (x => std_logic_vector(to_signed(227*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         228 => (x => std_logic_vector(to_signed(228*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         229 => (x => std_logic_vector(to_signed(229*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         230 => (x => std_logic_vector(to_signed(230*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         231 => (x => std_logic_vector(to_signed(231*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         232 => (x => std_logic_vector(to_signed(232*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         233 => (x => std_logic_vector(to_signed(233*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         234 => (x => std_logic_vector(to_signed(234*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         235 => (x => std_logic_vector(to_signed(235*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         236 => (x => std_logic_vector(to_signed(236*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         237 => (x => std_logic_vector(to_signed(237*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         238 => (x => std_logic_vector(to_signed(238*(2**(N_bits-1-8)),N_bits)),y=>zero),
                                                         239 => (x => std_logic_vector(to_signed(239*(2**(N_bits-1-8)),N_bits)),y=>zero)
                                                         );--tabla con los puntos de la recta inicial, en 230 aparecia 220
    --signal fifo : t_array_punto(0 to N_points-N_steps-1);
    signal fifo_ant : t_array_punto(0 to N_points-1);
    signal to_turn : t_punto;
    --signal turned : t_punto;
    signal cordic_clk : std_logic;
    signal enable : std_logic:='1';
    signal grados : STD_LOGIC_VECTOR(N_bits-1 downto 0):=zero;
    signal b : std_logic_vector(2 downto 0);
    -- para UART
    signal rx_data_rdy_sipo: std_logic;
    signal rx_data_sipo: std_logic_vector(7 downto 0);
    signal p_in_leo: std_logic_vector(71 downto 0);
    signal rd_en_sipo: std_logic;
    signal ang_leo : std_logic_vector (23 downto 0);
    signal I_leo: std_logic;
    signal D_leo: std_logic;
    signal C_leo: std_logic;
    
begin
    
    VGA: vga_ctrl
        port map (
            sys_clk => sys_clk,
            rst => rst,
            --sw => "000",
            hsync => hsync,
            vsync => vsync,
            red => red,
            green => green,
            blue => blue,
            pixel_clock=>pix_clock,
            video_read_add=>add_video_mem,
            pix_value => pixel_value,
            frame_tick => fr_tick
            -- Necesito un IN que sea lo que saca la memoria de video
            -- Necesito un OUT que sea la dire de la video mem
        );
        
    meta_harden_rst_sw0: meta_harden -- capaz haya que usar esto para otro boton
        port map(
            clk_dst     => sys_clk,
            rst_dst     => rst,            -- No reset on the hardener for reset!
            signal_src     => sw(0),
            signal_dst     => b(0)
        );
    meta_harden_rst_sw1: meta_harden -- capaz haya que usar esto para otro boton
        port map(
            clk_dst     => sys_clk,
            rst_dst     => rst,            -- No reset on the hardener for reset!
            signal_src     => sw(1),
            signal_dst     => b(1)
        );
    meta_harden_rst_sw2: meta_harden -- capaz haya que usar esto para otro boton
        port map(
            clk_dst     => sys_clk,
            rst_dst     => rst,            -- No reset on the hardener for reset!
            signal_src     => sw(2),
            signal_dst     => b(2)
        );
    meta_harden_rst_i0: meta_harden -- capaz haya que usar esto para otro boton
        port map(
            clk_dst     => sys_clk,
            rst_dst     => '0',            -- No reset on the hardener for reset!
            signal_src     => rst,
            signal_dst     => rst_clk_rx
        );
        
    UART: uart_rx 
        port map(
            clk_rx         => sys_clk,
            rst_clk_rx     => rst_clk_rx,
    
            rxd_i          => rxd_pin,
            rxd_clk_rx     => open,
    
            rx_data_rdy    => rx_data_rdy_sipo,
            rx_data        => rx_data_sipo,
            frm_err        => open
        );
        
        
    SIPOO: sipo
        port map(
            clk         => sys_clk,
            rst         => rst_clk_rx,
            
            s_in        => rx_data_sipo,
            wr_en       => rx_data_rdy_sipo,
            
            p_out       => p_in_leo,
            rd_en       => rd_en_sipo
        );
        
        
    COMPCOUNT: compandcount
        port map(
            clk         => sys_clk,
            rst         => rst_clk_rx,

            in_nchars   => rx_data_rdy_sipo,
	        in_char     => rx_data_sipo,

            coun_out    => rd_en_sipo            
        );
        
        
    LEOSIPOO: leosipo
        port map(
            clk         => sys_clk,
            rst         => rst_clk_rx,
        
            p_in        => p_in_leo,
            
            I           => I_leo,
            D           => D_leo,
            ang         => ang_leo,
            C           => C_leo
        );    
    

--        UART: uart_rx
--            port map(
--            rxd_pin     => rxd_pin
            
--           );

    memoria_video: video_mem_wrapper
        port map (
            addra_0 => add_video_mem_load,
            addrb_0 => add_video_mem,
            clka_0 => sys_clk,
            clkb_0 => pix_clock,
            dina_0 => pixel_in,
            doutb_0 => pixel_value,
            ena_0 => '1', --Horrible esto 6.6
            enb_0 => '1',
            wea_0 => "1"
        );	
--    chars: fontrom --evaluar si es necesaria
--        port map(
--            char_address => char_add,
--            font_row => font_row,
--            font_col => font_column,
--            rom_out => rom_out
--        );
    
        
-- Sección del código dedicada a girar puntos
-- esto tiene que ir a 2 clock de velocidad para poder escribir y borrar los puntos
    process (sys_clk)
    variable conteo : unsigned(2 downto 0);
    begin
        if rising_edge(sys_clk) then
            conteo:=conteo+1;
        end if;
        if conteo<4 then
            cordic_clk<='0';
        else
            cordic_clk<='1';
        end if;
    end process;
    
    CORDIC: CORDIC_top
        generic map(
            N_bits => N_bits,
            N_steps => N_steps
        )
        port map(
            degrees=>grados,
            enable=>enable,
            clk=>CORDIC_clk,
            x_out=>fifo_ant(0).x,
            y_out=>fifo_ant(0).y,
            x_in=>to_turn.x,
            y_in=>to_turn.y
        );
        
--chain: for i in 0 to N_points-N_steps-2 generate
--    chain_part: delay
--        port map(clk=>CORDIC_clk,
--                 ena=>enable,
--                 i_in=>fifo(i),
--                 o_out=>fifo(i+1));
--end generate;

chain2: for i in 0 to N_points-2 generate
	chain2_link: delay
		port map(clk=>CORDIC_clk,
		         ena=>enable,
		         i_in=>fifo_ant(i),
		         o_out=>fifo_ant(i+1));
	end generate;
-- proceso de control de girado	
init: process(sys_clk,fr_tick,b,rst_clk_rx,cordic_clk)
	--variable init, girar : bit := '0';
	variable i :natural :=0;
	--variable j :natural :=0;
	begin
	if rst_clk_rx='1' then
	   --init:='0';
	   --girar:='1';
	   --i:=0;
       enable<='1';
       grados<=zero;
	else
        if rising_edge(fr_tick) then -- cambio velocidad de giro '+'
            if (b(0)='1' or D_leo='1') then
            --if (b(0)='1') or (signed(grados)<signed(gr_max)) then
                grados<=std_logic_vector(signed(grados)+10);
            --end if;
            led(0)<='1';
            else
                led(0)<='0';
            end if;
        end if;
        if rising_edge(fr_tick) then --cambio velocidad de giro '-'
            if (b(2)='1' or I_leo='1') then
            --if (b(2)='1') or (signed(grados)>signed(gr_min)) then
                grados<=std_logic_vector(signed(grados)-10);
            --end if;
                led(2)<='1';
            else
                led(2)<='0';
            end if;
        end if;
        
        if rising_edge(cordic_clk) then -- tiene que estar
            i:=i+1;
        end if;
--        if rising_edge(fr_tick) then 
--            if sw(1)='1' then
--                girar:='1';
--                led(1)<='1';
--            else
--                led(1)<='0';
--            end if;
--        end if;
--        if girar='1' and rising_edge(cordic_clk) then
--            --j:=0;
--            girar:='0';
--            enable<='1';
--        end if;
        if i=N_Points then
            --enable<='0';
            i:=0;
            --init:='1';
        end if;
        led(1)<=b(1);
--        if j<N_points+1 and rising_edge(cordic_clk) then
--            j:=j+1;
--        end if;
--        if ((j<N_points) or (i<N_points)) then
--            enable<='1';
--        else
--            enable <='0';
--            init:='1';
--            led(0)<='1';
--        end if;
            to_turn<=puntos(i);
            --fifo_ant(0)<=fifo(N_points-N_steps-1);
        --if rising_edge(sys_clk) then
            --if init='1' then
                --fifo_ant(0)<=fifo(N_points-N_steps-1);
                --to_turn <= fifo(N_points-N_steps-1);
            --else --inicializacion, 
                --to_turn<=puntos(i);
                --fifo_ant(0)<=puntos(i);
                --led(0)<='0';
                --i:=i+1;
            --end if;
	   --end if;
    end if;
    end process;

-- Process para escribir la memoria de video
process (rst,sys_clk,fr_tick)
    variable conteo : integer := 0;
    variable wipe : bit := '0';
    variable dir : integer := 0;
    begin
    if (rst = '1' or rising_edge(fr_tick)) then -- si reset o termina un frame
        conteo := 0;
        wipe:='1';
    else
        if (rising_edge (sys_clk)) then
            conteo := conteo+1;
            if wipe='0' then --ploteo puntos
                --dir := 320 + to_integer(signed(fifo_ant(conteo).x(N_bits-1 downto N_bits-9))) + 800 * (to_integer(signed(fifo_ant(conteo).y(N_bits-1 downto N_bits-9)))+240);
                dir := 320 + to_integer(signed(fifo_ant(conteo).x(N_bits-1 downto N_bits-9))) + 800 * (to_integer(signed(fifo_ant(conteo).y(N_bits-1 downto N_bits-9)))+240);
                pixel_value_reg(0) <= '1';
                if conteo=N_points then
                    conteo:=0;
                end if;
            else --limpio pantalla
                pixel_value_reg(0)<='0';
                dir:=conteo;
                if (conteo >= 420000) then  --38400=800*480
                    wipe:='0';
                    conteo:=0;
                end if;
            end if;    
        end if;
    end if;
    add_video_mem_load <= std_logic_vector(to_unsigned(dir,add_video_mem_load'length));
    pixel_in <= pixel_value_reg;
end process;

end gir_arq;
