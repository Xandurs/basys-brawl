`timescale 1ns / 1ps
                                                                    
module fighter_draw(
    input [6:0] pixel_x, input [5:0] pixel_y,
    input [6:0] x, feet_y, input [3:0] state,
    input face_right, attack_active,
    input [1:0] character_id,
    input [6:0] attack_left, attack_right,
    input [15:0] body_colour,
    output reg visible, output reg [15:0] colour
);
    integer local_x, local_y, draw_x;
    reg [47:0] sprite_row;
    reg [3:0] ink;
    function [47:0] sprite_line;
        input [1:0] character;
        input [3:0] row;
        begin
            sprite_line = 0;
            case (character)
                2'd1: begin                
                    case (row)
                        4'd0: sprite_line = 48'h010044440010;
                        4'd1: sprite_line = 48'h011444444110;
                        4'd2: sprite_line = 48'h001422224100;
                        4'd3: sprite_line = 48'h001277272100;
                        4'd4: sprite_line = 48'h0012A22A2100;
                        4'd5: sprite_line = 48'h001244442100;
                        4'd6: sprite_line = 48'h001144441100;
                        4'd7: sprite_line = 48'h015555555100;
                        4'd8: sprite_line = 48'h125565655210;
                        4'd9: sprite_line = 48'h12555D555210;
                        4'd10: sprite_line = 48'h015556555100;
                        4'd11: sprite_line = 48'h015556555100;
                        4'd12: sprite_line = 48'h001566651000;
                        4'd13: sprite_line = 48'h001555551000;
                        4'd14: sprite_line = 48'h001955591000;
                        4'd15: sprite_line = 48'h019990999100;
                    endcase
                end
                2'd2: begin          
                    case (row)
                        4'd0: sprite_line = 48'h000144441000;
                        4'd1: sprite_line = 48'h001444444100;
                        4'd2: sprite_line = 48'h001666666100;
                        4'd3: sprite_line = 48'h001277272100;
                        4'd4: sprite_line = 48'h001282282100;
                        4'd5: sprite_line = 48'h001222222100;
                        4'd6: sprite_line = 48'h000122221000;
                        4'd7: sprite_line = 48'h001555555100;
                        4'd8: sprite_line = 48'h012556552100;
                        4'd9: sprite_line = 48'h12255D552210;
                        4'd10: sprite_line = 48'h012556552100;
                        4'd11: sprite_line = 48'h001666661000;
                        4'd12: sprite_line = 48'h001555551000;
                        4'd13: sprite_line = 48'h001990991000;
                        4'd14: sprite_line = 48'h001990991000;
                        4'd15: sprite_line = 48'h019990999100;
                    endcase
                end
                default: begin           
                    case (row)
                        4'd0: sprite_line = 48'h004444440000;
                        4'd1: sprite_line = 48'h044444444000;
                        4'd2: sprite_line = 48'h044222224400;
                        4'd3: sprite_line = 48'h044277274400;
                        4'd4: sprite_line = 48'h0442A22A4400;
                        4'd5: sprite_line = 48'h044222224400;
                        4'd6: sprite_line = 48'h004425244000;
                        4'd7: sprite_line = 48'h015555551000;
                        4'd8: sprite_line = 48'h012556552100;
                        4'd9: sprite_line = 48'h12255D552210;
                        4'd10: sprite_line = 48'h012556552100;
                        4'd11: sprite_line = 48'h001566651000;
                        4'd12: sprite_line = 48'h001555551000;
                        4'd13: sprite_line = 48'h001995991000;
                        4'd14: sprite_line = 48'h001990991000;
                        4'd15: sprite_line = 48'h019990999100;
                    endcase
                end
            endcase
        end
    endfunction

    function [15:0] palette;
        input [1:0] character;
        input [3:0] index;
        begin
            palette = 0;
            case (character)
                2'd1: begin                
                    case (index)
                        4'h1: palette = 16'h1105;
                        4'h2: palette = 16'hEDF2;
                        4'h3: palette = 16'hB44D;
                        4'h4: palette = 16'hDE96;
                        4'h5: palette = 16'h61A8;
                        4'h6: palette = 16'hCD2B;
                        4'h7: palette = 16'hFF9B;
                        4'h8: palette = 16'h1106;
                        4'h9: palette = 16'h3947;
                        4'hA: palette = 16'h9EDB;
                        4'hB: palette = 16'h4147;
                        4'hC: palette = 16'h5F3D;
                        default: palette = 0;
                    endcase
                end
                2'd2: begin          
                    case (index)
                        4'h1: palette = 16'h1105;
                        4'h2: palette = 16'hCC6B;
                        4'h3: palette = 16'h9307;
                        4'h4: palette = 16'h3144;
                        4'h5: palette = 16'hBB27;
                        4'h6: palette = 16'hF62D;
                        4'h7: palette = 16'hFF9B;
                        4'h8: palette = 16'h1106;
                        4'h9: palette = 16'h59A6;
                        4'hA: palette = 16'hF6D0;
                        4'hB: palette = 16'h8226;
                        4'hC: palette = 16'h5F3D;
                        default: palette = 0;
                    endcase
                end
                default: begin           
                    case (index)
                        4'h1: palette = 16'h1105;
                        4'h2: palette = 16'hF654;
                        4'h3: palette = 16'hC44D;
                        4'h4: palette = 16'h51C9;
                        4'h5: palette = 16'h2450;
                        4'h6: palette = 16'hF68E;
                        4'h7: palette = 16'hFF9B;
                        4'h8: palette = 16'h1106;
                        4'h9: palette = 16'h6A4A;
                        4'hA: palette = 16'h96FC;
                        4'hB: palette = 16'h1B2C;
                        4'hC: palette = 16'h5F3D;
                        default: palette = 0;
                    endcase
                end
            endcase
        end
    endfunction

    always @(*) begin
        visible = 0; colour = 0; ink = 0; sprite_row = 0;
        local_x = pixel_x - x;
        local_y = pixel_y - (feet_y - 16);
        draw_x = local_x;
        if (!face_right) draw_x = 11 - local_x;
        if (local_x >= 0 && local_x < 12 && local_y >= 0 && local_y < 16) begin
            sprite_row = sprite_line(character_id, local_y[3:0]);
            ink = sprite_row >> ((11 - draw_x) * 4);
                                                                               
            if (feet_y == 60 && x[1] && state != 0 && local_y == 14) begin
                if (draw_x == 3 || draw_x == 8) ink = 4'h9;
                if (draw_x == 4 || draw_x == 7) ink = 0;
            end
                                                                         
            if (state == 3 && draw_x >= 9 && local_y >= 6 && local_y <= 10)
                ink = 4'hC;
            if (state == 4 && draw_x >= 9 && local_y >= 7 && local_y <= 9)
                ink = 4'h2;
            if (ink != 0) begin
                visible = 1; colour = palette(character_id, ink);
                if (ink == 4'hD) colour = body_colour;                       
                if (state == 5 && ink != 1) colour = 16'hFFFF;
                if (state == 6) colour = 16'h4208;
                if (state == 7 && ink == 5) colour = 16'hF81F;
            end
        end
                                                                  
        if (attack_active && pixel_x >= attack_left && pixel_x < attack_right &&
            pixel_y >= feet_y-12 && pixel_y < feet_y-5) begin
            visible = 1; colour = 16'hFFE0;
            if (pixel_x == attack_left || pixel_x == attack_right-1 ||
                pixel_y == feet_y-12 || pixel_y == feet_y-6)
                colour = 16'hC408;
        end
    end
endmodule
