----------------------------------------------------------------------------------------------------
-- Summary:
--
-- The BIT_ALIGN_MACHINE module analyzes the data input of a single pair
-- to determine the optimal clock/data relationship for that pair.  By
-- changing the delay of the data with respect to the sampling clock,
-- the machine places the sampling point at the center of the data eye.
--
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Library declarations
----------------------------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;
library unisim;
  use unisim.vcomponents.all;

----------------------------------------------------------------------------------------------------
entity bit_align_machine is
generic (
  WIDTH        : integer := 8;
  PATTERN      : std_logic_vector(7 downto 0) := x"F0"
);
port (
  rst          : in  std_logic; -- reset all circuitry in machine
  clk          : in  std_logic; -- rx parallel side clock
  data         : in  std_logic_vector(WIDTH-1 downto 0);  -- data from one channel only
  ce           : out std_logic; -- machine issues delay decrement to appropriate data channel
  inc          : out std_logic; -- machine issues delay increment to appropriate data channel
  bitslip      : out std_logic; -- machine issues bitslip command to appropriate data channel
  start_align  : in  std_logic; -- pulse to start alignment
  data_aligned : out std_logic -- flag indicating alignment complete on this channel
);
end bit_align_machine;

architecture bit_align_machine_syn of bit_align_machine is

constant CNT_MAX : integer := 64;

type align_sm_states is (
  idle,

  wait_1st_edge,
  find_1st_edge,
  inc_1st_edge,
  found_1st_edge,

  wait_2nd_edge,
  find_2nd_edge,
  inc_2nd_edge,
  found_2nd_edge,

  wait_mid,
  find_mid,
  dec_mid,
  found_mid,

  wait_bit_slip,
  bit_slip,
  bit_slip_done
);

signal align_sm : align_sm_states;
signal align_sm_prev : align_sm_states;
signal cnt : integer range 0 to 2*CNT_MAX-1;
signal window_cnt: integer range 0 to 31;

signal data_prev : std_logic_vector(WIDTH-1 downto 0);
signal edgeflag : std_logic;
signal aligned_to_pattern : std_logic;

signal incr : std_logic;
signal decr : std_logic;

begin

----------------------------------------------------------------------------------------------------
-- Main state machine
----------------------------------------------------------------------------------------------------
process (rst, clk)
begin
  if (rst = '1') then

    align_sm <= idle;
    align_sm_prev <= idle;

  elsif (rising_edge(clk)) then

    if (start_align = '1') then

      align_sm <= wait_1st_edge;

    else

      align_sm_prev <= align_sm;

      case align_sm is

        when idle =>
          align_sm <= idle;

        when wait_1st_edge =>
          if (cnt = CNT_MAX-1) then
            align_sm <= find_1st_edge;
          end if;

        when find_1st_edge =>
          if (cnt = CNT_MAX-1) then
            if (edgeflag = '1') then
              align_sm <= found_1st_edge;
            else
              align_sm <= inc_1st_edge;
            end if;
          end if;

        when inc_1st_edge =>
          align_sm <= find_1st_edge;

        when found_1st_edge =>
          align_sm <= wait_2nd_edge;

        when wait_2nd_edge =>
          if (cnt = CNT_MAX-1) then
            if (window_cnt = 4) then -- do a few additional increments when an edge is found
              align_sm <= find_2nd_edge;
            else
              align_sm <= found_1st_edge;
            end if;
          end if;

        when find_2nd_edge =>
          if (cnt = CNT_MAX-1) then
            if (edgeflag = '1') then
              align_sm <= found_2nd_edge;
            else
              align_sm <= inc_2nd_edge;
            end if;
          end if;

        when inc_2nd_edge =>
          align_sm <= find_2nd_edge;

        when found_2nd_edge =>
          align_sm <= wait_mid;

        when wait_mid =>
          if (cnt = CNT_MAX-1) then
            align_sm <= find_mid;
          end if;

        when find_mid =>
          if (cnt = CNT_MAX-1) then
            if (window_cnt = 0 or window_cnt = 1) then
              align_sm <= found_mid;
            else
              align_sm <= dec_mid;
            end if;
          end if;

        when dec_mid =>
          align_sm <= find_mid;

        when found_mid =>
          align_sm <= wait_bit_slip;

        when wait_bit_slip =>
          if (cnt = CNT_MAX-1) then
            if (aligned_to_pattern = '0') then
              align_sm <= bit_slip;
            else
              align_sm <= bit_slip_done;
            end if;
          end if;

        when bit_slip =>
          align_sm <= wait_bit_slip;

        when bit_slip_done =>
          align_sm <= bit_slip_done;

        when others  =>
          align_sm <= idle;

      end case;

    end if;

  end if;
end process;

----------------------------------------------------------------------------------------------------
-- Actions
----------------------------------------------------------------------------------------------------
process (rst, clk)
begin
  if (rst = '1') then

    data_prev <= (others => '0');
    edgeflag <= '0';
    cnt <= 0;
    aligned_to_pattern <= '0';
    incr <= '0';
    decr <= '0';
    window_cnt <= 0;
    bitslip <= '0';
    data_aligned <= '0';

  elsif (rising_edge(clk)) then

    -- Store data in order to be able to detect edge
    if (align_sm = wait_1st_edge or align_sm = wait_2nd_edge) then
      data_prev <= data;
    end if;

    if (align_sm = find_1st_edge or align_sm = find_2nd_edge) then
      if (data /= data_prev) then
        edgeflag <= '1';
      end if;
    else
      edgeflag <= '0';
    end if;

    if (align_sm = idle or align_sm = bit_slip_done or align_sm /= align_sm_prev) then
      cnt <= 0;
    else
      cnt <= cnt + 1;
    end if;

    if (data = PATTERN) then
      aligned_to_pattern <= '1';
    else
      aligned_to_pattern <= '0';
    end if;

    if (align_sm = inc_1st_edge or align_sm = inc_2nd_edge or align_sm = found_1st_edge) then
      incr <= '1';
      decr <= '0';
    elsif (align_sm = dec_mid) then
      incr <= '0';
      decr <= '1';
    else
      incr <= '0';
      decr <= '0';
    end if;

    if (align_sm = wait_1st_edge) then
      window_cnt <= 0;
    elsif (align_sm = found_1st_edge or align_sm = inc_2nd_edge or align_sm = found_2nd_edge) then
      window_cnt <= window_cnt + 1;
    elsif (align_sm = dec_mid) then
      window_cnt <= window_cnt - 2;
    end if;

    if (align_sm = bit_slip) then
      bitslip <= '1';
    else
      bitslip <= '0';
    end if;

    if (align_sm = bit_slip_done) then
      data_aligned <= '1';
    else
      data_aligned <= '0';
    end if;

  end if;
end process;

ce  <= incr or decr;
inc <= incr;

----------------------------------------------------------------------------------------------------
-- End
----------------------------------------------------------------------------------------------------
end bit_align_machine_syn;
