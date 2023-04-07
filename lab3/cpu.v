// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  /***** Wire declarations *****/
  wire [31:0] next_pc;
  wire [31:0] current_pc;
  wire [31:0] addr;
  wire i_or_d;
  wire mem_read;
  wire mem_write;
  wire reg_write;
  wire ir_write;
  wire pc_write;
  wire pc_write_cond;
  wire [3:0] alu_op;
  wire [31:0] rd_din;
  wire [31:0] rs1_dout;
  wire [31:0] rs2_dout;
  wire [31:0] r17_dout;
  wire [31:0] imm_gen_out;
  wire mem_to_reg;
  wire alu_src_a;
  wire [1:0] alu_src_b;
  wire pc_source;
  wire alu_as_adder;
  wire is_ecall;
  wire [31:0] alu_in_1;
  wire [31:0] alu_in_2;
  wire [31:0] alu_result;
  wire alu_bcond;
  wire [31:0] dout;

  /***** Register declarations *****/
  reg [31:0] IR; // instruction register
  reg [31:0] MDR; // memory data register
  reg [31:0] A; // Read 1 data register
  reg [31:0] B; // Read 2 data register
  reg [31:0] ALUOut; // ALU output register
  // Do not modify and use registers declared above.

  assign is_halted = is_ecall && rs1_dout == 10;

  // synchronously update registers
  always @(posedge clk) begin
    if (ir_write) begin
      IR <= dout;
    end
    MDR <= dout;
    A <= rs1_dout;
    B <= rs2_dout;
    ALUOut <= alu_result;
  end

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .pc_write(pc_write || (alu_bcond && pc_write_cond)), // input
    .next_pc(next_pc),     // input
    .current_pc(current_pc)   // output
  );

  // ---------- Register File ----------
  RegisterFile reg_file(
    .reset(reset),        // input
    .clk(clk),          // input
    .rs1(is_ecall ? 5'b10001 : IR[19:15]),          // input
    .rs2(IR[24:20]),          // input
    .rd(IR[11:7]),           // input
    .rd_din(rd_din),       // input
    .write_enable(reg_write),    // input
    .rs1_dout(rs1_dout),     // output
    .rs2_dout(rs2_dout)      // output
  );

  // ---------- Memory ----------
  Memory memory(
    .reset(reset),        // input
    .clk(clk),          // input
    .addr(addr),         // input
    .din(B),          // input
    .mem_read(mem_read),     // input
    .mem_write(mem_write),    // input
    .dout(dout)          // output
  );

  // ---------- Control Unit ----------
  ControlUnit ctrl_unit(
    .part_of_inst(IR[6:0]),  // input
    .pc_write_cond(pc_write_cond),      // output
    .pc_write(pc_write),      // output
    .i_or_d(i_or_d),      // output
    .mem_read(mem_read),      // output
    .mem_write(mem_write),     // output
    .mem_to_reg(mem_to_reg),    // output
    .ir_write(ir_write),      // output
    .pc_source(pc_source),     // output
    .alu_src_a(alu_src_a),       // output
    .alu_src_b(alu_src_b),       // output
    .reg_write(reg_write),     // output
    .alu_as_adder(alu_as_adder),     // output
    .is_ecall(is_ecall)       // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .inst(IR),  // input
    .imm_gen_out(imm_gen_out)    // output
  );

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit(
    .inst(IR),  // input
    .as_adder(alu_as_adder),  // input
    .alu_op(alu_op)         // output
  );

  // ---------- ALU ----------
  ALU alu(
    .alu_op(alu_op),      // input
    .alu_in_1(alu_in_1),    // input  
    .alu_in_2(alu_in_2),    // input
    .alu_result(alu_result),  // output
    .alu_bcond(alu_bcond)     // output
  );

endmodule
