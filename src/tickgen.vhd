----------------------------------------------------------------------------------
-- Company:  LBNL
-- Engineer: Yuan Mei
-- 
-- Create Date: 12/17/2013 07:22:25 PM
-- Design Name: 
-- Module Name: tickgen - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
--
-- This module takes a CLK of frequency f_CLK, then generates a tick output of
-- frequency f_CLK / (2**COUNTER_WIDTH / DIVISOR).  Since the quotient has a
-- limited precision, the output frequency precision is limited.
-- The output local jitter can be as large as half of CLK period.
-- However, it keeps long term average output frequency as stable as the input
-- clock (no accumulation of local jitter).
--
-- The outputs TICK and TICK1CLK are of half repetition period and 1 CLK period
-- width respectively
--
-- Exsample frequencies: assuming f_CLK = 1/(10ns)
-- f_tick (MHz)    COUNTER_WIDTH    DIVISOR    Comment
-- 1.84326         16               1208       Good for 115200 X 16 Baud rate sampling
-- 0.61493                           403                 38400 X 16
-- 0.15411                           101                  9600 X 16
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

ENTITY tickgen IS
  GENERIC (
    -- tick repetition frequency is (input freq) / (2**COUNTER_WIDTH / DIVISOR)
    COUNTER_WIDTH : positive := 16;
    DIVISOR       : positive := 1208
  );
  PORT (
    CLK      : IN  std_logic;
    RESET    : IN  std_logic;
    TICK     : OUT std_logic;           -- output tick of width half repetition period
    TICK1CLK : OUT std_logic            -- output tick of width one CLK period
  );
END tickgen;

ARCHITECTURE Behavioral OF tickgen IS
  SIGNAL counter   : unsigned(COUNTER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL tick_i    : std_logic                          := '0';
  SIGNAL tick_prev : std_logic                          := '0';
BEGIN

  PROCESS (CLK, RESET) IS
  BEGIN
    IF RESET = '1' THEN
      counter   <= (OTHERS => '0');
      tick_prev <= '0';
    ELSIF rising_edge(CLK) THEN
      counter   <= counter + DIVISOR;
      tick_prev <= tick_i;
      TICK1CLK  <= (NOT tick_prev) AND tick_i;
    END IF;
  END PROCESS;
  tick_i <= counter(COUNTER_WIDTH-1);
  TICK   <= tick_i;

END Behavioral;
