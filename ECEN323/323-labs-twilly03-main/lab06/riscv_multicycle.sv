// This timescale statement indicates that each time tick of the simulator
// is 1 nanosecond and the simulator has a precision of 1 picosecond. This 
// is used for simulation and all of your SystemVerilog files should have 
// this statement at the top.
`timescale 1 ns / 1 ps

/***************************************************************************
*
* File: riscv_multicycle.sv
*
* Author: Thomas Williams
* Class: ECEN 323, Winter Semester 2024
*
* Module: riscv_multicycle
* In this exercise I will implement implement the basic RISC-V processor as described in the textbook
*
****************************************************************************/

module riscv_multicycle#(parameter INITIAL_PC = 32'h00400000)(clk, rst, instruction, dReadData, PC, dAddress, dWriteData, MemRead, MemWrite, WriteBackData);
`include "riscv_datapath_constants.sv"
`include "riscv_alu_constants.sv" //need to include second constants file?

input wire logic clk, rst;
input wire logic[31:0] instruction, dReadData;

output logic MemRead, MemWrite;
output logic[31:0] PC, dAddress, dWriteData, WriteBackData;

//datapath signals
logic PCSrc, ALUSrc, RegWrite, MemtoReg, loadPC, Zero;
logic[3:0] ALUCtrl;

//assign statement for ALUSrc only high when the instruction is not R or B
assign ALUSrc = (((instruction[OPCODE_MSB:OPCODE_LSB] == R_OPCODE)||(instruction[OPCODE_MSB:OPCODE_LSB] == B_OPCODE)) ? 0 : 1);

//assign statement for PCSrc sets high only when its a branch and zero is high
assign PCSrc = (((instruction[OPCODE_MSB:OPCODE_LSB] == B_OPCODE)&&(Zero)) ? 1 : 0);//This signal should be set to '1' when (1) current instruction is a "BEQ" function, and (2) the Zero flag is high.

//assign statement for MemtoReg only high when load word is high
assign MemtoReg = ((instruction[OPCODE_MSB:OPCODE_LSB] == LW_OPCODE) ? 1 : 0);//only true if load

//assign ALUCtrl = assigning based on opcode, func3, func7 using lab 2 alu_op input
always_comb begin
    case(instruction[OPCODE_MSB:OPCODE_LSB])
    
        //R_OPCODE block spnanning all alu_op functions
        R_OPCODE:
            if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_ADD_SUB_FUNC3) begin
                if(instruction[R_FUNCT7_MSB:R_FUNCT7_LSB] == R_FUNCT7_FIRST)  
                    ALUCtrl = ALUOP_Addition;
                else 
                    ALUCtrl = ALUOP_Subtraction;
            end
            
            else if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_XOR_FUNC3)
                ALUCtrl =  ALUOP_XOR;
                
            else if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_OR_FUNC3)
                ALUCtrl = ALUOP_OR;
                
            else if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_AND_FUNC3)
                ALUCtrl = ALUOP_AND;
                
            else if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_SLL_FUNC3)
                ALUCtrl = ALUOP_ShiftLeftLogical;
                
            else if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_SRL_SRA_FUNC3) begin
                if(instruction[R_FUNCT7_MSB:R_FUNCT7_LSB] == R_FUNCT7_FIRST)  
                    ALUCtrl = ALUOP_ShiftRightLogical;
                else 
                    ALUCtrl = ALUOP_ShiftRightArithmetic;
            end
                   
            else ALUCtrl = ALUOP_LessThan;
            
        //I_OPCODE block spnanning all alu_op functions except for subtraction
        I_OPCODE:
            if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_ADD_SUB_FUNC3)
                ALUCtrl = ALUOP_Addition;
                
            else if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_XOR_FUNC3)
                ALUCtrl =  ALUOP_XOR;
                
            else if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_OR_FUNC3)
                ALUCtrl = ALUOP_OR;
                
            else if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_AND_FUNC3)
                ALUCtrl = ALUOP_AND;
                
            else if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_SLL_FUNC3)
                ALUCtrl = ALUOP_ShiftLeftLogical;
                
            else if(instruction[FUNCT3_MSB:FUNCT3_LSB] == R_SRL_SRA_FUNC3) begin
                if(instruction[R_FUNCT7_MSB:R_FUNCT7_LSB] == R_FUNCT7_FIRST)  
                    ALUCtrl = ALUOP_ShiftRightLogical;
                else 
                    ALUCtrl = ALUOP_ShiftRightArithmetic;
            end
                   
            else ALUCtrl = ALUOP_LessThan;
        
        //S_OPCODE block, only includes addition    
        S_OPCODE:
            ALUCtrl = ALUOP_Addition;
        
        //B_OPCODE block, only includes subtraction       
        B_OPCODE:
            ALUCtrl = ALUOP_Subtraction;
            
        //LW_OPCODE block, only includes addition       
        LW_OPCODE:
            ALUCtrl = ALUOP_Addition;
        
        //default case that sets ALUCtrl to zero    
        default:
            ALUCtrl = 0;
            
    endcase
end

// Define the states of the state machine
enum logic [2:0] {IF_STATE, ID_STATE, EX_STATE, MEM_STATE, WB_STATE} State;

// Declare the current state and next state registers
logic [2:0] currState, nextState;

// Define the state transitions
always_ff @(posedge clk, posedge rst) begin
  if (rst) begin
    currState <= IF_STATE;
  end else begin
    currState <= nextState;
  end
end

//state transition state machine
always_comb begin
  case (currState)
  
    //IF state of the state transisiton state machine
    IF_STATE: begin
        nextState = ID_STATE;
      end
      
    //ID state of the state transisiton state machine
    ID_STATE: begin
        nextState = EX_STATE;
    end
    
    //EX state of the state transisiton state machine
    EX_STATE: begin
        nextState = MEM_STATE;
    end
    
    //MEM state of the state transisiton state machine
    MEM_STATE: begin
        nextState = WB_STATE;
    end
    
    //WB state of the state transisiton state machine
    WB_STATE: begin
        nextState = IF_STATE;
    end
    
    //default case of the state transition state machine, set to IF state
    default:
        nextState = IF_STATE;
  endcase
end

//output state machine
always_comb begin
  case (currState)
    
    //Outputs of the IF state, all zero
    IF_STATE: begin
       RegWrite = 0;
       loadPC = 0;
       MemRead = 0;
       MemWrite = 0;
    end
    
    //Outputs of the ID state, all zero
    ID_STATE: begin
       RegWrite = 0;
       loadPC = 0;
       MemRead = 0;
       MemWrite = 0;
    end
    
    //Outputs of the EX state, all zero
    EX_STATE: begin
       RegWrite = 0;
       loadPC = 0;
       MemRead = 0;
       MemWrite = 0;
    end
    
    //Outputs of the MEM state, REgWrite and loadPC are zero, 
    //MemRead and MemWrite only turn on if load or store word respectivley
    MEM_STATE: begin
       RegWrite = 0;
       loadPC = 0;
       MemRead = ((instruction[OPCODE_MSB:OPCODE_LSB] == LW_OPCODE) ? 1 : 0); //only if load word 
       MemWrite = ((instruction[OPCODE_MSB:OPCODE_LSB] == S_OPCODE) ? 1 : 0);//only if store word 
    end
    
    //Outputs of the WB state, MemRead and MemWrite are zero
    // RegWrite is high if instruction is not B or S and load PC is always high
    WB_STATE: begin
       RegWrite = (!((instruction[OPCODE_MSB:OPCODE_LSB] == B_OPCODE) || (instruction[OPCODE_MSB:OPCODE_LSB] == S_OPCODE))) ? 1 : 0; //RegWrite' should only be set to '1' during the 'WB' state of the instruction state machine
       loadPC = 1; //only in write back state
       MemRead = 0;
       MemWrite = 0;
    end
    
    //Default Outputs of the state machine, all zero
    default: begin
       RegWrite = 0;
       loadPC = 0;
       MemRead = 0;
       MemWrite = 0;
    end
  endcase
end

//datapath instance for the multicycle
 riscv_simple_datapath #(.INITIAL_PC(INITIAL_PC)) datapath(.clk(clk), .rst(rst), .instruction(instruction), .PCSrc(PCSrc), .ALUSrc(ALUSrc), 
.RegWrite(RegWrite), .MemtoReg(MemtoReg), .ALUCtrl(ALUCtrl), .loadPC(loadPC), .PC(PC), .Zero(Zero), .dAddress(dAddress), 
.dWriteData(dWriteData), .dReadData(dReadData), .WriteBackData(WriteBackData));
endmodule
