// This timescale statement indicates that each time tick of the simulator
// is 1 nanosecond and the simulator has a precision of 1 picosecond. This 
// is used for simulation and all of your SystemVerilog files should have 
// this statement at the top.
`timescale 1 ns / 1 ps

/***************************************************************************
*
* File: riscv_alu_constants.sv
*
* Author: Thomas Williams
* Class: ECEN 323, Winter Semester 2024
*
*
****************************************************************************/

// ALU Constants for available ALU operations

localparam[3:0] ALUOP_AND = 4'b0000;
localparam[3:0] ALUOP_OR = 4'b0001;
localparam[3:0] ALUOP_Addition = 4'b0010;
localparam[3:0] ALUOP_Subtraction = 4'b0110;
localparam[3:0] ALUOP_LessThan = 4'b0111;
localparam[3:0] ALUOP_ShiftRightLogical = 4'b1000;
localparam[3:0] ALUOP_ShiftLeftLogical = 4'b1001;
localparam[3:0] ALUOP_ShiftRightArithmetic = 4'b1010;
localparam[3:0] ALUOP_XOR = 4'b1101;

