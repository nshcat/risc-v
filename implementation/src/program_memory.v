module program_memory(
    input clk,
    input reset,

    // === Instruction bus
    input [31:0] instr_bus_address,
    output [31:0] instr_bus_data,

    // === Data bus
    output [31:0] data_bus_data,
    input [31:0] data_bus_addr,
    input [1:0] data_bus_mode,
    input [1:0] data_bus_reqw,
    input data_bus_reqs,
    input data_bus_select,

    input stall_lw  // Whether we currently are in the first stalling cycle of a memory load operation.
);

// === Constants
parameter WORD = 2'b00;
parameter HALF_WORD = 2'b01;
parameter BYTE = 2'b10;

parameter SIGNED = 1'b1;
parameter UNSIGNED = 1'b0;

// === State Machine
parameter STATE_INSTR = 1'b0;   // Flash isn't used by the data bus
parameter STATE_DATA = 1'b1;    // Flash is used by the data bus. Instruction bus needs to use backup value.

// Current state. This statemachine determines whether the program flash is currently used by
// the data bus (as part of a load instruction). If this is the case, the instruction bus can't read
// directly from it, but has to use the previously read value, which is okay since we are always
// stalling in a load instruction, and thus the pc is the same anyways.
reg state;

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        state <= STATE_INSTR;
    end
    else begin
        // If we are in the stalled cycle of a load operation, the next clock edge
        // will cause the memory read register to be filled with the result meant for
        // the data bus.
        if(state == STATE_INSTR && stall_lw) begin
            state <= STATE_DATA;
        end
        else if(state == STATE_DATA) begin
            state <= STATE_INSTR;
        end
    end
end
// ===

// === Memory implementation
// Select which address to use. If we are in the first cycle of a load instruction the data bus
// wants to perform a read at the next rising edge, otherwise the instruction bus reads.
wire [11:0] word_address = (stall_lw) ? data_bus_word_addr : instr_bus_word_addr;

reg [31:0] memory [0:3071];

`ifdef YOSYS_HX8K
    // For the HX8K we support replacing the flash contents after synthesis, which requires the flash
    // to be initially filled with special marker content.
    initial $readmemh("./../memory/marker.txt", memory);
`else
    initial $readmemh("./../memory/flash.txt", memory);
`endif

reg [31:0] memory_read;
reg [31:0] prev_read;

always @(posedge clk) begin
        prev_read <= memory_read;
        memory_read <= memory[word_address];
end
// ===

// === Instruction bus handling
// Word-based address from the instruction bus
wire [11:0] instr_bus_word_addr = instr_bus_address[13:2];

// Stored instruction. If the data bus is currently accessing the flash, we need to fall back
// to the stored previous instruction. This works since load instructions cause the CPU to stall
// for one cycle, so the read instruction would be the same anyways.
wire [31:0] instruction = (state == STATE_DATA) ? prev_read : memory_read;

// The instructions are stored in little endian, so we have to reverse the byte order.
assign instr_bus_data = {{instruction[07:00]}, {instruction[15:08]}, {instruction[23:16]}, {instruction[31:24]}};


// === Data bus handling
// Register storing current data bus read results. This is always the full word. If only a part of it was requested, that will
// be done later when assigning to the tri-state bus.
// We use positive clock edges with stall_lw asserted to do this loading, since no instruction fetch
// will happen at those.
wire [31:0] data_bus_read = memory_read;
// Data bus address, word-based
wire [11:0] data_bus_word_addr = data_bus_addr[13:2];
// Address of accessed byte in flash word
wire [1:0] data_bus_byte_addr = data_bus_addr[1:0];

// Whether a read from the program flash was requested by the data bus controller.
wire read_requested = (data_bus_mode == 2'b01) && (data_bus_select);

// Handle reads with sub-word width
assign data_bus_data = read_requested ? flash_read() : 32'h0;

function [31:0] flash_read();
    case (data_bus_reqw)
        WORD: begin // Simple case: Whole word was read
            flash_read = {data_bus_read[7:0], data_bus_read[15:8], data_bus_read[23:16], data_bus_read[31:24]};
        end
        BYTE: begin // Accessing a single byte
            case (data_bus_byte_addr) // Which byte do we need to load?
                2'b00: begin // The contents of data_bus_read are flipped, since the word was stored in little endian.
                             // Since byte address 0 is the LSB, we thus have to load the MSB here.
                    flash_read = { (data_bus_reqs == SIGNED && data_bus_read[31]) ? 24'hFFFFFF : 24'h0, data_bus_read[31:24] };
                end
                2'b01: begin
                    flash_read = { (data_bus_reqs == SIGNED && data_bus_read[23]) ? 24'hFFFFFF : 24'h0, data_bus_read[23:16] };
                end
                2'b10: begin
                    flash_read = { (data_bus_reqs == SIGNED && data_bus_read[15]) ? 24'hFFFFFF : 24'h0, data_bus_read[15:8] };
                end
                2'b11: begin
                    flash_read = { (data_bus_reqs == SIGNED && data_bus_read[7]) ? 24'hFFFFFF : 24'h0, data_bus_read[7:0] };
                end
            endcase
        end
        /* HALF_WORD: */ default: begin // Accessing a half word
            case (data_bus_byte_addr) // Which half-word are we accesing?
                2'b00: begin // Half-word made up from the LSB and next byte
                    flash_read = { (data_bus_reqs == SIGNED && data_bus_read[23]) ? 16'hFFFF : 16'h0, data_bus_read[23:16], data_bus_read[31:24] };
                end
                2'b01: begin
                    flash_read = { (data_bus_reqs == SIGNED && data_bus_read[15]) ? 16'hFFFF : 16'h0, data_bus_read[15:8], data_bus_read[23:16] };
                end
                2'b10: begin
                    flash_read = { (data_bus_reqs == SIGNED && data_bus_read[7]) ? 16'hFFFF : 16'h0, data_bus_read[7:0], data_bus_read[15:8] };
                end
                2'b11: begin // Access would cross word boundary. Just return zero for now.
                    flash_read = 32'h0;
                end
            endcase
        end
    endcase
endfunction

endmodule