`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2026 15:28:39
// Design Name: 
// Module Name: hud
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


`timescale 1ns / 1ps
// Basys Brawl HUD (Xander): health bars, super meter, phase text.
module hud(
    input[6:0] x,
    input[5:0] y,
    input[2:0] phase,
    input[1:0] count,
    input[1:0] winner,          // 01 P1, 10 P2, 11 draw
    input[5:0] timer,
    input      turn,            // NEW: 0 = P1, 1 = P2
    input[6:0] p1_hp,
    input[6:0] cpu_hp,
    input[6:0] p1_meter,

    output reg visible,
    output reg[15:0] colour
    );
    localparam INTRO = 3'b000, READY = 3'b001, FIGHT = 3'b010, PAUSE = 3'b011;
    localparam KO = 3'b100, TIMEUP = 3'b101, WINNER = 3'b110, TURN_END = 3'b111;
    localparam MATCH_SECS = 6'b111100;

    localparam WHITE = 16'hFFFF, YELLOW = 16'hFFE0, RED = 16'hF800;
    localparam GREEN = 16'h07E0, ORANGE = 16'hFD20, GREY = 16'h4208;
    localparam CYAN  = 16'h07FF;

    localparam [4:0] SP = 5'b00000, A = 5'b00001, C = 5'b00010, D = 5'b00011,
                     E  = 5'b00100, F = 5'b00101, G = 5'b00110, H = 5'b00111,
                     I  = 5'b01000, K = 5'b01001, M = 5'b01010, N = 5'b01011,
                     O  = 5'b01100, P = 5'b01101, R = 5'b01110, S = 5'b01111,
                     T  = 5'b10000, U = 5'b10001, W = 5'b10010, Y = 5'b10011,
                     DOT = 5'b10100, BANG = 5'b10101, ONE = 5'b10110, TWO = 5'b10111;

    localparam [39:0] MSG_PRESS  = {P, R, E, S, S, SP, C, SP};       // PRESS C
    localparam [39:0] MSG_FIGHT  = {F, I, G, H, T, BANG, SP, SP};    // FIGHT!
    localparam [39:0] MSG_PAUSE  = {P, A, U, S, E, SP, SP, SP};      // PAUSE
    localparam [39:0] MSG_KO     = {K, DOT, O, DOT, SP, SP, SP, SP}; // K.O.
    localparam [39:0] MSG_TIME   = {T, I, M, E, SP, U, P, SP};       // TIME UP
    localparam [39:0] MSG_P1TURN = {P, ONE, SP, T, U, R, N, SP};     // P1 TURN
    localparam [39:0] MSG_P2TURN = {P, TWO, SP, T, U, R, N, SP};     // P2 TURN
    localparam [39:0] MSG_P2RDY  = {P, TWO, SP, R, E, A, D, Y};      // P2 READY
    localparam [39:0] MSG_P1WIN  = {P, ONE, SP, W, I, N, S, SP};     // P1 WINS
    localparam [39:0] MSG_P2WIN  = {P, TWO, SP, W, I, N, S, SP};     // P2 WINS
    localparam [39:0] MSG_DRAW   = {D, R, A, W, SP, SP, SP, SP};     // DRAW

    //1. which message
    reg[39:0] msg;
    reg[3:0]  len;
    reg[15:0] text_col;
    reg       show_text;

    always @(*) begin
        show_text = 1'b1;
        msg = MSG_PRESS;
        len = 4'b0111;
        text_col = WHITE;

        if (phase == INTRO) begin
            msg = MSG_PRESS; len = 4'b0111; text_col = WHITE;       // hidden behind the menu
        end
        else if (phase == READY) begin                              // whose turn, above the countdown
            if (turn) begin msg = MSG_P2TURN; len = 4'b0111; text_col = CYAN; end
            else      begin msg = MSG_P1TURN; len = 4'b0111; text_col = CYAN; end
        end
        else if (phase == FIGHT && timer == MATCH_SECS) begin
            msg = MSG_FIGHT; len = 4'b0110; text_col = YELLOW;
        end
        else if (phase == PAUSE) begin
            msg = MSG_PAUSE; len = 4'b0101; text_col = WHITE;
        end
        else if (phase == KO) begin
            msg = MSG_KO; len = 4'b0100; text_col = RED;
        end
        else if (phase == TIMEUP) begin
            msg = MSG_TIME; len = 4'b0111; text_col = ORANGE;
        end
        else if (phase == TURN_END) begin
            msg = MSG_P2RDY; len = 4'b1000; text_col = CYAN;
        end
        else if (phase == WINNER) begin
            if      (winner == 2'b01) begin msg = MSG_P1WIN; len = 4'b0111; text_col = YELLOW; end
            else if (winner == 2'b10) begin msg = MSG_P2WIN; len = 4'b0111; text_col = YELLOW; end
            else                      begin msg = MSG_DRAW;  len = 4'b0100; text_col = WHITE;  end
        end
        else begin
            show_text = 1'b0;
        end
    end

    // 2. where the text goes 
    // READY: text near the top (y 10), so it sits above the countdown digit
    wire [5:0] text_y = (phase == READY) ? 6'b001010 : 6'b011001;   // 10 or 25
    wire [6:0] text_w = len * 7'b0001100 - 7'b0000010;
    wire [6:0] text_x = (7'b1100000 - text_w) >> 1;

    wire in_text_box = show_text &&
                       (x >= text_x) && (x < text_x + text_w) &&
                       (y >= text_y) && (y < text_y + 6'b001110);

    wire [6:0] rel_x = x - text_x;
    wire [2:0] idx   = rel_x / 7'b0001100;
    wire [3:0] col12 = rel_x % 7'b0001100;
    wire [2:0] gcol  = col12 >> 1;
    wire [2:0] grow  = (y - text_y) >> 1;

    wire [4:0] ch = msg[(39 - idx * 5) -: 5];
    wire [4:0] row_bits;
    font5x7 font (.ch(ch), .row(grow), .bits(row_bits));
    wire text_on = in_text_box && (col12 < 4'b1010) && row_bits[3'b100 - gcol];

    //3. countdown digit (moved down to y 24)
    wire digit_on;
    digit_pixel #(.W(18), .H(25), .T(4)) countdown (
        .x(x), .y(y), .x0(7'b0100111), .y0(6'b011000),      // (39, 24)
        .digit({2'b00, count}), .on(digit_on)
    );

    //4. health bars + super meter 
    wire [7:0] p_w = (p1_hp    * 8'b00000010) / 8'b00000101;
    wire [7:0] c_w = (cpu_hp   * 8'b00000010) / 8'b00000101;
    wire [7:0] m_w = (p1_meter * 8'b00000010) / 8'b00000101;

    wire bar_row   = (y >= 6'b000001) && (y <= 6'b000100);                 // rows 1-4
    wire meter_row = (y >= 6'b000110) && (y <= 6'b000111);                 // rows 6-7
    wire p_box  = bar_row   && (x >= 7'b0000010) && (x <= 7'b0101001);     // x 2-41
    wire c_box  = bar_row   && (x >= 7'b0110110) && (x <= 7'b1011101);     // x 54-93
    wire m_box  = meter_row && (x >= 7'b0000010) && (x <= 7'b0101001);
    wire p_fill = p_box && (x - 7'b0000010 < p_w);
    wire c_fill = c_box && (7'b1011101 - x < c_w);
    wire m_fill = m_box && (x - 7'b0000010 < m_w);

    reg [15:0] p_bar_col, c_bar_col;
    always @(*) begin
        if      (p1_hp  > 7'b0110010) p_bar_col = GREEN;
        else if (p1_hp  > 7'b0011001) p_bar_col = YELLOW;
        else                          p_bar_col = RED;

        if      (cpu_hp > 7'b0110010) c_bar_col = GREEN;
        else if (cpu_hp > 7'b0011001) c_bar_col = YELLOW;
        else                          c_bar_col = RED;
    end
    wire [15:0] m_col = (p1_meter == 7'b1100100) ? YELLOW : CYAN;

    //5. put it together 
    always @(*) begin
        visible = 1'b0;
        colour  = 16'h0000;

        if (phase != INTRO) begin
            if (p_box)  begin visible = 1'b1; colour = GREY;      end
            if (p_fill) begin visible = 1'b1; colour = p_bar_col; end
            if (c_box)  begin visible = 1'b1; colour = GREY;      end
            if (c_fill) begin visible = 1'b1; colour = c_bar_col; end
            if (m_box)  begin visible = 1'b1; colour = GREY;      end
            if (m_fill) begin visible = 1'b1; colour = m_col;     end
        end

        if (phase == READY && digit_on) begin visible = 1'b1; colour = YELLOW; end

        if (text_on) begin visible = 1'b1; colour = text_col; end
    end
endmodule
