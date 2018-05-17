// date: 2018.5.15
// author: Tiko.T

// file: data_ram.v
// role: the data random access memory, stores data
// note1: use big end mode
// note2: In order to the convenience of Byte Addressing,
//        We use four memories with 8 bits to replace a memory with 32 bits.
// note3: The design of sel signal is excellent.


`include "const.v"

module data_ram (
    input  wire                    clk    ,
    input  wire                    ce     ,      // chip enable
    input  wire                    we     ,      // 1 -> write   0 -> read
    input  wire  [ 3:0        ]    sel    ,
    input  wire  [`DataAddrBus]    addr   ,
    input  wire  [`DataBus    ]    data_i ,
    output  reg  [`DataBus    ]    data_o  
);
    
    // four 8 bits memory replace 32 bits memory
    reg  [`ByteWidth]    bank0 [0:`DataMemNum-1];
    reg  [`ByteWidth]    bank1 [0:`DataMemNum-1];
    reg  [`ByteWidth]    bank2 [0:`DataMemNum-1];
    reg  [`ByteWidth]    bank3 [0:`DataMemNum-1];

    // make the input address align by words
    wire [`DataMemNumLog2-1:0]  saddr = addr[`DataMemNumLog2+1:2];

    // store data
    always @(posedge clk) begin
        if(ce == `CHIP_ENABLE && we === `WRITE_ENABLE) begin
            if(sel[3] == 1'b1)  bank3[saddr] <= data_i[31:24];
            if(sel[2] == 1'b1)  bank2[saddr] <= data_i[23:16];
            if(sel[1] == 1'b1)  bank1[saddr] <= data_i[15: 8];
            if(sel[0] == 1'b1)  bank0[saddr] <= data_i[ 7: 0];
        end
    end
    
    // load data
    always @(*) begin
        if(ce == `CHIP_DISABLE)         data_o <= `ZERO_WORD;
        else if(we == `WRITE_DISABLE)   data_o <= {bank3[saddr], bank2[saddr], bank1[saddr], bank0[saddr]};
        else                            data_o <= `ZERO_WORD;
    end

endmodule