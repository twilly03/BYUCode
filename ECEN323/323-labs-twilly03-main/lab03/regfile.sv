// This timescale statement indicates that each time tick of the simulator
// is 1 nanosecond and the simulator has a precision of 1 picosecond. This 
// is used for simulation and all of your SystemVerilog files should have 
// this statement at the top.
`timescale 1 ns / 1 ps

/***************************************************************************
*
* File: calc.sv
*
* Author: Thomas Williams
* Class: ECEN 323, Winter Semester 2024
*
* Module: ALU
* In this exercise you will create a register file module that you will 
* use within another top-level module in this lab and for your RISC-V processor 
* in later labs of the course.
*
****************************************************************************/

module regfile(clk, readReg1, readReg2, writeReg, writeData, write, readData1, readData2);
input wire logic clk, write;
input wire logic [4:0] readReg1, readReg2, writeReg;
input wire logic [31:0] writeData;

output logic [31:0] readData1, readData2;

// Declare multi-dimensional logic array (32 words, 32 bits each)
logic [31:0] register[31:0];

integer i;
initial
  for (i=0;i<32;i=i+1)
    register[i] = 0;

always_ff@(posedge clk) begin
   readData1 <= register[readReg1];
   readData2 <= register[readReg2];
   if ((writeReg!=0)&&(write)) begin
     register[writeReg] <= writeData;
     if (readReg1 == writeReg)
         readData1 <= writeData;
     if (readReg2 == writeReg)
         readData2 <= writeData;
   end
end

endmodule
