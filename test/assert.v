`ifndef ASSERT_V
`define ASSERT_V

`define ASSERT(x) if(1) begin \
    if (!(x)) begin \
        $display("\033[91;1m[%s:%0d] ASSERTION FAILURE: %s\033[0m", `__FILE__,  `__LINE__, `"x`"); \
        $finish_and_return(1); \
    end \
end else if(0)

`define PASS(test) #2 if(1) begin $display("\033[92;1m%s -> PASS\033[0m", `"test`"); $finish; end else if(0)
`define AR(id, expected) `ASSERT(open_mips_min_sopc0.openmips0.regfile1.regs[id] === expected) // generic register assertion
`define AHI(expected) `ASSERT(open_mips_min_sopc0.openmips0.hilo_reg0.hi_o === expected)       // register HI assertion
`define ALO(expected) `ASSERT(open_mips_min_sopc0.openmips0.hilo_reg0.lo_o === expected)       // register LO assertion

`endif
