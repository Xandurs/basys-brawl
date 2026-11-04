`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.10.2026 19:35:38
// Design Name: 
// Module Name: game_flow
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


// INTRO(menu) -> P1: READY -> FIGHT -> KO/TIMEUP -> TURN_END
//             -> P2: READY -> FIGHT -> KO/TIMEUP -> WINNER -> INTRO
module game_flow(
    input CLOCK,
    input reset,
    input tick,
    input start_pulse,              // from Yuhan's menu: start P1's turn
    input continue_pulse,           // BTNC: P2's turn / back to menu
    input pause_sw,
    input [6:0] p1_hp,              // health of the human fighter (P1 or P2)
    input [6:0] cpu_hp,

    output reg [2:0] phase  = 3'b000,
    output reg [5:0] timer  = 6'b111100,
    output reg [1:0] count  = 2'b11,
    output reg [1:0] winner = 2'b00,          // 01 P1, 10 P2, 11 draw
    output reg       turn   = 1'b0,           // 0 = P1's turn, 1 = P2's turn
    output reg       p1_ko   = 1'b0,          // P1 knocked out the CPU
    output reg [5:0] p1_time = 6'b000000,     // seconds P1 had left
    output reg [6:0] p1_left = 7'b0000000,    // CPU health P1 left behind
    output reg       match_reset = 1'b0,
    output fight_active,
    output fighter_playing,
    output ko_phase
    );

    localparam INTRO    = 3'b000;
    localparam READY    = 3'b001;
    localparam FIGHT    = 3'b010;
    localparam PAUSE    = 3'b011;
    localparam KO       = 3'b100;
    localparam TIMEUP   = 3'b101;
    localparam WINNER   = 3'b110;
    localparam TURN_END = 3'b111;               // NEW: between P1's and P2's turns

    localparam P1 = 2'b01, P2 = 2'b10, DRAW = 2'b11;
    localparam LAST_FRAME = 6'b011101;          // 29
    localparam MATCH_SECS = 6'b111100;          // 60
    localparam READY_SECS = 2'b11;              // 3
    localparam BANNER     = 8'b00111100;        // 60 ticks = 2 s

    reg [5:0] frames = 6'b000000;
    reg [7:0] hold   = 8'b00000000;

    wire this_ko = (cpu_hp == 7'b0000000);      // current player knocked out the CPU

    always @(posedge CLOCK) begin
        match_reset <= 1'b0;

        if (reset) begin
            phase   <= INTRO;
            timer   <= MATCH_SECS;
            count   <= READY_SECS;
            winner  <= 2'b00;
            frames  <= 6'b000000;
            hold    <= 8'b00000000;
            turn    <= 1'b0;
            p1_ko   <= 1'b0;
            p1_time <= 6'b000000;
            p1_left <= 7'b0000000;
        end

        //INTRO: menu on screen, wait for its start pulse
        else if (phase == INTRO) begin
            if (start_pulse) begin
                phase       <= READY;
                turn        <= 1'b0;                // P1 goes first
                count       <= READY_SECS;
                frames      <= 6'b000000;
                timer       <= MATCH_SECS;
                winner      <= 2'b00;
                match_reset <= 1'b1;
            end
        end

        //READY: 3, 2, 1 
        else if (phase == READY) begin
            if (tick) begin
                if (frames == LAST_FRAME) begin
                    frames <= 6'b000000;
                    if (count == 2'b01) phase <= FIGHT;
                    else                count <= count - 1;
                end else
                    frames <= frames + 1;
            end
        end

        //FIGHT: KO > pause > timer
        else if (phase == FIGHT) begin
            if (p1_hp == 7'b0000000 || cpu_hp == 7'b0000000) begin
                phase <= KO;
                hold  <= BANNER;
            end
            else if (pause_sw) begin
                phase <= PAUSE;
            end
            else if (tick) begin
                if (frames == LAST_FRAME) begin
                    frames <= 6'b000000;
                    if (timer == 6'b000001) begin
                        timer <= 6'b000000;
                        phase <= TIMEUP;
                        hold  <= BANNER;
                    end else
                        timer <= timer - 1;
                end else
                    frames <= frames + 1;
            end
        end

        //PAUSE 
        else if (phase == PAUSE) begin
            if (!pause_sw) phase <= FIGHT;
        end

        // KO or TIMEUP: banner, then record / compare 
        else if (phase == KO || phase == TIMEUP) begin
            if (tick) begin
                if (hold == 8'b00000001) begin
                    if (turn == 1'b0) begin
                        // P1's turn is over: save the result
                        p1_ko   <= this_ko;
                        p1_time <= timer;
                        p1_left <= cpu_hp;
                        phase   <= TURN_END;
                    end
                    else begin
                        // P2's turn is over: compare with P1
                        phase <= WINNER;
                        if (p1_ko && this_ko) begin                 // both KO'd: faster wins
                            if      (p1_time > timer) winner <= P1;
                            else if (timer > p1_time) winner <= P2;
                            else                      winner <= DRAW;
                        end
                        else if (p1_ko)   winner <= P1;             // only P1 KO'd
                        else if (this_ko) winner <= P2;             // only P2 KO'd
                        else begin                                  // neither: more damage wins
                            if      (p1_left < cpu_hp) winner <= P1;
                            else if (cpu_hp < p1_left) winner <= P2;
                            else                       winner <= DRAW;
                        end
                    end
                end
                else
                    hold <= hold - 1;
            end
        end

        // TURN_END: "P2 READY", BTNC starts P2's turn
        else if (phase == TURN_END) begin
            if (continue_pulse) begin
                phase       <= READY;
                turn        <= 1'b1;
                count       <= READY_SECS;
                frames      <= 6'b000000;
                timer       <= MATCH_SECS;
                match_reset <= 1'b1;                // fresh fighters, health, meter
            end
        end

        //WINNER: BTNC goes back to the menu
        else if (phase == WINNER) begin
            if (continue_pulse) phase <= INTRO;
        end
    end

    assign fight_active    = (phase == FIGHT);
    assign fighter_playing = (phase == FIGHT) || (phase == KO);
    assign ko_phase        = (phase == KO);
endmodule
