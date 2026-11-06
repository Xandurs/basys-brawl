`timescale 1ns / 1ps
module fighter_actions_tb;
    reg test_passed=0;
    reg CLOCK=0, reset=1, tick=0, playing=1;
    reg left_held=0, right_held=0, block_held=0;
    reg jump_pressed=0, punch_pressed=0, special_pressed=0;
    reg hit_valid=0, hit_push_right=0, ko=0;
    wire [6:0] px,cx,pfeet,cfeet,pbl,pbr,pbt,pbb,cbl,cbr,cbt,cbb;
    wire [6:0] pal,par,pat,pab,cal,car,cat,cab;
    wire [3:0] ps,cs;
    wire pb,cb,pa,ca,pstart,cstart;
    fighter #(.START_X(30),.START_FACE(1)) player (
        .CLOCK(CLOCK),.reset(reset),.tick(tick),.playing(playing),
        .left_held(left_held),.right_held(right_held),.block_held(block_held),
        .jump_pressed(jump_pressed),.punch_pressed(punch_pressed),.special_pressed(special_pressed),
        .opponent_x(7'd70),.hit_valid(hit_valid),.hit_push_right(hit_push_right),.ko(ko),
        .dash_active(1'b0),.dash_x(7'd0),.x(px),.feet_y(pfeet),.state(ps),.face_right(),
        .blocking(pb),.attack_active(pa),.attack_start(pstart),
        .body_left(pbl),.body_right(pbr),.body_top(pbt),.body_bottom(pbb),
        .attack_left(pal),.attack_right(par),.attack_top(pat),.attack_bottom(pab),.action_frame()
    );
    fighter #(.START_X(30),.START_FACE(0)) cpu (
        .CLOCK(CLOCK),.reset(reset),.tick(tick),.playing(playing),
        .left_held(left_held),.right_held(right_held),.block_held(block_held),
        .jump_pressed(jump_pressed),.punch_pressed(punch_pressed),.special_pressed(special_pressed),
        .opponent_x(7'd0),.hit_valid(hit_valid),.hit_push_right(hit_push_right),.ko(ko),
        .dash_active(1'b0),.dash_x(7'd0),.x(cx),.feet_y(cfeet),.state(cs),.face_right(),
        .blocking(cb),.attack_active(ca),.attack_start(cstart),
        .body_left(cbl),.body_right(cbr),.body_top(cbt),.body_bottom(cbb),
        .attack_left(cal),.attack_right(car),.attack_top(cat),.attack_bottom(cab),.action_frame()
    );
    always #5 CLOCK=~CLOCK;
    task check(input condition,input string message);
        if(condition !== 1'b1) $fatal(1,"FAIL: %s",message);
    endtask
    task frame;
        begin
            @(negedge CLOCK);tick=1;
            @(negedge CLOCK);tick=0;
            #1;
            check(px<=84 && cx<=84,"screen bounds");
            check(pbr-pbl==12 && cbr-cbl==12 && pbb-pbt==16 && cbb-cbt==16,"body dimensions fixed");
            check(pbt>=8 && cbt>=8,"jump cannot underflow body top");
            check(px==cx && pfeet==cfeet && ps==cs,"player and CPU have identical action rules");
        end
    endtask
    integer old_x;
    initial begin
        #100;reset=0;
        right_held=1;punch_pressed=1;frame;punch_pressed=0;
        check(ps==4 && px==31,"walk and start punch together");
        repeat(3) frame;
        check(pa && ca && px==34,"walk continues through punch startup");
        check(par-pal==8 && car-cal==8,"same left/right punch reach");
        block_held=1;frame;
        check(ps==4 && !pb,"block does not cancel punch recovery");
        repeat(8) frame;
        check(ps==3 && pb && cb,"held block starts after punch recovery");
        old_x=px;frame;check(px==old_x+1 && pb,"walk while blocking");
        jump_pressed=1;frame;jump_pressed=0;frame;
        check(pfeet<60 && pb && cb,"jump while blocking");
        block_held=0;punch_pressed=1;frame;punch_pressed=0;
        check(ps==4 && pfeet<60,"punch starts in air");
        old_x=px;repeat(3) frame;
        check(pa && ca && pfeet<60 && px>old_x,"moving air punch reaches active phase");
        check(pat==pfeet-12 && pab==pfeet-5,"air attack box follows fighter height");
        repeat(18) frame;
        check(pfeet==60,"air action does not stop landing physics");
        hit_valid=1;frame;hit_valid=0;
        check(ps==5 && !pa && !pb,"accepted hit overrides actions");
        old_x=px;frame;check(px==old_x-2,"hitstun knockback overrides held movement");
        ko=1;frame;old_x=px;repeat(3) frame;
        check(ps==6 && px==old_x && !pa && !pb,"KO overrides controls");
        ko=0;reset=1;#30;reset=0;
        right_held=1;block_held=1;repeat(90) frame;
        check(px==84 && pb,"walking block clamps at right edge");
        right_held=0;left_held=1;punch_pressed=1;block_held=0;
        frame;punch_pressed=0;repeat(100) frame;
        check(px==0,"walking punch clamps at left edge");
        playing=0;old_x=px;repeat(5) frame;
        check(px==old_x && !pb && !pa,"inactive match freezes movement and attacks");
        test_passed=1;$display("PASS: fighter_actions_tb");$finish;
    end
endmodule
