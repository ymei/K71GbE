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
  PORT (
    RESET          : IN  std_logic;
    MEM_CLK        : IN  std_logic;
    MEM_WE         : IN  std_logic;     -- memory write enable
    MEM_ADDR       : IN  std_logic_vector(31 DOWNTO 0);
    MEM_D          : IN  std_logic_vector(31 DOWNTO 0);  -- memory data
    --
    TX_AXIS_ACLK   : IN  std_logic;
    TX_START       : IN  std_logic;  -- rising edge aligned 1-period pulse to start TX
    TX_BYTES       : IN  std_logic_vector(15 DOWNTO 0);  -- number of bytes to send
    TX_AXIS_TDATA  : OUT std_logic_vector(63 DOWNTO 0);
    TX_AXIS_TKEEP  : OUT std_logic_vector(7 DOWNTO 0);
    TX_AXIS_TVALID : OUT std_logic;
    TX_AXIS_TLAST  : OUT std_logic;
    TX_AXIS_TREADY : IN  std_logic
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

  SIGNAL mem_clk_i     : std_logic;
  SIGNAL tx_clk_i      : std_logic;
  TYPE pktState_type IS (S0, S1, S2, S3, S4);
  SIGNAL pktState      : pktState_type;
  SIGNAL mem_wea       : std_logic_vector(0 DOWNTO 0);
  SIGNAL addrb_i       : std_logic_vector(10 DOWNTO 0);
  SIGNAL doutb_i       : std_logic_vector(63 DOWNTO 0);
  SIGNAL addrCtr       : unsigned(15 DOWNTO 0) := (OTHERS => '0');
  SIGNAL bytesLeft     : unsigned(15 DOWNTO 0) := (OTHERS => '0');
  SIGNAL bytesLeft_reg : unsigned(15 DOWNTO 0) := (OTHERS => '0');
  SIGNAL pktCtr        : unsigned(47 DOWNTO 0) := (OTHERS => '0');

BEGIN

  mem_clk_i <= MEM_CLK;
  tx_clk_i  <= TX_AXIS_ACLK;
  mem_wea   <= (OTHERS => MEM_WE);
  tge_packet_ram_inst : ten_gig_eth_packet_ram
    PORT MAP (
      CLKA  => mem_clk_i,
      WEA   => mem_wea,
      ADDRA => MEM_ADDR(11 DOWNTO 0),
      DINA  => MEM_D,
      CLKB  => tx_clk_i,
      ADDRB => addrb_i,
      DOUTB => doutb_i
    );

  PROCESS (tx_clk_i) IS
  BEGIN
    IF falling_edge(tx_clk_i) THEN
      TX_AXIS_TDATA <= doutb_i;
      IF addrCtr = 5 THEN
        -- little endian of pktCtr seen by the host
        TX_AXIS_TDATA <= std_logic_vector(pktCtr) & doutb_i(15 DOWNTO 0);
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

  pkt_sm: PROCESS (tx_clk_i, RESET) IS
  BEGIN
    IF RESET = '1' THEN
      pktState       <= S0;
      pktCtr         <= (OTHERS => '0');
      addrCtr        <= (OTHERS => '0');
      TX_AXIS_TVALID <= '0';
      TX_AXIS_TLAST  <= '0';
    ELSIF falling_edge(tx_clk_i) THEN
      TX_AXIS_TVALID <= '0';
      TX_AXIS_TLAST  <= '0';
      CASE pktState IS
        WHEN S0 =>
          IF TX_START = '1' THEN
            addrCtr   <= (OTHERS => '0');
            bytesLeft <= unsigned(TX_BYTES);
            -- minimum packet length requirement
            IF unsigned(TX_BYTES) < 14 THEN
              pktState <= S0;
            ELSE
              pktState <= S1;
            END IF;
          END IF;
        WHEN S1 =>
          pktState       <= S1;
          TX_AXIS_TVALID <= '1';
          IF TX_AXIS_TREADY = '1' THEN
            addrCtr       <= addrCtr + 1;
            bytesLeft_reg <= bytesLeft;
            bytesLeft     <= bytesLeft - 8;
            IF bytesLeft <= 8 THEN
              pktState <= S2;
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
  addrb_i <= std_logic_vector(addrCtr(10 DOWNTO 0));

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
