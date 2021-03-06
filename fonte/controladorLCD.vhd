LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;
USE ieee.numeric_std.ALL;
-- This code displays time in the DE2's LCD Display
-- Key2  resets time
ENTITY controladorLCD IS
PORT(
  reset, clk_50Mhz: IN STD_LOGIC;
  LCD_RS, LCD_E, LCD_ON, RESET_LED: OUT  STD_LOGIC;
  LCD_RW: BUFFER STD_LOGIC;
  DATA_BUS: INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);   
  mem_exp_control_address : in std_LOGIC_VECTOR (11 DOWNTO 0)
 
 
  );
END controladorLCD;

ARCHITECTURE a OF controladorLCD IS
	
TYPE STATE_TYPE IS (HOLD, FUNC_SET, DISPLAY_ON, MODE_SET, WRITE_CHAR1,
WRITE_CHAR2,RETURN_HOME, TOGGLE_E, RESET1, RESET2, 
RESET3, DISPLAY_OFF, DISPLAY_CLEAR);
SIGNAL state, next_command: STATE_TYPE;
SIGNAL DATA_BUS_VALUE: STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL CLK_COUNT_400HZ: STD_LOGIC_VECTOR(19 DOWNTO 0);
SIGNAL CLK_COUNT_10HZ: STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL BCD_SECD0,BCD_SECD1,BCD_MIND0,BCD_MIND1: STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL BCD_HRD0,BCD_HRD1,BCD_TSEC: STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL CLK_400HZ, CLK_10HZ : STD_LOGIC;

SIGNAL BCD_JUNTOS_OP1 : STD_LOGIC_VECTOR(11 DOWNTO 0);
SIGNAL OP1 : std_LOGIC_VECTOR (3 DOWNTO 0);

component bin8bcd is
    port (
        bin:    in  std_logic_vector (7 downto 0);
        bcd:    out std_logic_vector (11 downto 0)
    );
end component;

BEGIN
  LCD_ON <= '1';
  RESET_LED <= NOT RESET;
  
  -- BIDIRECTIONAL TRI STATE LCD DATA BUS
  DATA_BUS <= DATA_BUS_VALUE WHEN LCD_RW = '0' ELSE "ZZZZZZZZ";

  PROCESS
  BEGIN
    WAIT UNTIL CLK_50MHZ'EVENT AND CLK_50MHZ = '1';
	IF RESET = '0' THEN
	  CLK_COUNT_400HZ <= X"00000";
	  CLK_400HZ <= '0';
	ELSE
	  IF CLK_COUNT_400HZ < X"0F424" THEN 
	    CLK_COUNT_400HZ <= CLK_COUNT_400HZ + 1;
	  ELSE
		CLK_COUNT_400HZ <= X"00000";
		CLK_400HZ <= NOT CLK_400HZ;
	  END IF;
    END IF;
  END PROCESS;
  
  PROCESS (CLK_400HZ, reset)
  BEGIN
    IF reset = '0' THEN
	  state <= RESET1;
	  DATA_BUS_VALUE <= X"38";
	  next_command <= RESET2;
	  LCD_E <= '1';
	  LCD_RS <= '0';
	  LCD_RW <= '0';
	ELSIF CLK_400HZ'EVENT AND CLK_400HZ = '1' THEN
-- GENERATE 1/10 SEC CLOCK SIGNAL FOR SECOND COUNT PROCESS
      IF CLK_COUNT_10HZ < 19 THEN
	    CLK_COUNT_10HZ <= CLK_COUNT_10HZ + 1;
	  ELSE
		CLK_COUNT_10HZ <= X"00";
		CLK_10HZ <= NOT CLK_10HZ;
	  END IF;
-- SEND TIME TO LCD			
	  CASE state IS
-- Set Function to 8-bit transfer and 2 line display with 5x8 Font size
-- see Hitachi HD44780 family data sheet for LCD command and timing details
	    WHEN RESET1 =>
	      LCD_E <= '1';
		  LCD_RS <= '0';
		  LCD_RW <= '0';
		  DATA_BUS_VALUE <= X"38";
		  state <= TOGGLE_E;
		  next_command <= RESET2;
		WHEN RESET2 =>
		  LCD_E <= '1';
		  LCD_RS <= '0';
		  LCD_RW <= '0';
	      DATA_BUS_VALUE <= X"38";
		  state <= TOGGLE_E;
		  next_command <= RESET3;
		WHEN RESET3 =>
		  LCD_E <= '1';
		  LCD_RS <= '0';
		  LCD_RW <= '0';
		  DATA_BUS_VALUE <= X"38";
		  state <= TOGGLE_E;
		  next_command <= FUNC_SET;
-- EXTRA STATES ABOVE ARE NEEDED FOR RELIABLE PUSHBUTTON RESET OF LCD
		WHEN FUNC_SET =>
		  LCD_E <= '1';
		  LCD_RS <= '0';
		  LCD_RW <= '0';
		  DATA_BUS_VALUE <= X"38";
		  state <= TOGGLE_E;
		  next_command <= DISPLAY_OFF;
-- Turn off Display and Turn off cursor
		WHEN DISPLAY_OFF =>
		  LCD_E <= '1';
		  LCD_RS <= '0';
		  LCD_RW <= '0';
		  DATA_BUS_VALUE <= X"08";
		  state <= TOGGLE_E;
		  next_command <= DISPLAY_CLEAR;
-- Turn on Display and Turn off cursor
		WHEN DISPLAY_CLEAR =>
		  LCD_E <= '1';
		  LCD_RS <= '0';
		  LCD_RW <= '0';
		  DATA_BUS_VALUE <= X"01";
		  state <= TOGGLE_E;
		  next_command <= DISPLAY_ON;
-- Turn on Display and Turn off cursor
		WHEN DISPLAY_ON =>
		  LCD_E <= '1';
		  LCD_RS <= '0';
		  LCD_RW <= '0';
		  DATA_BUS_VALUE <= X"0C";
		  state <= TOGGLE_E;
		  next_command <= MODE_SET;
-- Set write mode to auto increment address and move cursor to the right
		WHEN MODE_SET =>
		  LCD_E <= '1';
		  LCD_RS <= '0';
		  LCD_RW <= '0';
		  DATA_BUS_VALUE <= X"06";
		  state <= TOGGLE_E;
		  next_command <= WRITE_CHAR1;
-- Write ASCII hex character in first LCD character location
		WHEN WRITE_CHAR1 =>
		  LCD_E <= '1';
		  LCD_RS <= '1';
		  LCD_RW <= '0';
		  DATA_BUS_VALUE <= X"3" & BCD_HRD1;
		  state <= TOGGLE_E;
		  next_command <= WRITE_CHAR2;
-- Write ASCII hex character in second LCD character location
		WHEN WRITE_CHAR2 =>
		  LCD_E <= '1';
		  LCD_RS <= '1';
		  LCD_RW <= '0';
		  DATA_BUS_VALUE <= X"3" & BCD_HRD0;
		  state <= TOGGLE_E;
		  next_command <= RETURN_HOME;
-- Return write address to first character postion
		WHEN RETURN_HOME =>
		  LCD_E <= '1';
		  LCD_RS <= '0';
		  LCD_RW <= '0';
		  DATA_BUS_VALUE <= X"80";
		  state <= TOGGLE_E;
		  next_command <= WRITE_CHAR1;
-- The next two states occur at the end of each command to the LCD
-- Toggle E line - falling edge loads inst/data to LCD controller
		WHEN TOGGLE_E =>
		  LCD_E <= '0';
		  state <= HOLD;
-- Hold LCD inst/data valid after falling edge of E line				
		WHEN HOLD =>
		  state <= next_command;
	  END CASE;
	END IF;
	
	if (to_integer(signed(mem_exp_control_address)) < 5025) then
		OP1 <= "0000";
	else
		OP1 <= "0001";
	end if;
	
  END PROCESS;	
	
  conveter_OP1 : bin8bcd port map ("0000"&OP1, BCD_JUNTOS_OP1);  
  BCD_HRD1 <= BCD_JUNTOS_OP1 (7 downto 4);
  BCD_HRD0 <= BCD_JUNTOS_OP1 (3 downto 0);

  

END a;