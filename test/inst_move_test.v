`timescale 1ns/1ps
`include "../test/assert.v"

module inst_move_test();
    reg     clk, rst;
    integer i  ;

    open_mips_min_sopc open_mips_min_sopc0 (clk,rst);

    always #1 clk = ~clk;
    initial begin
        $dumpfile("../test/inst_move_test.vcd");
        $dumpvars;
        for (i = 1; i <= 4; i = i+1)
            $dumpvars(0, open_mips_min_sopc0.openmips0.regfile1.regs[i]);

        $readmemh("../data/inst_move_test.txt", open_mips_min_sopc0.openmips0.inst_rom0.inst_mem, 0, 15);

        clk = 0;
        rst = 1;
        #20 rst = 0;
        #12 `AR(1,32'h00000000);`AR(2,32'hxxxxxxxx);`AR(3,32'hxxxxxxxx);`AR(4,32'hxxxxxxxx);`AHI(32'h00000000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000000);`AR(2,32'hFFFF0000);`AR(3,32'hxxxxxxxx);`AR(4,32'hxxxxxxxx);`AHI(32'h00000000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000000);`AR(2,32'hFFFF0000);`AR(3,32'h05050000);`AR(4,32'hxxxxxxxx);`AHI(32'h00000000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000000);`AR(2,32'hFFFF0000);`AR(3,32'h05050000);`AR(4,32'h00000000);`AHI(32'h00000000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000000);`AR(2,32'hFFFF0000);`AR(3,32'h05050000);`AR(4,32'hFFFF0000);`AHI(32'h00000000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000000);`AR(2,32'hFFFF0000);`AR(3,32'h05050000);`AR(4,32'hFFFF0000);`AHI(32'h00000000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000000);`AR(2,32'hFFFF0000);`AR(3,32'h05050000);`AR(4,32'h05050000);`AHI(32'h00000000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000000);`AR(2,32'hFFFF0000);`AR(3,32'h05050000);`AR(4,32'h05050000);`AHI(32'h00000000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000000);`AR(2,32'hFFFF0000);`AR(3,32'h05050000);`AR(4,32'h05050000);`AHI(32'h00000000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000000);`AR(2,32'hFFFF0000);`AR(3,32'h05050000);`AR(4,32'h05050000);`AHI(32'hFFFF0000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000000);`AR(2,32'hFFFF0000);`AR(3,32'h05050000);`AR(4,32'h05050000);`AHI(32'h05050000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000000);`AR(2,32'hFFFF0000);`AR(3,32'h05050000);`AR(4,32'h05050000);`AHI(32'h05050000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000000);`AR(2,32'hFFFF0000);`AR(3,32'h05050000);`AR(4,32'h05050000);`AHI(32'h05050000);`ALO(32'h05050000);
        #2  `AR(1,32'h00000000);`AR(2,32'hFFFF0000);`AR(3,32'h05050000);`AR(4,32'h05050000);`AHI(32'h05050000);`ALO(32'hFFFF0000);
        #2  `AR(1,32'h00000000);`AR(2,32'hFFFF0000);`AR(3,32'h05050000);`AR(4,32'h05050000);`AHI(32'h05050000);`ALO(32'h00000000);
        #2  `AR(1,32'h00000000);`AR(2,32'hFFFF0000);`AR(3,32'h05050000);`AR(4,32'h00000000);`AHI(32'h05050000);`ALO(32'h00000000);
        `PASS(move instruction test);
    end

endmodule