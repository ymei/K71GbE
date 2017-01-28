--------------------------------------------------------------------------------
--! @file control_interface.vhd
--! @brief Control Interface
--! \verbatim
--! Author     : JS  <jschamba@physics.utexas.edu>
--! Company    : University of Texas at Austin
--! Created    : 2013-06-12
--! Last update: 2016-12-25
--! Description: Read words from command FIFO and interpret
--!              This defines some example interfaces at different addresses:
--!              Address 32 - 63:         16bit Configuration registers
--!                              These registers can be written and read.
--!                              Could be used to define operations parameters
--!              Address 11:             16bit Pulse REGISTER
--!                              This register generates a pulse at the bits
--!                              set to 1 that is 3 clocks wide
--!                              Could be used to start some action, e.g. jtag
--!              Address 0 - 10:        16bit Status registers
--!                              These are read-only.
--!                              Can be used to read the status of some external
--!                              device, .e.g an ADC, or input pins.
--!              Address 16 - 20:        32bit memory interface
--!                              The idea is to write an address into 17 (LSB)
--!                              and 18 (MSB)
--!                              Then write the LSB16 into 19, and finally
--!                              the  MSB16 into 20. On write to 20, the 32bit
--!                              data in 19 and 20 is written to the memory, AND
--!                              the address is auto-incremented, so that the NEXT
--!                              write seuqence doesn't need to re-write the address.
--!                              A Read on 20 reads the current address and returns
--!                              a 32bit data word into the FIFO, then increases
--!                              the memory. This read is repeated n times, where
--!                              "n" is the 16bit value at address 16.
--!              Address 25:     This address initiates a read from the DATA_FIFO
--!                              The value written `n' indicates the number of
--!                              words to copy from the DATA_FIFO to the FIFO.
--!                              Write `n' will result in n+1 words to be transferred.
--!                              Will wait indefinitely for all words to be transferred
--!                              should FIFOs stay in empty/full state.
--!
--! Revisions  :
--! Date        Version  Author          Description
--! 2013-06-12  1.0      jschamba        Created
--! 2013-10-21  1.1      thorsten        changed memory address space to 32 bit
--!                                      added an interface to read a data fifo
--! 2016-12-25           ymei            Adapt to FWFT FIFO
--! \endverbatim
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

--  Entity Declaration
ENTITY control_interface IS
  PORT (
    RESET           : IN  std_logic;
    CLK             : IN  std_logic;    -- system clock
    -- From FPGA to PC
    FIFO_Q          : OUT std_logic_vector(35 DOWNTO 0);  -- interface fifo data output port
    FIFO_EMPTY      : OUT std_logic;    -- interface fifo "emtpy" signal
    FIFO_RDREQ      : IN  std_logic;    -- interface fifo read request
    FIFO_RDCLK      : IN  std_logic;    -- interface fifo read clock
    -- From PC to FPGA, FWFT
    CMD_FIFO_Q      : IN  std_logic_vector(35 DOWNTO 0);  -- interface command fifo data out port
    CMD_FIFO_EMPTY  : IN  std_logic;    -- interface command fifo "emtpy" signal
    CMD_FIFO_RDREQ  : OUT std_logic;    -- interface command fifo read request
    -- Digital I/O
    CONFIG_REG      : OUT std_logic_vector(511 DOWNTO 0); -- thirtytwo 16bit registers
    PULSE_REG       : OUT std_logic_vector(15 DOWNTO 0);  -- 16bit pulse register
    STATUS_REG      : IN  std_logic_vector(175 DOWNTO 0); -- eleven 16bit registers
    -- Memory interface
    MEM_WE          : OUT std_logic;    -- memory write enable
    MEM_ADDR        : OUT std_logic_vector(31 DOWNTO 0);
    MEM_DIN         : OUT std_logic_vector(31 DOWNTO 0);  -- memory data input
    MEM_DOUT        : IN  std_logic_vector(31 DOWNTO 0);  -- memory data output
    -- Data FIFO interface, FWFT
    DATA_FIFO_Q     : IN  std_logic_vector(31 DOWNTO 0);
    DATA_FIFO_EMPTY : IN  std_logic;
    DATA_FIFO_RDREQ : OUT std_logic;
    DATA_FIFO_RDCLK : OUT std_logic
  );
END control_interface;

-- Architecture body
ARCHITECTURE a OF control_interface IS

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

  -- signals for FIFO
  SIGNAL bMemNotReg : integer;
  CONSTANT SEL_REG  : integer := 0;
  CONSTANT SEL_MEM  : integer := 1;
  CONSTANT SEL_FIFO : integer := 2;
  SIGNAL sFifoD     : std_logic_vector(35 DOWNTO 0);
  SIGNAL sFifoFull  : std_logic;
  SIGNAL sFifoWren  : std_logic;
  SIGNAL sFifoWrreq : std_logic;
  SIGNAL sFifoRst   : std_logic;
  SIGNAL sFifoClk   : std_logic;

  -- signals for single-port RAM
  SIGNAL sWea      : std_logic;
  SIGNAL sAddrA    : unsigned(31 DOWNTO 0);
  SIGNAL sDinA     : std_logic_vector(31 DOWNTO 0);
  SIGNAL sDoutA    : std_logic_vector(31 DOWNTO 0);
  SIGNAL sDinReg   : std_logic_vector(15 DOWNTO 0);
  SIGNAL sMemioCnt : std_logic_vector(15 DOWNTO 0);
  SIGNAL sMemLatch : std_logic_vector(31 DOWNTO 0);

  -- Configuration registers: 8 x 16bit
  SIGNAL sConfigReg : std_logic_vector(511 DOWNTO 0);
  SIGNAL sPulseReg  : std_logic_vector(15 DOWNTO 0);
  SIGNAL sRegOut    : std_logic_vector(15 DOWNTO 0);

  -- signals for FIFO read
  -- to read data from a FIFO
  SIGNAL sDataFifoCount : std_logic_vector(15 DOWNTO 0);

  -- State machine variable
  TYPE cmdState_t IS (
    INIT,
    WAIT_CMD,
    GET_CMD,
    INTERPRET_CMD,
    MEM_ADV,
    MEM_RD_CNT,
    PULSE_DELAY,
    FIFO_ADV
  );
  SIGNAL cmdState : cmdState_t;

BEGIN
  CONFIG_REG <= sConfigReg;
  PULSE_REG  <= sPulseReg;
  MEM_WE     <= sWea;
  MEM_ADDR   <= std_logic_vector(sAddrA);
  MEM_DIN    <= sDinA;
  sDoutA     <= MEM_DOUT;

  -- memory input
  sDinA(15 DOWNTO 0)  <= sDinReg;
  -- When FWFT FIFO is used, high 16 bits have to be registered by a cycled.
  PROCESS (CLK) IS
  BEGIN
    IF rising_edge(CLK) THEN
      sDinA(31 DOWNTO 16) <= CMD_FIFO_Q(15 DOWNTO 0);
    END IF;
  END PROCESS;

  -- data fifo
  DATA_FIFO_RDCLK <= CLK;

  -- data/event FIFO
  sFifoRst <= RESET;
  sFifoClk <= CLK;
  data_fifo : fifo36x512
    PORT MAP (
      rst    => sFifoRst,
      wr_clk => sFifoClk,
      rd_clk => FIFO_RDCLK,
      din    => sFifoD,
      wr_en  => sFifoWren,
      rd_en  => FIFO_RDREQ,
      dout   => FIFO_Q,
      full   => sFifoFull,
      empty  => FIFO_EMPTY
    );

  sFifoD(35 DOWNTO 32) <= (OTHERS => '0');  -- these bits not used
  sFifoD(31 DOWNTO 0)  <= MEM_DOUT WHEN bMemNotReg = SEL_MEM ELSE
                          DATA_FIFO_Q WHEN bMemNotReg = SEL_FIFO ELSE
                          x"0000" & sRegOut;
  sFifoWren            <= (NOT DATA_FIFO_EMPTY) WHEN bMemNotReg = SEL_FIFO
                          ELSE sFifoWrreq;
  DATA_FIFO_RDREQ      <= (NOT sFifoFull)       WHEN bMemNotReg = SEL_FIFO
                          ELSE '0';

  cmdIF_inst : PROCESS (CLK, RESET) IS
    VARIABLE counterV    : integer RANGE 0 TO 65535 := 0;
    VARIABLE address_i   : integer RANGE 0 TO 4095  := 0;
    VARIABLE counterFIFO : integer RANGE 0 TO 65535 := 0;
  BEGIN
    IF RESET = '1' THEN
      counterV       := 0;
      cmdState       <= INIT;
      CMD_FIFO_RDREQ <= '0';
      sConfigReg     <= (OTHERS => '0');
      sPulseReg      <= (OTHERS => '0');
      sDinReg        <= (OTHERS => '0');
      sMemioCnt      <= (OTHERS => '0');
      sWea           <= '0';
      sAddrA         <= (OTHERS => '0');
      bMemNotReg     <= SEL_REG;

    ELSIF rising_edge(CLK) THEN
      -- defaults:
      CMD_FIFO_RDREQ <= '0';
      sFifoWrreq     <= '0';
      sWea           <= '0';
      sRegOut        <= (OTHERS => '0');

      CASE cmdState IS
--      //// initialize registers to some sensible values
        WHEN INIT =>
          -- currently all 0
          sConfigReg <= (OTHERS => '0');
          sPulseReg  <= (OTHERS => '0');
          sAddrA     <= (OTHERS => '0');
          -- at least 1 memory read
          sMemioCnt  <= x"0001";
          cmdState   <= WAIT_CMD;

--      //// Wait for CMD_FIFO words
        WHEN WAIT_CMD =>
          bMemNotReg <= SEL_REG;          -- output registers
          sPulseReg  <= (OTHERS => '0');  -- reset pulse REGISTER
          -- wait for FIFO not empty
          IF CMD_FIFO_EMPTY = '0' THEN
            CMD_FIFO_RDREQ <= '1';
            cmdState       <= INTERPRET_CMD; -- GET_CMD;
          END IF;

--      //// one wait state to get next CMD_FIFO word
        -- When FWFT FIFO is used, this state should be skipped.
        -- WHEN GET_CMD =>
        --   cmdState <= INTERPRET_CMD;

--      //// Now interpret the current CMD_FIFO output
        WHEN INTERPRET_CMD =>
          ---------------------------------------------------------------------
          -- CMD_FIFO_Q format:
          -- Q(31)      : READ/NOT_WRITE
          -- Q(30:28)   : not used
          -- Q(27:16)   : ADDRESS
          -- Q(15:0)    : DATA
          ---------------------------------------------------------------------
          --address_i := conv_integer(unsigned(CMD_FIFO_Q(27 DOWNTO 16)));
          address_i := to_integer(unsigned(CMD_FIFO_Q(27 DOWNTO 16)));
          IF CMD_FIFO_Q(31) = '1' THEN
            -- //// a READ transaction ////////
            CASE address_i IS
              WHEN 32 TO 63 =>          -- CONFIG_REG
                sRegOut <= sConfigReg((address_i-32)*16+15 DOWNTO
                                      (address_i-32)*16);
                sFifoWrreq <= '1';
                cmdState   <= WAIT_CMD;

              WHEN 0 TO 10 =>           -- STATUS_REG
                sRegOut    <= STATUS_REG(address_i*16+15 DOWNTO address_i*16);
                sFifoWrreq <= '1';
                cmdState   <= WAIT_CMD;

              WHEN 16 =>                -- memory count REGISTER
                sRegOut    <= sMemioCnt;
                sFifoWrreq <= '1';
                cmdState   <= WAIT_CMD;

              WHEN 17 =>                -- memory address LSB REGISTER
                sRegOut    <= std_logic_vector(sAddrA (15 DOWNTO 0));
                sFifoWrreq <= '1';
                cmdState   <= WAIT_CMD;

              WHEN 18 =>                -- memory address MSB REGISTER
                sRegOut    <= std_logic_vector(sAddrA (31 DOWNTO 16));
                sFifoWrreq <= '1';
                cmdState   <= WAIT_CMD;

              WHEN 20 =>                -- read sMemioCnt 32bit memory words
                -- reads 32bit memory words starting at the current
                -- address sAddrA
                counterV   := to_integer(unsigned(sMemioCnt));
                bMemNotReg <= SEL_MEM;  -- switch FIFO input to memory output
                IF sFifoFull = '0' THEN
                  sFifoWrreq <= '1';    -- latch current memory output
                  sAddrA     <= sAddrA + 1;  -- and advance the address
                  cmdState   <= MEM_RD_CNT;
                END IF;

              WHEN OTHERS =>            -- bad address, return FFFF
                sRegOut    <= (OTHERS => '1');
                sFifoWrreq <= '1';
                cmdState   <= WAIT_CMD;
            END CASE;

          ELSE
            -- //// a WRITE transaction ////////
            CASE address_i IS
              WHEN 32 TO 63 =>          -- CONFIG_REG
                sConfigReg((address_i-32)*16+15 DOWNTO
                           (address_i-32)*16) <= CMD_FIFO_Q(15 DOWNTO 0);
                cmdState <= WAIT_CMD;

              WHEN 11 =>                -- PULSE_REG
                sPulseReg <= CMD_FIFO_Q(15 DOWNTO 0);
                counterV  := 2;         -- 60ns
                cmdState  <= PULSE_DELAY;

              WHEN 16 =>                -- memory count REGISTER
                sMemioCnt <= CMD_FIFO_Q(15 DOWNTO 0);
                cmdState  <= WAIT_CMD;

              WHEN 17 =>                -- memory address LSB REGISTER
                sAddrA (15 DOWNTO 0) <= unsigned(CMD_FIFO_Q(15 DOWNTO 0));
                cmdState             <= WAIT_CMD;

              WHEN 18 =>                -- memory address MSB REGISTER
                --sAddrA   <= CMD_FIFO_Q(15 DOWNTO 0);
                sAddrA (31 DOWNTO 16) <= unsigned(CMD_FIFO_Q(15 DOWNTO 0));
                cmdState              <= WAIT_CMD;

              WHEN 19 =>                -- memory LS16B
                sDinReg  <= CMD_FIFO_Q(15 DOWNTO 0);
                cmdState <= WAIT_CMD;

              WHEN 20 =>                -- memory MS16B
                -- raise WriteEnable for one clock, which clocks IN
                -- register 18 as LS16B and the data content of
                -- the CMD_FIFO word as MS16B
                sWea     <= '1';
                cmdState <= MEM_ADV;

              WHEN 25 =>                -- Data Fifo read count
                counterFIFO := to_integer(unsigned(CMD_FIFO_Q(15 DOWNTO 0)));
                bMemNotReg  <= SEL_FIFO;
                cmdState    <= FIFO_ADV;

              WHEN OTHERS =>            -- bad address, do nothing
                cmdState <= WAIT_CMD;
            END CASE;
          END IF;

--      //// advance memory address
        WHEN MEM_ADV =>
          sAddrA   <= sAddrA + 1;
          cmdState <= WAIT_CMD;

--      //// read sMemioCnt memory addresses
        WHEN MEM_RD_CNT =>
          counterV := counterV - 1;
          -- wait for FIFO not FULL
          IF (counterV = 0) THEN
            -- Done
            cmdState <= WAIT_CMD;
          ELSIF sFifoFull = '0' THEN
            -- latch current memory output
            sFifoWrreq <= '1';
            -- and advance address
            sAddrA     <= sAddrA + 1;
            cmdState   <= MEM_RD_CNT;
          ELSE
            -- FIFO Full:
            -- go back to previous count and wait for FIFO not full
            counterV := counterV + 1;
            cmdState <= MEM_RD_CNT;
          END IF;

--      //// delay two clocks to keep pulse high (total 3 clocks)
        WHEN PULSE_DELAY =>
          counterV := counterV - 1;
          IF (counterV = 0) THEN
            cmdState <= WAIT_CMD;
          END IF;

--      //// Data FIFO read
        WHEN FIFO_ADV =>
          -- read data fifo, write reads to output fifo
          -- exit when enough words were transferred
          bMemNotReg <= SEL_FIFO;
          cmdState   <= FIFO_ADV;
          IF (DATA_FIFO_EMPTY = '0') AND (sFifoFull = '0') THEN
            IF counterFIFO = 0 THEN
              -- we are done.
              bMemNotReg <= SEL_REG;
              cmdState   <= WAIT_CMD;
            ELSE
              -- reduce the counter.
              counterFIFO := counterFIFO - 1;
            END IF;
          END IF;

--      //// shouldn't happen
        WHEN OTHERS =>
          cmdState <= WAIT_CMD;
      END CASE;

    END IF;
  END PROCESS cmdIF_inst;

END a;
