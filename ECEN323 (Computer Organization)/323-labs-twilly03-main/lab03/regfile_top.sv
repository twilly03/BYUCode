// This timescale statement indicates that each time tick of the simulator
// is 1 nanosecond and the simulator has a precision of 1 picosecond. This 
// is used for simulation and all of your SystemVerilog files should have 
// this statement at the top.
`timescale 1 ns / 1 ps

/***************************************************************************
*
* File: regfile_top.sv
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

module regfile_top(clk, btnc, btnl, btnu, btnd, sw, led);
//`include "riscv_alu_constants.sv"
input wire logic clk, btnc, btnl, btnu, btnd;
input wire logic [15:0] sw;

output logic [15:0] led;

//the three ports of the register file
logic [4:0] readReg1, readReg2, writeReg;
logic [31:0] readData1, readData2, writeData;

//The write signal used to write a new value into the register file should be set when 'btnc' is pressed
logic write;
logic rst;

//declarations for all ALU components needed
 logic [3:0] alu_op;
 logic [31:0] op1_ALU;
 logic [31:0] op2_ALU;
 logic [31:0]  alu_r;
 logic [2:0] lcr_buttons;
 logic alu_zero;
 
 //creating a 15-bit register that controls the three ports of the register file
logic [14:0] register;
 
 //The 15 bits of the address register will be used to control the address of the three ports of the register file
  assign writeReg = register[14:10];
  assign readReg2  = register[9:5];
  assign readReg1  = register[4:0];



// increment signals (synchronized version of btnc)
logic btnc_d, btnc_dd, inc_c;

// increment signals (synchronized version of btnl)
logic btnl_d, btnl_dd, inc_l;

//assigning values based on buttons
assign rst = btnu;

//assinging values to alu instancion
assign op1_ALU = readData1;
assign op2_ALU = readData2;
assign alu_op = sw[3:0];

    // The following always block creates a "synchronizer" for the 'btnc' input.
    // A synchronizer synchronizes the asynchronous 'btnu' input to the global
    // clock (when you press a button you are not synchronous with anything!).
    // This particular synchronizer is just two flip-flop in series: 'btnu_d'
    // is the first flip-flop of the synchronizer and 'btnd_dd' is the second
    // flip-flop of the synchronizer. You should always have a synchronizer on
    // any button input if they are used in a sequential circuit.
    always_ff@(posedge clk)
        if (rst) begin
            btnc_d <= 0;
            btnc_dd <= 0;
        end
        else begin
            btnc_d <= btnc;
            btnc_dd <= btnc_d;
        end
    // Rename the output of the synchronizer to something more descriptive
    assign inc_c = btnc_dd;
    
    
        // The following always block creates a "synchronizer" for the 'btnl' input.
    // A synchronizer synchronizes the asynchronous 'btnu' input to the global
    // clock (when you press a button you are not synchronous with anything!).
    // This particular synchronizer is just two flip-flop in series: 'btnu_d'
    // is the first flip-flop of the synchronizer and 'btnd_dd' is the second
    // flip-flop of the synchronizer. You should always have a synchronizer on
    // any button input if they are used in a sequential circuit.
    always_ff@(posedge clk)
        if (rst) begin
            btnl_d <= 0;
            btnl_dd <= 0;
        end
        else begin
            btnl_d <= btnl;
            btnl_dd <= btnl_d;
        end
    // Rename the output of the synchronizer to something more descriptive
    assign inc_l = btnl_dd;
    
    // This register should be reset by the global reset signal ('btnu') and loaded with the bottom 15 switches (sw[14:0]) when 'btnl' is pressed
  always_ff@(posedge clk)begin
    if(rst)
     register <= 15'b000000000000000;
    else if(inc_l)
       register <= sw[14:0];
  end
  
    // A multiplexer when sw[15]=1, the multiplexer will pass a 32-bit sign-extended value of the lower 15 switches
  always_ff@(posedge clk)begin
    writeData <= (sw[15]) ? {{17{sw[14]}}, sw[14:0]} : alu_r;
  end
  
  // A multiplexer that selects the lower 16-bits of the readData1 when 'btnd' is NOT pressed and selects the upper 16-bits of the readData1 signal when 'btnd' IS pressed.
  always_ff@(posedge clk)begin
    led <= (btnd) ? readData1[31:16] : readData1[15:0];
  end
  
    
//ALU instansitation
alu alu_f(.op1(op1_ALU), .op2(op2_ALU), .alu_op(alu_op), .zero(alu_zero), .result(alu_r));

//One Shot
OneShot OS(.clk(clk), .rst(rst), .in(inc_c), .os(write));

//Regfile instansitation
regfile regfile_f(.clk(clk), .readReg1(readReg1), .readReg2(readReg2), .writeReg(writeReg), 
.writeData(writeData), .write(write), .readData1(readData1), .readData2(readData2));

endmodule
