module gpio_port(
    input clk,
    input reset,
    inout [31:0] data_bus_data,
    input [31:0] data_bus_addr,
    input [1:0] data_bus_mode,  // 00: Nothing, 01: Read, 10: Write
    inout [15:0] gpio_pins
);

// ==== Data Bus Registers ====
reg [15:0] pin_direction;       // Address 0x4034, 0: Input, 1: Output
reg [15:0] write_data;          // Address 0x4038
reg [15:0] read_data;           // Address 0x403C (read-only)
// ====


// ==== GPIO Management ====
genvar pin;
generate
for(pin = 0; pin < 16; pin++) begin : pins
    assign gpio_pins[pin] = (pin_direction[pin] == 1'b1) ? write_data[pin] : 1'bZ;
end
endgenerate

// Input synchronizer, 16 bits wide and three FF stages deep
synchronizer
#(.WIDTH(16), .DEPTH(3))
sync(
    .clk(clk),
    .reset(reset),
    .in(gpio_pins),     // Physical GPIO pins on the FPGA
    .out(sync_in)       // Synchronized output
);

wire [15:0] sync_in; // The synchronized input vector. Can be safely used in clocked processes.
// ====


// ==== Reading ====

wire addr_in_readonly = (data_bus_addr == 32'h403C);
wire addr_in_rw = (data_bus_addr >= 32'h4034) && (data_bus_addr <= 32'h4038);
wire read_requested = (data_bus_mode == 2'b01) && (addr_in_readonly || addr_in_rw);

assign data_bus_data = read_requested ? bus_read() : 32'bz;

function [31:0] bus_read();
    case (data_bus_addr)
        32'h4034: bus_read = { 16'h0, pin_direction };
        32'h4038: bus_read = { 16'h0, write_data };
        default: bus_read = { 16'h0, read_data };
    endcase
endfunction


// ==== Writing and Logic ====
wire write_requested = (data_bus_mode == 2'b10) && addr_in_rw;

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        pin_direction <= 16'b0;
        write_data <= 16'b0;
        read_data <= 16'b0;
    end
    else begin
        // If we are requested to do a write, handle that
        if(write_requested) begin
            case (data_bus_addr)
                32'h4034: pin_direction <= data_bus_data[15:0];
                default: write_data <= data_bus_data[15:0];
            endcase
        end

        read_data <= sync_in; // Sample synchronized input
    end
end

endmodule