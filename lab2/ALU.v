// non b type
`define ADD 4'b0000
`define SUB 4'b0001
`define AND 4'b0010
`define OR  4'b0011
`define XOR 4'b0100
`define SLL 4'b0101
`define SRL 4'b0110

// b type
`define BEQ 4'b0111
`define BNE 4'b1000
`define BLT 4'b1001
`define BGE 4'b1010

module ALU(input [3:0] alu_op, input [31:0] alu_in_1, input [31:0] alu_in_2, output reg [31:0] alu_result, output reg alu_bcond);
  always @(*) begin
    alu_bcond = 0;
    alu_result = 0;

    if (alu_op == `ADD) begin
        alu_result = alu_in_1 + alu_in_2;
    end else if (alu_op == `SUB) begin
        alu_result = alu_in_1 - alu_in_2;
    end else if (alu_op == `AND) begin
        alu_result = alu_in_1 & alu_in_2;
    end else if (alu_op == `OR) begin
        alu_result = alu_in_1 | alu_in_2;
    end else if (alu_op == `XOR) begin
        alu_result = alu_in_1 ^ alu_in_2;
    end else if (alu_op == `SLL) begin
        alu_result = alu_in_1 << alu_in_2;
    end else if (alu_op == `SRL) begin
        alu_result = alu_in_1 >> alu_in_2;
    end else if (alu_op == `BEQ) begin
        alu_bcond = alu_in_1 == alu_in_2;
    end else if (alu_op == `BNE) begin
        alu_bcond = alu_in_1 != alu_in_2;
    end else if (alu_op == `BLT) begin
        alu_bcond = alu_in_1 < alu_in_2;
    end else if (alu_op == `BGE) begin
        alu_bcond = alu_in_1 >= alu_in_2;
    end
  end
endmodule