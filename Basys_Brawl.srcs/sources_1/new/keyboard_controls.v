`timescale 1ns / 1ps
                                                            
                                                                           
module keyboard_controls(
    input CLOCK, reset, code_reset, PS2Clk, PS2Data,
    output reg [21:0] held = 0,
    output reg [21:0] pressed = 0,
    output reg [9:0] code_sw = 0
);
                                                                 
                                                              
                                                                            
    (* ASYNC_REG = "TRUE" *) reg [1:0] cs = 2'b11, ds = 2'b11;
    reg [7:0] filter = 8'hFF;
    reg filtered_clk = 1, previous_clk = 1;
    reg [3:0] bit_count = 0;
    reg [9:0] bits = 0;
    reg [17:0] timeout_count = 0;
    reg [7:0] scan = 0;
    reg valid = 0;
    reg released = 0, extended = 0;
    reg [3:0] skip = 0;
    integer key;
    wire falling = previous_clk && !filtered_clk;

    always @(posedge CLOCK) begin
        cs <= {cs[0], PS2Clk};
        ds <= {ds[0], PS2Data};
        filter <= {filter[6:0], cs[1]};
        if (&filter) filtered_clk <= 1;
        else if (~|filter) filtered_clk <= 0;
        previous_clk <= filtered_clk;
        valid <= 0;
        if (reset) begin
            bit_count <= 0; timeout_count <= 0;
        end else if (falling) begin
            timeout_count <= 0;
            if (bit_count == 0) begin
                if (!ds[1]) begin
                    bits[0] <= 0;
                    bit_count <= 1;
                end
            end else if (bit_count == 10) begin
                bit_count <= 0;
                                                                      
                if (!bits[0] && ds[1] && (^bits[9:1])) begin
                    scan <= bits[8:1]; valid <= 1;
                end
            end else begin
                bits[bit_count] <= ds[1];
                bit_count <= bit_count + 1;
            end
        end else if (bit_count != 0) begin
            if (timeout_count == 199999) begin                               
                bit_count <= 0; timeout_count <= 0;
            end else timeout_count <= timeout_count + 1;
        end
    end

                                                                             
    always @(*) begin
        key = -1;
        case (scan)
            8'h1D: if (!extended) key = 0;      
            8'h1C: if (!extended) key = 1;      
            8'h23: if (!extended) key = 2;      
            8'h3B: if (!extended) key = 3;      
            8'h43: if (!extended) key = 4;             
            8'h42: if (!extended) key = 5;      
            8'h4B: if (!extended) key = 6;      
            8'h31: if (!extended) key = 7;                 
            8'h3A: if (!extended) key = 8;                    
            8'h5A: key = 9;                                            
            8'h45: if (!extended) key = 10;     
            8'h16: if (!extended) key = 11;     
            8'h1E: if (!extended) key = 12;     
            8'h26: if (!extended) key = 13;     
            8'h25: if (!extended) key = 14;     
            8'h2E: if (!extended) key = 15;     
            8'h36: if (!extended) key = 16;     
            8'h3D: if (!extended) key = 17;     
            8'h3E: if (!extended) key = 18;     
            8'h46: if (!extended) key = 19;     
            8'h3C: if (!extended) key = 20;     
            8'h1B: if (!extended) key = 21;     
        endcase
    end

    always @(posedge CLOCK) begin
        pressed <= 0;
        if (reset) begin
            held <= 0; code_sw <= 0;
            released <= 0; extended <= 0; skip <= 0;
        end else if (valid) begin
            if (scan == 8'hAA) begin                              
                held <= 0; released <= 0; extended <= 0; skip <= 0;
            end else if (skip != 0) skip <= skip - 1;
            else if (scan == 8'hE1) begin                                 
                skip <= 7; released <= 0; extended <= 0;
            end else if (scan == 8'hE0) extended <= 1;
            else if (scan == 8'hF0) released <= 1;
            else begin
                if (key >= 0) begin
                    held[key] <= !released;
                    if (!released && !held[key]) begin
                        pressed[key] <= 1;
                        if (key >= 10 && key <= 19) code_sw[key-10] <= !code_sw[key-10];
                    end
                end
                if (scan == 8'h66 && !extended && !released) code_sw <= 0;             
                released <= 0; extended <= 0;
            end
        end
        if (code_reset) code_sw <= 0;
    end
endmodule

