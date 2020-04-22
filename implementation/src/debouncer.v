// Basic debouncer
// https://zipcpu.com/blog/2017/08/04/debouncing.html
//
module debouncer(
    input clk,
    input reset,

    input [WIDTH-1:0] raw_in,
    output reg [WIDTH-1:0] debounced_out
);

parameter WIDTH = 1;
parameter LGWAIT = 20;  // Maximum delay is 2^(LGWAIT) clock cycles.

reg [LGWAIT-1:0] timer;

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        timer <= {(LGWAIT){1'b1}};
    end
    else begin
        timer <= timer - 1'b1;
    end
end

reg [2:0] delay; // Delay register to avoid problems with initial firing of input edges after reset.
// The input synchronizer delays the read of the first "real" input values by three cycles, so for the
// first four cycles, we do not delay reading here in order to not fire false edge events. Otherwise
// we would read zero (synchronizer reset state), delay by LGWAIT, and then read again, which will almost
// always result in an edge being detected.

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        delay <= 3'h0;
    end
    else if(delay != 3'h5) begin
        delay <= delay + 3'h1;
    end
end

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        debounced_out <= {(WIDTH){1'b0}};
    end
    else if(timer == {(LGWAIT){1'b0}} || (delay <= 3'h4)) begin
        debounced_out <= raw_in;
    end
end

endmodule