`timescale 1ns / 1ps

module c_cpu(   //TESTING ONLY, DO NOT MODIFY or USE THIS MODULE IN YOUR DESIGN
    input CLOCK,
    input reset,
    input tick,

    // Information that will eventually come from Student A
    input [6:0] player_x,
    input [6:0] cpu_x,
    input [3:0] cpu_state,
    input[3:0] player_state,
    input cpu_busy,

    // Eventually comes from your menu
    input [1:0] difficulty,
    input [1:0] personality,

    input fireball_ready,
    input dash_ready,
    input shield_ready,
    input ult_ready,

    // Outputs to Student A
    output cpu_left,
    output cpu_right,
    output cpu_block,
    output cpu_jump,
    output cpu_punch,
    output cpu_shield,
    output cpu_ult,

    // Outputs to Student B
    output cpu_fireball,
    output cpu_dash
);

    // =========================================
    // Internal wires
    // =========================================

    wire [7:0] random_num;

    wire action_valid;
    wire [3:0] action;


    // =========================================
    // LFSR
    // =========================================

    lfsr rng (
        .CLOCK(CLOCK),
        .reset(reset),
        .enable(tick),
        .random_num(random_num)
    );


    // =========================================
    // AI decision module
    // =========================================

    ai_decision brain (
        .CLOCK(CLOCK),
        .reset(reset),
        .tick(tick),

        .player_x(player_x),
        .cpu_x(cpu_x),

        .cpu_state(cpu_state),
        .player_state(player_state),

        .random_num(random_num),

        .difficulty(difficulty),
        .personality(personality),

        .cpu_busy(cpu_busy),
        .fireball_ready(fireball_ready),
        .dash_ready(dash_ready),
        .shield_ready(shield_ready),
        .ult_ready(ult_ready),

        .action_valid(action_valid),
        .action(action)
    );


    // =========================================
    // CPU controller
    // =========================================

    cpu_control controller (
        .CLOCK(CLOCK),
        .reset(reset),

        .action_valid(action_valid),
        .action(action),

        .player_x(player_x),
        .cpu_x(cpu_x),

        .cpu_left(cpu_left),
        .cpu_right(cpu_right),
        .cpu_block(cpu_block),

        .cpu_jump(cpu_jump),
        .cpu_punch(cpu_punch),

        .cpu_fireball(cpu_fireball),
        .cpu_dash(cpu_dash),
        .cpu_shield(cpu_shield),
        .cpu_ult(cpu_ult)
    );

endmodule