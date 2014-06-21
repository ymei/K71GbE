KC705 1-gigabit ethernet (TCP) data acquisition from FMC112 module

Generating a PROM file (MCS):
In iMPACT, select BPI Flash Configure Single FPGA
Kintex7 128M, MCS, x16, no extra data
BPI PROM, 28F00AP30, 16 bit, RS Pins to 25:24 
Erase before programming

Mode switch: M2 M1 M0
0 0 1 Master SPI x1, x2, x4
0 1 0 Master BPI x8, x16
1 0 1 JTAG
