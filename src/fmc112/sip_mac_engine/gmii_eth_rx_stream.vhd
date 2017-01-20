--------------------------------------------------------------------------------
-- This module receives ethernet packets via the MII or GMII interface to the PHY.
-- It then outputs the ethernet packets in the following streaming format:
--   Bit 9: CKE: Clock enable sets data rate.  Lower bits are only valid if CKE.
--   Bit 8: FRM: Frame signal, asserted for entire ethernet frame
--   Bits 7-0: DAT: Frame data, ignored if not FRM.
--------------------------------------------------------------------------------
-- Notes:
--  The streaming ethernet frame includes all bytes from the Destination MAC through
--  the CRC bytes.
--
--  This module is intended move the received packets from the RXCLK domain into a
--  125MHz internal clock domain.
--
--  Because the 125MHz internal clock can be slightly faster than the RXCLK,
--  it is possible for CKE to deassert for a cycle during the ETH_RX_STREAM
--  frame.  This is not a problem if ETH_RX_STREAM is later stored in a buffer and
--  eventually re-timed.  However, if ETH_RX_STREAM was to drive
--  a RGMII_ETH_TX module directly, the cke sequence would likely not be correct.
--  Ie. cke=1 for duration of frame (1000Mbps)
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Specify Libraries
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_misc.all;
  use ieee.std_logic_unsigned.all;
library unisim;
  use unisim.vcomponents.all;

--------------------------------------------------------------------------------
-- Specify Entity
--------------------------------------------------------------------------------

entity gmii_eth_rx_stream is
port (
  clk125        : in  std_logic;
  rst           : in  std_logic;
  rxclk         : in  std_logic;
  rxd           : in  std_logic_vector(7 downto 0);
  rxctrl        : in  std_logic;
  speed         : in  std_logic_vector(1 downto 0);
  eth_rx_stream : out std_logic_vector(9 downto 0)
);
end entity gmii_eth_rx_stream;

--------------------------------------------------------------------------------
-- Specify Architecture
--------------------------------------------------------------------------------

architecture gmii_eth_rx_stream_syn of gmii_eth_rx_stream is

--------------------------------------------------------------------------------
-- Component declaration
--------------------------------------------------------------------------------

component afifo is
port (
  wr_clk : in  std_logic;
  din    : in  std_logic_vector(8 downto 0);
  wr_en  : in  std_logic;
  rd_clk : in  std_logic;
  rd_en  : in  std_logic;
  dout   : out std_logic_vector(8 downto 0);
  empty  : out std_logic;
  full   : out std_logic
);
end component;

--------------------------------------------------------------------------------
-- Signal declaration
--------------------------------------------------------------------------------

signal rxdat_inff     : std_logic_vector(7 downto 0);
signal rx_en_inff     : std_logic;

signal ge_rxd_byte_en : std_logic; -- ge received byte strobe (skip preamble)
signal ge_rxd_byte    : std_logic_vector(7 downto 0); -- ge received byte
signal ge_frame_low   : std_logic; -- after packet done write 1 extra byte with frame bit cleared

signal fe_rxd_byte_en : std_logic; -- fe received byte strobe
signal fe_rxd_byte    : std_logic_vector(7 downto 0); -- fe received byte
signal fe_tgl         : std_logic; --used to choose nybble location in fe_rxd_byte
signal fe_frame_low   : std_logic; -- after packet done write 1 extra byte with frame bit cleared

signal ge_wr_stb      : std_logic;
signal fe_wr_stb      : std_logic;
signal wr_stb         : std_logic;
signal wr_rx_byte     : std_logic_vector(7 downto 0);
signal wr_rx_frm      : std_logic;

signal out_cnt        : std_logic_vector(3 downto 0); --generate tick for readout of fifo
signal cke            : std_logic;

signal fifo_empty     : std_logic; -- fifo empty indicator
signal fifo_din       : std_logic_vector(8 downto 0);
signal fifo_dout      : std_logic_vector(8 downto 0);
signal fifo_rd_en     : std_logic;

signal out_cke        : std_logic;
signal out_frm        : std_logic; -- set when sfd found
signal out_dat        : std_logic_vector(7 downto 0); --rxd formatted into a byte

attribute keep : string;
attribute keep of rxdat_inff : signal is "TRUE";
attribute keep of rx_en_inff : signal is "TRUE";

--------------------------------------------------------------------------------
-- Begin
--------------------------------------------------------------------------------
begin

--------------------------------------------------------------------------------
-- Input FFs
--------------------------------------------------------------------------------
process (rxclk)
begin
  if (rising_edge(rxclk)) then
    rxdat_inff <= rxd;
    rx_en_inff <= rxctrl;
  end if;
end process;

--------------------------------------------------------------------------------
-- 1000Mbps Mode Sigs
--------------------------------------------------------------------------------
process (rxclk)
begin
  if (rising_edge(rxclk)) then

    ge_rxd_byte <= rxdat_inff;

    if (rx_en_inff = '1' and ge_rxd_byte = x"D5") then
      ge_rxd_byte_en <= '1';
    elsif (rx_en_inff = '0') then
      ge_rxd_byte_en <= '0';
    end if;

    ge_frame_low <= ge_rxd_byte_en and not rx_en_inff;

  end if;
end process;

--------------------------------------------------------------------------------
-- 100Mbps Mode Sigs
--------------------------------------------------------------------------------
process (rxclk)
begin
  if (rising_edge(rxclk)) then

    -- used to choose nybble location in fe_rxd_byte
    if (fe_rxd_byte = x"D5" and fe_rxd_byte_en = '0') then
      fe_tgl <= '0';
    else
      fe_tgl <= not fe_tgl;
    end if;

     -- fe received byte, form 2 consequtive nybbles into a byte
    fe_rxd_byte <= rxdat_inff(3 downto 0) & fe_rxd_byte(7 downto 4);

    -- fe received byte strobe
    if (rx_en_inff = '1' and fe_rxd_byte = x"D5") then
      fe_rxd_byte_en <= '1';
    elsif (rx_en_inff = '0') then
      fe_rxd_byte_en <= '0';
    end if;

    -- after packet done write 1 extra byte with frame bit cleared
    fe_frame_low <= fe_rxd_byte_en and not rx_en_inff;

  end if;
end process;

--------------------------------------------------------------------------------
-- Choose signals based on SPEED
--------------------------------------------------------------------------------

-- strobe for writing to fifo
ge_wr_stb  <= ge_rxd_byte_en or ge_frame_low;
fe_wr_stb  <= (fe_rxd_byte_en and fe_tgl) or fe_frame_low;

wr_stb     <= ge_wr_stb   when SPEED = "10" else fe_wr_stb;
wr_rx_byte <= ge_rxd_byte when SPEED = "10" else fe_rxd_byte;

wr_rx_frm <= '0' when (ge_frame_low = '1' or fe_frame_low = '1') else '1';

--------------------------------------------------------------------------------
-- Use asynchronous fifo to go from RXCLK (125Mhz or 25Mhz) to 125Mhz
--------------------------------------------------------------------------------

process (clk125)
begin
  if (rising_edge(clk125)) then

    if (out_cnt = "1001" or SPEED = "10") then
      out_cnt <= (others => '0');
    else
      out_cnt <= out_cnt + '1';
    end if;

    if (out_cnt = 0) then
      cke <= '1';
    else
      cke <= '0';
    end if;

  end if;
end process;

--------------------------------------------------------------------------------
-- Note: this fifo is a first word fall through type
--------------------------------------------------------------------------------
fifo_din   <= wr_rx_frm & wr_rx_byte;
fifo_rd_en <= not fifo_empty and cke;

afifo_inst : afifo
port map (
  wr_clk => rxclk,
  din    => fifo_din,
  wr_en  => wr_stb,
  rd_clk => clk125,
  rd_en  => fifo_rd_en,
  dout   => fifo_dout,
  empty  => fifo_empty,
  full   => open
);

process (clk125)
begin
  if (rising_edge(clk125)) then

    -- during a frame want to lower_cke when fifo empty, otherwise let it free run
    if (fifo_empty = '1' and out_frm = '1') then
      out_cke <= '0';
    else
      out_cke <= cke;
    end if;

    if (fifo_rd_en = '1') then
      out_frm <= fifo_dout(8);
      out_dat <= fifo_dout(7 downto 0);
    end if;

  end if;
end process;

--------------------------------------------------------------------------------
-- Make our new ethernet format
--------------------------------------------------------------------------------
eth_rx_stream <= out_cke & out_frm & out_dat(7 downto 0);

--------------------------------------------------------------------------------
-- End
--------------------------------------------------------------------------------

end gmii_eth_rx_stream_syn;
