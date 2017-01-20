--------------------------------------------------------------------------------
-- file name : cid.vhd
--
-- author    : e. barhorst
--
-- company   : 4dsp
--
-- item      : number
--
-- units     : entity       -cid
--             arch_itecture - arch_cid
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
--      from
-- ver  pcb mod    date      changes
-- ===  =======    ========  =======
--
-- 0.0    0        19-01-2009        new version
--
----------------------------------------------
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- specify libraries.
--------------------------------------------------------------------------------

library  ieee ;
use ieee.std_logic_unsigned.all ;
use ieee.std_logic_misc.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_1164.all ;

--------------------------------------------------------------------------------
-- entity declaration
--------------------------------------------------------------------------------
entity cid  is
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
      in_cmd_val        :in  std_logic




   );
end entity cid  ;

--------------------------------------------------------------------------------
-- arch_itecture declaration
--------------------------------------------------------------------------------
architecture arch_cid   of cid  is

-----------------------------------------------------------------------------------
--constant declarations
-----------------------------------------------------------------------------------

-----------------------------------------------------------------------------------
--signal declarations
-----------------------------------------------------------------------------------

-----------------------------------------------------------------------------------
--component declarations
-----------------------------------------------------------------------------------
component cid_regs
generic
(
   start_addr                    :std_logic_vector(27 downto 0):=x"0000000";
   stop_addr                     :std_logic_vector(27 downto 0):=x"0000001"
   );

port
   (
      reset                         :in std_logic;
      --command if
      clk_cmd                       :in  std_logic; --cmd_in and cmd_out are synchronous to this clock;
      out_cmd                       :out std_logic_vector(63 downto 0);
      out_cmd_val                   :out std_logic;
      in_cmd                        :in  std_logic_vector(63 downto 0);
      in_cmd_val                    :in  std_logic;

      --register interface
      clk_reg                       :in  std_logic
   );
end component;

begin

-----------------------------------------------------------------------------------
--component instantiations
-----------------------------------------------------------------------------------
i_cid_regs:cid_regs
generic map
(
   start_addr                   =>start_addr,
   stop_addr                    =>stop_addr
   )
port map
   (
      reset                         =>reset,
      clk_cmd                       =>clk_cmd,
      out_cmd                       =>out_cmd,
      out_cmd_val                   =>out_cmd_val,
      in_cmd                        =>in_cmd,
      in_cmd_val                    =>in_cmd_val,


      clk_reg                       =>clk_cmd

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



end architecture arch_cid   ; -- of cid

