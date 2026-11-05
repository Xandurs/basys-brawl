module special_top(
    input CLOCK, reset, tick, playing, ko,
    input [12:0] pixel_index,
    input [9:0]  sw,                   // code switches for ult_manager (sw[9:0] only)

    // buttons
    input fire_btn,                    // fireball (you used punch)
    input def_btn,                     // defence (you used block)
    input dash_back_input,                                      
    input dash_input,                  // raw dash switch (edge detect moved in here)
    input ult_btn,                     // ult button (pick one that doesn't also punch)

    // from the player's fighter
    input [6:0] fighter_x, feet_y,
    input face_right,
    input [3:0] state,
    input [6:0] attack_top, attack_bottom,

    // to the fighter / drawing
    output dash_active,
    output [6:0] dash_x,

    // merged overlay out
    output reg        sp_visible,
    output reg [15:0] sp_colour,

    // LEDs: [9:0] code hints, [10] ult ready, [11] dash, [12] def, [13] fireball
    output [13:0] sp_led,
    
    //link to Xander's combat module
    input fb_hit,               // combat: fireball connected
    input ult_hit,              // combat: ult shot connected
    output fb_active,
    output [6:0] fb_x, fb_y,
    output ult_active,
    output [6:0] ult_px, ult_py,
    output shield_up
);

    // ---------- dash edge detect (moved here from fighter_demo_core) ----------
    reg dash_prev = 0, dash_back_prev = 0;
    always @(posedge CLOCK) begin
        if (reset) begin dash_prev <= 0; dash_back_prev <= 0; end
        else begin dash_prev <= dash_input; dash_back_prev <= dash_back_input; end
    end
    wire dash_forward_pulse = dash_input && !dash_prev;
    wire dash_backward_pulse = dash_back_input && !dash_back_prev;
    wire dash_pulse = dash_forward_pulse || dash_backward_pulse;

    // ---------- sp1: fireball ----------
    wire [15:0] fb_colour;  wire fb_visible;
    special_fireball sp1(
        .CLOCK(CLOCK), .reset(reset), .tick(tick),
        .playing(playing), .ko(ko),
        .pixel_index(pixel_index),
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
        .dash_pressed(dash_pulse),
        .dash_backward(dash_backward_pulse && !dash_forward_pulse),
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
        .ult_unlocked(unl1),
        .led(sp_led[9:0])
    );

    special_ult sp4(
        .CLOCK(CLOCK), .reset(reset), .tick(tick),
        .playing(playing), .ko(ko),
        .pixel_index(pixel_index),
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

    // ---------- merge overlays (later line = higher priority) ----------
    always @(*) begin
        sp_visible = 1'b0;
        sp_colour  = 16'h0000;
        if (fb_visible)  begin sp_visible = 1'b1; sp_colour = fb_colour;  end
        if (def_visible) begin sp_visible = 1'b1; sp_colour = def_colour; end
        if (ult_visible) begin sp_visible = 1'b1; sp_colour = ult_colour; end
    end
endmodule