`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Thomas Williams
// 
// Create Date: 11/29/2022 03:23:08 PM
// Design Name: 
// Module Name: rx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module rx(
    input wire logic clk, Reset, Sin, Received,
    output logic Receive,parityErr,
    output logic [7:0] Dout
    );
    
 //output and input of the Baud Timer
 logic timerDone,clrTimer,halfDone;
 logic [12:0] counter;
 
 //Baud Timer
 always_ff @(posedge clk)
 begin
    if(clrTimer)
        counter<= 4'd0000;
    else if(counter!=13'd5207)
        counter<= counter+1;
    else if(counter==13'd5207)
        counter<= 4'd0000;
    else
        counter<= counter;
 end
 assign timerDone=(counter==13'd5207)?1:0;
 assign halfDone=(counter==13'd2604)?1:0;
 
 // shift register input & output
 logic inputs,shift,Bitdone;
 logic [8:0] outs;
 //shift register
 always_ff @(posedge clk)
 begin
    if(shift)
        outs<={inputs,outs[8:1]};
    else   
        outs<=outs;
 end
 assign shift=(halfDone&&!Bitdone)?1:0;
 
 //parity checker input
 logic pErr;
 //parity checker
 assign pErr=(~^outs[7:0]==outs[8])?0:1;
 
  //bitcounter input and output
 logic[8:0] bitNum;
 logic clrBit,incBit;
 //bit counter
 always_ff @(posedge clk)
 begin
     if(clrBit)
         bitNum<=4'd0;
     else if(incBit&&bitNum!=4'd9)
         bitNum<=bitNum +1;
     else
        bitNum<=bitNum;
 end 
assign Bitdone=(bitNum==4'd9)?1:0;
assign incBit=(halfDone&&!Bitdone)?1:0;
//FSM
typedef enum logic[2:0]{IDLE,START,BITS,RECV,ERR='X}
 stateType;
 stateType ns,cs;
 
 always_comb
 begin
    ns=ERR;
    clrTimer=0;
    clrBit=0;
    Receive=0;
    if(Reset)
    begin
        Dout=0;    
        ns=IDLE;
    end   
    else
    case(cs)
    IDLE: begin
          clrTimer=1;
          if(Sin)
            ns=IDLE;
          else
            ns=START;
          end
    START: begin       
           if(timerDone)
           begin
               clrBit=1;
               ns=BITS;
           end
           else if(~Sin)
               ns=START;
           else
               ns=IDLE;
           end
    BITS: begin
          inputs=Sin;
          if(Bitdone)
          begin
            Dout=outs[7:0];
            parityErr=pErr;      
            ns=RECV;
          end
          else
            ns=BITS;
          end
    RECV: begin
          Receive=1;
          if(Received) 
            ns=IDLE;
          else
            ns=RECV;                
          end
    endcase
    end
 
 //FSM fliflop
 always_ff@(posedge clk)
 cs<=ns;
endmodule
