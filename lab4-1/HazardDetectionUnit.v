`include "opcodes.v"

module HazardDetectionUnit(input reg_write_ex,
                           input reg_write_mem,
                           input [6:0] opcode_id,
                           input [4:0] rs1_id,
                           input [4:0] rs2_id,
                           input [4:0] rd_ex,
                           input [4:0] rd_mem,
                           output stall);
    wire use_rs1;
    wire use_rs2;
    assign use_rs1 = (opcode_id != `JAL && rs1_id != 0) || opcode_id == `ECALL;
    assign use_rs2 = (opcode_id == `ARITHMETIC || opcode_id == `STORE || opcode_id == `BRANCH) && rs2_id != 0;

    assign stall = (use_rs1 && rs1_id == rd_ex && reg_write_ex)
                || (use_rs1 && rs1_id == rd_mem && reg_write_mem)
                || (use_rs2 && rs2_id == rd_ex && reg_write_ex)
                || (use_rs2 && rs2_id == rd_mem && reg_write_mem);
endmodule
