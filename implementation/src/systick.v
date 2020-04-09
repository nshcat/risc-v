// Fixed timer that counts the number of milliseconds (system ticks) since boot
module systick(
    input clk,
    input reset,
    inout [31:0] data_bus_data,
    input [31:0] data_bus_addr,
    input [1:0] data_bus_mode   // 00: Nothing, 01: Read, 10: Write
);

// ==== Configuration ====
// IMPORTANT: These have to be adjusted for actual clock speed
`ifndef VERILATOR
	localparam PRESCALER = 32'd16499;	// 16.5MhZ / 16500 = 1KhZ
	localparam COUNTER = 32'd0;      	// 1KhZ / 1 = 1KhZ
`else
	localparam PRESCALER = 32'd9999;    // 100MhZ / 10000 = 10KhZ
	localparam COUNTER = 32'd9;         // 10KhZ / 10 = 1KhZ
`endif
// ====

// ==== Port Registers ====
reg [31:0] tick_count;   // Address 0x4030 (read only)
// ====

// ==== Internal Registers ====
reg [31:0] prescaler_threshold;
reg [31:0] counter_threshold;

reg [31:0] prescaler_value;
reg [31:0] counter_value;
// ====

// ==== Reading ====
wire read_requested = (data_bus_mode == 2'b01) && (data_bus_addr == 32'h4030);

assign data_bus_data = read_requested ? bus_read() : 32'bz;

function [31:0] bus_read();
    case (data_bus_addr)
        default: bus_read = tick_count;
    endcase
endfunction


// ==== Logic ====
always @(posedge clk or negedge reset) begin
    if(!reset) begin
        prescaler_threshold <= PRESCALER;
        counter_threshold <= COUNTER;
        prescaler_value <= 32'b0;
        counter_value <= 32'b0;
        tick_count <= 32'b0;
    end
    else begin
        prescaler_value <= prescaler_value + 32'b1;

        if (prescaler_value >= prescaler_threshold) begin
            prescaler_value <= 32'b0;
            counter_value <= counter_value + 32'b1;

            if (counter_value >= counter_threshold) begin
                counter_value <= 32'b0;
                tick_count <= tick_count + 32'b1;
            end
        end     
    end
end

endmodule
