`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.10.2026 21:30:50
// Design Name: 
// Module Name: combat
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


module combat(
    input CLOCK,
    input reset,            // sys_reset || match_reset: refills health
    input tick,
    input fight_active,     // from game_flow: only resolve hits in FIGHT

    //player fighter 
    input[6:0] p1_x,
    input p1_blocking, p1_attack_start, p1_attack_active,
    input[6:0] p1_body_left, p1_body_right, p1_body_top, p1_body_bottom,
    input[6:0] p1_atk_left,  p1_atk_right,  p1_atk_top,  p1_atk_bottom,

    //CPU fighter 
    input[6:0] cpu_x,
    input  cpu_blocking, cpu_attack_start, cpu_attack_active,
    input[6:0] cpu_body_left, cpu_body_right, cpu_body_top, cpu_body_bottom,
    input[6:0] cpu_atk_left,  cpu_atk_right,  cpu_atk_top,  cpu_atk_bottom,

    //player's projectiles and both shields 
    input p1_fb_active,
    input[6:0] p1_fb_x, p1_fb_y,
    input p1_ult_active,
    input[6:0] p1_ult_x, p1_ult_y,
    input p1_shield, cpu_shield,
    
    //CPU's fireball (yuhan's AI -> CPU copy of Karthi's special_top)
    input cpu_fb_active,
    input[6:0] cpu_fb_x, cpu_fb_y,
    
    output reg[6:0] p1_hp  = 7'b1100100,     
    output reg[6:0] cpu_hp = 7'b1100100,  
    output reg p1_hit  = 1'b0,          // -> player fighter hit_valid
    output reg p1_push_right  = 1'b0,   // -> player fighter hit_push_right
    output reg cpu_hit = 1'b0,          // -> CPU fighter hit_valid
    output reg cpu_push_right = 1'b0,   // -> CPU fighter hit_push_right
    output reg p1_fb_hit  = 1'b0,       // -> Karthi: remove fireball
    output reg[6:0] p1_meter = 7'b0000000,
    output p1_meter_full,
    output reg p1_ult_hit = 1'b0,        // -> Karthi: next ult shot
    output reg cpu_fb_hit = 1'b0         // -> Karthi (CPU coopy): remove fireball
    );
    
    localparam FULL_HP    = 7'b1100100;   
    localparam PUNCH_DMG  = 7'b0001000;   
    localparam PUNCH_CHIP = 7'b0000010;   
    localparam FB_DMG     = 7'b0001100;   
    localparam FB_CHIP    = 7'b0000011;   
    localparam ULT_DMG    = 7'b0001111;  
    localparam ULT_CHIP   = 7'b0000100;   
    localparam R          = 7'b0000011;   // projectile hitbox: 3 px each side of centre
    localparam METER_MAX = 7'b1100100;
    localparam GAIN_PUNCH = 7'b0001010;
    localparam GAIN_PCHIP = 7'b0000100;
    localparam GAIN_FB = 7'b0001000;
    localparam GAIN_FCHIP = 7'b0000011;
    
    function [6:0] gain;
        input[6:0] m,g;
        begin
            if ( m + g >= METER_MAX) gain = METER_MAX;
            else gain = m + g;
        end
    endfunction 
    
    assign p1_meter_full = (p1_meter == METER_MAX);
    
    //detect the moment the player's ult launches (ult_active goes 0 to 1)
    reg p1_ult_prev = 1'b0;
    wire p1_ult_launch = p1_ult_active && !p1_ult_prev;
    
     function [6:0] take;
        input [6:0] hp, dmg;
        begin
            if (hp > dmg) take = hp - dmg;
            else          take = 7'b0000000;
        end
    endfunction
    
    //projectile hitbox made into a square like punch hitbox
    wire [6:0] fb_l  = (p1_fb_x  > R) ? p1_fb_x  - R : 7'b0000000;
    wire [7:0] fb_r  =  p1_fb_x  + R + 8'b00000001;
    wire [6:0] fb_t  = (p1_fb_y  > R) ? p1_fb_y  - R : 7'b0000000;
    wire [7:0] fb_b  =  p1_fb_y  + R + 8'b00000001;
    wire [6:0] ult_l = (p1_ult_x > R) ? p1_ult_x - R : 7'b0000000;
    wire [7:0] ult_r =  p1_ult_x + R + 8'b00000001;
    wire [6:0] ult_t = (p1_ult_y > R) ? p1_ult_y - R : 7'b0000000;
    wire [7:0] ult_b =  p1_ult_y + R + 8'b00000001;
    wire [7:0] cfb_l = (cpu_fb_x > R) ? cpu_fb_x - R : 7'b0000000;
    wire [7:0] cfb_r =  cpu_fb_x + R + 8'b00000001;                      
    wire [6:0] cfb_t = (cpu_fb_y > R) ? cpu_fb_y - R : 7'b0000000;        
    wire [7:0] cfb_b =  cpu_fb_y + R + 8'b00000001;
    
    wire p1_punch_on_cpu = p1_attack_active &&
        (p1_atk_left < cpu_body_right) && (cpu_body_left < p1_atk_right) &&
        (p1_atk_top  < cpu_body_bottom) && (cpu_body_top < p1_atk_bottom);

    wire cpu_punch_on_p1 = cpu_attack_active &&
        (cpu_atk_left < p1_body_right) && (p1_body_left < cpu_atk_right) &&
        (cpu_atk_top  < p1_body_bottom) && (p1_body_top < cpu_atk_bottom);

    wire fb_on_cpu = p1_fb_active &&
        (fb_l < cpu_body_right) && (cpu_body_left < fb_r) &&
        (fb_t < cpu_body_bottom) && (cpu_body_top < fb_b);

    wire ult_on_cpu = p1_ult_active &&
        (ult_l < cpu_body_right) && (cpu_body_left < ult_r) &&
        (ult_t < cpu_body_bottom) && (cpu_body_top < ult_b);
        
    wire cfb_on_p1 = cpu_fb_active &&                                     
        (cfb_l < p1_body_right) && (p1_body_left < cfb_r) &&               
        (cfb_t < p1_body_bottom) && (p1_body_top < cfb_b);
        
    reg p1_armed = 1'b0;
    reg cpu_armed = 1'b0;
    
    always@(posedge CLOCK) begin
        if (reset) begin
            p1_hp <= FULL_HP;
            cpu_hp <= FULL_HP;
            p1_hit <= 1'b0; p1_push_right <= 1'b0;
            cpu_hit <= 1'b0; cpu_push_right <= 1'b0;
            p1_fb_hit <= 1'b0; p1_ult_hit <= 1'b0;
            cpu_fb_hit <= 1'b0;
            p1_armed <= 1'b0; cpu_armed <= 1'b0;
            p1_meter <= 7'b0000000;
            
        end
        else begin
            if (p1_attack_start) p1_armed <= 1'b1;
            if (cpu_attack_start) cpu_armed <= 1'b1;
            p1_ult_prev <= p1_ult_active;
            if (p1_ult_launch) p1_meter <= 7'b0000000;
        
            if (tick) begin
            //reset
                p1_hit <= 1'b0;
                cpu_hit <= 1'b0;
                p1_fb_hit <= 1'b0;
                p1_ult_hit <= 1'b0;
                cpu_fb_hit <= 1'b0;
            
                if (fight_active) begin
                    // attacks landing on CPU
                    if (ult_on_cpu && !p1_ult_hit) begin 
                        p1_ult_hit <= 1'b1;
                        if (!cpu_shield) begin
                            if (cpu_blocking) cpu_hp <= take(cpu_hp, ULT_CHIP);
                            else begin  
                                cpu_hp <= take(cpu_hp, ULT_DMG);
                                cpu_hit <= 1'b1;
                                cpu_push_right <= (p1_ult_x < cpu_body_left + 7'b0000110);
                            end
                        end
                    end
                    else if (fb_on_cpu && !p1_fb_hit) begin
                        p1_fb_hit <= 1'b1;
                        if (!cpu_shield) begin
                            if (cpu_blocking) begin
                                 cpu_hp <= take(cpu_hp, FB_CHIP);
                                 p1_meter <= gain(p1_meter, GAIN_FCHIP);
                            end
                            else begin
                                cpu_hp <= take(cpu_hp, FB_DMG);
                                cpu_hit <= 1'b1;
                                cpu_push_right <= (p1_fb_x < cpu_body_left + 7'b0000110);
                                p1_meter <= gain(p1_meter, GAIN_FB);
                            end
                        end
                    end
                    else if (p1_armed && p1_punch_on_cpu) begin
                        p1_armed <= 1'b0;
                        if (!cpu_shield) begin
                            if (cpu_blocking) begin
                                 cpu_hp <= take(cpu_hp, PUNCH_CHIP);
                                 p1_meter <= gain(p1_meter, GAIN_FB);
                            end
                            else begin
                                cpu_hp <= take(cpu_hp, PUNCH_DMG);
                                cpu_hit <= 1'b1;
                                cpu_push_right <= (p1_x < cpu_x);
                                p1_meter <= gain(p1_meter, GAIN_PUNCH);
                            end
                        end
                    end
                
                    //attacks landing on player (cpu no ult for now waiting on yuhan)
                    if (cfb_on_p1 && !cpu_fb_hit) begin
                        cpu_fb_hit <= 1'b1;
                        if (!p1_shield) begin
                            if(p1_blocking) p1_hp <= take(p1_hp, FB_CHIP);
                            else begin
                                p1_hp <= take(p1_hp, FB_DMG);
                                p1_hit <= 1'b1;
                                p1_push_right <= (cpu_fb_x < p1_body_left + 7'b0000110);
                            end
                        end
                    end
                    else if (cpu_armed && cpu_punch_on_p1) begin
                        cpu_armed <= 1'b0;
                        if (!p1_shield) begin
                            if (p1_blocking) p1_hp <= take(p1_hp, PUNCH_CHIP);
                            else begin
                                p1_hp <= take(p1_hp, PUNCH_DMG);
                                p1_hit <= 1'b1;
                                p1_push_right <= (cpu_x < p1_x);
                            end
                        end
                    end 
                end
            end
        end
    end                
endmodule
