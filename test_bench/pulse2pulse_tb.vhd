----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/29/2014 07:39:31 PM
-- Design Name: 
-- Module Name: pulse2pulse_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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
-- any Xilinx leaf cells in this code.
LIBRARY UNISIM;
USE UNISIM.VComponents.ALL;

ENTITY pulse2pulse_tb IS
END pulse2pulse_tb;

ARCHITECTURE Behavioral OF pulse2pulse_tb IS

  COMPONENT pulse2pulse IS
    PORT (
      IN_CLK   : IN  std_logic;
      OUT_CLK  : IN  std_logic;
      RST      : IN  std_logic;
      PULSEIN  : IN  std_logic;
      INBUSY   : OUT std_logic;
      PULSEOUT : OUT std_logic
    );
  END COMPONENT;

  SIGNAL CLK                : std_logic := '0';
  SIGNAL RESET              : std_logic := '0';
  --
  SIGNAL OUT_CLK            : std_logic;
  SIGNAL PULSEIN            : std_logic;
  SIGNAL INBUSY             : std_logic;
  SIGNAL PULSEOUT           : std_logic;

  -- Clock period definitions
  CONSTANT CLK_period               : time := 10 ns;
  CONSTANT CLKOUT_period            : time := 5 ns;

BEGIN
  -- Instantiate the Unit Under Test (UUT)
  uut : pulse2pulse
    PORT MAP (
      IN_CLK   => OUT_CLK,
      OUT_CLK  => OUT_CLK,
      RST      => RESET,
      PULSEIN  => PULSEIN,
      INBUSY   => INBUSY,
      PULSEOUT => PULSEOUT
    );

  -- Clock process definitions
  CLK_process : PROCESS
  BEGIN
    CLK <= '0';
    WAIT FOR CLK_period/2;
    CLK <= '1';
    WAIT FOR CLK_period/2;
  END PROCESS;

  CLKOUT_process : PROCESS
  BEGIN
    OUT_CLK <= '0';
    WAIT FOR CLKOUT_period/2;
    OUT_CLK <= '1';
    WAIT FOR CLKOUT_period/2;
  END PROCESS;

  -- Stimulus process
  stim_proc : PROCESS
  BEGIN
    PULSEIN <= '0';
    -- hold reset state
    RESET      <= '0';
    WAIT FOR 15 ns;
    RESET      <= '1';
    WAIT FOR CLK_period*3;
    RESET      <= '0';
    WAIT FOR CLK_period*5.3;
    --
    PULSEIN <= '1';
    WAIT FOR CLK_period*3;
    PULSEIN <= '0';
    --
    WAIT;
  END PROCESS;

END Behavioral;
