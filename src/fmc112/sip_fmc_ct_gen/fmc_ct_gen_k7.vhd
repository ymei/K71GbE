--------------------------------------------------------------------------------
-- file name : fmc_ct_gen.vhd
--
-- author    : p. kortekaas
--
-- company   : 4dsp
--
-- item      : number
--
-- units     : entity       - fmc_ct_gen
--             architecture - fmc_ct_gen_syn
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
--              special, infmc_ct_genental, consequential, or indirect damages
--              arising from the use or operation of the designs or
--              accompanying documentation, however caused and on any theory
--              of liability. this limitation will apply even if 4dsp
--              has been advised of the possibility of such damage. this
--              limitation shall apply not-withstanding the failure of the
--              essential purpose of any limited remedies herein.
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- specify libraries
--------------------------------------------------------------------------------
library  ieee ;
  use ieee.std_logic_unsigned.all;
  use ieee.std_logic_misc.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_1164.all;

--------------------------------------------------------------------------------
-- entity declaration
--------------------------------------------------------------------------------
entity fmc_ct_gen is
generic (
  START_ADDR : std_logic_vector(27 downto 0) := x"0000000";
  STOP_ADDR  : std_logic_vector(27 downto 0) := x"0000001"
);
port (
  -- GTX Connections
  ref_clk_p         : in  std_logic;
  ref_clk_n         : in  std_logic;
  tx_p              : out std_logic;
  tx_n              : out std_logic;
  rx_p              : in  std_logic;
  rx_n              : in  std_logic;
  -- Trigger output
  trig_out          : out std_logic;
  -- Command interface
  reset             : in  std_logic;
  clk_cmd           : in  std_logic;
  out_cmd           : out std_logic_vector(63 downto 0);
  out_cmd_val       : out std_logic;
  in_cmd            : in  std_logic_vector(63 downto 0);
  in_cmd_val        : in  std_logic
);
end entity;

--------------------------------------------------------------------------------
-- arch_itecture declaration
--------------------------------------------------------------------------------
architecture fmc_ct_gen_syn   of fmc_ct_gen  is

-----------------------------------------------------------------------------------
-- Component declarations
-----------------------------------------------------------------------------------
component fmc_ct_gen_cmd is
generic (
   START_ADDR   : std_logic_vector(27 downto 0) := x"0000000";
   STOP_ADDR    : std_logic_vector(27 downto 0) := x"0000010"
);
port (
   reset        : in  std_logic;
   -- Command interface
   clk_cmd      : in  std_logic;                    --cmd_in and cmd_out are synchronous to this clock;
   out_cmd      : out std_logic_vector(63 downto 0);
   out_cmd_val  : out std_logic;
   in_cmd       : in  std_logic_vector(63 downto 0);
   in_cmd_val   : in  std_logic;
   -- Register interface
   clk_reg      : in  std_logic;                    --register interface is synchronous to this clock
   out_reg      : out std_logic_vector(31 downto 0);--caries the out register data
   out_reg_val  : out std_logic;                    --the out_reg has valid data  (pulse)
   out_reg_addr : out std_logic_vector(27 downto 0);--out register address
   in_reg       : in  std_logic_vector(31 downto 0);--requested register data is placed on this bus
   in_reg_val   : in  std_logic;                    --pulse to indicate requested register is valid
   in_reg_req   : out std_logic;                    --pulse to request data
   in_reg_addr  : out std_logic_vector(27 downto 0);--requested address
   -- Mailbox interface
   mbx_in_reg   : in  std_logic_vector(31 downto 0);--value of the mailbox to send
   mbx_in_val   : in  std_logic                     --pulse to indicate mailbox is valid
);
end component;

component k7_gtxwizard_v1_6_top is
generic
(
    EXAMPLE_CONFIG_INDEPENDENT_LANES        : integer   := 1;
    EXAMPLE_LANE_WITH_START_CHAR            : integer   := 0;    -- specifies lane with unique start frame ch
    EXAMPLE_WORDS_IN_BRAM                   : integer   := 512;  -- specifies amount of data in BRAM
    EXAMPLE_SIM_GTRESET_SPEEDUP             : string    := "TRUE";    -- simulation setting for GT SecureIP model
    EXAMPLE_SIMULATION                      : integer   := 0;             -- Set to 1 for simulation
    EXAMPLE_USE_CHIPSCOPE                   : integer   := 0           -- Set to 1 to use Chipscope to drive resets
);
port
(
	 data_in                                 : in   std_logic_vector(31 downto 0);
    Q0_CLK1_GTREFCLK_PAD_N_IN               : in   std_logic;
    Q0_CLK1_GTREFCLK_PAD_P_IN               : in   std_logic;
	 SYSCLK_IN                               : in   std_logic;
    GTTXRESET_IN									  : in   std_logic;
    GTRXRESET_IN                            : in   std_logic;
    RXN_IN                                  : in   std_logic;
    RXP_IN                                  : in   std_logic;
    TXN_OUT                                 : out  std_logic;
    TXP_OUT                                 : out  std_logic
);

end component;

-----------------------------------------------------------------------------------
-- Signal declaration
-----------------------------------------------------------------------------------
signal trigger        : std_logic;

signal out_reg_val    : std_logic;
signal out_reg_addr   : std_logic_vector(27 downto 0);
signal out_reg        : std_logic_vector(31 downto 0);

signal in_reg_req     : std_logic;
signal in_reg_addr    : std_logic_vector(27 downto 0);
signal in_reg_val     : std_logic;
signal in_reg         : std_logic_vector(31 downto 0);

signal freq_sel       : std_logic_vector(3 downto 0);
signal trig_cnt       : std_logic_vector(31 downto 0); -- range 0 to 2**(trig_cnt'length-2)
signal data_in        : std_logic_vector(31 downto 0);

-----------------------------------------------------------------------------------
-- Begin
-----------------------------------------------------------------------------------
begin

-----------------------------------------------------------------------------------
-- Trigger output
-----------------------------------------------------------------------------------
process (reset, clk_cmd)
  variable counter : integer range 0 to 2**(trig_cnt'length-2);
begin
  if (reset = '1') then

    counter  := 0;
    trigger  <= '0';
    trig_out <= '0';

  elsif (rising_edge(clk_cmd)) then

    if (counter >= trig_cnt - 1) then
      counter := 0;
      trigger <= not trigger;
    else
      counter := counter + 1;
      trigger <= trigger;
    end if;

    trig_out <= trigger;

  end if;
end process;

-----------------------------------------------------------------------------------
-- Command filter
-----------------------------------------------------------------------------------
fmc_ct_gen_cmd_inst : fmc_ct_gen_cmd
generic map (
   START_ADDR   => START_ADDR,
   STOP_ADDR    => STOP_ADDR
)
port map (
   reset        => reset,
   clk_cmd      => clk_cmd,
   out_cmd      => out_cmd,
   out_cmd_val  => out_cmd_val,
   in_cmd       => in_cmd,
   in_cmd_val   => in_cmd_val,
   clk_reg      => clk_cmd,
   out_reg_val  => out_reg_val,
   out_reg_addr => out_reg_addr,
   out_reg      => out_reg,
   in_reg_req   => in_reg_req,
   in_reg_addr  => in_reg_addr,
   in_reg_val   => in_reg_val,
   in_reg       => in_reg,
   mbx_in_reg   => (others => '0'),
   mbx_in_val   => '0'
);

-----------------------------------------------------------------------------------
-- Registers
-----------------------------------------------------------------------------------
process (reset, clk_cmd)
begin
  if (reset = '1') then

    freq_sel <= (others => '0');
    trig_cnt <= conv_std_logic_vector(6, trig_cnt'length);
    data_in  <= (others => '0');

  elsif (rising_edge(clk_cmd)) then

    -- Write register
    if (out_reg_val = '1' and out_reg_addr = 0) then
      freq_sel <= out_reg(freq_sel'length-1 downto 0);
    elsif (out_reg_val = '1' and out_reg_addr = 1) then
      trig_cnt <= out_reg(trig_cnt'length-1 downto 0);
    end if;

    -- Read register
    if (in_reg_req = '1' and in_reg_addr = 0) then
      in_reg_val <= '1';
      in_reg     <= conv_std_logic_vector(conv_integer(freq_sel), 32);
    else
      in_reg_val <= '0';
      in_reg     <= in_reg;
    end if;

    -- Set output frequency
    case conv_integer(freq_sel) is
      when 1 =>
        data_in <= x"55555555"; -- GTX PLL /  1
      when 2 =>
        data_in <= x"33333333"; -- GTX PLL /  2
      when 3 =>
        data_in <= x"0F0F0F0F"; -- GTX PLL /  4
      when 4 =>
        data_in <= x"00FF00FF"; -- GTX PLL /  8
      when 5 =>
        data_in <= x"0000FFFF"; -- GTX PLL / 16
      when others =>
        data_in <= x"00000000";
    end case;

  end if;
end process;


-----------------------------------------------------------------------------------
-- Clock Generation
-----------------------------------------------------------------------------------

k7_gtxwizard_v1_6_top_inst : k7_gtxwizard_v1_6_top
generic map (
  EXAMPLE_CONFIG_INDEPENDENT_LANES        => 1,
  EXAMPLE_LANE_WITH_START_CHAR            => 0,
  EXAMPLE_WORDS_IN_BRAM                   => 512,
  EXAMPLE_SIM_GTRESET_SPEEDUP             => "TRUE",
  EXAMPLE_SIMULATION                      => 0,
  EXAMPLE_USE_CHIPSCOPE                   => 0
)
port map (
 		data_in                    => data_in,
 		Q0_CLK1_GTREFCLK_PAD_N_IN  => ref_clk_n,
 		Q0_CLK1_GTREFCLK_PAD_P_IN  => ref_clk_p,
 		SYSCLK_IN   						   => clk_cmd,
 		GTTXRESET_IN			         => reset,
 		GTRXRESET_IN               => reset,
 		rxn_in                     => rx_n,
 		rxp_in                     => rx_p,
 		txn_out                    => tx_n,
 		txp_out                    => tx_p
);

-----------------------------------------------------------------------------------
-- End
-----------------------------------------------------------------------------------

end architecture fmc_ct_gen_syn;

