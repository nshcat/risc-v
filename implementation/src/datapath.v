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
// The following registers were originally meant to be part of a separate submodule called the
// interrupt control unit, but having them right inside the datapath module makes the interrupt
// logic much easier to implement.
reg icu_in_isr;                 // Whether the CPU is currently inside a ISR
reg [31:0] icu_ipc;             // Interrupt process counter, used to restore program counter after IRQ

reg [3:0] icu_irq_mask;         // Address: 0x4000 IRQ mask used to enable and disable interrupt handling for certain sources
reg [3:0] icu_irq_flags;        // Address: 0x4004 Main IRQ flags register.
                                // A set flag represents an interrupt request. ISRs have to clear the flags.
reg [3:0] icu_active_irq;       // Address: 0x4008 Which IRQ is currently being handled (stored as index in binary, not as a flag)

wire [3:0] icu_new_irq_flags;   // The new value of irq flags: Sampled and already set flags combined. This is required since we want to do
                                // a lot of actions on a single clock edge. All IRQ decisions should be based on this value, since it already
                                // includes the newest IRQ source sample.

assign icu_new_irq_flags = icu_irq_flags | ~(irq_sources);  // Sample combinatorially     

wire [3:0] icu_irq_flags_masked = icu_new_irq_flags & icu_irq_mask; // Masked off IRQ flags
wire icu_triggered = (icu_irq_flags_masked != 4'h0) && !icu_in_isr && !stall; // Whether an interrupt handling sequence was triggered. Note that interrupts are not triggered when stalled

// The decimal index of the next triggered ISR. This will only hold a valid value if an IRQ was actually triggered.
function [3:0] icu_triggered_isr();
    casez (icu_irq_flags_masked)
        4'b???1: icu_triggered_isr = 4'h0;
        4'b??10: icu_triggered_isr = 4'h1;
        4'b?100: icu_triggered_isr = 4'h2;
        4'b1000: icu_triggered_isr = 4'h3;
        default: icu_triggered_isr = 4'h0;
    endcase
endfunction


// == ICU synchronized logic
wire in_read_space = (data_bus_addr >= 32'h4000) && (data_bus_addr <= 32'h4008);
wire in_write_space = (data_bus_addr >= 32'h4000) && (data_bus_addr <= 32'h4004);
wire read_requested = (data_bus_mode == 2'b01) && in_read_space;
wire write_requested = (data_bus_mode == 2'b10) && in_write_space;
assign data_bus_data = read_requested ? bus_read() : 32'bz;

function [31:0] bus_read();
    case (data_bus_addr)
        32'h4000: bus_read = { 28'h0, icu_irq_mask };
        32'h4004: bus_read = { 28'h0, icu_irq_flags };
        default: bus_read = { 28'h0, icu_active_irq };
    endcase
endfunction

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        icu_irq_mask <= 4'b0000;
        icu_irq_flags <= 4'b0000;
        icu_active_irq <= 4'b0000;
        icu_in_isr <= 1'b0;
    end
    else begin
        if(write_requested) begin
            case (data_bus_addr) // TODO in this case, we still need to sample!
                32'h4000: icu_irq_mask <= data_bus_data[3:0];
                default: icu_irq_flags <= data_bus_data[3:0];
            endcase
        end
        else begin
            // Sample
            icu_irq_flags <= icu_new_irq_flags;

            // Should we trigger an interrupt handler?
            if(icu_triggered) begin
                icu_ipc <= pc_next;
                icu_in_isr <= 1'b1;
                icu_active_irq <= icu_triggered_isr();
            end
            // Handle ISR return via RETI
            else if (icu_in_isr && cs_end_isr != 1'b0) begin
                icu_in_isr <= 1'b0;
            end
        end
    end
end
// == 

// ==== Process counter and related ==== 
reg [31:0] pc;              // The current program counter
wire [31:0] pc4 = pc + 4;   // PC + 4
wire [31:0] pc_next;        // Value for next PC, not affected by interrupts
wire [31:0] pc_next_final;  // Value for next PC, affected by interrupts

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
                irq_logic = icu_ipc;
            end
            else if(icu_triggered) begin // When entering an ISR, the next PC is its address
                irq_logic = 32'h10;
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
    end
    else begin
        // In any case, update the PC with thew new value. This is already affected by interrupt logic and stalling.
        pc <= pc_next_final;
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
wire cs_reg_write, cs_reg_1_zero, cs_alu_src, cs_bus_read, cs_bus_write, cs_alu_pc;
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
    .cs_load_signed(cs_load_signed),
    .cs_alu_pc(cs_alu_pc)
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
wire [31:0] alu_input_2 = (cs_alu_shamt == 1'b0) ? alu_input_2_before_shamt : { 27'h0, instr_shamt };
wire [31:0] alu_input_2_before_shamt = (cs_alu_src == 1'b0) ? read_data_2 : instr_imm;

wire [31:0] alu_input_1 = (cs_alu_pc == 1'b0) ? read_data_1 : pc;

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
    .a(alu_input_1),
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

