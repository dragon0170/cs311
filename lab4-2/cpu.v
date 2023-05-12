// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify modules (except InstMemory, DataMemory, and RegisterFile)
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  /***** Wire declarations *****/
  wire [31:0] predicted_next_pc;
  wire [31:0] next_pc;
  wire [31:0] current_pc;
  wire [31:0] inst;
  wire [31:0] rd_din_pre;
  wire [31:0] rd_din;
  wire [31:0] rs1_dout;
  wire [31:0] rs2_dout;
  wire [31:0] imm_gen_out;
  wire [31:0] alu_result;
  wire [31:0] mem_dout;
  wire is_jal;
  wire is_jalr;
  wire branch;
  wire alu_bcond;
  wire reg_write;
  wire mem_read;
  wire mem_write;
  wire mem_to_reg;
  wire pc_to_reg;
  wire is_ecall;
  wire [3:0] alu_op;
  wire alu_src;
  wire stall;
  wire [1:0] forward_a;
  wire [1:0] forward_b;
  wire [31:0] forwarded_rs2_data;
  wire [31:0] alu_in_1;
  wire [31:0] alu_in_2;

  wire [31:0] ex_pc_plus_4;
  wire [31:0] bj_out;
  wire [31:0] pc_src1_out;
  wire [31:0] actual_next_pc;
  wire branch_taken;
  wire predict_correct;
  wire id_flush;
  /***** Register declarations *****/
  // You need to modify the width of registers
  // In addition, 
  // 1. You might need other pipeline registers that are not described below
  // 2. You might not need registers described below
  /***** IF/ID pipeline registers *****/
  reg [31:0] IF_ID_inst;           // will be used in ID stage
  reg [31:0] IF_ID_pc;
  reg [31:0] IF_ID_predicted_next_pc;
  reg IF_ID_flush;
  /***** ID/EX pipeline registers *****/
  // From the control unit
  reg ID_EX_alu_src;        // will be used in EX stage
  reg ID_EX_is_jal;        // will be used in EX stage
  reg ID_EX_is_jalr;        // will be used in EX stage
  reg ID_EX_branch;        // will be used in EX stage
  reg ID_EX_mem_write;      // will be used in MEM stage
  reg ID_EX_mem_read;       // will be used in MEM stage
  reg ID_EX_mem_to_reg;     // will be used in WB stage
  reg ID_EX_pc_to_reg;     // will be used in WB stage
  reg ID_EX_reg_write;      // will be used in WB stage
  reg ID_EX_halt_cpu;      // will be used in WB stage
  reg ID_EX_flush;         // will be used in EX stage
  // From others
  reg [31:0] ID_EX_rs1_data;
  reg [31:0] ID_EX_rs2_data;
  reg [31:0] ID_EX_imm;
  reg [31:0] ID_EX_ALU_ctrl_unit_input;
  reg [4:0] ID_EX_rs1;
  reg [4:0] ID_EX_rs2;
  reg [4:0] ID_EX_rd;
  reg [31:0] ID_EX_pc;
  reg [31:0] ID_EX_predicted_next_pc;

  /***** EX/MEM pipeline registers *****/
  // From the control unit
  reg EX_MEM_mem_write;     // will be used in MEM stage
  reg EX_MEM_mem_read;      // will be used in MEM stage
  reg EX_MEM_mem_to_reg;    // will be used in WB stage
  reg EX_MEM_pc_to_reg;    // will be used in WB stage
  reg EX_MEM_reg_write;     // will be used in WB stage
  reg EX_MEM_halt_cpu;      // will be used in WB stage
  // From others
  reg [31:0] EX_MEM_pc_plus_4;
  reg [31:0] EX_MEM_alu_out;
  reg [31:0] EX_MEM_dmem_data;
  reg [4:0] EX_MEM_rd;

  /***** MEM/WB pipeline registers *****/
  // From the control unit
  reg MEM_WB_mem_to_reg;    // will be used in WB stage
  reg MEM_WB_pc_to_reg;    // will be used in WB stage
  reg MEM_WB_reg_write;     // will be used in WB stage
  reg MEM_WB_halt_cpu;      // will be used in WB stage
  // From others
  reg [31:0] MEM_WB_pc_plus_4;
  reg [31:0] MEM_WB_mem_to_reg_src_1;
  reg [31:0] MEM_WB_mem_to_reg_src_2;
  reg [4:0] MEM_WB_rd;

  BranchPredictor branch_predictor(
    .reset(reset),       // input
    .clk(clk),         // input
    .current_pc(current_pc), // input
    .write_index(ID_EX_pc[6:2]), // input
    .bht_data(branch_taken), // input
    .tag_data(ID_EX_pc[31:7]), // input
    .btb_data(actual_next_pc), // input
    .bht_write_enable(ID_EX_is_jal || ID_EX_is_jalr || ID_EX_branch),
    .tag_and_btb_write_enable(branch_taken && !predict_correct),
    .next_pc(predicted_next_pc) // output
  );

  Mux2To1 next_pc_mux(
    .din0(predicted_next_pc),
    .din1(actual_next_pc),
    .sel(!predict_correct),
    .dout(next_pc)
  );

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.  
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .pc_write(!stall),         // input
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

  // Update IF/ID pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      IF_ID_inst <= 0;
      IF_ID_pc <= 0;
      IF_ID_predicted_next_pc <= 4;
      IF_ID_flush <= 0;
    end
    else begin
      if (!stall) begin
        IF_ID_inst <= inst;
        IF_ID_pc <= current_pc;
        IF_ID_predicted_next_pc <= predicted_next_pc;
        IF_ID_flush <= !predict_correct;
      end
    end
  end

  // ---------- Hazard Detection Unit ----------
  HazardDetectionUnit hazard_detection_unit (
    .reg_write_ex (ID_EX_reg_write),  // input
    .reg_write_mem (EX_MEM_reg_write),  // input
    .mem_read_ex (ID_EX_mem_read),  // input
    .opcode_id (IF_ID_inst[6:0]),  // input
    .rs1_id (is_ecall ? 5'b10001 : IF_ID_inst[19:15]),  // input
    .rs2_id (IF_ID_inst[24:20]),  // input
    .rd_ex (ID_EX_rd),  // input
    .rd_mem (EX_MEM_rd),  // input
    .stall (stall)  // output
  );

  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (is_ecall ? 5'b10001 : IF_ID_inst[19:15]),  // input
    .rs2 (IF_ID_inst[24:20]),          // input
    .rd (MEM_WB_rd),           // input
    .rd_din (rd_din),       // input
    .write_enable (MEM_WB_reg_write),    // input
    .rs1_dout (rs1_dout),     // output
    .rs2_dout (rs2_dout)      // output
  );


  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .part_of_inst(IF_ID_inst[6:0]),  // input
    .is_jal(is_jal),        // output
    .is_jalr(is_jalr),       // output
    .branch(branch),        // output
    .mem_read(mem_read),      // output
    .mem_to_reg(mem_to_reg),    // output
    .mem_write(mem_write),     // output
    .alu_src(alu_src),       // output
    .write_enable(reg_write),  // output
    .pc_to_reg(pc_to_reg),     // output
    .is_ecall(is_ecall)       // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .inst(IF_ID_inst),  // input
    .imm_gen_out(imm_gen_out)    // output
  );

  assign id_flush = IF_ID_flush || !predict_correct;
  // Update ID/EX pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      ID_EX_alu_src <= 0;
      ID_EX_mem_write <= 0;
      ID_EX_mem_read <= 0;
      ID_EX_mem_to_reg <= 0;
      ID_EX_pc_to_reg <= 0;
      ID_EX_reg_write <= 0;
      ID_EX_halt_cpu <= 0;
      ID_EX_is_jal <= 0;
      ID_EX_is_jalr <= 0;
      ID_EX_branch <= 0;

      ID_EX_rs1_data <= 0;
      ID_EX_rs2_data <= 0;
      ID_EX_imm <= 0;
      ID_EX_ALU_ctrl_unit_input <= 0;
      ID_EX_rd <= 0;
      ID_EX_pc <= 0;
      ID_EX_predicted_next_pc <= 4;
      ID_EX_flush <= 0;
    end
    else begin
      ID_EX_alu_src <= alu_src;
      ID_EX_mem_write <= (stall || id_flush) ? 0 : mem_write;
      ID_EX_mem_read <= mem_read;
      ID_EX_mem_to_reg <= mem_to_reg;
      ID_EX_pc_to_reg <= pc_to_reg;
      ID_EX_reg_write <= (stall || id_flush) ? 0 : reg_write;
      ID_EX_halt_cpu <= (stall || id_flush) ? 0 : (is_ecall && rs1_dout == 10);
      ID_EX_is_jal <= (stall || id_flush) ? 0 : is_jal;
      ID_EX_is_jalr <= (stall || id_flush) ? 0 : is_jalr;
      ID_EX_branch <= (stall || id_flush) ? 0 : branch;

      ID_EX_rs1_data <= rs1_dout;
      ID_EX_rs2_data <= rs2_dout;
      ID_EX_imm <= imm_gen_out;
      ID_EX_ALU_ctrl_unit_input <= IF_ID_inst;
      ID_EX_rs1 <= IF_ID_inst[19:15];
      ID_EX_rs2 <= IF_ID_inst[24:20];
      ID_EX_rd <= IF_ID_inst[11:7];
      ID_EX_pc <= IF_ID_pc;
      ID_EX_predicted_next_pc <= IF_ID_predicted_next_pc;
      ID_EX_flush <= stall || id_flush;
    end
  end

  // Mux for alu_in_2
  Mux2To1 alu_in_2_mux(
    .din0(forwarded_rs2_data),
    .din1(ID_EX_imm),
    .sel(ID_EX_alu_src),
    .dout(alu_in_2)
  );

  // Mux for rs1 data forwarding
  Mux4To1 rs1_data_forward_mux(
    .din0 (ID_EX_rs1_data),
    .din1 (EX_MEM_alu_out),
    .din2 (rd_din),
    .din3 (32'b0),
    .sel (forward_a),
    .dout (alu_in_1)
  );

  // Mux for rs2 data forwarding
  Mux4To1 rs2_data_forward_mux(
    .din0 (ID_EX_rs2_data),
    .din1 (EX_MEM_alu_out),
    .din2 (rd_din),
    .din3 (32'b0),
    .sel (forward_b),
    .dout (forwarded_rs2_data)
  );

  ForwardingUnit forwarding_unit (
    .reg_write_mem (EX_MEM_reg_write), // input
    .reg_write_wb (MEM_WB_reg_write), // input
    .rs1_ex (ID_EX_rs1), // input
    .rs2_ex (ID_EX_rs2), // input
    .rd_mem (EX_MEM_rd), // input
    .rd_wb (MEM_WB_rd), // input
    .forward_a (forward_a), // output
    .forward_b (forward_b) // output
  );

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit (
    .inst(ID_EX_ALU_ctrl_unit_input),  // input
    .alu_op(alu_op)         // output
  );

  // ---------- ALU ----------
  ALU alu (
    .alu_op(alu_op),      // input
    .alu_in_1(alu_in_1),    // input  
    .alu_in_2(alu_in_2),    // input
    .alu_result(alu_result),  // output
    .alu_bcond(alu_bcond)     // output
  );

  // ----- Adder for B/J instruction---
  Adder adder_b_j(
    .in1(ID_EX_pc),  // input
    .in2(ID_EX_imm),  // input
    .dout(bj_out)  // output
  );

  // ----- Adder for current_pc + 4 ---
  Adder adder_pc_plus_4(
    .in1(ID_EX_pc),  // input
    .in2(32'd4),  // input
    .dout(ex_pc_plus_4)  // output
  );

  // ---------- MUX at PCsrc1----------
  Mux2To1 mux_pc_src1(
    .din0(ex_pc_plus_4),  // input
    .din1(bj_out),  // input
    .sel(ID_EX_is_jal || (ID_EX_branch && alu_bcond)),  // input
    .dout(pc_src1_out)  // output
  );

  // ---------- MUX at PCsrc2----------
  Mux2To1 mux_pc_src2(
    .din0(pc_src1_out),  // input
    .din1(alu_result),  // input
    .sel(ID_EX_is_jalr),  // input
    .dout(actual_next_pc)  // output
  );

  assign branch_taken = ID_EX_is_jal || ID_EX_is_jalr || (ID_EX_branch && alu_bcond);
  assign predict_correct = ID_EX_flush || (actual_next_pc == ID_EX_predicted_next_pc);

  // Update EX/MEM pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      EX_MEM_mem_write <= 0;
      EX_MEM_mem_read <= 0;
      EX_MEM_mem_to_reg <= 0;
      EX_MEM_pc_to_reg <= 0;
      EX_MEM_reg_write <= 0;
      EX_MEM_halt_cpu <= 0;

      EX_MEM_alu_out <= 0;
      EX_MEM_dmem_data <= 0;
      EX_MEM_rd <= 0;
      EX_MEM_pc_plus_4 <= 0;
    end
    else begin
      EX_MEM_mem_write <= ID_EX_mem_write;
      EX_MEM_mem_read <= ID_EX_mem_read;
      EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;
      EX_MEM_pc_to_reg <= ID_EX_pc_to_reg;
      EX_MEM_reg_write <= ID_EX_reg_write;
      EX_MEM_halt_cpu <= ID_EX_halt_cpu;

      EX_MEM_alu_out <= alu_result;
      EX_MEM_dmem_data <= forwarded_rs2_data;
      EX_MEM_rd <= ID_EX_rd;
      EX_MEM_pc_plus_4 <= ex_pc_plus_4;
    end
  end

  // ---------- Data Memory ----------
  DataMemory dmem(
    .reset (reset),      // input
    .clk (clk),        // input
    .addr (EX_MEM_alu_out),       // input
    .din (EX_MEM_dmem_data),        // input
    .mem_read (EX_MEM_mem_read),   // input
    .mem_write (EX_MEM_mem_write),  // input
    .dout (mem_dout)        // output
  );

  // Update MEM/WB pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      MEM_WB_mem_to_reg <= 0;
      MEM_WB_pc_to_reg <= 0;
      MEM_WB_reg_write <= 0;
      MEM_WB_halt_cpu <= 0;

      MEM_WB_mem_to_reg_src_1 <= 0;
      MEM_WB_mem_to_reg_src_2 <= 0;
      MEM_WB_rd <= 0;
      MEM_WB_pc_plus_4 <= 0;
    end
    else begin
      MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;
      MEM_WB_pc_to_reg <= EX_MEM_pc_to_reg;
      MEM_WB_reg_write <= EX_MEM_reg_write;
      MEM_WB_halt_cpu <= EX_MEM_halt_cpu;

      MEM_WB_mem_to_reg_src_1 <= EX_MEM_alu_out;
      MEM_WB_mem_to_reg_src_2 <= mem_dout;
      MEM_WB_rd <= EX_MEM_rd;
      MEM_WB_pc_plus_4 <= EX_MEM_pc_plus_4;
    end
  end

  // Mux for mem_to_reg
  Mux2To1 mem_to_reg_mux(
    .din0(MEM_WB_mem_to_reg_src_1),
    .din1(MEM_WB_mem_to_reg_src_2),
    .sel(MEM_WB_mem_to_reg),
    .dout(rd_din_pre)
  );

  // ---------- MUX at rd_din----------
  Mux2To1 mux_rd_din(
    .din0(rd_din_pre),  // input
    .din1(MEM_WB_pc_plus_4),  // input
    .sel(MEM_WB_pc_to_reg),  // input
    .dout(rd_din)  // output
  );

  assign is_halted = MEM_WB_halt_cpu;
  
endmodule
