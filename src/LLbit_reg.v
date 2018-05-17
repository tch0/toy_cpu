// date: 2018.5.16
// author: Tiko.T

// file: LLbit_reg.v
// role: save semaphore of instruction ll & sc
// note: if you want to implement a multi-processor, then there should be a register LLAddr to save the loaded address


`include "const.v"

module LLbit_reg (
    input  wire      clk     ,
    input  wire      rst     ,
    input  wire      flush   ,  // 1 -> exception  0 -> no exception
    input  wire      LLbit_i ,
    input  wire      we      ,  // 1 -> write   0 -> read
    output  reg      LLbit_o  
);
    
    always @(posedge clk) begin
        if(rst == `RESET_ENABLE || flush == 1'b1) begin
            LLbit_o <= 1'b0;
        end else if (we == `WRITE_ENABLE) begin 
            LLbit_o <= LLbit_i;
        end
    end

endmodule