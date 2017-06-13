/** \mainpage
@brief
KC705 1-gigabit ethernet (TCP) data acquisition with FMC112 module
\verbatim
-------------------------------------------------------------------------------
Generate the project after git clone:
Make sure there are following lines in config/project.tcl:
    # Create project
    create_project top ./
then 
    mkdir top; cd top/
    vivado -mode tcl -source ../config/project.tcl
# open GUI
    start_gui
# start synthesis
    launch_runs synth_1 -jobs 8
# start implementation
    launch_runs -jobs 8 impl_1 -to_step write_bitstream
# or do everything in tcl terminal
    open_project /path/to/example.xpr
    launch_runs -jobs 8 impl_1 -to_step write_bitstream
    wait_on_run impl_1
    exit
-------------------------------------------------------------------------------
Generating a PROM file (MCS):
In iMPACT, select BPI Flash Configure Single FPGA
Kintex7 128M, MCS, x16, no extra data
BPI PROM, 28F00AP30, 16 bit, RS Pins to 25:24 
Erase before programming

Mode switch: M2 M1 M0
0 0 1 Master SPI x1, x2, x4
0 1 0 Master BPI x8, x16
1 0 1 JTAG

In Vivado, use the Tcl command:
write_cfgmem -format MCS -size 128 -interface BPIx16 -loadbit "up 0x0 top/top.runs/impl_1/top.bit" target/FMC112IPv4Sel.mcs
Then in Hardware Manager, choose Micron density 1024Mb 28f00ap30t-bpi-x16
Pull-none, RS Pins 25:24
-------------------------------------------------------------------------------
gig_eth:

rgmii IDELAY_VALUE (.xdc) affects the 1gig ethernet reliability

With Vivado 2013.4 and 2014.4, values 10 and 30 both work, but 20 doesn't.
Value 10 seems to work the best.

RGMII_RXD[*] , RGMII_RX_CTL to RGMII_RXC

IDELAY_VALUE  | Total delay | Setup Slack
30              4 ns          -1.13 ns
10              2 ns           0.8  ns    <- did not violate timing constraints

When core is updated, compare to example design to update.
-------------------------------------------------------------------------------
MIG parameters:

Clock Period: 1250ps (800MHz)
SODIMM DDR3
Memory part: MT8JTF12864HZ-1G6
Data Mask: (check)
Ordering: Normal
Input Clock Period: 5000ps
Read Burst: sequential
Output Driver Impedance Control: RZQ/7
Controller Chip Select Pin: Enable
RTT RZQ/6
ROW-BANK-COLUMN order
System Clock   : no buffer
Reference Clock: no buffer
reset active high
50Ohm
DCI Cascade (check)

remember to git add ipcore_dir/mig_7series_0/mig_a.prj
and add the file in config/project.tcl
-------------------------------------------------------------------------------
In Vivado 2014.4, placing sophisticated PROCESS etc. in the top module doesn't
seem to work well.  Those logics get trimmed wildly.  Place them in modules
instead.
-------------------------------------------------------------------------------
ten_gig_eth:

When pcs_pma core is updated, open its example design and compare to
the source to update.  Updates in the source were marked with --ymei
\endverbatim
*/

