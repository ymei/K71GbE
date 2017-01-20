-------------------------------------------------------------------------------------
-- FILE NAME : fmc112_if.vhd
--
-- AUTHOR    : Remon Zandvliet
--
-- COMPANY   : 4DSP
--
-- ITEM      : 1
--
-- UNITS     : Entity       - fmc112_if
--             architecture - fmc112_if_syn
--
-- LANGUAGE  : VHDL
--
-------------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------------
-- DESCRIPTION
-- ===========
--
-- fmc112_if
-- Notes: fmc112_if
-------------------------------------------------------------------------------------
--  Disclaimer: LIMITED WARRANTY AND DISCLAIMER. These designs are
--              provided to you as is.  4DSP specifically disclaims any
--              implied warranties of merchantability, non-infringement, or
--              fitness for a particular purpose. 4DSP does not warrant that
--              the functions contained in these designs will meet your
--              requirements, or that the operation of these designs will be
--              uninterrupted or error free, or that defects in the Designs
--              will be corrected. Furthermore, 4DSP does not warrant or
--              make any representations regarding use or the results of the
--              use of the designs in terms of correctness, accuracy,
--              reliability, or otherwise.
--
--              LIMITATION OF LIABILITY. In no event will 4DSP or its
--              licensors be liable for any loss of data, lost profits, cost
--              or procurement of substitute goods or services, or for any
--              special, incidental, consequential, or indirect damages
--              arising from the use or operation of the designs or
--              accompanying documentation, however caused and on any theory
--              of liability. This limitation will apply even if 4DSP
--              has been advised of the possibility of such damage. This
--              limitation shall apply not-withstanding the failure of the
--              essential purpose of any limited remedies herein.
--
----------------------------------------------

-- Library declarations
library ieee;
  use ieee.std_logic_unsigned.all;
  use ieee.std_logic_misc.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_1164.all;
library unisim;
  use unisim.vcomponents.all;
library work;

entity fmc112_if is
generic (
  START_ADDR       : std_logic_vector(27 downto 0) := x"0000000";
  STOP_ADDR        : std_logic_vector(27 downto 0) := x"00000FF"
);
port (
  -- Global signals
  rst              : in    std_logic;
  clk              : in    std_logic;

  -- Command Interface
  clk_cmd          : in    std_logic;
  in_cmd_val       : in    std_logic;
  in_cmd           : in    std_logic_vector(63 downto 0);
  out_cmd_val      : out   std_logic;
  out_cmd          : out   std_logic_vector(63 downto 0);
  out_cmd_busy     : out   std_logic;

  --Output ports for ADC data
  phy_data_clk     : out std_logic;                     -- ADC data clk
  phy_out_data0    : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data1    : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data2    : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data3    : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data4    : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data5    : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data6    : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data7    : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data8    : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data9    : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data10   : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data11   : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format

  --External signals
  ctrl             : inout std_logic_vector(7 downto 0);

  clk_to_fpga_p    : in    std_logic;
  clk_to_fpga_n    : in    std_logic;
  ext_trigger_p    : in    std_logic;
  ext_trigger_n    : in    std_logic;
  ext_trigger      : out   std_logic;

  dco_p            : in    std_logic_vector(2 downto 0);
  dco_n            : in    std_logic_vector(2 downto 0);
  frame_p          : in    std_logic_vector(2 downto 0);
  frame_n          : in    std_logic_vector(2 downto 0);
  outa_p           : in    std_logic_vector(11 downto 0);
  outa_n           : in    std_logic_vector(11 downto 0);
  outb_p           : in    std_logic_vector(11 downto 0);
  outb_n           : in    std_logic_vector(11 downto 0);

  pg_m2c           : in    std_logic;
  prsnt_m2c_l      : in    std_logic

);
end fmc112_if;

architecture fmc112_if_syn of fmc112_if is

----------------------------------------------------------------------------------------------------
-- Constant declaration
----------------------------------------------------------------------------------------------------
constant START_ADDR_FMC112_CTRL    : std_logic_vector(27 downto 0) := START_ADDR + x"0000000";
constant STOP_ADDR_FMC112_CTRL     : std_logic_vector(27 downto 0) := START_ADDR + x"000000F"; --min. range 16#0010

constant START_ADDR_LTC2175_PHY    : std_logic_vector(27 downto 0) := START_ADDR + x"0000010";
constant STOP_ADDR_LTC2175_PHY     : std_logic_vector(27 downto 0) := START_ADDR + x"000001F"; --min. range 16#0010

constant START_ADDR_LTC2175_CTRL0  : std_logic_vector(27 downto 0) := START_ADDR + x"0000100";
constant STOP_ADDR_LTC2175_CTRL0   : std_logic_vector(27 downto 0) := START_ADDR + x"000010F"; --min. range 16#0010

constant START_ADDR_LTC2175_CTRL1  : std_logic_vector(27 downto 0) := START_ADDR + x"0000110";
constant STOP_ADDR_LTC2175_CTRL1   : std_logic_vector(27 downto 0) := START_ADDR + x"000011F"; --min. range 16#0010

constant START_ADDR_LTC2175_CTRL2  : std_logic_vector(27 downto 0) := START_ADDR + x"0000120";
constant STOP_ADDR_LTC2175_CTRL2   : std_logic_vector(27 downto 0) := START_ADDR + x"000012F"; --min. range 16#0010

constant START_ADDR_LTC2175_CTRL3  : std_logic_vector(27 downto 0) := START_ADDR + x"0000130";
constant STOP_ADDR_LTC2175_CTRL3   : std_logic_vector(27 downto 0) := START_ADDR + x"000013F"; --min. range 16#0010

constant START_ADDR_AD9517_CTRL    : std_logic_vector(27 downto 0) := START_ADDR + x"0000300";
constant STOP_ADDR_AD9517_CTRL     : std_logic_vector(27 downto 0) := START_ADDR + x"0000533"; --min. range 16#0234

constant START_ADDR_FREQ_CNT       : std_logic_vector(27 downto 0) := START_ADDR + x"0000600";
constant STOP_ADDR_FREQ_CNT        : std_logic_vector(27 downto 0) := START_ADDR + x"0000601"; --min. range 16#0002

constant START_ADDR_LTC2656_CTRL0  : std_logic_vector(27 downto 0) := START_ADDR + x"0000700";
constant STOP_ADDR_LTC2656_CTRL0   : std_logic_vector(27 downto 0) := START_ADDR + x"00007FF"; --min. range 16#0100

constant START_ADDR_LTC2656_CTRL1  : std_logic_vector(27 downto 0) := START_ADDR + x"0000800";
constant STOP_ADDR_LTC2656_CTRL1   : std_logic_vector(27 downto 0) := START_ADDR + x"00008FF"; --min. range 16#0100

constant START_ADDR_CPLD_CTRL      : std_logic_vector(27 downto 0) := START_ADDR + x"0000920";
constant STOP_ADDR_CPLD_CTRL       : std_logic_vector(27 downto 0) := START_ADDR + x"0000924"; --min. range 16#0010

----------------------------------------------------------------------------------------------------
--CPLD Preselection Bytes
----------------------------------------------------------------------------------------------------
constant PRESEL_CPLD  : std_logic_vector(7 downto 0) := x"00";
constant PRESEL_ADC0  : std_logic_vector(7 downto 0) := x"80";
constant PRESEL_ADC1  : std_logic_vector(7 downto 0) := x"81";
constant PRESEL_ADC2  : std_logic_vector(7 downto 0) := x"82";
constant PRESEL_ADC3  : std_logic_vector(7 downto 0) := x"83";
constant PRESEL_CLK0  : std_logic_vector(7 downto 0) := x"84";
constant PRESEL_DAC0  : std_logic_vector(7 downto 0) := x"85";
constant PRESEL_DAC1  : std_logic_vector(7 downto 0) := x"86";

constant NB_CHANNELS  : integer := 12;
constant AD_BITS      : integer := 16; --ADC resolution
constant WH_BITS      : integer := 64; --Wormhole bit-width
constant NB_CMD_BUS   : integer := 11; --Number of local command busses

----------------------------------------------------------------------------------------------------
--Type declaration
----------------------------------------------------------------------------------------------------
type STD2D_AD_BITS is array(natural range <>) of std_logic_vector(AD_BITS-1 downto 0);
type STD2D_WH_BITS is array(natural range <>) of std_logic_vector(WH_BITS-1 downto 0);
type STD2D_COMMAND is array(natural range <>) of std_logic_vector(63 downto 0);

----------------------------------------------------------------------------------------------------
--Signal declaration
----------------------------------------------------------------------------------------------------
signal cmd_val              : std_logic_vector(NB_CMD_BUS-1 downto 0);
signal cmd                  : STD2D_COMMAND(NB_CMD_BUS-1 downto 0);
signal cmd_busy             : std_logic_vector(NB_CMD_BUS-1 downto 0);

signal sclk_prebuf          : std_logic;
signal serial_clk           : std_logic;
signal sclk_ext             : std_logic;

signal    init_ena_ad9517   : std_logic;
signal   init_done_ad9517   : std_logic;
signal   init_ena_ltc2175_0 : std_logic;
signal  init_done_ltc2175_0 : std_logic;
signal   init_ena_ltc2175_1 : std_logic;
signal  init_done_ltc2175_1 : std_logic;
signal   init_ena_ltc2175_2 : std_logic;
signal  init_done_ltc2175_2 : std_logic;
signal   init_ena_ltc2175_3 : std_logic;
signal  init_done_ltc2175_3 : std_logic;
signal   init_ena_ltc2656_0 : std_logic;
signal  init_done_ltc2656_0 : std_logic;
signal   init_ena_ltc2656_1 : std_logic;
signal  init_done_ltc2656_1 : std_logic;
signal      init_ena_cpld   : std_logic;
signal     init_done_cpld   : std_logic;

signal        spi_n_oe0     : std_logic_vector(7 downto 0);
signal        spi_n_cs0     : std_logic_vector(7 downto 0);
signal        spi_sclk0     : std_logic_vector(7 downto 0);
signal         spi_sdo0     : std_logic_vector(7 downto 0);
signal         spi_sdi0     : std_logic_vector(7 downto 0);

signal        spi_n_oe      : std_logic;
signal        spi_n_cs      : std_logic;
signal        spi_sclk      : std_logic;
signal         spi_sdo      : std_logic;
signal         spi_sdi      : std_logic;

signal ctrl_clk             : std_logic;
signal phy_out_clk          : std_logic_vector(15 downto 0);
signal phy_out_data         : STD2D_AD_BITS(NB_CHANNELS-1 downto 0);

signal fifo_wr_en           : std_logic_vector(15 downto 0);
signal fifo_empty           : std_logic_vector(15 downto 0);
signal fifo_full            : std_logic_vector(15 downto 0);

signal adc_out_stop         : std_logic_vector(15 downto 0);
signal adc_out_dval         : std_logic_vector(15 downto 0);
signal adc_out_data         : STD2D_WH_BITS(NB_CHANNELS-1 downto 0);

signal test_clocks          : std_logic_vector(15 downto 0);
signal dco                  : std_logic_vector(3 downto 0);

signal ext_trigger_buf      : std_logic;

signal clk_to_fpga_buf      : std_logic;
signal clk_to_fpga          : std_logic;

----------------------------------------------------------------------------------------------------
--Component declaration
----------------------------------------------------------------------------------------------------
component fmc112_ctrl is
  generic
  (
    START_ADDR             : std_logic_vector(27 downto 0) := x"0000000";
    STOP_ADDR              : std_logic_vector(27 downto 0) := x"00000FF"
  );
  port (
    rst                    : in  std_logic;

    -- Command Interface
    clk_cmd                : in    std_logic;
    in_cmd_val             : in    std_logic;
    in_cmd                 : in    std_logic_vector(63 downto 0);
    out_cmd_val            : out   std_logic;
    out_cmd                : out   std_logic_vector(63 downto 0);
    cmd_busy               : out   std_logic;

    --External trigger
    ext_trigger_p          : in  std_logic;
    ext_trigger_n          : in  std_logic;
    ext_trigger_buf        : out std_logic;

    --Output FIFO Control
    adc_clk                : in  std_logic;
    fifo_wr_en             : out std_logic_vector(15 downto 0);
    fifo_empty             : in  std_logic_vector(15 downto 0);
    fifo_full              : in  std_logic_vector(15 downto 0);

    --FMC status
    pg_m2c                 : in  std_logic;
    prsnt_m2c_l            : in  std_logic

  );
end component;

component ltc2175_phy is
  generic
  (
    START_ADDR     : std_logic_vector(27 downto 0) := x"0000000";
    STOP_ADDR      : std_logic_vector(27 downto 0) := x"00000FF"
  );
  port (
    -- Global signals
    rst            : in  std_logic;

    -- Command Interface
    clk_cmd        : in  std_logic;
    in_cmd_val     : in  std_logic;
    in_cmd         : in  std_logic_vector(63 downto 0);
    out_cmd_val    : out std_logic;
    out_cmd        : out std_logic_vector(63 downto 0);
    in_cmd_busy    : out std_logic;

    -- DDR LVDS Interface
    dco_p          : in    std_logic_vector(3 downto 0);
    dco_n          : in    std_logic_vector(3 downto 0);
    frame_p        : in    std_logic_vector(3 downto 0);
    frame_n        : in    std_logic_vector(3 downto 0);
    outa_p         : in    std_logic_vector(15 downto 0);
    outa_n         : in    std_logic_vector(15 downto 0);
    outb_p         : in    std_logic_vector(15 downto 0);
    outb_n         : in    std_logic_vector(15 downto 0);

    -- Output port
    ctrl_clk       : out std_logic;                     -- Global clock from ADC0
    phy_out_clk    : out std_logic_vector(15 downto 0); -- clock equals sample frequecy (regional)
    phy_out_data0  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data1  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data2  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data3  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data4  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data5  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data6  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data7  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data8  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data9  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data10 : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data11 : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data12  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data13  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data14 : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data15 : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    -- Output clocks (for monitoring and test purposes)
    dco            : out std_logic_vector(3 downto 0)

  );
end component;

component fmc112_ltc2175_fifo is
  port (
    rst        : in  std_logic;
    -- Input port
    phy_clk    : in  std_logic;
    fifo_wr_clk : in std_logic;
    phy_data   : in  std_logic_vector(15 downto 0);

    fifo_wr_en : in  std_logic;
    fifo_empty : out std_logic;
    fifo_full  : out std_logic;

    -- Output port
    if_clk     : in  std_logic;
    if_stop    : in  std_logic;
    if_dval    : out std_logic;
    if_data    : out std_logic_vector(63 downto 0)
  );
end component;

component fmc112_cpld_ctrl is
generic (
  START_ADDR      : std_logic_vector(27 downto 0) := x"0000000";
  STOP_ADDR       : std_logic_vector(27 downto 0) := x"00000FF";
  PRESEL          : std_logic_vector(7 downto 0) := x"00"
);
port (
  rst             : in  std_logic;
  clk             : in  std_logic;
  serial_clk      : in  std_logic;
  sclk_ext        : in  std_logic;
  -- Sequence interface
  init_ena        : in  std_logic;
  init_done       : out std_logic;
  -- Command Interface
  clk_cmd         : in  std_logic;
  in_cmd_val      : in  std_logic;
  in_cmd          : in  std_logic_vector(63 downto 0);
  out_cmd_val     : out std_logic;
  out_cmd         : out std_logic_vector(63 downto 0);
  in_cmd_busy     : out std_logic;
  -- SPI control
  spi_n_oe        : out std_logic;
  spi_n_cs        : out std_logic;
  spi_sclk        : out std_logic;
  spi_sdo         : out std_logic;
  spi_sdi         : in  std_logic
);
end component;

component fmc112_ad9517_ctrl is
generic (
  START_ADDR      : std_logic_vector(27 downto 0) := x"0000000";
  STOP_ADDR       : std_logic_vector(27 downto 0) := x"00000FF";
  PRESEL          : std_logic_vector(7 downto 0) := x"00"
);
port (
  rst             : in  std_logic;
  clk             : in  std_logic;
  serial_clk      : in  std_logic;
  sclk_ext        : in  std_logic;
  -- Sequence interface
  init_ena        : in  std_logic;
  init_done       : out std_logic;
  -- Command Interface
  clk_cmd         : in  std_logic;
  in_cmd_val      : in  std_logic;
  in_cmd          : in  std_logic_vector(63 downto 0);
  out_cmd_val     : out std_logic;
  out_cmd         : out std_logic_vector(63 downto 0);
  in_cmd_busy     : out std_logic;
  -- SPI control
  spi_n_oe        : out std_logic;
  spi_n_cs        : out std_logic;
  spi_sclk        : out std_logic;
  spi_sdo         : out std_logic;
  spi_sdi         : in  std_logic
);
end component;

component fmc112_ltc2175_ctrl is
generic (
  START_ADDR      : std_logic_vector(27 downto 0) := x"0000000";
  STOP_ADDR       : std_logic_vector(27 downto 0) := x"00000FF";
  PRESEL          : std_logic_vector(7 downto 0) := x"00"
);
port (
  rst             : in  std_logic;
  clk             : in  std_logic;
  serial_clk      : in  std_logic;
  sclk_ext        : in  std_logic;
  -- Sequence interface
  init_ena        : in  std_logic;
  init_done       : out std_logic;
  -- Command Interface
  clk_cmd         : in  std_logic;
  in_cmd_val      : in  std_logic;
  in_cmd          : in  std_logic_vector(63 downto 0);
  out_cmd_val     : out std_logic;
  out_cmd         : out std_logic_vector(63 downto 0);
  in_cmd_busy     : out std_logic;
  -- SPI control
  spi_n_oe        : out std_logic;
  spi_n_cs        : out std_logic;
  spi_sclk        : out std_logic;
  spi_sdo         : out std_logic;
  spi_sdi         : in  std_logic
);
end component;

component fmc112_ltc2656_ctrl is
generic (
  START_ADDR      : std_logic_vector(27 downto 0) := x"0000000";
  STOP_ADDR       : std_logic_vector(27 downto 0) := x"00000FF";
  PRESEL          : std_logic_vector(7 downto 0) := x"00"
);
port (
  rst             : in  std_logic;
  clk             : in  std_logic;
  serial_clk      : in  std_logic;
  sclk_ext        : in  std_logic;
  -- Sequence interface
  init_ena        : in  std_logic;
  init_done       : out std_logic;
  -- Command Interface
  clk_cmd         : in  std_logic;
  in_cmd_val      : in  std_logic;
  in_cmd          : in  std_logic_vector(63 downto 0);
  out_cmd_val     : out std_logic;
  out_cmd         : out std_logic_vector(63 downto 0);
  in_cmd_busy     : out std_logic;
  -- SPI control
  spi_n_oe        : out std_logic;
  spi_n_cs        : out std_logic;
  spi_sclk        : out std_logic;
  spi_sdo         : out std_logic;
  spi_sdi         : in  std_logic
);
end component;

component sip_freq_cnt16 is
generic (
  START_ADDR      : std_logic_vector(27 downto 0) := x"0000000";
  STOP_ADDR       : std_logic_vector(27 downto 0) := x"0000001"
);
port (
  -- Command Interface
  clk_cmd         : in  std_logic;
  in_cmd_val      : in  std_logic;
  in_cmd          : in  std_logic_vector(63 downto 0);
  out_cmd_val     : out std_logic;
  out_cmd         : out std_logic_vector(63 downto 0);
  -- Clocks Interface
  reset           : in  std_logic;
  reference_clock : in  std_logic;
  test_clocks     : in  std_logic_vector(15 downto 0)
);
end component;

begin

----------------------------------------------------------------------------------------------------
-- Trigger control
----------------------------------------------------------------------------------------------------
fmc112_ctrl_inst : fmc112_ctrl
  generic map (
    START_ADDR         => START_ADDR_FMC112_CTRL,
    STOP_ADDR          => STOP_ADDR_FMC112_CTRL
  )
  port map (
    rst                => rst,

    clk_cmd            => clk_cmd,
    in_cmd_val         => in_cmd_val,
    in_cmd             => in_cmd,
    out_cmd_val        => cmd_val(0),
    out_cmd            => cmd(0),
    cmd_busy           => cmd_busy(0),

    ext_trigger_p      => ext_trigger_p,
    ext_trigger_n      => ext_trigger_n,
    ext_trigger_buf    => ext_trigger_buf,

    adc_clk            => ctrl_clk,
    fifo_wr_en         => fifo_wr_en,
    fifo_empty         => fifo_empty,
    fifo_full          => fifo_full,

    pg_m2c             => pg_m2c,
    prsnt_m2c_l        => prsnt_m2c_l

  );

----------------------------------------------------------------------------------------------------
-- ADS5400 Physical Data Interface for ADC0
----------------------------------------------------------------------------------------------------
ltc2175_phy_inst : ltc2175_phy
  generic map
  (
    START_ADDR   => START_ADDR_LTC2175_PHY,
    STOP_ADDR    => STOP_ADDR_LTC2175_PHY
  )
  port map (
    rst            => rst,

    clk_cmd        => clk_cmd,
    in_cmd_val     => in_cmd_val,
    in_cmd         => in_cmd,
    out_cmd_val    => cmd_val(1),
    out_cmd        => cmd(1),
    in_cmd_busy    => cmd_busy(1),

    dco_p(2 downto 0)    => dco_p,
	  dco_p(3) => '0',
    dco_n(2 downto 0)    => dco_n,
	  dco_n(3) => '0',
    frame_p(2 downto 0)  => frame_p,
    frame_p(3) => '0',
    frame_n(2 downto 0)  => frame_n,
	  frame_n(3) => '0',
    outa_p(11 downto 0)  => outa_p,
	  outa_p(15 downto 12) => (others => '0'),
    outa_n(11 downto 0)  => outa_n,
    outa_n(15 downto 12) => (others => '0'),
	  outb_p(11 downto 0)  => outb_p,
	  outb_p(15 downto 12) => (others => '0'),
    outb_n(11 downto 0)  => outb_n,
	  outb_n(15 downto 12) => (others => '0'),

    ctrl_clk  => ctrl_clk,
    phy_out_clk => phy_out_clk,

    phy_out_data0  => phy_out_data(0),
    phy_out_data1  => phy_out_data(1),
    phy_out_data2  => phy_out_data(2),
    phy_out_data3  => phy_out_data(3),
    phy_out_data4  => phy_out_data(4),
    phy_out_data5  => phy_out_data(5),
    phy_out_data6  => phy_out_data(6),
    phy_out_data7  => phy_out_data(7),
    phy_out_data8  => phy_out_data(8),
    phy_out_data9  => phy_out_data(9),
    phy_out_data10 => phy_out_data(10),
    phy_out_data11 => phy_out_data(11),
    phy_out_data12 => open,
 	  phy_out_data13 => open,
	  phy_out_data14 => open,
	  phy_out_data15 => open,
    dco => dco

  );

----------------------------------------------------------------------------------------------------
-- Clock boundary 16-to-64 FIFO's
----------------------------------------------------------------------------------------------------
-- ymei removal
--FIFO: for i in 0 to NB_CHANNELS-1 generate
--  fmc112_ltc2175_fifo_inst : fmc112_ltc2175_fifo
--  port map (
--    rst        => rst,
--    phy_clk    => phy_out_clk(i),
--    fifo_wr_clk => ctrl_clk,
--    phy_data   => phy_out_data(i),
--    fifo_wr_en => fifo_wr_en(i),
--    fifo_empty => fifo_empty(i),
--    fifo_full  => fifo_full(i),
--    if_clk     => clk_cmd,
--    if_stop    => adc_out_stop(i),
--    if_dval    => adc_out_dval(i),
--    if_data    => adc_out_data(i)
--  );
--end generate FIFO;



----------------------------------------------------------------------------------------------------
-- Generate serial clocks for SPI (max 6.66MHz, due to Tddata of 75ns on ADS5400)
----------------------------------------------------------------------------------------------------

process (clk)
  -- Divide by 2^5 = 32, CLKmax = 32 x 6.66MHz
  variable clk_div : std_logic_vector(4 downto 0) := (others => '0');
begin
  if (rising_edge(clk)) then
    clk_div    := clk_div + '1';
    -- The slave samples the data on the rising edge of SCLK.
    -- therefore we make sure the external clock is slightly
    -- after the internal clock.
    sclk_ext <= clk_div(clk_div'length-1);
    sclk_prebuf <= sclk_ext;
  end if;
end process;

bufg_sclk : bufg
port map (
  i => sclk_prebuf,
  o => serial_clk
);

----------------------------------------------------------------------------------------------------
-- SPI Interface controlling the clock IC
----------------------------------------------------------------------------------------------------
ad9517_ctrl_inst0 : fmc112_ad9517_ctrl
generic map (
  START_ADDR      => START_ADDR_AD9517_CTRL,
  STOP_ADDR       => STOP_ADDR_AD9517_CTRL,
  PRESEL          => PRESEL_CLK0
)
port map (
  rst             => rst,
  clk             => clk,
  serial_clk      => serial_clk,
  sclk_ext        => sclk_ext,

  init_ena        => init_ena_ad9517,
  init_done       => init_done_ad9517,

  clk_cmd         => clk_cmd,
  in_cmd_val      => in_cmd_val,
  in_cmd          => in_cmd,
  out_cmd_val     => cmd_val(2),
  out_cmd         => cmd(2),
  in_cmd_busy     => cmd_busy(2),

  spi_n_oe        => spi_n_oe0(0),
  spi_n_cs        => spi_n_cs0(0),
  spi_sclk        => spi_sclk0(0),
  spi_sdo         => spi_sdo0(0),
  spi_sdi         => spi_sdi0(0)
);

----------------------------------------------------------------------------------------------------
-- SPI interface controlling ADC chip 0
----------------------------------------------------------------------------------------------------
fmc112_ltc2175_ctrl_inst0 : fmc112_ltc2175_ctrl
generic map (
  START_ADDR      => START_ADDR_LTC2175_CTRL0,
  STOP_ADDR       => STOP_ADDR_LTC2175_CTRL0,
  PRESEL          => PRESEL_ADC0
)
port map (
  rst             => rst,
  clk             => clk,
  serial_clk      => serial_clk,
  sclk_ext        => sclk_ext,

  init_ena        => init_ena_ltc2175_0,
  init_done       => init_done_ltc2175_0,

  clk_cmd         => clk_cmd,
  in_cmd_val      => in_cmd_val,
  in_cmd          => in_cmd,
  out_cmd_val     => cmd_val(3),
  out_cmd         => cmd(3),
  in_cmd_busy     => cmd_busy(3),

  spi_n_oe        => spi_n_oe0(1),
  spi_n_cs        => spi_n_cs0(1),
  spi_sclk        => spi_sclk0(1),
  spi_sdo         => spi_sdo0(1),
  spi_sdi         => spi_sdi0(1)
);

----------------------------------------------------------------------------------------------------
-- SPI interface controlling ADC chip 1
----------------------------------------------------------------------------------------------------
fmc112_ltc2175_ctrl_inst1 : fmc112_ltc2175_ctrl
generic map (
  START_ADDR      => START_ADDR_LTC2175_CTRL1,
  STOP_ADDR       => STOP_ADDR_LTC2175_CTRL1,
  PRESEL          => PRESEL_ADC1
)
port map (
  rst             => rst,
  clk             => clk,
  serial_clk      => serial_clk,
  sclk_ext        => sclk_ext,

  init_ena        => init_ena_ltc2175_1,
  init_done       => init_done_ltc2175_1,

  clk_cmd         => clk_cmd,
  in_cmd_val      => in_cmd_val,
  in_cmd          => in_cmd,
  out_cmd_val     => cmd_val(4),
  out_cmd         => cmd(4),
  in_cmd_busy     => cmd_busy(4),

  spi_n_oe        => spi_n_oe0(2),
  spi_n_cs        => spi_n_cs0(2),
  spi_sclk        => spi_sclk0(2),
  spi_sdo         => spi_sdo0(2),
  spi_sdi         => spi_sdi0(2)
);

----------------------------------------------------------------------------------------------------
-- SPI interface controlling ADC chip 2
----------------------------------------------------------------------------------------------------
fmc112_ltc2175_ctrl_inst2 : fmc112_ltc2175_ctrl
generic map (
  START_ADDR      => START_ADDR_LTC2175_CTRL2,
  STOP_ADDR       => STOP_ADDR_LTC2175_CTRL2,
  PRESEL          => PRESEL_ADC2
)
port map (
  rst             => rst,
  clk             => clk,
  serial_clk      => serial_clk,
  sclk_ext        => sclk_ext,

  init_ena        => init_ena_ltc2175_2,
  init_done       => init_done_ltc2175_2,

  clk_cmd         => clk_cmd,
  in_cmd_val      => in_cmd_val,
  in_cmd          => in_cmd,
  out_cmd_val     => cmd_val(5),
  out_cmd         => cmd(5),
  in_cmd_busy     => cmd_busy(5),

  spi_n_oe        => spi_n_oe0(3),
  spi_n_cs        => spi_n_cs0(3),
  spi_sclk        => spi_sclk0(3),
  spi_sdo         => spi_sdo0(3),
  spi_sdi         => spi_sdi0(3)
);

----------------------------------------------------------------------------------------------------
-- SPI interface controlling ADC chip 3
----------------------------------------------------------------------------------------------------
fmc112_ltc2175_ctrl_inst3 : fmc112_ltc2175_ctrl
generic map (
  START_ADDR      => START_ADDR_LTC2175_CTRL3,
  STOP_ADDR       => STOP_ADDR_LTC2175_CTRL3,
  PRESEL          => PRESEL_ADC3
)
port map (
  rst             => rst,
  clk             => clk,
  serial_clk      => serial_clk,
  sclk_ext        => sclk_ext,

  init_ena        => init_ena_ltc2175_3,
  init_done       => init_done_ltc2175_3,

  clk_cmd         => clk_cmd,
  in_cmd_val      => in_cmd_val,
  in_cmd          => in_cmd,
  out_cmd_val     => cmd_val(6),
  out_cmd         => cmd(6),
  in_cmd_busy     => cmd_busy(6),

  spi_n_oe        => spi_n_oe0(4),
  spi_n_cs        => spi_n_cs0(4),
  spi_sclk        => spi_sclk0(4),
  spi_sdo         => spi_sdo0(4),
  spi_sdi         => spi_sdi0(4)
);

----------------------------------------------------------------------------------------------------
-- SPI interface controlling DAC chip 0
----------------------------------------------------------------------------------------------------
fmc112_ltc2656_ctrl_inst0 : fmc112_ltc2656_ctrl
generic map (
  START_ADDR      => START_ADDR_LTC2656_CTRL0,
  STOP_ADDR       => STOP_ADDR_LTC2656_CTRL0,
  PRESEL          => PRESEL_DAC0
)
port map (
  rst             => rst,
  clk             => clk,
  serial_clk      => serial_clk,
  sclk_ext        => sclk_ext,

  init_ena        => init_ena_ltc2656_0,
  init_done       => init_done_ltc2656_0,

  clk_cmd         => clk_cmd,
  in_cmd_val      => in_cmd_val,
  in_cmd          => in_cmd,
  out_cmd_val     => cmd_val(7),
  out_cmd         => cmd(7),
  in_cmd_busy     => cmd_busy(7),

  spi_n_oe        => spi_n_oe0(5),
  spi_n_cs        => spi_n_cs0(5),
  spi_sclk        => spi_sclk0(5),
  spi_sdo         => spi_sdo0(5),
  spi_sdi         => spi_sdi0(5)
);

----------------------------------------------------------------------------------------------------
-- SPI interface controlling DAC chip 1
----------------------------------------------------------------------------------------------------
fmc112_ltc2656_ctrl_inst1 : fmc112_ltc2656_ctrl
generic map (
  START_ADDR      => START_ADDR_LTC2656_CTRL1,
  STOP_ADDR       => STOP_ADDR_LTC2656_CTRL1,
  PRESEL          => PRESEL_DAC1
)
port map (
  rst             => rst,
  clk             => clk,
  serial_clk      => serial_clk,
  sclk_ext        => sclk_ext,

  init_ena        => init_ena_ltc2656_1,
  init_done       => init_done_ltc2656_1,

  clk_cmd         => clk_cmd,
  in_cmd_val      => in_cmd_val,
  in_cmd          => in_cmd,
  out_cmd_val     => cmd_val(8),
  out_cmd         => cmd(8),
  in_cmd_busy     => cmd_busy(8),

  spi_n_oe        => spi_n_oe0(6),
  spi_n_cs        => spi_n_cs0(6),
  spi_sclk        => spi_sclk0(6),
  spi_sdo         => spi_sdo0(6),
  spi_sdi         => spi_sdi0(6)
);

----------------------------------------------------------------------------------------------------
-- SPI Interface accessing internal CPLD registers
----------------------------------------------------------------------------------------------------
fmc112_cpld_ctrl_inst : fmc112_cpld_ctrl
generic map (
  START_ADDR      => START_ADDR_CPLD_CTRL,
  STOP_ADDR       => STOP_ADDR_CPLD_CTRL,
  PRESEL          => PRESEL_CPLD
)
port map (
  rst             => rst,
  clk             => clk,
  serial_clk      => serial_clk,
  sclk_ext        => sclk_ext,

  init_ena        => init_ena_cpld,
  init_done       => init_done_cpld,

  clk_cmd         => clk_cmd,
  in_cmd_val      => in_cmd_val,
  in_cmd          => in_cmd,
  out_cmd_val     => cmd_val(9),
  out_cmd         => cmd(9),
  in_cmd_busy     => cmd_busy(9),

  spi_n_oe        => spi_n_oe0(7),
  spi_n_cs        => spi_n_cs0(7),
  spi_sclk        => spi_sclk0(7),
  spi_sdo         => spi_sdo0(7),
  spi_sdi         => spi_sdi0(7)
);

----------------------------------------------------------------------------------------------------
-- Sequence SPI initialization
----------------------------------------------------------------------------------------------------

-- start AD9517 init after power up
init_ena_ad9517 <= '1';

-- start LTC2175 init after AD9517 init done
init_ena_ltc2175_0 <= init_done_ad9517;
init_ena_ltc2175_1 <= init_done_ltc2175_0;
init_ena_ltc2175_2 <= init_done_ltc2175_1;
init_ena_ltc2175_3 <= init_done_ltc2175_2;

-- start LCT2656 init after LTC2175 init done
init_ena_ltc2656_0 <= init_done_ltc2175_3;
init_ena_ltc2656_1 <= init_done_ltc2656_0;

-- start cpld init after dac5681z init done
init_ena_cpld <= '0'; -- no init required

----------------------------------------------------------------------------------------------------
-- SPI PHY, shared SPI bus
----------------------------------------------------------------------------------------------------
spi_sclk <= spi_sclk0(0) when spi_n_cs0(0) = '0' else
            spi_sclk0(1) when spi_n_cs0(1) = '0' else
            spi_sclk0(2) when spi_n_cs0(2) = '0' else
            spi_sclk0(3) when spi_n_cs0(3) = '0' else
            spi_sclk0(4) when spi_n_cs0(4) = '0' else
            spi_sclk0(5) when spi_n_cs0(5) = '0' else
            spi_sclk0(6) when spi_n_cs0(6) = '0' else
            spi_sclk0(7) when spi_n_cs0(7) = '0' else '0';

iobuf_cpld0 : iobuf
port map (
  I  => spi_sclk,
  O  => open,
  IO => ctrl(0),
  T  => '0'
);

spi_n_oe <= and_reduce(spi_n_oe0);
spi_n_cs <= and_reduce(spi_n_cs0);

iobuf_cpld1 : iobuf
port map (
  I  => spi_n_cs,
  O  => open,
  IO => ctrl(1),
  T  => '0'
);

spi_sdo <= spi_sdo0(0) when spi_n_oe0(0) = '0' else
           spi_sdo0(1) when spi_n_oe0(1) = '0' else
           spi_sdo0(2) when spi_n_oe0(2) = '0' else
           spi_sdo0(3) when spi_n_oe0(3) = '0' else
           spi_sdo0(4) when spi_n_oe0(4) = '0' else
           spi_sdo0(5) when spi_n_oe0(5) = '0' else
           spi_sdo0(6) when spi_n_oe0(6) = '0' else
           spi_sdo0(7) when spi_n_oe0(7) = '0' else '1';

iobuf_cpld2 : iobuf
port map (
  I  => spi_sdo,
  O  => spi_sdi,
  IO => ctrl(2),
  T  => spi_n_oe
);

spi_sdi0(0) <= spi_sdi;
spi_sdi0(1) <= spi_sdi;
spi_sdi0(2) <= spi_sdi;
spi_sdi0(3) <= spi_sdi;
spi_sdi0(4) <= spi_sdi;
spi_sdi0(5) <= spi_sdi;
spi_sdi0(6) <= spi_sdi;
spi_sdi0(7) <= spi_sdi;

iobuf_cpld3 : iobuf
port map (
  I  => '0',
  O  => open,
  IO => ctrl(3),
  T  => '1'
);

ctrl(4) <= 'Z';
ctrl(5) <= 'Z';
ctrl(6) <= 'Z';

iobuf_trig : IOBUF
  GENERIC MAP (
    DRIVE      => 12,
    IOSTANDARD => "DEFAULT",
    SLEW       => "SLOW"                -- output rise/fall
  )
  PORT MAP (
    IO => ctrl(7),  -- Buffer inout port (connect directly to top-level port)
    O  => OPEN,                         -- Buffer output to FPGA
    I  => ext_trigger_buf,              -- Buffer input from FPGA
    T  => '0'       -- 3-state enable input, '1'=input, '0'=output 
  );
ext_trigger <= ext_trigger_buf;

----------------------------------------------------------------------------------------------------
-- Frequency counter
----------------------------------------------------------------------------------------------------
sip_freq_cnt16_inst : sip_freq_cnt16
generic map (
  START_ADDR      => START_ADDR_FREQ_CNT,
  STOP_ADDR       => STOP_ADDR_FREQ_CNT
)
port map (
  clk_cmd         => clk_cmd,
  in_cmd_val      => in_cmd_val,
  in_cmd          => in_cmd,
  out_cmd_val     => cmd_val(10),
  out_cmd         => cmd(10),
  reset           => rst,
  reference_clock => clk_cmd,
  test_clocks     => test_clocks
);
cmd_busy(10) <= '0';

test_clocks(0) <= clk_cmd;
test_clocks(1) <= dco(0);
test_clocks(2) <= dco(1);
test_clocks(3) <= dco(2);
test_clocks(5) <= clk_to_fpga;
test_clocks(6) <= ext_trigger_buf;
test_clocks(15 downto 7) <= (others => '0');

----------------------------------------------------------------------------------------------------
-- Command out merge & pipeline
----------------------------------------------------------------------------------------------------
process (rst, clk_cmd)
  variable tmp : std_logic_vector(63 downto 0);
begin
  if (rst = '1') then

    out_cmd_val  <= '0';
    out_cmd      <= (others => '0');
    out_cmd_busy <= '0';

  elsif (rising_edge(clk_cmd)) then

    -- OR all local command busses
    tmp := (others => '0');
    for i in 0 to NB_CMD_BUS-1 loop
      tmp := tmp or cmd(i);
    end loop;

    out_cmd_val  <= or_reduce(cmd_val);
    out_cmd <= tmp;
    out_cmd_busy <= or_reduce(cmd_busy);

  end if;
end process;

----------------------------------------------------------------------------------------------------
-- Clock input
----------------------------------------------------------------------------------------------------
ibufds_ref_clk : ibufds
generic map (
  IOSTANDARD => "LVDS_25",
  DIFF_TERM => TRUE
)
port map (
  i  => clk_to_fpga_p,
  ib => clk_to_fpga_n,
  o  => clk_to_fpga_buf
);

bufg_ref_clk : bufg
port map (
  i => clk_to_fpga_buf,
  o => clk_to_fpga
);

----------------------------------------------------------------------------------------------------
-- Connect entity
----------------------------------------------------------------------------------------------------

-- ymei
phy_data_clk   <= ctrl_clk;
phy_out_data0  <= phy_out_data(0);
phy_out_data1  <= phy_out_data(1);
phy_out_data2  <= phy_out_data(2);
phy_out_data3  <= phy_out_data(3);
phy_out_data4  <= phy_out_data(4);
phy_out_data5  <= phy_out_data(5);
phy_out_data6  <= phy_out_data(6);
phy_out_data7  <= phy_out_data(7);
phy_out_data8  <= phy_out_data(8);
phy_out_data9  <= phy_out_data(9);
phy_out_data10 <= phy_out_data(10);
phy_out_data11 <= phy_out_data(11);

----------------------------------------------------------------------------------------------------
-- End
----------------------------------------------------------------------------------------------------
end fmc112_if_syn;
