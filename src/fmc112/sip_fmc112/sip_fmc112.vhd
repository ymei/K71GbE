-------------------------------------------------------------------------------------
-- FILE NAME : sip_fmc112.vhd
--
-- AUTHOR    : StellarIP (c) 4DSP
--
-- COMPANY   : 4DSP
--
-- ITEM      : 1
--
-- UNITS     : Entity       - sip_fmc112
--             architecture - arch_sip_fmc112
--
-- LANGUAGE  : VHDL
--
-------------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------------
-- DESCRIPTION
-- ===========
--
-- sip_fmc112
-- Notes: sip_fmc112
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
--
-------------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------------
--library declaration
-------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;
use ieee.std_logic_misc.all ;

-------------------------------------------------------------------------------------
--Entity Declaration
-------------------------------------------------------------------------------------
entity sip_fmc112  is
generic (
   global_start_addr_gen                   : std_logic_vector(27 downto 0);
   global_stop_addr_gen                    : std_logic_vector(27 downto 0);
   private_start_addr_gen                  : std_logic_vector(27 downto 0);
   private_stop_addr_gen                   : std_logic_vector(27 downto 0)
);
port (
--Wormhole 'clk' of type 'clkin':
   clk_clkin                               : in    std_logic_vector(31 downto 0);

--Wormhole 'rst' of type 'rst_in':
   rst_rstin                               : in    std_logic_vector(31 downto 0);

--Wormhole 'cmdclk_in' of type 'cmdclk_in':
   cmdclk_in_cmdclk                        : in    std_logic;

--Wormhole 'cmd_in' of type 'cmd_in':
   cmd_in_cmdin                            : in    std_logic_vector(63 downto 0);
   cmd_in_cmdin_val                        : in    std_logic;

--Wormhole 'cmd_out' of type 'cmd_out':
   cmd_out_cmdout                          : out   std_logic_vector(63 downto 0);
   cmd_out_cmdout_val                      : out   std_logic;

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

--Wormhole 'ext_fmc112' of type 'ext_fmc112':
   ctrl                                    : inout std_logic_vector(7 downto 0);
   clk_to_fpga_p                           : in    std_logic;
   clk_to_fpga_n                           : in    std_logic;
   ext_trigger_p                           : in    std_logic;
   ext_trigger_n                           : in    std_logic;
   ext_trigger                             : out   std_logic;
   outa_p                                  : in    std_logic_vector(11 downto 0);
   outa_n                                  : in    std_logic_vector(11 downto 0);
   outb_p                                  : in    std_logic_vector(11 downto 0);
   outb_n                                  : in    std_logic_vector(11 downto 0);
   dco_p                                   : in    std_logic_vector(2 downto 0);
   dco_n                                   : in    std_logic_vector(2 downto 0);
   frame_p                                 : in    std_logic_vector(2 downto 0);
   frame_n                                 : in    std_logic_vector(2 downto 0);
   pg_m2c                                  : in    std_logic;
   prsnt_m2c_l                             : in    std_logic
   );
end entity sip_fmc112;

-------------------------------------------------------------------------------------
--Architecture declaration
-------------------------------------------------------------------------------------
architecture arch_sip_fmc112 of sip_fmc112 is

-------------------------------------------------------------------------------------
--Constants declaration
-------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
--Signal declaration
-------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
--Components declarations
-------------------------------------------------------------------------------------
component fmc112_if is
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
end component;



begin

-------------------------------------------------------------------------------------
--Components instantiations
-------------------------------------------------------------------------------------
fmc112_if_inst : fmc112_if
generic map
(
  START_ADDR      => PRIVATE_START_ADDR_GEN,
  STOP_ADDR       => PRIVATE_STOP_ADDR_GEN
)
port map (
  rst             => rst_rstin(2),
  clk             => cmdclk_in_cmdclk,

  clk_cmd         => cmdclk_in_cmdclk,
  in_cmd_val      => cmd_in_cmdin_val,
  in_cmd          => cmd_in_cmdin,
  out_cmd_val     => cmd_out_cmdout_val,
  out_cmd         => cmd_out_cmdout,
  out_cmd_busy    => open,

  phy_data_clk    => phy_data_clk,
  phy_out_data0   => phy_out_data0,
  phy_out_data1   => phy_out_data1,
  phy_out_data2   => phy_out_data2,
  phy_out_data3   => phy_out_data3,
  phy_out_data4   => phy_out_data4,
  phy_out_data5   => phy_out_data5,
  phy_out_data6   => phy_out_data6,
  phy_out_data7   => phy_out_data7,
  phy_out_data8   => phy_out_data8,
  phy_out_data9   => phy_out_data9,
  phy_out_data10  => phy_out_data10,
  phy_out_data11  => phy_out_data11,

  ctrl            => ctrl,
  clk_to_fpga_p   => clk_to_fpga_p,
  clk_to_fpga_n   => clk_to_fpga_n,
  ext_trigger_p   => ext_trigger_p,
  ext_trigger_n   => ext_trigger_n,
  ext_trigger     => ext_trigger,
  dco_p           => dco_p,
  dco_n           => dco_n,
  frame_p         => frame_p,
  frame_n         => frame_n,
  outa_p          => outa_p,
  outa_n          => outa_n,
  outb_p          => outb_p,
  outb_n          => outb_n,
  pg_m2c          => pg_m2c,
  prsnt_m2c_l     => prsnt_m2c_l

);


-------------------------------------------------------------------------------------
--synchronous processes
-------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------
--asynchronous processes
-------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------
--asynchronous mapping
-------------------------------------------------------------------------------------


end architecture arch_sip_fmc112   ; -- of sip_fmc112
