-- Modified based on Eric Bainville, Mar 2013

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY uartio IS
  GENERIC (
    -- tick repetition frequency is (input freq) / (2**COUNTER_WIDTH / DIVISOR)
    COUNTER_WIDTH : positive := 16;
    DIVISOR       : positive := 1208
  );
  PORT (
    CLK   : IN std_logic;               -- clock
    RESET : IN std_logic;               -- reset

    -- Client interface
    RX_DATA : OUT std_logic_vector(7 DOWNTO 0);  -- received byte
    RX_RDY  : OUT std_logic;  -- validates received byte (1 system clock spike)
    TX_DATA : IN  std_logic_vector(7 DOWNTO 0);  -- byte to send
    TX_EN   : IN  std_logic;  -- validates byte to send if tx_rdy is '1'
    TX_RDY  : OUT std_logic;  -- if '1', we can send a new byte, otherwise we won't take it

    -- Physical interface
    RX_PIN : IN  std_logic;
    TX_PIN : OUT std_logic
  );
END uartio;

ARCHITECTURE Behavioral OF uartio IS
  COMPONENT tickgen
    GENERIC (
      -- tick repetition frequency is (input freq) / (2**COUNTER_WIDTH / DIVISOR)
      COUNTER_WIDTH : positive;
      DIVISOR       : positive
    );
    PORT (
      CLK      : IN  std_logic;
      RESET    : IN  std_logic;
      TICK     : OUT std_logic;
      TICK1CLK : OUT std_logic
    );
  END COMPONENT;
--  CONSTANT COUNTER_BITS : natural := integer(ceil(log2(real(DIVISOR))));
  TYPE fsm_state_t IS (idle, active);   -- common to both RX and TX FSM
  TYPE rx_state_t IS
  RECORD
    fsm_state : fsm_state_t;            -- FSM state
    counter   : unsigned(3 DOWNTO 0);   -- tick count
    bits      : std_logic_vector(7 DOWNTO 0);  -- received bits
    nbits     : unsigned(3 DOWNTO 0);  -- number of received bits (includes start bit)
    enable    : std_logic;              -- signal we received a new byte
  END RECORD;
  TYPE tx_state_t IS
  RECORD
    fsm_state : fsm_state_t;            -- FSM state
    counter   : unsigned(3 DOWNTO 0);   -- tick count
    bits      : std_logic_vector(8 DOWNTO 0);  -- bits to emit, includes start bit
    nbits     : unsigned(3 DOWNTO 0);   -- number of bits left to send
    ready     : std_logic;              -- signal we are accepting a new byte
  END RECORD;

  SIGNAL rx_state, rx_state_next : rx_state_t;
  SIGNAL tx_state, tx_state_next : tx_state_t;
  SIGNAL sample                  : std_logic;  -- 1 clk spike at 16x baud rate
  
BEGIN

  tickgen_inst : tickgen
    GENERIC MAP (
      -- tick repetition frequency is (input freq) / (2**COUNTER_WIDTH / DIVISOR)
      COUNTER_WIDTH => COUNTER_WIDTH,
      DIVISOR       => DIVISOR
    )
    PORT MAP (
      CLK      => CLK,
      RESET    => RESET,
      TICK     => OPEN,
      TICK1CLK => sample
    );

  -- RX, TX state registers update at each CLK, and RESET
  reg_process : PROCESS (CLK, RESET) IS
  BEGIN
    IF RESET = '1' THEN
      rx_state.fsm_state <= idle;
      rx_state.bits      <= (OTHERS => '0');
      rx_state.nbits     <= (OTHERS => '0');
      rx_state.enable    <= '0';
      tx_state.fsm_state <= idle;
      tx_state.bits      <= (OTHERS => '1');
      tx_state.nbits     <= (OTHERS => '0');
      tx_state.ready     <= '1';
    ELSIF rising_edge(CLK) THEN
      rx_state <= rx_state_next;
      tx_state <= tx_state_next;
    END IF;
  END PROCESS;

  -- RX FSM
  rx_process : PROCESS (rx_state, sample, RX_PIN) IS
  BEGIN
    CASE rx_state.fsm_state IS

      WHEN idle =>
        rx_state_next.counter <= (OTHERS => '0');
        rx_state_next.bits    <= (OTHERS => '0');
        rx_state_next.nbits   <= (OTHERS => '0');
        rx_state_next.enable  <= '0';
        IF RX_PIN = '0' THEN
          -- start a new byte
          rx_state_next.fsm_state <= active;
        ELSE
          -- keep idle
          rx_state_next.fsm_state <= idle;
        END IF;

      WHEN active =>
        rx_state_next <= rx_state;
        IF sample = '1' THEN
          IF rx_state.counter = 8 THEN
            -- sample next RX bit (at the middle of the counter cycle)
            IF rx_state.nbits = 9 THEN
              rx_state_next.fsm_state <= idle;  -- back to idle state to wait for next start bit
              rx_state_next.enable    <= RX_PIN;  -- OK if stop bit is '1'
            ELSE
              rx_state_next.bits  <= RX_PIN & rx_state.bits(7 DOWNTO 1);
              rx_state_next.nbits <= rx_state.nbits + 1;
            END IF;
          END IF;
          rx_state_next.counter <= rx_state.counter + 1;
        END IF;

    END CASE;
  END PROCESS;

  -- RX output
  rx_output : PROCESS (rx_state) IS
  BEGIN
    RX_DATA <= rx_state.bits;    
    RX_RDY  <= rx_state.enable;
  END PROCESS;

  -- TX FSM
  tx_process : PROCESS (tx_state, sample, TX_EN) IS
  BEGIN
    CASE tx_state.fsm_state IS

      WHEN idle =>
        IF TX_EN = '1' THEN
          -- start a new bit
          tx_state_next.bits      <= TX_DATA & '0';  -- data & start
          tx_state_next.nbits     <= x"a";  -- send 10 bits (includes '1' stop bit)
          tx_state_next.counter   <= (OTHERS => '0');
          tx_state_next.fsm_state <= active;
          tx_state_next.ready     <= '0';
        ELSE
          -- keep idle
          tx_state_next.bits      <= (OTHERS => '1');
          tx_state_next.nbits     <= (OTHERS => '0');
          tx_state_next.counter   <= (OTHERS => '0');
          tx_state_next.fsm_state <= idle;
          tx_state_next.ready     <= '1';
        END IF;

      WHEN active =>
        tx_state_next <= tx_state;
        IF sample = '1' THEN
          IF tx_state.counter = 15 THEN
            -- send next bit
            IF tx_state.nbits = 0 THEN
              -- turn idle
              tx_state_next.bits      <= (OTHERS => '1');
              tx_state_next.nbits     <= (OTHERS => '0');
              tx_state_next.counter   <= (OTHERS => '0');
              tx_state_next.fsm_state <= idle;
              tx_state_next.ready     <= '1';
            ELSE
              tx_state_next.bits  <= '1' & tx_state.bits(8 DOWNTO 1);
              tx_state_next.nbits <= tx_state.nbits - 1;
            END IF;
          END IF;
          tx_state_next.counter <= tx_state.counter + 1;
        END IF;

    END CASE;
  END PROCESS;

  -- TX output
  tx_output : PROCESS (tx_state) IS
  BEGIN
    TX_RDY <= tx_state.ready;
    TX_PIN <= tx_state.bits(0);
  END PROCESS;

END Behavioral;
