module Mux2To1(input [31:0] din0, input [31:0] din1, input sel, output [31:0] dout);
  assign dout = sel ? din1 : din0;
endmodule

module Mux4To1 #(parameter WIDTH = 32) (input [WIDTH-1:0] din0,
               input [WIDTH-1:0] din1,
               input [WIDTH-1:0] din2,
               input [WIDTH-1:0] din3,
               input [1:0] sel,
               output [WIDTH-1:0] dout);
  assign dout = sel[1] ? (sel[0] ? din3 : din2) : (sel[0] ? din1 : din0);
endmodule