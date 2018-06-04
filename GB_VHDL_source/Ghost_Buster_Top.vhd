--*************************************************************
-- Top level of Ghost Buster design for inclusion in server FPGA
--
--*************************************************************
--
--
library IEEE; 
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
--
entity Ghost_Buster_Top is
  port (
	clock         : in std_logic ;
	reset         : in std_logic ;
	byPass        : in std_logic ;
	--
	delay         : out integer   ;
	H_ready       : out std_logic ; -- Horz zone count ready
	V_ready       : out std_logic ; -- Vert zone count ready
	-- Bus interface for Ghost Factor memory access
	data_from_uP  : in std_logic_vector (15 downto 0) ;
	data_to_uP    : out std_logic_vector (15 downto 0) ;
	uP_addr       : in std_logic_vector (7 downto 1)  ; -- word address
	wr_en         : in std_logic ; -- ******* AT LEAST 4~ WIDE ******
	chip_sel      : in std_logic ; -- ******* AT LEAST 4~ WIDE ******
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
end Ghost_Buster_Top ;
--
--
--
architecture struct of Ghost_Buster_Top is
--
  component Ghost_Buster_RGB_16b
	port (
	  clock         : in std_logic ;
	  reset         : in std_logic ;
	  byPass        : in std_logic ;
	  --
	  delay         : out integer   ;
	  H_ready       : out std_logic ; -- Horz zone count ready
	  V_ready       : out std_logic ; -- Vert zone count ready
	  -- 
	  data_in       : in std_logic_vector (15 downto 0) ;
	  data_out      : out std_logic_vector (15 downto 0) ;
	  address       : in std_logic_vector (7 downto 1)  ;
	  wr_en         : in std_logic ;
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
--
--
  --
  signal GB_RED_left_out   : std_logic_vector (15 downto 0) ;
  signal GB_GRN_left_out   : std_logic_vector (15 downto 0) ;
  signal GB_BLU_left_out   : std_logic_vector (15 downto 0) ;
  signal GB_RED_right_out  : std_logic_vector (15 downto 0) ;
  signal GB_GRN_right_out  : std_logic_vector (15 downto 0) ;
  signal GB_BLU_right_out  : std_logic_vector (15 downto 0) ;
  --
  signal GB_act_image_out  : std_logic ;
  signal GB_horz_out       : std_logic ;
  signal GB_vert_out       : std_logic ;
  signal GB_field_out      : std_logic ;
  --
  signal GB_delay          : integer ;
  --
--
--
begin
--
--
  realD_buster: Ghost_Buster_RGB_16b
	port map (
	  clock         => clock ,
	  reset         => reset ,
	  byPass        => byPass ,
	  --
	  delay         => GB_delay ,
	  H_ready       => H_ready ,
	  V_ready       => V_ready ,
	  -- 
	  data_in       => data_from_uP ,
	  data_out      => data_to_uP ,
	  address       => uP_addr(7 downto 1) ,
	  wr_en         => wr_en ,
	  chip_sel      => chip_sel ,
	  --
	  horz_in       => horz_in ,
	  vert_in       => vert_in ,
	  field_in      => field_in ,
	  --
	  RED_left_in   => RED_left_in  ,
	  GRN_left_in   => GRN_left_in  ,
	  BLU_left_in   => BLU_left_in  ,
	  --
	  RED_right_in  => RED_right_in  ,
	  GRN_right_in  => GRN_right_in  ,
	  BLU_right_in  => BLU_right_in  ,
	  --
	  act_image_out => GB_act_image_out ,
	  horz_out      => GB_horz_out ,
	  vert_out      => GB_vert_out ,
	  field_out     => GB_field_out ,
	  --
	  RED_left_out  => GB_RED_left_out  ,
	  GRN_left_out  => GB_GRN_left_out  ,
	  BLU_left_out  => GB_BLU_left_out  ,
	  --
	  RED_right_out => GB_RED_right_out  ,
	  GRN_right_out => GB_GRN_right_out  ,
	  BLU_right_out => GB_BLU_right_out 
	  ) ;
--
--
  delay <= GB_delay + 1 ; -- account for reg_outp process
--
  reg_outp: process (clock, reset)
  begin
	if (reset = '1') then
	  act_image_out <= '0' ;
	  horz_out      <= '0' ;
	  vert_out      <= '0' ;
	  field_out     <= '0' ;
	  --
	  RED_left_out  <= (others => '0') ;
	  GRN_left_out  <= (others => '0') ;
	  BLU_left_out  <= (others => '0') ;
	  --
	  RED_right_out <= (others => '0') ;
	  GRN_right_out <= (others => '0') ;
	  BLU_right_out <= (others => '0') ;
	elsif (clock'event and clock = '1') then
	  act_image_out <= GB_act_image_out ;
	  horz_out      <= GB_horz_out ;
	  vert_out      <= GB_vert_out ;
	  field_out     <= GB_field_out ;
	  --
	  RED_left_out  <= GB_RED_left_out  ;
	  GRN_left_out  <= GB_GRN_left_out  ;
	  BLU_left_out  <= GB_BLU_left_out  ;
	  --
	  RED_right_out <= GB_RED_right_out  ;
	  GRN_right_out <= GB_GRN_right_out  ;
	  BLU_right_out <= GB_BLU_right_out  ;
	end if ;
  end process reg_outp ;
--
--
end struct ;
