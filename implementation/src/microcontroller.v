module microcontroller(
    input clk,
    input reset
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
    .data_bus_mode(data_bus_mode)
);

// ==== Data Memory ====
data_memory dmem(
    .clk(clk),
    .reset(reset),
    .data_bus_data(data_bus_data),
    .data_bus_addr(data_bus_addr),
    .data_bus_mode(data_bus_mode)
);

endmodule