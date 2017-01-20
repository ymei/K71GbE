
-------------------------------------------------------------------------------------
-- FILE NAME : kc705_fmc112.vhd
--
-- AUTHOR    : StellarIP (c) 4DSP
--
-- COMPANY   : 4DSP
--
-- ITEM      : 1
--
-- UNITS     : Entity       - kc705_fmc112
--             architecture - arch_kc705_fmc112
--
-- LANGUAGE  : VHDL
--
-------------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------------
-- DESCRIPTION
-- ===========
--
-- KC705 with FMC112 card
-- Notes: 12 channel A/D
-------------------------------------------------------------------------------------
--  Disclaimer: LIMITED WARRANTY AND DISCLAIMER. These designs are
--              provided to you as is.  4DSP specifically disclaims any
--              implied warranties of merchantability, non-infringement, or
--              fitness for a particular purpose. 4DSP does not warrant that
--              the functions contained in these designs will meet your
--              requirements, or that the operation of these designs will be
--              uninterrupted or error free, or that defects in the Designs
--              will be corrected. Furthermore, 4DSP does not warrant or
--              make any representations regarding use or the results of the
--              use of the designs in terms of correctness, accuracy,
--              reliability, or otherwise.
--
--              LIMITATION OF LIABILITY. In no event will 4DSP or its
--              licensors be liable for any loss of data, lost profits, cost
--              or procurement of substitute goods or services, or for any
--              special, incidental, consequential, or indirect damages
--              arising from the use or operation of the designs or
--              accompanying documentation, however caused and on any theory
--              of liability. This limitation will apply even if 4DSP
--              has been advised of the possibility of such damage. This
--              limitation shall apply not-withstanding the failure of the
--              essential purpose of any limited remedies herein.
--
----------------------------------------------
--
-------------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------------
--library declaration
-------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;
use ieee.std_logic_misc.all ;
library unisim;
use unisim.vcomponents.all;

-------------------------------------------------------------------------------------
--Entity Declaration
-------------------------------------------------------------------------------------
--! This is the top level project file for kc705_fmc112
--! @author StellarIP
--! @version 1.0
--! @date 03/22/14

ENTITY kc705_fmc112 IS
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
    EXT_TRIGGER     : OUT   std_logic;
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
    PHY_DATA_CLK    : OUT   std_logic;                      -- ADC data clk
    PHY_OUT_DATA0   : OUT   std_logic_vector(15 DOWNTO 0);  -- 1 sample, 16-bit format
    PHY_OUT_DATA1   : OUT   std_logic_vector(15 DOWNTO 0);
    PHY_OUT_DATA2   : OUT   std_logic_vector(15 DOWNTO 0);
    PHY_OUT_DATA3   : OUT   std_logic_vector(15 DOWNTO 0);
    PHY_OUT_DATA4   : OUT   std_logic_vector(15 DOWNTO 0);
    PHY_OUT_DATA5   : OUT   std_logic_vector(15 DOWNTO 0);
    PHY_OUT_DATA6   : OUT   std_logic_vector(15 DOWNTO 0);
    PHY_OUT_DATA7   : OUT   std_logic_vector(15 DOWNTO 0);
    PHY_OUT_DATA8   : OUT   std_logic_vector(15 DOWNTO 0);
    PHY_OUT_DATA9   : OUT   std_logic_vector(15 DOWNTO 0);
    PHY_OUT_DATA10  : OUT   std_logic_vector(15 DOWNTO 0);
    PHY_OUT_DATA11  : OUT   std_logic_vector(15 DOWNTO 0)
  );
END ENTITY kc705_fmc112;

-------------------------------------------------------------------------------------
--Architecture declaration
-------------------------------------------------------------------------------------
architecture arch_kc705_fmc112 of kc705_fmc112  is

-------------------------------------------------------------------------------------
--Constants declaration
-------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
--Signal declaration
-------------------------------------------------------------------------------------

--sip_cid
signal sip_cid_0_cmdclk_in_cmdclk              : std_logic;
signal sip_cid_0_cmd_in_cmdin                  : std_logic_vector(63 downto 0);
signal sip_cid_0_cmd_in_cmdin_val              : std_logic;
signal sip_cid_0_rst_rstin                     : std_logic_vector(31 downto 0);
signal sip_cid_0_cmd_out_cmdout                : std_logic_vector(63 downto 0);
signal sip_cid_0_cmd_out_cmdout_val            : std_logic;

--sip_mac_engine
signal sip_mac_engine_0_cmdclk_out_cmdclk      : std_logic;
signal sip_mac_engine_0_cmd_out_cmdout         : std_logic_vector(63 downto 0);
signal sip_mac_engine_0_cmd_out_cmdout_val     : std_logic;
signal sip_mac_engine_0_cmd_in_cmdin           : std_logic_vector(63 downto 0);
signal sip_mac_engine_0_cmd_in_cmdin_val       : std_logic;
signal sip_mac_engine_0_clkout_clkout          : std_logic_vector(31 downto 0);
signal sip_mac_engine_0_rst_out_rstout         : std_logic_vector(31 downto 0);
signal sip_mac_engine_0_ext_mac_engine_cpu_reset : std_logic;
signal sip_mac_engine_0_ext_mac_engine_sysclk_p : std_logic;
signal sip_mac_engine_0_ext_mac_engine_sysclk_n : std_logic;
signal sip_mac_engine_0_ext_mac_engine_phy_reset_l :   std_logic;
signal sip_mac_engine_0_ext_mac_engine_phy_mdc : std_logic;
signal sip_mac_engine_0_ext_mac_engine_phy_mdio : std_logic;
signal sip_mac_engine_0_ext_mac_engine_phy_txctl_txen :      std_logic;
signal sip_mac_engine_0_ext_mac_engine_phy_txer : std_logic;
signal sip_mac_engine_0_ext_mac_engine_phy_txc_gtxclk :      std_logic;
signal sip_mac_engine_0_ext_mac_engine_phy_txclk : std_logic;
signal sip_mac_engine_0_ext_mac_engine_phy_txd : std_logic_vector(7 downto 0);
signal sip_mac_engine_0_ext_mac_engine_phy_crs : std_logic;
signal sip_mac_engine_0_ext_mac_engine_phy_col : std_logic;
signal sip_mac_engine_0_ext_mac_engine_phy_rxer : std_logic;
signal sip_mac_engine_0_ext_mac_engine_phy_rxctrl_rxdv :       std_logic;
signal sip_mac_engine_0_ext_mac_engine_phy_rxclk : std_logic;
signal sip_mac_engine_0_ext_mac_engine_phy_rxd : std_logic_vector(7 downto 0);
signal sip_mac_engine_0_ext_mac_engine_gpio_led : std_logic_vector(3 downto 0);
signal sip_mac_engine_0_out_data_out_stop      : std_logic;
signal sip_mac_engine_0_out_data_out_dval      : std_logic;
signal sip_mac_engine_0_out_data_out_data      : std_logic_vector(63 downto 0);

--sip_i2c_master
signal sip_i2c_master_0_clk_clkin              : std_logic_vector(31 downto 0);
signal sip_i2c_master_0_rst_rstin              : std_logic_vector(31 downto 0);
signal sip_i2c_master_0_cmdclk_in_cmdclk       : std_logic;
signal sip_i2c_master_0_cmd_in_cmdin           : std_logic_vector(63 downto 0);
signal sip_i2c_master_0_cmd_in_cmdin_val       : std_logic;
signal sip_i2c_master_0_cmd_out_cmdout         : std_logic_vector(63 downto 0);
signal sip_i2c_master_0_cmd_out_cmdout_val     : std_logic;
signal sip_i2c_master_0_ext_i2c_i2c_scl        : std_logic;
signal sip_i2c_master_0_ext_i2c_i2c_sda        : std_logic;

--sip_cmd12_mux
signal sip_cmd12_mux_0_cmdclk_in_cmdclk        : std_logic;
signal sip_cmd12_mux_0_cmd0_in_cmdin           : std_logic_vector(63 downto 0);
signal sip_cmd12_mux_0_cmd0_in_cmdin_val       : std_logic;
signal sip_cmd12_mux_0_cmd1_in_cmdin           : std_logic_vector(63 downto 0);
signal sip_cmd12_mux_0_cmd1_in_cmdin_val       : std_logic;
signal sip_cmd12_mux_0_cmd2_in_cmdin           : std_logic_vector(63 downto 0);
signal sip_cmd12_mux_0_cmd2_in_cmdin_val       : std_logic;
signal sip_cmd12_mux_0_cmd3_in_cmdin           : std_logic_vector(63 downto 0);
signal sip_cmd12_mux_0_cmd3_in_cmdin_val       : std_logic;
signal sip_cmd12_mux_0_cmd4_in_cmdin           : std_logic_vector(63 downto 0);
signal sip_cmd12_mux_0_cmd4_in_cmdin_val       : std_logic;
signal sip_cmd12_mux_0_cmd5_in_cmdin           : std_logic_vector(63 downto 0);
signal sip_cmd12_mux_0_cmd5_in_cmdin_val       : std_logic;
signal sip_cmd12_mux_0_cmd6_in_cmdin           : std_logic_vector(63 downto 0);
signal sip_cmd12_mux_0_cmd6_in_cmdin_val       : std_logic;
signal sip_cmd12_mux_0_cmd7_in_cmdin           : std_logic_vector(63 downto 0);
signal sip_cmd12_mux_0_cmd7_in_cmdin_val       : std_logic;
signal sip_cmd12_mux_0_cmd8_in_cmdin           : std_logic_vector(63 downto 0);
signal sip_cmd12_mux_0_cmd8_in_cmdin_val       : std_logic;
signal sip_cmd12_mux_0_cmd9_in_cmdin           : std_logic_vector(63 downto 0);
signal sip_cmd12_mux_0_cmd9_in_cmdin_val       : std_logic;
signal sip_cmd12_mux_0_cmd10_in_cmdin          : std_logic_vector(63 downto 0);
signal sip_cmd12_mux_0_cmd10_in_cmdin_val      : std_logic;
signal sip_cmd12_mux_0_cmd11_in_cmdin          : std_logic_vector(63 downto 0);
signal sip_cmd12_mux_0_cmd11_in_cmdin_val      : std_logic;
signal sip_cmd12_mux_0_cmd_out_cmdout          : std_logic_vector(63 downto 0);
signal sip_cmd12_mux_0_cmd_out_cmdout_val      : std_logic;

--sip_fmc_ct_gen
signal sip_fmc_ct_gen_0_cmdclk_in_cmdclk       : std_logic;
signal sip_fmc_ct_gen_0_cmd_in_cmdin           : std_logic_vector(63 downto 0);
signal sip_fmc_ct_gen_0_cmd_in_cmdin_val       : std_logic;
signal sip_fmc_ct_gen_0_rst_rstin              : std_logic_vector(31 downto 0);
signal sip_fmc_ct_gen_0_cmd_out_cmdout         : std_logic_vector(63 downto 0);
signal sip_fmc_ct_gen_0_cmd_out_cmdout_val     : std_logic;
signal sip_fmc_ct_gen_0_ext_fmc_ct_gen_ref_clk_p : std_logic;
signal sip_fmc_ct_gen_0_ext_fmc_ct_gen_ref_clk_n : std_logic;
signal sip_fmc_ct_gen_0_ext_fmc_ct_gen_tx_p    : std_logic;
signal sip_fmc_ct_gen_0_ext_fmc_ct_gen_tx_n    : std_logic;
signal sip_fmc_ct_gen_0_ext_fmc_ct_gen_rx_p    : std_logic;
signal sip_fmc_ct_gen_0_ext_fmc_ct_gen_rx_n    : std_logic;
signal sip_fmc_ct_gen_0_ext_fmc_ct_gen_trig_out : std_logic;

--sip_fmc112
signal sip_fmc112_1_clk_clkin                  : std_logic_vector(31 downto 0);
signal sip_fmc112_1_rst_rstin                  : std_logic_vector(31 downto 0);
signal sip_fmc112_1_cmdclk_in_cmdclk           : std_logic;
signal sip_fmc112_1_cmd_in_cmdin               : std_logic_vector(63 downto 0);
signal sip_fmc112_1_cmd_in_cmdin_val           : std_logic;
signal sip_fmc112_1_cmd_out_cmdout             : std_logic_vector(63 downto 0);
signal sip_fmc112_1_cmd_out_cmdout_val         : std_logic;
signal sip_fmc112_1_adc0_out_stop              : std_logic;
signal sip_fmc112_1_adc0_out_dval              : std_logic;
signal sip_fmc112_1_adc0_out_data              : std_logic_vector(63 downto 0);
signal sip_fmc112_1_adc1_out_stop              : std_logic;
signal sip_fmc112_1_adc1_out_dval              : std_logic;
signal sip_fmc112_1_adc1_out_data              : std_logic_vector(63 downto 0);
signal sip_fmc112_1_adc2_out_stop              : std_logic;
signal sip_fmc112_1_adc2_out_dval              : std_logic;
signal sip_fmc112_1_adc2_out_data              : std_logic_vector(63 downto 0);
signal sip_fmc112_1_adc3_out_stop              : std_logic;
signal sip_fmc112_1_adc3_out_dval              : std_logic;
signal sip_fmc112_1_adc3_out_data              : std_logic_vector(63 downto 0);
signal sip_fmc112_1_adc4_out_stop              : std_logic;
signal sip_fmc112_1_adc4_out_dval              : std_logic;
signal sip_fmc112_1_adc4_out_data              : std_logic_vector(63 downto 0);
signal sip_fmc112_1_adc5_out_stop              : std_logic;
signal sip_fmc112_1_adc5_out_dval              : std_logic;
signal sip_fmc112_1_adc5_out_data              : std_logic_vector(63 downto 0);
signal sip_fmc112_1_adc6_out_stop              : std_logic;
signal sip_fmc112_1_adc6_out_dval              : std_logic;
signal sip_fmc112_1_adc6_out_data              : std_logic_vector(63 downto 0);
signal sip_fmc112_1_adc7_out_stop              : std_logic;
signal sip_fmc112_1_adc7_out_dval              : std_logic;
signal sip_fmc112_1_adc7_out_data              : std_logic_vector(63 downto 0);
signal sip_fmc112_1_adc8_out_stop              : std_logic;
signal sip_fmc112_1_adc8_out_dval              : std_logic;
signal sip_fmc112_1_adc8_out_data              : std_logic_vector(63 downto 0);
signal sip_fmc112_1_adc9_out_stop              : std_logic;
signal sip_fmc112_1_adc9_out_dval              : std_logic;
signal sip_fmc112_1_adc9_out_data              : std_logic_vector(63 downto 0);
signal sip_fmc112_1_adc10_out_stop             : std_logic;
signal sip_fmc112_1_adc10_out_dval             : std_logic;
signal sip_fmc112_1_adc10_out_data             : std_logic_vector(63 downto 0);
signal sip_fmc112_1_adc11_out_stop             : std_logic;
signal sip_fmc112_1_adc11_out_dval             : std_logic;
signal sip_fmc112_1_adc11_out_data             : std_logic_vector(63 downto 0);
signal sip_fmc112_1_ext_fmc112_ctrl            : std_logic_vector(7 downto 0);
signal sip_fmc112_1_ext_fmc112_clk_to_fpga_p   : std_logic;
signal sip_fmc112_1_ext_fmc112_clk_to_fpga_n   : std_logic;
signal sip_fmc112_1_ext_fmc112_ext_trigger_p   : std_logic;
signal sip_fmc112_1_ext_fmc112_ext_trigger_n   : std_logic;
signal sip_fmc112_1_ext_fmc112_outa_p          : std_logic_vector(11 downto 0);
signal sip_fmc112_1_ext_fmc112_outa_n          : std_logic_vector(11 downto 0);
signal sip_fmc112_1_ext_fmc112_outb_p          : std_logic_vector(11 downto 0);
signal sip_fmc112_1_ext_fmc112_outb_n          : std_logic_vector(11 downto 0);
signal sip_fmc112_1_ext_fmc112_dco_p           : std_logic_vector(2 downto 0);
signal sip_fmc112_1_ext_fmc112_dco_n           : std_logic_vector(2 downto 0);
signal sip_fmc112_1_ext_fmc112_frame_p         : std_logic_vector(2 downto 0);
signal sip_fmc112_1_ext_fmc112_frame_n         : std_logic_vector(2 downto 0);
signal sip_fmc112_1_ext_fmc112_pg_m2c          : std_logic;
signal sip_fmc112_1_ext_fmc112_prsnt_m2c_l     : std_logic;

--sip_router_s16d1
signal sip_router_s16d1_0_cmdclk_in_cmdclk     : std_logic;
signal sip_router_s16d1_0_cmd_in_cmdin         : std_logic_vector(63 downto 0);
signal sip_router_s16d1_0_cmd_in_cmdin_val     : std_logic;
signal sip_router_s16d1_0_cmd_out_cmdout       : std_logic_vector(63 downto 0);
signal sip_router_s16d1_0_cmd_out_cmdout_val   : std_logic;
signal sip_router_s16d1_0_clk_clkin            : std_logic_vector(31 downto 0);
signal sip_router_s16d1_0_rst_rstin            : std_logic_vector(31 downto 0);
signal sip_router_s16d1_0_out0_out_stop        : std_logic;
signal sip_router_s16d1_0_out0_out_dval        : std_logic;
signal sip_router_s16d1_0_out0_out_data        : std_logic_vector(63 downto 0);
signal sip_router_s16d1_0_in0_in_stop          : std_logic;
signal sip_router_s16d1_0_in0_in_dval          : std_logic;
signal sip_router_s16d1_0_in0_in_data          : std_logic_vector(63 downto 0);
signal sip_router_s16d1_0_in1_in_stop          : std_logic;
signal sip_router_s16d1_0_in1_in_dval          : std_logic;
signal sip_router_s16d1_0_in1_in_data          : std_logic_vector(63 downto 0);
signal sip_router_s16d1_0_in2_in_stop          : std_logic;
signal sip_router_s16d1_0_in2_in_dval          : std_logic;
signal sip_router_s16d1_0_in2_in_data          : std_logic_vector(63 downto 0);
signal sip_router_s16d1_0_in3_in_stop          : std_logic;
signal sip_router_s16d1_0_in3_in_dval          : std_logic;
signal sip_router_s16d1_0_in3_in_data          : std_logic_vector(63 downto 0);
signal sip_router_s16d1_0_in4_in_stop          : std_logic;
signal sip_router_s16d1_0_in4_in_dval          : std_logic;
signal sip_router_s16d1_0_in4_in_data          : std_logic_vector(63 downto 0);
signal sip_router_s16d1_0_in5_in_stop          : std_logic;
signal sip_router_s16d1_0_in5_in_dval          : std_logic;
signal sip_router_s16d1_0_in5_in_data          : std_logic_vector(63 downto 0);
signal sip_router_s16d1_0_in6_in_stop          : std_logic;
signal sip_router_s16d1_0_in6_in_dval          : std_logic;
signal sip_router_s16d1_0_in6_in_data          : std_logic_vector(63 downto 0);
signal sip_router_s16d1_0_in7_in_stop          : std_logic;
signal sip_router_s16d1_0_in7_in_dval          : std_logic;
signal sip_router_s16d1_0_in7_in_data          : std_logic_vector(63 downto 0);
signal sip_router_s16d1_0_in8_in_stop          : std_logic;
signal sip_router_s16d1_0_in8_in_dval          : std_logic;
signal sip_router_s16d1_0_in8_in_data          : std_logic_vector(63 downto 0);
signal sip_router_s16d1_0_in9_in_stop          : std_logic;
signal sip_router_s16d1_0_in9_in_dval          : std_logic;
signal sip_router_s16d1_0_in9_in_data          : std_logic_vector(63 downto 0);
signal sip_router_s16d1_0_in10_in_stop         : std_logic;
signal sip_router_s16d1_0_in10_in_dval         : std_logic;
signal sip_router_s16d1_0_in10_in_data         : std_logic_vector(63 downto 0);
signal sip_router_s16d1_0_in11_in_stop         : std_logic;
signal sip_router_s16d1_0_in11_in_dval         : std_logic;
signal sip_router_s16d1_0_in11_in_data         : std_logic_vector(63 downto 0);
signal sip_router_s16d1_0_in12_in_stop         : std_logic;
signal sip_router_s16d1_0_in12_in_dval         : std_logic;
signal sip_router_s16d1_0_in12_in_data         : std_logic_vector(63 downto 0);
signal sip_router_s16d1_0_in13_in_stop         : std_logic;
signal sip_router_s16d1_0_in13_in_dval         : std_logic;
signal sip_router_s16d1_0_in13_in_data         : std_logic_vector(63 downto 0);
signal sip_router_s16d1_0_in14_in_stop         : std_logic;
signal sip_router_s16d1_0_in14_in_dval         : std_logic;
signal sip_router_s16d1_0_in14_in_data         : std_logic_vector(63 downto 0);
signal sip_router_s16d1_0_in15_in_stop         : std_logic;
signal sip_router_s16d1_0_in15_in_dval         : std_logic;
signal sip_router_s16d1_0_in15_in_data         : std_logic_vector(63 downto 0);

--sip_fifo64k
signal sip_fifo64k_0_cmdclk_in_cmdclk          : std_logic;
signal sip_fifo64k_0_cmd_in_cmdin              : std_logic_vector(63 downto 0);
signal sip_fifo64k_0_cmd_in_cmdin_val          : std_logic;
signal sip_fifo64k_0_cmd_out_cmdout            : std_logic_vector(63 downto 0);
signal sip_fifo64k_0_cmd_out_cmdout_val        : std_logic;
signal sip_fifo64k_0_clk_clkin                 : std_logic_vector(31 downto 0);
signal sip_fifo64k_0_rst_rstin                 : std_logic_vector(31 downto 0);
signal sip_fifo64k_0_out0_out_stop             : std_logic;
signal sip_fifo64k_0_out0_out_dval             : std_logic;
signal sip_fifo64k_0_out0_out_data             : std_logic_vector(63 downto 0);
signal sip_fifo64k_0_in0_in_stop               : std_logic;
signal sip_fifo64k_0_in0_in_dval               : std_logic;
signal sip_fifo64k_0_in0_in_data               : std_logic_vector(63 downto 0);

-------------------------------------------------------------------------------------
--Components Declaration
-------------------------------------------------------------------------------------

component sip_cid
  generic
  (
   global_start_addr_gen                   : std_logic_vector(27 downto 0);
   global_stop_addr_gen                    : std_logic_vector(27 downto 0);
   private_start_addr_gen                  : std_logic_vector(27 downto 0);
   private_stop_addr_gen                   : std_logic_vector(27 downto 0)
);
  port
  (
   cmdclk_in_cmdclk                        : in    std_logic;
   cmd_in_cmdin                            : in    std_logic_vector(63 downto 0);
   cmd_in_cmdin_val                        : in    std_logic;
   rst_rstin                               : in    std_logic_vector(31 downto 0);
   cmd_out_cmdout                          : out   std_logic_vector(63 downto 0);
   cmd_out_cmdout_val                      : out   std_logic
  );
end component;

component sip_mac_engine
  port
  (
   cmdclk_out_cmdclk                       : out   std_logic;
   cmd_out_cmdout                          : out   std_logic_vector(63 downto 0);
   cmd_out_cmdout_val                      : out   std_logic;
   cmd_in_cmdin                            : in    std_logic_vector(63 downto 0);
   cmd_in_cmdin_val                        : in    std_logic;
   clkout_clkout                           : out   std_logic_vector(31 downto 0);
   rst_out_rstout                          : out   std_logic_vector(31 downto 0);
   cpu_reset                               : in    std_logic;
   sysclk_p                                : in    std_logic;
   sysclk_n                                : in    std_logic;
   phy_reset_l                             : out   std_logic;
   phy_mdc                                 : out   std_logic;
   phy_mdio                                : inout std_logic;
   phy_txctl_txen                          : out   std_logic;
   phy_txer                                : out   std_logic;
   phy_txc_gtxclk                          : out   std_logic;
   phy_txclk                               : in    std_logic;
   phy_txd                                 : out   std_logic_vector(7 downto 0);
   phy_crs                                 : in    std_logic;
   phy_col                                 : in    std_logic;
   phy_rxer                                : in    std_logic;
   phy_rxctrl_rxdv                         : in    std_logic;
   phy_rxclk                               : in    std_logic;
   phy_rxd                                 : in    std_logic_vector(7 downto 0);
   gpio_led                                : out   std_logic_vector(3 downto 0);
   in_data_in_stop                         : out   std_logic;
   in_data_in_dval                         : in    std_logic;
   in_data_in_data                         : in    std_logic_vector(63 downto 0);
   out_data_out_stop                       : in    std_logic;
   out_data_out_dval                       : out   std_logic;
   out_data_out_data                       : out   std_logic_vector(63 downto 0)
  );
end component;

component sip_i2c_master
  generic
  (
   global_start_addr_gen                   : std_logic_vector(27 downto 0);
   global_stop_addr_gen                    : std_logic_vector(27 downto 0);
   private_start_addr_gen                  : std_logic_vector(27 downto 0);
   private_stop_addr_gen                   : std_logic_vector(27 downto 0)
);
  port
  (
   clk_clkin                               : in    std_logic_vector(31 downto 0);
   rst_rstin                               : in    std_logic_vector(31 downto 0);
   cmdclk_in_cmdclk                        : in    std_logic;
   cmd_in_cmdin                            : in    std_logic_vector(63 downto 0);
   cmd_in_cmdin_val                        : in    std_logic;
   cmd_out_cmdout                          : out   std_logic_vector(63 downto 0);
   cmd_out_cmdout_val                      : out   std_logic;
   i2c_scl                                 : inout std_logic;
   i2c_sda                                 : inout std_logic
  );
end component;

component sip_cmd12_mux
  port
  (
   cmdclk_in_cmdclk                        : in    std_logic;
   cmd0_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd0_in_cmdin_val                       : in    std_logic;
   cmd1_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd1_in_cmdin_val                       : in    std_logic;
   cmd2_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd2_in_cmdin_val                       : in    std_logic;
   cmd3_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd3_in_cmdin_val                       : in    std_logic;
   cmd4_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd4_in_cmdin_val                       : in    std_logic;
   cmd5_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd5_in_cmdin_val                       : in    std_logic;
   cmd6_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd6_in_cmdin_val                       : in    std_logic;
   cmd7_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd7_in_cmdin_val                       : in    std_logic;
   cmd8_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd8_in_cmdin_val                       : in    std_logic;
   cmd9_in_cmdin                           : in    std_logic_vector(63 downto 0);
   cmd9_in_cmdin_val                       : in    std_logic;
   cmd10_in_cmdin                          : in    std_logic_vector(63 downto 0);
   cmd10_in_cmdin_val                      : in    std_logic;
   cmd11_in_cmdin                          : in    std_logic_vector(63 downto 0);
   cmd11_in_cmdin_val                      : in    std_logic;
   cmd_out_cmdout                          : out   std_logic_vector(63 downto 0);
   cmd_out_cmdout_val                      : out   std_logic
  );
end component;

component sip_fmc_ct_gen
  generic
  (
   global_start_addr_gen                   : std_logic_vector(27 downto 0);
   global_stop_addr_gen                    : std_logic_vector(27 downto 0);
   private_start_addr_gen                  : std_logic_vector(27 downto 0);
   private_stop_addr_gen                   : std_logic_vector(27 downto 0)
);
  port
  (
   cmdclk_in_cmdclk                        : in    std_logic;
   cmd_in_cmdin                            : in    std_logic_vector(63 downto 0);
   cmd_in_cmdin_val                        : in    std_logic;
   rst_rstin                               : in    std_logic_vector(31 downto 0);
   cmd_out_cmdout                          : out   std_logic_vector(63 downto 0);
   cmd_out_cmdout_val                      : out   std_logic;
   ref_clk_p                               : in    std_logic;
   ref_clk_n                               : in    std_logic;
   tx_p                                    : out   std_logic;
   tx_n                                    : out   std_logic;
   rx_p                                    : in    std_logic;
   rx_n                                    : in    std_logic;
   trig_out                                : out   std_logic
  );
end component;

component sip_fmc112
  generic
  (
   global_start_addr_gen                   : std_logic_vector(27 downto 0);
   global_stop_addr_gen                    : std_logic_vector(27 downto 0);
   private_start_addr_gen                  : std_logic_vector(27 downto 0);
   private_stop_addr_gen                   : std_logic_vector(27 downto 0)
);
  port
  (
   clk_clkin                               : in    std_logic_vector(31 downto 0);
   rst_rstin                               : in    std_logic_vector(31 downto 0);
   cmdclk_in_cmdclk                        : in    std_logic;
   cmd_in_cmdin                            : in    std_logic_vector(63 downto 0);
   cmd_in_cmdin_val                        : in    std_logic;
   cmd_out_cmdout                          : out   std_logic_vector(63 downto 0);
   cmd_out_cmdout_val                      : out   std_logic;
--Output ports for ADC data
  phy_data_clk     : out std_logic;                     -- ADC data clk
  phy_out_data0    : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data1    : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data2    : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data3    : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data4    : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data5    : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data6    : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data7    : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data8    : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data9    : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data10   : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
  phy_out_data11   : out std_logic_vector(15 downto 0); -- 1 sample, 16-bit format
--
   ctrl                                    : inout std_logic_vector(7 downto 0);
   clk_to_fpga_p                           : in    std_logic;
   clk_to_fpga_n                           : in    std_logic;
   ext_trigger_p                           : in    std_logic;
   ext_trigger_n                           : in    std_logic;
   ext_trigger                             : out   std_logic;
   outa_p                                  : in    std_logic_vector(11 downto 0);
   outa_n                                  : in    std_logic_vector(11 downto 0);
   outb_p                                  : in    std_logic_vector(11 downto 0);
   outb_n                                  : in    std_logic_vector(11 downto 0);
   dco_p                                   : in    std_logic_vector(2 downto 0);
   dco_n                                   : in    std_logic_vector(2 downto 0);
   frame_p                                 : in    std_logic_vector(2 downto 0);
   frame_n                                 : in    std_logic_vector(2 downto 0);
   pg_m2c                                  : in    std_logic;
   prsnt_m2c_l                             : in    std_logic
  );
end component;

component sip_router_s16d1
  generic
  (
   global_start_addr_gen                   : std_logic_vector(27 downto 0);
   global_stop_addr_gen                    : std_logic_vector(27 downto 0);
   private_start_addr_gen                  : std_logic_vector(27 downto 0);
   private_stop_addr_gen                   : std_logic_vector(27 downto 0)
);
  port
  (
   cmdclk_in_cmdclk                        : in    std_logic;
   cmd_in_cmdin                            : in    std_logic_vector(63 downto 0);
   cmd_in_cmdin_val                        : in    std_logic;
   cmd_out_cmdout                          : out   std_logic_vector(63 downto 0);
   cmd_out_cmdout_val                      : out   std_logic;
   clk_clkin                               : in    std_logic_vector(31 downto 0);
   rst_rstin                               : in    std_logic_vector(31 downto 0);
   out0_out_stop                           : in    std_logic;
   out0_out_dval                           : out   std_logic;
   out0_out_data                           : out   std_logic_vector(63 downto 0);
   in0_in_stop                             : out   std_logic;
   in0_in_dval                             : in    std_logic;
   in0_in_data                             : in    std_logic_vector(63 downto 0);
   in1_in_stop                             : out   std_logic;
   in1_in_dval                             : in    std_logic;
   in1_in_data                             : in    std_logic_vector(63 downto 0);
   in2_in_stop                             : out   std_logic;
   in2_in_dval                             : in    std_logic;
   in2_in_data                             : in    std_logic_vector(63 downto 0);
   in3_in_stop                             : out   std_logic;
   in3_in_dval                             : in    std_logic;
   in3_in_data                             : in    std_logic_vector(63 downto 0);
   in4_in_stop                             : out   std_logic;
   in4_in_dval                             : in    std_logic;
   in4_in_data                             : in    std_logic_vector(63 downto 0);
   in5_in_stop                             : out   std_logic;
   in5_in_dval                             : in    std_logic;
   in5_in_data                             : in    std_logic_vector(63 downto 0);
   in6_in_stop                             : out   std_logic;
   in6_in_dval                             : in    std_logic;
   in6_in_data                             : in    std_logic_vector(63 downto 0);
   in7_in_stop                             : out   std_logic;
   in7_in_dval                             : in    std_logic;
   in7_in_data                             : in    std_logic_vector(63 downto 0);
   in8_in_stop                             : out   std_logic;
   in8_in_dval                             : in    std_logic;
   in8_in_data                             : in    std_logic_vector(63 downto 0);
   in9_in_stop                             : out   std_logic;
   in9_in_dval                             : in    std_logic;
   in9_in_data                             : in    std_logic_vector(63 downto 0);
   in10_in_stop                            : out   std_logic;
   in10_in_dval                            : in    std_logic;
   in10_in_data                            : in    std_logic_vector(63 downto 0);
   in11_in_stop                            : out   std_logic;
   in11_in_dval                            : in    std_logic;
   in11_in_data                            : in    std_logic_vector(63 downto 0);
   in12_in_stop                            : out   std_logic;
   in12_in_dval                            : in    std_logic;
   in12_in_data                            : in    std_logic_vector(63 downto 0);
   in13_in_stop                            : out   std_logic;
   in13_in_dval                            : in    std_logic;
   in13_in_data                            : in    std_logic_vector(63 downto 0);
   in14_in_stop                            : out   std_logic;
   in14_in_dval                            : in    std_logic;
   in14_in_data                            : in    std_logic_vector(63 downto 0);
   in15_in_stop                            : out   std_logic;
   in15_in_dval                            : in    std_logic;
   in15_in_data                            : in    std_logic_vector(63 downto 0)
  );
end component;

component sip_fifo64k
  generic
  (
   global_start_addr_gen                   : std_logic_vector(27 downto 0);
   global_stop_addr_gen                    : std_logic_vector(27 downto 0);
   private_start_addr_gen                  : std_logic_vector(27 downto 0);
   private_stop_addr_gen                   : std_logic_vector(27 downto 0)
);
  port
  (
   cmdclk_in_cmdclk                        : in    std_logic;
   cmd_in_cmdin                            : in    std_logic_vector(63 downto 0);
   cmd_in_cmdin_val                        : in    std_logic;
   cmd_out_cmdout                          : out   std_logic_vector(63 downto 0);
   cmd_out_cmdout_val                      : out   std_logic;
   clk_clkin                               : in    std_logic_vector(31 downto 0);
   rst_rstin                               : in    std_logic_vector(31 downto 0);
   out0_out_stop                           : in    std_logic;
   out0_out_dval                           : out   std_logic;
   out0_out_data                           : out   std_logic_vector(63 downto 0);
   in0_in_stop                             : out   std_logic;
   in0_in_dval                             : in    std_logic;
   in0_in_data                             : in    std_logic_vector(63 downto 0)
  );
end component;



begin


-------------------------------------------------------------------------------------
--Components Instantiation
-------------------------------------------------------------------------------------
sip_cid_0 : sip_cid
generic map
(
   global_start_addr_gen     =>   x"0000000",
   global_stop_addr_gen      =>   x"0001FFF",
   private_start_addr_gen    =>   x"0002000",
   private_stop_addr_gen     =>   x"00023FF"
)
port map
(
   cmdclk_in_cmdclk          =>   sip_mac_engine_0_cmdclk_out_cmdclk,
   cmd_in_cmdin              =>   sip_mac_engine_0_cmd_out_cmdout,
   cmd_in_cmdin_val          =>   sip_mac_engine_0_cmd_out_cmdout_val,
   rst_rstin                 =>   sip_mac_engine_0_rst_out_rstout,
   cmd_out_cmdout            =>   sip_cid_0_cmd_out_cmdout,
   cmd_out_cmdout_val        =>   sip_cid_0_cmd_out_cmdout_val
);

--sip_mac_engine_0 : sip_mac_engine
--port map
--(
--   cmdclk_out_cmdclk         =>   sip_mac_engine_0_cmdclk_out_cmdclk,
--   cmd_out_cmdout            =>   sip_mac_engine_0_cmd_out_cmdout,
--   cmd_out_cmdout_val        =>   sip_mac_engine_0_cmd_out_cmdout_val,
--   cmd_in_cmdin              =>   sip_cmd12_mux_0_cmd_out_cmdout,
--   cmd_in_cmdin_val          =>   sip_cmd12_mux_0_cmd_out_cmdout_val,
--   clkout_clkout             =>   sip_mac_engine_0_clkout_clkout,
--   rst_out_rstout            =>   sip_mac_engine_0_rst_out_rstout,
--   cpu_reset                 =>   cpu_reset_0,
--   sysclk_p                  =>   sysclk_p_0,
--   sysclk_n                  =>   sysclk_n_0,
--   phy_reset_l               =>   phy_reset_l_0,
--   phy_mdc                   =>   phy_mdc_0,
--   phy_mdio                  =>   phy_mdio_0,
--   phy_txctl_txen            =>   phy_txctl_txen_0,
--   phy_txer                  =>   phy_txer_0,
--   phy_txc_gtxclk            =>   phy_txc_gtxclk_0,
--   phy_txclk                 =>   phy_txclk_0,
--   phy_txd                   =>   phy_txd_0,
--   phy_crs                   =>   phy_crs_0,
--   phy_col                   =>   phy_col_0,
--   phy_rxer                  =>   phy_rxer_0,
--   phy_rxctrl_rxdv           =>   phy_rxctrl_rxdv_0,
--   phy_rxclk                 =>   phy_rxclk_0,
--   phy_rxd                   =>   phy_rxd_0,
--   gpio_led                  =>   gpio_led_0,
--   in_data_in_stop           =>   sip_fifo64k_0_out0_out_stop,
--   in_data_in_dval           =>   sip_fifo64k_0_out0_out_dval,
--   in_data_in_data           =>   sip_fifo64k_0_out0_out_data,
--   out_data_out_stop         =>   sip_mac_engine_0_out_data_out_stop,
--   out_data_out_dval         =>   sip_mac_engine_0_out_data_out_dval,
--   out_data_out_data         =>   sip_mac_engine_0_out_data_out_data
--);

sip_mac_engine_0_cmdclk_out_cmdclk  <= CLK125;
sip_mac_engine_0_cmd_out_cmdout     <= CMD_IN;
sip_mac_engine_0_cmd_out_cmdout_val <= CMD_IN_VAL;
CMD_OUT                             <= sip_cmd12_mux_0_cmd_out_cmdout;
CMD_OUT_VAL                         <= sip_cmd12_mux_0_cmd_out_cmdout_val;
sip_mac_engine_0_clkout_clkout      <= (OTHERS => CLK125);
sip_mac_engine_0_rst_out_rstout     <= (OTHERS => RESET);

sip_i2c_master_0 : sip_i2c_master
generic map
(
   global_start_addr_gen     =>   x"0000000",
   global_stop_addr_gen      =>   x"0001FFF",
   private_start_addr_gen    =>   x"0002400",
   private_stop_addr_gen     =>   x"00123FF"
)
port map
(
   clk_clkin                 =>   sip_mac_engine_0_clkout_clkout,
   rst_rstin                 =>   sip_mac_engine_0_rst_out_rstout,
   cmdclk_in_cmdclk          =>   sip_mac_engine_0_cmdclk_out_cmdclk,
   cmd_in_cmdin              =>   sip_mac_engine_0_cmd_out_cmdout,
   cmd_in_cmdin_val          =>   sip_mac_engine_0_cmd_out_cmdout_val,
   cmd_out_cmdout            =>   sip_i2c_master_0_cmd_out_cmdout,
   cmd_out_cmdout_val        =>   sip_i2c_master_0_cmd_out_cmdout_val,
   i2c_scl                   =>   i2c_scl_0,
   i2c_sda                   =>   i2c_sda_0
);

sip_cmd12_mux_0 : sip_cmd12_mux
port map
(
   cmdclk_in_cmdclk          =>   sip_mac_engine_0_cmdclk_out_cmdclk,
   cmd0_in_cmdin             =>   sip_cid_0_cmd_out_cmdout,
   cmd0_in_cmdin_val         =>   sip_cid_0_cmd_out_cmdout_val,
   cmd1_in_cmdin             =>   sip_i2c_master_0_cmd_out_cmdout,
   cmd1_in_cmdin_val         =>   sip_i2c_master_0_cmd_out_cmdout_val,
   cmd2_in_cmdin             =>   sip_fmc_ct_gen_0_cmd_out_cmdout,
   cmd2_in_cmdin_val         =>   sip_fmc_ct_gen_0_cmd_out_cmdout_val,
   cmd3_in_cmdin             =>   sip_fmc112_1_cmd_out_cmdout,
   cmd3_in_cmdin_val         =>   sip_fmc112_1_cmd_out_cmdout_val,
   cmd4_in_cmdin             =>   sip_router_s16d1_0_cmd_out_cmdout,
   cmd4_in_cmdin_val         =>   sip_router_s16d1_0_cmd_out_cmdout_val,
   cmd5_in_cmdin             =>   sip_fifo64k_0_cmd_out_cmdout,
   cmd5_in_cmdin_val         =>   sip_fifo64k_0_cmd_out_cmdout_val,
   cmd6_in_cmdin             =>   (others=>'0'),
   cmd6_in_cmdin_val         =>   '0',
   cmd7_in_cmdin             =>   (others=>'0'),
   cmd7_in_cmdin_val         =>   '0',
   cmd8_in_cmdin             =>   (others=>'0'),
   cmd8_in_cmdin_val         =>   '0',
   cmd9_in_cmdin             =>   (others=>'0'),
   cmd9_in_cmdin_val         =>   '0',
   cmd10_in_cmdin            =>   (others=>'0'),
   cmd10_in_cmdin_val        =>   '0',
   cmd11_in_cmdin            =>   (others=>'0'),
   cmd11_in_cmdin_val        =>   '0',
   cmd_out_cmdout            =>   sip_cmd12_mux_0_cmd_out_cmdout,
   cmd_out_cmdout_val        =>   sip_cmd12_mux_0_cmd_out_cmdout_val
);

sip_fmc_ct_gen_0 : sip_fmc_ct_gen
generic map
(
   global_start_addr_gen     =>   x"0000000",
   global_stop_addr_gen      =>   x"0001FFF",
   private_start_addr_gen    =>   x"0012400",
   private_stop_addr_gen     =>   x"0012401"
)
port map
(
   cmdclk_in_cmdclk          =>   sip_mac_engine_0_cmdclk_out_cmdclk,
   cmd_in_cmdin              =>   sip_mac_engine_0_cmd_out_cmdout,
   cmd_in_cmdin_val          =>   sip_mac_engine_0_cmd_out_cmdout_val,
   rst_rstin                 =>   sip_mac_engine_0_rst_out_rstout,
   cmd_out_cmdout            =>   sip_fmc_ct_gen_0_cmd_out_cmdout,
   cmd_out_cmdout_val        =>   sip_fmc_ct_gen_0_cmd_out_cmdout_val,
   ref_clk_p                 =>   sip_fmc_ct_gen_0_ext_fmc_ct_gen_ref_clk_p,
   ref_clk_n                 =>   sip_fmc_ct_gen_0_ext_fmc_ct_gen_ref_clk_n,
   tx_p                      =>   sip_fmc_ct_gen_0_ext_fmc_ct_gen_tx_p,
   tx_n                      =>   sip_fmc_ct_gen_0_ext_fmc_ct_gen_tx_n,
   rx_p                      =>   sip_fmc_ct_gen_0_ext_fmc_ct_gen_rx_p,
   rx_n                      =>   sip_fmc_ct_gen_0_ext_fmc_ct_gen_rx_n,
   trig_out                  =>   trig_out_0
);

sip_fmc112_1 : sip_fmc112
generic map
(
   global_start_addr_gen     =>   x"0000000",
   global_stop_addr_gen      =>   x"0001FFF",
   private_start_addr_gen    =>   x"0012402",
   private_stop_addr_gen     =>   x"0013401"
)
port map
(
   clk_clkin                 =>   sip_mac_engine_0_clkout_clkout,
   rst_rstin                 =>   sip_mac_engine_0_rst_out_rstout,
   cmdclk_in_cmdclk          =>   sip_mac_engine_0_cmdclk_out_cmdclk,
   cmd_in_cmdin              =>   sip_mac_engine_0_cmd_out_cmdout,
   cmd_in_cmdin_val          =>   sip_mac_engine_0_cmd_out_cmdout_val,
   cmd_out_cmdout            =>   sip_fmc112_1_cmd_out_cmdout,
   cmd_out_cmdout_val        =>   sip_fmc112_1_cmd_out_cmdout_val,
--
   phy_data_clk              =>   PHY_DATA_CLK,
   phy_out_data0             =>   PHY_OUT_DATA0,
   phy_out_data1             =>   PHY_OUT_DATA1,
   phy_out_data2             =>   PHY_OUT_DATA2,
   phy_out_data3             =>   PHY_OUT_DATA3,
   phy_out_data4             =>   PHY_OUT_DATA4,
   phy_out_data5             =>   PHY_OUT_DATA5,
   phy_out_data6             =>   PHY_OUT_DATA6,
   phy_out_data7             =>   PHY_OUT_DATA7,
   phy_out_data8             =>   PHY_OUT_DATA8,
   phy_out_data9             =>   PHY_OUT_DATA9,
   phy_out_data10            =>   PHY_OUT_DATA10,
   phy_out_data11            =>   PHY_OUT_DATA11,
--
   ctrl                      =>   ctrl_1,
   clk_to_fpga_p             =>   clk_to_fpga_p_1,
   clk_to_fpga_n             =>   clk_to_fpga_n_1,
   ext_trigger_p             =>   ext_trigger_p_1,
   ext_trigger_n             =>   ext_trigger_n_1,
   ext_trigger               =>   ext_trigger,
   outa_p                    =>   outa_p_1,
   outa_n                    =>   outa_n_1,
   outb_p                    =>   outb_p_1,
   outb_n                    =>   outb_n_1,
   dco_p                     =>   dco_p_1,
   dco_n                     =>   dco_n_1,
   frame_p                   =>   frame_p_1,
   frame_n                   =>   frame_n_1,
   pg_m2c                    =>   pg_m2c_1,
   prsnt_m2c_l               =>   prsnt_m2c_l_1
);

sip_router_s16d1_0 : sip_router_s16d1
generic map
(
   global_start_addr_gen     =>   x"0000000",
   global_stop_addr_gen      =>   x"0001FFF",
   private_start_addr_gen    =>   x"0013402",
   private_stop_addr_gen     =>   x"0013403"
)
port map
(
   cmdclk_in_cmdclk          =>   sip_mac_engine_0_cmdclk_out_cmdclk,
   cmd_in_cmdin              =>   sip_mac_engine_0_cmd_out_cmdout,
   cmd_in_cmdin_val          =>   sip_mac_engine_0_cmd_out_cmdout_val,
   cmd_out_cmdout            =>   sip_router_s16d1_0_cmd_out_cmdout,
   cmd_out_cmdout_val        =>   sip_router_s16d1_0_cmd_out_cmdout_val,
   clk_clkin                 =>   sip_mac_engine_0_clkout_clkout,
   rst_rstin                 =>   sip_mac_engine_0_rst_out_rstout,
   out0_out_stop             =>   sip_router_s16d1_0_out0_out_stop,
   out0_out_dval             =>   sip_router_s16d1_0_out0_out_dval,
   out0_out_data             =>   sip_router_s16d1_0_out0_out_data,
   in0_in_stop               =>   sip_fmc112_1_adc0_out_stop,
   in0_in_dval               =>   sip_fmc112_1_adc0_out_dval,
   in0_in_data               =>   sip_fmc112_1_adc0_out_data,
   in1_in_stop               =>   sip_fmc112_1_adc1_out_stop,
   in1_in_dval               =>   sip_fmc112_1_adc1_out_dval,
   in1_in_data               =>   sip_fmc112_1_adc1_out_data,
   in2_in_stop               =>   sip_fmc112_1_adc2_out_stop,
   in2_in_dval               =>   sip_fmc112_1_adc2_out_dval,
   in2_in_data               =>   sip_fmc112_1_adc2_out_data,
   in3_in_stop               =>   sip_fmc112_1_adc3_out_stop,
   in3_in_dval               =>   sip_fmc112_1_adc3_out_dval,
   in3_in_data               =>   sip_fmc112_1_adc3_out_data,
   in4_in_stop               =>   sip_fmc112_1_adc4_out_stop,
   in4_in_dval               =>   sip_fmc112_1_adc4_out_dval,
   in4_in_data               =>   sip_fmc112_1_adc4_out_data,
   in5_in_stop               =>   sip_fmc112_1_adc5_out_stop,
   in5_in_dval               =>   sip_fmc112_1_adc5_out_dval,
   in5_in_data               =>   sip_fmc112_1_adc5_out_data,
   in6_in_stop               =>   sip_fmc112_1_adc6_out_stop,
   in6_in_dval               =>   sip_fmc112_1_adc6_out_dval,
   in6_in_data               =>   sip_fmc112_1_adc6_out_data,
   in7_in_stop               =>   sip_fmc112_1_adc7_out_stop,
   in7_in_dval               =>   sip_fmc112_1_adc7_out_dval,
   in7_in_data               =>   sip_fmc112_1_adc7_out_data,
   in8_in_stop               =>   sip_fmc112_1_adc8_out_stop,
   in8_in_dval               =>   sip_fmc112_1_adc8_out_dval,
   in8_in_data               =>   sip_fmc112_1_adc8_out_data,
   in9_in_stop               =>   sip_fmc112_1_adc9_out_stop,
   in9_in_dval               =>   sip_fmc112_1_adc9_out_dval,
   in9_in_data               =>   sip_fmc112_1_adc9_out_data,
   in10_in_stop              =>   sip_fmc112_1_adc10_out_stop,
   in10_in_dval              =>   sip_fmc112_1_adc10_out_dval,
   in10_in_data              =>   sip_fmc112_1_adc10_out_data,
   in11_in_stop              =>   sip_fmc112_1_adc11_out_stop,
   in11_in_dval              =>   sip_fmc112_1_adc11_out_dval,
   in11_in_data              =>   sip_fmc112_1_adc11_out_data,
   in12_in_stop              =>   open,
   in12_in_dval              =>   '0',
   in12_in_data              =>   (others=>'0'),
   in13_in_stop              =>   open,
   in13_in_dval              =>   '0',
   in13_in_data              =>   (others=>'0'),
   in14_in_stop              =>   open,
   in14_in_dval              =>   '0',
   in14_in_data              =>   (others=>'0'),
   in15_in_stop              =>   open,
   in15_in_dval              =>   '0',
   in15_in_data              =>   (others=>'0')
);

sip_fifo64k_0 : sip_fifo64k
generic map
(
   global_start_addr_gen     =>   x"0000000",
   global_stop_addr_gen      =>   x"0001FFF",
   private_start_addr_gen    =>   x"0013404",
   private_stop_addr_gen     =>   x"0013409"
)
port map
(
   cmdclk_in_cmdclk          =>   sip_mac_engine_0_cmdclk_out_cmdclk,
   cmd_in_cmdin              =>   sip_mac_engine_0_cmd_out_cmdout,
   cmd_in_cmdin_val          =>   sip_mac_engine_0_cmd_out_cmdout_val,
   cmd_out_cmdout            =>   sip_fifo64k_0_cmd_out_cmdout,
   cmd_out_cmdout_val        =>   sip_fifo64k_0_cmd_out_cmdout_val,
   clk_clkin                 =>   sip_mac_engine_0_clkout_clkout,
   rst_rstin                 =>   sip_mac_engine_0_rst_out_rstout,
   out0_out_stop             =>   sip_fifo64k_0_out0_out_stop,
   out0_out_dval             =>   sip_fifo64k_0_out0_out_dval,
   out0_out_data             =>   sip_fifo64k_0_out0_out_data,
   in0_in_stop               =>   sip_router_s16d1_0_out0_out_stop,
   in0_in_dval               =>   sip_router_s16d1_0_out0_out_dval,
   in0_in_data               =>   sip_router_s16d1_0_out0_out_data
);

-- ymei
-- was in the mac engine
idelayctrl_inst : idelayctrl
  PORT MAP (
    RST    => RESET,
    REFCLK => CLK200,
    RDY    => OPEN
  );

end architecture arch_kc705_fmc112   ; -- of kc705_fmc112
