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

module special_ult(
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
    input ult_pressed,                 // ult mode activated for this player
    input ult_unlocked,
    output ult_used,
    // ---- from THIS player's fighter (existing outputs) ----
    input [6:0] fighter_x,              // x-axis position of left edge
    //input [6:0] feet_y,                 // y-axis position of base of fighter
    input face_right,                   // direction of facing, 1 -> right facing
    input [3:0] state,                  // to block firing in HITSTUN/KO etc.
    input [6:0] attack_top, input [6:0] attack_bottom,// projectile zone

    // ---- from the hit module ----
    input ult_hit,                       // fireball connected, so remove it

    // ---- out to the hit module ---- //
    //output reg        fb_active,
    //output reg [6:0]  fb_left, fb_right,
    //output [6:0]      fb_top, fb_bottom,
    //output            fb_push_right,

    // ---- out to the board ----
    output ult_ready,     // cooldown finished (drive an LED)
    output ult_active,   // ult shot is on screen
    output[6:0] ult_px, ult_py    //ult shot centre 
);

    // ---- settings you may override per instance ----
    parameter COOLDOWN = 300;           // 10s at 30 ticks/s
    parameter projectile_speed = 3;     // pixels per tick (tune later)
    parameter radius = 3;               // fireball radius in pixels
    
    // ---- fixed constants (must match the fighter) ----
    localparam IDLE = 0, WALK = 1, JUMP = 2, BLOCK = 3;
    localparam PUNCH = 4, HITSTUN = 5, KO = 6, SPECIAL = 7;
    
    reg ult_lock = 0; //fire lock when cooldown
    reg ult_executing = 0; //ult active and moving
    reg ult_pending = 0;
    reg [9:0] countdown = COOLDOWN -1;        //countdown inside sequential block
    reg direction = 0; // to check direction; EDGE CASE when after fire i change dir, to prevent ball from reversing
    reg [6:0] x,y,ult_x,ult_y; // x and y axis value
    reg [6:0] displacement = 0; //used to compile movement of the fireball from original position 
    reg [1:0] ult_shots = 2;
    reg y_dir = 0;
    
    assign ult_ready  = !ult_lock && ult_unlocked;
    assign ult_active = ult_executing; //ult_ready will be 1 while ult shot is firing 
    assign ult_px = ult_x;      //ult shot centre
    assign ult_py = ult_y;
    
    //launch condition (waits for tick, blocked while stunned/KO/not playing)
    wire launch = tick && (ult_pending || (ult_pressed && ult_unlocked)) && !ult_lock && !ult_executing
                  && playing && !ko && !(state == HITSTUN || state == KO);

    //one-clock pulse to the manager (NOT ult_executing, which stays high the whole flight)
    assign ult_used = launch;
    
    always @(posedge CLOCK) begin
        if (reset) begin
            ult_executing <= 0;
            ult_lock <= 0;
            ult_pending <= 0;
            displacement <= 0;
            countdown <= COOLDOWN - 1;
            ult_shots <= 2;
            y_dir <= 0;
        end else begin
            if (!playing || ko) ult_pending <= 0;
            else if (ult_pressed && ult_unlocked && !ult_lock) ult_pending <= 1;       // runs every clock, so a short press is never missed

            if (tick) begin                            // everything below runs once per game frame
                ult_pending <= 0;                     // consumed (same idea as the fighter's punch_wait)

                if (launch) begin
                    ult_executing <= 1;
                    ult_lock <= 1;
                    direction <= face_right;
                    displacement <= 0;
                    ult_x <= face_right ? (fighter_x + 12) : fighter_x;
                    ult_y <= (attack_bottom+attack_top)/2;
                    ult_shots <= 2;
                    y_dir <= 0;
                end

                if (ult_executing) begin
                    if (ult_x >= 100 || ult_x == 0 || ult_hit) begin
                        if(ult_shots == 2) begin
                            ult_shots <= 1;
                            ult_x <= direction ? (fighter_x + 12) : fighter_x;
                            ult_y <= (attack_bottom+attack_top)/2;
                            y_dir <= 1;
                        end else if (ult_shots == 1) begin
                            ult_shots <= 2;
                            ult_executing <= 0;
                            y_dir <= 0;
                        end
                    end
                    else begin
                        ult_x <= (direction)? (ult_x + projectile_speed): (ult_x - projectile_speed);
                        ult_y <= (y_dir)? (ult_y + 4): (ult_y -4);
                        if(ult_y <= 4) begin
                            y_dir <= ~y_dir;
                            ult_y <= ult_y + 4;
                        end
                        else if (ult_y >= 56) begin
                            y_dir <= ~y_dir;
                            ult_y <= ult_y - 4;
                        end
                    end
                end

                if (ult_lock) countdown <= countdown - 1;

                if (countdown == 0 && !(state == HITSTUN || state == KO)) begin
                    countdown <= COOLDOWN - 1;
                    ult_lock <= 0;
                end
                else if (state == HITSTUN || state == KO) begin
                    countdown <= countdown;
                end
            end
        end
    end
    
    always @(*) begin
    
        x = pixel_index % 96; //checks for x axis value
        y = pixel_index/96;// check for y axis value
        visible = 1'b0;
        oled_data = 16'h0000;
        
        if(ult_executing) begin //if pending fire action to be completed
            if((x-ult_x)*(x-ult_x) + (y-ult_y)*(y-ult_y) <= 16) begin
                visible = 1'b1;
                if((x-ult_x)*(x-ult_x) + (y-ult_y)*(y-ult_y) <= 9) begin
                    if((x-ult_x)*(x-ult_x) + (y-ult_y)*(y-ult_y) <= 4) begin
                        oled_data = 16'h07FF;
                    end 
                    else oled_data = 16'h001F;
                end 
                else oled_data = 16'hF81F;
            end
        end
    end

endmodule

