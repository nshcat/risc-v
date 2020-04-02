// 6K of FLASH
module flash_contents(
    input clk,
    input ren,
    input [10:0] raddr,
    output reg [31:0] rdata
);

reg [31:0] mem [0:1535];

initial $readmemh("./../memory/flash.txt", mem);

always @(posedge clk) begin
    if(ren)
        rdata <= mem[raddr];
end

endmodule