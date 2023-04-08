`include "opcodes.v"
`include "ALU.v"

module ControlUnit(input clk,
                   input [6:0] part_of_inst,
                   output reg pc_write_cond,
                   output reg pc_write,
                   output reg i_or_d,
                   output reg mem_read,
                   output reg mem_write,
                   output reg mem_to_reg,
                   output reg ir_write,
                   output reg pc_source,
                   output reg alu_src_a,
                   output reg [1:0] alu_src_b,
                   output reg reg_write,
                   output reg alu_as_adder,
                   output reg is_ecall);
endmodule

module ALUControlUnit(input [31:0] inst, input as_adder, output reg [3:0] alu_op);
  always @(*) begin
    alu_op = 0;

    if (as_adder) begin
        alu_op = `ADD;
    end else begin
        if (inst[6:0] == `ARITHMETIC) begin
            if (inst[14:12] == `FUNCT3_ADD) begin
                if (inst[31:25] == `FUNCT7_SUB) begin
                    alu_op = `SUB;
                end else begin
                    alu_op = `ADD;
                end
            end else if (inst[14:12] == `FUNCT3_SLL) begin
                alu_op = `SLL;
            end else if (inst[14:12] == `FUNCT3_XOR) begin
                alu_op = `XOR;
            end else if (inst[14:12] == `FUNCT3_OR) begin
                alu_op = `OR;
            end else if (inst[14:12] == `FUNCT3_AND) begin
                alu_op = `AND;
            end else if (inst[14:12] == `FUNCT3_SRL) begin
                alu_op = `SRL;
            end
        end else if (inst[6:0] == `ARITHMETIC_IMM) begin
            if (inst[14:12] == `FUNCT3_ADD) begin
                alu_op = `ADD;
            end else if (inst[14:12] == `FUNCT3_SLL) begin
                alu_op = `SLL;
            end else if (inst[14:12] == `FUNCT3_XOR) begin
                alu_op = `XOR;
            end else if (inst[14:12] == `FUNCT3_OR) begin
                alu_op = `OR;
            end else if (inst[14:12] == `FUNCT3_AND) begin
                alu_op = `AND;
            end else if (inst[14:12] == `FUNCT3_SRL) begin
                alu_op = `SRL;
            end
        end else if (inst[6:0] == `LOAD || inst[6:0] == `STORE || inst[6:0] == `JALR) begin
            alu_op = `ADD;
        end else if (inst[6:0] == `BRANCH) begin
            if (inst[14:12] == `FUNCT3_BEQ) begin
                alu_op = `BEQ;
            end else if (inst[14:12] == `FUNCT3_BNE) begin
                alu_op = `BNE;
            end else if (inst[14:12] == `FUNCT3_BLT) begin
                alu_op = `BLT;
            end else if (inst[14:12] == `FUNCT3_BGE) begin
                alu_op = `BGE;
            end
        end
    end
  end
endmodule
