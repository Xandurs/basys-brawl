`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.10.2026 20:48:16
// Design Name: 
// Module Name: Part1_Test_Top
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



// Part 1 test: game flow + 7-seg, using Oliver's game_tick and button_input.
// SW15 reset | BTNC start | SW14 pause
// SW12 fake player KO | SW13 fake CPU KO | SW10 player at half health
module Part1_Test_Top (
    input         CLOCK, BTNC,
    input         BTNL, BTNR, BTNU, BTND,   // unused here, just to match Constraints.xdc
    input  [15:0] switch,
    output [7:0]  JX,
    output [15:0] LED,
    output [7:0]  seg,
    output [3:0]  anode
);
    // ----- 6.25 MHz OLED clock (same as Oliver's top) -----
    reg [3:0] oled_count = 4'b0000;
    always @(posedge CLOCK) oled_count <= oled_count + 1;
    wire oled_clock = oled_count[3];

    // ----- synchronised reset from SW15 -----
    reg r1 = 1'b1, r2 = 1'b1;
    always @(posedge CLOCK) begin
        r1 <= switch[15];
        r2 <= r1;
    end
    wire sys_reset = r2;

    // ----- Oliver's modules -----
    wire tick, start_pulse;
    game_tick    timing  (.CLOCK(CLOCK), .reset(sys_reset), .tick(tick));
    button_input b_start (.CLOCK(CLOCK), .reset(sys_reset), .raw_button(BTNC),
                          .held(), .pressed(start_pulse));

    // ----- fake health until Part 2 -----
    reg [6:0] p1_hp, cpu_hp;
    always @(*) begin
        if (switch[12])      p1_hp = 7'b0000000;   // 0   : player KO
        else if (switch[10]) p1_hp = 7'b0110010;   // 50  : half health
        else                 p1_hp = 7'b1100100;   // 100 : full health

        if (switch[13])      cpu_hp = 7'b0000000;  // 0   : CPU KO
        else                 cpu_hp = 7'b1100100;  // 100 : full health
    end

    // ----- your game flow -----
    wire [2:0] phase;
    wire [5:0] timer;
    wire [1:0] count, winner;
    wire match_reset, fight_active, fighter_playing, ko_phase;

    game_flow flow (
        .CLOCK(CLOCK), .reset(sys_reset), .tick(tick),
        .start_pulse(start_pulse), .pause_sw(switch[14]),
        .p1_hp(p1_hp), .cpu_hp(cpu_hp),
        .phase(phase), .timer(timer), .count(count), .winner(winner),
        .match_reset(match_reset), .fight_active(fight_active),
        .fighter_playing(fighter_playing), .ko_phase(ko_phase)
    );

    // ----- your 7-seg -----
    flow_seg segs (
        .CLOCK(CLOCK), .phase(phase), .timer(timer), .count(count),
        .seg(seg), .anode(anode)
    );

    // ----- OLED: one colour per phase (real text comes in Part 3) -----
    wire [12:0] pixel_index;
    reg  [15:0] colour;
    always @(*) begin
        if      (phase == 3'b000) colour = 16'h4208;   // INTRO  : grey
        else if (phase == 3'b001) colour = 16'hFFE0;   // READY  : yellow
        else if (phase == 3'b010) colour = 16'h07E0;   // FIGHT  : green
        else if (phase == 3'b011) colour = 16'h001F;   // PAUSE  : blue
        else if (phase == 3'b100) colour = 16'hF800;   // KO     : red
        else if (phase == 3'b101) colour = 16'hFD20;   // TIMEUP : orange
        else if (phase == 3'b110) begin                // WINNER : colour shows who won
            if      (winner == 2'b01) colour = 16'h07FF;   // player : cyan
            else if (winner == 2'b10) colour = 16'hF81F;   // CPU    : magenta
            else                      colour = 16'hFFFF;   // draw   : white
        end
        else                      colour = 16'h0000;
    end

    Oled_Display oled (
        .clk(oled_clock), .reset(sys_reset),
        .frame_begin(), .sending_pixels(), .sample_pixel(),
        .pixel_index(pixel_index), .pixel_data(colour),
        .cs(JX[0]), .sdin(JX[1]), .sclk(JX[3]), .d_cn(JX[4]),
        .resn(JX[5]), .vccen(JX[6]), .pmoden(JX[7])
    );
    assign JX[2] = 1'b0;

    // ----- LEDs for debugging -----
    assign LED[2:0]  = phase;            // which state, in binary
    assign LED[4:3]  = winner;           // 01 player, 10 CPU, 11 draw
    assign LED[5]    = fight_active;
    assign LED[6]    = fighter_playing;
    assign LED[14:7] = 8'b00000000;
    assign LED[15]   = sys_reset;
endmodule