// date: 2018.4.28
// author: Tiko.T

// file: inst_rom.v
// role: instruction memory


`include "const.v"

module inst_rom (
	input  wire                    ce    ,
	input  wire  [`InstAddrBus]    addr  ,    // the address of instruction
	output  reg  [`InstBus    ]    inst   
);

	// instruction memory
	reg  [`InstBus]      inst_mem[0:`InstMemNum-1];

	always @(*) begin
		if(ce == `CHIP_DISABLE) begin
			inst  <=  0;
		end else begin
			inst  <=  inst_mem[addr[`InstMemNumLog2+1:2]];
		end
	end
endmodule