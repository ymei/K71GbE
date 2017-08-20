--------------------------------------------------------------------------------
--! @file i2c_write_regmap
--! @brief As master, write a series of regAddr - data pairs into slave device
--! @author Yuan Mei, 20170819
--!
--! Write is initiated after RESET or by a pulse on START.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_textio.ALL;
USE std.textio.ALL;

ENTITY i2c_write_regmap IS
  GENERIC (
    REGMAP_FNAME        : string;
    INPUT_CLK_FREQENCY  : integer := 100_000_000;
    -- BUS CLK freqency should be divided by multiples of 4 from input frequency
    BUS_CLK_FREQUENCY   : integer := 100_000;
    START_DELAY_CYCLE   : integer := 100_000_000;  -- ext_rst to happen # of clk cycles after START
    EXT_RST_WIDTH_CYCLE : integer := 1000;     -- pulse width of ext_rst in clk cycles
    EXT_RST_DELAY_CYCLE : integer := 100_000   -- 1st reg write to happen clk cycles after ext_rst
  );
  PORT (
    CLK       : IN  std_logic;          -- system clock 50Mhz
    RESET     : IN  std_logic;          -- active high reset
    START     : IN  std_logic;  -- rising edge triggers r/w; synchronous to CLK
    EXT_RSTn  : OUT std_logic;          -- active low for resetting the slave
    BUSY      : OUT std_logic;          -- indicates transaction in progress
    ACK_ERROR : OUT std_logic;          -- i2c has unexpected ack
    SDA_in    : IN  std_logic;          -- serial data input from i2c bus
    SDA_out   : OUT std_logic;          -- serial data output to i2c bus
    SDA_t     : OUT std_logic;  -- serial data direction to/from i2c bus, '1' is read-in
    SCL       : OUT std_logic           -- serial clock output to i2c bus
  );
END i2c_write_regmap;

ARCHITECTURE arch OF i2c_write_regmap IS

  COMPONENT i2c_master
    GENERIC (
      INPUT_CLK_FREQENCY : integer := 100_000_000;
      -- BUS CLK freqency should be divided by multiples of 4 from input frequency
      BUS_CLK_FREQUENCY  : integer := 100_000
    );
    PORT (
      CLK       : IN  std_logic;        -- system clock 50Mhz
      RESET     : IN  std_logic;        -- active high reset
      START     : IN  std_logic;  -- rising edge triggers r/w; synchronous to CLK
      MODE      : IN  std_logic_vector(1 DOWNTO 0);  -- "00" : 1 bytes read or write, "01" : 2 bytes r/w, "10" : 3 bytes write only;
      SL_RW     : IN  std_logic;        -- '0' is write, '1' is read
      SL_ADDR   : IN  std_logic_vector(6 DOWNTO 0);  -- slave addr
      REG_ADDR  : IN  std_logic_vector(7 DOWNTO 0);  -- slave internal reg addr for read and write
      WR_DATA0  : IN  std_logic_vector(7 DOWNTO 0);  -- first data byte to write
      WR_DATA1  : IN  std_logic_vector(7 DOWNTO 0);  -- second data byte to write
      RD_DATA0  : OUT std_logic_vector(7 DOWNTO 0);  -- first data byte read
      RD_DATA1  : OUT std_logic_vector(7 DOWNTO 0);  -- second data byte read
      BUSY      : OUT std_logic;        -- indicates transaction in progress
      ACK_ERROR : OUT std_logic;        -- i2c has unexpected ack
      SDA_in    : IN  std_logic;        -- serial data input from i2c bus
      SDA_out   : OUT std_logic;        -- serial data output to i2c bus
      SDA_t     : OUT std_logic;  -- serial data direction to/from i2c bus, '1' is read-in
      SCL       : OUT std_logic         -- serial clock output to i2c bus
    );
  END COMPONENT;

  -- function for reading regmap from text file.  Doesn't seem to be synthesizable by vivado.
  TYPE addrval_t IS ARRAY (0 TO 2) OF integer;  -- RANGE -2147483648 TO 2147483647;
  TYPE regmap_t IS ARRAY (0 TO 1024) OF addrval_t;
  IMPURE FUNCTION read_regmap_fromfile(fname : IN string) RETURN regmap_t IS
    FILE fp             : text OPEN read_mode IS fname;
    VARIABLE fline      : line;
    VARIABLE cline      : line;
    VARIABLE c          : character;
    VARIABLE regmap     : regmap_t := (OTHERS => (OTHERS => -1));
    VARIABLE regAddr    : integer;
    VARIABLE regVal     : integer;
    VARIABLE regValV    : std_logic_vector(7 DOWNTO 0);
    VARIABLE i, j, k, l : integer;
  BEGIN
    i := 0;
    WHILE (NOT endfile(fp)) LOOP
      readline(fp, fline);
      NEXT WHEN fline(1) = '#';
      k := 0;
      l := 0;
      FOR j IN 1 TO fline'length LOOP  -- fline'range doesn't work
        IF fline(j) = ',' THEN
          k := j;
        END IF;
        IF fline(j) = 'h' THEN
          l := j;
        END IF;
      END LOOP;
      -- [Synth 8-27] allocator not supported: cline     := NEW string'(fline(1 TO k-1));
      read(fline, regAddr);
      -- unsynthesizable: regAddr   := integer'value(fline(1 TO k-1));
      FOR j IN 1 TO 1 LOOP              -- read the comma ','
        read(fline, c);
      END LOOP;
      hread(fline, regValV);
      regVal    := to_integer(unsigned(regValV));
      regmap(i) := addrval_t'(regAddr, regVal);
      i         := i + 1;
    END LOOP;

    ASSERT false REPORT "regmap" SEVERITY note;
    RETURN regmap;
  END FUNCTION read_regmap_fromfile;

  TYPE machine_type IS (S0, S1, S2, S3, S4, S5);
  SIGNAL state : machine_type;          -- state machine

  SIGNAL regmap_Si5324_125MHz : regmap_t := regmap_t'(
    (16#74#, 16#80#, -1),
    (16#68#,   0, 16#74#),
    (16#68#,   1, 16#E4#),
    (16#68#,   2, 16#42#),
    (16#68#,   3, 16#15#),
    (16#68#,   4, 16#92#),
    (16#68#,   5, 16#ED#),
    (16#68#,   6, 16#3F#),
    (16#68#,   7, 16#2A#),
    (16#68#,   8, 16#00#),
    (16#68#,   9, 16#C0#),
    (16#68#,  10, 16#08#),
    (16#68#,  11, 16#40#),
    (16#68#,  19, 16#29#),
    (16#68#,  20, 16#3E#),
    (16#68#,  21, 16#FE#),
    (16#68#,  22, 16#DF#),
    (16#68#,  23, 16#1F#),
    (16#68#,  24, 16#3F#),
    (16#68#,  25, 16#C0#),
    (16#68#,  31, 16#00#),
    (16#68#,  32, 16#00#),
    (16#68#,  33, 16#03#),
    (16#68#,  34, 16#00#),
    (16#68#,  35, 16#00#),
    (16#68#,  36, 16#03#),
    (16#68#,  40, 16#C0#),
    (16#68#,  41, 16#4E#),
    (16#68#,  42, 16#03#),
    (16#68#,  43, 16#00#),
    (16#68#,  44, 16#13#),
    (16#68#,  45, 16#80#),
    (16#68#,  46, 16#00#),
    (16#68#,  47, 16#11#),
    (16#68#,  48, 16#D4#),
    (16#68#,  55, 16#00#),
    (16#68#, 131, 16#1F#),
    (16#68#, 132, 16#02#),
    (16#68#, 137, 16#01#),
    (16#68#, 138, 16#0F#),
    (16#68#, 139, 16#FF#),
    (16#68#, 142, 16#00#),
    (16#68#, 143, 16#00#),
    (16#68#, 136, 16#40#),
    OTHERS => (-1, -1, -1));

  SIGNAL regmap_Si5324_156_25MHz : regmap_t := regmap_t'(
    (16#74#, 16#80#, -1),
    (16#68#,   0, 16#74#),
    (16#68#,   1, 16#E4#),
    (16#68#,   2, 16#52#),
    (16#68#,   3, 16#15#),
    (16#68#,   4, 16#92#),
    (16#68#,   5, 16#ED#),
    (16#68#,   6, 16#3F#),
    (16#68#,   7, 16#2A#),
    (16#68#,   8, 16#00#),
    (16#68#,   9, 16#C0#),
    (16#68#,  10, 16#08#),
    (16#68#,  11, 16#40#),
    (16#68#,  19, 16#29#),
    (16#68#,  20, 16#3E#),
    (16#68#,  21, 16#FE#),
    (16#68#,  22, 16#DF#),
    (16#68#,  23, 16#1F#),
    (16#68#,  24, 16#3F#),
    (16#68#,  25, 16#80#),
    (16#68#,  31, 16#00#),
    (16#68#,  32, 16#00#),
    (16#68#,  33, 16#03#),
    (16#68#,  34, 16#00#),
    (16#68#,  35, 16#00#),
    (16#68#,  36, 16#03#),
    (16#68#,  40, 16#80#),
    (16#68#,  41, 16#4E#),
    (16#68#,  42, 16#03#),
    (16#68#,  43, 16#00#),
    (16#68#,  44, 16#13#),
    (16#68#,  45, 16#80#),
    (16#68#,  46, 16#00#),
    (16#68#,  47, 16#0E#),
    (16#68#,  48, 16#43#),
    (16#68#,  55, 16#00#),
    (16#68#, 131, 16#1F#),
    (16#68#, 132, 16#02#),
    (16#68#, 137, 16#01#),
    (16#68#, 138, 16#0F#),
    (16#68#, 139, 16#FF#),
    (16#68#, 142, 16#00#),
    (16#68#, 143, 16#00#),
    (16#68#, 136, 16#40#),
    OTHERS => (-1, -1, -1));

  SIGNAL regmap     : regmap_t := regmap_Si5324_125MHz;
  -- SIGNAL regmap     : regmap_t := read_regmap_fromfile(REGMAP_FNAME);  
  SIGNAL addrval    : addrval_t;
  SIGNAL i2cStart   : std_logic;
  SIGNAL i2cBusy    : std_logic;
  SIGNAL i2cMode    : std_logic_vector(1 DOWNTO 0);
  SIGNAL i2cSlAddr  : std_logic_vector(6 DOWNTO 0);
  SIGNAL i2cRegAddr : std_logic_vector(7 DOWNTO 0);
  SIGNAL i2cRegVal  : std_logic_vector(7 DOWNTO 0);

BEGIN

  i2c_master_inst : i2c_master
    GENERIC MAP (
      INPUT_CLK_FREQENCY => INPUT_CLK_FREQENCY,
      BUS_CLK_FREQUENCY  => BUS_CLK_FREQUENCY
    )
    PORT MAP (
      CLK       => CLK,
      RESET     => RESET,
      START     => i2cStart,
      MODE      => i2cMode,
      SL_RW     => '0',
      SL_ADDR   => i2cSlAddr,
      REG_ADDR  => i2cRegAddr,
      WR_DATA0  => i2cRegVal,
      WR_DATA1  => (OTHERS => '0'),
      RD_DATA0  => OPEN,
      RD_DATA1  => OPEN,
      BUSY      => i2cBusy,
      ACK_ERROR => ACK_ERROR,
      SDA_in    => SDA_in,
      SDA_out   => SDA_out,
      SDA_t     => SDA_t,
      SCL       => SCL
    );
  
  PROCESS (CLK, RESET) IS
    VARIABLE cnt : integer;
    VARIABLE i   : integer;
  BEGIN
    IF RESET = '1' THEN
      state    <= S1;
      EXT_RSTn <= '1';
      cnt      := 2;
      BUSY     <= '1';
      i2cStart <= '0';
    ELSIF rising_edge(CLK) THEN
      EXT_RSTn <= '1';
      i2cStart <= '0';
      CASE state IS
        WHEN S0 =>
          state <= S0;
          cnt   := 2;
          BUSY  <= '0';
          IF START = '1' THEN
            BUSY  <= '1';
            state <= S1;
          END IF;
        WHEN S1 =>
          state <= S1;
          BUSY  <= '1';
          cnt   := cnt + 1;
          IF cnt > START_DELAY_CYCLE THEN
            state <= S2;
          END IF;
        WHEN S2 =>
          state    <= S2;
          EXT_RSTn <= '0';
          cnt      := cnt + 1;
          IF cnt > START_DELAY_CYCLE + EXT_RST_WIDTH_CYCLE THEN
            state <= S3;
          END IF;
        WHEN S3 =>
          state <= S3;
          cnt   := cnt + 1;
          IF cnt > START_DELAY_CYCLE + EXT_RST_WIDTH_CYCLE + EXT_RST_DELAY_CYCLE THEN
            i       := 0;
            addrval <= regmap(i);
            state   <= S4;
          END IF;
        WHEN S4 =>
          state <= S4;
          IF i2cBusy = '0' THEN
            i2cSlAddr  <= std_logic_vector(to_unsigned(addrval(0), i2cSlAddr'length));
            i2cRegAddr <= std_logic_vector(to_unsigned(addrval(1), i2cRegAddr'length));
            i2cRegVal  <= std_logic_vector(to_unsigned(addrval(2), i2cRegVal'length));
            IF addrval(2) < 0 THEN
              i2cMode <= "00";
            ELSE
              i2cMode <= "01";
            END IF;
            IF addrval(0) < 0 THEN
              state <= S0;
            ELSE
              i2cStart <= '1';
              state    <= S5;
            END IF;
          END IF;
        WHEN S5 =>
          state   <= S4;
          i       := i + 1;
          addrval <= regmap(i);

        WHEN OTHERS =>
          state <= S0;
      END CASE;
    END IF;
  END PROCESS;

END arch;
