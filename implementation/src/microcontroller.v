module microcontroller(
    input clk,
    input reset,

    output [7:0] leds_out,

    input int_ext1,
    input int_ext2    
);

// ==== Data Bus ====
wire [31:0] data_bus_data;
wire [31:0] data_bus_addr;
wire [1:0] data_bus_mode;

// ==== CPU Core ====
datapath core(
    .clk(clk),
    .reset(reset),
    .data_bus_data(data_bus_data),
    .data_bus_addr(data_bus_addr),
    .data_bus_mode(data_bus_mode),
    .irq_sources({3'b111, int_ext2, int_ext1})
);

// ==== Data Memory ====
data_memory dmem(
    .clk(clk),
    .reset(reset),
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

endmodule