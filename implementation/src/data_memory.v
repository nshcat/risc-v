module data_memory(
    input clk,
    input reset,

    input stall_lw,

    input [31:0] data_bus_write,
    output [31:0] data_bus_read,
    input [31:0] data_bus_addr,
    input [1:0] data_bus_mode,
    input [1:0] data_bus_reqw,
    input data_bus_select,
    input data_bus_reqs
);

// Instantiate all memory slices
parameter SRAM_BASE_ADDR = 32'h3000;
parameter SLICE_WIDTH = 32'h800;

genvar i;
for(i = 0; i < 2; i++) begin : slices
    /* verilator lint_off UNUSED */
    // Byte-based address relative to the beginning of this slice.
    // This is always being calculated, but only used if this slice is actually selected.
    wire [31:0] local_addr_big = data_bus_addr - (SRAM_BASE_ADDR + i*SLICE_WIDTH);
    wire [10:0] local_addr = local_addr_big[10:0];
    /* verilator lint_on UNUSED*/

    // Base address of this slice, in global address space
    wire [31:0] base_addr = (SRAM_BASE_ADDR + i*SLICE_WIDTH);
    // One-past-the-end address of this slice, in global address space
    wire [31:0] end_addr = (SRAM_BASE_ADDR + i*SLICE_WIDTH) + SLICE_WIDTH;

    // Whether the current access is to this slice.
    wire in_this_slice = (data_bus_addr >= base_addr) && (data_bus_addr < end_addr);

    wire [31:0] read_data;

    memory_slice inst(
        .clk(clk),
        .stall_lw(stall_lw),
        .wen(in_this_slice & write_requested),
        .ren(in_this_slice & read_requested),
        .width_mode(data_bus_reqw),
        .signed_mode(data_bus_reqs),
        .addr(local_addr),
        .wdata(data_bus_write),
        .rdata(read_data)
    );
end

// Whether the address is in range and bus mode is read/write.
wire read_requested = data_bus_select && (data_bus_mode == 2'b01);
wire write_requested = data_bus_select && (data_bus_mode == 2'b10);

// Since only one of the read result wires will carry anything other than 0, we can just OR them together
// here to retrieve the value read from memory.
assign data_bus_read = /*read_requested ? */(slices[0].read_data | slices[1].read_data) /*: 32'h0*/;


endmodule
