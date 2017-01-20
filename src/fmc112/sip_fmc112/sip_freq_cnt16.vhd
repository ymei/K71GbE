-----------------------------------------------------------------
-- Entity freq_cnt16
----------------------------------------------------------------

library ieee;
  use ieee.std_logic_unsigned.all;
  use ieee.std_logic_misc.all;
  use ieee.std_logic_arith.all;
  use ieee.math_real.all;
  use ieee.std_logic_1164.all;

entity sip_freq_cnt16 is
generic (
  START_ADDR      : std_logic_vector(27 downto 0) := x"0000000";
  STOP_ADDR       : std_logic_vector(27 downto 0) := x"0000001"
);
port (
  -- Command Interface
  clk_cmd         : in  std_logic;
  in_cmd_val      : in  std_logic;
  in_cmd          : in  std_logic_vector(63 downto 0);
  out_cmd_val     : out std_logic;
  out_cmd         : out std_logic_vector(63 downto 0);
  -- Clocks Interface
  reset           : in  std_logic;
  reference_clock : in  std_logic;
  test_clocks     : in  std_logic_vector(15 downto 0)
);
end sip_freq_cnt16;

architecture sip_freq_cnt16_syn of sip_freq_cnt16 is

-----------------------------------------------------------------------------------
-- Constant declarations
-----------------------------------------------------------------------------------
constant NB_CNTR : integer := 16;
type std2d_nb_cntrb is array(natural range <>) of std_logic_vector(NB_CNTR - 1  downto 0);

-----------------------------------------------------------------------------------
--Signal declarations
-----------------------------------------------------------------------------------
signal clock_sel       : std_logic_vector(3 downto 0);

signal cmd_rst         : std_logic;

signal ref_cntr        : integer range 2**13-1 downto 0;
signal ref_trigger     : std_logic;
signal trigger         : std_logic_vector(NB_CNTR - 1 downto 0);

signal clk_cntr        : std2d_nb_cntrb(NB_CNTR - 1 downto 0);
signal clk_cnt_reg     : std2d_nb_cntrb(NB_CNTR - 1 downto 0);
signal clock_cnt_out   : std_logic_vector(NB_CNTR - 1 downto 0);

-----------------------------------------------------------------------------------
-- Component declarations
-----------------------------------------------------------------------------------

component pulse2pulse
port (
  in_clk   : in  std_logic;
  out_clk  : in  std_logic;
  rst      : in  std_logic;
  pulsein  : in  std_logic;
  inbusy   : out std_logic;
  pulseout : out std_logic
);
end component;

-----------------------------------------------------------------------------------
-- Begin
-----------------------------------------------------------------------------------

begin

--------------------------------------------------------------------------------
-- Registers
--------------------------------------------------------------------------------

process (reset, clk_cmd)
begin
  if (reset = '1') then

    clock_sel   <= (others => '0');
    cmd_rst     <= '0';
    out_cmd_val <= '0';
    out_cmd     <= (others => '0');

  elsif (rising_edge(clk_cmd)) then

    -- Write
    if (in_cmd_val = '1' and in_cmd(63 downto 60) = x"1" and in_cmd(59 downto 32) = START_ADDR+0) then
      clock_sel <= in_cmd(clock_sel'length-1 downto 0);
      cmd_rst   <= '1';
    else
      clock_sel <= clock_sel;
      cmd_rst   <= '0';
    end if;

    -- Reads
    if (in_cmd_val = '1' and in_cmd(63 downto 60) = x"2" and in_cmd(59 downto 32) = START_ADDR+0) then
      out_cmd_val <= '1';
      out_cmd(63 downto 60) <= x"4";
      out_cmd(59 downto 32) <= in_cmd(59 downto 32);
      out_cmd(31 downto 0)  <= conv_std_logic_vector(0, 32-clock_sel'length) & clock_sel;
    elsif (in_cmd_val = '1' and in_cmd(63 downto 60) = x"2" and in_cmd(59 downto 32) = START_ADDR+1) then
      out_cmd_val <= '1';
      out_cmd(63 downto 60) <= x"4";
      out_cmd(59 downto 32) <= in_cmd(59 downto 32);
      out_cmd(31 downto 0)  <= conv_std_logic_vector(0, 32-clock_cnt_out'length) & clock_cnt_out;
    else
      out_cmd_val <= '0';
      out_cmd     <= (others => '0');
    end if;

  end if;
end process;

-----------------------------------------------------------------------------------
-- Reference Counter
-----------------------------------------------------------------------------------

process(reset, reference_clock)
begin
  if (reset = '1') then

    ref_cntr    <= 0;
    ref_trigger <= '1';

  elsif (rising_edge(reference_clock)) then

    if (ref_cntr = 2**13-1) then
      ref_cntr    <= 0;
      ref_trigger <= '1';
    else
      ref_cntr    <= ref_cntr + 1;
      ref_trigger <= '0';
    end if;

  end if;
end process;

-----------------------------------------------------------------------------------
-- Clock counters
-----------------------------------------------------------------------------------

CNTR_GEN : for i in 0 to NB_CNTR - 1 generate

  p2p_trigger_inst : pulse2pulse
  port map (
    in_clk   => reference_clock,
    out_clk  => test_clocks(i),
    rst      => reset,
    pulsein  => ref_trigger,
    inbusy   => open,
    pulseout => trigger(i)
  );

  process(reset, cmd_rst, test_clocks(i))
  begin
    if (reset = '1' or cmd_rst = '1') then

      clk_cntr(i)    <= (others=>'0');
      clk_cnt_reg(i) <= (others=>'0');

    elsif (rising_edge(test_clocks(i))) then

      if (trigger(i) = '1') then
        clk_cntr(i)    <= (others=>'0');
        clk_cnt_reg(i) <= clk_cntr(i);
      else
        clk_cntr(i)    <= clk_cntr(i) + conv_std_logic_vector(1, NB_CNTR);
        clk_cnt_reg(i) <= clk_cnt_reg(i);
      end if;

    end if;
  end process;

end generate;

-----------------------------------------------------------------------------------
-- Output MUX
-----------------------------------------------------------------------------------

process(clock_sel, clk_cnt_reg)
begin
  clock_cnt_out <= clk_cnt_reg(conv_integer(clock_sel));
end process;

-----------------------------------------------------------------------------------
-- End
-----------------------------------------------------------------------------------

end sip_freq_cnt16_syn;