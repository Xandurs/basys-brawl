`timescale 1ns / 1ps

module special_top(
    input CLOCK, reset, tick, playing, ko,
    input [12:0] pixel_index,
    input [9:0]  sw,                   // code switches for ult_manager (sw[9:0] only)

    // buttons
    input fire_btn,                    // fireball (you used punch)
    input def_btn,                     // defence (you used block)
    input dash_bkw_input,                                      
    input dash_fwd_input,                  // raw dash switch (edge detect moved in here)
    input ult_btn,                     // ult button (pick one that doesn't also punch)
    input ult_meter_full,              // check ult guage

    // from the player's fighter
    input [6:0] fighter_x, feet_y,          //from fighter, fighter x/y positions
    input face_right,                       //fighter direction
    input [3:0] state,                      //fighter state
    input [6:0] attack_top, attack_bottom,  //attack range (only a reference, some attack didnt use this range)

    // from outside
    input [1:0] character_id,               // character id (for 3 characters)

    // to the fighter / drawing
    output dash_active,                     //dash is active indiation to movement for player
    output [6:0] dash_x,                    // how much to dash to movement for player

    // merged overlay out
    output reg        sp_visible,           //special display 
    output reg [15:0] sp_colour,            //special display colours

    // LEDs: [9:0] code hints, [10] ult ready, [11] dash, [12] def, [13] fireball
    output [13:0] sp_led,
    
    //link to Xander's combat module
    input fb_hit,               // combat: fireball connected
    input ult_hit,              // combat: ult shot connected
    output fb_active,           // combat: fireball is fired
    output [6:0] fb_x, fb_y,    // combat: fireball x and y location
    output ult_active,          // commbat: ult if fired
    output ult_used_out,        // send signal to clear buffer that stores past ult code keyyed 
    output [6:0] ult_px, ult_py,// combat: ult x y location
    output shield_up            // shield active
);

    // ---------- dash edge detect (moved here from fighter_demo_core) ----------
    reg dash_fwd_prev = 0, dash_bkw_prev = 0;
    always @(posedge CLOCK) begin
        if (reset) begin dash_fwd_prev <= 0; dash_bkw_prev <= 0; end //saves the previous state of dash fwd/bkw
        else begin dash_fwd_prev <= dash_fwd_input; dash_bkw_prev <= dash_bkw_input; end
    end
    wire dash_fwd_pulse = dash_fwd_input && !dash_fwd_prev;
    wire dash_bkw_pulse = dash_bkw_input && !dash_bkw_prev;

    // ---------- sp1: fireball ----------
    wire [15:0] fb_colour;  wire fb_visible;
    special_fireball sp1(
        .CLOCK(CLOCK), .reset(reset), .tick(tick),
        .playing(playing), .ko(ko),
        .pixel_index(pixel_index),
        .character_id(character_id),
        .oled_data(fb_colour),
        .fire_pressed(fire_btn),
        .fighter_x(fighter_x), .face_right(face_right), .state(state),
        .attack_top(attack_top), .attack_bottom(attack_bottom),
        .fb_hit(fb_hit),
        .fb_ready(sp_led[13]),
        .visible(fb_visible),
        .fb_active(fb_active), .fb_x(fb_x), .fb_y(fb_y)
    );

    // ---------- sp2: defence ----------
    wire [15:0] def_colour; wire def_visible;
    special_def sp2(
        .CLOCK(CLOCK), .reset(reset), .tick(tick),
        .playing(playing), .ko(ko),
        .pixel_index(pixel_index),
        .character_id(character_id),
        .oled_data(def_colour),
        .def_pressed(def_btn),
        .fighter_x(fighter_x), .state(state),
        .feet_y(feet_y),
        .def_hit(1'b0),
        .def_ready(sp_led[12]),
        .visible(def_visible),
        .shield_up(shield_up)
    );

    // ---------- sp3: dash ----------
    special_dash sp3(
        .CLOCK(CLOCK), .reset(reset), .tick(tick),
        .playing(playing), .ko(ko),
        .pixel_index(pixel_index),
        .dash_pressed_fwd(dash_fwd_pulse && !dash_bkw_pulse),
        .dash_pressed_bkw(dash_bkw_pulse && !dash_fwd_pulse),
        .dashing(dash_active),
        .fighter_x(fighter_x),
        .face_right(face_right),
        .state(state),
        .dash_ready(sp_led[11]),
        .current_x(dash_x)
    );

    // ---------- sp4: ult (manager + ult) ----------
    wire unl1, used1, ult_ready;
    wire [15:0] ult_colour; wire ult_visible;

    ult_manager m1(
        .clk(CLOCK),
        .reset(reset),
        .tick(tick),
        .sw(sw),
        .btnC(ult_btn),                // unused inside manager
        .ult_used(used1),
        .meter_full(ult_meter_full),
        .ult_unlocked(unl1),
        .led(sp_led[9:0])
    );

    special_ult sp4(
        .CLOCK(CLOCK), .reset(reset), .tick(tick),
        .playing(playing), .ko(ko),
        .pixel_index(pixel_index),
        .character_id(character_id),
        .oled_data(ult_colour), .visible(ult_visible),
        .ult_pressed(ult_btn),
        .ult_unlocked(unl1),
        .ult_used(used1),            //now an ouput of sp4
        .fighter_x(fighter_x), .face_right(face_right), .state(state),
        .attack_top(attack_top), .attack_bottom(attack_bottom),
        .ult_hit(ult_hit),
        .ult_ready(ult_ready),
        .ult_active(ult_active), .ult_px(ult_px), .ult_py(ult_py)
       
    );
    assign sp_led[10] = ult_ready;
    assign ult_used_out = used1;

    // ---------- merge overlays (later line = higher priority) ----------
    always @(*) begin
        sp_visible = 1'b0;
        sp_colour  = 16'h0000;
        if (fb_visible)  begin sp_visible = 1'b1; sp_colour = fb_colour;  end
        if (def_visible) begin sp_visible = 1'b1; sp_colour = def_colour; end
        if (ult_visible) begin sp_visible = 1'b1; sp_colour = ult_colour; end
    end
endmodule