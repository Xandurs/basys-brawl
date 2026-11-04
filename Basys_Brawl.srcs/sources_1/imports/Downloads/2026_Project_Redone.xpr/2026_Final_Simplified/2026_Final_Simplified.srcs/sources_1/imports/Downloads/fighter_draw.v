`timescale 1ns / 1ps
module fighter_draw(
    input [6:0] pixel_x, input [5:0] pixel_y,
    input [6:0] x, feet_y, input [3:0] state,
    input face_right, attack_active,
    input [6:0] attack_left, attack_right,
    input [15:0] body_colour,
    output reg visible, output reg [15:0] colour
);
    always @(*) begin
        visible = 0; colour = 0;
        if (pixel_x >= x && pixel_x < x+12 &&
            pixel_y >= feet_y-16 && pixel_y < feet_y) begin
            visible = 1; colour = body_colour;
            case (state)
                3: colour = 16'h07FF; // block
                5: colour = 16'hFFFF; // hitstun
                6: colour = 16'h4208; // KO
                7: colour = 16'hF81F; 
                default: colour = body_colour;
            endcase
            if (pixel_y == feet_y-13) begin
                if (face_right && pixel_x == x+9) colour = 16'hFFFF;
                if (!face_right && pixel_x == x+2) colour = 16'hFFFF;
            end
        end
        if (attack_active && pixel_x >= attack_left && pixel_x < attack_right &&
            pixel_y >= feet_y-12 && pixel_y < feet_y-5) begin
            visible = 1; colour = 16'hFFE0;
        end
    end
endmodule
