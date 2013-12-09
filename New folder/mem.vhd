-- Import logic primitives
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity mem is
port(key: in std_logic_vector(0 downto 0);
	  IRDA_RXD: in std_logic;
GPIO: inout std_LOGIC_vector(0 to 3);
HEX5, HEX7, HEX3, HEX1, HEX2, HEX4, HEX6: OUT STD_LOGIC_VECTOR(0 TO 6);
clock_50 : in std_logic;
sram_addr : out std_LOGIC_VECTOR(19 downto 0);
sram_dq : inout std_LOGIC_VECTOR(15 downto 0);
sraM_OE_N, sraM_WE_N, sraM_CE_N, sraM_LB_N, sraM_UB_N : buffer std_logic;
ledg: out std_LOGIC_VECTOR(7 downto 0));
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
  type countstate is (idle, guidance, dataread);
	signal state : countstate;
	attribute synencoding:    string;
	attribute synencoding of countstate: type is "00 01 10";
	signal idle_count: integer range 0 to 263000;
	signal state_count: integer range 0 to 263000; 
	signal data_count: integer range 0 to 263000;
	
	signal idle_count_flag, state_count_flag, data_count_flag: std_logic;
   signal bitcount: integer range 0 to 33;
	signal forward1, backward1, rightturn1, leftturn1: std_logic:= '0';
	signal odata: std_logic_vector(31 downto 0);
	signal data_buf: std_logic_vector(31 downto 0);
	signal data:  std_logic_vector(31 downto 0);
	signal ready: std_logic;
		signal forward, backward, rightturn, leftturn: std_logic:= '0';
		SIGNAL counter : INTEGER RANGE 0 TO 10000000 := 0;
		signal instruction: std_LOGIC_VECTOR (19 downto 0):= "00000000000000000000";
		signal check: std_LOGIC_VECTOR (19 downto 0):= "00000000000000000000";
		signal address : std_LOGIC_VECTOR(19 downto 0):= "00000000000000000000";
		signal byteenable : std_LOGIC_VECTOR(1 downto 0):= "01";
		signal readdata, writedata : std_LOGIC_VECTOR(15 downto 0):="0000000000000000";
		signal is_read, is_write, readdatavalid : std_LOGIC:= '0';
		signal des_A, Source_A1, Source_A2 : std_LOGIC_VECTOR(4 downto 0):="00000";
		signal Source_A_D : std_LOGIC_VECTOR(2 downto 0):= "000";
		signal playit, re_turnit : std_logic:= '0';
		signal rememberit:std_logic:= '0';
		type count_state is (remember, play, re_turn); --name of the states
		SIGNAL present_state, next_state : count_state;
		attribute synen_coding : string;
		attribute synen_coding of count_state: type is "00 01 10"; --encode the states

begin
	
PROCESS(CLOCK_50, counter, rememberit, playit, odata, re_turnit)
BEGIN
IF(rising_edge(clocK_50)) THEN
	counter <= counter + 1;
	if (odata(23 downto 16) = "00010110") then
	instruction<= "00000000000000000000";
	rememberit<= '0';
	playit<='1';
	re_turnit<='0';
	elsif (odata(23 downto 16) = "00010001") then
	instruction<= "00000000000000000000";
	rememberit<= '1';
	playit<='0';
	re_turnit<='0';
	elsif (odata(23 downto 16) = "00010000") then
	instruction<= "00000000000000000000";
	rememberit<= '0';
	playit<='0';
	re_turnit<='1';
	end if;
	if (counter = 10000000) then
			instruction <= std_logic_vector(unsigned(instruction) + 1);
			ledg(3 downto 0)<=instruction(3 downto 0);
			if (present_state = remember) then
			check <= std_logic_vector(unsigned(check) + 1);
			else 
			check<=check;
			end if;
	end if;
  END IF;
END PROCESS;
	
	
	
	process(playit, rememberit, re_turnit)
	begin
		if (playit ='1') then
		present_state <= play;
		elsif (rememberit ='1') then
		present_state <= remember;
		elsif (re_turnit ='1') then
		present_state <= re_turn;
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

process (key(0),CLOCK_50)
      begin
		 if(rising_edge(CLOCK_50))then
		   if(key(0) = '0')then 
			  idle_count <= 0;
			  else
			    if (idle_count_flag = '1')then 
				   idle_count <= idle_count + 1;
					 else 
					    idle_count <= 0;
				  end if;
			 end if;
		  end if;		
	end process;
--//idle counter switch when IRDA_RXD is low under IDLE state		 
		 	 process (key(0), CLOCK_50)
            begin
       		    if (rising_edge(CLOCK_50))then
					   if (key(0) = '0')then
                    idle_count_flag <= '0';
						  else 
						    if ((state = idle) and (IRDA_RXD = '0'))then
						      idle_count_flag <= '1';
							   else 
							     idle_count_flag <= '0';
							  end if;
						  end if;
						end if;
		 end process;
	--	//state counter works on clk50 under state state only		    
   process (key(0),CLOCK_50)
      begin
		 if(rising_edge(CLOCK_50))then
		   if(key(0) = '0')then 
			  state_count <= 0;
			  else
			    if (state_count_flag = '1')then 
				   state_count <= state_count + 1;
					 else 
					    state_count <= 0;
				  end if;
			 end if;
		  end if;		
	end process;
--//state counter switch when IRDA_RXD is high under GUIdance state		 
		 	 process (key(0), CLOCK_50)
            begin
       		    if (rising_edge(CLOCK_50))then
					   if (key(0) = '0')then
                    state_count_flag <= '0';
						  else 
						    if ((state = guidance) and (IRDA_RXD = '1'))then
						      state_count_flag <= '1';
							   else 
							     state_count_flag <= '0';
							  end if;
						  end if;
						end if;
		 end process;
	--	//data counter works on clk50 under data state only		    
   process (key(0),CLOCK_50)
      begin
		 if(rising_edge(CLOCK_50))then
		   if(key(0) = '0')then 
			  data_count <= 0;
			  else
			    if (data_count_flag = '1')then 
				   data_count <= data_count + 1;
					 else 
					    data_count <= 0;
				  end if;
			 end if;
		  end if;		
	end process;
--//data counter switch when IRDA_RXD is high under DATAREAD state		 
		 	 process (key(0), CLOCK_50)
            begin
       		    if (rising_edge(CLOCK_50))then
					   if (key(0) = '0')then
                    data_count_flag <= '0';
						  else 
						    if ((state = dataread) and (IRDA_RXD = '1'))then
						      data_count_flag <= '1';
							   else 
							     data_count_flag <= '0';
							  end if;
						  end if;
						end if;
		 end process;
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
		 	 process (key(0), CLOCK_50)
            begin
       		    if (rising_edge(CLOCK_50))then
					   if (key(0) = '0')then
                    bitcount <= 0;		
							else
							if(state = dataread)then 
								if(data_count = 20000)then
									bitcount <= bitcount + 1;
								end if;
								else 
											bitcount <= 0;
							
							end if;
						end if;
					end if;
				end process;
				

process(key(0), CLOCK_50)
begin
	if (rising_edge(CLOCK_50)) then
		if (key(0) = '0') then
			state <= idle ;
		else 
			case state is
				when idle => 
					if idle_count > 230000 then
						state <= guidance ;
					end if ;
				when guidance =>
					if state_count > 210000 then
						state <= dataread ;
					end if ;
				when dataread =>
					if data_count > 262143 or bitcount >= 33 then
						state <= idle ;
					end if ;
				when others =>	
						state <= idle ;
			end case ;
		end if ;
	end if ;
end process ;

process(key(0), CLOCK_50)
begin
	if (rising_edge(CLOCK_50)) then
		if (key(0) = '0') then
			data <= (others => '0') ;
		elsif (state = dataread)then
				if data_count >= 41500 then
					data(bitcount - 1) <= '1' ;
					end if;
		else
				data <= (others => '0') ;
		end if ;
	end if ;
end process ;						
						  
process(key(0), CLOCK_50)
begin
	if (rising_edge(CLOCK_50)) then
		if (key(0) = '0') then
			ready <= '0' ;
		else 
			if bitcount = 32 then
				if (data(31 downto 24) = (not data(23 downto 16))) then
					data_buf <= data ;
					ready <= '1' ;
				else
					ready <= '0' ;
				end if ;
			else
				ready <= '0' ;
			end if ;
		end if ;
	end if ;
end process ;

process(key(0), CLOCK_50)
begin
	if rising_edge(CLOCK_50) then
		if key(0) = '0' then
			odata <= (others => '0') ;
		elsif(ready = '1') then
			odata <= data_buf ;
		end if ;
	end if ;
	end process ;

process(odata)		
begin			
if (odata(23 downto 16) = "00000010") then
forward1<= '1';
leftturn1<='0';
rightturn1<='0';
backward1<='0';
elsif (odata(23 downto 16) = "00000100") then
forward1<= '0';
leftturn1<='1';
rightturn1<='0';
backward1<='0';
elsif (odata(23 downto 16) = "00000110") then
forward1<= '0';
leftturn1<='0';
rightturn1<='1';
backward1<='0';
elsif (odata(23 downto 16) = "00001000") then
forward1<= '0';
leftturn1<='0';
rightturn1<='0';
backward1<='1';
else 
forward1<= '0';
leftturn1<='0';
rightturn1<='0';
backward1<='0';
end if;
end process;

--defining each state
	process(present_state, instruction, forward, counter, backward, leftturn, rightturn, forward1, backward1, rightturn1, leftturn1) --process when present_state
	begin
		case present_state is
			when remember =>
					forward<= forward1;
					backward<= backward1;
					rightturn<= rightturn1;
					leftturn<= leftturn1;
				
				is_read<= '0';
				is_write<= '1';
				if (counter = 10000000 and forward = '1') then			--forward:000
				address<= instruction;
				writedata<= "0000000000000" & "000";
				elsif (counter = 10000000 and backward = '1') then		--back:010
				address<= instruction;
				writedata<= "0000000000000" & "010";
				elsif (counter = 10000000 and rightturn = '1') then	--right:011
				address<= instruction;
				writedata<= "0000000000000" & "011";
				elsif (counter = 10000000 and leftturn = '1') then	 	--left:100
				address<= instruction;
				writedata<= "0000000000000" & "100";
				else 																	--stop:001
				address<= instruction;
				writedata<= "0000000000000" & "001";
				end if;
				
			when play =>
				is_read<= '1';
				is_write<= '0';
				if (instruction<=check) then
				address<=instruction;
				Source_A_D<=readdata(2 downto 0);
				if Source_A_D = "001" then
					forward<= '0';
					backward<= '0';
					rightturn<= '0';
					leftturn<= '0';
				elsif Source_A_D = "000" then
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
			else
					forward<= '0';
					backward<= '0';
					rightturn<= '0';
					leftturn<= '0';
				end if;
				
				
				when re_turn =>
				is_read<= '1';
				is_write<= '0';
				if (instruction<=check) then
				address<=instruction;
				Source_A_D<=readdata(2 downto 0);
				if Source_A_D = "001" then
					forward<= '0';
					backward<= '0';
					rightturn<= '0';
					leftturn<= '0';
				elsif Source_A_D = "000" then
					forward<= '0';
					backward<= '1';
					rightturn<= '0';
					leftturn<= '0';
				elsif Source_A_D = "010" then
					forward<= '1';
					backward<= '0';
					rightturn<= '0';
					leftturn<= '0';
				elsif Source_A_D = "011" then
					forward<= '0';
					backward<= '0';
					rightturn<= '0';
					leftturn<= '1';
				elsif Source_A_D = "100" then
					forward<= '0';
					backward<= '0';
					rightturn<= '1';
					leftturn<= '0';
				else
					forward<= '0';
					backward<= '0';
					rightturn<= '0';
					leftturn<= '0';
				end if;
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
