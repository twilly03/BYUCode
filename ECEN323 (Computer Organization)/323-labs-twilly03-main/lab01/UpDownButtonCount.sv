// This timescale statement indicates that each time tick of the simulator
// is 1 nanosecond and the simulator has a precision of 1 picosecond. This 
// is used for simulation and all of your SystemVerilog files should have 
// this statement at the top.
`timescale 1 ns / 1 ps

/***************************************************************************
*
* File: UpDownButtonCount.sv
*
* Author: Professor Mike Wirthlin
* Class: ECEN 323, Winter Semester 2020
*
* Module: ButtonCount
*
* Description:
*    This module includes a state machine that will provide a one cycle
*    signal every time the top button (btnu) is pressed (this is sometimes
*    called a 'single-shot' filter of the button signal). This signal
*    is used to increment a counter that is displayed on the LEDs. The
*    center button (btnc) is used as a synchronous reset.
*
*    This module is used to help students review their RTL design skills and
*    get the design tools working.
*
****************************************************************************/

module UpDownButtonCount(clk, btnc, btnu, led, btnd, btnl, btnr, sw);

    input wire logic clk, btnc, btnu, btnd, btnr, btnl;
    input logic [15:0] sw;
    output logic [15:0] led;
  
    // The internal 16-bit count signal.
    logic [15:0] count_i;
    // The increment counter output from the one shot module
    logic inc_count;
    // reset signal
    logic rst;
    // increment signals (synchronized version of btnu)
    logic btnu_d, btnu_dd, inc;
    // increment signals (synchronized version of btnd)
    logic btnd_d, btnd_dd, inc_d;
    // increment signals (synchronized version of btnl)
    logic btnl_d, btnl_dd, inc_l;
    // increment signals (synchronized version of btnr)
    logic btnr_d, btnr_dd, inc_r;

    // Assign the 'rst' signal to button c
    assign rst = btnc;

    // The following always block creates a "synchronizer" for the 'btnu' input.
    // A synchronizer synchronizes the asynchronous 'btnu' input to the global
    // clock (when you press a button you are not synchronous with anything!).
    // This particular synchronizer is just two flip-flop in series: 'btnu_d'
    // is the first flip-flop of the synchronizer and 'btnu_dd' is the second
    // flip-flop of the synchronizer. You should always have a synchronizer on
    // any button input if they are used in a sequential circuit.
    always_ff@(posedge clk)
        if (rst) begin
            btnu_d <= 0;
            btnu_dd <= 0;
        end
        else begin
            btnu_d <= btnu;
            btnu_dd <= btnu_d;
        end
    // Rename the output of the synchronizer to something more descriptive
    assign inc = btnu_dd;
    // The following always block creates a "synchronizer" for the 'btnd' input.
    // A synchronizer synchronizes the asynchronous 'btnu' input to the global
    // clock (when you press a button you are not synchronous with anything!).
    // This particular synchronizer is just two flip-flop in series: 'btnu_d'
    // is the first flip-flop of the synchronizer and 'btnd_dd' is the second
    // flip-flop of the synchronizer. You should always have a synchronizer on
    // any button input if they are used in a sequential circuit.
    always_ff@(posedge clk)
        if (rst) begin
            btnd_d <= 0;
            btnd_dd <= 0;
        end
        else begin
            btnd_d <= btnd;
            btnd_dd <= btnd_d;
        end
    // Rename the output of the synchronizer to something more descriptive
    assign inc_d = btnd_dd;

    // The following always block creates a "synchronizer" for the 'btnl' input.
    // A synchronizer synchronizes the asynchronous 'btnu' input to the global
    // clock (when you press a button you are not synchronous with anything!).
    // This particular synchronizer is just two flip-flop in series: 'btnu_d'
    // is the first flip-flop of the synchronizer and 'btnl_dd' is the second
    // flip-flop of the synchronizer. You should always have a synchronizer on
    // any button input if they are used in a sequential circuit.
    always_ff@(posedge clk)
        if (rst) begin
            btnl_d <= 0;
            btnl_dd <= 0;
        end
        else begin
            btnl_d <= btnl;
            btnl_dd <= btnl_d;
        end
    // Rename the output of the synchronizer to something more descriptive
    assign inc_l = btnl_dd;
    
    // The following always block creates a "synchronizer" for the 'btnr' input.
    // A synchronizer synchronizes the asynchronous 'btnu' input to the global
    // clock (when you press a button you are not synchronous with anything!).
    // This particular synchronizer is just two flip-flop in series: 'btnu_d'
    // is the first flip-flop of the synchronizer and 'btnr_dd' is the second
    // flip-flop of the synchronizer. You should always have a synchronizer on
    // any button input if they are used in a sequential circuit.
    always_ff@(posedge clk)
        if (rst) begin
            btnr_d <= 0;
            btnr_dd <= 0;
        end
        else begin
            btnr_d <= btnr;
            btnr_dd <= btnr_d;
        end
    // Rename the output of the synchronizer to something more descriptive
    assign inc_r = btnr_dd;
    
    // Instance the OneShot module
    OneShot os (.clk(clk), .rst(rst), .in(inc), .os(inc_count));
    //Second instance of the OneShot module
    OneShot ss (.clk(clk), .rst(rst), .in(inc_d), .os(dec_count));
    //Third instance of the OneShot module
    OneShot ts (.clk(clk), .rst(rst), .in(inc_r), .os(inc_sw_count));
    //Fourth instance of the OneShot module
    OneShot fs (.clk(clk), .rst(rst), .in(inc_l), .os(dec_sw_count));

    // 16-bit Counter. Increments once each time button is pressed.
    //
    // This is an exmaple of a 'sequential' statement that will synthesize flip-flops
    // as well as the logic for incrementing the count value.
    //
    //  CODING STANDARD: Every "segment/block" of your RTL code must have at least
    //  one line of white space between it and the previous and following block. Also,
    //  ALL always blocks must have a coment.
    always_ff@(posedge clk)
        if (rst)
            count_i <= 0;
        else if (dec_count)
            count_i <= count_i - 1;
        else if (inc_sw_count)
            count_i <= count_i + sw;
        else if (dec_sw_count)
            count_i <= count_i - sw;
        else if (inc_count)
            count_i <= count_i + 1;

    // Assign the 'led' output the value of the internal count_i signal.
    assign led = count_i;

endmodule
