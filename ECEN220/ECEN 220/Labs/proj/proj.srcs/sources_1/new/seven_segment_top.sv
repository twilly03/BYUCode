`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/11/2022 06:24:51 PM
// Design Name: 
// Module Name: seven_segment_top
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


module seven_segment_top(
        input wire logic [3:0] sw,
        input wire logic btnc,
        output logic [7:0] segment,
        output logic [3:0] anode
    );
    seven_segment M0(.data(sw[3:0]), .segment(segment[6:0]));
    assign segment[7] = ~btnc;
    assign anode[3:0] = 4'b1110;
endmodule
