`include "CLOG2.v"

`define IDLE 2'b00
`define READ_WAIT 2'b01
`define WRITE_WAIT 2'b10

module Cache #(parameter LINE_SIZE = 16,
               parameter NUM_SETS = 16,
               parameter NUM_WAYS = 1,
               parameter BLOCK_SHIFT = `CLOG2(LINE_SIZE)) (
    input reset,
    input clk,

    input [31:0] addr,
    input mem_read,
    input mem_write,
    input [31:0] din,

    output is_ready,
    output is_output_valid,
    output [31:0] dout,
    output is_hit);
  integer i; // only used for reset process
  integer cache_total; // only used for cache statistics
  integer cache_miss; // only used for cache statistics

  // Wire declarations
  wire is_data_mem_ready;
  wire is_data_output_valid;
  wire [23:0] tag_from_addr;
  wire [3:0] index_from_addr;
  wire [1:0] block_offset_from_addr;
  wire [LINE_SIZE * 8 - 1:0] data_dout;
  // Reg declarations
  // You might need registers to keep the status.
  reg [23:0] tag_bank[0:NUM_SETS-1];
  reg [LINE_SIZE * 8 - 1:0] data_bank[0:NUM_SETS-1];
  reg valid[0:NUM_SETS-1];
  reg dirty[0:NUM_SETS-1];
  reg [1:0] state;
  reg dm_is_input_valid;
  reg dm_mem_read;
  reg dm_mem_write;
  reg [31:0] dm_addr;
  reg [LINE_SIZE * 8 -1:0] dm_din;

  assign is_ready = is_data_mem_ready;
  assign is_output_valid = state == `IDLE;

  // addr[31:8] => tag from address
  assign tag_from_addr = addr[31:8];
  // addr[7:4] => index from address
  assign index_from_addr = addr[7:4];
  // addr[3:2] => block offset from address
  assign block_offset_from_addr = addr[3:2];

  // Instantiate data memory
  DataMemory #(.BLOCK_SIZE(LINE_SIZE)) data_mem(
    .reset(reset),
    .clk(clk),

    .is_input_valid(dm_is_input_valid),
    .addr(dm_addr),        // NOTE: address must be shifted by CLOG2(LINE_SIZE)
    .mem_read(dm_mem_read),
    .mem_write(dm_mem_write),
    .din(dm_din),

    // is output from the data memory valid?
    .is_output_valid(is_data_output_valid),
    .dout(data_dout),
    // is data memory ready to accept request?
    .mem_ready(is_data_mem_ready)
  );

  assign is_hit = (mem_read || mem_write) ? ((tag_from_addr == tag_bank[index_from_addr]) && valid[index_from_addr]) : 1;
  Mux4To1 dout_mux(
    .din0(data_bank[index_from_addr][31:0]),
    .din1(data_bank[index_from_addr][63:32]),
    .din2(data_bank[index_from_addr][95:64]),
    .din3(data_bank[index_from_addr][127:96]),
    .sel(block_offset_from_addr),
    .dout(dout)
  );

  always @(*) begin
    dm_is_input_valid = 0;
    dm_mem_read = 0;
    dm_mem_write = 0;
    dm_addr = 0;
    dm_din = 0;
    if (state == `IDLE) begin
      if (is_hit == 0 && (mem_read || mem_write) && is_data_mem_ready == 1) begin
        if (valid[index_from_addr] == 1 && dirty[index_from_addr] == 1) begin
          dm_is_input_valid = 1;
          dm_mem_read = 0;
          dm_mem_write = 1;
          dm_addr = {tag_bank[index_from_addr], index_from_addr, 4'b0000} >> BLOCK_SHIFT;
          dm_din = data_bank[index_from_addr];
        end else begin
          dm_is_input_valid = 1;
          dm_mem_read = 1;
          dm_mem_write = 0;
          dm_addr = addr >> BLOCK_SHIFT;
          dm_din = 0;
        end
      end
    end else if (state == `READ_WAIT) begin
      dm_is_input_valid = 0;
      dm_mem_read = 0;
      dm_mem_write = 0;
      dm_addr = 0;
      dm_din = 0;
    end else if (state == `WRITE_WAIT) begin
      dm_is_input_valid = 0;
      dm_mem_read = 0;
      dm_mem_write = 0;
      dm_addr = 0;
      dm_din = 0;
      if (is_data_mem_ready == 1) begin
        dm_is_input_valid = 1;
        dm_mem_read = 1;
        dm_mem_write = 0;
        dm_addr = addr >> BLOCK_SHIFT;
        dm_din = 0;
      end
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      for (i = 0; i < NUM_SETS; i = i + 1) begin
        tag_bank[i] <= 0;
        data_bank[i] <= 0;
        valid[i] <= 0;
        dirty[i] <= 0;
      end
      state <= `IDLE;
      cache_total <= 0;
      cache_miss <= 0;
    end
    else if (state == `IDLE) begin
      if ((mem_read || mem_write) && is_hit) begin
        cache_total <= cache_total + 1;
      end
      if (dm_is_input_valid == 1 && dm_mem_read == 1) begin
        cache_miss <= cache_miss + 1;
        state <= `READ_WAIT;
      end else if (dm_is_input_valid == 1 && dm_mem_write == 1) begin
        cache_miss <= cache_miss + 1;
        state <= `WRITE_WAIT;
      end else if (mem_write == 1 && is_hit == 1) begin
        if (block_offset_from_addr == 2'b00) begin
          data_bank[index_from_addr][31:0] <= din;
        end else if (block_offset_from_addr == 2'b01) begin
          data_bank[index_from_addr][63:32] <= din;
        end else if (block_offset_from_addr == 2'b10) begin
          data_bank[index_from_addr][95:64] <= din;
        end else if (block_offset_from_addr == 2'b11) begin
          data_bank[index_from_addr][127:96] <= din;
        end
        dirty[index_from_addr] <= 1;
      end
    end else if (state == `READ_WAIT) begin
      if (is_data_output_valid == 1) begin
        tag_bank[index_from_addr] <= tag_from_addr;
        data_bank[index_from_addr] <= data_dout;
        valid[index_from_addr] <= 1;
        dirty[index_from_addr] <= 0;
        state <= `IDLE;
      end
    end else if (state == `WRITE_WAIT) begin
      if (is_data_mem_ready == 1) begin
        tag_bank[index_from_addr] <= 0;
        data_bank[index_from_addr] <= 0;
        valid[index_from_addr] <= 0;
        dirty[index_from_addr] <= 0;
        state <= `READ_WAIT;
      end
    end
  end
endmodule
