module datapath(
    input clk,
    input reset
);

// ==== Process counter and related ==== 
reg [31:0] pc;              // The current program counter
wire [31:0] pc4 = pc + 4;   // PC + 4
wire [31:0] pc_next;        // Value for next PC

branch_control_unit bcu(
    .cs_branch_op(cs_branch_op),
    .imm(instr_imm),
    .branch_type(instr_func3),
    .pc(pc),
    .Z(alu_out_zero),
    .N(alu_out_neg),
    .C(alu_out_carry),
    .S(alu_out_sign),
    .V(alu_out_signed_of),
    .read_data_1(read_data_1),
    .next_pc(pc_next)
);

always @(posedge clk or negedge reset)
begin
    if(!reset) begin
        pc <= 32'd0;
    end
    else begin
        pc <= pc_next;
    end
end


// ==== Instruction and parts ==== 
wire [31:0] instruction;
wire [6:0] instr_opcode = instruction[6:0];
wire [4:0] instr_rs1 = instruction[19:15];
wire [4:0] instr_rs2 = instruction[24:20];
wire [4:0] instr_rd = instruction[11:7];
wire [4:0] instr_shamt = instruction[24:20];
wire [2:0] instr_func3 = instruction[14:12];
wire [6:0] instr_func7 = instruction[31:25];

// ==== Imm Generation ====
wire [31:0] instr_imm;

imm_generator immgen(
    .instr(instruction),
    .cs_imm_source(cs_imm_src),
    .imm(instr_imm)
);


// ==== Program memory ==== 
program_memory pmem(.address(pc), .instruction(instruction));

// ==== Control Signals ====
wire cs_reg_write, cs_reg_1_zero, cs_alu_src, cs_bus_read, cs_bus_write;
wire cs_alu_shamt;
wire [1:0] cs_alu_control, cs_branch_op, cs_mem_to_reg;
wire [2:0] cs_imm_src;

control_unit cunit(
    .opcode(instr_opcode),
    .cs_reg_write(cs_reg_write),
    .cs_reg_1_zero(cs_reg_1_zero),
    .cs_alu_src(cs_alu_src),
    .cs_alu_control(cs_alu_control),
    .cs_mem_to_reg(cs_mem_to_reg),
    .cs_branch_op(cs_branch_op),
    .cs_bus_read(cs_bus_read),
    .cs_bus_write(cs_bus_write),
    .cs_imm_src(cs_imm_src)
);

// ==== Register File  ==== 
wire [31:0] write_data;

register_file registers(
    .clk(clk),
    .reset(reset),
    .read_reg_1(instr_rs1),
    .read_reg_2(instr_rs2),
    .write_reg(instr_rd),
    .cs_reg_write(cs_reg_write),
    .write_data(write_data),
    .read_data_1(read_data_1),
    .read_data_2(read_data_2)
);

wire [31:0] read_data_1;    // First output of register read
wire [31:0] read_data_2;    // Second output of register read

// ==== ALU ==== 
wire [31:0] alu_input_2 = (cs_alu_shamt == 1'b0) ? alu_input_2_before_shamt : {27'h0, instr_shamt };
wire [31:0] alu_input_2_before_shamt = (cs_alu_src == 1'b0) ? read_data_2 : instr_imm;

wire alu_out_zero;
wire alu_out_neg;
wire alu_out_sign;
wire alu_out_carry;
wire alu_out_signed_of;
wire [31:0] alu_out_result;

wire [3:0] alu_op;

alu_control main_alu_control(
    .cs_alu_control(cs_alu_control),
    .funct3(instr_func3),
    .funct7(instr_func7),
    .cs_alu_shamt(cs_alu_shamt),
    .alu_op(alu_op)
);

alu main_alu(
    .a(read_data_1),
    .b(alu_input_2),
    .result(alu_out_result),
    .Z(alu_out_zero),
    .N(alu_out_neg),
    .C(alu_out_carry),
    .S(alu_out_sign),
    .V(alu_out_signed_of),
    .alu_op(alu_op)
);

// ==== Write Back ====
assign write_data = (cs_mem_to_reg == 2'b10) ? pc4 : alu_out_result; 

endmodule

