
-------------------------------------------------------------------------------------
-- FILE NAME : sip_fifo64k.vhd
--
-- AUTHOR    : StellarIP (c) 4DSP
--
-- COMPANY   : 4DSP
--
-- ITEM      : 1
--
-- UNITS     : Entity       - sip_fifo64k
--             architecture - arch_sip_fifo64k
--
-- LANGUAGE  : VHDL
--
-------------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------------
-- DESCRIPTION
-- ===========
--
-- sip_fifo64k
-- Notes: sip_fifo64k
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
entity sip_fifo64k  is
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
   in0_in_data                             : in    std_logic_vector(63 downto 0)
   );
end entity sip_fifo64k;

-------------------------------------------------------------------------------------
--Architecture declaration
-------------------------------------------------------------------------------------
architecture arch_sip_fifo64k   of sip_fifo64k  is

-------------------------------------------------------------------------------------
--Constants declaration
-------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
--Signal declaration
-------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
--components declarations
-------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
--components declarations
-------------------------------------------------------------------------------------
component fifo64k
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

      --output ports
      out0_data      :out    std_logic_vector(63 downto 0);
      out0_stop      :in     std_logic;
      out0_dval      :out    std_logic


   );
end component;

begin


-------------------------------------------------------------------------------------
--components instantiations
-------------------------------------------------------------------------------------
i_fifo64k:fifo64k
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

      --output ports
      out0_data      =>out0_out_data,
      out0_stop      =>out0_out_stop,
      out0_dval      =>out0_out_dval



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


end architecture arch_sip_fifo64k   ; -- of sip_fifo64k
