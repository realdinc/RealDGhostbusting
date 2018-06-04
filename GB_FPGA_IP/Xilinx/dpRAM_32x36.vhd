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
		a    : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
		d    : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
		dpra : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
		clk  : IN STD_LOGIC;
		we   : IN STD_LOGIC;
		qspo : OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
		qdpo : OUT STD_LOGIC_VECTOR(17 DOWNTO 0)
	) ;
	end component ;
	--
	signal UnUsedData : STD_LOGIC_VECTOR(35 DOWNTO 0) ;

begin
--
	ram_1: RAM_32x18
	port map (
		a 		=>  wraddress ,
		d 		=>  data(17 downto 0) ,
		dpra 	=>  rdaddress ,
		clk		=>  clock ,
		we		=>  wren,
		qspo	=>  UnUsedData(17 downto 0),
		qdpo	=> q(17 downto 0)
	) ;
	--
	ram_2: RAM_32x18
	port map (
		a 		=>  wraddress ,
		d 		=>  data(35 downto 18) ,
		dpra 	=>  rdaddress ,
		clk		=>  clock ,
		we		=>  wren,
		qspo	=>  UnUsedData(35 downto 18),
		qdpo	=> q(35 downto 18)
	) ;
end struct ;