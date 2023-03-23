module Mux(input [31:0] de_assert, input [31:0] assert, input sel, output [31:0] dout);
    always @(*) begin
        if (sel) begin
            out = assert;
        end else begin
            out = de_assert;
        end
    end