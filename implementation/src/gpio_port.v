module gpio_port(
    input clk,
    input reset,
    inout [31:0] data_bus_data,
    input [31:0] data_bus_addr,
    input [1:0] data_bus_mode,  // 00: Nothing, 01: Read, 10: Write
    inout [15:0] gpio_pins
);

// ==== Data Bus Registers ====
reg [31:0] pin_direction;       // Address 0x4030, 0: Input, 1: Output
reg [31:0] write_data;          // Address 0x4031
reg [31:0] read_data;           // Address 0x4032 (read-only)
// ====


// ==== GPIO Management ====
genvar pin;
generate
for(pin = 0; pin < 16; pin++) begin : pins
    assign gpio_pins[pin] = (pin_direction[pin] == 1'b1) ? write_data[pin] : 1'bZ;
end
endgenerate
// ====


// ==== Reading ====

wire addr_in_readonly = (data_bus_addr == 32'h4032);
wire addr_in_rw = (data_bus_addr >= 32'h4030) && (data_bus_addr <= 32'h4031);
wire read_requested = (data_bus_mode == 2'b01) && (addr_in_readonly || addr_in_rw);

assign data_bus_data = read_requested ? bus_read() : 32'bz;

function [31:0] bus_read();
    case (data_bus_addr)
        32'h4030: bus_read = pin_direction;
        32'h4031: bus_read = write_data;
        default: bus_read = read_data;
    endcase
endfunction


// ==== Writing and Logic ====
wire write_requested = (data_bus_mode == 2'b10) && addr_in_rw;

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        pin_direction <= 32'b0;
        write_data <= 32'b0;
        read_data <= 32'b0;
    end
    else begin
        // If we are requested to do a write, handle that
        if(write_requested) begin
            case (data_bus_addr)
                32'h4030: pin_direction <= data_bus_data;
                default: write_data <= data_bus_data;
            endcase
        end

        read_data <= { 16'h0, gpio_pins }; //read
    end
end

endmodule