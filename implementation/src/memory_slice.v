// 2K of RAM organized in words, with accessible bytes and halfwords
module memory_slice (
        input clk, wen, ren,
        input [1:0] width_mode,
        input signed_mode,
        input [10:0] addr,		// Full adress relative to begin of slice, byte-addressed
        input [31:0] wdata,
        output reg [31:0] rdata
);

parameter WORD = 2'b00;
parameter HALF_WORD = 2'b01;
parameter BYTE = 2'b10;

parameter SIGNED = 1'b1;
parameter UNSIGNED = 1'b0;

// The address of a single byte, for use in byte addressing mode
wire [1:0] byte_address = addr[1:0];
// The address of a full word inside this slice.
wire [8:0] word_address = addr[10:2];

// Final read results. These only have to be connected to the output rdata in the end.
reg [31:0] read_word;
reg [15:0] read_half;
reg [7:0] read_byte;

// Generate all four blocks that make up one word. Note that we are storing the word in little endian;
// This means that the first block stores the lowest byte, not the highest.
genvar i;
for(i = 0; i < 4; i++) begin : blocks
	wire [7:0] read_result;
	reg [7:0] write_data;
	reg write_enable;

	memory_block inst(
		.clk(clk),
		.addr(word_address),
		.rdata(read_result),
		.ren(ren),	// If we are reading, we always read the whole vertical slice (all four bytes). We just discard what we dont use.
		.wen(write_enable),
		.wdata(write_data)
	);
end

always @(*) begin
	if(ren) begin
		case (width_mode)
			WORD: begin
				read_word = { blocks[3].read_result, blocks[2].read_result, blocks[1].read_result, blocks[0].read_result }; // Beware: Little Endian!
				rdata = read_word;
				
				read_half = 16'h0;
				read_byte = 8'h0;
			end
			BYTE: begin
				// We need to read a single byte. Which one exactly?
				case (byte_address)
					2'b00: read_byte = blocks[0].read_result; // Lowest Byte (we are little endian!)
					2'b01: read_byte = blocks[1].read_result; 
					2'b10: read_byte = blocks[2].read_result; 
					2'b11: read_byte = blocks[3].read_result; // Highest Byte
				endcase
				
				// If we are operating in signed mode, we have to sign-extend the loaded byte.
				if(signed_mode == SIGNED) begin
					rdata = { (read_byte[7]) ? 24'hFFFFFF : 24'h0, read_byte };
				end
				else begin
					rdata = { 24'h0, read_byte };
				end
				
				
				read_half = 16'h0;
				read_word = 32'h0;
			end
			/*HALF_WORD:*/default: begin
				// For half words, there could be issues with loads crossing word boundaries. We do not allow this here!
				// Later, we could throw an exception/fault in that case. For now, we do nothing.
				case (byte_address)
					2'b00: begin
						// | FF FF FF FF |
						// | { h }       |
						// We load the first half word. Since we are little endian, we have to reverse the order again.
						read_half = { blocks[1].read_result, blocks[0].read_result };
					end
					2'b01: begin
						// | FF FF FF FF |
						// |    { h }    |
						// We load the half word that crosses the mid-point.
						read_half = { blocks[2].read_result, blocks[1].read_result };
					end
					2'b10: begin
						// | FF FF FF FF |
						// |       { h } |
						// We load the second half word.
						read_half = { blocks[3].read_result, blocks[2].read_result };
					end
					2'b11: begin
						// | FF FF FF FF | FF FF FF FF |
						// |          {  h  }          |
						// Load attempt on a half word that crosses a word-boundary.
						// We silently judge the programmer for being a jerk, and return zero.
						read_half = 16'h0;
					end
				endcase		
				
				// If we are operating in signed mode, we have to sign-extend the loaded half-word.
				if(signed_mode == SIGNED) begin
					rdata = { (read_half[15]) ? 16'hFFFF : 16'h0, read_half };
				end
				else begin
					rdata = { 16'h0, read_half };
				end
				
				read_word = 32'h0;
				read_byte = 8'h0;
			end
		endcase
		
		// Make sure to set all combinatorial wires in order to avoid latches
		blocks[0].write_enable = 1'b0;
		blocks[1].write_enable = 1'b0;
		blocks[2].write_enable = 1'b0;
		blocks[3].write_enable = 1'b0;
		
		blocks[0].write_data = 8'h0;
		blocks[1].write_data = 8'h0;
		blocks[2].write_data = 8'h0;
		blocks[3].write_data = 8'h0;
	end
	else if(wen) begin
		case (width_mode)
			WORD: begin
				// Writing a whole word is easy. We write to all blocks.
				blocks[0].write_enable = 1'b1;
				blocks[1].write_enable = 1'b1;
				blocks[2].write_enable = 1'b1;
				blocks[3].write_enable = 1'b1;
				
				// Careful: Little endian!
				blocks[0].write_data = wdata[7:0];
				blocks[1].write_data = wdata[15:8];
				blocks[2].write_data = wdata[23:16];
				blocks[3].write_data = wdata[31:24];
			end
			BYTE: begin
				// We need to write a single byte. Which one exactly?
				case (byte_address)
					2'b00: begin // Lowest Byte
						blocks[0].write_enable = 1'b1;
						blocks[0].write_data = wdata[7:0];
						
						// Disable write to other blocks
						blocks[1].write_enable = 1'b0;
						blocks[2].write_enable = 1'b0;
						blocks[3].write_enable = 1'b0;
						blocks[1].write_data = 8'h0;
						blocks[2].write_data = 8'h0;
						blocks[3].write_data = 8'h0;
					end
					2'b01: begin
						blocks[1].write_enable = 1'b1;
						blocks[1].write_data = wdata[7:0];
						
						// Disable write to other blocks
						blocks[0].write_enable = 1'b0;
						blocks[2].write_enable = 1'b0;
						blocks[3].write_enable = 1'b0;
						blocks[0].write_data = 8'h0;
						blocks[2].write_data = 8'h0;
						blocks[3].write_data = 8'h0;
					end
					2'b10: begin
						blocks[2].write_enable = 1'b1;
						blocks[2].write_data = wdata[7:0];
						
						// Disable write to other blocks
						blocks[0].write_enable = 1'b0;
						blocks[1].write_enable = 1'b0;
						blocks[3].write_enable = 1'b0;
						blocks[0].write_data = 8'h0;
						blocks[1].write_data = 8'h0;
						blocks[3].write_data = 8'h0;
					end
					2'b11: begin
						blocks[3].write_enable = 1'b1;
						blocks[3].write_data = wdata[7:0];
						
						// Disable write to other blocks
						blocks[0].write_enable = 1'b0;
						blocks[1].write_enable = 1'b0;
						blocks[2].write_enable = 1'b0;
						blocks[0].write_data = 8'h0;
						blocks[1].write_data = 8'h0;
						blocks[2].write_data = 8'h0;
					end 
				endcase
			end
			/*HALF_WORD:*/ default: begin
				// For half words, there could be issues with loads crossing word boundaries. We do not allow this here!
				// Later, we could throw an exception/fault in that case. For now, we do nothing.
				case (byte_address)
					2'b00: begin
						// | FF FF FF FF |
						// | { h }       |
						// We write to the first half-word.
						blocks[0].write_enable = 1'b1;
						blocks[0].write_data = wdata[7:0];
						blocks[1].write_enable = 1'b1;
						blocks[1].write_data = wdata[15:8];
						
						// Disable write to other blocks
						blocks[2].write_enable = 1'b0;
						blocks[3].write_enable = 1'b0;
						blocks[2].write_data = 8'h0;
						blocks[3].write_data = 8'h0;
					end
					2'b01: begin
						// | FF FF FF FF |
						// |    { h }    |
						// We write to the half word that crosses the mid-point.
						blocks[1].write_enable = 1'b1;
						blocks[1].write_data = wdata[7:0];
						blocks[2].write_enable = 1'b1;
						blocks[2].write_data = wdata[15:8];
						
						// Disable write to other blocks
						blocks[0].write_enable = 1'b0;
						blocks[3].write_enable = 1'b0;
						blocks[0].write_data = 8'h0;
						blocks[3].write_data = 8'h0;
					end
					2'b10: begin
						// | FF FF FF FF |
						// |       { h } |
						// We write to the second half word.
						blocks[2].write_enable = 1'b1;
						blocks[3].write_data = wdata[7:0];
						blocks[2].write_enable = 1'b1;
						blocks[3].write_data = wdata[15:8];
						
						// Disable write to other blocks
						blocks[0].write_enable = 1'b0;
						blocks[1].write_enable = 1'b0;
						blocks[0].write_data = 8'h0;
						blocks[1].write_data = 8'h0;
					end
					2'b11: begin
						// | FF FF FF FF | FF FF FF FF |
						// |          {  h  }          |
						// Write attempt to a half word that crosses a word-boundary.
						// We silently judge the programmer for being a jerk, and do nothing.
						blocks[0].write_enable = 1'b0;
						blocks[1].write_enable = 1'b0;
						blocks[2].write_enable = 1'b0;
						blocks[3].write_enable = 1'b0;
						
						blocks[0].write_data = 8'h0;
						blocks[1].write_data = 8'h0;
						blocks[2].write_data = 8'h0;
						blocks[3].write_data = 8'h0;
					end
				endcase
			end
		endcase
		
		read_word = 32'h0;
		read_half = 16'h0;
		read_byte = 8'h0;
		rdata = 32'h0;
	end
	else begin
		blocks[0].write_enable = 1'b0;
		blocks[1].write_enable = 1'b0;
		blocks[2].write_enable = 1'b0;
		blocks[3].write_enable = 1'b0;
		
		blocks[0].write_data = 8'h0;
		blocks[1].write_data = 8'h0;
		blocks[2].write_data = 8'h0;
		blocks[3].write_data = 8'h0;

		read_word = 32'h0;
		read_half = 16'h0;
		read_byte = 8'h0;
		rdata = 32'h0;
	end
end

endmodule
