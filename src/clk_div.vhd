----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:32:46 01/25/2015
-- Design Name: 
-- Module Name:    clk_div - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:    Clock dividing
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

ENTITY clk_div IS
  GENERIC (
    WIDTH : positive := 16;
    PBITS : positive := 4               -- log2(WIDTH)
  );
  PORT (
    RESET   : IN  std_logic;
    CLK     : IN  std_logic;
    DIV     : IN  std_logic_vector(PBITS-1 DOWNTO 0);
    CLK_DIV : OUT std_logic
  );
END clk_div;

ARCHITECTURE Behavioral OF clk_div IS
  SIGNAL cnt : unsigned(WIDTH-1 DOWNTO 0);
BEGIN
  PROCESS (CLK, RESET) IS
  BEGIN
    IF RESET = '1' THEN
      cnt <= (OTHERS => '0');
    ELSIF rising_edge(CLK) THEN
      cnt <= cnt + 1;
    END IF;
  END PROCESS;
  CLK_DIV <= CLK WHEN to_integer(unsigned(DIV)) = 0 ELSE
                  cnt(to_integer(unsigned(DIV))-1);

END Behavioral;
