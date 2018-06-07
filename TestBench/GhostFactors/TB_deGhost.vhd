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
  constant RED_factors : GF_array := (490, 731, 662, 393, 524, 655, 786, 918,
									  1049, 1180, 1311, 1442, 1573, 1704, 1835, 1966,
									  2097, 2228, 2359, 2490, 2621, 2753, 2884, 3015,
									  3146, 3277, 3408, 3539, 3670, 3801, 3932, 4063) ;
  constant GRN_factors : GF_array := (4194, 4325, 4456, 4588, 4719, 4850, 4981, 5112,
									  5243, 5374, 5505, 5636, 5767, 5898, 6029, 6160,
									  6291, 6423, 6554, 6685, 6816, 6947, 7078, 7209,
									  7340, 7471, 7602, 7733, 7864, 7995, 8126, 8258) ;
  constant BLU_factors : GF_array := (8389, 8520, 8651, 8782, 8913, 9044, 9175, 9306,
									  9437, 9568, 9699, 9830, 9961, 10093, 10224, 10355,
									  10486, 10617, 10784, 10879, 11010, 11141, 11272, 11403,
									  11534, 11665, 11796, 11928, 12059, 12190, 12321, 12452) ;
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
--
	ApplyPixelData: process 
	begin
		PixelInputValid <= '0' ;
		wait until (reset_H <= '0') ; -- end of reset
		wait until (LUT_ready'event and LUT_ready = '1') ;
		wait until (RGB_tpg_vert'event and RGB_tpg_vert = '1') ; -- Vert drive active
		wait until (RGB_tpg_vert'event and RGB_tpg_vert = '0') ; -- Vert drive inactive
		wait until (RGB_tpg_vert'event and RGB_tpg_vert = '1') ; -- Vert drive active
		RED_left_in  <= std_logic_vector(to_unsigned(3142,16)) ;
		RED_right_in <= std_logic_vector(to_unsigned(3373,16)) ; 
		GRN_left_in  <= std_logic_vector(to_unsigned(2891,16)) ; 
		GRN_right_in <= std_logic_vector(to_unsigned(2472,16)) ; 
		BLU_left_in  <= std_logic_vector(to_unsigned(910,16)) ; 
		BLU_right_in <= std_logic_vector(to_unsigned(1231,16)) ; 
		PixelInputValid <= '1' ;
		wait until (RGB_tpg_vert'event and RGB_tpg_vert = '0') ; -- Vert drive inactive
		--
		wait until (RGB_tpg_vert'event and RGB_tpg_vert = '1') ; -- Vert drive active
		RED_left_in  <= std_logic_vector(to_unsigned(4008,16)) ; 
		RED_right_in <= std_logic_vector(to_unsigned(3800,16)) ;
		GRN_left_in  <= std_logic_vector(to_unsigned(3472,16)) ;
		GRN_right_in <= std_logic_vector(to_unsigned(2347,16)) ; 
		BLU_left_in  <= std_logic_vector(to_unsigned(8431,16)) ;
		BLU_right_in <= std_logic_vector(to_unsigned(12372,16)) ;
		PixelInputValid <= '1' ;
		wait until (RGB_tpg_vert'event and RGB_tpg_vert = '0') ; -- Vert drive inactive
		--
		wait until (RGB_tpg_vert'event and RGB_tpg_vert = '1') ; -- Vert drive active
		RED_left_in  <= std_logic_vector(to_unsigned(7126,16)) ;
		RED_right_in <= std_logic_vector(to_unsigned(6388,16)) ;
		GRN_left_in  <= std_logic_vector(to_unsigned(2786,16)) ;
		GRN_right_in <= std_logic_vector(to_unsigned(1470,16)) ;
		BLU_left_in  <= std_logic_vector(to_unsigned(1876,16)) ;
		BLU_right_in <= std_logic_vector(to_unsigned(2387,16)) ;
		PixelInputValid <= '1' ;
		wait until (RGB_tpg_vert'event and RGB_tpg_vert = '0') ; -- Vert drive inactive
		--
		wait until (RGB_tpg_vert'event and RGB_tpg_vert = '1') ; -- Vert drive active
		RED_left_in  <= std_logic_vector(to_unsigned(16457,16)) ;
		RED_right_in <= std_logic_vector(to_unsigned(8217,16)) ;
		GRN_left_in  <= std_logic_vector(to_unsigned(33065,16)) ;
		GRN_right_in <= std_logic_vector(to_unsigned(6733,16)) ;
		BLU_left_in  <= std_logic_vector(to_unsigned(47800,16)) ;
		BLU_right_in <= std_logic_vector(to_unsigned(55347,16)) ;
		PixelInputValid <= '1' ;
		wait until (RGB_tpg_vert'event and RGB_tpg_vert = '0') ; -- Vert drive inactive
		--
		wait until (RGB_tpg_vert'event and RGB_tpg_vert = '1') ; -- Vert drive active
		RED_left_in  <= std_logic_vector(to_unsigned(997,16)) ;
		RED_right_in <= std_logic_vector(to_unsigned(2345,16)) ;
		GRN_left_in  <= std_logic_vector(to_unsigned(8765,16)) ;
		GRN_right_in <= std_logic_vector(to_unsigned(7982,16)) ;
		BLU_left_in  <= std_logic_vector(to_unsigned(2347,16)) ;
		BLU_right_in <= std_logic_vector(to_unsigned(1186,16)) ;
		PixelInputValid <= '1' ;
		wait until (RGB_tpg_vert'event and RGB_tpg_vert = '1') ; -- Vert drive active
		PixelInputValid <= '0' ; -- done
		wait until (RGB_tpg_vert'event and RGB_tpg_vert = '0') ; -- Vert drive inactive
	
		wait until (reset_H <= '1') ; -- reset
	end process ApplyPixelData ;
--
--
	SamplePixelData: process(clock, horz_out)
	begin
	
		if (clock'event and '1' = clock) then
			if (reset_H = '1' or PixelInputValid = '0') then
				SampleCounter <= 0 ;
				SampleStrobe <= '0' ;
				SampleCounterEnabled <= '0' ;
				HorzZone <= 0 ;
			elsif ('1' = SampleCounterEnabled) then
				if (SampleCounter < 7) then
					SampleCounter <= SampleCounter + 1 ;
					SampleStrobe <= '0' ;
				else
					SampleCounter <= 0 ;
					HorzZone <= HorzZone + 1 ;
					SampleStrobe <= not RGB_tpg_horz ; -- '1' ;
				end if ;
			end if ;
		end if ;
		--
		if (horz_out'event and horz_out = '0') then
			HorzZone <= 0 ;
			if ('1' = PixelInputValid  and '0' = vert_out) then
				SampleCounter <= 0 ;
				SampleStrobe <= '1' ;
				SampleCounterEnabled <= '1' ;
				--
				if (SampleCounterEnabled = '1') then
					VertZone <= VertZone + 1 ;
				else
					VertZone <= 0 ;
				end if ;
			else 
				SampleCounterEnabled <= '0' ;
			end if ;
		end if;
		
	end process SamplePixelData ;
	--
	--
	EvaluatePixeldata: process (SampleStrobe, PixelInputValid)
		variable l_out    : line ;
		variable zone     : integer ;
		variable CalcGF   : integer ;
		variable OldEye   : integer ;
		variable NewEye   : integer ;
		variable OtherEye : integer ;
		variable GF_OK    : std_logic ;
	begin
	--
	--
	if (PixelInputValid'event and PixelInputValid = '1') then
		-- Write header line to output file
		file_open(results_file,"GhostBusted.csv",WRITE_MODE) ;
		write(l_out,string'("ZONE ,")) ;
		write(l_out,string'("RED Right IN ,")) ;
		write(l_out,string'("RED Left IN ,")) ;
		write(l_out,string'("RED Expected Ghost Fact ,")) ;
		write(l_out,string'("RED Right OUT ,")) ;
		write(l_out,string'("RED Left OUT ,")) ;
		write(l_out,string'("RED Right Calc GF ,")) ;
		write(l_out,string'("RED Left Calc GF ,")) ;
		write(l_out,string'("GRN Right IN ,")) ;
		write(l_out,string'("GRN Left IN ,")) ;
		write(l_out,string'("GRN Expected Ghost Fact ,")) ;
		write(l_out,string'("GRN Right OUT ,")) ;
		write(l_out,string'("GRN Left OUT ,")) ;
		write(l_out,string'("GRN Right Calc GF ,")) ;
		write(l_out,string'("GRN Left Calc GF ,")) ;
		write(l_out,string'("BLU Right IN ,")) ;
		write(l_out,string'("BLU Left IN ,")) ;
		write(l_out,string'("BLU Expected Ghost Fact ,")) ;
		write(l_out,string'("BLU Right OUT ,")) ;
		write(l_out,string'("BLU Left OUT ,")) ;
		write(l_out,string'("BLU Right Calc GF ,")) ;
		write(l_out,string'("BLU Left Calc GF ,")) ;
		writeline(results_file,l_out) ;
	elsif (PixelInputValid'event and PixelInputValid = '0' and reset_H = '0') then
		file_close(results_file) ;
	end if ;
	--
	--
	if (SampleStrobe'event and SampleStrobe = '1') then
		zone := (VertZone * 8) + HorzZone ;
		write(l_out,(zone)) ;
		write(l_out,string'(",")) ;
		write(l_out,to_integer(unsigned(RED_right_in))) ;
		write(l_out,string'(",")) ;
		write(l_out,to_integer(unsigned(RED_left_in))) ;
		write(l_out,string'(",")) ;
		write(l_out,RED_factors(zone)) ;
		write(l_out,string'(",")) ;
		write(l_out,to_integer(unsigned(RED_right_out))) ;
		write(l_out,string'(",")) ;
		write(l_out,to_integer(unsigned(RED_left_out))) ;
		write(l_out,string'(",")) ;
		OldEye   := to_integer(unsigned(RED_right_in)) ;
		NewEye   := to_integer(unsigned(RED_right_out)) ;
		OtherEye := to_integer(unsigned(RED_left_in)) ;
		CalcGF   := Calc_GhostFactor(NewEye,OldEye,OtherEye) ;
		write(l_out,CalcGF) ;
		GF_OK := Check_GhostFactor(RED_factors(zone),CalcGF) ;
		assert (GF_OK = '1')
			report "RED GhostFactor Error"
			severity error ;
		write(l_out,string'(",")) ;
		OldEye   := to_integer(unsigned(RED_left_in)) ;
		NewEye   := to_integer(unsigned(RED_left_out)) ;
		OtherEye := to_integer(unsigned(RED_right_in)) ;
		CalcGF   := Calc_GhostFactor(NewEye,OldEye,OtherEye) ;
		write(l_out,CalcGF) ;
		GF_OK := Check_GhostFactor(RED_factors(zone),CalcGF) ;
		assert (GF_OK = '1')
			report "RED GhostFactor Error"
			severity error ;
		write(l_out,string'(",")) ;
		write(l_out,to_integer(unsigned(GRN_right_in))) ;
		write(l_out,string'(",")) ;
		write(l_out,to_integer(unsigned(GRN_left_in))) ;
		write(l_out,string'(",")) ;
		write(l_out,GRN_factors(zone)) ;
		write(l_out,string'(",")) ;
		write(l_out,to_integer(unsigned(GRN_right_out))) ;
		write(l_out,string'(",")) ;
		write(l_out,to_integer(unsigned(GRN_left_out))) ;
		write(l_out,string'(",")) ;
		OldEye   := to_integer(unsigned(GRN_right_in)) ;
		NewEye   := to_integer(unsigned(GRN_right_out)) ;
		OtherEye := to_integer(unsigned(GRN_left_in)) ;
		CalcGF   := Calc_GhostFactor(NewEye,OldEye,OtherEye) ;
		write(l_out,CalcGF) ;
		GF_OK := Check_GhostFactor(GRN_factors(zone),CalcGF) ;
		assert (GF_OK = '1')
			report "GREEN GhostFactor Error"
			severity error ;
		write(l_out,string'(",")) ;
		OldEye   := to_integer(unsigned(GRN_left_in)) ;
		NewEye   := to_integer(unsigned(GRN_left_out)) ;
		OtherEye := to_integer(unsigned(GRN_right_in)) ;
		CalcGF   := Calc_GhostFactor(NewEye,OldEye,OtherEye) ;
		write(l_out,CalcGF) ;
		GF_OK := Check_GhostFactor(GRN_factors(zone),CalcGF) ;
		assert (GF_OK = '1')
			report "GREEN GhostFactor Error"
			severity error ;
		write(l_out,string'(",")) ;
		write(l_out,to_integer(unsigned(BLU_right_in))) ;
		write(l_out,string'(",")) ;
		write(l_out,to_integer(unsigned(BLU_left_in))) ;
		write(l_out,string'(",")) ;
		write(l_out,BLU_factors(zone)) ;
		write(l_out,string'(",")) ;
		write(l_out,to_integer(unsigned(BLU_right_out))) ;
		write(l_out,string'(",")) ;
		write(l_out,to_integer(unsigned(BLU_left_out))) ;
		write(l_out,string'(",")) ;
		OldEye   := to_integer(unsigned(BLU_right_in)) ;
		NewEye   := to_integer(unsigned(BLU_right_out)) ;
		OtherEye := to_integer(unsigned(BLU_left_in)) ;
		CalcGF   := Calc_GhostFactor(NewEye,OldEye,OtherEye) ;
		write(l_out,CalcGF) ;
		GF_OK := Check_GhostFactor(BLU_factors(zone),CalcGF) ;
		assert (GF_OK = '1')
			report "BLUE GhostFactor Error"
			severity error ;
		write(l_out,string'(",")) ;
		OldEye   := to_integer(unsigned(BLU_left_in)) ;
		NewEye   := to_integer(unsigned(BLU_left_out)) ;
		OtherEye := to_integer(unsigned(BLU_right_in)) ;
		CalcGF   := Calc_GhostFactor(NewEye,OldEye,OtherEye);
		write(l_out,CalcGF) ;
		GF_OK := Check_GhostFactor(BLU_factors(zone),CalcGF) ;
		assert (GF_OK = '1')
			report "BLUE GhostFactor Error"
			severity error ;
		write(l_out,string'(",")) ;
		writeline(results_file,l_out) ;
	end if ;
	--
	-- if (PixelInputValid'event and PixelInputValid = '0') then
		-- file_close(results_file) ;
	-- end if ;
	--
	end process EvaluatePixeldata ;
	--
-- --
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