// date: 2018.4.28
// author: Tiko.T

// file: open_mips_min_sopc_tb.v
// role: test bench of min sopc which only can run one instructin ori.

`include "../src/const.v"

`timescale 1ns/1ps

module open_mips_min_sopc_tb;

	reg  clock;
	reg  rst;

	initial begin 
		clock = 1'b0;
		forever # 10 clock = ~clock;
	end

	initial begin 
		rst = `RESET_ENABLE;
		#195 rst = `RESET_DISABLE;
		#1000 $finish;
	end

	open_mips_min_sopc open_mips_min_sopc0 (
		.clk(clock),
		.rst(rst)
	);

	// initial  $readmemh("../src/inst_rom1.data",open_mips_min_sopc.inst_rom.inst_mem);

	initial begin 
		$dumpfile("./open_mips_min_sopc_tb.vcd");
		$dumpvars(5,open_mips_min_sopc_tb);
	end

endmodule