--------------------------------------------------------------------------------
--! @file utility.vhd
--! @brief Package of utility modules and functions.
--! @author Yuan Mei
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;

PACKAGE utility IS
  COMPONENT uartio
    GENERIC (
      -- tick repetition frequency is (input freq) / (2**COUNTER_WIDTH / DIVISOR)
      COUNTER_WIDTH : positive;
      DIVISOR       : positive
    );
    PORT (
      CLK     : IN  std_logic;
      RESET   : IN  std_logic;
      RX_DATA : OUT std_logic_vector(7 DOWNTO 0);
      RX_RDY  : OUT std_logic;
      TX_DATA : IN  std_logic_vector(7 DOWNTO 0);
      TX_EN   : IN  std_logic;
      TX_RDY  : OUT std_logic;
      -- serial lines
      RX_PIN  : IN  std_logic;
      TX_PIN  : OUT std_logic
    );
  END COMPONENT;
  COMPONENT byte2cmd
    PORT (
      CLK            : IN  std_logic;
      RESET          : IN  std_logic;
      -- byte in
      RX_DATA        : IN  std_logic_vector(7 DOWNTO 0);
      RX_RDY         : IN  std_logic;
      -- cmd out
      CMD_FIFO_Q     : OUT std_logic_vector(35 DOWNTO 0);  --! command fifo data out port
      CMD_FIFO_EMPTY : OUT std_logic;   --! command fifo "emtpy" SIGNAL
      CMD_FIFO_RDCLK : IN  std_logic;
      CMD_FIFO_RDREQ : IN  std_logic    --! command fifo read request
    );
  END COMPONENT;
  COMPONENT channel_sel
    GENERIC (
      CHANNEL_WIDTH : positive := 16;
      INDATA_WIDTH  : positive := 256;
      OUTDATA_WIDTH : positive := 256
    );
    PORT (
      CLK             : IN  std_logic;  --! fifo wrclk
      RESET           : IN  std_logic;
      SEL             : IN  std_logic_vector(7 DOWNTO 0);
      --
      DATA_FIFO_RESET : IN  std_logic;
      --
      INDATA_Q        : IN  std_logic_vector(INDATA_WIDTH-1 DOWNTO 0);
      DATA_FIFO_WREN  : IN  std_logic;
      DATA_FIFO_FULL  : OUT std_logic;
      --
      OUTDATA_FIFO_Q  : OUT std_logic_vector(OUTDATA_WIDTH-1 DOWNTO 0);
      DATA_FIFO_RDEN  : IN  std_logic;
      DATA_FIFO_EMPTY : OUT std_logic
    );
  END COMPONENT;
  COMPONENT channel_avg
    GENERIC (
      NCH            : positive := 16;
      OUTCH_WIDTH    : positive := 16;
      INTERNAL_WIDTH : positive := 32;
      INDATA_WIDTH   : positive := 256;
      OUTDATA_WIDTH  : positive := 256
    );
    PORT (
      RESET     : IN  std_logic;
      CLK       : IN  std_logic;
      -- high 4-bit is offset, 2**(low 4-bit) is number of points to average
      CONFIG    : IN  std_logic_vector(7 DOWNTO 0);
      TRIG      : IN  std_logic;
      INDATA_Q  : IN  std_logic_vector(INDATA_WIDTH-1 DOWNTO 0);
      OUTVALID  : OUT std_logic;
      OUTDATA_Q : OUT std_logic_vector(OUTDATA_WIDTH-1 DOWNTO 0)
    );
  END COMPONENT;
  COMPONENT pulse2pulse
    PORT (
      IN_CLK   : IN  std_logic;
      OUT_CLK  : IN  std_logic;
      RST      : IN  std_logic;
      PULSEIN  : IN  std_logic;
      INBUSY   : OUT std_logic;
      PULSEOUT : OUT std_logic
    );
  END COMPONENT;
  COMPONENT edge_sync IS
    GENERIC (
      EDGE : std_logic := '1'  --! '1'  :  rising edge,  '0' falling edge
    );
    PORT (
      RESET : IN  std_logic;
      CLK   : IN  std_logic;
      EI    : IN  std_logic;
      SO    : OUT std_logic
    );
  END COMPONENT;
  COMPONENT clk_div IS
    GENERIC (
      WIDTH : positive := 16;
      PBITS : positive := 4             --! log2(WIDTH)
    );
    PORT (
      RESET   : IN  std_logic;
      CLK     : IN  std_logic;
      DIV     : IN  std_logic_vector(PBITS-1 DOWNTO 0);
      CLK_DIV : OUT std_logic
    );
  END COMPONENT;
  COMPONENT clk_fwd
    GENERIC (
      INV : boolean := false
    );
    PORT (
      R : IN  std_logic;
      I : IN  std_logic;
      O : OUT std_logic
    );
  END COMPONENT;

  IMPURE FUNCTION version_from_file(filename : IN string) RETURN std_logic_vector;

END PACKAGE utility;

PACKAGE BODY utility IS

  IMPURE FUNCTION version_from_file(filename : IN string) RETURN std_logic_vector IS
--    FILE foo        : text IS IN filename;
    FILE foo        : text OPEN read_mode IS filename;
    VARIABLE xline  : line;
    VARIABLE inStr  : string(1 TO 100);
    VARIABLE i      : integer RANGE 1 TO 100;
    VARIABLE x      : integer                      := 0;
    VARIABLE done   : boolean                      := false;
    VARIABLE good   : boolean;
    VARIABLE smudge : std_logic_vector(1 DOWNTO 0) := "00";
  BEGIN
    readline(foo, xline);
--    FOR i IN 1 TO xline'length LOOP
    FOR i IN inStr'range LOOP
      read(xline, inStr(i), good);
      IF NOT good THEN
        EXIT;
      ELSIF inStr(i) = ':' THEN         -- mark if a range of revisions
        x         := 0;                 -- and report the later one
        smudge(0) := '1';
      ELSIF inStr(i) = 'M' THEN  -- mark if anything is modified from repository
        done      := true;  -- if we see this, it's also the end of the number!
        smudge(1) := '1';
      ELSIF NOT done THEN
        x := 10*x + character'pos(inStr(i))-character'pos('0');
      END IF;
    END LOOP;
    ASSERT false REPORT "version="&inStr SEVERITY note;
    RETURN smudge & std_logic_vector(to_unsigned(x, 14));
  END FUNCTION;

END PACKAGE BODY utility;
