`timescale 1ns / 1ps
module game_tick(input CLOCK, reset, output tick);
    parameter COUNT_MAX = 3333332; 
    reg [25:0] count = 0;
    assign tick = (count == COUNT_MAX) && !reset;
    always @(posedge CLOCK) begin
        if (reset || tick) count <= 0;
        else count <= count + 1;
    end
endmodule
