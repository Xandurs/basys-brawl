`timescale 1ns / 1ps

module cpu_control(
    input CLOCK,
    input reset,
    
    input action_valid,
    input [3:0] action,

    input [6:0] player_x,
    input [6:0] cpu_x,

    output reg cpu_left,
    output reg cpu_right,
    output reg cpu_block,
    output reg cpu_jump,
    output reg cpu_punch,
    output reg cpu_fireball,
    output reg cpu_dash,
    output reg cpu_shield,
    output reg cpu_ult
);

    parameter NONE     = 4'b0000;
    parameter APPROACH = 4'b0001;
    parameter PUNCH    = 4'b0010;
    parameter BLOCK    = 4'b0011;
    parameter RETREAT  = 4'b0100;
    parameter JUMP     = 4'b0111;
    parameter FIREBALL = 4'b0101;
    parameter DASH     = 4'b0110;
    parameter SHIELD   = 4'b1000;
    parameter ULT      = 4'b1001;

    always @(posedge CLOCK) begin
        
        cpu_jump <= 0;
        cpu_punch <= 0;
        cpu_dash <= 0;
        cpu_fireball <= 0;
        cpu_shield <= 0;
        cpu_ult <= 0;

        if (reset) begin
            cpu_left <= 0;
            cpu_right <= 0;
            cpu_block <= 0;
        end

        else if (action_valid) begin
                                                                        
            if (action != PUNCH && action != BLOCK && action != JUMP) begin
                cpu_left <= 0;
                cpu_right <= 0;
            end
            cpu_block <= 0;
            case (action)
                
                APPROACH: begin                       //move to player
                    if (player_x > cpu_x) begin
                        cpu_left <= 0;
                        cpu_right <= 1;
                    end
                    else if (player_x < cpu_x) begin
                        cpu_left <= 1;
                        cpu_right <= 0;    
                    end
                end

                PUNCH: begin
                    cpu_punch <= 1;
                end  

                BLOCK: begin
                    cpu_block <= 1;
                end
                
                
                RETREAT: begin
                    if (player_x > cpu_x) begin
                        cpu_left <= 1;
                        cpu_right <= 0;
                    end
                    
                    else if (player_x < cpu_x) begin
                        cpu_left <= 0;
                        cpu_right <= 1;                   
                    end
                end                            

                FIREBALL: begin
                    cpu_fireball <= 1;
                end

                DASH: begin
                    cpu_dash <= 1;
                end

                JUMP: begin
                    cpu_jump <= 1;
                end
                
                SHIELD: begin
                    cpu_shield <= 1;
                end

                ULT: begin
                    cpu_ult <= 1;
                end

                NONE: begin                   
                end
            endcase
        end
    end
endmodule
         
       