module microcontroller(
    input clk,
    input reset,

    output [7:0] leds_out,
    output tim1_cmp, tim2_cmp,

    input int_ext1,
    input int_ext2
);

// ==== Data Bus ====
wire [31:0] data_bus_data;
wire [31:0] data_bus_addr;
wire [1:0] data_bus_mode;
wire [1:0] data_bus_reqw; // Request width
wire data_bus_reqs;       // If read request is signed

// ==== Instruction Bus ====
wire [31:0] instr_bus_data;
wire [31:0] instr_bus_addr;

// ==== CPU Core ====
wire stall_lw;
datapath core(
    .clk(clk),
    .reset(reset),
    .stall_lw(stall_lw),
    .data_bus_data(data_bus_data),
    .data_bus_addr(data_bus_addr),
    .data_bus_mode(data_bus_mode),
    .data_bus_reqw(data_bus_reqw),
    .data_bus_reqs(data_bus_reqs),
    .instr_bus_addr(instr_bus_addr),
    .instr_bus_data(instr_bus_data),
    .irq_sources({tim3_irq, tim2_irq, tim1_irq, int_ext2, int_ext1})
);

// ==== Data Memory ====
data_memory dmem(
    .clk(clk),
    .reset(reset),
    .stall_lw(stall_lw),
    .data_bus_data(data_bus_data),
    .data_bus_addr(data_bus_addr),
    .data_bus_mode(data_bus_mode),
    .data_bus_reqw(data_bus_reqw),
    .data_bus_reqs(data_bus_reqs)
);

// ==== Program Memory ====
program_memory pmem(
    .clk(clk),
    .reset(reset),
    .stall_lw(stall_lw),
    .instr_bus_data(instr_bus_data),
    .instr_bus_address(instr_bus_addr),
    .data_bus_data(data_bus_data),
    .data_bus_addr(data_bus_addr),
    .data_bus_mode(data_bus_mode),
    .data_bus_reqw(data_bus_reqw),
    .data_bus_reqs(data_bus_reqs)
);

// ==== Peripherals ====
leds led(
    .clk(clk),
    .reset(reset),
    .data_bus_data(data_bus_data),
    .data_bus_addr(data_bus_addr),
    .data_bus_mode(data_bus_mode),
    .leds_out(leds_out)
);

systick stick(
    .clk(clk),
    .reset(reset),
    .data_bus_data(data_bus_data),
    .data_bus_addr(data_bus_addr),
    .data_bus_mode(data_bus_mode)
);

wire tim1_irq, tim2_irq;

reg tim3_irq = 1'b1;

timer
#(.base_address(32'h40A0))
tim1
(
    .clk(clk),
    .reset(reset),
    .data_bus_data(data_bus_data),
    .data_bus_addr(data_bus_addr),
    .data_bus_mode(data_bus_mode),
    .timer_irq(tim1_irq),
    .comparator_out(tim1_cmp)
);

timer
#(.base_address(32'h40B0))
tim2
(
    .clk(clk),
    .reset(reset),
    .data_bus_data(data_bus_data),
    .data_bus_addr(data_bus_addr),
    .data_bus_mode(data_bus_mode),
    .timer_irq(tim2_irq),
    .comparator_out(tim2_cmp)
);

endmodule
