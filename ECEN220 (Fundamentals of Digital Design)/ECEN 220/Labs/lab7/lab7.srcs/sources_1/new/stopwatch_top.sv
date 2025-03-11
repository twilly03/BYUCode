`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/25/2022 05:57:39 PM
// Design Name: 
// Module Name: stopwatch_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module stopwatch_top(
    input wire logic clk,
    input wire logic btnc,
    input wire logic sw,
    output logic [3:0] anode,
    output logic [7:0] segment
    );
    logic [15:0] all; 
    SevenSegmentControl n0(.clk(clk), .reset(btnc), .dataIn(all[15:0]), .digitDisplay(4'b1111), .digitPoint(4'b0100), .anode(anode[3:0]), .segment(segment[7:0]));
    stopwatch m0(.clk(clk), .reset(btnc), .run(sw), .digit0(all[3:0]), .digit1(all[7:4]), .digit2(all[11:8]), .digit3(all[15:12]));
    
endmodule
