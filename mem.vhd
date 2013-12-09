-- Import logic primitives
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity mem is
port(GPIO: inout std_LOGIC_vector(0 to 3);
HEX5, HEX7, HEX3, HEX1, HEX2, HEX4, HEX6: OUT STD_LOGIC_VECTOR(0 TO 6);
clock_50 : in std_logic;
sram_addr : out std_LOGIC_VECTOR(19 downto 0);
sram_dq : inout std_LOGIC_VECTOR(15 downto 0);
sraM_OE_N, sraM_WE_N, sraM_CE_N, sraM_LB_N, sraM_UB_N : buffer std_logic;
ledg: out std_LOGIC_VECTOR(3 downto 0));
end mem;

architecture rtl of mem is
component altera_UP_sram is
PORT (
	-- Inputs
	clk				:IN		STD_LOGIC;
	address			:IN		STD_LOGIC_VECTOR(19 DOWNTO  0);
	byteenable		:IN		STD_LOGIC_VECTOR( 1 DOWNTO  0);	
	read				:IN		STD_LOGIC;
	write				:IN		STD_LOGIC;
	writedata		:IN		STD_LOGIC_VECTOR(15 DOWNTO  0);	

	-- Bi-Directional
	SRAM_DQ			:INOUT	STD_LOGIC_VECTOR(15 DOWNTO  0);	-- SRAM Data bus 16 Bits

	-- Outputs
	readdata			:BUFFER	STD_LOGIC_VECTOR(15 DOWNTO  0);	
	readdatavalid	:BUFFER	STD_LOGIC;

	SRAM_ADDR		:BUFFER	STD_LOGIC_VECTOR(19 DOWNTO  0);	-- SRAM Address bus 18 Bits

	SRAM_LB_N		:BUFFER	STD_LOGIC;								-- SRAM Low-byte Data Mask 
	SRAM_UB_N		:BUFFER	STD_LOGIC;								-- SRAM High-byte Data Mask 
	SRAM_CE_N		:BUFFER	STD_LOGIC;								-- SRAM Chip chipselect
	SRAM_OE_N		:BUFFER	STD_LOGIC;								-- SRAM Output chipselect
	SRAM_WE_N		:BUFFER	STD_LOGIC								-- SRAM Write chipselect

);
end comPONENT;
		signal forward, backward, rightturn, leftturn: std_logic:= '0';
		SIGNAL counter : INTEGER RANGE 0 TO 10000000 := 0;
		signal instruction: std_LOGIC_VECTOR (19 downto 0):= "00000000000000000000";
		signal address : std_LOGIC_VECTOR(19 downto 0):= "00000000000000000000";
		signal byteenable : std_LOGIC_VECTOR(1 downto 0):= "01";
		signal readdata, writedata : std_LOGIC_VECTOR(15 downto 0):="0000000000000000";
		signal is_read, is_write, readdatavalid : std_LOGIC:= '0';
		signal des_A, Source_A1, Source_A2 : std_LOGIC_VECTOR(4 downto 0):="00000";
		signal Source_A_D : std_LOGIC_VECTOR(2 downto 0):= "000";
		signal reset, playit, rememberit : std_logic:= '0';
		type count_state is (remember, play); --name of the states
		SIGNAL present_state, next_state : count_state;
		attribute syn_encoding : string;
		attribute syn_encoding of count_state: type is "0 1"; --encode the states

begin
	--reset <= ;
	--playit <= ;
	--rememberit <=;
	
PROCESS(CLOCK_50, counter, rememberit, playit)
BEGIN
IF(rising_edge(clocK_50)) THEN
	counter <= counter + 1;
	if(rememberit='1' or playit='1') then 
		counter<=0;
		instruction<= "00000000000000000000";
	end if;
	if (counter = 10000000) then
			instruction <= std_logic_vector(unsigned(instruction) + 1);
			ledg(3 downto 0)<=instruction(3 downto 0);
	end if;
  END IF;
END PROCESS;
	
	
	
	process(playit, rememberit)
	begin
		if (rising_edge(playit)) then
		present_state <= play;
		elsif (rising_edge(rememberit)) then
		present_state <= remember;
		end if;
	end process;

--signal mapping for sram
mem1: altera_UP_sram port map(
clk=>clock_50,
address=>address,
byteenable=>byteenable,
read=>is_read,
write => is_write,
writedata => writedata,
sram_dq => sram_dq,
readdata => readdata,
readdatavalid => readdatavalid,
sram_addr => sram_addr,
SRAM_LB_N => SRAM_LB_N,
SRAM_UB_N => SRAM_UB_N,
SRAM_CE_N => SRAM_CE_N,
SRAM_OE_N => SRAM_OE_N,
SRAM_WE_N => SRAM_WE_N);




--defining each state
	process(present_state, instruction, forward, counter, backward, leftturn, rightturn) --process when present_state
	begin
		case present_state is
			when remember =>
				--forward<= '1';
				--	backward<= ;
				--	rightturn<= ;
				--	leftturn<= ;
				
				is_read<= '0';
				is_write<= '1';
				if (counter = 10000000 and forward = '1') then			--forward:001
				address<= instruction;
				writedata<= "0000000000000" & "001";
				elsif (counter = 10000000 and backward = '1') then		--back:010
				address<= instruction;
				writedata<= "0000000000000" & "010";
				elsif (counter = 10000000 and rightturn = '1') then	--right:011
				address<= instruction;
				writedata<= "0000000000000" & "011";
				elsif (counter = 10000000 and leftturn = '1') then	 	--left:100
				address<= instruction;
				writedata<= "0000000000000" & "100";
				else 																	--stop:000
				address<= instruction;
				writedata<= "0000000000000" & "000";
				end if;
				
			when play =>
				is_read<= '1';
				is_write<= '0';
				address<=instruction;
				Source_A_D<=readdata(2 downto 0);
				if Source_A_D = "000" then
					forward<= '0';
					backward<= '0';
					rightturn<= '0';
					leftturn<= '0';
				elsif Source_A_D = "001" then
					forward<= '1';
					backward<= '0';
					rightturn<= '0';
					leftturn<= '0';
				elsif Source_A_D = "010" then
					forward<= '0';
					backward<= '1';
					rightturn<= '0';
					leftturn<= '0';
				elsif Source_A_D = "011" then
					forward<= '0';
					backward<= '0';
					rightturn<= '1';
					leftturn<= '0';
				elsif Source_A_D = "100" then
					forward<= '0';
					backward<= '0';
					rightturn<= '0';
					leftturn<= '1';
				else
					forward<= '0';
					backward<= '0';
					rightturn<= '0';
					leftturn<= '0';
				end if;
		end case;

	end process;
	process(forward, backward, leftturn, rightturn)
begin
if forward = '1' then
GPIO(0 to 3)<= "1010";
HEX1 <= "0110000"; --display AdvAncE
HEX5 <= "1100011";
HEX4 <= "0001000";
HEX2 <= "1110010";
HEX3 <= "1101010";
HEX6 <= "1000010";
HEX7 <= "0001000";
elsif backward = '1' then
GPIO(0 to 3)<= "0101";
HEX1 <= "1111111";
HEX5 <= "1100011"; --display InvErt
HEX4 <= "0110000";
HEX2 <= "1110000";
HEX3 <= "1111010";
HEX6 <= "1101010";
HEX7 <= "1001111";
elsif leftturn = '1' then
GPIO(0 to 3)<= "1000";
HEX3 <= "1111111";
HEX2 <= "1111111";
HEX1 <= "1111111";
HEX5 <= "0111000"; --display LEFt
HEX4 <= "1110000";
HEX6 <= "0110000";
HEX7 <= "1110001";
elsif rightturn = '1' then
GPIO(0 to 3)<= "0010";
HEX2 <= "1111111";
HEX1 <= "1111111";
HEX3 <= "1110000";
HEX5 <= "0100000"; --display rIGHt
HEX4 <= "1001000";
HEX6 <= "1001111";
HEX7 <= "1111010";
else
GPIO(0 to 3)<= "0000"; 
HEX3 <= "1111111";
HEX2 <= "1111111";
HEX1 <= "1111111";
HEX5 <= "0000001"; --display StOP
HEX4 <= "0011000";
HEX6 <= "1110000";
HEX7 <= "0100100";
end if;
end process;
end rtl;

