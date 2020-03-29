module memory_block (
        input clk, wen, ren, 
        input [8:0] addr,
        input [7:0] wdata,
        output reg [7:0] rdata
);
	reg [7:0] mem [0:511];
	
	wire [7:0] contents = mem[0];
	
	always @(posedge clk) begin
		if (wen)
			mem[addr] <= wdata;
		if (ren)
			rdata <= mem[addr];
	end
endmodule
