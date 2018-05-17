`timescale 1ns/1ps
`include "../test/assert.v"

module inst_logic_test();
    reg     clk, rst;
    integer i  ;

    open_mips_min_sopc open_mips_min_sopc0 (clk,rst);

    always #1 clk = ~clk;
    initial begin
        $dumpfile("../test/inst_logic_test.vcd");
        $dumpvars;
        for (i = 1; i <= 4; i = i+1)
            $dumpvars(0, open_mips_min_sopc0.openmips0.regfile1.regs[i]);

        $readmemh("../data/inst_logic_test.txt", open_mips_min_sopc0.inst_rom0.inst_mem, 0, 8);

        clk = 0;
        rst = 1;
        #20 rst = 0;
        #12 `AR(1, 32'h01010000); `AR(2, 32'hxxxxxxxx); `AR(3, 32'hxxxxxxxx); `AR(4, 32'hxxxxxxxx);
        #2  `AR(1, 32'h01010101); `AR(2, 32'hxxxxxxxx); `AR(3, 32'hxxxxxxxx); `AR(4, 32'hxxxxxxxx);
        #2  `AR(1, 32'h01010101); `AR(2, 32'h01011101); `AR(3, 32'hxxxxxxxx); `AR(4, 32'hxxxxxxxx);
        #2  `AR(1, 32'h01011101); `AR(2, 32'h01011101); `AR(3, 32'hxxxxxxxx); `AR(4, 32'hxxxxxxxx);
        #2  `AR(1, 32'h01011101); `AR(2, 32'h01011101); `AR(3, 32'h00000000); `AR(4, 32'hxxxxxxxx);
        #2  `AR(1, 32'h00000000); `AR(2, 32'h01011101); `AR(3, 32'h00000000); `AR(4, 32'hxxxxxxxx);
        #2  `AR(1, 32'h00000000); `AR(2, 32'h01011101); `AR(3, 32'h00000000); `AR(4, 32'h0000FF00);
        #2  `AR(1, 32'h0000FF00); `AR(2, 32'h01011101); `AR(3, 32'h00000000); `AR(4, 32'h0000FF00);
        #2  `AR(1, 32'hFFFF00FF); `AR(2, 32'h01011101); `AR(3, 32'h00000000); `AR(4, 32'h0000FF00);
        `PASS(logic instruction test);
    end

endmodule