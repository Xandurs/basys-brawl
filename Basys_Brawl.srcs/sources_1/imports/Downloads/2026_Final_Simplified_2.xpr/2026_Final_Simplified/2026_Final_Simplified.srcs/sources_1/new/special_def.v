`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2026 03:51:34 PM
// Design Name: 
// Module Name: special_def
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


module special_def(
 // ---- shared inputs from top level ----
    input CLOCK,                        // FPGA clock 100MHz
    input reset,                        // reset button
    input tick,                         // one pulse per game frame, basically oled clock
    input playing,                      // match is live
    input ko,                           // someone is KO'd
    input [12:0] pixel_index,           //pixel location
    output reg [15:0] oled_data,    // oled output
    output reg visible,             // oled output overlay
    // ---- btnD input ----
    input def_pressed,                 // debounced button pulse for this player

    // ---- from THIS player's fighter (existing outputs) ----
    input [6:0] fighter_x,              // x-axis position of left edge
    input [6:0] feet_y,                 // y-axis position of base of fighter
    input [3:0] state,                  // to block firing in HITSTUN/KO etc.

    // ---- from the hit module ----
    input def_hit,                       // fireball connected, so remove it

    // ---- out to the hit module ---- //
    //output reg        def_active,
    //output reg [6:0]  def_left, fb_right,
    //output [6:0]      def_top, def_bottom,
    //output            def_push_right,

    // ---- out to the board ----
    output def_ready,                     // cooldown finished (drive an LED)
    output shield_up                      //shield is active right now
);

    // ---- settings you may override per instance ----
    parameter COOLDOWN = 300;           // 10s at 30 ticks/s
    parameter def_up_timelength = 90;    // 3s useage time for shield, then auto deactivates

    // ---- fixed constants (must match the fighter) ----
    localparam IDLE = 0, WALK = 1, JUMP = 2, BLOCK = 3;
    localparam PUNCH = 4, HITSTUN = 5, KO = 6, SPECIAL = 7;
    
    reg def_lock = 0; //defence lock when cooldown
    reg def_up = 0; //defence active and moving
    reg def_input, def_pending;  // def input tracks button press, def pending checks for pending animation
    reg [8:0] cooldown_count = COOLDOWN -1;        //countdown inside sequential block
    reg [7:0] def_up_count = def_up_timelength -1;        //countdown inside sequential block
    reg [6:0] x, y, def_xl, def_xr, def_yu, def_yd; // x and y axis value
    reg left_wall;
    reg right_wall;
    reg up_wall;
    reg down_wall;
    
    assign def_ready = !def_lock;
    assign shield_up = def_up;                      //def up is 1 while shiled is active. Combat checks shield_up before applying damage: if the shiled is up no damage and no knockback
    
    always @(posedge CLOCK) begin
        if (reset) begin //usual reset logic
            def_up <= 0;
            def_lock <= 0;
            def_pending <= 0;
            cooldown_count <= COOLDOWN - 1;
            def_up_count <= def_up_timelength -1;
        end else begin      // if pressed, queue action
            if (def_pressed) def_pending <= 1;       // runs every clock, so a short press is never missed

            if (tick) begin                            // everything below runs once per game frame
                def_pending <= 0;                     // consumed (same idea as the fighter's punch_wait)

                if (def_pending && !def_lock && !def_up) begin
                    def_up <= 1;      //if first press after cooldown, def_up will toggle high to indicate need for animation
                    def_lock <= 1;    //after 1st press, def lock will toggle high to engage cooldown period
                end

                if (def_up) begin
                    if (!def_up_count) begin //if duration of shield is exceeded, disable animation and reset the count
                        def_up <= 0;
                        def_up_count <= def_up_timelength -1;
                    end else //else count down the use duration
                        def_up_count <= def_up_count -1;
                    end
                if (def_lock) cooldown_count <= cooldown_count - 1; //if lock is on, cooldown happens

                if (cooldown_count == 0) begin //when cooldown is over, reset the cooldown period, and disengage lock if still playing
                    cooldown_count <= COOLDOWN - 1;
                    if (!(state == HITSTUN || state == KO))
                        def_lock <= 0; //lock if entity is in stun or game over
                         end
                end
            end
    end
    
    always @(*) begin
    
        x = pixel_index % 96; //checks for x axis value
        y = pixel_index/96;// check for y axis value
        visible = 1'b0;
        oled_data = 16'h0000;
        
        //----- shield 'radius' max 4 pixel from body, avoid wrapping error-----/ 
        def_xr = (fighter_x < 78)?(fighter_x + 12 + 4): 93;
        def_xl = (fighter_x >= 6)?(fighter_x - 4): 2;
        def_yd = (feet_y <= 58)?(feet_y+4):60; 
        def_yu = (feet_y >= 23)?(feet_y - 16 - 4):2;
        
        left_wall   = (x <= def_xl && x > def_xl - 2)   && (y >= def_yu && y <= def_yd);
        right_wall  = (x <= def_xr + 2 && x > def_xr)   && (y >= def_yu && y <= def_yd);
        up_wall    = (y >  def_yu - 2 && y <= def_yu)  && (x >= def_xl && x <= def_xr);
        down_wall = (y >  def_yd - 2 && y <= def_yd)  && (x >= def_xl && x <= def_xr);
        
        if(def_up) begin //if pending fire action to be completed
            if(left_wall || right_wall || up_wall || down_wall) begin
                visible = 1'b1;
                oled_data = 16'h07FF; //cyan shield
            end 
        end
    end

endmodule
