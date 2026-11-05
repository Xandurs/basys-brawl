`timescale 1ns / 1ps

module font_render(
    input [7:0] char_code,

    input [6:0] pixel_x,
    input [5:0] pixel_y,

    input [6:0] char_x,
    input [5:0] char_y,

    output reg pixel_on
);

    // =====================================================
    // 5 x 7 FONT
    // Each character contains 35 bits:
    // 7 rows x 5 pixels
    // =====================================================

    function [34:0] get_glyph;

        input [7:0] ch;

        begin

            case (ch)

                // A
                8'h41: get_glyph = {
                    5'b01110,
                    5'b10001,
                    5'b10001,
                    5'b11111,
                    5'b10001,
                    5'b10001,
                    5'b10001
                };

                // B
                8'h42: get_glyph = {
                    5'b11110,
                    5'b10001,
                    5'b10001,
                    5'b11110,
                    5'b10001,
                    5'b10001,
                    5'b11110
                };

                // C
                8'h43: get_glyph = {
                    5'b01111,
                    5'b10000,
                    5'b10000,
                    5'b10000,
                    5'b10000,
                    5'b10000,
                    5'b01111
                };

                // D
                8'h44: get_glyph = {
                    5'b11110,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b11110
                };

                // E
                8'h45: get_glyph = {
                    5'b11111,
                    5'b10000,
                    5'b10000,
                    5'b11110,
                    5'b10000,
                    5'b10000,
                    5'b11111
                };

                // F
                8'h46: get_glyph = {
                    5'b11111,
                    5'b10000,
                    5'b10000,
                    5'b11110,
                    5'b10000,
                    5'b10000,
                    5'b10000
                };

                // G
                8'h47: get_glyph = {
                    5'b01111,
                    5'b10000,
                    5'b10000,
                    5'b10111,
                    5'b10001,
                    5'b10001,
                    5'b01110
                };

                // H
                8'h48: get_glyph = {
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b11111,
                    5'b10001,
                    5'b10001,
                    5'b10001
                };

                // I
                8'h49: get_glyph = {
                    5'b11111,
                    5'b00100,
                    5'b00100,
                    5'b00100,
                    5'b00100,
                    5'b00100,
                    5'b11111
                };

                // L
                8'h4C: get_glyph = {
                    5'b10000,
                    5'b10000,
                    5'b10000,
                    5'b10000,
                    5'b10000,
                    5'b10000,
                    5'b11111
                };

                // M
                8'h4D: get_glyph = {
                    5'b10001,
                    5'b11011,
                    5'b10101,
                    5'b10101,
                    5'b10001,
                    5'b10001,
                    5'b10001
                };

                // N
                8'h4E: get_glyph = {
                    5'b10001,
                    5'b11001,
                    5'b10101,
                    5'b10011,
                    5'b10001,
                    5'b10001,
                    5'b10001
                };

                // O
                8'h4F: get_glyph = {
                    5'b01110,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b01110
                };

                // P
                8'h50: get_glyph = {
                    5'b11110,
                    5'b10001,
                    5'b10001,
                    5'b11110,
                    5'b10000,
                    5'b10000,
                    5'b10000
                };

                // R
                8'h52: get_glyph = {
                    5'b11110,
                    5'b10001,
                    5'b10001,
                    5'b11110,
                    5'b10100,
                    5'b10010,
                    5'b10001
                };

                // S
                8'h53: get_glyph = {
                    5'b01111,
                    5'b10000,
                    5'b10000,
                    5'b01110,
                    5'b00001,
                    5'b00001,
                    5'b11110
                };

                // T
                8'h54: get_glyph = {
                    5'b11111,
                    5'b00100,
                    5'b00100,
                    5'b00100,
                    5'b00100,
                    5'b00100,
                    5'b00100
                };

                // U
                8'h55: get_glyph = {
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b01110
                };

                // V
                8'h56: get_glyph = {
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b01010,
                    5'b00100
                };

                // W
                8'h57: get_glyph = {
                    5'b10001,
                    5'b10001,
                    5'b10001,
                    5'b10101,
                    5'b10101,
                    5'b10101,
                    5'b01010
                };

                // Y
                8'h59: get_glyph = {
                    5'b10001,
                    5'b10001,
                    5'b01010,
                    5'b00100,
                    5'b00100,
                    5'b00100,
                    5'b00100
                };

                // Z
                8'h5A: get_glyph = {
                    5'b11111,
                    5'b00001,
                    5'b00010,
                    5'b00100,
                    5'b01000,
                    5'b10000,
                    5'b11111
                };

                // 1
                8'h31: get_glyph = {
                    5'b00100,
                    5'b01100,
                    5'b00100,
                    5'b00100,
                    5'b00100,
                    5'b00100,
                    5'b01110
                };

                // 2
                8'h32: get_glyph = {
                    5'b01110,
                    5'b10001,
                    5'b00001,
                    5'b00010,
                    5'b00100,
                    5'b01000,
                    5'b11111
                };

                // 3
                8'h33: get_glyph = {
                    5'b11110,
                    5'b00001,
                    5'b00001,
                    5'b01110,
                    5'b00001,
                    5'b00001,
                    5'b11110
                };

                // >
                8'h3E: get_glyph = {
                    5'b10000,
                    5'b01000,
                    5'b00100,
                    5'b00010,
                    5'b00100,
                    5'b01000,
                    5'b10000
                };

                             
                8'h4B: get_glyph = {5'b10001, 5'b10010, 5'b10100,
                                   5'b11000, 5'b10100, 5'b10010, 5'b10001};

                // Space / unknown character
                default: get_glyph = 35'b0;

            endcase

        end

    endfunction

    // =====================================================
    // Which row / column of the letter this pixel is
    // =====================================================

    wire [2:0] row = pixel_y - char_y;      // 0..6
    wire [2:0] col = pixel_x - char_x;      // 0..4

    wire in_glyph = (pixel_x >= char_x) && (pixel_x < char_x + 7'd5) &&
                  (pixel_y >= char_y) && (pixel_y < char_y + 6'd7);

    wire [34:0] glyph = get_glyph(char_code);

    // =====================================================
    // Pick the 5 bits for this row (fixed slices)
    // =====================================================

    reg [4:0] line;

    always @(*) begin
        if      (row == 3'b000) line = glyph[34:30];
        else if (row == 3'b001) line = glyph[29:25];
        else if (row == 3'b010) line = glyph[24:20];
        else if (row == 3'b011) line = glyph[19:15];
        else if (row == 3'b100) line = glyph[14:10];
        else if (row == 3'b101) line = glyph[9:5];
        else if (row == 3'b110) line = glyph[4:0];
        else                    line = 5'b00000;
    end

    // =====================================================
    // Leftmost pixel = MSB of the row
    // =====================================================

    always @(*) begin
        if (in_glyph) pixel_on = line[3'd4 - col];
        else        pixel_on = 1'b0;
    end

endmodule