----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/21/2013 02:38:36 AM
-- Design Name: 
-- Module Name: ten_gig_eth_rx_parser - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
--
-- Parses incoming packets.  Deals WITH ARP AND UDP and generates appropriate
-- action commands.
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

ENTITY ten_gig_eth_rx_parser IS
  PORT (
    RESET                : IN  std_logic;
    RX_AXIS_FIFO_ARESETN : OUT std_logic;
    -- Everything internal to this module is synchronous to this clock `ACLK'
    RX_AXIS_FIFO_ACLK    : IN  std_logic;
    RX_AXIS_FIFO_TDATA   : IN  std_logic_vector(63 DOWNTO 0);
    RX_AXIS_FIFO_TKEEP   : IN  std_logic_vector(7 DOWNTO 0);
    RX_AXIS_FIFO_TVALID  : IN  std_logic;
    RX_AXIS_FIFO_TLAST   : IN  std_logic;
    RX_AXIS_FIFO_TREADY  : OUT std_logic;
    -- Constants
    SRC_MAC              : IN std_logic_vector(47 DOWNTO 0);
    SRC_IP               : IN std_logic_vector(31 DOWNTO 0);
    SRC_PORT             : IN std_logic_vector(15 DOWNTO 0);
    -- Command output fifo interface AFTER parsing the packet
    -- dstMAC(48) dstIP(32) dstPort(16) opcode(32)
    CMD_FIFO_Q           : OUT std_logic_vector(127 DOWNTO 0);
    CMD_FIFO_EMPTY       : OUT std_logic;
    CMD_FIFO_RDREQ       : IN  std_logic;
    CMD_FIFO_RDCLK       : IN  std_logic
  );
END ten_gig_eth_rx_parser;

ARCHITECTURE Behavioral OF ten_gig_eth_rx_parser IS

  COMPONENT fifo128x
    PORT (
      RST    : IN  std_logic;
      WR_CLK : IN  std_logic;
      RD_CLK : IN  std_logic;
      DIN    : IN  std_logic_vector(127 DOWNTO 0);
      WR_EN  : IN  std_logic;
      RD_EN  : IN  std_logic;
      DOUT   : OUT std_logic_vector(127 DOWNTO 0);
      FULL   : OUT std_logic;
      EMPTY  : OUT std_logic
    );
  END COMPONENT;

  --
  CONSTANT pktType_ARP  : std_logic_vector(15 DOWNTO 0) := x"0806";
  CONSTANT pktType_IP   : std_logic_vector(15 DOWNTO 0) := x"0800";
  CONSTANT opcode_REQ   : std_logic_vector(15 DOWNTO 0) := x"0001";
  CONSTANT protocol_UDP : std_logic_vector(7 DOWNTO 0)  := x"11";
  --
  SIGNAL clk_i          : std_logic;
  SIGNAL cmd_fifo_din   : std_logic_vector(127 DOWNTO 0);
  SIGNAL cmd_fifo_wren  : std_logic;
  SIGNAL cmd_fifo_full  : std_logic;
  --
  SIGNAL tvalid_prev    : std_logic;
  SIGNAL tstart         : std_logic;
  SIGNAL tlast_i        : std_logic;
  --
  SIGNAL dst_mac_reg    : std_logic_vector(47 DOWNTO 0);
  SIGNAL dst_ip_reg     : std_logic_vector(31 DOWNTO 0);
  SIGNAL dst_port_reg   : std_logic_vector(15 DOWNTO 0);
  SIGNAL src_mac_reg    : std_logic_vector(47 DOWNTO 0);
  SIGNAL src_ip_reg     : std_logic_vector(31 DOWNTO 0);
  SIGNAL src_port_reg   : std_logic_vector(15 DOWNTO 0);
  SIGNAL pktType_reg    : std_logic_vector(15 DOWNTO 0);
  SIGNAL opcode_reg     : std_logic_vector(15 DOWNTO 0);
  SIGNAL protocol_reg   : std_logic_vector(7 DOWNTO 0);
  SIGNAL udp_cmd_reg    : std_logic_vector(31 DOWNTO 0);
  --
  TYPE parser_state_type IS (S0, S1, S2, S3, S4, S5, S6);
  SIGNAL parser_state   : parser_state_type;
  SIGNAL cmd_state      : parser_state_type;

BEGIN

  clk_i                <= RX_AXIS_FIFO_ACLK;
  RX_AXIS_FIFO_ARESETN <= NOT RESET;
  RX_AXIS_FIFO_TREADY  <= NOT cmd_fifo_full;

  cmd_fifo : fifo128x
    PORT MAP (
      RST    => RESET,
      WR_CLK => clk_i,
      RD_CLK => CMD_FIFO_RDCLK,
      DIN    => cmd_fifo_din,
      WR_EN  => cmd_fifo_wren,
      RD_EN  => CMD_FIFO_RDREQ,
      DOUT   => CMD_FIFO_Q,
      FULL   => cmd_fifo_full,
      EMPTY  => CMD_FIFO_EMPTY
    );

  -- catch the rising edge of tvalid
  PROCESS (clk_i, RESET) IS
  BEGIN
    IF falling_edge(clk_i) THEN
      tvalid_prev <= RX_AXIS_FIFO_TVALID;
      tstart      <= RX_AXIS_FIFO_TVALID AND (NOT tvalid_prev);
    END IF;
  END PROCESS;

  parser_sm : PROCESS (clk_i, RESET) IS
  BEGIN
    IF RESET = '1' THEN
      dst_mac_reg  <= (OTHERS => '0');
      dst_ip_reg   <= (OTHERS => '0');
      dst_port_reg <= (OTHERS => '0');
      src_mac_reg  <= (OTHERS => '0');
      src_ip_reg   <= (OTHERS => '0');
      src_port_reg <= (OTHERS => '0');
      pktType_reg  <= (OTHERS => '0');
      opcode_reg   <= (OTHERS => '0');
      protocol_reg <= (OTHERS => '0');
      udp_cmd_reg  <= (OTHERS => '0');
      parser_state <= S0;
    ELSIF rising_edge(clk_i) THEN
      tlast_i      <= RX_AXIS_FIFO_TLAST;
      parser_state <= S0;
      CASE parser_state IS
        WHEN S0 =>
          IF tstart = '1' THEN
            dst_mac_reg <= RX_AXIS_FIFO_TDATA(7 DOWNTO 0) &
                           RX_AXIS_FIFO_TDATA(15 DOWNTO 8) &
                           RX_AXIS_FIFO_TDATA(23 DOWNTO 16) &
                           RX_AXIS_FIFO_TDATA(31 DOWNTO 24) &
                           RX_AXIS_FIFO_TDATA(39 DOWNTO 32) &
                           RX_AXIS_FIFO_TDATA(47 DOWNTO 40);
            src_mac_reg(47 DOWNTO 32) <= RX_AXIS_FIFO_TDATA(55 DOWNTO 48) &
                                         RX_AXIS_FIFO_TDATA(63 DOWNTO 56);
            parser_state <= S1;
          END IF;
        WHEN S1 =>
          parser_state <= S1;
          IF RX_AXIS_FIFO_TVALID = '1' THEN
            src_mac_reg(31 DOWNTO 0) <= RX_AXIS_FIFO_TDATA(7 DOWNTO 0) &
                                        RX_AXIS_FIFO_TDATA(15 DOWNTO 8) &
                                        RX_AXIS_FIFO_TDATA(23 DOWNTO 16) &
                                        RX_AXIS_FIFO_TDATA(31 DOWNTO 24);
            pktType_reg <= RX_AXIS_FIFO_TDATA(39 DOWNTO 32) &
                           RX_AXIS_FIFO_TDATA(47 DOWNTO 40);
            parser_state <= S2;
          END IF;
        WHEN S2 =>
          parser_state <= S2;
          IF RX_AXIS_FIFO_TVALID = '1' THEN
            opcode_reg <= RX_AXIS_FIFO_TDATA(39 DOWNTO 32) &
                          RX_AXIS_FIFO_TDATA(47 DOWNTO 40);
            protocol_reg <= RX_AXIS_FIFO_TDATA(63 DOWNTO 56);
            parser_state <= S3;
          END IF;
        WHEN S3 =>
          parser_state <= S3;
          IF RX_AXIS_FIFO_TVALID = '1' THEN
            IF pktType_reg = pktType_ARP THEN
              src_ip_reg <= RX_AXIS_FIFO_TDATA(39 DOWNTO 32) &
                            RX_AXIS_FIFO_TDATA(47 DOWNTO 40) &
                            RX_AXIS_FIFO_TDATA(55 DOWNTO 48) &
                            RX_AXIS_FIFO_TDATA(63 DOWNTO 56);
            ELSE
              src_ip_reg <= RX_AXIS_FIFO_TDATA(23 DOWNTO 16) &
                            RX_AXIS_FIFO_TDATA(31 DOWNTO 24) &
                            RX_AXIS_FIFO_TDATA(39 DOWNTO 32) &
                            RX_AXIS_FIFO_TDATA(47 DOWNTO 40);
              dst_ip_reg(31 DOWNTO 16) <= RX_AXIS_FIFO_TDATA(55 DOWNTO 48) &
                                          RX_AXIS_FIFO_TDATA(63 DOWNTO 56);
            END IF;
            parser_state <= S4;
          END IF;
        WHEN S4 =>
          parser_state <= S4;
          IF RX_AXIS_FIFO_TVALID = '1' THEN
            IF pktType_reg = pktType_ARP THEN
              dst_ip_reg(31 DOWNTO 16) <= RX_AXIS_FIFO_TDATA(55 DOWNTO 48) &
                                          RX_AXIS_FIFO_TDATA(63 DOWNTO 56);
            ELSE
              dst_ip_reg(15 DOWNTO 0) <= RX_AXIS_FIFO_TDATA(7 DOWNTO 0) &
                                         RX_AXIS_FIFO_TDATA(15 DOWNTO 8);
              src_port_reg <= RX_AXIS_FIFO_TDATA(23 DOWNTO 16) &
                              RX_AXIS_FIFO_TDATA(31 DOWNTO 24);
              dst_port_reg <= RX_AXIS_FIFO_TDATA(39 DOWNTO 32) &
                              RX_AXIS_FIFO_TDATA(47 DOWNTO 40);
            END IF;
            parser_state <= S5;
          END IF;
        WHEN S5 =>
          parser_state <= S5;
          IF RX_AXIS_FIFO_TVALID = '1' THEN
            IF pktType_reg = pktType_ARP THEN
              dst_ip_reg(15 DOWNTO 0) <= RX_AXIS_FIFO_TDATA(7 DOWNTO 0) &
                                         RX_AXIS_FIFO_TDATA(15 DOWNTO 8);
            ELSE
              udp_cmd_reg <= RX_AXIS_FIFO_TDATA(47 DOWNTO 16);
            END IF;
            IF RX_AXIS_FIFO_TLAST = '1' THEN
              parser_state <= S0;
            ELSE
              parser_state <= S6;
            END IF;
          END IF;
        WHEN S6 =>
          parser_state <= S6;
          IF RX_AXIS_FIFO_TLAST = '1' THEN
            parser_state <= S0;
          END IF;
        WHEN OTHERS =>
          parser_state <= S0;
      END CASE;
    END IF;
  END PROCESS parser_sm;

  PROCESS (clk_i, RESET) IS
  BEGIN
    IF RESET = '1' THEN
      cmd_state <= S0;
    ELSIF falling_edge(clk_i) THEN
      cmd_fifo_wren <= '0';
      cmd_state     <= S0;
      CASE cmd_state IS
        WHEN S0 =>
          IF tlast_i = '1' THEN
            cmd_state <= S1;
          END IF;
        WHEN S1 =>
          IF pktType_reg = pktType_ARP THEN
            IF (dst_ip_reg = SRC_IP) AND (opcode_reg = opcode_REQ) THEN  -- valid ARP request
              cmd_fifo_din  <= src_mac_reg & src_ip_reg & src_port_reg & x"00000000";
              cmd_fifo_wren <= '1';              
            END IF;
          ELSIF (pktType_reg = pktType_IP) AND (protocol_reg = protocol_UDP)
            AND (dst_mac_reg = SRC_MAC) AND (dst_ip_reg = SRC_IP) AND (dst_port_reg = SRC_PORT)
            THEN                        -- valid UDP packet
              cmd_fifo_din  <= src_mac_reg & src_ip_reg & src_port_reg & udp_cmd_reg;
              cmd_fifo_wren <= '1';
          END IF;
          cmd_state <= S0;
        WHEN OTHERS =>
          cmd_state <= S0;
      END CASE;
    END IF;
  END PROCESS;

END Behavioral;
