// date: 2018.4.28
// author: Tiko.T

// file: mem.v
// role: access data memory (the RAM) in this stage
// note: only load & store isntruction will access data memory


`include "const.v"

module mem (
	input  wire                     rst        ,

	// from EX
	input  wire                     we_i       ,
	input  wire  [`RegAddrBus]      waddr_i    ,
	input  wire  [`RegBus    ]      wdata_i    ,
	input  wire                     whilo_i    ,
	input  wire  [`RegBus    ]      hi_i       ,
	input  wire  [`RegBus    ]      lo_i       ,
	input  wire  [`AluOpBus  ]      aluop_i    ,
	input  wire  [`RegBus    ]      mem_addr_i ,
	input  wire  [`RegBus    ]      opv2_i     ,

	// from data RAM
	input  wire  [`RegBus    ]      mem_data_i ,

	// from LLbit_reg
	input  wire                     LLbit_i          ,
	input  wire                     wb_LLbit_we_i    ,
	input  wire                     wb_LLbit_value_i ,

	// to data RAM
	output  reg                     mem_ce_o   ,      // chip enable
	output  reg                     mem_we_o   ,      // write to memory ot not
	output  reg  [3:0        ]      mem_sel_o  ,      // select byte
	output  reg  [`RegBus    ]      mem_addr_o ,
	output  reg  [`RegBus    ]      mem_data_o ,

	// to WB
	output  reg                     we_o       ,
	output  reg  [`RegAddrBus]      waddr_o    ,
	output  reg  [`RegBus    ]      wdata_o    ,
	output  reg                     whilo_o    ,
	output  reg  [`RegBus    ]      hi_o       ,
	output  reg  [`RegBus    ]      lo_o       ,
	output  reg                     LLbit_we_o    ,
	output  reg                     LLbit_value_o
);

	reg LLbit;

	`define SET_MEM(i_wdata, i_mem_we, i_mem_sel, i_mem_addr, i_mem_data, i_mem_ce) if(1) begin \
		wdata_o     <= i_wdata    ; \
		mem_we_o    <= i_mem_we   ; \
		mem_sel_o   <= i_mem_sel  ; \
		mem_addr_o  <= i_mem_addr ; \
		mem_data_o  <= i_mem_data ; \
		mem_ce_o    <= i_mem_ce   ; \
	end else if(0)

	always @(*) begin
		if(rst == `RESET_ENABLE) begin 
			waddr_o       <=  `NOPRegAddr;
			we_o          <=  `WRITE_DISABLE;
			wdata_o       <=  `ZERO_WORD;
			whilo_o       <=  `WRITE_DISABLE;
			hi_o          <=  `ZERO_WORD;
			lo_o          <=  `ZERO_WORD;
			LLbit_we_o    <=  1'b0;
			LLbit_value_o <=  1'b0;
			`SET_MEM(0, 0, 0, 0, 0, 0);
		end else begin 
			waddr_o       <=  waddr_i;
			we_o          <=  we_i;
			wdata_o       <=  wdata_i;
			whilo_o       <=  whilo_i;
			hi_o          <=  hi_i;    
			lo_o          <=  lo_i;
			LLbit_we_o    <=  1'b0;
			LLbit_value_o <=  1'b0;
			`SET_MEM(wdata_i, 0, 0, 0, 0, 0);
			case (aluop_i)
				// load instruction
				`EXE_LB_OP  : case (mem_addr_i[1:0]) // load which byte in a word
					2'b00 : `SET_MEM(({{24{mem_data_i[31]}},mem_data_i[31:24]}), 0, 4'b1000, mem_addr_i, 0, 1);
					2'b01 : `SET_MEM(({{24{mem_data_i[23]}},mem_data_i[23:16]}), 0, 4'b0100, mem_addr_i, 0, 1);
					2'b10 : `SET_MEM(({{24{mem_data_i[15]}},mem_data_i[15: 8]}), 0, 4'b0010, mem_addr_i, 0, 1);
					2'b11 : `SET_MEM(({{24{mem_data_i[ 7]}},mem_data_i[ 7: 0]}), 0, 4'b0001, mem_addr_i, 0, 1);
				endcase
				`EXE_LBU_OP : case (mem_addr_i[1:0])
					2'b00 : `SET_MEM(({{24{1'b0}},mem_data_i[31:24]}), 0, 4'b1000, mem_addr_i, 0, 1);
					2'b01 : `SET_MEM(({{24{1'b0}},mem_data_i[23:16]}), 0, 4'b0100, mem_addr_i, 0, 1);
					2'b10 : `SET_MEM(({{24{1'b0}},mem_data_i[15: 8]}), 0, 4'b0010, mem_addr_i, 0, 1);
					2'b11 : `SET_MEM(({{24{1'b0}},mem_data_i[ 7: 0]}), 0, 4'b0001, mem_addr_i, 0, 1);
				endcase
				`EXE_LH_OP  : case (mem_addr_i[1:0])
					2'b00 : `SET_MEM(({{16{mem_data_i[31]}},mem_data_i[31:16]}), 0, 4'b1100, mem_addr_i, 0, 1);
					2'b10 : `SET_MEM(({{16{mem_data_i[31]}},mem_data_i[15: 0]}), 0, 4'b0011, mem_addr_i, 0, 1);
				endcase
				`EXE_LHU_OP : case (mem_addr_i[1:0])
					2'b00 : `SET_MEM(({{16{1'b0}},mem_data_i[31:16]}), 0, 4'b1100, mem_addr_i, 0, 1);
					2'b10 : `SET_MEM(({{16{1'b0}},mem_data_i[15: 0]}), 0, 4'b0011, mem_addr_i, 0, 1);
				endcase
				`EXE_LW_OP  : `SET_MEM(mem_data_i, 0, 4'b1111, mem_addr_i, 0, 1);
				`EXE_LWL_OP : case (mem_addr_i[1:0])
					2'b00 : `SET_MEM(( mem_data_i[31: 0]               ), 0, 4'b1111, ({mem_addr_i[31:2],2'b00}), 0, 1);
					2'b01 : `SET_MEM(({mem_data_i[23: 0], opv2_i[7 :0]}), 0, 4'b1111, ({mem_addr_i[31:2],2'b00}), 0, 1);
					2'b10 : `SET_MEM(({mem_data_i[15: 0], opv2_i[15:0]}), 0, 4'b1111, ({mem_addr_i[31:2],2'b00}), 0, 1);
					2'b11 : `SET_MEM(({mem_data_i[7 : 0], opv2_i[23:0]}), 0, 4'b1111, ({mem_addr_i[31:2],2'b00}), 0, 1);
				endcase
				`EXE_LWR_OP : case (mem_addr_i[1:0])
					2'b00 : `SET_MEM(({opv2_i[31: 8], mem_data_i[31:24]}), 0, 4'b1111, ({mem_addr_i[31:2],2'b00}), 0, 1);
					2'b01 : `SET_MEM(({opv2_i[31:16], mem_data_i[31:16]}), 0, 4'b1111, ({mem_addr_i[31:2],2'b00}), 0, 1);
					2'b10 : `SET_MEM(({opv2_i[31:24], mem_data_i[31: 8]}), 0, 4'b1111, ({mem_addr_i[31:2],2'b00}), 0, 1);
					2'b11 : `SET_MEM((                mem_data_i[31: 0] ), 0, 4'b1111, ({mem_addr_i[31:2],2'b00}), 0, 1);
				endcase
				// store instruction
				`EXE_SB_OP  : case (mem_addr_i[1:0])
					2'b00 : `SET_MEM(0, 1, 4'b1000, mem_addr_i, ({opv2_i[7:0],opv2_i[7:0],opv2_i[7:0],opv2_i[7:0]}), 1);
					2'b01 : `SET_MEM(0, 1, 4'b0100, mem_addr_i, ({opv2_i[7:0],opv2_i[7:0],opv2_i[7:0],opv2_i[7:0]}), 1);
					2'b10 : `SET_MEM(0, 1, 4'b0010, mem_addr_i, ({opv2_i[7:0],opv2_i[7:0],opv2_i[7:0],opv2_i[7:0]}), 1);
					2'b11 : `SET_MEM(0, 1, 4'b0001, mem_addr_i, ({opv2_i[7:0],opv2_i[7:0],opv2_i[7:0],opv2_i[7:0]}), 1);
				endcase
				`EXE_SH_OP  : case (mem_addr_i[1:0])
					2'b00 : `SET_MEM(0, 1, 4'b1100, mem_addr_i, ({opv2_i[15:0],opv2_i[15:0]}), 1);
					2'b10 : `SET_MEM(0, 1, 4'b0011, mem_addr_i, ({opv2_i[15:0],opv2_i[15:0]}), 1);
				endcase
				`EXE_SW_OP  : `SET_MEM(0, 1, 4'b1111, mem_addr_i, opv2_i, 1);
				`EXE_SWL_OP : case (mem_addr_i[1:0])
					2'b00 : `SET_MEM(0, 1, 4'b1111, ({mem_addr_i[31:2], 2'b00}), (opv2_i               ), 1);
					2'b01 : `SET_MEM(0, 1, 4'b0111, ({mem_addr_i[31:2], 2'b00}), ({8'b0 ,opv2_i[31: 8]}), 1);
					2'b10 : `SET_MEM(0, 1, 4'b0011, ({mem_addr_i[31:2], 2'b00}), ({16'b0,opv2_i[31:16]}), 1);
					2'b11 : `SET_MEM(0, 1, 4'b0001, ({mem_addr_i[31:2], 2'b00}), ({24'b0,opv2_i[31:24]}), 1);
				endcase
				`EXE_SWR_OP : case (mem_addr_i[1:0])
					2'b00 : `SET_MEM(0, 1, 4'b1000, ({mem_addr_i[31:2], 2'b00}), ({opv2_i[ 7: 0],24'b0}), 1);
					2'b01 : `SET_MEM(0, 1, 4'b1100, ({mem_addr_i[31:2], 2'b00}), ({opv2_i[15: 0],16'b0}), 1);
					2'b10 : `SET_MEM(0, 1, 4'b1110, ({mem_addr_i[31:2], 2'b00}), ({opv2_i[23: 0], 8'b0}), 1);
					2'b11 : `SET_MEM(0, 1, 4'b1111, ({mem_addr_i[31:2], 2'b00}), ( opv2_i              ), 1);
				endcase
				`EXE_LL_OP  : begin 
					`SET_MEM(mem_data_i, 0, 4'b1111, mem_addr_i, 0, 1);
					LLbit_we_o    <= 1'b1;
					LLbit_value_o <= 1'b1;
				end
				`EXE_SC_OP  : if(LLbit == 1'b1) begin 
					`SET_MEM(1, 1, 4'b1111, mem_addr_i, opv2_i, 1);
					LLbit_we_o    <= 1'b1;
					LLbit_value_o <= 1'b0;
				end
			endcase // aluop_i
		end
	end

	always @(*) begin
		if(rst == `RESET_ENABLE) begin 
			LLbit <= 1'b0;
		end else if(wb_LLbit_we_i == 1'b1) begin 
			LLbit <= wb_LLbit_value_i;
		end else begin 
			LLbit <= LLbit_i;
		end
	end

	`undef SET_MEM

endmodule