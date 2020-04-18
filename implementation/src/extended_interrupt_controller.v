module extended_interrupt_controller(
    input clk,
    input reset,

    input [15:0] gpio_pin_state,     // State of GPIO input pins
    output eic_irq,             // Interrupt request line for all EIC events

    // Data bus slave interface
    input [15:0] data_bus_write,
    output [15:0] data_bus_read,
    input [31:0] data_bus_addr,
    input [1:0] data_bus_mode,  // 00: Nothing, 01: Read, 10: Write
    input data_bus_select
);


// === Peripheral registers
reg [15:0] event_mask;      // 0x4010 Event flag mask, works like the IRQ mask in the ICU: Events wont be handled, but remembered
reg [15:0] detection_mask;  // 0x4014 Controls whether event flags are generated at all for the pins
reg [15:0] event_flags;     // 0x4018 Pending event flags
reg [15:0] active_event;    // 0x401C The currently active event. Must be cleared by user code to rearm the EIC.
reg [15:0] falling_edge;    // 0x4020 Detect falling edges
reg [15:0] rising_edge;     // 0x4024 Detect rising edges

wire in_event = (active_event != 16'h0);    // Whether we are currently handling an event.
wire write_requested = (data_bus_mode == 2'b10) & data_bus_select; // Whether a data bus write is requested

wire [15:0] next_event_flags = event_flags | detected_edges; // New event flags sample
wire new_event = !in_event && ((next_event_flags & event_mask) != 16'h0); // Whether a new event should be triggered

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        event_mask <= 16'h0;
        detection_mask <= 16'h0;
        event_flags <= 16'h0;
        active_event <= 16'h0;
        falling_edge <= 16'h0;
        rising_edge <= 16'h0;
    end
    else begin
        // Handle data bus write
        if(write_requested) begin
            case(data_bus_addr)
                32'h4010: event_mask <= data_bus_write;
                32'h4014: detection_mask <= data_bus_write;
                32'h4018: event_flags <= data_bus_write;
                32'h401C: active_event <= data_bus_write;
                32'h4020: falling_edge <= data_bus_write;
                32'h4024: rising_edge <= data_bus_write;     
                default: begin end     
            endcase
        end
        else begin
            // Sample new edge detector events
            event_flags <= next_event_flags;

            // Check if we have a new event trigger
            if(new_event) begin
                // Trigger a new event
                active_event <= event_selector();
            end
        end
    end
end

// Priority selector that decides which event to select as the next handled one
function [15:0] event_selector();
    casez (next_event_flags & event_mask)
        16'b???????????????1: event_selector = 16'b1;
        16'b??????????????10: event_selector = 16'b10;
        16'b?????????????100: event_selector = 16'b100;
        16'b????????????1000: event_selector = 16'b1000;
        16'b???????????10000: event_selector = 16'b10000;
        16'b??????????100000: event_selector = 16'b100000;
        16'b?????????1000000: event_selector = 16'b1000000;
        16'b????????10000000: event_selector = 16'b10000000;
        16'b???????100000000: event_selector = 16'b100000000;
        16'b??????1000000000: event_selector = 16'b1000000000;
        16'b?????10000000000: event_selector = 16'b10000000000;
        16'b????100000000000: event_selector = 16'b100000000000;
        16'b???1000000000000: event_selector = 16'b1000000000000;
        16'b??10000000000000: event_selector = 16'b10000000000000;
        16'b?100000000000000: event_selector = 16'b100000000000000;
        16'b1000000000000000: event_selector = 16'b1000000000000000;
        default: event_selector = 16'h0;
    endcase
endfunction

// Control IRQ line
assign eic_irq = ~new_event;

// === Data bus read logic
assign data_bus_read = bus_read();

function [15:0] bus_read();
    case (data_bus_addr)
        32'h4010: bus_read = event_mask;
        32'h4014: bus_read = detection_mask;
        32'h4018: bus_read = event_flags;
        32'h401C: bus_read = active_event;
        32'h4020: bus_read = falling_edge;
        default: bus_read = rising_edge;
    endcase
endfunction

// === Edge detector

wire [15:0] detector_out;
wire [15:0] detected_edges = detector_out & detection_mask;

edge_detector
#(.WIDTH(16))
uut(
    .clk(clk),
    .reset(reset),
    .in(gpio_pin_state),
    .rising_edge(rising_edge),
    .falling_edge(falling_edge),
    .out(detector_out)
);

endmodule