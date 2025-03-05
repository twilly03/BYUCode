`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/27/2022 04:03:30 PM
// Design Name: 
// Module Name: Add8
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


module Add8(
    input wire logic [7:0] a,
    input wire logic [7:0] b,
    input wire logic cin,
    output logic [7:0] s,
    output logic co
    );
    logic c1, c2, c3, c4, c5, c6, c7;
    
    FullAdd T0(.a(a[0]), .b(b[0]), .cin(cin), .s(s[0]), .co(c1));
    FullAdd T1(.a(a[1]), .b(b[1]), .cin(c1), .s(s[1]), .co(c2));
    FullAdd T2(.a(a[2]), .b(b[2]), .cin(c2), .s(s[2]), .co(c3));
    FullAdd T3(.a(a[3]), .b(b[3]), .cin(c3), .s(s[3]), .co(c4));
    FullAdd T4(.a(a[4]), .b(b[4]), .cin(c4), .s(s[4]), .co(c5));
    FullAdd T5(.a(a[5]), .b(b[5]), .cin(c5), .s(s[5]), .co(c6));
    FullAdd T6(.a(a[6]), .b(b[6]), .cin(c6), .s(s[6]), .co(c7));
    FullAdd T7(.a(a[7]), .b(b[7]), .cin(c7), .s(s[7]), .co(co));
endmodule
