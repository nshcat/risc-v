module leds(
    input clk,
    input reset,
    output [7:0] data_bus_read,
    input [7:0] data_bus_write,
    input [31:0] data_bus_addr,
    input data_bus_select,
    input [1:0] data_bus_mode,   // 00: Nothing, 01: Read, 10: Write
    output [7:0] leds_out
);


// ==== Port Registers ====
reg [7:0] led_state;   // Address 0x40F0
// ====

// ==== Reading ====
wire read_requested = (data_bus_mode == 2'b01) && data_bus_select;
assign data_bus_read = /*read_requested ? { 24'h0, led_state } : 32'bz;*/ led_state;


// ==== Logic ====
assign leds_out = led_state[7:0];
wire write_requested = (data_bus_mode == 2'b10) && data_bus_select;

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        led_state <= 8'b0;
    end
    else begin
        if(write_requested) begin
            led_state <= data_bus_write;
        end   
    end
end

endmodule