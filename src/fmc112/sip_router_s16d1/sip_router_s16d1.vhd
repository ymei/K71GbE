
-------------------------------------------------------------------------------------
-- FILE NAME : sip_router_s16d1.vhd
--
-- AUTHOR    : StellarIP (c) 4DSP
--
-- COMPANY   : 4DSP
--
-- ITEM      : 1
--
-- UNITS     : Entity       - sip_router_s16d1
--             architecture - arch_sip_router_s16d1
--
-- LANGUAGE  : VHDL
--
-------------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------------
-- DESCRIPTION
-- ===========
--
-- sip_router_s16d1
-- Notes: sip_router_s16d1
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
entity sip_router_s16d1  is
generic (
   global_start_addr_gen                   : std_logic_vector(27 downto 0);
   global_stop_addr_gen                    : std_logic_vector(27 downto 0);
   private_start_addr_gen                  : std_logic_vector(27 downto 0);
   private_stop_addr_gen                   : std_logic_vector(27 downto 0)
);
port (
--Wormhole 'cmdclk_in':
   cmdclk_in_cmdclk                        : in    std_logic;

--Wormhole 'cmd_in':
   cmd_in_cmdin                            : in    std_logic_vector(63 downto 0);
   cmd_in_cmdin_val                          : in    std_logic;

--Wormhole 'cmd_out':
   cmd_out_cmdout                          : out   std_logic_vector(63 downto 0);
   cmd_out_cmdout_val                      : out   std_logic;

--Wormhole 'clk':
   clk_clkin                               : in    std_logic_vector(31 downto 0);

--Wormhole 'rst':
   rst_rstin                               : in    std_logic_vector(31 downto 0);

--Wormhole 'out0':
   out0_out_stop                           : in    std_logic;
   out0_out_dval                           : out   std_logic;
   out0_out_data                           : out   std_logic_vector(63 downto 0);

--Wormhole 'in0':
   in0_in_stop                             : out   std_logic;
   in0_in_dval                             : in    std_logic;
   in0_in_data                             : in    std_logic_vector(63 downto 0);
--Wormhole 'in1':
   in1_in_stop                             : out   std_logic;
   in1_in_dval                             : in    std_logic;
   in1_in_data                             : in    std_logic_vector(63 downto 0);
--Wormhole 'in2':
   in2_in_stop                             : out   std_logic;
   in2_in_dval                             : in    std_logic;
   in2_in_data                             : in    std_logic_vector(63 downto 0);
--Wormhole 'in3':
   in3_in_stop                             : out   std_logic;
   in3_in_dval                             : in    std_logic;
   in3_in_data                             : in    std_logic_vector(63 downto 0);
--Wormhole 'in4':
   in4_in_stop                             : out   std_logic;
   in4_in_dval                             : in    std_logic;
   in4_in_data                             : in    std_logic_vector(63 downto 0);
--Wormhole 'in5':
   in5_in_stop                             : out   std_logic;
   in5_in_dval                             : in    std_logic;
   in5_in_data                             : in    std_logic_vector(63 downto 0);
--Wormhole 'in6':
   in6_in_stop                             : out   std_logic;
   in6_in_dval                             : in    std_logic;
   in6_in_data                             : in    std_logic_vector(63 downto 0);
--Wormhole 'in7':
   in7_in_stop                             : out   std_logic;
   in7_in_dval                             : in    std_logic;
   in7_in_data                             : in    std_logic_vector(63 downto 0);
--Wormhole 'in8':
   in8_in_stop                             : out   std_logic;
   in8_in_dval                             : in    std_logic;
   in8_in_data                             : in    std_logic_vector(63 downto 0);
--Wormhole 'in9':
   in9_in_stop                             : out   std_logic;
   in9_in_dval                             : in    std_logic;
   in9_in_data                             : in    std_logic_vector(63 downto 0);
--Wormhole 'in10':
   in10_in_stop                             : out   std_logic;
   in10_in_dval                             : in    std_logic;
   in10_in_data                             : in    std_logic_vector(63 downto 0);
--Wormhole 'in11':
   in11_in_stop                             : out   std_logic;
   in11_in_dval                             : in    std_logic;
   in11_in_data                             : in    std_logic_vector(63 downto 0);
--Wormhole 'in12':
   in12_in_stop                             : out   std_logic;
   in12_in_dval                             : in    std_logic;
   in12_in_data                             : in    std_logic_vector(63 downto 0);
--Wormhole 'in13':
   in13_in_stop                             : out   std_logic;
   in13_in_dval                             : in    std_logic;
   in13_in_data                             : in    std_logic_vector(63 downto 0);
--Wormhole 'in14':
   in14_in_stop                             : out   std_logic;
   in14_in_dval                             : in    std_logic;
   in14_in_data                             : in    std_logic_vector(63 downto 0);
--Wormhole 'in15':
   in15_in_stop                             : out   std_logic;
   in15_in_dval                             : in    std_logic;
   in15_in_data                             : in    std_logic_vector(63 downto 0)
   );
end entity sip_router_s16d1;

-------------------------------------------------------------------------------------
--Architecture declaration
-------------------------------------------------------------------------------------
architecture arch_sip_router_s16d1   of sip_router_s16d1  is

-------------------------------------------------------------------------------------
--Constants declaration
-------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
--Signal declaration
-------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
--components declarations
-------------------------------------------------------------------------------------
component router_s16d1
generic
(
   start_addr                    :std_logic_vector(27 downto 0):=x"0000000";
   stop_addr                     :std_logic_vector(27 downto 0):=x"0000001"
   );
port
   (
      clk               :in std_logic;
      reset             :in std_logic;

      --command if
      clk_cmd           :in  std_logic;
      out_cmd           :out std_logic_vector(63 downto 0);
      out_cmd_val       :out std_logic;
      in_cmd            :in  std_logic_vector(63 downto 0);
      in_cmd_val        :in  std_logic;



     --input ports
      in0_data       :in     std_logic_vector(63 downto 0);
      in0_stop       :out    std_logic;
      in0_dval       :in     std_logic;
      in0_sync       :in     std_logic;

      in1_data       :in     std_logic_vector(63 downto 0);
      in1_stop       :out    std_logic;
      in1_dval       :in     std_logic;
      in1_sync       :in     std_logic;

      in2_data       :in     std_logic_vector(63 downto 0);
      in2_stop       :out    std_logic;
      in2_dval       :in     std_logic;
      in2_sync       :in     std_logic;

      in3_data       :in     std_logic_vector(63 downto 0);
      in3_stop       :out    std_logic;
      in3_dval       :in     std_logic;
      in3_sync       :in     std_logic;

      in4_data       :in     std_logic_vector(63 downto 0);
      in4_stop       :out    std_logic;
      in4_dval       :in     std_logic;
      in4_sync       :in     std_logic;

      in5_data       :in     std_logic_vector(63 downto 0);
      in5_stop       :out    std_logic;
      in5_dval       :in     std_logic;
      in5_sync       :in     std_logic;

      in6_data       :in     std_logic_vector(63 downto 0);
      in6_stop       :out    std_logic;
      in6_dval       :in     std_logic;
      in6_sync       :in     std_logic;

      in7_data       :in     std_logic_vector(63 downto 0);
      in7_stop       :out    std_logic;
      in7_dval       :in     std_logic;
      in7_sync       :in     std_logic;

      in8_data       :in     std_logic_vector(63 downto 0);
      in8_stop       :out    std_logic;
      in8_dval       :in     std_logic;
      in8_sync       :in     std_logic;

      in9_data       :in     std_logic_vector(63 downto 0);
      in9_stop       :out    std_logic;
      in9_dval       :in     std_logic;
      in9_sync       :in     std_logic;

      in10_data      :in     std_logic_vector(63 downto 0);
      in10_stop      :out    std_logic;
      in10_dval      :in     std_logic;
      in10_sync      :in     std_logic;

      in11_data      :in     std_logic_vector(63 downto 0);
      in11_stop      :out    std_logic;
      in11_dval      :in     std_logic;
      in11_sync      :in     std_logic;

      in12_data      :in     std_logic_vector(63 downto 0);
      in12_stop      :out    std_logic;
      in12_dval      :in     std_logic;
      in12_sync      :in     std_logic;

      in13_data      :in     std_logic_vector(63 downto 0);
      in13_stop      :out    std_logic;
      in13_dval      :in     std_logic;
      in13_sync      :in     std_logic;

      in14_data      :in     std_logic_vector(63 downto 0);
      in14_stop      :out    std_logic;
      in14_dval      :in     std_logic;
      in14_sync      :in     std_logic;

      in15_data      :in     std_logic_vector(63 downto 0);
      in15_stop      :out    std_logic;
      in15_dval      :in     std_logic;
      in15_sync      :in     std_logic;

      --output ports
      out0_data      :out    std_logic_vector(63 downto 0);
      out0_stop      :in     std_logic;
      out0_dval      :out    std_logic;
      out0_sync      :out    std_logic

   );

end component;


begin


-------------------------------------------------------------------------------------
--components instantiations
-------------------------------------------------------------------------------------
 i_router_s16d1:router_s16d1
generic map
(
  start_addr           =>private_start_addr_gen,
   stop_addr            =>private_stop_addr_gen
   )
port map
   (
      clk                =>cmdclk_in_cmdclk,
      reset              =>rst_rstin(2),

      --command interface
      clk_cmd                    =>cmdclk_in_cmdclk,
      out_cmd                    =>cmd_out_cmdout,
      out_cmd_val                =>cmd_out_cmdout_val,
      in_cmd                     =>cmd_in_cmdin,
      in_cmd_val                 =>cmd_in_cmdin_val,



     --input ports
      in0_data       =>in0_in_data,
      in0_stop       =>in0_in_stop,
      in0_dval       =>in0_in_dval,
      in0_sync       => '0',

      in1_data       =>in1_in_data,
      in1_stop       =>in1_in_stop,
      in1_dval       =>in1_in_dval,
      in1_sync       => '0',

      in2_data       =>in2_in_data,
      in2_stop       =>in2_in_stop,
      in2_dval       =>in2_in_dval,
      in2_sync       => '0',

      in3_data       =>in3_in_data,
      in3_stop       =>in3_in_stop,
      in3_dval       =>in3_in_dval,
      in3_sync       => '0',

      in4_data       =>in4_in_data,
      in4_stop       =>in4_in_stop,
      in4_dval       =>in4_in_dval,
      in4_sync       => '0',

      in5_data       =>in5_in_data,
      in5_stop       =>in5_in_stop,
      in5_dval       =>in5_in_dval,
      in5_sync       => '0',

      in6_data       =>in6_in_data,
      in6_stop       =>in6_in_stop,
      in6_dval       =>in6_in_dval,
      in6_sync       => '0',

      in7_data       =>in7_in_data,
      in7_stop       =>in7_in_stop,
      in7_dval       =>in7_in_dval,
      in7_sync       => '0',

      in8_data       =>in8_in_data,
      in8_stop       =>in8_in_stop,
      in8_dval       =>in8_in_dval,
      in8_sync       => '0',

      in9_data       =>in9_in_data,
      in9_stop       =>in9_in_stop,
      in9_dval       =>in9_in_dval,
      in9_sync       => '0',

      in10_data       =>in10_in_data,
      in10_stop       =>in10_in_stop,
      in10_dval       =>in10_in_dval,
      in10_sync       => '0',

      in11_data       =>in11_in_data,
      in11_stop       =>in11_in_stop,
      in11_dval       =>in11_in_dval,
      in11_sync       => '0',

      in12_data       =>in12_in_data,
      in12_stop       =>in12_in_stop,
      in12_dval       =>in12_in_dval,
      in12_sync       => '0',

      in13_data       =>in13_in_data,
      in13_stop       =>in13_in_stop,
      in13_dval       =>in13_in_dval,
      in13_sync       => '0',

      in14_data       =>in14_in_data,
      in14_stop       =>in14_in_stop,
      in14_dval       =>in14_in_dval,
      in14_sync       => '0',

      in15_data       =>in15_in_data,
      in15_stop       =>in15_in_stop,
      in15_dval       =>in15_in_dval,
      in15_sync       => '0',

      --output ports
      out0_data      =>out0_out_data,
      out0_stop      =>out0_out_stop,
      out0_dval      =>out0_out_dval,
      out0_sync      => open




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


end architecture arch_sip_router_s16d1   ; -- of sip_router_s16d1
