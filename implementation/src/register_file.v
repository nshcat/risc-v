module register_file(
    input clk,
    input reset,
    input [4:0] read_reg_1,
    input [4:0] read_reg_2,
    input [4:0] write_reg,
    input [31:0] write_data,
    input cs_reg_write,

    output [31:0] read_data_1,
    output [31:0] read_data_2
);

// 32 registers. Note that $0 is hard-wired to always be 0.
reg [31:0] regs [31:0];

// Write back
always @(posedge clk or negedge reset) begin
    if(reset) begin
        if(cs_reg_write)
            regs[write_reg] <= write_data;
    end
    else begin
        regs[0] <= 32'b0;
        regs[1] <= 32'b0;
        regs[2] <= 32'b0;
        regs[3] <= 32'b0;
        regs[4] <= 32'b0;
        regs[5] <= 32'b0;
        regs[6] <= 32'b0;
        regs[7] <= 32'b0;
        regs[8] <= 32'b0;
        regs[9] <= 32'b0;
        regs[10] <= 32'b0;
        regs[11] <= 32'b0;
        regs[12] <= 32'b0;
        regs[13] <= 32'b0;
        regs[14] <= 32'b0;
        regs[15] <= 32'b0;
        regs[16] <= 32'b0;
        regs[17] <= 32'b0;
        regs[18] <= 32'b0;
        regs[19] <= 32'b0;
        regs[20] <= 32'b0;
        regs[21] <= 32'b0;
        regs[22] <= 32'b0;
        regs[23] <= 32'b0;
        regs[24] <= 32'b0;
        regs[25] <= 32'b0;
        regs[26] <= 32'b0;
        regs[27] <= 32'b0;
        regs[28] <= 32'b0;
        regs[29] <= 32'b0;
        regs[30] <= 32'b0;
        regs[31] <= 32'b0;
    end
end


assign read_data_1 = (read_reg_1 == 5'b0) ? 32'b0 : regs[read_reg_1];
assign read_data_2 = (read_reg_2 == 5'b0) ? 32'b0 : regs[read_reg_2];


endmodule