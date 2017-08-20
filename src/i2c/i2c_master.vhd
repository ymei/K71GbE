--------------------------------------------------------------------------------
--! @file i2c_master
--! @brief As master, read/write up to 2/3 bytes on th i2c bus.
--! @author Dong Wang, 20161009
--!         Yuan Mei, 20170817
--! Read/write is initiated by a pulse on START
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY i2c_master IS
  GENERIC (
    INPUT_CLK_FREQENCY : integer := 100_000_000;
    -- BUS CLK freqency should be divided by multiples of 4 from input frequency
    BUS_CLK_FREQUENCY  : integer := 100_000
  );
  PORT (
    CLK       : IN  std_logic;          -- system clock 50Mhz
    RESET     : IN  std_logic;          -- active high reset
    START     : IN  std_logic;  -- rising edge triggers r/w; synchronous to CLK
    MODE      : IN  std_logic_vector(1 DOWNTO 0);  -- "00" : 1 bytes read or write, "01" : 2 bytes r/w, "10" : 3 bytes write only;
    SL_RW     : IN  std_logic;          -- '0' is write, '1' is read
    SL_ADDR   : IN  std_logic_vector(6 DOWNTO 0);  -- slave addr
    REG_ADDR  : IN  std_logic_vector(7 DOWNTO 0);  -- slave internal reg addr for read and write
    WR_DATA0  : IN  std_logic_vector(7 DOWNTO 0);  -- first data byte to write
    WR_DATA1  : IN  std_logic_vector(7 DOWNTO 0);  -- second data byte to write
    RD_DATA0  : OUT std_logic_vector(7 DOWNTO 0);  -- first data byte read
    RD_DATA1  : OUT std_logic_vector(7 DOWNTO 0);  -- second data byte read
    BUSY      : OUT std_logic;          -- indicates transaction in progress
    ACK_ERROR : OUT std_logic;          -- i2c has unexpected ack
    SDA_in    : IN  std_logic;          -- serial data input from i2c bus
    SDA_out   : OUT std_logic;          -- serial data output to i2c bus
    SDA_t     : OUT std_logic;  -- serial data direction to/from i2c bus, '1' is read-in
    SCL       : OUT std_logic           -- serial clock output to i2c bus
  );
END i2c_master;

ARCHITECTURE arch OF i2c_master IS
  COMPONENT i2c_master_core IS
    GENERIC (
      INPUT_CLK_FREQENCY : integer;
      BUS_CLK_FREQUENCY  : integer
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
      SDA_t     : OUT std_logic;
      SCL       : OUT std_logic
    );
  END COMPONENT i2c_master_core;

  SIGNAL sI2C_enable  : std_logic;
  SIGNAL sI2C_data_wr : std_logic_vector(7 DOWNTO 0);
  SIGNAL sI2C_data_rd : std_logic_vector(7 DOWNTO 0);
  SIGNAL sI2C_busy    : std_logic;
  SIGNAL sBusyCnt     : std_logic_vector(2 DOWNTO 0);
  SIGNAL sBusy_d1     : std_logic;
  SIGNAL sBusy_d2     : std_logic;
  SIGNAL rd_data0_buf : std_logic_vector(7 DOWNTO 0);
  SIGNAL rd_data1_buf : std_logic_vector(7 DOWNTO 0);

  TYPE machine_type IS (StWaitStart,
                        StWr1,
                        StWr2,
                        StWr3,
                        StRd1,
                        StRd2
                      );                -- needed states
  SIGNAL state : machine_type;          -- state machine

BEGIN
  i2c_master_core_inst : i2c_master_core
    GENERIC MAP (
      INPUT_CLK_FREQENCY => INPUT_CLK_FREQENCY,
      BUS_CLK_FREQUENCY  => BUS_CLK_FREQUENCY
    )
    PORT MAP (
      CLK       => CLK,
      RESET     => RESET,
      ENA       => sI2C_enable,
      ADDR      => SL_ADDR,
      RW        => SL_RW,
      DATA_WR   => sI2C_data_wr,
      BUSY      => sI2C_busy,
      DATA_RD   => sI2C_data_rd,
      ACK_ERROR => ACK_ERROR,
      SDA_in    => SDA_in,
      SDA_out   => SDA_out,
      SDA_t     => SDA_t,
      SCL       => SCL
    );

  --busy counter
  busy_d : PROCESS (CLK) IS
  BEGIN
    IF rising_edge(CLK) THEN
      sBusy_d1 <= sI2C_busy;
      sBusy_d2 <= sBusy_d1;
    END IF;
  END PROCESS busy_d;

  busy_counter : PROCESS (CLK, RESET) IS
  BEGIN
    IF RESET = '1' THEN                 -- asynchronous reset (active high)
      sBusyCnt     <= "000";
    ELSIF rising_edge(CLK) THEN
      IF state = StWaitStart THEN
        sBusyCnt     <= "000";
      ELSIF sBusy_d2 = '0' and sBusy_d1 = '1' THEN
        sBusyCnt <= std_logic_vector(unsigned(sBusyCnt) + 1);
      ELSE
        sBusyCnt <= sBusyCnt;
      END IF;
    END IF;
  END PROCESS busy_counter;

  state_machine : PROCESS (CLK, RESET) IS
  BEGIN
    IF RESET = '1' THEN                 -- asynchronous reset (active high)
      sI2C_enable  <= '0';
      sI2C_data_wr <= (OTHERS => '0');
      BUSY         <= '0';
      rd_data0_buf <= (OTHERS => '0');
      rd_data1_buf <= (OTHERS => '0');
      state        <= StWaitStart;

    ELSIF rising_edge(CLK) THEN         -- rising clock edge
      CASE state IS
--      //// Wait for signal to start I2C transaction
        WHEN StWaitStart =>
          sI2C_enable  <= '0';
          sI2C_data_wr <= (OTHERS => '0');
          BUSY         <= '0';
          rd_data0_buf <= rd_data0_buf;
          rd_data1_buf <= rd_data1_buf;
          IF START = '1' THEN
            BUSY <= '1';
            IF SL_RW = '0' THEN         -- write
              IF MODE = "00" THEN       -- 1 byte write (no payload)
                state <= StWr1;
              ELSIF MODE = "01" THEN    -- 2 bytes write (1 byte payload)
                state <= StWr2;
              ELSIF MODE = "10" THEN    -- 3 bytes write (2 byte payload)
                state <= StWr3;
              ELSE
                state <= StWaitStart;
              END IF;
            ELSE
              IF MODE = "00" THEN       -- 1 byte read
                state <= StRd1;
              ELSIF MODE = "01" THEN    -- 2 bytes read
                state <= StRd2;
              ELSE
                state <= StWaitStart;
              END IF;
            END IF;
          ELSE
            state <= StWaitStart;
          END IF;

        -- 1 byte write
        WHEN StWr1 =>
          BUSY <= '1';
          CASE sBusyCnt IS
            WHEN "000" =>
              sI2C_enable  <= '1';
              sI2C_data_wr <= REG_ADDR;
              state        <= StWr1;
            WHEN "001" =>
              sI2C_enable  <= '0';
              sI2C_data_wr <= REG_ADDR;
              IF sI2C_busy = '0' THEN
                state <= StWaitStart;
              ELSE
                state <= StWr1;
              END IF;
            WHEN OTHERS =>
              sI2C_enable  <= '0';
              sI2C_data_wr <= (OTHERS => '0');
              state        <= StWaitStart;
          END CASE;

        -- 2 bytes write
        WHEN StWr2 =>
          BUSY <= '1';
          CASE sBusyCnt IS
            WHEN "000" =>
              sI2C_enable  <= '1';
              sI2C_data_wr <= REG_ADDR;
              state        <= StWr2;
            WHEN "001" =>
              sI2C_enable  <= '1';
              sI2C_data_wr <= WR_DATA0;
              state        <= StWr2;
            WHEN "010" =>
              sI2C_enable  <= '0';
              sI2C_data_wr <= WR_DATA0;
              IF sI2C_busy = '0' THEN
                state <= StWaitStart;
              ELSE
                state <= StWr2;
              END IF;
            WHEN OTHERS =>
              sI2C_enable  <= '0';
              sI2C_data_wr <= (OTHERS => '0');
              state        <= StWaitStart;
          END CASE;

        -- 3 bytes write
        WHEN StWr3 =>
          BUSY <= '1';
          CASE sBusyCnt IS
            WHEN "000" =>
              sI2C_enable  <= '1';
              sI2C_data_wr <= REG_ADDR;
              state        <= StWr3;
            WHEN "001" =>
              sI2C_enable  <= '1';
              sI2C_data_wr <= WR_DATA0;
              state        <= StWr3;
            WHEN "010" =>
              sI2C_enable  <= '1';
              sI2C_data_wr <= WR_DATA1;
              state        <= StWr3;
            WHEN "011" =>
              sI2C_enable  <= '0';
              sI2C_data_wr <= WR_DATA1;
              IF sI2C_busy = '0' THEN
                state <= StWaitStart;
              ELSE
                state <= StWr3;
              END IF;
            WHEN OTHERS =>
              sI2C_enable  <= '0';
              sI2C_data_wr <= (OTHERS => '0');
              state        <= StWaitStart;
          END CASE;

        -- 1 byte read
        WHEN StRd1 =>
          BUSY         <= '1';
          rd_data1_buf <= rd_data1_buf;
          sI2C_data_wr <= (OTHERS => '0');
          CASE sBusyCnt IS
            WHEN "000" =>
              sI2C_enable  <= '1';
              rd_data0_buf <= rd_data0_buf;
              state        <= StRd1;
            WHEN "001" =>
              sI2C_enable <= '0';
              IF sI2C_busy = '0' THEN
                state        <= StWaitStart;
                rd_data0_buf <= sI2C_data_rd;
              ELSE
                state        <= StRd1;
                rd_data0_buf <= rd_data0_buf;
              END IF;
            WHEN OTHERS =>
              sI2C_enable  <= '0';
              rd_data0_buf <= rd_data0_buf;
              state        <= StWaitStart;
          END CASE;

        -- 2 bytes read
        WHEN StRd2 =>
          BUSY         <= '1';
          sI2C_data_wr <= (OTHERS => '0');
          CASE sBusyCnt IS
            WHEN "000" =>
              sI2C_enable  <= '1';
              rd_data0_buf <= rd_data0_buf;
              rd_data1_buf <= rd_data1_buf;
              state        <= StRd2;
            WHEN "001" =>
              sI2C_enable <= '1';
              IF sI2C_busy = '0' THEN
                state        <= StRd2;
                rd_data0_buf <= sI2C_data_rd;
                rd_data1_buf <= rd_data1_buf;
              ELSE
                state        <= StRd2;
                rd_data0_buf <= rd_data0_buf;
                rd_data1_buf <= rd_data1_buf;
              END IF;
            WHEN "010" =>
              sI2C_enable <= '0';
              IF sI2C_busy = '0' THEN
                state        <= StWaitStart;
                rd_data0_buf <= rd_data0_buf;
                rd_data1_buf <= sI2C_data_rd;
              ELSE
                state        <= StRd2;
                rd_data0_buf <= rd_data0_buf;
                rd_data1_buf <= rd_data1_buf;
              END IF;
            WHEN OTHERS =>
              sI2C_enable  <= '0';
              rd_data0_buf <= rd_data0_buf;
              rd_data1_buf <= rd_data1_buf;
              state        <= StWaitStart;
          END CASE;

--      //// shouldn't happen
        WHEN OTHERS =>
          sI2C_enable  <= '0';
          sI2C_data_wr <= (OTHERS => '0');
          BUSY         <= '0';
          rd_data0_buf <= (OTHERS => '0');
          rd_data1_buf <= (OTHERS => '0');
          state        <= StWaitStart;

      END CASE;
    END IF;
  END PROCESS state_machine;

  RD_DATA0 <= rd_data0_buf;
  RD_DATA1 <= rd_data1_buf;

END arch;
