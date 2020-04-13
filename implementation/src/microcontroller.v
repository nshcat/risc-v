module microcontroller(
    input clk,
    input reset,

    output [7:0] leds_out,
    output tim1_cmp, tim2_cmp,
    inout [15:0] gpio_port_a,

    input int_ext1,
    input int_ext2
);

// ==== Data Bus ====
wire [31:0] cpu_read_data;
wire [31:0] cpu_write_data;
wire [31:0] cpu_address;
wire [1:0] cpu_mode;
wire [1:0] cpu_reqw; // Request width
wire cpu_reqs;       // If read request is signed

wire [31:0] slv_write_data;
wire [31:0] slv_address;
wire [1:0] slv_reqw;
wire [1:0] slv_mode;
wire slv_reqs;

wire slv_select_pmem;
wire slv_select_dmem;
wire slv_select_leds;
wire slv_select_icu;
wire slv_select_tim1;
wire slv_select_tim2;
wire slv_select_systick;
wire slv_select_gpio;

wire [31:0] slv_read_data_pmem;
wire [31:0] slv_read_data_dmem;
wire [7:0] slv_read_data_leds;
wire [31:0] slv_read_data_icu;
wire [31:0] slv_read_data_tim1;
wire [31:0] slv_read_data_tim2;
wire [31:0] slv_read_data_systick;
wire [15:0] slv_read_data_gpio;

wire [31:0] dbg_read_data;

bus_arbiter bus(
    .ds_cpu_halt(1'h0),

    // CPU master
    .cpu_address(cpu_address),
    .cpu_write_data(cpu_write_data),
    .cpu_reqw(cpu_reqw),
    .cpu_reqs(cpu_reqs),
    .cpu_mode(cpu_mode),
    .cpu_read_data(cpu_read_data),

    // Debug bus master
    .dbg_address(32'h0),
    .dbg_write_data(32'h0),
    .dbg_reqw(2'h0),
    .dbg_reqs(1'h0),
    .dbg_mode(2'h0),
    .dbg_read_data(dbg_read_data),

    // Bus slave interface, to be routed to all peripherals
    .slv_address(slv_address),
    .slv_write_data(slv_write_data),
    .slv_mode(slv_mode),
    .slv_reqw(slv_reqw),
    .slv_reqs(slv_reqs),
    
    // Slave select lines
    .slv_select_pmem(slv_select_pmem),
    .slv_select_dmem(slv_select_dmem),
    .slv_select_icu(slv_select_icu),
    .slv_select_leds(slv_select_leds),
    .slv_select_systick(slv_select_systick),
    .slv_select_tim1(slv_select_tim1),
    .slv_select_tim2(slv_select_tim2),
    .slv_select_gpio(slv_select_gpio),

    // Read results from slaves
    .slv_read_data_pmem(slv_read_data_pmem),
    .slv_read_data_dmem(slv_read_data_dmem),
    .slv_read_data_icu(slv_read_data_icu),
    .slv_read_data_leds(slv_read_data_leds),
    .slv_read_data_systick(slv_read_data_systick),
    .slv_read_data_tim1(slv_read_data_tim1),
    .slv_read_data_tim2(slv_read_data_tim2),
    .slv_read_data_gpio(slv_read_data_gpio)
);

// ==== Instruction Bus ====
wire [31:0] instr_bus_data;
wire [31:0] instr_bus_addr;

// ==== CPU Core ====
wire stall_lw;
datapath core(
    .clk(clk),
    .reset(reset),
    .stall_lw(stall_lw),
    .cpu_address(cpu_address),
    .cpu_read_data(cpu_read_data),
    .cpu_write_data(cpu_write_data),
    .cpu_mode(cpu_mode),
    .cpu_reqs(cpu_reqs),
    .cpu_reqw(cpu_reqw),
    .slv_address(slv_address),
    .slv_write_data(slv_write_data),
    .slv_mode(slv_mode),
    .slv_read_data_icu(slv_read_data_icu),
    .slv_select_icu(slv_select_icu),
    .instr_bus_addr(instr_bus_addr),
    .instr_bus_data(instr_bus_data),
    .irq_sources({tim2_irq, tim1_irq, int_ext2, int_ext1})
);

// ==== Data Memory ====
data_memory dmem(
    .clk(clk),
    .reset(reset),
    .stall_lw(stall_lw),
    .data_bus_read(slv_read_data_dmem),
    .data_bus_write(slv_write_data),
    .data_bus_select(slv_select_dmem),
    .data_bus_addr(slv_address),
    .data_bus_mode(slv_mode),
    .data_bus_reqw(slv_reqw),
    .data_bus_reqs(slv_reqs)
);

// ==== Program Memory ====
program_memory pmem(
    .clk(clk),
    .reset(reset),
    .stall_lw(stall_lw),
    .instr_bus_data(instr_bus_data),
    .instr_bus_address(instr_bus_addr),
    .data_bus_data(slv_read_data_pmem),
    .data_bus_select(slv_select_pmem),
    .data_bus_addr(slv_address),
    .data_bus_mode(slv_mode),
    .data_bus_reqw(slv_reqw),
    .data_bus_reqs(slv_reqs)
);

// ==== Peripherals ====
leds led(
    .clk(clk),
    .reset(reset),
    .data_bus_read(slv_read_data_leds),
    .data_bus_write(slv_write_data[7:0]),
    .data_bus_select(slv_select_leds),
    .data_bus_addr(slv_address),
    .data_bus_mode(slv_mode),
    .leds_out(leds_out)
);

gpio_port gpio_a(
    .clk(clk),
    .reset(reset),
    .data_bus_read(slv_read_data_gpio),
    .data_bus_write(slv_write_data[15:0]),
    .data_bus_select(slv_select_gpio),
    .data_bus_addr(slv_address),
    .data_bus_mode(slv_mode),
    .gpio_pins(gpio_port_a)
);

systick stick(
    .clk(clk),
    .reset(reset),
    .data_bus_read(slv_read_data_systick),
    .data_bus_select(slv_select_systick),
    .data_bus_addr(slv_address),
    .data_bus_mode(slv_mode)
);

wire tim1_irq, tim2_irq;

timer
#(.base_address(32'h40A0))
tim1
(
    .clk(clk),
    .reset(reset),
    .data_bus_read(slv_read_data_tim1),
    .data_bus_write(slv_write_data),
    .data_bus_select(slv_select_tim1),
    .data_bus_addr(slv_address),
    .data_bus_mode(slv_mode),
    .timer_irq(tim1_irq),
    .comparator_out(tim1_cmp)
);

timer
#(.base_address(32'h40C0))
tim2
(
    .clk(clk),
    .reset(reset),
    .data_bus_read(slv_read_data_tim2),
    .data_bus_write(slv_write_data),
    .data_bus_select(slv_select_tim2),
    .data_bus_addr(slv_address),
    .data_bus_mode(slv_mode),
    .timer_irq(tim2_irq),
    .comparator_out(tim2_cmp)
);

endmodule
