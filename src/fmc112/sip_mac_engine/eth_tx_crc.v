`timescale  100 ps / 10 ps
//-------------------------------------
// ETH_TX_CRC.v
//-------------------------------------
// History of Changes:
//	02-07-2007 JAD: Wrapper created
//  02-08-2007 CJL: Code inserted
//  02-12-2007 JAD: tweaked, simulated at both 
//       100mb (in_cke 1/4 cycles) and 1000mb (in_cke = 1)
//  02-15-2007 JAD: Combined STB, FRM, and DAT signals into a single 10 bit ETH_STREAM signal. 
//-------------------------------------
// This is a module to add the CRC to an ethernet frame.
//-------------------------------------
// The ETH_STREAM signal actually includes three signals:
//   Bit 9: CKE: Clock enable sets data rate.  Lower bits are only valid if CKE.
//   Bit 8: FRM: Frame signal, asserted for entire ethernet frame.
//   Bits 7-0: DAT: Frame data, ignored if not FRM.
//-------------------------------------
// The input frame to this module is a complete ethernet frame 
//  including the frame check sequence, but the frame check sequence is
//  just a filler, which is overwritten by this module.
//-------------------------------------
module ETH_TX_CRC(
	CLK, 
	IN_ETH_STREAM, 
	OUT_ETH_STREAM
	);

// Master Clock
input			CLK;

// Input data stream
input	[9:0]	IN_ETH_STREAM;
wire			in_cke = IN_ETH_STREAM[9];
wire			in_frm = IN_ETH_STREAM[8];
wire	[7:0]	in_dat = IN_ETH_STREAM[7:0];

// Output data stream
output	[9:0]	OUT_ETH_STREAM;

// delay the data by four bytes to detect the end of the frame
reg 	[8:0]	dat_dly[4:1];
reg 	[4:1]	frm_dly = 0;
always @(posedge CLK) if (in_cke)
	begin
	dat_dly[1] <= in_dat;
	dat_dly[2] <= dat_dly[1];
	dat_dly[3] <= dat_dly[2];
	dat_dly[4] <= dat_dly[3];
	frm_dly <= {frm_dly[3:1], in_frm};
	end

// Run the checksum
wire	[7:0]	checksum;
wire	[31:0]	crc;
crc_32 crc_checksum (
    .clk(CLK), 
    .d(dat_dly[4]), // data input
    .init(!frm_dly[4]), // reset CRC
    .calc(in_frm),   // use d in calculation
    .d_valid(in_cke), // strobe byte
    .crc_reg(crc), 
    .crc(checksum), 
    .reset(1'b0) // async reset not used.
    );

//register outputs
reg 			out_frm = 0;
reg 	[7:0]	out_dat=0;
reg 			out_cke = 0;
wire	[9:0]	OUT_ETH_STREAM = {out_cke, out_frm, out_dat[7:0]};
always @(posedge CLK) 
	if (in_cke)
		begin
		out_frm <= frm_dly[4];
		out_dat <= in_frm ? dat_dly[4] : checksum;
		out_cke <= 1;
		end
	else 
		out_cke <= 0;

endmodule
