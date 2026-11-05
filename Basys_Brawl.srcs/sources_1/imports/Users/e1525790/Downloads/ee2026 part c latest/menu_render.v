`timescale 1ns / 1ps

module menu_render(
    input [6:0] pixel_x,
    input [5:0] pixel_y,

    input [1:0] menu_state,
    input [1:0] difficulty,
    input [1:0] personality,
    input [1:0] round_count,
    input [1:0] character_slot, character_choice,

    output reg [15:0] pixel_data
);

    // Menu states
    parameter TITLE       = 2'b00;
    parameter DIFFICULTY  = 2'b01;
    parameter PERSONALITY = 2'b10;
    parameter CHARACTER   = 2'b11;

    // Difficulty values
    parameter EASY   = 2'b00;
    parameter MEDIUM = 2'b01;
    parameter HARD   = 2'b10;

    // Personality values
    parameter AGGRESSIVE = 2'b00;
    parameter DEFENSIVE  = 2'b01;
    parameter ZONER      = 2'b10;


    reg [7:0] char_code;
    reg [127:0] name_line;
    
    wire [11:0] mul43    = pixel_x * 6'd43;             // x*43
    wire [3:0]  cell_col = mul43[11:8];                  // = x/6
    wire [2:0]  cell_row = pixel_y[5:3];                 // = y/8
    wire [6:0]  char_x   = {cell_col, 2'b00} + {cell_col, 1'b0};   // col*4 + col*2 = col*6
    wire [5:0]  char_y   = {cell_row, 3'b000};           // row*8
    reg selected_line;

    wire glyph_on;


   
    // FONT RENDERER
   

    font_render font (
        .char_code(char_code),

        .pixel_x(pixel_x),
        .pixel_y(pixel_y),

        .char_x(char_x),
        .char_y(char_y),

        .pixel_on(glyph_on)
    );


    
    // DECIDE WHICH CHARACTER BELONGS IN EACH CELL
    
    always @(*) begin


        // Default = space
        char_code = 8'h20;

        selected_line = 0;
        name_line = "                ";


        case (menu_state)

            // TITLE SCREEN
            

            TITLE: begin

                // BASYS BRAWL
                if (cell_row == 1) begin

                    case (cell_col)

                        2:  char_code = "B";
                        3:  char_code = "A";
                        4:  char_code = "S";
                        5:  char_code = "Y";
                        6:  char_code = "S";

                        8:  char_code = "B";
                        9:  char_code = "R";
                        10: char_code = "A";
                        11: char_code = "W";
                        12: char_code = "L";

                    endcase

                end


                // PRESS SELECT
                else if (cell_row == 4) begin

                    case (cell_col)

                        2:  char_code = "P";
                        3:  char_code = "R";
                        4:  char_code = "E";
                        5:  char_code = "S";
                        6:  char_code = "S";

                        8:  char_code = "S";
                        9:  char_code = "E";
                        10: char_code = "L";
                        11: char_code = "E";
                        12: char_code = "C";
                        13: char_code = "T";

                    endcase

                end

            end


            // ========================================
            // DIFFICULTY SCREEN
            // ========================================

            DIFFICULTY: begin

                // DIFFICULTY
                if (cell_row == 0) begin

                    case (cell_col)

                        3:  char_code = "D";
                        4:  char_code = "I";
                        5:  char_code = "F";
                        6:  char_code = "F";
                        7:  char_code = "I";
                        8:  char_code = "C";
                        9:  char_code = "U";
                        10: char_code = "L";
                        11: char_code = "T";
                        12: char_code = "Y";

                    endcase

                end


                // EASY
                else if (cell_row == 2) begin

                    selected_line = (difficulty == EASY);

                    if ((cell_col == 3) && (difficulty == EASY))
                        char_code = ">";

                    case (cell_col)
                        5: char_code = "E";
                        6: char_code = "A";
                        7: char_code = "S";
                        8: char_code = "Y";
                    endcase

                end


                // MEDIUM
                else if (cell_row == 4) begin

                    selected_line = (difficulty == MEDIUM);

                    if ((cell_col == 3) && (difficulty == MEDIUM))
                        char_code = ">";

                    case (cell_col)
                        5:  char_code = "M";
                        6:  char_code = "E";
                        7:  char_code = "D";
                        8:  char_code = "I";
                        9:  char_code = "U";
                        10: char_code = "M";
                    endcase

                end


                // HARD
                else if (cell_row == 6) begin

                    selected_line = (difficulty == HARD);

                    if ((cell_col == 3) && (difficulty == HARD))
                        char_code = ">";

                    case (cell_col)
                        5: char_code = "H";
                        6: char_code = "A";
                        7: char_code = "R";
                        8: char_code = "D";
                    endcase

                end

            end


          
            // PERSONALITY SCREEN
            

            PERSONALITY: begin

                // CPU STYLE
                if (cell_row == 0) begin

                    case (cell_col)

                        3:  char_code = "C";
                        4:  char_code = "P";
                        5:  char_code = "U";

                        7:  char_code = "S";
                        8:  char_code = "T";
                        9:  char_code = "Y";
                        10: char_code = "L";
                        11: char_code = "E";

                    endcase

                end


                // AGGRESSIVE
                else if (cell_row == 2) begin

                    selected_line = (personality == AGGRESSIVE);

                    if ((cell_col == 3) &&
                        (personality == AGGRESSIVE))
                        char_code = ">";

                    case (cell_col)

                        5:  char_code = "A";
                        6:  char_code = "G";
                        7:  char_code = "G";
                        8:  char_code = "R";
                        9:  char_code = "E";
                        10: char_code = "S";
                        11: char_code = "S";
                        12: char_code = "I";
                        13: char_code = "V";
                        14: char_code = "E";

                    endcase

                end


                // DEFENSIVE
                else if (cell_row == 4) begin

                    selected_line = (personality == DEFENSIVE);

                    if ((cell_col == 3) &&
                        (personality == DEFENSIVE))
                        char_code = ">";

                    case (cell_col)

                        5:  char_code = "D";
                        6:  char_code = "E";
                        7:  char_code = "F";
                        8:  char_code = "E";
                        9:  char_code = "N";
                        10: char_code = "S";
                        11: char_code = "I";
                        12: char_code = "V";
                        13: char_code = "E";

                    endcase

                end


                // ZONER
                else if (cell_row == 6) begin

                    selected_line = (personality == ZONER);

                    if ((cell_col == 3) &&
                        (personality == ZONER))
                        char_code = ">";

                    case (cell_col)

                        5: char_code = "Z";
                        6: char_code = "O";
                        7: char_code = "N";
                        8: char_code = "E";
                        9: char_code = "R";

                    endcase

                end

            end


            // ========================================
            // ROUND COUNT
            // ========================================

            CHARACTER: begin
                if (cell_row == 0) begin
                    case (character_slot)
                        0: name_line = "  P1 CHARACTER  ";
                        1: name_line = "  P2 CHARACTER  ";
                        default: name_line = " CPU CHARACTER  ";
                    endcase
                end else if (cell_row == 2) begin
                    name_line = "   DR CHUA      ";
                    selected_line = (character_choice == 0);
                end else if (cell_row == 4) begin
                    name_line = "   PROF MASSIMO ";
                    selected_line = (character_choice == 1);
                end else if (cell_row == 6) begin
                    name_line = "   KARTHI       ";
                    selected_line = (character_choice == 2);
                end
                char_code = name_line >> ((15 - cell_col) * 8);
                if (selected_line && cell_col == 1) char_code = ">";
            end

        endcase

    end


    // ================================================
    // COLOUR OUTPUT
    // ================================================

    always @(*) begin

        if (glyph_on) begin

            if (selected_line)
                pixel_data = 16'hFFE0;   // Yellow

            else
                pixel_data = 16'hFFFF;   // White

        end

        else begin

            pixel_data = 16'h0000;       // Black

        end

    end

endmodule