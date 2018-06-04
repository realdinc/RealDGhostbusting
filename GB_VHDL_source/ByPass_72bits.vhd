--*************************************************************
--  ByPass_72bit :
--     dual port memory with adjustable read / write offset
--
--     09-18-2008   RWL
--
--*************************************************************
--
--
library IEEE; 
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
--
entity ByPass_72bits is
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
end ByPass_72bits ;
--

architecture behave of ByPass_72bits is
--
--
--
  component dpRAM_32x36
	PORT
	(
		clock	   : IN STD_LOGIC ;
		data	   : IN STD_LOGIC_VECTOR (35 DOWNTO 0);
		rdaddress  : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
		wraddress  : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
		wren	   : IN STD_LOGIC ;
		q		   : OUT STD_LOGIC_VECTOR (35 DOWNTO 0)
	);
end component;
--
--
  signal delay_we       : std_logic ;
  signal wr_addr        : std_logic_vector (4 downto 0) ;
  signal rd_addr        : std_logic_vector (4 downto 0) ;
--
begin
  --
  delay_we      <= not reset ;
--
  --
  -- Write address initialized to delay -1 to account for dpRAM output reg.
  gen_addr: process (clock)
  begin
	if (clock'event and clock = '1') then
	  if (reset = '1') then
		rd_addr <= (others => '0') ;
		wr_addr <= std_logic_vector(to_unsigned(delay-2,5)) ; -- 
	  else
		wr_addr <= std_logic_vector(unsigned(wr_addr)+ 1) ; -- after 500 ps ;
		rd_addr <= std_logic_vector(unsigned(rd_addr)+ 1) ; -- after 500 ps ;
	  end if ;
	end if ;
  end process gen_addr ;
  --
  --
  --
  delay_RAM_a: dpRAM_32x36 PORT MAP
	(
	  clock	     => clock ,
	  data	     => data_in(35 downto 0),
	  rdaddress	 => rd_addr,
	  wraddress	 => wr_addr,
	  wren	     => delay_we,
	  q	         => data_out(35 downto 0)
	  );
  --
  delay_RAM_b: dpRAM_32x36 PORT MAP
	(
	  clock	     => clock ,
	  data	     => data_in(71 downto 36),
	  rdaddress	 => rd_addr,
	  wraddress	 => wr_addr,
	  wren	     => delay_we,
	  q	         => data_out(71 downto 36)
	  );
--
end behave ;
