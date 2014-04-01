--------------------------------------------------------------------------------
-- file name : sip_fmc_ct_gen.vhd
--
-- author    : p. kortekaas
--
-- company   : 4dsp
--
-- item      : number
--
-- language  : vhdl
--
--------------------------------------------------------------------------------
-- description
-- ===========
--
--
-- notes:
--------------------------------------------------------------------------------
--
--  disclaimer: limited warranty and disclaimer. these designs are
--              provided to you as is.  4dsp specifically disclaims any
--              implied warranties of merchantability, non-infringement, or
--              fitness for a particular purpose. 4dsp does not warrant that
--              the functions contained in these designs will meet your
--              requirements, or that the operation of these designs will be
--              uninterrupted or error free, or that defects in the designs
--              will be corrected. furthermore, 4dsp does not warrant or
--              make any representations regarding use or the results of the
--              use of the designs in terms of correctness, accuracy,
--              reliability, or otherwise.
--
--              limitation of liability. in no event will 4dsp or its
--              licensors be liable for any loss of data, lost profits, cost
--              or procurement of substitute goods or services, or for any
--              special, incidental, consequential, or indirect damages
--              arising from the use or operation of the designs or
--              accompanying documentation, however caused and on any theory
--              of liability. this limitation will apply even if 4dsp
--              has been advised of the possibility of such damage. this
--              limitation shall apply not-withstanding the failure of the
--              essential purpose of any limited remedies herein.
--
--------------------------------------------------------------------------------
-- specify libraries
--------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_unsigned.all;
  use ieee.std_logic_misc.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_1164.all;

--------------------------------------------------------------------------------
-- entity declaration
--------------------------------------------------------------------------------
entity sip_fmc_ct_gen is
generic (
  GLOBAL_START_ADDR_GEN     : std_logic_vector(27 downto 0);
  GLOBAL_STOP_ADDR_GEN      : std_logic_vector(27 downto 0);
  PRIVATE_START_ADDR_GEN    : std_logic_vector(27 downto 0);
  PRIVATE_STOP_ADDR_GEN     : std_logic_vector(27 downto 0)
);
port (
  cmdclk_in_cmdclk          : in  std_logic;
  cmd_in_cmdin              : in  std_logic_vector(63 downto 0);
  cmd_in_cmdin_val          : in  std_logic;
  cmd_out_cmdout            : out std_logic_vector(63 downto 0);
  cmd_out_cmdout_val        : out std_logic;
  rst_rstin                 : in  std_logic_vector(31 downto 0);
  -- External
  ref_clk_p                 : in  std_logic;
  ref_clk_n                 : in  std_logic;
  tx_p                      : out std_logic;
  tx_n                      : out std_logic;
  rx_p                      : in  std_logic;
  rx_n                      : in  std_logic;
  trig_out                  : out std_logic
);
end entity sip_fmc_ct_gen;

--------------------------------------------------------------------------------
-- arch_itecture declaration
--------------------------------------------------------------------------------
architecture sip_fmc_ct_gen_syn of sip_fmc_ct_gen is

-----------------------------------------------------------------------------------
--constant declarations
-----------------------------------------------------------------------------------

-----------------------------------------------------------------------------------
--signal declarations
-----------------------------------------------------------------------------------

-----------------------------------------------------------------------------------
--component declarations
-----------------------------------------------------------------------------------
component fmc_ct_gen is
generic (
  START_ADDR : std_logic_vector(27 downto 0) := x"0000000";
  STOP_ADDR  : std_logic_vector(27 downto 0) := x"0000001"
);
port (
  -- GTX Connections
  ref_clk_p         : in  std_logic;
  ref_clk_n         : in  std_logic;
  tx_p              : out std_logic;
  tx_n              : out std_logic;
  rx_p              : in  std_logic;
  rx_n              : in  std_logic;
  -- Trigger output
  trig_out          : out std_logic;
  -- Command interface
  reset             : in  std_logic;
  clk_cmd           : in  std_logic;
  out_cmd           : out std_logic_vector(63 downto 0);
  out_cmd_val       : out std_logic;
  in_cmd            : in  std_logic_vector(63 downto 0);
  in_cmd_val        : in  std_logic
);
end component;

begin

-----------------------------------------------------------------------------------
--component instantiations
-----------------------------------------------------------------------------------
fmc_ct_gen_inst : fmc_ct_gen
generic map (
  START_ADDR => PRIVATE_START_ADDR_GEN,
  STOP_ADDR  => PRIVATE_STOP_ADDR_GEN
)
port map (
  -- GTX Connections
  ref_clk_p         => ref_clk_p,
  ref_clk_n         => ref_clk_n,
  tx_p              => tx_p,
  tx_n              => tx_n,
  rx_p              => rx_p,
  rx_n              => rx_n,
  -- Trigger output
  trig_out          => trig_out,
  -- Command interface
  reset             => rst_rstin(2),
  clk_cmd           => cmdclk_in_cmdclk,
  out_cmd           => cmd_out_cmdout,
  out_cmd_val       => cmd_out_cmdout_val,
  in_cmd            => cmd_in_cmdin,
  in_cmd_val        => cmd_in_cmdin_val
);

-----------------------------------------------------------------------------------
--synchronous processes
-----------------------------------------------------------------------------------

-----------------------------------------------------------------------------------
--asynchronous processes
-----------------------------------------------------------------------------------

-----------------------------------------------------------------------------------
--asynchronous mapping
-----------------------------------------------------------------------------------

end architecture sip_fmc_ct_gen_syn;

