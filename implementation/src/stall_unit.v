module stall_unit(
    input clk,
    input reset,
    input cs_stall_lw,
    output stall
);

reg stall1;
wire stallL = cs_stall_lw & ~stall1;
assign stall = stallL;

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        stall1 <= 1'b0;
    end
    else begin
        stall1 <= stallL;
    end
end

endmodule