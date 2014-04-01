-------------------------------------------------------------------------------
-- Title      : AXI-S FIFO
-- Project    : 10 Gigabit Ethernet MAC Core
-------------------------------------------------------------------------------
-- File       : ten_gig_eth_mac_0_axi_fifo.vhd
-- Author     : Xilinx Inc.
-------------------------------------------------------------------------------
-- (c) Copyright 2001-2012 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
-- 
-------------------------------------------------------------------------------
-- Description: This is the AXI-Streaming fifo for the client loopback design
--              example of the 10 Gigabit Ethernet MAC core
--
--              The FIFO is created from Block RAMs and can be chosen to of 
--              size (in 8 bytes words) 512, 1024, 2048, 4096, 8192, or 2048.
--
--              Frame data received from the write side is written into the
--              data field of the BRAM on the wr_axis_aclk. Start of Frame , 
--              End of Frame and a binary encoded strobe signal (indicating the
--              number of valid bytes in the last word of the frame) are 
--              created and stored in the parity field of the BRAM
--
--              The wr_axis_tlast and wr_axis_tuser signals are used to qualify
--              the frame.  A frame for which wr_axis_tuser was not asserted
--              when wr_axis_tlast was asserted will cause the FIFO write
--              address pointer to be reset to the base address of that frame.
--              In this way the bad frame will be overwritten with the next
--              received frame and is therefore dropped from the FIFO.
--
--              When there is at least one complete frame in the FIFO,
--              the read interface will be enabled allowing data to be read
--              from the fifo.
--
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity ten_gig_eth_mac_0_axi_fifo is
   generic (
      FIFO_SIZE : integer := 512;
      WR_FLOW_CTRL : boolean := false);
   port (
   -- FIFO write domain
   wr_axis_aresetn : in  std_logic;
   wr_axis_aclk    : in  std_logic;
   wr_axis_tdata   : in  std_logic_vector(63 downto 0);
   wr_axis_tkeep   : in  std_logic_vector(7 downto 0);
   wr_axis_tvalid  : in  std_logic;
   wr_axis_tlast   : in  std_logic;
   wr_axis_tready  : out std_logic;
   wr_axis_tuser   : in  std_logic;

   -- FIFO read domain 
   rd_axis_aresetn : in  std_logic;
   rd_axis_aclk    : in  std_logic;
   rd_axis_tdata   : out std_logic_vector(63 downto 0);
   rd_axis_tkeep   : out std_logic_vector(7 downto 0);
   rd_axis_tvalid  : out std_logic;
   rd_axis_tlast   : out std_logic;
   rd_axis_tready  : in  std_logic;

   -- FIFO Status Signals
   fifo_status : out std_logic_vector(3 downto 0);
   fifo_full      : out std_logic);

end ten_gig_eth_mac_0_axi_fifo;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.xgmac_fifo_pack.all;


architecture rtl of ten_gig_eth_mac_0_axi_fifo is
   component ten_gig_eth_mac_0_fifo_ram
      generic (
         ADDR_WIDTH : integer);
      port (
         wr_clk    : in  std_logic;
         wr_addr   : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
         data_in   : in  std_logic_vector(63 downto 0);
         ctrl_in   : in  std_logic_vector(3 downto 0);
         wr_allow  : in  std_logic;
         rd_clk    : in  std_logic;
         rd_sreset : in  std_logic;
         rd_addr   : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
         data_out  : out std_logic_vector(63 downto 0);
         ctrl_out  : out std_logic_vector(3 downto 0);
         rd_allow  : in  std_logic);
   end component;



   -- the address width required is a function of FIFO size
   constant ADDR_WIDTH        : integer := log2(FIFO_SIZE);

   -- write clock domain
   signal wr_addr             : unsigned(ADDR_WIDTH-1 downto 0);            -- current write address
   signal wr_addr_last        : unsigned(ADDR_WIDTH-1 downto 0);            -- store last address for frame drop
   signal wr_rd_addr_gray     : unsigned(ADDR_WIDTH-1 downto 0);            -- rd_addr in wr domain (Gray code)
   signal wr_rd_addr_gray_d1  : unsigned(ADDR_WIDTH-1 downto 0);            -- 2nd register rd_addr in wr domain (Gray code)
   signal wr_rd_addr_gray_d2  : unsigned(ADDR_WIDTH-1 downto 0);            -- 3rd register rd_addr in wr domain (Gray code)
   signal wr_rd_addr_gray_d3  : unsigned(ADDR_WIDTH-1 downto 0);            -- 4th register rd_addr in wr domain (Gray code)
   signal wr_rd_addr_gray_d4  : unsigned(ADDR_WIDTH-1 downto 0);            -- 5th register rd_addr in wr domain (Gray code)
   signal wr_rd_addr          : unsigned(ADDR_WIDTH-1 downto 0);            -- rd_addr in wr domain
   signal wr_enable           : std_logic;                                  -- write enable
   signal wr_enable_ram       : std_logic;                                  -- write enable pipelined
   signal wr_fifo_full        : std_logic;                                  -- fifo full
   signal wr_data_pipe        : std_logic_vector(63 downto 0);              -- write data pipelined
   signal wr_ctrl_pipe        : std_logic_vector(3 downto 0);               -- contains SOF, EOF and Remainder information for the frame: stored in the parity bits of BRAM.
   signal wr_store_frame      : std_logic;                                  -- decision to keep the previous received frame 
   signal wr_store_frame_reg  : std_logic;                                  -- wr_store_frame pipelined 
   signal wr_store_frame_tog  : std_logic;                                  -- toggle everytime a frame is kept: this crosses onto the read clock domain 
   signal wr_rem              : std_logic_vector(2 downto 0);               -- Number of bytes valiod in last word of frame encoded as a binary remainder 
   signal wr_eof              : std_logic;                                  -- asserted with the last word of the frame 

   
   -- read clock domain
   signal rd_addr             : unsigned(ADDR_WIDTH-1 downto 0);            -- current read address
   signal rd_addr_gray        : unsigned(ADDR_WIDTH-1 downto 0);            -- read address grey encoded 
   signal rd_addr_gray_reg    : unsigned(ADDR_WIDTH-1 downto 0);            -- read address grey encoded 
   signal rd_frames           : unsigned(ADDR_WIDTH-2 downto 0);            -- A count of the number of frames currently stored in the FIFO
   signal rd_store_frame_tog  : std_logic;                                  -- sample wr_store_frame_tog on the read clock 
   signal rd_store_frame_tog_d1  : std_logic;                                  -- sample wr_store_frame_tog on the read clock 
   signal rd_store_frame_tog_d2  : std_logic;                                  -- sample wr_store_frame_tog on the read clock 
   signal rd_store_frame_tog_d3  : std_logic;                                  -- sample wr_store_frame_tog on the read clock 
   signal rd_store_frame_sync : std_logic;                                  -- register wr_store_frame_tog a 2nd time 
   signal rd_store_frame      : std_logic;                                  -- edge detector for wr_store_frame_tog 
   signal rd_enable           : std_logic;                                  -- read enable 
   signal rd_data             : std_logic_vector(63 downto 0);              -- data word output from BRAM 
   signal rd_ctrl             : std_logic_vector(3 downto 0);               -- data control output from BRAM parity (contains SOF, EOF and Remainder information for the frame) 
   signal rd_avail            : std_logic;                                  -- there is at least 1 frame stored in the FIFO
   signal rd_state            : std_logic_vector(2 downto 0);               -- frame read state machine
   signal wr_addr_diff        : unsigned(ADDR_WIDTH-1 downto 0);            -- the difference between read and write address 
   signal wr_addr_diff_comb   : unsigned(ADDR_WIDTH-1 downto 0);            -- the difference between read and write address 
   signal wr_addr_diff_2s_comp : unsigned(ADDR_WIDTH-1 downto 0);            -- 2's compl of read and write address diff
 

  signal rd_sreset              : std_logic;
  signal rd_sreset2             : std_logic;
  signal rd_sreset3             : std_logic;
  signal rd_sreset4             : std_logic;
  signal rd_sreset5             : std_logic;

  signal wr_sreset              : std_logic;
  signal wr_sreset2             : std_logic;
  signal wr_sreset3             : std_logic;
  signal wr_sreset4             : std_logic;
  signal wr_sreset5             : std_logic;

  signal dst_rdy_in             : std_logic;
  signal sof_out                : std_logic;

          
   attribute async_reg                       : string;
   attribute async_reg of wr_rd_addr_gray    : signal is "true";
   attribute async_reg of wr_rd_addr_gray_d1 : signal is "true";
   attribute async_reg of wr_rd_addr_gray_d2 : signal is "true";
   attribute async_reg of wr_rd_addr_gray_d3 : signal is "true";
   attribute async_reg of wr_rd_addr_gray_d4 : signal is "true";
   
   attribute async_reg of rd_store_frame_tog : signal is "true";
   attribute async_reg of rd_store_frame_tog_d1 : signal is "true";
   attribute async_reg of rd_store_frame_tog_d2 : signal is "true";
   attribute async_reg of rd_store_frame_tog_d3 : signal is "true";
   attribute async_reg of rd_store_frame_sync : signal is "true";
   attribute async_reg of rd_sreset          : signal is "true";
   attribute async_reg of rd_sreset2         : signal is "true";
   attribute async_reg of rd_sreset3         : signal is "true";
   attribute async_reg of rd_sreset4         : signal is "true";
   attribute async_reg of rd_sreset5         : signal is "true";
   attribute async_reg of wr_sreset          : signal is "true";
   attribute async_reg of wr_sreset2         : signal is "true";
   attribute async_reg of wr_sreset3         : signal is "true";
   attribute async_reg of wr_sreset4         : signal is "true";
   attribute async_reg of wr_sreset5         : signal is "true";
begin

  -- Convert between active low and high
  dst_rdy_in <= rd_axis_tready;

  -- Create synchronous reset in the write clock domain.
  gen_wr_sreset : process (wr_axis_aclk, wr_axis_aresetn, rd_axis_aresetn)
  begin
    if wr_axis_aresetn = '0' or rd_axis_aresetn = '0' then
      wr_sreset5     <= '1';
      wr_sreset4     <= '1';
      wr_sreset3     <= '1';
      wr_sreset2     <= '1';
      wr_sreset      <= '1';
    elsif wr_axis_aclk'event and wr_axis_aclk = '1' then
      wr_sreset5     <= '0';
      wr_sreset4     <= wr_sreset5;
      wr_sreset3     <= wr_sreset4;
      wr_sreset2     <= wr_sreset3;
      wr_sreset      <= wr_sreset2;
   end if;
  end process gen_wr_sreset;

  -- Create synchronous reset in the read clock domain.
  gen_rd_sreset : process (rd_axis_aclk, wr_axis_aresetn, rd_axis_aresetn)
  begin
    if wr_axis_aresetn = '0' or rd_axis_aresetn = '0' then
      rd_sreset5     <= '1';
      rd_sreset4     <= '1';
      rd_sreset3     <= '1';
      rd_sreset2     <= '1';
      rd_sreset      <= '1';
    elsif rd_axis_aclk'event and rd_axis_aclk = '1' then
      rd_sreset5     <= '0';
      rd_sreset4     <= rd_sreset5;
      rd_sreset3     <= rd_sreset4;
      rd_sreset2     <= rd_sreset3;
      rd_sreset      <= rd_sreset2;
   end if;
  end process gen_rd_sreset;

  ----------------------------------------------------------------------
  -- FIFO Read domain
  ----------------------------------------------------------------------


  -- Edge detector to register that a new frame was written into the 
  -- FIFO.  
  -- NOTE: wr_store_frame_tog crosses clock domains from FIFO write
  p_sync_rd_store : process (rd_axis_aclk)
  begin 
    if rd_axis_aclk'event and rd_axis_aclk = '1' then 
      if rd_sreset = '1' then
        rd_store_frame_tog     <= '0';
        rd_store_frame_tog_d1  <= '0';
        rd_store_frame_tog_d2  <= '0';
        rd_store_frame_tog_d3  <= '0';
        rd_store_frame_sync    <= '0';
        rd_store_frame         <= '0';

      else
        rd_store_frame_tog  <= wr_store_frame_tog;
        rd_store_frame_tog_d1 <= rd_store_frame_tog;
        rd_store_frame_tog_d2 <= rd_store_frame_tog_d1;
        rd_store_frame_tog_d3 <= rd_store_frame_tog_d2;
        rd_store_frame_sync <= rd_store_frame_tog_d3;

        -- edge detector
        if (rd_store_frame_sync xor rd_store_frame_tog_d3) = '1' then
          rd_store_frame    <= '1';
        else
          rd_store_frame    <= '0';
        end if;
      end if;
    end if;
  end process p_sync_rd_store;
   

                                                                                                                                
  -- Up/Down counter to monitor the number of frames stored within the
  -- the FIFO. Note:  
  --    * decrements at the beginning of a frame read cycle
  --    * increments at the end of a frame write cycle
  p_rd_frames : process (rd_axis_aclk)
  begin 
    if rd_axis_aclk'event and rd_axis_aclk = '1' then 
      if rd_sreset = '1' then
        rd_frames <= (others => '0');

      else
        -- A frame has been written into the FIFO
        if rd_store_frame = '1' then
          if rd_state = "001" then 
            -- one in, one out = no change
            rd_frames <= rd_frames;
          else
            if rd_frames /= (rd_frames'range => '1') then -- if we max out error!
              rd_frames <= rd_frames + 1;
            end if;
          end if;
        else
          -- A frame is about to be read out of the FIFO
          if rd_state = "001" then -- one out = take 1
            if rd_frames /= (rd_frames'range => '0') then -- if we bottom out error!
              rd_frames <= rd_frames - 1;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process p_rd_frames;
    


  -- Data is available if there is at leat one frame stored in the FIFO.
  p_rd_avail : process (rd_axis_aclk)
  begin 
    if rd_axis_aclk'event and rd_axis_aclk = '1' then 
      if rd_sreset = '1' then
        rd_avail <= '0';

      else
        if rd_frames /= (rd_frames'range => '0') then
          rd_avail <= '1';
        else
          rd_avail <= '0';
        end if;
      end if;
    end if;
  end process p_rd_avail;
    
   

  -- Read State Machine: to run through the frame read cycle.
  p_rd_state : process (rd_axis_aclk)
  begin 
    if rd_axis_aclk'event and rd_axis_aclk = '1' then 
      if rd_sreset = '1' then
        rd_state <= "000";

      else
        case rd_state is 
          -- Idle state
          when "000" =>
            -- check for at least 1 frame stored in the FIFO:
            if rd_avail = '1' then
              rd_state <= "001"; 
            end if;

          -- Read Initialisation 1: read 1st frame word out of FIFO
          when "001" =>
              rd_state <= "010";

          -- Read Initialisation 2: 1st word and SOF are registered onto
          --                        read whilst 2nd word is fetched
          when "010" =>
              rd_state <= "011";

          -- Frame Read in Progress
          when "011" =>
            -- detect the end of the frame
            if dst_rdy_in = '1' and rd_ctrl(3) = '1' then  
              rd_state <= "100";
            end if;

          -- End of Frame Read: EOF is driven onto read interface
          when "100" =>
            if dst_rdy_in = '1' then  -- wait until EOF is sampled  
              if rd_avail = '1' then  -- frame is waiting
                rd_state <= "001"; 
              else                    -- go to Idle state
                rd_state <= "000";
              end if;
            end if;

          when others =>
            rd_state <= "000";
        end case;
      end if;
    end if;
  end process p_rd_state;
     
  

  -- Read Enable signal based on Read State Machine 
  rd_enable <= '1' after 1 ps when rd_state = "001" or rd_state = "010" or   -- Read Initialisation States
                       (rd_state = "011" and rd_ctrl(3) = '0'     -- Frame Read in Progress but not EOF 
                         and dst_rdy_in = '1')
                   else '0' after 1 ps;

  

  -- Create the Read Address Pointer 
  p_rd_addr : process (rd_axis_aclk)
  begin 
    if rd_axis_aclk'event and rd_axis_aclk = '1' then 
      if rd_sreset = '1' then
        rd_addr <= (others => '0');

      elsif rd_enable = '1' then
        rd_addr <= rd_addr + 1;
      end if;
    end if;
  end process p_rd_addr;

     

  -- Create the AXI-S Output Packet Signals
  p_rd_pipe : process (rd_axis_aclk)
  begin 
    if rd_axis_aclk'event and rd_axis_aclk = '1' then
      if rd_sreset = '1' then
        rd_axis_tdata      <= (others => '0');
        rd_axis_tkeep      <= (others => '0');  
        rd_axis_tlast       <= '0';

      elsif rd_state = "010" or (rd_state /= "000" and dst_rdy_in = '1') then
        -- pipeline appropriately for registered read
        rd_axis_tdata      <= rd_data;

        -- The remainder is encoded into rd_ctrl[2:0]
        case rd_ctrl(2 downto 0) is
          when "000" => rd_axis_tkeep <= "00000001";
          when "001" => rd_axis_tkeep <= "00000011";
          when "010" => rd_axis_tkeep <= "00000111";
          when "011" => rd_axis_tkeep <= "00001111";
          when "100" => rd_axis_tkeep <= "00011111";
          when "101" => rd_axis_tkeep <= "00111111";
          when "110" => rd_axis_tkeep <= "01111111";
          when "111" => rd_axis_tkeep <= "11111111";
          when others=> rd_axis_tkeep <= "00000000";
        end case;

        -- The EOF is encoded into rd_ctrl[3] but needs to be qualified to 
        -- ensure that its deasserted once its been read.
        if rd_state = "011" then
          rd_axis_tlast       <= rd_ctrl(3);
        else 
          rd_axis_tlast       <= '0';  
        end if;


      end if;
    end if;
  end process p_rd_pipe;
     


  -- Create the AXI-S Valid Signal
  p_src_rdy : process (rd_axis_aclk)
  begin 
    if rd_axis_aclk'event and rd_axis_aclk = '1' then
      if rd_sreset = '1' then
        rd_axis_tvalid    <= '0';

      else
        -- Assert during Read Initialisation 2 state
        if rd_state = "010" then
          rd_axis_tvalid   <= '1';

        -- Remove on End of Frame Read state 
        elsif rd_state = "100" and dst_rdy_in = '1' then
          rd_axis_tvalid   <= '0';
        end if;
      end if;
    end if;
  end process p_src_rdy;   
  

    
  -- Take the Read Address Pointer and convert it into a grey code 
  rd_addr_gray <= unsigned(bin_to_gray(std_logic_vector(rd_addr)));

  -- register the gray code read address pointer in read clock domain.
  p_rd_addr_reg : process (rd_axis_aclk)
  begin 
     if rd_axis_aclk'event and rd_axis_aclk = '1' then
       if rd_sreset = '1' then
         rd_addr_gray_reg <= (others => '0');
       else
         rd_addr_gray_reg <= rd_addr_gray;
       end if;
     end if;
  end process p_rd_addr_reg;

  ----------------------------------------------------------------------
  -- FIFO Write Domain
  ----------------------------------------------------------------------

  
  -- Resync the Read Address Pointer grey code onto the write clock
  -- NOTE: rd_addr_gray signal crosses clock domains
  p_sync_rd_addr : process (wr_axis_aclk)
  begin 
     if wr_axis_aclk'event and wr_axis_aclk = '1' then 
        if wr_sreset = '1' then
          wr_rd_addr_gray    <= (others => '0');
          wr_rd_addr_gray_d1 <= (others => '0');
          wr_rd_addr_gray_d2 <= (others => '0');
          wr_rd_addr_gray_d3 <= (others => '0');
          wr_rd_addr_gray_d4 <= (others => '0');
        else
          wr_rd_addr_gray    <= rd_addr_gray_reg;
          wr_rd_addr_gray_d1 <= wr_rd_addr_gray;
          wr_rd_addr_gray_d2 <= wr_rd_addr_gray_d1;
          wr_rd_addr_gray_d3 <= wr_rd_addr_gray_d2;
          wr_rd_addr_gray_d4 <= wr_rd_addr_gray_d3;
        end if;
     end if;
  end process p_sync_rd_addr;   

  -- Convert the resync'd Read Address Pointer grey code back to binary
  wr_rd_addr <= unsigned(gray_to_bin(std_logic_vector(wr_rd_addr_gray_d4)));


  -- Obtain the difference between write and read pointers
  p_addr_diff : process (wr_axis_aclk)
  begin
     if wr_axis_aclk'event and wr_axis_aclk = '1' then
        if wr_sreset = '1' then
           wr_addr_diff <= (others => '0');
        else
           wr_addr_diff <= wr_rd_addr - wr_addr;
        end if;
     end if;
  end process p_addr_diff;

  wr_addr_diff_comb <= (wr_rd_addr - wr_addr);

  ----------------------------------------------------------------------
  -- Create FIFO Status Signals  in the Read Domain
  ----------------------------------------------------------------------
  -- The FIFO status signal is four bits which represents the occupancy
  -- of the FIFO in 16'ths.  To generate this signal we need use the 
  -- 2's complement of the difference between the read and write 
  -- pointers and take the top 4 bits.

  wr_addr_diff_2s_comp <= not(wr_addr_diff) + 1;
  
  -- The 4 most significant bits of the write pointer minus the 4 msb of
  -- the read pointer gives us our FIFO status.
  p_fifo_status : process (wr_axis_aclk)
  begin 
     if wr_axis_aclk'event and wr_axis_aclk = '1' then
       if wr_sreset = '1' then
         fifo_status <= "0000";
       else
         fifo_status <= std_logic_vector(wr_addr_diff_2s_comp(ADDR_WIDTH-1 downto ADDR_WIDTH-4));
       end if;
     end if;
  end process p_fifo_status;

    

  -- Detect when the FIFO is full
  p_wr_full : process (wr_axis_aclk)
  begin 
     if wr_axis_aclk'event and wr_axis_aclk = '1' then
       if wr_sreset = '1' then
         wr_fifo_full <= '0';
       else

      --At the end of the frame FIFO will never be full since the 
      --frame will be dropped if it's already full
         if(wr_axis_tlast='1') then
           wr_fifo_full <= '0';
         -- The FIFO is considered to be full if the write address
         -- pointer is within 1 to 3 of the read address pointer.
         elsif wr_addr_diff_comb(ADDR_WIDTH-1 downto 3) = 0 and 
               wr_addr_diff_comb(2 downto 0) /= "000" then
           wr_fifo_full <= '1';

         -- We hold the full signal until the end of frame reception to guarantee that this
         -- frame will be dropped
         elsif (WR_FLOW_CTRL or wr_axis_tlast='1' or wr_axis_tvalid='0') then
           wr_fifo_full <= '0';
         end if;
       end if;
     end if;
  end process p_wr_full;   

  fifo_full <= wr_fifo_full;
  wr_axis_tready <= not wr_fifo_full;

  -- Create the Write Address Pointer 
  p_wr_addr : process (wr_axis_aclk)
  begin 
     if wr_axis_aclk'event and wr_axis_aclk = '1' then
        if wr_sreset = '1' then
          wr_addr <= (others => '0');
        else
          -- If the received frame contained an error, it will be over-
          -- written: reload the starting address for that frame
          if (wr_axis_tlast= '1' and wr_fifo_full = '1') or
           (wr_axis_tlast= '1' and wr_axis_tuser='0') then
            wr_addr <= wr_addr_last;

          -- increment write pointer as frame is written.
          elsif wr_enable_ram = '1' then
            wr_addr <= wr_addr + 1;
          end if;
        end if;
     end if;
  end process p_wr_addr;   

  -- Record the starting address of a new frame in case it needs to be 
  -- overwritten
  p_wr_addr_last : process (wr_axis_aclk)
  begin 
     if wr_axis_aclk'event and wr_axis_aclk = '1' then
       if wr_sreset = '1' then
         wr_addr_last <= (others => '0');
       elsif wr_store_frame_reg = '1' then
         wr_addr_last <= wr_addr;
       end if;
     end if;
  end process p_wr_addr_last; 

  
  
  -- Write Enable signal based on write signals and FIFO status 
  wr_enable <= '1' when wr_axis_tkeep(0) = '1' and wr_axis_tvalid = '1' and wr_fifo_full = '0' else '0';



  -- At the end of frame reception, decide whether to keep the frame or
  -- to overwrite it with the next.
  p_wr_end : process (wr_axis_aclk)
  begin 
     if wr_axis_aclk'event and wr_axis_aclk = '1' then
       if wr_sreset = '1' then
         wr_store_frame       <= '0';
         wr_store_frame_reg   <= '0';
         wr_store_frame_tog   <= '0';

       else
         wr_store_frame_reg   <= wr_store_frame;

         -- Error free frame is received and has fit in the FIFO: keep
         if wr_axis_tuser = '1' and wr_axis_tvalid = '1' and wr_fifo_full = '0' then
           wr_store_frame     <= '1';
           wr_store_frame_tog <= not wr_store_frame_tog;

         -- Error free frame is received but does not fit in FIFO or
         -- an error-ed frame is received: discard frame
         elsif (wr_axis_tlast= '1' and wr_fifo_full = '1') or
           (wr_axis_tlast= '1' and wr_axis_tuser='0') then
           wr_store_frame     <= '0';

         else
           wr_store_frame     <= '0';
         end if;
       end if;
     end if;
  end process p_wr_end;   



  -- Pipeline the data and control signals to BRAM
  p_wr_pipe : process (wr_axis_aclk)
  begin 
     if wr_axis_aclk'event and wr_axis_aclk = '1' then
       if wr_sreset = '1' then
         wr_data_pipe   <= (others => '0');
         wr_rem         <= (others => '0');

       else
         -- pipeline write enable and the data
         -- End of frame is indicated by the tlast signal
         if(wr_axis_tlast='1' and wr_axis_tuser='1' and wr_axis_tvalid='1') then
           wr_eof <='1';
         else
           wr_eof <='0';
         end if;

         --Hold the last data beat untill the last signal is received
         if(wr_enable = '1') then
           wr_data_pipe   <= wr_axis_tdata;


           -- Encode the data strobe signals as a binary remainder:

           -- wr_axis_tkeep   wr_rem
           -- -------------   ------
           -- 0x00000001      000
           -- 0x00000011      001
           -- 0x00000111      010
           -- 0x00001111      011
           -- 0x00011111      100
           -- 0x00111111      101
           -- 0x01111111      110
           -- 0x11111111      111

           wr_rem(2) <= wr_axis_tkeep(4);

           case wr_axis_tkeep is
           when "00000001" | "00011111" =>
             wr_rem(1 downto 0) <= "00";
           when "00000011" | "00111111" =>
             wr_rem(1 downto 0) <= "01";
           when "00000111" | "01111111" =>
             wr_rem(1 downto 0) <= "10";
           when others =>
             wr_rem(1 downto 0) <= "11";
           end case;
	 elsif (wr_eof = '1') then
           wr_rem <= (others => '0');
         end if;
       end if;

     end if;
  end process p_wr_pipe; 

  wr_enable_ram <= '1' after 1 ps when (wr_rem="111" and wr_enable='1')
                   or wr_eof='1' else '0' after 1 ps;

  -- This signal, stored in the parity bits of the BRAM, contains
  -- EOF and Remainder information for the stored frame:
  -- wr_ctrl[3]    = EOF
  -- wr_ctrl([2:0] = remainder 
  -- Note that remainder is only valid when EOF is asserted.
               
  wr_ctrl_pipe <= wr_eof & wr_rem; 



  ----------------------------------------------------------------------
  -- Instantiate BRAMs to produce the dual port memory
  ----------------------------------------------------------------------
  
  fifo_ram_inst : ten_gig_eth_mac_0_fifo_ram 
     generic map (                           
        ADDR_WIDTH => ADDR_WIDTH)       
     port map (                              
        wr_clk    => wr_axis_aclk,                 
        wr_addr   => std_logic_vector(wr_addr),            
        data_in   => wr_data_pipe,                
        ctrl_in   => wr_ctrl_pipe,                
        wr_allow  => wr_enable_ram,               
        rd_clk    => rd_axis_aclk,                 
        rd_sreset => rd_sreset,              
        rd_addr   => std_logic_vector(rd_addr),            
        data_out  => rd_data,               
        ctrl_out  => rd_ctrl,               
        rd_allow  => rd_enable);          
 

end rtl;
