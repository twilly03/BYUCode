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


module Counter(
        input wire logic CLK,
        input wire logic CLR,
        input wire logic INC,
        output logic [3:0] Q,
        output logic [3:0] NXT
    );
    FDCE my_ff0 (.Q(Q[0]), .C(CLK), .CE(1'b1), .CLR(1'b0), .D(NXT[0]));
    FDCE my_ff1 (.Q(Q[1]), .C(CLK), .CE(1'b1), .CLR(1'b0), .D(NXT[1]));
    FDCE my_ff2 (.Q(Q[2]), .C(CLK), .CE(1'b1), .CLR(1'b0), .D(NXT[2]));
    FDCE my_ff3 (.Q(Q[3]), .C(CLK), .CE(1'b1), .CLR(1'b0), .D(NXT[3]));
    assign NXT = 
    (CLR&&INC)?Q:
    (CLR&&!INC)?4'b0000:
    (!CLR&&INC)?Q+1:
    Q;
    
endmodule
