`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/25/2022 03:07:38 PM
// Design Name: 
// Module Name: mod_counter
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


module mod_counter #(parameter MOD_VALUE=10, width=4) (
    input wire logic clk,
    input wire logic reset,
    input wire logic increment,
    output logic rolling_over,
    output logic [width-1:0] count 
    );
    assign rolling_over = increment && (count == MOD_VALUE-1);
    always_ff @(posedge clk)
        begin
        if (reset) 
        count <= 4'b0000;
        else if (rolling_over)
        count <= 4'b0000;
        else if (increment) 
        count <= count + 4'b0001;
        end
endmodule
