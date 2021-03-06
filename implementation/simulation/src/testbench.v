`timescale 1ns / 1ns

module testbench(
    input clk,
    input reset,
    output [7:0] leds_out,
    output TIM1_CMP,
	output TIM2_CMP,
    inout [15:0] gpio_port_a
    
`ifdef FEATURE_DBG_PORT
    ,  
    input uart_rx,
    output uart_tx
`endif
);

microcontroller uut(
    .clk(clk),
    .reset(reset),
    .leds_out(leds_out),
    .tim1_cmp(TIM1_CMP),
	.tim2_cmp(TIM2_CMP),
    .gpio_port_a(gpio_port_a)
    
`ifdef FEATURE_DBG_PORT
    ,
    .uart_rx(uart_rx),
    .uart_tx(uart_tx)
`endif
);


endmodule
