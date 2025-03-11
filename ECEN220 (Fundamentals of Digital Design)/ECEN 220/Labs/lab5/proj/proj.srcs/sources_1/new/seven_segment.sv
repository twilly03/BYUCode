`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Thomas Williams
// 
// Create Date: 10/11/2022 03:50:26 PM
// Design Name: 
// Module Name: seven_segment
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


module seven_segment(
    input wire logic [3:0] data,
    output logic [6:0] segment
    );
    // Segment A using SV
    logic d1, d2, d3, d0, a1, a2, a3, a4;
    
    not(d0, data[0]);
    not(d1, data[1]);
    not(d2, data[2]);
    not(d3, data[3]);
    
    and(a1, data[0], d1, d2, d3);
    and(a2, d0, d1, data[2], d3);
    and(a3, data[0], data[1], d2, data[3]);
    and(a4, data[0], d1, data[2], data[3]);
    
    or(segment[0], a1, a2, a3, a4);
    
    // Segment B using SV
    logic a5, a6, a7, a8, a9, a10;
    
    and(a5, data[0], d1, data[2], d3);
    and(a6, d0, data[1], data[2], d3);
    and(a7, data[0], data[1], d2, data[3]);
    and(a8, d0, d1, data[2], data[3]);
    and(a9, d0, data[1], data[2], data[3]);
    and(a10, data[0], data[1], data[2], data[3]);
    
    or(segment[1], a5, a6, a7, a8, a9, a10); 
    
    // Segment C using SV
    logic a22, a11, a12, a13;
    
    and(a22, d0, data[1], d2, d3);
    and(a11, d0, d1, data[2], data[3]);
    and(a12, d0, data[1], data[2], data[3]);
    and(a13, data[0], data[1], data[2], data[3]);
    
    or(segment[2], a22, a11, a12, a13);
    
    // Segment D using SV
    logic a14, a15, a16, a17, a18;
    
    and(a14, data[0], d1, d2, d3);
    and(a15, d0, d1, data[2], d3);
    and(a16, data[0], data[1], data[2], d3);
    and(a17, d0, data[1], d2, data[3]);
    and(a18, data[0], data[1], data[2], data[3]);
    
    or(segment[3], a14, a15, a16, a17, a18);
    
    // Segment E using DataFlow SV
    assign segment[4] = (data[0] & ~data[1] & ~data[2] & ~data[3]) | (data[0] & data[1] & ~data[2] & ~data[3]) | (~data[0] & ~data[1] & data[2] & ~data[3]) | (data[0] & ~data[1] & data[2] & ~data[3]) | (data[0] & data[1] & data[2] & ~data[3]) | (data[0] & ~data[1] & ~data[2] & data[3]);
    
    // Segment F using DataFlow SV
    assign segment[5] =
        (data==4'b0000)?0:
        (data==4'b0001)?1:
        (data==4'b0010)?1:
        (data==4'b0011)?1:
        (data==4'b0100)?0:
        (data==4'b0101)?0:
        (data==4'b0110)?0:
        (data==4'b0111)?1:
        (data==4'b1000)?0:
        (data==4'b1001)?0:
        (data==4'b1010)?0:
        (data==4'b1011)?0:
        (data==4'b1100)?0:
        (data==4'b1101)?1:
        (data==4'b1110)?0:
        0;
    
    // Segment G using simplified SV
    logic a19, a20, a21;
    
    and(a19, d1, d2, d3);
    and(a20, data[0], data[1], data[2], d3);
    and(a21, d0, d1, data[2], data[3]);
    
    or(segment[6], a19, a20, a21);
    
    
endmodule
