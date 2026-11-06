`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2026 16:38:11
// Design Name: 
// Module Name: Top_Basys_Brawl
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


module Top_Basys_Brawl (
    input         CLOCK, BTNC, BTNL, BTNR, BTNU, BTND,
    input  [15:0] switch,
    output [7:0]  JX,
    output [15:0] LED,
    output [7:0]  seg,
    output [3:0]  anode
);
    // =====================================================================
    // CLOCKS AND RESET
    // =====================================================================
    reg [3:0] oled_count = 4'b0000;                 // 6.25 MHz OLED clock
    always @(posedge CLOCK) oled_count <= oled_count + 1;
    wire oled_clock = oled_count[3];

    reg r1 = 1'b1, r2 = 1'b1;                       // SW15 reset, synchronised
    always @(posedge CLOCK) begin
        r1 <= switch[15];
        r2 <= r1;
    end
    wire sys_reset = r2;

    wire tick;                                      // Oliver: 30 Hz game tick
    game_tick timing (.CLOCK(CLOCK), .reset(sys_reset), .tick(tick));

    // =====================================================================
    // INPUTS (Oliver's button_input debouncer)
    // =====================================================================
    wire left, right, block, jump, punch;
    wire fire_pulse, shield_pulse, ult_pulse;
    wire down_pressed;

    button_input b_l  (.CLOCK(CLOCK), .reset(sys_reset), .raw_button(BTNL), .held(left),  .pressed());
    button_input b_r  (.CLOCK(CLOCK), .reset(sys_reset), .raw_button(BTNR), .held(right), .pressed());
    button_input b_d (.CLOCK(CLOCK), .reset(sys_reset), .raw_button(BTND), .held(block), .pressed(down_pressed));
    button_input b_u  (.CLOCK(CLOCK), .reset(sys_reset), .raw_button(BTNU), .held(),      .pressed(jump));
    button_input b_c  (.CLOCK(CLOCK), .reset(sys_reset), .raw_button(BTNC), .held(),      .pressed(punch));

    button_input b_fb (.CLOCK(CLOCK), .reset(sys_reset), .raw_button(switch[10]), .held(), .pressed(fire_pulse));
    button_input b_sh (.CLOCK(CLOCK), .reset(sys_reset), .raw_button(switch[12]), .held(), .pressed(shield_pulse));
    button_input b_ul (.CLOCK(CLOCK), .reset(sys_reset), .raw_button(switch[13]), .held(), .pressed(ult_pulse));
    // switch[11] (dash) is reserved: not connected until Oliver + Karthi link dash to the fighter

    // =====================================================================
    // YUHAN: MENU (only listens to buttons while on the menu screen)
    // =====================================================================
    wire [2:0] phase;                       // declared here because the menu needs it
    wire       in_menu = (phase == 3'b000); // INTRO
    wire [1:0] menu_state, difficulty, personality;
    wire       start_match;

    control_menu menu (
        .CLOCK(CLOCK), .reset(sys_reset),
        .up_pressed    (jump         && in_menu),     // BTNU
        .down_pressed  (down_pressed && in_menu),     // BTND
        .select_pressed(punch        && in_menu),     // BTNC
        .menu_state(menu_state),
        .difficulty(difficulty), .personality(personality),
        .round_count(), .start_match(start_match)
    );
    
    

    // =====================================================================
    // XANDER: GAME FLOW
    // =====================================================================
    wire [6:0] p1_hp, cpu_hp;
    wire [5:0] timer;
    wire [1:0] count, winner;
    wire match_reset, fight_active, fighter_playing, ko_phase;
    wire       turn, p1_ko;
    wire [5:0] p1_time;
    wire [6:0] p1_left;

    game_flow flow (
        .CLOCK(CLOCK), .reset(sys_reset), .tick(tick),
        .start_pulse(start_match), .continue_pulse(punch),
        .pause_sw(switch[14]),
        .p1_hp(p1_hp), .cpu_hp(cpu_hp),
        .phase(phase), .timer(timer), .count(count), .winner(winner),
        .turn(turn), .p1_ko(p1_ko), .p1_time(p1_time), .p1_left(p1_left),
        .match_reset(match_reset), .fight_active(fight_active),
        .fighter_playing(fighter_playing), .ko_phase(ko_phase)
    );

    wire game_reset = sys_reset || match_reset;     // everyone resets for a new match

    // =====================================================================
    // FIGHTER WIRES
    // =====================================================================
    wire [6:0] p_x, p_feet, p_bl, p_br, p_bt, p_bb, p_al, p_ar, p_at, p_ab;
    wire [6:0] c_x, c_feet, c_bl, c_br, c_bt, c_bb, c_al, c_ar, c_at, c_ab;
    wire [3:0] p_state, c_state;
    wire p_face, p_blocking, p_atk_active, p_atk_start;
    wire c_face, c_blocking, c_atk_active, c_atk_start;
    wire p1_hit, p1_push_right, cpu_hit, cpu_push_right;

    // =====================================================================
    // YUHAN: CPU OPPONENT
    // =====================================================================
    wire cpu_left, cpu_right, cpu_block, cpu_jump, cpu_punch, cpu_fireball, cpu_dash;

    // the CPU can't start a new action while punching, stunned, KO'd, or outside the fight
    wire cpu_busy = !fight_active ||
                    (c_state == 4'b0100) ||     // PUNCH
                    (c_state == 4'b0101) ||     // HITSTUN
                    (c_state == 4'b0110);       // KO

    c_cpu yuhan_cpu (
        .CLOCK(CLOCK), .reset(game_reset), .tick(tick),
        .player_x(p_x), .cpu_x(c_x), .cpu_state(c_state), .player_state(p_state), .cpu_busy(cpu_busy),
        .difficulty(difficulty), .personality(personality),
        .cpu_left(cpu_left), .cpu_right(cpu_right), .cpu_block(cpu_block),
        .cpu_jump(cpu_jump), .cpu_punch(cpu_punch),
        .cpu_fireball(cpu_fireball), .cpu_dash(cpu_dash)
    );

    // =====================================================================
    // OLIVER: FIGHTERS (commands only reach them during the fight)
    // =====================================================================
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

    // =====================================================================
    // OLED PIXEL POSITION (shared by every drawing layer)
    // =====================================================================
    wire [12:0] pixel_index;
    wire [6:0] sx = pixel_index % 96;
    wire [5:0] sy = pixel_index / 96;

    // =====================================================================
    // KARTHI: SPECIALS - player copy
    // =====================================================================
    wire        fb_active, ult_active, shield_up, fb_hit, ult_hit;
    wire [6:0]  fb_x, fb_y, ult_px, ult_py;
    wire        sp_visible;
    wire [15:0] sp_colour;
    wire [13:0] sp_led;
    wire[6:0] p1_meter;
    wire p1_meter_full;

    special_top specials (
        .CLOCK(CLOCK), .reset(game_reset),
        .tick(tick && fight_active),            // frozen outside the fight
        .playing(fight_active), .ko(ko_phase),
        .pixel_index(pixel_index),
        .sw(switch[9:0]),                       // ult unlock code
        .fire_btn(fire_pulse   && fight_active),
        .def_btn (shield_pulse && fight_active),
        .dash_input(1'b0),                      // SW11 reserved: not linked to the fighter yet
        .ult_btn (ult_pulse && fight_active && p1_meter_full),
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

    // =====================================================================
    // KARTHI: SPECIALS - CPU copy (fireball only until Yuhan adds shield / ult)
    // =====================================================================
    wire        cfb_active, cfb_hit;
    wire [6:0]  cfb_x, cfb_y;
    wire        csp_visible;
    wire [15:0] csp_colour;

    special_top cpu_specials (
        .CLOCK(CLOCK), .reset(game_reset),
        .tick(tick && fight_active),
        .playing(fight_active), .ko(ko_phase),
        .pixel_index(pixel_index),
        .sw(10'b0000000000),                    // CPU ult locked for now
        .fire_btn(cpu_fireball && fight_active),
        .def_btn(1'b0),                         // waiting on Yuhan: cpu_shield
        .dash_input(1'b0),
        .ult_btn(1'b0),                         // waiting on Yuhan: cpu_ult
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

    // =====================================================================
    // XANDER: COMBAT
    // =====================================================================
    
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
        .p1_shield(shield_up), .cpu_shield(1'b0),   // CPU shield: waiting on Yuhan

        .cpu_fb_active(cfb_active), .cpu_fb_x(cfb_x), .cpu_fb_y(cfb_y),

        .p1_hp(p1_hp), .cpu_hp(cpu_hp),
        .p1_hit(p1_hit), .p1_push_right(p1_push_right),
        .cpu_hit(cpu_hit), .cpu_push_right(cpu_push_right),
        .p1_fb_hit(fb_hit), .p1_ult_hit(ult_hit),
        .cpu_fb_hit(cfb_hit),
        .p1_meter(p1_meter), .p1_meter_full(p1_meter_full)
    );

    // =====================================================================
    // XANDER: 7-SEGMENT (match timer)
    // =====================================================================
    flow_seg segs (.CLOCK(CLOCK), .phase(phase), .timer(timer), .count(count),
                   .turn(turn), .p1_ko(p1_ko), .p1_time(p1_time),
                   .seg(seg), .anode(anode));

    // =====================================================================
    // DRAWING LAYERS
    // =====================================================================
    wire p_vis, c_vis;
    wire [15:0] p_col, c_col;
    fighter_draw p_draw (                       // Oliver
        .pixel_x(sx), .pixel_y(sy), .x(p_x), .feet_y(p_feet),
        .state(p_state), .face_right(p_face), .attack_active(p_atk_active),
        .attack_left(p_al), .attack_right(p_ar),
        .visible(p_vis), .colour(p_col), 
        .body_colour(turn ? 16'h801F : 16'h001F)    // P1 blue, P2 purple
    );
    fighter_draw c_draw (                       // Oliver
        .pixel_x(sx), .pixel_y(sy), .x(c_x), .feet_y(c_feet),
        .state(c_state), .face_right(c_face), .attack_active(c_atk_active),
        .attack_left(c_al), .attack_right(c_ar), .body_colour(16'hF800),
        .visible(c_vis), .colour(c_col)
    );

    wire        hud_vis;
    wire [15:0] hud_col;
    hud h (                                     // Xander
        .x(sx), .y(sy),
        .phase(phase), .count(count), .winner(winner), .timer(timer),
        .p1_hp(p1_hp), .cpu_hp(cpu_hp),
        .p1_meter(p1_meter),
        .turn(turn),
        .visible(hud_vis), .colour(hud_col)
    );
    
    wire [15:0] menu_col;
    menu_render menu_draw (
        .pixel_x(sx), .pixel_y(sy),
        .menu_state(menu_state),
        .difficulty(difficulty), .personality(personality),
        .round_count(2'b00),
        .pixel_data(menu_col)
    );

    // ----- OLED layer mux: later line = drawn on top -----
    reg [15:0] colour;
    always @(*) begin
        colour = 16'h0000;                       // black sky
        if (sy >= 60)    colour = 16'h07E0;      // green ground
        if (c_vis)       colour = c_col;         // Oliver: CPU fighter
        if (p_vis)       colour = p_col;         // Oliver: player fighter
        if (csp_visible) colour = csp_colour;    // Karthi: CPU specials
        if (sp_visible)  colour = sp_colour;     // Karthi: player specials
        if (hud_vis)     colour = hud_col;       // Xander: health bars and text
        if (in_menu)     colour = menu_col;      // Yuhan: menu covers everything in INTRO
    end

    Oled_Display oled (
        .clk(oled_clock), .reset(sys_reset),
        .frame_begin(), .sending_pixels(), .sample_pixel(),
        .pixel_index(pixel_index), .pixel_data(colour),
        .cs(JX[0]), .sdin(JX[1]), .sclk(JX[3]), .d_cn(JX[4]),
        .resn(JX[5]), .vccen(JX[6]), .pmoden(JX[7])
    );
    assign JX[2] = 1'b0;

    
    // =====================================================================
    // LEDS: each "ready" LED sits above its own switch
    // =====================================================================
    assign LED[9:0]  = sp_led[9:0];                    // Karthi: ult code hints (above SW0-SW9)
    assign LED[10]   = sp_led[13];                     // fireball ready  (above SW10)
    assign LED[11]   = sp_led[11];                     // dash ready      (above SW11)
    assign LED[12]   = sp_led[12];                     // shield ready    (above SW12)
    assign LED[13]   = sp_led[10] && p1_meter_full;    // ult ready       (above SW13): code + full meter
    assign LED[14]   = (c_state == 4'b0101);           // CPU in HITSTUN
    assign LED[15]   = (p_state == 4'b0101);           // player in HITSTUN
    
endmodule