module interrupt_controller(
    input clk,
    input reset,

    input [3:0] irq_sources,
    output [31:0] irq_target,       // The flash address of the current ISR
    output [4:0] irq_mask,          // Mask determining whether interrupts are active for various sources

    inout [31:0] data_bus_data,
    input [31:0] data_bus_addr,
    input [1:0] data_bus_mode
);

// ==== Port Registers ====
reg [31:0] isr_mask;        // Address 0x4000, IRQ mask, 1 means interrupt is enabled.

reg [31:0] isr_ext1;        // Address 0x4001, ISR address for external interrupt 1
reg [31:0] isr_ext2;        // Address 0x4002, ISR address for external interrupt 2
reg [31:0] isr_tim1;        // Address 0x4003, ISR address for timer interrupt 1
reg [31:0] isr_tim2;        // Address 0x4004, ISR address for timer interrupt 2
// ====

assign irq_mask = isr_mask[4:0];

function [31:0] current_isr();
    current_isr = 32'b0;

    if(irq_sources[0] == 1'b0) begin
        current_isr = isr_ext1;
    end

    if(irq_sources[1] == 1'b0) begin
        current_isr = isr_ext2;
    end

    if(irq_sources[2] == 1'b0) begin
        current_isr = isr_tim1;
    end

    if(irq_sources[3] == 1'b0) begin
        current_isr = isr_tim2;
    end
endfunction

assign irq_target = current_isr();


wire in_address_space = (data_bus_addr >= 32'h4000) && (data_bus_addr <= 32'h4004);
wire read_requested = (data_bus_mode == 2'b01) && in_address_space;
wire write_requested = (data_bus_mode == 2'b10) && in_address_space;
assign data_bus_data = read_requested ? bus_read() : 32'bz;

function [31:0] bus_read();
    case (data_bus_addr)
        32'h4000: bus_read = isr_mask;
        32'h4001: bus_read = isr_ext1;
        32'h4002: bus_read = isr_ext2;
        32'h4003: bus_read = isr_tim1;
        default: bus_read = isr_tim2;
    endcase
endfunction

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        isr_mask <= 32'b0;
        isr_ext1 <= 32'b0;
        isr_ext2 <= 32'b0;
        isr_tim1 <= 32'b0;
        isr_tim2 <= 32'b0;
    end
    else begin
        if(write_requested) begin
            case (data_bus_addr)
                32'h4000: isr_mask <= data_bus_data;
                32'h4001: isr_ext1 <= data_bus_data;
                32'h4002: isr_ext2 <= data_bus_data;
                32'h4003: isr_tim1 <= data_bus_data;
                default: isr_tim2 <= data_bus_data;
            endcase
        end
    end
end


endmodule