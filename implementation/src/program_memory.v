module program_memory(
    input clk,
    input reset,

    // === Instruction bus
    input [31:0] instr_bus_address,
    output [31:0] instr_bus_data,

    // === Data bus
    inout [31:0] data_bus_data,
    input [31:0] data_bus_addr,
    input [1:0] data_bus_mode,
    input [1:0] data_bus_reqw,
    input data_bus_reqs,

    input stall_lw  // Whether we currently are in the first stalling cycle of a memory load operation.
);

// === Constants
parameter WORD = 2'b00;
parameter HALF_WORD = 2'b01;
parameter BYTE = 2'b10;

parameter SIGNED = 1'b1;
parameter UNSIGNED = 1'b0;

// === Memory implementation
wire [31:0] pm_dbus_read;

flash_contents dbus(
    .clk(clk),
    .raddr(data_bus_word_addr),
    .rdata(pm_dbus_read),
    .ren(stall_lw & read_requested)
);

wire [31:0] pm_ibus_read;

flash_contents ibus(
    .clk(clk),
    .raddr(instr_bus_word_addr),
    .rdata(pm_ibus_read),
    .ren(~stall_lw)
);


// === Instruction bus handling
// Word-based address from the instruction bus
wire [10:0] instr_bus_word_addr = instr_bus_address[12:2];

// Stored instruction
wire [31:0] instruction = pm_ibus_read;

// The instructions are stored in little endian, so we have to reverse the byte order.
assign instr_bus_data = {{instruction[07:00]}, {instruction[15:08]}, {instruction[23:16]}, {instruction[31:24]}};

/*always @(posedge clk or negedge reset) begin
    if(!reset) begin
        // The CPU is required to do nothing for the first cycle to allow for the first instruction to load.
        // A completely empty instruction register will be treated as a NOP and thus do nothing.
        instruction <= 32'h0;
    end
    else if(~stall_lw) begin // We use the write-back cycle to load the the new instruction from program memory
        instruction <= memory_instr_bus[instr_bus_word_addr];
    end
end*/

// === Data bus handling
// Register storing current data bus read results. This is always the full word. If only a part of it was requested, that will
// be done later when assigning to the tri-state bus.
// We use positive clock edges with stall_lw asserted to do this loading, since no instruction fetch
// will happen at those.
wire [31:0] data_bus_read = pm_dbus_read;
// Data bus address, word-based
wire [10:0] data_bus_word_addr = data_bus_addr[12:2];
// Address of accessed byte in flash word
wire [1:0] data_bus_byte_addr = data_bus_addr[1:0];

// Whether a read from the program flash was requested by the data bus controller.
wire read_requested = (data_bus_mode == 2'b01) && (data_bus_addr < 32'h2000);

/*always @(posedge clk or negedge reset) begin
    if(!reset) begin
        data_bus_read <= 32'h0;
    end
    else if(stall_lw & read_requested) begin
        data_bus_read <= memory_data_bus[data_bus_word_addr];
    end
end*/

// Handle reads with sub-word width
assign data_bus_data = read_requested ? flash_read() : 32'bz;

function [31:0] flash_read();
    case (data_bus_mode)
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