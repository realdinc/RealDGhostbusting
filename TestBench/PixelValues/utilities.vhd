-- GhostBuster test utilities
--
library IEEE; 
use IEEE.std_logic_1164.all;
--
package utilities is

  procedure wr_GB_LUT (
	signal wr_addr  : in std_logic_vector (7 downto 0) ;
	signal wr_data  : in std_logic_vector (15 downto 0) ;
	signal addr_bus : out std_logic_vector (7 downto 1) ;
	signal data_bus : out std_logic_vector (15 downto 0) ;
	signal wr_en    : out std_logic ;
	signal chip_sel : out std_logic
	) ;
	--
  function Calc_GhostFactor(NewEye,OldEye,OtherEye : IN integer) return integer ;
  
  function Check_GhostFactor(ExpectedGF,CalculatedGF : IN integer) return std_logic ;

  
end utilities ;
--
package body utilities is
  procedure wr_GB_LUT (
	signal wr_addr  : in std_logic_vector (7 downto 0) ;
	signal wr_data  : in std_logic_vector (15 downto 0) ;
	signal addr_bus : out std_logic_vector (7 downto 1) ;
	signal data_bus : out std_logic_vector (15 downto 0) ;
	signal wr_en    : out std_logic ;
	signal chip_sel : out std_logic
	) is
  begin
	wait for 5 ns ;
	addr_bus <= wr_addr(7 downto 1) ;
	wait for 3 ns ;
	chip_sel <= '1' ;
	wait for 1 ns ;
	wr_en    <= '1' ;
	wait for 7 ns ;
	data_bus <= wr_data ;
	wait for 53 ns ;
	wr_en    <= '0' ;
	chip_sel <= '0' ;
	data_bus <= (others => 'X') ;
	addr_bus <= (others => 'X') ;
  end wr_GB_LUT ;
--
--
function Calc_GhostFactor(NewEye,OldEye,OtherEye : IN integer) return integer is
	variable GhostFactor : integer := 0 ;
	--
	begin
		GhostFactor := (131072 * OldEye) ;
		GhostFactor := GhostFactor - (131072 * NewEye) ;
		--
		if ( OtherEye /= 0) then
			GhostFactor := GhostFactor / OtherEye ;
		end if ;
		return abs(GhostFactor) ;

end Calc_GhostFactor ;
--
--
function Check_GhostFactor(ExpectedGF,CalculatedGF : IN integer) return std_logic is
	variable GF_OK : std_logic := '0' ; -- default not OK
	variable HighLimit : integer ;
	variable LowLimit  : integer ;
	
	begin 
	HighLimit := ExpectedGF + (ExpectedGF/10) ; -- + 10%
	LowLimit  := ExpectedGF - (ExpectedGF/10) ; -- - 10%
	
	if (LowLimit < 0 ) then
		LowLimit := 0 ;
	end if ;
	
	if (CalculatedGF > LowLimit and CalculatedGF < HighLimit) then
		GF_OK := '1' ;
	else
		GF_OK := '0' ;
	end if ;
		
	return (GF_OK) ;
end Check_GhostFactor ;
--
--
end utilities ;
