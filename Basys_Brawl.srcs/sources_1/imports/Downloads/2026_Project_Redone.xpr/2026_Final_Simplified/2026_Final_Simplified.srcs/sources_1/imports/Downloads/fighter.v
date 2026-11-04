`timescale 1ns / 1ps

module fighter #(parameter START_X = 12, START_FACE = 1)(
    input CLOCK, reset, tick, playing,
    input left_held, right_held, block_held,
    input jump_pressed, punch_pressed, special_pressed,
    input [6:0] opponent_x,
    input hit_valid, hit_push_right, ko,
    output reg [6:0] x,
    output [6:0] feet_y,
    output reg [3:0] state,
    output reg face_right,
    output blocking, attack_active,
    output reg attack_start,
    output [6:0] body_left, body_right, body_top, body_bottom,
    output reg [6:0] attack_left, attack_right,
    output [6:0] attack_top, attack_bottom,
    output reg [3:0] action_frame
);
    localparam IDLE=0, WALK=1, JUMP=2, BLOCK=3;
    localparam PUNCH=4, HITSTUN=5, KO=6, SPECIAL=7;
    integer height, speed;
    reg airborne, push_right;
    reg jump_wait, punch_wait, special_wait, hit_wait, hit_direction;

    assign feet_y = 60 - height;
    assign body_left = x;
    assign body_right = x + 7'd12;
    assign body_top = feet_y - 7'd16;
    assign body_bottom = feet_y;
    assign blocking = playing && (state == BLOCK);
    assign attack_active = playing && !ko && (state == PUNCH)
                           && (action_frame >= 3) && (action_frame <= 5);
    assign attack_top = feet_y - 7'd12;
    assign attack_bottom = feet_y - 7'd5;

    always @(*) begin
        attack_left = x;
        attack_right = x;
        if (face_right) begin
            attack_left = x + 12;
            if (x > 76) attack_right = 96;
            else attack_right = x + 20;
        end else begin
            if (x < 8) attack_left = 0;
            else attack_left = x - 8;
        end
    end


    always @(posedge CLOCK) begin
        if (reset || !playing || tick) begin
            jump_wait <= 0; punch_wait <= 0;
            special_wait <= 0; hit_wait <= 0;
        end else begin
            if (jump_pressed) jump_wait <= 1;
            if (punch_pressed) punch_wait <= 1;
            if (special_pressed) special_wait <= 1;
            if (hit_valid) hit_wait <= 1;
        end
        if (reset) hit_direction <= 0;
        else if (hit_valid) hit_direction <= hit_push_right;
    end

    always @(posedge CLOCK) begin
        attack_start <= 0; 
        if (reset) begin
            x <= START_X; face_right <= START_FACE; state <= IDLE;
            height <= 0; speed <= 0; airborne <= 0;
            push_right <= 0; action_frame <= 0;
        end else if (playing && tick) begin
            if (airborne && !ko && state != KO) begin
                if (height + speed <= 0) begin
                    height <= 0; speed <= 0; airborne <= 0;
                end else begin
                    height <= height + speed;
                    speed <= speed - 1;
                end
            end
            if (ko || state == KO) state <= KO;
            else if (hit_valid || hit_wait) begin
                state <= HITSTUN;
                action_frame <= 0;
                if (hit_valid) push_right <= hit_push_right;
                else push_right <= hit_direction;
            end else begin
                case (state)
                    PUNCH, SPECIAL, HITSTUN: begin
                        if (state == HITSTUN && action_frame < 4) begin
                            if (push_right) begin
                                if (x >= 82) x <= 84;
                                else x <= x + 2;
                            end else begin
                                if (x <= 2) x <= 0;
                                else x <= x - 2;
                            end
                        end
                        if (action_frame == 11) begin
                            action_frame <= 0;
                            if (airborne) state <= JUMP;
                            else state <= IDLE;
                        end else action_frame <= action_frame + 1;
                    end
                    default: begin
                        if (opponent_x > x) face_right <= 1;
                        else if (opponent_x < x) face_right <= 0;
                        if (!airborne && block_held) state <= BLOCK;
                        else if (!airborne && (special_pressed || special_wait)) begin
                            state <= SPECIAL; action_frame <= 0;
                        end else if (!airborne && (punch_pressed || punch_wait)) begin
                            state <= PUNCH; action_frame <= 0; attack_start <= 1;
                        end else if (!airborne && (jump_pressed || jump_wait)) begin
                            state <= JUMP; airborne <= 1; height <= 0; speed <= 8;
                        end else begin
                            if (airborne) state <= JUMP;
                            else state <= IDLE;
                            if (left_held && !right_held && x > 0) begin
                                x <= x - 1;
                                if (!airborne) state <= WALK;
                            end else if (right_held && !left_held && x < 84) begin
                                x <= x + 1;
                                if (!airborne) state <= WALK;
                            end
                        end
                    end
                endcase
            end
        end
    end
endmodule
