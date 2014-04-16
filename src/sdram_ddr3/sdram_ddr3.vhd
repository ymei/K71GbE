----------------------------------------------------------------------------------
-- Company:  LBNL
-- Engineer: Yuan Mei
-- 
-- Create Date: 12/17/2013 07:22:25 PM
-- Design Name: 
-- Module Name: sdram_ddr3 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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
-- any Xilinx leaf cells in this code.
LIBRARY UNISIM;
USE UNISIM.VComponents.ALL;

ENTITY sdram_ddr3 IS
  GENERIC (
    INDATA_WIDTH   : positive := 128;
    OUTDATA_WIDTH  : positive := 32;
    APP_ADDR_WIDTH : positive := 28;
    APP_DATA_WIDTH : positive := 512;
    APP_MASK_WIDTH : positive := 64;
    APP_ADDR_BURST : positive := 8
  );
  PORT (
    CLK                   : IN    std_logic;  -- system clock, must be the same as intended in MIG
    REFCLK                : IN    std_logic;  -- 200MHz for iodelay
    RESET                 : IN    std_logic;
    -- SDRAM_DDR3
    -- Inouts
    DDR3_DQ               : INOUT std_logic_vector(63 DOWNTO 0);
    DDR3_DQS_P            : INOUT std_logic_vector(7 DOWNTO 0);
    DDR3_DQS_N            : INOUT std_logic_vector(7 DOWNTO 0);
    -- Outputs
    DDR3_ADDR             : OUT   std_logic_vector(13 DOWNTO 0);
    DDR3_BA               : OUT   std_logic_vector(2 DOWNTO 0);
    DDR3_RAS_N            : OUT   std_logic;
    DDR3_CAS_N            : OUT   std_logic;
    DDR3_WE_N             : OUT   std_logic;
    DDR3_RESET_N          : OUT   std_logic;
    DDR3_CK_P             : OUT   std_logic_vector(0 DOWNTO 0);
    DDR3_CK_N             : OUT   std_logic_vector(0 DOWNTO 0);
    DDR3_CKE              : OUT   std_logic_vector(0 DOWNTO 0);
    DDR3_CS_N             : OUT   std_logic_vector(0 DOWNTO 0);
    DDR3_DM               : OUT   std_logic_vector(7 DOWNTO 0);
    DDR3_ODT              : OUT   std_logic_vector(0 DOWNTO 0);
    -- Status Outputs
    INIT_CALIB_COMPLETE   : OUT   std_logic;
    -- Internal data r/w interface
    UI_CLK                : OUT   std_logic;
    --
    CTRL_RESET            : IN  std_logic;
    WR_START              : IN    std_logic;
    WR_ADDR_BEGIN         : IN    std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
    WR_STOP               : IN    std_logic;
    WR_WRAP_AROUND        : IN    std_logic;
    POST_TRIGGER          : IN    std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
    WR_BUSY               : OUT   std_logic;
    WR_POINTER            : OUT   std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
    TRIGGER_POINTER       : OUT   std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
    WR_WRAPPED            : OUT   std_logic;
    RD_START              : IN    std_logic;
    RD_ADDR_BEGIN         : IN    std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
    RD_ADDR_END           : IN    std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
    RD_BUSY               : OUT   std_logic;
    --
    DATA_FIFO_RESET       : IN    std_logic;
    INDATA_FIFO_WRCLK     : IN    std_logic;
    INDATA_FIFO_Q         : IN    std_logic_vector(INDATA_WIDTH-1 DOWNTO 0);
    INDATA_FIFO_FULL      : OUT   std_logic;
    INDATA_FIFO_WREN      : IN    std_logic;
    --
    OUTDATA_FIFO_RDCLK    : IN    std_logic;
    OUTDATA_FIFO_Q        : OUT   std_logic_vector(OUTDATA_WIDTH-1 DOWNTO 0);
    OUTDATA_FIFO_EMPTY    : OUT   std_logic;
    OUTDATA_FIFO_RDEN     : IN    std_logic;
    --
    DBG_APP_ADDR          : OUT std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
    DBG_APP_EN            : OUT std_logic;
    DBG_APP_RDY           : OUT std_logic;
    DBG_APP_WDF_DATA      : OUT std_logic_vector(APP_DATA_WIDTH-1 DOWNTO 0);
    DBG_APP_WDF_END       : OUT std_logic;
    DBG_APP_WDF_WREN      : OUT std_logic;
    DBG_APP_WDF_RDY       : OUT std_logic;
    DBG_APP_RD_DATA       : OUT std_logic_vector(APP_DATA_WIDTH-1 DOWNTO 0);
    DBG_APP_RD_DATA_VALID : OUT std_logic
  );
END sdram_ddr3;

ARCHITECTURE Behavioral OF sdram_ddr3 IS

  COMPONENT mig_7series_0
    PORT(
      DDR3_DQ             : INOUT std_logic_vector(63 DOWNTO 0);
      DDR3_DQS_P          : INOUT std_logic_vector(7 DOWNTO 0);
      DDR3_DQS_N          : INOUT std_logic_vector(7 DOWNTO 0);
      DDR3_ADDR           : OUT   std_logic_vector(13 DOWNTO 0);
      DDR3_BA             : OUT   std_logic_vector(2 DOWNTO 0);
      DDR3_RAS_N          : OUT   std_logic;
      DDR3_CAS_N          : OUT   std_logic;
      DDR3_WE_N           : OUT   std_logic;
      DDR3_RESET_N        : OUT   std_logic;
      DDR3_CK_P           : OUT   std_logic_vector(0 DOWNTO 0);
      DDR3_CK_N           : OUT   std_logic_vector(0 DOWNTO 0);
      DDR3_CKE            : OUT   std_logic_vector(0 DOWNTO 0);
      DDR3_CS_N           : OUT   std_logic_vector(0 DOWNTO 0);
      DDR3_DM             : OUT   std_logic_vector(7 DOWNTO 0);
      DDR3_ODT            : OUT   std_logic_vector(0 DOWNTO 0);
      APP_ADDR            : IN    std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
      APP_CMD             : IN    std_logic_vector(2 DOWNTO 0);
      APP_EN              : IN    std_logic;
      APP_WDF_DATA        : IN    std_logic_vector(APP_DATA_WIDTH-1 DOWNTO 0);
      APP_WDF_END         : IN    std_logic;
      APP_WDF_MASK        : IN    std_logic_vector(APP_MASK_WIDTH-1 DOWNTO 0);
      APP_WDF_WREN        : IN    std_logic;
      APP_RD_DATA         : OUT   std_logic_vector(APP_DATA_WIDTH-1 DOWNTO 0);
      APP_RD_DATA_END     : OUT   std_logic;
      APP_RD_DATA_VALID   : OUT   std_logic;
      APP_RDY             : OUT   std_logic;
      APP_WDF_RDY         : OUT   std_logic;
      APP_SR_REQ          : IN    std_logic;
      APP_REF_REQ         : IN    std_logic;
      APP_ZQ_REQ          : IN    std_logic;
      APP_SR_ACTIVE       : OUT   std_logic;
      APP_REF_ACK         : OUT   std_logic;
      APP_ZQ_ACK          : OUT   std_logic;
      UI_CLK              : OUT   std_logic;
      UI_CLK_SYNC_RST     : OUT   std_logic;
      INIT_CALIB_COMPLETE : OUT   std_logic;
      -- System Clock Ports
      SYS_CLK_I           : IN    std_logic;
      -- Reference Clock Ports
      CLK_REF_I           : IN    std_logic;
      SYS_RST             : IN    std_logic
    );
  END COMPONENT mig_7series_0;

  COMPONENT sdram_buffer_fifo
  GENERIC (
    INDATA_WIDTH   : positive := 128;
    OUTDATA_WIDTH  : positive := 32;
    APP_ADDR_WIDTH : positive := 28;
    APP_DATA_WIDTH : positive := 512;
    APP_MASK_WIDTH : positive := 64;
    APP_ADDR_BURST : positive := 8
  );
  PORT (
    CLK                : IN  std_logic;  -- MIG UI_CLK
    RESET              : IN  std_logic;
    --
    APP_ADDR           : OUT std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
    APP_CMD            : OUT std_logic_vector(2 DOWNTO 0);
    APP_EN             : OUT std_logic;
    APP_RDY            : IN  std_logic;
    APP_WDF_DATA       : OUT std_logic_vector(APP_DATA_WIDTH-1 DOWNTO 0);
    APP_WDF_END        : OUT std_logic;
    APP_WDF_MASK       : OUT std_logic_vector(APP_MASK_WIDTH-1 DOWNTO 0);
    APP_WDF_WREN       : OUT std_logic;
    APP_WDF_RDY        : IN  std_logic;
    APP_RD_DATA        : IN  std_logic_vector(APP_DATA_WIDTH-1 DOWNTO 0);
    APP_RD_DATA_END    : IN  std_logic;
    APP_RD_DATA_VALID  : IN  std_logic;
    --
    CTRL_RESET         : IN  std_logic;
    WR_START           : IN  std_logic;
    WR_ADDR_BEGIN      : IN  std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);    
    WR_STOP            : IN  std_logic;
    WR_WRAP_AROUND     : IN  std_logic;
    POST_TRIGGER       : IN  std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
    WR_BUSY            : OUT std_logic;    
    WR_POINTER         : OUT std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);    
    TRIGGER_POINTER    : OUT std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);    
    WR_WRAPPED         : OUT std_logic;
    RD_START           : IN  std_logic;
    RD_ADDR_BEGIN      : IN  std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
    RD_ADDR_END        : IN  std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);    
    RD_BUSY            : OUT std_logic;
    --
    DATA_FIFO_RESET    : IN  std_logic;
    INDATA_FIFO_WRCLK  : IN  std_logic;
    INDATA_FIFO_Q      : IN  std_logic_vector(INDATA_WIDTH-1 DOWNTO 0);
    INDATA_FIFO_FULL   : OUT std_logic;
    INDATA_FIFO_WREN   : IN  std_logic;
    --
    OUTDATA_FIFO_RDCLK : IN  std_logic;
    OUTDATA_FIFO_Q     : OUT std_logic_vector(OUTDATA_WIDTH-1 DOWNTO 0);
    OUTDATA_FIFO_EMPTY : OUT std_logic;
    OUTDATA_FIFO_RDEN  : IN  std_logic
  );
  END COMPONENT sdram_buffer_fifo;

  SIGNAL app_addr            : std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
  SIGNAL app_cmd             : std_logic_vector(2 DOWNTO 0);
  SIGNAL app_en              : std_logic;
  SIGNAL app_rdy             : std_logic;
  SIGNAL app_rd_data         : std_logic_vector(APP_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL app_rd_data_end     : std_logic;
  SIGNAL app_rd_data_valid   : std_logic;
  SIGNAL app_wdf_data        : std_logic_vector(APP_DATA_WIDTH-1 DOWNTO 0);
  SIGNAL app_wdf_end         : std_logic;
  SIGNAL app_wdf_mask        : std_logic_vector(APP_MASK_WIDTH-1 DOWNTO 0);
  SIGNAL app_wdf_wren        : std_logic;
  SIGNAL app_wdf_rdy         : std_logic;
  SIGNAL ui_clk_i            : std_logic;
  SIGNAL ui_clk_sync_rst     : std_logic;

BEGIN

  mig_7series_0_inst : mig_7series_0
    PORT MAP (
      -- Memory interface ports
      DDR3_ADDR           => DDR3_ADDR,
      DDR3_BA             => DDR3_BA,
      DDR3_CAS_N          => DDR3_CAS_N,
      DDR3_CK_N           => DDR3_CK_N,
      DDR3_CK_P           => DDR3_CK_P,
      DDR3_CKE            => DDR3_CKE,
      DDR3_RAS_N          => DDR3_RAS_N,
      DDR3_RESET_N        => DDR3_RESET_N,
      DDR3_WE_N           => DDR3_WE_N,
      DDR3_DQ             => DDR3_DQ,
      DDR3_DQS_N          => DDR3_DQS_N,
      DDR3_DQS_P          => DDR3_DQS_P,
      DDR3_CS_N           => DDR3_CS_N,
      DDR3_DM             => DDR3_DM,
      DDR3_ODT            => DDR3_ODT,
      -- Application interface ports
      APP_ADDR            => app_addr,
      APP_CMD             => app_cmd,
      APP_EN              => app_en,
      APP_WDF_DATA        => app_wdf_data,
      APP_WDF_END         => app_wdf_end,
      APP_WDF_MASK        => app_wdf_mask,      
      APP_WDF_WREN        => app_wdf_wren,
      APP_RD_DATA         => app_rd_data,
      APP_RD_DATA_END     => app_rd_data_end,
      APP_RD_DATA_VALID   => app_rd_data_valid,
      APP_RDY             => app_rdy,
      APP_WDF_RDY         => app_wdf_rdy,
      APP_SR_REQ          => '0',
      APP_REF_REQ         => '0',
      APP_ZQ_REQ          => '0',
      APP_SR_ACTIVE       => OPEN,
      APP_REF_ACK         => OPEN,
      APP_ZQ_ACK          => OPEN,
      UI_CLK              => ui_clk_i,
      UI_CLK_SYNC_RST     => ui_clk_sync_rst,
      INIT_CALIB_COMPLETE => INIT_CALIB_COMPLETE,
      -- System Clock Ports
      SYS_CLK_I           => CLK,
      -- Reference Clock Ports
      CLK_REF_I           => REFCLK,
      SYS_RST             => RESET
    );

  sdram_buffer_fifo_inst : sdram_buffer_fifo
    GENERIC MAP (
      INDATA_WIDTH   => INDATA_WIDTH,
      OUTDATA_WIDTH  => OUTDATA_WIDTH,
      APP_ADDR_WIDTH => APP_ADDR_WIDTH,
      APP_DATA_WIDTH => APP_DATA_WIDTH,
      APP_MASK_WIDTH => APP_MASK_WIDTH,
      APP_ADDR_BURST => APP_ADDR_BURST
    )
    PORT MAP (
      CLK                => ui_clk_i,
      RESET              => RESET,
      --
      APP_ADDR           => app_addr,
      APP_CMD            => app_cmd,
      APP_EN             => app_en,
      APP_RDY            => app_rdy,
      APP_WDF_DATA       => app_wdf_data,
      APP_WDF_END        => app_wdf_end,
      APP_WDF_MASK       => app_wdf_mask,
      APP_WDF_WREN       => app_wdf_wren,
      APP_WDF_RDY        => app_wdf_rdy,
      APP_RD_DATA        => app_rd_data,
      APP_RD_DATA_END    => app_rd_data_end,
      APP_RD_DATA_VALID  => app_rd_data_valid,
      --
      CTRL_RESET         => CTRL_RESET,
      WR_START           => WR_START,
      WR_ADDR_BEGIN      => WR_ADDR_BEGIN,
      WR_STOP            => WR_STOP,
      WR_WRAP_AROUND     => WR_WRAP_AROUND,
      POST_TRIGGER       => POST_TRIGGER,
      WR_BUSY            => WR_BUSY,
      WR_POINTER         => WR_POINTER,
      TRIGGER_POINTER    => TRIGGER_POINTER,
      WR_WRAPPED         => WR_WRAPPED,
      RD_START           => RD_START,
      RD_ADDR_BEGIN      => RD_ADDR_BEGIN,
      RD_ADDR_END        => RD_ADDR_END,
      RD_BUSY            => RD_BUSY,
      --
      DATA_FIFO_RESET    => DATA_FIFO_RESET,
      INDATA_FIFO_WRCLK  => INDATA_FIFO_WRCLK,
      INDATA_FIFO_Q      => INDATA_FIFO_Q,
      INDATA_FIFO_FULL   => INDATA_FIFO_FULL,
      INDATA_FIFO_WREN   => INDATA_FIFO_WREN,
      --
      OUTDATA_FIFO_RDCLK => OUTDATA_FIFO_RDCLK,
      OUTDATA_FIFO_Q     => OUTDATA_FIFO_Q,
      OUTDATA_FIFO_EMPTY => OUTDATA_FIFO_EMPTY,
      OUTDATA_FIFO_RDEN  => OUTDATA_FIFO_RDEN
    );

  UI_CLK <= ui_clk_i;
  --
  DBG_APP_ADDR          <= app_addr;
  DBG_APP_EN            <= app_en;
  DBG_APP_RDY           <= app_rdy;
  DBG_APP_WDF_DATA      <= app_wdf_data;
  DBG_APP_WDF_END       <= app_wdf_end;
  DBG_APP_WDF_WREN      <= app_wdf_wren;
  DBG_APP_WDF_RDY       <= app_wdf_rdy;
  DBG_APP_RD_DATA       <= app_rd_data;
  DBG_APP_RD_DATA_VALID <= app_rd_data_valid;

END Behavioral;
