----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:32:46 01/25/2015
-- Design Name: 
-- Module Name:    clk_fwd - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:    Clock forwarding
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

ENTITY clk_fwd IS
  GENERIC (
    INV : boolean := false
  );
  PORT (
    R : IN  std_logic;
    I : IN  std_logic;
    O : OUT std_logic
  );
END clk_fwd;

ARCHITECTURE Behavioral OF clk_fwd IS
  SIGNAL d1 : std_logic := '1';
  SIGNAL d2 : std_logic := '0';
BEGIN
  d1 <= '1' WHEN INV = false ELSE '0';
  d2 <= '0' WHEN INV = false ELSE '1';
  ODDR_inst : ODDR
    GENERIC MAP (
      DDR_CLK_EDGE => "OPPOSITE_EDGE",
      INIT         => '0',
      SRTYPE       => "ASYNC"
    )
    PORT MAP (
      Q  => O,
      C  => I,
      CE => '1',
      D1 => d1,
      D2 => d2,
      R  => R,
      S  => '0'
    );

END Behavioral;
