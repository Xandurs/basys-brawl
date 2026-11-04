`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2026 07:15:41 PM
// Design Name: 
// Module Name: atk_fireball
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

module special_fireball(
    // ---- shared inputs from top level ----
    input CLOCK,                        // FPGA clock 100MHz
    input reset,                        // reset button
    input tick,                         // one pulse per game frame, basically oled clock
    input playing,                      // match is live
    input ko,                           // someone is KO'd
    input [12:0] pixel_index,           //pixel location
    output reg [15:0] oled_data,    // oled output
    output reg visible,             // oled output overlay
    // ---- btnC input ----
    input fire_pressed,                 // debounced button pulse for this player

    // ---- from THIS player's fighter (existing outputs) ----
    input [6:0] fighter_x,              // x-axis position of left edge
    //input [6:0] feet_y,                 // y-axis position of base of fighter
    input face_right,                   // direction of facing, 1 -> right facing
    input [3:0] state,                  // to block firing in HITSTUN/KO etc.
    input [6:0] attack_top, input [6:0] attack_bottom,// projectile zone

    // ---- from the hit module ----
    input fb_hit,                       // fireball connected, so remove it

    // ---- out to the hit module ---- //
    //output reg        fb_active,
    //output reg [6:0]  fb_left, fb_right,
    //output [6:0]      fb_top, fb_bottom,
    //output            fb_push_right,

    // ---- out to the board ----
    output fb_ready,       // cooldown finished (drive an LED)
    //out to hit module 
    output fb_active,      //fireball is on screen
    output[6:0] fb_x, fb_y //fireball centre                   
);

    // ---- settings you may override per instance ----
    parameter COOLDOWN = 90;           // 3s at 60 ticks/s
    parameter projectile_speed = 2;     // pixels per tick (tune later)
    parameter radius = 3;               // fireball radius in pixels
    
    // ---- fixed constants (must match the fighter) ----
    localparam IDLE = 0, WALK = 1, JUMP = 2, BLOCK = 3;
    localparam PUNCH = 4, HITSTUN = 5, KO = 6, SPECIAL = 7;
    
    reg fire_lock = 0; //fire lock when cooldown
    reg fired = 0; //fire active and moving
    reg fire_input, fire_pending;
    reg [7:0] countdown = COOLDOWN -1;        //countdown inside sequential block
    reg direction = 0; // to check direction; EDGE CASE when after fire i change dir, to prevent ball from reversing
    reg [6:0] x,y,fireball_x,fireball_y; // x and y axis value
    reg [6:0] displacement = 0; //used to compile movement of the fireball from original position 
    
    assign fb_ready = !fire_lock;
    assign fb_active = fired; //sets fired to 1 when the fireball launches, and 0 when its gone 
    assign fb_x = fireball_x; //centre of the fireball
    assign fb_y = fireball_y;
    
    always @(posedge CLOCK) begin
        if (reset) begin
            fired <= 0;
            fire_lock <= 0;
            fire_pending <= 0;
            displacement <= 0;
            countdown <= COOLDOWN - 1;
        end else begin
            if (fire_pressed) fire_pending <= 1;       // runs every clock, so a short press is never missed

            if (tick) begin                            // everything below runs once per game frame
                fire_pending <= 0;                     // consumed (same idea as the fighter's punch_wait)

                if (fire_pending && !fire_lock && !fired) begin
                    fired <= 1;
                    fire_lock <= 1;
                    direction <= face_right;
                    displacement <= 0;
                    fireball_x <= face_right ? (fighter_x + 12) : fighter_x;
                    fireball_y <= (attack_bottom+attack_top)/2; 
                end

                if (fired) begin
                    if (fireball_x >= 100 || fireball_x == 0 || fb_hit) begin
                        fired <= 0;
                    end else if (direction)
                        fireball_x <= fireball_x + projectile_speed;
                    else
                        fireball_x <= fireball_x - projectile_speed;
                end

                if (fire_lock) countdown <= countdown - 1;

                if (countdown == 0) begin
                    countdown <= COOLDOWN - 1;
                    if (!(state == HITSTUN || state == KO))
                        fire_lock <= 0;
                    end
                end
            end
    end
    
    always @(*) begin
    
        x = pixel_index % 96; //checks for x axis value
        y = pixel_index/96;// check for y axis value
        visible = 1'b0;
        oled_data = 16'h0000;
        
        if(fired) begin //if pending fire action to be completed
            if((x-fireball_x)*(x-fireball_x) + (y-fireball_y)*(y-fireball_y) <= 16) begin
                visible = 1'b1;
                if((x-fireball_x)*(x-fireball_x) + (y-fireball_y)*(y-fireball_y) <= 9) begin
                    if((x-fireball_x)*(x-fireball_x) + (y-fireball_y)*(y-fireball_y) <= 4) begin
                        oled_data = 16'hFFE0; //16'hFDAB; //yellow inside, red outside
                    end 
                    else oled_data = 16'hFD20; //yellow inside, red outside
                end 
                else oled_data = 16'hF800;
            end
        end
    end

endmodule
