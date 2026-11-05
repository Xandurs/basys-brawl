`timescale 1ns / 1ps
module sprite_bounds_tb;
    reg test_passed=0;
    reg [6:0] pixel_x=0,x=0,feet_y=60,attack_left=0,attack_right=0;
    reg [5:0] pixel_y=0;
    reg [3:0] state=0;
    reg [1:0] character_id=0;
    reg face_right=0,attack_active=0;
    reg [15:0] body_colour=16'h001F;
    wire visible;
    wire [15:0] colour;
    fighter_draw dut(.*);
    integer ch,f,h,pos,pose,xx,yy;
    reg in_body,in_fist;
    initial begin
        for(ch=0;ch<3;ch=ch+1)
        for(f=0;f<2;f=f+1)
        for(h=0;h<2;h=h+1)
        for(pos=0;pos<3;pos=pos+1)
        for(pose=0;pose<3;pose=pose+1) begin
            character_id=ch;face_right=f;feet_y=h ? 60 : 24;x=pos*42;
            state=pose==0 ? 0 : (pose==1 ? 3 : 4);
            attack_active=(pose==2);
            attack_left=f ? x+12 : (x<8 ? 0 : x-8);
            attack_right=f ? (x>76 ? 96 : x+20) : x;
            for(yy=0;yy<64;yy=yy+1)
            for(xx=0;xx<96;xx=xx+1) begin
                pixel_x=xx;pixel_y=yy;#1;
                in_body=xx>=x && xx<x+12 && yy>=feet_y-16 && yy<feet_y;
                in_fist=attack_active && xx>=attack_left && xx<attack_right &&
                        yy>=feet_y-12 && yy<feet_y-5;
                if(visible && !(in_body || in_fist)) $fatal(1,"sprite escapes combat rectangles");
                if(in_fist && !visible) $fatal(1,"active punch box lacks visible fist");
            end
        end
                                                                                 
        x=0;feet_y=60;state=0;attack_active=0;face_right=1;
        pixel_x=3;pixel_y=52;character_id=0;#1;
        if(colour!==16'h2450) $fatal(1,"Dr Chua tunic palette mismatch");
        character_id=1;#1;
        if(colour!==16'h61A8) $fatal(1,"Prof Massimo tunic palette mismatch");
        character_id=2;#1;
        if(colour!==16'hBB27) $fatal(1,"Karthi tunic palette mismatch");
        test_passed=1;$display("PASS: sprite_bounds_tb");$finish;
    end
endmodule
