-- This module is intended for power-on resetting, while accepting force reset
-- (i.e. from a button push) to reset both clock generator (DCM) and other
-- components in the design.  It sets CLK_RST high for (CNT_RANGE_HIGH -
-- CLK_RESET_DELAY_CNT) cycles, Then wait for the DCM_LOCKED signal.  It waits
-- for another (CNT_RANGE_HIGH - GBL_RESET_DELAY_CNT) cycles before setting
-- GLOBAL_RST low.  This module will monitor both FORCE_RST and DCM_LOCKED,
-- and go through proper resetting sequence if either condition is triggered.
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
LIBRARY UNISIM;
USE UNISIM.VComponents.ALL;

--  Entity Declaration
ENTITY GlobalResetter IS
  GENERIC (
    CLK_RESET_DELAY_CNT : integer := 10000;
    GBL_RESET_DELAY_CNT : integer := 100;
    CNT_RANGE_HIGH      : integer := 16383
  );
  PORT (
    FORCE_RST   : IN  std_logic;
    CLK         : IN  std_logic;        -- system clock
    DCM_LOCKED  : IN  std_logic;
    CLK_RST     : OUT std_logic;
    GLOBAL_RST  : OUT std_logic
  );
END GlobalResetter;

-- Architecture body
ARCHITECTURE Behavioral OF GlobalResetter IS
  TYPE rstState_type IS (R0, R1, R2, R3, R4);
  SIGNAL rstState : rstState_type;

BEGIN
  rst_sm: PROCESS (CLK, FORCE_RST) IS
    VARIABLE rstCtr : integer RANGE 0 TO CNT_RANGE_HIGH := 0;
  BEGIN  -- PROCESS rst_sm
    IF FORCE_RST = '1' THEN    -- asynchronous reset (active high)
      rstState <= R0;
      rstCtr := 0;
    ELSIF rising_edge(CLK) THEN  -- rising clock edge
      CLK_RST <= '0';
      GLOBAL_RST <= '1';

      CASE rstState IS
        WHEN R0 =>
          CLK_RST <= '1';
          rstCtr := CLK_RESET_DELAY_CNT;
          rstState <= R1;
        WHEN R1 =>
          CLK_RST <= '1';
          IF rstCtr = 0 THEN
            rstState <= R2;
          ELSE
            rstCtr := rstCtr + 1;
          END IF;
        WHEN R2 =>
          rstCtr :=  GBL_RESET_DELAY_CNT;
          IF DCM_LOCKED = '1' THEN
            rstState <= R3;
          END IF;
        WHEN R3 =>
          IF rstCtr = 0 THEN
            rstState <= R4;
          ELSE
            rstCtr := rstCtr + 1;
          END IF;
        WHEN R4 =>
          GLOBAL_RST <= '0';
          IF DCM_LOCKED = '0' THEN
            rstState <= R0;
          END IF;
        WHEN OTHERS =>
          rstState <= R0;
      END CASE;
    END IF;
  END PROCESS rst_sm;
END Behavioral;
