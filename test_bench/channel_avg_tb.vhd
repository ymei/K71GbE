----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/29/2014 07:39:31 PM
-- Design Name: 
-- Module Name: channel_avg_tb - Behavioral
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

ENTITY channel_avg_tb IS
END channel_avg_tb;

ARCHITECTURE Behavioral OF channel_avg_tb IS

  COMPONENT channel_avg IS
    PORT (
      RESET     : IN  std_logic;
      CLK       : IN  std_logic;
      CONFIG    : IN  std_logic_vector(7 DOWNTO 0);
      TRIG      : IN  std_logic;
      INDATA_Q  : IN  std_logic_vector(256-1 DOWNTO 0);
      OUTVALID  : OUT std_logic;
      OUTDATA_Q : OUT std_logic_vector(256-1 DOWNTO 0)
    );
  END COMPONENT;

  SIGNAL   RESET         : std_logic := '0';
  SIGNAL   CLK           : std_logic := '0';
  --
  SIGNAL   CONFIG        : std_logic_vector(7 DOWNTO 0) := x"94";
  SIGNAL   TRIG          : std_logic := '0';
  SIGNAL   INDATA_Q      : std_logic_vector(256-1 DOWNTO 0);
  SIGNAL   OUTVALID      : std_logic;
  SIGNAL   OUTDATA_Q     : std_logic_vector(256-1 DOWNTO 0);
  --
  SIGNAL   ch_val        : signed(13 DOWNTO 0) := (OTHERS => '0');
  -- Clock period definitions
  CONSTANT CLK_period    : time      := 10 ns;
  CONSTANT CLKOUT_period : time      := 5 ns;

BEGIN
  -- Instantiate the Unit Under Test (UUT)
  uut : channel_avg
    PORT MAP (
      RESET     => RESET,
      CLK       => CLK,
      CONFIG    => CONFIG,
      TRIG      => TRIG,
      INDATA_Q  => INDATA_Q,
      OUTVALID  => OUTVALID,
      OUTDATA_Q => OUTDATA_Q
    );

  -- Clock process definitions
  CLK_process : PROCESS
  BEGIN
    CLK <= '0';
    WAIT FOR CLK_period/2;
    CLK <= '1';
    WAIT FOR CLK_period/2;
  END PROCESS;

  PROCESS (CLK, RESET) IS
    VARIABLE i : integer;
  BEGIN
    IF RESET = '1' THEN
      ch_val <= to_signed(-128, ch_val'length);
    ELSIF rising_edge(CLK) THEN
      ch_val <= ch_val + 1;
    END IF;
    FOR i IN 0 TO 15 LOOP
      INDATA_Q(i*16+15 DOWNTO i*16+2) <= std_logic_vector(ch_val);
      INDATA_Q(i*16+1 DOWNTO i*16)    <= "00";
    END LOOP;
  END PROCESS;
  
  -- Stimulus process
  stim_proc : PROCESS
  BEGIN
    -- hold reset state
    RESET      <= '0';
    WAIT FOR 15 ns;
    RESET      <= '1';
    WAIT FOR CLK_period*3;
    RESET      <= '0';
    WAIT FOR CLK_period*5.3;
    TRIG       <= '1';
    WAIT FOR CLK_period*5.7;
    TRIG       <= '0';
    --
    --
    WAIT;
  END PROCESS;

END Behavioral;
