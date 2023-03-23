`include "opcodes.v"
`include "ALU.v"

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
    write_enable = 0; // regWrite in pdf
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

module ALUControlUnit(input [31:0] inst, output reg [3:0] alu_op);
  always @(*) begin
    alu_op = 0;

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
endmodule
