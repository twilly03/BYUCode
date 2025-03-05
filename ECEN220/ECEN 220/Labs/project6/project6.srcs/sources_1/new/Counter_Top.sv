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


module Counter_Top(
        input wire logic btnc,
        input wire logic [1:0] sw,
        output logic [7:0] segment,
        output logic [3:0] anode,
        output logic [3:0] led
    );
   logic [3:0]a; // a is my Q instantiated from Counter.sv
    
   Counter c1(.CLK(btnc), .CLR(sw[0]), .INC(sw[1]), .Q(a), .NXT(led[3:0]));
   seven_segment s1(.data(a), .segment(segment[6:0]));
   assign segment[7] = 1'b1;
   assign anode[3:0] = 4'b1110;
endmodule
