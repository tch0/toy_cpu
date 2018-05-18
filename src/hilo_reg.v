// date: 2018.5.4
// author: Tiko.T

// file: hilo_reg.v
// role: the reg HI & LO


`include "const.v"

module hilo_reg (
    input  wire                 clk  ,
    input  wire                 rst  ,
    input  wire                 we   ,
    input  wire  [`RegBus]      hi_i ,
    input  wire  [`RegBus]      lo_i ,
    output  reg  [`RegBus]      hi_o ,
    output  reg  [`RegBus]      lo_o  
);

    always @(posedge clk) begin
        if(rst == `RESET_ENABLE) begin
            hi_o <= 0;
            lo_o <= 0;
        end else if(we == `WRITE_ENABLE) begin
            hi_o <= hi_i;
            lo_o <= lo_i;
        end
    end
endmodule // hilo_reg
