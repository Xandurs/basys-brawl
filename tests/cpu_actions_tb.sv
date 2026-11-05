`timescale 1ns / 1ps
module cpu_actions_tb;
    reg test_passed=0;
    reg CLOCK=0,reset=1,action_valid=0;
    reg [2:0] action=0;
    wire cpu_left,cpu_right,cpu_block,cpu_jump,cpu_punch,cpu_fireball,cpu_dash;
    cpu_control dut(.CLOCK(CLOCK),.reset(reset),.action_valid(action_valid),.action(action),
        .player_x(7'd70),.cpu_x(7'd30),.cpu_left(cpu_left),.cpu_right(cpu_right),
        .cpu_block(cpu_block),.cpu_jump(cpu_jump),.cpu_punch(cpu_punch),
        .cpu_fireball(cpu_fireball),.cpu_dash(cpu_dash));
    reg tick=0;
    reg [3:0] cpu_state=0;
    wire brain_valid;
    wire [2:0] brain_action;
    ai_decision brain(.CLOCK(CLOCK),.reset(reset),.tick(tick),
        .player_x(7'd70),.cpu_x(7'd30),.cpu_state(cpu_state),
        .random_num(8'd250),.difficulty(2'd2),.personality(2'd0),.cpu_busy(1'b0),
        .action_valid(brain_valid),.action(brain_action));
    always #5 CLOCK=~CLOCK;
    task check(input condition,input string message);
        if(condition !== 1'b1) $fatal(1,"FAIL: %s",message);
    endtask
    task command(input [2:0] value);
        begin
            @(negedge CLOCK);action=value;action_valid=1;
            @(negedge CLOCK);action_valid=0;#1;
        end
    endtask
    task frame;
        begin
            @(negedge CLOCK);tick=1;
            @(negedge CLOCK);tick=0;#1;
        end
    endtask
    initial begin
        #100;reset=0;
        command(1);check(cpu_right && !cpu_left,"approach holds right");
        command(2);check(cpu_punch && cpu_right,"punch retains walking");
        command(3);check(cpu_block && cpu_right,"block retains walking");
        command(7);check(cpu_jump && cpu_right && !cpu_block,"jump retains horizontal movement");
        command(4);check(cpu_left && !cpu_right,"retreat replaces movement direction");
        command(0);check(!cpu_left && !cpu_right && !cpu_block,"NONE releases movement");
        repeat(5) frame;check(brain_valid && brain_action==7,"AI can choose existing JUMP action");
        cpu_state=2;repeat(5) frame;
        check(brain_valid && brain_action!=7,"AI avoids choosing jump while JUMP state active");
        test_passed=1;$display("PASS: cpu_actions_tb");$finish;
    end
endmodule
