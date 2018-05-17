// date: 2018.4.27
// author: Tiko.T

// file: id_ex.v
// role: flip-flop between stage ID & EX


`include "const.v"

module id_ex (
	input  wire                     clk        ,
	input  wire                     rst        ,

	// from ID
	input  wire  [`AluOpBus  ]      id_aluop   ,
	input  wire  [`AluSelBus ]      id_alusel  ,
	input  wire  [`RegBus    ]      id_reg1    ,
	input  wire  [`RegBus    ]      id_reg2    ,
	input  wire  [`RegAddrBus]      id_waddr   ,
	input  wire                     id_we      ,
	input  wire  [`InstBus   ]      id_inst    ,
	// from ctrl
	input  wire  [`StallBus  ]      stall      ,
	// to EX
	output  reg  [`AluOpBus  ]      ex_aluop   ,
	output  reg  [`AluSelBus ]      ex_alusel  ,
	output  reg  [`RegBus    ]      ex_reg1    ,
	output  reg  [`RegBus    ]      ex_reg2    ,
	output  reg  [`RegAddrBus]      ex_waddr   ,
	output  reg                     ex_we      ,
	output  reg  [`InstBus   ]      ex_inst    ,

	// signals about branch
	input  wire                     id_cur_in_delay_slot  ,
	input  wire  [`RegBus    ]      id_link_addr          ,
	input  wire                     next_in_delay_slot_i  ,
	output  reg                     ex_cur_in_delay_slot  ,
	output  reg  [`RegBus    ]      ex_link_addr          ,
	output  reg                     next_in_delay_slot_o     // not to ex, this signal should back to id, remember !!!

);


	always @(posedge clk) begin
		if(rst == `RESET_ENABLE || (stall[2] == `STOP && stall[3] == `NOSTOP)) begin
			ex_aluop    <=  `EXE_NOP_OP;
			ex_alusel   <=  `EXE_RES_NOP;
			ex_reg1     <=  `ZERO_WORD;
			ex_reg2     <=  `ZERO_WORD;
			ex_waddr    <=  `NOPRegAddr;
			ex_we       <=  `WRITE_DISABLE;
			ex_cur_in_delay_slot  <= 0;
			ex_link_addr          <= 0;
			next_in_delay_slot_o  <= 0;
			ex_inst               <= 0;
		end else if (stall[2] == `NOSTOP) begin
			ex_aluop    <=  id_aluop  ;
			ex_alusel   <=  id_alusel ;
			ex_reg1     <=  id_reg1   ;
			ex_reg2     <=  id_reg2   ;
			ex_waddr    <=  id_waddr  ;
			ex_we       <=  id_we     ;
			ex_cur_in_delay_slot  <= id_cur_in_delay_slot  ;
			ex_link_addr          <= id_link_addr          ;
			next_in_delay_slot_o  <= next_in_delay_slot_i  ;
			ex_inst               <= id_inst               ;

		end
	end
      
endmodule