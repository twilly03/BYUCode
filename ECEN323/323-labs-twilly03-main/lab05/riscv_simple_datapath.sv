// This timescale statement indicates that each time tick of the simulator
// is 1 nanosecond and the simulator has a precision of 1 picosecond. This 
// is used for simulation and all of your SystemVerilog files should have 
// this statement at the top.
`timescale 1 ns / 1 ps

/***************************************************************************
*
* File: riscv_simple_datapath.sv
*
* Author: Thomas Williams
* Class: ECEN 323, Winter Semester 2024
*
* Module: riscv_simple_datapath
* In this exercise I will implement the datapath portion of the processor as 
* shown in the high-level diagram above and described in the textbook.
*
****************************************************************************/

module riscv_simple_datapath#(parameter INITIAL_PC = 32'h00400000)(clk, rst, instruction, PCSrc, ALUSrc, RegWrite, MemtoReg, ALUCtrl, loadPC, PC, Zero, dAddress, dWriteData, dReadData, WriteBackData);
`include "riscv_datapath_constants.sv"
input wire logic clk, rst, PCSrc, ALUSrc, RegWrite, MemtoReg, loadPC;
input wire logic [31:0] instruction, dReadData;
input wire logic [3:0] ALUCtrl;

output logic Zero;
output logic [31:0] PC, dAddress, dWriteData, WriteBackData;

//instruction format immmediate variables 
logic[31:0] IMM;
logic[31:0] I_IMM;
logic[31:0] S_IMM;
logic[31:0] B_IMM;

//register and alu variables
logic[31:0] readData1, op2_ALU, branch_offset, alu_r;
assign dAddress = alu_r;

//immidiate assingment logic
assign B_IMM = {{IMM_B_EXT_BITS{instruction[B_IMM_BIT_12]}}, instruction[B_IMM_BIT_12], instruction[B_IMM_BIT_11], instruction[B_IMM_UPPER_MSB:B_IMM_UPPER_LSB], instruction[B_IMM_LOWER_MSB:B_IMM_LOWER_LSB], 1'b0};
assign I_IMM = {{IMM_IS_EXT_BITS{instruction[I_IMM_MSB]}}, instruction[I_IMM_MSB:I_IMM_LSB]};
assign S_IMM = {{IMM_IS_EXT_BITS{instruction[S_IMM_UPPER_MSB]}}, instruction[S_IMM_UPPER_MSB:S_IMM_UPPER_LSB], instruction[S_IMM_LOWER_MSB:S_IMM_LOWER_LSB]};

//an always comb block used to decide which Immediate will be passed into the op2_ALU
always_comb begin
    case(instruction[OPCODE_MSB:OPCODE_LSB])
        I_OPCODE:
            IMM = I_IMM;
        S_OPCODE:
            IMM = S_IMM;
        B_OPCODE:
            IMM = B_IMM;
        LW_OPCODE:
            IMM = I_IMM;
        default:
            IMM = 100;
    endcase
end

//The ALUSrc control signal dictates which input to use (see Figure 4.11 for an explanation on what to do for this control signal). 
//Create a multiplexer that selects between these two signals and drives the op2 input of your ALU.
assign op2_ALU = (ALUSrc ? IMM : dWriteData);

//the branch offset references half-words meaning that the offset should be left shifted by 1
assign branch_offset = B_IMM;

//The value written into the register file is one of two values: the ALU result 
//for conventional arithmetic and logic instructions or the result of the memory read (dReadData)
assign WriteBackData = (MemtoReg ? dReadData : alu_r);

//a multiplexpr to control the PC When the pc signal is hight the pc should be updated at the next clock edge
//if alusrc is high we +4 to the Pc and when alusrc is low we pass the branch offset to pc
always_ff@(posedge clk) begin
  if(rst) PC <= INITIAL_PC;
  else if(loadPC) begin  
    PC <= ((PCSrc && Zero) ?  PC + branch_offset : PC + 4);
  end
end
  

//Regfile instansitation
regfile regfile_f(.clk(clk), .readReg1(instruction[RS1_MSB:RS1_LSB]), .readReg2(instruction[RSB_RS2_MSB:RSB_RS2_LSB]), .writeReg(instruction[RI_RD_MSB:RI_RD_LSB]), 
.writeData(WriteBackData), .write(RegWrite), .readData1(readData1), .readData2(dWriteData));

//ALU instansitation
alu alu_f(.op1(readData1), .op2(op2_ALU), .alu_op(ALUCtrl), .zero(Zero), .result(alu_r));

endmodule
