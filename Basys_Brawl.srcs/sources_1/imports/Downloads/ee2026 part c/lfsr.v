`timescale 1ns / 1ps

module lfsr(
    input CLOCK,
    input reset,
    input enable,
    output reg [7:0] random_num = 8'b00000001
);

    wire feedback;

    assign feedback =
        random_num[7] ^
        random_num[5] ^
        random_num[4] ^
        random_num[3];

    always @(posedge CLOCK) begin

        if (reset)
            random_num <= 8'b00000001;
        else if (enable)
            random_num <= {
                random_num[6:0], feedback
            };

    end

endmodule