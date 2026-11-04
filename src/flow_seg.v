`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.10.2026 20:19:33
// Design Name: 
// Module Name: flow_seg
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


module flow_seg(
    input CLOCK,
    input[2:0] phase,
    input[5:0] timer,
    input[1:0] count,
    input      turn,          
    input      p1_ko,          
    input[5:0] p1_time,        
    output reg[7:0] seg,
    output reg[3:0] anode
    );
    
    localparam INTRO = 3'b000;
    localparam READY = 3'b001;
    localparam FIGHT = 3'b010;
    localparam PAUSE = 3'b011;

    localparam BLANK    = 7'b1111111;   
    localparam DASH     = 7'b0111111;   
    localparam LETTER_P = 7'b0001100;  
    localparam LETTER_A = 7'b0001000;   
    
    reg[18:0] scan_count = 19'b000_0000_0000_0000_0000;
    reg[1:0] digit = 2'b00;
    
    always @(posedge CLOCK) begin
        if (scan_count == 19'b100_1001_0011_1101_1111) begin
            scan_count <= 19'b000_0000_0000_0000_0000;
            digit <= digit + 1;
        end else 
            scan_count <= scan_count + 1;
    end
    
    wire[3:0] tens = timer / 10;
    wire[3:0] ones = timer % 10;
    wire[6:0] tens_seg, ones_seg, count_seg;
    
    num_to_seg n_t (.NUM(tens), .SEG(tens_seg));
    num_to_seg n_o (.NUM(ones), .SEG(ones_seg));
    num_to_seg n_c (.NUM({2'b00, count}), .SEG(count_seg));
    
    wire[3:0] p1_tens = p1_time / 10;
    wire[3:0] p1_ones = p1_time % 10;
    wire[6:0] p1t_seg, p1o_seg;
    num_to_seg n_p1t (.NUM(p1_tens), .SEG(p1t_seg));
    num_to_seg n_p1o (.NUM(p1_ones), .SEG(p1o_seg));
    
    reg[6:0] d3, d2, d1, d0;
    always @(*) begin
        if (phase == INTRO)begin
            d3 = DASH; d2 = DASH; d1 = DASH; d0 = DASH;
        end
        else if (phase == READY) begin
            d3 = BLANK; d2 = BLANK; d1 = BLANK; d0 = count_seg;
        end
        else if (phase == PAUSE) begin
            d3 = LETTER_P; d2 = LETTER_A; d1 = tens_seg; d0 = ones_seg;
        end
        else begin
            if (turn && p1_ko) begin               // P2's turn: P1's time to beat
                d3 = p1t_seg;  d2 = p1o_seg;
            end
            else if (turn) begin                   // P1 didn't KO: nothing to beat
                d3 = DASH;     d2 = DASH;
            end
            else begin
                d3 = BLANK;    d2 = BLANK;
            end
            d1 = tens_seg; d0 = ones_seg;
        end
    end
    
    always @(*) begin
        if (digit == 2'b11) begin
            anode = 4'b0111; seg = {1'b1, d3};
        end
        else if (digit == 2'b10) begin
            anode = 4'b1011; seg = {1'b1, d2};
        end
        else if (digit == 2'b01) begin
            anode = 4'b1101; seg = {1'b1, d1};
        end
        else begin
            anode = 4'b1110; seg = {1'b1, d0};
        end
    end 
endmodule
