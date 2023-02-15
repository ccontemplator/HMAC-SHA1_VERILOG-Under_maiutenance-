`timescale 1ns / 1ps

module SHA1_tb();

reg clk;
reg rst_n;
reg SHA1_req;
reg [447:0] plain_text;
reg [8:0] size;
wire task_done;
wire [159:0] hashed_text;


initial begin
    clk = 1'b0;
    rst_n = 1'b1;
    SHA1_req = 1'b0;
    plain_text = 'd0;
    size = 'd0;
    #20 
    SHA1_req = 1'b1;
    //text=abcdefgh
    plain_text = 448'h0000000000000000_0000000000000000_0000000000000000_0000000000000000_0000000000000000_0000000000000000_6162636465666768;
    size = 'd64;
end


always begin
    #10 clk = ~clk;
end

always@ (posedge clk) begin
    if(task_done == 1'b1) begin
        SHA1_req = 1'b0;
        $display("Hashed text is %h:", hashed_text);
    end
    else begin
        SHA1_req = SHA1_req;
    end
end

Top_SHA1 SHA1_ins(.clk(clk), .rst_n(rst_n), .SHA1_req(SHA1_req), .plain_text(plain_text), .size(size), .hashed_text(hashed_text), .task_done(task_done));


endmodule
