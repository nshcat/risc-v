// Module that decides which data bus master - the CPU or the debug - gets to control
// the bus. Additionally, it implements the memory map.
module bus_arbiter(
    input ds_cpu_halt,                 // CPU halt debug signal. If it's active, the debug bus controls the bus.

    // CPU master signals
    input [31:0] cpu_address,
    input [31:0] cpu_write_data,
    input [1:0] cpu_reqw,
    input [1:0] cpu_mode,
    input cpu_reqs,
    output [31:0] cpu_read_data,

    
`ifdef FEATURE_DBG_PORT
    // Debug master signals
    input [31:0] dbg_address,
    input [31:0] dbg_write_data,
    input [1:0] dbg_reqw,
    input [1:0] dbg_mode,
    input dbg_reqs,
    output [31:0] dbg_read_data,
`endif


    // Bus connections to slaves
    output [31:0] slv_write_data,
    output [31:0] slv_address,
    output [1:0] slv_reqw,
    output [1:0] slv_mode,
    output slv_reqs,
    
    // Slave peripheral select lines
    output slv_select_pmem,
    output slv_select_dmem,
    output slv_select_leds,
    output slv_select_icu,
    output slv_select_tim1,
    output slv_select_tim2,
    output slv_select_systick,
    output slv_select_gpio,
    

    // Data lines from slave peripherals
    input [31:0] slv_read_data_pmem,
    input [31:0] slv_read_data_dmem,
    input [7:0] slv_read_data_leds,
    input [31:0] slv_read_data_icu,
    input [31:0] slv_read_data_tim1,
    input [31:0] slv_read_data_tim2,
    input [31:0] slv_read_data_systick,
    input [15:0] slv_read_data_gpio
    

`ifdef FEATURE_DBG_PORT
    // The register file is only mapped into the data bus address space if the debug port
    // feature is enabled
    ,
    output slv_select_regs,
    input [31:0] slv_read_data_regs
`endif
);

// ===== Master selection
`ifdef FEATURE_DBG_PORT
    // The debug port has complete control over the data bus when the CPU is halted.
    assign slv_address = ds_cpu_halt ? dbg_address : cpu_address;
    assign slv_write_data = ds_cpu_halt ? dbg_write_data : cpu_write_data;
    assign slv_reqw = ds_cpu_halt ? dbg_reqw : cpu_reqw;
    assign slv_reqs = ds_cpu_halt ? dbg_reqs : cpu_reqs;
    assign slv_mode = ds_cpu_halt ? dbg_mode : cpu_mode;
`else
    // If the debug port is disabled, the CPU is the only bus master. No arbitration needed.
    assign slv_address = cpu_address;
    assign slv_write_data = cpu_write_data;
    assign slv_reqw = cpu_reqw;
    assign slv_reqs = cpu_reqs;
    assign slv_mode = cpu_mode;
`endif

// Just give the read result to both. Doesn't matter if it isnt used.
assign cpu_read_data = read_data;

`ifdef FEATURE_DBG_PORT
    assign dbg_read_data = read_data;
`endif


// ===== Peripheral selection
assign slv_select_pmem = (slv_address < 32'h3000);
assign slv_select_dmem = (slv_address >= 32'h3000) && (slv_address <= 32'h3FFF);
assign slv_select_leds = (slv_address == 32'h40F0);
assign slv_select_icu = (slv_address >= 32'h4000) && (slv_address <= 32'h400C);
assign slv_select_tim1 = (slv_address >= 32'h40A0) && (slv_address <= 32'h40B4);
assign slv_select_tim2 = (slv_address >= 32'h40C0) && (slv_address <= 32'h40D4);
assign slv_select_systick = (slv_address == 32'h4030);
assign slv_select_gpio = (slv_address >= 32'h4034) && (slv_address <= 32'h403C);

`ifdef FEATURE_DBG_PORT
    `ifndef FEATURE_RV32E
        // If RV32E is disabled, the accepted address range is bigger
        assign slv_select_regs = (slv_address >= 32'h4100) && (slv_address <= 32'h417C);
    `else
        assign slv_select_regs = (slv_address >= 32'h4100) && (slv_address <= 32'h413C);
    `endif
`endif

// ===== Bus data muxing
wire [31:0] read_data;  // Data returned from selected peripheral

// Select which slaves gets to provide read result data
assign read_data =  slv_select_pmem ? slv_read_data_pmem :
                    (slv_select_dmem ? slv_read_data_dmem :
                    (slv_select_leds ? { 24'h0, slv_read_data_leds} :
                    (slv_select_tim1 ? slv_read_data_tim1 :
                    (slv_select_tim2 ? slv_read_data_tim2 :
                    (slv_select_systick ? slv_read_data_systick :
                    (slv_select_gpio ? { 16'h0, slv_read_data_gpio } :
                    (slv_select_icu ? slv_read_data_icu :

`ifdef FEATURE_DBG_PORT
                    (slv_select_regs ? slv_read_data_regs :
                    (32'h0)))))))));
`else
                    (32'h0))))))));
`endif

endmodule