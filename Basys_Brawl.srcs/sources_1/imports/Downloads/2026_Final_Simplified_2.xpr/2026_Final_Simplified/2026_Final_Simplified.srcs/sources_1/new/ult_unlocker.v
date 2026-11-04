`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/16/2026 10:23:00 PM
// Design Name: 
// Module Name: ult_manager
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


module ult_manager(
    input clk,
    input reset,
    input tick,
    input [9:0] sw,
    input btnC,
    input ult_used,
    output ult_unlocked,
    output [9:0] led
    );
    
    //parameters//
    /*ult unlock codes*/
    parameter code1 = 103;
    parameter code2 = 295;
    parameter code3 = 361;
    parameter code4 = 067;
    parameter code5 = 182;
    parameter code6 = 917;
    parameter code7 = 302;
    parameter code8 = 743;
    parameter code9 = 519;
    parameter code10 = 425;   
    parameter code11 = 683;
    parameter code12 = 896;
    parameter code13 = 841;
    parameter code14 = 561;
    parameter code15 = 789;
   
    
    reg [9:0] count = 0; 
    reg charge = 0; 
    reg [36:0] randomiser = 0; 
    reg [3:0] code_number = 0; 
    integer selected_code = 0;
    reg [3:0] digits = 0; reg [1:0] scan = 0;
    reg [2:0] state = 3'b000; //FSM tracker for switch sequence
    reg [3:0] digitAn = 0; 
    wire [9:0]expected_sw;
    wire [3:0] hundreds; wire [3:0] tens; wire [3:0] ones;
    
    /*randomiser that selects 1-15 by taking remainder of a running clock*/
    always @(posedge clk) begin
        randomiser <= (charge)? randomiser: randomiser + 1;
        if (ult_used) code_number <= (randomiser % 15) + 1;
        //scan <= scan + 1;
    end
 
    assign hundreds = selected_code/100; // 1st digit from right
    assign tens = (selected_code%100)/10; // 2nd digit from right
    assign ones = selected_code%10; // last digit from right
    assign expected_sw = ((10'b1 << hundreds) ^ (10'b1 << tens) ^ (10'b1 << ones)); //expected switch configuration
 
    assign led = (state == 3'b000)? (10'b1 << hundreds):
                 (state == 3'b001)? ((10'b1 << hundreds)^(10'b1 << tens)):
                 expected_sw;
    
    assign ult_unlocked = (state == 3'b111);
    
    //FSM for each unlock code//
    always @(*) begin
        case(code_number) //based on the random generator, it sets the integer code 
            4'b0001: selected_code = code1;
            4'b0010: selected_code = code2;
            4'b0011: selected_code = code3;
            4'b0100: selected_code = code4;
            4'b0101: selected_code = code5;
            4'b0110: selected_code = code6;
            4'b0111: selected_code = code7;
            4'b1000: selected_code = code8;
            4'b1001: selected_code = code9;
            4'b1010: selected_code = code10;
            4'b1011: selected_code = code11;
            4'b1100: selected_code = code12;
            4'b1101: selected_code = code13;
            4'b1110: selected_code = code14;
            4'b1111: selected_code = code15;
            default: selected_code = code1;
        endcase
    end
    
    
    always @(posedge clk) begin
        if(ult_used || reset) state <= 3'b000;
        else begin
        case(state) //state transition to make sure unlock code is written in sequence and not just combinational
            3'b000: state = (sw == (10'b1 << hundreds))? 3'b001: state;
            3'b001: state = (sw == ((10'b1 << hundreds)^(10'b1 << tens)))? 3'b011: state;
            3'b011: state = (sw == expected_sw)? 3'b111: state;
            3'b111: /*loop here until ult is over*/ state=state;
        endcase
        end
    end
endmodule