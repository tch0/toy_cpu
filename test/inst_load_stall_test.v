`timescale 1ns/1ps
`include "../test/assert.v"

module inst_load_stall_test();
    reg     clk, rst;
    integer i  ;

    open_mips_min_sopc open_mips_min_sopc0 (clk,rst);

    always #1 clk = ~clk;
    wire [31:0] mem0x0000 = {open_mips_min_sopc0.data_ram0.bank3[0], open_mips_min_sopc0.data_ram0.bank2[0], open_mips_min_sopc0.data_ram0.bank1[0], open_mips_min_sopc0.data_ram0.bank0[0]};
    wire [31:0] mem0x0004 = {open_mips_min_sopc0.data_ram0.bank3[1], open_mips_min_sopc0.data_ram0.bank2[1], open_mips_min_sopc0.data_ram0.bank1[1], open_mips_min_sopc0.data_ram0.bank0[1]};
    wire [31:0] mem0x0008 = {open_mips_min_sopc0.data_ram0.bank3[2], open_mips_min_sopc0.data_ram0.bank2[2], open_mips_min_sopc0.data_ram0.bank1[2], open_mips_min_sopc0.data_ram0.bank0[2]};
    initial begin
        $dumpfile("../test/inst_load_stall_test.vcd");
        $dumpvars;
        $dumpvars(0, open_mips_min_sopc0.openmips0.regfile1.regs[1]);
        $dumpvars(0, open_mips_min_sopc0.openmips0.regfile1.regs[3]);

        $readmemh("../data/inst_load_stall_test.txt", open_mips_min_sopc0.inst_rom0.inst_mem, 0, 12);

        clk = 0;
        rst = 1;
        #20 rst = 0;
        #12 `AR(1,32'h00001234);
        #2  `AR(1,32'h00001234);
        #2  `AR(1,32'h00001234);
        #2  `AR(1,32'h00000000);
        #2  `AR(1,32'h00001234);
        #2  `AR(1,32'h00001234);
        #2  `AR(1,32'h00001234);
        #2  `AR(1,32'h00001234);
        #2  `AR(1,32'h000089AB);
        #20 `PASS(load stall test);
    end

endmodule