--
-- Test bench for zoned test pattern generator.
--
--
library IEEE; 
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
library std ;
use std.textio.all ;
--
use work.utilities.all ;
--
entity TB_deGhost is

end TB_deGhost ;
--
--
architecture test of TB_deGhost is
--
--
	component Ghost_Buster_Top
	port (
	  clock         : in std_logic ;
	  reset         : in std_logic ;
	  byPass        : in std_logic ;
	  --
	  delay         : out integer   ;
	  H_ready       : out std_logic ; -- Horz zone count ready
	  V_ready       : out std_logic ; -- Vert zone count ready
	  -- Bus interface for Ghost Factor memory writes
	  data_from_uP  : in std_logic_vector (15 downto 0) ;
	  data_to_uP    : out std_logic_vector (15 downto 0) ;
	  uP_addr       : in std_logic_vector (7 downto 1)  ; -- word address
	  wr_en         : in std_logic ; -- at least 4~ wide
	  chip_sel      : in std_logic ;
	  --
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
	end component ;
--
--
component RGB_16b_TestPattern_8x4 is
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
end component  ;
--
--
  signal clock      	: std_logic ;
  signal uP_clock   	: std_logic ;
  signal reset_H    	: std_logic ;
  signal reset_L		: std_logic ;
  signal GB_delay   	: integer ;
  signal GB_byPass 		: std_logic ;
  signal H_ready 		: std_logic ;
  signal V_ready 		: std_logic ;
  --
  signal uP_data    	: std_logic_vector (15 downto 0 );
  signal check_data 	: std_logic_vector (15 downto 0 );
  signal uP_addr   		: std_logic_vector (7  downto 0) ;
  signal uP_wren_L   	: std_logic ;
  signal uP_select_L 	: std_logic ;
  --
  signal RGB_tpg_horz   : std_logic ;
  signal RGB_tpg_vert   : std_logic ;
  signal RGB_tpg_field  : std_logic ;
  signal RGB_tpg_active : std_logic ;
  --
  signal RED_left_in   	: std_logic_vector (15 downto 0) ;
  signal GRN_left_in   	: std_logic_vector (15 downto 0) ;
  signal BLU_left_in   	: std_logic_vector (15 downto 0) ;
  --
  signal RED_right_in  	: std_logic_vector (15 downto 0) ;
  signal GRN_right_in  	: std_logic_vector (15 downto 0) ;
  signal BLU_right_in  	: std_logic_vector (15 downto 0) ;
  --
  signal act_image_out 	: std_logic ;
  signal horz_out      	: std_logic ;
  signal vert_out      	: std_logic ;
  signal field_out     	: std_logic ;
  --
  signal RED_left_out  	: std_logic_vector (15 downto 0) ;
  signal GRN_left_out  	: std_logic_vector (15 downto 0) ;
  signal BLU_left_out  	: std_logic_vector (15 downto 0) ;
  --
  signal RED_right_out 	: std_logic_vector (15 downto 0) ;
  signal GRN_right_out 	: std_logic_vector (15 downto 0) ;
  signal BLU_right_out 	: std_logic_vector (15 downto 0) ;
--
--
  -- NOTE any ghost factor > 32897 will saturate an integer for max pixel value
  -- of 65279
  type GF_array is array (0 to 31) of integer ;
  constant RED_factors : GF_array := (1, 2, 3, 4, 5, 6, 7, 8,
									  9, 10, 11, 12, 13, 14, 15, 16,
									  17, 18, 19, 20, 21, 22, 23, 24,
									  25, 26, 27, 28, 29, 30, 31, 32) ;
  constant GRN_factors : GF_array := (1, 2, 3, 4, 5, 6, 7, 8,
									  9, 10, 11, 12, 13, 14, 15, 16,
									  17, 18, 19, 20, 21, 22, 23, 24,
									  25, 26, 27, 28, 29, 30, 31, 32) ;
-- Set blue factors for Left out to yield zone * 33 for left in = 8192 & right in = 32768
  constant BLU_factors : GF_array := (132, 264, 396, 526, 660, 792, 924, 1056,
									  1188, 1320, 1452, 1584, 1716, 1848, 1980, 2112,
									  2244, 2376, 2508, 2640, 2772, 2904, 3036, 3168,
									  3300, 3432, 3564, 3696, 3828, 3960, 4092, 4224) ;
--
	constant BLU_Left_Constant  : integer := 8192 ;
	constant BLU_Right_Constant : integer := 32768 ;
	
	signal data_2_GB  : std_logic_vector (15 downto 0) ;
	signal addr_4_GB  : std_logic_vector (7 downto 0) ;
	signal LUT_ready : std_logic ;
	signal uP_wren   : std_logic ;
	signal uP_select : std_logic ;
--
--
--
	signal VideoClk	: std_logic ;
	signal PixelCount  	: integer ;
	signal LineCount	: integer ;
	signal HorzZone		: integer ;
	signal VertZone		: integer ;
	signal PixelInputValid : std_logic ;
	--
	signal SampleCounterEnabled : std_logic ;
	signal SampleCounter : integer ;
	signal SampleStrobe : std_logic  ;
	--
	file results_file  : text ; -- open write_mode is "GhostBusted.txt" ;
	--
	--
	signal SelectVideo : std_logic_vector (1 downto 0) ;
	constant Select_1p9K : std_logic_vector (1 downto 0) := "00" ;
	constant Select_2K : std_logic_vector (1 downto 0) := "01" ;
	constant Select_4K : std_logic_vector (1 downto 0) := "10" ;
	signal  TPG_enable : std_Logic ;
	signal tpg_act_video : std_logic ;
	signal TPG_zone : integer ;
	--
	signal CalcZone : integer ;
	signal test : unsigned (15 downto 0) ;
	signal SampleCalcZone : std_logic ;
	--
	signal ZonesValid : std_logic ;
--
begin
--
--
	CountFrames: process
	begin
		ZonesValid <= '0' ;
		wait until (reset_H <= '0') ; -- end of reset
		wait until (vert_out'event and vert_out = '0') ;
		wait until (vert_out'event and vert_out = '1') ;
		wait until (vert_out'event and vert_out = '0') ;
		ZonesValid <= '1' ;
		wait until (vert_out'event and vert_out = '1') ;

		ZonesValid <= '0' ;
		wait until (reset_H <= '1') ;
	end process ;
	--
	--
	CountLines: process 
	begin
		wait until (vert_out'event or horz_out'event) ;
		--
		if (vert_out'event) then
			LineCount <= 1 ; 
		elsif ((horz_out'event and horz_out = '1') and vert_out = '0') then
			LineCount <=  LineCount + 1 ;
		end if ;
	end process CountLines ;
	--
	--
	CountPixels: process
	begin
		wait until (horz_out'event or clock'event) ;
		if (horz_out'event) then
			PixelCount   <= 1 ;
			CalcZone     <= 35 ;
		elsif (clock'event and clock = '1') then
			CalcZone <= (BLU_Left_Constant - 1 - (to_integer(unsigned(BLU_left_out))))/ 33 ;
			PixelCount <= PixelCount + 1 ;
		end if ;
		--
		--
		
	end process CountPixels ;
	--
	--
	CheckZones: process 
	variable LastCaclZone : integer ;
	begin
		wait until (horz_out'event or CalcZone'event) ;
		if (horz_out'event) then
			LastCaclZone := 33 ;
			SampleCalcZone <= '0' ;
		elsif (CalcZone'event and CalcZone /= LastCaclZone and horz_out = '0') then
			SampleCalcZone <= ZonesValid ;
			SampleCalcZone <= transport '0' after 30 nS;
			LastCaclZone := CalcZone;
		else 
			SampleCalcZone <= '0' ;
		end if ;
	end process CheckZones ;
	--
	--
	VerifyZones: process(SampleCalcZone,ZonesValid)
		variable l_out	: line ;
		variable row	: integer ;
		variable column	: integer ;
		variable ErrorFlag  : std_logic ;
	begin
		if (ZonesValid'event and ZonesValid = '1') then
			-- Write header line to output file
			file_open(results_file,"Zones.csv",WRITE_MODE) ;
			write(l_out,string'("Expected ZONE ,")) ;
			write(l_out,string'("Calculated ZONE ,")) ;
			write(l_out,string'("ZONE Row ,")) ;
			write(l_out,string'("ZONE Column,")) ;
			writeline(results_file,l_out) ;
		elsif (ZonesValid'event and ZonesValid = '0' and reset_H = '0') then
			file_close(results_file) ;
		end if ;
		--
		if (SampleCalcZone'event and SampleCalcZone = '0' and ZonesValid = '1') then
			if (CalcZone > 23) then
				row := 3 ;
			elsif (CalcZone > 15) then
				row := 2 ;
			elsif (CalcZone > 7) then
				row := 1 ;
			else 
				row := 0 ;
			end if ;
			--
			column := CalcZone - (row * 8) ;
			--
			if (CalcZone = TPG_zone) then
				ErrorFlag := '0' ;
			else 
				ErrorFlag := '1' ;
			end if ;
			--
			write(l_out,TPG_zone) ;
			write(l_out,string'(",")) ;
			write(l_out,CalcZone) ;
			write(l_out,string'(",")) ;
			write(l_out,row) ;
			write(l_out,string'(",")) ;
			write(l_out,column) ;
			write(l_out,string'(",")) ;
			--
			if (ErrorFlag = '1') then
				write(l_out,string'("*** ERROR")) ;
			end if ;
			--
			writeline(results_file,l_out) ;
			--
			assert (CalcZone = TPG_zone)
				report "Calculated Zone NOT Equal to Expected Zone"
				severity error ;
		end if ;
	end process VerifyZones ;
	--
	--
--
	uP_wren_L <= not uP_wren ;
	uP_select_L <= not uP_select ;
--
	DUT: Ghost_Buster_Top
	port map (
	  clock         => clock ,
	  reset         => reset_H ,
	  byPass        => GB_byPass ,
	  --
	  delay         => GB_delay ,
	  H_ready       => H_ready ,
	  V_ready       => V_ready ,
	  -- Bus interface for Ghost Factor memory writes
	  data_from_uP  => uP_data ,
	  data_to_uP    => check_data ,
	  uP_addr       => uP_addr(7 downto 1) ,
	  wr_en         => uP_wren ,
	  chip_sel      => uP_select ,
	  --
	  horz_in       => RGB_tpg_horz ,
	  vert_in       => RGB_tpg_vert ,
	  field_in      => RGB_tpg_field ,
	  --
	  RED_left_in   => RED_left_in  ,
	  GRN_left_in   => GRN_left_in  ,
	  BLU_left_in   => std_logic_vector(to_unsigned(BLU_Left_Constant,16)), -- BLU_left_in  ,
	  --
	  RED_right_in  => RED_right_in  ,
	  GRN_right_in  => GRN_right_in  ,
	  BLU_right_in  => std_logic_vector(to_unsigned(BLU_Right_Constant,16)), -- BLU_right_in  ,
	  --
	  act_image_out => act_image_out ,
	  horz_out      => horz_out ,
	  vert_out      => vert_out ,
	  field_out     => field_out ,
	  --
	  RED_left_out  => RED_left_out  ,
	  GRN_left_out  => GRN_left_out  ,
	  BLU_left_out  => BLU_left_out  ,
	  --
	  RED_right_out => RED_right_out  ,
	  GRN_right_out => GRN_right_out  ,
	  BLU_right_out => BLU_right_out 
	) ;
--
--
Pattern: RGB_16b_TestPattern_8x4 
  port map(
	clock         => clock ,
	reset         => reset_H ,
	--
	video_select  => Select_4K ,
	TPG_enable    => LUT_ready ,
	--
	horz_out      => RGB_tpg_horz ,
	vert_out      => RGB_tpg_vert ,
	field_out     => RGB_tpg_field ,
	act_video_out => tpg_act_video ,
	crnt_zone     => TPG_zone ,
	--
	R_left_out    => RED_left_in  ,
	G_left_out    => GRN_left_in ,
	B_left_out    => BLU_left_in ,
	R_right_out   => RED_right_in ,
	G_right_out   => GRN_right_in ,
	B_right_out   => BLU_right_in
	) ;
--
--
--
  wr_GF_LUT: process
  begin
	GB_byPass  <= '1' ;
	LUT_ready  <= '0' ;
	uP_wren    <= '0' ;
	uP_data    <= (others => '0') ;
	uP_addr    <= (others => '0') ;
	uP_select  <= '0' ;
	wait until (reset_H <= '0') ; -- end of reset
	wait until (uP_clock'event and uP_clock = '1') ;
	wait until (uP_clock'event and uP_clock = '1') ;
	data_2_GB <= std_logic_vector(to_unsigned(0,16)) ;
	addr_4_GB <= "00000000" ;
	l1: for i in 0 to 31 loop
	  data_2_GB <= std_logic_vector(to_unsigned(RED_factors(i),16)) ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wr_GB_LUT(addr_4_GB,data_2_GB,uP_addr(7 downto 1),uP_data,uP_wren,uP_select) ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  -- read back
	  uP_addr(7 downto 1) <= addr_4_GB(7 downto 1) ;
	  uP_select <= '1' ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  assert (check_data = data_2_GB)
		report "RED read back error"
		severity error ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  uP_select <= '0' ;
	  uP_addr(7 downto 1) <= (others => 'X') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  addr_4_GB <= std_logic_vector(unsigned(addr_4_GB) + to_unsigned(2,8)) ;
	end loop ;
	wait until (uP_clock'event and uP_clock = '1') ;
	wait until (uP_clock'event and uP_clock = '1') ;
	wait until (uP_clock'event and uP_clock = '1') ;
	wait until (uP_clock'event and uP_clock = '1') ;
	addr_4_GB <= "01000000" ;
	wait until (uP_clock'event and uP_clock = '1') ;
	l2: for i in 0 to 31 loop
	  data_2_GB <= std_logic_vector(to_unsigned(GRN_factors(i),16)) ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wr_GB_LUT(addr_4_GB,data_2_GB,uP_addr(7 downto 1),uP_data,uP_wren,uP_select) ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  -- read back
	  uP_addr(7 downto 1) <= addr_4_GB(7 downto 1) ;
	  uP_select <= '1' ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  assert (check_data = data_2_GB)
		report "GREEN read back error"
		severity error ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  uP_select <= '0' ;
	  uP_addr(7 downto 1) <= (others => 'X') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  addr_4_GB <= std_logic_vector(unsigned(addr_4_GB) + to_unsigned(2,8)) ;
	end loop ;
	wait until (uP_clock'event and uP_clock = '1') ;
	wait until (uP_clock'event and uP_clock = '1') ;
	wait until (uP_clock'event and uP_clock = '1') ;
	wait until (uP_clock'event and uP_clock = '1') ;
	addr_4_GB <= "10000000" ;
	wait until (uP_clock'event and uP_clock = '1') ;
	l3: for i in 0 to 31 loop
	  data_2_GB <= std_logic_vector(to_unsigned(BLU_factors(i),16)) ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wr_GB_LUT(addr_4_GB,data_2_GB,uP_addr(7 downto 1),uP_data,uP_wren,uP_select) ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  -- read back
	  uP_addr(7 downto 1) <= addr_4_GB(7 downto 1) ;
	  uP_select <= '1' ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  assert (check_data = data_2_GB)
		report "BLUE read back error"
		severity error ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  uP_select <= '0' ;
	  uP_addr(7 downto 1) <= (others => 'X') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  wait until (uP_clock'event and uP_clock = '1') ;
	  addr_4_GB <= std_logic_vector(unsigned(addr_4_GB) + to_unsigned(2,8)) ;
	end loop ;
	wait until (uP_clock'event and uP_clock = '1') ;
	wait until (uP_clock'event and uP_clock = '1') ;
	wait until (uP_clock'event and uP_clock = '1') ;
	wait until (uP_clock'event and uP_clock = '1') ;
	GB_byPass  <= '0' ;
	LUT_ready  <= '1' ;
	wait until (uP_clock'event and uP_clock = '1') ;
	wait until (uP_clock'event and uP_clock = '1') ;
	wait until (reset_H <= '1') ; -- reset
  end process wr_GF_LUT ;
--
--
--
	GEN_vidCLOCK : process
	begin
		VideoClk <= '0' ;
		wait for 51372 ps ;
		VideoClk <= '1' ;
		wait for 51372 ps ;
	end process GEN_vidCLOCK ;
--
  GEN_CLOCK : process
  begin
	clock <= '0' ;
	wait for 5000 ps ;
	clock <= '1' ;
	wait for 5000 ps ;
  end process GEN_CLOCK ;  
--
--
  GEN_upCLOCK : process
  begin
	uP_clock <= '0' ;
	wait for 10000 ps ;
	uP_clock <= '1' ;
	wait for 10000 ps ;
  end process GEN_upCLOCK ;  
--
--
  reset_L <= not reset_H ;
  --
  GEN_RESET : process
  begin
	reset_H <= '1' ; 
	wait for 44 ns;
	reset_H <= '0' ;
	wait;
  end process GEN_RESET ;
--
end test ;