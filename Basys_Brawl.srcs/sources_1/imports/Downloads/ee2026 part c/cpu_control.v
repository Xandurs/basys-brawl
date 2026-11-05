`timescale 1ns / 1ps

module cpu_control(
    input CLOCK,
    input reset,
    
    input action_valid,
    input [2:0] action,

    input [6:0] player_x,
    input [6:0] cpu_x,

    output reg cpu_left,
    output reg cpu_right,
    output reg cpu_block,
    output reg cpu_jump,
    output reg cpu_punch,
    output reg cpu_fireball,
    output reg cpu_dash
);

    parameter NONE     = 3'b000;  //same action code as in ai_decision.v
    parameter APPROACH = 3'b001;
    parameter PUNCH    = 3'b010;
    parameter BLOCK    = 3'b011;
    parameter RETREAT  = 3'b100;
    parameter FIREBALL = 3'b101;
    parameter DASH     = 3'b110;
    parameter JUMP     = 3'b111;

    always @(posedge CLOCK) begin
        
        cpu_jump <= 0;
        cpu_punch <= 0;
        cpu_dash <= 0;
        cpu_fireball <= 0;

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

                NONE: begin                   
                end
            endcase
        end
    end
endmodule
         
       