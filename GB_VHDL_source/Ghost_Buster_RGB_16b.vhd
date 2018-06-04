--*************************************************************
-- Top level of Ghost Buster design for inclusion in server FPGA
--
-- ver 1.1 08-Dec-2008 Remove output saturation logic RWL
--*************************************************************
--
--
library IEEE; 
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
--
entity Ghost_Buster_RGB_16b is
  port (
	clock         : in std_logic ;
	reset         : in std_logic ;
	byPass        : in std_logic ;
	--
	delay         : out integer   ;
	H_ready       : out std_logic ; -- Horz zone count ready
	V_ready       : out std_logic ; -- Vert zone count ready
	-- Bus interface for Ghost Factor memory writes
	data_in       : in std_logic_vector (15 downto 0) ;
	data_out      : out std_logic_vector (15 downto 0) ;
	address       : in std_logic_vector (7 downto 1)  ; -- word address
	wr_en         : in std_logic ; -- ******* AT LEAST 4~ WIDE ******
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
end Ghost_Buster_RGB_16b ;
--
--
--
architecture struct of Ghost_Buster_RGB_16b is
--
--
  component deGhost_RGB_8x4
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
  end component ;
--
--
  component ByPass_72bits
	port (
	  clock  : in std_logic ;
	  reset  : in std_logic ;
	  --
	  delay  : in integer   ;
	  --
	  data_in  : in std_logic_vector (71 downto 0) ;
	  --
	  data_out : out std_logic_vector (71 downto 0)
	  ) ;
  end component ;
--
  signal act_image_in     : std_logic ; -- '1' during active video
--
  signal wr_sr            : std_logic_vector (3 downto 0) ;
  signal wr_strb          : std_logic ; -- write Ghost factor RAM
  signal GB_delay         : integer   ;
  signal BYP_delay        : integer   ;
  --
  signal GB_act_image_out  : std_logic ;
  signal GB_horz_out       : std_logic ;
  signal GB_vert_out       : std_logic ;
  signal GB_field_out      : std_logic ;
  --
  signal GB_RED_left_out   : std_logic_vector (15 downto 0) ;
  signal GB_GRN_left_out   : std_logic_vector (15 downto 0) ;
  signal GB_BLU_left_out   : std_logic_vector (15 downto 0) ;
  signal GB_RED_right_out  : std_logic_vector (15 downto 0) ;
  signal GB_GRN_right_out  : std_logic_vector (15 downto 0) ;
  signal GB_BLU_right_out  : std_logic_vector (15 downto 0) ;
  --
  signal SAT_act_image_out  : std_logic ;
  signal SAT_horz_out       : std_logic ;
  signal SAT_vert_out       : std_logic ;
  signal SAT_field_out      : std_logic ;
  --
  signal SAT_RED_left_out   : std_logic_vector (15 downto 0) ;
  signal SAT_GRN_left_out   : std_logic_vector (15 downto 0) ;
  signal SAT_BLU_left_out   : std_logic_vector (15 downto 0) ;
  signal SAT_RED_right_out  : std_logic_vector (15 downto 0) ;
  signal SAT_GRN_right_out  : std_logic_vector (15 downto 0) ;
  signal SAT_BLU_right_out  : std_logic_vector (15 downto 0) ;
  --
  --
  signal BYP_act_image_out : std_logic ;
  signal BYP_horz_out      : std_logic ;
  signal BYP_vert_out      : std_logic ;
  signal BYP_field_out     : std_logic ;
  --
  signal BYP_left_in      : std_logic_vector (71 downto 0) ;
  alias BYP_RED_left_in   : std_logic_vector (15 downto 0) is BYP_left_in(15 downto 0) ;
  alias BYP_GRN_left_in   : std_logic_vector (15 downto 0) is BYP_left_in(31 downto 16);
  alias BYP_BLU_left_in   : std_logic_vector (15 downto 0) is BYP_left_in(47 downto 32);
  alias BYP_horz_left_in  : std_logic is BYP_left_in(48) ;
  alias BYP_vert_left_in  : std_logic is BYP_left_in(49) ;
  alias BYP_field_left_in : std_logic is BYP_left_in(50) ;
  alias BYP_act_left_in   : std_logic is BYP_left_in(51) ;
  --
  signal BYP_right_in      : std_logic_vector (71 downto 0) ;
  alias BYP_RED_right_in   : std_logic_vector (15 downto 0) is BYP_right_in(15 downto 0) ;
  alias BYP_GRN_right_in   : std_logic_vector (15 downto 0) is BYP_right_in(31 downto 16);
  alias BYP_BLU_right_in   : std_logic_vector (15 downto 0) is BYP_right_in(47 downto 32);
  alias BYP_horz_right_in  : std_logic is BYP_right_in(48) ;
  alias BYP_vert_right_in  : std_logic is BYP_right_in(49) ;
  alias BYP_field_right_in : std_logic is BYP_right_in(50) ;
  alias BYP_act_right_in   : std_logic is BYP_right_in(51) ;
  --
  signal BYP_left_out      : std_logic_vector (71 downto 0) ;
  alias BYP_RED_left_out   : std_logic_vector (15 downto 0) is BYP_left_out(15 downto 0) ;
  alias BYP_GRN_left_out   : std_logic_vector (15 downto 0) is BYP_left_out(31 downto 16);
  alias BYP_BLU_left_out   : std_logic_vector (15 downto 0) is BYP_left_out(47 downto 32);
  alias BYP_horz_left_out  : std_logic is BYP_left_out(48) ;
  alias BYP_vert_left_out  : std_logic is BYP_left_out(49) ;
  alias BYP_field_left_out : std_logic is BYP_left_out(50) ;
  alias BYP_act_left_out   : std_logic is BYP_left_out(51) ;
  --
  signal BYP_right_out      : std_logic_vector (71 downto 0) ;
  alias BYP_RED_right_out   : std_logic_vector (15 downto 0) is BYP_right_out(15 downto 0) ;
  alias BYP_GRN_right_out   : std_logic_vector (15 downto 0) is BYP_right_out(31 downto 16);
  alias BYP_BLU_right_out   : std_logic_vector (15 downto 0) is BYP_right_out(47 downto 32);
  alias BYP_horz_right_out  : std_logic is BYP_right_out(48) ;
  alias BYP_vert_right_out  : std_logic is BYP_right_out(49) ;
  alias BYP_field_right_out : std_logic is BYP_right_out(50) ;
  alias BYP_act_right_out   : std_logic is BYP_right_out(51) ;
  --
  signal sync_reset : std_logic ;
  signal rst_SR     : std_logic_vector (3 downto 0) ;
--
--
begin
--
  act_image_in <= horz_in nor vert_in  ;
--
  GB_module: deGhost_RGB_8x4
	port map (
	  clock         => clock ,
	  reset         => sync_reset ,
	  --
	  delay         => GB_delay ,
	  H_ready       => H_ready ,
	  V_ready       => V_ready ,
	  -- Bus interface for Ghost Factor memory writes
	  data_in       => data_in ,
	  data_out      => data_out ,
	  address       => address ,
	  wr_en         => wr_strb ,
	  byPass        => byPass ,
	  --
	  act_image_in  => act_image_in  ,
	  horz_in       => horz_in ,
	  vert_in       => vert_in ,
	  field_in      => field_in ,
	  --
	  RED_left_in   => RED_left_in ,
	  GRN_left_in   => GRN_left_in ,
	  BLU_left_in   => BLU_left_in ,
	  --
	  RED_right_in  => RED_right_in ,
	  GRN_right_in  => GRN_right_in ,
	  BLU_right_in  => BLU_right_in ,
	  --
	  act_image_out => GB_act_image_out ,
	  horz_out      => GB_horz_out ,
	  vert_out      => GB_vert_out ,
	  field_out     => GB_field_out ,
	  --
	  RED_left_out  => GB_RED_left_out ,
	  GRN_left_out  => GB_GRN_left_out ,
	  BLU_left_out  => GB_BLU_left_out ,
	  --
	  RED_right_out => GB_RED_right_out ,
	  GRN_right_out => GB_GRN_right_out ,
	  BLU_right_out => GB_BLU_right_out
	  ) ;
--
--
-- Saturate the output to be between 0x0100 and 0xFEFF
  saturate: process (clock, sync_reset)
  begin
	if (sync_reset = '1') then
	  SAT_act_image_out  <= '0' ;
	  SAT_horz_out       <= '0' ;
	  SAT_vert_out       <= '0' ;
	  SAT_field_out      <= '0' ;
	  SAT_RED_left_out   <= (others=> '0') ;
	  SAT_GRN_left_out   <= (others=> '0') ;
	  SAT_BLU_left_out   <= (others=> '0') ;
	  SAT_RED_right_out  <= (others=> '0') ;
	  SAT_GRN_right_out  <= (others=> '0') ;
	  SAT_BLU_right_out  <= (others=> '0') ;
	elsif (clock'event and clock = '1') then
	  SAT_act_image_out  <= GB_act_image_out ;
	  SAT_horz_out       <= GB_horz_out  ;
	  SAT_vert_out       <= GB_vert_out  ;
	  SAT_field_out      <= GB_field_out ;
	  --
	  SAT_RED_left_out  <= GB_RED_left_out ;
	  SAT_GRN_left_out  <= GB_GRN_left_out ;
	  SAT_BLU_left_out  <= GB_BLU_left_out ;
	  SAT_RED_right_out <= GB_RED_right_out ;
	  SAT_GRN_right_out <= GB_GRN_right_out ;
	  SAT_BLU_right_out <= GB_BLU_right_out ;
	  --
	end if ;
  end process saturate ;
--
  BYP_delay <= GB_delay  + 1  ; -- add for saturation register
  delay     <= GB_delay  + 2  ; -- add for output buffer
--
  BYP_RED_right_in   <= RED_right_in ;
  BYP_GRN_right_in   <= GRN_right_in ;
  BYP_BLU_right_in   <= BLU_right_in ;
  BYP_horz_right_in  <= horz_in ;
  BYP_vert_right_in  <= vert_in ;
  BYP_field_right_in <= field_in ;
  BYP_act_right_in   <= act_image_in ;
  --
  BYP_right: ByPass_72bits
	port map (
	  clock    => clock ,
	  reset    => sync_reset ,
	  --
	  delay    => BYP_delay ,
	  data_in  => BYP_right_in ,
	  data_out => BYP_right_out
	  ) ;
  --
  --
  BYP_RED_left_in   <= RED_left_in ;
  BYP_GRN_left_in   <= GRN_left_in ;
  BYP_BLU_left_in   <= BLU_left_in ;
  BYP_horz_left_in  <= horz_in ;
  BYP_vert_left_in  <= vert_in ;
  BYP_field_left_in <= field_in ;
  BYP_act_left_in   <= act_image_in ;
  --
  BYP_left: ByPass_72bits
	port map (
	  clock    => clock ,
	  reset    => sync_reset ,
	  --
	  delay    => BYP_delay ,
	  data_in  => BYP_left_in ,
	  data_out => BYP_left_out
	  ) ;
--
--
  outp_regs: process (clock, sync_reset)
  begin
	if (sync_reset = '1') then
	  RED_left_out  <= (others => '0') ;
	  GRN_left_out  <= (others => '0') ;
	  BLU_left_out  <= (others => '0') ;
	  --
	  RED_right_out <= (others => '0') ;
	  GRN_right_out <= (others => '0') ;
	  BLU_right_out <= (others => '0') ;
	  --
	  act_image_out <= '0' ;
	  horz_out      <= '0' ;
	  vert_out      <= '0' ;
	  field_out     <= '0' ;
	elsif (clock'event and clock = '1') then
	  if (bypass = '1' or BYP_act_right_out = '0') then
		RED_left_out  <= BYP_RED_left_out ;
		GRN_left_out  <= BYP_GRN_left_out ;
		BLU_left_out  <= BYP_BLU_left_out ;
		--
		RED_right_out <= BYP_RED_right_out ;
		GRN_right_out <= BYP_GRN_right_out ;
		BLU_right_out <= BYP_BLU_right_out ;
		--
		act_image_out <= BYP_act_right_out ;
		horz_out      <= BYP_horz_right_out ;
		vert_out      <= BYP_vert_right_out ;
		field_out     <= BYP_field_right_out ;
	  else
		RED_left_out  <= SAT_RED_left_out ;
		GRN_left_out  <= SAT_GRN_left_out ;
		BLU_left_out  <= SAT_BLU_left_out ;
		--
		RED_right_out <= SAT_RED_right_out ;
		GRN_right_out <= SAT_GRN_right_out ;
		BLU_right_out <= SAT_BLU_right_out ;
		--
		act_image_out <= SAT_act_image_out ;
		horz_out      <= SAT_horz_out ;
		vert_out      <= SAT_vert_out ;
		field_out     <= SAT_field_out ;
	  end if ;
	end if ;
  end process outp_regs ;
--
--
--
--
  gen_write: process (clock, reset)
  begin
	if (reset = '1') then
	  wr_sr   <= (others => '0') ;
	  wr_strb <= '0' ;
	elsif (clock'event and clock = '1') then
	  wr_sr(wr_sr'high downto 1) <= wr_sr(wr_sr'high-1 downto 0) ;
	  wr_sr(0) <= wr_en and chip_sel ;
	  --
	  if (wr_sr = "0011") then
		wr_strb <= '1' ;
	  else
		wr_strb <= '0' ;
	  end if ;
	end if ;
  end process gen_write ;
--
--
  sync_reset <= rst_SR(rst_SR'high) ;
  --
  sync_rst: process (clock, reset)
  begin
	if (reset = '1') then
	  rst_SR     <= (others => '1') ;
	elsif (clock'event and clock = '1') then
	  rst_SR(rst_SR'high downto 1) <= rst_SR(rst_SR'high-1 downto 0) ;
	  rst_SR(0) <= reset ;
	end if ;
  end process sync_rst ;
--
end struct ;
