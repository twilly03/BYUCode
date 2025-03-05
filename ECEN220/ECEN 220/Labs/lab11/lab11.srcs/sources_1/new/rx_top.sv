//////////////////////////////////////////////////////////////////////////////////
//
//  Filename: rx_top.sv
//
//  Author: Scott Lloyd
//
//  Description: UART Receiver top-level design
//
//
//////////////////////////////////////////////////////////////////////////////////
`default_nettype none

module rx_top (
    input wire logic  clk,   // system clock
    input wire logic  btnu,  // reset
    input wire logic  rx_in, // serial input
    output logic[15:0] led,
    output logic[3:0] anode,
    output logic[7:0] segment
    );

    logic reset, req, ack, perr;
    logic[7:0] data0, data1, data2;

    assign reset = btnu;

    // Data history on seven-segment display
    always_ff @(posedge clk)
        if (reset) begin
            data1 <= 0;
            data2 <= 0;
        end else if (req & ~ack) begin
            data1 <= data0;
            data2 <= data1;
        end

    // Parity error history on LEDs
    always_ff @(posedge clk)
        if (reset) begin
            led <= 0;
        end else if (req & ~ack) begin
            led <= led << 1;
            led[0] <= perr;
        end

    // Handshake
    always_ff @(posedge clk)
        if (reset) ack <= 0;
        else ack <= req;

    // Receiver
    rx rx_inst(
        .clk(clk),
        .Reset(reset),
        .Sin(rx_in),
        .Receive(req),
        .Received(ack),
        .Dout(data0),
        .parityErr(perr)
    );

    // Seven-Segment Display
    SevenSegmentControl SSC(
        .clk(clk),
        .reset(reset),
        .dataIn({data2, data1}),
        .digitDisplay(4'hf),
        .digitPoint(4'h4),
        .anode(anode),
        .segment(segment)
    );

endmodule