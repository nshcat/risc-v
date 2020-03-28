module microcontroller(
    input clk,
    input reset,

    output [7:0] leds_out,
    output tim1_cmp, tim2_cmp, tim3_cmp,

    input int_ext1,
    input int_ext2
);

// ==== Data Bus ====
wire [31:0] data_bus_data;
wire [31:0] data_bus_addr;
wire [1:0] data_bus_mode;

// ==== CPU Core ====
wire stall_lw;
datapath core(
    .clk(clk),
    .reset(reset),
    .stall_lw(stall_lw),
    .data_bus_data(data_bus_data),
    .data_bus_addr(data_bus_addr),
    .data_bus_mode(data_bus_mode),
    .irq_sources({tim3_irq, tim2_irq, tim1_irq, int_ext2, int_ext1})
);

// ==== Data Memory ====
data_memory dmem(
    .clk(clk),
    .reset(reset),
    .stall_lw(stall_lw),
    .data_bus_data(data_bus_data),
    .data_bus_addr(data_bus_addr),
    .data_bus_mode(data_bus_mode)
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

wire tim1_irq, tim2_irq, tim3_irq;

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

timer
#(.base_address(32'h40C0))
tim3
(
    .clk(clk),
    .reset(reset),
    .data_bus_data(data_bus_data),
    .data_bus_addr(data_bus_addr),
    .data_bus_mode(data_bus_mode),
    .timer_irq(tim3_irq),
    .comparator_out(tim3_cmp)
);

endmodule
