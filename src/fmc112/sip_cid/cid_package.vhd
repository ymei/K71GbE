--------------------------------------------------------------------------------
-- specify libraries.
--------------------------------------------------------------------------------

library  ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_1164.all;

--------------------------------------------------------------------------------
-- entity declaration
-------------------------------------------------------------------------------
package cid_package  is

type cid_register_type is array(natural range <>) of std_logic_vector(31 downto 0);

constant nb_cid_registers     :integer := 28;

constant cid_registers :cid_register_type(0 to nb_cid_registers-1):=(
-- REG0 : constellationid<<16|nbrstar
x"00E40008",
-- REG1 : software build code
x"532E3930",
-- REG2 : firmware build code
x"00000000",
-- REG3 : VersionHI<<8|VersionLO
x"00000001",
-- REG4..6 : star 'sip_cid' {BaseAddress, EndAddress, StarId<<16|StarVersion}
x"00002000",
x"000023FF",
x"00010100",
-- REG7..9 : star 'sip_mac_engine' {BaseAddress, EndAddress, StarId<<16|StarVersion}
x"00000000",
x"00000000",
x"00280100",
-- REG10..12 : star 'sip_i2c_master' {BaseAddress, EndAddress, StarId<<16|StarVersion}
x"00002400",
x"000123FF",
x"00050100",
-- REG13..15 : star 'sip_cmd12_mux' {BaseAddress, EndAddress, StarId<<16|StarVersion}
x"00000000",
x"00000000",
x"00180100",
-- REG16..18 : star 'sip_fmc_ct_gen' {BaseAddress, EndAddress, StarId<<16|StarVersion}
x"00012400",
x"00012401",
x"00430100",
-- REG19..21 : star 'sip_fmc112' {BaseAddress, EndAddress, StarId<<16|StarVersion}
x"00012402",
x"00013401",
x"00800100",
-- REG22..24 : star 'sip_router_s16d1' {BaseAddress, EndAddress, StarId<<16|StarVersion}
x"00013402",
x"00013403",
x"006D0100",
-- REG25..27 : star 'sip_fifo64k' {BaseAddress, EndAddress, StarId<<16|StarVersion}
x"00013404",
x"00013409",
x"003D0100"
);

end cid_package;

