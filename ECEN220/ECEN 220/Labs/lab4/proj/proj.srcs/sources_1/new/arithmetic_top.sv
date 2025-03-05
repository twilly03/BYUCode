`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/27/2022 05:03:45 PM
// Design Name: 
// Module Name: arithmetic_top
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


module arithmetic_top(
    input wire logic [15:0] sw,
    input wire logic btnc,
    output logic [8:0] led
    );
    
    logic co, o1, o2, notsw7, notb7, notled7;
    logic [7:0]b;
    Add8 M0(.a(sw[7:0]), .b(b[7:0]), .cin(btnc), .s(led[7:0]), .co(co));
    
    not(notsw7, sw[7]);
    not(notb7, b[7]);
    not(notled7, led[7]);
    and(o1, notsw7, notb7, led[7]);
    and(o2, sw[7], b[7], notled7);
    or(led[8], o1, o2);
    
    xor(b[0], sw[8], btnc);
    xor(b[1], sw[9], btnc);
    xor(b[2], sw[10], btnc);
    xor(b[3], sw[11], btnc);
    xor(b[4], sw[12], btnc);
    xor(b[5], sw[13], btnc);
    xor(b[6], sw[14], btnc);
    xor(b[7], sw[15], btnc);
    
endmodule
