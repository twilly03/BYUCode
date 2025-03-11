// This timescale statement indicates that each time tick of the simulator
// is 1 nanosecond and the simulator has a precision of 1 picosecond. This 
// is used for simulation and all of your SystemVerilog files should have 
// this statement at the top.
`timescale 1 ns / 1 ps

/***************************************************************************
*
* File: calc.sv
*
* Author: Thomas Williams
* Class: ECEN 323, Winter Semester 2024
*
* Module: ALU
*
* For this exercise you will design a top-level calculator 
*circuit that uses the ALU you created in the previous 
*exercise. This circuit will maintain a current value of 
*the "calculator" in a 16-bit accumulator register and 
*allow the user to update the value by implementing any of 
*the arithmetic and logic functions provided by your ALU.  
*
****************************************************************************/

module calc(clk, btnc, btnl, btnu, btnr, btnd, sw, led);
    `include "riscv_alu_constants.sv"
    //all inputs, clock and the buttons
    input wire logic clk, btnc, btnu, btnr, btnl, btnd;
    //the input for the switches
    input wire logic [15:0] sw;
    
    //LED output
    output logic [15:0] led;
    
    //new variables to connect to the new 3 bit binary format
    localparam[2:0] CALCOP_AND = 3'b010;
    localparam[2:0] CALCOP_OR = 3'b011;
    localparam[2:0] CALCOP_Addition = 3'b000;
    localparam[2:0] CALCOP_Subtraction = 3'b001;
    localparam[2:0] CALCOP_LessThan = 3'b101;
    //localparam[2:0] CALCOP_ShiftRightLogical = 3'b100;
    localparam[2:0] CALCOP_ShiftLeftLogical = 3'b110;
    localparam[2:0] CALCOP_ShiftRightArithmetic = 4'b111;
    localparam[2:0] CALCOP_XOR = 3'b100;
    
    //Create a 16-bit register (called the accumulator) to hold the contents of the current value of the calculator. 
    logic [15:0] accumulator;
    
    //declarations for all ALU components needed
    logic rst;
    logic btnd_pressed;
    logic [3:0] alu_op;
    logic [31:0] op1_ALU;
    logic [31:0] op2_ALU;
    logic [31:0]  alu_r;
    logic [2:0] lcr_buttons;
    logic alu_zero;
    
    // increment signals (synchronized version of btnd)
    logic btnd_d, btnd_dd, inc_d;
    
    //reset variable for when btnu and btnd is pushed.
    assign rst = btnu;
    assign btnd_pressed = out_d;
    
    
   //setting variables for the op1 and op2 alu 
    assign op2_ALU = {{16{sw[15]}}, sw};
    assign op1_ALU = {{16{accumulator[15]}}, accumulator};
    
    //assigning the values of the leds to the accumulator values
    assign led = accumulator; 
   
    
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
    
    //creating a variable to store the button pushes of l, c, r
    assign lcr_buttons = {btnl, btnc, btnr};
    
    //This is assigning the accumulator values based on what buttons are pressed 
    always_ff@(posedge clk) begin
        if(rst)
            accumulator <= 16'b0;
        else if(btnd_pressed) 
            accumulator <= alu_r[15:0];
    end
     
     //A multiplexer used to select an operation based on the combination of the 3 buttons
     always_comb begin
        case(lcr_buttons)
            CALCOP_AND:                  alu_op = ALUOP_AND;
            
            CALCOP_OR:                   alu_op = ALUOP_OR;
            
            CALCOP_Addition:             alu_op = ALUOP_Addition;
            
            CALCOP_Subtraction:          alu_op = ALUOP_Subtraction;
            
            CALCOP_LessThan:             alu_op = ALUOP_LessThan;
            
            //CALCOP_ShiftRightLogical:    alu_op = ALUOP_ShiftRightLogical;
            
            CALCOP_ShiftLeftLogical:     alu_op = ALUOP_ShiftLeftLogical;
            
            CALCOP_ShiftRightArithmetic: alu_op = ALUOP_ShiftRightArithmetic;
            
            CALCOP_XOR:                  alu_op = ALUOP_XOR;  
            
            default:                     alu_op = ALUOP_Addition;  
      endcase
   end
    
    //One shot instansitation for each of the 2 buttons, up and down
    OneShot os_d(.clk(clk), .rst(rst), .in(inc_d), .os(out_d));

    
    //ALU instansitation
    alu alu_f(.op1(op1_ALU), .op2(op2_ALU), .alu_op(alu_op), .zero(alu_zero), .result(alu_r));
    
    
        
 
endmodule
