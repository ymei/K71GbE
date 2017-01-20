------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_misc.all;
  use ieee.numeric_std.all;
library unisim;
  use unisim.vcomponents.all;

entity serdes is
generic (
  SYS_W                 : integer := 10; -- width of the data for the system
  DEV_W                 : integer := 80  -- width of the data for the device
);
port (
  -- From the system into the device
  data_in_from_pins_p   : in    std_logic_vector(SYS_W-1 downto 0);
  data_in_from_pins_n   : in    std_logic_vector(SYS_W-1 downto 0);
  data_in_to_device     : out   std_logic_vector(DEV_W-1 downto 0);
  -- Input, Output delay control signals
  rst_cmd               : in    std_logic;
  clk_cmd               : in    std_logic;
  start_align           : in    std_logic;                            -- start automatic alignment, test pattern should be tuned on
  data_aligned_out      : out   std_logic_vector(SYS_W-1 downto 0);   -- automatic alignment ready flags
  data_aligned          : out   std_logic;                            -- automatic alignment ready flag (and function)
  delay_reset           : in    std_logic;                            -- active high synchronous reset for input delay
  delay_valid_inc       : in    std_logic;                            --
  delay_data_inc        : in    std_logic_vector(SYS_W-1 downto 0);   -- delay increment
  delay_valid_dec       : in    std_logic;                            --
  delay_data_dec        : in    std_logic_vector(SYS_W-1 downto 0);   -- delay decrement
  delay_value           : out   std_logic_vector(5*SYS_W-1 downto 0); -- automatic alignment ready flags
  bitslip_val           : in    std_logic;                            -- bitslip module is enabled in networking mode, user should tie it to '0' if not needed
  bitslip               : in    std_logic_vector(SYS_W-1 downto 0);   -- bitslip module is enabled in networking mode, user should tie it to '0' if not needed
  -- Clock and reset signals
  clk_div               : in    std_logic;                            -- slow clock
  clk_in_int_buf        : in    std_logic;                            -- fast clock
  clk_in_int_inv        : in    std_logic;                            -- fast clock inverted
  io_reset              : in    std_logic                             -- reset signal for io circuit
);
end serdes;

architecture serdes_arch of serdes is

----------------------------------------------------------------------------------------------------
-- Component declaration
----------------------------------------------------------------------------------------------------
component bit_align_machine is
generic (
  WIDTH        : integer := 8;
  PATTERN      : std_logic_vector(7 downto 0)
);
port (
  rst          : in  std_logic;                      -- reset all circuitry in machine
  clk          : in  std_logic;                      -- rx parallel side clock
  data         : in  std_logic_vector(WIDTH-1 downto 0);  -- data from one channel only
  ce           : out std_logic;                      -- machine issues delay decrement to appropriate data channel
  inc          : out std_logic;                      -- machine issues delay increment to appropriate data channel
  bitslip      : out std_logic;                      -- machine issues bitslip command to appropriate data channel
  start_align  : in  std_logic;                      -- pulse to start alignment
  data_aligned : out std_logic                       -- flag indicating alignment complete on this channel
);
end component bit_align_machine;

component pulse2pulse is
port (
  in_clk   : in  std_logic;
  out_clk  : in  std_logic;
  rst      : in  std_logic;
  pulsein  : in  std_logic;
  inbusy   : out std_logic;
  pulseout : out std_logic
);
end component pulse2pulse;

----------------------------------------------------------------------------------------------------
-- Constant declaration
----------------------------------------------------------------------------------------------------
constant SER_W        : integer := DEV_W/SYS_W;
constant IDELAY_VALUE : integer := 0; -- initial delay value between 0 and 31

----------------------------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------------------------
signal data_in_from_pins_int     : std_logic_vector(SYS_W-1 downto 0);
signal data_in_from_pins_delay   : std_logic_vector(SYS_W-1 downto 0);

signal delay_valid_inc_int       : std_logic;
signal delay_valid_dec_int       : std_logic;

signal delay_ce                  : std_logic_vector(SYS_W-1 downto 0);
signal delay_inc                 : std_logic_vector(SYS_W-1 downto 0);

signal delay_ce_int              : std_logic_vector(SYS_W-1 downto 0) := (others => '0');
signal delay_inc_int             : std_logic_vector(SYS_W-1 downto 0) := (others => '0');

signal bitslip_align             : std_logic_vector(SYS_W-1 downto 0) := (others => '0');
signal bitslip_int               : std_logic_vector(SYS_W-1 downto 0) := (others => '0');
signal bitslip_val_int           : std_logic;

signal start_align_int           : std_logic;

signal io_reset_int              : std_logic;
signal delay_reset_int           : std_logic;
signal data_aligned_int          : std_logic_vector(SYS_W-1 downto 0) := (others => '0');

type serdes_array is array (0 to SYS_W-1) of std_logic_vector(SER_W-1 downto 0);
signal iserdes_q                 : serdes_array := (( others => (others => '0')));
signal icascade1                 : std_logic_vector(SYS_W-1 downto 0);
signal icascade2                 : std_logic_vector(SYS_W-1 downto 0);

begin

pulse2pulse_io_reset : pulse2pulse
port map (
  in_clk   => clk_cmd,
  out_clk  => clk_div,
  rst      => rst_cmd,
  pulsein  => io_reset,
  inbusy   => open,
  pulseout => io_reset_int
);

pulse2pulse_delay_reset : pulse2pulse
port map (
  in_clk   => clk_cmd,
  out_clk  => clk_div,
  rst      => rst_cmd,
  pulsein  => delay_reset,
  inbusy   => open,
  pulseout => delay_reset_int
);

pulse2pulse_sync : pulse2pulse
port map (
  in_clk   => clk_cmd,
  out_clk  => clk_div,
  rst      => rst_cmd,
  pulsein  => start_align,
  inbusy   => open,
  pulseout => start_align_int
);

alignment: for i in 0 to SYS_W-1 generate

  bit_align_machine_master : bit_align_machine
  generic map (
    WIDTH        => SER_W,
    PATTERN      => x"F0"
  )
  port map (
    rst          => io_reset_int,
    clk          => clk_div,
    data         => iserdes_q(i)(SER_W-1 downto 0),
    ce           => delay_ce_int(i),
    inc          => delay_inc_int(i),
    bitslip      => bitslip_align(i),
    start_align  => start_align_int,
    data_aligned => data_aligned_int(i)
  );

end generate;

pulse2pulse_delay_inc : pulse2pulse
port map (
  in_clk   => clk_cmd,
  out_clk  => clk_div,
  rst      => rst_cmd,
  pulsein  => delay_valid_inc,
  inbusy   => open,
  pulseout => delay_valid_inc_int
);

pulse2pulse_delay_dec : pulse2pulse
port map (
  in_clk   => clk_cmd,
  out_clk  => clk_div,
  rst      => rst_cmd,
  pulsein  => delay_valid_dec,
  inbusy   => open,
  pulseout => delay_valid_dec_int
);

delay_ce     <= delay_data_inc when delay_valid_inc_int = '1' else
                delay_data_dec when delay_valid_dec_int = '1' else delay_ce_int;
delay_inc    <= (others=> '1') when delay_valid_inc_int = '1' else
                (others=> '0') when delay_valid_dec_int = '1' else delay_inc_int;

pulse2pulse_bitslip : pulse2pulse
port map (
  in_clk   => clk_cmd,
  out_clk  => clk_div,
  rst      => rst_cmd,
  pulsein  => bitslip_val,
  inbusy   => open,
  pulseout => bitslip_val_int
);

--bitslip_int  <= bitslip_align or bitslip;
bitslip_gen: for i in 0 to bitslip_int'length-1 generate
  bitslip_int(i) <= bitslip_align(i) or (bitslip(i) and bitslip_val_int);
end generate;

data_aligned_out <= data_aligned_int;
data_aligned     <= and_reduce(data_aligned_int);

-- We have multiple bits - step over every bit, instantiating the required elements
pins: for pin_count in 0 to SYS_W-1 generate

  -- Instantiate a buffer for every bit of the data bus
  ibufds_inst : IBUFDS
  generic map (
    DIFF_TERM  => TRUE,             -- Differential termination
    IOSTANDARD => "LVDS_25"
  )
  port map (
    i          => data_in_from_pins_p(pin_count),
    ib         => data_in_from_pins_n(pin_count),
    o          => data_in_from_pins_int(pin_count)
  );

  -- Instantiate the delay primitive
     iodelay_bus : IDELAYE2
       generic map (
         CINVCTRL_SEL           => "FALSE",            -- TRUE, FALSE
         DELAY_SRC              => "IDATAIN",        -- IDATAIN, DATAIN
         HIGH_PERFORMANCE_MODE  => "TRUE",             -- TRUE, FALSE
         IDELAY_TYPE            => "VARIABLE",          -- FIXED, VARIABLE, or VAR_LOADABLE
         IDELAY_VALUE           => IDELAY_VALUE,                -- 0 to 31
         REFCLK_FREQUENCY       => 200.0,
         PIPE_SEL               => "FALSE",
         SIGNAL_PATTERN         => "DATA"           -- CLOCK, DATA
         )
         port map (
         DATAOUT                => data_in_from_pins_delay(pin_count),
         DATAIN                 => '0', -- Data from FPGA logic
         C                      => clk_div,
         CE                     => delay_ce(pin_count),
         INC                    => delay_inc(pin_count),
         IDATAIN                => data_in_from_pins_int  (pin_count), -- Driven by IOB
         LD                     => delay_reset_int,
         REGRST                 => delay_reset_int,
         LDPIPEEN               => '0',
         CNTVALUEIN             => "00000",
         CNTVALUEOUT            => delay_value(5*pin_count+4 downto 5*pin_count),
         CINVCTRL               => '0'
         );

  ----------------------------------------------------------------------------------------------------
  -- Instantiate the serdes primitive, master/slave serdes for 8x deserialisation
  ----------------------------------------------------------------------------------------------------
  serdes_w8: if SER_W = 8 generate
    iserdese1_master : ISERDESE2
    generic map (
      DATA_RATE         => "DDR",
      DATA_WIDTH        => 8,
      INTERFACE_TYPE    => "NETWORKING",
      DYN_CLKDIV_INV_EN => "FALSE",
      DYN_CLK_INV_EN    => "FALSE",
      NUM_CE            => 2,
      OFB_USED          => "FALSE",
      IOBDELAY          => "IFD",                              -- Use input at DDLY to output the data on Q1-Q6
      SERDES_MODE       => "MASTER"
    )
    port map (
      Q1                => iserdes_q(pin_count)(0),
      Q2                => iserdes_q(pin_count)(1),
      Q3                => iserdes_q(pin_count)(2),
      Q4                => iserdes_q(pin_count)(3),
      Q5                => iserdes_q(pin_count)(4),
      Q6                => iserdes_q(pin_count)(5),
      Q7                => iserdes_q(pin_count)(6),
      Q8                => iserdes_q(pin_count)(7),
      SHIFTOUT1         => open,               -- Cascade connection to Slave ISERDES
      SHIFTOUT2         => open,               -- Cascade connection to Slave ISERDES
      BITSLIP           => bitslip_int(pin_count),             -- 1-bit Invoke Bitslip. This can be used with any
                                                               -- DATA_WIDTH, cascaded or not.
      CE1               => '1',                                -- 1-bit Clock enable input
      CE2               => '1',                                -- 1-bit Clock enable input
      CLK               => clk_in_int_buf,                     -- Fast Source Synchronous SERDES clock from BUFIO
      CLKB              => clk_in_int_inv,                     -- Locally inverted clock
      CLKDIV            => clk_div,                            -- Slow clock driven by BUFR
      CLKDIVP           => '0',
      D                 => '0',
      DDLY              => data_in_from_pins_delay(pin_count), -- 1-bit Input signal from IODELAYE1.
      RST               => io_reset_int,                       -- 1-bit Asynchronous reset only.
      SHIFTIN1          => '0',
      SHIFTIN2          => '0',
      -- unused connections
      DYNCLKDIVSEL      => '0',
      DYNCLKSEL         => '0',
      OFB               => '0',
      OCLK              => '0',
      OCLKB             => '0',
      O                 => open                                -- unregistered output of ISERDESE1
    );

  end generate;

end generate pins;

----------------------------------------------------------------------------------------------------
-- Reorder bits to one parallel bus
----------------------------------------------------------------------------------------------------
sys_bits: for p in 0 to SYS_W-1 generate --loop per pin

  ser_bits: for b in 0 to SER_W-1 generate --loop per bit

    data_in_to_device(p*SER_W+b) <= iserdes_q(p)(b);

  end generate ser_bits;

end generate sys_bits;

----------------------------------------------------------------------------------------------------
-- End
----------------------------------------------------------------------------------------------------
end serdes_arch;



