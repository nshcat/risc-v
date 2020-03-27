module data_memory(
    input clk,
    input reset,

    inout [31:0] data_bus_data,
    input [31:0] data_bus_addr,
    input [1:0] data_bus_mode
);

reg [31:0] memory [1023:0];

// The result of the last memory read. Is presented to the bus if address falls into range.
reg [31:0] read_result;

wire [31:0] read_result_be = {{read_result[07:00]},
                              {read_result[15:08]},
                              {read_result[23:16]},
                              {read_result[31:24]}};

wire addr_in_range = (data_bus_addr >= 32'h2000) && (data_bus_addr <= 32'h2FFF);
wire [31:0] internal_addr = data_bus_addr >> 2;
wire read_requested = addr_in_range && (data_bus_mode == 2'b01);

assign data_bus_data = read_requested ? read_result_be : 32'bz;

always @(posedge clk or negedge reset) begin
    if (!reset) begin
        read_result <= 32'b0;
    end
    else begin
        if(addr_in_range) begin
            // Are we supposed to write?
            if(data_bus_mode == 2'b10) begin
                memory[internal_addr] <= {{data_bus_data[07:00]},
                                          {data_bus_data[15:08]},
                                          {data_bus_data[23:16]},
                                          {data_bus_data[31:24]}};
            end
            else begin
                // Load from memory
                read_result <= memory[internal_addr];
            end
        end
    end
end


endmodule