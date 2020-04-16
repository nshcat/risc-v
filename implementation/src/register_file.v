module register_file(
    input clk,
    input reset,
    input [4:0] read_reg_1,
    input [4:0] read_reg_2,
    input [4:0] write_reg,
    input [31:0] write_data,
    input cs_reg_write,

    output [31:0] read_data_1,
    output [31:0] read_data_2

`ifdef FEATURE_DBG_PORT
    // Data bus slave interface. The register file is only mapped into the data bus
    // address space when the debug port feature is enabled, since it is very costly
    // in terms of LC utilization.
    ,
    input [31:0] slv_address,
    input [31:0] slv_write_data,
    input [1:0] slv_mode,
    output [31:0] slv_read_data_regs,
    input slv_select_regs
`endif
);

`ifndef FEATURE_RV32E
    // 32 registers. Note that $0 is hard-wired to always be 0.
    reg [31:0] regs [31:0];
`else
    // 16 registers. $0 is hard-wired to always be 0.
    reg [31:0] regs [15:0];
`endif

// Write back
always @(posedge clk or negedge reset) begin
    if(reset) begin
`ifdef FEATURE_DBG_PORT
        if(write_requested) begin
            case (slv_address)
                32'h4104: regs[1] <= slv_write_data;
                32'h4108: regs[2] <= slv_write_data;
                32'h410C: regs[3] <= slv_write_data;
                32'h4110: regs[4] <= slv_write_data;
                32'h4114: regs[5] <= slv_write_data;
                32'h4118: regs[6] <= slv_write_data;
                32'h411C: regs[7] <= slv_write_data;
                32'h4120: regs[8] <= slv_write_data;
                32'h4124: regs[9] <= slv_write_data;
                32'h4128: regs[10] <= slv_write_data;
                32'h412C: regs[11] <= slv_write_data;
                32'h4130: regs[12] <= slv_write_data;
                32'h4134: regs[13] <= slv_write_data;
                32'h4138: regs[14] <= slv_write_data;
                32'h413C: regs[15] <= slv_write_data;

            `ifndef FEATURE_RV32E
                32'h4140: regs[16] <= slv_write_data;
                32'h4144: regs[17] <= slv_write_data;
                32'h4148: regs[18] <= slv_write_data;
                32'h414C: regs[19] <= slv_write_data;
                32'h4150: regs[20] <= slv_write_data;
                32'h4154: regs[21] <= slv_write_data;
                32'h4158: regs[22] <= slv_write_data;
                32'h415C: regs[23] <= slv_write_data;
                32'h4160: regs[24] <= slv_write_data;
                32'h4164: regs[25] <= slv_write_data;
                32'h4168: regs[26] <= slv_write_data;
                32'h416C: regs[27] <= slv_write_data;
                32'h4170: regs[28] <= slv_write_data;
                32'h4174: regs[29] <= slv_write_data;
                32'h4178: regs[30] <= slv_write_data;
                32'h417C: regs[31] <= slv_write_data;
            `endif

                default: begin                   
                end
            endcase
        end
        else
`endif
        if(cs_reg_write) begin
`ifndef FEATURE_RV32E
            regs[write_reg] <= write_data;
`else
            regs[write_reg[3:0]] <= write_data;
`endif
        end
    end
    else begin
        regs[0] <= 32'b0;
        regs[1] <= 32'b0;
        regs[2] <= 32'b0;
        regs[3] <= 32'b0;
        regs[4] <= 32'b0;
        regs[5] <= 32'b0;
        regs[6] <= 32'b0;
        regs[7] <= 32'b0;
        regs[8] <= 32'b0;
        regs[9] <= 32'b0;
        regs[10] <= 32'b0;
        regs[11] <= 32'b0;
        regs[12] <= 32'b0;
        regs[13] <= 32'b0;
        regs[14] <= 32'b0;
        regs[15] <= 32'b0;
    
    `ifndef FEATURE_RV32E
        regs[16] <= 32'b0;
        regs[17] <= 32'b0;
        regs[18] <= 32'b0;
        regs[19] <= 32'b0;
        regs[20] <= 32'b0;
        regs[21] <= 32'b0;
        regs[22] <= 32'b0;
        regs[23] <= 32'b0;
        regs[24] <= 32'b0;
        regs[25] <= 32'b0;
        regs[26] <= 32'b0;
        regs[27] <= 32'b0;
        regs[28] <= 32'b0;
        regs[29] <= 32'b0;
        regs[30] <= 32'b0;
        regs[31] <= 32'b0;
    `endif

    end
end

`ifndef FEATURE_RV32E
    assign read_data_1 = (read_reg_1 == 5'b0) ? 32'b0 : regs[read_reg_1];
    assign read_data_2 = (read_reg_2 == 5'b0) ? 32'b0 : regs[read_reg_2];
`else
    assign read_data_1 = (read_reg_1 == 5'b0) ? 32'b0 : regs[read_reg_1[3:0]];
    assign read_data_2 = (read_reg_2 == 5'b0) ? 32'b0 : regs[read_reg_2[3:0]];
`endif

`ifdef FEATURE_DBG_PORT
    wire read_requested = (slv_mode == 2'b01) && slv_select_regs;
    wire write_requested = (slv_mode == 2'b10) && slv_select_regs;
    assign slv_read_data_regs = bus_read();

    function [31:0] bus_read();
        case (slv_address)
            32'h4100: bus_read = regs[0];
            32'h4104: bus_read = regs[1];
            32'h4108: bus_read = regs[2];
            32'h410C: bus_read = regs[3];
            32'h4110: bus_read = regs[4];
            32'h4114: bus_read = regs[5];
            32'h4118: bus_read = regs[6];
            32'h411C: bus_read = regs[7];
            32'h4120: bus_read = regs[8];
            32'h4124: bus_read = regs[9];
            32'h4128: bus_read = regs[10];
            32'h412C: bus_read = regs[11];
            32'h4130: bus_read = regs[12];
            32'h4134: bus_read = regs[13];
            32'h4138: bus_read = regs[14];
            32'h413C: bus_read = regs[15];

        `ifndef FEATURE_RV32E
            32'h4140: bus_read = regs[16];
            32'h4144: bus_read = regs[17];
            32'h4148: bus_read = regs[18];
            32'h414C: bus_read = regs[19];
            32'h4150: bus_read = regs[20];
            32'h4154: bus_read = regs[21];
            32'h4158: bus_read = regs[22];
            32'h415C: bus_read = regs[23];
            32'h4160: bus_read = regs[24];
            32'h4164: bus_read = regs[25];
            32'h4168: bus_read = regs[26];
            32'h416C: bus_read = regs[27];
            32'h4170: bus_read = regs[28];
            32'h4174: bus_read = regs[29];
            32'h4178: bus_read = regs[30];
            32'h417C: bus_read = regs[31];
        `endif

            default: bus_read = 32'h0;
        endcase
    endfunction
`endif

endmodule