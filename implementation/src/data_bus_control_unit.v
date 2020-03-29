module data_bus_control_unit(
    input cs_bus_read,
    input cs_bus_write,
    input [1:0] cs_mem_width,
    input cs_load_signed,
    input [31:0] addr_in,
    input [31:0] data_in,
    output [31:0] data_out,

    inout [31:0] data_bus_data,
    output [31:0] data_bus_addr,
    output [1:0] data_bus_mode,
    output [1:0] data_bus_reqw, // Request width
    output data_bus_reqs        // Request signed status
);

assign data_bus_mode = cs_bus_write ? 2'b10 : cs_bus_read ? 2'b01 : 2'b00;
assign data_bus_addr = addr_in;
assign data_bus_data = (data_bus_mode == 2'b10) ? data_in : 32'bz;
assign data_out = (data_bus_mode == 2'b01) ? data_bus_data : 32'b0;
assign data_bus_reqs = cs_load_signed;
assign data_bus_reqw = cs_mem_width;

endmodule