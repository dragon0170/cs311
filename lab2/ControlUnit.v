`include "opcodes.v"

module ControlUnit(input [6:0] part_of_inst,
                   output is_jal,
                   output is_jalr,
                   output branch,
                   output mem_read,
                   output mem_to_reg,
                   output mem_write,
                   output alu_src,
                   output write_enable,
                   output pc_to_reg,
                   output reg is_ecall);
  always @(*) begin
    is_ecall = 0;
    if (part_of_inst == `ECALL) begin
        is_ecall = 1;
    end
  end
endmodule

module ALUControlUnit(input [31:0] part_of_inst, output alu_op);
  
endmodule
