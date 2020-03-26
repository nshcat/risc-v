module program_memory(
    input [31:0] address,
    output [31:0] instruction
);

reg [31:0] memory [127:0];
wire [6:0] internal_address = address[8:2];

initial begin
    $readmemh("./../memory/flash.bin", memory);
end

wire [31:0] instruction_raw = memory[internal_address];

// Memory is organized in little endian, we have to swap to big endian here since
// that's how the instruction is stored in the registers.
assign instruction = {{instruction_raw[07:00]},
                      {instruction_raw[15:08]},
                      {instruction_raw[23:16]},
                      {instruction_raw[31:24]}};

endmodule