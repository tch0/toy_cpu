// date: 2018.4.27
// author: Tiko.T

// Open MIPS five-stage pipeline toy cpu
// Five stages:
// IF    instruction fetch
// ID    instruction decoder
// EX    execution
// MEM   memory
// WB    write back


// file: const.v
// role: global macro defiend here
// includes: enable & disable signals, all implemented instrctions, bus & width of wires
// notes: every file which uses these macros should include this file theoretically
// constant:  length of word -> 32 bits
//            length of instrction -> 32 bits
//            width of instruction memory -> 32 bits
//            width of data memory -> 32 bits

// attention : the OpenMIPS toy cpu use big end mode.
// which means for load & store instructions : high byte of data stores to low address of memory.


`ifndef  CONST_V_
`define  CONST_V_


/***************************************** global macro ******************************************/
`define  RESET_ENABLE         1'b1         
`define  RESET_DISABLE        1'b0         
`define  ZERO_WORD            32'h00000000 
`define  WRITE_ENABLE         1'b1         
`define  WRITE_DISABLE        1'b0         
`define  READ_ENABLE          1'b1         
`define  READ_DISABLE         1'b0         
`define  AluOpBus             7:0                  // bus of isntruction types
`define  AluSelBus            2:0                  // bus of instruction subtypes
`define  INST_VALID           1'b0
`define  INST_INVALID         1'b1
`define  TRUE                 1'b1
`define  FALSE                1'b0
`define  CHIP_ENABLE          1'b1
`define  CHIP_DISABLE         1'b0
`define  STOP                 1'b1                 // pipeline stop
`define  NOSTOP               1'b0                 // pipeline kepps runing
`define  BRANCH               1'b1                 // branch or not
`define  NOT_BRANCH           1'b0
`define  IN_DELAYSLOT         1'b1                 // instruction in the delay slot or not
`define  NOT_IN_DELAYSLOT     1'b0

/************************************* instrction-realated macro ************************************/
//======= op
`define  EXE_NOP              6'b000000            // nop
`define  EXE_ORI              6'b001101            // ori    ori rt,rs,immediate
`define  EXE_ANDI             6'b001100            // andi
`define  EXE_XORI             6'b001110            // xori
`define  EXE_LUI              6'b001111            // lui
`define  EXE_PREF             6'b110011            // prefetch
`define  EXE_SPECIAL_INST     6'b000000            // SPECIAL  type isntruction also R type
`define  EXE_SPECIAL2_INST    6'b011100            // SPECIAL2 type instruction also R type

`define  EXE_J                6'b000010
`define  EXE_JAL              6'b000011
`define  EXE_BEQ              6'b000100
`define  EXE_BGTZ             6'b000111
`define  EXE_BLEZ             6'b000110
`define  EXE_BNE              6'b000101

`define  EXE_REGIMM           6'b000001            // jump instrution, use rt to judge which type
// === rt (op = `EXE_REGIMM)
`define  EXE_BGEZ             5'b00001
`define  EXE_BGEZAL           5'b10001
`define  EXE_BLTZ             5'b00000
`define  EXE_BLTZAL           5'b10000

`define  EXE_LB               6'b100000            // load byte
`define  EXE_LBU              6'b100100            // load unsigned byte
`define  EXE_LH               6'b100001            // load half word (2 bytes), requires alignment (offset end with 0)
`define  EXE_LHU              6'b100101            // load unsigned half word
`define  EXE_LW               6'b100011            // load word (4 bytes), requires alignment (offset end with 00)
`define  EXE_LWL              6'b100010            // load bytes from address to the right end of the word to the left  end of register
`define  EXE_LWR              6'b100110            // load bytes from address to the left  end of the word to the right end of register
`define  EXE_SB               6'b101000            // store byte
`define  EXE_SH               6'b101001            // store half word
`define  EXE_SW               6'b101011            // store word
`define  EXE_SWL              6'b101010            // on the opposite of lwl
`define  EXE_SWR              6'b101110            // on the opposite of lwr
`define  EXE_LL               6'b110000            // load and link
`define  EXE_SC               6'b111000            // store and 



//======= funct
`define  EXE_AND              6'b100100            // and 
`define  EXE_OR               6'b100101            // or  
`define  EXE_XOR              6'b100110            // xor  exclusive or
`define  EXE_NOR              6'b100111            // nor  not or

`define  EXE_SLL              6'b000000            // sll    shift left logical immediate
`define  EXE_SLLV             6'b000100            // sllv   shift left logical
`define  EXE_SRL              6'b000010            // srl    shift right logical immediate
`define  EXE_SRLV             6'b000110            // srlv   shift right logical
`define  EXE_SRA              6'b000011            // sra    shift right arithmetic immediate
`define  EXE_SRAV             6'b000111            // srav   shift right arithmetic

`define  EXE_SYNC             6'b001111            // sync

`define  EXE_MOVZ             6'b001010            // novn rd,rs,rt if(rt==0) rd = rs
`define  EXE_MOVN             6'b001011            // novn rd,rs,rt if(rt!=0) rd = rs
`define  EXE_MFHI             6'b010000
`define  EXE_MTHI             6'b010001
`define  EXE_MFLO             6'b010010
`define  EXE_MTLO             6'b010011

`define  EXE_SLT              6'b101010            // set on less than
`define  EXE_SLTU             6'b101011            // set on less than unsigned
`define  EXE_SLTI             6'b001010
`define  EXE_SLTIU            6'b001011
`define  EXE_ADD              6'b100000
`define  EXE_ADDU             6'b100001
`define  EXE_SUB              6'b100010
`define  EXE_SUBU             6'b100011
`define  EXE_ADDI             6'b001000
`define  EXE_ADDIU            6'b001001
`define  EXE_CLZ              6'b100000            // count leading zeros
`define  EXE_CLO              6'b100001            // count leading ones

`define  EXE_MULT             6'b011000
`define  EXE_MULTU            6'b011001
`define  EXE_MUL              6'b000010
`define  EXE_DIV              6'b011010
`define  EXE_DIVU             6'b011011

`define  EXE_JR               6'b001000
`define  EXE_JALR             6'b001001            // jump and link register




//====== ALUSEL ==== types of instructions
`define  EXE_RES_NOP          3'b000
`define  EXE_RES_LOGIC        3'b001
`define  EXE_RES_SHIFT        3'b010
`define  EXE_RES_MOVE         3'b011
`define  EXE_RES_ARITH        3'b100
`define  EXE_RES_MUL          3'b101
`define  EXE_RES_JUMP_BRANCH  3'b110
`define  EXE_RES_LOAD_STORE   3'b111


//====== ALUOP ==== subtype of instrutions
`define  EXE_AND_OP    8'b00100100
`define  EXE_OR_OP     8'b00100101
`define  EXE_XOR_OP    8'b00100110
`define  EXE_NOR_OP    8'b00100111
`define  EXE_NOP_OP    8'b00000000

`define  EXE_SLL_OP    8'b01111100
`define  EXE_SLLV_OP   8'b00000100
`define  EXE_SRL_OP    8'b00000010
`define  EXE_SRLV_OP   8'b00000110
`define  EXE_SRA_OP    8'b00000011
`define  EXE_SRAV_OP   8'b00000111

`define  EXE_MOVZ_OP   8'b00001010
`define  EXE_MOVN_OP   8'b00001011
`define  EXE_MFHI_OP   8'b00010000
`define  EXE_MTHI_OP   8'b00010001
`define  EXE_MFLO_OP   8'b00010010
`define  EXE_MTLO_OP   8'b00010011

`define  EXE_SLT_OP    8'b00101010
`define  EXE_SLTU_OP   8'b00101011
`define  EXE_SLTI_OP   8'b01010111
`define  EXE_SLTIU_OP  8'b01011000
`define  EXE_ADD_OP    8'b00100000
`define  EXE_ADDU_OP   8'b00100001
`define  EXE_SUB_OP    8'b00100010
`define  EXE_SUBU_OP   8'b00100011
`define  EXE_ADDI_OP   8'b01010101
`define  EXE_ADDIU_OP  8'b01010110
`define  EXE_CLZ_OP    8'b10110000
`define  EXE_CLO_OP    8'b10110001

`define  EXE_MULT_OP   8'b00011000
`define  EXE_MULTU_OP  8'b00011001
`define  EXE_MUL_OP    8'b10101001
`define  EXE_DIV_OP    8'b00011010
`define  EXE_DIVU_OP   8'b00011011

`define  EXE_J_OP      8'b01001111
`define  EXE_JAL_OP    8'b01010000
`define  EXE_JALR_OP   8'b00001001
`define  EXE_JR_OP     8'b00001000
`define  EXE_BEQ_OP    8'b01010001
`define  EXE_BGEZ_OP   8'b01000001
`define  EXE_BGEZAL_OP 8'b01001011
`define  EXE_BGTZ_OP   8'b01010100
`define  EXE_BLEZ_OP   8'b01010011
`define  EXE_BLTZ_OP   8'b01000000
`define  EXE_BLTZAL_OP 8'b01001010
`define  EXE_BNE_OP    8'b01010010

`define  EXE_LB_OP     8'b11100000
`define  EXE_LBU_OP    8'b11100100
`define  EXE_LH_OP     8'b11100001
`define  EXE_LHU_OP    8'b11100101
`define  EXE_LL_OP     8'b11110000
`define  EXE_LW_OP     8'b11100011
`define  EXE_LWL_OP    8'b11100010
`define  EXE_LWR_OP    8'b11100110
`define  EXE_SB_OP     8'b11101000
`define  EXE_SC_OP     8'b11111000
`define  EXE_SH_OP     8'b11101001
`define  EXE_SW_OP     8'b11101011
`define  EXE_SWL_OP    8'b11101010
`define  EXE_SWR_OP    8'b11101110


/********************************* ROM-related macro ***********************************/
`define  InstAddrBus          31:0                  // Rom address bus
`define  InstBus              31:0                  // Rom data bus
`define  InstMemNum           1024                  // Rom real size 128KB
`define  InstMemNumLog2       10                    // Rom real address bus 10 bit


/******************************* regfile-related macro *********************************/
`define  RegAddrBus           4:0                   // module regfile address bus
`define  RegBus               31:0                  // module regfile data bus
`define  RegWidth             32                    // gengeric regsiter width
`define  DoubleRegWidth       64                    // double generic register width to keep results of multiplication
`define  DoubleRegBus         63:0                  // double generic register bus 
`define  RegNum               32                    // number of register
`define  RegNumLog2           5                     // register address width
`define  NOPRegAddr           5'b00000              // NO.0 register ($0/$zero) constant 0

// stallbus
`define  StallBus             5:0

/************************** data RAM raleated macro *******************************8*****/
`define  DataBus              31:0
`define  DataAddrBus          31:0
`define  DataMemNum           1024  // 16384
`define  DataMemNumLog2       10
`define  ByteWidth            7:0                   // width of one byte

`endif


