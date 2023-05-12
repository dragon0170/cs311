module BranchPredictor(input reset,
                       input clk,
                       input [31:0] current_pc,
                       input [4:0] write_index,
                       input bht_data,
                       input [24:0] tag_data,
                       input [31:0] btb_data,
                       input bht_write_enable,
                       input tag_and_btb_write_enable,
                       output [31:0] next_pc);
  integer i;

  wire [31:0] pc_plus_4;
  wire [57:0] current_entry;

  reg [57:0] entry[0:31];

  assign current_entry = entry[current_pc[6:2]];

  Adder pc_plus_4_adder(
    .in1(current_pc),
    .in2(32'd4),
    .dout(pc_plus_4)
  );

  Mux2To1 predicted_next_pc_mux(
    .din0(pc_plus_4),
    .din1(current_entry[31:0]),
    .sel((current_entry[57:33] == current_pc[31:7]) && (current_entry[32] == 1)),
    .dout(next_pc)
  );

  always @(posedge clk) begin
    if (reset) begin
      for (i = 0; i < 32; i = i + 1)
        entry[i] <= 58'b0;
    end

    if (bht_write_enable) begin
      if (entry[write_index][57:33] == tag_data || tag_and_btb_write_enable) begin
        entry[write_index][32] <= bht_data;
      end
    end
    if (tag_and_btb_write_enable) begin
      entry[write_index][57:33] <= tag_data;
      entry[write_index][31:0] <= btb_data;
    end
  end
  
endmodule