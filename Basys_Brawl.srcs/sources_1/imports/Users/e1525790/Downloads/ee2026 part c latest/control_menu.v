`timescale 1ns / 1ps
module control_menu(
    input CLOCK, reset,
    input up_pressed, down_pressed, select_pressed,
    output reg [1:0] menu_state,
    output reg [1:0] difficulty, personality, round_count,
    output reg start_match,
    output reg [1:0] p1_character, p2_character, cpu_character,
    output reg [1:0] character_slot,
    output [1:0] character_choice
);
    localparam TITLE=0, DIFFICULTY=1, PERSONALITY=2, CHARACTER=3;
    wire [1:0] next_character;
    assign character_choice = (character_slot == 0) ? p1_character :
                              (character_slot == 1) ? p2_character : cpu_character;
    assign next_character = down_pressed ?
                            ((character_choice == 2) ? 0 : character_choice + 1'b1) :
                            ((character_choice == 0) ? 2 : character_choice - 1'b1);

    always @(posedge CLOCK) begin
        start_match <= 0;
        if (reset) begin
            menu_state <= TITLE; difficulty <= 1; personality <= 0;
            round_count <= 3; character_slot <= 0;
            p1_character <= 0; p2_character <= 1; cpu_character <= 2;
        end else begin
            case (menu_state)
                TITLE: if (select_pressed) menu_state <= DIFFICULTY;
                DIFFICULTY: begin
                    if (down_pressed) difficulty <= (difficulty == 2) ? 0 : difficulty + 1'b1;
                    else if (up_pressed) difficulty <= (difficulty == 0) ? 2 : difficulty - 1'b1;
                    else if (select_pressed) menu_state <= PERSONALITY;
                end
                PERSONALITY: begin
                    if (down_pressed) personality <= (personality == 2) ? 0 : personality + 1'b1;
                    else if (up_pressed) personality <= (personality == 0) ? 2 : personality - 1'b1;
                    else if (select_pressed) begin menu_state <= CHARACTER; character_slot <= 0; end
                end
                CHARACTER: begin
                    if (down_pressed || up_pressed) begin
                        case (character_slot)
                            0: p1_character <= next_character;
                            1: p2_character <= next_character;
                            2: cpu_character <= next_character;
                        endcase
                    end else if (select_pressed) begin
                        if (character_slot == 2) begin
                            start_match <= 1; menu_state <= TITLE; character_slot <= 0;
                        end else character_slot <= character_slot + 1'b1;
                    end
                end
                default: menu_state <= TITLE;
            endcase
        end
    end
endmodule
