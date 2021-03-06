module timer(
    input clk,
    input reset,
    input [31:0] data_bus_write,
    output [31:0] data_bus_read,
    input [31:0] data_bus_addr,
    input [1:0] data_bus_mode,  // 00: Nothing, 01: Read, 10: Write
    input data_bus_select,
    output timer_irq,
    output reg comparator_out
);

// ==== Module Parameters ====
parameter base_address = 32'h40A0;
parameter addr_cntrl = base_address + 32'h0000;
parameter addr_prsclr_th = base_address + 32'h0004;
parameter addr_cntr_th = base_address + 32'h0008;
parameter addr_cmp_vl = base_address + 32'h000C;
parameter addr_prsclr_vl = base_address + 32'h0010;
parameter addr_cntr_vl = base_address + 32'h0014;


// ==== Port Registers ====
reg [1:0] timer_control;   
wire timer_enabled = timer_control[0];
wire comparator_out_enabled = timer_control[1];

reg [31:0] prescaler_threshold; 
reg [31:0] counter_threshold;   
reg [31:0] comparator_value;    

reg [31:0] prescaler_value;     // (read only)
reg [31:0] counter_value;       // (read only)
// ====

// ==== Reading ====
wire read_requested = (data_bus_mode == 2'b01) && data_bus_select;

assign data_bus_read = bus_read();

function [31:0] bus_read();
    case (data_bus_addr)
        addr_cntrl: bus_read = { 30'h0, timer_control };
        addr_prsclr_th: bus_read = prescaler_threshold;
        addr_cntr_th: bus_read = counter_threshold;
        addr_cmp_vl: bus_read = comparator_value;
        addr_prsclr_vl: bus_read = prescaler_value;
        default: bus_read = counter_value;
    endcase
endfunction


// ==== Writing and Logic ====
wire write_requested = (data_bus_mode == 2'b10) && data_bus_select;

assign timer_irq = (!timer_enabled) | !(((prescaler_value >= (prescaler_threshold)) && (counter_value >= (counter_threshold))));

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        timer_control <= 2'b0;
        prescaler_threshold <= 32'b0;
        counter_threshold <= 32'b0;
        prescaler_value <= 32'b0;
        counter_value <= 32'b0;
        comparator_value <= 32'b0; 
        comparator_out <= 1'b0;
    end
    else begin
        // If we are requested to do a write, handle that
        if(write_requested) begin
            case (data_bus_addr)
                addr_cntrl: timer_control <= data_bus_write[1:0];
                addr_prsclr_th: prescaler_threshold <= data_bus_write;
                addr_cntr_th: counter_threshold <= data_bus_write;
                default: comparator_value <= data_bus_write;
            endcase

            // Reset timer TODO is this a good idea?
            prescaler_value <= 32'b0;
            counter_value <= 32'b0;
        end
        else begin // Otherwise perform normal counter operation
            if(timer_enabled) begin           
                prescaler_value <= prescaler_value + 32'b1;

                // Did we exceed the prescaler counter?
                if (prescaler_value >= prescaler_threshold) begin
                    prescaler_value <= 32'b0;

                    // Increment real counter
                    counter_value <= counter_value + 32'b1;

                    if (counter_value >= counter_threshold) begin
                        counter_value <= 32'b0;
                        comparator_out <= 1'b1;
                    end
                    else begin
                        comparator_out <= (comparator_out_enabled) ? (counter_value < comparator_value) : 1'b0;
                    end
                end
            end
            else begin
                // Make sure the comparator out will go off when the timer is stopped
                comparator_out <= 1'b0;
            end
        end        
    end
end

endmodule