--------------------------------------------------------------------------------
-- brd_clocks.vhd
--------------------------------------------------------------------------------
-- This module contains all of the clock related stuff
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

entity brd_clocks is
port (

  -- system reset - resets plls, dcm's
  rst             : in std_logic;

  -- differential sys clock
  sysclk_p        : in std_logic;
  sysclk_n        : in std_logic;

  pll_lock        : out std_logic; -- from pll

  clk50           : out std_logic; -- 50 mhz
  clk125          : out std_logic; -- 125 mhz
  clk200          : out std_logic  -- 200 mhz

);
end brd_clocks;

--------------------------------------------------------------------------------
-- Specify Architecture
--------------------------------------------------------------------------------

architecture brd_clocks_syn of brd_clocks is

--------------------------------------------------------------------------------
-- Component declaration
--------------------------------------------------------------------------------

component pll0 is
port (
  -- Clock in ports
  clk_in1_p         : in     std_logic;
  clk_in1_n         : in     std_logic;
  -- Clock out ports
  clk_out1          : out    std_logic;
  clk_out2          : out    std_logic;
  clk_out3          : out    std_logic;
  -- Status and control signals
  reset             : in     std_logic;
  locked            : out    std_logic
 );
end component;

--------------------------------------------------------------------------------
-- Signal declaration
--------------------------------------------------------------------------------

signal sysclk            : std_logic;

-- Clock from PLLFBOUT to PLLFBIN
signal clk_pllfb         : std_logic;

-- Raw PLL outputs
signal clk50_bufg_in     : std_logic;
signal clk125_bufg_in    : std_logic;

--------------------------------------------------------------------------------
-- Begin
--------------------------------------------------------------------------------

begin

--------------------------------------------------------------------------------
-- System Clock
--------------------------------------------------------------------------------

--  -- IBUFG the raw clock input
--  ibufgds_inst : ibufgds
--  generic map (
--    DIFF_TERM        => FALSE,  -- Differential Termination (Virtex-4/5, Spartan-3E/3A)
--    IBUF_DELAY_VALUE => "0",      -- Specify the amount of added input delay for the buffer, "0"-"16" (Spartan-3E/3A only)
--    IOSTANDARD       => "LVDS_25" -- Specify the input I/O standard
--  )
--  port map (
--    o  => sysclk,   -- Clock buffer output
--    i  => sysclk_p, -- Diff_p clock buffer input (connect directly to top-level port)
--    ib => sysclk_n  -- Diff_n clock buffer input (connect directly to top-level port)
--  );
--
--  u_pll_adv : PLL_ADV
--  generic map (
--    BANDWIDTH          => "OPTIMIZED",
--    CLKIN1_PERIOD      => 5.0, -- 200 MHz = 5ns
--    CLKIN2_PERIOD      => 1.0,
--    DIVCLK_DIVIDE      => 1,
--    CLKFBOUT_MULT      => 5,  -- 200 MHz x5 = 1000 MHz
--    CLKFBOUT_PHASE     => 0.0,
--    CLKOUT0_DIVIDE     => 20, -- 1000 Mhz / 20 =  50 MHz
--    CLKOUT1_DIVIDE     => 8,  -- 1000 Mhz /  8 = 125 MHz
--    CLKOUT2_DIVIDE     => 8,  -- 1000 Mhz /  8 = 125 MHz
--    CLKOUT3_DIVIDE     => 8,  -- 1000 Mhz /  8 = 125 MHz
--    CLKOUT4_DIVIDE     => 8,  -- 1000 Mhz /  8 = 125 MHz
--    CLKOUT5_DIVIDE     => 8,  -- 1000 Mhz /  8 = 125 MHz
--    CLKOUT0_PHASE      => 0.000,
--    CLKOUT1_PHASE      => 180.000,
--    CLKOUT2_PHASE      => 0.000,
--    CLKOUT3_PHASE      => 0.000,
--    CLKOUT4_PHASE      => 0.000,
--    CLKOUT5_PHASE      => 0.000,
--    CLKOUT0_DUTY_CYCLE => 0.500,
--    CLKOUT1_DUTY_CYCLE => 0.500,
--    CLKOUT2_DUTY_CYCLE => 0.500,
--    CLKOUT3_DUTY_CYCLE => 0.500,
--    CLKOUT4_DUTY_CYCLE => 0.500,
--    CLKOUT5_DUTY_CYCLE => 0.500,
--    COMPENSATION       => "SYSTEM_SYNCHRONOUS",
--    REF_JITTER         => 0.005000
--  )
--  port map (
--    clkfbin     => clk_pllfb,
--    clkinsel    => '1',
--    clkin1      => sysclk,
--    clkin2      => '0',
--    daddr       => "00000",
--    dclk        => '0',
--    den         => '0',
--    di          => x"0000",
--    dwe         => '0',
--    rel         => '0',
--    rst         => rst,
--    clkfbdcm    => open,
--    clkfbout    => clk_pllfb,
--    clkoutdcm0  => open,
--    clkoutdcm1  => open,
--    clkoutdcm2  => open,
--    clkoutdcm3  => open,
--    clkoutdcm4  => open,
--    clkoutdcm5  => open,
--    clkout0     => clk50_bufg_in,
--    clkout1     => clk125_bufg_in,
--    clkout2     => open,
--    clkout3     => open,
--    clkout4     => open,
--    clkout5     => open,
--    do          => open,
--    drdy        => open,
--    locked      => pll_lock
--  );
--
--  bufg_clk50 : bufg
--  port map (
--    i => clk50_bufg_in,
--    o => clk50
--  );
--
--  bufg_clk125 : bufg
--  port map (
--    i => clk125_bufg_in,
--    o => clk125
--  );

pll0_inst : pll0
port map (
  clk_in1_p => sysclk_p,
  clk_in1_n => sysclk_n,
  clk_out1  => clk50,
  clk_out2  => clk125,
  clk_out3  => clk200,
  reset     => rst,
  locked    => pll_lock
);

--------------------------------------------------------------------------------
-- End
--------------------------------------------------------------------------------

end brd_clocks_syn;
