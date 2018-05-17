// date: 2018.5.6
// author: Tiko.T

// file: ctrl.v
// implememtation of pipeline stall
// motes: receive the stall signal from all stages, control operation of all stages
//        there are only stage id & ex will launch a stall signal, othes stages can finish operation within one clock cycle
// the meaning of signal [stall] : stall[0] -> pc remain (1 is remain)
// stall[1] to stall[5] -> whether stage IF/ID/EX/MEM/WB will stop (1 is stop)


`include "const.v"

module ctrl (
	input  wire               rst              ,
	input  wire               stallreq_from_id ,
	input  wire               stallreq_from_ex ,
	output  reg [`StallBus]   stall               // control signal
);
	
	always @(*) begin
		if(rst == `RESET_ENABLE) begin
			stall <= 6'b000000;
		end else if (stallreq_from_ex == `STOP) begin 
			stall <= 6'b001111;
		end else if (stallreq_from_id == `STOP) begin
			stall <= 6'b000111;
		end else begin 
			stall <= 6'b000000;
		end
	end
endmodule