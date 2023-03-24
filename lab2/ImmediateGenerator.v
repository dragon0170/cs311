`include "opcodes.v"

module ImmediateGenerator(input [31:0] inst, output reg [31:0] imm_gen_out);
  reg [6:0] opcode;
    
  always @(*) begin
    opcode = inst[6:0];
    
    if (opcode == `ARITHMETIC_IMM || opcode == `LOAD || opcode == `JALR) begin
      imm_gen_out = {{21{inst[31]}}, inst[30:20]};
    end else if (opcode == `STORE) begin
      imm_gen_out = {{21{inst[31]}}, inst[30:25], inst[11:7]};
    end else if (opcode == `BRANCH) begin
      imm_gen_out = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 2'b0};
    end else if (opcode == `JAL) begin
      imm_gen_out = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 2'b0};
    end else begin
      imm_gen_out = 32'b0;
    end
  end
endmodule