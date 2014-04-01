--------------------------------------------------------------------------------
--
-- Company:        LBNL
-- Engineer:       Yuan Mei
-- 
-- Create Date:    02:00:18 08/23/2013 
-- Design Name:    K710GbE
-- Module Name:    top - Behavioral 
-- Project Name:
-- Target Devices: Kintex-7 XC7K325T-FFG900-2 (KC705 eval board)
-- Tool versions:  Vivado 2013.4
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--------------------------------------------------------------------------------
--
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
LIBRARY UNISIM;
USE UNISIM.VComponents.ALL;

ENTITY top IS
  GENERIC (
    ENABLE_DEBUG       : boolean := false;
    ENABLE_GIG_ETH     : boolean := true;
    ENABLE_TEN_GIG_ETH : boolean := true
  );
  PORT (
    SYS_RST          : IN    std_logic;
    SYS_CLK_P        : IN    std_logic;
    SYS_CLK_N        : IN    std_logic;
    USER_CLK_P       : IN    std_logic;  -- 156.250 MHz
    USER_CLK_N       : IN    std_logic;
    SGMIICLK_Q0_P    : IN    std_logic;  -- 125 MHz, for GTP/GTH/GTX
    SGMIICLK_Q0_N    : IN    std_logic;
    --
    LED8Bit          : OUT   std_logic_vector(7 DOWNTO 0);
    DIPSw4Bit        : IN    std_logic_vector(3 DOWNTO 0);
    BTN5Bit          : IN    std_logic_vector(4 DOWNTO 0);
    -- UART via usb
    USB_RX           : OUT   std_logic;
    USB_TX           : IN    std_logic;
    -- SFP
    SFP_TX_P         : OUT   std_logic;
    SFP_TX_N         : OUT   std_logic;
    SFP_RX_P         : IN    std_logic;
    SFP_RX_N         : IN    std_logic;
    SFP_LOS_LS       : IN    std_logic;
    SFP_TX_DISABLE_N : OUT   std_logic;
    -- Gigbit eth interface (RGMII)
    PHY_RESET_N      : OUT   std_logic;
    RGMII_TXD        : OUT   std_logic_vector(3 DOWNTO 0);
    RGMII_TX_CTL     : OUT   std_logic;
    RGMII_TXC        : OUT   std_logic;
    RGMII_RXD        : IN    std_logic_vector(3 DOWNTO 0);
    RGMII_RX_CTL     : IN    std_logic;
    RGMII_RXC        : IN    std_logic;
    MDIO             : INOUT std_logic;
    MDC              : OUT   std_logic;
    -- SDRAM
    DDR3_DQ          : INOUT std_logic_vector(63 DOWNTO 0);
    DDR3_DQS_P       : INOUT std_logic_vector(7 DOWNTO 0);
    DDR3_DQS_N       : INOUT std_logic_vector(7 DOWNTO 0);
    -- Outputs
    DDR3_ADDR        : OUT   std_logic_vector(13 DOWNTO 0);
    DDR3_BA          : OUT   std_logic_vector(2 DOWNTO 0);
    DDR3_RAS_N       : OUT   std_logic;
    DDR3_CAS_N       : OUT   std_logic;
    DDR3_WE_N        : OUT   std_logic;
    DDR3_RESET_N     : OUT   std_logic;
    DDR3_CK_P        : OUT   std_logic_vector(0 DOWNTO 0);
    DDR3_CK_N        : OUT   std_logic_vector(0 DOWNTO 0);
    DDR3_CKE         : OUT   std_logic_vector(0 DOWNTO 0);
    DDR3_CS_N        : OUT   std_logic_vector(0 DOWNTO 0);
    DDR3_DM          : OUT   std_logic_vector(7 DOWNTO 0);
    DDR3_ODT         : OUT   std_logic_vector(0 DOWNTO 0);
    -- FMC LPC FMC112
    I2C_SCL          : INOUT std_logic;
    I2C_SDA          : INOUT std_logic;
    TRIG_OUT_0       : OUT   std_logic;
    CTRL_1           : INOUT std_logic_vector(7 DOWNTO 0);
    CLK_TO_FPGA_P_1  : IN    std_logic;
    CLK_TO_FPGA_N_1  : IN    std_logic;
    EXT_TRIGGER_P_1  : IN    std_logic;
    EXT_TRIGGER_N_1  : IN    std_logic;
    OUTA_P_1         : IN    std_logic_vector(11 DOWNTO 0);
    OUTA_N_1         : IN    std_logic_vector(11 DOWNTO 0);
    OUTB_P_1         : IN    std_logic_vector(11 DOWNTO 0);
    OUTB_N_1         : IN    std_logic_vector(11 DOWNTO 0);
    DCO_P_1          : IN    std_logic_vector(2 DOWNTO 0);
    DCO_N_1          : IN    std_logic_vector(2 DOWNTO 0);
    FRAME_P_1        : IN    std_logic_vector(2 DOWNTO 0);
    FRAME_N_1        : IN    std_logic_vector(2 DOWNTO 0);
    PRSNT_M2C_L_1    : IN    std_logic
  );
END top;

ARCHITECTURE Behavioral OF top IS
  -- Components
  COMPONENT global_clock_reset
    PORT (
      SYS_CLK_P  : IN  std_logic;
      SYS_CLK_N  : IN  std_logic;
      FORCE_RST  : IN  std_logic;
      -- output
      GLOBAL_RST : OUT std_logic;
      SYS_CLK    : OUT std_logic;
      CLK_OUT1   : OUT std_logic;
      CLK_OUT2   : OUT std_logic;
      CLK_OUT3   : OUT std_logic;
      CLK_OUT4   : OUT std_logic
    );
  END COMPONENT;
  ---------------------------------------------< ten_gig_eth
  COMPONENT ten_gig_eth
    PORT (
      REFCLK_P             : IN  std_logic;  -- 156.25MHz for transceiver
      REFCLK_N             : IN  std_logic;
      RESET                : IN  std_logic;
      SFP_TX_P             : OUT std_logic;
      SFP_TX_N             : OUT std_logic;
      SFP_RX_P             : IN  std_logic;
      SFP_RX_N             : IN  std_logic;
      SFP_LOS              : IN  std_logic;  -- loss of receiver signal
      SFP_TX_DISABLE       : OUT std_logic;
      -- clk156 domain, clock generated by the core
      CLK156               : OUT std_logic;
      PCS_PMA_CORE_STATUS  : OUT std_logic_vector(7 DOWNTO 0);
      TX_STATISTICS_VECTOR : OUT std_logic_vector(25 DOWNTO 0);
      TX_STATISTICS_VALID  : OUT std_logic;
      RX_STATISTICS_VECTOR : OUT std_logic_vector(29 DOWNTO 0);
      RX_STATISTICS_VALID  : OUT std_logic;
      PAUSE_VAL            : IN  std_logic_vector(15 DOWNTO 0);
      PAUSE_REQ            : IN  std_logic;
      TX_IFG_DELAY         : IN  std_logic_vector(7 DOWNTO 0);
      -- emac control interface
      S_AXI_ACLK           : IN  std_logic;
      S_AXI_ARESETN        : IN  std_logic;
      S_AXI_AWADDR         : IN  std_logic_vector(10 DOWNTO 0);
      S_AXI_AWVALID        : IN  std_logic;
      S_AXI_AWREADY        : OUT std_logic;
      S_AXI_WDATA          : IN  std_logic_vector(31 DOWNTO 0);
      S_AXI_WVALID         : IN  std_logic;
      S_AXI_WREADY         : OUT std_logic;
      S_AXI_BRESP          : OUT std_logic_vector(1 DOWNTO 0);
      S_AXI_BVALID         : OUT std_logic;
      S_AXI_BREADY         : IN  std_logic;
      S_AXI_ARADDR         : IN  std_logic_vector(10 DOWNTO 0);
      S_AXI_ARVALID        : IN  std_logic;
      S_AXI_ARREADY        : OUT std_logic;
      S_AXI_RDATA          : OUT std_logic_vector(31 DOWNTO 0);
      S_AXI_RRESP          : OUT std_logic_vector(1 DOWNTO 0);
      S_AXI_RVALID         : OUT std_logic;
      S_AXI_RREADY         : IN  std_logic;
      -- tx_wr_clk domain
      TX_AXIS_FIFO_ARESETN : IN  std_logic;
      TX_AXIS_FIFO_ACLK    : IN  std_logic;
      TX_AXIS_FIFO_TDATA   : IN  std_logic_vector(63 DOWNTO 0);
      TX_AXIS_FIFO_TKEEP   : IN  std_logic_vector(7 DOWNTO 0);
      TX_AXIS_FIFO_TVALID  : IN  std_logic;
      TX_AXIS_FIFO_TLAST   : IN  std_logic;
      TX_AXIS_FIFO_TREADY  : OUT std_logic;
      -- rx_rd_clk domain
      RX_AXIS_FIFO_ARESETN : IN  std_logic;
      RX_AXIS_FIFO_ACLK    : IN  std_logic;
      RX_AXIS_FIFO_TDATA   : OUT std_logic_vector(63 DOWNTO 0);
      RX_AXIS_FIFO_TKEEP   : OUT std_logic_vector(7 DOWNTO 0);
      RX_AXIS_FIFO_TVALID  : OUT std_logic;
      RX_AXIS_FIFO_TLAST   : OUT std_logic;
      RX_AXIS_FIFO_TREADY  : IN  std_logic
    );
  END COMPONENT;
  COMPONENT ten_gig_eth_packet_gen
    PORT (
      RESET          : IN  std_logic;
      MEM_CLK        : IN  std_logic;
      MEM_WE         : IN  std_logic;   -- memory write enable
      MEM_ADDR       : IN  std_logic_vector(31 DOWNTO 0);
      MEM_D          : IN  std_logic_vector(31 DOWNTO 0);  -- memory data
      --
      TX_AXIS_ACLK   : IN  std_logic;
      TX_START       : IN  std_logic;
      TX_BYTES       : IN  std_logic_vector(15 DOWNTO 0);  -- number of bytes to send
      TX_AXIS_TDATA  : OUT std_logic_vector(63 DOWNTO 0);
      TX_AXIS_TKEEP  : OUT std_logic_vector(7 DOWNTO 0);
      TX_AXIS_TVALID : OUT std_logic;
      TX_AXIS_TLAST  : OUT std_logic;
      TX_AXIS_TREADY : IN  std_logic
    );
  END COMPONENT;
  COMPONENT ten_gig_eth_rx_parser
    PORT (
      RESET                : IN  std_logic;
      RX_AXIS_FIFO_ARESETN : OUT std_logic;
      -- Everything internal to this module is synchronous to this clock `ACLK'
      RX_AXIS_FIFO_ACLK    : IN  std_logic;
      RX_AXIS_FIFO_TDATA   : IN  std_logic_vector(63 DOWNTO 0);
      RX_AXIS_FIFO_TKEEP   : IN  std_logic_vector(7 DOWNTO 0);
      RX_AXIS_FIFO_TVALID  : IN  std_logic;
      RX_AXIS_FIFO_TLAST   : IN  std_logic;
      RX_AXIS_FIFO_TREADY  : OUT std_logic;
      -- Constants
      SRC_MAC              : IN  std_logic_vector(47 DOWNTO 0);
      SRC_IP               : IN  std_logic_vector(31 DOWNTO 0);
      SRC_PORT             : IN  std_logic_vector(15 DOWNTO 0);
      -- Command output fifo interface AFTER parsing the packet
      -- dstMAC(48) dstIP(32) dstPort(16) opcode(32)
      CMD_FIFO_Q           : OUT std_logic_vector(127 DOWNTO 0);
      CMD_FIFO_EMPTY       : OUT std_logic;
      CMD_FIFO_RDREQ       : IN  std_logic;
      CMD_FIFO_RDCLK       : IN  std_logic
    );
  END COMPONENT;
  ---------------------------------------------> ten_gig_eth
  ---------------------------------------------< gig_eth
  COMPONENT gig_eth
    PORT (
      -- asynchronous reset
      GLBL_RST             : IN    std_logic;
      -- clocks
      GTX_CLK              : IN    std_logic;  -- 125MHz
      REF_CLK              : IN    std_logic;  -- 200MHz for IODELAY
      -- PHY interface
      PHY_RESETN           : OUT   std_logic;
      -- RGMII Interface
      RGMII_TXD            : OUT   std_logic_vector(3 DOWNTO 0);
      RGMII_TX_CTL         : OUT   std_logic;
      RGMII_TXC            : OUT   std_logic;
      RGMII_RXD            : IN    std_logic_vector(3 DOWNTO 0);
      RGMII_RX_CTL         : IN    std_logic;
      RGMII_RXC            : IN    std_logic;
      -- MDIO Interface
      MDIO                 : INOUT std_logic;
      MDC                  : OUT   std_logic;
      -- TCP
      TCP_CONNECTION_RESET : IN    std_logic;
      TX_TDATA             : IN    std_logic_vector(7 DOWNTO 0);
      TX_TVALID            : IN    std_logic;
      TX_TREADY            : OUT   std_logic;
      RX_TDATA             : OUT   std_logic_vector(7 DOWNTO 0);
      RX_TVALID            : OUT   std_logic;
      RX_TREADY            : IN    std_logic;
      -- FIFO
      TCP_USE_FIFO         : IN    std_logic;
      TX_FIFO_WRCLK        : IN    std_logic;
      TX_FIFO_Q            : IN    std_logic_vector(31 DOWNTO 0);
      TX_FIFO_WREN         : IN    std_logic;
      TX_FIFO_FULL         : OUT   std_logic;
      RX_FIFO_RDCLK        : IN    std_logic;
      RX_FIFO_Q            : OUT   std_logic_vector(31 DOWNTO 0);
      RX_FIFO_RDEN         : IN    std_logic;
      RX_FIFO_EMPTY        : OUT   std_logic
    );
  END COMPONENT;
  ---------------------------------------------> gig_eth
  ---------------------------------------------< UART/RS232
  COMPONENT uartio
    GENERIC (
      -- tick repetition frequency is (input freq) / (2**COUNTER_WIDTH / DIVISOR)
      COUNTER_WIDTH : positive;
      DIVISOR       : positive
    );
    PORT (
      CLK     : IN  std_logic;
      RESET   : IN  std_logic;
      RX_DATA : OUT std_logic_vector(7 DOWNTO 0);
      RX_RDY  : OUT std_logic;
      TX_DATA : IN  std_logic_vector(7 DOWNTO 0);
      TX_EN   : IN  std_logic;
      TX_RDY  : OUT std_logic;
      -- serial lines
      RX_PIN  : IN  std_logic;
      TX_PIN  : OUT std_logic
    );
  END COMPONENT;
  COMPONENT byte2cmd
    PORT (
      CLK            : IN  std_logic;
      RESET          : IN  std_logic;
      -- byte in
      RX_DATA        : IN  std_logic_vector(7 DOWNTO 0);
      RX_RDY         : IN  std_logic;
      -- cmd out
      CMD_FIFO_Q     : OUT std_logic_vector(35 DOWNTO 0);  -- command fifo data out port
      CMD_FIFO_EMPTY : OUT std_logic;   -- command fifo "emtpy" SIGNAL
      CMD_FIFO_RDCLK : IN  std_logic;
      CMD_FIFO_RDREQ : IN  std_logic    -- command fifo read request
    );
  END COMPONENT;
  COMPONENT control_interface
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
  END COMPONENT;
  ---------------------------------------------> UART/RS232
  ---------------------------------------------< SDRAM
  COMPONENT sdram_ddr3
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
      DBG_APP_ADDR          : OUT   std_logic_vector(APP_ADDR_WIDTH-1 DOWNTO 0);
      DBG_APP_EN            : OUT   std_logic;
      DBG_APP_RDY           : OUT   std_logic;
      DBG_APP_WDF_DATA      : OUT   std_logic_vector(APP_DATA_WIDTH-1 DOWNTO 0);
      DBG_APP_WDF_END       : OUT   std_logic;
      DBG_APP_WDF_WREN      : OUT   std_logic;
      DBG_APP_WDF_RDY       : OUT   std_logic;
      DBG_APP_RD_DATA       : OUT   std_logic_vector(APP_DATA_WIDTH-1 DOWNTO 0);
      DBG_APP_RD_DATA_VALID : OUT   std_logic
    );
  END COMPONENT;
  ---------------------------------------------> SDRAM
  ---------------------------------------------< FMC112  
  COMPONENT kc705_fmc112
    PORT (
      RESET           : IN    std_logic;
      CLK125          : IN    std_logic;
      CLK200          : IN    std_logic;
      GPIO_LED        : OUT   std_logic_vector(3 DOWNTO 0);
      --SIP commands
      CMD_OUT         : OUT   std_logic_vector(63 DOWNTO 0);
      CMD_OUT_VAL     : OUT   std_logic;
      CMD_IN          : IN    std_logic_vector(63 DOWNTO 0);
      CMD_IN_VAL      : IN    std_logic;
      --STAR sip_i2c_master, ID=0 (ext_i2c)
      I2C_SCL_0       : INOUT std_logic;
      I2C_SDA_0       : INOUT std_logic;
      --STAR sip_fmc_ct_gen, ID=0 (ext_fmc_ct_gen)
      TRIG_OUT_0      : OUT   std_logic;
      --STAR sip_fmc112, ID=1 (ext_fmc112)
      CTRL_1          : INOUT std_logic_vector(7 DOWNTO 0);
      CLK_TO_FPGA_P_1 : IN    std_logic;
      CLK_TO_FPGA_N_1 : IN    std_logic;
      EXT_TRIGGER_P_1 : IN    std_logic;
      EXT_TRIGGER_N_1 : IN    std_logic;
      OUTA_P_1        : IN    std_logic_vector(11 DOWNTO 0);
      OUTA_N_1        : IN    std_logic_vector(11 DOWNTO 0);
      OUTB_P_1        : IN    std_logic_vector(11 DOWNTO 0);
      OUTB_N_1        : IN    std_logic_vector(11 DOWNTO 0);
      DCO_P_1         : IN    std_logic_vector(2 DOWNTO 0);
      DCO_N_1         : IN    std_logic_vector(2 DOWNTO 0);
      FRAME_P_1       : IN    std_logic_vector(2 DOWNTO 0);
      FRAME_N_1       : IN    std_logic_vector(2 DOWNTO 0);
      PG_M2C_1        : IN    std_logic;
      PRSNT_M2C_L_1   : IN    std_logic;
      --ADC data
      phy_data_clk    : OUT   std_logic;                      -- ADC data clk
      phy_out_data0   : OUT   std_logic_vector(15 DOWNTO 0);  -- 1 sample, 16-bit format
      phy_out_data1   : OUT   std_logic_vector(15 DOWNTO 0);
      phy_out_data2   : OUT   std_logic_vector(15 DOWNTO 0);
      phy_out_data3   : OUT   std_logic_vector(15 DOWNTO 0);
      phy_out_data4   : OUT   std_logic_vector(15 DOWNTO 0);
      phy_out_data5   : OUT   std_logic_vector(15 DOWNTO 0);
      phy_out_data6   : OUT   std_logic_vector(15 DOWNTO 0);
      phy_out_data7   : OUT   std_logic_vector(15 DOWNTO 0);
      phy_out_data8   : OUT   std_logic_vector(15 DOWNTO 0);
      phy_out_data9   : OUT   std_logic_vector(15 DOWNTO 0);
      phy_out_data10  : OUT   std_logic_vector(15 DOWNTO 0);
      phy_out_data11  : OUT   std_logic_vector(15 DOWNTO 0)
    );
  END COMPONENT;
  COMPONENT pulse2pulse
    PORT (
      IN_CLK   : IN  std_logic;
      OUT_CLK  : IN  std_logic;
      RST      : IN  std_logic;
      PULSEIN  : IN  std_logic;
      INBUSY   : OUT std_logic;
      PULSEOUT : OUT std_logic
    );
  END COMPONENT;
  ---------------------------------------------> FMC112
  ---------------------------------------------< debug : ILA and VIO (`Chipscope')
  COMPONENT dbg_ila
    PORT (
      CLK    : IN std_logic;
      PROBE0 : IN std_logic_vector(63 DOWNTO 0);
      PROBE1 : IN std_logic_vector(79 DOWNTO 0);
      PROBE2 : IN std_logic_vector(79 DOWNTO 0);
      PROBE3 : IN std_logic_vector(2047 DOWNTO 0)
    );
  END COMPONENT;
  COMPONENT dbg_ila1
    PORT (
      CLK    : IN std_logic;
      PROBE0 : IN std_logic_vector(15 DOWNTO 0);
      PROBE1 : IN std_logic_vector(15 DOWNTO 0)
    );
  END COMPONENT;
  COMPONENT dbg_vio
    PORT (
      CLK        : IN  std_logic;
      PROBE_IN0  : IN  std_logic_vector(63 DOWNTO 0);
      PROBE_IN1  : IN  std_logic_vector(63 DOWNTO 0);
      PROBE_IN2  : IN  std_logic_vector(63 DOWNTO 0);
      PROBE_IN3  : IN  std_logic_vector(63 DOWNTO 0);
      PROBE_IN4  : IN  std_logic_vector(63 DOWNTO 0);
      PROBE_IN5  : IN  std_logic_vector(63 DOWNTO 0);
      PROBE_IN6  : IN  std_logic_vector(63 DOWNTO 0);
      PROBE_IN7  : IN  std_logic_vector(63 DOWNTO 0);
      PROBE_IN8  : IN  std_logic_vector(35 DOWNTO 0);
      PROBE_OUT0 : OUT std_logic_vector(63 DOWNTO 0)
    );
  END COMPONENT;
  ---------------------------------------------> debug : ILA and VIO (`Chipscope')
  COMPONENT pulsegen
    GENERIC (
      COUNTER_WIDTH : positive := 16
    );
    PORT (
      CLK    : IN  std_logic;
      PERIOD : IN  std_logic_vector(COUNTER_WIDTH-1 DOWNTO 0);
      I      : IN  std_logic;
      O      : OUT std_logic
    );
  END COMPONENT;

  -- Signals
  SIGNAL reset                             : std_logic;  
  SIGNAL sys_clk                           : std_logic;
  SIGNAL clk_50MHz                         : std_logic;
  SIGNAL clk_100MHz                        : std_logic;
  SIGNAL clk_125MHz                        : std_logic;
  SIGNAL clk_200MHz                        : std_logic;
  SIGNAL clk_250MHz                        : std_logic;
  SIGNAL clk156                            : std_logic;
  SIGNAL clk_sgmii_i                       : std_logic;
  SIGNAL clk_sgmii                         : std_logic;
  ---------------------------------------------< UART/RS232
  SIGNAL uart_rx_data                      : std_logic_vector(7 DOWNTO 0);
  SIGNAL uart_rx_rdy                       : std_logic;
  SIGNAL control_clk                       : std_logic;
  SIGNAL control_fifo_q                    : std_logic_vector(35 DOWNTO 0);
  SIGNAL control_fifo_rdreq                : std_logic;
  SIGNAL control_fifo_empty                : std_logic;
  SIGNAL control_fifo_rdclk                : std_logic;
  SIGNAL cmd_fifo_q                        : std_logic_vector(35 DOWNTO 0);
  SIGNAL cmd_fifo_empty                    : std_logic;
  SIGNAL cmd_fifo_rdreq                    : std_logic;
  -- thirtytwo 16bit registers  
  SIGNAL config_reg                        : std_logic_vector(511 DOWNTO 0);
  -- 16bit pulse register
  SIGNAL pulse_reg                         : std_logic_vector(15 DOWNTO 0);
  -- eleven 16bit registers
  SIGNAL status_reg                        : std_logic_vector(175 DOWNTO 0) := (OTHERS => '0');
  SIGNAL control_mem_we                    : std_logic;
  SIGNAL control_mem_addr                  : std_logic_vector(31 DOWNTO 0);
  SIGNAL control_mem_din                   : std_logic_vector(31 DOWNTO 0);
  ---------------------------------------------> UART/RS232
  ---------------------------------------------< ten_gig_eth 
  SIGNAL sfp_tx_disable_i                  : std_logic;
  SIGNAL sPcs_pma_core_status              : std_logic_vector(7 DOWNTO 0);
  SIGNAL sEmac_status_vector               : std_logic_vector(1 DOWNTO 0);
  SIGNAL sTx_axis_fifo_aresetn             : std_logic;
  SIGNAL sTx_axis_fifo_aclk                : std_logic;
  SIGNAL sTx_axis_fifo_tdata               : std_logic_vector(63 DOWNTO 0);
  SIGNAL sTx_axis_fifo_tkeep               : std_logic_vector(7 DOWNTO 0);
  SIGNAL sTx_axis_fifo_tvalid              : std_logic;
  SIGNAL sTx_axis_fifo_tlast               : std_logic;
  SIGNAL sTx_axis_fifo_tready              : std_logic;
  SIGNAL sRx_axis_fifo_aresetn             : std_logic;
  SIGNAL sRx_axis_fifo_aclk                : std_logic;
  SIGNAL sRx_axis_fifo_tdata               : std_logic_vector(63 DOWNTO 0);
  SIGNAL sRx_axis_fifo_tkeep               : std_logic_vector(7 DOWNTO 0);
  SIGNAL sRx_axis_fifo_tvalid              : std_logic;
  SIGNAL sRx_axis_fifo_tlast               : std_logic;
  SIGNAL sRx_axis_fifo_tready              : std_logic;
  -- control interface
  SIGNAL s_axi_aclk                        : std_logic;
  SIGNAL s_axi_aresetn                     : std_logic;
  SIGNAL s_axi_awaddr                      : std_logic_vector(10 DOWNTO 0);
  SIGNAL s_axi_awvalid                     : std_logic;
  SIGNAL s_axi_awready                     : std_logic;
  SIGNAL s_axi_wdata                       : std_logic_vector(31 DOWNTO 0);
  SIGNAL s_axi_wvalid                      : std_logic;
  SIGNAL s_axi_wready                      : std_logic;
  SIGNAL s_axi_bresp                       : std_logic_vector(1 DOWNTO 0);
  SIGNAL s_axi_bvalid                      : std_logic;
  SIGNAL s_axi_bready                      : std_logic;
  SIGNAL s_axi_araddr                      : std_logic_vector(10 DOWNTO 0);
  SIGNAL s_axi_arvalid                     : std_logic;
  SIGNAL s_axi_arready                     : std_logic;
  SIGNAL s_axi_rdata                       : std_logic_vector(31 DOWNTO 0);
  SIGNAL s_axi_rresp                       : std_logic_vector(1 DOWNTO 0);
  SIGNAL s_axi_rvalid                      : std_logic;
  SIGNAL s_axi_rready                      : std_logic;
  -- packets
  SIGNAL ten_gig_eth_tx_start              : std_logic;
  SIGNAL tge_cmd_fifo_q                    : std_logic_vector(127 DOWNTO 0);
  SIGNAL tge_cmd_fifo_empty                : std_logic;
  SIGNAL tge_cmd_fifo_rdreq                : std_logic;
  ---------------------------------------------> ten_gig_eth
  SIGNAL usr_data_output                   : std_logic_vector (7 DOWNTO 0);
  ---------------------------------------------< gig_eth
  SIGNAL gig_eth_tx_tdata                  : std_logic_vector(7 DOWNTO 0);
  SIGNAL gig_eth_tx_tvalid                 : std_logic;
  SIGNAL gig_eth_tx_tready                 : std_logic;  
  SIGNAL gig_eth_rx_tdata                  : std_logic_vector(7 DOWNTO 0);
  SIGNAL gig_eth_rx_tvalid                 : std_logic;
  SIGNAL gig_eth_rx_tready                 : std_logic;
  SIGNAL gig_eth_tcp_use_fifo              : std_logic;
  SIGNAL gig_eth_tx_fifo_wrclk             : std_logic;
  SIGNAL gig_eth_tx_fifo_q                 : std_logic_vector(31 DOWNTO 0);
  SIGNAL gig_eth_tx_fifo_wren              : std_logic;
  SIGNAL gig_eth_tx_fifo_full              : std_logic;
  SIGNAL gig_eth_rx_fifo_rdclk             : std_logic;
  SIGNAL gig_eth_rx_fifo_q                 : std_logic_vector(31 DOWNTO 0);
  SIGNAL gig_eth_rx_fifo_rden              : std_logic;
  SIGNAL gig_eth_rx_fifo_empty             : std_logic;
  ---------------------------------------------> gig_eth
  ---------------------------------------------< SDRAM
  SIGNAL sdram_app_addr                    : std_logic_vector(28-1 DOWNTO 0);
  SIGNAL sdram_app_en                      : std_logic;
  SIGNAL sdram_app_rdy                     : std_logic;
  SIGNAL sdram_app_wdf_data                : std_logic_vector(512-1 DOWNTO 0);
  SIGNAL sdram_app_wdf_end                 : std_logic;
  SIGNAL sdram_app_wdf_wren                : std_logic;
  SIGNAL sdram_app_wdf_rdy                 : std_logic;
  SIGNAL sdram_app_rd_data                 : std_logic_vector(512-1 DOWNTO 0);
  SIGNAL sdram_app_rd_data_valid           : std_logic;
  ---------------------------------------------> SDRAM
  ---------------------------------------------< FMC112
  SIGNAL fmc112_cmd_out                    : std_logic_vector(63 DOWNTO 0);
  SIGNAL fmc112_cmd_out_val                : std_logic;
  SIGNAL fmc112_cmd_in                     : std_logic_vector(63 DOWNTO 0);
  SIGNAL fmc112_cmd_in_val                 : std_logic;
  SIGNAL fmc112_adc_data_clk               : std_logic;
  SIGNAL fmc112_adc_data0                  : std_logic_vector(15 DOWNTO 0);
  SIGNAL fmc112_adc_data1                  : std_logic_vector(15 DOWNTO 0);
  SIGNAL fmc112_adc_data2                  : std_logic_vector(15 DOWNTO 0);
  SIGNAL fmc112_adc_data3                  : std_logic_vector(15 DOWNTO 0);
  SIGNAL fmc112_adc_data4                  : std_logic_vector(15 DOWNTO 0);
  SIGNAL fmc112_adc_data5                  : std_logic_vector(15 DOWNTO 0);
  SIGNAL fmc112_adc_data6                  : std_logic_vector(15 DOWNTO 0);
  SIGNAL fmc112_adc_data7                  : std_logic_vector(15 DOWNTO 0);
  SIGNAL fmc112_adc_data8                  : std_logic_vector(15 DOWNTO 0);
  SIGNAL fmc112_adc_data9                  : std_logic_vector(15 DOWNTO 0);
  SIGNAL fmc112_adc_data10                 : std_logic_vector(15 DOWNTO 0);
  SIGNAL fmc112_adc_data11                 : std_logic_vector(15 DOWNTO 0);
  SIGNAL fmc112_data_fifo_rdclk            : std_logic;
  SIGNAL fmc112_data_fifo_din              : std_logic_vector(127 DOWNTO 0);
  SIGNAL fmc112_data_fifo_wren             : std_logic;
  SIGNAL fmc112_data_fifo_rden             : std_logic;
  SIGNAL fmc112_data_fifo_dout             : std_logic_vector(31 DOWNTO 0);
  SIGNAL fmc112_data_fifo_full             : std_logic;
  SIGNAL fmc112_data_fifo_empty            : std_logic;
  ---------------------------------------------> FMC112
  ---------------------------------------------< debug
  SIGNAL dbg_ila_probe0                           : std_logic_vector (63 DOWNTO 0);
  SIGNAL dbg_ila_probe1                           : std_logic_vector (79 DOWNTO 0);
  SIGNAL dbg_ila_probe2                           : std_logic_vector (79 DOWNTO 0);
  SIGNAL dbg_ila_probe3                           : std_logic_vector (2047 DOWNTO 0);
  SIGNAL dbg_vio_probe_out0                       : std_logic_vector (63 DOWNTO 0);
  SIGNAL dbg_ila1_probe0                          : std_logic_vector (15 DOWNTO 0);
  SIGNAL dbg_ila1_probe1                          : std_logic_vector (15 DOWNTO 0);
  ATTRIBUTE mark_debug                            : string;
  ATTRIBUTE keep                                  : string;
  ATTRIBUTE mark_debug OF USB_TX                  : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF uart_rx_data            : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF uart_rx_rdy             : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF cmd_fifo_q              : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF cmd_fifo_empty          : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF cmd_fifo_rdreq          : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF config_reg              : SIGNAL IS "true";
--ATTRIBUTE mark_debug OF status_reg              : SIGNAL IS "true";
--ATTRIBUTE mark_debug OF pulse_reg               : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF control_mem_we          : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF control_mem_addr        : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF control_mem_din         : SIGNAL IS "true";
  --
  ATTRIBUTE mark_debug OF sPcs_pma_core_status    : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sEmac_status_vector     : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sTx_axis_fifo_aresetn   : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sTx_axis_fifo_aclk      : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sTx_axis_fifo_tdata     : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sTx_axis_fifo_tkeep     : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sTx_axis_fifo_tvalid    : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sTx_axis_fifo_tlast     : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sTx_axis_fifo_tready    : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sRx_axis_fifo_aresetn   : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sRx_axis_fifo_aclk      : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sRx_axis_fifo_tdata     : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sRx_axis_fifo_tkeep     : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sRx_axis_fifo_tvalid    : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sRx_axis_fifo_tlast     : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sRx_axis_fifo_tready    : SIGNAL IS "true";
  --ATTRIBUTE mark_debug OF ten_gig_eth_tx_start    : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF tge_cmd_fifo_q          : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF tge_cmd_fifo_empty      : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF tge_cmd_fifo_rdreq      : SIGNAL IS "true";
  --
  ATTRIBUTE mark_debug OF gig_eth_tx_tdata        : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF gig_eth_tx_tvalid       : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF gig_eth_tx_tready       : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF gig_eth_rx_tdata        : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF gig_eth_rx_tvalid       : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF gig_eth_rx_tready       : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF gig_eth_tx_fifo_q       : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF gig_eth_rx_fifo_q       : SIGNAL IS "true";
  --
  ATTRIBUTE mark_debug OF sdram_app_addr          : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sdram_app_en            : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sdram_app_rdy           : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sdram_app_wdf_data      : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sdram_app_wdf_end       : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sdram_app_wdf_wren      : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sdram_app_wdf_rdy       : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sdram_app_rd_data       : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF sdram_app_rd_data_valid : SIGNAL IS "true";
  --
  ATTRIBUTE mark_debug OF fmc112_cmd_out          : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF fmc112_cmd_out_val      : SIGNAL IS "true";
  ATTRIBUTE mark_debug OF fmc112_cmd_in_val       : SIGNAL IS "true";
  ---------------------------------------------> debug

BEGIN
  ---------------------------------------------< Clock
  global_clock_reset_inst : global_clock_reset
    PORT MAP (
      SYS_CLK_P  => SYS_CLK_P,
      SYS_CLK_N  => SYS_CLK_N,
      FORCE_RST  => SYS_RST,
      -- output
      GLOBAL_RST => reset,
      SYS_CLK    => sys_clk,
      CLK_OUT1   => clk_50MHz,
      CLK_OUT2   => clk_100MHz,
      CLK_OUT3   => OPEN,
      CLK_OUT4   => clk_250MHz
    );

  -- gtx/gth reference clock can be used as general purpose clock this way
  sgmiiclk_ibufds_inst : IBUFDS_GTE2
    PORT MAP (
      O     => clk_sgmii_i,
      ODIV2 => OPEN,
      CEB   => '0',
      I     => SGMIICLK_Q0_P,
      IB    => SGMIICLK_Q0_N
    );
  sgmiiclk_bufg_inst : BUFG
    PORT MAP (
      I => clk_sgmii_i,
      O => clk_sgmii
    );
  clk_125MHz <= clk_sgmii;
  ---------------------------------------------> Clock
  ---------------------------------------------< debug : ILA and VIO (`Chipscope')
  dbg_cores : IF ENABLE_DEBUG GENERATE
    dbg_ila_inst : dbg_ila
      PORT MAP (
        CLK    => sys_clk,
        PROBE0 => dbg_ila_probe0,
        PROBE1 => dbg_ila_probe1,
        PROBE2 => dbg_ila_probe2,
        PROBE3 => dbg_ila_probe3
      );
    dbg_vio_inst : dbg_vio
      PORT MAP (
        CLK        => sys_clk,
        PROBE_IN0  => config_reg(64*1-1 DOWNTO 64*0),
        PROBE_IN1  => config_reg(64*2-1 DOWNTO 64*1),
        PROBE_IN2  => config_reg(64*3-1 DOWNTO 64*2),
        PROBE_IN3  => config_reg(64*4-1 DOWNTO 64*3),
        PROBE_IN4  => config_reg(64*5-1 DOWNTO 64*4),
        PROBE_IN5  => config_reg(64*6-1 DOWNTO 64*5),
        PROBE_IN6  => config_reg(64*7-1 DOWNTO 64*6),
        PROBE_IN7  => x"00000000000000" & sPcs_pma_core_status, -- config_reg(64*8-1 DOWNTO 64*7),
        PROBE_IN8  => cmd_fifo_q,
        PROBE_OUT0 => dbg_vio_probe_out0
      );
    --dbg_ila1_inst : dbg_ila1
    --  PORT MAP (
    --    CLK    => fmc112_adc_data_clk,
    --    PROBE0 => dbg_ila1_probe0,
    --    PROBE1 => dbg_ila1_probe1
    --  );
  END GENERATE dbg_cores;
  ---------------------------------------------> debug : ILA and VIO (`Chipscope')
  ---------------------------------------------< UART/RS232
  uartio_inst : uartio
    GENERIC MAP (
      -- tick repetition frequency is (input freq) / (2**COUNTER_WIDTH / DIVISOR)
      COUNTER_WIDTH => 16,
      DIVISOR       => 1208*2
    )
    PORT MAP (
      CLK     => clk_50MHz,
      RESET   => reset,
      RX_DATA => uart_rx_data,
      RX_RDY  => uart_rx_rdy,
      TX_DATA => "0000" & DIPSw4Bit,
      TX_EN   => '1',
      TX_RDY  => dbg_ila_probe0(2),
      -- serial lines
      RX_PIN  => USB_TX,                -- notice the pin swap
      TX_PIN  => USB_RX
    );

  --dbg_ila1_probe0(7 DOWNTO 0)  <= uart_rx_data;
  --dbg_ila1_probe0(8)           <= uart_rx_rdy;
  --dbg_ila1_probe0(9)           <= USB_TX;

  -- dbg_ila_probe0(63 DOWNTO 32) <= cmd_fifo_q(31 DOWNTO 0);
  dbg_ila_probe0(31)           <= cmd_fifo_empty;
  dbg_ila_probe0(30)           <= cmd_fifo_rdreq;

  byte2cmd_inst : byte2cmd
    PORT MAP (
      CLK            => clk_50MHz,
      RESET          => reset,
      -- byte in
      RX_DATA        => uart_rx_data,
      RX_RDY         => uart_rx_rdy,
      -- cmd out
      CMD_FIFO_Q     => OPEN,-- cmd_fifo_q,
      CMD_FIFO_EMPTY => OPEN,-- cmd_fifo_empty,
      CMD_FIFO_RDCLK => control_clk,
      CMD_FIFO_RDREQ => '0'  -- cmd_fifo_rdreq
    );

  control_clk <= clk_100MHz;
  control_interface_inst : control_interface
    PORT MAP (
      RESET => reset,
      CLK   => control_clk,
      -- From FPGA to PC
      FIFO_Q          => control_fifo_q,
      FIFO_EMPTY      => control_fifo_empty,
      FIFO_RDREQ      => control_fifo_rdreq,
      FIFO_RDCLK      => control_fifo_rdclk,
      -- From PC to FPGA, FWFT
      CMD_FIFO_Q      => cmd_fifo_q,
      CMD_FIFO_EMPTY  => cmd_fifo_empty,
      CMD_FIFO_RDREQ  => cmd_fifo_rdreq,
      -- Digital I/O
      CONFIG_REG      => config_reg,
      PULSE_REG       => pulse_reg,
      STATUS_REG      => status_reg,
      -- Memory interface
      MEM_WE          => control_mem_we,
      MEM_ADDR        => control_mem_addr,
      MEM_DIN         => control_mem_din,
      MEM_DOUT        => (OTHERS => '0'),
      -- Data FIFO interface, FWFT
      DATA_FIFO_Q     => fmc112_data_fifo_dout,
      DATA_FIFO_EMPTY => fmc112_data_fifo_empty,
      DATA_FIFO_RDREQ => fmc112_data_fifo_rden,
      DATA_FIFO_RDCLK => fmc112_data_fifo_rdclk
    );
  dbg_ila_probe0(18 DOWNTO 3) <= pulse_reg;
  ---------------------------------------------> UART/RS232
  ---------------------------------------------< ten_gig_eth
  ten_gig_eth_cores : IF ENABLE_TEN_GIG_ETH GENERATE
    ten_gig_eth_inst : ten_gig_eth
      PORT MAP (
        REFCLK_P             => USER_CLK_P,  -- 156.25MHz for transceiver
        REFCLK_N             => USER_CLK_N,
        RESET                => reset,
        SFP_TX_P             => SFP_TX_P,
        SFP_TX_N             => SFP_TX_N,
        SFP_RX_P             => SFP_RX_P,
        SFP_RX_N             => SFP_RX_N,
        SFP_LOS              => SFP_LOS_LS,  -- loss of receiver signal
        SFP_TX_DISABLE       => sfp_tx_disable_i,
        -- clk156 domain, clock generated by the core
        CLK156               => clk156,
        PCS_PMA_CORE_STATUS  => sPcs_pma_core_status,
        TX_STATISTICS_VECTOR => OPEN,
        TX_STATISTICS_VALID  => OPEN,
        RX_STATISTICS_VECTOR => OPEN,
        RX_STATISTICS_VALID  => OPEN,
        PAUSE_VAL            => (OTHERS => '0'),
        PAUSE_REQ            => '0',
        TX_IFG_DELAY         => x"ff",
        -- emac control interface
        S_AXI_ACLK           => s_axi_aclk,
        S_AXI_ARESETN        => s_axi_aresetn,
        S_AXI_AWADDR         => s_axi_awaddr,
        S_AXI_AWVALID        => s_axi_awvalid,
        S_AXI_AWREADY        => s_axi_awready,
        S_AXI_WDATA          => s_axi_wdata,
        S_AXI_WVALID         => s_axi_wvalid,
        S_AXI_WREADY         => s_axi_wready,
        S_AXI_BRESP          => s_axi_bresp,
        S_AXI_BVALID         => s_axi_bvalid,
        S_AXI_BREADY         => s_axi_bready,
        S_AXI_ARADDR         => s_axi_araddr,
        S_AXI_ARVALID        => s_axi_arvalid,
        S_AXI_ARREADY        => s_axi_arready,
        S_AXI_RDATA          => s_axi_rdata,
        S_AXI_RRESP          => s_axi_rresp,
        S_AXI_RVALID         => s_axi_rvalid,
        S_AXI_RREADY         => s_axi_rready,
        -- tx_wr_clk domain
        TX_AXIS_FIFO_ARESETN => sTx_axis_fifo_aresetn,
        Tx_AXIS_FIFO_ACLK    => sTx_axis_fifo_aclk,
        TX_AXIS_FIFO_TDATA   => sTx_axis_fifo_tdata,
        TX_AXIS_FIFO_TKEEP   => sTx_axis_fifo_tkeep,
        TX_AXIS_FIFO_TVALID  => sTx_axis_fifo_tvalid,
        TX_AXIS_FIFO_TLAST   => sTx_axis_fifo_tlast,
        TX_AXIS_FIFO_TREADY  => sTx_axis_fifo_tready,
        -- rx_rd_clk domain
        RX_AXIS_FIFO_ARESETN => sRx_axis_fifo_aresetn,
        RX_AXIS_FIFO_ACLK    => sRx_axis_fifo_aclk,
        RX_AXIS_FIFO_TDATA   => sRx_axis_fifo_tdata,
        RX_AXIS_FIFO_TKEEP   => sRx_axis_fifo_tkeep,
        RX_AXIS_FIFO_TVALID  => sRx_axis_fifo_tvalid,
        RX_AXIS_FIFO_TLAST   => sRx_axis_fifo_tlast,
        RX_AXIS_FIFO_TREADY  => sRx_axis_fifo_tready
      );

    SFP_TX_DISABLE_N   <= NOT sfp_tx_disable_i;
    LED8Bit(7)         <= sPcs_pma_core_status(0);
    LED8Bit(6)         <= NOT sfp_tx_disable_i;
    LED8Bit(5)         <= NOT SFP_LOS_LS;
    s_axi_aclk         <= clk_50MHz;
    sTx_axis_fifo_aclk <= clk_200MHz;
    sRx_axis_fifo_aclk <= sTx_axis_fifo_aclk;

    s_axi_aresetn         <= '1';
    sTx_axis_fifo_aresetn <= '1';
    sRx_axis_fifo_aresetn <= '1';

    ten_gig_eth_packet_gen_inst : ten_gig_eth_packet_gen
      PORT MAP (
        RESET          => reset,
        MEM_CLK        => control_clk,
        MEM_WE         => control_mem_we,
        MEM_ADDR       => control_mem_addr,
        MEM_D          => control_mem_din,
        --
        TX_AXIS_ACLK   => sTx_axis_fifo_aclk,
        TX_START       => ten_gig_eth_tx_start,
        TX_BYTES       => config_reg(15 DOWNTO 0),
        TX_AXIS_TDATA  => OPEN, -- sTx_axis_fifo_tdata,
        TX_AXIS_TKEEP  => sTx_axis_fifo_tkeep,
        TX_AXIS_TVALID => sTx_axis_fifo_tvalid,
        TX_AXIS_TLAST  => sTx_axis_fifo_tlast,
        TX_AXIS_TREADY => sTx_axis_fifo_tready
      );

    ten_gig_eth_rx_parser_inst : ten_gig_eth_rx_parser
      PORT MAP (
        RESET                => reset,
        RX_AXIS_FIFO_ARESETN => sRx_axis_fifo_aresetn,
        -- Everything internal to this module is synchronous to this clock `ACLK'
        RX_AXIS_FIFO_ACLK    => sRx_axis_fifo_aclk,
        RX_AXIS_FIFO_TDATA   => sRx_axis_fifo_tdata,
        RX_AXIS_FIFO_TKEEP   => sRx_axis_fifo_tkeep,
        RX_AXIS_FIFO_TVALID  => sRx_axis_fifo_tvalid,
        RX_AXIS_FIFO_TLAST   => sRx_axis_fifo_tlast,
        RX_AXIS_FIFO_TREADY  => sRx_axis_fifo_tready,
        -- Constants
        SRC_MAC              => x"000a3502a759",
        SRC_IP               => x"c0a80302",
        SRC_PORT             => x"ea62",
        -- Command output fifo interface AFTER parsing the packet
        -- dstMAC(48) dstIP(32) dstPort(16) opcode(32)
        CMD_FIFO_Q           => tge_cmd_fifo_q,
        CMD_FIFO_EMPTY       => tge_cmd_fifo_empty,
        CMD_FIFO_RDREQ       => '1',
        CMD_FIFO_RDCLK       => clk_200MHz
      );

    --pulsegen_inst : pulsegen
    --  GENERIC MAP (
    --    COUNTER_WIDTH => 16
    --  )
    --  PORT MAP (
    --    CLK    => sTx_axis_fifo_aclk,
    --    PERIOD => config_reg(31 DOWNTO 16),
    --    I      => pulse_reg(0),
    --    O      => ten_gig_eth_tx_start
    --  );
    ten_gig_eth_tx_start <= pulse_reg(0);

    dbg_ila_probe0(0) <= clk156;
    dbg_ila_probe0(1) <= ten_gig_eth_tx_start;

    dbg_ila_probe1(79 DOWNTO 16) <= sTx_axis_fifo_tdata;
    dbg_ila_probe1(15 DOWNTO 8)  <= sTx_axis_fifo_tkeep;
    dbg_ila_probe1(7)            <= sTx_axis_fifo_tvalid;
    dbg_ila_probe1(6)            <= sTx_axis_fifo_tlast;
    dbg_ila_probe1(5)            <= sTx_axis_fifo_tready;
    --dbg_ila_probe2(79 DOWNTO 16) <= sRx_axis_fifo_tdata;
    --dbg_ila_probe2(79 DOWNTO 48) <= control_mem_addr;
    --dbg_ila_probe2(47 DOWNTO 16) <= control_mem_din;
    --dbg_ila_probe2(15 DOWNTO 8)  <= sRx_axis_fifo_tkeep;
    dbg_ila_probe2(7)            <= sRx_axis_fifo_tvalid;
    dbg_ila_probe2(6)            <= sRx_axis_fifo_tlast;
    dbg_ila_probe2(5)            <= sRx_axis_fifo_tready;
    dbg_ila_probe2(4)            <= control_mem_we;
    --
    --dbg_ila_probe3(127 DOWNTO 0) <= tge_cmd_fifo_q;
    --dbg_ila_probe3(128)          <= tge_cmd_fifo_empty;
  END GENERATE ten_gig_eth_cores;
  ---------------------------------------------> ten_gig_eth
  ---------------------------------------------< gig_eth
  gig_eth_cores : IF ENABLE_GIG_ETH GENERATE
    gig_eth_inst : gig_eth
      PORT MAP (
        -- asynchronous reset
        GLBL_RST             => reset,
        -- clocks
        GTX_CLK              => clk_125MHz,
        REF_CLK              => sys_clk, -- 200MHz for IODELAY
        -- PHY interface
        PHY_RESETN           => PHY_RESET_N,
        -- RGMII Interface
        RGMII_TXD            => RGMII_TXD,
        RGMII_TX_CTL         => RGMII_TX_CTL,
        RGMII_TXC            => RGMII_TXC,
        RGMII_RXD            => RGMII_RXD,
        RGMII_RX_CTL         => RGMII_RX_CTL,
        RGMII_RXC            => RGMII_RXC,
        -- MDIO Interface
        MDIO                 => MDIO,
        MDC                  => MDC,
        -- TCP
        TCP_CONNECTION_RESET => '0',
        TX_TDATA             => gig_eth_tx_tdata,
        TX_TVALID            => gig_eth_tx_tvalid,
        TX_TREADY            => gig_eth_tx_tready,
        RX_TDATA             => gig_eth_rx_tdata,
        RX_TVALID            => gig_eth_rx_tvalid,
        RX_TREADY            => gig_eth_rx_tready,
        -- FIFO
        TCP_USE_FIFO         => gig_eth_tcp_use_fifo,
        TX_FIFO_WRCLK        => gig_eth_tx_fifo_wrclk,
        TX_FIFO_Q            => gig_eth_tx_fifo_q,
        TX_FIFO_WREN         => gig_eth_tx_fifo_wren,
        TX_FIFO_FULL         => gig_eth_tx_fifo_full,
        RX_FIFO_RDCLK        => gig_eth_rx_fifo_rdclk,
        RX_FIFO_Q            => gig_eth_rx_fifo_q,
        RX_FIFO_RDEN         => gig_eth_rx_fifo_rden,
        RX_FIFO_EMPTY        => gig_eth_rx_fifo_empty
      );
    dbg_ila_probe0(26 DOWNTO 19) <= gig_eth_rx_tdata;
    dbg_ila_probe0(27)           <= gig_eth_rx_tvalid;
    dbg_ila_probe0(28)           <= gig_eth_rx_tready;

    -- loopback
    --gig_eth_tx_tdata  <= gig_eth_rx_tdata;
    --gig_eth_tx_tvalid <= gig_eth_rx_tvalid;
    --gig_eth_rx_tready <= gig_eth_tx_tready;

    -- receive to cmd_fifo
    gig_eth_tcp_use_fifo         <= '1';
    gig_eth_rx_fifo_rdclk        <= control_clk;
    cmd_fifo_q(31 DOWNTO 0)      <= gig_eth_rx_fifo_q;
    dbg_ila_probe0(63 DOWNTO 32) <= gig_eth_rx_fifo_q;
    cmd_fifo_empty               <= gig_eth_rx_fifo_empty;
    gig_eth_rx_fifo_rden         <= cmd_fifo_rdreq;

    -- send control_fifo data through gig_eth_tx_fifo
    gig_eth_tx_fifo_wrclk <= clk_125MHz;
    control_fifo_rdclk    <= gig_eth_tx_fifo_wrclk;
    PROCESS (control_fifo_rdclk) IS     -- use DFF to delay half a clock cycle
    BEGIN
      IF falling_edge(control_fifo_rdclk) THEN
        gig_eth_tx_fifo_q <= control_fifo_q(31 DOWNTO 0);
      END IF;
    END PROCESS;
    gig_eth_tx_fifo_wren <= NOT control_fifo_empty;
    control_fifo_rdreq   <= NOT gig_eth_tx_fifo_full;
  END GENERATE gig_eth_cores;
  ---------------------------------------------> gig_eth
  ---------------------------------------------< SDRAM
  sdram_ddr3_inst : sdram_ddr3
    PORT MAP (
      CLK                   => sys_clk,  -- system clock, must be the same as intended in MIG
      REFCLK                => sys_clk,  -- 200MHz for iodelay
      RESET                 => reset,
      -- SDRAM_DDR3
      -- Inouts
      DDR3_DQ               => DDR3_DQ,
      DDR3_DQS_P            => DDR3_DQS_P,
      DDR3_DQS_N            => DDR3_DQS_N,
      -- Outputs
      DDR3_ADDR             => DDR3_ADDR,
      DDR3_BA               => DDR3_BA,
      DDR3_RAS_N            => DDR3_RAS_N,
      DDR3_CAS_N            => DDR3_CAS_N,
      DDR3_WE_N             => DDR3_WE_N,
      DDR3_RESET_N          => DDR3_RESET_N,
      DDR3_CK_P             => DDR3_CK_P,
      DDR3_CK_N             => DDR3_CK_N,
      DDR3_CKE              => DDR3_CKE,
      DDR3_CS_N             => DDR3_CS_N,
      DDR3_DM               => DDR3_DM,
      DDR3_ODT              => DDR3_ODT,
      -- Status Outputs
      INIT_CALIB_COMPLETE   => LED8Bit(4),
      -- Internal data r/w interface
      UI_CLK                => clk_200MHz,
      --
      WR_START              => pulse_reg(3),
      WR_ADDR_BEGIN         => config_reg(32*4+27 DOWNTO 32*4),
      WR_STOP               => pulse_reg(4),
      WR_WRAP_AROUND        => config_reg(32*4+28),
      POST_TRIGGER          => config_reg(32*5+27 DOWNTO 32*5),
      WR_BUSY               => status_reg(64*2+28),
      WR_POINTER            => OPEN,
      TRIGGER_POINTER       => status_reg(64*2+27 DOWNTO 64*2),
      WR_WRAPPED            => status_reg(64*2+29),
      RD_START              => pulse_reg(5),
      RD_ADDR_BEGIN         => (OTHERS => '0'),
      RD_ADDR_END           => config_reg(32*6+27 DOWNTO 32*6),
      RD_BUSY               => status_reg(64*2+30),
      --
      DATA_FIFO_RESET       => pulse_reg(2),
      INDATA_FIFO_WRCLK     => fmc112_adc_data_clk,
      INDATA_FIFO_Q         => fmc112_data_fifo_din,
      INDATA_FIFO_FULL      => fmc112_data_fifo_full,
      INDATA_FIFO_WREN      => fmc112_data_fifo_wren,
      --
      OUTDATA_FIFO_RDCLK    => fmc112_data_fifo_rdclk,
      OUTDATA_FIFO_Q        => fmc112_data_fifo_dout,
      OUTDATA_FIFO_EMPTY    => fmc112_data_fifo_empty,
      OUTDATA_FIFO_RDEN     => fmc112_data_fifo_rden,
      --
      DBG_APP_ADDR          => sdram_app_addr,
      DBG_APP_EN            => sdram_app_en,
      DBG_APP_RDY           => sdram_app_rdy,
      DBG_APP_WDF_DATA      => sdram_app_wdf_data,
      DBG_APP_WDF_END       => sdram_app_wdf_end,
      DBG_APP_WDF_WREN      => sdram_app_wdf_wren,
      DBG_APP_WDF_RDY       => sdram_app_wdf_rdy,
      DBG_APP_RD_DATA       => sdram_app_rd_data,
      DBG_APP_RD_DATA_VALID => sdram_app_rd_data_valid
    );
  dbg_ila_probe3(27 DOWNTO 0)               <= sdram_app_addr;
  dbg_ila_probe3(28)                        <= sdram_app_en;
  dbg_ila_probe3(29)                        <= sdram_app_rdy;
  dbg_ila_probe3(30)                        <= sdram_app_wdf_wren;
  dbg_ila_probe3(31)                        <= sdram_app_wdf_rdy;
  dbg_ila_probe3(32)                        <= sdram_app_wdf_end;
  dbg_ila_probe3(1023 DOWNTO 512)           <= sdram_app_wdf_data;
  dbg_ila_probe3(1024+1023 DOWNTO 1024+512) <= sdram_app_rd_data;
  dbg_ila_probe3(33)                        <= sdram_app_rd_data_valid;
  dbg_ila_probe3(511 DOWNTO 336)            <= status_reg;
  ---------------------------------------------> SDRAM
  ---------------------------------------------< FMC112  
  kc705_fmc112_inst : kc705_fmc112
    PORT MAP (
      RESET           => reset,
      CLK125          => clk_125MHz,
      CLK200          => sys_clk,
      GPIO_LED        => OPEN,
      --SIP commands
      CMD_OUT         => fmc112_cmd_out,
      CMD_OUT_VAL     => fmc112_cmd_out_val,
      CMD_IN          => fmc112_cmd_in,
      CMD_IN_VAL      => fmc112_cmd_in_val,
      --STAR sip_i2c_master, ID=0 (ext_i2c)
      I2C_SCL_0       => I2C_SCL,
      I2C_SDA_0       => I2C_SDA,
      --STAR sip_fmc_ct_gen, ID=0 (ext_fmc_ct_gen)
      TRIG_OUT_0      => TRIG_OUT_0,
      --STAR sip_fmc112, ID=1 (ext_fmc112)
      CTRL_1          => CTRL_1,
      CLK_TO_FPGA_P_1 => CLK_TO_FPGA_P_1,
      CLK_TO_FPGA_N_1 => CLK_TO_FPGA_N_1,
      EXT_TRIGGER_P_1 => EXT_TRIGGER_P_1,
      EXT_TRIGGER_N_1 => EXT_TRIGGER_N_1,
      OUTA_P_1        => OUTA_P_1,
      OUTA_N_1        => OUTA_N_1,
      OUTB_P_1        => OUTB_P_1,
      OUTB_N_1        => OUTB_N_1,
      DCO_P_1         => DCO_P_1,        
      DCO_N_1         => DCO_N_1,        
      FRAME_P_1       => FRAME_P_1,
      FRAME_N_1       => FRAME_N_1,
      PG_M2C_1        => '0',
      PRSNT_M2C_L_1   => PRSNT_M2C_L_1,
      --ADC Data
      PHY_DATA_CLK    => fmc112_adc_data_clk,
      PHY_OUT_DATA0   => fmc112_adc_data0,
      PHY_OUT_DATA1   => fmc112_adc_data1,
      PHY_OUT_DATA2   => fmc112_adc_data2,
      PHY_OUT_DATA3   => fmc112_adc_data3,
      PHY_OUT_DATA4   => fmc112_adc_data4,
      PHY_OUT_DATA5   => fmc112_adc_data5,
      PHY_OUT_DATA6   => fmc112_adc_data6,
      PHY_OUT_DATA7   => fmc112_adc_data7,
      PHY_OUT_DATA8   => fmc112_adc_data8,
      PHY_OUT_DATA9   => fmc112_adc_data9,
      PHY_OUT_DATA10  => fmc112_adc_data10,
      PHY_OUT_DATA11  => fmc112_adc_data11
    );
  fmc112_cmd_in <= config_reg(64*2-1 DOWNTO 64*1);  
  fmc112_cmd_in_val_sync : pulse2pulse
    PORT MAP (
      IN_CLK   => control_clk,
      OUT_CLK  => clk_125MHz,
      RST      => reset,
      PULSEIN  => pulse_reg(1),
      INBUSY   => OPEN,
      PULSEOUT => fmc112_cmd_in_val
    );
  PROCESS (clk_125MHz) IS
  BEGIN
    IF falling_edge(clk_125MHz) THEN  -- register for status_reg to read it
      IF fmc112_cmd_out_val = '1' THEN
        status_reg(64*2-1 DOWNTO 64*1) <= fmc112_cmd_out;          
      END IF;
    END IF;
  END PROCESS;
  --
  PROCESS (fmc112_adc_data_clk) IS
  BEGIN
    IF falling_edge(fmc112_adc_data_clk) THEN  -- register half-cycle earlier
      -- swap for correct endian on x86 computer (through tcp core transmission)
      fmc112_data_fifo_din(16*1-1 DOWNTO 16*0) <= fmc112_adc_data7(7 DOWNTO 0) & fmc112_adc_data7(15 DOWNTO 8);
      fmc112_data_fifo_din(16*2-1 DOWNTO 16*1) <= fmc112_adc_data6(7 DOWNTO 0) & fmc112_adc_data6(15 DOWNTO 8);
      fmc112_data_fifo_din(16*3-1 DOWNTO 16*2) <= fmc112_adc_data5(7 DOWNTO 0) & fmc112_adc_data5(15 DOWNTO 8);
      fmc112_data_fifo_din(16*4-1 DOWNTO 16*3) <= fmc112_adc_data4(7 DOWNTO 0) & fmc112_adc_data4(15 DOWNTO 8);
      fmc112_data_fifo_din(16*5-1 DOWNTO 16*4) <= fmc112_adc_data3(7 DOWNTO 0) & fmc112_adc_data3(15 DOWNTO 8);
      fmc112_data_fifo_din(16*6-1 DOWNTO 16*5) <= fmc112_adc_data2(7 DOWNTO 0) & fmc112_adc_data2(15 DOWNTO 8);
      fmc112_data_fifo_din(16*7-1 DOWNTO 16*6) <= fmc112_adc_data1(7 DOWNTO 0) & fmc112_adc_data1(15 DOWNTO 8);
      fmc112_data_fifo_din(16*8-1 DOWNTO 16*7) <= fmc112_adc_data0(7 DOWNTO 0) & fmc112_adc_data0(15 DOWNTO 8);
      fmc112_data_fifo_wren                    <= config_reg(32*6+31);
    END IF;
  END PROCESS;

  dbg_ila1_probe0 <= fmc112_adc_data0;
  dbg_ila1_probe1 <= fmc112_adc_data4;
  ---------------------------------------------> FMC112

  --led_obufs : FOR i IN 0 TO 7 GENERATE
  --  led_obuf : OBUF
  --    PORT MAP (
  --      I => usr_data_output(i),
  --      O => LED8Bit(i)
  --    );
  --END GENERATE led_obufs;
  --LED8Bit(5 DOWNTO 1) <= (OTHERS => '0');

END Behavioral;
