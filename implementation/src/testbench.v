`timescale 1ns / 1ns

module testbench(
    input clk,
    input reset
);

microcontroller uut(
    .clk(clk),
    .reset(reset)
);


endmodule
