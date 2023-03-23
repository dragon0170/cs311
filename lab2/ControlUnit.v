`include "opcodes.v"

module ControlUnit(input [6:0] part_of_inst,
                   output reg is_jal,
                   output reg is_jalr,
                   output reg branch,
                   output reg mem_read,
                   output reg mem_to_reg,
                   output reg mem_write,
                   output reg alu_src,
                   output reg write_enable,
                   output reg pc_to_reg,
                   output reg is_ecall);
  always @(*) begin
    is_jal = 0;
    is_jalr = 0;
    branch = 0;
    mem_read = 0;
    mem_to_reg = 0;
    mem_write = 0;
    alu_src = 0;
    write_enable = 0;
    pc_to_reg = 0;
    is_ecall = 0;

    if (part_of_inst == `JAL) begin
        is_jal = 1;
        pc_to_reg = 1;
    end else if (part_of_inst == `JALR) begin
        is_jalr = 1;
        pc_to_reg = 1;
    end else if (part_of_inst == `LOAD) begin
        mem_read = 1;
        mem_to_reg = 1;
    end else if (part_of_inst == `STORE) begin
        mem_write = 1;
    end else if (part_of_inst == `BRANCH) begin
        branch = 1;
    end else if (part_of_inst == `ECALL) begin
        is_ecall = 1;
    end

    if (part_of_inst != `STORE && part_of_inst != `BRANCH) begin
        write_enable = 1;
    end
    if (part_of_inst != `ARITHMETIC && part_of_inst != `BRANCH) begin
        alu_src = 1;
    end
  end
endmodule

module ALUControlUnit(input [31:0] part_of_inst, output alu_op);
  
endmodule
