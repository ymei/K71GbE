--------------------------------------------------------------------------------
--! @file i2c_write_regmap_tb
--! @brief testbench of i2c_write_regmap
--! @author Yuan Mei, 20170819
--!
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY i2c_write_regmap_tb IS
END i2c_write_regmap_tb;

ARCHITECTURE behavior OF i2c_write_regmap_tb IS
  -- Component Declaration for the Unit Under Test (UUT)
  COMPONENT i2c_write_regmap
    GENERIC (
      REGMAP_FNAME        : string;
      INPUT_CLK_FREQENCY  : integer := 100_000_000;
      -- BUS CLK freqency should be divided by multiples of 4 from input frequency
      BUS_CLK_FREQUENCY   : integer := 100_000;
      START_DELAY_CYCLE   : integer := 100_000_000; -- ext_rst to happen # of clk cycles after START
      EXT_RST_WIDTH_CYCLE : integer := 1000;     -- pulse width of ext_rst in clk cycles
      EXT_RST_DELAY_CYCLE : integer := 100_000   -- 1st reg write to happen clk cycles after ext_rst
    );
    PORT (
      CLK       : IN  std_logic;        -- system clock 50Mhz
      RESET     : IN  std_logic;        -- active high reset
      START     : IN  std_logic;  -- rising edge triggers r/w; synchronous to CLK
      EXT_RSTn  : OUT std_logic;        -- active low for resetting the slave
      BUSY      : OUT std_logic;        -- indicates transaction in progress
      ACK_ERROR : OUT std_logic;        -- i2c has unexpected ack
      SDA_in    : IN  std_logic;        -- serial data input from i2c bus
      SDA_out   : OUT std_logic;        -- serial data output to i2c bus
      SDA_t     : OUT std_logic;  -- serial data direction to/from i2c bus, '1' is read-in
      SCL       : OUT std_logic         -- serial clock output to i2c bus
    );
  END COMPONENT;

  --Inputs
  SIGNAL CLK       : std_logic                    := '0';
  SIGNAL RESET     : std_logic                    := '0';
  SIGNAL START     : std_logic                    := '0';
  SIGNAL SDA_in    : std_logic                    := '0';

  --Outputs
  SIGNAL EXT_RSTn  : std_logic;
  SIGNAL BUSY      : std_logic;
  SIGNAL ACK_ERROR : std_logic;
  SIGNAL SDA_out   : std_logic;
  SIGNAL SDA_t     : std_logic;
  SIGNAL SCL       : std_logic;
  SIGNAL RD_DATA0  : std_logic_vector(7 DOWNTO 0);
  SIGNAL RD_DATA1  : std_logic_vector(7 DOWNTO 0);

  -- Clock period definitions
  CONSTANT CLK_period : time := 10 ns;

BEGIN

  -- Instantiate the Unit Under Test (UUT)
  uut : i2c_write_regmap
    GENERIC MAP (
      REGMAP_FNAME        => "../../../../config/Si5324_125MHz_regmap.txt",
      INPUT_CLK_FREQENCY  => 100_000_000,
      BUS_CLK_FREQUENCY   => 25_000_000,
      START_DELAY_CYCLE   => 12,
      EXT_RST_WIDTH_CYCLE => 13,
      EXT_RST_DELAY_CYCLE => 14
    )
    PORT MAP (
      CLK       => CLK,
      RESET     => RESET,
      START     => START,
      EXT_RSTn  => EXT_RSTn,
      BUSY      => BUSY,
      ACK_ERROR => ACK_ERROR,
      SDA_in    => SDA_in,
      SDA_out   => SDA_out,
      SDA_t     => SDA_t,
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
    START   <= '0';
    SDA_in  <= '1';

    -- hold reset state for 100 ns.
    WAIT FOR 10 ns;
    RESET <= '1';
    WAIT FOR 100 ns;
    RESET <= '0';

    -- stimulate START
    WAIT FOR CLK_period * 10;
    START   <= '1';
    WAIT FOR CLK_period * 2;
    START   <= '0';

    WAIT UNTIL (falling_edge(BUSY));
    START   <= '1';
    WAIT FOR CLK_period * 2;
    START   <= '0';

    WAIT UNTIL (falling_edge(BUSY));
    RESET <= '1';
    WAIT FOR CLK_period * 2;
    RESET <= '0';
    
    WAIT;
  END PROCESS;

END;
