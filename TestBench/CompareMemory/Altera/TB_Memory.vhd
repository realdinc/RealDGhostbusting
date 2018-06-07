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
entity TB_Memory is

end TB_Memory ;
--
--
architecture test of TB_Memory is
--
--
-- Inferred RAM
COMPONENT RAM_32x18
  PORT (
    clock   	: in  std_logic ;
	data   		: in  std_logic_vector(17 downto 0);
	rdaddress	: in  std_logic_vector(4 downto 0) ;
	wraddress  	: in  std_logic_vector(4 downto 0) ;
	wren    	: in  std_logic;
	q  			: out std_logic_vector(17 downto 0)
  );
END COMPONENT;
--
--
-- Altera FPGA from IP generator
component dpRAM_32x18
	port
	  (
		clock	  : in std_logic ;
		data	  : in std_logic_vector (17 downto 0);
		rdaddress : in std_logic_vector (4 downto 0);
		wraddress : in std_logic_vector (4 downto 0);
		wren	  : in std_logic ;
		q		  : out std_logic_vector (17 downto 0)
		);
end component ;
--
--
  signal clock      	: std_logic ;
  --
  signal uP_data    	: std_logic_vector (17 downto 0 );
  signal check_data 	: std_logic_vector (17 downto 0 );
  signal uP_addr   		: std_logic_vector (4  downto 0) ;
  signal uP_wren   		: std_logic ;
  signal Infer_data_out	: std_logic_vector (17 downto 0 );
  signal IP_data_out	: std_logic_vector (17 downto 0 );
  signal IP_Unused_out	: std_logic_vector (17 downto 0 );
  --
  signal ReadAddr		: std_logic_vector (4  downto 0) ;
  --
   signal LoopCount 		: integer ;
  --
   signal ExpectData		: integer ;
  --
  signal RAM_ready 		: std_logic ;
--
begin
--
--
--
INFER_RAM: RAM_32x18
  PORT MAP(
    clock	  => clock ,
		data	  => uP_data ,
		rdaddress => ReadAddr ,
		wraddress => uP_addr,
		wren	  => uP_wren ,
		q		  => Infer_data_out
  );
  --
  --
  FPGA_IP: dpRAM_32x18
	port map(
		clock	  => clock ,
		data	  => uP_data ,
		rdaddress => ReadAddr ,
		wraddress => uP_addr,
		wren	  => uP_wren ,
		q		  => IP_data_out
	);
--
--
  wr_MEM: process
    variable Test_data : integer ;
    variable Test_addr : integer ;
  begin
	RAM_ready  <= '0' ;
	uP_wren    <= '0' ;
	uP_data    <= (others => '0') ;
	uP_addr    <= (others => '0') ;
	Test_data  := 0 ;
	Test_addr  := 0 ;
	LoopCount  <= 0 ;
	wait for 10 nS ;
	--
	--
	while (Test_data < 262000) loop
		--
		wait until (clock'event and clock = '1') ;
		uP_wren     <= '1' after 2 nS ;
		uP_addr	    <= std_logic_vector(to_unsigned(Test_addr,5)) after 3 nS ;
		uP_data		<= std_logic_vector(to_unsigned(Test_data,18)) after 3 nS ;
		--
		if (LoopCount = 3) then
			RAM_ready  <= '1' ;
		end if ;
		LoopCount  <= LoopCount  + 1  ;
		Test_data  := Test_data  + 63 ;
		Test_addr  := Test_addr  + 1  ;
	end loop ;
	--
	uP_wren    <= '0' after 1 ns ;
	RAM_ready  <= '0' ;
	wait for 10 nS ;
	while (true) loop
		wait for 10 nS ;
	end loop ;
  end process wr_MEM ;
--
--
	rd_MEM: process
	   variable ReadAddress : integer ;
	   variable RdLoopCount : integer ;
	begin
		ReadAddress := 0 ;
		RdLoopCount := 0 ;
		ExpectData  <= 0 ;
		ReadAddr    <= (others => 'X') ;
		wait until (RAM_ready'event and RAM_ready = '1') ;
		while (RAM_ready = '1') loop 
			ReadAddr 	<= std_logic_vector(to_unsigned(ReadAddress,5)) after 3 nS ;
			wait until (clock'event and clock = '1') ;
			--
			ReadAddress := ReadAddress + 1  ;
            RdLoopCount := RdLoopCount + 1 ;
            if (RdLoopCount > 2) then
			     assert (Infer_data_out = IP_data_out)
				    report "Read Mismatch"
				    severity error ;
			--
			     assert (ExpectData = unsigned(IP_data_out))
				    report "IP Data Mismatch"
				    severity error ;
			--
			     assert (unsigned(Infer_data_out) = ExpectData)
				    report "Infer Data Mismatch"
				    severity error ;
			--
			     ExpectData  <= ExpectData + 63  ;
			end if ;
		end loop ;
	end process rd_MEM ;
--
  GEN_CLOCK : process
  begin
	clock <= '0' ;
	wait for 5000 ps ;
	clock <= '1' ;
	wait for 5000 ps ;
  end process GEN_CLOCK ;  
--
end test ;