----------------------------------------------------------------------------------
-- Company:  LBNL
-- Engineer: Yuan Mei
-- 
-- Create Date: 12/17/2013 07:22:25 PM
-- Design Name: 
-- Module Name: sdram_buffer - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
--
-- Interface to Xilinx MIG UI to use external sdram as a circular buffer for
-- stream data input and packet output
-- Currently read and write are not allowed to happen simultaneously.
--
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- At the 1-clk wide WR_START pulse, RD_POINTER is loaded to be the first
-- address to write to.  Afterwards, as writes advances, WR_POINTER increments
-- accordingly.  NBURST was loaded at WR_START to control the write burst size.
-- When WR_POINTER wraps around and hits the original RD_POINTER, COLLISION
-- asserts.  Writes will continue (overwritting previous data) until WR_STOP
-- (1-clk) asserts.  WR_STOP can be considered as a stop trigger.
--
-- AT RD_START (1-clk), RD_ADDR is loaded and a packet of NBURST is loaded into
-- the read buffer.  Then RD_VALID asserts.
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

ENTITY sdram_buffer IS
  GENERIC (
    INDATA_WIDTH   : positive := 256;
    OUTDATA_WIDTH  : positive := 64;
    NBURST_WIDTH   : positive := 8;
    APP_ADDR_WIDTH : positive := 28;
    APP_DATA_WIDTH : positive := 512;
    APP_MASK_WIDTH : positive := 64
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
    RD_POINTER         : IN  std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
    WR_POINTER         : OUT std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
    COLLISION          : OUT std_logic;
    NBURST             : IN  std_logic_vector(NBURST_WIDTH-1 DOWNTO 0);
    RD_ADDR            : IN  std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
    RD_START           : IN  std_logic;
    RD_VALID           : OUT std_logic;
    WR_START           : IN  std_logic;
    WR_STOP            : IN  std_logic;
    WR_BUSY            : OUT std_logic;
    --
    INDATA_FIFO_WRCLK  : IN  std_logic;
    INDATA_FIFO_Q      : IN  std_logic_vector(INDATA_WIDTH-1 DOWNTO 0);
    INDATA_FIFO_FULL   : OUT std_logic;
    INDATA_FIFO_WREN   : IN  std_logic;
    --
    OUTDATA_BRAM_CLKB  : IN  std_logic;
    OUTDATA_BRAM_ADDRB : IN  std_logic_vector(NBURST_WIDTH+3-1 DOWNTO 0);
    OUTDATA_BRAM_DOUTB : OUT std_logic_vector(OUTDATA_WIDTH-1 DOWNTO 0)
  );
END sdram_buffer;

ARCHITECTURE Behavioral OF sdram_buffer IS

  COMPONENT fifo256to512
    PORT (
      RST        : IN  std_logic;
      WR_CLK     : IN  std_logic;
      RD_CLK     : IN  std_logic;
      DIN        : IN  std_logic_vector(255 DOWNTO 0);
      WR_EN      : IN  std_logic;
      RD_EN      : IN  std_logic;
      DOUT       : OUT std_logic_vector(511 DOWNTO 0);
      FULL       : OUT std_logic;
      EMPTY      : OUT std_logic;
      PROG_EMPTY : OUT std_logic
    );
  END COMPONENT;

  COMPONENT sdram_buffer_bram
    PORT (
      CLKA  : IN  std_logic;
      WEA   : IN  std_logic_vector(0 DOWNTO 0);
      ADDRA : IN  std_logic_vector(7 DOWNTO 0);
      DINA  : IN  std_logic_vector(511 DOWNTO 0);
      CLKB  : IN  std_logic;
      ADDRB : IN  std_logic_vector(10 DOWNTO 0);
      DOUTB : OUT std_logic_vector(63 DOWNTO 0)
    );
  END COMPONENT;

  CONSTANT DDR3_CMD_WRITE : std_logic_vector(2 DOWNTO 0) := "000";
  CONSTANT DDR3_CMD_READ  : std_logic_vector(2 DOWNTO 0) := "001";

  SIGNAL rd_pointer_reg         : unsigned(RD_POINTER'length-1 DOWNTO 0);
  SIGNAL rd_addr_reg            : unsigned(RD_ADDR'length-1 DOWNTO 0);
  SIGNAL rd_start_pulse         : std_logic := '0';
  SIGNAL rd_cmd_busy            : std_logic := '0';
  SIGNAL rd_data_busy           : std_logic := '0';  
  SIGNAL rd_burst_start         : std_logic := '0';
  SIGNAL rd_burst_start_i       : std_logic := '0';
  --
  SIGNAL wr_start_pulse         : std_logic := '0';
  SIGNAL wr_stop_pulse          : std_logic := '0';
  SIGNAL writing_reg            : std_logic := '0';
  SIGNAL wr_burst_start         : std_logic := '0';
  SIGNAL wr_burst_start_i       : std_logic := '0';
  SIGNAL wr_wdf_end             : std_logic := '0';
  SIGNAL wr_wdf_wren            : std_logic := '0';
  SIGNAL wr_cmd_busy            : std_logic := '0';
  SIGNAL wr_data_busy           : std_logic := '0';
  --
  SIGNAL nburst_reg             : unsigned(NBURST'length-1 DOWNTO 0);
  --
  SIGNAL indata_fifo_rdclk      : std_logic;
  SIGNAL indata_fifo_rden       : std_logic;
  SIGNAL indata_fifo_dout       : std_logic_vector(APP_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL indata_fifo_empty      : std_logic;
  SIGNAL indata_fifo_prog_empty : std_logic;
  --
  SIGNAL bram_clka              : std_logic;
  SIGNAL bram_wea               : std_logic_vector(0 DOWNTO 0);
  SIGNAL bram_we                : std_logic;
  SIGNAL bram_addra             : std_logic_vector(7 DOWNTO 0);
  SIGNAL bram_dina              : std_logic_vector(511 DOWNTO 0);

  SIGNAL reading          : std_logic;
  TYPE   read_state_type IS (R0, R1, R2, R3, R4);
  SIGNAL read_state       : read_state_type  := R0;
  SIGNAL read_data_state  : read_state_type  := R0;
  TYPE   write_state_type IS (W0, W1, W2, W3, W4);
  SIGNAL write_state      : write_state_type := W0;
  SIGNAL write_data_state : write_state_type := W0;

  SIGNAL rd_addr_i      : unsigned(APP_ADDR'length-1 DOWNTO 0);
  SIGNAL rd_app_en      : std_logic;
  SIGNAL rd_app_cmd     : std_logic_vector(2 DOWNTO 0);
  SIGNAL wr_addr_i      : unsigned(APP_ADDR'length-1 DOWNTO 0);
  SIGNAL wr_app_en      : std_logic;
  SIGNAL wr_app_cmd     : std_logic_vector(2 DOWNTO 0);

BEGIN

  indata_fifo_inst : fifo256to512
  PORT MAP (
    RST        => RESET,
    WR_CLK     => INDATA_FIFO_WRCLK,
    RD_CLK     => indata_fifo_rdclk,
    DIN        => INDATA_FIFO_Q,
    WR_EN      => INDATA_FIFO_WREN,
    RD_EN      => indata_fifo_rden,
    DOUT       => indata_fifo_dout,
    FULL       => INDATA_FIFO_FULL,
    EMPTY      => indata_fifo_empty,
    PROG_EMPTY => indata_fifo_prog_empty
  );
  indata_fifo_rdclk <= CLK;
  APP_WDF_DATA <= indata_fifo_dout;
  APP_WDF_MASK <= (OTHERS => '0');

  sdram_buffer_bram_inst : sdram_buffer_bram
    PORT MAP (
      CLKA  => bram_clka,
      WEA   => bram_wea,
      ADDRA => bram_addra,
      DINA  => bram_dina,
      CLKB  => OUTDATA_BRAM_CLKB,
      ADDRB => OUTDATA_BRAM_ADDRB,
      DOUTB => OUTDATA_BRAM_DOUTB
    );
  bram_wea <= (OTHERS => bram_we);
  PROCESS (bram_clka)
  BEGIN
    IF falling_edge(bram_clka) THEN
      bram_dina <= APP_RD_DATA;
    END IF;
  END PROCESS;
  bram_clka <= CLK;

  -- make sure _pulse's are 1-clk wide
  PROCESS (CLK)
    VARIABLE prev  : std_logic := '0';
    VARIABLE prev1 : std_logic := '0';
    VARIABLE prev2 : std_logic := '0';
  BEGIN
    IF rising_edge(CLK) THEN
      rd_start_pulse <= RD_START AND (NOT prev);
      wr_start_pulse <= WR_START AND (NOT prev1);
      wr_stop_pulse  <= WR_STOP AND (NOT prev2);
      prev           := RD_START;
      prev1          := WR_START;
      prev2          := WR_STOP;
    END IF;
  END PROCESS;
  -- register addresses and status
  PROCESS (CLK, RESET)
  BEGIN
    IF RESET = '1' THEN
      rd_pointer_reg <= (OTHERS => '0');
      rd_addr_reg    <= (OTHERS => '0');
      nburst_reg     <= (OTHERS => '0');
      writing_reg    <= '0';
    ELSIF falling_edge(CLK) THEN
      IF wr_start_pulse = '1' THEN
        rd_pointer_reg <= unsigned(RD_POINTER);
        nburst_reg     <= unsigned(NBURST);
        writing_reg    <= '1';
      END IF;
      IF wr_stop_pulse = '1' THEN 
        writing_reg <= '0';
      END IF;
      IF rd_start_pulse = '1' THEN
        rd_addr_reg <= unsigned(RD_ADDR);
        nburst_reg  <= unsigned(NBURST);
      END IF;
    END IF;
  END PROCESS;

  -- write command
  PROCESS (CLK, RESET)
    VARIABLE burst_counter : signed(NBURST'length DOWNTO 0);
  BEGIN
    IF RESET = '1' THEN 
      wr_addr_i   <= (OTHERS => '0');
      write_state <= W0;
      COLLISION   <= '0';
    ELSIF falling_edge(CLK) THEN
      wr_app_en      <= '0';
      wr_app_cmd     <= (OTHERS => '0');
      wr_burst_start <= '0';
      wr_cmd_busy    <= '1';
      write_state    <= W0;
      CASE write_state IS
        WHEN W0 =>
          wr_cmd_busy <= '0';
          IF wr_start_pulse = '1' THEN
            wr_cmd_busy <= '1';
            wr_addr_i   <= rd_pointer_reg;
            COLLISION   <= '0';
            write_state <= W1;
          END IF;
        WHEN W1 =>
          IF indata_fifo_prog_empty = '0' THEN
            burst_counter  := signed('0' & nburst_reg);
            wr_burst_start <= '1';
            write_state    <= W2;
          ELSE
            write_state <= W1;
          END IF;
        WHEN W2 =>
          wr_app_cmd  <= DDR3_CMD_WRITE;
          wr_app_en   <= '1';
          write_state <= W3;
        WHEN W3 =>
          wr_app_cmd  <= DDR3_CMD_WRITE;
          wr_app_en   <= '1';
          write_state <= W3;
          IF APP_RDY = '1' THEN
            wr_addr_i     <= wr_addr_i + 8;
            burst_counter := burst_counter - 1;
          END IF;
          IF burst_counter < 1 THEN
            wr_app_en   <= '0';           
            IF writing_reg = '1' THEN
              write_state <= W1;
            ELSE
              write_state <= W0;
            END IF;
          END IF;
          IF rd_pointer_reg - wr_addr_i <= 8 THEN
            COLLISION <= '1';
          END IF;
        WHEN OTHERS =>
          write_state <= W0;
      END CASE;
    END IF;
  END PROCESS;
  -- write data
  PROCESS (CLK, RESET)
    VARIABLE burst_counter : signed(NBURST'length DOWNTO 0);
  BEGIN
    IF RESET = '1' THEN
      write_data_state <= W0;
    ELSIF falling_edge(CLK) THEN
      indata_fifo_rden <= '0';
      wr_wdf_end       <= '0';
      wr_wdf_wren      <= '0';
      wr_data_busy     <= '1';
      write_data_state <= W0;
      CASE write_data_state IS
        WHEN W0 =>
          wr_data_busy       <= '0';
          IF wr_burst_start_i = '1' THEN
            wr_wdf_end       <= '1';
            wr_wdf_wren      <= '1';
            burst_counter    := signed('0' & nburst_reg);
            wr_data_busy     <= '1';
            write_data_state <= W1;
          END IF;
        WHEN W1 =>
          wr_wdf_end       <= '1';
          wr_wdf_wren      <= '1';
          write_data_state <= W1;
          IF APP_WDF_RDY = '1' THEN
            indata_fifo_rden <= '1';
            burst_counter    := burst_counter - 1;
          END IF;
          IF burst_counter < 1 THEN
            wr_wdf_wren      <= '0';
            wr_wdf_end       <= '0';
            write_data_state <= W0;
          END IF;
        WHEN OTHERS =>
          write_data_state <= W0;
      END CASE;
    END IF;
  END PROCESS;

  -- read command
  PROCESS (CLK, RESET)
    VARIABLE burst_counter : signed(NBURST'length DOWNTO 0);
  BEGIN
    IF RESET = '1' THEN 
      rd_addr_i  <= (OTHERS => '0');
      read_state <= R0;
    ELSIF falling_edge(CLK) THEN
      rd_app_en      <= '0';
      rd_app_cmd     <= (OTHERS => '0');
      rd_burst_start <= '0';
      rd_cmd_busy    <= '1';
      read_state     <= R0;
      CASE read_state IS
        WHEN R0 =>
          rd_cmd_busy <= '0';
          IF rd_start_pulse = '1' THEN
            rd_cmd_busy    <= '1';
            rd_addr_i      <= unsigned(RD_ADDR);
            burst_counter  := signed('0' & nburst_reg);
            rd_burst_start <= '1';
            read_state     <= R1;
          END IF;
        WHEN R1 =>
          rd_app_cmd <= DDR3_CMD_READ;
          rd_app_en  <= '1';
          read_state <= R2;
        WHEN R2 =>
          rd_app_cmd <= DDR3_CMD_READ;
          rd_app_en  <= '1';
          read_state <= R2;
          IF APP_RDY = '1' THEN
            rd_addr_i     <= rd_addr_i + 8;
            burst_counter := burst_counter - 1;
          END IF;
          IF burst_counter < 1 THEN
            rd_app_en <= '0';
            read_state <= R0;
          END IF;
        WHEN OTHERS =>
          read_state <= R0;
      END CASE;
    END IF;
  END PROCESS;
  -- read data
  PROCESS (CLK, RESET)
    VARIABLE burst_counter : signed(NBURST'length DOWNTO 0);
  BEGIN
    IF RESET = '1' THEN
      read_data_state <= R0;
    ELSIF falling_edge(CLK) THEN 
      bram_we         <= '0';
      read_data_state <= R0;
      CASE read_data_state IS
        WHEN R0 =>
          rd_data_busy <= '0';
          IF rd_burst_start_i = '1' THEN 
            bram_addra    <= (OTHERS => '0');
            burst_counter := signed('0' & nburst_reg);
            rd_data_busy  <= '1';
            read_data_state <= R1;
          END IF;
        WHEN R1 =>
          read_data_state <= R1;
          IF APP_RD_DATA_VALID = '1' THEN
            bram_we       <= '1';
            bram_addra    <= std_logic_vector(unsigned(bram_addra)+1);
            burst_counter := burst_counter - 1;
          END IF;
          IF burst_counter < 1 THEN
            read_data_state <= R0;
          END IF;
        WHEN OTHERS =>
          read_data_state <= R0;
      END CASE;
    END IF;
  END PROCESS;

  -- buffer out and delay half CLK
  PROCESS (CLK, RESET)
  BEGIN
    IF RESET = '1' THEN
    ELSIF rising_edge(CLK) THEN
      IF wr_app_en = '1' THEN
        APP_ADDR <= std_logic_vector(wr_addr_i);
      ELSE
        APP_ADDR <= std_logic_vector(rd_addr_i);
      END IF;
      APP_CMD          <= wr_app_cmd OR rd_app_cmd;
      APP_EN           <= wr_app_en OR rd_app_en;
      APP_WDF_END      <= wr_wdf_end;
      APP_WDF_WREN     <= wr_wdf_wren;
      WR_POINTER       <= std_logic_vector(wr_addr_i);
      WR_BUSY          <= wr_cmd_busy OR wr_data_busy;
      RD_VALID         <= NOT (rd_cmd_busy OR rd_data_busy);
      --
      rd_burst_start_i <= rd_burst_start;
      wr_burst_start_i <= wr_burst_start;
    END IF;
  END PROCESS;

END Behavioral;
