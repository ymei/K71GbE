----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:32:46 08/25/2013 
-- Design Name: 
-- Module Name:    pulsegen - Behavioral 
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
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
LIBRARY UNISIM;
USE UNISIM.VComponents.ALL;

ENTITY pulsegen IS
  GENERIC (
    COUNTER_WIDTH : positive := 32
  );
  PORT (
    CLK    : IN  std_logic;
    PERIOD : IN  std_logic_vector(COUNTER_WIDTH-1 DOWNTO 0);
    I      : IN  std_logic;
    O      : OUT std_logic
  );
END pulsegen;

ARCHITECTURE Behavioral OF pulsegen IS
  SIGNAL counter : unsigned(COUNTER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
BEGIN

  PROCESS (CLK) IS
    VARIABLE zeros : unsigned(COUNTER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  BEGIN
    O <= '0';
    IF I = '1' THEN
      O <= I;
    ELSIF rising_edge(CLK) THEN
      IF unsigned(PERIOD) = zeros THEN
        O <= I;
      ELSE
        counter <= counter + 1;
        O       <= '0';
        IF counter = unsigned(PERIOD)-1 THEN
          O <= '1';
        ELSIF counter >= unsigned(PERIOD) THEN
          O       <= '0';
          counter <= (OTHERS => '0');
        END IF;
      END IF;
    END IF;
  END PROCESS;

END Behavioral;
