-------------------------------------------------------------------------------------
-- FILE NAME : fmc112_ltc2175_fifo.vhd
--
-- AUTHOR    : Peter Kortekaas
--
-- COMPANY   : 4DSP
--
-- ITEM      : 1
--
-- UNITS     : Entity       - fmc112_ltc2175_fifo
--             architecture - fmc112_ltc2175_fifo_syn
--
-- LANGUAGE  : VHDL
--
-------------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------------
-- DESCRIPTION
-- ===========
--
-- fmc112_ltc2175_fifo
-- Notes: fmc112_ltc2175_fifo
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
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;
library unisim;
  use unisim.vcomponents.all;

entity fmc112_ltc2175_fifo is
  port (
    rst        : in  std_logic;
    -- Input port
    phy_clk    : in  std_logic;
    fifo_wr_clk : in std_logic;
    phy_data   : in  std_logic_vector(15 downto 0);
    fifo_wr_en : in  std_logic;
    fifo_empty : out std_logic;
    fifo_full  : out std_logic;
    -- Output port
    if_clk     : in  std_logic;
    if_stop    : in  std_logic;
    if_dval    : out std_logic;
    if_data    : out std_logic_vector(63 downto 0)
  );
end fmc112_ltc2175_fifo;

architecture fmc112_ltc2175_fifo_syn of fmc112_ltc2175_fifo is

----------------------------------------------------------------------------------------------------
-- Components
----------------------------------------------------------------------------------------------------
component ltc2175_cbfifo_16to64 is
port (
  rst           : in  std_logic;
  wr_clk        : in  std_logic;
  rd_clk        : in  std_logic;
  din           : in  std_logic_vector(15 downto 0);
  wr_en         : in  std_logic;
  rd_en         : in  std_logic;
  dout          : out std_logic_vector(63 downto 0);
  full          : out std_logic;
  empty         : out std_logic;
  valid         : out std_logic
);
end component;
component ltc2175_16to16 is
port (
  rst           : in  std_logic;
  wr_clk        : in  std_logic;
  rd_clk        : in  std_logic;
  din           : in  std_logic_vector(15 downto 0);
  wr_en         : in  std_logic;
  rd_en         : in  std_logic;
  dout          : out std_logic_vector(15 downto 0);
  full          : out std_logic;
  empty         : out std_logic
);
end component;
----------------------------------------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------------------------------
signal dout           : std_logic_vector(63 downto 0);
signal if_rd_en       : std_logic;
signal wr_data_count  : std_logic_vector(13 downto 0);
signal full_flag      : std_logic;
signal full_latch     : std_logic;
signal fifo_empty_sig : std_logic;
signal fifo_wr_en_reg : std_logic;
signal dout_fifo_a    : std_logic_vector(15 downto 0);

begin

----------------------------------------------------------------------------------------------------
-- FIFO A
----------------------------------------------------------------------------------------------------
ltc2175_16to16_inst : ltc2175_16to16
port map (
  rst           => rst,
  wr_clk        => phy_clk,
  rd_clk        => fifo_wr_clk,
  din           => phy_data,
  wr_en         => '1',
  rd_en         => '1',
  dout          => dout_fifo_a,
  full          => open,
  empty         => open
);

----------------------------------------------------------------------------------------------------
-- FIFO B
----------------------------------------------------------------------------------------------------

ltc2175_cbfifo_16to64_inst : ltc2175_cbfifo_16to64
port map (
  rst           => rst,
  wr_clk        => fifo_wr_clk,
  rd_clk        => if_clk,
  din           => dout_fifo_a,
  wr_en         => fifo_wr_en_reg,
  rd_en         => if_rd_en,
  dout          => dout,
  full          => full_flag,
  empty         => fifo_empty_sig,
  valid         => if_dval
);

if_data <= dout(15 downto 0) & dout(31 downto 16) & dout(47 downto 32) & dout(63 downto 48);

----------------------------------------------------------------------------------------------------
-- Write logic
----------------------------------------------------------------------------------------------------
process (rst, phy_clk)
begin
  if (rst = '1') then

    full_latch     <= '0';
	  fifo_wr_en_reg <= '0';

  elsif (rising_edge(phy_clk)) then

	  if (fifo_wr_en = '1' and full_flag = '1') then
	    full_latch <= '1';
	  else
	    full_latch <= full_latch;
	  end if;

	  fifo_wr_en_reg <= fifo_wr_en;

  end if;
end process;

fifo_full <= full_latch;

process (rst, if_clk)
begin
  if (rst = '1') then

    if_rd_en   <= '0';
    fifo_empty <= '1';

  elsif (rising_edge(if_clk)) then

    if_rd_en   <= not if_stop and not fifo_empty_sig;
    fifo_empty <= fifo_empty_sig;

  end if;
end process;

----------------------------------------------------------------------------------------------------
-- End
----------------------------------------------------------------------------------------------------
end fmc112_ltc2175_fifo_syn;
