module ControlUnit(input [31:0] part_of_inst,
                   output is_jal,
                   output is_jalr,
                   output branch,
                   output mem_read,
                   output mem_to_reg,
                   output mem_write,
                   output alu_src,
                   output write_enable,
                   output pc_to_reg,
                   output is_ecall);
  
endmodule

module ALUControlUnit(input [31:0] part_of_inst, output alu_op);
  
endmodule
