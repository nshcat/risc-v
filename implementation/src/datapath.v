module datapath(
    input clk,
    input reset,
    
    // Whether the core is currently in the first clock cylce of a LW stall
    output stall_lw,

    // Data bus
    inout [31:0] data_bus_data,
    output [31:0] data_bus_addr,
    output [1:0] data_bus_mode,
    output [1:0] data_bus_reqw,
    output data_bus_reqs,

    // Instruction bus
    output [31:0] instr_bus_addr,
    input [31:0] instr_bus_data,

    // Interrupts signals
    input [3:0] irq_sources
);

// ==== First Cycle Detection ====
reg first_cycle;

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        first_cycle <= 1'b1;
    end
    else begin
        first_cycle <= 1'b0;
    end
end

// ==== Interrupt Management ====
reg in_isr;                 // Whether the CPU is currently inside a ISR
reg [31:0] ipc;             // Interrupt process counter, used to restore program counter after IRQ

wire [3:0] irq_mask;
wire [31:0] irq_target;

reg [3:0] stalled_irq_sample;   // Saved IRQ sample from first half of stalled LW instruction

// This is a combination of both the current IRQ sources and the stored IRQs sampled
// in the first cycle of a stalled LW instruction.
wire [3:0] combined_irq_sources = irq_sources & stalled_irq_sample;

interrupt_controller irq_cu(
    .clk(clk),
    .reset(reset),
    .data_bus_data(data_bus_data),
    .data_bus_mode(data_bus_mode),
    .data_bus_addr(data_bus_addr),
    .irq_sources(irq_sources),
    .irq_mask(irq_mask),
    .irq_target(irq_target)
);

// ==== Process counter and related ==== 
reg [31:0] pc;              // The current program counter
wire [31:0] pc4 = pc + 4;   // PC + 4
wire [31:0] pc_next;        // Value for next PC, not affected by interrupts
wire [31:0] pc_next_final;  // Value for next PC, affected by interrupts
wire will_enter_isr = (((~combined_irq_sources & irq_mask) != 4'b0) && (in_isr == 1'b0)); // Whether we will enter an ISR

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

// Note: In previous versions of this core, all the PC-related interrupt handling logic was done in the
// sequential block below. But since switching to a sequential-read FLASH memory module, the final PC value
// has to be known before the clock edge, i.e. as part of a combinatorial circuit. Because of this,
// the final PC calculation has been refactored out into the function irq_logic below.

// Apply interrupt logic to pc_next
function [31:0] irq_logic();
    // Do nothing in first cycle
    if(first_cycle) begin
        irq_logic = 32'h0;
    end
    else begin  
        if(stall) begin // In a stall we keep the PC the same.
            irq_logic = pc;
        end
        else begin
            // If we are requested to end the current ISR, we need to restore the saved PC
            if(cs_end_isr) begin
                irq_logic = ipc;
            end
            else if(will_enter_isr) begin // When entering an ISR, the next PC is its address
                irq_logic = irq_target;
            end
            else begin // In all other cases pc_next is unaffected
                irq_logic = pc_next;
            end
        end
    end
endfunction

assign pc_next_final = irq_logic();


// Perform PC update and sequential IRQ logic
always @(posedge clk or negedge reset)
begin
    if(!reset) begin
        pc <= 32'd0;
        in_isr <= 1'b0;
        stalled_irq_sample <= 4'b1111;
    end
    else begin
        // In any case, update the PC with thew new value. This is already affected by interrupt logic.
        pc <= pc_next_final;

        // If the CPU is currently stalling in order to execute a multi-cycle instruction, we can not
        // allow interrupts to disrupt the current instruction execution.
        // We therefore save all incomming IRQs in a temporary storage to be acted
        // upon at a later stage.
        if (stall == 1'b1) begin
            // If we are stalling, we need to sample and store incomming IRQs
            // to handle them at the end of the stalled instruction
            stalled_irq_sample <= irq_sources;
        end
        else begin
            // Check if need to return from ISR
            if (cs_end_isr != 1'b0) begin
                in_isr <= 1'b0;
            end
            // Check if there was a IRQ
            else if (will_enter_isr) begin
                // Save original new PC for when we want to return from this ISR
                ipc <= pc_next;
                in_isr <= 1'b1;

                // Make sure the stored IRQ sample is reset so it won't continuously
                // fire interrupts. Not all of them might have been handled, 
                // but the one with the highest priority has been. 
                stalled_irq_sample <= 4'b1111;
            end
        end
    end
end

// ==== Stalling logic ====
wire stall;

assign stall_lw = stall & cs_stall_lw;

stall_unit su(
    .clk(clk),
    .reset(reset),
    .cs_stall_lw(cs_stall_lw),
    .stall(stall)
);


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

// ==== Instruction bus control unit ==== 
instruction_bus_control_unit ibcu(
    .clk(clk),
    .reset(reset),
    .next_pc(pc_next_final),
    .instr_bus_addr(instr_bus_addr),
    .instr_bus_data(instr_bus_data),
    .instruction(instruction)
);

// ==== Control Signals ====
wire cs_reg_write, cs_reg_1_zero, cs_alu_src, cs_bus_read, cs_bus_write;
wire cs_alu_shamt, cs_stall_lw, cs_end_isr;
wire [1:0] cs_alu_control, cs_branch_op, cs_mem_to_reg, cs_mem_width;
wire [2:0] cs_imm_src;
wire cs_load_signed;

control_unit cunit(
    .opcode(instr_opcode),
    .func3(instr_func3),
    .cs_reg_write(cs_reg_write),
    .cs_reg_1_zero(cs_reg_1_zero),
    .cs_alu_src(cs_alu_src),
    .cs_alu_control(cs_alu_control),
    .cs_mem_to_reg(cs_mem_to_reg),
    .cs_branch_op(cs_branch_op),
    .cs_bus_read(cs_bus_read),
    .cs_bus_write(cs_bus_write),
    .cs_imm_src(cs_imm_src),
    .cs_stall_lw(cs_stall_lw),
    .cs_end_isr(cs_end_isr),
    .cs_mem_width(cs_mem_width),
    .cs_load_signed(cs_load_signed)
);

// ==== Register File  ==== 
wire [31:0] write_data;

wire [4:0] read_reg_1 = (cs_reg_1_zero == 1'b1) ? 5'b0 : instr_rs1;

wire write_reg = cs_reg_write & ~stall;

register_file registers(
    .clk(clk),
    .reset(reset),
    .read_reg_1(read_reg_1),
    .read_reg_2(instr_rs2),
    .write_reg(instr_rd),
    .cs_reg_write(write_reg),
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

// ==== Data Bus Controller ====
wire [31:0] bus_result;

// Only read from bus in second cycle of stalled LW instruction.
// The first cycle is used to give peripherals time to prepare the load and
// present the data to the bus.
//wire read_bus = cs_bus_read & ~stall;

data_bus_control_unit dbcu(
    .cs_bus_read(cs_bus_read),
    .cs_bus_write(cs_bus_write),
    .cs_mem_width(cs_mem_width),
    .cs_load_signed(cs_load_signed),
    .addr_in(alu_out_result),
    .data_out(bus_result),
    .data_in(read_data_2),
    .data_bus_addr(data_bus_addr),
    .data_bus_data(data_bus_data),
    .data_bus_mode(data_bus_mode),
    .data_bus_reqw(data_bus_reqw),
    .data_bus_reqs(data_bus_reqs)
);



// ==== Write Back ====
assign write_data = (cs_mem_to_reg == 2'b10) ? pc4 : (cs_mem_to_reg == 2'b01 ? bus_result : alu_out_result);

endmodule

