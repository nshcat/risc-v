module alu_control(
    input [1:0] cs_alu_control,
    input [2:0] funct3,
    input [6:0] funct7,
    output cs_alu_shamt,
    output reg [3:0] alu_op
);

assign cs_alu_shamt = (cs_alu_control == 2'b10) && (funct3 == 3'b001 || funct3 == 3'b101);

always @(*) begin
    case(cs_alu_control)
        2'b01: alu_op = 4'b0001;
        2'b10: begin // I-type
            case(funct3)
                3'b000: alu_op = 4'b0000;
                3'b001: alu_op = 4'b0010;
                3'b010: alu_op = 4'b0011;
                3'b011: alu_op = 4'b0100;
                3'b100: alu_op = 4'b0101;
                3'b101: begin
                    if(funct7 == 7'b0) begin
                        alu_op = 4'b0110;
                    end
                    else begin
                        alu_op = 4'b0111;
                    end
                end
                3'b110: alu_op = 4'b1000;
                3'b111: alu_op = 4'b1001;
            endcase
        end
        2'b11: begin // R-type
            case(funct3)
                3'b000: begin // ADD/SUB
                    if(funct7 == 7'b0) begin
                        alu_op = 4'b0000;
                    end
                    else begin
                        alu_op = 4'b0001;
                    end
                end
                3'b001: alu_op = 4'b0010;
                3'b010: alu_op = 4'b0011;
                3'b011: alu_op = 4'b0100;
                3'b100: alu_op = 4'b0101;
                3'b101: begin // SRL/SRA
                    if(funct7 == 7'b0) begin
                        alu_op = 4'b0110;
                    end
                    else begin
                        alu_op = 4'b0111;
                    end
                end
                3'b110: alu_op = 4'b1000;
                3'b111: alu_op = 4'b1001;
            endcase 
        end
        default: alu_op = 4'b0000;        // Fallback is just ADD   
    endcase
end

endmodule