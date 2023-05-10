module ForwardingUnit(input reg_write_mem,
                      input reg_write_wb,
                      input [4:0] rs1_ex,
                      input [4:0] rs2_ex,
                      input [4:0] rd_mem,
                      input [4:0] rd_wb,
                      output reg [1:0] forward_a,
                      output reg [1:0] forward_b);
    always @(*) begin
        if (rs1_ex != 0 && rs1_ex == rd_mem && reg_write_mem) begin
            forward_a = 1;
        end else if (rs1_ex != 0 && rs1_ex == rd_wb && reg_write_wb) begin
            forward_a = 2;
        end else begin
            forward_a = 0;
        end

        if (rs2_ex != 0 && rs2_ex == rd_mem && reg_write_mem) begin
            forward_b = 1;
        end else if (rs2_ex != 0 && rs2_ex == rd_wb && reg_write_wb) begin
            forward_b = 2;
        end else begin
            forward_b = 0;
        end
    end
endmodule
