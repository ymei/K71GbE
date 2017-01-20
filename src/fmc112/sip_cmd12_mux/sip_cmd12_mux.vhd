
-------------------------------------------------------------------------------------
-- FILE NAME : sip_cmd12_mux.vhd
--
-- AUTHOR    : StellarIP (c) 4DSP
--
-- COMPANY   : 4DSP
--
-- ITEM      : 1
--
-- UNITS     : Entity       - sip_cmd12_mux
--             architecture - arch_sip_cmd12_mux
--
-- LANGUAGE  : VHDL
--
-------------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------------
-- DESCRIPTION
-- ===========
--
-- sip_cmd12_mux
-- Notes: sip_cmd12_mux
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
entity sip_cmd12_mux  is
port (
--Wormhole 'cmdclk_in':
   cmdclk_in_cmdclk                        : in    std_logic;

--Wormhole 'cmd0_in':
   cmd0_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd0_in_cmdin_val                         : in    std_logic;

--Wormhole 'cmd1_in':
   cmd1_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd1_in_cmdin_val                         : in    std_logic;

--Wormhole 'cmd2_in':
   cmd2_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd2_in_cmdin_val                         : in    std_logic;

--Wormhole 'cmd3_in':
   cmd3_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd3_in_cmdin_val                         : in    std_logic;

--Wormhole 'cmd4_in':
   cmd4_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd4_in_cmdin_val                         : in    std_logic;

--Wormhole 'cmd5_in':
   cmd5_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd5_in_cmdin_val                         : in    std_logic;

--Wormhole 'cmd6_in':
   cmd6_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd6_in_cmdin_val                         : in    std_logic;

--Wormhole 'cmd7_in':
   cmd7_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd7_in_cmdin_val                         : in    std_logic;

--Wormhole 'cmd8_in':
   cmd8_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd8_in_cmdin_val                         : in    std_logic;

--Wormhole 'cmd9_in':
   cmd9_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd9_in_cmdin_val                         : in    std_logic;

--Wormhole 'cmd10_in':
   cmd10_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd10_in_cmdin_val                         : in    std_logic;

--Wormhole 'cmd11_in':
   cmd11_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd11_in_cmdin_val                         : in    std_logic;

--Wormhole 'cmd_out':
   cmd_out_cmdout                          : out   std_logic_vector(63 downto 0);
   cmd_out_cmdout_val                      : out   std_logic
   );
end entity sip_cmd12_mux;

-------------------------------------------------------------------------------------
--Architecture declaration
-------------------------------------------------------------------------------------
architecture arch_sip_cmd12_mux   of sip_cmd12_mux  is

-------------------------------------------------------------------------------------
--Constants declaration
-------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
--constant declarations
-----------------------------------------------------------------------------------
constant nb_in_ports  :integer := 12;
constant data_w       :integer :=64;

type  std2d_data_w   is array(natural range <>) of std_logic_vector(data_w -1  downto 0);
type  std2d_inports  is array(natural range <>) of std_logic_vector(nb_in_ports - 1 downto 0);
-----------------------------------------------------------------------------------
--signal declarations
-----------------------------------------------------------------------------------

signal cmd_in_cmdin        :std2d_data_w(nb_in_ports -1  downto 0);
signal cmd_in_cmdin_val      :std_logic_vector(nb_in_ports -1  downto 0);


begin


-------------------------------------------------------------------------------------
--components instantiations
-------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------
--synchronous processes
-------------------------------------------------------------------------------------

mux_proc : process (cmdclk_in_cmdclk)
   variable data_mux_out :std_logic_vector(data_w-1 downto 0):=(others=>'0');
   variable dval_mux_out :std_logic:='0';
   begin
      if (cmdclk_in_cmdclk'event and cmdclk_in_cmdclk = '1') then
         --choose the right input source for each output
         data_mux_out :=cmd_in_cmdin(0);
         dval_mux_out :=cmd_in_cmdin_val(0);
         for i in 1 to nb_in_ports-1 loop
            data_mux_out :=  cmd_in_cmdin(i) or data_mux_out;
            dval_mux_out :=  cmd_in_cmdin_val(i) or dval_mux_out;
         end loop;

         cmd_out_cmdout    <= data_mux_out;
         cmd_out_cmdout_val<= dval_mux_out;
      end if;
   end process;



-------------------------------------------------------------------------------------
--asynchronous processes
-------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------
--asynchronous mapping
-------------------------------------------------------------------------------------
  cmd_in_cmdin(0)    <= cmd0_in_cmdin;
cmd_in_cmdin_val(0)    <= cmd0_in_cmdin_val;

  cmd_in_cmdin(1)    <=  cmd1_in_cmdin;
cmd_in_cmdin_val(1)    <=  cmd1_in_cmdin_val;

  cmd_in_cmdin(2)    <=  cmd2_in_cmdin;
cmd_in_cmdin_val(2)    <=  cmd2_in_cmdin_val;

  cmd_in_cmdin(3)    <=  cmd3_in_cmdin;
cmd_in_cmdin_val(3)    <=  cmd3_in_cmdin_val;

  cmd_in_cmdin(4)    <=  cmd4_in_cmdin;
cmd_in_cmdin_val(4)    <=  cmd4_in_cmdin_val;

  cmd_in_cmdin(5)    <=  cmd5_in_cmdin;
cmd_in_cmdin_val(5)    <=  cmd5_in_cmdin_val;

  cmd_in_cmdin(6)    <=  cmd6_in_cmdin;
cmd_in_cmdin_val(6)    <=  cmd6_in_cmdin_val;

  cmd_in_cmdin(7)    <=  cmd7_in_cmdin;
cmd_in_cmdin_val(7)    <=  cmd7_in_cmdin_val;

  cmd_in_cmdin(8)    <=  cmd8_in_cmdin;
cmd_in_cmdin_val(8)    <=  cmd8_in_cmdin_val;

  cmd_in_cmdin(9)    <=  cmd9_in_cmdin;
cmd_in_cmdin_val(9)    <=  cmd9_in_cmdin_val;

  cmd_in_cmdin(10)    <=  cmd10_in_cmdin;
cmd_in_cmdin_val(10)    <=  cmd10_in_cmdin_val;

  cmd_in_cmdin(11)    <=  cmd11_in_cmdin;
cmd_in_cmdin_val(11)    <=  cmd11_in_cmdin_val;

end architecture arch_sip_cmd12_mux   ; -- of sip_cmd12_mux
