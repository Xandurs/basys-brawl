`timescale 1ns / 1ps
                                                               
module keyboard_system_tb;
    reg test_passed=0;
    reg CLOCK=0, BTNC=0, BTNL=0, BTNR=0, BTNU=0, BTND=0;
    reg [15:0] switch=16'h8000;
    reg PS2Clk=1, PS2Data=1, test_tick=0;
    wire [7:0] JX, seg;
    wire [15:0] LED;
    wire [3:0] anode;
    Top_Basys_Brawl dut(.*);
    always #5 CLOCK=~CLOCK;
    integer old_x, old_timer;

    task check(input condition, input string message);
        if (condition !== 1'b1) $fatal(1,"FAIL: %s",message);
    endtask
    task send_bit(input value);
        begin
            PS2Data=value; #1000; PS2Clk=0; #1000; PS2Clk=1; #1000;
        end
    endtask
    task send_byte(input [7:0] value);
        integer i;
        begin
            send_bit(0);
            for(i=0;i<8;i=i+1) send_bit(value[i]);
            send_bit(~^value); send_bit(1); PS2Data=1; #1000;
        end
    endtask
    task release_key(input [7:0] code);
        begin send_byte(8'hF0); send_byte(code); end
    endtask
    task tap(input [7:0] code);
        begin send_byte(code); release_key(code); end
    endtask
    task frames(input integer n);
        repeat(n) begin
            @(negedge CLOCK); test_tick=1;
            @(negedge CLOCK); test_tick=0;
            repeat(4) @(negedge CLOCK);
        end
    endtask

    initial begin
                                                                            
        force dut.tick=test_tick;
        force dut.cpu_busy=1'b1;                                               
        #500; switch[15]=0; #500;
        check(dut.in_menu,"reset -> menu");
        tap(8'h5A); check(dut.menu_state==1,"Enter opens difficulty");
        tap(8'h1B); check(dut.difficulty==2,"S selects hard");
        tap(8'h1D); check(dut.difficulty==1,"W selects medium");
        tap(8'h5A); check(dut.menu_state==2,"Enter opens personality");
        tap(8'h5A); check(dut.menu_state==3 && dut.character_slot==0,"CPU style -> P1 character");
        tap(8'h1B); check(dut.p1_character==1,"S selects Prof Massimo for P1");
        tap(8'h5A); check(dut.character_slot==1,"Enter -> P2 character");
        tap(8'h1B); check(dut.p2_character==2,"S selects Karthi for P2");
        tap(8'h5A); check(dut.character_slot==2,"Enter -> CPU character");
        tap(8'h1B); check(dut.cpu_character==0,"CPU selection wraps to Dr Chua");
        tap(8'h5A); check(dut.phase==1,"Enter starts countdown after characters");
        frames(90); check(dut.fight_active,"90 ticks finish ready countdown");
        check(dut.p_x==12,"player spawn");
        check(dut.p_draw.character_id==1 && dut.c_draw.character_id==0,"selected P1/CPU wired to sprites");

                                                                                  
        send_byte(8'h23); frames(3); check(dut.p_x==15,"D walks right");
        send_byte(8'h1C); frames(2); check(dut.p_x==15,"A+D cancel");
        release_key(8'h23); frames(2); check(dut.p_x==13,"A walks left");
        release_key(8'h1C);
        send_byte(8'h3B); frames(1); check(dut.p_state==3,"J blocks");
        release_key(8'h3B); frames(1); check(dut.p_state==0,"J release ends block");
        send_byte(8'h1D); frames(1); check(dut.p_state==2,"W jumps");
        frames(22); check(dut.p_feet==60,"jump lands");
        send_byte(8'h1D); frames(1); check(dut.p_feet==60 && dut.p_state!=2,"repeat W cannot jump again");
        release_key(8'h1D);
        tap(8'h43); frames(1); check(dut.p_state==4,"I punches");
        frames(12); check(dut.p_state==0,"punch recovers");

        tap(8'h42); frames(1); check(dut.fb_active,"K launches fireball");
        tap(8'h4B); frames(1); check(dut.shield_up,"L raises shield");
        old_x=dut.p_x;
        tap(8'h3A); frames(12); check(dut.p_x>old_x,"M forward dash updates fighter x");
        frames(241);                                 
        old_x=dut.p_x;
        tap(8'h31); frames(12); check(dut.p_x<old_x,"N backward dash updates fighter x");
        check(dut.p_x<=84,"dash stays on screen");

                                                                            
        tap(8'h66); tap(8'h16); tap(8'h45); tap(8'h26);
        check(dut.code_switches==10'b1011,"digits emulate code 103");
        check(dut.specials.unl1,"ordered code unlocks existing manager");
        force dut.p1_meter_full=1'b1;                                            
        tap(8'h3C); frames(1); check(dut.ult_active,"U requests unlocked ultimate");
        release dut.p1_meter_full;

        switch[14]=1; #100;
        check(dut.phase==3,"SW14 pauses");
        old_x=dut.p_x; old_timer=dut.timer;
        tap(8'h23); tap(8'h42); frames(40);
        check(dut.p_x==old_x && dut.timer==old_timer,"pause freezes fighter and timer");
        check(!dut.specials.sp1.fire_pending,"paused fire press not queued");
        switch[14]=0; #100; check(dut.fight_active,"SW14 resumes");

                                                                               
        force dut.cpu_hp=7'd0; #100; frames(60);
        release dut.cpu_hp;
        check(dut.phase==7,"KO banner -> between-player screen");
        tap(8'h43); check(dut.phase==7,"I does not continue menus");
        tap(8'h5A); check(dut.phase==1 && dut.turn,"Enter starts P2 countdown");
        check(dut.code_switches==0,"new turn clears virtual code switches");
        check(dut.p_draw.character_id==2 && dut.c_draw.character_id==0,"P2 uses Karthi; CPU choice retained");
        switch[15]=1; #100; check(dut.in_menu,"SW15 resets");
        test_passed=1;
        $display("PASS: keyboard_system_tb");
        $finish;
    end
    initial begin #100000000; $fatal(1,"test timed out"); end
endmodule
