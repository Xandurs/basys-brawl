`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2026 15:20:26
// Design Name: 
// Module Name: digit_pixel
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


module digit_pixel #(
    parameter W = 30,    // width
    parameter H = 50,    // height
    parameter T = 6      // thickness
)(
    input  [6:0] x, input [5:0] y,
    input  [6:0] x0, input [5:0] y0,
    input  [3:0] digit,
    output on
);
    localparam MID_TOP = (H - T) / 2;
    localparam MID_BOT = (H + T) / 2 - 1;

    wire a = (x >= x0)         && (x <= x0 + W - 1) && (y >= y0)           && (y <= y0 + T - 1);
    wire b = (x >= x0 + W - T) && (x <= x0 + W - 1) && (y >= y0)           && (y <= y0 + MID_BOT);
    wire c = (x >= x0 + W - T) && (x <= x0 + W - 1) && (y >= y0 + MID_TOP) && (y <= y0 + H - 1);
    wire d = (x >= x0)         && (x <= x0 + W - 1) && (y >= y0 + H - T)   && (y <= y0 + H - 1);
    wire e = (x >= x0)         && (x <= x0 + T - 1) && (y >= y0 + MID_TOP) && (y <= y0 + H - 1);
    wire f = (x >= x0)         && (x <= x0 + T - 1) && (y >= y0)           && (y <= y0 + MID_BOT);
    wire g = (x >= x0)         && (x <= x0 + W - 1) && (y >= y0 + MID_TOP) && (y <= y0 + MID_BOT);

    reg [6:0] seg;   // a b c d e f g
    always @(*) begin
        case (digit)
            4'd0: seg = 7'b1111110;
            4'd1: seg = 7'b0110000;
            4'd2: seg = 7'b1101101;
            4'd3: seg = 7'b1111001;
            4'd4: seg = 7'b0110011;
            4'd5: seg = 7'b1011011;
            4'd6: seg = 7'b1011111;
            4'd7: seg = 7'b1110000;
            4'd8: seg = 7'b1111111;
            4'd9: seg = 7'b1111011;
            default: seg = 7'b0000000;
        endcase
    end

    assign on = (seg[6] && a) || (seg[5] && b) || (seg[4] && c) ||
                (seg[3] && d) || (seg[2] && e) || (seg[1] && f) ||
                (seg[0] && g);
endmodule