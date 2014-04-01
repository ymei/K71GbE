----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Yuan Mei
-- 
-- Create Date: 12/13/2013 07:56:40 PM
-- Design Name: 
-- Module Name: global_clock_reset - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
--
-- This module encapsulates the main clock generation and its proepr resetting.
-- It also provides a global reset signal output upon stable clock's pll lock.
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
-- any Xilinx leaf cells in this code.
LIBRARY UNISIM;
USE UNISIM.VComponents.ALL;

ENTITY global_clock_reset IS
  PORT (
    SYS_CLK_P  : IN  std_logic;
    SYS_CLK_N  : IN  std_logic;
    FORCE_RST  : IN  std_logic;
    -- output
    GLOBAL_RST : OUT std_logic;
    SYS_CLK    : OUT std_logic;
    CLK_OUT1   : OUT std_logic;
    CLK_OUT2   : OUT std_logic;
    CLK_OUT3   : OUT std_logic;
    CLK_OUT4   : OUT std_logic
  );
END global_clock_reset;

ARCHITECTURE Behavioral OF global_clock_reset IS

  COMPONENT clockwiz
    PORT (
      -- Clock in ports
      clk_in1  : IN  std_logic;
      -- Clock out ports
      clk_out1 : OUT std_logic;
      clk_out2 : OUT std_logic;
      clk_out3 : OUT std_logic;
      clk_out4 : OUT std_logic;
      -- Status and control signals
      reset    : IN  std_logic;
      locked   : OUT std_logic
    );
  END COMPONENT;
  COMPONENT GlobalResetter
    PORT (
      FORCE_RST   : IN  std_logic;
      CLK         : IN  std_logic;      -- system clock
      DCM_LOCKED  : IN  std_logic;
      CLK_RST     : OUT std_logic;
      GLOBAL_RST  : OUT std_logic
    );
  END COMPONENT;
  -- Signals
  SIGNAL sys_clk_i  : std_logic;
  SIGNAL dcm_locked : std_logic;
  SIGNAL dcm_reset  : std_logic;

BEGIN

  IBUFDS_inst : IBUFDS
    GENERIC MAP (
      DIFF_TERM    => false, -- Differential Termination
      IBUF_LOW_PWR => false, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD   => "DEFAULT"
    )
    PORT MAP (
      O  => sys_clk_i, -- Buffer output
      I  => SYS_CLK_P, -- Diff_p buffer input (connect directly to top-level port)
      IB => SYS_CLK_N  -- Diff_n buffer input (connect directly to top-level port)
    );
  BUFG_inst : BUFG
    PORT MAP (
      I => sys_clk_i,
      O => sys_clk
    );
  --sys_clk <= sys_clk_i;

  clockwiz_inst : clockwiz
    PORT MAP (
      -- Clock in ports
      clk_in1  => sys_clk_i,
      -- Clock out ports  
      clk_out1 => CLK_OUT1,
      clk_out2 => CLK_OUT2,
      clk_out3 => CLK_OUT3,
      clk_out4 => CLK_OUT4,
      -- Status and control signals                
      reset    => dcm_reset,
      locked   => dcm_locked
    );

  globalresetter_inst : GlobalResetter
    PORT MAP (
      FORCE_RST   => FORCE_RST,
      CLK         => sys_clk_i,
      DCM_LOCKED  => dcm_locked,
      CLK_RST     => dcm_reset,
      GLOBAL_RST  => GLOBAL_RST
  );

END Behavioral;
