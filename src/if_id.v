// date: 2018.4.27
// author: Tiko.T

// file: if_id.v
// role: the flip-flop between stage IF & ID

`include "const.v"

module if_id (
    input wire                    clk      ,
    input wire                    rst      ,
    // from IF
    input wire  [`InstAddrBus]    if_pc    ,
    input wire  [`InstBus    ]    if_inst  ,
    // stall signal
    input wire  [`StallBus   ]    stall    ,
    // to ID
    output reg  [`InstAddrBus]    id_pc    ,
    output reg  [`InstBus    ]    id_inst  
);
    

    always @(posedge clk) begin
        if(rst == `RESET_ENABLE || (stall[1] == `STOP && stall[2] == `NOSTOP)) begin
            id_pc   <=  `ZERO_WORD;
            id_inst <=  `ZERO_WORD;
        end else if (stall[1] == `NOSTOP) begin
            id_pc   <= if_pc;
            id_inst <= if_inst;
        end
    end

endmodule
