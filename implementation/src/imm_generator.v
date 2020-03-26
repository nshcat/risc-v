module imm_generator(
    input [31:0] instr,
    input [2:0] cs_imm_source,
    output reg [31:0] imm
);

wire sign = instr[31];

always @(*) begin
    case(cs_imm_source)
        3'b001: begin // I-Type
            imm = { (sign ? 21'h1FFFFF : 21'h0), instr[30:20] };
        end

        3'b010: begin // S-Type
            imm = { (sign ? 21'h1FFFFF : 21'h0), instr[30:25], instr[11:8], instr[7] };
        end

        3'b011: begin // B-Type
            imm = { (sign ? 20'hFFFFF : 20'h0), instr[7], instr[30:25], instr[11:8], 1'b0 };
        end

        3'b000: begin // U-Type
            imm = { instr[31:12], 12'h0 };
        end
        
        default: begin // J-Type
            imm = { (sign ? 12'hFFF : 12'h0), instr[19:12], instr[20], instr[30:25], instr[24:21], 1'b0 };
        end
    endcase
end

endmodule