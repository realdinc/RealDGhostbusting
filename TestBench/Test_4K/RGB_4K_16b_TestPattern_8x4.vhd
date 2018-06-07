--***********************************************************************
-- RGB_16b_TestPattern_8x4.vhd
-- 
-- Generates test patterns for system simulation.
-- Supports 24 Fps either 1920 x 1080p or 2048 x 1080p.
-- Generates 4 horizontal stripes in one eye and 8
-- vertical stripes in the other.
--
-- Outputs 16 bit linear RGB values
-- 
--
--  The zone mapping is :
--                                      cntr[2:0]
--                000    001    010   011    100     101   110    111
--           00  zone0  zone1  zone2  zone3  zone4  zone5  zone6  zone7
--cntr[4:3]  01  zone8  zone9  zone10 zone11 zone12 zone13 zone14 zone15
--           10  zone16 zone17 zone18 zone19 zone20 zone21 zone22 zone23
--           11  zone24 zone25 zone26 zone27 zone28 zone29 zone30 zone31
--           
--     09-22-2008   RWL
--
--**********************************************************************
--
--
library IEEE; 
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
--
entity RGB_16b_TestPattern_8x4 is
  port (
	clock         : in std_logic ;
	reset         : in std_logic ;
	--
	video_select  : in std_logic_vector (1 downto 0)        ; -- 1920, 2048, or 4096
	TPG_enable    : in std_logic        ; -- run test pattern generator
	--
	horz_out      : out std_logic ;
	vert_out      : out std_logic ;
	field_out     : out std_logic ;
	act_video_out : out std_logic ;
	crnt_zone     : out integer range 0 to 31 ;
	--
	R_left_out     : out std_logic_vector (15 downto 0) ;
	G_left_out     : out std_logic_vector (15 downto 0) ;
	B_left_out     : out std_logic_vector (15 downto 0) ;
	R_right_out    : out std_logic_vector (15 downto 0) ;
	G_right_out    : out std_logic_vector (15 downto 0) ;
	B_right_out    : out std_logic_vector (15 downto 0)
	) ;
end RGB_16b_TestPattern_8x4 ;
--
--
architecture behave of RGB_16b_TestPattern_8x4 is
--
--
  type state_def is (FROM_RST, ODD_PIXEL, EVEN_PIXEL, FIRST_EAV, SECOND_EAV,
					 THIRD_EAV, FOURTH_EAV, LN0, LN1, ANCILLARY,
					 FIRST_SAV, SECOND_SAV, THIRD_SAV, FOURTH_SAV) ;
  signal crnt_state : state_def ;
  signal next_state : state_def ;
  signal sync_rst   : std_logic ;
  attribute STATE_VECTOR : string ;
  attribute STATE_VECTOR of behave:architecture is "crnt_state" ;
--
-- ************ Video Format Constants ***************
  -- MUST BE AN EVEN NUMBER ******* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  constant Boarder_Width           : integer := 12    ; -- borders are 12 pixels
  --
-- 1920 X 1080/24/1:1
  constant P1920_24_Total_Pixels   : integer := 2750 ;
  constant P1920_24_Active_Pixels  : integer := 1920 ;
  constant P1920_24_Zone_Width     : integer := (P1920_24_Active_Pixels / 8);
  constant P1920_24_Total_Lines    : integer := 1125 ;
  constant P1920_24_Active_Lines   : integer := 1080 ;
  constant P1920_24_Zone_Height    : integer := (P1920_24_Active_Lines / 4) ;
  constant P1920_24_EAV_start      : integer := 1920 ;
  constant P1920_24_EAV_end        : integer := 1924 ;
  constant P1920_24_SAV_start      : integer := 2746 ;
  constant P1920_24_SAV_end        : integer := 0    ;
  constant P1920_24_VB_start       : integer := 1121 ; -- end of this line
  constant P1920_24_VB_end         : integer := 41   ; -- end of this line
--
-- 2048 X 1080/24/1:1
  constant P2048_24_Total_Pixels   : integer := 2750 ;
  constant P2048_24_Active_Pixels  : integer := 2048 ;
  constant P2048_24_Zone_Width     : integer := (P2048_24_Active_Pixels / 8);
  constant P2048_24_Total_Lines    : integer := 1125 ;
  constant P2048_24_Active_Lines   : integer := 1080 ;
  constant P2048_24_Zone_Height    : integer := (P2048_24_Active_Lines / 4) ;
  constant P2048_24_EAV_start      : integer := 2048 ; -- ????
  constant P2048_24_EAV_end        : integer := 2052 ; -- ????
  constant P2048_24_SAV_start      : integer := 2746 ;
  constant P12048_24_SAV_end       : integer := 0    ;
  constant P2048_24_VB_start       : integer := 1121 ;
  constant P2048_24_VB_end         : integer := 41   ;
-- 4096 X 2160/24/1:1
  constant P4096_24_Total_Pixels   : integer := 5500 ;
  constant P4096_24_Active_Pixels  : integer := 4096 ;
  constant P4096_24_Zone_Width     : integer := (P4096_24_Active_Pixels / 8);
  constant P4096_24_Total_Lines    : integer := 2250 ;
  constant P4096_24_Active_Lines   : integer := 2160 ;
  constant P4096_24_Zone_Height    : integer := (P4096_24_Active_Lines / 4) ;
  constant P4096_24_EAV_start      : integer := 4096 ;
  constant P4096_24_EAV_end        : integer := 4104 ;
  constant P4096_24_SAV_start      : integer := 5492 ;
  constant P4096_24_SAV_end        : integer := 0    ;
  constant P4096_24_VB_start       : integer := 2240 ;
  constant P4096_24_VB_end         : integer := 80   ;--
  
-- ************ END Video Format Constants ***********
-- ************ RGB Constants *********************
  constant R_ZERO    : integer := 0 ;
  constant G_ZERO    : integer := 0 ;
  constant B_ZERO    : integer := 0 ;
  --
  constant R_BLACK    : integer := 256 ;
  constant G_BLACK    : integer := 256 ;
  constant B_BLACK    : integer := 256 ;
  --
  constant R_GRAY_12  : integer := 322 ; -- 12.5% gray
  constant G_GRAY_12  : integer := 816 ;
  constant B_GRAY_12  : integer := 639 ;
  --
  constant R_GRAY_25  : integer := 16383 ; -- 25% gray
  constant G_GRAY_25  : integer := 897 ;
  constant B_GRAY_25  : integer := 2213 ;
  --
  constant R_GRAY_37  : integer := 24573 ; -- 37.5% gray
  constant G_GRAY_37  : integer := 4573 ;
  constant B_GRAY_37  : integer := 573 ;
  --
  constant R_GRAY_50  : integer := 32764 ; -- 50% gray
  constant G_GRAY_50  : integer := 14759 ;
  constant B_GRAY_50  : integer := 8867 ;
  --
  constant R_GRAY_62  : integer := 40956 ; -- 62.5% gray
  constant G_GRAY_62  : integer := 19041 ;
  constant B_GRAY_62  : integer := 876 ;
  --
  constant R_GRAY_75  : integer := 49147 ; -- 75% gray
  constant G_GRAY_75  : integer := 288 ;
  constant B_GRAY_75  : integer := 9147 ;
  --
  constant R_GRAY_87  : integer := 57339 ; -- 87.5% gray
  constant G_GRAY_87  : integer :=   339 ;
  constant B_GRAY_87  : integer := 37339 ;
  --
  constant R_WHITE    : integer := 65279 ; -- Saturated White
  constant G_WHITE    : integer := 65279 ;
  constant B_WHITE    : integer := 65279 ;
  --
  constant R_SATURATE : integer := 65535 ; -- Saturated 16 bit output
  constant G_SATURATE : integer := 65535 ;
  constant B_SATURATE : integer := 65535 ;
  --
--
  signal start_of_VB : std_logic_vector (15 downto 0) ;
  signal end_of_VB   : std_logic_vector (15 downto 0) ;
  --
  signal PixelCount : std_logic_vector(15 downto 0);
  signal LineCount  : std_logic_vector(15 downto 0);
  --
  signal pixels_per_line : std_logic_vector (15 downto 0) ;
  signal active_pixels   : std_logic_vector (15 downto 0) ;
  signal lines_per_frame : std_logic_vector (15 downto 0) ;
  signal start_SAV       : std_logic_vector (15 downto 0) ;
  signal start_EAV       : std_logic_vector (15 downto 0) ;
  signal zone_width      : std_logic_vector (15 downto 0)  ;
  signal zone_width_less_1 : std_logic_vector (15 downto 0) ;
  signal zone_pixel_cntr : std_logic_vector (15 downto 0)  ;
  signal zone_height     : std_logic_vector (15 downto 0)  ;
  signal zone_line_cntr  : std_logic_vector (15 downto 0)  ;
  signal zone_cntr       : std_logic_vector (4 downto 0)  ;
  alias  zone_column     : std_logic_vector (2 downto 0) is zone_cntr(2 downto 0)  ;
  alias  zone_row        : std_logic_vector (1 downto 0) is zone_cntr(4 downto 3)  ;
  --
  signal horz_drv  : std_logic ;
  signal horz_flag : std_logic ; -- used to generate protection bits
  signal vert_drv  : std_logic ;
  signal field     : std_logic ;
  --
  signal vert_border_start : std_logic_vector (15 downto 0)  ;
  signal column_border     : std_logic ; -- in border between columns
  signal horz_border_start : std_logic_vector (15 downto 0)  ;
  signal row_border        : std_logic ; -- in border between rows
  --
  signal R_left   : std_logic_vector (15 downto 0) ;
  signal G_left   : std_logic_vector (15 downto 0) ;
  signal B_left   : std_logic_vector (15 downto 0) ;
  signal R_right  : std_logic_vector (15 downto 0) ;
  signal G_right  : std_logic_vector (15 downto 0) ;
  signal B_right  : std_logic_vector (15 downto 0) ;
  --
  signal prot_sel  : std_logic_vector (2 downto 0) ;
  signal prot_bits : std_logic_vector (3 downto 0) ;
--
begin
--
--
  crnt_zone <= to_integer(unsigned(zone_cntr)) ;
--
-- ******************** setup selected format *********
  --
  parse_format: process (clock)
  begin
	if (clock'event and clock = '1') then
	  if (reset = '1') then
		pixels_per_line   <= (others => '0') ;
		active_pixels     <= (others => '0') ;
		lines_per_frame   <= (others => '0') ;
		zone_width        <= (others => '0') ;
		zone_width_less_1 <= (others => '0') ;
		zone_height       <= (others => '0') ;
		start_of_VB       <= (others => '0') ;
		end_of_VB         <= (others => '0') ;
	  else
		if (video_select = "00") then
		  pixels_per_line <= std_logic_vector(to_unsigned(P1920_24_Total_Pixels,16)) ;
		  active_pixels   <= std_logic_vector(to_unsigned(P1920_24_Active_Pixels,16)) ;
		  lines_per_frame <= std_logic_vector(to_unsigned(P1920_24_Total_Lines,16))  ;
		  start_SAV       <= std_logic_vector(to_unsigned(P1920_24_SAV_start-1,16))  ;
		  start_EAV       <= std_logic_vector(to_unsigned(P1920_24_EAV_start-1,16))  ;
		  zone_width      <= std_logic_vector(to_unsigned(P1920_24_Zone_Width,16))   ;
		  zone_width_less_1 <= std_logic_vector(to_unsigned(P1920_24_Zone_Width-1,16));
		  zone_height     <= std_logic_vector(to_unsigned(P1920_24_Zone_Height,16))  ;
		  start_of_VB     <= std_logic_vector(to_unsigned(P1920_24_VB_start,16)) ;
		  end_of_VB       <= std_logic_vector(to_unsigned(P1920_24_VB_end,16))   ;
		  vert_border_start <= std_logic_vector(to_unsigned(P1920_24_Zone_Width-Boarder_Width-2,16)) ;
		  horz_border_start <= std_logic_vector(to_unsigned(P1920_24_Zone_Height-Boarder_Width,16)) ;
		elsif (video_select = "01") then
		  pixels_per_line <= std_logic_vector(to_unsigned(P2048_24_Total_Pixels,16)) ;
		  active_pixels   <= std_logic_vector(to_unsigned(P2048_24_Active_Pixels,16)) ;
		  lines_per_frame <= std_logic_vector(to_unsigned(P2048_24_Total_Lines,16))  ;
		  start_SAV       <= std_logic_vector(to_unsigned(P2048_24_SAV_start-1,16))  ;
		  start_EAV       <= std_logic_vector(to_unsigned(P2048_24_EAV_start-1,16))  ;
		  zone_width      <= std_logic_vector(to_unsigned(P2048_24_Zone_Width,16))   ;
		  zone_width_less_1 <= std_logic_vector(to_unsigned(P2048_24_Zone_Width-1,16));
		  zone_height     <= std_logic_vector(to_unsigned(P2048_24_Zone_Height,16))  ;
		  start_of_VB     <= std_logic_vector(to_unsigned(P2048_24_VB_start,16)) ;
		  end_of_VB       <= std_logic_vector(to_unsigned(P2048_24_VB_end,16))   ;
		  vert_border_start <= std_logic_vector(to_unsigned(P2048_24_Zone_Width-Boarder_Width-1,16)) ;
		  horz_border_start <= std_logic_vector(to_unsigned(P2048_24_Zone_Height-Boarder_Width,16)) ;
		else 
		  pixels_per_line <= std_logic_vector(to_unsigned(P4096_24_Total_Pixels,16)) ;
		  active_pixels   <= std_logic_vector(to_unsigned(P4096_24_Active_Pixels,16)) ;
		  lines_per_frame <= std_logic_vector(to_unsigned(P4096_24_Total_Lines,16))  ;
		  start_SAV       <= std_logic_vector(to_unsigned(P4096_24_SAV_start-1,16))  ;
		  start_EAV       <= std_logic_vector(to_unsigned(P4096_24_EAV_start-1,16))  ;
		  zone_width      <= std_logic_vector(to_unsigned(P4096_24_Zone_Width,16))   ;
		  zone_width_less_1 <= std_logic_vector(to_unsigned(P4096_24_Zone_Width-1,16));
		  zone_height     <= std_logic_vector(to_unsigned(P4096_24_Zone_Height,16)) ;
		  start_of_VB     <= std_logic_vector(to_unsigned(P4096_24_VB_start,16)) ;
		  end_of_VB       <= std_logic_vector(to_unsigned(P4096_24_VB_end,16))   ;
		  vert_border_start <= std_logic_vector(to_unsigned(P4096_24_Zone_Width-Boarder_Width-1,16)) ;
		  horz_border_start <= std_logic_vector(to_unsigned(P4096_24_Zone_Height-Boarder_Width,16)) ;
		end if ;
	  end if;
	end if ;
  end process parse_format ;
--
-- ******************** Pixel and Line Counters *******
--
  --
  horz_zones: process (clock)
  begin
	if (clock'event and clock = '1') then
	  if (reset = '1') then
		zone_column     <= (others => '0') ;
		zone_pixel_cntr <= std_logic_vector(to_unsigned(1, 16)) ;
		column_border   <= '1' ; 
	  else
		if (zone_pixel_cntr = zone_width and (crnt_state=ODD_PIXEL or crnt_state=EVEN_PIXEL)) then
		  zone_pixel_cntr <= std_logic_vector(to_unsigned(1, 16)) ;
		elsif (crnt_state = FOURTH_SAV) then
		  zone_pixel_cntr <= std_logic_vector(to_unsigned(1, 16)) ;
		elsif (crnt_state=ODD_PIXEL or crnt_state=EVEN_PIXEL) then 
		  zone_pixel_cntr <= std_logic_vector(unsigned(zone_pixel_cntr) + 1) ;
		end if ;
		--
		if (zone_pixel_cntr = zone_width and (crnt_state=ODD_PIXEL or crnt_state=EVEN_PIXEL)) then
		  zone_column <= std_logic_vector(unsigned(zone_column) + 1) ;
		elsif (crnt_state = FIRST_EAV) then
		  zone_column <= (others => '0') ;
		end if ;
		--
		-- Goes active one pixel before boarder start and inactive
		-- one pixel before end of boarder.
		if (zone_pixel_cntr = vert_border_start) then
		  column_border   <= '1' ; -- "Boarder_Width" pixels before end of column
		elsif (zone_pixel_cntr = std_logic_vector(to_unsigned((Boarder_Width-2), 16))) then
		  column_border   <= '0' ; -- clear after "Boarder_Width" pixels
		end if ;
	  end if ;
	end if ;
  end process  horz_zones ;
  --
  vert_zones: process (clock)
  begin
	if (clock'event and clock = '1') then
	  if (reset = '1') then
		zone_row       <= (others => '0') ;
		zone_line_cntr <= std_logic_vector(to_unsigned(1, 16));
		row_border     <= '1' ;
	  else
		if (zone_line_cntr = zone_height and crnt_state = FIRST_EAV) then
		  zone_line_cntr <= std_logic_vector(to_unsigned(1, 16));
		elsif (crnt_state = FIRST_EAV  and vert_drv = '0') then 
		  zone_line_cntr <= std_logic_vector(unsigned(zone_line_cntr) + 1) ;
		end if ;
		--
		if (zone_line_cntr = zone_height and crnt_state = FIRST_EAV) then
		  zone_row  <= std_logic_vector(unsigned(zone_row) + 1) ;
		elsif (LineCount = lines_per_frame and crnt_state = FIRST_EAV) then
		  zone_row  <= (others => '0') ;
		end if ;
		--
		if (zone_line_cntr = std_logic_vector(to_unsigned(1, 16))) then
		  row_border     <= '1' ; -- set at start of new row
		elsif (zone_line_cntr = std_logic_vector(to_unsigned(Boarder_Width, 16))) then
		  row_border     <= '0' ; -- clear after "Boarder_Width" rows
		elsif (zone_line_cntr = horz_border_start) then
		  row_border     <= '1' ; -- set "Boarder_Width" rows from end of zone
		end if ;
	  end if ;
	end if ;
  end process  vert_zones ;
--
  count_pixels: process (clock)
  begin
	if (clock'event and clock = '1') then
	  if (reset = '1') then
		PixelCount <= std_logic_vector(to_unsigned(0, 16));
	  else
		if (crnt_state = FOURTH_SAV) then
		  PixelCount <= std_logic_vector(to_unsigned(0, 16));
		else
		  PixelCount <= std_logic_vector(unsigned(PixelCount) + 1) ;
		end if ;
	  end if ;
	end if ;
  end process count_pixels ;
--
  count_lines: process (clock)
  begin
	if (clock'event and clock = '1') then
	  if (reset = '1') then
		LineCount <= std_logic_vector(to_unsigned(1, 16)) ;
	  else
		if (LineCount = lines_per_frame and crnt_state = FIRST_EAV) then
		  LineCount <= std_logic_vector(to_unsigned(1, 16)) ;
		elsif (crnt_state = FIRST_EAV) then 
		  LineCount <= std_logic_vector(unsigned(LineCount) + 1) ;
		end if ;
	  end if ;
	end if ;
  end process count_lines ;
--
--
-- *************************** State machine ***********
--
  state_trans: process (reset, PixelCount)
  begin
	case (crnt_state) is
	  when FROM_RST  =>
		if (reset = '0') then
		  next_state <= ANCILLARY ;
		else
		  next_state <= FROM_RST ;
		end if ;
	  when ODD_PIXEL   =>
		if (PixelCount = start_EAV) then
		  next_state <= FIRST_EAV ;
		else
		  next_state <= EVEN_PIXEL  ;
		end if ;
	  when EVEN_PIXEL  =>
		next_state <= ODD_PIXEL ;
	  when FIRST_EAV  =>
		next_state <= SECOND_EAV ;
	  when SECOND_EAV  =>
		next_state <= THIRD_EAV ;
	  when THIRD_EAV  =>
		next_state <= FOURTH_EAV ;
	  when FOURTH_EAV  =>
		next_state <= LN0 ;
	  when LN0  =>
		next_state <= LN1 ;
	  when LN1  =>
		next_state <= ANCILLARY ;
	  when ANCILLARY  =>
		if (PixelCount = start_SAV) then
		  next_state <= FIRST_SAV ;
		else
		  next_state <= ANCILLARY ;
		end if ;
	  when FIRST_SAV  =>
		next_state <= SECOND_SAV ;
	  when SECOND_SAV  =>
		next_state <= THIRD_SAV ;
	  when THIRD_SAV  =>
		next_state <= FOURTH_SAV ;
	  when FOURTH_SAV  =>
		next_state <= EVEN_PIXEL ;
	  when others =>
		next_state <= FROM_RST ;
	end case ;
  end process state_trans ;
--
  act_video_out <= (not vert_drv) and (not horz_drv) ;
  vert_out  <= vert_drv ;
  horz_out  <= horz_drv ;
  field_out <= field ;
--
  state_based: process (clock)
  begin
	if (clock'event and clock = '1') then
	  if (reset = '1') then
		horz_drv       <= '1' ;
		horz_flag      <= '1' ;
		vert_drv       <= '1' ;
		field          <= '0' ;
		R_left_out     <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
		G_left_out     <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
		B_left_out     <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
		--
		R_right_out    <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
		G_right_out    <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
		B_right_out    <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
	  else
		if (PixelCount = std_logic_vector(unsigned(active_pixels) - 1)) then
		  horz_drv <= '1' ;
		elsif (crnt_state = FOURTH_SAV) then
		  horz_drv <= '0' ;
		end if ;
		--
		if (PixelCount = std_logic_vector(unsigned(active_pixels) - 1)) then
		  horz_flag <= '1' ;
		elsif (crnt_state = ANCILLARY and PixelCount = start_SAV) then
		  horz_flag <= '0' ;
		end if ;
		--
		if (crnt_state = FIRST_EAV and LineCount = start_of_VB) then
		  vert_drv <= '1' ;
		elsif (crnt_state = FIRST_EAV and LineCount = end_of_VB) then
		  vert_drv <= '0' ;
		end if ;
		-- YUV outputs
		case (crnt_state) is
		  when FROM_RST  =>
			R_left_out     <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			G_left_out     <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			B_left_out     <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
			--
			R_right_out    <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			G_right_out    <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			B_right_out    <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
		  when ODD_PIXEL   =>
			if (PixelCount = start_EAV) then
			  R_left_out     <= std_logic_vector(to_unsigned(R_SATURATE,16)) ;
			  G_left_out     <= std_logic_vector(to_unsigned(G_SATURATE,16)) ;
			  B_left_out     <= std_logic_vector(to_unsigned(B_SATURATE,16)) ;
			  --
			  R_right_out    <= std_logic_vector(to_unsigned(R_SATURATE,16)) ;
			  G_right_out    <= std_logic_vector(to_unsigned(G_SATURATE,16)) ;
			  B_right_out    <= std_logic_vector(to_unsigned(B_SATURATE,16)) ;
			else
			  if (vert_drv = '0') then
				R_left_out  <= R_left ;
				G_left_out  <= G_left ;
				B_left_out  <= B_left ;
				R_right_out <= R_right ;
				G_right_out <= G_right ;
				B_right_out <= B_right ;
			  else
				R_left_out     <= std_logic_vector(to_unsigned(R_SATURATE,16)) ;
				G_left_out     <= std_logic_vector(to_unsigned(G_SATURATE,16)) ;
				B_left_out     <= std_logic_vector(to_unsigned(B_SATURATE,16)) ;
				--
				R_right_out    <= std_logic_vector(to_unsigned(R_SATURATE,16)) ;
				G_right_out    <= std_logic_vector(to_unsigned(G_SATURATE,16)) ;
				B_right_out    <= std_logic_vector(to_unsigned(B_SATURATE,16)) ;
			  end if ;
			end if ;
		  when EVEN_PIXEL  =>
			if (vert_drv = '0') then
			  R_left_out  <= R_left ;
			  G_left_out  <= G_left ;
			  B_left_out  <= B_left ;
			  R_right_out <= R_right ;
			  G_right_out <= G_right ;
			  B_right_out <= B_right ;
			else
			  R_left_out     <= std_logic_vector(to_unsigned(R_SATURATE,16)) ;
			  G_left_out     <= std_logic_vector(to_unsigned(G_SATURATE,16)) ;
			  B_left_out     <= std_logic_vector(to_unsigned(B_SATURATE,16)) ;
			  --
			  R_right_out    <= std_logic_vector(to_unsigned(R_SATURATE,16)) ;
			  G_right_out    <= std_logic_vector(to_unsigned(G_SATURATE,16)) ;
			  B_right_out    <= std_logic_vector(to_unsigned(B_SATURATE,16)) ;
			end if ;
		  when FIRST_EAV  =>
			R_left_out     <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			G_left_out     <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			B_left_out     <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
			--
			R_right_out    <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			G_right_out    <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			B_right_out    <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
		  when SECOND_EAV  =>
			R_left_out     <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			G_left_out     <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			B_left_out     <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
			--
			R_right_out    <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			G_right_out    <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			B_right_out    <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
		  when THIRD_EAV  =>
			R_left_out     <= '1' & field & vert_drv & horz_flag & prot_bits & "00000000" ;
			G_left_out     <= '1' & field & vert_drv & horz_flag & prot_bits & "00000000" ;
			B_left_out     <= '1' & field & vert_drv & horz_flag & prot_bits & "00000000" ;
			--
			R_right_out    <= '1' & field & vert_drv & horz_flag & prot_bits & "00000000" ;
			G_right_out    <= '1' & field & vert_drv & horz_flag & prot_bits & "00000000" ;
			B_right_out    <= '1' & field & vert_drv & horz_flag & prot_bits & "00000000" ;
		  when FOURTH_EAV  =>
			R_left_out     <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			G_left_out     <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			B_left_out     <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
			--
			R_right_out    <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			G_right_out    <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			B_right_out    <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
		  when LN0  =>
			R_left_out     <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			G_left_out     <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			B_left_out     <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
			--
			R_right_out    <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			G_right_out    <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			B_right_out    <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
		  when LN1  =>
			R_left_out     <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			G_left_out     <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			B_left_out     <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
			--
			R_right_out    <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			G_right_out    <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			B_right_out    <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
		  when ANCILLARY  =>
			if (PixelCount = start_SAV) then
			  R_left_out     <= std_logic_vector(to_unsigned(R_SATURATE,16)) ;
			  G_left_out     <= std_logic_vector(to_unsigned(G_SATURATE,16)) ;
			  B_left_out     <= std_logic_vector(to_unsigned(B_SATURATE,16)) ;
			  --
			  R_right_out    <= std_logic_vector(to_unsigned(R_SATURATE,16)) ;
			  G_right_out    <= std_logic_vector(to_unsigned(G_SATURATE,16)) ;
			  B_right_out    <= std_logic_vector(to_unsigned(B_SATURATE,16)) ;
			else
			  R_right_out    <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			  G_right_out    <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			  B_right_out    <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
			  --
			  R_left_out     <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			  G_left_out     <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			  B_left_out     <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
			end if ;
		  when FIRST_SAV  =>
			R_left_out     <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			G_left_out     <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			B_left_out     <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
			--
			R_right_out    <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			G_right_out    <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			B_right_out    <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
		  when SECOND_SAV  =>
			R_left_out     <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			G_left_out     <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			B_left_out     <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
			--
			R_right_out    <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			G_right_out    <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			B_right_out    <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
		  when THIRD_SAV  =>
			R_left_out     <= '1' & field & vert_drv & horz_flag & prot_bits & "00000000" ;
			G_left_out     <= '1' & field & vert_drv & horz_flag & prot_bits & "00000000" ;
			B_left_out     <= '1' & field & vert_drv & horz_flag & prot_bits & "00000000" ;
			--
			R_right_out    <= '1' & field & vert_drv & horz_flag & prot_bits & "00000000" ;
			G_right_out    <= '1' & field & vert_drv & horz_flag & prot_bits & "00000000" ;
			B_right_out    <= '1' & field & vert_drv & horz_flag & prot_bits & "00000000" ;
		  when FOURTH_SAV  =>
			if (vert_drv = '0') then
			  R_left_out  <= R_left ;
			  G_left_out  <= G_left ;
			  B_left_out  <= B_left ;
			  R_right_out <= R_right ;
			  G_right_out <= G_right ;
			  B_right_out <= B_right ;
			else
			  R_right_out    <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			  G_right_out    <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			  B_right_out    <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
			  --
			  R_left_out     <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			  G_left_out     <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			  B_left_out     <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
			end if ;
		  when others =>
			R_left_out     <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			G_left_out     <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			B_left_out     <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
			--
			R_right_out    <= std_logic_vector(to_unsigned(R_ZERO,16)) ;
			G_right_out    <= std_logic_vector(to_unsigned(G_ZERO,16)) ;
			B_right_out    <= std_logic_vector(to_unsigned(B_ZERO,16)) ;
		end case ;
	  end if ;
	end if ;
  end process state_based ;
--
  UPDATE_STATE: process (clock)
  begin
	if (clock'event and clock = '1') then
	  if (reset = '1') then
		crnt_state <= FROM_RST ;
	  else
		crnt_state <= next_state ;
	  end if ;
	end if ;
  end process UPDATE_STATE ;
--
--
  patterns: process (clock)
  begin
	if (clock'event and clock = '1') then
	  if (reset = '1') then
		R_left     <= std_logic_vector(to_unsigned(R_BLACK,16)) ;
		G_left     <= std_logic_vector(to_unsigned(G_BLACK,16)) ;
		B_left     <= std_logic_vector(to_unsigned(B_BLACK,16)) ;
		--
		R_right    <= std_logic_vector(to_unsigned(R_BLACK,16)) ;
		G_right    <= std_logic_vector(to_unsigned(G_BLACK,16)) ;
		B_right    <= std_logic_vector(to_unsigned(B_BLACK,16)) ;
	  else
		--
		-- 8 Vertical stripes
		if (zone_pixel_cntr = zone_width_less_1) then
		  case zone_column is
			when "000" => -- for zone 1
			  R_left <= std_logic_vector(to_unsigned(R_GRAY_25,16)) ;
			  G_left <= std_logic_vector(to_unsigned(G_GRAY_25,16)) ;
			  B_left <= std_logic_vector(to_unsigned(B_GRAY_25,16)) ;
			when "001" => -- for zone 2
			  R_left <= std_logic_vector(to_unsigned(R_GRAY_37,16)) ;
			  G_left <= std_logic_vector(to_unsigned(G_GRAY_37,16)) ;
			  B_left <= std_logic_vector(to_unsigned(B_GRAY_37,16)) ;
			when "010" => -- for zone 3
			  R_left <= std_logic_vector(to_unsigned(R_GRAY_50,16)) ;
			  G_left <= std_logic_vector(to_unsigned(G_GRAY_50,16)) ;
			  B_left <= std_logic_vector(to_unsigned(B_GRAY_50,16)) ;
			when "011" => -- for zone 4
			  R_left <= std_logic_vector(to_unsigned(R_GRAY_62,16)) ;
			  G_left <= std_logic_vector(to_unsigned(G_GRAY_62,16)) ;
			  B_left <= std_logic_vector(to_unsigned(B_GRAY_62,16)) ;
			when "100" => -- for zone 5
			  R_left <= std_logic_vector(to_unsigned(R_GRAY_75,16)) ;
			  G_left <= std_logic_vector(to_unsigned(G_GRAY_75,16)) ;
			  B_left <= std_logic_vector(to_unsigned(B_GRAY_75,16)) ;
			when "101" => -- for zone 6
			  R_left <= std_logic_vector(to_unsigned(R_GRAY_87,16)) ;
			  G_left <= std_logic_vector(to_unsigned(G_GRAY_87,16)) ;
			  B_left <= std_logic_vector(to_unsigned(B_GRAY_87,16)) ;
			when "110" => -- for zone 7
			  R_left <= std_logic_vector(to_unsigned(R_WHITE,16)) ;
			  G_left <= std_logic_vector(to_unsigned(G_WHITE,16)) ;
			  B_left <= std_logic_vector(to_unsigned(B_WHITE,16)) ;
			when "111" => -- for zone 0
			  R_left <= std_logic_vector(to_unsigned(R_GRAY_12,16)) ;
			  G_left <= std_logic_vector(to_unsigned(G_GRAY_12,16)) ;
			  B_left <= std_logic_vector(to_unsigned(B_GRAY_12,16)) ;
			when others =>
			  R_left     <= std_logic_vector(to_unsigned(R_BLACK,16)) ;
			  G_left     <= std_logic_vector(to_unsigned(G_BLACK,16)) ;
			  B_left     <= std_logic_vector(to_unsigned(B_BLACK,16)) ;
		  end case ;
		end if ;
		--
		-- 4 Horizontal stripes
		if (crnt_state = FIRST_SAV) then
		  case zone_row is
			when "00" => -- for row 0
			  R_right <= std_logic_vector(to_unsigned(R_WHITE,16)) ;
			  G_right <= std_logic_vector(to_unsigned(G_WHITE,16)) ;
			  B_right <= std_logic_vector(to_unsigned(B_WHITE,16)) ;
			when "01" => -- for row 1
			  R_right <= std_logic_vector(to_unsigned(R_GRAY_75,16)) ;
			  G_right <= std_logic_vector(to_unsigned(G_GRAY_75,16)) ;
			  B_right <= std_logic_vector(to_unsigned(B_GRAY_75,16)) ;
			when "10" => -- for row 2
			  R_right <= std_logic_vector(to_unsigned(R_GRAY_50,16)) ;
			  G_right <= std_logic_vector(to_unsigned(G_GRAY_50,16)) ;
			  B_right <= std_logic_vector(to_unsigned(B_GRAY_50,16)) ;
			when "11" => -- for row 3
			  R_right <= std_logic_vector(to_unsigned(R_GRAY_25,16)) ;
			  G_right <= std_logic_vector(to_unsigned(G_GRAY_25,16)) ;
			  B_right <= std_logic_vector(to_unsigned(B_GRAY_25,16)) ;
			when others =>
			  R_right     <= std_logic_vector(to_unsigned(R_BLACK,16)) ;
			  G_right     <= std_logic_vector(to_unsigned(G_BLACK,16)) ;
			  B_right     <= std_logic_vector(to_unsigned(B_BLACK,16)) ;
		  end case ;
		end if ;
	  end if ;
	end if ;
  end process patterns ;
--
-- Protection bits for fouth EAV & SAV
  prot_sel  <= field & vert_drv & horz_flag ;
  --
  decode_prot: process (prot_sel)
  begin
	case prot_sel is
	  when "000" =>
		prot_bits <= "0000" ;
	  when "001" =>
		prot_bits <= "1101" ;
	  when "010" =>
		prot_bits <= "1011" ;
	  when "011" =>
		prot_bits <= "0110" ;
	  when "100" =>
		prot_bits <= "0111" ;
	  when "101" =>
		prot_bits <= "1010" ;
	  when "110" =>
		prot_bits <= "1100" ;
	  when "111" =>
		prot_bits <= "0001" ;
	  when others =>
		prot_bits <= "0000" ;
	end case ;
  end process decode_prot ;
--
--
end behave ;
