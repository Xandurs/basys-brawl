`timescale 1ns / 1ps

module ai_decision(
    input CLOCK,
    input reset,
    input tick,
    input [6:0] player_x,
    input [6:0] cpu_x,
    input [3:0] cpu_state,
    input [7:0] random_num,
    input [1:0] difficulty,
    input [1:0] personality,
    input cpu_busy,
    output reg action_valid,
    output reg [2:0] action
);
    parameter NONE     = 3'b000;   //action 
    parameter APPROACH = 3'b001;
    parameter PUNCH    = 3'b010;
    parameter BLOCK    = 3'b011;
    parameter RETREAT  = 3'b100;
    parameter FIREBALL = 3'b101;
    parameter DASH     = 3'b110;
    parameter JUMP     = 3'b111;

    parameter AGGRESSIVE = 2'b00;  //personality 
    parameter DEFENSIVE  = 2'b01;
    parameter ZONER      = 2'b10;

    reg [5:0] reaction_counter;  //counter for reaction time
    reg [5:0] reaction_limit;

    always @(*) begin
        case (difficulty)
            2'b00: reaction_limit = 15;   //easy
            2'b01: reaction_limit = 9;    //medium
            2'b10: reaction_limit = 5;     //hard
            default: reaction_limit = 9;    //medium is the default
        endcase
    end

    reg [6:0] distance;

    always @(*) begin
        distance = (player_x >= cpu_x) ? (player_x - cpu_x) : (cpu_x - player_x);  //calculate distance between player and cpu
    end

    always @(posedge CLOCK) begin
          action_valid <= 0;

          if (reset) begin
              reaction_counter <= 0;
              action <= NONE;
          
          end
          
          else if (tick) begin

            if (cpu_busy) begin   
                  
             reaction_counter <= 0;  //if cpu is busy, no action is taken

            end

            else if (reaction_counter >= reaction_limit - 1) begin
                reaction_counter <= 0;  //reset reaction counter after action is taken
                action_valid <= 1;  //indicate that an action has been decided

                if (personality == AGGRESSIVE) begin   //AGGRESSIVE personality logic
                    if (distance <=20) begin
                         if (random_num < 190)
                            action <= PUNCH;
                        else
                            action <= BLOCK;
                    end
                    else begin
                        if (random_num < 180)
                            action <= APPROACH;
                        else
                            action <= DASH;
                    end
                end


                else if (personality == DEFENSIVE) begin   //DEFENSIVE personality logic
                    if (distance <= 20) begin
                        if (random_num < 110)
                            action <= BLOCK;
                        else if (random_num < 180)
                            action <= RETREAT;
                        else
                            action <= PUNCH;
                    end
                    
                    else begin
                        if (random_num < 150)
                            action <= APPROACH;
                        else
                            action <= BLOCK;
                    end
                end


                else if (personality == ZONER) begin   //ZONER personality logic
                    
                    if (distance <= 20) begin
                        
                        if (random_num < 180)
                            action <= RETREAT;
                        else 
                        action <= PUNCH;
                     end
                    
                    else begin 
                        if (random_num < 180)
                            action <= FIREBALL;
                        else
                            action <= APPROACH;
                    end
                end
            end 
            else begin
                reaction_counter <= reaction_counter + 1;  //increment reaction counter if no action is taken
                end
            end
         end

         endmodule

                       


              
              

                  

                      

                      

                 
              
        