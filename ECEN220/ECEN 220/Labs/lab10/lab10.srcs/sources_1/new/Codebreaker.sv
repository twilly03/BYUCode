`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2022 03:32:47 PM
// Design Name: 
// Module Name: Codebreaker
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


module Codebreaker(
    input wire logic clk,
    input wire logic reset,
    input wire logic start,
    output logic [15:0] key_display,
    output logic stopwatch_run,
    output logic draw_plaintext,
    input wire logic done_drawing_plaintext,
    output logic [127:0] plaintext_to_draw
    );
    //assign key_display = 0;
    //assign stopwatch_run = 1;
    //assign draw_plaintext = start;
    //assign plaintext_to_draw = {"Hello Victor"};
    decrypt_rc4 Decrypt(.clk(clk), .reset(reset), .enable(Enable), .key(key), .bytes_in(cyphertext), .bytes_out(plaintext_to_draw), .done(Done));
    
    typedef enum logic[2:0]{WAITS,DECRYPT, CHECK ,DISPLAY,TERM,ERR='X} stateType;
    logic  Done, Enable, plaintext_is_ascii, incKey;
    logic [23:0] key;
    logic [127:0] cyphertext;
    
    assign cyphertext = 128'h189f2800aac06ce4a74292bffe33fd2c;

    assign plaintext_is_ascii = ((plaintext_to_draw[127:120] >= "A" && plaintext_to_draw[127:120] <= "Z") || (plaintext_to_draw[127:120] >= "0" && plaintext_to_draw[127:120] <= "9") || (plaintext_to_draw[127:120] == " ")) &&
                            ((plaintext_to_draw[119:112] >= "A" && plaintext_to_draw[119:112] <= "Z") || (plaintext_to_draw[119:112] >= "0" && plaintext_to_draw[119:112] <= "9") || (plaintext_to_draw[119:112] == " ")) &&
                            ((plaintext_to_draw[111:104] >= "A" && plaintext_to_draw[111:104] <= "Z") || (plaintext_to_draw[111:104] >= "0" && plaintext_to_draw[111:104] <= "9") || (plaintext_to_draw[111:104] == " ")) &&
                            ((plaintext_to_draw[103:96] >= "A" && plaintext_to_draw[103:96] <= "Z") || (plaintext_to_draw[103:96] >= "0" && plaintext_to_draw[103:96] <= "9") || (plaintext_to_draw[103:96] == " ")) &&
                            ((plaintext_to_draw[95:88] >= "A" && plaintext_to_draw[95:88] <= "Z") || (plaintext_to_draw[95:88] >= "0" && plaintext_to_draw[95:88] <= "9") || (plaintext_to_draw[95:88] == " ")) &&
                            ((plaintext_to_draw[87:80] >= "A" && plaintext_to_draw[87:80] <= "Z") || (plaintext_to_draw[87:80] >= "0" && plaintext_to_draw[87:80] <= "9") || (plaintext_to_draw[87:80] == " ")) &&
                            ((plaintext_to_draw[79:72] >= "A" && plaintext_to_draw[79:72] <= "Z") || (plaintext_to_draw[79:72] >= "0" && plaintext_to_draw[79:72] <= "9") || (plaintext_to_draw[79:72] == " ")) &&
                            ((plaintext_to_draw[71:64] >= "A" && plaintext_to_draw[71:64] <= "Z") || (plaintext_to_draw[71:64] >= "0" && plaintext_to_draw[71:64] <= "9") || (plaintext_to_draw[71:64] == " ")) &&
                            ((plaintext_to_draw[63:56] >= "A" && plaintext_to_draw[63:56] <= "Z") || (plaintext_to_draw[63:56] >= "0" && plaintext_to_draw[63:56] <= "9") || (plaintext_to_draw[63:56] == " ")) &&
                            ((plaintext_to_draw[55:48] >= "A" && plaintext_to_draw[55:48] <= "Z") || (plaintext_to_draw[55:48] >= "0" && plaintext_to_draw[55:48] <= "9") || (plaintext_to_draw[55:48] == " ")) &&
                            ((plaintext_to_draw[47:40] >= "A" && plaintext_to_draw[47:40] <= "Z") || (plaintext_to_draw[47:40] >= "0" && plaintext_to_draw[47:40] <= "9") || (plaintext_to_draw[47:40] == " ")) &&
                            ((plaintext_to_draw[39:32] >= "A" && plaintext_to_draw[39:32] <= "Z") || (plaintext_to_draw[39:32] >= "0" && plaintext_to_draw[39:32] <= "9") || (plaintext_to_draw[39:32] == " ")) &&
                            ((plaintext_to_draw[31:24] >= "A" && plaintext_to_draw[31:24] <= "Z") || (plaintext_to_draw[31:24] >= "0" && plaintext_to_draw[31:24] <= "9") || (plaintext_to_draw[31:24] == " ")) &&
                            ((plaintext_to_draw[23:16] >= "A" && plaintext_to_draw[23:16] <= "Z") || (plaintext_to_draw[23:16] >= "0" && plaintext_to_draw[23:16] <= "9") || (plaintext_to_draw[23:16] == " ")) &&
                            ((plaintext_to_draw[15:8] >= "A" && plaintext_to_draw[15:8] <= "Z") || (plaintext_to_draw[15:8] >= "0" && plaintext_to_draw[15:8] <= "9") || (plaintext_to_draw[15:8] == " ")) &&
                            ((plaintext_to_draw[7:0] >= "A" && plaintext_to_draw[7:0] <= "Z") || (plaintext_to_draw[7:0] >= "0" && plaintext_to_draw[7:0] <= "9") || (plaintext_to_draw[7:0] == " "));
    
    stateType ns,cs;
    assign key_display = key[23:8];
    always_comb
    begin
    ns=ERR;
    incKey = 0;
    Enable = 0;
    stopwatch_run = 0;
    draw_plaintext = 0;
    if(reset)
    begin
    ns=WAITS;
    end
    else
    case(cs)
        WAITS: begin
              if(start)
                begin
                ns=DECRYPT;
                end
              else
                ns=WAITS;
                end
        DECRYPT: begin
               Enable=1;
                stopwatch_run=1;               
               if(Done)
                 begin
                 ns=CHECK;
                 end
               else
               ns=DECRYPT;     
               end
        CHECK: begin
                stopwatch_run=1;        
               if(plaintext_is_ascii)
                ns=DISPLAY;
               else 
                begin
                incKey = 1;
                ns=DECRYPT;
                end
               end
        DISPLAY: begin
              draw_plaintext=1;
              if(done_drawing_plaintext)
                ns=TERM;
              else
                ns=DISPLAY;           
              end
        TERM: begin
             if(reset)
              begin
              ns=WAITS;
              end
             else 
              ns=TERM;         
            end
        endcase
        end
        
    always_ff@(posedge clk)
        cs<=ns;
        
    always_ff@(posedge clk)    
    begin
        if(reset)
         key <=0;
        else if (incKey)
         key <= key+1;
    end
        
    
endmodule
