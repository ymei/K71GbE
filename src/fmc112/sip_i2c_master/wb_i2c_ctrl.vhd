
library ieee;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;
use ieee.std_logic_misc.all ;

entity wb_i2c_ctrl is
port (
   -- Wishbone signals
      wb_clk_i     :in std_logic;                     -- master clock input
      wb_rst_i     :in std_logic;                     -- synchronous active high reset
      wb_adr_o     :out std_logic_vector(3 downto 0);  -- lower address bits
      wb_dat_i     :in std_logic_vector(7 downto 0);        -- databus input
      wb_dat_o     :out std_logic_vector(7 downto 0);       -- databus output
      wb_sel_o     :out std_logic_vector(3 downto 0);         -- byte select inputs
      wb_we_o      :out std_logic;                     -- write enable input
      wb_stb_o     :out std_logic;                     -- stobe/core select signal
      wb_cyc_o     :out std_logic;                     -- valid bus cycle input
      wb_ack_i     :in std_logic;                    -- bus cycle acknowledge output
      wb_err_i     :in std_logic;                    -- termination w/ error
      wb_int_i     :in std_logic;                    -- interrupt request signal output


      PRER        :in std_logic_vector(15 downto 0);
      ctrl        :in std_logic_vector(7 downto 0);
      sl_adr      :in std_logic_vector(7 downto 0);
      sub_adr     :in std_logic_vector(7 downto 0);
      wr_data     :in std_logic_vector(7 downto 0);

      read_req     :in std_logic;
      init_req     :in std_logic;
      transfer_req :in std_logic;
      sub_adr_req  :in std_logic;

      busy           :out std_logic;
      transfer_done  :out std_logic;
      init_done      :out std_logic;
      error          :out std_logic;
      rd_data        :out std_logic_vector(7 downto 0)
);

end wb_i2c_ctrl;

architecture wb_i2c_ctrl_syn of wb_i2c_ctrl is

-----------------------------------------------------------------------------------
--constant declarations
-----------------------------------------------------------------------------------
constant i2s_CTR_adr       :std_logic_vector(3 downto 0) := x"2";
constant i2s_RXR_adr       :std_logic_vector(3 downto 0) := x"3";
constant i2s_TXR_adr       :std_logic_vector(3 downto 0) := x"3";
constant i2s_SR_adr        :std_logic_vector(3 downto 0) := x"4";
constant i2s_CR_adr        :std_logic_vector(3 downto 0) := x"4";
constant i2s_PRERlo_adr    :std_logic_vector(3 downto 0) := x"0";
constant i2s_PRERhi_adr    :std_logic_vector(3 downto 0) := x"1";


constant i2s_sr_tip       :integer := 1;
constant i2s_sr_rxack     :integer := 7;

constant i2s_start_rd         :std_logic_vector(7 downto 0) := x"69";
constant i2s_start_adr_wr     :std_logic_vector(7 downto 0) := x"91";
constant i2s_start_sub_wr     :std_logic_vector(7 downto 0) := x"11";
constant i2s_start_sub_rd     :std_logic_vector(7 downto 0) := x"51";
constant i2s_start_data_wr    :std_logic_vector(7 downto 0) := x"51";


-----------------------------------------------------------------------------------
--signal declarations
-----------------------------------------------------------------------------------
type i2s_sm_type is (i2s_init, i2s_idle, i2s_sl_wr_adr,i2s_sl_rd_adr , i2s_sub_adr, i2s_read, i2s_write, i2s_wait_ack);

signal i2s_sm            :i2s_sm_type;
signal i2s_sm_prev       :i2s_sm_type;
signal i2s_sm_prev2       :i2s_sm_type;
signal i2s_sm_prev3       :i2s_sm_type;
signal ack_entry_state  :i2s_sm_type;

signal i2s_TIP :std_logic;
signal i2s_ack :std_logic;
signal long_ack_state :std_logic;

signal mux_sel :integer := 0;
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
i2s_sm_proc: process(wb_clk_i, wb_rst_i)
begin
if (wb_rst_i = '1') then
   i2s_sm             <= i2s_init;
   i2s_sm_prev        <= i2s_idle;
   i2s_sm_prev2        <= i2s_idle;
   i2s_sm_prev3        <= i2s_idle;

elsif( wb_clk_i'event and wb_clk_i = '1') then
      i2s_sm_prev        <= i2s_sm;
      i2s_sm_prev2        <= i2s_sm_prev;
      i2s_sm_prev3        <= i2s_sm_prev2;
   case i2s_sm is
      when  i2s_init =>
         --during init the clock divide register is set
         if (i2s_sm_prev = i2s_init) then
            i2s_sm <= i2s_idle;
         else
            i2s_sm <= i2s_init;
         end if;

      when  i2s_idle =>
         if (init_req = '1') then
            i2s_sm <= i2s_init;
         elsif (transfer_req = '1' and (sub_adr_req = '1' or read_req= '0')) then
            i2s_sm <= i2s_sl_wr_adr;
         elsif (transfer_req = '1' ) then
            i2s_sm <= i2s_sl_rd_adr;
         else
            i2s_sm <= i2s_idle;
         end if;


      when i2s_sl_wr_adr =>
         i2s_sm <=  i2s_wait_ack;

      when i2s_sl_rd_adr =>
         i2s_sm <=  i2s_wait_ack;

      when  i2s_sub_adr =>
         i2s_sm <=  i2s_wait_ack;

      when  i2s_read =>
         i2s_sm <=  i2s_wait_ack;

      when  i2s_write =>
         i2s_sm <=  i2s_wait_ack;

      when i2s_wait_ack =>
         if (i2s_TIP = '0' and i2s_ack = '0' and ack_entry_state = i2s_sl_wr_adr and sub_adr_req = '1'
                  and long_ack_state ='1') then

            i2s_sm <= i2s_sub_adr;
         elsif (i2s_TIP = '0' and i2s_ack = '0' and (ack_entry_state = i2s_sl_wr_adr or ack_entry_state = i2s_sub_adr)
                  and read_req = '0' and long_ack_state ='1') then

            i2s_sm <= i2s_write;
         elsif (i2s_TIP = '0' and i2s_ack = '0' and (ack_entry_state = i2s_sl_rd_adr)
                           and long_ack_state ='1') then

            i2s_sm <= i2s_read;
         elsif (i2s_TIP = '0' and i2s_ack = '0' and (ack_entry_state = i2s_sub_adr)
                                    and long_ack_state ='1') then

            i2s_sm <= i2s_sl_rd_adr;

         elsif (i2s_TIP = '0' and long_ack_state ='1') then
            i2s_sm <= i2s_idle;
         else
            i2s_sm <= i2s_wait_ack;
         end if;
      end case;

end if;
end process;

i2s_ctrl_proc: process(wb_clk_i, wb_rst_i)
begin
if (wb_rst_i = '1') then
   ack_entry_state   <= i2s_init;
      transfer_done <= '0';
      init_done <= '0';
      error <= '0';
      i2s_TIP <= '0';
      i2s_ack <= '0';
      busy <= '0';

elsif( wb_clk_i'event and wb_clk_i = '1') then

   if (i2s_sm /= i2s_sm_prev) then
      ack_entry_state <= i2s_sm_prev;
   end if;

   if (i2s_sm_prev = i2s_wait_ack and i2s_sm = i2s_idle and ack_entry_state = i2s_read) then
      rd_data <= wb_dat_i;
   end if;

   if (i2s_sm = i2s_idle and i2s_sm_prev = i2s_wait_ack  ) then
      transfer_done <= '1';
   else
      transfer_done <= '0';
   end if;

   if (i2s_sm = i2s_idle and i2s_sm_prev = i2s_init) then
         init_done <= '1';
   else
         init_done <= '0';
   end if;


   if (i2s_sm_prev = i2s_idle and i2s_sm /= i2s_idle) then
      error <= '0';
   elsif (long_ack_state = '1' and i2s_TIP = '0' and i2s_ack = '1' and ack_entry_state /= i2s_read) then
      error <= '1';
   end if;

   if (i2s_sm_prev = i2s_wait_ack and i2s_sm = i2s_wait_ack) then
      i2s_TIP <= wb_dat_i(i2s_sr_tip);
      i2s_ack <= wb_dat_i(i2s_sr_rxack);
   end if;

   if (  i2s_sm /= i2s_idle and i2s_sm_prev = i2s_idle) then
      busy <= '1';
   elsif (  i2s_sm_prev3 /= i2s_idle and i2s_sm_prev2 = i2s_idle) then
      busy <= '0';
   end if;


end if;
end process;




-----------------------------------------------------------------------------------
--asynchronous processes
-----------------------------------------------------------------------------------
wb_data_mux :process(i2s_sm, i2s_sm_prev,read_req, ack_entry_state, i2s_TIP,ctrl, PRER, sl_adr,sub_adr,wr_data  )
   begin

      if (i2s_sm_prev = i2s_init and i2s_sm = i2s_idle) then
         wb_dat_o    <= ctrl;
         wb_adr_o   <= i2s_CTR_adr;
         mux_sel <=0;
      elsif (i2s_sm_prev = i2s_init and i2s_sm = i2s_init) then
         wb_dat_o    <= PRER(15 downto 8);
         wb_adr_o   <= i2s_PRERhi_adr;
         mux_sel <=1;
      elsif (i2s_sm = i2s_init) then
         wb_dat_o    <= PRER(7 downto 0);
         wb_adr_o   <= i2s_PRERlo_adr;
         mux_sel <=2;
      elsif (i2s_sm = i2s_sl_wr_adr) then
         wb_dat_o    <= sl_adr(7 downto 1) & '0';
         wb_adr_o   <= i2s_TXR_adr;
         mux_sel <=3;
      elsif (i2s_sm = i2s_sl_rd_adr) then
         wb_dat_o    <= sl_adr(7 downto 1) & '1' ;
         wb_adr_o   <= i2s_TXR_adr;
         mux_sel <=3;
      elsif (i2s_sm = i2s_sub_adr ) then
         wb_dat_o    <= sub_adr;
         wb_adr_o   <= i2s_TXR_adr;
         mux_sel <=4;
      elsif (i2s_sm = i2s_write ) then
         wb_dat_o    <= wr_data;
         wb_adr_o   <= i2s_TXR_adr;
         mux_sel <=5;
      elsif ( i2s_sm_prev = i2s_read) then
         wb_dat_o    <= i2s_start_rd;
         wb_adr_o   <= i2s_CR_adr;
         mux_sel <=6;
      elsif (i2s_sm_prev = i2s_write ) then
         wb_dat_o    <= i2s_start_data_wr;
         wb_adr_o   <= i2s_CR_adr;
         mux_sel <=7;
      elsif ( i2s_sm_prev = i2s_sub_adr and read_req = '0') then
         wb_dat_o    <= i2s_start_sub_wr;
         wb_adr_o   <= i2s_CR_adr;
         mux_sel <=7;
      elsif ( i2s_sm_prev = i2s_sub_adr ) then
         wb_dat_o    <= i2s_start_sub_rd;
         wb_adr_o   <= i2s_CR_adr;
         mux_sel <=7;
      elsif (i2s_sm = i2s_wait_ack and i2s_sm_prev /= i2s_wait_ack ) then
         wb_dat_o    <= i2s_start_adr_wr;
         wb_adr_o   <= i2s_CR_adr;
         mux_sel <=8;
      --elsif (i2s_TIP = '0' and long_ack_state = '1' and ack_entry_state = i2s_read ) then
      elsif (i2s_sm = i2s_idle and i2s_sm_prev = i2s_wait_ack  and ack_entry_state = i2s_read ) then
         wb_dat_o    <= (others =>'0');
         wb_adr_o   <= i2s_RXR_adr;
         mux_sel <=9;
      else
         wb_dat_o    <= (others =>'0');
         wb_adr_o   <= i2s_SR_adr;
         mux_sel <=10;
      end if;



   end process;


we_proc :process(i2s_sm, i2s_sm_prev,ack_entry_state  )
   begin
      if (i2s_sm_prev = i2s_init or i2s_sm = i2s_write or i2s_sm = i2s_sub_adr or i2s_sm = i2s_sl_rd_adr or i2s_sm = i2s_sl_wr_adr
            or i2s_sm = i2s_init  or (i2s_sm = i2s_wait_ack and i2s_sm_prev /= i2s_wait_ack and ack_entry_state /= i2s_read)) then
         wb_we_o  <= '1';
      else
         wb_we_o <= '0';
      end if;
end process;
-----------------------------------------------------------------------------------
--asynchronous mapping
-----------------------------------------------------------------------------------



 wb_cyc_o   <= '1';
 wb_stb_o <= '1';

 wb_sel_o <= (others =>'0');

 long_ack_state <=  '1' when i2s_sm = i2s_wait_ack and i2s_sm_prev = i2s_wait_ack
                              and i2s_sm_prev2 = i2s_wait_ack and i2s_sm_prev3 = i2s_wait_ack
                    else '0';
-------------------
-------------------
end wb_i2c_ctrl_syn;