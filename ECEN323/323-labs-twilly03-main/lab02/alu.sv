// This timescale statement indicates that each time tick of the simulator
// is 1 nanosecond and the simulator has a precision of 1 picosecond. This 
// is used for simulation and all of your SystemVerilog files should have 
// this statement at the top.
`timescale 1 ns / 1 ps

/***************************************************************************
*
* File: alu.sv
*
* Author: Thomas Williams
* Class: ECEN 323, Winter Semester 2024
*
* Module: ALU
*
* Description:
* For this exercise you will design an "Arithmetic Logic Unit" 
* (ALU) for a simplified version of the RISC-V processor. You 
* will use this ALU in your RISC-V processor in a later lab. 
* Your ALU will be designed to implement the following ALU 
* operations signed addition, signed subtraction, logical AND,
* logical OR, logical XOR, "Less Than" comparison, and three 
* different shift operations. We will talk about the ALU in 
* more detail when we discuss Chapter 4 of the textbook but 
* you are ready to create the ALU with the background you 
* have now.   
*
****************************************************************************/

module alu(op1, op2, alu_op, zero, result);
    `include "riscv_alu_constants.sv"
    //operand 1 and 2
    input wire logic [31:0] op1, op2;
    //Indicates which operation to perform
    input wire logic [3:0] alu_op;
    
    //Indicates when the ALU Result is zero
    output logic zero;
    //ALU Result
    output logic [31:0] result;
    
    // An ALU circuit that includes a multiplexer to select which of the functions to perform. A case statement within a always_comb block is the most convenient way to implement this multiplexer (you will be penalized if you do not use a case statement). 
    always_comb begin
        case(alu_op)
            ALUOP_AND:                 result = op1 & op2;
            
            ALUOP_OR:                  result = op1 | op2;
            
            ALUOP_Addition:            result = op1 + op2;
            
            ALUOP_Subtraction:         result = op1 - op2;
            
            ALUOP_LessThan:            result = $signed(op1) < $signed(op2);
            
            ALUOP_ShiftRightLogical:    result = op1 >> op2[4:0];
            
            ALUOP_ShiftLeftLogical:     result = op1 << op2[4:0];
            
            ALUOP_ShiftRightArithmetic: result = $unsigned($signed(op1) >>> op2[4:0]);
            
            ALUOP_XOR:                 result = op1 ^ op2;
            
            default:                    result = op1 + op2;     
      endcase
      zero = (result == 0);
   end
endmodule
