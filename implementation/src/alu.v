module alu(
    input [31:0] a,
    input [31:0] b,
    input [3:0] alu_op,

    output reg [31:0] result,
    output Z,
    output N,
    output S,
    output reg C,
    output reg V
);

wire [31:0] shr = a >> b;

always @(*) begin
    C = 1'b0;
    V = 1'b0;

    case (alu_op)
        4'b0000: begin  // Add
            {C, result} = a + b;
            V = (a[31] & b[31] & !result[31]) | (!a[31] & !b[31] & result[31]);
        end
        4'b0001: begin // Sub
            {C, result} = a - b;
            V = (a[31] & !b[31] & !result[31]) | (!a[31] & b[31] & result[31]);
        end
        4'b0010: result = a << b; // SLL
        4'b0011: begin // SLT
            result = ($signed(a) <  $signed(b)) ? 32'b1 : 32'b0;
        end
        4'b0100: begin // SLTU
            result = ($unsigned(a) <  $unsigned(b)) ? 32'b1 : 32'b0;
        end
        4'b0101: result = a ^ b; // XOR
        4'b0110: result = a >> b; // SRL
        4'b0111: result = {(a[31] ? 1'b1: 1'b0), shr[30:0] }; // SRA
        4'b1000: result = a | b;
        default: result = a & b;
    endcase
end

assign Z = (result == 32'b0) ? 1'b1 : 1'b0;
assign N = result[31];
assign S = N ^ V;


endmodule