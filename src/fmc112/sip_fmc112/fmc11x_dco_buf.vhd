-------------------------------------------------------------------------------------
-- FILE NAME : fmc112_dco_buf.vhd
--
-- AUTHOR    : Peter Kortekaas
--
-- COMPANY   : 4DSP
--
-- ITEM      : 1
--
-- UNITS     : Entity       - fmc112_dco_buf
--             architecture - fmc112_dco_buf_syn
--
-- LANGUAGE  : VHDL
--
-------------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------------
-- DESCRIPTION
-- ===========
--
-- fmc112_dco_buf
-- Notes: fmc112_dco_buf
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

entity fmc11x_dco_buf is
  port (
    clk_reset : in   std_logic;
    dco_p     : in   std_logic;
    dco_n     : in   std_logic;
    clk_buf   : out  std_logic; -- fast clock
    clk_inv   : out  std_logic; -- fast clock inverted
    clk_div   : out  std_logic;  -- slow clock (/4)
    clk_div_g : out  std_logic  -- slow clock (/4)
  );
end fmc11x_dco_buf;

architecture fmc11x_dco_buf_syn of fmc11x_dco_buf is

----------------------------------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------------------------------
signal clk_in_int     : std_logic;
signal clk_in_int_buf : std_logic;
signal clk_div_int    : std_logic;

begin

----------------------------------------------------------------------------------------------------
-- Create the clock input logic
----------------------------------------------------------------------------------------------------
ibufgds_inst_clk : IBUFDS
generic map (
  DIFF_TERM  => TRUE,
  IOSTANDARD => "LVDS_25"
)
port map (
  I  => dco_p,
  IB => dco_n,
  O  => clk_in_int
);

-- High Speed BUFIO clock buffer
-- BUFIO
bufio_inst_clk : BUFIO
port map (
  I => clk_in_int,
  O => clk_in_int_buf
);

clk_buf <= clk_in_int_buf;
clk_inv <= not clk_in_int_buf;

-- BUFR generates the slow clock
bufr_inst_clk_div : BUFR
generic map (
  SIM_DEVICE => "7SERIES",
  BUFR_DIVIDE => "4"
)
port map (
  I   => clk_in_int,
  O   => clk_div_int,
  CE  => '1',
  CLR => clk_reset
);
clk_div <= clk_div_int;

bufg_inst_clk : BUFG
port map (
  I => clk_div_int,
  O => clk_div_g
);


-- Slow clock is driven by a BUFG to equalize delays between fast and slow clock,
-- this is necesary to properly sync/reset ISERDES' spread over multiple banks in different columns







----------------------------------------------------------------------------------------------------
-- End
----------------------------------------------------------------------------------------------------
end fmc11x_dco_buf_syn;
