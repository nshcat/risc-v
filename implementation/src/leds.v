module leds(
    input clk,
    input reset,
    inout [31:0] data_bus_data,
    input [31:0] data_bus_addr,
    input [1:0] data_bus_mode,   // 00: Nothing, 01: Read, 10: Write
    output [7:0] leds_out
);


// ==== Port Registers ====
reg [31:0] led_state;   // Address 0x4F00
// ====

// ==== Reading ====
wire read_requested = (data_bus_mode == 2'b01) && (data_bus_addr == 32'h4F00);
assign data_bus_data = read_requested ? led_state : 32'bz;


// ==== Logic ====
assign leds_out = led_state[7:0];
wire write_requested = (data_bus_mode == 2'b10) && (data_bus_addr == 32'h4F00);

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        led_state <= 32'b0;
    end
    else begin
        if(write_requested) begin
            led_state <= data_bus_data;
        end   
    end
end

endmodule