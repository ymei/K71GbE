--------------------------------------------------------------------------------
-- file name : router_s16d1.vhd
--
-- author    : e. barhorst
--
-- company   : 4dsp
--
-- item      : number
--
-- units     : entity       -router_s16d1
--             arch_itecture - arch_router_s16d1
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
entity router_s16d1  is
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
end entity router_s16d1  ;

--------------------------------------------------------------------------------
-- arch_itecture declaration
--------------------------------------------------------------------------------
architecture arch_router_s16d1   of router_s16d1  is

-----------------------------------------------------------------------------------
--constant declarations
-----------------------------------------------------------------------------------
constant nb_in_ports  :integer :=16;
constant nb_out_ports :integer := 1;
constant data_w       :integer :=64;

type  std2d_data_w   is array(natural range <>) of std_logic_vector(data_w -1  downto 0);
type  std2d_6b       is array(natural range <>) of std_logic_vector(5 downto 0);
type  std2d_outports  is array(natural range <>) of std_logic_vector(nb_out_ports - 1 downto 0);
type  std2d_inports  is array(natural range <>) of std_logic_vector(nb_in_ports - 1 downto 0);
-----------------------------------------------------------------------------------
--signal declarations
-----------------------------------------------------------------------------------

signal data_mux_in         :std2d_data_w(nb_in_ports -1  downto 0);
signal data_mux_out        :std2d_data_w(nb_out_ports -1  downto 0);
signal dval_mux_in         :std_logic_vector(nb_in_ports -1  downto 0);
signal sync_mux_in         :std_logic_vector(nb_in_ports -1  downto 0);
signal dval_mux_out        :std_logic_vector(nb_out_ports -1  downto 0);
signal sync_mux_out        :std_logic_vector(nb_out_ports -1  downto 0);
signal stop_mux_in         :std2d_inports(nb_out_ports -1  downto 0);
signal stop_mux_out        :std_logic_vector(nb_in_ports -1  downto 0);
signal data_mux_out_sel    :std2d_6b(nb_out_ports -1  downto 0);
signal stop_out            :std_logic_vector(nb_out_ports -1 downto 0);
-----------------------------------------------------------------------------------
--component declarations
-----------------------------------------------------------------------------------
component router_s16d1_regs
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
      ou0_sel                       :out std_logic_vector(5 downto 0);
      ou1_sel                       :out std_logic_vector(5 downto 0);
      ou2_sel                       :out std_logic_vector(5 downto 0);
      ou3_sel                       :out std_logic_vector(5 downto 0);
      ou4_sel                       :out std_logic_vector(5 downto 0);
      ou5_sel                       :out std_logic_vector(5 downto 0);
      ou6_sel                       :out std_logic_vector(5 downto 0);
      ou7_sel                       :out std_logic_vector(5 downto 0)
   );
end component;

begin

-----------------------------------------------------------------------------------
--component instantiations
-----------------------------------------------------------------------------------
i_router_s16d1_regs:router_s16d1_regs
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
      ou0_sel                       =>data_mux_out_sel(0),
      ou1_sel                       =>open,--data_mux_out_sel(1),
      ou2_sel                       =>open,--data_mux_out_sel(2),
      ou3_sel                       =>open,
      ou4_sel                       =>open,                 --data_mux_out_sel(4),--
      ou5_sel                       =>open,                 --data_mux_out_sel(5),--
      ou6_sel                       =>open,                 --data_mux_out_sel(6),--
      ou7_sel                       =>open                  --data_mux_out_sel(7) --
   );


-----------------------------------------------------------------------------------
--synchronous processes
-----------------------------------------------------------------------------------

mux_gen:for i in 0 to nb_out_ports -1 generate
   mux_proc : process (clk)
   begin
      if (clk'event and clk = '1') then
         --choose the right input source for each output
         if (conv_integer(data_mux_out_sel(i))>=nb_in_ports) then
            data_mux_out(i) <= (others=>'0');
            dval_mux_out(i) <= '0';
         else
            data_mux_out(i) <= data_mux_in(conv_integer(data_mux_out_sel(i)));
            dval_mux_out(i) <= dval_mux_in(conv_integer(data_mux_out_sel(i)));
            sync_mux_out(i) <= sync_mux_in(conv_integer(data_mux_out_sel(i)));
         end if;

         --the stop signal is routed backwards to the inputs. it is forbidden
         --to route one input to two outputs (at least then the stop signal routing
         --wil not be correct
         --each output will enablet the stop signal only to the channel it is
         --taking its data from. The input will then or the stop signals from all the
         --possible outputs. Normally only one can toggle the otehrs should stay zero
         for j in 0 to nb_in_ports -1 loop
            if (j = conv_integer(data_mux_out_sel(i))) then
               stop_mux_in(i)(j) <= stop_out(i);
            else
               stop_mux_in(i)(j) <= '0';
            end if;
         end loop;
      end if;
   end process;
end generate;

stop_gen:for i in 0 to nb_in_ports -1 generate

   stop_proc : process (clk)
   variable stop_mux_vect         :std_logic_vector(nb_out_ports -1  downto 0);
   begin
      if (clk'event and clk = '1') then

         --the stop signal is routed backwards to the inputs. it is forbidden
         --to route one input to two outputs (at least then the stop signal routing
         --wil not be correct
         --each output will enablet the stop signal only to the channel it is
         --taking its data from. The input will then or the stop signals from all the
         --possible outputs. Normally only one can toggle the otehrs should stay zero
         --recreate the stop vectors
          for j in 0 to nb_out_ports -1 loop
               stop_mux_vect(j) := stop_mux_in(j)(i);
         end loop;
         stop_mux_out(i) <= or_reduce(stop_mux_vect);
      end if;
   end process;
end generate;

-----------------------------------------------------------------------------------
--asynchronous processes
-----------------------------------------------------------------------------------






-----------------------------------------------------------------------------------
--asynchronous mapping
-----------------------------------------------------------------------------------
--map the inputs
data_mux_in(0)          <=             in0_data;
dval_mux_in(0)          <=             in0_dval;
sync_mux_in(0)          <=             in0_sync;
          in0_stop      <=  stop_mux_out(0);

data_mux_in(1)          <=             in1_data;
dval_mux_in(1)          <=             in1_dval;
sync_mux_in(1)          <=             in1_sync;
          in1_stop      <=  stop_mux_out(1);

data_mux_in(2)          <=             in2_data;
dval_mux_in(2)          <=             in2_dval;
sync_mux_in(2)          <=             in2_sync;
          in2_stop      <=  stop_mux_out(2);

data_mux_in(3)          <=             in3_data;
dval_mux_in(3)          <=             in3_dval;
sync_mux_in(3)          <=             in3_sync;
          in3_stop      <=  stop_mux_out(3);

data_mux_in(4)          <=             in4_data;
dval_mux_in(4)          <=             in4_dval;
sync_mux_in(4)          <=             in4_sync;
          in4_stop      <=  stop_mux_out(4);

data_mux_in(5)          <=             in5_data;
dval_mux_in(5)          <=             in5_dval;
sync_mux_in(5)          <=             in5_sync;
          in5_stop      <=  stop_mux_out(5);

data_mux_in(6)          <=             in6_data;
dval_mux_in(6)          <=             in6_dval;
sync_mux_in(6)          <=             in6_sync;
          in6_stop      <=  stop_mux_out(6);

data_mux_in(7)          <=             in7_data;
dval_mux_in(7)          <=             in7_dval;
sync_mux_in(7)          <=             in7_sync;
          in7_stop      <=  stop_mux_out(7);

data_mux_in(8)          <=             in8_data;
dval_mux_in(8)          <=             in8_dval;
sync_mux_in(8)          <=             in8_sync;
          in8_stop      <=  stop_mux_out(8);

data_mux_in(9)          <=             in9_data;
dval_mux_in(9)          <=             in9_dval;
sync_mux_in(9)          <=             in9_sync;
          in9_stop      <=  stop_mux_out(9);

data_mux_in(10)          <=             in10_data;
dval_mux_in(10)          <=             in10_dval;
sync_mux_in(10)          <=             in10_sync;
          in10_stop      <=  stop_mux_out(10);

data_mux_in(11)          <=             in11_data;
dval_mux_in(11)          <=             in11_dval;
sync_mux_in(11)          <=             in11_sync;
          in11_stop      <=  stop_mux_out(11);

data_mux_in(12)          <=             in12_data;
dval_mux_in(12)          <=             in12_dval;
sync_mux_in(12)          <=             in12_sync;
          in12_stop      <=  stop_mux_out(12);

data_mux_in(13)          <=             in13_data;
dval_mux_in(13)          <=             in13_dval;
sync_mux_in(13)          <=             in13_sync;
          in13_stop      <=  stop_mux_out(13);

data_mux_in(14)          <=             in14_data;
dval_mux_in(14)          <=             in14_dval;
sync_mux_in(14)          <=             in14_sync;
          in14_stop      <=  stop_mux_out(14);

data_mux_in(15)          <=             in15_data;
dval_mux_in(15)          <=             in15_dval;
sync_mux_in(15)          <=             in15_sync;
          in15_stop      <=  stop_mux_out(15);

--map the outputs
      out0_data         <= data_mux_out(0);
      out0_dval         <= dval_mux_out(0);
      out0_sync         <= sync_mux_out(0);
stop_out(0)             <=           out0_stop;




end architecture arch_router_s16d1   ; -- of router_s16d1

