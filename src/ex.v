// date: 2018.4.28
// author: Tiko.T

// file: ex.v
// role: execution of instrucions from ID


`include "const.v"

module ex (
    input  wire                        rst        ,
    // form ID
    input  wire  [`AluOpBus  ]         aluop_i    ,
    input  wire  [`AluSelBus ]         alusel_i   ,
    inout  wire  [`RegBus    ]         opv1_i     ,
    input  wire  [`RegBus    ]         opv2_i     ,
    input  wire  [`RegAddrBus]         waddr_i    ,
    input  wire                        we_i       ,
    input  wire  [`InstBus   ]         inst_i     ,

    // result to MEM
    output  reg                       we_o        ,
    output  reg  [`RegAddrBus]        waddr_o     ,
    output  reg  [`RegBus    ]        wdata_o     ,
    output  reg                       whilo_o     ,
    output  reg  [`RegBus    ]        hi_o        ,
    output  reg  [`RegBus    ]        lo_o        ,
    output wire  [`AluOpBus  ]        aluop_o     ,
    output wire  [`RegBus    ]        mem_addr_o  ,
    output wire  [`RegBus    ]        opv2_o      ,

    // HI & LO input
    input  wire  [`RegBus    ]        hi_i        ,
    input  wire  [`RegBus    ]        lo_i        ,

    // stall request signal to ctrl
    output wire                       stallreq    ,
    // handle the data-dependent hazard about HI & LO
    input  wire                       mem_whilo_i ,
    input  wire  [`RegBus    ]        mem_hi_i    ,
    input  wire  [`RegBus    ]        mem_lo_i    ,
    input  wire                       wb_whilo_i  ,
    input  wire  [`RegBus    ]        wb_hi_i     ,
    input  wire  [`RegBus    ]        wb_lo_i     ,

    // signals about branch
    input  wire                       cur_in_delay_slot_i ,
    input  wire  [`RegBus    ]        link_addr_i         

);

    // result of operation
    reg  [`RegBus]    logic_res;
    reg  [`RegBus]    shift_res;
    reg  [`RegBus]    move_res;
    reg  [`RegBus]    HI;
    reg  [`RegBus]    LO;
    reg  [`RegBus]    arith_res;
    reg  [`DoubleRegBus]    mul_res;

    assign stallreq = `NOSTOP;
    assign aluop_o  = aluop_i;
    assign opv2_o   = opv2_i ;
    assign mem_addr_o = opv1_i + {{16{inst_i[15]}}, inst_i[15:0]};  // memory address <- base + signed-extend offset


    // multiplication operation
    always @(*) begin
        if(rst == `RESET_ENABLE) begin
            mul_res <= `ZERO_WORD;
        end else begin
            case (aluop_i)
                `EXE_MUL_OP  : mul_res <= $signed(opv1_i) * $signed(opv2_i);
                `EXE_MULT_OP : mul_res <= $signed(opv1_i) * $signed(opv2_i);
                `EXE_MULTU_OP: mul_res <= opv1_i * opv2_i;
            endcase
        end
    end

    // Add/subtract & counting operation
    wire [`RegBus]    opv1_i_not = ~opv1_i;
    always @(*) begin
        if(rst == `RESET_ENABLE) begin
            arith_res <= `ZERO_WORD;
        end else begin 
            case (aluop_i)
                `EXE_SLT_OP   : arith_res <= $signed(opv1_i) < $signed(opv2_i);
                `EXE_SLTU_OP  : arith_res <= opv1_i < opv2_i;
                `EXE_ADD_OP   : arith_res <= $signed(opv1_i) + $signed(opv2_i);
                `EXE_ADDU_OP  : arith_res <= opv1_i + opv2_i;
                `EXE_ADDI_OP  : arith_res <= $signed(opv1_i) + $signed(opv2_i);
                `EXE_ADDIU_OP : arith_res <= opv1_i + opv2_i;
                `EXE_SUB_OP   : arith_res <= $signed(opv1_i) - $signed(opv2_i);
                `EXE_SUBU_OP  : arith_res <= opv1_i - opv2_i;
                `EXE_CLZ_OP   : arith_res <= opv1_i [31] ? 0  :  opv1_i [30] ? 1  : 
                                             opv1_i [29] ? 2  :  opv1_i [28] ? 3  : 
                                             opv1_i [27] ? 4  :  opv1_i [26] ? 5  : 
                                             opv1_i [25] ? 6  :  opv1_i [24] ? 7  : 
                                             opv1_i [23] ? 8  :  opv1_i [22] ? 9  : 
                                             opv1_i [21] ? 10 :  opv1_i [20] ? 11 : 
                                             opv1_i [19] ? 12 :  opv1_i [18] ? 13 : 
                                             opv1_i [17] ? 14 :  opv1_i [16] ? 15 : 
                                             opv1_i [15] ? 16 :  opv1_i [14] ? 17 : 
                                             opv1_i [13] ? 18 :  opv1_i [12] ? 19 : 
                                             opv1_i [11] ? 20 :  opv1_i [10] ? 21 : 
                                             opv1_i [9 ] ? 22 :  opv1_i [8 ] ? 23 : 
                                             opv1_i [7 ] ? 24 :  opv1_i [6 ] ? 25 : 
                                             opv1_i [5 ] ? 26 :  opv1_i [4 ] ? 27 : 
                                             opv1_i [3 ] ? 28 :  opv1_i [2 ] ? 29 : 
                                             opv1_i [1 ] ? 30 :  opv1_i [0 ] ? 31 : 32 ;
                `EXE_CLO_OP   : arith_res <= opv1_i_not [31] ? 0  : opv1_i_not [30] ? 1  : 
                                             opv1_i_not [29] ? 2  : opv1_i_not [28] ? 3  : 
                                             opv1_i_not [27] ? 4  : opv1_i_not [26] ? 5  : 
                                             opv1_i_not [25] ? 6  : opv1_i_not [24] ? 7  : 
                                             opv1_i_not [23] ? 8  : opv1_i_not [22] ? 9  : 
                                             opv1_i_not [21] ? 10 : opv1_i_not [20] ? 11 : 
                                             opv1_i_not [19] ? 12 : opv1_i_not [18] ? 13 : 
                                             opv1_i_not [17] ? 14 : opv1_i_not [16] ? 15 : 
                                             opv1_i_not [15] ? 16 : opv1_i_not [14] ? 17 : 
                                             opv1_i_not [13] ? 18 : opv1_i_not [12] ? 19 : 
                                             opv1_i_not [11] ? 20 : opv1_i_not [10] ? 21 : 
                                             opv1_i_not [9 ] ? 22 : opv1_i_not [8 ] ? 23 : 
                                             opv1_i_not [7 ] ? 24 : opv1_i_not [6 ] ? 25 : 
                                             opv1_i_not [5 ] ? 26 : opv1_i_not [4 ] ? 27 : 
                                             opv1_i_not [3 ] ? 28 : opv1_i_not [2 ] ? 29 : 
                                             opv1_i_not [1 ] ? 30 : opv1_i_not [0 ] ? 31 : 32 ;
                default: arith_res <= 0;
            endcase
        end
    end
    // overflow flag of add & substract operation
    wire  sum_overflow = ($signed(opv1_i) > 0 && $signed(opv2_i) > 0 && $signed(arith_res) < 0
                       || $signed(opv1_i) < 0 && $signed(opv2_i) < 0 && $signed(arith_res) > 0);



    // logical operation
    always @(*) begin
        if(rst == `RESET_ENABLE) begin
            logic_res <= `ZERO_WORD;
        end else begin 
            case (aluop_i)
                `EXE_OR_OP  : logic_res <= opv1_i | opv2_i;
                `EXE_AND_OP : logic_res <= opv1_i & opv2_i;
                `EXE_NOR_OP : logic_res <= ~(opv1_i | opv2_i);
                `EXE_XOR_OP : logic_res <= opv1_i ^ opv2_i;
                default     : logic_res <= `ZERO_WORD;
            endcase
        end
    end

    // shift operation
    always @(*) begin
        if(rst == `RESET_ENABLE) begin 
            shift_res <= `ZERO_WORD;
        end else begin
            case (aluop_i)
                `EXE_SLL_OP : shift_res <= opv2_i << opv1_i[4:0];
                `EXE_SRL_OP : shift_res <= opv2_i >> opv1_i[4:0];
                `EXE_SRA_OP : shift_res <= $signed(opv2_i) >>> opv1_i[4:0]; // shift right arithmetic >>>
                default     : shift_res <= `ZERO_WORD;
            endcase
        end
    end

    // move operation
    always @(*) begin
        if(rst == `RESET_ENABLE) begin
            move_res <= `ZERO_WORD;
        end else begin
            case (aluop_i)
                `EXE_MOVZ_OP : move_res <= opv1_i;
                `EXE_MOVN_OP : move_res <= opv1_i;
                `EXE_MFHI_OP : move_res <= HI    ;
                `EXE_MFLO_OP : move_res <= LO    ;
                default      : move_res <= `ZERO_WORD;
            endcase
        end
    end

    // handle the data-dependent hazard about HI & LO
    always @(*) begin
        if(rst == `RESET_ENABLE)  {HI,LO} <= {`ZERO_WORD, `ZERO_WORD};
        else if(mem_whilo_i) {HI,LO} <= {mem_hi_i,mem_lo_i};
        else if(wb_whilo_i)  {HI,LO} <= {wb_hi_i,wb_lo_i};
        else {HI,LO} <= {hi_i,lo_i};
    end

    // operations goning to write HI & LO (include moves & division & multipilcation)
    `define SET_HILO_OUT(i_whilo, i_hi, i_lo) if(1) begin \
        whilo_o <= i_whilo ; \
        hi_o    <= i_hi    ; \
        lo_o    <= i_lo    ; \
    end else if(0)
    always @(*) begin 
        if(rst == `RESET_ENABLE) begin
            `SET_HILO_OUT(0,0,0);
        end else begin 
            case (aluop_i)
                `EXE_MTHI_OP : `SET_HILO_OUT(1, opv1_i, LO);
                `EXE_MTLO_OP : `SET_HILO_OUT(1, HI, opv1_i);
                `EXE_MULT_OP : `SET_HILO_OUT(1, mul_res[63:32], mul_res[31:0]);
                `EXE_MULTU_OP: `SET_HILO_OUT(1, mul_res[63:32], mul_res[31:0]);
                `EXE_DIV_OP  : `SET_HILO_OUT(1, $signed(opv1_i) % $signed(opv2_i), $signed(opv1_i) / $signed(opv2_i));
                `EXE_DIVU_OP : `SET_HILO_OUT(1, opv1_i % opv2_i, opv1_i / opv2_i);
                default      : `SET_HILO_OUT(0,0,0);
            endcase
        end
    end
    `undef SET_HILO_OUT

    // select the final result
    always @(*) begin
        waddr_o   <=  waddr_i;
        we_o      <=  we_i;
        case (alusel_i)
            `EXE_RES_LOGIC:  wdata_o  <=  logic_res;
            `EXE_RES_SHIFT:  wdata_o  <=  shift_res;
            `EXE_RES_MOVE :  wdata_o  <=  move_res;
            `EXE_RES_MUL  :  wdata_o  <=  mul_res[31:0];
            `EXE_RES_ARITH:  begin
                we_o    <=  (aluop_i == `EXE_ADD_OP || aluop_i == `EXE_ADDI_OP || aluop_i == `EXE_SUB_OP) && sum_overflow == 1 ? 0 : we_i;
                wdata_o <=  arith_res;
            end
            `EXE_RES_JUMP_BRANCH: begin 
                wdata_o <= link_addr_i;
            end
            default       :  wdata_o  <=  `ZERO_WORD;
        endcase
    end

endmodule // ex
