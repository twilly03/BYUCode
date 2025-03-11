`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/25/2022 04:56:03 PM
// Design Name: 
// Module Name: stopwatch
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


module stopwatch(
    input wire logic clk,
    input wire logic reset,
    input wire logic run,
    output logic [3:0] digit0,
    output logic [3:0] digit1,
    output logic [3:0] digit2,
    output logic [3:0] digit3
    );
    logic [3:0] i;
    logic throwaway;
    logic [19:0] throwaway1;
    mod_counter #(1000000,20) n0(.clk(clk), .reset(reset), .increment(run), .rolling_over(i[0]), .count(throwaway1));
    mod_counter #(10,4) m0(.clk(clk), .reset(reset), .increment(i[0]), .rolling_over(i[1]), .count(digit0));
    mod_counter #(10,4) m1(.clk(clk), .reset(reset), .increment(i[1]), .rolling_over(i[2]), .count(digit1));
    mod_counter #(10,4) m2(.clk(clk), .reset(reset), .increment(i[2]), .rolling_over(i[3]), .count(digit2));
    mod_counter #(6,4) m3(.clk(clk), .reset(reset), .increment(i[3]), .rolling_over(throwaway), .count(digit3));
endmodule
