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

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        debounced_out <= {(WIDTH){1'b0}};
    end
    else if(timer == {(LGWAIT){1'b0}}) begin
        debounced_out <= raw_in;
    end
end

endmodule