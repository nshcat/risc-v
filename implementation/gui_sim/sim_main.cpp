// DESCRIPTION: Verilator: Verilog example module
//
// This file ONLY is placed into the Public Domain, for any use,
// without warranty, 2017 by Wilson Snyder.
//======================================================================

// Include common routines
#include <thread>
#include <iostream>
#include "systemc.h"

// Include model header, generated from Verilating "top.v"
#include "Vtestbench.h"
#include "Vtestbench_testbench.h"
#include "Vtestbench_microcontroller.h"
#include "Vtestbench_datapath.h"
#include "Vtestbench_register_file.h"

// If "verilator --trace" is used, include the tracing class
#if VM_TRACE
# include <verilated_vcd_sc.h>
#endif

uint32_t get_pc(Vtestbench* top)
{
	return top->testbench->uut->core->pc;
}

uint32_t dump_state(Vtestbench* top)
{
	std::cout << "PC: " << std::hex << "0x" << top->testbench->uut->core->pc << std::endl;
	/*std::cout << "Registers:\n";
	
	for(int i = 0; i < 32; ++i)
	{
		std::cout << "   r" << i << ": 0x" << top->testbench->uut->core->registers->regs[i] << std::endl;
	}
	std::cout << "\n\n";*/
}


int sc_main(int argc, char** argv)
{
#if VM_TRACE
    Verilated::traceEverOn(true);
    VL_PRINTF("Enabling waves into logs/vlt_dump.vcd...\n");
    VerilatedVcdSc* tfp = new VerilatedVcdSc;
    Verilated::mkdir("logs");
#endif

	// Clock period, corresponds to 16.5 MHz
	sc_time T(60610, SC_PS);
	
	sc_clock clk("clk", T);
	sc_signal<bool> reset("reset");
	sc_signal<bool> int_ext1("int_ext1");
	sc_signal<bool> int_ext2("int_ext2");
	sc_signal<uint32_t, SC_MANY_WRITERS> gpio;
	sc_signal<uint32_t> leds;
	sc_signal<bool> tim1_cmp, tim2_cmp;
	
	int_ext1 = 1;
	int_ext2 = 1;
	
	Vtestbench top("top_verilog");
	top.clk(clk);
	top.reset(reset);
	top.int_ext1(int_ext1);
	top.int_ext2(int_ext2);
	top.gpio_port_a(gpio);
	top.leds_out(leds);
	top.TIM1_CMP(tim1_cmp);
	top.TIM2_CMP(tim2_cmp);
	
	// Reset signal
	reset = 0;
	sc_start(3*T);
	reset = 1;
	
	for(int i = 0; i < 75; ++i)
	{
		sc_start(T);
		//dump_state(&top);
	}
	
#ifdef TRACE
	tfp->close();
#endif	
	
	return 0;
}
