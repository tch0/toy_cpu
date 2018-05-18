// date: 2018.4.28
// author: Tiko.T

// file: ex_mem.v
// role: flip-flop between stage EX & MEM 

`include "const.v"

module ex_mem (
    input  wire                     clk         ,
    input  wire                     rst         ,

    // from EX
    input  wire                     ex_we       ,
    input  wire  [`RegAddrBus]      ex_waddr    ,
    input  wire  [`RegBus    ]      ex_wdata    ,
    input  wire                     ex_whilo    ,
    input  wire  [`RegBus    ]      ex_hi       ,
    input  wire  [`RegBus    ]      ex_lo       ,
    input  wire  [`AluOpBus  ]      ex_aluop    ,
    input  wire  [`RegBus    ]      ex_mem_addr ,
    input  wire  [`RegBus    ]      ex_opv2     ,

    // from ctrl
    input  wire  [`StallBus  ]      stall       ,

    // to MEM
    output  reg                     mem_we      ,
    output  reg  [`RegAddrBus]      mem_waddr   ,  
    output  reg  [`RegBus    ]      mem_wdata   ,
    output  reg                     mem_whilo   ,
    output  reg  [`RegBus    ]      mem_hi      ,
    output  reg  [`RegBus    ]      mem_lo      ,
    output  reg  [`AluOpBus  ]      mem_aluop   ,
    output  reg  [`RegBus    ]      mem_mem_addr,
    output  reg  [`RegBus    ]      mem_opv2     

);

    always @(posedge clk) begin
        if(rst == `RESET_ENABLE || (stall[3] == `STOP && stall[4] == `NOSTOP)) begin 
            mem_waddr  <=  `NOPRegAddr;
            mem_we     <=  `WRITE_DISABLE;
            mem_wdata  <=  `ZERO_WORD;
            mem_whilo  <=  `WRITE_DISABLE;
            mem_hi     <=  `ZERO_WORD;
            mem_lo     <=  `ZERO_WORD;
            mem_aluop     <=  0 ;            
            mem_mem_addr  <=  0 ;            
            mem_opv2      <=  0 ;
        end else if (stall[3] == `NOSTOP) begin 
            mem_waddr  <=  ex_waddr;
            mem_we     <=  ex_we;
            mem_wdata  <=  ex_wdata;
            mem_whilo  <=  ex_whilo; 
            mem_hi     <=  ex_hi;
            mem_lo     <=  ex_lo;
            mem_aluop    <=  ex_aluop   ;
            mem_mem_addr <=  ex_mem_addr;
            mem_opv2     <=  ex_opv2    ;
        end
    end

endmodule
