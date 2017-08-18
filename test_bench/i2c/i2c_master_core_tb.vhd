-------------------------------------------------------------------------------
-- Title      : I2C master core module testbench
-- Project    : HFT PXL
-------------------------------------------------------------------------------
-- File       : i2c_master_core_tb.vhd
-- Author     : J. Schambach
-- Company    : University of Texas at Austin
-- Created    : 2013-11-08
-- Last update: 2013-12-02
-- Platform   : Windows, Xilinx ISE / PlanAhead 14.5
-- Target     : Virtex-6 (XC6VLX240T-FF1759)
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: I2C master testbench
-------------------------------------------------------------------------------
-- Copyright (c) 2013
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author        Description
-- 2013-11-08  1.0      jschamba      Created
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY i2c_master_core_tb IS
END i2c_master_core_tb;

ARCHITECTURE behavior OF i2c_master_core_tb IS
  -- Component Declaration for the Unit Under Test (UUT)
  COMPONENT i2c_master_core
    GENERIC(
      INPUT_CLK_FREQENCY : integer := 100_000_000; -- input clock speed from user logic
      -- BUS CLK freqency should be divided by multiples of 4 from input frequency
      BUS_CLK_FREQUENCY  : integer := 100_000      -- speed the i2c bus (SCL) will run at
    );
    PORT (
      CLK       : IN  std_logic;
      RESET     : IN  std_logic;
      ENA       : IN  std_logic;
      ADDR      : IN  std_logic_vector(6 DOWNTO 0);
      RW        : IN  std_logic;
      DATA_WR   : IN  std_logic_vector(7 DOWNTO 0);
      BUSY      : OUT std_logic;
      DATA_RD   : OUT std_logic_vector(7 DOWNTO 0);
      ACK_ERROR : OUT std_logic;
      SDA_in    : IN  std_logic;
      SDA_out   : OUT std_logic;
      SDA_T     : OUT std_logic;
      SCL       : OUT std_logic
    );
  END COMPONENT;

  --Inputs
  SIGNAL CLK     : std_logic                    := '0';
  SIGNAL RESET   : std_logic                    := '0';
  SIGNAL ENA     : std_logic                    := '0';
  SIGNAL ADDR    : std_logic_vector(6 DOWNTO 0) := (OTHERS => '0');
  SIGNAL RW      : std_logic                    := '0';
  SIGNAL DATA_WR : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
  SIGNAL SDA_in  : std_logic                    := '0';

  --Outputs
  SIGNAL BUSY      : std_logic;
  SIGNAL DATA_RD   : std_logic_vector(7 DOWNTO 0);
  SIGNAL ACK_ERROR : std_logic;
  SIGNAL SDA_out   : std_logic;
  SIGNAL SDA_T     : std_logic;
  SIGNAL SCL       : std_logic;

  -- Clock period definitions
  CONSTANT CLK_period : time := 20 ns;

BEGIN

  -- Instantiate the Unit Under Test (UUT)
  uut : i2c_master_core
    GENERIC MAP (
      INPUT_CLK_FREQENCY => 50_000_000,
      BUS_CLK_FREQUENCY  => 12_500_000
    )
    PORT MAP (
      CLK       => CLK,
      RESET     => RESET,
      ENA       => ENA,
      ADDR      => ADDR,
      RW        => RW,
      DATA_WR   => DATA_WR,
      BUSY      => BUSY,
      DATA_RD   => DATA_RD,
      ACK_ERROR => ACK_ERROR,
      SDA_in    => SDA_in,
      SDA_out   => SDA_out,
      SDA_T     => SDA_T,
      SCL       => SCL
    );

  -- Clock process definitions
  CLK_process : PROCESS
  BEGIN
    CLK <= '0';
    WAIT FOR CLK_period/2;
    CLK <= '1';
    WAIT FOR CLK_period/2;
  END PROCESS;

  -- Stimulus process
  stim_proc : PROCESS
  BEGIN
    -- initial values:
    ADDR    <= "1010101";
    RW      <= '0';                      -- write
    DATA_WR <= "10011001";
    SDA_in  <= '0';
    ENA     <= '0';

    -- hold reset state for 100 ns.
    RESET <= '1';
    WAIT FOR 100 ns;
    RESET <= '0';

    WAIT UNTIL (rising_edge(CLK));
    WAIT FOR CLK_period*10;

    -- insert stimulus here

    -- first a write transaction:
    -- Command = 1010101
    -- Data    = 10011001
    ENA <= '1';

    WAIT UNTIL (rising_edge(BUSY));
    WAIT UNTIL (rising_edge(CLK));
    WAIT FOR CLK_period;

    -- next a "read"
    RW <= '1';

    WAIT UNTIL (rising_edge(BUSY));
    WAIT UNTIL (rising_edge(SDA_T));

    -- I2C read: 1101_0110 (0xd6)
    WAIT FOR CLK_period*4;
    SDA_in <= '1';
    WAIT FOR CLK_period*4;
    SDA_in <= '1';
    WAIT FOR CLK_period*4;
    SDA_in <= '0';
    WAIT FOR CLK_period*4;
    SDA_in <= '1';
    WAIT FOR CLK_period*4;
    SDA_in <= '0';
    WAIT FOR CLK_period*4;
    SDA_in <= '1';
    WAIT FOR CLK_period*4;
    SDA_in <= '1';
    WAIT FOR CLK_period*4;
    SDA_in <= '0';
    WAIT FOR CLK_period*4;
    SDA_in <= '0';

    -- another read
    WAIT UNTIL (rising_edge(BUSY));

    WAIT UNTIL (rising_edge(CLK));
    WAIT FOR CLK_period;

    -- finish after this transaction
    ENA <= '0';

    WAIT;
  END PROCESS;

END;
