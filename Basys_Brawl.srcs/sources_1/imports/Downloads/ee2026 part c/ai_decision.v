`timescale 1ns / 1ps

module ai_decision(
    input CLOCK,
    input reset,
    input tick,
    input [6:0] player_x,
    input [6:0] cpu_x,
    input [3:0] cpu_state,
    input [3:0] player_state,
    input [7:0] random_num,
    input [1:0] difficulty,
    input [1:0] personality,
    input cpu_busy,

    //special move uptime
    input fireball_ready,
    input dash_ready,
    input shield_ready,
    input ult_ready,

    output reg action_valid,
    output reg [3:0] action // 4 bits to represent 10 possible actions or more

    
);
    parameter NONE     = 4'b0000;
    parameter APPROACH = 4'b0001;
    parameter PUNCH    = 4'b0010;
    parameter BLOCK    = 4'b0011;
    parameter RETREAT  = 4'b0100;
    parameter FIREBALL = 4'b0101;
    parameter DASH     = 4'b0110;
    parameter JUMP     = 4'b0111;
    parameter SHIELD   = 4'b1000;
    parameter ULT      = 4'b1001;

    parameter AGGRESSIVE = 2'b00;  //personality 
    parameter DEFENSIVE  = 2'b01;
    parameter ZONER      = 2'b10;

    reg [5:0] reaction_counter;  //counter for reaction time
    reg [5:0] reaction_limit;

    always @(*) begin
        case (difficulty)
            2'b00: reaction_limit = 10;   //easy
            2'b01: reaction_limit = 5;    //medium
            2'b10: reaction_limit = 2;     //hard
            default: reaction_limit = 5;    //medium is the default
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

            //if (difficulty == 2'b10) begin
                
                
                if ((distance <= 20) && (player_state == 4'd4) && (difficulty == 2'b10))  begin

                    if (shield_ready)
                        action <= SHIELD;
                    else
                        action <= BLOCK;

    end
             else if ((player_state == 4'd7) && (distance <= 20) && (difficulty == 2'b10)) begin
                 if (shield_ready)
                    action <= SHIELD;
                 else
                    action <= BLOCK;
    end
            else if ((player_state == 4'd5) && (difficulty == 2'b10)) begin
               
                if ((distance <= 20) && ult_ready)
                    action <= ULT;

                 else if (distance <= 20)
                    action <= PUNCH;

                else if (dash_ready)
                     action <= DASH;

                 else
                     action <= APPROACH;
    end

            else if ((player_state == 4'd3) && (distance <= 20) && (difficulty == 2'b10)) begin
                action <= RETREAT;
    end

                else if (personality == AGGRESSIVE) begin   //AGGRESSIVE personality logic 
                    if (distance <=20) begin

                        //rare ult
                        if (ult_ready && random_num < 20)             //close range
                            action <= ULT;

                        else if (dash_ready && random_num < 70) //dash 
                            action <= DASH;
                        else if (random_num < 100)
                            action <= JUMP;
                        else if (random_num < 220)  //punch will be most common
                            action <= PUNCH;

                        else                       
                            action <= BLOCK;  //block sometimes
                    end

                    else if (distance <= 45) begin    //MID RANGE

                        if (dash_ready && random_num < 100)
                            action <= DASH;

                        else if (random_num < 150)
                            action <= JUMP;

                        else
                            action <= APPROACH;

                     end
                    
                    else begin   //Player is far away, so approach or dash towards them
                        if (random_num < 50 && dash_ready)
                            action <= DASH;
                        else if (random_num < 90)
                            action <= JUMP;                       
                        else if (random_num < 130 && fireball_ready)  //fireball will be used sometimes
                            action <= FIREBALL;
                        else
                            action <= APPROACH;
                    end
                end


                else if (personality == DEFENSIVE) begin   //DEFENSIVE personality logic
                    if (distance <= 20) begin
                         if ((random_num < 20) && ult_ready)
                            action <= ULT;
                        else if (random_num < 80 && shield_ready)
                            action <= SHIELD;
                        else if (random_num < 140)
                            action <= BLOCK;
                        else if (random_num < 190)
                            action <= RETREAT;
                        else if ( random_num < 220)
                            action <= JUMP;
                        else
                            action <= PUNCH;
                    end

                    else if (distance <= 45) begin  //MID RANGE

                        // Keep some space
                    if (random_num < 80)
                         action <= RETREAT;

                        // Sometimes reposition
                    else if (random_num < 125)
                         action <= JUMP;

                        // Occasionally attack
                    else if (fireball_ready && random_num < 165)
                        action <= FIREBALL;

                        // Otherwise approach carefully
                    else
                         action <= APPROACH;

                    end

                    
                    else begin
                        if ((random_num < 50) && fireball_ready)
                            action <= FIREBALL;
                        else if (ult_ready && random_num < 105)
                            action <= ULT;
                        else if (random_num < 140)
                            action <= APPROACH;
                        else if (random_num < 175)
                            action <= JUMP;
                        else
                            action <= BLOCK;

                    end
                end


                else if (personality == ZONER) begin   //ZONER personality logic
                    
                    if (distance <= 20) begin
                        
                        if (random_num < 60 && shield_ready)
                            action <= SHIELD;
                        else if (random_num < 150)
                            action <= RETREAT;
                        else if (random_num < 200)
                            action <= JUMP;                       
                        else 
                        action <= PUNCH;
                     end

                    else if (distance <= 45) begin
                        if (fireball_ready && random_num < 110)
                            action <= FIREBALL;
                        else if (ult_ready && random_num < 140)
                             action <= ULT;
                        else if (random_num < 200)
                            action <= RETREAT;
                        else
                             action <= JUMP;

                    end

                    
                    else begin 
                        if (random_num < 135 && fireball_ready)
                            action <= FIREBALL;
                        else if ((random_num < 175) && ult_ready)
                            action <= ULT;
                        else if (random_num < 210)
                            action <= JUMP;
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

                       


              
              

                  

                      

                      

                 
              
        