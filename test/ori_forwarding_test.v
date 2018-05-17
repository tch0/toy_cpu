`timescale 1ns/1ps
`include "../test/assert.v"

module ori_forwarding_test();
    reg     clk, rst;
    integer i  ;

    open_mips_min_sopc open_mips_min_sopc0 (clk, rst);

    always #1 clk = ~clk;
    initial begin
        $dumpfile("../test/ori_forwarding_test.vcd");
        $dumpvars;
        for (i = 2; i <= 5; i = i+1)
            $dumpvars(0, open_mips_min_sopc0.openmips0.regfile1.regs[i]);

        $readmemh("../data/ori_forwarding_test.txt", open_mips_min_sopc0.inst_rom0.inst_mem, 0, 6);

        clk = 0;
        rst = 1;
        #20 rst = 0;
        #18 `AR(5, 32'h00001100);
        #2  `AR(5, 32'h00001120);
        #2  `AR(5, 32'h00005520);
        #2  `AR(5, 32'h00005564);
        `PASS(ori instruction & data hazard test);
    end

endmodule