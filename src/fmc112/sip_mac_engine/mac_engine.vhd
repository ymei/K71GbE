--------------------------------------------------------------------------------
-- This is the top level MAC Engine
-- Its the glue logic between the MAC and StellarIP Stars
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

entity mac_engine is
port (
  -- Master reset input
  cpu_reset         : in  std_logic;

  -- Master clock input
  sysclk_p          : in  std_logic;
  sysclk_n          : in  std_logic;
  gpio_led          : out std_logic_vector(3 downto 0);

  -- Ethernet control interface
  phy_reset_l       : out std_logic;
  phy_mdc           : out std_logic;
  phy_mdio          : inout std_logic;

  -- Interface to gigabit phy
  phy_txctl_txen    : out std_logic;
  phy_txer          : out std_logic;
  phy_txc_gtxclk    : out std_logic;
  phy_txclk         : in  std_logic;
  phy_txd           : out std_logic_vector(7 downto 0);

  phy_crs           : in  std_logic;
  phy_col           : in  std_logic;
  phy_rxer          : in  std_logic;
  phy_rxctrl_rxdv   : in  std_logic;
  phy_rxclk         : in  std_logic;
  phy_rxd           : in  std_logic_vector(7 downto 0);

  -- Command interface (register read/write)
  clk_out           : out std_logic;
  rst_out           : out std_logic;

  -- Command interface (register read/write)
  cmd_clk           : out std_logic;
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
end mac_engine;

--------------------------------------------------------------------------------
-- Specify Architecture
--------------------------------------------------------------------------------

architecture mac_engine_syn of mac_engine is

--------------------------------------------------------------------------------
-- Component declaration
--------------------------------------------------------------------------------

component brd_clocks is
port (
  rst             : in  std_logic;
  sysclk_p        : in  std_logic;
  sysclk_n        : in  std_logic;
  pll_lock        : out std_logic;
  clk50           : out std_logic;
  clk125          : out std_logic;
  clk200          : out std_logic
);
end component brd_clocks;

component ge_mac_stream is
port (
  link_speed    : out std_logic_vector(1 downto 0);
  clk50         : in  std_logic;
  phy_reset_l   : out std_logic;
  phy_mdc       : out std_logic;
  phy_mdio      : inout std_logic;
  ge_rxclk      : in  std_logic;
  ge_rxdv       : in  std_logic;
  ge_rxd        : in  std_logic_vector(7 downto 0);
  ge_txclk      : out std_logic;
  ge_txen       : out std_logic;
  ge_txd        : out std_logic_vector(7 downto 0);
  ge_txer       : out std_logic;
  fe_txclk      : in  std_logic;
  fe_out_tick   : out std_logic; -- strobe at 12.5mhz
  clk125        : in  std_logic;
  rst           : in  std_logic;
  eth_rx_stream : out std_logic_vector(9 downto 0);
  eth_tx_stream : in  std_logic_vector(9 downto 0)
);
end component ge_mac_stream;

component brd_packet_engine is
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
end component brd_packet_engine;

component rst_gen
generic ( reset_base :integer:=1024);
port
(


   clk            :in std_logic;
   reset_i        :in std_logic; --reset complete FPGA
   clk_locked     :in std_logic;

   --reset outputs
   dcm_reset                      :out std_logic;
   reset1_o                       :out std_logic;
   reset2_o                       :out std_logic;
   reset3_o                       :out std_logic

   );
end component;

--------------------------------------------------------------------------------
-- Constant declaration
--------------------------------------------------------------------------------

-- MAC addresses
constant SERVER_MAC_DEF      : std_logic_vector(47 downto 0) := x"34_44_53_50_30_30"; -- 4DSP00 --x"00_50_C2_AE_40_00";
constant MY_MAC_DEF          : std_logic_vector(47 downto 0) := x"34_44_53_50_30_31"; -- 4DSP01 --x"00_50_C2_AE_40_01";

-- Stellar Addresses
constant ADDR_SW_RESET       : std_logic_vector(27 downto 0) := x"0000000";
constant ADDR_SERVER_MAC_L   : std_logic_vector(27 downto 0) := x"0000003";
constant ADDR_SERVER_MAC_H   : std_logic_vector(27 downto 0) := x"0000004";

--------------------------------------------------------------------------------
-- Signal declaration
--------------------------------------------------------------------------------
signal pll_lock          : std_logic;
signal clk50             : std_logic;
signal clk125            : std_logic;
signal clk200            : std_logic;
signal rst               : std_logic;

signal rst_cmd           : std_logic;
signal rst_dly           : std_logic_vector(15 downto 0);
signal sw_rst            : std_logic;

signal eth_rx_stream     : std_logic_vector(9 downto 0);
signal eth_tx_stream     : std_logic_vector(9 downto 0);
signal out_tick          : std_logic;
signal link_speed        : std_logic_vector(1 downto 0);

signal server_mac        : std_logic_vector(47 downto 0);

signal out_cmd_val_i     : std_logic;
signal out_cmd_i         : std_logic_vector(63 downto 0);
signal in_cmd_val_i      : std_logic;
signal in_cmd_i          : std_logic_vector(63 downto 0);


signal dcm_reset          :std_logic;
signal reset1_o           :std_logic;
signal reset2_o           :std_logic;
signal reset3_o           :std_logic;

--------------------------------------------------------------------------------
-- Begin
--------------------------------------------------------------------------------
begin

--------------------------------------------------------------------------------
-- Clock generation
--------------------------------------------------------------------------------
brd_clocks_inst : brd_clocks
port map (
  rst             => '0',
  sysclk_p        => sysclk_p,
  sysclk_n        => sysclk_n,
  pll_lock        => pll_lock,
  clk50           => clk50,
  clk125          => clk125,
  clk200          => clk200
);
--reset generation must make sure to reset the phy for at least 10 ms
--reset_i is debounced for 10 ms after asertion
--reset 1 is deaserted 16*reset_base after the dcm reset is deasserted
--reset 2 is deaserted 8*reset_base after the  reset 1 is deasserted
--reset 3 is deaserted 4*reset_base after the  reset 2 is deasserted

i_rst_gen:rst_gen
generic map( reset_base =>80000)
port map
(


   clk            =>clk125,
   reset_i        =>cpu_reset,
   clk_locked     => pll_lock,

   --reset outputs
   dcm_reset        =>dcm_reset,
   reset1_o         =>reset1_o,
   reset2_o         =>reset2_o,
   reset3_o         =>reset3_o
   );
----------------------------------------------------------------------------------------------------
-- Reset generation
----------------------------------------------------------------------------------------------------
rst <=  reset2_o or sw_rst;
phy_reset_l <= not   reset1_o;
--------------------------------------------------------------------------------
-- Ethernet Interface
--------------------------------------------------------------------------------
-- Note: all ethernet traffic is handled in 10-bit streams
-- The ETH_STREAM signal actually includes three signals:
--   Bit 9: CKE: Clock enable sets data rate.  Lower bits are only valid if CKE.
--   Bit 8: FRM: Frame signal, asserted for entire ethernet frame.
--   Bits 7-0: DAT: Frame data, ignored if not FRM.
ge_mac_stream_inst : ge_mac_stream
port map (
  clk50         => clk50,
  phy_reset_l   => open,
  phy_mdc       => phy_mdc,
  phy_mdio      => phy_mdio,
  ge_rxclk      => phy_rxclk,
  ge_rxdv       => phy_rxctrl_rxdv,
  ge_rxd        => phy_rxd,
  ge_txclk      => phy_txc_gtxclk,
  ge_txen       => phy_txctl_txen,
  ge_txd        => phy_txd,
  ge_txer       => phy_txer,
  fe_txclk      => phy_txclk,
  clk125        => clk125,
  rst           => rst,
  eth_rx_stream => eth_rx_stream,
  fe_out_tick   => out_tick, -- strobe at 12.5mhz
  link_speed    => link_speed,
  eth_tx_stream => eth_tx_stream
);

--------------------------------------------------------------------------------
-- Ethernet packet engine
-- Recieves packets from Software, generates response packets
--------------------------------------------------------------------------------
brd_packet_engine_inst : brd_packet_engine
generic map (
  MY_MAC            => MY_MAC_DEF
)
port map (
  server_mac        => server_mac,

  rst               => rst,
  clk               => clk125,
  eth_stream_in     => eth_rx_stream,
  eth_stream_out    => eth_tx_stream,
  out_tick          => out_tick,
  link_speed        => link_speed,

  out_cmd_val       => out_cmd_val_i,
  out_cmd           => out_cmd_i,
  in_cmd_val        => in_cmd_val_i,
  in_cmd            => in_cmd_i,

  auto_start        => auto_start,
  auto_channel      => auto_channel,
  auto_size         => auto_size,
  auto_data_val     => auto_data_val,
  auto_data         => auto_data,
  auto_data_stop    => auto_data_stop,
  auto_busy         => auto_busy,

  write_start       => write_start,
  write_channel     => write_channel,
  write_start_addr  => write_start_addr,
  write_size        => write_size,
  write_data_val    => write_data_val,
  write_data        => write_data,

  read_start        => read_start,
  read_channel      => read_channel,
  read_start_addr   => read_start_addr,
  read_size         => read_size,
  read_data_val     => read_data_val,
  read_data         => read_data,
  read_data_stop    => read_data_stop
);

--------------------------------------------------------------------------------
-- Software reset
--------------------------------------------------------------------------------
process (clk125)
begin
  if (rising_edge(clk125)) then

    -- Software Reset
    if (out_cmd_val_i = '1' and out_cmd_i(63 downto 60) = x"1" and out_cmd_i(59 downto 32) = ADDR_SW_RESET) then
      rst_cmd <= out_cmd_i(0);
    else
      rst_cmd <= '0';
    end if;

    rst_dly <= rst_dly(rst_dly'length-2 downto 0) & rst_cmd;

    sw_rst <= or_reduce(rst_dly);

  end if;
end process;

--------------------------------------------------------------------------------
-- Registers
--------------------------------------------------------------------------------
process (rst, clk125)
begin
  if (rst = '1') then
    server_mac   <= SERVER_MAC_DEF;
    in_cmd_val_i <= '0';
    in_cmd_i     <= (others => '0');

  elsif (rising_edge(clk125)) then

    -- Write to Server MAC registers
    if (out_cmd_val_i = '1' and out_cmd_i(63 downto 60) = x"1" and out_cmd_i(59 downto 32) = ADDR_SERVER_MAC_L) then
      server_mac(31 downto 0) <= out_cmd_i(31 downto 0);
    elsif (out_cmd_val_i = '1' and out_cmd_i(63 downto 60) = x"1" and out_cmd_i(59 downto 32) = ADDR_SERVER_MAC_H) then
      server_mac(47 downto 32) <= out_cmd_i(15 downto 0);
    end if;

    -- Read registers
    if (out_cmd_val_i = '1' and out_cmd_i(63 downto 60) = x"2" and out_cmd_i(59 downto 32) = ADDR_SERVER_MAC_L) then
      in_cmd_val_i <= '1';
      in_cmd_i(63 downto 60) <= x"4";
      in_cmd_i(59 downto 32) <= out_cmd_i(59 downto 32);
      in_cmd_i(31 downto  0) <= server_mac(31 downto 0);
    elsif (out_cmd_val_i = '1' and out_cmd_i(63 downto 60) = x"2" and out_cmd_i(59 downto 32) = ADDR_SERVER_MAC_H) then
      in_cmd_val_i <= '1';
      in_cmd_i(63 downto 60) <= x"4";
      in_cmd_i(59 downto 32) <= out_cmd_i(59 downto 32);
      in_cmd_i(31 downto  0) <= conv_std_logic_vector(0, 16) & server_mac(47 downto 32);
    else
      in_cmd_val_i <= in_cmd_val;
      in_cmd_i     <= in_cmd;
    end if;

  end if;
end process;

--------------------------------------------------------------------------------
-- IDELAYCTRL
--------------------------------------------------------------------------------
idelayctrl_inst : idelayctrl
port map (
  rst    => rst,
  refclk => clk200,
  rdy    => open
);

--------------------------------------------------------------------------------
-- Connect entity
--------------------------------------------------------------------------------
clk_out     <= clk125;
rst_out     <= rst;
cmd_clk     <= clk125;
out_cmd_val <= out_cmd_val_i;
out_cmd     <= out_cmd_i;

gpio_led(0) <= pll_lock;
gpio_led(1) <= not pll_lock;
gpio_led(2) <= rst;
gpio_led(3) <= '0';

--------------------------------------------------------------------------------
-- End
--------------------------------------------------------------------------------

end mac_engine_syn;


