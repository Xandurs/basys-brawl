`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2026 16:38:11
// Design Name: 
// Module Name: Top_Basys_Brawl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module background(
    input CLOCK, reset, tick, playing, ko,
    input [12:0] pixel_index,

    // merged overlay out
    output reg visible,
    output reg [15:0] oled_data    // oled output
);

reg [1:0] randomiser = 0; reg [19:0] count = 0;
reg stars;  
reg [6:0] x,y;
/*
always @(posedge CLOCK) begin
        counter <= counter + 1;
        randomiser <= counter % 3; // random select background
end
*/

always @(*) begin
    x = pixel_index % 96; //checks for x axis value
    y = pixel_index/96;// check for y axis value
    visible = 1'b0;
    oled_data = 16'h0000;
    stars = (x == 7'd2 && y == 7'd1) || (x == 7'd21 && y == 7'd11) ||
            (x == 7'd18 && y == 7'd6) || (x == 7'd79 && y == 7'd31) ||
            (x == 7'd90 && y == 7'd41) || (x == 7'd66 && y == 7'd39) ||
            (x == 7'd43 && y == 7'd19) || (x == 7'd50 && y == 7'd7) ||
            (x == 7'd29 && y == 7'd5) || (x == 7'd14 && y == 7'd27) ||
            (x == 7'd87 && y == 7'd2);

    if (reset || !playing) visible = 1'b0;
    else begin
        visible = 1'b1;
        if(y < 60) begin
            oled_data = 16'h0084; //near blue-black sky
            if (stars) oled_data = 16'hFFFF; //star specks
            if((((x-7'd94)*(x-7'd94) + (y-7'd2)*(y-7'd2)) <= 289) && x <= 7'd95 && y >= 7'd0) begin
                if(((x-7'd94)*(x-7'd94) + (y-7'd2)*(y-7'd2)) <= 225) begin
                    if(((x-7'd94)*(x-7'd94) + (y-7'd2)*(y-7'd2)) <= 144) oled_data = 16'hFFFF; //moon
                    else oled_data = 16'hCCCC; //moon
                end
                else oled_data = 16'hAAAA; //moon
            end 
        end
    end
end


endmodule