`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2026 16:17:04
// Design Name: 
// Module Name: Part3_Test_Top
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


module Part3_Test_Top (
    input         CLOCK, BTNC, BTNL, BTNR, BTNU, BTND,
    input  [15:0] switch,
    output [7:0]  JX,
    output [15:0] LED,
    output [7:0]  seg,
    output [3:0]  anode
);
    // ===== clocks and reset =====
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

    // ===== player buttons and test switches (Oliver's debouncer) =====
    wire left, right, block, jump, punch;
    wire fire_pulse, ult_pulse, shield_pulse;
    button_input b_l (.CLOCK(CLOCK), .reset(sys_reset), .raw_button(BTNL), .held(left),  .pressed());
    button_input b_r (.CLOCK(CLOCK), .reset(sys_reset), .raw_button(BTNR), .held(right), .pressed());
    button_input b_d (.CLOCK(CLOCK), .reset(sys_reset), .raw_button(BTND), .held(block), .pressed());
    button_input b_u (.CLOCK(CLOCK), .reset(sys_reset), .raw_button(BTNU), .held(),      .pressed(jump));
    button_input b_c (.CLOCK(CLOCK), .reset(sys_reset), .raw_button(BTNC), .held(),      .pressed(punch));
    button_input b_fb(.CLOCK(CLOCK), .reset(sys_reset), .raw_button(switch[10]), .held(), .pressed(fire_pulse));
    button_input b_ul(.CLOCK(CLOCK), .reset(sys_reset), .raw_button(switch[11]), .held(), .pressed(ult_pulse));
    button_input b_sh(.CLOCK(CLOCK), .reset(sys_reset), .raw_button(switch[13]), .held(), .pressed(shield_pulse));

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

    wire game_reset = sys_reset || match_reset;

    // ===== fighter wires =====
    wire [6:0] p_x, p_feet, p_bl, p_br, p_bt, p_bb, p_al, p_ar, p_at, p_ab;
    wire [6:0] c_x, c_feet, c_bl, c_br, c_bt, c_bb, c_al, c_ar, c_at, c_ab;
    wire [3:0] p_state, c_state;
    wire p_face, p_blocking, p_atk_active, p_atk_start;
    wire c_face, c_blocking, c_atk_active, c_atk_start;
    wire p1_hit, p1_push_right, cpu_hit, cpu_push_right;

    // ===== Yuhan's CPU =====
    wire cpu_left, cpu_right, cpu_block, cpu_jump, cpu_punch, cpu_fireball, cpu_dash;

    wire cpu_busy = !fight_active ||
                    (c_state == 4'b0100) ||     // PUNCH
                    (c_state == 4'b0101) ||     // HITSTUN
                    (c_state == 4'b0110);       // KO

    wire [1:0] personality = switch[12] ? 2'b10 : 2'b00;   // up = Zoner, down = Aggressive
    wire [1:0] difficulty  = 2'b01;                         // medium (until Yuhan's menu)

    c_cpu yuhan_cpu (
        .CLOCK(CLOCK), .reset(game_reset), .tick(tick),
        .player_x(p_x), .cpu_x(c_x), .cpu_state(c_state), .cpu_busy(cpu_busy),
        .difficulty(difficulty), .personality(personality),
        .cpu_left(cpu_left), .cpu_right(cpu_right), .cpu_block(cpu_block),
        .cpu_jump(cpu_jump), .cpu_punch(cpu_punch),
        .cpu_fireball(cpu_fireball), .cpu_dash(cpu_dash)
    );

    // ===== Oliver's fighters =====
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
        .left_held (cpu_left  && fight_active),
        .right_held(cpu_right && fight_active),
        .block_held(cpu_block && fight_active),
        .jump_pressed (cpu_jump  && fight_active),
        .punch_pressed(cpu_punch && fight_active),
        .special_pressed(1'b0),
        .opponent_x(p_x),
        .hit_valid(cpu_hit), .hit_push_right(cpu_push_right), .ko(cpu_hp == 7'b0000000),
        .x(c_x), .feet_y(c_feet), .state(c_state), .face_right(c_face),
        .blocking(c_blocking), .attack_active(c_atk_active), .attack_start(c_atk_start),
        .body_left(c_bl), .body_right(c_br), .body_top(c_bt), .body_bottom(c_bb),
        .attack_left(c_al), .attack_right(c_ar), .attack_top(c_at), .attack_bottom(c_ab),
        .action_frame()
    );

    // ===== OLED pixel position =====
    wire [12:0] pixel_index;
    wire [6:0] sx = pixel_index % 96;
    wire [5:0] sy = pixel_index / 96;

    // ===== Karthi's specials: player copy =====
    wire        fb_active, ult_active, shield_up, fb_hit, ult_hit;
    wire [6:0]  fb_x, fb_y, ult_px, ult_py;
    wire        sp_visible;
    wire [15:0] sp_colour;
    wire [13:0] sp_led;

    special_top specials (
        .CLOCK(CLOCK), .reset(game_reset),
        .tick(tick && fight_active),
        .playing(fight_active), .ko(ko_phase),
        .pixel_index(pixel_index),
        .sw(switch[9:0]),
        .fire_btn(fire_pulse && fight_active),
        .def_btn(shield_pulse && fight_active),
        .dash_input(1'b0),
        .ult_btn(ult_pulse && fight_active),
        .fighter_x(p_x), .feet_y(p_feet),
        .face_right(p_face), .state(p_state),
        .attack_top(p_at), .attack_bottom(p_ab),
        .dash_active(), .dash_x(),
        .sp_visible(sp_visible), .sp_colour(sp_colour),
        .sp_led(sp_led),
        .fb_hit(fb_hit), .ult_hit(ult_hit),
        .fb_active(fb_active), .fb_x(fb_x), .fb_y(fb_y),
        .ult_active(ult_active), .ult_px(ult_px), .ult_py(ult_py),
        .shield_up(shield_up)
    );

    // ===== Karthi's specials: CPU copy (fireball only for now) =====
    wire        cfb_active, cfb_hit;
    wire [6:0]  cfb_x, cfb_y;
    wire        csp_visible;
    wire [15:0] csp_colour;

    special_top cpu_specials (
        .CLOCK(CLOCK), .reset(game_reset),
        .tick(tick && fight_active),
        .playing(fight_active), .ko(ko_phase),
        .pixel_index(pixel_index),
        .sw(10'b0000000000),
        .fire_btn(cpu_fireball && fight_active),
        .def_btn(1'b0),
        .dash_input(1'b0),
        .ult_btn(1'b0),
        .fighter_x(c_x), .feet_y(c_feet),
        .face_right(c_face), .state(c_state),
        .attack_top(c_at), .attack_bottom(c_ab),
        .dash_active(), .dash_x(),
        .sp_visible(csp_visible), .sp_colour(csp_colour),
        .sp_led(),
        .fb_hit(cfb_hit), .ult_hit(1'b0),
        .fb_active(cfb_active), .fb_x(cfb_x), .fb_y(cfb_y),
        .ult_active(), .ult_px(), .ult_py(),
        .shield_up()
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

        .p1_fb_active(fb_active),   .p1_fb_x(fb_x),    .p1_fb_y(fb_y),
        .p1_ult_active(ult_active), .p1_ult_x(ult_px), .p1_ult_y(ult_py),
        .p1_shield(shield_up), .cpu_shield(1'b0),

        .cpu_fb_active(cfb_active), .cpu_fb_x(cfb_x), .cpu_fb_y(cfb_y),

        .p1_hp(p1_hp), .cpu_hp(cpu_hp),
        .p1_hit(p1_hit), .p1_push_right(p1_push_right),
        .cpu_hit(cpu_hit), .cpu_push_right(cpu_push_right),
        .p1_fb_hit(fb_hit), .p1_ult_hit(ult_hit),
        .cpu_fb_hit(cfb_hit)
    );

    // ===== 7-seg (Part 1) =====
    flow_seg segs (.CLOCK(CLOCK), .phase(phase), .timer(timer), .count(count),
                   .seg(seg), .anode(anode));

    // ===== drawing layers =====
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

    // ===== Part 3: HUD =====                                              // NEW
    wire        hud_vis;
    wire [15:0] hud_col;
    hud h (
        .x(sx), .y(sy),
        .phase(phase), .count(count), .winner(winner), .timer(timer),
        .p1_hp(p1_hp), .cpu_hp(cpu_hp),
        .visible(hud_vis), .colour(hud_col)
    );

    reg [15:0] colour;
    always @(*) begin
        colour = 16'h0000;                       // black sky
        if (sy >= 60)    colour = 16'h07E0;      // green ground
        if (c_vis)       colour = c_col;         // Oliver: CPU
        if (p_vis)       colour = p_col;         // Oliver: player
        if (csp_visible) colour = csp_colour;    // Karthi (CPU copy): CPU fireball
        if (sp_visible)  colour = sp_colour;     // Karthi (player copy): fireball / ult / shield
        if (hud_vis)     colour = hud_col;       // you: bars and text on top      // NEW
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
    assign LED[13:0] = sp_led;
    assign LED[14]   = (c_state == 4'b0101);    // CPU in HITSTUN
    assign LED[15]   = (p_state == 4'b0101);    // player in HITSTUN
endmodule
