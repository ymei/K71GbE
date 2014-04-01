--------------------------------------------------------------------------------
-- eth_mdio.vhd
--------------------------------------------------------------------------------
-- This module utilizes a state machine to read PHY status
-- using the MDIO interface.  Specifically it discovers the
-- current LINK speed of the ethernet connection which is used
-- by the ethernet routing logic external to this module.
--------------------------------------------------------------------------------
-- Link speed:
-- 00 = Off
-- 01 = 100Mbit
-- 10 = 1Gbit
-- 11 = Reserved

--------------------------------------------------------------------------------
-- Specify Libraries
--------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_misc.all;
  use ieee.std_logic_unsigned.all;
library unisim;
  use unisim.vcomponents.all;

--------------------------------------------------------------------------------
-- Specify Entity
--------------------------------------------------------------------------------
entity eth_mdio is
port (
  rst          : in    std_logic;
  clk          : in    std_logic;
  e_rst_l      : out   std_logic;
  e_mdc        : out   std_logic;
  e_mdio       : inout std_logic;
  e_link_speed : out   std_logic_vector(1 downto 0)
);
end entity eth_mdio;

--------------------------------------------------------------------------------
-- Specify Architecture
--------------------------------------------------------------------------------
architecture eth_mdio_syn of eth_mdio is

--------------------------------------------------------------------------------
-- Signal declaration
--------------------------------------------------------------------------------
type sh_states is (idle, reset, preamble, start_of_frame, opcode,
  phy_addr, reg_addr, turn_around, data_field, postamble);
signal sh_state    : sh_states;

signal shift_reg   : std_logic_vector(71 downto 0);

signal sclk_prebuf : std_logic;
signal serial_clk  : std_logic;
signal sclk_ext    : std_logic;

signal read_reg    : std_logic_vector(15 downto 0);
signal resolved    : std_logic;
signal speed       : std_logic_vector(1 downto 0);

--------------------------------------------------------------------------------
-- Begin
--------------------------------------------------------------------------------
begin

----------------------------------------------------------------------------------------------------
-- Generate serial clock (max 8.3MHz)
----------------------------------------------------------------------------------------------------

process (clk)
  -- Divide by 2^4 = 16, CLKmax = 16 x 8.3MHz = 132.8MHz
  variable clk_div : std_logic_vector(3 downto 0) := (others => '0');
begin
  if (rising_edge(clk)) then
    clk_div    := clk_div + '1';
    sclk_ext <= clk_div(clk_div'length-1);
    sclk_prebuf <= sclk_ext;
  end if;
end process;

bufg_sclk : bufg
port map (
  i => sclk_prebuf,
  o => serial_clk
);

----------------------------------------------------------------------------------------------------
-- Serial interface state-machine
----------------------------------------------------------------------------------------------------
process (rst, serial_clk)

  variable cnt : integer range 0 to 63;

begin
  if (rst = '1') then

    cnt := 0;
    sh_state <= reset;

  elsif (rising_edge(serial_clk)) then

    case sh_state is

      when reset =>
        cnt := cnt + 1;
        if (cnt = 63) then
          cnt := 0;
          sh_state <= idle;
        end if;

      when idle =>
        cnt := cnt + 1;
        if (cnt = 32) then
          cnt := 0;
          sh_state <= preamble;
        end if;

      when preamble =>
        cnt := cnt + 1;
        if (cnt = 32) then
          cnt := 0;
          sh_state <= start_of_frame;
        end if;

      when start_of_frame =>
        cnt := cnt + 1;
        if (cnt = 2) then
          cnt := 0;
          sh_state <= opcode;
        end if;

      when opcode =>
        cnt := cnt + 1;
        if (cnt = 2) then
          cnt := 0;
          sh_state <= phy_addr;
        end if;

      when phy_addr =>
        cnt := cnt + 1;
        if (cnt = 5) then
          cnt := 0;
          sh_state <= reg_addr;
        end if;

      when reg_addr =>
        cnt := cnt + 1;
        if (cnt = 5) then
          cnt := 0;
          sh_state <= turn_around;
        end if;

      when turn_around =>
        cnt := cnt + 1;
        if (cnt = 2) then
          cnt := 0;
          sh_state <= data_field;
        end if;

      when data_field =>
        cnt := cnt + 1;
        if (cnt = 16) then
          cnt := 0;
          sh_state <= postamble;
        end if;

      when postamble =>
        cnt := cnt + 1;
        if (cnt = 8) then
          cnt := 0;
          sh_state <= idle;
        end if;

      when others =>
        sh_state <= idle;

    end case;

  end if;
end process;

----------------------------------------------------------------------------------------------------
-- State-machine outputs
----------------------------------------------------------------------------------------------------
process (rst, serial_clk)
begin
  if (rst = '1') then

    shift_reg  <= (others => '1');
    read_reg   <= (others => '0');
    resolved   <= '0';
    speed      <= "00";

  elsif (rising_edge(serial_clk)) then

    if (sh_state = idle) then
      shift_reg <= x"FFFFFFFF" & "01" & "10" & "00111" & "10001" & "00" & x"0000" & x"FF";
    elsif (sh_state /= postamble) then
      shift_reg <= shift_reg(shift_reg'length-2 downto 0) & e_mdio;
    end if;

    if (sh_state = data_field) then
      read_reg <= shift_reg(15 downto 0);
    end if;

    if (sh_state = postamble) then
      resolved <= read_reg(11);
      speed    <= read_reg(15 downto 14);
    end if;

  end if;
end process;

--------------------------------------------------------------------------------
-- Outputs
--------------------------------------------------------------------------------
e_rst_l      <= '1';--'0' when (sh_state = reset) else '1';
e_mdc        <= not sclk_ext when (sh_state /= reset and sh_state /= idle) else '0';
e_mdio       <= 'Z' when (sh_state = reset or sh_state = idle or sh_state = turn_around or sh_state = data_field) else shift_reg(shift_reg'length-1);
e_link_speed <= speed when resolved = '1' else "00";

--------------------------------------------------------------------------------
-- End
--------------------------------------------------------------------------------

end eth_mdio_syn;
