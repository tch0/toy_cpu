// date: 2018.4.27
// author: Tiko.T

// file: regfile.v
// role: definitoin of 32 generic registers
// note: two read ports, one write port.
//       reading register is sequential logic circuit.
//       writing register is combinational logic circuit.
//       $0 aka $zero is constant 0.


`include "const.v"

module regfile (
	input  wire                   clk      ,
	input  wire 	              rst      ,
	// write port
	input  wire                   we       ,
	input  wire  [`RegAddrBus]    waddr    ,
	input  wire  [`RegBus    ]    wdata    ,
	// read port1
	input  wire                   re1      ,
	input  wire  [`RegAddrBus]	  raddr1   ,
	output  reg  [`RegBus    ]    rdata1   ,
	// read port2
	input  wire                   re2      ,
	input  wire  [`RegAddrBus]	  raddr2   ,
	output  reg  [`RegBus    ]    rdata2    
);
	
	//definitoin of 32 generic registers
	reg  [`RegBus]  regs[0:`RegNum-1];

	//write operation
	always @(posedge clk) begin
		if(rst == `RESET_DISABLE) begin 
			if((we == `READ_ENABLE) && (waddr != `RegNumLog2'h0)) begin
				regs[waddr] <= wdata;
			end
		end
	end

	//read port 1 operation
	always @(*) begin
		if(rst == `RESET_ENABLE) begin
			rdata1 <= `ZERO_WORD;
		end else if(raddr1 == `RegNumLog2'h0) begin 
			rdata1 <= `ZERO_WORD;
		end else if((raddr1 == waddr) && (we == `WRITE_ENABLE) && (re1 == `READ_ENABLE)) begin
			rdata1 <= wdata;          // handle data-dependant hazard about instruction away from two inst
		end else if(re1 == `READ_ENABLE) begin 
			rdata1 <= regs[raddr1];   // read data
		end else begin
			rdata1 <= `ZERO_WORD;
		end
	end

	//read port 2 operation
	always @(*) begin
		if(rst == `RESET_ENABLE) begin 
			rdata2 <= `ZERO_WORD;
		end else if(raddr2 == `RegNumLog2'h0) begin 
			rdata2 <= `ZERO_WORD;
		end else if((raddr2 == waddr) && (we == `WRITE_ENABLE) && (re2 == `READ_ENABLE)) begin
			rdata2 <= wdata;
		end else if(re2 == `READ_ENABLE) begin 
			rdata2 <= regs[raddr2];
		end else begin
			rdata2 <= `ZERO_WORD;
		end
	end

endmodule