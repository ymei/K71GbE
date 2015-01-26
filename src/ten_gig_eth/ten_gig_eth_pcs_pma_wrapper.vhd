-------------------------------------------------------------------------------
-- Title      : Example Design level wrapper
-- Project    : 10GBASE-R
-------------------------------------------------------------------------------
-- File       : ten_gig_eth_pcs_pma_0_example_design.vhd
-------------------------------------------------------------------------------
-- Description: This file is a wrapper for the 10GBASE-R core; it contains the 
-- core support level and a few registers, including a DDR output register
-------------------------------------------------------------------------------
-- (c) Copyright 2009 - 2014 Xilinx, Inc. All rights reserved.
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

library ieee;
use ieee.std_logic_1164.all;



ENTITY ten_gig_eth_pcs_pma_wrapper IS
  PORT (
    refclk_p        : IN  std_logic;
    refclk_n        : IN  std_logic;
    core_clk156_out : OUT std_logic;
    reset           : IN  std_logic;
    sim_speedup_control: in std_logic := '0';
    qpll_locked     : OUT std_logic;
    xgmii_txd       : IN  std_logic_vector(63 DOWNTO 0);
    xgmii_txc       : IN  std_logic_vector(7 DOWNTO 0);
    xgmii_rxd       : OUT std_logic_vector(63 DOWNTO 0);
    xgmii_rxc       : OUT std_logic_vector(7 DOWNTO 0);
    xgmii_rx_clk    : OUT std_logic;
    txp             : OUT std_logic;
    txn             : OUT std_logic;
    rxp             : IN  std_logic;
    rxn             : IN  std_logic;
    mdc             : IN  std_logic;
    mdio_in         : IN  std_logic;
    mdio_out        : OUT std_logic;
    mdio_tri        : OUT std_logic;
    prtad           : IN  std_logic_vector(4 DOWNTO 0);
    core_status     : OUT std_logic_vector(7 DOWNTO 0);
    resetdone       : OUT std_logic;
    signal_detect   : IN  std_logic;
    tx_fault        : IN  std_logic;
    tx_disable      : OUT std_logic
  );
END ten_gig_eth_pcs_pma_wrapper;

library ieee;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

architecture wrapper of ten_gig_eth_pcs_pma_wrapper is

----------------------------------------------------------------------------
-- Component Declaration for the 10GBASE-R block level.
----------------------------------------------------------------------------

  component ten_gig_eth_pcs_pma_0_support is
    port (
      refclk_p             : in  std_logic;
      refclk_n             : in  std_logic;
      core_clk156_out      : out std_logic;
      reset                : in  std_logic;
      sim_speedup_control  : in  std_logic := '0';
      qplloutclk_out       : out std_logic;
      qplloutrefclk_out    : out std_logic;
      qplllock_out         : out std_logic;
      dclk_out             : out std_logic;            
      txusrclk_out         : out std_logic;
      txusrclk2_out        : out std_logic;
      gttxreset_out        : out std_logic;
      gtrxreset_out        : out std_logic;
      txuserrdy_out        : out std_logic;
      areset_clk156_out     : out std_logic;
      reset_counter_done_out : out std_logic;
      xgmii_txd            : in  std_logic_vector(63 downto 0);
      xgmii_txc            : in  std_logic_vector(7 downto 0);
      xgmii_rxd            : out std_logic_vector(63 downto 0);
      xgmii_rxc            : out std_logic_vector(7 downto 0);
      txp                  : out std_logic;
      txn                  : out std_logic;
      rxp                  : in  std_logic;
      rxn                  : in  std_logic;
      resetdone            : out std_logic;
      signal_detect        : in  std_logic;
      tx_fault             : in  std_logic;
      tx_disable           : out std_logic;
      mdc                  : in  std_logic;
      mdio_in              : in  std_logic;
      mdio_out             : out std_logic;
      mdio_tri             : out std_logic;
      prtad                : in  std_logic_vector(4 downto 0);
      pma_pmd_type         : in std_logic_vector(2 downto 0);
      core_status          : out std_logic_vector(7 downto 0)); 
  end component;

----------------------------------------------------------------------------
-- Signal declarations.
----------------------------------------------------------------------------

  signal clk156      : std_logic;

  signal qplloutclk_out : std_logic;
  signal qplloutrefclk_out : std_logic;
  signal qplllock_out : std_logic;
  signal dclk_out : std_logic;
  
  signal txusrclk_out : std_logic;
  signal txusrclk2_out : std_logic;
  signal gttxreset_out        : std_logic;
  signal gtrxreset_out        : std_logic;
  signal txuserrdy_out        : std_logic;
    
  signal areset_clk156_out     : std_logic;

  signal reset_counter_done_out : std_logic;
  
  signal xgmii_txd_reg : std_logic_vector(63 downto 0);
  signal xgmii_txc_reg : std_logic_vector(7 downto 0);
    
  signal xgmii_rxd_int : std_logic_vector(63 downto 0);
  signal xgmii_rxc_int : std_logic_vector(7 downto 0);
    

  signal mdio_out_int : std_logic;
  signal mdio_tri_int : std_logic;
  signal mdc_reg     : std_logic;
  signal mdio_in_reg : std_logic;

begin



  -- Add a pipeline to the xmgii_tx inputs, to aid timing closure
  tx_reg_proc : process(clk156)
  begin
    if(clk156'event and clk156 = '1') then
      xgmii_txd_reg <= xgmii_txd; 
      xgmii_txc_reg <= xgmii_txc; 
    end if;
  end process;     

  -- Add a pipeline to the xmgii_rx outputs, to aid timing closure
  rx_reg_proc : process(clk156)
  begin
    if(clk156'event and clk156 = '1') then
      xgmii_rxd <= xgmii_rxd_int; 
      xgmii_rxc <= xgmii_rxc_int; 
    end if;
  end process;     

  -- Add a pipeline to the mdio in/outputs, to aid timing closure
  -- This is safe since the mdio clk is running so slowly.
  mdio_outtri_reg_proc : process(clk156)
  begin
    if(clk156'event and clk156 = '1') then
      mdio_tri <= mdio_tri_int;
      mdio_out <= mdio_out_int; 
      mdc_reg <= mdc;
      mdio_in_reg <= mdio_in;
    end if;
  end process;  

  -- Instance the 10GBASE-KR Core Support layer
  ten_gig_eth_pcs_pma_core_support_layer_i : ten_gig_eth_pcs_pma_0_support
    port map (
      refclk_p            => refclk_p,
      refclk_n            => refclk_n,
      core_clk156_out     => clk156,
      reset               => reset,
      sim_speedup_control => sim_speedup_control,
      qplloutclk_out      => qplloutclk_out,
      qplloutrefclk_out   => qplloutrefclk_out,
      qplllock_out        => qplllock_out,
      dclk_out            => dclk_out,        
      
      txusrclk_out        => txusrclk_out,
      txusrclk2_out       => txusrclk2_out,
      gttxreset_out          => gttxreset_out,
      gtrxreset_out          => gtrxreset_out,
      txuserrdy_out          => txuserrdy_out,
      
      areset_clk156_out      => areset_clk156_out,      
      reset_counter_done_out => reset_counter_done_out,
      xgmii_txd           => xgmii_txd_reg,
      xgmii_txc           => xgmii_txc_reg,
      xgmii_rxd           => xgmii_rxd_int,
      xgmii_rxc           => xgmii_rxc_int,
      txp                 => txp,
      txn                 => txn,
      rxp                 => rxp,
      rxn                 => rxn,
      resetdone           => resetdone,
      signal_detect       => signal_detect,
      tx_fault            => tx_fault,
      tx_disable          => tx_disable,
      mdc                 => mdc_reg,
      mdio_in             => mdio_in_reg,
      mdio_out            => mdio_out_int,
      mdio_tri            => mdio_tri_int,
      prtad               => prtad,
      pma_pmd_type        => "101",
      core_status         => core_status); 

  qpll_locked     <= qplllock_out;
  core_clk156_out <= clk156;

  rx_clk_ddr : ODDR
    generic map (
      SRTYPE => "ASYNC",
      DDR_CLK_EDGE => "SAME_EDGE")
    port map (
      Q =>  xgmii_rx_clk,
      D1 => '0',
      D2 => '1',
      C  => clk156,
      CE => '1',
      R  => '0',
      S  => '0');


end wrapper;
