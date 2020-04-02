`timescale 1ns / 1ns

module testbench(
    input clk,
    input reset,
    output [7:0] leds_out,
    input int_ext1,
    input int_ext2,
    output TIM1_CMP,
	output TIM2_CMP
);

microcontroller uut(
    .clk(clk),
    .reset(reset),
    .leds_out(leds_out),
    .int_ext1(int_ext1),
    .int_ext2(int_ext2),
    .tim1_cmp(TIM1_CMP),
	.tim2_cmp(TIM2_CMP)
);


endmodule
