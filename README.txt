KC705 1-gigabit ethernet (TCP) data acquisition from FMC112 module

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
-------------------------------------------------------------------------------
rgmii IDELAY_VALUE (.xdc) affects the 1gig ethernet reliability

With Vivado 2013.4 and 2014.4, values 10 and 30 both work, but 20 doesn't.
Value 10 seems to work the best.

RGMII_RXD[*] , RGMII_RX_CTL to RGMII_RXC

IDELAY_VALUE  | Total delay | Setup Slack
30              4 ns          -1.13 ns
10              2 ns           0.8  ns    <- did not violate timing constraints
-------------------------------------------------------------------------------
MIG parameters:

Clock Period: 1250ps
SODIMM DDR3
Memory part: MT8JTF12864HZ-1G6
ROW-BANK-COLUMN order
RTT RZQ/6
Input Clock Period: 5000ps
System Clock   : no buffer
Reference Clock: no buffer
50Ohm
DCI Cascade (check)
reset active high
-------------------------------------------------------------------------------
In Vivado 2014.4, placing sophisticated PROCESS etc. in the top module doesn't
seem to work well.  Those logics get trimmed wildly.  Place them in modules
instead.

