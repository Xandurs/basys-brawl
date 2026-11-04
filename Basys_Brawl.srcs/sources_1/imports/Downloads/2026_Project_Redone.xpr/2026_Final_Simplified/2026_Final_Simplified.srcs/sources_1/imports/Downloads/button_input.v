`timescale 1ns / 1ps

module button_input(input CLOCK, reset, raw_button,
                    output reg held = 0, pressed = 0);
    reg sync1 = 0, sync2 = 0;
    reg [19:0] count = 0;
    always @(posedge CLOCK) begin
        if (reset) begin
            sync1 <= 0; sync2 <= 0; count <= 0;
            held <= 0; pressed <= 0;
        end else begin
            sync1 <= raw_button;
            sync2 <= sync1;
            pressed <= 0;
            if (sync2 == held) count <= 0;
            else if (count == 999999) begin 
                count <= 0;
                held <= sync2;
                pressed <= sync2;
            end else count <= count + 1;
        end
    end
endmodule
