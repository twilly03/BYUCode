// This timescale statement indicates that each time tick of the simulator
// is 1 nanosecond and the simulator has a precision of 1 picosecond. This 
// is used for simulation and all of your SystemVerilog files should have 
// this statement at the top.
`timescale 1 ns / 1 ps

/***************************************************************************
*
* File: riscv_basic_pipeline.sv
*
* Author: Thomas Williams
* Class: ECEN 323, Winter Semester 2024
*
* Module: riscv_basic_pipeline
* In this exercise I will implement implement the basic RISC-V processor as described in the textbook
*
****************************************************************************/

module riscv_basic_pipeline#(parameter INITIAL_PC = 32'h00400000)(clk, rst, instruction, ALUResult, dReadData, PC, dAddress, dWriteData, MemRead, MemWrite, WriteBackData);
`include "riscv_datapath_constants.sv"
`include "riscv_alu_constants.sv" 

input wire logic clk, rst;
input wire logic[31:0] instruction, dReadData;

output logic MemRead, MemWrite;
output logic[31:0] PC, ALUResult, dAddress, dWriteData, WriteBackData;

//IF variables
logic[31:0] if_PC;

//ID variables
logic[31:0] id_PC, id_IMM, I_IMM, B_IMM, S_IMM;
logic[4:0] id_writeReg;
logic[3:0] id_ALUCtrl;
logic id_ALUSrc, id_MemWrite, id_MemRead, id_PCSrc, id_RegWrite, id_MemtoReg;

//EX variables
logic ex_ALUSrc, ex_MemWrite, ex_MemRead, ex_PCSrc, ex_RegWrite, ex_MemtoReg, ex_Zero;
logic[31:0] ex_PC, ex_IMM, ex_readData1, ex_readData2, ex_op2, ex_alu_r, ex_target_address;
logic[4:0] ex_writeReg;
logic[3:0] ex_ALUCtrl;

//MEM variables
logic[31:0] mem_dWriteData, mem_alu_r, mem_target_address, mem_readData2;
logic[4:0] mem_writeReg;
logic mem_MemRead, mem_MemWrite, mem_PCSrc, mem_RegWrite, mem_MemtoReg, mem_Zero, mem_Branch, PCSrc;

//WB variables
logic[31:0] wb_dReadData, wb_alu_r, wb_writeData;
logic[4:0] wb_writeReg;
logic wb_RegWrite, wb_MemtoReg;

//////////////////////////////////////////////////////////////////////
// IF: Instruction Fetch
//////////////////////////////////////////////////////////////////////
//Top Level Port
assign PC = if_PC;

always_ff@(posedge clk) begin
    if(rst) begin
        if_PC <= INITIAL_PC;
    end
    else if(PCSrc) begin
        if_PC <= mem_target_address; // Branch Target TODO IS THIS CORRECT???
    end 
    else begin
        if_PC <= if_PC + 4;
    end
end

//Pipline Signals
always_ff@(posedge clk) begin
    if(rst) begin
        id_PC <= INITIAL_PC;
    end
    else begin
        id_PC <= if_PC;
    end
end

//////////////////////////////////////////////////////////////////////
// ID: Instruction Decode
//////////////////////////////////////////////////////////////////////
//assign logic for id_writeReg
assign id_writeReg = instruction[RI_RD_MSB:RI_RD_LSB];

//immidiate assingment logic
assign B_IMM = {{IMM_B_EXT_BITS{instruction[B_IMM_BIT_12]}}, instruction[B_IMM_BIT_12], instruction[B_IMM_BIT_11], instruction[B_IMM_UPPER_MSB:B_IMM_UPPER_LSB], instruction[B_IMM_LOWER_MSB:B_IMM_LOWER_LSB], 1'b0};
assign I_IMM = {{IMM_IS_EXT_BITS{instruction[I_IMM_MSB]}}, instruction[I_IMM_MSB:I_IMM_LSB]};
assign S_IMM = {{IMM_IS_EXT_BITS{instruction[S_IMM_UPPER_MSB]}}, instruction[S_IMM_UPPER_MSB:S_IMM_UPPER_LSB], instruction[S_IMM_LOWER_MSB:S_IMM_LOWER_LSB]};
//an always comb block used to decide which Immediate will be passed into the op2_ALU
always_comb begin
    case(instruction[OPCODE_MSB:OPCODE_LSB])
        I_OPCODE:
            id_IMM = I_IMM;
        S_OPCODE:
            id_IMM = S_IMM;
        B_OPCODE:
            id_IMM = B_IMM;
        LW_OPCODE:
            id_IMM = I_IMM;
        default:
            id_IMM = 100;
    endcase
end

//assign statement for id_ALUSrc only high when the instruction is not R or B
assign id_ALUSrc = (((instruction[OPCODE_MSB:OPCODE_LSB] == R_OPCODE)||(instruction[OPCODE_MSB:OPCODE_LSB] == B_OPCODE)) ? 0 : 1);

//TODO I USED mem_Zero HERE is this correct???
//assign statement for id_PCSrc sets high only when its a branch and zero is high
assign id_PCSrc = ((instruction[OPCODE_MSB:OPCODE_LSB] == B_OPCODE));//This signal should be set to '1' when (1) current instruction is a "BEQ" function, and (2) the Zero flag is high.

//assign statement for id_MemtoReg only high when load word is high
assign id_MemtoReg = ((instruction[OPCODE_MSB:OPCODE_LSB] == LW_OPCODE) ? 1 : 0);//only true if load

//assign statement for id_MemRead only high when load word is high
assign id_MemRead = ((instruction[OPCODE_MSB:OPCODE_LSB] == LW_OPCODE) ? 1 : 0); //only if load word 

//assign statement for id_MemWrite only when storw word is high
assign id_MemWrite = ((instruction[OPCODE_MSB:OPCODE_LSB] == S_OPCODE) ? 1 : 0);//only if store word 

//RegWrite' should only be set to '1' if the instruction is not B or S
assign id_RegWrite = ((!((instruction[OPCODE_MSB:OPCODE_LSB] == B_OPCODE) || (instruction[OPCODE_MSB:OPCODE_LSB] == S_OPCODE))) ? 1 : 0); 

//assign id_ALUCtrl = assigning based on opcode, func3, func7 using lab 2 alu_op input
always_comb begin
    case(instruction[OPCODE_MSB:OPCODE_LSB])
    
        //R_OPCODE block spnanning all alu_op functions
        R_OPCODE:
            if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_ADD_SUB_FUNC3) begin
                if(instruction[R_FUNCT7_MSB:R_FUNCT7_LSB] == R_FUNCT7_FIRST)  
                    id_ALUCtrl = ALUOP_Addition;
                else 
                    id_ALUCtrl = ALUOP_Subtraction;
            end
            
            else if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_XOR_FUNC3)
                id_ALUCtrl =  ALUOP_XOR;
                
            else if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_OR_FUNC3)
                id_ALUCtrl = ALUOP_OR;
                
            else if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_AND_FUNC3)
                id_ALUCtrl = ALUOP_AND;
                
            else if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_SLL_FUNC3)
                id_ALUCtrl = ALUOP_ShiftLeftLogical;
                
            else if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_SRL_SRA_FUNC3) begin
                if(instruction[R_FUNCT7_MSB:R_FUNCT7_LSB] == R_FUNCT7_FIRST)  
                    id_ALUCtrl = ALUOP_ShiftRightLogical;
                else 
                    id_ALUCtrl = ALUOP_ShiftRightArithmetic;
            end
                   
            else id_ALUCtrl = ALUOP_LessThan;
            
        //I_OPCODE block spnanning all alu_op functions except for subtraction
        I_OPCODE:
            if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_ADD_SUB_FUNC3)
                id_ALUCtrl = ALUOP_Addition;
                
            else if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_XOR_FUNC3)
                id_ALUCtrl =  ALUOP_XOR;
                
            else if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_OR_FUNC3)
                id_ALUCtrl = ALUOP_OR;
                
            else if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_AND_FUNC3)
                id_ALUCtrl = ALUOP_AND;
                
            else if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_SLL_FUNC3)
                id_ALUCtrl = ALUOP_ShiftLeftLogical;
                
            else if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_SRL_SRA_FUNC3) begin
                if(instruction[R_FUNCT7_MSB:R_FUNCT7_LSB] == R_FUNCT7_FIRST)  
                    id_ALUCtrl = ALUOP_ShiftRightLogical;
                else 
                    id_ALUCtrl = ALUOP_ShiftRightArithmetic;
            end
                   
            else id_ALUCtrl = ALUOP_LessThan;
        
        //S_OPCODE block, only includes addition    
        S_OPCODE:
            id_ALUCtrl = ALUOP_Addition;
        
        //B_OPCODE block, only includes subtraction       
        B_OPCODE:
            id_ALUCtrl = ALUOP_Subtraction;
            
        //LW_OPCODE block, only includes addition       
        LW_OPCODE:
            id_ALUCtrl = ALUOP_Addition;
        
        //default case that sets id_ALUCtrl to zero    
        default:
            id_ALUCtrl = 0;
            
    endcase
end

//Pipline Signals
always_ff@(posedge clk) begin
    if(rst) begin
        ex_PC <= id_PC;
        ex_ALUSrc <= 0;
        ex_MemWrite <= 0;
        ex_MemRead <= 0; 
        ex_PCSrc <= 0; 
        ex_RegWrite <= 0; 
        ex_MemtoReg <= 0;
        ex_ALUCtrl <= 0;
        ex_IMM <= 0;
        ex_writeReg <= 0;
    end 
    else begin
        ex_PC <= id_PC;
        ex_ALUSrc <= id_ALUSrc;
        ex_MemWrite <= id_MemWrite;
        ex_MemRead <= id_MemRead; 
        ex_PCSrc <= id_PCSrc; //really is branch???
        ex_RegWrite <= id_RegWrite; 
        ex_MemtoReg <= id_MemtoReg;
        ex_ALUCtrl <= id_ALUCtrl;
        ex_IMM <= id_IMM; 
        ex_writeReg <= id_writeReg;
    end
end

//////////////////////////////////////////////////////////////////////
// EX: Execute
//////////////////////////////////////////////////////////////////////
//Top Level Ports
assign ALUResult = ex_alu_r;

//The pipelined 'ALUSrc' signal is used to determine whether the second register output or the immediate data is used for the second operand of the ALU.
assign ex_op2 = (ex_ALUSrc ? ex_IMM : ex_readData2);
//adding the pipelined 'PC' signal in the EX stage with the pipelined immediate branch offset
assign ex_target_address = ex_PC + ex_IMM;

//Pipline signals
always_ff@(posedge clk) begin
    if(rst) begin
        mem_writeReg <= 0;
        mem_alu_r <= 0;
        mem_Zero <= 0;
        mem_target_address <= 0;
        mem_PCSrc <= 0;
        mem_MemWrite <= 0;
        mem_MemRead <= 0;
        mem_MemtoReg <= 0;
        mem_RegWrite <= 0;
        mem_readData2 <= 0;
    end 
    else begin
        mem_writeReg <= ex_writeReg;
        mem_alu_r <= ex_alu_r;
        mem_Zero <= ex_Zero;
        mem_target_address <= ex_target_address;
        mem_PCSrc <= ex_PCSrc;
        mem_MemWrite <= ex_MemWrite;
        mem_MemRead <= ex_MemRead;
        mem_MemtoReg <= ex_MemtoReg;
        mem_RegWrite <= ex_RegWrite;
        mem_readData2 <= ex_readData2;
    end
end

//////////////////////////////////////////////////////////////////////
// MEM: Memory Access
//////////////////////////////////////////////////////////////////////
//Memory control signals
//assign wb_dReadData = dReadData;
assign dWriteData = mem_readData2;
assign MemRead = mem_MemRead;
assign MemWrite = mem_MemWrite;
assign dAddress = mem_alu_r;

//Branch Signal
assign PCSrc = (mem_PCSrc && mem_Zero ? 1 : 0);  // TODO ALREADY HAD A PCSrc ??? WHY NEW ONE

//Pipeline signals
always_ff@(posedge clk) begin
    if(rst) begin
        wb_alu_r <= 0;
        wb_MemtoReg <= 0;
        wb_writeReg <= 0;
        wb_RegWrite <= 0;
    end 
    else begin
        wb_alu_r <= mem_alu_r;
        wb_MemtoReg <= mem_MemtoReg;
        wb_writeReg <= mem_writeReg;
        wb_RegWrite <= mem_RegWrite;
    end 
 end

//////////////////////////////////////////////////////////////////////
// WB: Write Back
//////////////////////////////////////////////////////////////////////
//Top Level Ports
assign wb_writeData = (wb_MemtoReg ? dReadData : wb_alu_r); 
assign WriteBackData = wb_writeData;

        
//Regfile instansitation
regfile regfile_f(.clk(clk), .readReg1(instruction[RS1_MSB:RS1_LSB]), .readReg2(instruction[RSB_RS2_MSB:RSB_RS2_LSB]), .writeReg(wb_writeReg), 
.writeData(wb_writeData), .write(wb_RegWrite), .readData1(ex_readData1), .readData2(ex_readData2));

//ALU instansitation
alu alu_f(.op1(ex_readData1), .op2(ex_op2), .alu_op(ex_ALUCtrl), .zero(ex_Zero), .result(ex_alu_r));
endmodule
