`timescale 1ns / 1ps

module Top_SHA1(

        input clk,
        input rst_n,
        input SHA1_req,  //SHA1_req should be zero on receipt of (task_done = 1)
        input [447:0] plain_text, //At most 56 characters (56*1byte = 448 bits)
        input [8:0] size, //number of bits
        output [159:0] hashed_text,
        output task_done

);

parameter WAIT_TIME_LIMIT = 'd4;

wire rst;
assign rst = ~rst_n;
////
reg [2:0] wait_counter;
reg req;
////
wire [511:0] inp_temp1;
wire [511:0] inp_temp2;
wire [511:0] SHA1_input_text;
assign inp_temp1 = {plain_text, 64'h8000_0000_0000_0000};
assign inp_temp2 = inp_temp1 << ('d448 - size);
assign SHA1_input_text = {inp_temp2[511:64], 55'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_000, size[8:0]};

//The system will wait 5 cycles to start requesting SHA1_round

//wait_counter
always @(posedge clk) begin
    if(rst || task_done || SHA1_req == 1'b0) begin
        wait_counter <= 'd0;
    end
    else if(SHA1_req == 1'b1 && wait_counter <= WAIT_TIME_LIMIT) begin
        wait_counter <= wait_counter + 'd1;
    end
    else begin
        wait_counter <= wait_counter;
    end
end

//req
always @(posedge clk) begin
    if(rst || task_done || SHA1_req == 1'b0) begin //req should be zero on receipt of (task_done = 1)
        req <= 1'b0;
    end
    else if(wait_counter == WAIT_TIME_LIMIT) begin
        req <= 1'b1;
    end
    else begin
        req <= req;
    end
end

SHA1_round sha_round_ins(.clk(clk), .rst(rst), .req(req), .SHA1_input_text(SHA1_input_text), .hashed_text(hashed_text), .task_done(task_done));

endmodule