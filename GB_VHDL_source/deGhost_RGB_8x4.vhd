--*************************************************************
--  deGhost_RGB_8x4 :
--     RGB Zoned Ghost Buster. 36 zones (8 across X 4 down).
--     Performs the calculations :
--        RED_left = RED_left - (RED_right_ghost_factor * RED_right)
--        GRN_left = GRN_left - (GRN_right_ghost_factor * GRN_right)
--        BLU_left = BLU_left - (BLU_right_ghost_factor * BLU_right)
--        RED_right = RED_right - (RED_left_ghost_factor * RED_left)
--        GRN_right = GRN_right - (GRN_left_ghost_factor * GRN_left)
--        BLU_right = BLU_right - (BLU_left_ghost_factor * BLU_left)
--
--  The LUT memory address to screen zone mapping is :
--                                      addr[3:1]
--                000    001    010   011    100     101   110    111
--           00  zone0  zone1  zone2  zone3  zone4  zone5  zone6  zone7
-- addr[5:4] 01  zone8  zone9  zone10 zone11 zone12 zone13 zone14 zone15
--           10  zone16 zone17 zone18 zone19 zone20 zone21 zone22 zone23
--           11  zone24 zone25 zone26 zone27 zone28 zone29 zone30 zone31
--           
--     01-08-2008   RWL
--     09-17-2008  Use identical ghost factors for both eyes &
--                 change address (7 downto 1) for word address
--
--*************************************************************
--
--
library IEEE; 
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
--
entity deGhost_RGB_8x4 is
  port (
	clock         : in std_logic ;
	reset         : in std_logic ;
	--
	delay         : out integer   ;
	H_ready       : out std_logic ; -- Horz zone count ready
	V_ready       : out std_logic ; -- Vert zone count ready
	-- Bus interface for Ghost Factor memory writes
	data_in       : in std_logic_vector (15 downto 0) ;
	data_out      : out std_logic_vector (15 downto 0) ;
	address       : in std_logic_vector (7 downto 1)  ; -- word address
	wr_en         : in std_logic ; -- 1~ wide
	byPass        : in std_logic ;
	--
	act_image_in  : in std_logic ; -- '1' during active video
	horz_in       : in std_logic ;
	vert_in       : in std_logic ;
	field_in      : in std_logic ;
	--
	RED_left_in   : in std_logic_vector (15 downto 0) ;
	GRN_left_in   : in std_logic_vector (15 downto 0) ;
	BLU_left_in   : in std_logic_vector (15 downto 0) ;
	--
	RED_right_in  : in std_logic_vector (15 downto 0) ;
	GRN_right_in  : in std_logic_vector (15 downto 0) ;
	BLU_right_in  : in std_logic_vector (15 downto 0) ;
	--
	act_image_out : out std_logic ;
	horz_out      : out std_logic ;
	vert_out      : out std_logic ;
	field_out     : out std_logic ;
	--
	RED_left_out  : out std_logic_vector (15 downto 0) ;
	GRN_left_out  : out std_logic_vector (15 downto 0) ;
	BLU_left_out  : out std_logic_vector (15 downto 0) ;
	--
	RED_right_out : out std_logic_vector (15 downto 0) ;
	GRN_right_out : out std_logic_vector (15 downto 0) ;
	BLU_right_out : out std_logic_vector (15 downto 0)
	) ;
end deGhost_RGB_8x4 ;
--
--
--
architecture behave of deGhost_RGB_8x4 is
--
--
--
  component dpRAM_32x18
	port
	  (
		clock	  : in std_logic ;
		data	  : in std_logic_vector (17 downto 0);
		rdaddress : in std_logic_vector (4 downto 0);
		wraddress : in std_logic_vector (4 downto 0);
		wren	  : in std_logic  := '1';
		q		  : out std_logic_vector (17 downto 0)
		);
  end component ;
--
--
  constant pipe_delay : integer := 3 ;
  --
  signal act_image_SR : std_logic_vector (pipe_delay-1 downto 0) ;
  signal horz_SR      : std_logic_vector (pipe_delay-1 downto 0) ;
  signal vert_SR      : std_logic_vector (pipe_delay-1 downto 0) ;
  signal field_SR     : std_logic_vector (pipe_delay-1 downto 0) ;
  --
  --
  signal GF_data_to_RAM  : std_logic_vector (17 downto 0) ;
  signal WR_red_left_GF  : std_logic ;
  alias  which_RAM       : std_logic_vector (1 downto 0) is address (7 downto 6) ;
  constant sel_RED       : std_logic_vector (1 downto 0) := "00" ;
  constant sel_GRN       : std_logic_vector (1 downto 0) := "01" ;
  constant sel_BLU       : std_logic_vector (1 downto 0) := "10" ;
--
  signal wr_RED          : std_logic ; -- write strobe
  signal wr_GRN          : std_logic ; -- write strobe
  signal wr_BLU          : std_logic ; -- write strobe
  --
  signal RED_left_extnd    : signed (17 downto 0) ;
  signal GRN_left_extnd    : signed (17 downto 0) ;
  signal BLU_left_extnd    : signed (17 downto 0) ;
  --
  signal RED_right_extnd   : signed (17 downto 0) ;
  signal GRN_right_extnd   : signed (17 downto 0) ;
  signal BLU_right_extnd   : signed (17 downto 0) ;
  --
  signal RED_left_ext_reg  : signed (17 downto 0) ;
  signal GRN_left_ext_reg  : signed (17 downto 0) ;
  signal BLU_left_ext_reg  : signed (17 downto 0) ;
  --
  signal RED_right_ext_reg : signed (17 downto 0) ;
  signal GRN_right_ext_reg : signed (17 downto 0) ;
  signal BLU_right_ext_reg : signed (17 downto 0) ;
  --
  signal RED_ghost_factor : std_logic_vector (17 downto 0) ;
  signal GRN_ghost_factor : std_logic_vector (17 downto 0) ;
  signal BLU_ghost_factor : std_logic_vector (17 downto 0) ;
  --
  signal RED_left_prod  : signed (35 downto 0) ;
  signal GRN_left_prod  : signed (35 downto 0) ;
  signal BLU_left_prod  : signed (35 downto 0) ;
  --
  signal RED_right_prod : signed (35 downto 0) ;
  signal GRN_right_prod : signed (35 downto 0) ;
  signal BLU_right_prod : signed (35 downto 0) ;
  --
  signal RED_left_prod_reg  : signed (17 downto 0) ;
  signal GRN_left_prod_reg  : signed (17 downto 0) ;
  signal BLU_left_prod_reg  : signed (17 downto 0) ;
  --
  signal RED_right_prod_reg : signed (17 downto 0) ;
  signal GRN_right_prod_reg : signed (17 downto 0) ;
  signal BLU_right_prod_reg : signed (17 downto 0) ;
  --
  signal RED_left_deGhost  : signed (17 downto 0) ;
  signal GRN_left_deGhost  : signed (17 downto 0) ;
  signal BLU_left_deGhost  : signed (17 downto 0) ;
  --
  signal RED_right_deGhost : signed (17 downto 0) ;
  signal GRN_right_deGhost : signed (17 downto 0) ;
  signal BLU_right_deGhost : signed (17 downto 0) ;
  --
  signal edg_horz_SR    : std_logic_vector (3 downto 0) ;
  signal pixel_cntr     : unsigned (12 downto 0) ;
  signal horz_zone_trgt : unsigned (12 downto 0) ;
  signal horz_zone_cntr : unsigned (12 downto 0)  ;
  signal early_ZCcntr_rst : std_logic ;
  signal ZCcntr_rst       : std_logic ;
  signal zone_column    : std_logic_vector (2 downto 0) ;
  signal horz_rise      : std_logic ; -- rising edge
  signal edg_vert_SR    : std_logic_vector (3 downto 0) ;
  signal line_cntr      : unsigned (12 downto 0) ;
  signal vert_zone_trgt : unsigned (12 downto 0) ;
  signal vert_zone_cntr : unsigned (12 downto 0)  ;
  signal ZRcntr_rst     : std_logic ;
  signal zone_row       : std_logic_vector (1 downto 0) ;
  signal vert_rise      : std_logic ; -- rising edge
  --
  signal first_H_cnt   : std_logic ; -- first horz seen
  signal first_V_cnt   : std_logic ; -- first vert seen
  --
  signal GF_read_addr   : std_logic_vector (4 downto 0) ;
--
begin
--
  delay <= pipe_delay ;
--
  -- Sign extend the input pixels (always positive)
  RED_left_extnd  <= signed("00" & RED_left_in)  ;
  GRN_left_extnd  <= signed("00" & GRN_left_in)  ;
  BLU_left_extnd  <= signed("00" & BLU_left_in)  ;
  RED_right_extnd <= signed("00" & RED_right_in) ;
  GRN_right_extnd <= signed("00" & GRN_right_in) ;
  BLU_right_extnd <= signed("00" & BLU_right_in) ;
  --
  -- perform multiplications
  RED_left_prod  <= RED_left_extnd  * signed(RED_ghost_factor)  ;
  GRN_left_prod  <= GRN_left_extnd  * signed(GRN_ghost_factor)  ;
  BLU_left_prod  <= BLU_left_extnd  * signed(BLU_ghost_factor)  ;
  RED_right_prod <= RED_right_extnd * signed(RED_ghost_factor) ;
  GRN_right_prod <= GRN_right_extnd * signed(GRN_ghost_factor) ;
  BLU_right_prod <= BLU_right_extnd * signed(BLU_ghost_factor) ;
  --
  -- Register the product /2^17
  reg_product: process (clock)
  begin
	if (clock'event and clock = '1') then
	  if (reset = '1') then
		RED_left_prod_reg  <= (others => '0') ;
		GRN_left_prod_reg  <= (others => '0') ;
		BLU_left_prod_reg  <= (others => '0') ;
		RED_right_prod_reg <= (others => '0') ;
		GRN_right_prod_reg <= (others => '0') ;
		BLU_right_prod_reg <= (others => '0') ;
	  else
		if (RED_left_prod(16) = '1') then
		  RED_left_prod_reg  <= RED_left_prod(34 downto 17) + 1 ;
		else
		  RED_left_prod_reg  <= RED_left_prod(34 downto 17) ;
		end if ;
		--
		if (GRN_left_prod(16) = '1') then
		  GRN_left_prod_reg  <= GRN_left_prod(34 downto 17) + 1 ;
		else
		  GRN_left_prod_reg  <= GRN_left_prod(34 downto 17) ;
		end if ;
		--
		if (BLU_left_prod(16) = '1') then
		  BLU_left_prod_reg  <= BLU_left_prod(34 downto 17) + 1 ;
		else
		  BLU_left_prod_reg  <= BLU_left_prod(34 downto 17) ;
		end if ;
		--
		if (RED_right_prod_reg(16) = '1') then 
		  RED_right_prod_reg <= RED_right_prod(34 downto 17) + 1 ;
		else
		  RED_right_prod_reg <= RED_right_prod(34 downto 17) ;
		end if ;
		--
		if (GRN_right_prod_reg(16) = '1') then 
		  GRN_right_prod_reg <= GRN_right_prod(34 downto 17) + 1 ;
		else
		  GRN_right_prod_reg <= GRN_right_prod(34 downto 17) ;
		end if ;
		--
		if (BLU_right_prod_reg(16) = '1') then 
		  BLU_right_prod_reg <= BLU_right_prod(34 downto 17) + 1 ;
		else
		  BLU_right_prod_reg <= BLU_right_prod(34 downto 17) ;
		end if ;
		--
		-- maintain alignment between product & inputs
		RED_left_ext_reg   <= RED_left_extnd ;
		GRN_left_ext_reg   <= GRN_left_extnd ;
		BLU_left_ext_reg   <= BLU_left_extnd ;
		RED_right_ext_reg  <= RED_right_extnd ;
		GRN_right_ext_reg  <= GRN_right_extnd ;
		BLU_right_ext_reg  <= BLU_right_extnd ;
	  end if ;
	end if ;
  end process reg_product ;
  --
  apply_deGhost: process (clock)
  begin
	if (clock'event and clock = '1') then
	  if (reset = '1') then
		RED_left_deGhost  <= (others => '0') ;
		GRN_left_deGhost  <= (others => '0') ;
		BLU_left_deGhost  <= (others => '0') ;
		RED_right_deGhost <= (others => '0') ;
		GRN_right_deGhost <= (others => '0') ;
		BLU_right_deGhost <= (others => '0') ;
	  else
		RED_left_deGhost  <= RED_left_ext_reg - RED_right_prod_reg ;
		GRN_left_deGhost  <= GRN_left_ext_reg - GRN_right_prod_reg ;
		BLU_left_deGhost  <= BLU_left_ext_reg - BLU_right_prod_reg ;
		RED_right_deGhost <= RED_right_ext_reg - RED_left_prod_reg ;
		GRN_right_deGhost <= GRN_right_ext_reg - GRN_left_prod_reg ;
		BLU_right_deGhost <= BLU_right_ext_reg - BLU_left_prod_reg ;
	  end if ;
	end if ;
  end process apply_deGhost ;
  --
  drive_outs: process (clock)
  begin
	if (clock'event and clock = '1') then
	  if (reset = '1') then
		RED_left_out  <= (others => '0') ;
		GRN_left_out  <= (others => '0') ;
		BLU_left_out  <= (others => '0') ;
		RED_right_out <= (others => '0') ;
		GRN_right_out <= (others => '0') ;
		BLU_right_out <= (others => '0') ;
	  else
		if (RED_left_deGhost(RED_left_deGhost'high) = '1') then
		  RED_left_out <= (others => '0') ; -- if deGhosted negative
		else
		  RED_left_out <=  std_logic_vector(RED_left_deGhost(15 downto 0)) ;
		end if ;
		--
		if (GRN_left_deGhost(GRN_left_deGhost'high) = '1') then
		  GRN_left_out <= (others => '0') ; -- if deGhosted negative
		else
		  GRN_left_out <=  std_logic_vector(GRN_left_deGhost(15 downto 0)) ;
		end if ;
		--
		if (BLU_left_deGhost(BLU_left_deGhost'high) = '1') then
		  BLU_left_out <= (others => '0') ; -- if deGhosted negative
		else
		  BLU_left_out <=  std_logic_vector(BLU_left_deGhost(15 downto 0)) ;
		end if ;
		--
		if (RED_right_deGhost(RED_right_deGhost'high) = '1') then
		  RED_right_out <= (others => '0') ; -- if deGhosted negative
		else
		  RED_right_out <=  std_logic_vector(RED_right_deGhost(15 downto 0)) ;
		end if ;
		--
		if (GRN_right_deGhost(GRN_right_deGhost'high) = '1') then
		  GRN_right_out <= (others => '0') ; -- if deGhosted negative
		else
		  GRN_right_out <=  std_logic_vector(GRN_right_deGhost(15 downto 0)) ;
		end if ;
		--
		if (BLU_right_deGhost(BLU_right_deGhost'high) = '1') then
		  BLU_right_out <= (others => '0') ; -- if deGhosted negative
		else
		  BLU_right_out <=  std_logic_vector(BLU_right_deGhost(15 downto 0)) ;
		end if ;
		--
	  end if ;
	end if ;
  end process drive_outs ;
--
-- ****************** Ghost Factor Zone Counters *******************
--
  count_pixels: process (clock)
  begin
	if(clock'event and clock = '1') then
	  if (reset = '1') then
		pixel_cntr     <= (others => '1')  ;
		horz_zone_trgt <= (others => '1')  ;
		horz_zone_cntr <= (others => '0')  ;
		zone_column    <= (others => '0')  ;
		early_ZCcntr_rst <= '0' ;
		ZCcntr_rst       <= '0' ;
		H_ready          <= '0' ;
		first_H_cnt      <= '0' ;
	  else
		if (horz_rise = '1') then
		  pixel_cntr <= (others => '0')  ;
		elsif (horz_in = '0') then 
		  pixel_cntr <= pixel_cntr + 1 ;
		end if ;
		--
		-- divide screen into 8 columns, -3 to
		-- account for pipe delay of LUT RAM's
		if (horz_rise = '1') then
		  horz_zone_trgt <= (pixel_cntr/8) - 3 ;
		  first_H_cnt    <= '1' ;
		  H_ready        <= first_H_cnt ;
		end if ;
		--
		if (horz_in = '1') then
		  horz_zone_cntr <= (others => '0')  ;
		elsif (ZCcntr_rst = '1') then 
		  horz_zone_cntr <= (others => '0')  ;
		else
		  horz_zone_cntr <= horz_zone_cntr + 1 ;
		end if ;
		--
		if (horz_in = '1') then
		  zone_column    <= (others => '0')  ;
		elsif (horz_zone_cntr = horz_zone_trgt) then
		  zone_column <= std_logic_vector(unsigned(zone_column) + 1) ;
		end if ;
		-- The zone counter always gets reset 2~ after the zone_row
		-- is incremented.
		if (horz_zone_cntr = horz_zone_trgt) then
		  early_ZCcntr_rst <= '1' ;
		else
		  early_ZCcntr_rst <= '0' ;
		end if ;
		--
		ZCcntr_rst <= early_ZCcntr_rst ;
	  end if ;
	end if ;
  end process count_pixels ;
  --
  --
  -- Note that the line counter starts at 1 not 0 since the
  -- vertical signal goes away at the start of HD going
  -- active so a line is counted just after VD goes
  -- inactive.
  count_lines: process (clock)
  begin
	if(clock'event and clock = '1') then
	  if (reset = '1') then
		line_cntr      <= (others => '1')  ;
		vert_zone_trgt <= (others => '1')  ;
		vert_zone_cntr <= (others => '0')  ;
		zone_row       <= (others => '0')  ;
		ZRcntr_rst       <= '0' ;
		V_ready          <= '0' ;
		first_V_cnt      <= '0' ;
	  else
		if (vert_rise = '1') then
		  line_cntr  <= (others => '0')  ;
		elsif (horz_rise = '1'and vert_in = '0') then
		  line_cntr <= line_cntr + 1 ; -- active lines only
		end if ;
		--
		-- Divide screen into 4 rows
		if (vert_rise = '1') then
		  vert_zone_trgt <= (line_cntr/4); --  - 1 ;
		  first_V_cnt    <= '1' ;
		  V_ready        <= first_V_cnt ;
		end if ;
		--
		-- Reset to 0 @ Vert since the Horz which occurs
		-- as Vert is going inactive will increment the
		-- count, reset to 1 on all terminal count resets.
		if (vert_in = '1') then
		  vert_zone_cntr <= (others => '0')  ;
		elsif (ZRcntr_rst = '1' and horz_rise = '1') then
		  vert_zone_cntr <= to_unsigned(1,(vert_zone_cntr'high+1)) ;
		elsif (horz_rise = '1' and vert_in = '0' and ZRcntr_rst = '0') then
		  vert_zone_cntr <= vert_zone_cntr + 1 ;
		end if ;
		--
		if (vert_in = '1') then
		  zone_row  <= (others => '0')  ;
		elsif ((vert_zone_cntr = vert_zone_trgt) and horz_rise = '1') then
		  zone_row <= std_logic_vector(unsigned(zone_row) + 1) ;
		end if ;
		--
		if (vert_zone_cntr = vert_zone_trgt) then
		  ZRcntr_rst <= '1' ;
		else
		  ZRcntr_rst <= '0' ;
		end if ;
		--
	  end if ;
	end if ;
  end process count_lines ;
  --
  H_V_edges: process (clock)
  begin
	if (clock'event and clock = '1') then
	  if (reset = '1') then
		edg_horz_SR <= (others => '0') ;
		edg_vert_SR <= (others => '0') ;
		horz_rise   <= '0' ;
		vert_rise   <= '0' ;
	  else
		edg_horz_SR(0) <= horz_in ;
		edg_horz_SR(edg_horz_SR'high downto 1) <= edg_horz_SR(edg_horz_SR'high-1 downto 0) ;
		--
		edg_vert_SR(0) <= vert_in ; -- & '0' ;
		edg_vert_SR(edg_vert_SR'high downto 1) <= edg_vert_SR(edg_vert_SR'high-1 downto 0) ;
		--
		if (edg_horz_SR = "0011") then
		  horz_rise   <= '1' ;
		else
		  horz_rise   <= '0' ;
		end if ;
		--
		if (edg_vert_SR = "0011") then
		  vert_rise   <= '1' ;
		else
		  vert_rise   <= '0' ;
		end if ;
	  end if ;
	end if ;
  end process H_V_edges ;
-- 
-- *********************** Ghost Factor RAM's ***********************
-- data *2 (always positive)
  GF_data_to_RAM <= "00" & data_in(15 downto 0) ;
  GF_read_addr   <= address(5 downto 1) when bypass = '1'
					else zone_row & zone_column ;
  data_out       <= RED_ghost_factor(15 downto 0) when (which_RAM = sel_RED) else
					GRN_ghost_factor(15 downto 0) when (which_RAM = sel_GRN) else
					BLU_ghost_factor(15 downto 0)  ;
  --
  wr_RED <= wr_en when (which_RAM = sel_RED) else '0' ;
  red_GF_RAM: dpRAM_32x18
	port map (
	  clock	     => clock ,
	  data	     => GF_data_to_RAM ,
	  rdaddress	 => GF_read_addr ,
	  wraddress	 => address(5 downto 1) ,
	  wren	     => wr_RED  ,
	  q	         => RED_ghost_factor
	  );
  --
  wr_GRN <= wr_en when (which_RAM = sel_GRN) else '0' ;
  grn_GF_RAM: dpRAM_32x18
	port map (
	  clock	     => clock ,
	  data	     => GF_data_to_RAM ,
	  rdaddress	 => GF_read_addr ,
	  wraddress	 => address(5 downto 1) ,
	  wren	     => wr_GRN  ,
	  q	         => GRN_ghost_factor
	  );
  --
  wr_BLU <= wr_en when (which_RAM = sel_BLU) else '0' ;
  blu_GF_RAM: dpRAM_32x18
	port map (
	  clock	     => clock ,
	  data	     => GF_data_to_RAM ,
	  rdaddress	 => GF_read_addr ,
	  wraddress	 => address(5 downto 1) ,
	  wren	     => wr_BLU  ,
	  q	         => BLU_ghost_factor
	  );
  --
--
-- **************** Pipe delay for video status signals ******************
  --
  act_image_out <= act_image_SR(act_image_SR'high) ;
  horz_out      <= horz_SR(horz_SR'high) ;
  vert_out      <= vert_SR(vert_SR'high) ;
  field_out     <= field_SR(field_SR'high) ;
  --
  dly_status: process (clock)
  begin
	if (clock'event and clock = '1') then
	  if (reset = '1') then
		act_image_SR  <= (others => '0') ;
		horz_SR       <= (others => '0') ;
		vert_SR       <= (others => '0') ;
		field_SR      <= (others => '0') ;
	  else
		act_image_SR(0) <= act_image_in ;
		act_image_SR(act_image_SR'high downto 1) <= act_image_SR(act_image_SR'high-1 downto 0) ;
		--
		horz_SR(0) <= horz_in ;
		horz_SR(horz_SR'high downto 1) <= horz_SR(horz_SR'high-1 downto 0) ;
		--
		vert_SR(0) <= vert_in ;
		vert_SR(vert_SR'high downto 1) <= vert_SR(vert_SR'high-1 downto 0) ;
		--
		field_SR(0) <= field_in ;
		field_SR(field_SR'high downto 1) <= field_SR(field_SR'high-1 downto 0) ;
	  end if ;
	end if ;
  end process dly_status ;
--
end behave ;
