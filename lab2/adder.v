module Adder(input [31:0] in1, input [31:0] in2, output [31:0] dout);
    always @(*) begin
        sum = in1 + in2;
    end