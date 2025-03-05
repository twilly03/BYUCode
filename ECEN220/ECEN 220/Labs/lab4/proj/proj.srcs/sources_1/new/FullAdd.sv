`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/27/2022 03:39:11 PM
// Design Name: 
// Module Name: FullAdd
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


module FullAdd(
    input wire logic a,
    input wire logic b,
    input wire logic cin,
    output logic s,
    output logic co
    );
    // The outputs of the 3 AND gates in the full adder
    logic a1, a2, a3;
    
    //three input xor gate
    xor(s, a, b, cin);
    
    //three two input and gates
    and(a1, a, b);
    and(a2, b, cin);
    and(a3, a, cin);
    
    //three input or gate
    or(co, a1, a2, a3);
    
   
endmodule
