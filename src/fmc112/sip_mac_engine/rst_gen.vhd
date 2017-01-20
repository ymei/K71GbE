--------------------------------------------------------------------------------
-- file name : rst_gen.vhd
--
-- author    : e. barhorst
--
-- company   : 4dsp
--
-- item      : number
--
-- units     : entity       -rst_gen
--             arch_itecture - arch_rst_gen
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
library UNISIM;
use UNISIM.Vcomponents.ALL;
--------------------------------------------------------------------------------
-- entity declaration
--------------------------------------------------------------------------------
entity rst_gen  is
generic ( reset_base :integer:=80000);
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
end entity rst_gen  ;

--------------------------------------------------------------------------------
-- arch_itecture declaration
--------------------------------------------------------------------------------
architecture arch_rst_gen   of rst_gen  is

-----------------------------------------------------------------------------------
--constant declarations
-----------------------------------------------------------------------------------
constant reset1_cnt     :integer :=reset_base*16-1;
constant reset2_cnt     :integer :=reset_base*8-1;
constant reset3_cnt     :integer :=reset_base*4-1;
type reset_sm_type  is  (reset_all, reset_dcm, wait_dcm_lock, wait_reset1, wait_reset2, wait_reset3, idle);
-----------------------------------------------------------------------------------
--signal declarations
-----------------------------------------------------------------------------------
signal reset_i_reg            :std_logic;
signal reset_i_reg2           :std_logic;

signal all_clk_locked         :std_logic;

signal reset1_sig              :std_logic;
signal reset2_sig              :std_logic;
signal reset3_sig              :std_logic;


signal reset_sm               :reset_sm_type;
signal reset_sm_prev          :reset_sm_type;

signal rst_in_cnt             :std_logic_vector(19 downto 0):=(others=>'0');
-----------------------------------------------------------------------------------
--component declarations
-----------------------------------------------------------------------------------

begin

-----------------------------------------------------------------------------------
--component instantiations
-----------------------------------------------------------------------------------

-----------------------------------------------------------------------------------
--synchronous processes
-----------------------------------------------------------------------------------

reset_sm_proc: process(clk )
variable wait_cnt :integer range 0 to reset1_cnt;

begin
   if(clk'event and clk='1') then

      ---debounce incoming signal
      --typical switches will not bounce more  then 6 ms (750K clock cycles @ 125 MHz)

      if(reset_i = '1' and rst_in_cnt /= 1048575) then
           rst_in_cnt  <= rst_in_cnt +1;
      elsif(reset_i = '0' and rst_in_cnt /= 0) then
           rst_in_cnt  <= rst_in_cnt -1;
      end if;
      if(reset_i = '1' and rst_in_cnt = 1048575) then
         reset_i_reg <= '1';
      elsif(reset_i = '0' and rst_in_cnt = 0) then
         reset_i_reg <= '0';
      end if;


      reset_i_reg2   <= reset_i_reg;
      if (reset_i_reg2= '1') then
         reset_sm       <= reset_all;
         reset_sm_prev  <= reset_all;
         wait_cnt       := 0;
         all_clk_locked <= '0';

      else


         all_clk_locked <= clk_locked;

         reset_sm_prev <= reset_sm;
         case reset_sm  is
            when reset_all =>
               if (all_clk_locked = '1' and wait_cnt = 16) then
                  reset_sm <= reset_dcm;
                  wait_cnt :=0;
               elsif (all_clk_locked = '1') then
                  reset_sm <= reset_all;
                  wait_cnt := wait_cnt+1;
               else
                  reset_sm <= reset_all;
                  wait_cnt := wait_cnt;
               end if;

            when reset_dcm =>
               if (wait_cnt = 8) then
                  reset_sm <= wait_dcm_lock;
                  wait_cnt :=0;
               else
                  reset_sm <= reset_dcm;
                  wait_cnt := wait_cnt +1;
               end if;
            when wait_dcm_lock =>
               if (all_clk_locked = '1' and wait_cnt = 16 and (reset_i_reg2='0')) then
                  reset_sm <= wait_reset1;
                  wait_cnt :=0;
               elsif (all_clk_locked = '1' and ( reset_i_reg2='0')) then
                  reset_sm <= wait_dcm_lock;
                  wait_cnt := wait_cnt+1;
               else
                  reset_sm <= wait_dcm_lock;
                  wait_cnt := wait_cnt;
               end if;

            when wait_reset1 =>
               if (all_clk_locked = '0' ) then
                  reset_sm <= reset_all;
               elsif(wait_cnt = reset1_cnt) then
                  reset_sm <= wait_reset2;
                  wait_cnt :=0;
               else
                  reset_sm <= wait_reset1;
                  wait_cnt := wait_cnt+1;
               end if;
            when wait_reset2 =>
               if (all_clk_locked = '0' ) then
                  reset_sm <= reset_all;
               elsif(wait_cnt = reset2_cnt) then
                  reset_sm <= wait_reset3;
                  wait_cnt :=0;
               else
                  reset_sm <= wait_reset2;
                  wait_cnt := wait_cnt+1;
               end if;
            when wait_reset3 =>
               if (all_clk_locked = '0' ) then
                  reset_sm <= reset_all;
               elsif(wait_cnt = reset3_cnt) then
                  reset_sm <= idle;
                  wait_cnt :=0;
               else
                  reset_sm <= wait_reset3;
                  wait_cnt := wait_cnt+1;
               end if;
            when idle =>
               if (all_clk_locked = '0' ) then
                  reset_sm <= reset_all;
               else
                  reset_sm <= idle;
               end if;
            when others=>
               reset_sm <= reset_all;
         end case;
      end if;
   end if;
end process;

reset_proc: process(clk )
begin
   if(clk'event and clk='1') then
      if (reset_i_reg2= '1') then
         reset1_sig      <= '1';
         reset2_sig      <= '1';
         reset3_sig      <= '1';
         dcm_reset       <= '1';
      else
         --reset the DCM only when the SM asks to do so
         if (reset_sm = reset_dcm) then
            dcm_reset      <= '1';
         else
            dcm_reset      <= '0';
         end if;

         --reset1 is deaserted when the reset_sm exits the wait_reset1 state
         if (reset_sm = wait_reset2 and reset_sm_prev = wait_reset1) then
            reset1_sig      <= '0';
         elsif (reset_sm = reset_all) then
            reset1_sig     <= '1';
         end if;

         --reset2 is deaserted when the reset_sm exits the wait_reset2 state
         if (reset_sm = wait_reset3 and reset_sm_prev = wait_reset2) then
            reset2_sig      <= '0';
         elsif (reset_sm = reset_all) then
            reset2_sig     <= '1';
         end if;
         --reset2 is deaserted when the reset_sm exits the wait_reset2 state
         if (reset_sm = idle and reset_sm_prev = wait_reset3) then
            reset3_sig      <= '0';
         elsif (reset_sm = reset_all) then
            reset3_sig     <= '1';
         end if;

      end if;
   end if;
end process;

reset_proc2: process(clk )
begin
   if(clk'event and clk='1') then
      reset1_o    <= reset1_sig;
		reset2_o    <= reset2_sig;
		reset3_o    <= reset3_sig;
   end if;
end process;


-----------------------------------------------------------------------------------
--asynchronous processes
-----------------------------------------------------------------------------------


-----------------------------------------------------------------------------------
--asynchronous mapping
-----------------------------------------------------------------------------------




end architecture arch_rst_gen   ; -- of rst_gen

