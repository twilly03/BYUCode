`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Thomas Williams
// 
// Create Date: 11/01/2022 03:06:50 PM
// Design Name: 
// Module Name: Debounce
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


module debouncer(
    input wire logic clk,
    input wire logic reset,
    input wire logic noisy,
    output logic debounced
    );
    typedef enum logic[3:0] {s0, s1, s2, s3, ERR='X} StateType;
    StateType ns, cs;
    logic timerDone, clrTimer;
    logic [18:0] count;
    //state register
    always_ff @(posedge clk)
    cs <= ns;
    
    //The IFL/OFL
    always_comb
    begin
        ns = ERR;
        clrTimer = 0;
        debounced = 0;
        if(reset)
        ns = s0;
        else case (cs)
            s0: begin
                clrTimer = 1;
                if(noisy) ns = s1;
                else ns = s0;
                end
            s1: begin
                if(noisy && timerDone) ns = s2;
                else if(noisy && ~timerDone) ns = s1;
                else if(~noisy) ns = s0;
                end
            s2: begin
                debounced = 1;
                clrTimer = 1;
                if(noisy) ns = s2;
                else ns = s3;
                end
            s3: begin
                debounced = 1;
                if(noisy) ns = s2;
                else if(~timerDone) ns = s3;
                else 
                ns = s0;
                end
         endcase
     end

    assign timerDone = (count == 500000-1);
    always_ff @(posedge clk)
        begin
        if (reset || clrTimer) 
        count <= 0;
        else if (timerDone)
        count <= 0;
        else 
        count <= count + 1;
        end
endmodule