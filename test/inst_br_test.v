`timescale 1ns/1ps
`include "../test/assert.v"

module inst_br_test();
    reg     clk, rst;
    integer i  ;

    open_mips_min_sopc open_mips_min_sopc0 (clk,rst);

    always #1 clk = ~clk;
    initial begin
        $dumpfile("../test/inst_br_test.vcd");
        $dumpvars;
        $dumpvars(0, open_mips_min_sopc0.openmips0.regfile1.regs[1]);
        $dumpvars(0, open_mips_min_sopc0.openmips0.regfile1.regs[3]);
        $dumpvars(0, open_mips_min_sopc0.openmips0.regfile1.regs[31]);

        $readmemh("../data/inst_br_test.txt", open_mips_min_sopc0.inst_rom0.inst_mem, 0, 91);

        clk = 0;
        rst = 1;
        #20 rst = 0;
        #12 `AR(1,32'hxxxxxxxx);`AHI(32'h00000000);`ALO(32'h00000000);
        #2  `AR(1,32'hxxxxxxxx);`AHI(32'h00000000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000001);`AHI(32'h00000000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000001);`AHI(32'h00000000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000002);`AHI(32'h00000000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000003);`AHI(32'h00000000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000003);`AHI(32'h00000000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000003);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000004);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000004);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h0000002C);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000005);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000005);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000006);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000007);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000008);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000008);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000009);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h0000000A);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h0000000A);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h0000002C);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h0000000B);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h0000000C);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h0000000D);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h0000000E);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h0000000E);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h0000000F);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000010);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000010);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000011);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000012);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000013);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000013);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h0000014C);`AHI(32'h00000002);`ALO(32'h0000000E);
        #2  `AR(1,32'h00000014);`AHI(32'h00000002);`ALO(32'h0000000E);
        `PASS(branch instruction test);
    end

endmodule