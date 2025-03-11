`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: THOMAS WILLIAMS
// 
// Create Date: 10/18/2022 03:11:38 PM
// Design Name: 
// Module Name: FunRegister
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


module FunRegister(
        input wire logic CLK,
        input wire logic DIN,
        input wire logic LOAD,
        output logic Q,
        output logic NXT
    );
    FDCE my_ff (.Q(Q), .C(CLK), .CE(1'b1), .CLR(1'b0), .D(NXT));
    assign NXT = 
    (LOAD)?DIN:
    Q; 
endmodule
