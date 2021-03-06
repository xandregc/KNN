LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
--USE IEEE.std_logic_arith.all;
--USE IEEE.std_logic_unsigned.all;
USE IEEE.numeric_std.all;

ENTITY RX IS
PORT(
CLK: IN STD_LOGIC;
RX_LINE: IN STD_LOGIC;
DATA: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
BUSY: OUT STD_LOGIC
);
END RX;

ARCHITECTURE RX_arch OF RX IS
SIGNAL DATAFLL: STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL RX_FLG: STD_LOGIC:='0';
SIGNAL PRSCL: INTEGER RANGE 0 TO 5208:=0;
SIGNAL INDEX: INTEGER RANGE 0 TO 9:=0;
BEGIN
	PROCESS(CLK)
	BEGIN
		IF(CLK'EVENT AND CLK='1') THEN
			IF(RX_FLG='0' AND RX_LINE='0') THEN
				INDEX<=0;
				PRSCL<=0;
				BUSY<='1';
				RX_FLG<='1';
			END IF;
			IF(RX_FLG='1') THEN 
				DATAFLL(INDEX)<=RX_LINE;
				IF(PRSCL<5207) THEN
					PRSCL<=PRSCL+1;
				ELSE
					PRSCL<=0;
				END IF;
				IF(PRSCL=2500) THEN
					IF(INDEX<9) THEN
						INDEX<=INDEX+1;
					ELSE
						IF(DATAFLL(0)='0' AND DATAFLL(9)='1') THEN
							DATA<=DATAFLL(8 DOWNTO 1);
						ELSE
							DATA<=(OTHERS=>'0');
						END IF;
						RX_FLG<='0';
						BUSY<='0';
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;
END RX_arch;