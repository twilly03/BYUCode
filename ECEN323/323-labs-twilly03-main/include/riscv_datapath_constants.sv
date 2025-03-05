// This timescale statement indicates that each time tick of the simulator
// is 1 nanosecond and the simulator has a precision of 1 picosecond. This 
// is used for simulation and all of your SystemVerilog files should have 
// this statement at the top.
`timescale 1 ns / 1 ps

/***************************************************************************
*
* File: riscv_datapath_constants.sv
*
* Author: Thomas Williams
* Class: ECEN 323, Winter Semester 2024
*
* Module: riscv_datapath_constants
* While creating your datapath module you will need to declare a number 
* of constants related to decoding RISC-V instructions. You will use 
* these constants throughout your code and will likely use these constants 
* in the next lab.
*
****************************************************************************/
//opcode msb and lsb
localparam OPCODE_MSB = 6;
localparam OPCODE_LSB = 0;

//opcode bits
localparam[6:0] R_OPCODE = 7'b0110011;
localparam[6:0] I_OPCODE = 7'b0010011;
localparam[6:0] S_OPCODE = 7'b0100011;
localparam[6:0] B_OPCODE = 7'b1100011; 
localparam[6:0] LW_OPCODE = 7'b0000011;
localparam[6:0] JAL_OPCODE = 7'b1101111;
localparam[6:0] JALR_OPCODE = 7'b1100111;
localparam[6:0] LUI_OPCODE = 7'b0110111;

//bit extended constants
localparam IMM_IS_EXT_BITS = 20;
localparam IMM_B_EXT_BITS = 19;
localparam IMM_U_EXT_BITS = 12;
localparam IMM_J_EXT_BITS = 12;

//R and I msb and lsb
localparam RI_RD_MSB = 11;
localparam RI_RD_LSB = 7;

//S imm[4:0] bits
localparam S_IMM_LOWER_LSB = 7;
localparam S_IMM_LOWER_MSB = 11;

//B imm[4:1|11] bits
localparam B_IMM_BIT_11 = 7;
localparam B_IMM_LOWER_LSB = 8;
localparam B_IMM_LOWER_MSB = 11;

//funct3 msb and lsb
localparam FUNCT3_MSB = 14;
localparam FUNCT3_LSB = 12;

//rs1 msb and lsb
localparam RS1_MSB = 19;
localparam RS1_LSB = 15;

//R and S and B rs2 msb and lsb
localparam RSB_RS2_MSB = 24;
localparam RSB_RS2_LSB = 20;

//R funct 7 msb and lsb 
localparam R_FUNCT7_MSB = 31;
localparam R_FUNCT7_LSB = 25;

//I imm[11:0] msb and lsb
localparam I_IMM_LSB = 20;
localparam I_IMM_MSB = 31;

//S imm[11:5] msb and lsb
localparam S_IMM_UPPER_LSB = 25;
localparam S_IMM_UPPER_MSB = 31;

//B imm[12|10:5] msb and lsb
localparam B_IMM_BIT_12 = 31;
localparam B_IMM_UPPER_LSB = 25;
localparam B_IMM_UPPER_MSB = 30;

//U imm[31:12]
localparam U_IMM_MSB = 31;
localparam U_IMM_LSB = 12;

//J imm[20|10:1|11|19:12]
localparam J_IMM_BIT_20 = 31;
localparam J_IMM_LOWER_MSB = 30;
localparam J_IMM_LOWER_LSB = 21;
localparam J_IMM_BIT_11 = 20;
localparam J_IMM_UPPER_MSB = 20;
localparam J_IMM_UPPER_LSB = 12;


//r funct3 bits
localparam R_ADD_SUB_FUNC3 = 3'b000;
//localparam R_SUB_FUNC3 = 0;    //potentially delete this?
localparam R_XOR_FUNC3 = 3'b100;
localparam R_OR_FUNC3 = 3'b110;
localparam R_AND_FUNC3 = 3'b111;
localparam R_SLL_FUNC3 = 3'b001;
localparam R_SRL_SRA_FUNC3 = 3'b101;
//localparam R_SRA_FUNC3 = 5;      //potentially delete this?
localparam R_SLT_FUNC3 = 3'b010;
localparam R_SLTU_FUNC3 = 3'b011;

//b funct3 bits
localparam R_BEQ_FUNCT3 = 3'b000;
localparam R_BNE_FUNCT3 = 3'b001;
localparam R_BLT_FUNCT3 = 3'b100;
localparam R_BGE_FUNCT3 = 3'b101;

localparam R_FUNCT7_FIRST = 0;
localparam R_FUNCT7_SECOND = 7'b0100000; //do i even need this?

//s funct3 bits
localparam S_FUNC3_SB = 3'b000;
localparam S_FUNC3_SH = 3'b001;
localparam S_FUNC3_SW = 3'b010;
