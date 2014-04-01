-------------------------------------------------------------------------------------
-- FILE NAME : fmc112_ctrl.vhd
--
-- AUTHOR    : Remon Zandvliet
--
-- COMPANY   : 4DSP
--
-- ITEM      : 1
--
-- UNITS     : Entity       - fmc112_ctrl
--             architecture - fmc112_ctrl_syn
--
-- LANGUAGE  : VHDL
--
-------------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------------
-- DESCRIPTION
-- ===========
--
-- fmc116_ctrl
-- Notes: fmc116_ctrl
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
  use ieee.std_logic_unsigned.all;
  use ieee.std_logic_misc.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_1164.all;
library unisim;
  use unisim.vcomponents.all;

entity fmc112_ctrl is
  generic
  (
    START_ADDR             : std_logic_vector(27 downto 0) := x"0000000";
    STOP_ADDR              : std_logic_vector(27 downto 0) := x"00000FF"
  );
  port (
    rst                    : in  std_logic;

    -- Command Interface
    clk_cmd                : in    std_logic;
    in_cmd_val             : in    std_logic;
    in_cmd                 : in    std_logic_vector(63 downto 0);
    out_cmd_val            : out   std_logic;
    out_cmd                : out   std_logic_vector(63 downto 0);
    cmd_busy               : out   std_logic;

    --External trigger
    ext_trigger_p          : in  std_logic;
    ext_trigger_n          : in  std_logic;
    ext_trigger_buf        : out std_logic;

    --FIFO Control
    adc_clk                : in  std_logic;
    fifo_wr_en             : out std_logic_vector(15 downto 0);
    fifo_empty             : in  std_logic_vector(15 downto 0);
    fifo_full              : in  std_logic_vector(15 downto 0);

    --FMC Status
    pg_m2c                  : in  std_logic;
    prsnt_m2c_l             : in  std_logic

  );
end fmc112_ctrl;

architecture fmc112_ctrl_syn of fmc112_ctrl is

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
constant ADDR_COMMAND         : std_logic_vector(31 downto 0) := x"00000000";
constant ADDR_CONTROL         : std_logic_vector(31 downto 0) := x"00000001";
constant ADDR_NB_BURSTS       : std_logic_vector(31 downto 0) := x"00000002";
constant ADDR_BURST_SIZE      : std_logic_vector(31 downto 0) := x"00000003";
constant ADDR_FMC_INFO        : std_logic_vector(31 downto 0) := x"00000004";

constant EXT_TRIGGER_DISABLE  : std_logic_vector(1 downto 0) := "00";
constant EXT_TRIGGER_RISE     : std_logic_vector(1 downto 0) := "01";
constant EXT_TRIGGER_FALL     : std_logic_vector(1 downto 0) := "10";
constant EXT_TRIGGER_BOTH     : std_logic_vector(1 downto 0) := "11";

----------------------------------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------------------------------
signal out_reg_val       : std_logic;
signal out_reg_addr      : std_logic_vector(27 downto 0);
signal out_reg           : std_logic_vector(31 downto 0);

signal in_reg_req        : std_logic;
signal in_reg_addr       : std_logic_vector(27 downto 0);
signal in_reg_val        : std_logic;
signal in_reg            : std_logic_vector(31 downto 0);

signal adc_en_reg        : std_logic_vector(15 downto 0);
signal trigger_sel_reg   : std_logic_vector(1 downto 0);

signal nb_bursts_reg     : std_logic_vector(31 downto 0);
signal burst_size_reg    : std_logic_vector(31 downto 0);

signal cmd_reg           : std_logic_vector(31 downto 0);
signal adc_cmd           : std_logic_vector(31 downto 0);

signal arm               : std_logic;
signal disarm            : std_logic;
signal sw_trigger        : std_logic;

signal armed             : std_logic;
signal adc_en            : std_logic_vector(15 downto 0);
signal unlim_bursts      : std_logic;
signal nb_bursts_cnt     : std_logic_vector(31 downto 0);
signal burst_size_cnt    : std_logic_vector(31 downto 0);
signal trigger           : std_logic;

signal ext_trigger       : std_logic;
signal ext_trigger_prev0 : std_logic;
signal ext_trigger_prev1 : std_logic;
signal ext_trigger_re    : std_logic;
signal ext_trigger_fe    : std_logic;

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

cmd_busy <= '0';

----------------------------------------------------------------------------------------------------
-- Registers
----------------------------------------------------------------------------------------------------
process (rst, clk_cmd)
begin
  if (rst = '1') then
    cmd_reg         <= (others => '0');
    adc_en_reg      <= (others => '0');
    trigger_sel_reg <= (others => '0');
    nb_bursts_reg   <= (others => '0');
    burst_size_reg  <= (others => '0');

    in_reg_val      <= '0';
    in_reg          <= (others => '0');

  elsif (rising_edge(clk_cmd)) then

    -- Write
    if (out_reg_val = '1' and out_reg_addr = ADDR_COMMAND) then
      cmd_reg <= out_reg;
    else
      cmd_reg <= (others => '0');
    end if;

    if (out_reg_val = '1' and out_reg_addr = ADDR_CONTROL) then
      adc_en_reg      <= out_reg(15 downto 0);
      trigger_sel_reg <= out_reg(17 downto 16);
    end if;

    if (out_reg_val = '1' and out_reg_addr = ADDR_NB_BURSTS) then
      nb_bursts_reg <= out_reg;
    end if;

    if (out_reg_val = '1' and out_reg_addr = ADDR_BURST_SIZE) then
      burst_size_reg <= out_reg;
    end if;

    -- Read
    if (in_reg_req = '1' and in_reg_addr = ADDR_COMMAND) then
      in_reg_val <= '1';
      in_reg     <= cmd_reg;

    elsif (in_reg_req = '1' and in_reg_addr = ADDR_CONTROL) then
      in_reg_val <= '1';
      in_reg     <= conv_std_logic_vector(0, 12) &
	      or_reduce(fifo_full) &
	      and_reduce(fifo_empty) &
		    trigger_sel_reg &
		    adc_en_reg;

    elsif (in_reg_req = '1' and in_reg_addr = ADDR_NB_BURSTS) then
      in_reg_val <= '1';
      in_reg     <= nb_bursts_reg;

    elsif (in_reg_req = '1' and in_reg_addr = ADDR_BURST_SIZE) then
      in_reg_val <= '1';
      in_reg     <= burst_size_reg;

    elsif (in_reg_req = '1' and in_reg_addr = ADDR_FMC_INFO) then
      in_reg_val <= '1';
      in_reg     <= conv_std_logic_vector(0, 30) & '1' & not prsnt_m2c_l; -- PG_M2C_0 is always high.

    else
      in_reg_val <= '0';
      in_reg     <= in_reg;
    end if;

  end if;
end process;

----------------------------------------------------------------------------------------------------
-- Transfer command pulses to other ADC0 clock domain
----------------------------------------------------------------------------------------------------
adc0_cmd_pls: for i in 0 to 31 generate

  pulse2pulse_inst : pulse2pulse
  port map (
    in_clk   => clk_cmd,
    out_clk  => adc_clk,
    rst      => rst,
    pulsein  => cmd_reg(i),
    inbusy   => open,
    pulseout => adc_cmd(i)
  );

end generate;

----------------------------------------------------------------------------------------------------
-- Map pulses
----------------------------------------------------------------------------------------------------
arm        <= adc_cmd(0);
disarm     <= adc_cmd(1);
sw_trigger <= adc_cmd(2);

----------------------------------------------------------------------------------------------------
-- LVDS Trigger Input
----------------------------------------------------------------------------------------------------
ibufds_trig : ibufds
generic map (
  IOSTANDARD => "LVDS_25",
  DIFF_TERM => TRUE
)
port map (
  i  => ext_trigger_p,
  ib => ext_trigger_n,
  o  => ext_trigger
);

-----------------------------------------------------------------------------------
-- ADC triggering and burst control
-----------------------------------------------------------------------------------
process (rst, adc_clk)
begin
  if (rst = '1') then
    ext_trigger_prev0 <= '0';
    ext_trigger_prev1 <= '0';
    ext_trigger_re    <= '0';
    ext_trigger_fe    <= '0';
    trigger           <= '0';
    armed             <= '0';
    adc_en            <= (others => '0');
    unlim_bursts      <= '0';
    nb_bursts_cnt     <= (others => '0');
    burst_size_cnt    <= (others => '0');
    fifo_wr_en        <= (others => '0');

  elsif (rising_edge(adc_clk)) then

    ext_trigger_prev0 <= ext_trigger;
    ext_trigger_prev1 <= ext_trigger_prev0;

    -- Generate pulse on rising edge external trigger
    if (ext_trigger_prev0 = '1' and ext_trigger_prev1 = '0') then
      ext_trigger_re <= '1';
    else
      ext_trigger_re <= '0';
    end if;

    -- Generate pulse on falling edge external trigger
    if (ext_trigger_prev0 = '0' and ext_trigger_prev1 = '1') then
      ext_trigger_fe <= '1';
    else
      ext_trigger_fe <= '0';
    end if;

    -- Select the trigger source
    if (armed = '1' and sw_trigger = '1') then
      trigger <= '1';
    elsif (armed = '1' and ext_trigger_re = '1' and (trigger_sel_reg = EXT_TRIGGER_RISE or trigger_sel_reg = EXT_TRIGGER_BOTH) ) then
      trigger <= '1';
    elsif (armed = '1' and ext_trigger_fe = '1' and (trigger_sel_reg = EXT_TRIGGER_FALL or trigger_sel_reg = EXT_TRIGGER_BOTH) ) then
      trigger <= '1';
    else
      trigger <= '0';
    end if;

    -- Latch channel enable
    if (arm = '1' and armed = '0') then
      adc_en <= adc_en_reg;
    end if;

    if (arm = '1' and armed = '0') then
      armed <= '1';
    elsif (disarm = '1' and armed = '1') then
      armed <= '0';
    elsif (unlim_bursts = '0' and nb_bursts_cnt = 0 and burst_size_cnt = 0) then
      armed <= '0';
    end if;

    -- No of burst set to 0 means unlimited amount of bustst
    if (armed = '0') then
      unlim_bursts <= not or_reduce(nb_bursts_reg);
    end if;

    -- When not (yet) armed copy the register into the counter
    if (armed = '0') then
      nb_bursts_cnt <= nb_bursts_reg;
    elsif (trigger = '1' and burst_size_cnt = 0 and nb_bursts_cnt /= 0) then
      nb_bursts_cnt <= nb_bursts_cnt - '1';
    end if;

    -- Conversion start when the burst size counter is unequal to 0
    -- Load the burst size counter on a trigger, when the previous burst is
    -- finished and one or more channels are selected.
    if (armed = '0') then
      burst_size_cnt <= (others => '0');
    elsif (trigger = '1' and burst_size_cnt = 0 and (nb_bursts_cnt /= 0 or unlim_bursts = '1')) then
      burst_size_cnt <= burst_size_reg;
    -- Decrease the burst size counter every conversion
    elsif (burst_size_cnt /= 0) then
      burst_size_cnt <= burst_size_cnt - 1;
    end if;

    if (trigger = '1' and burst_size_cnt = 0 and (nb_bursts_cnt /= 0 or unlim_bursts = '1')) then
      fifo_wr_en <= adc_en;
    elsif (burst_size_cnt = 1) then
      fifo_wr_en <= (others => '0');
    end if;

  end if;
end process;

----------------------------------------------------------------------------------------------------
-- Connect entity
----------------------------------------------------------------------------------------------------
ext_trigger_buf <= ext_trigger;

----------------------------------------------------------------------------------------------------
-- End
----------------------------------------------------------------------------------------------------
end fmc112_ctrl_syn;
