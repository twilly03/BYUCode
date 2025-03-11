`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Thomas Williams
// 
// Create Date: 11/01/2022 05:30:53 PM
// Design Name: 
// Module Name: debounce_top
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


module debounce_top(
    input wire logic clk,
    input wire logic btnu,
    input wire logic btnc,
    output logic [3:0] anode,
    output logic [7:0] segment
    );
    logic register1, register2, debounced1, oneshot1, oneshot2, andCombine, notCombine;
    logic [7:0] QDebounced;
     //synchronizer
     always_ff @(posedge clk)
        begin
        register1 <= btnc;
        register2 <= register1;
        end
        //instance of debouncer
   debouncer m1(.clk(clk), .reset(btnu), .noisy(register2), .debounced(debounced1));
   //one shot detector
     always_ff @(posedge clk)
        begin
        oneshot1 <= debounced1;
        oneshot2 <= oneshot1;
        end
   not(notCombine, oneshot2);
   and(andCombine, oneshot1, notCombine);
   // Counter Debounced
     always_ff @(posedge clk)
        begin
        QDebounced <= 0;
        if (btnu == 1)
        QDebounced <= 0;
        else if(andCombine == 1)
        QDebounced <= QDebounced + 1;
        else 
        QDebounced <= QDebounced;
        end
        logic oneshot3, oneshot4, notCombine1, andCombine1;
        logic [15:0] combineDataIn;
        logic [7:0] QDebounced1;
   //one shot detector2
     always_ff @(posedge clk)
        begin
        oneshot3 <= register2;
        oneshot4 <= oneshot3;
        end
   not(notCombine1, oneshot4);
   and(andCombine1, oneshot3, notCombine1);
   // Counter unDebounced
     always_ff @(posedge clk)
        begin
        QDebounced1 <= 0;
        if (btnu == 1)
        QDebounced1 <= 0;
        else if(andCombine1 == 1)
        QDebounced1 <= QDebounced1 + 1;
        else 
        QDebounced1 <= QDebounced1;
        end
    assign combineDataIn = {QDebounced1, QDebounced};
    SevenSegmentControl m2(.clk(clk), .reset(btnu), .dataIn(combineDataIn), .digitDisplay(4'b1111), .digitPoint(4'b0000), .anode(anode), .segment(segment));
endmodule
