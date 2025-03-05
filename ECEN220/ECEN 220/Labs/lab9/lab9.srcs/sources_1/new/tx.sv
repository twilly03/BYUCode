`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Thomas Williams
// 
// Create Date: 11/08/2022 03:07:25 PM
// Design Name: 
// Module Name: tx
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


module tx(
    input wire logic clk,
    input wire logic Reset, 
    input wire logic Send,
    input wire logic [7:0] Din,
    output logic Sent, 
    output logic Sout
    );
    
    logic clrTimer, timerDone, bitDone, startBit, dataBit, parityBit, clrBit, incBit;
    logic  [12:0] Bcounter;
    logic [2:0] bitnum;
    
    
    //Baud Rate Timer
    assign timerDone = (Bcounter == 13'd5208);
    always_ff @(posedge clk)
    begin
        if(clrTimer)
            Bcounter<= 4'd0000;
        else if(timerDone)
            Bcounter<= 4'd0000;
        else 
            Bcounter<= Bcounter+1;
    end
    
    
    // Datapath Generator with parity
    always_ff @(posedge clk)
        if (startBit)
            Sout <= 0;
        else if (dataBit)
            Sout <= Din[bitnum];
        else if (parityBit)
            Sout <=  ~^Din; // Parity calculation for odd parity
        else
            Sout <= 1;
            
    //Bit Counter   
    always_ff @(posedge clk)   
    begin
        if(clrBit)
            bitnum<=3'd0;
        else if(incBit&&bitnum!=3'd7)
            bitnum<=bitnum +1;
        else if(incBit&&bitnum==3'd7)         
            bitnum<=3'd0;
        else
            bitnum<=bitnum;     
    end
    
    //FSM
    typedef enum logic[2:0]{IDLE,START,BITS,PAR,STOP,ACK,ERR='X} stateType;
    stateType ns,cs;
    
    always_comb
    begin
        ns=ERR;
        clrTimer=0;
        startBit=0;
        clrBit=0;
        incBit=0;
        dataBit=0;
        parityBit=0;
        Sent=0;
    if(timerDone&&bitnum==3'd7)
        bitDone=1;
    else
        bitDone=0;
        
        
    if(Reset)
        ns=IDLE;
    else
        case(cs)
            IDLE: begin
                  clrTimer=1;
                  if(Send)
                    ns=START;
                  else
                    ns=IDLE;
                    end
            START: begin
                   startBit=1;
                   if(timerDone)
                     begin
                     clrBit=1;
                     ns=BITS;
                     end
                   else
                   ns=START;     
                   end
            BITS: begin
                  dataBit=1;
                  if(timerDone&&bitDone)
                    ns=PAR;
                  else if(timerDone&&~bitDone)
                    begin
                        incBit=1;
                         ns=BITS;
                     end
                  else
                    ns=BITS;           
                  end
            PAR: begin
                 parityBit=1;
                 if(timerDone)
                    ns=STOP;
                 else   
                    ns=PAR;                
                end
            STOP: if(timerDone)
                    ns=ACK;
                  else
                    ns=STOP;  
            ACK: begin 
                 Sent=1;
                 if(~Send)
                   ns=IDLE;
                 else
                   ns=ACK;
                 end
         endcase
    end
        
    always_ff@(posedge clk)
        cs<=ns;
    
       

endmodule

