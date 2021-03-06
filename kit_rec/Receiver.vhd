----------------------------------------------------------------------------------
-- to check receiver on board with no errors and not a single warning
-- Company: 
-- Engineer: 
-- 
-- Create Date:    02:37:19 03/24/2014 
-- Design Name: 
-- Module Name:    Receiver - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.STD_LOGIC_ARITH.ALL;
	use IEEE.STD_LOGIC_UNSIGNED.ALL;

	entity Receiver is
		 Port ( 
			RXD 	: inout  std_logic;					
			CLK 	: in  std_logic;								
			DBOUT : out std_logic_vector (7 downto 0);
			RDA	: inout std_logic;					
			RD		: in  std_logic;					
			PE		: out std_logic;					
			FE		: out std_logic;					
			OE		: out std_logic;			
			RST		: in  std_logic;
			DBin : in std_logic_vector(10 downto 0) );	
	end Receiver;

	architecture Behavioral of Receiver is

		
		type rstate is (					  
			strIdle,			
			strEightDelay,	
			strGetData,		
			strCheckStop	
		);


			

	constant baudDivide : std_logic_vector(3 downto 0) := "1101";
constant tbauddivide: std_logic_vector(7 downto 0):="11010000"; 	
																								
   signal rdReg	:  std_logic_vector(7 downto 0) := "00000000";			
		signal rdSReg	:  std_logic_vector(9 downto 0) := "0000000000";		
		signal clkDiv	:  std_logic_vector(3 downto 0)	:= "0000";
signal tclkdiv : std_logic_vector(7 downto 0):="00000000";		
		--signal rClkDiv :  std_logic_vector(3 downto 0)	:= "0000";				
		signal ctr	:  std_logic_vector(3 downto 0)	:= "0000";					
		signal rClk	:  std_logic := '1';
      signal tclk :  std_logic:='1';		
		signal dataCtr :  std_logic_vector(3 downto 0)	:= "0000";		
		signal parError:  std_logic;									
		signal frameError: std_logic;									
		signal CE		:  std_logic;
		signal ctRst	:  std_logic := '0';
	   signal rShift	:  std_logic := '0';
		signal dataRST :  std_logic := '0';
		signal dataIncr:  std_logic := '0';
		--constant data: std_logic_vector( 10 downto 0):="10101010100";

		signal strCur	:  rstate	:= strIdle; 						
		signal strNext	:  rstate;									
	begin
		frameError <= not rdSReg(9);
		parError <= not ( rdSReg(8) xor (((rdSReg(0) xor rdSReg(1)) xor (rdSReg(2) xor rdSReg(3))) xor ((rdSReg(4) xor rdSReg(5)) xor (rdSReg(6) xor rdSReg(7)))) );
		--DBOUT <= rdReg;



		--receiver clock generation
		process (CLK, clkDiv)	    						
		begin
				if (Clk = '1' and Clk'event) then
					if (clkDiv = baudDivide) then
					rclk<= not rclk;
						clkDiv <= "0000";
					else
					rclk<= rclk;
						clkDiv <= clkDiv +1;
					end if;
				end if;
			end process;
			
			--transmitter clock generation
			process (CLK, tclkDiv)	    						
		begin
				if (Clk = '1' and Clk'event) then
					if (tclkDiv = tbaudDivide) then
					tclk<= not tclk;
						tclkDiv <= "00000000";
					else
					tclk<= tclk;
						tclkDiv <= tclkDiv +1;
					end if;
				end if;
			end process;

-- transmision of data
process(rclk,rd)
variable count:integer:=0;
begin
if(rclk'event and rclk='1') then
if ((count<11)and rd='1') then
--if (rst='1') then 
--count:=0;
--else
rxd<= DBIN(count);
count:=count + 1;
--end if;
end if;
end if;
end process;


	process(rclk,ctRst)
		begin
				if rClk = '1' and rClk'Event then
					if ctRst = '1' then
						ctr <= "0000";
					else
						ctr <= ctr +1;
					end if;
				end if;
			end process;



		process (rClk,rdreg,RST, RD, CE)
			begin
				if RD = '0' or RST = '1' then
					FE <= '0';
					OE <= '0';
					RDA <= '0';
					PE <= '0';
				elsif rClk = '1' and rClk'event then
					if CE = '1' then
						FE <= frameError;
						OE <= RDA;
						RDA <= '1';	 
						PE <= parError;
						rdReg(7 downto 0) <= rdSReg (7 downto 0);
						Dbout<=rdSReg (7 downto 0);
					end if;				
				end if;
				--Dbout<=rdReg;
			end process;

		
		process (rClk, rShift)
			begin
				if rClk = '1' and rClk'Event then
					if rShift = '1' then
						rdSReg <= (RXD & rdSReg(9 downto 1));
						
					end if;
				end if;
			end process;

		
		process (rClk, dataRST)
			begin
				if (rClk = '1' and rClk'event) then
					if dataRST = '1' then
						dataCtr <= "0000";
					elsif dataIncr = '1' then
						dataCtr <= dataCtr +1;
					end if;
				end if;
			end process;

		
		process (rClk, RST)
			begin
				if rClk = '1' and rClk'Event then
					if RST = '1' then
						strCur <= strIdle;
					else
						strCur <= strNext;
					end if;
				end if;
			end process;
				
		
		
		process (strCur, ctr, RXD, dataCtr, rdSReg, rdReg, RDA)
			begin   
				case strCur is

					when strIdle =>
						dataIncr <= '0';
						rShift <= '0';
						dataRst <= '0';
				      CE <= '0';
						if RXD = '0' then
							ctRst <= '1';
							strNext <= strEightDelay;
						else
							ctRst <= '0';
							strNext <= strIdle;
						end if;
					
					when strEightDelay => 
						dataIncr <= '0';
						rShift <= '0';
						CE <= '0';

						if ctr(2 downto 0) = "111" then
							ctRst <= '1';
								dataRST <= '1';
							strNext <= strGetData;
						else
							ctRst <= '0';
							dataRST <= '0';
							strNext <= strEightDelay;
						end if;
					
					when strGetData =>	
						CE <= '0';
						dataRst <= '0';
						if ctr(3 downto 0) = "1110" then
							ctRst <= '1';
							dataIncr <= '1';
							rShift <= '1';
						else
							ctRst <= '0';
							dataIncr <= '0';
							rShift <= '0';		
						end if;

						if dataCtr = "1010" then
							strNext <= strCheckStop;
						else
							strNext <= strGetData;
						end if;
					
					when strCheckStop =>
						dataIncr <= '0';
						rShift <= '0';
						dataRst <= '0';
						ctRst <= '0';

						CE <= '1';
						strNext <= strIdle;
										
				end case;
			
			end process;			
	end Behavioral;