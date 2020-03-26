module branch_control_unit(
    input [1:0] cs_branch_op,   // BranchOp control signal
    input [2:0] branch_type,    // Exact branch type. Used for BEQ, BLT and friends
    input [31:0] pc,            // Old PC
    input [31:0] imm,           // imm read from instruction according to current instruction format
    input [31:0] read_data_1,   // Data from first register read
    input Z,                    // Zero flag from ALU. Result was zero.
    input N,                    // Negative flag from ALU. Result was negative.
    input C,                    // Carry flag
    input S,                    // Sign flag
    input V,                    // Signed overflow flag
    output reg [31:0] next_pc   // New PC value
);

wire [31:0] jalr = imm + read_data_1;

always @(*) begin
    case (cs_branch_op)
        2'b00: begin    // No branching
            next_pc = pc + 4;
        end
        2'b01: begin    // Conditional branch
            case (branch_type)
                3'b000: next_pc = (Z == 1'b1) ? pc + imm : pc + 4; // BEQ
                3'b001: next_pc = (Z == 1'b0) ? pc + imm : pc + 4; // BNE
                3'b100: next_pc = (S == 1'b1) ? pc + imm : pc + 4; // BLT
                3'b101: next_pc = (S == 1'b0) ? pc + imm : pc + 4; // BGE TODO not N?
                3'b110: next_pc = (C == 1'b1) ? pc + imm : pc + 4; // BLTU
                default: next_pc = (C == 1'b0) ? pc + imm : pc + 4; // BGEU
            endcase
        end
        2'b10: begin // JAL
            next_pc = pc + imm;
        end
        2'b11: begin // JALR
            next_pc = { jalr[31:1], 1'b0 };
        end
    endcase
end

endmodule