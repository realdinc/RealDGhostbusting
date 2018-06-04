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
  signal clock      	: std_logic ;
  signal uP_clock   	: std_logic ;
  signal reset_H    	: std_logic ;
  signal reset_L	: std_logic ;
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
  constant RED_factors : GF_array := (0, 0, 0, 0, 0, 0, 0, 0,
									  0, 0, 0, 0, 0,0, 0, 0,
									  0, 0, 0, 0, 0, 0, 0, 0,
									  0, 0, 0, 0, 0, 0, 0, 0) ;
  constant GRN_factors : GF_array := (0, 0, 0, 0, 0, 0, 0, 0,
									  0, 0, 0, 0, 0,0, 0, 0,
									  0, 0, 0, 0, 0, 0, 0, 0,
									  0, 0, 0, 0, 0, 0, 0, 0) ;
  constant BLU_factors : GF_array := (0, 0, 0, 0, 0, 0, 0, 0,
									  0, 0, 0, 0, 0,0, 0, 0,
									  0, 0, 0, 0, 0, 0, 0, 0,
									  0, 0, 0, 0, 0, 0, 0, 0) ;
--
constant RED_FirstPixel : integer := 0 ;
constant GRN_FirstPixel : integer := 1024 ;
constant BLU_FirstPixel : integer := 2048 ;
constant LeftEyeOffset  : integer := 32768 ;
--
	
--
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
begin
--
	Gen_HD : process
	begin
		PixelCount   <= 0 ;
		RGB_tpg_horz <= '0' ;
		wait until (reset_H <= '0') ; -- end of reset
		while (true) loop
			wait until (clock'event and clock = '1') ;
			PixelCount <= PixelCount + 1 ;
			if (63 = PixelCount) then
				RGB_tpg_horz <= '1' ; -- set Horz
			end if ;
			--
			if (69 = PixelCount) then
				PixelCount 	 <= 0 ;
				RGB_tpg_horz <= '0' ; -- clear
			end if ;
			--
		end loop ;
	end process Gen_HD ;
--
--
	Gen_VD : process
	begin
		LineCount 	 <= 0 ;
		RGB_tpg_vert <= '0' ;
		wait until (reset_H <= '0') ; -- end of reset
		while (true) loop
			wait until (RGB_tpg_horz'event and RGB_tpg_horz = '1') ;
			LineCount <= LineCount + 1 ;
			if (3 = LineCount) then 
				RGB_tpg_vert <= '1' ; -- set Horz
			elsif (5 = LineCount) then
				LineCount 	 <= 0 ;
				RGB_tpg_vert <= '0' ; -- clear
			end if ;
		end loop ;
	end process Gen_VD ;
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
	  BLU_left_in   => BLU_left_in  ,
	  --
	  RED_right_in  => RED_right_in  ,
	  GRN_right_in  => GRN_right_in  ,
	  BLU_right_in  => BLU_right_in  ,
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
	DrivePixelInputs: process (clock) 
		variable RED_CurrentRightPixel : integer ;
		variable RED_CurrentLeftPixel  : integer ;
		variable GRN_CurrentRightPixel : integer ;
		variable GRN_CurrentLeftPixel  : integer ;
		variable BLU_CurrentRightPixel : integer ;
		variable BLU_CurrentLeftPixel  : integer ;
	begin
		if (clock'event and '1' = clock) then
			if (RGB_tpg_horz = '1') then
				RED_CurrentRightPixel := RED_FirstPixel ;
				RED_CurrentLeftPixel  := LeftEyeOffset+RED_FirstPixel ;
				GRN_CurrentRightPixel := GRN_FirstPixel ;
				GRN_CurrentLeftPixel  := LeftEyeOffset+GRN_FirstPixel ;
				BLU_CurrentRightPixel := BLU_FirstPixel ;
				BLU_CurrentLeftPixel  := LeftEyeOffset+BLU_FirstPixel ;
			elsif (RGB_tpg_vert = '0' and RGB_tpg_horz = '0') then
				RED_CurrentRightPixel := RED_CurrentRightPixel + 1 ;
				RED_CurrentLeftPixel  := RED_CurrentLeftPixel  + 1 ;
				GRN_CurrentRightPixel := GRN_CurrentRightPixel + 1 ;
				GRN_CurrentLeftPixel  := GRN_CurrentLeftPixel  + 1 ;
				BLU_CurrentRightPixel := BLU_CurrentRightPixel + 1 ;
				BLU_CurrentLeftPixel  := BLU_CurrentLeftPixel  + 1 ;
			end if ;
			--
			RED_right_in <= std_logic_vector(to_unsigned(RED_CurrentRightPixel,16)) after 3 ns ;
			GRN_right_in <= std_logic_vector(to_unsigned(GRN_CurrentRightPixel,16)) after 3 ns ;
			BLU_right_in <= std_logic_vector(to_unsigned(BLU_CurrentRightPixel,16)) after 3 ns ;
			RED_left_in <= std_logic_vector(to_unsigned(RED_CurrentLeftPixel,16))   after 3 ns ;
			GRN_left_in <= std_logic_vector(to_unsigned(GRN_CurrentLeftPixel,16))   after 3 ns ;
			BLU_left_in <= std_logic_vector(to_unsigned(BLU_CurrentLeftPixel,16))   after 3 ns ;
		end if ;
	
	end process DrivePixelInputs ;
--
--
	SamplePixelData: process(clock)
		variable RED_ExpectedRightPixel : integer ;
		variable RED_ExpectedLeftPixel  : integer ;
		variable GRN_ExpectedRightPixel : integer ;
		variable GRN_ExpectedLeftPixel  : integer ;
		variable BLU_ExpectedRightPixel : integer ;
		variable BLU_ExpectedLeftPixel  : integer ;
	begin
		if (clock'event and '1' = clock) then
			if (horz_out = '1') then
				RED_ExpectedRightPixel := RED_FirstPixel ;
				RED_ExpectedLeftPixel  := LeftEyeOffset+RED_FirstPixel ;
				GRN_ExpectedRightPixel := GRN_FirstPixel ;
				GRN_ExpectedLeftPixel  := LeftEyeOffset+GRN_FirstPixel ;
				BLU_ExpectedRightPixel := BLU_FirstPixel ;
				BLU_ExpectedLeftPixel  := LeftEyeOffset+BLU_FirstPixel ;
			elsif (vert_out = '0' and horz_out = '0') then
				RED_ExpectedRightPixel := RED_ExpectedRightPixel + 1 ;
				RED_ExpectedLeftPixel  := RED_ExpectedLeftPixel  + 1 ;
				GRN_ExpectedRightPixel := GRN_ExpectedRightPixel + 1 ;
				GRN_ExpectedLeftPixel  := GRN_ExpectedLeftPixel  + 1 ;
				BLU_ExpectedRightPixel := BLU_ExpectedRightPixel + 1 ;
				BLU_ExpectedLeftPixel  := BLU_ExpectedLeftPixel  + 1 ;
			end if ;
		elsif (clock'event and '0' = clock) then
			if (vert_out = '0' and horz_out = '0' and LUT_ready = '1') then
				assert (RED_ExpectedRightPixel = unsigned(RED_right_out))
					report "RED Right Error"
					severity error ;
				--
				assert (RED_ExpectedLeftPixel = unsigned(RED_left_out))
					report "RED Left Error"
					severity error ;
				--
				assert (GRN_ExpectedRightPixel = unsigned(GRN_right_out))
					report "GREEN Right Error"
					severity error ;
				--
				assert (GRN_ExpectedLeftPixel = unsigned(GRN_left_out))
					report "GREEN Left Error"
					severity error ;
				--
				assert (BLU_ExpectedRightPixel = unsigned(BLU_right_out))
					report "BLUE Right Error"
					severity error ;
				--
				assert (BLU_ExpectedLeftPixel = unsigned(BLU_left_out))
					report "BLUE Left Error"
					severity error ;
				
			end if ;
		end if ;
		
	end process SamplePixelData ;
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