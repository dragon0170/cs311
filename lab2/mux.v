module Mux(input [31:0] de_assert, input [31:0] assert, input sel, output [31:0] dout);
    assign dout = sel ? assert : de_assert;
endmodule