--------------------------------------------------------------------------------
--! @file edge_sync.vhd
--! @brief capture the edge of a signal.
--! @author Yuan Mei
--!
--! Input signal EI can be in the CLK domain or from another clock domain.
--! If from another clock domain, it has to be high (rising edge) or
--! low (falling edge) longer than 1 CLK cycle.
--! The output SO is synchronized to CLK and is exactly 1 CLK cycle wide.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
LIBRARY UNISIM;
USE UNISIM.VComponents.ALL;

--! A module that captures the edge of a signal EI.
--! If EI is from another clock domain, it has to be high (rising edge) OR
--! low (falling edge) longer than 1 CLK cycle.
--! The output SO is synchronized to CLK and is exactly 1 CLK cycle wide.
ENTITY edge_sync IS
  GENERIC (
    EDGE : std_logic := '1'  --! '1'  :  rising edge,  '0' falling edge
  );
  PORT (
    RESET : IN  std_logic;              --! reset
    CLK   : IN  std_logic;              --! clock
    EI    : IN  std_logic;              --! input signal.
    SO    : OUT std_logic               --! output pulse, 1 CLK cycle wide.
  );
END edge_sync;

ARCHITECTURE Behavioral OF edge_sync IS
  SIGNAL prev  : std_logic;
  SIGNAL prev1 : std_logic;
  SIGNAL prev2 : std_logic;
BEGIN
  PROCESS (CLK, RESET) IS
  BEGIN
    IF RESET = '1' THEN
      prev  <= '0';
      prev1 <= '0';
      prev2 <= '0';
    ELSIF rising_edge(CLK) THEN
      prev  <= EI;
      prev1 <= prev;
      prev2 <= prev1;
    END IF;
  END PROCESS;
  SO <= '1' WHEN ((prev2 = '0' AND prev1 = '1' AND EDGE = '1')  -- rising edge
               OR (prev2 = '1' AND prev1 = '0' AND EDGE = '0')) -- falling edge
        ELSE '0';
  
END Behavioral;
