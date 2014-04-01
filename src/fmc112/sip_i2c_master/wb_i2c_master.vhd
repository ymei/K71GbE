--------------------------------------------------------------------------------

--
-- Ease 5.2 Revision 12.
-- Design library : increment1.
-- Host name      : BREDW754.
-- User name      : BarhorstE.
-- Time stamp     : Tue Aug 30 16:33:21 2005.
--
-- --------------------------------------------------------------------------------
-- AUTHOR    : E. Barhorst
--
-- COMPANY   : 4DSP
--
-- ITEM      : Number
--
-- UNITS     : Entity
--             architecture
--
-- LANGUAGE  : VHDL
--
--------------------------------------------------------------------------------
-- DESCRIPTION
-- ===========
--
--
-- Notes:
--------------------------------------------------------------------------------
--
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
--      FROM
-- VER  PCB MOD    DATE      CHANGES
-- ===  =======    ========  =======
--
-- 0.0    0        05-12-2006        New Version Barhorst E
-- Company        : 4DSP Inc..
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Entity declaration of 'i2c_master_top'.
-- Last modified : Tue Aug 02 14:56:53 2005.
--------------------------------------------------------------------------------
-- Wishbone interface for i2c_master core


library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;

entity i2c_master_top is
  generic(
    ARST_LVL :  std_logic := '1' ;
    Tcq      :  Time := 1 ns );
  port(
    Din       : buffer std_logic_vector(7 downto 0);
    ack_in    : out    std_logic; -- cmr_reg(3)  0 = send ACK, 1 = send NACK
    arst_i    : in     std_logic;
    clk_cnt   : out    unsigned(15 downto 0);
    done      : in     std_logic; -- command completed, clear command register
    ena       : out    std_logic;
    i2c_busy  : in     std_logic; -- bus busy (start signal detected)
    irxack    : in     std_logic; -- received aknowledge from slave
    read      : out    std_logic;
    rxr       : in     std_logic_vector(7 downto 0); -- receive register
    start     : out    std_logic;
    stop      : out    std_logic;
    wb_ack_o  : out    std_logic;
    wb_adr_i  : in     unsigned(2 downto 0);
    wb_clk_i  : in     std_logic := '0'; -- Clock
    wb_cyc_i  : in     std_logic;
    wb_dat_i  : in     std_logic_vector(7 downto 0);
    wb_dat_o  : out    std_logic_vector(7 downto 0);
    wb_inta_o : out    std_logic;
    wb_rst_i  : in     std_logic := '0'; -- not used in EPLD
    wb_stb_i  : in     std_logic;
    wb_we_i   : in     std_logic;
    write     : out    std_logic);
end entity i2c_master_top ;

--------------------------------------------------------------------------------
-- Architecture 'a0' of 'i2c_master_top'
-- Last modified : Tue Aug 02 14:56:53 2005.
--------------------------------------------------------------------------------

architecture a0 of i2c_master_top is
-- Internal I2C-Master registers
	signal prer  	: unsigned(15 downto 0);		 		-- clock prescale register
	signal ctr   	: std_logic_vector(7 downto 0); 		-- control register
	signal txr   	: std_logic_vector(7 downto 0);			-- transmit register
	signal cr    	: std_logic_vector(7 downto 0); 		-- command register
	signal sr    	: std_logic_vector(7 downto 0);			-- status register
	signal rst_i 	: std_logic;							-- internal reset signal
	signal core_en 	: std_logic;							-- core enable signal
	signal ien 		: std_logic;

	signal sta, sto, rd, wr, ack, iack : std_logic;			-- command register signals

-- status register signals
	signal rxack 	: std_logic;							-- received aknowledge from slave
	signal tip 		: std_logic;         					-- Transfer In Progress read or write
	signal irq_flag : std_logic;			     			-- interrupt pending flag


begin
	rst_i 		<= arst_i xor ARST_LVL;						-- generate internal reset signal
	wb_ack_o 	<= wb_cyc_i and wb_stb_i;	  				-- because timing is always honored

assign_dato : process(wb_adr_i, prer, ctr, txr, cr, rxr, sr)-- assign wb_dat_o
	begin
		case wb_adr_i is
--  Read i2c internal registers
			when "000" =>	wb_dat_o <= std_logic_vector(prer( 7 downto 0));
			when "001" =>	wb_dat_o <= std_logic_vector(prer(15 downto 8));
			when "010" =>	wb_dat_o <= ctr;
			when "011" =>	wb_dat_o <= rxr;   				-- read is rxr, write is transmit register TxR
			when "100" =>	wb_dat_o <= sr;    				-- read is sr , write is command  register CR
-- Debugging registers:
-- These registers are not documented.
-- Functionality could change in future releases
			when "101" =>	wb_dat_o <= txr;
			when "110" =>	wb_dat_o <= cr;
			when "111" =>	wb_dat_o <= (others => '0');
			when others =>	wb_dat_o <= (others => 'X');	-- for simulation only
		end case;
end process assign_dato;


-- registers block
regs_block: process(rst_i, wb_clk_i)
	begin
		if (rst_i = '0') then
			prer <= (others => '0') after Tcq;
			ctr  <= (others => '0') after Tcq;
			txr  <= (others => '0') after Tcq;
			cr   <= (others => '0') after Tcq;
		elsif rising_edge(wb_clk_i) then
				if (wb_cyc_i = '1' and wb_stb_i = '1' and wb_we_i = '1') then
					if (wb_adr_i(2) = '0') then
						case wb_adr_i(1 downto 0) is
							when "00" => prer( 7 downto 0) <= unsigned(wb_dat_i) after Tcq;
							when "01" => prer(15 downto 8) <= unsigned(wb_dat_i) after Tcq;
							when "10" => ctr               <= wb_dat_i after Tcq;
							when "11" => txr               <= wb_dat_i after Tcq;
							when others => 											-- illegal cases, for simulation only
								report ("Illegal write address, setting all registers to unknown.");
								prer <= (others => 'X');
								ctr  <= (others => 'X');
								txr  <= (others => 'X');
						end case;
					elsif ( (core_en = '1') and (wb_adr_i(1 downto 0) = 0) ) then 	-- only take new commands when i2c core enabled
						cr <= wb_dat_i after Tcq;								  	-- pending commands are finished
					end if;
				else
					if (done = '1') then
						cr(7 downto 4) <= (others => '0') after Tcq;				-- clear command bits when done
					end if;
					cr(2 downto 1) <= (others => '0') after Tcq;					-- reserved bits
					cr(0) <= cr(0) and irq_flag;									-- clear iack when irq_flag cleared
				end if;

		end if;
end process regs_block;

	-- decode command register
	sta  <= cr(7);
	sto  <= cr(6);
	rd   <= cr(5);
	wr   <= cr(4);
	ack  <= cr(3);
	iack <= cr(0);

	-- decode control register
	core_en <= ctr(7);
	ien     <= ctr(6);


st_irq_block : block		-- status register block + interrupt request signal
	begin
		-- generate status register bits
	gen_sr_bits: process (wb_clk_i, rst_i)
		begin
			if (rst_i = '0') then
				rxack    <= '0' after Tcq;
				tip      <= '0' after Tcq;
				irq_flag <= '0' after Tcq;
			elsif rising_edge(wb_clk_i) then
					rxack    <= irxack after Tcq;
					tip      <= (rd or wr) after Tcq;
 					irq_flag <= (done or irq_flag) and not iack after Tcq; -- interrupt request flag is always generated
			end if;
	end process gen_sr_bits;

		-- generate interrupt request signals
	gen_irq: process (wb_clk_i, rst_i)
		begin
			if (rst_i = '0') then
					wb_inta_o <= '0' after Tcq;
			elsif rising_edge(wb_clk_i) then
					wb_inta_o <= irq_flag and ien after Tcq;	-- interrupt signal is only generated when IEN (interrupt enable bit) is set
			end if;
	end process gen_irq;

		-- assign status register bits
		sr(7)          <= rxack;
		sr(6)          <= i2c_busy;
		sr(5 downto 2) <= (others => '0'); -- reserved
		sr(1)          <= tip;
		sr(0)          <= irq_flag;
end block;


connect_io: process(core_en,prer,sta,sto,rd,wr,ack,i2c_busy,txr,done,irxack,rxr)
begin
		ena 	<= core_en ;
		clk_cnt	<= prer ;
		start	<= sta ;
		stop  	<= sto ;
		read	<= rd ;
		write	<= wr ;
		ack_in	<= ack ;
		din 	<= txr ;
end process connect_io;


end architecture a0 ; -- of i2c_master_top
--------------------------------------------------------------------------------
-- Entity declaration of 'i2c_master_byte_ctrl'.
-- Last modified : Tue Aug 02 14:56:53 2005.
--------------------------------------------------------------------------------


library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;

entity i2c_master_byte_ctrl is
  generic(
    Tcq :  Time := 1 ns );
  port(
    ack_in   : in     std_logic;
    ack_out  : out    std_logic;
    clk      : in     std_logic; -- Clock
    cmd_ack  : out    std_logic;
    core_ack : in     std_logic;
    core_cmd : out    std_logic_vector(3 downto 0);
    core_rxd : in     std_logic;
    core_txd : out    std_logic;
    din      : in     std_logic_vector(7 downto 0);
    dout     : out    std_logic_vector(7 downto 0);
    read     : in     std_logic;
    rst      : in     std_logic;
    start    : in     std_logic;
    stop     : in     std_logic;
    write    : in     std_logic);
end entity i2c_master_byte_ctrl ;

--------------------------------------------------------------------------------
-- Architecture 'a0' of 'i2c_master_byte_ctrl'
-- Last modified : Tue Aug 02 14:56:53 2005.
--------------------------------------------------------------------------------
-- Change History:
--               Revision 1.0  2002-01-15   rdeleeuw
--               Initial revision
--               Revision 1.1  2001/11/05
--               Code updated, is now up-to-date to doc. rev.0.4.
--
------------------------------------------
-- Byte controller section
------------------------------------------
--

architecture a0 of i2c_master_byte_ctrl is
	-- commands for bit_controller block
	constant I2C_CMD_NOP  		: std_logic_vector(3 downto 0) := "0000";
	constant I2C_CMD_START		: std_logic_vector(3 downto 0) := "0001";
	constant I2C_CMD_STOP	 	: std_logic_vector(3 downto 0) := "0010";
	constant I2C_CMD_READ	 	: std_logic_vector(3 downto 0) := "0100";
	constant I2C_CMD_WRITE		: std_logic_vector(3 downto 0) := "1000";

	-- signals for shift register
	signal sr 					: std_logic_vector(7 downto 0); -- 8bit shift register
	signal shift, ld 			: std_logic;

	-- signals for state machine
	signal go, host_ack 		: std_logic;
	signal dcnt 				: unsigned(2 downto 0); 		-- data counter
	signal cnt_done 			: std_logic;

begin
	cmd_ack <= host_ack;										-- generate host-command-acknowledge
	go 		<= (read or write or stop) and not host_ack;		-- generate go-signal
	dout 	<= sr;												-- assign Dout output to shift-register

	-- generate shift register
	shift_register: process(clk, Rst)
	begin
		if (Rst = '1') then				sr <= (others => '0') 			  after Tcq;
		elsif rising_Edge(clk)  then
			if (ld = '1')       then	sr <= din 						  after Tcq; -- din = transmit register value
			elsif (shift = '1') then	sr <= (sr(6 downto 0) & core_rxd) after Tcq;
			end if;
		end if;
	end process shift_register;

	-- generate data-counter
	data_cnt: process(clk, Rst)
	begin
		if (Rst = '1')   then			dcnt <= (others => '0') after Tcq;
		elsif rising_Edge(clk) then
		   	if (ld = '1') then			dcnt <= (others => '1') after Tcq; 					-- load counter with 7
			elsif (shift = '1') then	dcnt <= dcnt - 1 		after Tcq;
			end if;
		end if;
	end process data_cnt;

	cnt_done <= '1' when (dcnt = 0) else '0';

	--
	-- state machine
	--
	statemachine : block
		type states is (st_idle, st_start, st_read, st_write, st_ack, st_stop);
		signal cmd_state : states;
	begin
		--
		-- command interpreter, translate complex commands into simpler I2C commands
		--
		nxt_state_decoder: process(clk, Rst)
		begin
			if (Rst = '1')   then
				core_cmd <= I2C_CMD_NOP 	after Tcq;
				core_txd <= '0' 			after Tcq;
				shift    <= '0' 			after Tcq;
				ld       <= '0' 			after Tcq;
				host_ack <= '0' 			after Tcq;
				cmd_state  <= st_idle 		after Tcq;
				ack_out  <= '0' 			after Tcq;
			elsif rising_Edge(clk) then
					-- initialy reset all signal
					core_txd <= sr(7) 		after Tcq;
					shift    <= '0'   		after Tcq;
					ld       <= '0'   		after Tcq;
					host_ack <= '0'   		after Tcq;

					case cmd_state is
						when st_idle =>
							if (go = '1') then
								if (start = '1') then
									cmd_state  <= st_start after Tcq;
									core_cmd <= I2C_CMD_START after Tcq;
								elsif (read = '1') then
									cmd_state  <= st_read after Tcq;
									core_cmd <= I2C_CMD_READ after Tcq;
								elsif (write = '1') then
									cmd_state  <= st_write after Tcq;
									core_cmd <= I2C_CMD_WRITE after Tcq;
								else -- stop
									cmd_state  <= st_stop after Tcq;
									core_cmd <= I2C_CMD_STOP after Tcq;
									host_ack <= '1' after Tcq; -- generate host acknowledge signal
								end if;
								ld <= '1' after Tcq;
							end if;

						when st_start =>
							if (core_ack = '1') then
								if (read = '1') then
									cmd_state  <= st_read after Tcq;
									core_cmd <= I2C_CMD_READ after Tcq;
								else
									cmd_state  <= st_write after Tcq;
									core_cmd <= I2C_CMD_WRITE after Tcq;
								end if;
								ld <= '1' after Tcq;
							end if;

						when st_write =>
							if (core_ack = '1') then
								if (cnt_done = '1') then
									cmd_state  <= st_ack after Tcq;
									core_cmd <= I2C_CMD_READ after Tcq;
								else
									cmd_state  <= st_write after Tcq;       -- stay in same state
									core_cmd <= I2C_CMD_WRITE after Tcq;  -- write next bit
									shift    <= '1' after Tcq;
								end if;
							end if;

						when st_read =>
							if (core_ack = '1') then
								if (cnt_done = '1') then
									cmd_state  <= st_ack after Tcq;
									core_cmd <= I2C_CMD_WRITE after Tcq;
								else
									cmd_state  <= st_read after Tcq;      -- stay in same state
									core_cmd <= I2C_CMD_READ after Tcq; -- read next bit
								end if;
									shift    <= '1' after Tcq;
									core_txd <= ack_in after Tcq;
							end if;

						when st_ack =>
							if (core_ack = '1') then 					-- check for stop; Should a STOP command be generated ?
								if (stop = '1') then
									cmd_state  <= st_stop after Tcq;
									core_cmd <= I2C_CMD_STOP after Tcq;
								else
									cmd_state  <= st_idle after Tcq;
									core_cmd <= I2C_CMD_NOP after Tcq;
								end if;

								ack_out  <= core_rxd after Tcq;			-- assign ack_out output to core_rxd (contains last received bit)
								host_ack <= '1' after Tcq;				-- generate command acknowledge signal
								core_txd <= '1' after Tcq;
							else
								core_txd <= ack_in after Tcq;
							end if;

						when st_stop =>
							if (core_ack = '1') then
								cmd_state  <= st_idle after Tcq;
								core_cmd <= I2C_CMD_NOP after Tcq;
							end if;

						when others => -- illegal states
							cmd_state  <= st_idle after Tcq;
							core_cmd <= I2C_CMD_NOP after Tcq;
							report ("Byte controller entered illegal state.");

					end case;

			end if;
		end process nxt_state_decoder;

	end block statemachine;

end architecture a0 ; -- of i2c_master_byte_ctrl
--------------------------------------------------------------------------------
-- Entity declaration of 'i2c_master_bit_ctrl'.
-- Last modified : Tue Aug 02 14:56:53 2005.
--------------------------------------------------------------------------------


library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;

entity i2c_master_bit_ctrl is
  generic(
    Tcq :  Time := 0 ns );
  port(
    bus_free : out    std_logic;
    busy     : out    std_logic;
    clk      : in     std_logic;
    clk_cnt  : in     unsigned(15 downto 0);
    cmd      : in     std_logic_vector(3 downto 0);
    cmd_ack  : out    std_logic;
    din      : in     std_logic;
    dout     : out    std_logic;
    ena      : in     std_logic;
    rst      : in     std_logic;
    scl      : inout    std_logic;
    scl2     : inout    std_logic;
    scl_i    : in     std_logic := '1';
    sda      : inout    std_logic;
    sda2     : inout    std_logic;
    sda2_i   : in     std_logic := '1';
    sda_i    : in     std_logic := '1');
end entity i2c_master_bit_ctrl ;

--------------------------------------------------------------------------------
-- Architecture 'a0' of 'i2c_master_bit_ctrl'
-- Last modified : Tue Aug 02 14:56:53 2005.
--------------------------------------------------------------------------------
-- Change History:
--               Revision 1.0  2002-01-15   rdeleeuw
--               Initial revision
--               Code updated, is now up-to-date to doc. rev.0.4.
--
-------------------------------------
-- Bit controller section
------------------------------------
--
-- Translate simple commands into SCL/SDA transitions
-- Each command has 5 states, A/B/C/D/idle
--
-- start:	SCL	~~~~~~~~~~\____
--	SDA	~~~~~~~~\______
--		 x | A | B | C | D | i
--
-- repstart	SCL	____/~~~~\___
--	SDA	__/~~~\______
--		 x | A | B | C | D | i
--
-- stop	SCL	____/~~~~~~~~
--	SDA	==\____/~~~~~
--		 x | A | B | C | D | i
--
--- write	SCL	____/~~~~\____
--	SDA	==X=========X=
--		 x | A | B | C | D | i
--
--- read	SCL	____/~~~~\____
--	SDA	XXXX=====XXXX
--		 x | A | B | C | D | i
--

-- Timing:		Normal mode	Fast mode
-----------------------------------------------------------------
-- Fscl		100KHz		400KHz
-- Th_scl		4.0us		0.6us	High period of SCL
-- Tl_scl		4.7us		1.3us	Low period of SCL
-- Tsu:sta		4.7us		0.6us	setup time for a repeated start condition
-- Tsu:sto		4.0us		0.6us	setup time for a stop conditon
-- Tbuf	  		4.7us		1.3us	Bus free time between a stop and start condition
--

architecture a0 of i2c_master_bit_ctrl is
	type states is (idle, start_a, start_b, start_c, start_d, stop_a, stop_b, stop_c, rd_a, rd_b, rd_c, rd_d, wr_a, wr_b, wr_c, wr_d);

	constant I2C_CMD_NOP  		: std_logic_vector(3 downto 0) := "0000";
	constant I2C_CMD_START		: std_logic_vector(3 downto 0) := "0001";
	constant I2C_CMD_STOP		: std_logic_vector(3 downto 0) := "0010";
	constant I2C_CMD_READ		: std_logic_vector(3 downto 0) := "0100";
	constant I2C_CMD_WRITE		: std_logic_vector(3 downto 0) := "1000";

	signal c_state 				: states;
	signal iscl_oen, isda_oen 	: std_logic := '0' ;   	   					-- internal I2C lines
	signal sSCL, sSDA 			: std_logic := '0' ;       					-- synchronized SCL and SDA inputs
	signal clk_en, slave_wait 	: std_logic;								-- clock generation signals
	signal cnt 					: unsigned(15 downto 0) ;					-- clock divider counter (simulation)


	-- generate bus status controller
	signal dSDA 				: std_logic;
	signal sta_condition 		: std_logic;
	signal sto_condition 		: std_logic;
	signal ibusy 				: std_logic := '0' ;



begin
	-- synchronize SCL and SDA inputs
--		sSCL <= '1' WHEN SCL_I = '1' ELSE '0' ;
--		-- assign output
		busy <= ibusy;

synch_scl_sda: process(clk)
	begin
		if rising_Edge(clk) then
			if sda = '0' or sda2 = '0' then  sSDA <= '0' after Tcq ; else sSDA <= '1' after Tcq ; end if ;
			if scl = '0' then  sSCL <= '0' after Tcq ; else sSCL <= '1' after Tcq ; end if ;
		end if;
	end process synch_SCL_SDA;

	-- whenever the slave is not ready it can delay the cycle by pulling SCL low
	slave_wait <= iscl_oen and not sSCL;

	-- generate clk enable signal
	gen_clken: process(clk, Rst)
	begin
		if (Rst = '1') then
			cnt    <= (others => '0') after Tcq;
			clk_en <= '1' after Tcq;
		elsif rising_Edge(clk) then
				if ( (cnt = 0) or (ena = '0') ) then
					clk_en <= '1' after Tcq;
					cnt    <= clk_cnt after Tcq;
				else
					if (slave_wait = '0') then					-- check for clock stretching
						cnt <= cnt -1 after Tcq;
					end if;
					clk_en <= '0' after Tcq;
				end if;

		end if;
	end process gen_clken;



	-- detect start condition => detect falling edge on SDA while SCL is high
	-- detect stop condition  => detect rising edge on SDA while SCL is high
	detect_sta_sto: process(clk)
		begin
			if rising_Edge(clk) then
				dSDA <= sSDA;										-- generate a delayed version of sSDA
				sta_condition <= (not sSDA and dSDA) and sSCL;
				sto_condition <= (sSDA and not dSDA) and sSCL;
			end if;
	end process detect_sta_sto;

		-- generate bus busy signal
	gen_busy: process(clk, Rst)
		begin
			if (Rst = '1') then
				ibusy <= '0' after Tcq;
			elsif rising_Edge(clk) then
					ibusy <= (sta_condition or ibusy) and not sto_condition after Tcq;
			end if;
	end process gen_busy;


	-- generate statemachine
	nxt_state_decoder : process (clk, Rst, c_state, cmd)
		variable nxt_state : states;
		variable icmd_ack, store_sda : std_logic;
	begin

		nxt_state := c_state;

		icmd_ack := '0'; -- default no acknowledge

		store_sda := '0';

		case (c_state) is
			-- idle
			when idle =>
				case cmd is
					when I2C_CMD_START =>
						nxt_state := start_a;

					when I2C_CMD_STOP =>
						nxt_state := stop_a;

					when I2C_CMD_WRITE =>
						nxt_state := wr_a;

					when I2C_CMD_READ =>
						nxt_state := rd_a;

					when others =>  -- NOP command
						nxt_state := idle;
				end case;

			-- start
			when start_a =>
				nxt_state := start_b;

			when start_b =>
				nxt_state := start_c;

			when start_c =>
				nxt_state := start_d;

			when start_d =>
				nxt_state := idle;
				icmd_ack := '1'; -- command completed

			-- stop
			when stop_a =>
				nxt_state := stop_b;

			when stop_b =>
				nxt_state := stop_c;

			when stop_c =>
				nxt_state := idle;
				icmd_ack := '1'; -- command completed

			-- read
			when rd_a =>
				nxt_state := rd_b;

			when rd_b =>
				nxt_state := rd_c;

			when rd_c =>
				nxt_state := rd_d;
				store_sda := '1';

			when rd_d =>
				nxt_state := idle;
				icmd_ack := '1'; -- command completed

			-- write
			when wr_a =>
				nxt_state := wr_b;

			when wr_b =>
				nxt_state := wr_c;

			when wr_c =>
				nxt_state := wr_d;

			when wr_d =>
				nxt_state := idle;
				icmd_ack := '1'; -- command completed

		end case;

		-- generate regs
		if (Rst = '1') then
			c_state <= idle after Tcq;
			cmd_ack <= '0' after Tcq;
			Dout    <= '0' after Tcq;
		elsif rising_Edge(clk) then
				if (clk_en = '1') then
					c_state <= nxt_state after Tcq;

					if (store_sda = '1') then
						dout <= sSDA after Tcq;
					end if;
				end if;
				cmd_ack <= icmd_ack and clk_en;
		end if;
	end process nxt_state_decoder;

	--
	-- convert states to SCL and SDA signals
	--
	output_decoder: process (clk, Rst, c_state, iscl_oen, isda_oen, din)
		variable iscl, isda : std_logic;
	begin
		case (c_state) is
			when idle =>
				iscl := iscl_oen; -- keep SCL in same state
				isda := isda_oen; -- keep SDA in same state

			-- start
			when start_a =>
				iscl := iscl_oen; -- keep SCL in same state (for repeated start)
				isda := '1';      -- set SDA high

			when start_b =>
				iscl := '1';	-- set SCL high
				isda := '1'; -- keep SDA high

			when start_c =>
				iscl := '1';	-- keep SCL high
				isda := '0'; -- sel SDA low

			when start_d =>
				iscl := '0'; -- set SCL low
				isda := '0'; -- keep SDA low

			-- stop
			when stop_a =>
				iscl := '0'; -- keep SCL disabled
				isda := '0'; -- set SDA low

			when stop_b =>
				iscl := '1'; -- set SCL high
				isda := '0'; -- keep SDA low

			when stop_c =>
				iscl := '1'; -- keep SCL high
				isda := '1'; -- set SDA high

			-- write
			when wr_a =>
				iscl := '0';	-- keep SCL low
				isda := din; -- set SDA

			when wr_b =>
				iscl := '1';	-- set SCL high
				isda := din; -- keep SDA

			when wr_c =>
				iscl := '1';	-- keep SCL high
				isda := din; -- keep SDA

			when wr_d =>
				iscl := '0'; -- set SCL low
				isda := din; -- keep SDA

			-- read
			when rd_a =>
				iscl := '0'; -- keep SCL low
				isda := '1'; -- tri-state SDA

			when rd_b =>
				iscl := '1'; -- set SCL high
				isda := '1'; -- tri-state SDA

			when rd_c =>
				iscl := '1'; -- keep SCL high
				isda := '1'; -- tri-state SDA

			when rd_d =>
				iscl := '0'; -- set SCL low
				isda := '1'; -- tri-state SDA
		end case;

		-- generate registers
		if (Rst = '1') then
			iscl_oen <= '1' after Tcq;
			isda_oen <= '1' after Tcq;
		elsif rising_Edge(clk) then
				if (clk_en = '1') then
					iscl_oen <= iscl after Tcq;
					isda_oen <= isda after Tcq;
				end if;
		end if;
	end process output_decoder;

	SCL	<= '0' when (iscl_oen = '0') else 'Z' ;
--	SCL	<= '0' when (iscl_oen = '0') else '1' ; -- test 23 juni 2003
	SDA	<= '0' when (isda_oen = '0') else 'Z' ;

    bus_free <= '1' when (iscl_oen = '1' and isda_oen = '1') else '0' ;

	SCL2	<= '0' when (iscl_oen = '0') else 'Z' ;
--	SCL2	<= '0' when (iscl_oen = '0') else '1' ;-- test 23 juni 2003
	SDA2	<= '0' when (isda_oen = '0') else 'Z' ;

--	SCL	<= '0' when (iscl_oen = '0') else '1' ;
--	SDA	<= '0' when (isda_oen = '0') else 'Z' ;

end architecture a0 ; -- of i2c_master_bit_ctrl

	-- assign outputs
--	scl_o   <= '0';
--	scl_oen <= iscl_oen;
--	sda_o   <= '0';
--	sda_oen <= isda_oen;


-- for simulation only
--	SCL	<= scl_o when (scl_oen = '0') else '1' ;
--	SDA	<= sda_o when (sda_oen = '0') else '1' ;
--------------------------------------------------------------------------------
-- Entity declaration of 'top_i2c'.
-- Last modified : Wed Aug 10 10:41:33 2005.
--------------------------------------------------------------------------------
-- History info :
-- V1.00  initial version tested in testbench
--


library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;

entity top_i2c is
  port(
    Mp_test   : out    std_logic;
    arst_i    : in     std_logic := '0';
    bus_free  : out    std_logic;
    clk       : in     std_logic := '0';
    rst       : in     std_logic := '0';
    scl2_pin  : inout  std_logic;
    scl_pin   : inout  std_logic := '1';
    sda2_pin  : inout  std_logic;
    sda_pin   : inout  std_logic;
    wb_ack_o  : out    std_logic;
    wb_adr_i  : in     unsigned(2 downto 0);
    wb_clk_i  : in     std_logic := '0';
    wb_cyc_i  : in     std_logic;
    wb_dat_i  : in     std_logic_vector(7 downto 0) := "00000000";
    wb_dat_o  : out    std_logic_vector(7 downto 0);
    wb_inta_o : out    std_logic;
    wb_rst_i  : in     std_logic := '0';
    wb_stb_i  : in     std_logic;
    wb_we_i   : in     std_logic);
end entity top_i2c ;

--------------------------------------------------------------------------------
-- Architecture 'a0' of 'top_i2c'
-- Last modified : Wed Aug 10 10:41:33 2005.
--------------------------------------------------------------------------------

architecture a0 of top_i2c is

  component i2c_master_top
    generic(
      ARST_LVL :  std_logic := '1';
      Tcq      :  Time := 1 ns);
    port(
      Din       : buffer std_logic_vector(7 downto 0);
      ack_in    : out    std_logic; -- cmr_reg(3)  0 = send ACK, 1 = send NACK
      arst_i    : in     std_logic;
      clk_cnt   : out    unsigned(15 downto 0);
      done      : in     std_logic; -- command completed, clear command register
      ena       : out    std_logic;
      i2c_busy  : in     std_logic; -- bus busy (start signal detected)
      irxack    : in     std_logic; -- received aknowledge from slave
      read      : out    std_logic;
      rxr       : in     std_logic_vector(7 downto 0); -- receive register
      start     : out    std_logic;
      stop      : out    std_logic;
      wb_ack_o  : out    std_logic;
      wb_adr_i  : in     unsigned(2 downto 0);
      wb_clk_i  : in     std_logic := '0'; -- Clock
      wb_cyc_i  : in     std_logic;
      wb_dat_i  : in     std_logic_vector(7 downto 0);
      wb_dat_o  : out    std_logic_vector(7 downto 0);
      wb_inta_o : out    std_logic;
      wb_rst_i  : in     std_logic := '0'; -- not used in EPLD
      wb_stb_i  : in     std_logic;
      wb_we_i   : in     std_logic;
      write     : out    std_logic);
  end component i2c_master_top ;

  component i2c_master_byte_ctrl
    generic(
      Tcq :  Time := 1 ns);
    port(
      ack_in   : in     std_logic;
      ack_out  : out    std_logic;
      clk      : in     std_logic; -- Clock
      cmd_ack  : out    std_logic;
      core_ack : in     std_logic;
      core_cmd : out    std_logic_vector(3 downto 0);
      core_rxd : in     std_logic;
      core_txd : out    std_logic;
      din      : in     std_logic_vector(7 downto 0);
      dout     : out    std_logic_vector(7 downto 0);
      read     : in     std_logic;
      rst      : in     std_logic;
      start    : in     std_logic;
      stop     : in     std_logic;
      write    : in     std_logic);
  end component i2c_master_byte_ctrl ;

  component i2c_master_bit_ctrl
    generic(
      Tcq :  Time := 0 ns);
    port(
      bus_free : out    std_logic;
      busy     : out    std_logic;
      clk      : in     std_logic;
      clk_cnt  : in     unsigned(15 downto 0);
      cmd      : in     std_logic_vector(3 downto 0);
      cmd_ack  : out    std_logic;
      din      : in     std_logic;
      dout     : out    std_logic;
      ena      : in     std_logic;
      rst      : in     std_logic;
      scl      : inout    std_logic;
      scl2     : inout    std_logic;
      scl_i    : in     std_logic := '1';
      sda      : inout    std_logic;
      sda2     : inout    std_logic;
      sda2_i   : in     std_logic := '1';
      sda_i    : in     std_logic := '1');
  end component i2c_master_bit_ctrl ;

  signal ena       :  std_logic;
  signal clk_cnt   :  unsigned(15 downto 0);
  signal start     :  std_logic;
  signal stop      :  std_logic;
  signal read      :  std_logic;
  signal send_ACK  :  std_logic;
  signal txr_value :  std_logic_vector(7 downto 0);
  signal rxr       :  std_logic_vector(7 downto 0);
  signal write     :  std_logic;
  signal i2c_busy  :  std_logic;
  signal done      :  std_logic;
  signal irxack    :  std_logic;
  signal core_ack  :  std_logic;
  signal core_cmd  :  std_logic_vector(3 downto 0);
  signal core_txd  :  std_logic;
  signal core_rxd  :  std_logic;

begin
  --standard wishbone interface
  --54 cells
  --66 cells

  Mp_test <= i2c_busy;

  u0: i2c_master_top
    generic map(
      ARST_LVL => '1',
      Tcq => 1 ns)

    port map(
      Din => txr_value,
      ack_in => send_ACK,
      arst_i => arst_i,
      clk_cnt => clk_cnt,
      done => done,
      ena => ena,
      i2c_busy => i2c_busy,
      irxack => irxack,
      read => read,
      rxr => rxr,
      start => start,
      stop => stop,
      wb_ack_o => wb_ack_o,
      wb_adr_i => wb_adr_i,
      wb_clk_i => wb_clk_i,
      wb_cyc_i => wb_cyc_i,
      wb_dat_i => wb_dat_i,
      wb_dat_o => wb_dat_o,
      wb_inta_o => wb_inta_o,
      wb_rst_i => open,
      wb_stb_i => wb_stb_i,
      wb_we_i => wb_we_i,
      write => write);

  u1: i2c_master_byte_ctrl
    generic map(
      Tcq => 1 ns)

    port map(
      ack_in => send_ACK,
      ack_out => irxack,
      clk => clk,
      cmd_ack => done,
      core_ack => core_ack,
      core_cmd => core_cmd,
      core_rxd => core_rxd,
      core_txd => core_txd,
      din => txr_value,
      dout => rxr,
      read => read,
      rst => rst,
      start => start,
      stop => stop,
      write => write);

  u2: i2c_master_bit_ctrl
    generic map(
      Tcq => 0 ns)

    port map(
      bus_free => bus_free,
      busy => i2c_busy,
      clk => clk,
      clk_cnt => clk_cnt,
      cmd => core_cmd,
      cmd_ack => core_ack,
      din => core_txd,
      dout => core_rxd,
      ena => ena,
      rst => rst,
      scl => scl_pin,
      scl2 => scl2_pin,
      scl_i => '0',
      sda => sda_pin,
      sda2 => sda2_pin,
      sda2_i => '0',
      sda_i => '0');
end architecture a0 ; -- of top_i2c

