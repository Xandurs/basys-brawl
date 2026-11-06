`timescale 1ns / 1ps
                                                                            
module collision_tb;
    reg test_passed=0;
    reg CLOCK=0,reset=1,tick=0;
    reg pblock=0,cblock=0,pstart=0,cstart=0,pactive=0,cactive=0;
    reg [6:0] px=12,cx=30,pbl=12,pbr=24,pbt=44,pbb=60;
    reg [6:0] cbl=30,cbr=42,cbt=44,cbb=60;
    reg [6:0] pal=24,par=30,pat=48,pab=55;
    reg [6:0] cal=22,car=30,cat=48,cab=55;
    wire [6:0] php,chp;
    wire phit,chit;
    always #5 CLOCK=~CLOCK;
    combat dut(
        .CLOCK(CLOCK),.reset(reset),.tick(tick),.fight_active(1'b1),
        .p1_x(px),.p1_blocking(pblock),.p1_attack_start(pstart),.p1_attack_active(pactive),
        .p1_body_left(pbl),.p1_body_right(pbr),.p1_body_top(pbt),.p1_body_bottom(pbb),
        .p1_atk_left(pal),.p1_atk_right(par),.p1_atk_top(pat),.p1_atk_bottom(pab),
        .cpu_x(cx),.cpu_blocking(cblock),.cpu_attack_start(cstart),.cpu_attack_active(cactive),
        .cpu_body_left(cbl),.cpu_body_right(cbr),.cpu_body_top(cbt),.cpu_body_bottom(cbb),
        .cpu_atk_left(cal),.cpu_atk_right(car),.cpu_atk_top(cat),.cpu_atk_bottom(cab),
        .p1_fb_active(1'b0),.p1_fb_x(7'd0),.p1_fb_y(7'd0),
        .p1_ult_active(1'b0),.p1_ult_x(7'd0),.p1_ult_y(7'd0),
        .p1_shield(1'b0),.cpu_shield(1'b0),
        .cpu_fb_active(1'b0),.cpu_fb_x(7'd0),.cpu_fb_y(7'd0),
        .p1_hp(php),.cpu_hp(chp),.p1_hit(phit),.cpu_hit(chit),
        .p1_push_right(),.cpu_push_right(),.p1_fb_hit(),.p1_ult_hit(),.cpu_fb_hit(),
        .p1_meter(),.p1_meter_full()
    );
    task check(input condition,input string message);
        if(condition !== 1'b1) $fatal(1,"FAIL: %s",message);
    endtask
    task frame;
        begin
            @(negedge CLOCK);tick=1;
            @(negedge CLOCK);tick=0;#1;
        end
    endtask
    task arm_player;
        begin
            @(negedge CLOCK);pstart=1;
            @(negedge CLOCK);pstart=0;
        end
    endtask
    initial begin
        #100;reset=0;
        arm_player;pactive=1;frame;
        check(chp==100,"touching exclusive edges must not hit");
        par=31;frame;check(chp==92 && chit,"one pixel overlap punches for 8");
        repeat(5) frame;check(chp==92,"one punch cannot damage repeatedly");
        pactive=0;cblock=1;arm_player;pactive=1;frame;
        check(chp==90 && !chit,"block retains original chip damage without hitstun");
        pactive=0;cblock=0;pbt=8;pbb=24;pat=12;pab=19;
        arm_player;pactive=1;frame;
        check(chp==90,"air punch cannot hit a vertically separated ground body");
        cbt=8;cbb=24;frame;
        check(chp==82,"air punch hits overlapping airborne body");
        pactive=0;pblock=1;cat=12;cab=19;
        @(negedge CLOCK);cstart=1;
        @(negedge CLOCK);cstart=0;cactive=1;
        frame;check(php==98 && !phit,"air block retains original chip rules");
        cactive=0;px=84;pbl=84;pbr=96;pal=96;par=96;
        arm_player;pactive=1;frame;
        check(chp==82,"zero reach at screen edge cannot create a phantom punch");
        test_passed=1;$display("PASS: collision_tb");$finish;
    end
endmodule
