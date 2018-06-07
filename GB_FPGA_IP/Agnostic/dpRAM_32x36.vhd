-- Wrapper for Xilinx memory to match ALtera components.


LIBRARY ieee;
USE ieee.std_logic_1164.all;


ENTITY dpRAM_32x36 IS
	PORT
	(
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (35 DOWNTO 0);
		rdaddress	: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
		wraddress	: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
		wren		: IN STD_LOGIC  := '0';
		q			: OUT STD_LOGIC_VECTOR (35 DOWNTO 0)
	);
END dpRAM_32x36;


ARCHITECTURE struct OF dpram_32x36 IS
--
	component RAM_32x18 
	port (
		clock   	: in  std_logic ;
		data   		: in  std_logic_vector(17 downto 0);
		rdaddress	: in  std_logic_vector(4 downto 0) ;
		wraddress  	: in  std_logic_vector(4 downto 0) ;
		wren    	: in  std_logic;
		q  			: out std_logic_vector(17 downto 0)
	) ;
	end component ;
	--

begin
--
	ram_1: RAM_32x18
	port map (
		clock   	=> clock ,
		data   		=> data(17 downto 0) ,
		rdaddress	=> rdaddress ,
		wraddress  	=> wraddress ,
		wren    	=> wren ,
		q  			=> q(17 downto 0)
	) ;
	--
	ram_2: RAM_32x18
	port map (
		clock   	=> clock ,
		data   		=> data(35 downto 18) ,
		rdaddress	=> rdaddress ,
		wraddress  	=> wraddress ,
		wren    	=> wren ,
		q  			=> q(35 downto 18) 
	) ;
end struct ;