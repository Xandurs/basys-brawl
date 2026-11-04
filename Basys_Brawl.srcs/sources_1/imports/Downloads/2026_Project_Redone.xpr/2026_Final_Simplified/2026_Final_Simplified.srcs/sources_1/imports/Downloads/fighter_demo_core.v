`timescale 1ns / 1ps
module fighter_demo_core(
    input CLOCK, raw_reset, BTNL, BTNR, BTNU, BTND, BTNC,
    input raw_test_hit, raw_test_ko,
    input [12:0] pixel_index,
    output reg [15:0] pixel_colour,
    output [3:0] player_state, cpu_state,
    output tick 
);
    reg reset1 = 1, reset2 = 1;
    always @(posedge CLOCK) begin
        reset1 <= raw_reset; reset2 <= reset1;
    end
    wire left, right, block, jump, punch, hit, ko;
    game_tick timing(.CLOCK(CLOCK), .reset(reset2), .tick(tick));
    button_input b0(.CLOCK(CLOCK), .reset(reset2), .raw_button(BTNL), .held(left), .pressed()); //left
    button_input b1(.CLOCK(CLOCK), .reset(reset2), .raw_button(BTNR), .held(right), .pressed()); //right
    button_input b2(.CLOCK(CLOCK), .reset(reset2), .raw_button(BTND), .held(block), .pressed()); //down
    button_input b3(.CLOCK(CLOCK), .reset(reset2), .raw_button(BTNU), .held(), .pressed(jump)); //up
    button_input b4(.CLOCK(CLOCK), .reset(reset2), .raw_button(BTNC), .held(), .pressed(punch)); //centre
    button_input b5(.CLOCK(CLOCK), .reset(reset2), .raw_button(raw_test_hit), .held(), .pressed(hit));  //connected to switch 12, used for testing a hit on player
    button_input b6(.CLOCK(CLOCK), .reset(reset2), .raw_button(raw_test_ko), .held(ko), .pressed()); //switch 13, tests KO

    wire [6:0] px, py, cx, cy, pl, pr, cl, cr;
    wire pf, cf, pa, ca;
    
    fighter #(.START_X(12), .START_FACE(1)) player(
        .CLOCK(CLOCK), .reset(reset2), .tick(tick), .playing(1'b1),
        .left_held(left), .right_held(right), .block_held(block),
        .jump_pressed(jump), .punch_pressed(punch), .special_pressed(1'b0),
        .opponent_x(cx), .hit_valid(hit), .hit_push_right(1'b0), .ko(ko),
        .x(px), .feet_y(py), .state(player_state), .face_right(pf),
        .attack_active(pa), .attack_left(pl), .attack_right(pr)
    );
    // AI fighter for now
    fighter #(.START_X(70), .START_FACE(0)) cpu(
        .CLOCK(CLOCK), .reset(reset2), .tick(tick), .playing(1'b1),
        .left_held(1'b0), .right_held(1'b0), .block_held(1'b0),
        .jump_pressed(1'b0), .punch_pressed(1'b0), .special_pressed(1'b0),
        .opponent_x(px), .hit_valid(1'b0), .hit_push_right(1'b0), .ko(1'b0),
        .x(cx), .feet_y(cy), .state(cpu_state), .face_right(cf),
        .attack_active(ca), .attack_left(cl), .attack_right(cr)
    );
    wire [6:0] screen_x;
    wire [5:0] screen_y;
    assign screen_x = pixel_index % 96;
    assign screen_y = pixel_index / 96;
    wire p_visible, c_visible;
    wire [15:0] p_colour, c_colour;
    
    fighter_draw p_draw(
        .pixel_x(screen_x), .pixel_y(screen_y), .x(px), .feet_y(py),
        .state(player_state), .face_right(pf), .attack_active(pa),
        .attack_left(pl), .attack_right(pr), .body_colour(16'h001F),
        .visible(p_visible), .colour(p_colour)
    );
    fighter_draw c_draw(
        .pixel_x(screen_x), .pixel_y(screen_y), .x(cx), .feet_y(cy),
        .state(cpu_state), .face_right(cf), .attack_active(ca),
        .attack_left(cl), .attack_right(cr), .body_colour(16'hF800),
        .visible(c_visible), .colour(c_colour)
    );
    always @(*) begin
        pixel_colour = 16'h0000;
        if (screen_y >= 60) pixel_colour = 16'h07E0;
        if (c_visible) pixel_colour = c_colour;
        if (p_visible) pixel_colour = p_colour;
    end
endmodule
