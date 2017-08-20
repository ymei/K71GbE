-------------------------------------------------------------------------------
-- Title      : I2C master core module
-- Project    : HFT PXL
-------------------------------------------------------------------------------
-- File	      : i2c_master_core.vhd
-- Author     : J. Schambach
-- Company    : University of Texas at Austin
-- Created    : 2013-11-08
-- Last update: 2013-12-12
-- Platform   : Windows, Xilinx ISE / PlanAhead 14.5
-- Target     : Virtex-6 (XC6VLX240T-FF1759)
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: I2C master logic
-------------------------------------------------------------------------------
-- Copyright (c) 2013
-------------------------------------------------------------------------------
-- Revisions  :
-- Date	       Version	Author	      Description
-- 2013-11-08  1.0	jschamba      Created
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY i2c_master_core IS
  GENERIC(
    INPUT_CLK_FREQENCY : integer := 100_000_000; -- input clock speed from user logic
    -- BUS CLK freqency should be divided by multiples of 4 from input frequency
    BUS_CLK_FREQUENCY  : integer := 100_000      -- speed the i2c bus (SCL) will run at
  );
  PORT (
    CLK	      : IN  std_logic;		--  system clock
    RESET     : IN  std_logic;		--  active high reset
    ENA	      : IN  std_logic;		--  latch in command
    ADDR      : IN  std_logic_vector(6 DOWNTO 0);  -- address of target slave
    RW	      : IN  std_logic;		-- '0' is write, '1' is read
    DATA_WR   : IN  std_logic_vector(7 DOWNTO 0);  -- data to write to slave
    BUSY      : OUT std_logic;		-- indicates transaction in progress
    DATA_RD   : OUT std_logic_vector(7 DOWNTO 0);  -- data read from slave
    ACK_ERROR : OUT std_logic;	-- flag if improper acknowledge from slave
    SDA_in    : IN  std_logic;		-- serial data input of i2c bus
    SDA_out   : OUT std_logic;		-- serial data output of i2c bus
    SDA_t     : OUT std_logic;		-- serial data direction of i2c bus
    SCL	      : OUT std_logic		-- serial clock output of i2c bus
  );
END i2c_master_core;

ARCHITECTURE logic OF i2c_master_core IS
  CONSTANT DIVIDER : integer := (INPUT_CLK_FREQENCY/BUS_CLK_FREQUENCY)/4;  -- number of clocks in 1/4 cycle of SCL
  --CONSTANT DIVIDER : integer := 1;	   -- number of clocks in 1/4 cycle of SCL
  TYPE machine_type IS (StReady,
			StStart,
			StCommand,
			StSlv_ack1,
			StWr,
			StRd,
			StSlv_ack2,
			StMstr_ack,
			StRdWait,
			StStop);	-- needed states
  SIGNAL state	   : machine_type;	-- state machine
  SIGNAL data_clk  : std_logic;		-- clock edges for sda
  SIGNAL scl_clk   : std_logic;		-- constantly running internal scl
  SIGNAL scl_ena   : std_logic		  := '0';  -- enables internal scl to output
  SIGNAL scl_ena_d : std_logic		  := '0';  -- enables internal scl to output
  SIGNAL sda_int   : std_logic		  := '1';  -- internal sda
  SIGNAL sda_ena_n : std_logic;		-- enables internal sda to output
  SIGNAL sAckError : std_logic;
  SIGNAL addr_rw   : std_logic_vector(7 DOWNTO 0);  -- latched in address and read/write
  SIGNAL data_tx   : std_logic_vector(7 DOWNTO 0);  -- latched in data to write to slave
  SIGNAL data_rx   : std_logic_vector(7 DOWNTO 0);  -- data received from slave
  SIGNAL bit_cnt   : integer RANGE 0 TO 7 := 7;	 -- tracks bit number in transaction

BEGIN

  -- generate the timing for the bus clock (scl_clk) and the data clock (data_clk)
  PROCESS(CLK, RESET)
    VARIABLE count : integer RANGE 0 TO DIVIDER*4;  -- timing for clock generation
  BEGIN
    IF(RESET = '1') THEN		-- reset asserted
      count := 0;
    ELSIF rising_edge(CLK) THEN
      IF(count = DIVIDER*4-1) THEN	-- end of timing cycle
	count := 0;			-- reset timer
      ELSE		     -- clock stretching from slave not detected
	count := count + 1;		-- continue clock generation timing
      END IF;

      IF count < DIVIDER THEN		-- first 1/4 cycle of clocking
	scl_clk	 <= '0';
	data_clk <= '0';
      ELSIF count < (DIVIDER*2) THEN	-- second 1/4 cycle of clocking
	scl_clk	 <= '0';
	data_clk <= '1';
      ELSIF count < DIVIDER*3 THEN	-- third 1/4 cycle of clocking
	scl_clk	 <= '1';		-- scl high
	data_clk <= '1';
      ELSE				-- last 1/4 cycle of clocking
	scl_clk	 <= '1';
	data_clk <= '0';
      END IF;
    END IF;
  END PROCESS;

  PROCESS(scl_clk)
  BEGIN
    IF rising_edge(scl_clk) THEN
      scl_ena_d <=  scl_ena;
    END IF;
  END PROCESS;
  -- state machine and writing to sda during SCL low (data_clk rising edge)
  PROCESS(data_clk, RESET)
  BEGIN
    IF(RESET = '1') THEN		-- reset asserted
      state   <= StReady;		-- return to initial state
      BUSY    <= '1';			-- indicate not available
      scl_ena <= '0';			-- sets SCL high
      sda_int <= '1';			-- sets sda high
      SDA_t   <= '1';			-- sets SDA bus as input
      bit_cnt <= 7;			-- restarts data bit counter
      DATA_RD <= "00000000";		-- clear data read port
    ELSIF rising_edge(data_clk) THEN
      CASE state IS

	WHEN StReady =>			-- idle state
	  SDA_t	  <= '0';		-- output
	  sda_int <= '1';		-- pull SDA high
	  IF(ENA = '1') THEN		-- transaction requested
	    BUSY    <= '1';		-- flag busy
	    addr_rw <= ADDR & RW;  -- collect requested slave address and command
	    data_tx <= DATA_WR;		-- collect requested data to write
	    scl_ena <= '1';		-- enable SCL output
	    state   <= StStart;		-- go to start bit
	  ELSE				-- remain idle
	    BUSY  <= '0';		-- unflag busy
	    state <= StReady;		-- remain idle
	  END IF;

	WHEN StStart =>			-- start bit of transaction
	  BUSY	  <= '1';		-- resume busy if continuous mode
	  sda_int <= addr_rw(bit_cnt);	-- set first address bit to bus
	  state	  <= StCommand;		-- go to StCommand

	WHEN StCommand =>	    -- address and command byte of transaction
	  IF(bit_cnt = 0) THEN		-- command transmit finished
	    SDA_t   <= '1';		-- release sda for slave acknowledge
	    sda_int <= '1';		-- internal SDA high
	    bit_cnt <= 7;		-- reset bit counter for "byte" states
	    state   <= StSlv_ack1;	-- go to slave acknowledge (command)
	  ELSE				-- next clock cycle of command state
	    bit_cnt <= bit_cnt - 1;	-- keep track of transaction bits
	    sda_int <= addr_rw(bit_cnt-1);  -- write address/command bit to bus
	    state   <= StCommand;	-- continue with command
	  END IF;

	WHEN StSlv_ack1 =>		  -- slave acknowledge bit (command)
	  IF(addr_rw(0) = '0') THEN	  -- write command
	    SDA_t   <= '0';		  -- output
	    sda_int <= data_tx(bit_cnt);  -- write first bit of data
	    state   <= StWr;		  -- go to write byte
	  ELSE				  -- read command
	    SDA_t <= '1';		  -- release SDA for incoming data
	    state <= StRd;		  -- go to read byte
	  END IF;

	WHEN StWr =>			-- write byte of transaction
	  BUSY <= '1';			-- resume busy if continuous mode
	  IF(bit_cnt = 0) THEN		-- write byte transmit finished
	    SDA_t   <= '1';		-- release sda for slave acknowledge
	    sda_int <= '1';		-- internal SDA high
	    bit_cnt <= 7;		-- reset bit counter for "byte" states
	    state   <= StSlv_ack2;	-- go to slave acknowledge (write)
	  ELSE				-- next clock cycle of write state
	    bit_cnt <= bit_cnt - 1;	-- keep track of transaction bits
	    sda_int <= data_tx(bit_cnt-1);  -- write next bit to bus
	    state   <= StWr;		-- continue writing
	  END IF;

	WHEN StRd =>			-- read byte of transaction
	  BUSY <= '1';			-- resume busy if continuous mode
	  IF(bit_cnt = 0) THEN		-- read byte receive finished
	    SDA_t <= '0';		-- output
	    IF(ENA = '1' AND RW = '1') THEN  -- continuing with another read
	      sda_int <= '0';  -- acknowledge the byte has been received
	    ELSE			-- stopping or continuing with a write
	      sda_int <= '1';  -- send a no-acknowledge (before stop or repeated start)
	    END IF;
	    bit_cnt <= 7;		-- reset bit counter for "byte" states
	    DATA_RD <= data_rx;		-- output received data
	    state   <= StMstr_ack;	-- go to master acknowledge
	  ELSE				-- next clock cycle of read state
	    bit_cnt <= bit_cnt - 1;	-- keep track of transaction bits
	    state   <= StRd;		-- continue reading
	  END IF;

	WHEN StSlv_ack2 =>		-- slave acknowledge bit (write)
	  SDA_t <= '0';			-- output
	  IF(ENA = '1') THEN		-- continue transaction
	    BUSY    <= '0';		-- continue is accepted
	    addr_rw <= ADDR & RW;  -- collect requested slave address and command
	    data_tx <= DATA_WR;		-- collect requested data to write
	    IF(RW = '1') THEN		-- continue transaction with a read
	      sda_int <= '1';		-- internal SDA high
	      state   <= StStart;	-- go to repeated start
	    ELSE		   -- continue transaction with another write
	      sda_int <= DATA_WR(bit_cnt);  -- write first bit of data
	      state   <= StWr;		-- go to write byte
	    END IF;
	  ELSE				-- complete transaction
	    scl_ena <= '0';		-- disable SCL
	    state <= StStop;		-- go to stop bit
	  END IF;

	WHEN StMstr_ack =>		-- master acknowledge bit after a read
	  IF(ENA = '1') THEN		-- continue transaction
	    BUSY    <= '0';  -- continue is accepted and data received is available on bus
	    addr_rw <= ADDR & RW;  -- collect requested slave address and command
	    data_tx <= DATA_WR;		-- collect requested data to write
	    IF(RW = '0') THEN		-- continue transaction with a write
	      state <= StStart;		-- repeated start
	    ELSE	     -- continue transaction with another read
	      SDA_t   <= '1';		-- input
	      sda_int <= '1';		-- release sda from incoming data
	      scl_ena <= '0';  -- disable SCL for one period for extra reads
	      state   <= StRdWait;	-- goto wait state
	    END IF;
	  ELSE				-- complete transaction
	    scl_ena <= '0';		-- disable SCL
	    state <= StStop;		-- go to stop bit
	  END IF;

	WHEN StRdWait =>    -- extra wait in case of additional Read
	  scl_ena <= '1';		-- re-enable SCL
	  state	  <= StRd;		-- back to reading

	WHEN StStop =>			-- stop bit of transaction
	  scl_ena <= '0';		-- disable SCL
	  BUSY	  <= '0';		-- unflag busy
	  state	  <= StReady;		-- go to StReady state
      END CASE;
    END IF;

    -- reading from SDA during SCL high (falling edge of data_clk)
    IF(RESET = '1') THEN		-- reset asserted
      sAckError <= '0';
    ELSIF falling_edge(data_clk) THEN
      CASE state IS
	WHEN StStart =>			-- starting new transaction
	  sAckError <= '0';		-- reset acknowledge error flag

	WHEN StSlv_ack1 =>  -- receiving slave acknowledge (command)
	  sAckError <= SDA_in OR sAckError;  -- set error output if no-acknowledge

	WHEN StRd =>			-- receiving slave data
	  data_rx(bit_cnt) <= SDA_in;	-- receive current slave data bit

	WHEN StSlv_ack2 =>		-- receiving slave acknowledge (write)
	  sAckError <= SDA_in OR sAckError;  -- set error output if no-acknowledge

	WHEN OTHERS =>
	  NULL;
      END CASE;
    END IF;
  END PROCESS;

  -- set sda output
  WITH state SELECT
    SDA_out <=
    data_clk	 WHEN StStart,		-- generate Start condition
    NOT data_clk WHEN StStop,		-- generate Stop condition
    sda_int	 WHEN OTHERS;		-- internal SDA data


  -- set SCL and SDA outputs
  SCL <= scl_clk WHEN scl_ena_d = '1'  ELSE '1';

  ACK_ERROR <= sAckError;

END logic;
