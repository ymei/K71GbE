----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:32:46 06/20/2014
-- Design Name: 
-- Module Name:    channel_sel - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
LIBRARY UNISIM;
USE UNISIM.VComponents.ALL;

ENTITY channel_sel IS
  GENERIC (
    CHANNEL_WIDTH : positive := 16;
    INDATA_WIDTH  : positive := 256;
    OUTDATA_WIDTH : positive := 256
  );
  PORT (
    CLK             : IN  std_logic;    -- fifo wrclk
    RESET           : IN  std_logic;
    SEL             : IN  std_logic_vector(7 DOWNTO 0);
    --
    DATA_FIFO_RESET : IN  std_logic;
    --
    INDATA_Q        : IN  std_logic_vector(INDATA_WIDTH-1 DOWNTO 0);    
    DATA_FIFO_WREN  : IN  std_logic;
    DATA_FIFO_FULL  : OUT std_logic;
    --
    OUTDATA_FIFO_Q  : OUT std_logic_vector(OUTDATA_WIDTH-1 DOWNTO 0);
    DATA_FIFO_RDEN  : IN  std_logic;
    DATA_FIFO_EMPTY : OUT std_logic
  );
END channel_sel;

ARCHITECTURE Behavioral OF channel_sel IS

  COMPONENT fifo16to64                 -- FWFT
    PORT (
      RST    : IN  std_logic;
      WR_CLK : IN  std_logic;
      RD_CLK : IN  std_logic;
      DIN    : IN  std_logic_vector(15 DOWNTO 0);
      WR_EN  : IN  std_logic;
      RD_EN  : IN  std_logic;
      DOUT   : OUT std_logic_vector(63 DOWNTO 0);
      FULL   : OUT std_logic;
      EMPTY  : OUT std_logic
    );
  END COMPONENT;
  COMPONENT fifo64to256                 -- FWFT
    PORT (
      RST    : IN  std_logic;
      WR_CLK : IN  std_logic;
      RD_CLK : IN  std_logic;
      DIN    : IN  std_logic_vector(63 DOWNTO 0);
      WR_EN  : IN  std_logic;
      RD_EN  : IN  std_logic;
      DOUT   : OUT std_logic_vector(OUTDATA_WIDTH-1 DOWNTO 0);
      FULL   : OUT std_logic;
      EMPTY  : OUT std_logic
    );
  END COMPONENT;
  COMPONENT fifo128to256                -- FWFT
    PORT (
      RST    : IN  std_logic;
      WR_CLK : IN  std_logic;
      RD_CLK : IN  std_logic;
      DIN    : IN  std_logic_vector(127 DOWNTO 0);
      WR_EN  : IN  std_logic;
      RD_EN  : IN  std_logic;
      DOUT   : OUT std_logic_vector(OUTDATA_WIDTH-1 DOWNTO 0);
      FULL   : OUT std_logic;
      EMPTY  : OUT std_logic
    );
  END COMPONENT;

  SIGNAL indata_q_i        : std_logic_vector(INDATA_WIDTH-1 DOWNTO 0);
  --
  SIGNAL fifo16_indata_q   : std_logic_vector(15 DOWNTO 0);
  SIGNAL fifo16_indata_q1  : std_logic_vector(63 DOWNTO 0);  
  SIGNAL fifo16_wren       : std_logic := '0';
  SIGNAL fifo16_wren1      : std_logic := '0';  
  SIGNAL fifo16_rden       : std_logic;
  SIGNAL fifo16_rden1      : std_logic;  
  SIGNAL fifo16_outdata_q  : std_logic_vector(OUTDATA_WIDTH-1 DOWNTO 0);
  SIGNAL fifo16_outdata_q1 : std_logic_vector(63 DOWNTO 0);
  SIGNAL fifo16_full       : std_logic;
  SIGNAL fifo16_full1      : std_logic;
  SIGNAL fifo16_empty      : std_logic;  
  SIGNAL fifo16_empty1     : std_logic;
  --
  SIGNAL fifo64_indata_q   : std_logic_vector(63 DOWNTO 0);
  SIGNAL fifo64_wren       : std_logic := '0';
  SIGNAL fifo64_rden       : std_logic;
  SIGNAL fifo64_outdata_q  : std_logic_vector(OUTDATA_WIDTH-1 DOWNTO 0);
  SIGNAL fifo64_full       : std_logic;
  SIGNAL fifo64_empty      : std_logic;
  --
  SIGNAL fifo128_indata_q  : std_logic_vector(127 DOWNTO 0);
  SIGNAL fifo128_wren      : std_logic := '0';
  SIGNAL fifo128_rden      : std_logic;
  SIGNAL fifo128_outdata_q : std_logic_vector(OUTDATA_WIDTH-1 DOWNTO 0);
  SIGNAL fifo128_full      : std_logic;
  SIGNAL fifo128_empty     : std_logic;

BEGIN

  -- 16 bit in 256 bit out FIFO, 2 glued together ---------------------------------------------
  fifo16 : fifo16to64                   -- FWFT
    PORT MAP (
      RST    => RESET OR DATA_FIFO_RESET,
      WR_CLK => CLK,
      RD_CLK => CLK,
      DIN    => fifo16_indata_q,
      WR_EN  => fifo16_wren,
      RD_EN  => fifo16_rden1,
      DOUT   => fifo16_outdata_q1,
      FULL   => fifo16_full,
      EMPTY  => fifo16_empty1
    );
  fifo16_64 : fifo64to256               -- FWFT
    PORT MAP (
      RST    => RESET OR DATA_FIFO_RESET,
      WR_CLK => CLK,
      RD_CLK => CLK,
      DIN    => fifo16_indata_q1,
      WR_EN  => fifo16_wren1,
      RD_EN  => fifo16_rden,
      DOUT   => fifo16_outdata_q,
      FULL   => fifo16_full1,
      EMPTY  => fifo16_empty
    );
  fifo16_indata_q1 <= fifo16_outdata_q1;
  fifo16_rden1     <= NOT fifo16_full1;
  fifo16_wren1     <= NOT fifo16_empty1;
  ---------------------------------------------------------------------------------------------
  
  fifo64 : fifo64to256                  -- FWFT
    PORT MAP (
      RST    => RESET OR DATA_FIFO_RESET,
      WR_CLK => CLK,
      RD_CLK => CLK,
      DIN    => fifo64_indata_q,
      WR_EN  => fifo64_wren,
      RD_EN  => fifo64_rden,
      DOUT   => fifo64_outdata_q,
      FULL   => fifo64_full,
      EMPTY  => fifo64_empty
    );

  fifo128 : fifo128to256                -- FWFT
    PORT MAP (
      RST    => RESET OR DATA_FIFO_RESET,
      WR_CLK => CLK,
      RD_CLK => CLK,
      DIN    => fifo128_indata_q,
      WR_EN  => fifo128_wren,
      RD_EN  => fifo128_rden,
      DOUT   => fifo128_outdata_q,
      FULL   => fifo128_full,
      EMPTY  => fifo128_empty
    );

  PROCESS (CLK) IS 
   VARIABLE i : integer;
   VARIABLE j : integer;
  BEGIN
    IF falling_edge(CLK) THEN  -- register half-cycle earlier
      -- swap for correct endian on x86 computer (through tcp core transmission)
      FOR i IN 0 TO 15 LOOP
        j := 15-i;
        indata_q_i(16*(i+1)-1 DOWNTO 16*i) <=
          INDATA_Q(16*j+7 DOWNTO 16*j) & INDATA_Q(16*j+15 DOWNTO 16*j+8);
      END LOOP;
    END IF;
  END PROCESS;

  PROCESS (SEL)
    VARIABLE offset : integer := 0;
  BEGIN 
    -- defaults
    fifo16_wren      <= '0';
    fifo16_rden      <= '0';    
    fifo64_wren      <= '0';
    fifo64_rden      <= '0';
    fifo128_wren     <= '0';
    fifo128_rden     <= '0';
    DATA_FIFO_FULL   <= '0';
    DATA_FIFO_EMPTY  <= '0';
    fifo16_indata_q  <= indata_q_i(INDATA_WIDTH-1 DOWNTO INDATA_WIDTH-1*CHANNEL_WIDTH);
    fifo64_indata_q  <= indata_q_i(INDATA_WIDTH-1 DOWNTO INDATA_WIDTH-4*CHANNEL_WIDTH);
    fifo128_indata_q <= indata_q_i(INDATA_WIDTH-1 DOWNTO INDATA_WIDTH-8*CHANNEL_WIDTH);
    OUTDATA_FIFO_Q   <= indata_q_i;
    CASE SEL(7 DOWNTO 4) IS
      WHEN "0000" =>                    -- 1 channel
        fifo16_wren     <= DATA_FIFO_WREN;
        fifo16_rden     <= DATA_FIFO_RDEN;
        DATA_FIFO_FULL  <= fifo16_full;
        DATA_FIFO_EMPTY <= fifo16_empty;
        offset          := to_integer(unsigned(SEL(3 DOWNTO 0)));
        fifo16_indata_q <= indata_q_i(INDATA_WIDTH-1-offset*CHANNEL_WIDTH DOWNTO
                                      INDATA_WIDTH-(offset+1)*CHANNEL_WIDTH);
        OUTDATA_FIFO_Q  <= fifo16_outdata_q;
      WHEN "0001" =>                    -- 4 channels
        fifo64_wren     <= DATA_FIFO_WREN;
        fifo64_rden     <= DATA_FIFO_RDEN;
        DATA_FIFO_FULL  <= fifo64_full;
        DATA_FIFO_EMPTY <= fifo64_empty;
        offset          := to_integer(unsigned(SEL(3 DOWNTO 0)));
        fifo64_indata_q <= indata_q_i(INDATA_WIDTH-1-offset*4*CHANNEL_WIDTH DOWNTO
                                      INDATA_WIDTH-(offset+1)*4*CHANNEL_WIDTH);
        OUTDATA_FIFO_Q  <= fifo64_outdata_q;
      WHEN "0010" =>                    -- 8 channels
        fifo128_wren <= DATA_FIFO_WREN;
        fifo128_rden <= DATA_FIFO_RDEN;
        DATA_FIFO_FULL  <= fifo128_full;
        DATA_FIFO_EMPTY <= fifo128_empty;
        IF SEL(3 DOWNTO 0) = "0001" THEN  -- high 8 channels
          fifo128_indata_q <= indata_q_i(8*CHANNEL_WIDTH-1 DOWNTO 0);
        ELSE                              -- low 8 channels
          fifo128_indata_q <= indata_q_i(INDATA_WIDTH-1 DOWNTO INDATA_WIDTH-8*CHANNEL_WIDTH);
        END IF;
        OUTDATA_FIFO_Q  <= fifo128_outdata_q;
      WHEN "0011" =>                    -- 16 channels
        OUTDATA_FIFO_Q  <= indata_q_i;
        DATA_FIFO_FULL  <= NOT DATA_FIFO_RDEN;
        DATA_FIFO_EMPTY <= NOT DATA_FIFO_WREN;
      WHEN OTHERS => NULL;
    END CASE;
  END PROCESS;

END Behavioral;
