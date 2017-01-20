--------------------------------------------------------------------------------
-- brd_packet_engine.vhd
--------------------------------------------------------------------------------
-- This module manages all of the ethernet communication with
-- the Reference Design Software.  This communication
-- consists of the following packet types:
--
--  Control - various settings to control
--  Auto Offload - offload ADC data to PC
--  Block Write -
--  Block Read -
--
-- When a packet is received a response acknowledge packet is generated
-- to inform the PC that the packet was received.
--
-- Although doing all of this ethernet processing in logic
-- is somewhat expensive, it allows for fast reading and writing
-- of image data.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Specify libraries
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_unsigned.all;
  use ieee.std_logic_misc.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_1164.all;

--------------------------------------------------------------------------------
-- Specify entity
--------------------------------------------------------------------------------

entity brd_packet_engine is
generic (
  MY_MAC            : std_logic_vector(47 downto 0)
);
port (
  -- Destination MAC addresses
  server_mac        : in std_logic_vector(47 downto 0);
  -- Master Clock
  rst               : in std_logic;
  clk               : in std_logic;
  -- Frame Buffer interface
  eth_stream_in     : in  std_logic_vector(9 downto 0);
  eth_stream_out    : out std_logic_vector(9 downto 0);
  out_tick          : in  std_logic;
  link_speed        : in  std_logic_vector(1 downto 0);
  -- Command interface (register read/write)
  out_cmd_val       : out std_logic;
  out_cmd           : out std_logic_vector(63 downto 0);
  in_cmd_val        : in  std_logic;
  in_cmd            : in  std_logic_vector(63 downto 0);
  -- Auto offload interface (data push, with stop)
  auto_start        : in  std_logic;
  auto_channel      : in  std_logic_vector(7 downto 0);
  auto_size         : in  std_logic_vector(31 downto 0);
  auto_data_val     : in  std_logic;
  auto_data         : in  std_logic_vector(63 downto 0);
  auto_data_stop    : out std_logic;
  auto_busy         : out std_logic;
  -- Block write interface (data push, non-stop)
  write_start       : out std_logic;
  write_channel     : out std_logic_vector(7 downto 0);
  write_start_addr  : out std_logic_vector(31 downto 0);
  write_size        : out std_logic_vector(31 downto 0);
  write_data_val    : out std_logic;
  write_data        : out std_logic_vector(63 downto 0);
  -- Block read interface (data push, with stop)
  read_start        : out std_logic;
  read_channel      : out std_logic_vector(7 downto 0);
  read_start_addr   : out std_logic_vector(31 downto 0);
  read_size         : out std_logic_vector(31 downto 0);
  read_data_val     : in  std_logic;
  read_data         : in  std_logic_vector(63 downto 0);
  read_data_stop    : out std_logic
);
end entity brd_packet_engine;

--------------------------------------------------------------------------------
-- Specify Architecture
--------------------------------------------------------------------------------

architecture brd_packet_engine_syn of brd_packet_engine is

--------------------------------------------------------------------------------
-- Declare function
--------------------------------------------------------------------------------

function byteSwap (
  data : std_logic_vector
) return std_logic_vector is

  variable NR_OF_BYTES  : integer := data'length / 8;
  variable LEFT_BYTE    : integer := (data'left+1) / 8 - 1;
  variable data_swapped : std_logic_vector(data'length-1 downto 0);

begin

  for i in 0 to NR_OF_BYTES-1 loop
    data_swapped(i*8+7 downto i*8) := data((LEFT_BYTE-i)*8+7 downto (LEFT_BYTE-i)*8);
  end loop;

  return data_swapped;

end byteSwap;

--------------------------------------------------------------------------------
-- Declare components
--------------------------------------------------------------------------------

component eth_filter is
generic (
  MAC_FILTER     : std_logic_vector(47 downto 0)
);
port (
  rst            : in  std_logic;
  clk            : in  std_logic;
  eth_stream_in  : in  std_logic_vector(9 downto 0);
  eth_stream_out : out std_logic_vector(9 downto 0)
);
end component eth_filter;

component eth_rx_stream_buf is
port (
  rst            : in  std_logic;
  clk            : in  std_logic;
  eth_stream_in  : in  std_logic_vector(9 downto 0);
  eth_stream_out : out std_logic_vector(9 downto 0);
  out_req        : out std_logic;
  out_go         : in  std_logic;
  out_tick       : in  std_logic
);
end component eth_rx_stream_buf;

component fifo_64_to_8 is
port (
  rst          : in  std_logic;
  wr_clk       : in  std_logic;
  rd_clk       : in  std_logic;
  din          : in  std_logic_vector(63 downto 0);
  wr_en        : in  std_logic;
  rd_en        : in  std_logic;
  dout         : out std_logic_vector(7 downto 0);
  full         : out std_logic;
  empty        : out std_logic;
  valid        : out std_logic;
  rd_data_count: out std_logic_vector(10 downto 0);
  wr_data_count: out std_logic_vector(7 downto 0)
);
end component fifo_64_to_8;

component eth_tx_crc is
port (
  clk            : in  std_logic;
  in_eth_stream  : in  std_logic_vector(9 downto 0);
  out_eth_stream : out std_logic_vector(9 downto 0)
);
end component eth_tx_crc;

--------------------------------------------------------------------------------
-- Declare constants
--------------------------------------------------------------------------------

-- Protocol field used in the response packets
constant ETHERTYPE      : std_logic_vector(15 downto 0) := x"F000";

-- Opcodes for different incoming packet types
constant OP_CONTROL     : std_logic_vector(7 downto 0) := x"01";
constant OP_WRITE       : std_logic_vector(7 downto 0) := x"03";
constant OP_READ        : std_logic_vector(7 downto 0) := x"04";

-- Opcodes for different outgoing packet types
constant OP_CONTROL_RET : std_logic_vector(7 downto 0) := x"81";
constant OP_AUTO_RET    : std_logic_vector(7 downto 0) := x"82";
constant OP_WRITE_RET   : std_logic_vector(7 downto 0) := x"83";
constant OP_READ_RET    : std_logic_vector(7 downto 0) := x"84";

-- # of payload bytes (non-image data) past the opcode field
constant MAX_PAYLOAD : integer := 15;

--------------------------------------------------------------------------------
-- Declare signals
--------------------------------------------------------------------------------

signal eth_stream_filt   : std_logic_vector(9 downto 0);
signal eth_stream_buff   : std_logic_vector(9 downto 0);
signal out_req           : std_logic;
signal out_go            : std_logic;

signal in_cke            : std_logic;
signal in_frm            : std_logic;
signal in_dat            : std_logic_vector(7 downto 0);

signal rx_cnt            : std_logic_vector(10 downto 0);
signal rx_opcode         : std_logic_vector(7 downto 0);
signal pyld_byte_en      : std_logic_vector(MAX_PAYLOAD downto 1);

signal cmd               : std_logic_vector(63 downto 0);
signal cmd_val           : std_logic;

signal ao_channel        : std_logic_vector(7 downto 0);
signal ao_frame_addr     : std_logic_vector(31 downto 0);
signal ao_block_size     : std_logic_vector(31 downto 0);
signal ao_block_size_cnt : std_logic_vector(31 downto 0);
signal ao_byte_req       : std_logic;
signal ao_byte_tick      : std_logic;
signal ao_fifo_empty     : std_logic;
signal ao_size           : std_logic_vector(10 downto 0);
signal ao_size_cnt       : std_logic_vector(10 downto 0);
signal ao_frame_size     : std_logic_vector(15 downto 0);
signal snd_ao_ack        : std_logic;
signal ao_byte_val       : std_logic;
signal rd_data_count0    : std_logic_vector(10 downto 0);
signal wr_data_count0    : std_logic_vector(7 downto 0);
--signal ao_data_swap      : std_logic_vector(63 downto 0);
signal ao_byte           : std_logic_vector(7 downto 0);

signal wr_channel        : std_logic_vector(7 downto 0);
signal wr_frame_addr     : std_logic_vector(31 downto 0);
signal wr_block_size     : std_logic_vector(31 downto 0);
signal wr_word           : std_logic_vector(63 downto 0);
signal wr_start          : std_logic;
signal wr_block_addr     : std_logic_vector(31 downto 0);
signal wr_size           : std_logic_vector(10 downto 0);
signal wr_size_cnt       : std_logic_vector(10 downto 0);
signal wr_frame_size     : std_logic_vector(15 downto 0);
signal wr_block_size_cnt : std_logic_vector(31 downto 0);
signal snd_wr_ack        : std_logic;
signal wr_byte_val       : std_logic;
signal wr_1_every_8      : std_logic_vector(7 downto 0);
signal wr_word_val       : std_logic;

signal rd_channel        : std_logic_vector(7 downto 0);
signal rd_block_addr     : std_logic_vector(31 downto 0);
signal rd_frame_addr     : std_logic_vector(31 downto 0);
signal rd_block_size     : std_logic_vector(31 downto 0);
signal rd_start          : std_logic;
signal rd_size           : std_logic_vector(10 downto 0);
signal rd_size_cnt       : std_logic_vector(10 downto 0);
signal rd_frame_size     : std_logic_vector(15 downto 0);
signal rd_block_size_cnt : std_logic_vector(31 downto 0);
signal snd_rd_ack        : std_logic;
signal rd_byte_req       : std_logic;
signal rd_byte_tick      : std_logic;
signal rd_fifo_empty     : std_logic;
signal rd_byte_val       : std_logic;
signal rd_data_count1    : std_logic_vector(10 downto 0);
signal wr_data_count1    : std_logic_vector(7 downto 0);
--signal rd_data_swap      : std_logic_vector(63 downto 0);
signal rd_byte           : std_logic_vector(7 downto 0);

signal eth_busy          : std_logic; -- Set when a command has been issued, cleared when ack has been sent
signal tx_cnt            : std_logic_vector(10 downto 0);
signal tx_shift          : std_logic_vector(207 downto 0);
signal tx_frm            : std_logic;
signal tx_out_tick       : std_logic;

signal ifg_cnt           : std_logic_vector(7 downto 0);
signal tx_busy           : std_logic;

signal tx_stream         : std_logic_vector(9 downto 0);

begin

--------------------------------------------------------------------------------
-- Only accept packets with the right Dst Mac address
--------------------------------------------------------------------------------
eth_filter_inst : eth_filter
generic map (
  MAC_FILTER     => MY_MAC
)
port map (
  rst            => rst,
  clk            => clk,
  eth_stream_in  => eth_stream_in,
  eth_stream_out => eth_stream_filt
);

--------------------------------------------------------------------------------
-- Buffer incoming packets and check CRC
--------------------------------------------------------------------------------
eth_rx_stream_buf_inst : eth_rx_stream_buf
port map (
  rst            => rst,
  clk            => clk,
  eth_stream_in  => eth_stream_filt,
  eth_stream_out => eth_stream_buff,
  out_req        => out_req,
  out_go         => out_go,
  out_tick       => '1' -- always read from fifo at gigabit speeds
);

out_go <= out_req and not eth_busy;

--------------------------------------------------------------------------------
-- Create tick for sending 1000 or 100 Mbps packets
--------------------------------------------------------------------------------
process (clk)
begin
  if (rising_edge(clk)) then

    if (link_speed = 1) then --0 = Off, 1 = 100Mbit, 2 = 1Gbit, 3 = RSVD
      tx_out_tick <= out_tick;
    else
      tx_out_tick <= '1';
    end if;

  end if;
end process;

--------------------------------------------------------------------------------
-- Receive Packets
--------------------------------------------------------------------------------
in_cke <= eth_stream_buff(9);
in_frm <= eth_stream_buff(8);
in_dat <= eth_stream_buff(7 downto 0);

process (clk, rst)
begin
  if (rst = '1') then
    rx_cnt       <= (others => '0');
    rx_opcode    <= (others => '0');
    pyld_byte_en <= (others => '0');
  elsif (rising_edge(clk)) then

    -- Byte Counter
    if (in_cke = '1') then
      if (in_frm = '0') then
        rx_cnt <= (others => '0');
      else
        rx_cnt <= rx_cnt + 1;
      end if;
    end if;

    -- Use shift register to store packet bytes (no reason to be space sensitive!)
    if (in_cke = '1' and rx_cnt = 14) then
      rx_opcode <= in_dat;
      pyld_byte_en <= pyld_byte_en(MAX_PAYLOAD-1 downto 1) & '1';
    elsif (in_cke = '1') then
      rx_opcode <= rx_opcode;
      pyld_byte_en <= pyld_byte_en(MAX_PAYLOAD-1 downto 1) & '0';
    end if;

  end if;
end process;

--------------------------------------------------------------------------------
-- Stellar CMD (register write/read)
--------------------------------------------------------------------------------
process (rst, clk)
begin
  if (rst = '1') then
    cmd         <= (others => '0');
    cmd_val     <= '0';
    out_cmd     <= (others => '0');
    out_cmd_val <= '0';
  elsif (rising_edge(clk)) then

    if (in_cke = '1' and rx_opcode = OP_CONTROL) then

      if (pyld_byte_en(1) = '1') then
        cmd(39 downto 32) <= in_dat;
      end if;

      if (pyld_byte_en(2) = '1') then
        cmd(47 downto 40) <= in_dat;
      end if;

      if (pyld_byte_en(3) = '1') then
        cmd(55 downto 48) <= in_dat;
      end if;

      if (pyld_byte_en(4) = '1') then
        cmd(63 downto 56) <= in_dat;
      end if;

      if (pyld_byte_en(5) = '1') then
        cmd( 7 downto  0) <= in_dat;
      end if;

      if (pyld_byte_en(6) = '1') then
        cmd(15 downto  8) <= in_dat;
      end if;

      if (pyld_byte_en(7) = '1') then
        cmd(23 downto 16) <= in_dat;
      end if;

      if (pyld_byte_en(8) = '1') then
        cmd(31 downto 24) <= in_dat;
      end if;

    end if;

    -- Acknowledge end of control packet
    if (in_cke = '1' and rx_opcode = OP_CONTROL and pyld_byte_en(8) = '1') then
      cmd_val <= '1';
    else
      cmd_val <= '0';
    end if;

    out_cmd_val <= cmd_val;
    out_cmd     <= cmd;

  end if;
end process;

--------------------------------------------------------------------------------
-- Auto Offload
--------------------------------------------------------------------------------
process (rst, clk)
begin
  if (rst = '1') then
    ao_channel        <= (others => '0');
    ao_frame_addr     <= (others => '0');
    ao_block_size     <= (others => '0');
    ao_block_size_cnt <= (others => '0');
    ao_byte_req       <= '0';
    ao_size           <= (others => '0');
    ao_size_cnt       <= (others => '0');
    snd_ao_ack        <= '0';
    auto_busy         <= '0';

  elsif (rising_edge(clk)) then

    if (auto_start = '1') then
      ao_channel    <= auto_channel;
      ao_block_size <= auto_size;
    end if;

    if (auto_start = '1') then
      ao_frame_addr     <= (others => '0');
      ao_block_size_cnt <= auto_size;
    elsif (snd_ao_ack = '1') then
      ao_frame_addr     <= ao_frame_addr     + ao_size;
      ao_block_size_cnt <= ao_block_size_cnt - ao_size;
    end if;

    -- Max frame size
    if (tx_out_tick = '1' and tx_busy = '0' and ao_byte_req = '0' and ao_block_size_cnt >= 1488 and rd_data_count0 >= 1488) then
      ao_byte_req <= '1';
      ao_size     <= conv_std_logic_vector(1488, 11);
      snd_ao_ack  <= '1';

    -- Last frame may be smaller
    elsif (tx_out_tick = '1' and tx_busy = '0' and ao_byte_req = '0' and ao_block_size_cnt > 0 and ao_block_size_cnt < 1488 and rd_data_count0 >= ao_block_size_cnt) then
      ao_byte_req <= '1';
      ao_size     <= ao_block_size_cnt(10 downto 0);
      snd_ao_ack  <= '1';

    -- Clear request bit at the end of a frame
    elsif (ao_byte_tick = '1' and ao_size_cnt = ao_size - 1) then
      ao_byte_req <= '0';
      ao_size     <= ao_size;
      snd_ao_ack  <= '0';

    -- Clear the ack bit, ack should be high for only one clock cycle
    else
      ao_byte_req <= ao_byte_req;
      ao_size     <= ao_size;
      snd_ao_ack  <= '0';

    end if;

    --Frame counter
    if (ao_byte_tick = '1') then
      ao_size_cnt <= ao_size_cnt + '1';
    elsif (ao_byte_req = '0') then
      ao_size_cnt <= (others => '0');
    end if;

    -- Can't reveive a new start until the block size counter is back to 0
    auto_busy <= or_reduce(ao_block_size_cnt);

  end if;
end process;

-- Buffer data to be send through ethernet
fifo_64_to_8_inst0 : fifo_64_to_8
port map (
  rst           => rst,
  wr_clk        => clk,
  rd_clk        => clk,
  din           => byteSwap(auto_data),--ao_data_swap,
  wr_en         => auto_data_val,
  rd_en         => ao_byte_tick,
  dout          => ao_byte,
  full          => open,
  empty         => ao_fifo_empty,
  valid         => ao_byte_val,
  rd_data_count => rd_data_count0,
  wr_data_count => wr_data_count0
);

-- Slow down reading from FIFO in case of 100Mbit Ehternet
ao_byte_tick <= ao_byte_req and tx_out_tick and not ao_fifo_empty;

--AO_DATA_BYTE_SWAP: for i in 0 to 7 generate
--  ao_data_swap(i*8+7 downto i*8) <= auto_data((7-i)*8+7 downto (7-i)*8);
--end generate;

auto_data_stop <= and_reduce(wr_data_count0(wr_data_count0'length-1 downto 4));

--------------------------------------------------------------------------------
-- WRITE BURST
--------------------------------------------------------------------------------
process (clk, rst)
begin
  if (rst = '1') then
    wr_channel        <= (others => '0');
    wr_size           <= (others => '0');
    wr_frame_addr     <= (others => '0');
    wr_block_size     <= (others => '0');
    wr_word           <= (others => '0');
    wr_start          <= '0';
    wr_block_addr     <= (others => '0');
    wr_size_cnt       <= (others => '0');
    wr_block_size_cnt <= (others => '0');
    wr_byte_val       <= '0';
    wr_1_every_8      <= (others => '0');
    wr_word_val       <= '0';
    snd_wr_ack        <= '0';
  elsif (rising_edge(clk)) then

    if (in_cke = '1' and rx_opcode = OP_WRITE) then

      -- Channel(8)
      if (pyld_byte_en(1) = '1') then
        wr_channel <= in_dat;
      end if;

      -- Frame data size(16)
      if (pyld_byte_en(2) = '1') then
        wr_size( 7 downto 0) <= in_dat;
      elsif (pyld_byte_en(3) = '1') then
        wr_size(10 downto 8) <= in_dat(2 downto 0);
      end if;

      -- Start Address(32) of the frame
      if (pyld_byte_en(4) = '1') then
        wr_frame_addr( 7 downto  0) <= in_dat;
      elsif (pyld_byte_en(5) = '1') then
        wr_frame_addr(15 downto  8) <= in_dat;
      elsif (pyld_byte_en(6) = '1') then
        wr_frame_addr(23 downto 16) <= in_dat;
      elsif (pyld_byte_en(7) = '1') then
        wr_frame_addr(31 downto 24) <= in_dat;
      end if;

      -- Block Size(32)
      if (pyld_byte_en(8) = '1') then
        wr_block_size( 7 downto  0) <= in_dat;
      elsif (pyld_byte_en(9) = '1') then
        wr_block_size(15 downto  8) <= in_dat;
      elsif (pyld_byte_en(10) = '1') then
        wr_block_size(23 downto 16) <= in_dat;
      elsif (pyld_byte_en(11) = '1') then
        wr_block_size(31 downto 24) <= in_dat;
      end if;

      -- Data word
      --wr_word <= wr_word(55 downto 0) & in_dat;
      wr_word <= in_dat & wr_word(63 downto 8);

      -- Start pulse (only the first frame, addr=0)
      -- Latch the start address
      if (pyld_byte_en(11) = '1' and wr_frame_addr = 0) then
        wr_start      <= '1';
        wr_block_addr <= wr_frame_addr;
      else
        wr_start      <= '0';
        wr_block_addr <= wr_block_addr;
      end if;

      -- Write counter (this frame)
      if (pyld_byte_en(12) = '1') then
        wr_size_cnt <= wr_size;
      elsif (wr_size_cnt /= 0 and wr_byte_val = '1') then
        wr_size_cnt <= wr_size_cnt - 1;
      end if;

      -- Write counter (all frames)
      if (pyld_byte_en(12) = '1' and wr_frame_addr = 0) then
        wr_block_size_cnt <= wr_block_size;
      elsif (wr_block_size_cnt /= 0 and wr_byte_val = '1') then
        wr_block_size_cnt <= wr_block_size_cnt - 1;
      end if;

      -- Valid; issue one strobe when full 64-bit word available
      if (wr_size_cnt /= 0) then
        wr_byte_val <= '1';
        wr_1_every_8 <= wr_1_every_8(6 downto 0) & wr_1_every_8(7);
      else
        wr_byte_val <= '0';
        wr_1_every_8 <= x"01";
      end if;
      wr_word_val <= wr_1_every_8(6); -- one cycles earlier due to output register

      -- Ack when ready
      if (wr_block_size_cnt = 1 and wr_byte_val = '1') then
        snd_wr_ack <= '1';
      else
        snd_wr_ack <= '0';
      end if;

    end if;

  end if;
end process;

write_start      <= wr_start;
write_channel    <= wr_channel;
write_start_addr <= wr_block_addr;
write_size       <= wr_block_size;
write_data_val   <= wr_word_val;
write_data       <= wr_word;

--------------------------------------------------------------------------------
-- READ BURST
--------------------------------------------------------------------------------

-- Initiate block read command to the firmware
process (rst, clk)
begin
  if (rst = '1') then
    rd_channel    <= (others => '0');
    rd_block_addr <= (others => '0');
    rd_block_size <= (others => '0');
    rd_start      <= '0';

  elsif (rising_edge(clk)) then

    if (in_cke = '1' and rx_opcode = OP_READ) then

      -- Channel(8)
      if (pyld_byte_en(1) = '1') then
        rd_channel <= in_dat;
      end if;

      -- Frame data size(16)
      -- two bytes don't care

      -- Start Address(32)
      if (pyld_byte_en(4) = '1') then
        rd_block_addr( 7 downto  0) <= in_dat;
      elsif (pyld_byte_en(5) = '1') then
        rd_block_addr(15 downto  8) <= in_dat;
      elsif (pyld_byte_en(6) = '1') then
        rd_block_addr(23 downto 16) <= in_dat;
      elsif (pyld_byte_en(7) = '1') then
        rd_block_addr(31 downto 24) <= in_dat;
      end if;

      -- Size(32)
      if (pyld_byte_en(8) = '1') then
        rd_block_size( 7 downto  0) <= in_dat;
      elsif (pyld_byte_en(9) = '1') then
        rd_block_size(15 downto  8) <= in_dat;
      elsif (pyld_byte_en(10) = '1') then
        rd_block_size(23 downto 16) <= in_dat;
      elsif (pyld_byte_en(11) = '1') then
        rd_block_size(31 downto 24) <= in_dat;
      end if;

      -- Start pulse
      if (pyld_byte_en(11) = '1') then
        rd_start <= '1';
      else
        rd_start <= '0';
      end if;

    end if;

  end if;
end process;

read_start      <= rd_start;
read_channel    <= rd_channel;
read_start_addr <= rd_block_addr;
read_size       <= rd_block_size;

-- Samples in the FIFO are send over Ethernet
process (rst, clk)
begin
  if (rst = '1') then
    rd_frame_addr     <= (others => '0');
    rd_block_size_cnt <= (others => '0');
    rd_byte_req       <= '0';
    rd_size           <= (others => '0');
    rd_size_cnt       <= (others => '0');
    snd_rd_ack        <= '0';
    --read_busy         <= '0';

  elsif (rising_edge(clk)) then

    -- Calculate offset address and remaining block size
    if (rd_start = '1') then
      rd_frame_addr     <= rd_block_addr;
      rd_block_size_cnt <= rd_block_size;
    elsif (snd_rd_ack = '1') then
      rd_frame_addr     <= rd_frame_addr     + rd_size;
      rd_block_size_cnt <= rd_block_size_cnt - rd_size;
    end if;

    -- Max frame size
    if (tx_out_tick = '1' and tx_busy = '0' and rd_byte_req = '0' and rd_block_size_cnt >= 1488 and rd_data_count1 >= 1488) then
      rd_byte_req <= '1';
      rd_size     <= conv_std_logic_vector(1488, 11);
      snd_rd_ack  <= '1';

    -- Last frame may be smaller
    elsif (tx_out_tick = '1' and tx_busy = '0' and rd_byte_req = '0' and rd_block_size_cnt > 0 and rd_block_size_cnt < 1488 and rd_data_count1 >= rd_block_size_cnt) then
      rd_byte_req <= '1';
      rd_size     <= rd_block_size_cnt(10 downto 0);
      snd_rd_ack  <= '1';

    -- Clear request bit at the end of a frame
    elsif (rd_byte_tick = '1' and rd_size_cnt = rd_size - 1) then
      rd_byte_req <= '0';
      rd_size     <= rd_size;
      snd_rd_ack  <= '0';

    -- Clear the ack bit, ack should be high for only one clock cycle
    else
      rd_byte_req <= rd_byte_req;
      rd_size     <= rd_size;
      snd_rd_ack  <= '0';

    end if;

    --Frame counter
    if (rd_byte_tick = '1') then
      rd_size_cnt <= rd_size_cnt + '1';
    elsif (rd_byte_req = '0') then
      rd_size_cnt <= (others => '0');
    end if;

    -- Can't reveive a new start until the block size counter is back to 0
    --read_busy <= or_reduce(rd_block_size_cnt);

  end if;
end process;

-- Buffer data to be send through ethernet
fifo_64_to_8_inst1 : fifo_64_to_8
port map (
  rst           => rst,
  wr_clk        => clk,
  rd_clk        => clk,
  din           => byteSwap(read_data),--rd_data_swap,
  wr_en         => read_data_val,
  rd_en         => rd_byte_tick,
  dout          => rd_byte,
  full          => open,
  empty         => rd_fifo_empty,
  valid         => rd_byte_val,
  rd_data_count => rd_data_count1,
  wr_data_count => wr_data_count1
);

-- Slow down reading from FIFO in case of 100Mbit Ehternet
rd_byte_tick <= rd_byte_req and tx_out_tick and not rd_fifo_empty;

--RD_BYTE_BYTE_SWAP: for i in 0 to 7 generate
--  rd_data_swap(i*8+7 downto i*8) <= read_data((7-i)*8+7 downto (7-i)*8);
--end generate;

read_data_stop <= and_reduce(wr_data_count1(wr_data_count1'length-1 downto 4));

--------------------------------------------------------------------------------
-- Add leading zero's to the size field
--------------------------------------------------------------------------------
ao_frame_size <= "00000" & ao_size;
wr_frame_size <= "00000" & wr_size;
rd_frame_size <= "00000" & rd_size;

--------------------------------------------------------------------------------
-- Transmit packets
--------------------------------------------------------------------------------
process (clk, rst)
begin
  if (rst = '1') then
    eth_busy <= '0';
    tx_shift <= (others => '0');
    tx_cnt   <= (others => '0');
    tx_frm   <= '0';
    ifg_cnt  <= (others => '0');
    tx_busy  <= '0';

  elsif (rising_edge(clk)) then

    --if (tx_cnt = 1) then
    eth_busy <= '0'; -- clear when almost done sending
    ----elsif (in_cke = '1' and (rx_cnt = 14) and (in_dat = op_control or in_dat = op_status or in_dat = op_write or in_dat = op_read)) then
    --elsif (in_cke = '1' and (rx_cnt = 14) and (in_dat = op_write or in_dat = op_read)) then
    --  eth_busy <= '1'; -- set when a new opcode received
    --end if;

    -- Minimum frame length (tx_cnt+1) is 64 bytes, including header(14), data(46) and crc(4)
    if (in_cmd_val = '1') then
      tx_shift <= SERVER_MAC & MY_MAC & ETHERTYPE & OP_CONTROL_RET & byteSwap(in_cmd(63 downto 32)) & byteSwap(in_cmd(31 downto 0)) & conv_std_logic_vector(0, 24);
      --tx_cnt <= conv_std_logic_vector(63, 11); -- dst_mac(6) + src_mac(6) + protocol(2) + opcode(1) + addr(4) + data(4) + crc(4) - 1
      tx_cnt <= conv_std_logic_vector(1517, 11); -- dst_mac(6) + src_mac(6) + protocol(2) + payload(1500) + crc(4) - 1
      tx_frm <= '1';

    elsif (snd_ao_ack = '1') then
      tx_shift <= SERVER_MAC & MY_MAC & ETHERTYPE & OP_AUTO_RET    & ao_channel & byteSwap(ao_frame_size) & byteSwap(ao_frame_addr) & byteSwap(ao_block_size);
      --if (ao_size < 34) then
      --  tx_cnt <= conv_std_logic_vector(63, 11);  -- dst_mac(6) + src_mac(6) + protocol(2) + opcode(1) + channel(1) + size(2) + addr(4) + size(4) + ao_size(34) + crc(4) - 1
      --else
      --  tx_cnt <= ao_size(10 downto 0) + 29;      -- dst_mac(6) + src_mac(6) + protocol(2) + opcode(1) + channel(1) + size(2) + addr(4) + size(4) + ao_size(??) + crc(4) - 1
      --end if;
      tx_cnt <= conv_std_logic_vector(1517, 11); -- dst_mac(6) + src_mac(6) + protocol(2) + payload(1500) + crc(4) - 1
      tx_frm <= '1';

    elsif (snd_wr_ack = '1') then
      tx_shift <= SERVER_MAC & MY_MAC & ETHERTYPE & OP_WRITE_RET   & wr_channel & byteSwap(wr_frame_size) & byteSwap(wr_block_addr) & byteSwap(wr_block_size);
      --tx_cnt <= conv_std_logic_vector(63, 11); -- dst_mac(6) + src_mac(6) + protocol(2) + opcode(1) + addr(4) + size(4) + crc(4) - 1
      tx_cnt <= conv_std_logic_vector(1517, 11); -- dst_mac(6) + src_mac(6) + protocol(2) + payload(1500) + crc(4) - 1
      tx_frm <= '1';

    elsif (snd_rd_ack = '1') then
      tx_shift <= SERVER_MAC & MY_MAC & ETHERTYPE & OP_READ_RET    & rd_channel & byteSwap(rd_frame_size) & byteSwap(rd_frame_addr) & byteSwap(rd_block_size);
      --if (rd_size < 34) then
      --  tx_cnt <= conv_std_logic_vector(63, 11); -- dst_mac(6) + src_mac(6) + protocol(2) + opcode(1) + channel(1) + size(2) + addr(4) + size(4) + rd_size(34) + crc(4) - 1
      --else
      --  tx_cnt <= rd_size(10 downto 0) + 29;      -- dst_mac(6) + src_mac(6) + protocol(2) + opcode(1) + channel(1) + size(2) + addr(4) + size(4) + rd_size(??) + crc(4) - 1
      --end if;
      tx_cnt <= conv_std_logic_vector(1517, 11); -- dst_mac(6) + src_mac(6) + protocol(2) + payload(1500) + crc(4) - 1
      tx_frm <= '1';

    elsif (tx_out_tick = '1') then

      if (tx_cnt /= 0) then
        tx_cnt <= tx_cnt - 1;
        tx_frm <= '1';
      else
        tx_cnt <= tx_cnt;
        tx_frm <= '0';
      end if;

      -- Byte injection for 1Gb Ethernet
      if (ao_byte_val = '1') then
        tx_shift <= tx_shift(199 downto 0) & ao_byte;
      elsif (rd_byte_val = '1') then
        tx_shift <= tx_shift(199 downto 0) & rd_byte;
      else
        tx_shift <= tx_shift(199 downto 0) & x"00";
      end if;

    else

      -- Byte injection for 100Mb Ethernet
      if (ao_byte_val = '1') then
        tx_shift <= tx_shift(207 downto 8) & ao_byte;
      elsif (rd_byte_val = '1') then
        tx_shift <= tx_shift(207 downto 8) & rd_byte;
      else
        tx_shift <= tx_shift(207 downto 0);
      end if;

    end if;

    -- Interframe GAP time counter (96 bit times, http://en.wikipedia.org/wiki/Interframe_gap)
    if (tx_frm = '1') then
      ifg_cnt <= conv_std_logic_vector(96, 8);
    elsif (tx_out_tick = '1' and ifg_cnt /= 0) then
      ifg_cnt <= ifg_cnt - '1';
    end if;

    -- Eth Tx is busy during a frame and during the Interframe GAP time
    if (tx_frm = '1' or ifg_cnt /= 0) then
      tx_busy <= '1';
    else
      tx_busy <= '0';
    end if;

  end if;
end process;

--------------------------------------------------------------------------------
-- Add CRC to the stream
--------------------------------------------------------------------------------

tx_stream <= tx_out_tick & tx_frm & tx_shift(207 downto 200);

eth_tx_crc_inst : eth_tx_crc
port map (
  clk            => clk,
  in_eth_stream  => tx_stream,
  out_eth_stream => eth_stream_out
);

--------------------------------------------------------------------------------
-- End
--------------------------------------------------------------------------------

end architecture brd_packet_engine_syn;
