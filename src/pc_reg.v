// date: 2018.4.27
// author: Tiko.T

// file: pc_reg.v
// role: generation of signal PC (program counter)
// note: It will take at most tow clock cycles to get isntructions run from disable to enable of reset.


`include "const.v"

module pc_reg (
	input wire                    clk            ,
	input wire                    rst            ,
	input wire  [`StallBus   ]    stall          ,
	input wire                    branch_flag_i  ,
	input wire  [`RegBus     ]    branch_addr_i  ,
	output reg  [`InstAddrBus]    pc             ,
	output reg                    ce                // chip enable to inst_rom
);

	always @(posedge clk) begin
		if(rst == `RESET_ENABLE) begin 
			ce <= `CHIP_DISABLE;
		end else begin 
			ce <= `CHIP_ENABLE;
		end
	end

	always @(posedge clk) begin
		if(ce == `CHIP_DISABLE) begin
			pc <= 0;
		end else if (stall[0] == `NOSTOP) begin           // the pipeline do not stop
				if(branch_flag_i == `BRANCH)              // branch
					pc <= branch_addr_i;
				else pc <= pc + 4;
		end
	end
endmodule