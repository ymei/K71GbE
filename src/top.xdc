# KC705 configuration
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 2.5 [current_design]

# 200MHz onboard diff clock
create_clock -name system_clock -period 5.0 [get_ports {SYS_CLK_P}]
# 156.25MHz
create_clock -name user_clock   -period 6.4 [get_ports {USER_CLK_P}]
# 125MHz
create_clock -name sgmii_clock  -period 8.0 [get_ports {SGMIICLK_Q0_P}]

# PadFunction: IO_L12P_T1_MRCC_33 
set_property VCCAUX_IO DONTCARE [get_ports {SYS_CLK_P}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {SYS_CLK_P}]
set_property PACKAGE_PIN AD12 [get_ports {SYS_CLK_P}]

# PadFunction: IO_L12N_T1_MRCC_33 
set_property VCCAUX_IO DONTCARE [get_ports {SYS_CLK_N}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {SYS_CLK_N}]
set_property PACKAGE_PIN AD11 [get_ports {SYS_CLK_N}]

# Set DCI_CASCADE          
set_property slave_banks {32 34} [get_iobanks 33]

# 156.25MHz clock, IOSTANDARD is overridden in IBUFDS
set_property IOSTANDARD LVDS_25 [get_ports {USER_CLK_P}]
set_property PACKAGE_PIN K28 [get_ports {USER_CLK_P}]
set_property IOSTANDARD LVDS_25 [get_ports {USER_CLK_N}]
set_property PACKAGE_PIN K29 [get_ports {USER_CLK_N}]

# 125MHz clock, for GTP/GTH/GTX
set_property PACKAGE_PIN G8 [get_ports {SGMIICLK_Q0_P}]
set_property PACKAGE_PIN G7 [get_ports {SGMIICLK_Q0_N}]

# clock domain interaction
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks system_clock] -group [get_clocks -include_generated_clocks sgmii_clock]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks system_clock] -group [get_clocks -include_generated_clocks user_clock]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks user_clock] -group [get_clocks -include_generated_clocks sgmii_clock]
# seems we ran out of bufg's
# set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets global_clock_reset_inst/I]
# false path of resetter
set_false_path -from [get_pins -of_objects [get_cells -hierarchical -filter {NAME =~ *GLOBAL_RST_reg*}] -filter {NAME =~ *C}]

#<-- LEDs, buttons and switches --<

# Bank: 33 - GPIO_SW_7 (CPU_RESET)
set_property VCCAUX_IO DONTCARE [get_ports {SYS_RST}]
set_property SLEW SLOW [get_ports {SYS_RST}]
set_property IOSTANDARD LVCMOS15 [get_ports {SYS_RST}]
set_property LOC AB7 [get_ports {SYS_RST}]
# set_property PACKAGE_PIN AB7 [get_ports CPU_RESET]
# set_property IOSTANDARD LVCMOS15 [get_ports CPU_RESET]

# LED:
# Bank: 33 - GPIO_LED_0_LS
set_property DRIVE 12 [get_ports {LED8Bit[0]}]
set_property SLEW SLOW [get_ports {LED8Bit[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED8Bit[0]}]
set_property LOC AB8 [get_ports {LED8Bit[0]}]

# Bank: 33 - GPIO_LED_1_LS
set_property DRIVE 12 [get_ports {LED8Bit[1]}]
set_property SLEW SLOW [get_ports {LED8Bit[1]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED8Bit[1]}]
set_property LOC AA8 [get_ports {LED8Bit[1]}]

# Bank: 33 - GPIO_LED_2_LS
set_property DRIVE 12 [get_ports {LED8Bit[2]}]
set_property SLEW SLOW [get_ports {LED8Bit[2]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED8Bit[2]}]
set_property LOC AC9 [get_ports {LED8Bit[2]}]

# Bank: 33 - GPIO_LED_3_LS
set_property DRIVE 12 [get_ports {LED8Bit[3]}]
set_property SLEW SLOW [get_ports {LED8Bit[3]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED8Bit[3]}]
set_property LOC AB9 [get_ports {LED8Bit[3]}]

# Bank: - GPIO_LED_4_LS
set_property DRIVE 12 [get_ports {LED8Bit[4]}]
set_property SLEW SLOW [get_ports {LED8Bit[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {LED8Bit[4]}]
set_property LOC AE26 [get_ports {LED8Bit[4]}]

# Bank: - GPIO_LED_5_LS
set_property DRIVE 12 [get_ports {LED8Bit[5]}]
set_property SLEW SLOW [get_ports {LED8Bit[5]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED8Bit[5]}]
set_property LOC G19 [get_ports {LED8Bit[5]}]

# Bank: - GPIO_LED_6_LS
set_property DRIVE 12 [get_ports {LED8Bit[6]}]
set_property SLEW SLOW [get_ports {LED8Bit[6]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED8Bit[6]}]
set_property LOC E18 [get_ports {LED8Bit[6]}]

# Bank: - GPIO_LED_7_LS
set_property DRIVE 12 [get_ports {LED8Bit[7]}]
set_property SLEW SLOW [get_ports {LED8Bit[7]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED8Bit[7]}]
set_property LOC F16 [get_ports {LED8Bit[7]}]

# GPIO_DIP_SW0
set_property SLEW SLOW [get_ports {DIPSw4Bit[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {DIPSw4Bit[0]}]
set_property LOC Y29 [get_ports {DIPSw4Bit[0]}]

# GPIO_DIP_SW1
set_property SLEW SLOW [get_ports {DIPSw4Bit[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {DIPSw4Bit[1]}]
set_property LOC W29 [get_ports {DIPSw4Bit[1]}]

# GPIO_DIP_SW2
set_property SLEW SLOW [get_ports {DIPSw4Bit[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {DIPSw4Bit[2]}]
set_property LOC AA28 [get_ports {DIPSw4Bit[2]}]

# GPIO_DIP_SW3
set_property SLEW SLOW [get_ports {DIPSw4Bit[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {DIPSw4Bit[3]}]
set_property LOC Y28 [get_ports {DIPSw4Bit[3]}]

# GPIO_SW_N : SW2
set_property SLEW SLOW [get_ports {BTN5Bit[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {BTN5Bit[0]}]
set_property LOC AA12 [get_ports {BTN5Bit[0]}]

# GPIO_SW_E : SW3
set_property SLEW SLOW [get_ports {BTN5Bit[1]}]
set_property IOSTANDARD LVCMOS15 [get_ports {BTN5Bit[1]}]
set_property LOC AG5 [get_ports {BTN5Bit[1]}]

# GPIO_SW_S : SW4
set_property SLEW SLOW [get_ports {BTN5Bit[2]}]
set_property IOSTANDARD LVCMOS15 [get_ports {BTN5Bit[2]}]
set_property LOC AB12 [get_ports {BTN5Bit[2]}]

# GPIO_SW_C : SW5
set_property SLEW SLOW [get_ports {BTN5Bit[3]}]
set_property IOSTANDARD LVCMOS15 [get_ports {BTN5Bit[3]}]
set_property LOC G12 [get_ports {BTN5Bit[3]}]

# GPIO_SW_W : SW6
set_property SLEW SLOW [get_ports {BTN5Bit[4]}]
set_property IOSTANDARD LVCMOS15 [get_ports {BTN5Bit[4]}]
set_property LOC AC6 [get_ports {BTN5Bit[4]}]

# SMA
set_property PACKAGE_PIN L25 [get_ports {USER_SMA_CLOCK_P}]
set_property IOSTANDARD LVCMOS25 [get_ports USER_SMA_CLOCK_P]
set_property PACKAGE_PIN K25 [get_ports {USER_SMA_CLOCK_N}]
set_property IOSTANDARD LVCMOS25 [get_ports USER_SMA_CLOCK_N]

set_property PACKAGE_PIN Y23 [get_ports USER_SMA_GPIO_P]
set_property IOSTANDARD LVCMOS25 [get_ports USER_SMA_GPIO_P]
set_property PACKAGE_PIN Y24 [get_ports USER_SMA_GPIO_N]
set_property IOSTANDARD LVCMOS25 [get_ports USER_SMA_GPIO_N]

#>-- LEDs, buttons and switches -->

#<-- UART --<

set_property PACKAGE_PIN K24 [get_ports {USB_RX}]
set_property IOSTANDARD LVCMOS25 [get_ports {USB_RX}]
set_property PACKAGE_PIN M19 [get_ports {USB_TX}]
set_property IOSTANDARD LVCMOS25 [get_ports {USB_TX}]

#>-- UART -->

#<-- control interface --<

set_false_path -from [get_pins -of_objects [get_cells -hierarchical -filter {NAME =~ *control_interface_inst*sConfigReg_reg[*]}] -filter {NAME =~ *C}]
set_false_path -from [get_pins -of_objects [get_cells -hierarchical -filter {NAME =~ *control_interface_inst*sPulseReg_reg[*]}] -filter {NAME =~ *C}]
set_false_path -to [get_pins -of_objects [get_cells -hierarchical -filter {NAME =~ *control_interface_inst*sRegOut_reg[*]}] -filter {NAME =~ *D}]

#>-- control interface -->

#<-- ten gig eth interface --<

# SFP
set_property PACKAGE_PIN Y20 [get_ports SFP_TX_DISABLE_N]
set_property IOSTANDARD LVCMOS25 [get_ports SFP_TX_DISABLE_N]
set_property PACKAGE_PIN P19 [get_ports SFP_LOS_LS]
set_property IOSTANDARD LVCMOS25 [get_ports SFP_LOS_LS]
set_property PACKAGE_PIN H2 [get_ports SFP_TX_P]
set_property PACKAGE_PIN H1 [get_ports SFP_TX_N]
set_property PACKAGE_PIN G4 [get_ports SFP_RX_P]
set_property PACKAGE_PIN G3 [get_ports SFP_RX_N]

# create_generated_clock -name ddrclock -divide_by 1 -invert -source [get_pins *rx_clk_ddr/C] [get_ports xgmii_rx_clk]
# set_output_delay -max 1.500 -clock [get_clocks ddrclock] [get_ports * -filter {NAME =~ *xgmii_rxd*}]
# set_output_delay -min -1.500 -clock [get_clocks ddrclock] [get_ports * -filter {NAME =~ *xgmii_rxd*}]
# set_output_delay -max 1.500 -clock [get_clocks ddrclock] [get_ports * -filter {NAME =~ *xgmii_rxc*}]
# set_output_delay -min -1.500 -clock [get_clocks ddrclock] [get_ports * -filter {NAME =~ *xgmii_rxc*}]

# False paths for async reset removal synchronizers
set_false_path -to [get_pins -of_objects [get_cells -hierarchical -filter {NAME =~ *ten_gig_eth_pcs_pma_core_support_layer_i/*shared*sync1_r_reg*}] -filter {NAME =~ *PRE}]
set_false_path -to [get_pins -of_objects [get_cells -hierarchical -filter {NAME =~ *ten_gig_eth_pcs_pma_core_support_layer_i/*shared*sync1_r_reg*}] -filter {NAME =~ *CLR}]

## Sample constraint for GT location
#set_property LOC GTXE2_CHANNEL_X0Y18 [get_cells ten_gig_eth_pcs_pma_core_support_layer_i/ten_gig_eth_pcs_pma_i/*/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_10gbaser_i/gtxe2_i]
#set_property LOC GTXE2_COMMON_X0Y4 [get_cells ten_gig_eth_pcs_pma_core_support_layer_i/ten_gig_eth_pcs_pma_gt_common_block/gtxe2_common_0_i]

#>-- ten gig eth interface -->

#<-- gigabit eth interface --<

set_property PACKAGE_PIN L20      [get_ports PHY_RESET_N]
set_property IOSTANDARD  LVCMOS25 [get_ports PHY_RESET_N]
set_property PACKAGE_PIN J21      [get_ports MDIO]
set_property IOSTANDARD  LVCMOS25 [get_ports MDIO]
set_property PACKAGE_PIN R23      [get_ports MDC]
set_property IOSTANDARD  LVCMOS25 [get_ports MDC]

set_property PACKAGE_PIN U28      [get_ports RGMII_RXD[3]]
set_property PACKAGE_PIN T25      [get_ports RGMII_RXD[2]]
set_property PACKAGE_PIN U25      [get_ports RGMII_RXD[1]]
set_property PACKAGE_PIN U30      [get_ports RGMII_RXD[0]]
set_property IOSTANDARD  LVCMOS25 [get_ports RGMII_RXD[3]]
set_property IOSTANDARD  LVCMOS25 [get_ports RGMII_RXD[2]]
set_property IOSTANDARD  LVCMOS25 [get_ports RGMII_RXD[1]]
set_property IOSTANDARD  LVCMOS25 [get_ports RGMII_RXD[0]]
set_property PACKAGE_PIN L28      [get_ports RGMII_TXD[3]]
set_property PACKAGE_PIN M29      [get_ports RGMII_TXD[2]]
set_property PACKAGE_PIN N25      [get_ports RGMII_TXD[1]]
set_property PACKAGE_PIN N27      [get_ports RGMII_TXD[0]]
set_property IOSTANDARD  LVCMOS25 [get_ports RGMII_TXD[3]]
set_property IOSTANDARD  LVCMOS25 [get_ports RGMII_TXD[2]]
set_property IOSTANDARD  LVCMOS25 [get_ports RGMII_TXD[1]]
set_property IOSTANDARD  LVCMOS25 [get_ports RGMII_TXD[0]]
set_property PACKAGE_PIN M27      [get_ports RGMII_TX_CTL]
set_property PACKAGE_PIN K30      [get_ports RGMII_TXC]
set_property IOSTANDARD  LVCMOS25 [get_ports RGMII_TX_CTL]
set_property IOSTANDARD  LVCMOS25 [get_ports RGMII_TXC]
set_property PACKAGE_PIN R28      [get_ports RGMII_RX_CTL]
set_property IOSTANDARD  LVCMOS25 [get_ports RGMII_RX_CTL]
set_property PACKAGE_PIN U27      [get_ports RGMII_RXC]
set_property IOSTANDARD  LVCMOS25 [get_ports RGMII_RXC]

# already set in ip / tri_mode_ethernet_mac_0.xdc
# create_clock -period 8 [get_ports RGMII_RXC]
set rx_clk_var [get_clocks -of [get_ports RGMII_RXC]]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks -of_objects [get_ports RGMII_RXC]] -group [get_clocks -include_generated_clocks sgmii_clock]

set_property IODELAY_GROUP tri_mode_ethernet_mac_iodelay_grp [get_cells -hier -filter {name =~ *trimac_fifo_block/trimac_sup_block/tri_mode_ethernet_mac_idelayctrl_common_i}]

# If TEMAC timing fails, use the following to relax the requirements
# The RGMII receive interface requirement allows a 1ns setup and 1ns hold - this is met but only just so constraints are relaxed
#set_input_delay -clock [get_clocks tri_mode_ethernet_mac_0_rgmii_rx_clk] -max -1.5 [get_ports {rgmii_rxd[*] rgmii_rx_ctl}]
#set_input_delay -clock [get_clocks tri_mode_ethernet_mac_0_rgmii_rx_clk] -min -2.8 [get_ports {rgmii_rxd[*] rgmii_rx_ctl}]
#set_input_delay -clock [get_clocks tri_mode_ethernet_mac_0_rgmii_rx_clk] -clock_fall -max -1.5 -add_delay [get_ports {rgmii_rxd[*] rgmii_rx_ctl}]
#set_input_delay -clock [get_clocks tri_mode_ethernet_mac_0_rgmii_rx_clk] -clock_fall -min -2.8 -add_delay [get_ports {rgmii_rxd[*] rgmii_rx_ctl}]

# the following properties can be adjusted if requried to adjuct the IO timing
# the value shown (12) is the default used by the IP
# increasing this value will improve the hold timing but will also add jitter.
# set_property IDELAY_VALUE 12 [get_cells -hier -filter {name =~ *trimac_fifo_block/trimac_sup_block/tri_mode_ethernet_mac_i/*/rgmii_interface/delay_rgmii_rx* *trimac_fifo_block/trimac_sup_block/tri_mode_ethernet_mac_i/*/rgmii_interface/rxdata_bus[*].delay_rgmii_rx*}]
set_property IDELAY_VALUE 10 [get_cells -hier -filter {name =~ *trimac_fifo_block/trimac_sup_block/tri_mode_ethernet_mac_i/*/rgmii_interface/delay_rgmii_rx*}]
set_property IDELAY_VALUE 10 [get_cells -hier -filter {name =~ *trimac_fifo_block/trimac_sup_block/tri_mode_ethernet_mac_i/*/rgmii_interface/rxdata_bus[*].delay_rgmii_rx*}]

# FIFO Clock Crossing Constraints
# control signal is synched separately so this is a false path
set_max_delay -from [get_cells -hier -filter {name =~ *tx_fifo_i/rd_addr_txfer_reg[*]}] -to [get_cells -hier -filter {name =~ *fifo*wr_rd_addr_reg[*]}] 6 -datapath_only
set_max_delay -from [get_cells -hier -filter {name =~ *rx_fifo_i/rd_addr_reg[*]}] -to [get_cells -hier -filter {name =~ *fifo*wr_rd_addr_reg[*]}] 6 -datapath_only
set_max_delay -from [get_cells -hier -filter {name =~ *rx_fifo_i/wr_store_frame_tog_reg}] -to [get_cells -hier -filter {name =~ *fifo_i/resync_wr_store_frame_tog/data_sync_reg0}] 6 -datapath_only
set_max_delay -from [get_cells -hier -filter {name =~ *rx_fifo_i/update_addr_tog_reg}] -to [get_cells -hier -filter {name =~ *rx_fifo_i/sync_rd_addr_tog/data_sync_reg0}] 6 -datapath_only
set_max_delay -from [get_cells -hier -filter {name =~ *tx_fifo_i/wr_frame_in_fifo_reg}] -to [get_cells -hier -filter {name =~ *tx_fifo_i/resync_wr_frame_in_fifo/data_sync_reg0}] 6 -datapath_only
set_max_delay -from [get_cells -hier -filter {name =~ *tx_fifo_i/wr_frames_in_fifo_reg}] -to [get_cells -hier -filter {name =~ *tx_fifo_i/resync_wr_frames_in_fifo/data_sync_reg0}] 6 -datapath_only
set_max_delay -from [get_cells -hier -filter {name =~ *tx_fifo_i/frame_in_fifo_valid_tog_reg}] -to [get_cells -hier -filter {name =~ *tx_fifo_i/resync_fif_valid_tog/data_sync_reg0}] 6 -datapath_only
set_max_delay -from [get_cells -hier -filter {name =~ *tx_fifo_i/rd_txfer_tog_reg}] -to [get_cells -hier -filter {name =~ *tx_fifo_i/resync_rd_txfer_tog/data_sync_reg0}] 6 -datapath_only
set_max_delay -from [get_cells -hier -filter {name =~ *tx_fifo_i/rd_tran_frame_tog_reg}] -to [get_cells -hier -filter {name =~ *tx_fifo_i/resync_rd_tran_frame_tog/data_sync_reg0}] 6 -datapath_only

# False paths for async reset removal synchronizers
set_false_path -to [get_pins -of_objects [get_cells -hierarchical -filter {NAME =~ *tri_mode_ethernet*reset_sync*}] -filter {NAME =~ *PRE}]

#>-- gigabit eth interface -->

#<-- FMC112 --<

# I2C Location assignments (KC705 pinout, connects to FMC connectors)
set_property PACKAGE_PIN K21 [get_ports I2C_SCL]
set_property IOSTANDARD LVCMOS25 [get_ports I2C_SCL]
set_property PACKAGE_PIN L21 [get_ports I2C_SDA]
set_property IOSTANDARD LVCMOS25 [get_ports I2C_SDA]
# FMC signals (FMC112 on KC705 LPC)
set_property PACKAGE_PIN AG23 [get_ports CLK_TO_FPGA_N_1]
set_property PACKAGE_PIN AF22 [get_ports CLK_TO_FPGA_P_1]
set_property PACKAGE_PIN AB29 [get_ports CTRL_1[0]]
set_property IOSTANDARD LVCMOS25 [get_ports CTRL_1[0]]
set_property SLEW SLOW [get_ports CTRL_1[0]]
set_property PACKAGE_PIN AB30 [get_ports CTRL_1[1]]
set_property IOSTANDARD LVCMOS25 [get_ports CTRL_1[1]]
set_property SLEW SLOW [get_ports CTRL_1[1]]
set_property PACKAGE_PIN AD29 [get_ports CTRL_1[2]]
set_property IOSTANDARD LVCMOS25 [get_ports CTRL_1[2]]
set_property SLEW SLOW [get_ports CTRL_1[2]]
set_property PACKAGE_PIN AE29 [get_ports CTRL_1[3]]
set_property IOSTANDARD LVCMOS25 [get_ports CTRL_1[3]]
set_property SLEW SLOW [get_ports CTRL_1[3]]
set_property PACKAGE_PIN Y30 [get_ports CTRL_1[4]]
set_property IOSTANDARD LVCMOS25 [get_ports CTRL_1[4]]
set_property SLEW SLOW [get_ports CTRL_1[4]]
set_property PACKAGE_PIN AA30 [get_ports CTRL_1[5]]
set_property IOSTANDARD LVCMOS25 [get_ports CTRL_1[5]]
set_property SLEW SLOW [get_ports CTRL_1[5]]
set_property PACKAGE_PIN AC29 [get_ports CTRL_1[6]]
set_property IOSTANDARD LVCMOS25 [get_ports CTRL_1[6]]
set_property SLEW SLOW [get_ports CTRL_1[6]]
set_property PACKAGE_PIN AC30 [get_ports CTRL_1[7]]
set_property IOSTANDARD LVCMOS25 [get_ports CTRL_1[7]]
set_property SLEW SLOW [get_ports CTRL_1[7]]
set_property PACKAGE_PIN AE24 [get_ports DCO_N_1[0]]
set_property IOSTANDARD LVDS_25 [get_ports DCO_N_1[0]]
set_property PACKAGE_PIN AF23 [get_ports DCO_N_1[1]]
set_property IOSTANDARD LVDS_25 [get_ports DCO_N_1[1]]
set_property PACKAGE_PIN AC27 [get_ports DCO_N_1[2]]
set_property IOSTANDARD LVDS_25 [get_ports DCO_N_1[2]]
set_property PACKAGE_PIN AD23 [get_ports DCO_P_1[0]]
set_property IOSTANDARD LVDS_25 [get_ports DCO_P_1[0]]
set_property PACKAGE_PIN AE23 [get_ports DCO_P_1[1]]
set_property IOSTANDARD LVDS_25 [get_ports DCO_P_1[1]]
set_property PACKAGE_PIN AB27 [get_ports DCO_P_1[2]]
set_property IOSTANDARD LVDS_25 [get_ports DCO_P_1[2]]
set_property PACKAGE_PIN AK21 [get_ports FRAME_N_1[0]]
set_property PACKAGE_PIN AD28 [get_ports FRAME_N_1[1]]
set_property PACKAGE_PIN AD26 [get_ports FRAME_N_1[2]]
set_property PACKAGE_PIN AK20 [get_ports FRAME_P_1[0]]
set_property PACKAGE_PIN AD27 [get_ports FRAME_P_1[1]]
set_property PACKAGE_PIN AC26 [get_ports FRAME_P_1[2]]
set_property PACKAGE_PIN AK24 [get_ports OUTA_N_1[0]]
set_property PACKAGE_PIN AH25 [get_ports OUTA_N_1[1]]
set_property PACKAGE_PIN AJ21 [get_ports OUTA_N_1[2]]
set_property PACKAGE_PIN AF21 [get_ports OUTA_N_1[3]]
set_property PACKAGE_PIN AK26 [get_ports OUTA_N_1[4]]
set_property PACKAGE_PIN AD24 [get_ports OUTA_N_1[5]]
set_property PACKAGE_PIN AC25 [get_ports OUTA_N_1[6]]
set_property PACKAGE_PIN AF25 [get_ports OUTA_N_1[7]]
set_property PACKAGE_PIN AF30 [get_ports OUTA_N_1[8]]
set_property PACKAGE_PIN AK30 [get_ports OUTA_N_1[9]]
set_property PACKAGE_PIN AH27 [get_ports OUTA_N_1[10]]
set_property PACKAGE_PIN AG28 [get_ports OUTA_N_1[11]]
set_property PACKAGE_PIN AK23 [get_ports OUTA_P_1[0]]
set_property PACKAGE_PIN AG25 [get_ports OUTA_P_1[1]]
set_property PACKAGE_PIN AH21 [get_ports OUTA_P_1[2]]
set_property PACKAGE_PIN AF20 [get_ports OUTA_P_1[3]]
set_property PACKAGE_PIN AJ26 [get_ports OUTA_P_1[4]]
set_property PACKAGE_PIN AC24 [get_ports OUTA_P_1[5]]
set_property PACKAGE_PIN AB24 [get_ports OUTA_P_1[6]]
set_property PACKAGE_PIN AE25 [get_ports OUTA_P_1[7]]
set_property PACKAGE_PIN AE30 [get_ports OUTA_P_1[8]]
set_property PACKAGE_PIN AK29 [get_ports OUTA_P_1[9]]
set_property PACKAGE_PIN AH26 [get_ports OUTA_P_1[10]]
set_property PACKAGE_PIN AG27 [get_ports OUTA_P_1[11]]
set_property PACKAGE_PIN AK25 [get_ports OUTB_N_1[0]]
set_property PACKAGE_PIN AJ23 [get_ports OUTB_N_1[1]]
set_property PACKAGE_PIN AH22 [get_ports OUTB_N_1[2]]
set_property PACKAGE_PIN AH20 [get_ports OUTB_N_1[3]]
set_property PACKAGE_PIN AF27 [get_ports OUTB_N_1[4]]
set_property PACKAGE_PIN AD22 [get_ports OUTB_N_1[5]]
set_property PACKAGE_PIN AE21 [get_ports OUTB_N_1[6]]
set_property PACKAGE_PIN AB20 [get_ports OUTB_N_1[7]]
set_property PACKAGE_PIN AF28 [get_ports OUTB_N_1[8]]
set_property PACKAGE_PIN AJ29 [get_ports OUTB_N_1[9]]
set_property PACKAGE_PIN AH30 [get_ports OUTB_N_1[10]]
set_property PACKAGE_PIN AK28 [get_ports OUTB_N_1[11]]
set_property PACKAGE_PIN AJ24 [get_ports OUTB_P_1[0]]
set_property PACKAGE_PIN AJ22 [get_ports OUTB_P_1[1]]
set_property PACKAGE_PIN AG22 [get_ports OUTB_P_1[2]]
set_property PACKAGE_PIN AG20 [get_ports OUTB_P_1[3]]
set_property PACKAGE_PIN AF26 [get_ports OUTB_P_1[4]]
set_property PACKAGE_PIN AC22 [get_ports OUTB_P_1[5]]
set_property PACKAGE_PIN AD21 [get_ports OUTB_P_1[6]]
set_property PACKAGE_PIN AA20 [get_ports OUTB_P_1[7]]
set_property PACKAGE_PIN AE28 [get_ports OUTB_P_1[8]]
set_property PACKAGE_PIN AJ28 [get_ports OUTB_P_1[9]]
set_property PACKAGE_PIN AG30 [get_ports OUTB_P_1[10]]
set_property PACKAGE_PIN AJ27 [get_ports OUTB_P_1[11]]
set_property PACKAGE_PIN AH29 [get_ports EXT_TRIGGER_N_1]
set_property PACKAGE_PIN AG29 [get_ports EXT_TRIGGER_P_1]
set_property PACKAGE_PIN J22 [get_ports PRSNT_M2C_L_1]
set_property IOSTANDARD LVCMOS25 [get_ports PRSNT_M2C_L_1]
set_property SLEW SLOW [get_ports PRSNT_M2C_L_1]

# clocks
create_clock -name dco0_clock -period 2.0 [get_ports {DCO_P_1[0]}]
create_clock -name dco1_clock -period 2.0 [get_ports {DCO_P_1[1]}]
create_clock -name dco2_clock -period 2.0 [get_ports {DCO_P_1[2]}]
create_clock -name clk_to_fpga_clock -period 2.0 [get_ports {CLK_TO_FPGA_P_1}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks clk_to_fpga_clock] -group [get_clocks -include_generated_clocks sgmii_clock]

# SPI
#create_clock -name spi_clock -period 256.0 [get_ports {CTRL_1[0]}]
#create_clock -name spi_clock -period 256.0
#set_output_delay -clock spi_clock 10.0 [get_ports {CTRL_1[0]}]
#set_output_delay -clock spi_clock 10.0 [get_ports {CTRL_1[1]}] -clock_fall
#set_output_delay -clock spi_clock 10.0 [get_ports {CTRL_1[2]}] -clock_fall
#set_input_delay  -clock spi_clock 10.0 [get_ports {CTRL_1[2]}] -clock_fall

# iodelay
set_property IODELAY_GROUP fmc112_iodelay_grp [get_cells -hier -filter {name =~ *ltc2175_phy_inst*iodelay_bus}]
set_property IODELAY_GROUP fmc112_iodelay_grp [get_cells -hier -filter {name =~ *fmc112_inst*idelayctrl_inst}]

# gtx
# create_clock -name q0_clk1_refclk_i -period 8.0 [get_pins -hier -filter {NAME =~ */q0_clk1_refclk_i}]
# create_clock -name gt0_txusrclk_i   -period 3.2 [get_pins -hier -filter {NAME =~ */gt0_txusrclk_i}]
# create_clock -name gt0_txusrclk2_i  -period 6.4 [get_pins -hier -filter {NAME =~ */gt0_txusrclk2_i}]
# set_property LOC GTXE2_CHANNEL_X0Y8 [get_cells -hierarchical -filter {NAME =~ */k7_gtxwizard_v1_6_*/gt0_k7_gtxwizard_v1_6_*/gtxe2_i}]

# false paths
set_false_path -from [get_pins -of_objects [get_cells -hierarchical -filter {NAME =~ *p2p_trigger_inst*outreset_reg}] -filter {NAME =~ *C}]
set_false_path -from [get_pins -of_objects [get_cells -hierarchical -filter {NAME =~ *pulse2pulse*outreset_reg}] -filter {NAME =~ *C}]
set_false_path -to [get_pins -of_objects [get_cells -hierarchical -filter {NAME =~ *channel_avg_inst*trig_prev_reg}] -filter {NAME =~ *D}]

#>-- FMC112 -->

# Local Variables:
# mode: tcl
# End:
