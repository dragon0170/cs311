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
  wire [31:0] inst;
  wire mem_read;
  wire mem_write;
  wire write_enable;
  wire [3:0] alu_op;
  wire [31:0] rd_din;
  wire [31:0] rs1_dout;
  wire [31:0] rs2_dout;
  wire [31:0] r17_dout;
  wire [31:0] imm_gen_out;
  wire is_jal;
  wire is_jalr;
  wire branch;
  wire mem_to_reg;
  wire alu_src;
  wire pc_to_reg;
  wire is_ecall;
  wire [31:0] alu_in_2;
  wire [31:0] alu_result;
  wire alu_bcond;
  wire [31:0] dout;
  wire [31:0] bj_out;
  wire [31:0] pc_src1_out;
  wire [31:0] rd_din_pre;

  /***** Register declarations *****/

  // for debugging the value. Remove this before submit
  always @(inst) begin
    $display("current_pc: %d", current_pc, ", inst: %h", inst, ", is_ecall: %b", is_ecall);
  end

  // TODO: Temporary calculate next pc by adding 4 to current pc
  assign next_pc =  current_pc + 4;

  assign is_halted = is_ecall && r17_dout == 10;

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(next_pc),     // input
    .current_pc(current_pc)   // output
  );
  
  // ---------- Instruction Memory ----------
  InstMemory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(current_pc),    // input
    .dout(inst)     // output
  );

  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (inst[19:15]),          // input
    .rs2 (inst[24:20]),          // input
    .rd (inst[11:7]),           // input
    .rd_din (rd_din),       // input
    .write_enable (write_enable),    // input
    .rs1_dout (rs1_dout),     // output
    .rs2_dout (rs2_dout),     // output
    .r17_dout (r17_dout)
  );


  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .part_of_inst(inst[6:0]),  // input
    .is_jal(is_jal),        // output
    .is_jalr(is_jalr),       // output
    .branch(branch),        // output
    .mem_read(mem_read),      // output
    .mem_to_reg(mem_to_reg),    // output
    .mem_write(mem_write),     // output
    .alu_src(alu_src),       // output
    .write_enable(write_enable),     // output
    .pc_to_reg(pc_to_reg),     // output
    .is_ecall(is_ecall)       // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .inst(inst),  // input
    .imm_gen_out(imm_gen_out)    // output
  );

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit (
    .inst(inst),  // input
    .alu_op(alu_op)         // output
  );

  // ---------- ALU ----------
  ALU alu (
    .alu_op(alu_op),      // input
    .alu_in_1(rs1_dout),    // input = alu_in_1 
    .alu_in_2(alu_in_2),    // input
    .alu_result(alu_result),  // output
    .alu_bcond(alu_bcond)     // output
  );

  // ---------- Data Memory ----------
  DataMemory dmem(
    .reset (reset),      // input
    .clk (clk),        // input
    .addr (alu_result),       // input
    .din (rs2_dout),        // input
    .mem_read (mem_read),   // input
    .mem_write (mem_write),  // input
    .dout (dout)        // output
  );


  // ---------- MUX at ALUsrc----------
  Mux mux_alu_src(
    .de_assert(rs2_dout),  // input
    .assert(imm_gen_out),  // input
    .sel(alu_src),  // input
    .dout(alu_in_2)  // output
  );

  // ----- Adder for B/J instruction---
  Adder adder_b_j(
    .in1(current_pc),  // input
    .in2(imm_gen_out),  // input
    .dout(bj_out)  // output
  );

  // ---------- MUX at PCsrc1----------
  Mux mux_pc_src1(
    .de_assert(next_pc),  // input
    .assert(bj_out),  // input
    .sel(is_jal || (branch && alu_bcond)),  // input
    .dout(pc_src1_out)  // output
  );

  // ---------- MUX at PCsrc2----------
  Mux mux_pc_src2(
    .de_assert(pc_src1_out),  // input
    .assert(alu_result),  // input
    .sel(is_jalr),  // input
    .dout(next_pc)  // output
  );

  // --------- MUX after Data Memory---
  Mux mux_dmem(
    .de_assert(alu_result),  // input
    .assert(dout),  // input
    .sel(mem_to_reg),  // input
    .dout(rd_din_pre)  // output
  );

  // ---------- MUX at rd_din----------
  Mux mux_rd_din(
    .de_assert(rd_din_pre),  // input
    .assert(current_pc + 4),  // input
    .sel(pc_to_reg),  // input
    .dout(rd_din)  // output
  );

endmodule
