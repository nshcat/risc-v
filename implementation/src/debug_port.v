module debug_port(
    input clk,      
    input reset,            // System reset

    input uart_rx,          // UART receive pin
    output uart_tx,         // UART transmit pin

    output ds_cpu_halt,     // Debug signal that halts CPU execution (active high)
    output ds_cpu_reset,     // Debug signal that resets the CPU (active low)

    // Bus master interface
    output [31:0] dbg_address,
    output [31:0] dbg_write_data,
    output [1:0] dbg_reqw,
    output [1:0] dbg_mode,
    output dbg_reqs,
    input [31:0] dbg_read_data,
    output dbg_stall_lw,


    // The current PC
    input [31:0] dbg_pc
);

// ==== State machine handling
parameter STATE_IDLE = 6'h0;
parameter STATE_RCV_COMMAND_1 = 6'h1; // Receiving first command char
parameter STATE_RCV_COMMAND_2 = 6'h2; // Receiving second command char
parameter STATE_SEND_RESPONSE = 6'h3; // Receiving second command char
parameter STATE_RCV_MEM_ADR = 6'h4; // Receiving source address for memory read/write command
parameter STATE_MR_PH1 = 6'h5; // Doing memory read, phase 1
parameter STATE_MR_PH2 = 6'h6; // Doing memory read, phase 2
parameter STATE_RCV_MW_VAL = 6'h7; // Receiving value for memory read command
parameter STATE_MW = 6'h8; // Executing memory write operation





parameter MEM_OP_READ = 1'h0;   // Memory access types used to make reusing of STATE_RCV_MEM_ADR
parameter MEM_OP_WRITE = 1'h1;  // Functionality possible. The state after address receive (MW/MR)
                                // is remembered to be transitioned to after address receive completes.

reg mem_op, next_mem_op;

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        mem_op <= MEM_OP_READ;
    end
    else begin
        mem_op <= next_mem_op;
    end
end




reg halted, next_halted;
reg [5:0] current_state;
reg [5:0] next_state;

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        current_state <= STATE_IDLE;
        halted <= 1'b0;
    end
    else begin
        current_state <= next_state;
        halted <= next_halted;
    end
end


// ==== Registers
reg [7:0] data, next_data;

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        data <= 8'h0;
    end
    else begin
        data <= next_data;
    end
end

reg [15:0] command, next_command;           // Command code
reg [31:0] address, next_address;           // Data bus address argument
reg[1:0] address_byte, next_address_byte;   // Which address byte is currently being received

reg [31:0] value, next_value;           // Data bus write value argument
reg[1:0] value_byte, next_value_byte;   // Which write value byte is currently being received

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        command <= 16'h0;
        address <= 32'h0;
        address_byte <= 2'h0;
        value <= 32'h0;
        value_byte <= 2'h0;
    end
    else begin
        command <= next_command;
        address <= next_address;
        address_byte <= next_address_byte;
        value <= next_value;
        value_byte <= next_value_byte;
    end
end

reg start_tx, next_start_tx;
reg [7:0] response [5:0];
reg [7:0] next_response [5:0];
reg [2:0] response_pos, next_response_pos, response_size, next_response_size;

integer i;
always @(posedge clk or negedge reset) begin
    if(!reset) begin
        for (i = 0; i < 6; i++) begin
            response[i] <= 8'h0;
        end

        response_pos <= 3'h0;
        response_size <= 3'h0;

        start_tx <= 1'b0;
    end
    else begin
        for (i = 0; i < 6; i++) begin
            response[i] <= next_response[i];
        end

        response_pos <= next_response_pos;
        response_size <= next_response_size;

        start_tx <= next_start_tx;
    end
end

// ==== State Machine logic
always @(*) begin
    // Defaults to avoid latches
    next_state = current_state;
    next_data = 8'h0;
    next_mem_op = mem_op;
    next_command = command;
    next_address = address;
    next_response_pos = response_pos;
    next_response_size = response_size;
    next_address_byte = address_byte;
    next_halted = halted;
    next_value = value;
    next_value_byte = value_byte;
    next_start_tx = 1'b0; // Turns off start tx strobe after its been on

    for (i = 0; i < 6; i++) begin
        next_response[i] = response[i];
    end

    // FSM Logic
    case(current_state)
        STATE_IDLE: begin
            // Did we receive anything?
            if(rx_done) begin
                // Is it the start of a command?
                if(rx_data == "+") begin
                    next_state = STATE_RCV_COMMAND_1;
                end
            end
        end

        STATE_RCV_COMMAND_1: begin
            // Did we receive anything?
            if(rx_done) begin
                // Store it
                next_command = { rx_data, 8'h0 };
                next_state = STATE_RCV_COMMAND_2;
            end
        end

        STATE_RCV_COMMAND_2: begin
            // Did we receive anything?
            if(rx_done) begin
                // Store it
                next_command = { command[15:8], rx_data };
                
                case(next_command)
                    "HL": begin // Halt execution
                        next_halted = 1'b1;
                        next_response_pos = 3'h0;
                        next_response_size = 3'd2;
                        next_response[0] = "O";
                        next_response[1] = "K";
                        next_state = STATE_SEND_RESPONSE;
                        next_start_tx = 1'b1; // Already start transmitting first byte
                    end

                    "RE": begin // Resume execution
                        next_halted = 1'b0;
                        next_response_pos = 3'h0;
                        next_response_size = 3'd2;
                        next_response[0] = "O";
                        next_response[1] = "K";
                        next_state = STATE_SEND_RESPONSE;
                        next_start_tx = 1'b1; // Already start transmitting first byte
                    end

                    "PC": begin // Retrieve current PC
                        next_response_pos = 3'h0;
                        next_response_size = 3'd6;
                        next_response[0] = "O";
                        next_response[1] = "K";
                        next_response[2] = dbg_pc[31:24];
                        next_response[3] = dbg_pc[23:16];
                        next_response[4] = dbg_pc[15:8];
                        next_response[5] = dbg_pc[7:0];
                        next_state = STATE_SEND_RESPONSE;
                        next_start_tx = 1'b1; // Already start transmitting first byte
                    end

                    "ST": begin // Retrieve current CPU execution state
                        next_response_pos = 3'h0;
                        next_response_size = 3'd3;
                        next_response[0] = "O";
                        next_response[1] = "K";
                        next_response[2] = (halted ? "H" : "R");
                        next_state = STATE_SEND_RESPONSE;
                        next_start_tx = 1'b1; // Already start transmitting first byte
                    end

                    "MR": begin // Memory read
                        next_address_byte = 2'd0;
                        next_mem_op = MEM_OP_READ;
                        next_state = STATE_RCV_MEM_ADR;
                    end

                    "MW": begin // Memory write
                        next_address_byte = 2'd0;
                        next_mem_op = MEM_OP_WRITE;
                        next_state = STATE_RCV_MEM_ADR;
                    end

                    default: begin
                        next_response_pos = 3'h0;
                        next_response_size = 3'd2;
                        next_response[0] = "N";
                        next_response[1] = "O";
                        next_state = STATE_SEND_RESPONSE;
                        next_start_tx = 1'b1; // Already start transmitting first byte
                    end
                endcase
            end
        end

        STATE_RCV_MW_VAL: begin
            // Is another byte ready?
            if(rx_done) begin
                next_value_byte = value_byte + 2'd1;

                case(value_byte)
                    2'd0: begin
                        next_value = { rx_data, 24'h0 };
                    end
                    2'd1: begin
                        next_value = { value[31:24], rx_data, 16'h0 };
                    end
                    2'd2: begin
                        next_value = { value[31:16], rx_data, 8'h0 };
                    end
                    2'd3: begin
                        next_value = { value[31:8], rx_data };

                        // Are we actually allowed to perform a memory operation right now?
                        // We only have control over the data bus if the CPU is currently halted.
                        if(halted) begin
                            next_state = STATE_MW;
                        end
                        else begin 
                            // Send an error message, doing a memory write is not allowed right now. We don't
                            // Have control over the data bus while the CPU is running.
                            next_response_pos = 3'h0;
                            next_response_size = 3'd2;
                            next_response[0] = "N";
                            next_response[1] = "O";
                            next_state = STATE_SEND_RESPONSE;
                            next_start_tx = 1'b1; // Already start transmitting first byte
                        end
                    end
                endcase
            end
        end

        STATE_RCV_MEM_ADR: begin
            if(rx_done) begin
                next_address_byte = address_byte + 2'd1;

                case(address_byte)
                    2'd0: begin
                        next_address = { rx_data, 24'h0 };
                    end
                    2'd1: begin
                        next_address = { address[31:24], rx_data, 16'h0 };
                    end
                    2'd2: begin
                        next_address = { address[31:16], rx_data, 8'h0 };
                    end
                    2'd3: begin
                        next_address = { address[31:8], rx_data };

                        // Is the received address part of a memory write operation?
                        // If so, we can't yet fail if the CPU is not halted, since the debugger
                        // will still send the new memory value.
                        if(mem_op == MEM_OP_WRITE) begin
                            // Begin receiving the value to write to the requested memory location
                            next_value_byte = 2'h0;
                            next_state = STATE_RCV_MW_VAL;
                        end
                        // Check if CPU is halted, since otherwise we have no control over the bus
                        else if(halted) begin
                            next_state = STATE_MR_PH1;
                        end
                        else begin 
                            // Send an error message, doing a memory read is not allowed right now. We don't
                            // Have control over the data bus while the CPU is running.
                            next_response_pos = 3'h0;
                            next_response_size = 3'd2;
                            next_response[0] = "N";
                            next_response[1] = "O";
                            next_state = STATE_SEND_RESPONSE;
                            next_start_tx = 1'b1; // Already start transmitting first byte
                        end
                    end
                endcase     
            end
        end

        STATE_MR_PH1: begin // Debug bus signals are assigned below when this state is active
            next_state = STATE_MR_PH2;
        end

        STATE_MR_PH2: begin
            next_response_pos = 3'h0;
            next_response_size = 3'd6;
            next_response[0] = "O";
            next_response[1] = "K";
            next_response[2] = dbg_read_data[31:24];
            next_response[3] = dbg_read_data[23:16];
            next_response[4] = dbg_read_data[15:8];
            next_response[5] = dbg_read_data[7:0];
            next_state = STATE_SEND_RESPONSE;
            next_start_tx = 1'b1; // Already start transmitting first byte
        end

        STATE_MW: begin // The bus control signals for performing the actual write are done combinationally below
            next_response_pos = 3'h0;
            next_response_size = 3'd2;
            next_response[0] = "O";
            next_response[1] = "K";
            next_state = STATE_SEND_RESPONSE;
            next_start_tx = 1'b1; // Already start transmitting first byte
        end

        STATE_SEND_RESPONSE: begin
            if(tx_done) begin
                // Are we already done?
                if(response_pos >= response_size - 1) begin
                    next_start_tx = 1'b0;
                    next_state = STATE_IDLE;
                end
                else begin
                    // Otherwise continue sending the contents of the response buffer
                    next_start_tx = 1'b1;
                    next_response_pos = response_pos + 3'h1;
                end
            end
        end

        default: begin
            // Do nothings
        end
    endcase
end


// ==== UART
uart_baud_tick tick_gen(
    .clk(clk),
    .reset(reset),
    .baud_tick(baud_tick)
);


// == Transmitting
wire [7:0] tx_data = response[response_pos];
wire tx_start = start_tx;
wire tx_done;
wire baud_tick;

uart_tx utx(
    .clk(clk),
    .reset(reset),
    .baud_tick(baud_tick),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .tx_done_tick(tx_done),
    .tx(uart_tx)
);

// == Receiving
wire [7:0] rx_data;
wire rx_done;
wire rx_synced;

uart_rx urx(
    .clk(clk),
    .reset(reset),
    .baud_tick(baud_tick),
    .rx_done_tick(rx_done),
    .rx_data(rx_data),
    .rx(rx_synced)
);

synchronizer
#(.WIDTH(1), .DEPTH(3))
sync(
    .clk(clk),
    .reset(reset),
    .in(uart_rx),
    .out(rx_synced)
);

// ==== Debug signal generation
assign ds_cpu_reset = 1'b1;
assign ds_cpu_halt = halted;

// ==== Debug bus master control signal generation
assign dbg_address = address;
assign dbg_mode = ((current_state == STATE_MR_PH1 || current_state == STATE_MR_PH2) ? 2'b01 : ((current_state == STATE_MW) ? 2'b10 : 2'b00));
assign dbg_reqs = 1'h0;
assign dbg_reqw = 2'h0;
assign dbg_write_data = value;
assign dbg_stall_lw = (current_state == STATE_MR_PH1);

endmodule