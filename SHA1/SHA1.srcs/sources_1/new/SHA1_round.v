`timescale 1ns / 1ps


module SHA1_round(
    input clk,
    input rst,
    input req,
    input [511:0] SHA1_input_text,
    output [159:0] hashed_text, //output 160 bits
    output reg task_done
);
//Some constants
parameter K1 = 32'h5a827999;
parameter K2 = 32'h6ed9eba1;
parameter K3 = 32'h8f1bbcdc;
parameter K4 = 32'hca62c1d6;
//states
parameter IDLE = 'd0;
parameter CONFIG = 'd1;
parameter ROUND = 'd2;
//state time limit
parameter CONFIG_TIME_LIMIT = 'd5;
parameter ROUND_TIME_LIMIT = 'd79;

reg [1:0] state;
reg [1:0] round;

reg [31:0] A,B,C,D,E;
assign hashed_text = {A,B,C,D,E};

wire [31:0] F1,F2_4,F3;
assign F1 = (B & C) | ((~B) & D);
assign F2_4 = B ^ C ^ D;
assign F3 = (B & C) | (B & D) | (C & D);

wire [31:0] S5_A;
assign S5_A = (A << 5) | (A >> 27); //left shift 5 bits 

reg [6:0] step_counter;
reg [3:0] CONFIG_wait;

//CONFIG_wait
always@ (posedge clk) begin
    if(rst || req == 1'b0) begin
        CONFIG_wait <= 1'b0;
    end
    else if(state == CONFIG) begin
        if(CONFIG_wait == CONFIG_TIME_LIMIT) begin 
            CONFIG_wait <= 1'b0;
        end
        else begin
            CONFIG_wait <= CONFIG_wait + 1'b1;
        end
    end
    else begin
        CONFIG_wait <= CONFIG_wait;
    end
end

//state
always@ (posedge clk) begin
    if(rst || req == 1'b0) begin
        state <= IDLE;
    end
    else if(req == 1'b1) begin
        case(state)
            IDLE: begin
              state <= CONFIG;  
            end
            CONFIG: begin
                if(CONFIG_wait == CONFIG_TIME_LIMIT) begin
                    state <= ROUND;
                end
                else begin
                    state <= state;
                end
            end
            ROUND: begin
                if(step_counter == ROUND_TIME_LIMIT) begin
                    if(round < 'd3) begin
                        state <= CONFIG;
                    end
                    else begin //task done!
                        state <= IDLE;
                    end
                end
                else begin
                    state <= state;
                end
            end
            
            default: state <= state;
        endcase
    end
end

//round
always@ (posedge clk) begin
    if(rst || req == 1'b0) begin
        round <= 'd3; //default 3
    end
    else if(CONFIG_wait == CONFIG_TIME_LIMIT) begin
        round <= round + 'd1;
    end
    else begin
        round <= round;
    end
end

//step_counter
always@ (posedge clk) begin
    if(rst || req == 1'b0) begin
        step_counter <= 'd0;
    end
    else if(req == 1'b1) begin
        if(CONFIG_wait == CONFIG_TIME_LIMIT) begin //state == CONFIG is implicitly true
            step_counter <= 'd0;
        end
        else if(state == ROUND && step_counter < ROUND_TIME_LIMIT) begin
            step_counter <= step_counter + 'd1;       
        end
        else begin
            step_counter <= 'd0;
        end
    end
    else begin
        step_counter <= step_counter;
    end
end

//w0~w19 for each round
reg [31:0] w0,w1,w2,w3,w4,w5,w6,w7,w8,w9,w10,w11,w12,w13,w14,w15,w16,w17,w18,w19;
always@ (posedge clk) begin //each round consists of 20 steps
    if(rst || req == 1'b0) begin
        {w0,w1,w2,w3,w4,w5,w6,w7,w8,w9,w10,w11,w12,w13,w14,w15,w16,w17,w18,w19} <= 'd0;
    end
    else if(step_counter == ROUND_TIME_LIMIT) begin //non-blocking  3 cycles configuration of w1~w19
            w0 <= ({w4 ^ w6 ^ w12 ^ w17} << 1) | ({w4 ^ w6 ^ w12 ^ w17} >> (31)); //circularly left shift one bit
            w1 <= ({w5 ^ w7 ^ w13 ^ w18} << 1) | ({w5 ^ w7 ^ w13 ^ w18} >> (31)); //circularly left shift one bit
            w2 <= ({w6 ^ w8 ^ w14 ^ w19} << 1) | ({w6 ^ w8 ^ w14 ^ w19} >> (31)); //circularly left shift one bit
            w3 <= ({w7 ^ w9 ^ w15 ^ w0} << 1) | ({w7 ^ w9 ^ w15 ^ w0} >> (31)); //circularly left shift one bit
            w4 <= ({w8 ^ w10 ^ w16 ^ w1} << 1) | ({w8 ^ w10 ^ w16 ^ w1} >> (31)); //circularly left shift one bit
            w5 <= ({w9 ^ w11 ^ w17 ^ w2} << 1) | ({w9 ^ w11 ^ w17 ^ w2} >> (31)); //circularly left shift one bit
            w6 <= ({w10 ^ w12 ^ w18 ^ w3} << 1) | ({w10 ^ w12 ^ w18 ^ w3} >> (31)); //circularly left shift one bit
            w7 <= ({w11 ^ w13 ^ w19 ^ w4} << 1) | ({w11 ^ w13 ^ w19 ^ w4} >> (31)); //circularly left shift one bit
            w8 <= ({w12 ^ w14 ^ w0 ^ w5} << 1) | ({w12 ^ w14 ^ w0 ^ w5} >> (31)); //circularly left shift one bit
            w9 <= ({w13 ^ w15 ^ w1 ^ w6} << 1) | ({w13 ^ w15 ^ w1 ^ w6} >> (31)); //circularly left shift one bit
            w10 <= ({w14 ^ w16 ^ w2 ^ w7} << 1) | ({w14 ^ w16 ^ w2 ^ w7} >> (31)); //circularly left shift one bit
            w11 <= ({w15 ^ w17 ^ w3 ^ w8} << 1) | ({w15 ^ w17 ^ w3 ^ w8} >> (31)); //circularly left shift one bit
            w12 <= ({w16 ^ w18 ^ w4 ^ w9} << 1) | ({w16 ^ w18 ^ w4 ^ w9} >> (31)); //circularly left shift one bit
            w13 <= ({w17 ^ w19 ^ w5 ^ w10} << 1) | ({w17 ^ w19 ^ w5 ^ w10} >> (31)); //circularly left shift one bit
            w14 <= ({w18 ^ w0 ^ w6 ^ w11} << 1) | ({w18 ^ w0 ^ w6 ^ w11} >> (31)); //circularly left shift one bit
            w15 <= ({w19 ^ w1 ^ w7 ^ w12} << 1) | ({w19 ^ w1 ^ w7 ^ w12} >> (31)); //circularly left shift one bit
            w16 = ({w0 ^ w2 ^ w8 ^ w13} << 1) | ({w0 ^ w2 ^ w8 ^ w13} >> (31)); //circularly left shift one bit
            w17 = ({w1 ^ w3 ^ w9 ^ w14} << 1) | ({w1 ^ w3 ^ w9 ^ w14} >> (31)); //circularly left shift one bit
            w18 = ({w2 ^ w4 ^ w10 ^ w15} << 1) | ({w2 ^ w4 ^ w10 ^ w15} >> (31)); //circularly left shift one bit
            w19 = ({w3 ^ w5 ^ w11 ^ w16} << 1) | ({w3 ^ w5 ^ w11 ^ w16} >> (31)); //circularly left shift one bit
    end     
    else if(round == 'd3 && (req == 1'b1 && state == IDLE)) begin //blocking 3 cycles configuration of w1~w19
            {w0,w1,w2,w3,w4,w5,w6,w7,w8,w9,w10,w11,w12,w13,w14,w15} = SHA1_input_text;
            w16 = ({w0 ^ w2 ^ w8 ^ w13} << 1) | ({w0 ^ w2 ^ w8 ^ w13} >> (31)); //circularly left shift one bit
            w17 = ({w1 ^ w3 ^ w9 ^ w14} << 1) | ({w1 ^ w3 ^ w9 ^ w14} >> (31)); //circularly left shift one bit
            w18 = ({w2 ^ w4 ^ w10 ^ w15} << 1) | ({w2 ^ w4 ^ w10 ^ w15} >> (31)); //circularly left shift one bit
            w19 = ({w3 ^ w5 ^ w11 ^ w16} << 1) | ({w3 ^ w5 ^ w11 ^ w16} >> (31)); //circularly left shift one bit
    end
    else begin
        {w0,w1,w2,w3,w4,w5,w6,w7,w8,w9,w10,w11,w12,w13,w14,w15,w16,w17,w18,w19} <= {w0,w1,w2,w3,w4,w5,w6,w7,w8,w9,w10,w11,w12,w13,w14,w15,w16,w17,w18,w19};
    end
end


//A,B,C,D,E
reg [31:0] w_i;
always @(posedge clk) begin

        if(rst || req == 1'b0) begin
                {A,B,C,D,E} <= {32'h67452301, 32'hefcdab89, 32'h98badcfe, 32'h10325476, 32'hc3d2e1f0};
        end
        else if(state == ROUND && step_counter < ROUND_TIME_LIMIT) begin //after going into ROUND state 1 cycle
        
                case(round)
                    2'b00: begin //4cycles
                        if(step_counter[1:0] == 2'b00) begin
                                A <= E ^ F1 ^ S5_A ^ w_i ^ K1;
                                B <= A;
                                C <= (B << 30) | (B >> 2);
                                D <= C;
                                E <= D;
                        end
                        else begin
                            {A,B,C,D,E} <= {A,B,C,D,E};
                        end
                    end

                    2'b01: begin //4cycles
                        if(step_counter[1:0] == 2'b00) begin
                                A <= E ^ F2_4 ^ S5_A ^ w_i ^ K2;
                                B <= A;
                                C <= (B << 30) | (B >> 2);
                                D <= C;
                                E <= D;
                        end
                        else begin
                            {A,B,C,D,E} <= {A,B,C,D,E};
                        end                        
                    end

                    2'b10: begin //4cycles
                        if(step_counter[1:0] == 2'b00) begin
                                A <= E ^ F3 ^ S5_A ^ w_i ^ K3;
                                B <= A;
                                C <= (B << 30) | (B >> 2);
                                D <= C;
                                E <= D;
                        end
                        else begin
                            {A,B,C,D,E} <= {A,B,C,D,E};
                        end    
                    end

                    2'b11: begin //4cycles
                        if(step_counter[1:0] == 2'b00) begin
                                A <= E ^ F2_4 ^ S5_A ^ w_i ^ K4;
                                B <= A;
                                C <= (B << 30) | (B >> 2);
                                D <= C;
                                E <= D;
                        end
                        else begin
                            {A,B,C,D,E} <= {A,B,C,D,E};
                        end   
                    end

                    default: {A,B,C,D,E} <= {A,B,C,D,E};

                endcase
        end
        else begin
            {A,B,C,D,E} <= {A,B,C,D,E};
        end

end

//w_string
reg [639:0] w_string;
always@ (posedge clk) begin
    if(rst || req == 1'b0) begin
        w_string <= 'd0;
    end
    else if(CONFIG_wait == CONFIG_TIME_LIMIT) begin
        w_string <= {w0,w1,w2,w3,w4,w5,w6,w7,w8,w9,w10,w11,w12,w13,w14,w15,w16,w17,w18,w19};
    end
    else if(step_counter[1:0] == 2'b00) begin
        w_string <= w_string << 32;
    end
    else begin
        w_string <= w_string;
    end
end

//w_i
always@ (posedge clk) begin//prepare w_i

        if(rst || state == IDLE) begin
            w_i <= 'd0;
        end
        else if(step_counter[1:0] == 2'b01) begin 
             w_i <= w_string[639:608];
        end
        else if(CONFIG_wait == CONFIG_TIME_LIMIT && round == 'd3) begin
             w_i <= w0;
        end
        else begin
            w_i <= w_i;
        end
end

//task_done
always @(posedge clk) begin
    if(rst || state == IDLE) begin
        task_done <= 1'b0;
    end
    else if(round == 'd3 && step_counter == ROUND_TIME_LIMIT) begin
        task_done <= 1'b1;
    end
    else begin
        task_done <= 1'b0;
    end
end

endmodule