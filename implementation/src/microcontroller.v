module microcontroller(
    input clk,
    input reset,

    output [7:0] leds_out,
    output tim1_cmp, tim2_cmp,
    inout [15:0] gpio_port_a

`ifdef FEATURE_DBG_PORT
    , // This is ugly, but has to be done

    // Debug port UART
    input uart_rx,
    output uart_tx
`endif

);

// ==== Debug Port ====

`ifdef FEATURE_DBG_PORT
    wire [31:0] dbg_address;
    wire [31:0] dbg_write_data;
    wire [1:0] dbg_reqw;
    wire [1:0] dbg_mode;
    wire dbg_reqs;
    wire [31:0] dbg_read_data;
    wire dbg_stall_lw;

    wire ds_cpu_reset;
    wire ds_cpu_halt;   

    debug_port dbg(
        .clk(clk),
        .reset(reset),
        .ds_cpu_halt(ds_cpu_halt),
        .ds_cpu_reset(ds_cpu_reset),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .dbg_address(dbg_address),
        .dbg_write_data(dbg_write_data),
        .dbg_read_data(dbg_read_data),
        .dbg_reqw(dbg_reqw),
        .dbg_reqs(dbg_reqs),
        .dbg_mode(dbg_mode),
        .dbg_stall_lw(dbg_stall_lw),
        .dbg_pc(dbg_pc)
    );
`else
    // Debug signals are disabled if the debug port feature is disabled
    wire ds_cpu_reset = 1'b1;
    wire ds_cpu_halt = 1'b0;
    wire dbg_stall_lw = 1'b0;
`endif

// The final reset signal is a combination of the PLL reset and the debug port reset
wire cpu_reset = ds_cpu_reset & reset;

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
wire slv_select_eic;

wire [31:0] slv_read_data_pmem;
wire [31:0] slv_read_data_dmem;
wire [7:0] slv_read_data_leds;
wire [31:0] slv_read_data_icu;
wire [31:0] slv_read_data_tim1;
wire [31:0] slv_read_data_tim2;
wire [31:0] slv_read_data_systick;
wire [15:0] slv_read_data_gpio;
wire [15:0] slv_read_data_eic;

`ifdef FEATURE_DBG_PORT
    // The register file is only mapped into the data bus address space if the
    // debug port feature is enabled
    wire slv_select_regs;
    wire [31:0] slv_read_data_regs;
`endif

bus_arbiter bus(
    .ds_cpu_halt(ds_cpu_halt),

    // CPU master
    .cpu_address(cpu_address),
    .cpu_write_data(cpu_write_data),
    .cpu_reqw(cpu_reqw),
    .cpu_reqs(cpu_reqs),
    .cpu_mode(cpu_mode),
    .cpu_read_data(cpu_read_data),

`ifdef FEATURE_DBG_PORT
    // Debug bus master
    .dbg_address(dbg_address),
    .dbg_write_data(dbg_write_data),
    .dbg_read_data(dbg_read_data),
    .dbg_reqw(dbg_reqw),
    .dbg_reqs(dbg_reqs),
    .dbg_mode(dbg_mode),
`endif
    
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
    .slv_select_eic(slv_select_eic),

    // Read results from slaves
    .slv_read_data_pmem(slv_read_data_pmem),
    .slv_read_data_dmem(slv_read_data_dmem),
    .slv_read_data_icu(slv_read_data_icu),
    .slv_read_data_leds(slv_read_data_leds),
    .slv_read_data_systick(slv_read_data_systick),
    .slv_read_data_tim1(slv_read_data_tim1),
    .slv_read_data_tim2(slv_read_data_tim2),
    .slv_read_data_gpio(slv_read_data_gpio),
    .slv_read_data_eic(slv_read_data_eic)

`ifdef FEATURE_DBG_PORT
    ,
    .slv_select_regs(slv_select_regs),
    .slv_read_data_regs(slv_read_data_regs)
`endif

);

// ==== Instruction Bus ====
wire [31:0] instr_bus_data;
wire [31:0] instr_bus_addr;

// ==== CPU Core ====
wire stall_lw;
wire [31:0] dbg_pc;
datapath core(
    .clk(clk),
    .reset(cpu_reset),
    .stall_lw(stall_lw),
    .ds_cpu_halt(ds_cpu_halt),
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
    .irq_sources({eic_irq, tim2_irq, tim1_irq}),
    .dbg_pc(dbg_pc)

`ifdef FEATURE_DBG_PORT
    ,
    .slv_select_regs(slv_select_regs),
    .slv_read_data_regs(slv_read_data_regs)
`endif
);

// ==== Data Memory ====
data_memory dmem(
    .clk(clk),
    .reset(cpu_reset),
    .stall_lw(stall_lw | dbg_stall_lw),
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
    .reset(cpu_reset),
    .stall_lw(stall_lw | dbg_stall_lw),
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
    .reset(cpu_reset),
    .data_bus_read(slv_read_data_leds),
    .data_bus_write(slv_write_data[7:0]),
    .data_bus_select(slv_select_leds),
    .data_bus_addr(slv_address),
    .data_bus_mode(slv_mode),
    .leds_out(leds_out)
);

gpio_port gpio_a(
    .clk(clk),
    .reset(cpu_reset),
    .data_bus_read(slv_read_data_gpio),
    .data_bus_write(slv_write_data[15:0]),
    .data_bus_select(slv_select_gpio),
    .data_bus_addr(slv_address),
    .data_bus_mode(slv_mode),
    .gpio_pins(gpio_port_a),
    .gpio_pin_state(gpio_pin_state)
);

wire [15:0] gpio_pin_state;
wire eic_irq;

extended_interrupt_controller eic(
    .clk(clk),
    .reset(reset),
    .eic_irq(eic_irq),
    .gpio_pin_state(gpio_pin_state),
    .data_bus_read(slv_read_data_eic),
    .data_bus_write(slv_write_data[15:0]),
    .data_bus_select(slv_select_eic),
    .data_bus_addr(slv_address),
    .data_bus_mode(slv_mode)
);

systick stick(
    .clk(clk),
    .reset(cpu_reset),
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
    .reset(cpu_reset),
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
    .reset(cpu_reset),
    .data_bus_read(slv_read_data_tim2),
    .data_bus_write(slv_write_data),
    .data_bus_select(slv_select_tim2),
    .data_bus_addr(slv_address),
    .data_bus_mode(slv_mode),
    .timer_irq(tim2_irq),
    .comparator_out(tim2_cmp)
);

endmodule
