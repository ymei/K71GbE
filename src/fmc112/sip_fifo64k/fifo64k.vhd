--------------------------------------------------------------------------------
-- file name : fifo64k.vhd
--
-- author    : e. barhorst
--
-- company   : 4dsp
--
-- item      : number
--
-- units     : entity       -fifo64k
--             arch_itecture - arch_fifo64k
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
entity fifo64k  is
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
end entity fifo64k  ;

--------------------------------------------------------------------------------
-- arch_itecture declaration
--------------------------------------------------------------------------------
architecture arch_fifo64k   of fifo64k  is

-----------------------------------------------------------------------------------
--constant declarations
-----------------------------------------------------------------------------------
constant bit_ctrl_stop  :integer := 0;
constant bit_osim_en		:integer := 1;
-----------------------------------------------------------------------------------
--signal declarations
-----------------------------------------------------------------------------------

signal status           :std_logic_vector(31 downto 0);
signal status_clear     :std_logic;
signal ctrl             :std_logic_vector(31 downto 0);
signal fifo_rd_en       :std_logic;
signal fifo_overflow    :std_logic;
signal fifo_dout        :std_logic_vector(63 downto 0);
signal fifo_full        :std_logic;
signal fifo_empty       :std_logic;
signal fifo_valid       :std_logic;
signal fifo_data_count  :std_logic_vector(12 downto 0);
signal sim_cntr         :std_logic_vector(11 downto 0);
-----------------------------------------------------------------------------------
--component declarations
-----------------------------------------------------------------------------------
component fifo64k_regs
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
      clk_reg                       :in  std_logic;
      status                        :in  std_logic_vector(31 downto 0);
      status_clear                  :out std_logic;
      ctrl                          :out std_logic_vector(31 downto 0)
   );
end component;

component  fifo64k_fifo_64x8K
	port
	(
	rst            : IN std_logic;
	clk            : IN std_logic;
	din            : IN std_logic_VECTOR(63 downto 0);
	wr_en          : IN std_logic;
	rd_en          : IN std_logic;
	dout           : OUT std_logic_VECTOR(63 downto 0);
	full           : OUT std_logic;
	empty          : OUT std_logic;
	valid          : OUT std_logic;
	data_count     : OUT std_logic_VECTOR(12 downto 0);
	prog_full      : OUT std_logic
	);
end component ;
begin

-----------------------------------------------------------------------------------
--component instantiations
-----------------------------------------------------------------------------------
i_fifo64k_regs:fifo64k_regs
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


      clk_reg                       =>clk,
      status                        =>status,
      status_clear                  =>status_clear,
      ctrl                          =>ctrl
   );

i_fifo64k_fifo_64x8K:fifo64k_fifo_64x8K
	port map
	(
	rst            =>reset,
	clk            =>clk,
	din            =>in0_data,
	wr_en          =>in0_dval,
	rd_en          =>fifo_rd_en,
	dout           =>fifo_dout,
	full           =>fifo_full,
	empty          =>fifo_empty,
	valid          =>fifo_valid,
	data_count     =>fifo_data_count,
	prog_full      =>in0_stop
	);
-----------------------------------------------------------------------------------
--synchronous processes
-----------------------------------------------------------------------------------


ctrl_proc : process (clk)
   begin
      if(reset = '1' ) then
         fifo_overflow <= '0' ;
         fifo_rd_en    <= '0' ;
         sim_cntr      <= (others=>'0');
         out0_dval     <= '0' ;
      elsif (clk'event and clk = '1') then
         --we only read when the ctrl register does not inidcate we have to stop
         --and when the output does not indicate we have to stop
         if(ctrl(bit_ctrl_stop)='1' or out0_stop = '1' ) then
            fifo_rd_en <= '0';
         else
            fifo_rd_en <= not fifo_empty;
         end if;

         if (status_clear='1' ) then
            fifo_overflow <= '0';
         elsif(fifo_full = '1' and in0_dval='1' ) then
            fifo_overflow <= '1';
         end if;

         if(ctrl(bit_osim_en)='1' and fifo_valid='1' )then
            sim_cntr <= sim_cntr +4;
            out0_data <=x"0" & sim_cntr + 3 & x"0" & sim_cntr + 2 & x"0" & sim_cntr + 1 & x"0" & sim_cntr;
            out0_dval <=fifo_valid;
         else
            out0_data <=fifo_dout;
            out0_dval <=fifo_valid;
         end if;


      end if;
   end process;


-----------------------------------------------------------------------------------
--asynchronous processes
-----------------------------------------------------------------------------------

status(15 downto 0) <= "000" & fifo_data_count;
status(16)          <= fifo_overflow;
status(31 downto 17)<= (others=>'0');



-----------------------------------------------------------------------------------
--asynchronous mapping
-----------------------------------------------------------------------------------


end architecture arch_fifo64k   ; -- of fifo64k




