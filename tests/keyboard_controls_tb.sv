`timescale 1ns / 1ps
module keyboard_controls_tb;
    reg test_passed=0;
    reg CLOCK=0, reset=1, code_reset=0, PS2Clk=1, PS2Data=1;
    always #5 CLOCK=~CLOCK;
    wire [21:0] held, pressed;
    wire [9:0] code_sw;
    keyboard_controls dut(.*);
    wire left_held=held[1], right_held=held[2], block_held=held[3];
    wire jump_pressed=pressed[0], fire_pressed=pressed[5];
    wire enter_pressed=pressed[9], ult_pressed=pressed[20];
    integer jumps=0, fires=0, enters=0, ults=0;
    always @(posedge CLOCK) begin
        if (jump_pressed) jumps=jumps+1;
        if (fire_pressed) fires=fires+1;
        if (enter_pressed) enters=enters+1;
        if (ult_pressed) ults=ults+1;
    end
    task check(input condition, input string message);
        if (condition !== 1'b1) $fatal(1, "%s", message);
    endtask
    task bit_send(input value);
        begin
            PS2Data=value; #1000;
            PS2Clk=0; #1000;
            PS2Clk=1; #1000;
        end
    endtask
    task byte_send(input [7:0] value, input bad_parity);
        integer i;
        begin
            bit_send(0);
            for(i=0;i<8;i=i+1) bit_send(value[i]);
            bit_send((~^value)^bad_parity);
            bit_send(1); PS2Data=1; #1000;
        end
    endtask
    task make_key(input [7:0] code);
        byte_send(code,0);
    endtask
    task release_key(input [7:0] code);
        begin byte_send(8'hF0,0); byte_send(code,0); end
    endtask
    initial begin
        #200; reset=0; #200;
        make_key(8'h1C); make_key(8'h23); make_key(8'h3B);
        check(left_held && right_held && block_held,"simultaneous holds");
        release_key(8'h1C);
        check(!left_held && right_held && block_held,"independent release");
        release_key(8'h23); release_key(8'h3B);
        make_key(8'h1D); make_key(8'h1D);
        check(jumps==1,"auto-repeat must not repeat jump");
        release_key(8'h1D); make_key(8'h1D);
        check(jumps==2,"repress must jump again"); release_key(8'h1D);
        make_key(8'h3C); make_key(8'h3C);
        check(ults==1,"U make/repeat"); release_key(8'h3C);
        make_key(8'h5A); release_key(8'h5A);
        make_key(8'hE0); make_key(8'h5A);
        check(enters==2,"normal and extended Enter");
        make_key(8'hE0); release_key(8'h5A);
        make_key(8'hE0); make_key(8'h1C);
        check(!left_held,"extended code must not alias A");
        make_key(8'h16); make_key(8'h16);
        check(code_sw==10'b10,"digit repeat cannot retoggle");
        release_key(8'h16); make_key(8'h45); release_key(8'h45);
        make_key(8'h26); release_key(8'h26);
        check(code_sw==10'b1011,"code 103 switch sequence");
        make_key(8'h46); release_key(8'h46);
        check(code_sw[9],"digit 9 must exist");
        make_key(8'h66); release_key(8'h66);
        check(code_sw==0,"Backspace clear");
        release_key(8'h16); make_key(8'h16); release_key(8'h16);
        make_key(8'h16); release_key(8'h16);
        check(code_sw==0,"second digit press turns bit off");
        byte_send(8'h1D,1);
        check(jumps==2,"bad parity must be ignored");
        bit_send(0); PS2Data=1; #2100000;
        make_key(8'h1D); check(jumps==3,"partial frame timeout recovery");
        make_key(8'hAA); check(held==0,"startup byte clears held keys");
        make_key(8'h1B); check(held[21],"S menu key"); release_key(8'h1B);
        make_key(8'h46); release_key(8'h46);
        make_key(8'h1C); check(held[1],"A held before round reset");
        @(negedge CLOCK); code_reset=1;
        @(negedge CLOCK); code_reset=0;
        check(code_sw==0 && held[1],"round reset clears code without forgetting held keys");
        release_key(8'h1C);
        test_passed=1;
        $display("PASS: keyboard_controls_tb");
        $finish;
    end
endmodule
