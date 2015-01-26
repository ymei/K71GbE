----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/21/2013 02:38:36 AM
-- Design Name: 
-- Module Name: ten_gig_eth_packet_gen - Behavioral
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

ENTITY ten_gig_eth_packet_gen IS
  GENERIC (
    OUTDATA_WIDTH  : positive := 64;
    NBURST_WIDTH   : positive := 8;
    APP_ADDR_WIDTH : positive := 28
  );
  PORT (
    RESET           : IN  std_logic;
    --
    TX_AXIS_ACLK    : IN  std_logic;  -- this clk drives the module's internal logic
    TX_AXIS_TDATA   : OUT std_logic_vector(63 DOWNTO 0);
    TX_AXIS_TKEEP   : OUT std_logic_vector(7 DOWNTO 0);
    TX_AXIS_TVALID  : OUT std_logic;
    TX_AXIS_TLAST   : OUT std_logic;
    TX_AXIS_TREADY  : IN  std_logic;
    --
    PKT_MEM_CLK     : IN  std_logic;
    PKT_MEM_WE      : IN  std_logic;  -- memory write enable
    PKT_MEM_ADDR    : IN  std_logic_vector(31 DOWNTO 0);
    PKT_MEM_D       : IN  std_logic_vector(31 DOWNTO 0);  -- memory data
    --
    TX_START        : IN  std_logic;  -- rising edge aligned 1-period pulse to start TX
    DATA_START_ADDR : IN  std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
    DATA_N_PACKETS  : IN  std_logic_vector(15 DOWNTO 0);
    --
    NBURST          : IN  std_logic_vector(NBURST_WIDTH-1 DOWNTO 0);
    DATA_RD_ADDR    : OUT std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
    DATA_RD_START   : OUT std_logic;
    DATA_RD_VALID   : IN  std_logic;
    --
    DATA_BRAM_CLK   : OUT std_logic;
    DATA_BRAM_ADDR  : OUT std_logic_vector(NBURST_WIDTH+3-1 DOWNTO 0);
    DATA_BRAM_D     : IN  std_logic_vector(OUTDATA_WIDTH-1 DOWNTO 0);
    --
    CMD_FIFO_Q      : IN  std_logic_vector(127 DOWNTO 0);
    CMD_FIFO_EMPTY  : IN  std_logic;
    CMD_FIFO_RDREQ  : OUT std_logic;
    CMD_FIFO_RDCLK  : OUT std_logic
  );
END ten_gig_eth_packet_gen;

ARCHITECTURE Behavioral OF ten_gig_eth_packet_gen IS

  COMPONENT ten_gig_eth_packet_ram
    PORT (
      CLKA  : IN  std_logic;
      WEA   : IN  std_logic_vector(0 DOWNTO 0);
      ADDRA : IN  std_logic_vector(11 DOWNTO 0);
      DINA  : IN  std_logic_vector(31 DOWNTO 0);
      CLKB  : IN  std_logic;
      ADDRB : IN  std_logic_vector(10 DOWNTO 0);
      DOUTB : OUT std_logic_vector(63 DOWNTO 0)
    );
  END COMPONENT;

  SIGNAL pkt_mem_clk_i      : std_logic;
  SIGNAL clk_i              : std_logic;
  TYPE pktState_type IS (S0, S1, S2, S3, S4);
  SIGNAL pktState           : pktState_type;
  SIGNAL pkt_mem_addrb_i    : std_logic_vector(10 DOWNTO 0);
  SIGNAL pkt_mem_doutb_i    : std_logic_vector(63 DOWNTO 0);
  SIGNAL pkt_mem_addrCtr    : unsigned(15 DOWNTO 0) := (OTHERS => '0');
  SIGNAL pktBytes           : unsigned(15 DOWNTO 0) := x"0038";
  SIGNAL bytesLeft          : unsigned(15 DOWNTO 0) := (OTHERS => '0');
  SIGNAL bytesLeft_reg      : unsigned(15 DOWNTO 0) := (OTHERS => '0');
  SIGNAL pktCtr             : unsigned(47 DOWNTO 0) := (OTHERS => '0');
  --
  SIGNAL data_bram_addr_max : std_logic_vector(NBURST_WIDTH+3-1 DOWNTO 0);
  SIGNAL pkt_mem_wea        : std_logic_vector(0 DOWNTO 0);

BEGIN

  pkt_mem_clk_i <= PKT_MEM_CLK;
  clk_i         <= TX_AXIS_ACLK;
  
  tge_packet_ram_inst : ten_gig_eth_packet_ram
    PORT MAP (
      CLKA  => pkt_mem_clk_i,
      WEA   => pkt_mem_wea,
      ADDRA => PKT_MEM_ADDR(11 DOWNTO 0),
      DINA  => PKT_MEM_D,
      CLKB  => clk_i,
      ADDRB => pkt_mem_addrb_i,
      DOUTB => pkt_mem_doutb_i
    );
  pkt_mem_wea <= (OTHERS => PKT_MEM_WE);

  PROCESS (clk_i) IS
  BEGIN
    IF falling_edge(clk_i) THEN
      TX_AXIS_TDATA <= pkt_mem_doutb_i;
      IF pkt_mem_addrCtr = 5 THEN
        -- little endian of pktCtr seen by the host
        TX_AXIS_TDATA <= std_logic_vector(pktCtr) & pkt_mem_doutb_i(15 DOWNTO 0);
        -- convert to big endian
        --TX_AXIS_TDATA <= std_logic_vector(pktCtr(7 DOWNTO 0))
        --               & std_logic_vector(pktCtr(15 DOWNTO 8))
        --               & std_logic_vector(pktCtr(23 DOWNTO 16))
        --               & std_logic_vector(pktCtr(31 DOWNTO 24))
        --               & std_logic_vector(pktCtr(39 DOWNTO 32))
        --               & std_logic_vector(pktCtr(47 DOWNTO 40))
        --               & doutb_i(15 DOWNTO 0);
      END IF;
    END IF;
  END PROCESS;

  pkt_sm : PROCESS (clk_i, RESET) IS
  BEGIN
    IF RESET = '1' THEN
      pktState        <= S0;
      pktCtr          <= (OTHERS => '0');
      pkt_mem_addrCtr <= (OTHERS => '0');
      TX_AXIS_TVALID  <= '0';
      TX_AXIS_TLAST   <= '0';
    ELSIF falling_edge(clk_i) THEN
      TX_AXIS_TVALID <= '0';
      TX_AXIS_TLAST  <= '0';
      CASE pktState IS
        WHEN S0 =>
          IF TX_START = '1' THEN
            pkt_mem_addrCtr <= (OTHERS => '0');
            bytesLeft       <= pktBytes;
            -- minimum packet length requirement
            IF unsigned(pktBytes) < 14 THEN
              pktState <= S0;
            ELSE
              pktState <= S1;
            END IF;
          END IF;
        WHEN S1 =>
          pktState       <= S1;
          TX_AXIS_TVALID <= '1';
          IF TX_AXIS_TREADY = '1' THEN
            pkt_mem_addrCtr <= pkt_mem_addrCtr + 1;
            bytesLeft_reg   <= bytesLeft;
            bytesLeft       <= bytesLeft - 8;
            IF bytesLeft    <= 8 THEN
              pktState      <= S2;
              TX_AXIS_TLAST <= '1';
            END IF;
          END IF;
        WHEN S2 =>
          pktState <= S0;
          pktCtr   <= pktCtr + 1;
        WHEN OTHERS =>
          pktState <= S0;
      END CASE;
    END IF;
  END PROCESS pkt_sm;
  pkt_mem_addrb_i <= std_logic_vector(pkt_mem_addrCtr(10 DOWNTO 0));

  WITH bytesLeft_reg SELECT
    TX_AXIS_TKEEP <=
    (OTHERS => '0') WHEN to_unsigned(0,bytesLeft_reg'length),
    "00000001"      WHEN to_unsigned(1,bytesLeft_reg'length),
    "00000011"      WHEN to_unsigned(2,bytesLeft_reg'length),
    "00000111"      WHEN to_unsigned(3,bytesLeft_reg'length),
    "00001111"      WHEN to_unsigned(4,bytesLeft_reg'length),
    "00011111"      WHEN to_unsigned(5,bytesLeft_reg'length),
    "00111111"      WHEN to_unsigned(6,bytesLeft_reg'length),
    "01111111"      WHEN to_unsigned(7,bytesLeft_reg'length),
    (OTHERS => '1') WHEN OTHERS;

END Behavioral;
