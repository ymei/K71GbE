-------------------------------------------------------------------------------------
-- FILE NAME : ltc2175_triple_phy.vhd
--
-- AUTHOR    : Peter Kortekaas
--
-- COMPANY   : 4DSP
--
-- ITEM      : 1
--
-- UNITS     : Entity       - ltc2175_triple_phy
--             architecture - ltc2175_triple_phy_syn
--
-- LANGUAGE  : VHDL
--
-------------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------------
-- DESCRIPTION
-- ===========
--
-- ltc2175_triple_phy
-- Notes: ltc2175_triple_phy
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

-- Library declarations
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_misc.all;
  use ieee.numeric_std.all;
library unisim;
  use unisim.vcomponents.all;

entity ltc2175_phy is
  generic
  (
    START_ADDR   : std_logic_vector(27 downto 0) := x"0000000";
    STOP_ADDR    : std_logic_vector(27 downto 0) := x"00000FF";
    DMUX_MODE    : integer := 1 -- either 1 for 1:1 mode or 2 for 1:2 mode
  );
  port (
    -- Global signals
    rst          : in  std_logic;

    -- Command Interface
    clk_cmd      : in  std_logic;
    in_cmd_val   : in  std_logic;
    in_cmd       : in  std_logic_vector(63 downto 0);
    out_cmd_val  : out std_logic;
    out_cmd      : out std_logic_vector(63 downto 0);
    in_cmd_busy  : out std_logic;

    -- DDR LVDS Interface
    dco_p          : in    std_logic_vector(3 downto 0);
    dco_n          : in    std_logic_vector(3 downto 0);
    frame_p        : in    std_logic_vector(3 downto 0);
    frame_n        : in    std_logic_vector(3 downto 0);
    outa_p         : in    std_logic_vector(15 downto 0);
    outa_n         : in    std_logic_vector(15 downto 0);
    outb_p         : in    std_logic_vector(15 downto 0);
    outb_n         : in    std_logic_vector(15 downto 0);

    -- Output port
    ctrl_clk       : out std_logic;
    phy_out_clk    : out std_logic_vector(15 downto 0); -- clock equals sample frequecy's
    phy_out_data0  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data1  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data2  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data3  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data4  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data5  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data6  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data7  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data8  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data9  : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data10 : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
    phy_out_data11 : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
	 phy_out_data12 : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
	 phy_out_data13 : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
	 phy_out_data14 : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
	 phy_out_data15 : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format

    -- Output clocks (for monitoring and test purposes)
    dco            : out std_logic_vector(3 downto 0)

  );
end ltc2175_phy;

architecture ltc2175_phy_syn of ltc2175_phy is

----------------------------------------------------------------------------------------------------
-- Components
----------------------------------------------------------------------------------------------------
component fmc11x_stellar_cmd is
generic
(
  START_ADDR           : std_logic_vector(27 downto 0) := x"0000000";
  STOP_ADDR            : std_logic_vector(27 downto 0) := x"00000FF"
);
port
(
  reset                : in  std_logic;
  -- Command Interface
  clk_cmd              : in  std_logic;                     --cmd_in and cmd_out are synchronous to this clock;
  out_cmd              : out std_logic_vector(63 downto 0);
  out_cmd_val          : out std_logic;
  in_cmd               : in  std_logic_vector(63 downto 0);
  in_cmd_val           : in  std_logic;
  -- Register interface
  clk_reg              : in  std_logic;                     --register interface is synchronous to this clock
  out_reg              : out std_logic_vector(31 downto 0); --caries the out register data
  out_reg_val          : out std_logic;                     --the out_reg has valid data  (pulse)
  out_reg_addr         : out std_logic_vector(27 downto 0); --out register address
  in_reg               : in  std_logic_vector(31 downto 0); --requested register data is placed on this bus
  in_reg_val           : in  std_logic;                     --pulse to indicate requested register is valid
  in_reg_req           : out std_logic;                     --pulse to request data
  in_reg_addr          : out std_logic_vector(27 downto 0);  --requested address
  --mailbox interface
  mbx_in_reg           : in  std_logic_vector(31 downto 0); --value of the mailbox to send
  mbx_in_val           : in  std_logic                      --pulse to indicate mailbox is valid
);
end component fmc11x_stellar_cmd;

component fmc11x_dco_buf is
port (
  clk_reset : in   std_logic;
  dco_p     : in   std_logic;
  dco_n     : in   std_logic;
  clk_buf   : out  std_logic; -- fast clock
  clk_inv   : out  std_logic; -- fast clock inverted
  clk_div   : out  std_logic;  -- slow clock (/4)
  clk_div_g : out  std_logic  -- slow clock (/4)
);
end component fmc11x_dco_buf;

component serdes_clock_map is

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
end component serdes_clock_map;

component serdes is
generic (
  SYS_W                 : integer := 10; -- width of the data for the system
  DEV_W                 : integer := 80  -- width of the data for the device
);
port (
  -- From the system into the device
  data_in_from_pins_p   : in    std_logic_vector(SYS_W-1 downto 0);
  data_in_from_pins_n   : in    std_logic_vector(SYS_W-1 downto 0);
  data_in_to_device     : out   std_logic_vector(DEV_W-1 downto 0);
  -- Input, Output delay control signals
  rst_cmd               : in    std_logic;
  clk_cmd               : in    std_logic;
  start_align           : in    std_logic;                            -- start automatic alignment, test pattern should be tuned on
  data_aligned_out      : out   std_logic_vector(SYS_W-1 downto 0);   -- automatic alignment ready flags
  data_aligned          : out   std_logic;                            -- automatic alignment ready flag (and function)
  delay_reset           : in    std_logic;                            -- active high synchronous reset for input delay
  delay_valid_inc       : in    std_logic;                            --
  delay_data_inc        : in    std_logic_vector(SYS_W-1 downto 0);   -- delay increment
  delay_valid_dec       : in    std_logic;                            --
  delay_data_dec        : in    std_logic_vector(SYS_W-1 downto 0);   -- delay decrement
  delay_value           : out   std_logic_vector(5*SYS_W-1 downto 0); -- automatic alignment ready flags
  bitslip_val           : in    std_logic;                            -- bitslip module is enabled in networking mode, user should tie it to '0' if not needed
  bitslip               : in    std_logic_vector(SYS_W-1 downto 0);   -- bitslip module is enabled in networking mode, user should tie it to '0' if not needed
  -- Clock and reset signals
  clk_div               : in    std_logic;                            -- slow clock
  clk_in_int_buf        : in    std_logic;                            -- fast clock
  clk_in_int_inv        : in    std_logic;                            -- fast clock inverted
  io_reset              : in    std_logic                             -- reset signal for io circuit
);
end component serdes;

component pulse2pulse is
port (
  in_clk   : in  std_logic;
  out_clk  : in  std_logic;
  rst      : in  std_logic;
  pulsein  : in  std_logic;
  inbusy   : out std_logic;
  pulseout : out std_logic
);
end component pulse2pulse;

----------------------------------------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------------------------------------
constant ADDR_COMMAND    : std_logic_vector(31 downto 0) := x"00000000";
constant ADDR_CONTROL    : std_logic_vector(31 downto 0) := x"00000001";

constant ADDR_INC_A      : std_logic_vector(31 downto 0) := x"00000002";
constant ADDR_INC_B      : std_logic_vector(31 downto 0) := x"00000003";
constant ADDR_DEC_A      : std_logic_vector(31 downto 0) := x"00000004";
constant ADDR_DEC_B      : std_logic_vector(31 downto 0) := x"00000005";
constant ADDR_BITSLIP_A  : std_logic_vector(31 downto 0) := x"00000006";
constant ADDR_BITSLIP_B  : std_logic_vector(31 downto 0) := x"00000007";

constant ADDR_TAP_VAL0   : std_logic_vector(31 downto 0) := x"00000008";
constant ADDR_TAP_VAL1   : std_logic_vector(31 downto 0) := x"00000009";
constant ADDR_TAP_VAL2   : std_logic_vector(31 downto 0) := x"0000000A";
constant ADDR_TAP_VAL3   : std_logic_vector(31 downto 0) := x"0000000B";
constant ADDR_TAP_VAL4   : std_logic_vector(31 downto 0) := x"0000000C";
constant ADDR_TAP_VAL5   : std_logic_vector(31 downto 0) := x"0000000D";
constant ADDR_TAP_VAL6   : std_logic_vector(31 downto 0) := x"0000000E";
constant ADDR_TAP_VAL7   : std_logic_vector(31 downto 0) := x"0000000F";

constant NBIC            : integer := 3; -- Number of LTC2175 ICs
constant NBCH            : integer := NBIC*4; -- Number of channels (4 per LTC2175 ICs)
constant SYS_W           : integer := (1+4+4); --Per IC: 1x FRAME, 4x OUTA, 4x OUTB

----------------------------------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------------------------------
signal out_reg_val    : std_logic;
signal out_reg_addr   : std_logic_vector(27 downto 0);
signal out_reg        : std_logic_vector(31 downto 0);

signal in_reg_req     : std_logic;
signal in_reg_addr    : std_logic_vector(27 downto 0);
signal in_reg_val     : std_logic;
signal in_reg         : std_logic_vector(31 downto 0);

signal cmd_reg        : std_logic_vector(31 downto 0);

signal delay_reset    : std_logic;
signal clk_reset      : std_logic;
signal io_reset       : std_logic;

signal start_align    : std_logic;
signal data_aligned   : std_logic_vector(NBCH+NBIC-1 downto 0);
--signal data_aligned_out : std_logic_vector(SYS_W-1 downto 0);

type data_aligned_out_array is array (0 to NBCH+NBIC-1) of std_logic_vector(1 downto 0);
signal data_aligned_out     : data_aligned_out_array := (( others => (others => '0')));

signal clk_buf        : std_logic_vector(NBIC-1 downto 0);
signal clk_inv        : std_logic_vector(NBIC-1 downto 0);
signal clk_div        : std_logic_vector(NBIC-1 downto 0);
signal clk_div_g        : std_logic_vector(NBIC-1 downto 0);

signal clk_buf_o_data      : std_logic_vector(NBCH-1 downto 0);
signal clk_inv_o_data      : std_logic_vector(NBCH-1 downto 0);
signal clk_div_o_data      : std_logic_vector(NBCH-1 downto 0);

signal clk_buf_o_frame      : std_logic_vector(NBIC-1 downto 0);
signal clk_inv_o_frame      : std_logic_vector(NBIC-1 downto 0);
signal clk_div_o_frame      : std_logic_vector(NBIC-1 downto 0);


type in_pn_array is array (0 to NBCH-1) of std_logic_vector(1 downto 0);
signal in_p           : in_pn_array := (( others => (others => '0')));
signal in_n           : in_pn_array := (( others => (others => '0')));

type serdes_out_array is array (0 to 15) of std_logic_vector(16-1 downto 0);
signal serdes_out     : serdes_out_array := (( others => (others => '0')));

type data_array is array (0 to NBCH-1) of std_logic_vector(15 downto 0);
signal data           : data_array := (( others => (others => '0')));

signal delay_inc_val  : std_logic;
type delay_inc_array is array (0 to NBCH+NBIC-1) of std_logic_vector(1 downto 0);
signal delay_inc      : delay_inc_array := (( others => (others => '0')));

signal delay_dec_val  : std_logic;
--signal delay_dec      : std_logic_vector(SYS_W-1 downto 0);

type delay_dec_array is array (0 to NBCH+NBIC-1) of std_logic_vector(1 downto 0);
signal delay_dec      : delay_dec_array := (( others => (others => '0')));

signal bitslip_val    : std_logic;

type bitslip_array is array (0 to NBCH+NBIC-1) of std_logic_vector(1 downto 0);
signal bitslip      : bitslip_array := (( others => (others => '0')));
--signal bitslip        : std_logic_vector(SYS_W-1 downto 0);

--signal delay_value    : std_logic_vector(SYS_W*5-1 downto 0);
type delay_value_array is array (0 to 16+NBIC-1) of std_logic_vector(5*2-1 downto 0);
signal delay_value      : delay_value_array := (( others => (others => '0')));

signal pec            : std_logic;
signal pat            : std_logic_vector(15 downto 0);
signal pef            : std_logic_vector(NBCH-1 downto 0);

begin

----------------------------------------------------------------------------------------------------
-- Stellar Command Interface
----------------------------------------------------------------------------------------------------
fmc11x_stellar_cmd_inst : fmc11x_stellar_cmd
generic map
(
  START_ADDR   => START_ADDR,
  STOP_ADDR    => STOP_ADDR
)
port map
(
  reset        => rst,

  clk_cmd      => clk_cmd,
  in_cmd_val   => in_cmd_val,
  in_cmd       => in_cmd,
  out_cmd_val  => out_cmd_val,
  out_cmd      => out_cmd,

  clk_reg      => clk_cmd,
  out_reg_val  => out_reg_val,
  out_reg_addr => out_reg_addr,
  out_reg      => out_reg,

  in_reg_req   => in_reg_req,
  in_reg_addr  => in_reg_addr,
  in_reg_val   => in_reg_val,
  in_reg       => in_reg,

  mbx_in_val   => '0',
  mbx_in_reg   => (others => '0')
);

in_cmd_busy <= '0';

----------------------------------------------------------------------------------------------------
-- Registers
----------------------------------------------------------------------------------------------------
process (rst, clk_cmd)
begin
  if (rst = '1') then

    cmd_reg        <= (others => '0');
    pec            <= '0';
    pat            <= (others => '0');
    delay_inc_val  <= '0';
    delay_inc      <= (( others => (others => '0')));
    delay_dec_val  <= '0';
    delay_dec      <= (( others => (others => '0')));
    bitslip_val    <= '0';
    bitslip        <= (( others => (others => '0')));
    in_reg_val     <= '0';
    in_reg         <= (others=> '0');

  elsif (rising_edge(clk_cmd)) then

    -- Write commands
    if (out_reg_val = '1' and out_reg_addr = ADDR_COMMAND) then
      cmd_reg <= out_reg;
    else
      cmd_reg <= (others => '0');
    end if;

    -- Write controls
    if (out_reg_val = '1' and out_reg_addr = ADDR_CONTROL) then
      pec <= '1';
      pat <= out_reg(pat'length-1 downto 0);
	  else
      pec <= '0';
    end if;

    --Increment register
    if (out_reg_val = '1' and out_reg_addr = ADDR_INC_A) then -- lower 32 bits controls OUTA and OUTB lines

        delay_inc_val <= '1';
        delay_a: for i in 0 to NBCH-1 loop
              delay_inc(i)  <= out_reg(1+(2*i) downto (i*2));
        end loop delay_a;

    elsif (out_reg_val = '1' and out_reg_addr = ADDR_INC_B) then -- upper 4 bits controls FRAME lines

        delay_inc_val <= '1';
        delay_b: for i in NBCH to NBIC+NBCH-1 loop
               delay_inc(i)  <= out_reg(i) & '0';
        end loop delay_b;

    else
      delay_inc_val <= '0';
    end if;

    --Decrement register
    if (out_reg_val = '1' and out_reg_addr = ADDR_DEC_A) then -- lower 32 bits controls OUTA and OUTB lines

      delay_dec_val <= '1';
      delay_c: for i in 0 to NBCH-1 loop
             delay_dec(i)  <= out_reg(1+(2*i) downto (i*2));
      end loop delay_c;

    elsif (out_reg_val = '1' and out_reg_addr = ADDR_DEC_B) then -- upper 4 bits controls FRAME lines

        delay_dec_val <= '1';
        delay_d: for i in NBCH to NBIC+NBCH-1 loop
               delay_dec(i)  <= out_reg(i) & '0';
        end loop delay_d;

    else
      delay_dec_val <= '0';
    end if;

    --Bitslip register
    if (out_reg_val = '1' and out_reg_addr = ADDR_BITSLIP_A) then -- lower 32 bits controls OUTA and OUTB lines
      bitslip_val <= '1';

      delay_dec_val <= '1';
      bitslip_a: for i in 0 to NBCH-1 loop
             bitslip(i)  <= out_reg(1+(2*i) downto (i*2));
      end loop bitslip_a;

    elsif (out_reg_val = '1' and out_reg_addr = ADDR_BITSLIP_B) then -- upper 4 bits controls FRAME lines
      bitslip_val <= '1';

      bitslip_b: for i in NBCH to NBIC+NBCH-1 loop
             bitslip(i)  <= out_reg(i) & '0';
      end loop bitslip_b;

    else
      bitslip_val <= '0';
    end if;

    -- Read
    if (in_reg_req = '1' and in_reg_addr = ADDR_COMMAND) then
      in_reg_val <= '1';
      in_reg(31 downto 16) <= conv_std_logic_vector(0, 16);
      in_reg(15 downto  0) <= conv_std_logic_vector(0, 16-1) & and_reduce(data_aligned);

    elsif (in_reg_req = '1' and in_reg_addr = ADDR_CONTROL) then
      in_reg_val <= '1';
      in_reg     <= conv_std_logic_vector(0, 32-NBCH) & pef;

    elsif (in_reg_req = '1' and in_reg_addr = ADDR_TAP_VAL0) then
      in_reg_val <= '1';
      in_reg( 7 downto  0) <= conv_std_logic_vector(0, 8-5) & delay_value(0)( 4 downto  0);
      in_reg(15 downto  8) <= conv_std_logic_vector(0, 8-5) & delay_value(0)( 4 downto  0);
      in_reg(23 downto 16) <= conv_std_logic_vector(0, 8-5) & delay_value(1)( 9 downto  5);
      in_reg(31 downto 24) <= conv_std_logic_vector(0, 8-5) & delay_value(1)( 9 downto  5);

    elsif (in_reg_req = '1' and in_reg_addr = ADDR_TAP_VAL1) then
      in_reg_val <= '1';
      in_reg( 7 downto  0) <= conv_std_logic_vector(0, 8-5) & delay_value(2)( 4 downto  0);
      in_reg(15 downto  8) <= conv_std_logic_vector(0, 8-5) & delay_value(2)( 4 downto  0);
      in_reg(23 downto 16) <= conv_std_logic_vector(0, 8-5) & delay_value(3)( 9 downto  5);
      in_reg(31 downto 24) <= conv_std_logic_vector(0, 8-5) & delay_value(3)( 9 downto  5);

	  elsif (in_reg_req = '1' and in_reg_addr = ADDR_TAP_VAL2) then
      in_reg_val <= '1';
      in_reg( 7 downto  0) <= conv_std_logic_vector(0, 8-5) & delay_value(4)( 4 downto  0);
      in_reg(15 downto  8) <= conv_std_logic_vector(0, 8-5) & delay_value(4)( 4 downto  0);
      in_reg(23 downto 16) <= conv_std_logic_vector(0, 8-5) & delay_value(5)( 9 downto  5);
      in_reg(31 downto 24) <= conv_std_logic_vector(0, 8-5) & delay_value(5)( 9 downto  5);

	  elsif (in_reg_req = '1' and in_reg_addr = ADDR_TAP_VAL3) then
      in_reg_val <= '1';
      in_reg( 7 downto  0) <= conv_std_logic_vector(0, 8-5) & delay_value(6)( 4 downto  0);
      in_reg(15 downto  8) <= conv_std_logic_vector(0, 8-5) & delay_value(6)( 4 downto  0);
      in_reg(23 downto 16) <= conv_std_logic_vector(0, 8-5) & delay_value(7)( 9 downto  5);
      in_reg(31 downto 24) <= conv_std_logic_vector(0, 8-5) & delay_value(7)( 9 downto  5);

	  elsif (in_reg_req = '1' and in_reg_addr = ADDR_TAP_VAL4) then
      in_reg_val <= '1';
      in_reg( 7 downto  0) <= conv_std_logic_vector(0, 8-5) & delay_value(8)( 4 downto  0);
      in_reg(15 downto  8) <= conv_std_logic_vector(0, 8-5) & delay_value(8)( 4 downto  0);
      in_reg(23 downto 16) <= conv_std_logic_vector(0, 8-5) & delay_value(9)( 9 downto  5);
      in_reg(31 downto 24) <= conv_std_logic_vector(0, 8-5) & delay_value(9)( 9 downto  5);

	  elsif (in_reg_req = '1' and in_reg_addr = ADDR_TAP_VAL5) then
      in_reg_val <= '1';
      in_reg( 7 downto  0) <= conv_std_logic_vector(0, 8-5) & delay_value(10)( 4 downto  0);
      in_reg(15 downto  8) <= conv_std_logic_vector(0, 8-5) & delay_value(10)( 4 downto  0);
      in_reg(23 downto 16) <= conv_std_logic_vector(0, 8-5) & delay_value(11)( 9 downto  5);
      in_reg(31 downto 24) <= conv_std_logic_vector(0, 8-5) & delay_value(11)( 9 downto  5);

    elsif (in_reg_req = '1' and in_reg_addr = ADDR_TAP_VAL6) then
      in_reg_val <= '1';
      in_reg( 7 downto  0) <= conv_std_logic_vector(0, 8-5) & delay_value(12)( 4 downto  0);
      in_reg(15 downto  8) <= conv_std_logic_vector(0, 8-5) & delay_value(12)( 4 downto  0);
      in_reg(23 downto 16) <= conv_std_logic_vector(0, 8-5) & delay_value(13)( 9 downto  5);
      in_reg(31 downto 24) <= conv_std_logic_vector(0, 8-5) & delay_value(13)( 9 downto  5);

	  elsif (in_reg_req = '1' and in_reg_addr = ADDR_TAP_VAL7) then
      in_reg_val <= '1';
      in_reg( 7 downto  0) <= conv_std_logic_vector(0, 8-5) & delay_value(14)( 4 downto  0);
      in_reg(15 downto  8) <= conv_std_logic_vector(0, 8-5) & delay_value(14)( 4 downto  0);
      in_reg(23 downto 16) <= conv_std_logic_vector(0, 8-5) & delay_value(15)( 9 downto  5);
      in_reg(31 downto 24) <= conv_std_logic_vector(0, 8-5) & delay_value(15)( 9 downto  5);

    else
      in_reg_val <= '0';
      in_reg     <= in_reg;

    end if;

  end if;
end process;

----------------------------------------------------------------------------------------------------
-- Map commands
----------------------------------------------------------------------------------------------------
delay_reset     <= cmd_reg(0) or rst;
clk_reset       <= cmd_reg(1) or rst;
io_reset        <= cmd_reg(2) or rst;
start_align     <= cmd_reg(3);

----------------------------------------------------------------------------------------------------
-- Create the clock input logic
----------------------------------------------------------------------------------------------------
clks: for i in 0 to NBIC-1 generate
  fmc11x_dco_buf_inst0: fmc11x_dco_buf
  port map (
    clk_reset => clk_reset,
    dco_p     => dco_p(i),
    dco_n     => dco_n(i),
    clk_buf   => clk_buf(i),
    clk_inv   => clk_inv(i),
    clk_div   => clk_div(i),
    clk_div_g => clk_div_g(i)
  );
end generate;

dco(NBIC-1 downto 0) <= clk_div;

----------------------------------------------------------------------------------------------------
-- Serdes input mapping (3 clock domains/regions)
----------------------------------------------------------------------------------------------------

serdes_clock_map_inst : serdes_clock_map

generic map(
  NBCH => NBCH,
  NBIC => NBIC
)
port map(

   clk_buf_i  => clk_buf,
   clk_inv_i  => clk_inv,
   clk_div_i  => clk_div,

   clk_buf_o_data  => clk_buf_o_data,
   clk_inv_o_data  => clk_inv_o_data,
   clk_div_o_data  => clk_div_o_data,

   clk_buf_o_frame => clk_buf_o_frame,
   clk_inv_o_frame => clk_inv_o_frame,
   clk_div_o_frame => clk_div_o_frame
);

inputs_ch: for i in 0 to NBCH-1 generate

  in_p(i) (1 downto 0)<= outa_p(i)  & outb_p(i);
  in_n(i) (1 downto 0)<= outa_n(i)  & outb_n(i);

end generate;

----------------------------------------------------------------------------------------------------
-- Channel A
----------------------------------------------------------------------------------------------------

frame: for i in 0 to NBIC-1 generate
  frame_serdes_inst : serdes

  generic map (
    SYS_W               => 1,
    DEV_W               => 8
  )
  port map (
    data_in_from_pins_p => frame_p(i downto i),
    data_in_from_pins_n => frame_n(i downto i),
    data_in_to_device   => open,
    rst_cmd             => rst,
    clk_cmd             => clk_cmd,
    start_align         => start_align,
    data_aligned_out    => data_aligned_out(NBCH+i)(0 downto 0),
    data_aligned        => data_aligned(NBCH+i),
    delay_reset         => delay_reset,
    delay_valid_inc     => delay_inc_val,
    delay_data_inc      => delay_inc(NBCH+i)(0 downto 0),
    delay_valid_dec     => delay_dec_val,
    delay_data_dec      => delay_dec(NBCH+i)(0 downto 0),
    delay_value         => delay_value(NBCH+i)(4 downto 0),
    bitslip_val         => bitslip_val,
    bitslip             => bitslip(NBCH+i)(0 downto 0),
    clk_div             => clk_div_o_frame(i),
    clk_in_int_buf      => clk_buf_o_frame(i),
    clk_in_int_inv      => clk_inv_o_frame(i),
    io_reset            => io_reset

    );
end generate;

frames: for i in 0 to NBCH-1 generate
  ch_serdes_inst : serdes
  generic map (
    SYS_W               => 2,
    DEV_W               => 2*8
  )
  port map (
    data_in_from_pins_p => in_p(i),
    data_in_from_pins_n => in_n(i),
    data_in_to_device   => serdes_out(i),
    rst_cmd             => rst,
    clk_cmd             => clk_cmd,
    start_align         => start_align,
    data_aligned_out    => data_aligned_out(i),
    data_aligned        => data_aligned(i),
    delay_reset         => delay_reset,
    delay_valid_inc     => delay_inc_val,
    delay_data_inc      => delay_inc(i),
    delay_valid_dec     => delay_dec_val,
    delay_data_dec      => delay_dec(i),
    delay_value         => delay_value(i),
    bitslip_val         => bitslip_val,
    bitslip             => bitslip(i),
    clk_div             => clk_div_o_data(i),
    clk_in_int_buf      => clk_buf_o_data(i),
    clk_in_int_inv      => clk_inv_o_data(i),
    io_reset            => io_reset

    );
end generate;

----------------------------------------------------------------------------------------------------
-- Serdes output mapping
----------------------------------------------------------------------------------------------------
serdesmap: for s in 0 to NBCH-1 generate

      data(s)(00) <= serdes_out(s)(00);
      data(s)(02) <= serdes_out(s)(01);
      data(s)(04) <= serdes_out(s)(02);
      data(s)(06) <= serdes_out(s)(03);
      data(s)(08) <= serdes_out(s)(04);
      data(s)(10) <= serdes_out(s)(05);
      data(s)(12) <= serdes_out(s)(06);
      data(s)(14) <= serdes_out(s)(07);

      data(s)(01) <= serdes_out(s)(08);
      data(s)(03) <= serdes_out(s)(09);
      data(s)(05) <= serdes_out(s)(10);
      data(s)(07) <= serdes_out(s)(11);
      data(s)(09) <= serdes_out(s)(12);
      data(s)(11) <= serdes_out(s)(13);
      data(s)(13) <= serdes_out(s)(14);
      data(s)(15) <= serdes_out(s)(15);

end generate;
----------------------------------------------------------------------------------------------------
-- Pattern check (toggling pattern)
----------------------------------------------------------------------------------------------------
pattern_check: for i in 0 to NBCH-1 generate
  process (pec, clk_div(0))
  begin
    if (pec = '1') then
        pef(i) <= '0';
    elsif (rising_edge(clk_div(0))) then
      if (data(i) /= pat) then
        pef(i) <= '1';
      end if;
    end if;
  end process;
end generate;

----------------------------------------------------------------------------------------------------
-- Connect entity
----------------------------------------------------------------------------------------------------
phy_out_clk(NBCH-1 downto 0) <= clk_div_o_data; -- Regional ADC clock's
ctrl_clk    <= clk_div_g(1);                    -- Global clock from ADC0

phy_out_data0  <= data(00);
phy_out_data1  <= data(01);
phy_out_data2  <= data(02);
phy_out_data3  <= data(03);
phy_out_data4  <= data(04);
phy_out_data5  <= data(05);
phy_out_data6  <= data(06);
phy_out_data7  <= data(07);
phy_out_data8  <= data(08);
phy_out_data9  <= data(09);
phy_out_data10 <= data(10);
phy_out_data11 <= data(11);

ch_16: if(NBCH = 16) generate

   phy_out_data12 <= data(12);
   phy_out_data13 <= data(13);
   phy_out_data14 <= data(14);
   phy_out_data15 <= data(15);

end generate;

----------------------------------------------------------------------------------------------------
-- end
----------------------------------------------------------------------------------------------------
end ltc2175_phy_syn;