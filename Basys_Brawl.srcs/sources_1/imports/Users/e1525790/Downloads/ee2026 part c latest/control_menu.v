`timescale 1ns / 1ps

module control_menu(
    input CLOCK,
    input reset,

    input up_pressed,
    input down_pressed,
    input select_pressed,

    output reg [1:0] menu_state,

    output reg [1:0] difficulty,
    output reg [1:0] personality,
    output reg [1:0] round_count,
    output reg start_match
);

//menu states
parameter TITLE = 2'b00;
parameter DIFFICULTY = 2'b01;           
parameter PERSONALITY = 2'b10;
parameter ROUND_COUNT = 2'b11;

//difficulty options
parameter EASY = 2'b00;
parameter MEDIUM = 2'b01;
parameter HARD = 2'b10;

//personality options
parameter AGGRESSIVE = 2'b00;
parameter DEFENSIVE = 2'b01;
parameter ZONER = 2'b10;

always @(posedge CLOCK) begin
    if (reset) begin
        menu_state <= TITLE;
        
        difficulty <= MEDIUM;
        personality <= AGGRESSIVE;
        round_count <= 2'b11; // Default to 3 rounds
        start_match <= 0;
    end
    
    else begin

        start_match <= 0; // Reset start_match at the beginning of each clock cycle//1 for 1 clock cycle when menu is finished

        case (menu_state) 

            TITLE: begin
                
                if (select_pressed) 
                    menu_state <= DIFFICULTY;
                
            end

            DIFFICULTY: begin
                 if (down_pressed) begin

                        if (difficulty == HARD)                           
                            difficulty <= EASY;
                        
                        else
                              difficulty <= difficulty + 1;

                    end
                    
                    else if (up_pressed) begin

                        if (difficulty == EASY)
                            difficulty <= HARD;
                        else
                            difficulty <= difficulty - 1;

                    end

                    else if (select_pressed) begin
                        menu_state <= PERSONALITY;
                    end

                end

            PERSONALITY: begin
                if (down_pressed) begin

                        if (personality == ZONER)
                            personality <= AGGRESSIVE;
                       
                        else
                            personality <= personality + 1;

                    end

                    else if (up_pressed) begin

                        if (personality == AGGRESSIVE)
                            personality <= ZONER;
                        else
                            personality <= personality - 1;
                    end

                    else if (select_pressed) begin
                        start_match <= 1;                // start the match after choosing CPU style
                        menu_state  <= TITLE;
                    end

                end

            ROUND_COUNT: begin
                 if (down_pressed) begin

                        if (round_count == 3)
                            round_count <= 1;
                        else
                            round_count <= round_count + 1;
                    end

                    else if (up_pressed) begin

                        if (round_count == 1)
                            round_count <= 3;
                        else
                            round_count <= round_count - 1;
                    end

                    else if (select_pressed) begin

                        start_match <= 1;
                        menu_state <= TITLE;

                    end

                end

        endcase
    end
end
endmodule