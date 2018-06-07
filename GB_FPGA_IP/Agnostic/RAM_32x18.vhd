-- A inferable, true dual-port, single-clock RAM in VHDL.
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
 
entity RAM_32x18 is
port (
	clock   	: in  std_logic ;
	data   		: in  std_logic_vector(17 downto 0);
	rdaddress	: in  std_logic_vector(4 downto 0) ;
	wraddress  	: in  std_logic_vector(4 downto 0) ;
	wren    	: in  std_logic;
	q  			: out std_logic_vector(17 downto 0)
);
end RAM_32x18 ;
 
architecture behave of RAM_32x18 is
    -- Shared memory
    type mem_type is array (31 downto 0 ) of std_logic_vector(17 downto 0);
    shared variable mem : mem_type;
	--
	signal Reg_RdAddress 	: std_logic_vector(4 downto 0) ;
	signal Reg_WrAddress 	: std_logic_vector(4 downto 0) ;
	signal Reg_InData		: std_logic_vector(17 downto 0);
	signal Reg_wren			: std_logic ;
	signal OutData			: std_logic_vector(17 downto 0);
begin
 --
 InRegisters : process (clock) 
 begin
	if (clock'event and clock = '1') then
		Reg_InData 		<= data ;
		Reg_RdAddress	<= rdaddress ;
		Reg_WrAddress	<= wraddress ;
		Reg_wren		<= wren ;
	end if ;
 
 end process InRegisters ;
 --
 --
 MemArray: process(clock) 
 begin
	if (clock'event and clock = '1') then
		if (Reg_wren = '1') then
			mem(conv_integer(Reg_WrAddress)) := Reg_InData ;
		end if ;
		--
		OutData <= mem(conv_integer(Reg_RdAddress)) ;
	end if ;
 
 end process MemArray ;
 --
 --
 OutRegisters: process(clock)
 begin
	if (clock'event and clock = '1') then
		q <= mem(conv_integer(Reg_RdAddress)) ;
	end if ;
 end process OutRegisters ;
--
end behave ;