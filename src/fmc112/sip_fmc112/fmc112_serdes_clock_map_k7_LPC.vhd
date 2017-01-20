library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_misc.all;
  use ieee.numeric_std.all;
library unisim;
  use unisim.vcomponents.all;

entity serdes_clock_map is

generic(
  NBCH : integer := 12;
  NBIC : integer := 3
);
port(

   clk_buf_i  : in std_logic_vector(NBIC-1 downto 0);
   clk_inv_i  : in std_logic_vector(NBIC-1 downto 0);
   clk_div_i  : in std_logic_vector(NBIC-1 downto 0);

   clk_buf_o_data  : out std_logic_vector(NBCH-1 downto 0);
   clk_inv_o_data  : out std_logic_vector(NBCH-1 downto 0);
   clk_div_o_data  : out std_logic_vector(NBCH-1 downto 0);

   clk_buf_o_frame  : out std_logic_vector(NBIC-1 downto 0);
   clk_inv_o_frame  : out std_logic_vector(NBIC-1 downto 0);
   clk_div_o_frame  : out std_logic_vector(NBIC-1 downto 0)

   );
end entity serdes_clock_map;


architecture serdes_clock_map_k7_LPC of serdes_clock_map is
begin

clk_buf_o_data(0)  <= clk_buf_i(0);
clk_buf_o_data(1)  <= clk_buf_i(0);
clk_buf_o_data(2)  <= clk_buf_i(0);
clk_buf_o_data(3)  <= clk_buf_i(1);
clk_buf_o_data(4)  <= clk_buf_i(2);
clk_buf_o_data(5)  <= clk_buf_i(1);
clk_buf_o_data(6)  <= clk_buf_i(1);
clk_buf_o_data(7)  <= clk_buf_i(1);
clk_buf_o_data(8)  <= clk_buf_i(2);
clk_buf_o_data(9)  <= clk_buf_i(2);
clk_buf_o_data(10) <= clk_buf_i(2);
clk_buf_o_data(11) <= clk_buf_i(2);

clk_inv_o_data(0)  <= clk_inv_i(0);
clk_inv_o_data(1)  <= clk_inv_i(0);
clk_inv_o_data(2)  <= clk_inv_i(0);
clk_inv_o_data(3)  <= clk_inv_i(1);
clk_inv_o_data(4)  <= clk_inv_i(2);
clk_inv_o_data(5)  <= clk_inv_i(1);
clk_inv_o_data(6)  <= clk_inv_i(1);
clk_inv_o_data(7)  <= clk_inv_i(1);
clk_inv_o_data(8)  <= clk_inv_i(2);
clk_inv_o_data(9)  <= clk_inv_i(2);
clk_inv_o_data(10) <= clk_inv_i(2);
clk_inv_o_data(11) <= clk_inv_i(2);

clk_div_o_data(0)  <= clk_div_i(0);
clk_div_o_data(1)  <= clk_div_i(0);
clk_div_o_data(2)  <= clk_div_i(0);
clk_div_o_data(3)  <= clk_div_i(1);
clk_div_o_data(4)  <= clk_div_i(2);
clk_div_o_data(5)  <= clk_div_i(1);
clk_div_o_data(6)  <= clk_div_i(1);
clk_div_o_data(7)  <= clk_div_i(1);
clk_div_o_data(8)  <= clk_div_i(2);
clk_div_o_data(9)  <= clk_div_i(2);
clk_div_o_data(10) <= clk_div_i(2);
clk_div_o_data(11) <= clk_div_i(2);

clk_buf_o_frame(0) <= clk_buf_i(0);
clk_buf_o_frame(1) <= clk_buf_i(2);
clk_buf_o_frame(2) <= clk_buf_i(2);

clk_inv_o_frame(0) <= clk_inv_i(0);
clk_inv_o_frame(1) <= clk_inv_i(2);
clk_inv_o_frame(2) <= clk_inv_i(2);

clk_div_o_frame(0) <= clk_div_i(0);
clk_div_o_frame(1) <= clk_div_i(2);
clk_div_o_frame(2) <= clk_div_i(2);

end architecture serdes_clock_map_k7_LPC;