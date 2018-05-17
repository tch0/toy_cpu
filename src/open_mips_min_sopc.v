// date: 2018.4.28
// author: Tiko.T

// file: open_mips_min_sopc.v
// role: the implementation of min SOPC(system on programmable chip)


`include "const.v"

module open_mips_min_sopc (
	input  wire  clk,
	input  wire  rst	
);

	// for inst_rom
	wire  [`InstAddrBus]      inst_addr   ;
	wire  [`InstBus]          inst        ;
	wire                      rom_ce      ;

	// for data ram
	wire                      ram_ce      ;
	wire                      ram_we      ;
	wire  [3:0        ]       ram_sel     ;
	wire  [`RegBus    ]       ram_addr    ;
	wire  [`RegBus    ]       ram_data_o  ;
	wire  [`DataBus   ]       ram_data_i  ;

	openmips openmips0 (
		.clk ( clk ),
		.rst ( rst ),
		// rom signal
		.rom_addr_o ( inst_addr  ),
		.rom_data_i ( inst       ),
		.rom_ce_o   ( rom_ce     ),
		// ram signal
		.ram_ce     ( ram_ce     ),
		.ram_we     ( ram_we     ),
		.ram_sel    ( ram_sel    ),
		.ram_addr   ( ram_addr   ),
		.ram_data_o ( ram_data_o ),
		.ram_data_i ( ram_data_i )
	);

	inst_rom  inst_rom0 (
		.ce(rom_ce),
		.addr(inst_addr),
		.inst(inst)
	);

	data_ram  data_ram0 (
		.clk    ( clk ),
		// from mem
		.ce     ( ram_ce     ),
		.we     ( ram_we     ),
		.sel    ( ram_sel    ),
		.addr   ( ram_addr   ),
		.data_i ( ram_data_o ),
		// to mem, the output of data_ram become the input of mem. Attetion !!!
		.data_o ( ram_data_i )
	);

endmodule