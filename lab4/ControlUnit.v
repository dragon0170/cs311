`include "opcodes.v"
`include "ALU.v"

module ControlUnit(input clk,
                   input reset,
                   input [6:0] part_of_inst,
                   input [6:0] opcode_from_mem,
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

    reg [1:0] addr_ctl; // control signal for MUX in address select logic
    reg [3:0] state; // micro program counter

    wire [3:0] increased_state;
    wire [3:0] next_state;
    reg [3:0] mux_in1;
    reg [3:0] mux_in2;
    reg [3:0] mux_in3;

    // Microcode Storage
    always @(*) begin
        pc_write_cond = 0;
        pc_write = 0;
        i_or_d = 0;
        mem_read = 0;
        mem_write = 0;
        mem_to_reg = 0;
        ir_write = 0;
        pc_source = 0;
        alu_src_a = 0;
        alu_src_b = 2'b00;
        reg_write = 0;
        alu_as_adder = 0;
        is_ecall = 0;

        if (state == 0) begin
            mem_read = 1;
            i_or_d = 0;
            ir_write = 1;
            alu_src_a = 0;
            alu_src_b = 2'b01;
            alu_as_adder = 1;
            addr_ctl = 3;
        end else if (state == 1) begin
            alu_src_a = 0;
            alu_src_b = 2'b10;
            alu_as_adder = 1;
            pc_write = 1;
            pc_source = 1;
            addr_ctl = 1;
        end else if (state == 2) begin
            alu_src_a = 1;
            alu_src_b = 2'b10;
            addr_ctl = 2;
        end else if (state == 3) begin
            mem_read = 1;
            i_or_d = 1;
            addr_ctl = 3;
        end else if (state == 4) begin
            reg_write = 1;
            mem_to_reg = 1;
            addr_ctl = 0;
        end else if (state == 5) begin
            mem_write = 1;
            i_or_d = 1;
            addr_ctl = 0;
        end else if (state == 6) begin
            alu_src_a = 1;
            alu_src_b = 2'b00;
            addr_ctl = 3;
        end else if (state == 7) begin
            reg_write = 1;
            mem_to_reg = 0;
            addr_ctl = 0;
        end else if (state == 8) begin
            alu_src_a = 1;
            alu_src_b = 2'b00;
            pc_write_cond = 1;
            pc_source = 1;
            addr_ctl = 0;
        end else if (state == 9) begin
            alu_src_a = 0;
            alu_src_b = 2'b10;
            alu_as_adder = 1;
            pc_write = 1;
            pc_source = 0;
            reg_write = 1;
            mem_to_reg = 0;
            addr_ctl = 0;
        end else if (state == 10) begin
            alu_src_a = 0;
            alu_src_b = 2'b01;
            alu_as_adder = 1;
            addr_ctl = 3;
        end else if (state == 11) begin
            alu_src_a = 1;
            alu_src_b = 2'b10;
            pc_write = 1;
            pc_source = 0;
            reg_write = 1;
            mem_to_reg = 0;
            addr_ctl = 0;
        end else if (state == 12) begin
            is_ecall = 1;
            addr_ctl = 0;
        end
    end

    // adder for state plus one
    Adder #(
        .WIDTH(4)
    ) adder(
        .in1(state),
        .in2(4'b1),
        .dout(increased_state)
    );

    // address select logic
    always @(*) begin
        if (part_of_inst == `LOAD || part_of_inst == `STORE || part_of_inst == `ARITHMETIC_IMM) begin
            mux_in1 = 4'd2;
        end else if (part_of_inst == `ARITHMETIC) begin
            mux_in1 = 4'd6;
        end else if (part_of_inst == `BRANCH) begin
            mux_in1 = 4'd8;
        end else if (part_of_inst == `ECALL) begin
            mux_in1 = 4'd12;
        end
    end
    always @(*) begin
        if (part_of_inst == `LOAD) begin
            mux_in2 = 4'd3;
        end else if (part_of_inst == `STORE) begin
            mux_in2 = 4'd5;
        end else if (part_of_inst == `ARITHMETIC_IMM) begin
            mux_in2 = 4'd7;
        end
    end
    always @(*) begin
        if (state == 0) begin
            if (opcode_from_mem == `JAL) begin
                mux_in3 = 4'd9;
            end else if (opcode_from_mem == `JALR) begin
                mux_in3 = 4'd10;
            end else begin
                mux_in3 = increased_state;
            end
        end else begin
            mux_in3 = increased_state;
        end
    end

    Mux4To1 #(
        .WIDTH(4)
    ) addr_select_mux(
        .din0(4'b0),
        .din1(mux_in1),
        .din2(mux_in2),
        .din3(mux_in3),
        .sel(addr_ctl),
        .dout(next_state)
    );

    // micro program counter
    always @(posedge clk) begin
        if (reset) begin
            state <= 0;
        end else begin
            state <= next_state;
        end
    end
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
