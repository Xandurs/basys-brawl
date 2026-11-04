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

module special_dash(
    // ---- shared inputs from top level ----
    input CLOCK,                        // FPGA clock 100MHz
    input reset,                        // reset button
    input tick,                         // one pulse per game frame, basically oled clock
    input playing,                      // match is live
    input ko,                           // someone is KO'd
    input [12:0] pixel_index,           //pixel location
    
    // ---- btnC input ----
    input dash_pressed,                 // takes sw[11] as input, detect high to activate dash
    output reg dashing,                 // used to output dashing state to fighter mod so that fighter mod check for dashes and update x, before executing any other movement
    // ---- from THIS player's fighter (existing outputs) ----
    input [6:0] fighter_x,              // x-axis position of left edge
    input face_right,                   // direction of facing, 1 -> right facing
    input [3:0] state,                  // to block dash in HITSTUN/KO etc.

    // ---- out to the hit module ---- //
    //output reg        fb_active,
    //output reg [6:0]  fb_left, fb_right,
    //output [6:0]      fb_top, fb_bottom,
    //output            fb_push_right,

    // ---- out to the board ----
    output dash_ready ,                    // cooldown finished (drive an LED)
    output reg [6:0] current_x
);

    // ---- settings you may override per instance ----
    parameter COOLDOWN = 240;           // 8s at 30 ticks/s
    reg [4:0] dist_covered = 19;     // pixels covered
    
    // ---- fixed constants (must match the fighter) ----
    localparam IDLE = 0, WALK = 1, JUMP = 2, BLOCK = 3;
    localparam PUNCH = 4, HITSTUN = 5, KO = 6, SPECIAL = 7;
    
    reg dash_lock = 0; //dash lock when cooldown
    //reg dashing = 0; //dash active and moving
    reg dash_input; reg dash_input_count = 0;
    reg dash_pending;
    reg [7:0] countdown = COOLDOWN -1;        //countdown inside sequential block
    reg direction = 0; // to check direction;
    reg [6:0] x,y; // x and y axis value
    reg [3:0] displacement = 0; //used to compile movement of the player from original position 
 
    assign dash_ready = !dash_lock;
    
    always @(posedge CLOCK) begin
        if (reset) begin
            dashing <= 0;
            dash_lock <= 0;
            direction <= face_right;
            dist_covered <= 25;
            countdown <= COOLDOWN -1;
            dash_pending <= 0;
            displacement <= 0;
            current_x <= fighter_x;
        end else begin
            if (dash_pressed) begin
                dash_pending <= 1;       // runs every clock, so a short press is never missed
            end
            if (tick) begin                            // everything below runs once per game frame
                dash_pending <= 0;                     // consumed (same idea as the fighter's punch_wait)

                if (dash_pending && !dash_lock && !dashing) begin
                    dashing <= 1;
                    current_x <= fighter_x;
                    dash_lock <= 1;
                    direction <= face_right;

                end

                if (dashing) begin
                    if (current_x == 1 || current_x == 83 || !dist_covered) begin
                        dashing <= 0;
                        dist_covered <= 25;
                        displacement <= 0;
                    end
                    else begin
                        displacement <= (dist_covered > (1+displacement))? displacement+1:dist_covered;
                        dist_covered <= (dist_covered > displacement)? dist_covered - displacement:0;
                    end
                    
                    if(direction) current_x <= (current_x + displacement > 83)? 83: current_x + displacement;
                    else current_x <= (current_x <= 1 + displacement)? 1: current_x - displacement;
                end

                if (dash_lock) countdown <= countdown - 1;

                if (countdown == 0) begin
                    countdown <= COOLDOWN - 1;
                    if (!(state == HITSTUN || state == KO))
                        dash_lock <= 0;
                    end
                end
            end
    end
    
endmodule