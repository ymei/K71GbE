--------------------------------------------------------------------------------
-- eth_rx_pkt_buf_2048.vhd
--------------------------------------------------------------------------------
-- This is a module used to store received ethernet packet streams.
-- This Buffer uses a block ram to store up to 2048 Bytes of packet data.
-- If there isn't enough buffer space for a new packet or the packet has a
-- invalid checksum, the packet is dropped.
-- The packets are stored in block ram as sections of contiguous bytes specified by
-- setting the block ram parity bit = 1.  These frames are seperated by
-- 2 consequtive cells where the parity bit = 0.
--------------------------------------------------------------------------------
-- The ETH_STREAM signal actually includes three signals:
--   Bit 9: CKE: Clock enable sets data rate.  Lower bits are only valid if CKE.
--   Bit 8: FRM: Frame signal, asserted for entire ethernet frame.
--   Bits 7-0: DAT: Frame data, ignored if not FRM.
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

entity eth_rx_stream_buf is
port (
  -- Master clock
	rst             : in  std_logic;
	clk             : in  std_logic;
  -- Input/Output streams
	eth_stream_in   : in  std_logic_vector(9 downto 0);
	eth_stream_out  : out std_logic_vector(9 downto 0);
  -- Output arbitration
	out_req         : out std_logic; -- we have a packet to send
	out_go          : in  std_logic; -- strobe says we can send one!
	out_tick        : in  std_logic  -- sets the output data rate.
);
end entity;

--------------------------------------------------------------------------------
-- Specify Architecture
--------------------------------------------------------------------------------

architecture eth_rx_stream_buf_syn of eth_rx_stream_buf is

--------------------------------------------------------------------------------
-- Component declaration
--------------------------------------------------------------------------------

component eth_rx_crc is
port (
	clk            : in  std_logic;
	in_eth_stream  : in  std_logic_vector(9 downto 0);
	out_eth_stream : out std_logic_vector(9 downto 0);
	out_start_stb  : out std_logic;
	out_dat        : out std_logic_vector(7 downto 0);
	out_dat_stb    : out std_logic;
	out_ok_stb     : out std_logic;
	out_bad_stb    : out std_logic
);
end component eth_rx_crc;

component ramb16_s9_s9 is
port (
	-- Port A -- Written to when receiving
	clka   : in  std_logic;
	addra  : in  std_logic_vector(10 downto 0);
	dia    : in  std_logic_vector(7 downto 0);
	dipa   : in  std_logic_vector(0 downto 0);
	wea    : in  std_logic;
	doa    : out std_logic_vector(7 downto 0);
	dopa   : out std_logic_vector(0 downto 0);
	ena    : in  std_logic;
	ssra   : in  std_logic;
	-- Port B -- Read from
  clkb   : in  std_logic;
  addrb  : in  std_logic_vector(10 downto 0);
  dib    : in  std_logic_vector(7 downto 0);
  dipb   : in  std_logic_vector(0 downto 0);
  web    : in  std_logic;
  dob    : out std_logic_vector(7 downto 0);
  dopb   : out std_logic_vector(0 downto 0);
  enb    : in  std_logic;
  ssrb   : in  std_logic
);
end component ramb16_s9_s9;

--------------------------------------------------------------------------------
-- Signal declaration
--------------------------------------------------------------------------------

signal crc_out_stream  : std_logic_vector(9 downto 0);

signal start_stb       : std_logic;
signal dat_stb         : std_logic;
signal ok_stb          : std_logic;
signal bad_stb         : std_logic;

signal dat             : std_logic_vector(7 downto 0);
signal wrt_a           : std_logic_vector(10 downto 0);
signal wrt_a_sv        : std_logic_vector(10 downto 0);
signal wrt_a_nxt       : std_logic_vector(10 downto 0);
signal rd_a            : std_logic_vector(10 downto 0);
signal wr_e_p_s        : std_logic;
signal wr_en           : std_logic;

signal out_go_reg      : std_logic;
signal out_req_reg     : std_logic;
signal rd_dat          : std_logic_vector(7 downto 0);
signal rd_frm          : std_logic;

signal dipa            : std_logic_vector(0 downto 0);
signal dopb            : std_logic_vector(0 downto 0);

--------------------------------------------------------------------------------
-- Begin
--------------------------------------------------------------------------------

begin

--------------------------------------------------------------------------------
-- Test the CRC
--------------------------------------------------------------------------------

eth_rx_crc_inst : eth_rx_crc
port map (
	clk            => clk,
	in_eth_stream  => eth_stream_in,
	out_eth_stream => crc_out_stream,
	out_start_stb  => start_stb,
	out_dat        => dat,
	out_dat_stb    => dat_stb,
	out_ok_stb     => ok_stb,
	out_bad_stb    => bad_stb
);

--------------------------------------------------------------------------------
-- Write the incoming packet if there is space
--------------------------------------------------------------------------------

-- Next write address
wrt_a_nxt <= wrt_a + 1;

-- Strobe to write a second inter-packet-gap (simplifies packet readout)
wr_en <= '1' when (dat_stb = '1' or ok_stb = '1' or wr_e_p_s = '1') and (wrt_a /= wrt_a_sv) else
         '1' when rst = '1' else --writes 0 to RAM
         '0';

process (rst, clk)
begin
  if (rst = '1') then
    wrt_a    <= (others => '0');
    wrt_a_sv <= (others => '0');
    wr_e_p_s <= '0';
  elsif (rising_edge(clk)) then

	  if (dat_stb = '1' or start_stb = '1' or ok_stb = '1') then

	    if (wrt_a_nxt = rd_a) then -- reached end of unused space in fifo, restore ptr to start
	      wrt_a <= wrt_a_sv;
	    elsif (wrt_a /= wrt_a_sv or start_stb = '1') then
	      wrt_a <= wrt_a + 1;
	    end if;

	  end if;

    if (wr_e_p_s = '1') then
      wrt_a_sv <= wrt_a;
    end if;

    -- Strobe to write a second inter-packet-gap (simplifies packet readout)
	  wr_e_p_s <= ok_stb;


  end if;
end process;

--------------------------------------------------------------------------------
-- Stream out the stored packets
--------------------------------------------------------------------------------
process (clk)
begin
  if (rst = '1') then
    out_go_reg  <= '0';
    rd_a        <= (others => '0');
    out_req_reg <= '0';
  elsif (rising_edge(clk)) then

    if (out_go = '1' and out_req_reg = '1') then
      out_go_reg <= '1';
    elsif (out_tick = '1') then
      out_go_reg <= '0';
    end if;

	  if (out_tick = '1') then

	    if (out_go_reg = '1' or rd_frm = '1') then
		    rd_a <= rd_a + 1;
		  end if;

      if (wrt_a_sv /= rd_a and rd_frm = '0' and out_go_reg = '0') then
        out_req_reg <= '1';
      else
        out_req_reg <= '0';
      end if;

	  end if;

  end if;
end process;

out_req <= out_req_reg;

--------------------------------------------------------------------------------
--Receive buffer RAM
--------------------------------------------------------------------------------
ramb16_s9_s9_inst : ramb16_s9_s9
port map(
	-- Port A -- Written to when receiving
	clka   => clk,
	addra  => wrt_a,
	dia    => dat,
	dipa   => dipa,
	wea    => wr_en,
	doa    => open,
	dopa   => open,
	ena    => '1',
	ssra   => '0',
	-- Port B -- Read from
  clkb   => clk,
  addrb  => rd_a,
  dib    => "00000000",
  dipb   => "0",
  web    => '0',
  dob    => rd_dat,
  dopb   => dopb,
  enb    => out_tick,
  ssrb   => '0'
);

dipa(0) <= dat_stb;
rd_frm  <= dopb(0);

--------------------------------------------------------------------------------
-- Register the outputs
--------------------------------------------------------------------------------
process (rst, clk)
begin
  if (rst = '1') then
    eth_stream_out <= (others => '0');

  elsif (rising_edge(clk)) then

    eth_stream_out(9) <= out_tick;
    eth_stream_out(8) <= rd_frm;
    eth_stream_out(7 downto 0) <= rd_dat;

  end if;
end process;

--------------------------------------------------------------------------------
-- End
--------------------------------------------------------------------------------

end eth_rx_stream_buf_syn;





