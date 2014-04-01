----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Yuan Mei
-- 
-- Create Date:    23:56:58 10/26/2013 
-- Design Name:    Convert byte stream into command
-- Module Name:    byte2cmd - Behavioral 
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
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
LIBRARY UNISIM;
USE UNISIM.VComponents.ALL;

ENTITY byte2cmd IS
  PORT (
    CLK            : IN  std_logic;
    RESET          : IN  std_logic;
    -- byte in
    RX_DATA        : IN  std_logic_vector(7 DOWNTO 0);
    RX_RDY         : IN  std_logic;
    -- cmd out
    CMD_FIFO_Q     : OUT std_logic_vector(35 DOWNTO 0);  -- command fifo data out port
    CMD_FIFO_EMPTY : OUT std_logic;  -- command fifo "emtpy" SIGNAL
    CMD_FIFO_RDCLK : IN  std_logic;
    CMD_FIFO_RDREQ : IN  std_logic   -- command fifo read request
  );
END byte2cmd;

ARCHITECTURE Behavioral OF byte2cmd IS

  COMPONENT fifo36x512
    PORT (
      rst    : IN  std_logic;
      wr_clk : IN  std_logic;
      rd_clk : IN  std_logic;
      din    : IN  std_logic_vector(35 DOWNTO 0);
      wr_en  : IN  std_logic;
      rd_en  : IN  std_logic;
      dout   : OUT std_logic_vector(35 DOWNTO 0);
      full   : OUT std_logic;
      empty  : OUT std_logic
    );
  END COMPONENT;

  SIGNAL sCmdFifoWrClk : std_logic;
  SIGNAL sCmdFifoD     : std_logic_vector(39 DOWNTO 0);
  SIGNAL sCmdFifoWrreq : std_logic;
  SIGNAL sCmdFifoFull  : std_logic;
  SIGNAL sInByte       : std_logic_vector(7 DOWNTO 0);
  TYPE cmdState_t IS (S0, S1);
  SIGNAL cmdState      : cmdState_t;
BEGIN

  -- cmd FIFO
  sCmdFifoWrClk <= CLK;
  cmd_fifo : fifo36x512
    PORT MAP (
      rst    => RESET,
      wr_clk => sCmdFifoWrClk,
      rd_clk => CMD_FIFO_RDCLK,
      din    => sCmdFifoD(35 DOWNTO 0),
      wr_en  => sCmdFifoWrreq,
      rd_en  => CMD_FIFO_RDREQ,
      dout   => CMD_FIFO_Q,
      full   => sCmdFifoFull,
      empty  => CMD_FIFO_EMPTY
    );

  PROCESS (CLK, RESET) IS
    VARIABLE addri : integer RANGE 0 TO 7 :=0;
  BEGIN
    IF RESET = '1' THEN
      addri         := 0;
      sCmdFifoD     <= (OTHERS => '0');
      sCmdFifoWrreq <= '0';
      sInByte       <= x"ff";
      cmdState      <= S0;
    ELSIF falling_edge(CLK) THEN
      CASE cmdState IS
        WHEN S0 =>
          sCmdFifoWrreq <= '0';
          IF RX_RDY = '1' THEN
            sInByte <= RX_DATA;
            addri   := to_integer(unsigned(sInByte(7 DOWNTO 5)));
            sCmdFifoD((addri+1)*5-1 DOWNTO addri*5) <= sInByte(4 DOWNTO 0);
            IF addri = 0 THEN
              cmdState <= S1;
            END IF;
          END IF;
        WHEN S1 =>
          sCmdFifoWrreq <= '1';
          cmdState      <= S0;
        WHEN OTHERS =>
          cmdState <= S0;
      END CASE;
    END IF;
  END PROCESS;

END Behavioral;
