// DESCRIPTION: Verilator: Verilog example module
//
// This file ONLY is placed into the Public Domain, for any use,
// without warranty, 2017 by Wilson Snyder.
//======================================================================

// Include common routines
#include <verilated.h>

// Include model header, generated from Verilating "top.v"
#include "Vtestbench.h"

// If "verilator --trace" is used, include the tracing class
#if VM_TRACE
# include <verilated_vcd_c.h>
#endif

// Current simulation time (64-bit unsigned)
vluint64_t main_time = 0;
// Called by $time in Verilog
double sc_time_stamp() {
    return main_time;  // Note does conversion to real, to match SystemC
}

int main(int argc, char** argv, char** env) {
    // This is a more complicated example, please also see the simpler examples/make_hello_c.

    // Prevent unused variable warnings
    if (0 && argc && argv && env) {}

    // Set debug level, 0 is off, 9 is highest presently used
    // May be overridden by commandArgs
    Verilated::debug(0);

    // Randomization reset policy
    // May be overridden by commandArgs
    Verilated::randReset(2);

    // Pass arguments so Verilated code can see them, e.g. $value$plusargs
    // This needs to be called before you create any model
    Verilated::commandArgs(argc, argv);

    // Construct the Verilated model, from Vtop.h generated from Verilating "top.v"
    Vtestbench* tb = new Vtestbench;  // Or use a const unique_ptr, or the VL_UNIQUE_PTR wrapper

#if VM_TRACE
    // If verilator was invoked with --trace argument,
    // and if at run time passed the +trace argument, turn on tracing
    VerilatedVcdC* tfp = NULL;
    const char* flag = Verilated::commandArgsPlusMatch("trace");
    if (flag && 0==strcmp(flag, "+trace")) {
        Verilated::traceEverOn(true);  // Verilator must compute traced signals
        VL_PRINTF("Enabling waves into logs/vlt_dump.vcd...\n");
        tfp = new VerilatedVcdC;
        tb->trace(tfp, 99);  // Trace 99 levels of hierarchy
        Verilated::mkdir("logs");
        tfp->open("logs/vlt_dump.vcd");  // Open the dump file
    }
#endif

    // Set some inputs
    //tb->rst = !0;
    tb->clk = 0;
	tb->reset = 1;
	tb->gpio_port_a = 0xFFFF;
	main_time++;

	tb->eval();

#if VM_TRACE
    // Dump trace data for this cycle
    if (tfp) tfp->dump(main_time);
#endif
	main_time++;
	tb->reset = 0;

	tb->eval();

#if VM_TRACE
    // Dump trace data for this cycle
    if (tfp) tfp->dump(main_time);
#endif
	main_time++;
	tb->reset = 1;

	tb->eval();

#if VM_TRACE
    // Dump trace data for this cycle
    if (tfp) tfp->dump(main_time);
#endif

    // Simulate until $finish
    while (!Verilated::gotFinish()) {
        main_time++;  // Time passes...
			
        // Toggle clocks and such
		/*if((main_time % 10) == 2 && main_time == 152)
			tb->int_ext1 = 0;*/

        if ((main_time % 10) == 3) {
            tb->clk = 1;
        }
        if ((main_time % 10) == 8) {
            tb->clk = 0;
			//tb->int_ext1 =1;
        }

        // Evaluate model
        tb->eval();

#if VM_TRACE
        // Dump trace data for this cycle
        if (tfp) tfp->dump(main_time);
#endif
    }

    // Final model cleanup
    tb->final();

    // Close trace if opened
#if VM_TRACE
    if (tfp) { tfp->close(); tfp = NULL; }
#endif

    //  Coverage analysis (since test passed)
#if VM_COVERAGE
    Verilated::mkdir("logs");
    VerilatedCov::write("logs/coverage.dat");
#endif

    // Destroy model
    delete tb; tb = NULL;

    // Fin
    exit(0);
}
