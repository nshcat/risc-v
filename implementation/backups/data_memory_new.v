module data_memory(
    input clk,
    input reset,

    input stall_lw,

    inout [31:0] data_bus_data,
    input [31:0] data_bus_addr,
    input [1:0] data_bus_mode
);

`ifndef VERILATOR
    wire in_area_0 = (data_bus_addr >= 32'h2000) && (data_bus_addr <= 32'h23FF);

    wire [31:0] relative_addr_byte = data_bus_addr - 32'h2000;
    wire [31:0] area_0_address = relative_addr_byte >> 2;
    wire [15:0] read_hi_0, read_lo_0;

    wire [31:0] read_result_ebr = { read_hi_0, read_lo_0 };

    wire [15:0] write_hi = data_bus_data[31:16];
    wire [15:0] write_lo = data_bus_data[15:0];

    SB_RAM40_4K #(
        .WRITE_MODE(0),
        .READ_MODE(0),
    ) memory_hi_0 (
        .RDATA(read_hi_0),
        .RADDR(area_0_address),
        .RCLK(clk & stall_lw),
        .RCLKE(read_requested & in_area_0),
        .RE(read_requested & in_area_0),
        .WADDR(area_0_address),
        .WDATA(write_hi),
        .WE(1'b1),
        .WCLK(clk),
        .WCLKE(write_requested & in_area_0)
    );

   SB_RAM40_4K #(
        .WRITE_MODE(0),
        .READ_MODE(0),
    ) memory_lo_0 (
        .RDATA(read_lo_0),
        .RADDR(area_0_address),
        .RCLK(clk & stall_lw),
        .RCLKE(read_requested & in_area_0),
        .RE(read_requested & in_area_0),
        .WADDR(area_0_address),
        .WDATA(write_lo),
        .WE(1'b1),
        .WCLK(clk),
        .WCLKE(write_requested & in_area_0)
    );

    assign data_bus_data = read_requested ? read_result_ebr : 32'bz;
`else
	reg [31:0] memory [1023:0];

    assign data_bus_data = read_requested ? read_result_be : 32'bz;
`endif

// The result of the last memory read. Is presented to the bus if address falls into range.
reg [31:0] read_result;

wire [31:0] read_result_be = {{read_result[07:00]},
                              {read_result[15:08]},
                              {read_result[23:16]},
                              {read_result[31:24]}};

wire addr_in_range = (data_bus_addr >= 32'h2000) && (data_bus_addr <= 32'h2FFF);
wire [31:0] internal_addr = (data_bus_addr - 32'h2000) >> 2;
wire read_requested = addr_in_range && (data_bus_mode == 2'b01);
wire write_requested = addr_in_range && (data_bus_mode == 2'b10);


wire [31:0] value = memory[0];

always @(posedge clk or negedge reset) begin
    if (!reset) begin
        read_result <= 32'b0;
    end
    else begin
        if(addr_in_range) begin
            `ifdef VERILATOR
                // Are we supposed to write?
                if(data_bus_mode == 2'b10) begin
                    memory[internal_addr] <= {{data_bus_data[07:00]},
                                            {data_bus_data[15:08]},
                                            {data_bus_data[23:16]},
                                            {data_bus_data[31:24]}};
                end
                else if(stall_lw) begin
                    // Load from memory
                    read_result <= memory[internal_addr];
                end
            `endif
        end
    end
end


endmodule