`define CONTROL_SIGNALS(imm_src, reg_write, reg_1_zero, alu_src, alu_pc, alu_control, mem_to_reg, branch_op, bus_read, bus_write, end_isr) \
    begin   \
        cs_imm_src      = imm_src; \
        cs_reg_write    = reg_write; \
        cs_reg_1_zero   = reg_1_zero; \
        cs_alu_src      = alu_src; \
        cs_alu_control  = alu_control; \
        cs_mem_to_reg   = mem_to_reg; \
        cs_branch_op    = branch_op; \
        cs_bus_read     = bus_read; \
        cs_bus_write    = bus_write; \
        cs_end_isr      = end_isr; \
        cs_alu_pc       = alu_pc; \
    end



// The main control unit. Generates the majority of control signals based on the current
// instruction opcode.
module control_unit(
    input [6:0] opcode,                // The instructions opcode
    input [2:0] func3,                 // Func3 field from instruction
    output reg [2:0] cs_imm_src,       // Determines how the immediate value is constructed from the instruction
    output reg cs_reg_write,           // Toggles register file write
    output reg cs_reg_1_zero,          // Causes source register 1 to be hard-wired to zero register $0
    output reg cs_alu_src,             // Toggles between register file output 2 and the 16 it imm from the instruction
    output reg cs_alu_pc,              // Selects between register read data 1 and the current PC for ALU input A
    output reg [1:0] cs_alu_control,   // Determines how the ALU control unit determines the ALU mode
    output reg [1:0] cs_mem_to_reg,    // Selects write data input for register file
    output reg [1:0] cs_branch_op,     // Branching operation
    output reg cs_bus_read,            // Causes a data bus read operation
    output reg cs_bus_write,           // Causes a data bus write operation
    output reg cs_stall_lw,            // Whether we need to stall because of a memory load
    output reg cs_end_isr,             // Causes a return from ISR
    output reg [1:0] cs_mem_width,     // Width of memory operation (word, half word, byte)
    output reg cs_load_signed          // Whether loaded value should be sign-extended (affects only half word and byte loads)
);

always @(opcode) begin
    case(opcode)                  // ImmSrc  RegWrite Reg1Zero ALUSrc ALUPc  ALUControl  MemToReg BranchOp  BusRead BusWrite EndISR
        7'b0110011: `CONTROL_SIGNALS(3'b000,  1'b1,    1'b0,    1'b0,  1'b0,  2'b11,      2'b00,   2'b00,   1'b0,   1'b0,    1'b0   ) // ArithR
        7'b0010011: `CONTROL_SIGNALS(3'b001,  1'b1,    1'b0,    1'b1,  1'b0,  2'b10,      2'b00,   2'b00,   1'b0,   1'b0,    1'b0   ) // ArithI/ShI
        7'b1100011: `CONTROL_SIGNALS(3'b011,  1'b0,    1'b0,    1'b0,  1'b0,  2'b01,      2'b00,   2'b01,   1'b0,   1'b0,    1'b0   ) // CondBR
        7'b1101111: `CONTROL_SIGNALS(3'b100,  1'b1,    1'b1,    1'b1,  1'b0,  2'b00,      2'b10,   2'b10,   1'b0,   1'b0,    1'b0   ) // JAL
        7'b1100111: `CONTROL_SIGNALS(3'b001,  1'b1,    1'b0,    1'b1,  1'b0,  2'b00,      2'b10,   2'b11,   1'b0,   1'b0,    1'b0   ) // JALR
        7'b0000011: `CONTROL_SIGNALS(3'b001,  1'b1,    1'b0,    1'b1,  1'b0,  2'b00,      2'b01,   2'b00,   1'b1,   1'b0,    1'b0   ) // LOAD
        7'b0100011: `CONTROL_SIGNALS(3'b010,  1'b0,    1'b0,    1'b1,  1'b0,  2'b00,      2'b00,   2'b00,   1'b0,   1'b1,    1'b0   ) // STORE
        7'b0110111: `CONTROL_SIGNALS(3'b000,  1'b1,    1'b1,    1'b1,  1'b0,  2'b00,      2'b00,   2'b00,   1'b0,   1'b0,    1'b0   ) // LUI
        7'b1111111: `CONTROL_SIGNALS(3'b000,  1'b0,    1'b0,    1'b0,  1'b0,  2'b00,      2'b00,   2'b00,   1'b0,   1'b0,    1'b1   ) // RETI (custom)
        7'b0010111: `CONTROL_SIGNALS(3'b000,  1'b1,    1'b0,    1'b1,  1'b1,  2'b00,      2'b00,   2'b00,   1'b0,   1'b0,    1'b0   ) // AUIPC
        default:    `CONTROL_SIGNALS(3'b000,  1'b0,    1'b0,    1'b0,  1'b0,  2'b00,      2'b00,   2'b00,   1'b0,   1'b0,    1'b0   ) // Treat other instructions as NOP
    endcase

    // The CPU needs to stall for one cycle when executing a LW instruction, since the data memory
    // uses synchronous read on the rising clock edge.
    cs_stall_lw = (opcode == 7'b0000011) ? 1'b1 : 1'b0;
        
    // Memory operation parameters
    cs_load_signed = (opcode == 7'b0000011) ? ~func3[2] : 1'b0;
    
    if (opcode == 7'b0000011 || opcode == 7'b0100011) begin
        case (func3[1:0])
            2'b00: cs_mem_width = 2'b10;
            2'b01: cs_mem_width = 2'b01;
            default: cs_mem_width = 2'b00;
        endcase
    end
    else begin
        cs_mem_width = 2'b00;
    end

end

endmodule