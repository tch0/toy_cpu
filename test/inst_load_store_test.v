`timescale 1ns/1ps
`include "../test/assert.v"

module inst_load_store_test();
    reg     clk, rst;
    integer i  ;

    open_mips_min_sopc open_mips_min_sopc0 (clk,rst);

    always #1 clk = ~clk;
    wire [31:0] mem0x0000 = {open_mips_min_sopc0.data_ram0.bank3[0], open_mips_min_sopc0.data_ram0.bank2[0], open_mips_min_sopc0.data_ram0.bank1[0], open_mips_min_sopc0.data_ram0.bank0[0]};
    wire [31:0] mem0x0004 = {open_mips_min_sopc0.data_ram0.bank3[1], open_mips_min_sopc0.data_ram0.bank2[1], open_mips_min_sopc0.data_ram0.bank1[1], open_mips_min_sopc0.data_ram0.bank0[1]};
    wire [31:0] mem0x0008 = {open_mips_min_sopc0.data_ram0.bank3[2], open_mips_min_sopc0.data_ram0.bank2[2], open_mips_min_sopc0.data_ram0.bank1[2], open_mips_min_sopc0.data_ram0.bank0[2]};
    initial begin
        $dumpfile("../test/inst_load_store_test.vcd");
        $dumpvars;
        $dumpvars(0, open_mips_min_sopc0.openmips0.regfile1.regs[1]);
        $dumpvars(0, open_mips_min_sopc0.openmips0.regfile1.regs[3]);

        $readmemh("../data/inst_load_store_test.txt", open_mips_min_sopc0.inst_rom0.inst_mem, 0, 31);

        clk = 0;
        rst = 1;
        #20 rst = 0;
        #12 `AR(1,32'hxxxxxxxx);`AR(3,32'h0000EEFF);
        #2  `AR(1,32'hxxxxxxxx);`AR(3,32'h0000EEFF);
        #2  `AR(1,32'hxxxxxxxx);`AR(3,32'h000000EE);
        #2  `AR(1,32'hxxxxxxxx);`AR(3,32'h000000EE);
        #2  `AR(1,32'hxxxxxxxx);`AR(3,32'h0000CCDD);
        #2  `AR(1,32'hxxxxxxxx);`AR(3,32'h0000CCDD);
        #2  `AR(1,32'hxxxxxxxx);`AR(3,32'h000000CC);
        #2  `AR(1,32'hxxxxxxxx);`AR(3,32'h000000CC);
        #2  `AR(1,32'hFFFFFFFF);`AR(3,32'h000000CC);
        #2  `AR(1,32'h000000EE);`AR(3,32'h000000CC);
        #2  `AR(1,32'h000000EE);`AR(3,32'h0000AABB);
        #2  `AR(1,32'h000000EE);`AR(3,32'h0000AABB);
        #2  `AR(1,32'h0000AABB);`AR(3,32'h0000AABB);
        #2  `AR(1,32'hFFFFAABB);`AR(3,32'h0000AABB);
        #2  `AR(1,32'hFFFFAABB);`AR(3,32'h00008899);
        #2  `AR(1,32'hFFFFAABB);`AR(3,32'h00008899);
        #2  `AR(1,32'hFFFF8899);`AR(3,32'h00008899);
        #2  `AR(1,32'h00008899);`AR(3,32'h00008899);
        #2  `AR(1,32'h00008899);`AR(3,32'h00004455);
        #2  `AR(1,32'h00008899);`AR(3,32'h44550000);
        #2  `AR(1,32'h00008899);`AR(3,32'h44556677);
        #2  `AR(1,32'h00008899);`AR(3,32'h44556677);
        #2  `AR(1,32'h44556677);`AR(3,32'h44556677);
        #2  `AR(1,32'h44556677);`AR(3,32'h44556677);
        #2  `AR(1,32'hBB889977);`AR(3,32'h44556677);
        #2  `AR(1,32'hBB889977);`AR(3,32'h44556677);
        #2  `AR(1,32'hBB889944);`AR(3,32'h44556677);
        #2  `AR(1,32'hBB889944);`AR(3,32'h44556677);
        #2  `AR(1,32'hBB889944);`AR(3,32'h44556677);
        #2  `AR(1,32'hBB889944);`AR(3,32'h44556677);
        #2  `AR(1,32'h889944FF);`AR(3,32'h44556677);
        #2  `AR(1,32'hAABB88BB);`AR(3,32'h44556677);
        #40 `PASS(load & store instruction test);
    end

endmodule