`timescale  1 ns / 100 ps
//-------------------------------------
// ETH_RX_CRC.v
//-------------------------------------
// History of Changes:
//	02-07-2007 JAD: Wrapper created
//	02-08-2007 CJL: Guts inserted
//  02-12-2007 JAD: tweaked, simulated at both 
//       100mb (in_cke 1/4 cycles) and 1000mb (in_cke = 1)
//  02-15-2007 JAD: Combined STB, FRM, and DAT signals into a single 10 bit ETH_STREAM signal. 
//-------------------------------------
// This is a module to test the CRC of an ethernet frame.
//-------------------------------------
// The ETH_STREAM signal actually includes three signals:
//   Bit 9: CKE: Clock enable sets data rate.  Lower bits are only valid if CKE.
//   Bit 8: FRM: Frame signal, asserted for entire ethernet frame.
//   Bits 7-0: DAT: Frame data, ignored if not FRM.
//-------------------------------------
// OUT_START_STB asserts before out_frm goes high to 
//  indicate the start of an ethernet frame
// OUT_DAT_STB asserts during bytes within a FRM
// OUT_OK_STB and OUT_BAD_STB are strobes asserted after out_frm drops,
//  to indicate if the CRC was correct or not.
// These strobes can replace the use of out_frm.
//-------------------------------------
module ETH_RX_CRC(
	CLK, 
	IN_ETH_STREAM, 
	OUT_ETH_STREAM, 
	OUT_START_STB, OUT_DAT, OUT_DAT_STB, OUT_OK_STB, OUT_BAD_STB
	);

// Master Clock
input			CLK;

// Input data stream
input	[9:0]	IN_ETH_STREAM;
wire			in_cke = IN_ETH_STREAM[9];
wire			in_frm = IN_ETH_STREAM[8];
wire	[7:0]	in_dat = IN_ETH_STREAM[7:0];

// Output data stream - delayed to match CRC calculation latency?
output	[9:0]	OUT_ETH_STREAM;

// Simplified output
output			OUT_START_STB; // frame starting
output	[7:0]	OUT_DAT;     // Output data
output			OUT_DAT_STB; // out_dat in frame
output			OUT_OK_STB;  // CRC was correct
output			OUT_BAD_STB; // CRC was incorrect

// Previous in_frm
reg				in_frm_prev = 0;
always @(posedge CLK) if (in_cke) in_frm_prev <= in_frm;

// CRC calculation----------------------------------------------------
parameter	[31:0]		magic_number=32'hc704dd7b;  // magic number
wire		[31:0]		crc_reg;  //accumulative crc reg
wire					crc_ok = (crc_reg == magic_number);
crc_32 crc_checksum (
    .clk(CLK), 
    .init(!in_frm && !in_frm_prev), 
    .calc(1'b1), 
    .d_valid(in_cke), 
    .d(in_dat), 
    .crc_reg(crc_reg), 
    .crc(), 
    .reset(1'b0)
    );
 
//register output
reg 			out_frm = 0, out_cke = 0;
reg 	[7:0]	OUT_DAT;
wire	[9:0]	OUT_ETH_STREAM = {out_cke, out_frm, OUT_DAT[7:0]};
always @(posedge CLK)
	begin
	out_cke <= in_cke;
	out_frm <= in_frm;
	OUT_DAT <= in_dat;
	end



// generate special strobes
wire			OUT_START_STB = in_cke && in_frm && !in_frm_prev;
reg 			OUT_DAT_STB =0;
reg 			OUT_OK_STB  =0;
reg 			OUT_BAD_STB =0;
always @(posedge CLK)
	begin
	OUT_DAT_STB   <= in_cke &&  in_frm;
	OUT_OK_STB    <= in_cke && !in_frm &&  in_frm_prev &&  crc_ok;
	OUT_BAD_STB   <= in_cke && !in_frm &&  in_frm_prev && !crc_ok;			
	end


endmodule
