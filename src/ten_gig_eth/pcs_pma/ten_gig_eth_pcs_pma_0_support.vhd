-------------------------------------------------------------------------------
-- Title      : Core Support level wrapper
-- Project    : 10GBASE-R
-------------------------------------------------------------------------------
-- File       : ten_gig_eth_pcs_pma_0_support.vhd
-------------------------------------------------------------------------------
-- Description: This file is a wrapper for the 10GBASE-R/KR Core Support level
-- It contains the block level for the core which a user would instance in
-- their own design, along with various components which can be shared between
-- several block levels.
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
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ten_gig_eth_pcs_pma_0_support is
  port (
    refclk_p             : in  std_logic;
    refclk_n             : in  std_logic;
    dclk_out             : out std_logic; -- ymei
    coreclk_out          : out std_logic;
    reset                : in  std_logic;
    sim_speedup_control  : in  std_logic := '0';
    qplloutclk_out       : out std_logic;
    qplloutrefclk_out    : out std_logic;
    qplllock_out         : out std_logic;
    areset_datapathclk_out   : out std_logic;
    txusrclk_out         : out std_logic;
    txusrclk2_out        : out std_logic;
    gttxreset_out        : out std_logic;
    gtrxreset_out        : out std_logic;
    txuserrdy_out        : out std_logic;
    rxrecclk_out         : out std_logic;
    reset_counter_done_out : out std_logic;
    xgmii_txd            : in  std_logic_vector(63 downto 0);
    xgmii_txc            : in  std_logic_vector(7 downto 0);
    xgmii_rxd            : out std_logic_vector(63 downto 0);
    xgmii_rxc            : out std_logic_vector(7 downto 0);
    txp                  : out std_logic;
    txn                  : out std_logic;
    rxp                  : in  std_logic;
    rxn                  : in  std_logic;
    mdc                  : in  std_logic;
    mdio_in              : in  std_logic;
    mdio_out             : out std_logic;
    mdio_tri             : out std_logic;
    prtad                : in  std_logic_vector(4 downto 0);
    core_status          : out std_logic_vector(7 downto 0);
    resetdone_out        : out std_logic;
    signal_detect        : in  std_logic;
    tx_fault             : in  std_logic;
    pma_pmd_type         : in  std_logic_vector(2 downto 0);
    tx_disable           : out std_logic);
end entity ten_gig_eth_pcs_pma_0_support;

architecture wrapper of ten_gig_eth_pcs_pma_0_support is

    attribute DowngradeIPIdentifiedWarnings: string;

    attribute DowngradeIPIdentifiedWarnings of wrapper : architecture is "yes";

  component ten_gig_eth_pcs_pma_0_gt_common
  generic
  (
    WRAPPER_SIM_GTRESET_SPEEDUP : string := "TRUE"
  );
  port
  (
    refclk         : in  std_logic;
    qpllreset      : in  std_logic;
    qplllock       : out std_logic;
    qplloutclk     : out std_logic;
    qplloutrefclk  : out std_logic
  );
  end component;

  component ten_gig_eth_pcs_pma_0_shared_clock_and_reset
  port
  (
    areset                  : in  std_logic;
    refclk_p                : in  std_logic;
    refclk_n                : in  std_logic;
    refclk                  : out std_logic;
    coreclk                 : out std_logic;
    dclk                    : out std_logic; -- ymei
    txoutclk                : in  std_logic;
    qplllock                : in  std_logic;
    areset_coreclk          : out std_logic;
    gttxreset               : out std_logic;
    gtrxreset               : out std_logic;
    txuserrdy               : out std_logic;
    txusrclk                : out std_logic;
    txusrclk2               : out std_logic;
    qpllreset               : out std_logic;
    reset_counter_done      : out std_logic
  );
  end component;


  component ten_gig_eth_pcs_pma_0 is
  port
  (
     coreclk            : in  std_logic;
     dclk               : in  std_logic;
     txusrclk           : in  std_logic;
     txusrclk2          : in  std_logic;
     txoutclk           : out std_logic;
     areset_coreclk     : in  std_logic;
     txuserrdy          : in  std_logic;
     rxrecclk_out       : out std_logic;
     areset             : in  std_logic;
     gttxreset          : in  std_logic;
     gtrxreset          : in  std_logic;
     sim_speedup_control: in  std_logic := '0';
     qplllock           : in  std_logic;
     qplloutclk         : in  std_logic;
     qplloutrefclk      : in  std_logic;
     reset_counter_done : in  std_logic;
     xgmii_txd        : in  std_logic_vector(63 downto 0);
     xgmii_txc        : in  std_logic_vector(7 downto 0);
     xgmii_rxd        : out std_logic_vector(63 downto 0);
     xgmii_rxc        : out std_logic_vector(7 downto 0);
     txp              : out std_logic;
     txn              : out std_logic;
     rxp              : in  std_logic;
     rxn              : in  std_logic;
     mdc              : in  std_logic;
     mdio_in          : in  std_logic;
     mdio_out         : out std_logic;
     mdio_tri         : out std_logic;
     prtad            : in  std_logic_vector(4 downto 0);
     core_status      : out std_logic_vector(7 downto 0);
     tx_resetdone     : out std_logic;
     rx_resetdone     : out std_logic;
     signal_detect    : in  std_logic;
     tx_fault         : in  std_logic;
     drp_req          : out std_logic;
     drp_gnt          : in  std_logic;
     drp_den_o          : out std_logic;
     drp_dwe_o          : out std_logic;
     drp_daddr_o        : out std_logic_vector(15 downto 0);
     drp_di_o           : out std_logic_vector(15 downto 0);
     drp_drdy_i         : in  std_logic;
     drp_drpdo_i        : in  std_logic_vector(15 downto 0);
     drp_den_i          : in  std_logic;
     drp_dwe_i          : in  std_logic;
     drp_daddr_i        : in  std_logic_vector(15 downto 0);
     drp_di_i           : in  std_logic_vector(15 downto 0);
     drp_drdy_o         : out std_logic;
     drp_drpdo_o        : out std_logic_vector(15 downto 0);
     pma_pmd_type     : in  std_logic_vector(2 downto 0);
     tx_disable       : out std_logic);
  end component;

  -- Signal declarations
  signal dclk_i : std_logic; -- ymei
  signal coreclk : std_logic;
  signal txoutclk : std_logic;
  signal drp_req : std_logic;
  signal drp_gnt : std_logic;
  signal drp_den_o   : std_logic;
  signal drp_dwe_o   : std_logic;
  signal drp_daddr_o : std_logic_vector(15 downto 0);
  signal drp_di_o    : std_logic_vector(15 downto 0);
  signal drp_drdy_o  : std_logic;
  signal drp_drpdo_o : std_logic_vector(15 downto 0);
  signal drp_den_i   : std_logic;
  signal drp_dwe_i   : std_logic;
  signal drp_daddr_i : std_logic_vector(15 downto 0);
  signal drp_di_i    : std_logic_vector(15 downto 0);
  signal drp_drdy_i  : std_logic;
  signal drp_drpdo_i : std_logic_vector(15 downto 0);

  signal refclk : std_logic;
  signal qpllreset : std_logic;
  signal qplllock : std_logic;
  signal qplloutclk : std_logic;
  signal qplloutrefclk : std_logic;

  signal tx_resetdone_int : std_logic;
  signal rx_resetdone_int : std_logic;
  signal areset_coreclk : std_logic;
  signal gttxreset : std_logic;
  signal gtrxreset : std_logic;
  signal txuserrdy : std_logic;
  signal reset_counter_done : std_logic;
  signal areset_txusrclk2 : std_logic;

  signal txusrclk : std_logic;
  signal txusrclk2 : std_logic;
  
begin
  dclk_out <= dclk_i; -- ymei
  coreclk_out <= coreclk;
  resetdone_out <= tx_resetdone_int and rx_resetdone_int;

  -- If no arbitration is required on the GT DRP ports then connect REQ to GNT
  -- and connect other signals i <= o;
  drp_gnt <= drp_req;
  drp_den_i <= drp_den_o;
  drp_dwe_i <= drp_dwe_o;
  drp_daddr_i <= drp_daddr_o;
  drp_di_i <= drp_di_o;
  drp_drdy_i <= drp_drdy_o;
  drp_drpdo_i <= drp_drpdo_o;
  qplloutclk_out <= qplloutclk;
  qplloutrefclk_out <= qplloutrefclk;
  qplllock_out <= qplllock;
  txusrclk_out <= txusrclk;
  txusrclk2_out <= txusrclk2;
  areset_datapathclk_out     <= areset_coreclk;
  gttxreset_out          <= gttxreset;
  gtrxreset_out          <= gtrxreset;
  txuserrdy_out          <= txuserrdy;
  reset_counter_done_out <= reset_counter_done;

  -- Instantiate the 10GBASER/KR GT Common block

  ten_gig_eth_pcs_pma_gt_common_block : ten_gig_eth_pcs_pma_0_gt_common
  generic map
  (
     WRAPPER_SIM_GTRESET_SPEEDUP  =>  "TRUE"  --Does not affect hardware
  )
  port map
  (
     refclk         => refclk,
     qpllreset      => qpllreset,
     qplllock       => qplllock,
     qplloutclk     => qplloutclk,
     qplloutrefclk  => qplloutrefclk
  );


  -- Instantiate the 10GBASER/KR shared clock/reset block

  ten_gig_eth_pcs_pma_shared_clock_reset_block : ten_gig_eth_pcs_pma_0_shared_clock_and_reset
  port map
  (
     areset              => reset,
     refclk_p            => refclk_p,
     refclk_n            => refclk_n,
     refclk              => refclk,
     coreclk             => coreclk,
     dclk                => dclk_i, -- ymei
     txoutclk            => txoutclk,
     qplllock            => qplllock,
     areset_coreclk      => areset_coreclk,
     gttxreset           => gttxreset,
     gtrxreset           => gtrxreset,
     txuserrdy           => txuserrdy,
     txusrclk            => txusrclk,
     txusrclk2           => txusrclk2,
     qpllreset           => qpllreset,
     reset_counter_done  => reset_counter_done
  );

  -- Instantiate the 10GBASER/KR Block Level

  ten_gig_eth_pcs_pma_i : ten_gig_eth_pcs_pma_0
  port map
  (
     coreclk             => coreclk,
     dclk                => dclk_i, -- ymei
     txusrclk            => txusrclk,
     txusrclk2           => txusrclk2,
     txoutclk            => txoutclk,
     areset_coreclk      => areset_coreclk,
     txuserrdy           => txuserrdy,
     rxrecclk_out        => rxrecclk_out,
     areset              => reset,
     gttxreset           => gttxreset,
     gtrxreset           => gtrxreset,
     sim_speedup_control => sim_speedup_control,
     qplllock            => qplllock,
     qplloutclk          => qplloutclk,
     qplloutrefclk       => qplloutrefclk,
     reset_counter_done  => reset_counter_done,
     xgmii_txd           => xgmii_txd,
     xgmii_txc           => xgmii_txc,
     xgmii_rxd           => xgmii_rxd,
     xgmii_rxc           => xgmii_rxc,
     txp                 => txp,
     txn                 => txn,
     rxp                 => rxp,
     rxn                 => rxn,
     mdc                 => mdc,
     mdio_in             => mdio_in,
     mdio_out            => mdio_out,
     mdio_tri            => mdio_tri,
     prtad               => prtad,
     core_status         => core_status,
     tx_resetdone        => tx_resetdone_int,
     rx_resetdone        => rx_resetdone_int,
     signal_detect       => signal_detect,
     tx_fault            => tx_fault,
     drp_req             => drp_req,
     drp_gnt             => drp_gnt,
      drp_den_o           => drp_den_o,
      drp_dwe_o           => drp_dwe_o,
      drp_daddr_o         => drp_daddr_o,
      drp_di_o            => drp_di_o,
      drp_drdy_o          => drp_drdy_o,
      drp_drpdo_o         => drp_drpdo_o,
      drp_den_i           => drp_den_i,
      drp_dwe_i           => drp_dwe_i,
      drp_daddr_i         => drp_daddr_i,
      drp_di_i            => drp_di_i,
      drp_drdy_i          => drp_drdy_i,
      drp_drpdo_i         => drp_drpdo_i,
     pma_pmd_type        => pma_pmd_type,
     tx_disable          => tx_disable
   );

end wrapper;
