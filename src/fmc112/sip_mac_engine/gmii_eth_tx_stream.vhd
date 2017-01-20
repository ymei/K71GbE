--------------------------------------------------------------------------------
--	Basic Functions:
--	  Provides the electrical interface to a PHY using the GMII or MII spec.
--	  Takes a ethernet stream (post crc) and appends the preamble
--	  All bytes sent LSNybble first.
--			Send Preamble (7 bytes)	01010101
--			Send SFD (1 byte) 11010101
--	  Both 1000Mbps and 100Mbps is supported
--------------------------------------------------------------------------------
--	NOTES:
--		This module must receive exactly 1 byte per clock cycle during a gigabit ethernet
--		frame (ie. cke must be high for duration of frame)
--		This module does not pad ethernet packets to the minimum ethernet frame size.
--		This module does not enforce the Inter Frame Gap time (96 ns for 1Gb/s implementation)
--		This module was tested using a Marvell 88E1111 PHY
--------------------------------------------------------------------------------

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

entity gmii_eth_tx_stream is
port (
  clk125        : in  std_logic;
  speed         : in  std_logic_vector(1 downto 0);
  txd           : out std_logic_vector(7 downto 0);
  txctrl        : out std_logic;
  txc           : out std_logic;
  eth_tx_stream : in  std_logic_vector(9 downto 0)
);
end entity gmii_eth_tx_stream;

--------------------------------------------------------------------------------
-- Specify Architecture
--------------------------------------------------------------------------------

architecture gmii_eth_tx_stream_syn of gmii_eth_tx_stream is

--------------------------------------------------------------------------------
-- Component declaration
--------------------------------------------------------------------------------

component oddr is
generic (
  DDR_CLK_EDGE : string;
  INIT         : std_logic;
  SRTYPE       : string
);
port (
  q  : out std_logic;
  c  : in  std_logic;
  ce : in  std_logic;
  d1 : in  std_logic;
  d2 : in  std_logic;
  r  : in  std_logic;
  s  : in  std_logic
);
end component;

--------------------------------------------------------------------------------
-- Signal declaration
--------------------------------------------------------------------------------

signal in_cke : std_logic;
signal in_frm : std_logic;
signal in_dat : std_logic_vector(7 downto 0);

signal data_dly1 : std_logic_vector(7 downto 0);
signal data_dly2 : std_logic_vector(7 downto 0);
signal data_dly3 : std_logic_vector(7 downto 0);
signal data_dly4 : std_logic_vector(7 downto 0);
signal data_dly5 : std_logic_vector(7 downto 0);
signal data_dly6 : std_logic_vector(7 downto 0);
signal data_dly7 : std_logic_vector(7 downto 0);
signal data_dly8 : std_logic_vector(7 downto 0);
signal frm_dly   : std_logic_vector(8 downto 1);

signal outcnt    : std_logic_vector(2 downto 0);
signal txd_int   : std_logic_vector(7 downto 0);

signal txdat_reg : std_logic_vector(7 downto 0);
signal txen_reg  : std_logic;

--------------------------------------------------------------------------------
-- Begin
--------------------------------------------------------------------------------

begin

--------------------------------------------------------------------------------
-- Map
--------------------------------------------------------------------------------
in_cke <= eth_tx_stream(9);
in_frm <= eth_tx_stream(8);
in_dat <= eth_tx_stream(7 downto 0);

--------------------------------------------------------------------------------
-- Delay the data by eight bytes to insert the preamble
--------------------------------------------------------------------------------
process (clk125)
begin
  if (rising_edge(clk125)) then

	  if (in_cke = '1') then
		  data_dly1 <= in_dat;
		  data_dly2 <= data_dly1;
		  data_dly3 <= data_dly2;
		  data_dly4 <= data_dly3;
		  data_dly5 <= data_dly4;
		  data_dly6 <= data_dly5;
		  data_dly7 <= data_dly6;
		  data_dly8 <= data_dly7;
		  frm_dly <= frm_dly(7 downto 1) & in_frm;
		end if;

  end if;
end process;

--------------------------------------------------------------------------------
-- Register the Data byte to send
--------------------------------------------------------------------------------
process (clk125)
begin
  if (rising_edge(clk125)) then

	  if (in_cke = '1') then

  		if (frm_dly(8) = '1') then
  		  txdat_reg <= data_dly8;
  		elsif (frm_dly(7) = '1') then
  		  txdat_reg <= x"D5";
  		else
  		  txdat_reg <= x"55";
  		end if;

	  	txen_reg <= in_frm or frm_dly(8);

		end if;

  end if;
end process;

--------------------------------------------------------------------------------
-- Handle 100Mbps/1000Mbps Modes
--------------------------------------------------------------------------------
process (clk125)
begin
  if (rising_edge(clk125)) then

    if (in_cke = '1') then
      outcnt <= "000";
    elsif (outcnt /= "111") then
      outcnt <= outcnt + '1';
    end if;

    if (in_cke = '1') then
      txd_int <= txdat_reg;
    elsif (outcnt = "100") then
      txd_int <= "0000" & txd_int(7 downto 4);
    end if;

    if (in_cke = '1') then
      txctrl <= txen_reg;
    end if;

  end if;
end process;

txd <= txd_int;

--------------------------------------------------------------------------------
-- Create the 125Mhz and 25Mhz transmit clocks
--------------------------------------------------------------------------------
oddr_tx : oddr
generic map (
  DDR_CLK_EDGE => "OPPOSITE_EDGE",
  INIT         => '0',    -- Sets initial state of the Q output to 1'b0 or 1'b1
  SRTYPE       => "SYNC"  -- Specifies "SYNC" or "ASYNC" set/reset
)
port map (
  q  => txc,     -- 1-bit ddr output data
  c  => clk125,  -- 1-bit clock input
  ce => '1',     -- 1-bit clock enable input
  d1 => '1',     -- 1-bit data input (associated with c0)
  d2 => '0',     -- 1-bit data input (associated with c1)
  r  => '0',     -- 1-bit reset input
  s  => '0'      -- 1-bit set input
);

--------------------------------------------------------------------------------
-- End
--------------------------------------------------------------------------------

end gmii_eth_tx_stream_syn;
