------------------------------------------------------------------------
-- title   : package for the 10 gig ethernet mac fifo reference design
-- project : 10 gig ethernet mac fifo reference design
------------------------------------------------------------------------
-- file    : xgmac_fifo_pack.vhd
-- author  : xilinx inc.
------------------------------------------------------------------------
-- description : this module is the package used by the 10-gigabit
-- ethernet mac fifo interface. 
--
------------------------------------------------------------------------
-- (c) Copyright 2001-2008 Xilinx, Inc. All rights reserved.
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


library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package xgmac_fifo_pack is

   ---------------------------------------------------------------------
   -- purpose: define function to convert fifo word size into an address
   -- width
   -- type   : function
   ---------------------------------------------------------------------
   function log2 (
      value : integer)
      return integer;

   ---------------------------------------------------------------------
   -- purpose : converts gray code to binary code
   -- type    : function
   ---------------------------------------------------------------------
   function gray_to_bin (
      gray : std_logic_vector)
      return std_logic_vector;

   ---------------------------------------------------------------------
   -- purpose : converts binary to gray code (by calling gray_to_bin)
   ---------------------------------------------------------------------
   function bin_to_gray (
      bin : std_logic_vector)
      return std_logic_vector;

end xgmac_fifo_pack;

package body xgmac_fifo_pack is

   ---------------------------------------------------------------------
   -- purpose: define function to convert fifo word size into an address
   -- width
   -- type   : function
   ---------------------------------------------------------------------
   function log2 (value : integer) return integer is
      variable ret_val : integer;
   begin
      ret_val := 0;

      if value <= 2**ret_val then
         ret_val := 0;
      else
         while 2**ret_val < value loop
            ret_val := ret_val + 1;
         end loop;
      end if;

      return ret_val;
      
   end log2;


   function gray_to_bin (
      gray : std_logic_vector)
      return std_logic_vector is

      variable binary : std_logic_vector(gray'range);
      
   begin

      for i in gray'high downto gray'low loop
         if i = gray'high then
            binary(i) := gray(i);
         else
            binary(i) := binary(i+1) xor gray(i);
         end if;
      end loop;  -- i

      return binary;
      
   end gray_to_bin;

   function bin_to_gray (
      bin : std_logic_vector)
      return std_logic_vector is

      variable gray : std_logic_vector(bin'range);
      
   begin

      for i in bin'range loop
         if i = bin'left then
            gray(i) := bin(i);
         else
            gray(i) := bin(i+1) xor bin(i);
         end if;
      end loop;  -- i

      return gray;

   end bin_to_gray;

end xgmac_fifo_pack;

