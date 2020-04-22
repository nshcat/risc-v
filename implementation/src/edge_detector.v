module edge_detector(
    input clk,
    input reset,

    input [WIDTH-1:0] in,               // Sampled input state
    input [WIDTH-1:0] rising_edge,      // Flags controlling whether rising edges are detected
    input [WIDTH-1:0] falling_edge,     // Flags controlling whether falling edges are detected
    output [WIDTH-1:0] out              // Flags describing whether edges were detected
);

parameter WIDTH = 16;       // The input width

reg [WIDTH-1:0] previous;   // The previous state used to detect a clock edge

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        previous <= {WIDTH{1'h0}};
    end
    else begin
        previous <= in;
    end
end


reg [2:0] delay;    // Delay counter. After a reset, we have to delay edge detection for four cycles, since the GPIO input
                    // is delayed by three cycles because of the input synchronizer, so we read the actual previous value
                    // on the fourth cycle. We count this up to 3'h4.
wire [WIDTH-1:0] delay_mask = {WIDTH{(delay == 3'h4)}};

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        delay <= 3'h0;
    end
    else begin
        if(delay != 3'h4) begin
            delay <= delay + 3'h1;
        end
    end
end

// Detection logic
wire [WIDTH-1:0] re_detected = rising_edge & (~previous & in);
wire [WIDTH-1:0] fe_detected = falling_edge & (previous & ~in);

assign out = delay_mask & (re_detected | fe_detected);

endmodule