// date: 2018.4.28
// author: Tiko.T

// file: mem_wb.v
// role: flip-flop between stage MEM & WB
// note: there is not a module named wb, just write result back to regfile


`include "const.v"

module mem_wb (
	input  wire                     clk        ,
	input  wire                     rst        ,

	// from MEM
	input  wire                     mem_we          ,
	input  wire  [`RegAddrBus]      mem_waddr       ,
	input  wire  [`RegBus    ]      mem_wdata       ,
	input  wire                     mem_whilo       ,
	input  wire  [`RegBus    ]      mem_hi          ,
	input  wire  [`RegBus    ]      mem_lo          ,
	input  wire                     mem_LLbit_we    ,
	input  wire                     mem_LLbit_value ,

	// from ctrl
	input  wire  [`StallBus  ]      stall           ,

	// to WB
	output  reg                     wb_we           ,
	output  reg  [`RegAddrBus]      wb_waddr        ,
	output  reg  [`RegBus    ]      wb_wdata        ,
	output  reg                     wb_whilo        ,
	output  reg  [`RegBus    ]      wb_hi           ,
	output  reg  [`RegBus    ]      wb_lo           ,
	output  reg                     wb_LLbit_we     ,
	output  reg                     wb_LLbit_value   
);

	always @(posedge clk) begin 
		if(rst == `RESET_ENABLE || (stall[4] == `STOP && stall[5] == `NOSTOP)) begin 
			wb_waddr       <=  `NOPRegAddr;
			wb_we          <=  `WRITE_DISABLE;
			wb_wdata       <=  `ZERO_WORD;
			wb_whilo       <=  `WRITE_DISABLE;
			wb_hi          <=  `ZERO_WORD;
			wb_lo          <=  `ZERO_WORD;
			wb_LLbit_we    <=  1'b0;
			wb_LLbit_value <=  1'b0;
		end else if (stall[4] == `NOSTOP) begin 
			wb_waddr       <=  mem_waddr;
			wb_we          <=  mem_we;
			wb_wdata       <=  mem_wdata;
			wb_whilo       <=  mem_whilo;
			wb_hi          <=  mem_hi;
			wb_lo          <=  mem_lo;
			wb_LLbit_we    <=  mem_LLbit_we;
			wb_LLbit_value <=  mem_LLbit_value;
		end
	end

endmodule