`timescale 1ns / 1ps
/***************************************************************************
*
* Module: <FourFunctions>
*
* Author: <Thomas>
* Class: <ECEN 220, 001, Fall> - ECEN 220, Section 1, Winter 2020
* Date: <9/20/22>
*
* Description: <Provide a brief description of what this SystemVerilog file does>
*
*
****************************************************************************/
`default_nettype none

module FourFunctions(
    input wire logic A, B, C,
    output logic O1, O2, O3, O4
    );
    
    //logic function 1-8
    logic F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15;
    
    //function 1
    and(F1, A, C);
    not(F2, A);
    and(F3, F2, B);
    or(O1, F3, F1);
    
    //funtion 2
    not(F4, C);
    or(F5, A, F4);
    and(F6, B, C);
    and(O2, F5, F6);
    
    //function 3
    not(F7, B);
    and(F8, A, F7);
    or(O3, F8, C);
    
    //function 4
    and(F9, A, B);
    not(F10, F9);
    not(F11, C);
    not(F12, B);
    and(F13, F11, F12);
    not(F14, F13);
    and(F15, F14, F10);
    not(O4, F15);
endmodule
