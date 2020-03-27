`timescale 1ns / 1ns

module testbench(
    input clk,
    input reset,
    output [7:0] leds_out,
    input int_ext1,
    input int_ext2
);

microcontroller uut(
    .clk(clk),
    .reset(reset),
    .leds_out(leds_out),
    .int_ext1(int_ext1),
    .int_ext2(int_ext2)
);


endmodule
