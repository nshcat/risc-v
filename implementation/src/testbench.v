`timescale 1ns / 1ns

module testbench(
    input clk,
    input reset,
    output [7:0] leds_out
);

microcontroller uut(
    .clk(clk),
    .reset(reset),
    .leds_out(leds_out)
);


endmodule
