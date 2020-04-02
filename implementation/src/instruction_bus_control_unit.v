module instruction_bus_control_unit(
    input clk,
    input reset,

    input [31:0] next_pc,
    output [31:0] instruction,

    // === Instruction bus
    input [31:0] instr_bus_data,
    output [31:0] instr_bus_addr
);

// Whether we are in the first CPU cycle.
reg first_cycle;

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        first_cycle <= 1'b1;    
    end
    else begin
        first_cycle <= 1'b0;
    end
end

// For the first instruction, next_pc is still invalid, so we have to force the address to zero.
// (Or whatever the boot address is)
assign instr_bus_addr = first_cycle ? 32'h0 : next_pc;

// The current instruction is stored in a register in the program memory module, for ease of implementation.
assign instruction = instr_bus_data;

endmodule