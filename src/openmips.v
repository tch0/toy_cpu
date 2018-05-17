// date: 2018.4.28
// author: Tiko.T

// file: openmips.v
// role: top module of cpu, not inclue instruction rom & data ram


`include "const.v"

module openmips (
	input  wire                     clk ,
	input  wire                     rst ,

	input  wire  [`RegBus]          rom_data_i  ,      // instructions from inst_rom
	output wire  [`RegBus]          rom_addr_o  ,      // instruction address to inst_rom, assgnment with pc
	output wire                     rom_ce_o    ,      // chip enable to inst_rom

	output wire                      ram_ce      ,
	output wire                      ram_we      ,
	output wire  [3:0        ]       ram_sel     ,
	output wire  [`RegBus    ]       ram_addr    ,
	output wire  [`RegBus    ]       ram_data_o  ,
	input  wire  [`DataBus   ]       ram_data_i   
);


	// pc_reg -> if_id
	wire  [`InstAddrBus]            pc            ;

	// if_id -> if
	wire  [`InstAddrBus]            id_pc_i       ;
	wire  [`InstBus    ]            id_inst_i     ;

	// id -> id_ex
	wire  [`AluOpBus  ]             id_aluop_o    ;
	wire  [`AluSelBus ]             id_alusel_o   ;
	wire  [`RegBus    ]             id_opv1_o     ;
	wire  [`RegBus    ]             id_opv2_o     ;
	wire  [`RegAddrBus]             id_waddr_o    ;
	wire                            id_we_o       ;
	wire  [`InstBus   ]             id_idex_inst  ;

	// id_ex -> ex
	wire  [`AluOpBus  ]             ex_aluop_i    ;
	wire  [`AluSelBus ]             ex_alusel_i   ;
	wire  [`RegBus    ]             ex_opv1_i     ;
	wire  [`RegBus    ]             ex_opv2_i     ;
	wire  [`RegAddrBus]             ex_waddr_i    ;
	wire                            ex_we_i       ;
	wire  [`InstBus   ]             idex_ex_inst  ;

	// ex -> ex_mem
	wire                            ex_we_o       ;
	wire  [`RegAddrBus]             ex_waddr_o    ;
	wire  [`RegBus    ]             ex_wdata_o    ;
	wire                            ex_whilo_o    ;
	wire  [`RegBus    ]             ex_hi_o       ;
	wire  [`RegBus    ]             ex_lo_o       ;
	wire  [`AluOpBus  ]             ex_exmem_aluop    ;
	wire  [`RegBus    ]             ex_exmem_mem_addr ;
	wire  [`RegBus    ]             ex_exmem_opv2     ;


	// ex_mem -> mem
	wire                            mem_we_i      ;
	wire  [`RegAddrBus]             mem_waddr_i   ;
	wire  [`RegBus    ]             mem_wdata_i   ;
	wire                            mem_whilo_i   ;
	wire  [`RegBus    ]             mem_hi_i      ;
	wire  [`RegBus    ]             mem_lo_i      ;
	wire  [`AluOpBus  ]             exmem_mem_aluop    ;
	wire  [`RegBus    ]             exmem_mem_mem_addr ;
	wire  [`RegBus    ]             exmem_mem_opv2     ;


	// mem -> mem_wb
	wire                            mem_we_o      ;
	wire  [`RegAddrBus]             mem_waddr_o   ;
	wire  [`RegBus    ]             mem_wdata_o   ;
	wire                            mem_whilo_o   ;
	wire  [`RegBus    ]             mem_hi_o      ;
	wire  [`RegBus    ]             mem_lo_o      ;
	wire                            mem_LLbit_we_o    ;
	wire                            mem_LLbit_value_o ;


	// mem_wb -> regfile
	wire                            wb_we_i       ;
	wire  [`RegAddrBus]             wb_waddr_i    ;
	wire  [`RegBus    ]             wb_wdata_i    ;
	// mem_wb -> hilo_reg
	wire                            wb_whilo_i    ;
	wire  [`RegBus    ]             wb_hi_i       ;
	wire  [`RegBus    ]             wb_lo_i       ;
	// mem_wb -> LLbit_reg
	wire                            wb_LLbit_we_i    ;
	wire                            wb_LLbit_value_i ;

	// id -> regfile
	wire                            reg1_read     ;
	wire  [`RegAddrBus]             reg1_addr     ;
	wire  [`RegBus    ]             reg1_data     ;
	wire                            reg2_read     ;
	wire  [`RegAddrBus]             reg2_addr     ;
	wire  [`RegBus    ]             reg2_data     ;

	// hilo_reg -> ex
	wire  [`RegBus    ]             hi_ex_o       ;
	wire  [`RegBus    ]             lo_ex_o       ;

	// stall signals
	wire  [`StallBus  ]             stall         ;
	wire                            stallreq_from_id ;
	wire                            stallreq_from_ex ;

	// branch signals
	wire                            id_pc_branch_flag          ;
	wire  [`RegBus    ]             id_pc_branch_addr          ;
	wire                            id_idex_cur_in_delay_slot  ;
	wire  [`RegBus    ]             id_idex_link_addr          ;
	wire                            id_idex_next_in_delay_slot ;
	wire  [`RegBus    ]             idex_ex_link_addr          ;
	wire                            idex_ex_next_in_delay_slot ;
	wire                            idex_id_cur_in_delay_slot  ;

	// LLbit_reg -> mem
	wire                            LLbitreg_mem_LLbit_o       ;                          

	//============================ pc_reg instantiation ==================================================================
	pc_reg  pc_reg0 (
		.clk  ( clk      ),
		.rst  ( rst      ),
		.pc   ( pc       ),
		.ce   ( rom_ce_o ),
		.stall( stall    ),
		.branch_flag_i ( id_pc_branch_flag ),
		.branch_addr_i ( id_pc_branch_addr )
	);

	//=============== pc assignment =============
	assign  rom_addr_o = pc;

	//============================= module instantiation ==================================================================


	if_id  if_id0 (
		.clk     ( clk        ),
		.rst     ( rst        ),
		.if_pc   ( pc         ),
		.if_inst ( rom_data_i ),
		.id_pc   ( id_pc_i    ),
		.id_inst ( id_inst_i  ),
		.stall   ( stall      ) 

	);


	id  id0 (
		.rst         ( rst            ),  
		.pc_i        ( id_pc_i        ),  
		.inst_i      ( id_inst_i      ),
		// read from regfile 
		.reg1_data_i ( reg1_data      ),  
		.reg2_data_i ( reg2_data      ),  
		// handle the data-dependent hazard
		.ex_we_i     ( ex_we_o        ),
		.ex_waddr_i  ( ex_waddr_o     ),
		.ex_wdata_i  ( ex_wdata_o     ),
		.mem_we_i    ( mem_we_o       ),
		.mem_waddr_i ( mem_waddr_o    ),
		.mem_wdata_i ( mem_wdata_o    ),
		.ex_aluop_i  ( ex_exmem_aluop ),
		// to ctrl
		.stallreq    (stallreq_from_id),
		// write to regfile
		.reg1_re_o   ( reg1_read      ),
		.reg2_re_o   ( reg2_read      ),
		.reg1_addr_o ( reg1_addr      ),
		.reg2_addr_o ( reg2_addr      ),
		// send to id_ex
		.aluop_o     ( id_aluop_o     ),
		.alusel_o    ( id_alusel_o    ),
		.opv1_o      ( id_opv1_o      ),
		.opv2_o      ( id_opv2_o      ),
		.we_o        ( id_we_o        ),
		.waddr_o     ( id_waddr_o     ),
		.inst_o      (id_idex_inst    ),

		// branch signals
		.cur_in_delay_slot_i  ( idex_id_cur_in_delay_slot  ),
		.branch_flag_o        ( id_pc_branch_flag          ),
		.branch_addr_o        ( id_pc_branch_addr          ),
		.cur_in_delay_slot_o  ( id_idex_cur_in_delay_slot  ),
		.link_addr_o          ( id_idex_link_addr          ),
		.next_in_delay_slot_o ( id_idex_next_in_delay_slot ) 
	);

	regfile  regfile1 (

		.clk     ( clk ),
		.rst     ( rst ),
		// write
		.we      ( wb_we_i    ),
		.waddr   ( wb_waddr_i ),
		.wdata   ( wb_wdata_i ),
		// read
		.re1     ( reg1_read  ),
		.raddr1  ( reg1_addr  ),
		.rdata1  ( reg1_data  ),
		.re2     ( reg2_read  ),
		.raddr2  ( reg2_addr  ),
		.rdata2  ( reg2_data  )  
	);

	id_ex  id_ex0 (
		.clk       ( clk    ),
		.rst       ( rst    ),
		// from ID
		.id_aluop  ( id_aluop_o  ),
		.id_alusel ( id_alusel_o ),
		.id_reg1   ( id_opv1_o   ),
		.id_reg2   ( id_opv2_o   ),
		.id_waddr  ( id_waddr_o  ),
		.id_we     ( id_we_o     ),
		.id_inst   (id_idex_inst ),
		// from ctrl
		.stall     ( stall       ),
		// to EX
		.ex_aluop  ( ex_aluop_i  ),
		.ex_alusel ( ex_alusel_i ),
		.ex_reg1   ( ex_opv1_i   ),
		.ex_reg2   ( ex_opv2_i   ),
		.ex_waddr  ( ex_waddr_i  ),
		.ex_we     ( ex_we_i     ),
		.ex_inst   ( idex_ex_inst),
		// branch signals
		.id_cur_in_delay_slot  ( id_idex_cur_in_delay_slot  ),
		.id_link_addr          ( id_idex_link_addr          ),
		.next_in_delay_slot_i  ( id_idex_next_in_delay_slot ),
		.ex_cur_in_delay_slot  ( idex_ex_next_in_delay_slot ),         
		.ex_link_addr          ( idex_ex_link_addr          ),
		.next_in_delay_slot_o  ( idex_id_cur_in_delay_slot  ) 
	);

	ex  ex0 (
		.rst       ( rst ),
		// from ID
		.aluop_i   ( ex_aluop_i  ),
		.alusel_i  ( ex_alusel_i ),
		.opv1_i    ( ex_opv1_i   ),
		.opv2_i    ( ex_opv2_i   ),
		.waddr_i   ( ex_waddr_i  ),
		.we_i      ( ex_we_i     ),
		.inst_i    ( idex_ex_inst),
		// to MEM
		.we_o      ( ex_we_o     ),
		.waddr_o   ( ex_waddr_o  ),
		.wdata_o   ( ex_wdata_o  ),
		.whilo_o   ( ex_whilo_o  ),
		.hi_o      ( ex_hi_o     ),
		.lo_o      ( ex_lo_o     ),
		.aluop_o   ( ex_exmem_aluop    ),
		.mem_addr_o( ex_exmem_mem_addr ),
		.opv2_o    ( ex_exmem_opv2     ),
		// to ctrl
		.stallreq  ( stallreq_from_ex  ),
		// from HI & LO
		.hi_i       ( hi_ex_o     ),
		.lo_i       ( lo_ex_o     ),
		// handle the data-dependent about HI & LO
		.mem_whilo_i( mem_whilo_o ),
		.mem_hi_i   ( mem_hi_o    ),
		.mem_lo_i   ( mem_lo_o    ),
		.wb_whilo_i ( wb_whilo_i  ),
		.wb_hi_i    ( wb_hi_i     ),
		.wb_lo_i    ( wb_lo_i     ),
		// branch signals
		.cur_in_delay_slot_i ( idex_ex_next_in_delay_slot ),
		.link_addr_i         ( idex_ex_link_addr          )

	);

	ex_mem  ex_mem0 (
		.clk         ( clk ),
		.rst         ( rst ),
		// from EX
		.ex_we       ( ex_we_o     ),
		.ex_waddr    ( ex_waddr_o  ),
		.ex_wdata    ( ex_wdata_o  ),
		.ex_whilo    ( ex_whilo_o  ),
		.ex_hi       ( ex_hi_o     ),
		.ex_lo       ( ex_lo_o     ),
		.ex_aluop    ( ex_exmem_aluop    ),
		.ex_mem_addr ( ex_exmem_mem_addr ),
		.ex_opv2     ( ex_exmem_opv2     ),

		// from ctrl
		.stall       ( stall       ),
		// to MEM
		.mem_we      ( mem_we_i    ),
		.mem_waddr   ( mem_waddr_i ),
		.mem_wdata   ( mem_wdata_i ),
		.mem_whilo   ( mem_whilo_i ),
		.mem_hi      ( mem_hi_i    ),
		.mem_lo      ( mem_lo_i    ),
		.mem_aluop   ( exmem_mem_aluop    ),
		.mem_mem_addr( exmem_mem_mem_addr ),
		.mem_opv2    ( exmem_mem_opv2     ) 

	);

	mem  mem0 (
		.rst      ( rst ),
		// from EX
		.we_i     ( mem_we_i    ),
		.waddr_i  ( mem_waddr_i ),
		.wdata_i  ( mem_wdata_i ),
		.whilo_i  ( mem_whilo_i ),
		.hi_i     ( mem_hi_i    ),
		.lo_i     ( mem_lo_i    ),
		// to WB
		.we_o     ( mem_we_o    ),
		.waddr_o  ( mem_waddr_o ),
		.wdata_o  ( mem_wdata_o ),
		.whilo_o  ( mem_whilo_o ),
		.hi_o     ( mem_hi_o    ),
		.lo_o     ( mem_lo_o    ),
		.LLbit_we_o    ( mem_LLbit_we_o     ),
		.LLbit_value_o ( mem_LLbit_value_o  ),
		// from EX/MEM
		.aluop_i       ( exmem_mem_aluop    ),
		.mem_addr_i    ( exmem_mem_mem_addr ),
		.opv2_i        ( exmem_mem_opv2     ),
		// to data_ram
		.mem_ce_o   ( ram_ce     ),
		.mem_we_o   ( ram_we     ),
		.mem_sel_o  ( ram_sel    ),
		.mem_addr_o ( ram_addr   ),
		.mem_data_o ( ram_data_o ),
		// from data_ram
		.mem_data_i ( ram_data_i ),
		// from mem_wb
		.wb_LLbit_we_i    ( wb_LLbit_we_i    ),
		.wb_LLbit_value_i ( wb_LLbit_value_i ),
		// from LLbit_reg
		.LLbit_i   ( LLbitreg_mem_LLbit_o    )
	);

	mem_wb  mem_wb0 (

		.clk       ( clk ),
		.rst       ( rst ),
		// from MEM
		.mem_we    ( mem_we_o    ),
		.mem_waddr ( mem_waddr_o ),
		.mem_wdata ( mem_wdata_o ),
		.mem_whilo ( mem_whilo_o ),
		.mem_hi    ( mem_hi_o    ),
		.mem_lo    ( mem_lo_o    ),
		.mem_LLbit_we    ( mem_LLbit_we_o    ), 
		.mem_LLbit_value ( mem_LLbit_value_o ), 
		// from ctrl
		.stall     ( stall       ),
		// to WB
		.wb_we     ( wb_we_i     ),
		.wb_waddr  ( wb_waddr_i  ),
		.wb_wdata  ( wb_wdata_i  ),
		.wb_whilo  ( wb_whilo_i  ),
		.wb_hi     ( wb_hi_i     ),
		.wb_lo     ( wb_lo_i     ),
		.wb_LLbit_we    ( wb_LLbit_we_i    ), 
		.wb_LLbit_value ( wb_LLbit_value_i )  

	);

	hilo_reg  hilo_reg0 (
		.clk       ( clk        ),
		.rst       ( rst        ),
		.we        ( wb_whilo_i ),
		.hi_i      ( wb_hi_i    ),
		.lo_i      ( wb_lo_i    ),
		.hi_o      ( hi_ex_o    ),
		.lo_o      ( lo_ex_o    )
	);

	ctrl  ctrl0 (
		.rst              ( rst              ),
		.stallreq_from_id ( stallreq_from_id ),
		.stallreq_from_ex ( stallreq_from_ex ),
		.stall            ( stall            ) 
	);

	LLbit_reg LLbit_reg0 (
		.clk     ( clk  ), 
		.rst     ( rst  ), 
		.flush   ( 1'b0 ), 
		.we      ( wb_LLbit_we_i        ),
		.LLbit_i ( wb_LLbit_value_i     ),  
		.LLbit_o ( LLbitreg_mem_LLbit_o )

	);

endmodule