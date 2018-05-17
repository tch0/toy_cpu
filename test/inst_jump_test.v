`timescale 1ns/1ps
`include "../test/assert.v"

module inst_jump_test();
    reg     clk, rst;
    integer i  ;

    open_mips_min_sopc open_mips_min_sopc0 (clk,rst);

    always #1 clk = ~clk;
    initial begin
        $dumpfile("../test/inst_jump_test.vcd");
        $dumpvars;
        $dumpvars(0, open_mips_min_sopc0.openmips0.regfile1.regs[1]);
        $dumpvars(0, open_mips_min_sopc0.openmips0.regfile1.regs[2]);
        $dumpvars(0, open_mips_min_sopc0.openmips0.regfile1.regs[31]);

        $readmemh("../data/inst_jump_test.txt", open_mips_min_sopc0.inst_rom0.inst_mem, 0, 34);

        clk = 0;
        rst = 1;
        #20 rst = 0;
        #12 `AR(1,32'h00000001);`AR(31,32'hxxxxxxxx);`AHI(32'h00000000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000001);`AR(31,32'hxxxxxxxx);`AHI(32'h00000000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000002);`AR(31,32'hxxxxxxxx);`AHI(32'h00000000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000003);`AR(31,32'hxxxxxxxx);`AHI(32'h00000000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000003);`AR(31,32'h0000002C);`AHI(32'h00000000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000003);`AR(31,32'h0000002C);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000003);`AR(31,32'h0000002C);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000048);`AR(31,32'h0000002C);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000005);`AR(31,32'h0000002C);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000006);`AR(31,32'h0000002C);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000006);`AR(31,32'h0000002C);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000006);`AR(31,32'h0000002C);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000007);`AR(31,32'h0000002C);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000007);`AR(31,32'h0000002C);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000008);`AR(31,32'h0000002C);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000009);`AR(31,32'h0000002C);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h0000000A);`AR(31,32'h0000002C);`AHI(32'h00000002);`ALO(32'h0000000E);
        `PASS(jump isntruction test);
    end

endmodule