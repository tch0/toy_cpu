// date: 2018.4.27
// author: Tiko.T

// file: id.v
// role: instruction decoder


`include "const.v"

module id (
    input  wire                           rst          ,
    input  wire  [`InstAddrBus]           pc_i         ,
    input  wire  [`InstBus    ]           inst_i       ,

    //============== read from regfile
    input  wire  [`RegBus     ]           reg1_data_i  ,
    input  wire  [`RegBus     ]           reg2_data_i  ,

    //============== handle the data dependent hazard
    input  wire                           ex_we_i      ,
    input  wire  [`RegAddrBus ]           ex_waddr_i   ,
    input  wire  [`RegBus     ]           ex_wdata_i   ,
    input  wire                           mem_we_i     ,
    input  wire  [`RegAddrBus ]           mem_waddr_i  ,
    input  wire  [`RegBus     ]           mem_wdata_i  ,
    //============ from ex, handle the load hazard
    input  wire  [`AluOpBus   ]           ex_aluop_i   ,

    //============== read regfile
    output  reg                           reg1_re_o    ,
    output  reg                           reg2_re_o    ,
    output  reg  [`RegAddrBus]            reg1_addr_o  ,
    output  reg  [`RegAddrBus]            reg2_addr_o  ,

    //============= send to EX
    output  reg  [`AluOpBus  ]            aluop_o      ,            // instruction subtype
    output  reg  [`AluSelBus ]            alusel_o     ,            // instruction type
    output  reg  [`RegBus    ]            opv1_o       ,            // operation number 1
    output  reg  [`RegBus    ]            opv2_o       ,            // operation number 2
    output  reg                           we_o         ,            // wirte register or not
    output  reg  [`RegAddrBus]            waddr_o      ,            // the address of register
    output wire  [`InstBus   ]            inst_o       ,            // instruction to ex for load & store instructions 

    //============ send to ctrl, stall request signal
    output wire                           stallreq     ,
    //============ signals about branch
    input  wire                           cur_in_delay_slot_i  ,     // current instruction in the delay slot or not, from id_ex
    output  reg                           branch_flag_o        ,     // branch or not
    output  reg  [`RegBus    ]            branch_addr_o        ,     // branch target address
    output wire                           cur_in_delay_slot_o  ,     // to id_ex
    output  reg  [`RegBus    ]            link_addr_o          ,     // link address / return address
    output  reg                           next_in_delay_slot_o       // next instruction is in delay slot or not
);

    // get every part of an instruction
    wire  [5:0 ]  op       =  inst_i[31:26];
    wire  [4:0 ]  rs       =  inst_i[25:21];
    wire  [4:0 ]  rt       =  inst_i[20:16];
    wire  [4:0 ]  rd       =  inst_i[15:11];  // destination
    wire  [4:0 ]  sa       =  inst_i[10:6 ];  // shamt / offset
    wire  [5:0 ]  funct    =  inst_i[5 :0 ];
    wire  [15:0]  inst_imm =  inst_i[15:0 ];
    wire  [31:0]  sext_imm =  {{16{inst_i[15]}}, inst_i[15:0]}; // sign-extended immidiate
    wire  [31:0]  pc4      =  pc_i + 4;
    wire  [31:0]  pc8      =  pc_i + 8;
    wire  [31:0]  pc_j     =  {pc4[31:28], inst_i[25:0], 2'b00};                
    wire  [31:0]  pc_b     =  pc_i + 4 + {{14{inst_i[15]}}, inst_i[15:0], 2'b00};

    reg  [`RegBus]       imm;
    reg                  inst_valid;
    wire                 pre_inst_is_load;
    reg                  stallreq_for_reg1_load_dependant;
    reg                  stallreq_for_reg2_load_dependant;

    assign stallreq = stallreq_for_reg1_load_dependant || stallreq_for_reg2_load_dependant;
    assign cur_in_delay_slot_o = cur_in_delay_slot_i;
    assign inst_o = inst_i;
    assign pre_inst_is_load = ( ex_aluop_i == `EXE_LB_OP  || 
                                ex_aluop_i == `EXE_LBU_OP ||
                                ex_aluop_i == `EXE_LH_OP  ||
                                ex_aluop_i == `EXE_LHU_OP ||
                                ex_aluop_i == `EXE_LW_OP  ||
                                ex_aluop_i == `EXE_LW_OP  ||
                                ex_aluop_i == `EXE_LWL_OP ||
                                ex_aluop_i == `EXE_LWR_OP ||
                                ex_aluop_i == `EXE_LL_OP  || 
                                ex_aluop_i == `EXE_SC_OP  ) ? 1'b1 : 1'b0;

    `define SET_INST(i_aluop, i_alusel, i_re1, i_reg1_addr, i_re2, i_reg2_addr, i_we, i_waddr, i_imm, i_inst_valid) if(1) begin \
        aluop_o       <=  i_aluop       ; \
        alusel_o      <=  i_alusel      ; \
        reg1_re_o     <=  i_re1         ; \
        reg1_addr_o   <=  i_reg1_addr   ; \
        reg2_re_o     <=  i_re2         ; \
        reg2_addr_o   <=  i_reg2_addr   ; \
        we_o          <=  i_we          ; \
        waddr_o       <=  i_waddr       ; \
        imm           <=  i_imm         ; \
        inst_valid    <=  i_inst_valid  ; \
    end else if(0)

    `define SET_BRANCH(i_branch_flag, i_branch_target_addr, i_link_addr, i_next_in_delay_slot) if(1) begin \
        branch_flag_o         <=  i_branch_flag         ; \
        branch_addr_o         <=  i_branch_target_addr  ; \
        link_addr_o           <=  i_link_addr           ; \
        next_in_delay_slot_o  <=  i_next_in_delay_slot  ; \
    end else if(0)


    // decode
    always @(*) begin
        if(rst == `RESET_ENABLE) begin
            `SET_INST(`EXE_NOP_OP, `EXE_RES_NOP, 0, rs, 0, rt, 0, rd, 0, 0);
        end else begin
            `SET_INST(`EXE_NOP_OP, `EXE_RES_NOP, 0, 0, 0, 0, 0, 0, 0, 0);
            `SET_BRANCH(0, 0, 0, 0);
            case (op)
                `EXE_SPECIAL_INST: case (funct) // R type instruction and op == 6h'0 (RI type)
                    `EXE_AND  :  `SET_INST(`EXE_AND_OP  , `EXE_RES_LOGIC, 1, rs, 1, rt, 1, rd, 0 , 1);
                    `EXE_OR   :  `SET_INST(`EXE_OR_OP   , `EXE_RES_LOGIC, 1, rs, 1, rt, 1, rd, 0 , 1);
                    `EXE_XOR  :  `SET_INST(`EXE_XOR_OP  , `EXE_RES_LOGIC, 1, rs, 1, rt, 1, rd, 0 , 1);
                    `EXE_NOR  :  `SET_INST(`EXE_NOR_OP  , `EXE_RES_LOGIC, 1, rs, 1, rt, 1, rd, 0 , 1);
                    `EXE_SLLV :  `SET_INST(`EXE_SLL_OP  , `EXE_RES_SHIFT, 1, rs, 1, rt, 1, rd, 0 , 1);
                    `EXE_SRLV :  `SET_INST(`EXE_SRL_OP  , `EXE_RES_SHIFT, 1, rs, 1, rt, 1, rd, 0 , 1);
                    `EXE_SRAV :  `SET_INST(`EXE_SRA_OP  , `EXE_RES_SHIFT, 1, rs, 1, rt, 1, rd, 0 , 1);
                    `EXE_SLL  :  `SET_INST(`EXE_SLL_OP  , `EXE_RES_SHIFT, 0, rs, 1, rt, 1, rd, sa, 1);
                    `EXE_SRL  :  `SET_INST(`EXE_SRL_OP  , `EXE_RES_SHIFT, 0, rs, 1, rt, 1, rd, sa, 1);
                    `EXE_SRA  :  `SET_INST(`EXE_SRA_OP  , `EXE_RES_SHIFT, 0, rs, 1, rt, 1, rd, sa, 1);
                    `EXE_SYNC :  `SET_INST(`EXE_NOP_OP  , `EXE_RES_LOGIC, 0, rs, 0, rt, 0, rd, 0 , 1);
                    `EXE_MOVN :  `SET_INST(`EXE_MOVN_OP , `EXE_RES_MOVE , 1, rs, 1, rt, opv2_o!=0, rd, 0 , 1);
                    `EXE_MOVZ :  `SET_INST(`EXE_MOVZ_OP , `EXE_RES_MOVE , 1, rs, 1, rt, opv2_o==0, rd, 0 , 1);
                    `EXE_MFHI :  `SET_INST(`EXE_MFHI_OP , `EXE_RES_MOVE , 0, rs, 0, rt, 1, rd, 0 , 1);
                    `EXE_MFLO :  `SET_INST(`EXE_MFLO_OP , `EXE_RES_MOVE , 0, rs, 0, rt, 1, rd, 0 , 1);
                    `EXE_MTHI :  `SET_INST(`EXE_MTHI_OP , `EXE_RES_MOVE , 1, rs, 0, rt, 0, rd, 0 , 1);
                    `EXE_MTLO :  `SET_INST(`EXE_MTLO_OP , `EXE_RES_MOVE , 1, rs, 0, rt, 0, rd, 0 , 1);
                    `EXE_SLT  :  `SET_INST(`EXE_SLT_OP  , `EXE_RES_ARITH, 1, rs, 1, rt, 1, rd, 0 , 1);
                    `EXE_SLTU :  `SET_INST(`EXE_SLTU_OP , `EXE_RES_ARITH, 1, rs, 1, rt, 1, rd, 0 , 1);
                    `EXE_ADD  :  `SET_INST(`EXE_ADD_OP  , `EXE_RES_ARITH, 1, rs, 1, rt, 1, rd, 0 , 1);
                    `EXE_ADDU :  `SET_INST(`EXE_ADDU_OP , `EXE_RES_ARITH, 1, rs, 1, rt, 1, rd, 0 , 1);
                    `EXE_SUB  :  `SET_INST(`EXE_SUB_OP  , `EXE_RES_ARITH, 1, rs, 1, rt, 1, rd, 0 , 1);
                    `EXE_SUBU :  `SET_INST(`EXE_SUBU_OP , `EXE_RES_ARITH, 1, rs, 1, rt, 1, rd, 0 , 1);
                    `EXE_MULT :  `SET_INST(`EXE_MULT_OP , `EXE_RES_ARITH, 1, rs, 1, rt, 1, rd, 0 , 1);  // mul ?
                    `EXE_MULTU:  `SET_INST(`EXE_MULTU_OP, `EXE_RES_ARITH, 1, rs, 1, rt, 1, rd, 0 , 1);
                    `EXE_DIV  :  `SET_INST(`EXE_DIV_OP  , `EXE_RES_ARITH, 1, rs, 1, rt, 0, rd ,0 , 1);
                    `EXE_DIVU :  `SET_INST(`EXE_DIV_OP  , `EXE_RES_ARITH, 1, rs, 1, rt, 0, rd ,0 , 1);
                    `EXE_JR   :  begin 
                        `SET_INST(`EXE_JR_OP ,  `EXE_RES_JUMP_BRANCH, 1, rs, 0, rt, 0, rd, 0, 1);
                        `SET_BRANCH(1, opv1_o, 0, 1);
                    end
                    `EXE_JALR:  begin 
                        `SET_INST(`EXE_JALR_OP, `EXE_RES_JUMP_BRANCH, 1, rs, 0, rt, 1, rd, 0, 1);
                        `SET_BRANCH(1, opv1_o, pc8, 1); // delay slot: return address <- pc_i + 8
                    end
                endcase // funct
                `EXE_SPECIAL2_INST: case (funct) // SPECIAL2 type instruction (R type & op == 6'b011100) 
                    `EXE_CLZ : `SET_INST(`EXE_CLZ_OP, `EXE_RES_ARITH, 1, rs, 0, rt, 1, rd, 0, 1);
                    `EXE_CLO : `SET_INST(`EXE_CLO_OP, `EXE_RES_ARITH, 1, rs, 0, rt, 1, rd, 0, 1);
                    `EXE_MUL : `SET_INST(`EXE_MUL_OP, `EXE_RES_MUL  , 1, rs, 1, rt, 1, rd, 0, 1);
                endcase // funct
                `EXE_ORI  : `SET_INST(`EXE_OR_OP   , `EXE_RES_LOGIC, 1, rs, 0, 0, 1, rt, ({16'h0, inst_imm}), 1); // zero-extend 16bit to 32 bit
                `EXE_ANDI : `SET_INST(`EXE_AND_OP  , `EXE_RES_LOGIC, 1, rs, 0, 0, 1, rt, ({16'h0, inst_imm}), 1);
                `EXE_XORI : `SET_INST(`EXE_XOR_OP  , `EXE_RES_LOGIC, 1, rs, 0, 0, 1, rt, ({16'h0, inst_imm}), 1);
                `EXE_LUI  : `SET_INST(`EXE_OR_OP   , `EXE_RES_LOGIC, 1, rs, 0, 0, 1, rt, ({inst_imm, 16'h0}), 1);
                `EXE_PREF : `SET_INST(`EXE_NOP_OP  , `EXE_RES_NOP  , 0, rs, 0, 0, 0, rt, 0                  , 1);
                `EXE_SLTI : `SET_INST(`EXE_SLT_OP  , `EXE_RES_ARITH, 1, rs, 0, 0, 1, rt, sext_imm           , 1);
                `EXE_SLTIU: `SET_INST(`EXE_SLTU_OP , `EXE_RES_ARITH, 1, rs, 0, 0, 1, rt, sext_imm           , 1);
                `EXE_ADDI : `SET_INST(`EXE_ADDI_OP , `EXE_RES_ARITH, 1, rs, 0, 0, 1, rt, sext_imm           , 1);
                `EXE_ADDIU: `SET_INST(`EXE_ADDIU_OP, `EXE_RES_ARITH, 1, rs, 0, 0, 1, rt, sext_imm           , 1);
                `EXE_LB   : `SET_INST(`EXE_LB_OP   , `EXE_RES_LOAD_STORE, 1, rs, 0, 0 , 1, rt, 0, 1);
                `EXE_LBU  : `SET_INST(`EXE_LBU_OP  , `EXE_RES_LOAD_STORE, 1, rs, 0, 0 , 1, rt, 0, 1);
                `EXE_LH   : `SET_INST(`EXE_LH_OP   , `EXE_RES_LOAD_STORE, 1, rs, 0, 0 , 1, rt, 0, 1);
                `EXE_LHU  : `SET_INST(`EXE_LHU_OP  , `EXE_RES_LOAD_STORE, 1, rs, 0, 0 , 1, rt, 0, 1);
                `EXE_LW   : `SET_INST(`EXE_LW_OP   , `EXE_RES_LOAD_STORE, 1, rs, 0, 0 , 1, rt, 0, 1);
                `EXE_LWL  : `SET_INST(`EXE_LWL_OP  , `EXE_RES_LOAD_STORE, 1, rs, 1, rt, 1, rt, 0, 1);
                `EXE_LWR  : `SET_INST(`EXE_LWR_OP  , `EXE_RES_LOAD_STORE, 1, rs, 1, rt, 1, rt, 0, 1);
                `EXE_SB   : `SET_INST(`EXE_SB_OP   , `EXE_RES_LOAD_STORE, 1, rs, 1, rt, 0, 0 , 0, 1);
                `EXE_SH   : `SET_INST(`EXE_SH_OP   , `EXE_RES_LOAD_STORE, 1, rs, 1, rt, 0, 0 , 0, 1);
                `EXE_SW   : `SET_INST(`EXE_SW_OP   , `EXE_RES_LOAD_STORE, 1, rs, 1, rt, 0, 0 , 0, 1);
                `EXE_SWL  : `SET_INST(`EXE_SWL_OP  , `EXE_RES_LOAD_STORE, 1, rs, 1, rt, 0, 0 , 0, 1);
                `EXE_SWR  : `SET_INST(`EXE_SWR_OP  , `EXE_RES_LOAD_STORE, 1, rs, 1, rt, 0, 0 , 0, 1);
                `EXE_LL   : `SET_INST(`EXE_LL_OP   , `EXE_RES_LOAD_STORE, 1, rs, 0,  0, 1, rt, 0, 1);
                `EXE_SC   : `SET_INST(`EXE_SC_OP   , `EXE_RES_LOAD_STORE, 1, rs, 1, rt, 1, rt, 0, 1);    
                // branch & jump instructions
                `EXE_J    : begin 
                    `SET_INST(`EXE_J_OP   , `EXE_RES_JUMP_BRANCH, 0, rs, 0, rt, 0, rd, 0, 1);
                    `SET_BRANCH(1, pc_j, 0, 1);
                end
                `EXE_JAL  : begin 
                    `SET_INST(`EXE_JAL_OP , `EXE_RES_JUMP_BRANCH, 0, rs, 0, rt, 1, 31, 0, 1);
                    `SET_BRANCH(1, pc_j, pc8, 1);        
                end
                `EXE_BEQ  : begin 
                    `SET_INST(`EXE_BEQ_OP , `EXE_RES_JUMP_BRANCH, 1, rs, 1, rt, 0, rd, 0, 1);
                    if(opv1_o == opv2_o) `SET_BRANCH(1, pc_b, 0, 1);
                end
                `EXE_BNE  : begin 
                    `SET_INST(`EXE_BNE_OP , `EXE_RES_JUMP_BRANCH, 1, rs, 1, rt, 0, rd, 0, 1);
                    if(opv1_o != opv2_o) `SET_BRANCH(1, pc_b, 0, 1);
                end
                `EXE_BGTZ : begin 
                    `SET_INST(`EXE_BGTZ_OP, `EXE_RES_JUMP_BRANCH, 1, rs, 0, rt, 0, rd, 0, 1);
                    if($signed(opv1_o) > 0) `SET_BRANCH(1, pc_b, 0, 1);
                end
                `EXE_BLEZ : begin 
                    `SET_INST(`EXE_BLEZ_OP, `EXE_RES_JUMP_BRANCH, 1, rs, 0, rt, 0, rd, 0, 1);
                    if($signed(opv1_o) <= 0) `SET_BRANCH(1, pc_b, 0, 1);
                end
                `EXE_REGIMM : case (rt)
                    `EXE_BLTZ : begin 
                        `SET_INST(`EXE_BLTZ_OP   , `EXE_RES_JUMP_BRANCH, 1, rs, 0, rt, 0, rd, 0, 1);
                        if($signed(opv1_o) <  0) `SET_BRANCH(1, pc_b, 0, 1);
                    end    
                    `EXE_BGEZ : begin 
                        `SET_INST(`EXE_BGEZ_OP   , `EXE_RES_JUMP_BRANCH, 1, rs, 0, rt, 0, rd, 0, 1);
                        if($signed(opv1_o) >= 0) `SET_BRANCH(1, pc_b, 0, 1);
                    end
                    `EXE_BLTZAL : begin // need link (save return address to $31)
                        if($signed(opv1_o) <  0) begin 
                            `SET_INST(`EXE_BLTZAL_OP, `EXE_RES_JUMP_BRANCH, 1, rs, 0, rt, 1, 31, 0, 1);
                            `SET_BRANCH(1, pc_b, pc8, 1);
                        end else begin 
                            `SET_INST(`EXE_BLTZAL_OP, `EXE_RES_JUMP_BRANCH, 1, rs, 0, rt, 0, 31, 0, 1);
                        end
                    end
                    `EXE_BGEZAL : begin // need link (save return address to $31)
                        if($signed(opv1_o) >= 0) begin 
                            `SET_INST(`EXE_BGEZAL_OP, `EXE_RES_JUMP_BRANCH, 1, rs, 0, rt, 1, 31, 0, 1);
                            `SET_BRANCH(1, pc_b, pc8, 1);
                        end else begin 
                            `SET_INST(`EXE_BGEZAL_OP, `EXE_RES_JUMP_BRANCH, 1, rs, 0, rt, 0, 31, 0, 1);
                        end
                    end
                endcase // rt
            endcase // op
        end
    end


    // source operation number 1
    always @(*) begin
        stallreq_for_reg1_load_dependant <= `NOSTOP;
        if(rst == `RESET_ENABLE) begin
            opv1_o  <=  `ZERO_WORD;
        end else if(pre_inst_is_load == 1'b1 && ex_waddr_i == reg1_addr_o && reg1_re_o == 1'b1) begin
            stallreq_for_reg1_load_dependant <= `STOP;
        end else if((reg1_re_o == 1'b1) && (ex_we_i == 1'b1) && (ex_waddr_i == reg1_addr_o)) begin 
            opv1_o  <=  ex_wdata_i;
        end else if((reg1_re_o == 1'b1) && (mem_we_i == 1'b1) && (mem_waddr_i == reg1_addr_o)) begin 
            opv1_o  <=  mem_wdata_i;
        end else if(reg1_re_o   == 1'b1) begin 
            opv1_o  <=  reg1_data_i;
        end else if(reg1_re_o   == 1'b0) begin 
            opv1_o  <=  imm;
        end else begin 
            opv1_o  <= `ZERO_WORD;
        end
    end


    // source operation number 2
    always @(*) begin
        stallreq_for_reg2_load_dependant <= `NOSTOP;
        if(rst == `RESET_ENABLE) begin 
            opv2_o  <=  `ZERO_WORD;
        end else if(pre_inst_is_load == 1'b1 && ex_waddr_i == reg2_addr_o && reg2_re_o == 1'b1) begin
            stallreq_for_reg2_load_dependant <= `STOP;
        end else if((reg2_re_o == 1'b1) && (ex_we_i == 1'b1) && (ex_waddr_i == reg2_addr_o)) begin 
            opv2_o  <=  ex_wdata_i;
        end else if((reg2_re_o == 1'b1) && (mem_we_i == 1'b1) && (mem_waddr_i == reg2_addr_o)) begin 
            opv2_o  <=  mem_wdata_i;
        end else if(reg2_re_o   == 1'b1) begin 
            opv2_o  <=  reg2_data_i;            // regfile read port 2
        end else if(reg2_re_o   == 1'b0) begin 
            opv2_o  <=  imm;                    // immidiate number
        end else begin 
            opv2_o  <= `ZERO_WORD;
        end
    end

    `undef SET_INST
    `undef SET_BRANCH

endmodule
