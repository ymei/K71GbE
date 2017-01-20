
library ieee;
  use ieee.std_logic_1164.all ;
  use ieee.std_logic_arith.all ;
  use ieee.std_logic_unsigned.all ;
  use ieee.std_logic_misc.all ;

entity i2c_master is
generic (
  START_ADDR      : std_logic_vector(27 downto 0) := x"0000000";
  STOP_ADDR       : std_logic_vector(27 downto 0) := x"000FFFF";
  PRER            : std_logic_vector(15 downto 0) := conv_std_logic_vector(4096,16);
  CTRL            : std_logic_vector(7 downto 0)  := conv_std_logic_vector(128,8)
);
port (
  -- Globals
  rst             : in  std_logic;
  clk             : in  std_logic;
  -- Command Interface
  clk_cmd         : in  std_logic;
  in_cmd_val      : in  std_logic;
  in_cmd          : in  std_logic_vector(63 downto 0);
  out_cmd_val     : out std_logic;
  out_cmd         : out std_logic_vector(63 downto 0);
  in_cmd_busy     : out std_logic;
  in_cmd_error    : out std_logic;
  -- I2C interface
  scl_pin         : inout std_logic;
  sda_pin         : inout std_logic
);
end i2c_master;

architecture i2c_master_syn of i2c_master is

-----------------------------------------------------------------------------------
-- Component declarations
-----------------------------------------------------------------------------------

component i2c_master_stellar_cmd is
generic
(
  START_ADDR           : std_logic_vector(27 downto 0) := x"0000000";
  STOP_ADDR            : std_logic_vector(27 downto 0) := x"00000FF"
);
port
(
  reset                : in  std_logic;
  -- Command Interface
  clk_cmd              : in  std_logic;                     --cmd_in and cmd_out are synchronous to this clock;
  out_cmd              : out std_logic_vector(63 downto 0);
  out_cmd_val          : out std_logic;
  in_cmd               : in  std_logic_vector(63 downto 0);
  in_cmd_val           : in  std_logic;
  -- Register interface
  clk_reg              : in  std_logic;                     --register interface is synchronous to this clock
  out_reg              : out std_logic_vector(31 downto 0); --caries the out register data
  out_reg_val          : out std_logic;                     --the out_reg has valid data  (pulse)
  out_reg_addr         : out std_logic_vector(27 downto 0); --out register address
  in_reg               : in  std_logic_vector(31 downto 0); --requested register data is placed on this bus
  in_reg_val           : in  std_logic;                     --pulse to indicate requested register is valid
  in_reg_req           : out std_logic;                     --pulse to request data
  in_reg_addr          : out std_logic_vector(27 downto 0);  --requested address
  --mailbox interface
  mbx_in_reg           : in  std_logic_vector(31 downto 0); --value of the mailbox to send
  mbx_in_val           : in  std_logic                      --pulse to indicate mailbox is valid
);
end component i2c_master_stellar_cmd;

component wb_i2c_ctrl
port (
  -- Wishbone signals
  wb_clk_i      : in  std_logic;                     -- master clock input
  wb_rst_i      : in  std_logic;                     -- synchronous active high reset
  wb_adr_o      : out std_logic_vector(3 downto 0);  -- lower address bits
  wb_dat_i      : in  std_logic_vector(7 downto 0);  -- databus input
  wb_dat_o      : out std_logic_vector(7 downto 0);  -- databus output
  wb_sel_o      : out std_logic_vector(3 downto 0);  -- byte select inputs
  wb_we_o       : out std_logic;                     -- write enable input
  wb_stb_o      : out std_logic;                     -- stobe/core select signal
  wb_cyc_o      : out std_logic;                     -- valid bus cycle input
  wb_ack_i      : in  std_logic;                     -- bus cycle acknowledge output
  wb_err_i      : in  std_logic;                     -- termination w/ error
  wb_int_i      : in  std_logic;                     -- interrupt request signal output

  PRER          : in  std_logic_vector(15 downto 0);
  CTRL          : in  std_logic_vector(7 downto 0);
  sl_adr        : in  std_logic_vector(7 downto 0);
  sub_adr       : in  std_logic_vector(7 downto 0);
  wr_data       : in  std_logic_vector(7 downto 0);

  read_req      : in  std_logic;
  init_req      : in  std_logic;
  transfer_req  : in  std_logic;
  sub_adr_req   : in  std_logic;

  busy          : out std_logic;
  transfer_done : out std_logic;
  init_done     : out std_logic;
  error         : out std_logic;
  rd_data       : out std_logic_vector(7 downto 0)
);
end component wb_i2c_ctrl;

component top_i2c
port(
  mp_test   : out    std_logic;
  arst_i    : in     std_logic;
  bus_free  : out    std_logic;
  clk       : in     std_logic;
  rst       : in     std_logic;
  scl2_pin  : inout  std_logic;
  scl_pin   : inout  std_logic;
  sda2_pin  : inout  std_logic;
  sda_pin   : inout  std_logic;
  wb_ack_o  : out    std_logic;
  wb_adr_i  : in     unsigned(2 downto 0);
  wb_clk_i  : in     std_logic;
  wb_cyc_i  : in     std_logic;
  wb_dat_i  : in     std_logic_vector(7 downto 0) ;
  wb_dat_o  : out    std_logic_vector(7 downto 0);
  wb_inta_o : out    std_logic;
  wb_rst_i  : in     std_logic;
  wb_stb_i  : in     std_logic;
  wb_we_i   : in     std_logic
);
end component;

-----------------------------------------------------------------------------------
-- Constant declarations
-----------------------------------------------------------------------------------

-----------------------------------------------------------------------------------
-- Signal declarations
-----------------------------------------------------------------------------------

signal out_reg_val    : std_logic;
signal out_reg_addr   : std_logic_vector(27 downto 0);
signal out_reg        : std_logic_vector(31 downto 0);

signal in_reg_req     : std_logic;
signal in_reg_addr    : std_logic_vector(27 downto 0);
signal in_reg_val     : std_logic;
signal in_reg         : std_logic_vector(31 downto 0);

signal i2c_start      : std_logic;
signal i2c_busy       : std_logic;

signal wb_rst_i       : std_logic;
signal wb_adr_o       : std_logic_vector(3 downto 0);
signal wb_dat_i       : std_logic_vector(7 downto 0);
signal wb_dat_o       : std_logic_vector(7 downto 0);
signal wb_sel_o       : std_logic_vector(3 downto 0);
signal wb_we_o        : std_logic;
signal wb_stb_o       : std_logic;
signal wb_cyc_o       : std_logic;
signal wb_ack_i       : std_logic;
signal wb_int_i       : std_logic;

signal adr_sig        : unsigned(2 downto 0);

signal done           : std_logic;
signal sl_adr         : std_logic_vector(7 downto 0);
signal sub_adr        : std_logic_vector(7 downto 0);
signal wr_data        : std_logic_vector(7 downto 0);
signal read_req       : std_logic;
signal transfer_req   : std_logic;
signal sub_adr_req    : std_logic;
signal start_received : std_logic;
signal busy           : std_logic;
signal transfer_done  : std_logic;
signal init_done      : std_logic;
signal error          : std_logic;
signal rd_data        : std_logic_vector(7 downto 0);

signal bus_free       : std_logic;
signal mp_test        : std_logic;

begin

--------------------------------------------------------------------------------
-- Synchronise reset input
--------------------------------------------------------------------------------

process (clk)
begin
  if (rising_edge(clk)) then

    wb_rst_i <= rst;

  end if;
end process;

----------------------------------------------------------------------------------------------------
-- Stellar Command Interface
----------------------------------------------------------------------------------------------------

i2c_master_stellar_cmd_inst : i2c_master_stellar_cmd
generic map
(
  START_ADDR   => START_ADDR,
  STOP_ADDR    => STOP_ADDR
)
port map
(
  reset        => rst,

  clk_cmd      => clk_cmd,
  in_cmd_val   => in_cmd_val,
  in_cmd       => in_cmd,
  out_cmd_val  => out_cmd_val,
  out_cmd      => out_cmd,

  clk_reg      => clk,
  out_reg_val  => out_reg_val,
  out_reg_addr => out_reg_addr,
  out_reg      => out_reg,

  in_reg_req   => in_reg_req,
  in_reg_addr  => in_reg_addr,
  in_reg_val   => in_reg_val,
  in_reg       => in_reg,

  mbx_in_val   => '0',
  mbx_in_reg   => (others => '0')
);

----------------------------------------------------------------------------------------------------
-- I2C control
----------------------------------------------------------------------------------------------------

wb_i2c_ctrl_inst : wb_i2c_ctrl
port map (
  wb_clk_i      => clk,--wb_clk_i,
  wb_rst_i      => wb_rst_i,
  wb_adr_o      => wb_adr_o,
  wb_dat_i      => wb_dat_i,
  wb_dat_o      => wb_dat_o,
  wb_sel_o      => wb_sel_o,
  wb_we_o       => wb_we_o,
  wb_stb_o      => wb_stb_o,
  wb_cyc_o      => wb_cyc_o,
  wb_ack_i      => wb_ack_i,
  wb_err_i      => '0',
  wb_int_i      => wb_int_i,
  PRER          => PRER,
  CTRL          => CTRL,
  sl_adr        => sl_adr,
  sub_adr       => sub_adr,
  wr_data       => wr_data,
  read_req      => read_req,
  init_req      => '0',
  transfer_req  => transfer_req,
  sub_adr_req   => sub_adr_req,
  busy          => busy,
  transfer_done => transfer_done,
  init_done     => init_done,
  error         => error,
  rd_data       => rd_data
);

adr_sig <= unsigned(wb_adr_o(2 downto 0));

----------------------------------------------------------------------------------------------------
-- I2C master
----------------------------------------------------------------------------------------------------

wb_i2c_master : top_i2c
port map (
  mp_test   => mp_test,
  arst_i    => wb_rst_i,
  bus_free  => bus_free,
  clk       => clk,
  rst       => wb_rst_i,
  scl2_pin  => open,
  scl_pin   => scl_pin,
  sda2_pin  => open,
  sda_pin   => sda_pin,
  wb_ack_o  => wb_ack_i,
  wb_adr_i  => adr_sig,
  wb_clk_i  => clk,
  wb_cyc_i  => wb_cyc_o,
  wb_dat_i  => wb_dat_o,
  wb_dat_o  => wb_dat_i,
  wb_inta_o => wb_int_i,
  wb_rst_i  => wb_rst_i,
  wb_stb_i  => wb_stb_o,
  wb_we_i   => wb_we_o
);

--------------------------------------------------------------------------------
-- Stellar registers
--------------------------------------------------------------------------------

process(clk, rst)
begin
  if (rst = '1') then

    i2c_start   <= '0';
    sl_adr      <= (others => '0');
    sub_adr     <= (others => '0');
    wr_data     <= (others => '0');
    sub_adr_req <= '0';
    read_req    <= '0';

  elsif(clk'event and clk = '1') then

    -- Write cycle
    if (i2c_busy = '0' and out_reg_val = '1') then
      i2c_start   <= '1';
      sl_adr      <= out_reg_addr(14 downto 8) & '0';
      sub_adr     <= out_reg_addr(7 downto 0);
      wr_data     <= out_reg(7 downto 0);
      sub_adr_req <= '1';
      read_req    <= '0';
    -- Read cycle
    elsif (i2c_busy = '0' and in_reg_req = '1') then
      i2c_start   <= '1';
      sl_adr      <= in_reg_addr(14 downto 8) & '0';
      sub_adr     <= in_reg_addr(7 downto 0);
      wr_data     <= wr_data;
      sub_adr_req <= '1';
      read_req    <= '1';
    -- Hold values
    else
      i2c_start   <= '0';
      sl_adr      <= sl_adr;
      sub_adr     <= sub_adr;
      wr_data     <= wr_data;
      sub_adr_req <= sub_adr_req;
      read_req    <= read_req;
    end if;

    -- Read cycle resonse
    if (read_req = '1' and transfer_done = '1') then
      in_reg_val <= '1';
      in_reg     <= x"000000" & rd_data;
    else
      in_reg_val <= '0';
      in_reg     <= in_reg;
    end if;


  end if;
end process;

--------------------------------------------------------------------------------
-- Start I2C Handshake
--------------------------------------------------------------------------------

process(clk, rst)
begin
  if (rst = '1') then

    start_received <= '0';
    transfer_req   <= '0';
    i2c_busy       <= '0';
    in_cmd_error   <= '0';
    in_cmd_busy    <= '0';

  elsif(clk'event and clk = '1') then

    -- We receive a pulse when we need to transmit some data using i2c
    if (i2c_start = '1') then
      start_received <= '1';
    elsif (busy = '0' and transfer_req = '1') then
      start_received <= '0';
    end if;

    if (busy = '0' and start_received = '1') then
      transfer_req <= '1';
    elsif (busy = '1') then
      transfer_req <= '0';
    end if;

    --we are busy as long as the i2c controller is busy
    if (busy = '0' and start_received = '1') then
      i2c_busy <= '1';
    elsif (transfer_done = '1') then
      i2c_busy <= '0';
    end if;

    in_cmd_error <= error;
    in_cmd_busy  <= i2c_busy;

  end if;
end process;


--------------------------------------------------------------------------------
-- End
--------------------------------------------------------------------------------

end i2c_master_syn;