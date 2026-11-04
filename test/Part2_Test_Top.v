`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.10.2026 22:32:45
// Design Name: 
// Module Name: Part2_Test_Top
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


module Part2_Test_Top (
    input         CLOCK, BTNC, BTNL, BTNR, BTNU, BTND,
    input  [15:0] switch,
    output [7:0]  JX,
    output [15:0] LED,
    output [7:0]  seg,
    output [3:0]  anode
);
    // ===== clocks and reset (same as Oliver's top) =====
    reg [3:0] oled_count = 4'b0000;
    always @(posedge CLOCK) oled_count <= oled_count + 1;
    wire oled_clock = oled_count[3];

    reg r1 = 1'b1, r2 = 1'b1;
    always @(posedge CLOCK) begin
        r1 <= switch[15];
        r2 <= r1;
    end
    wire sys_reset = r2;

    wire tick;
    game_tick timing (.CLOCK(CLOCK), .reset(sys_reset), .tick(tick));

    // ===== buttons (Oliver's debouncer, same use as fighter_demo_core) =====
    wire left, right, block, jump, punch, cpu_punch;
    button_input b_l (.CLOCK(CLOCK), .reset(sys_reset), .raw_button(BTNL), .held(left),  .pressed());
    button_input b_r (.CLOCK(CLOCK), .reset(sys_reset), .raw_button(BTNR), .held(right), .pressed());
    button_input b_d (.CLOCK(CLOCK), .reset(sys_reset), .raw_button(BTND), .held(block), .pressed());
    button_input b_u (.CLOCK(CLOCK), .reset(sys_reset), .raw_button(BTNU), .held(),      .pressed(jump));
    button_input b_c (.CLOCK(CLOCK), .reset(sys_reset), .raw_button(BTNC), .held(),      .pressed(punch));
    button_input b_cp(.CLOCK(CLOCK), .reset(sys_reset), .raw_button(switch[12]), .held(cpu_punch), .pressed());

    // ===== Part 1: game flow =====
    wire [6:0] p1_hp, cpu_hp;
    wire [2:0] phase;
    wire [5:0] timer;
    wire [1:0] count, winner;
    wire match_reset, fight_active, fighter_playing, ko_phase;

    game_flow flow (
        .CLOCK(CLOCK), .reset(sys_reset), .tick(tick),
        .start_pulse(punch), .pause_sw(switch[14]),
        .p1_hp(p1_hp), .cpu_hp(cpu_hp),
        .phase(phase), .timer(timer), .count(count), .winner(winner),
        .match_reset(match_reset), .fight_active(fight_active),
        .fighter_playing(fighter_playing), .ko_phase(ko_phase)
    );

    wire game_reset = sys_reset || match_reset;   // new match: positions + health reset

    // ===== Oliver's fighters =====
    wire [6:0] p_x, p_feet, p_bl, p_br, p_bt, p_bb, p_al, p_ar, p_at, p_ab;
    wire [6:0] c_x, c_feet, c_bl, c_br, c_bt, c_bb, c_al, c_ar, c_at, c_ab;
    wire [3:0] p_state, c_state;
    wire p_face, p_blocking, p_atk_active, p_atk_start;
    wire c_face, c_blocking, c_atk_active, c_atk_start;
    wire p1_hit, p1_push_right, cpu_hit, cpu_push_right;

    fighter #(.START_X(12), .START_FACE(1)) player (
        .CLOCK(CLOCK), .reset(game_reset), .tick(tick), .playing(fighter_playing),
        .left_held (left  && fight_active),
        .right_held(right && fight_active),
        .block_held(block && fight_active),
        .jump_pressed (jump  && fight_active),
        .punch_pressed(punch && fight_active),
        .special_pressed(1'b0),
        .opponent_x(c_x),
        .hit_valid(p1_hit), .hit_push_right(p1_push_right), .ko(p1_hp == 7'b0000000),
        .x(p_x), .feet_y(p_feet), .state(p_state), .face_right(p_face),
        .blocking(p_blocking), .attack_active(p_atk_active), .attack_start(p_atk_start),
        .body_left(p_bl), .body_right(p_br), .body_top(p_bt), .body_bottom(p_bb),
        .attack_left(p_al), .attack_right(p_ar), .attack_top(p_at), .attack_bottom(p_ab),
        .action_frame()
    );

    fighter #(.START_X(70), .START_FACE(0)) cpu (
        .CLOCK(CLOCK), .reset(game_reset), .tick(tick), .playing(fighter_playing),
        .left_held(1'b0), .right_held(1'b0), .block_held(1'b0),
        .jump_pressed(1'b0),
        .punch_pressed(cpu_punch && fight_active),      // test: SW12 up = keep punching
        .special_pressed(1'b0),
        .opponent_x(p_x),
        .hit_valid(cpu_hit), .hit_push_right(cpu_push_right), .ko(cpu_hp == 7'b0000000),
        .x(c_x), .feet_y(c_feet), .state(c_state), .face_right(c_face),
        .blocking(c_blocking), .attack_active(c_atk_active), .attack_start(c_atk_start),
        .body_left(c_bl), .body_right(c_br), .body_top(c_bt), .body_bottom(c_bb),
        .attack_left(c_al), .attack_right(c_ar), .attack_top(c_at), .attack_bottom(c_ab),
        .action_frame()
    );

    // ===== Part 2: combat =====
    combat cmb (
        .CLOCK(CLOCK), .reset(game_reset), .tick(tick), .fight_active(fight_active),

        .p1_x(p_x), .p1_blocking(p_blocking),
        .p1_attack_start(p_atk_start), .p1_attack_active(p_atk_active),
        .p1_body_left(p_bl), .p1_body_right(p_br), .p1_body_top(p_bt), .p1_body_bottom(p_bb),
        .p1_atk_left(p_al),  .p1_atk_right(p_ar),  .p1_atk_top(p_at),  .p1_atk_bottom(p_ab),

        .cpu_x(c_x), .cpu_blocking(c_blocking),
        .cpu_attack_start(c_atk_start), .cpu_attack_active(c_atk_active),
        .cpu_body_left(c_bl), .cpu_body_right(c_br), .cpu_body_top(c_bt), .cpu_body_bottom(c_bb),
        .cpu_atk_left(c_al),  .cpu_atk_right(c_ar),  .cpu_atk_top(c_at),  .cpu_atk_bottom(c_ab),

        // Karthi's projectiles and shields: tied off until Part 2B
        .p1_fb_active(1'b0),  .p1_fb_x(7'b0000000),  .p1_fb_y(7'b0000000),
        .p1_ult_active(1'b0), .p1_ult_x(7'b0000000), .p1_ult_y(7'b0000000),
        .p1_shield(1'b0), .cpu_shield(1'b0),

        .p1_hp(p1_hp), .cpu_hp(cpu_hp),
        .p1_hit(p1_hit), .p1_push_right(p1_push_right),
        .cpu_hit(cpu_hit), .cpu_push_right(cpu_push_right),
        .p1_fb_hit(), .p1_ult_hit()
    );

    // ===== 7-seg (Part 1) =====
    flow_seg segs (.CLOCK(CLOCK), .phase(phase), .timer(timer), .count(count),
                   .seg(seg), .anode(anode));

    // ===== OLED: Oliver's fighter_draw + test health bars =====
    wire [12:0] pixel_index;
    wire [6:0] sx = pixel_index % 96;
    wire [5:0] sy = pixel_index / 96;

    wire p_vis, c_vis;
    wire [15:0] p_col, c_col;
    fighter_draw p_draw (
        .pixel_x(sx), .pixel_y(sy), .x(p_x), .feet_y(p_feet),
        .state(p_state), .face_right(p_face), .attack_active(p_atk_active),
        .attack_left(p_al), .attack_right(p_ar), .body_colour(16'h001F),
        .visible(p_vis), .colour(p_col)
    );
    fighter_draw c_draw (
        .pixel_x(sx), .pixel_y(sy), .x(c_x), .feet_y(c_feet),
        .state(c_state), .face_right(c_face), .attack_active(c_atk_active),
        .attack_left(c_al), .attack_right(c_ar), .body_colour(16'hF800),
        .visible(c_vis), .colour(c_col)
    );

    // test bars: width = hp / 2 (max 50 px). Player from the left, CPU from the right.
    wire p_bar = (sy >= 1 && sy <= 3) && (sx < p1_hp[6:1]);
    wire c_bar = (sy >= 5 && sy <= 7) && (sx >= 7'b1100000 - cpu_hp[6:1]);   // 96 - hp/2

    reg [15:0] colour;
    always @(*) begin
        colour = 16'h0000;                          // black sky
        if (sy >= 60) colour = 16'h07E0;            // green ground
        if (p_bar)    colour = 16'h001F;            // player bar: blue
        if (c_bar)    colour = 16'hF800;            // CPU bar: red
        if (c_vis)    colour = c_col;
        if (p_vis)    colour = p_col;               // player drawn on top
    end

    Oled_Display oled (
        .clk(oled_clock), .reset(sys_reset),
        .frame_begin(), .sending_pixels(), .sample_pixel(),
        .pixel_index(pixel_index), .pixel_data(colour),
        .cs(JX[0]), .sdin(JX[1]), .sclk(JX[3]), .d_cn(JX[4]),
        .resn(JX[5]), .vccen(JX[6]), .pmoden(JX[7])
    );
    assign JX[2] = 1'b0;

    // ===== LEDs =====
    assign LED[2:0]   = phase;
    assign LED[4:3]   = winner;
    assign LED[5]     = fight_active;
    assign LED[9:6]   = 4'b0000;
    assign LED[13:10] = p_state;                       // Oliver's state numbers
    assign LED[14]    = (c_state == 4'b0101);          // CPU in HITSTUN
    assign LED[15]    = (p_state == 4'b0101);          // player in HITSTUN
endmodule
