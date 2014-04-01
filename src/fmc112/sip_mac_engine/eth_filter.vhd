--------------------------------------------------------------------------------
-- eth_filter.vhd
--------------------------------------------------------------------------------
-- This is a module to Filter packets based on Dst Mac address
--------------------------------------------------------------------------------
-- The ETH_STREAM signals actually includes three signals:
--   Bit    9 : CKE: Clock enable sets data rate. Lower bits are only valid if CKE.
--   Bit    8 : FRM: Frame signal, asserted for entire ethernet frame.
--   Bits 7-0 : DAT: Frame data, ignored if not FRM.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Specify Libraries
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_misc.all;
  use ieee.std_logic_unsigned.all;

--------------------------------------------------------------------------------
-- Specify Entity
--------------------------------------------------------------------------------

entity eth_filter is
generic (
  MAC_FILTER     : std_logic_vector(47 downto 0)
);
port (
  rst            : in  std_logic;
  clk            : in  std_logic;
  eth_stream_in  : in  std_logic_vector(9 downto 0);
  eth_stream_out : out std_logic_vector(9 downto 0)
);
end entity eth_filter;

--------------------------------------------------------------------------------
-- Specify Architecture
--------------------------------------------------------------------------------

architecture eth_filter_syn of eth_filter is

--------------------------------------------------------------------------------
-- Signal declaration
--------------------------------------------------------------------------------

signal in_cke       : std_logic;
signal in_frm       : std_logic;
signal in_dat       : std_logic_vector(7 downto 0);
signal byte_cnt     : std_logic_vector(5 downto 0);
signal mac_dat      : std_logic_vector(7 downto 0);
signal mac_chk_en   : std_logic;
signal mac_mismatch : std_logic;
signal match        : std_logic;

signal dat_dly1     : std_logic_vector(7 downto 0);
signal dat_dly2     : std_logic_vector(7 downto 0);
signal dat_dly3     : std_logic_vector(7 downto 0);
signal dat_dly4     : std_logic_vector(7 downto 0);
signal dat_dly5     : std_logic_vector(7 downto 0);
signal dat_dly6     : std_logic_vector(7 downto 0);

signal frm_dly1     : std_logic;
signal frm_dly2     : std_logic;
signal frm_dly3     : std_logic;
signal frm_dly4     : std_logic;
signal frm_dly5     : std_logic;
signal frm_dly6     : std_logic;

--------------------------------------------------------------------------------
-- Begin
--------------------------------------------------------------------------------

begin

in_cke <= eth_stream_in(9);
in_frm <= eth_stream_in(8);
in_dat <= eth_stream_in(7 downto 0);

-- Packet Byte counter
process (rst, clk)
begin
  if (rst = '1') then
    byte_cnt <= (others => '0');

  elsif (rising_edge(clk)) then

    if (in_cke = '1') then
      if (in_frm = '0') then
        byte_cnt <= (others => '0');
      elsif (byte_cnt /= 63) then
        byte_cnt <= byte_cnt + 1;
      end if;
    end if;

  end if;
end process;

-- Dst Mac address
mac_dat <=
  MAC_FILTER(47 downto 40) when byte_cnt = 0 else
  MAC_FILTER(39 downto 32) when byte_cnt = 1 else
  MAC_FILTER(31 downto 24) when byte_cnt = 2 else
  MAC_FILTER(23 downto 16) when byte_cnt = 3 else
  MAC_FILTER(15 downto  8) when byte_cnt = 4 else
  MAC_FILTER( 7 downto  0) when byte_cnt = 5 else
  (others => '0');

-- Check the Dst Mac address
mac_chk_en   <= '1' when (in_frm = '1' and byte_cnt >= 0 and byte_cnt < 6) else '0';
mac_mismatch <= '1' when (in_dat /= mac_dat) else '0';

process (rst, clk)
begin
  if (rst = '1') then
    match <= '0';

    dat_dly1 <= (others => '0');
    dat_dly2 <= (others => '0');
    dat_dly3 <= (others => '0');
    dat_dly4 <= (others => '0');
    dat_dly5 <= (others => '0');
    dat_dly6 <= (others => '0');

    frm_dly1 <= '0';
    frm_dly2 <= '0';
    frm_dly3 <= '0';
    frm_dly4 <= '0';
    frm_dly5 <= '0';
    frm_dly6 <= '0';

    eth_stream_out <= (others => '0');

  elsif (rising_edge(clk)) then

    -- Check
    if (in_cke = '1') then
      if (in_frm = '1' and byte_cnt = 0) then
        match <= not mac_mismatch;
      elsif (mac_chk_en = '1' and mac_mismatch = '1') then
        match <= '0';
      end if;
    end if;

    -- Delay the data to lag comparison results
    if (in_cke = '1') then
      dat_dly1 <= in_dat;
      dat_dly2 <= dat_dly1;
      dat_dly3 <= dat_dly2;
      dat_dly4 <= dat_dly3;
      dat_dly5 <= dat_dly4;
      dat_dly6 <= dat_dly5;

      frm_dly1 <= in_frm;
      frm_dly2 <= frm_dly1;
      frm_dly3 <= frm_dly2;
      frm_dly4 <= frm_dly3;
      frm_dly5 <= frm_dly4;
      frm_dly6 <= frm_dly5;
    end if;

    -- Register outputs
    eth_stream_out(9) <= in_cke;
    eth_stream_out(8) <= frm_dly6 and match;
    eth_stream_out(7 downto 0) <= dat_dly6;

  end if;
end process;

--------------------------------------------------------------------------------
-- End
--------------------------------------------------------------------------------

end eth_filter_syn;
