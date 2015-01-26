----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/17/2013 07:39:31 PM
-- Design Name: 
-- Module Name: sdram_buffer_fifo_tb - Behavioral
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

ENTITY sdram_buffer_fifo_tb IS
END sdram_buffer_fifo_tb;

ARCHITECTURE Behavioral OF sdram_buffer_fifo_tb IS

  CONSTANT INDATA_WIDTH   : positive := 256;
  CONSTANT OUTDATA_WIDTH  : positive := 32;
  CONSTANT APP_ADDR_WIDTH : positive := 5;
  CONSTANT APP_DATA_WIDTH : positive := 512;
  CONSTANT APP_MASK_WIDTH : positive := 64;
  CONSTANT APP_ADDR_BURST : positive := 2;

  COMPONENT sdram_buffer_fifo IS
    GENERIC (
      INDATA_WIDTH   : positive := 128;
      OUTDATA_WIDTH  : positive := 32;
      APP_ADDR_WIDTH : positive := 28;
      APP_DATA_WIDTH : positive := 512;
      APP_MASK_WIDTH : positive := 64;
      APP_ADDR_BURST : positive := 8
    );
    PORT (
      CLK                : IN  std_logic;  -- MIG UI_CLK
      RESET              : IN  std_logic;
      --
      APP_ADDR           : OUT std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
      APP_CMD            : OUT std_logic_vector(2 DOWNTO 0);
      APP_EN             : OUT std_logic;
      APP_RDY            : IN  std_logic;
      APP_WDF_DATA       : OUT std_logic_vector(APP_DATA_WIDTH-1 DOWNTO 0);
      APP_WDF_END        : OUT std_logic;
      APP_WDF_MASK       : OUT std_logic_vector(APP_MASK_WIDTH-1 DOWNTO 0);
      APP_WDF_WREN       : OUT std_logic;
      APP_WDF_RDY        : IN  std_logic;
      APP_RD_DATA        : IN  std_logic_vector(APP_DATA_WIDTH-1 DOWNTO 0);
      APP_RD_DATA_END    : IN  std_logic;
      APP_RD_DATA_VALID  : IN  std_logic;
      --
      CTRL_RESET         : IN  std_logic;
      WR_START           : IN  std_logic;
      WR_ADDR_BEGIN      : IN  std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
      WR_STOP            : IN  std_logic;
      WR_WRAP_AROUND     : IN  std_logic;
      POST_TRIGGER       : IN  std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
      WR_BUSY            : OUT std_logic;
      WR_POINTER         : OUT std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
      TRIGGER_POINTER    : OUT std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
      WR_WRAPPED         : OUT std_logic;
      RD_START           : IN  std_logic;
      RD_ADDR_BEGIN      : IN  std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
      RD_ADDR_END        : IN  std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
      RD_BUSY            : OUT std_logic;
      --
      DATA_FIFO_RESET    : IN  std_logic;
      INDATA_FIFO_WRCLK  : IN  std_logic;
      INDATA_FIFO_Q      : IN  std_logic_vector(INDATA_WIDTH-1 DOWNTO 0);
      INDATA_FIFO_FULL   : OUT std_logic;
      INDATA_FIFO_WREN   : IN  std_logic;
      --
      OUTDATA_FIFO_RDCLK : IN  std_logic;
      OUTDATA_FIFO_Q     : OUT std_logic_vector(OUTDATA_WIDTH-1 DOWNTO 0);
      OUTDATA_FIFO_EMPTY : OUT std_logic;
      OUTDATA_FIFO_RDEN  : IN  std_logic
    );
  END COMPONENT;

  SIGNAL CLK                : std_logic := '0';
  SIGNAL RESET              : std_logic := '0';
  --
  SIGNAL APP_ADDR           : std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
  SIGNAL APP_CMD            : std_logic_vector(2 DOWNTO 0);
  SIGNAL APP_EN             : std_logic;
  SIGNAL APP_RDY            : std_logic := '0';
  SIGNAL APP_WDF_DATA       : std_logic_vector(APP_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL APP_WDF_END        : std_logic;
  SIGNAL APP_WDF_MASK       : std_logic_vector(APP_MASK_WIDTH-1 DOWNTO 0);
  SIGNAL APP_WDF_WREN       : std_logic;
  SIGNAL APP_WDF_RDY        : std_logic := '0';
  SIGNAL APP_RD_DATA        : std_logic_vector(APP_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL APP_RD_DATA_END    : std_logic;
  SIGNAL APP_RD_DATA_VALID  : std_logic := '0';
  --
  SIGNAL CTRL_RESET         : std_logic := '0';
  SIGNAL WR_START           : std_logic := '0';
  SIGNAL WR_ADDR_BEGIN      : std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
  SIGNAL WR_STOP            : std_logic := '0';
  SIGNAL WR_WRAP_AROUND     : std_logic := '0';
  SIGNAL POST_TRIGGER       : std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL WR_BUSY            : std_logic := '0';
  SIGNAL WR_POINTER         : std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
  SIGNAL TRIGGER_POINTER    : std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
  SIGNAL WR_WRAPPED         : std_logic := '0';
  SIGNAL RD_START           : std_logic := '0';
  SIGNAL RD_ADDR_BEGIN      : std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
  SIGNAL RD_ADDR_END        : std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
  SIGNAL RD_BUSY            : std_logic := '0';
  --
  SIGNAL DATA_FIFO_RESET    : std_logic;
  SIGNAL INDATA_FIFO_WRCLK  : std_logic;
  SIGNAL INDATA_FIFO_Q      : std_logic_vector(INDATA_WIDTH-1 DOWNTO 0);
  SIGNAL INDATA_FIFO_FULL   : std_logic;
  SIGNAL INDATA_FIFO_WREN   : std_logic := '0';
  --
  SIGNAL OUTDATA_FIFO_RDCLK : std_logic;
  SIGNAL OUTDATA_FIFO_Q     : std_logic_vector(OUTDATA_WIDTH-1 DOWNTO 0);
  SIGNAL OUTDATA_FIFO_EMPTY : std_logic := '0';
  SIGNAL OUTDATA_FIFO_RDEN  : std_logic := '0';

  -- Clock period definitions
  CONSTANT CLK_period               : time := 5 ns;
  CONSTANT INDATA_FIFO_WRCLK_period : time := 4 ns;

BEGIN
  -- Instantiate the Unit Under Test (UUT)
  uut : sdram_buffer_fifo
    GENERIC MAP (
      INDATA_WIDTH   => INDATA_WIDTH,
      OUTDATA_WIDTH  => OUTDATA_WIDTH,
      APP_ADDR_WIDTH => APP_ADDR_WIDTH,
      APP_DATA_WIDTH => APP_DATA_WIDTH,
      APP_MASK_WIDTH => APP_MASK_WIDTH,
      APP_ADDR_BURST => APP_ADDR_BURST
    )
    PORT MAP (
      CLK                => CLK,
      RESET              => RESET,
      --
      APP_ADDR           => APP_ADDR,
      APP_CMD            => APP_CMD,
      APP_EN             => APP_EN,
      APP_RDY            => APP_RDY,
      APP_WDF_DATA       => APP_WDF_DATA,
      APP_WDF_END        => APP_WDF_END,
      APP_WDF_MASK       => APP_WDF_MASK,
      APP_WDF_WREN       => APP_WDF_WREN,
      APP_WDF_RDY        => APP_WDF_RDY,
      APP_RD_DATA        => APP_RD_DATA,
      APP_RD_DATA_END    => APP_RD_DATA_END,
      APP_RD_DATA_VALID  => APP_RD_DATA_VALID,
      --
      CTRL_RESET         => CTRL_RESET,
      WR_START           => WR_START,
      WR_ADDR_BEGIN      => WR_ADDR_BEGIN,
      WR_STOP            => WR_STOP,
      WR_WRAP_AROUND     => WR_WRAP_AROUND,
      POST_TRIGGER       => POST_TRIGGER,
      WR_BUSY            => WR_BUSY,
      WR_POINTER         => WR_POINTER,
      TRIGGER_POINTER    => TRIGGER_POINTER,
      WR_WRAPPED         => WR_WRAPPED,
      RD_START           => RD_START,
      RD_ADDR_BEGIN      => RD_ADDR_BEGIN,
      RD_ADDR_END        => RD_ADDR_END,
      RD_BUSY            => RD_BUSY,
      --
      DATA_FIFO_RESET    => DATA_FIFO_RESET,
      INDATA_FIFO_WRCLK  => INDATA_FIFO_WRCLK,
      INDATA_FIFO_Q      => INDATA_FIFO_Q,
      INDATA_FIFO_FULL   => INDATA_FIFO_FULL,
      INDATA_FIFO_WREN   => INDATA_FIFO_WREN,
      --
      OUTDATA_FIFO_RDCLK => OUTDATA_FIFO_RDCLK,
      OUTDATA_FIFO_Q     => OUTDATA_FIFO_Q,
      OUTDATA_FIFO_EMPTY => OUTDATA_FIFO_EMPTY,
      OUTDATA_FIFO_RDEN  => OUTDATA_FIFO_RDEN
    );

  -- Clock process definitions
  CLK_process : PROCESS
  BEGIN
    CLK <= '0';
    WAIT FOR CLK_period/2;
    CLK <= '1';
    WAIT FOR CLK_period/2;
  END PROCESS;

  INDATA_FIFO_WRCLK_process : PROCESS
  BEGIN
    INDATA_FIFO_WRCLK <= '0';
    WAIT FOR INDATA_FIFO_WRCLK_period/2;
    INDATA_FIFO_WRCLK <= '1';
    WAIT FOR INDATA_FIFO_WRCLK_period/2;
  END PROCESS;

  PROCESS (INDATA_FIFO_WRCLK, RESET)
  BEGIN
    IF RESET = '1' THEN
      INDATA_FIFO_Q <= (OTHERS => '0');
    ELSIF rising_edge(INDATA_FIFO_WRCLK) THEN
      INDATA_FIFO_Q <= std_logic_vector(unsigned(INDATA_FIFO_Q) + 1);
    END IF;
  END PROCESS;

  PROCESS (CLK, RESET)
  BEGIN
    IF RESET = '1' THEN
      APP_RD_DATA <= (OTHERS => '0');
    ELSIF rising_edge(CLK) THEN
      APP_RD_DATA <= std_logic_vector(unsigned(APP_RD_DATA) + 1);
    END IF;
  END PROCESS;
  OUTDATA_FIFO_RDEN  <= '0';

  -- Stimulus process
  stim_proc : PROCESS
  BEGIN
    -- hold reset state
    RESET      <= '0';
    WAIT FOR 15 ns;
    RESET      <= '1';
    WAIT FOR CLK_period*3;
    RESET      <= '0';
    WAIT FOR CLK_period*5;
    --
    WAIT FOR CLK_period*5;
    INDATA_FIFO_WREN <= '1';
    --
    WAIT FOR CLK_period*20;
    --
    WR_WRAP_AROUND <= '1';
    WAIT FOR CLK_period*0.8;
    WR_ADDR_BEGIN <= "00010";
    WR_START   <= '1';
    WAIT FOR CLK_period*2.2;
    WR_START   <= '0';
    --
    WAIT FOR CLK_period*2.5;
    APP_RDY     <= '1';
    APP_WDF_RDY <= '1';    
    --
    WAIT FOR CLK_period*5;
    POST_TRIGGER <= "00110";
    WAIT FOR CLK_period*0.8;
    WR_STOP    <= '1';
    WAIT FOR CLK_period*2.2;
    WR_STOP    <= '0';
    --
    APP_WDF_RDY <= '1';
    WAIT FOR CLK_period*14;
    APP_RDY     <= '0';
    WAIT FOR CLK_period*5;
    APP_RDY     <= '0';
    WAIT FOR CLK_period*1;
    APP_RDY     <= '0';
    WAIT FOR CLK_period*1;
    APP_RDY     <= '1';
    --
    WAIT FOR CLK_period*10;
    RD_ADDR_BEGIN <= "00010";
    RD_ADDR_END   <= "01110";
    WAIT FOR CLK_period*5.8;
    RD_START   <= '1';
    WAIT FOR CLK_period*2.2;
    RD_START   <= '0';
    --
    WAIT FOR CLK_period*5;
    APP_RD_DATA_VALID <= '1' AFTER 0.1ns;
    WAIT FOR CLK_period*0.8;
    WR_STOP    <= '1';
    --WR_WRAP_AROUND <= '0';    
    --WR_START   <= '1';
    WAIT FOR CLK_period*2.2;
    WR_STOP    <= '0';
    --WR_START   <= '0';
    APP_RD_DATA_VALID <= '0' AFTER 0.1ns;
    --
    WAIT FOR CLK_period*4;
    APP_RD_DATA_VALID <= '1' AFTER 0.1ns;
    --
    WAIT;
  END PROCESS;

END Behavioral;
