module top(
  input clk,
  output [7:0] leds
);

reg [1:0] counter;
initial counter = 2'b0;

wire reset = (counter < 2'b0) || (counter == 2'b11);

always @(posedge clk) begin
	if(counter != 2'b11) begin
		counter <= counter + 2'b1;
	end
end

wire [15:0] gpio_a;
wire tim1_cmp, tim2_cmp;
reg int;
initial int = 1'b1;

microcontroller mc(
  .clk(clk),
  .reset(reset),
  .leds_out(leds),
  .int_ext1(int),
  .int_ext2(int),
  .tim1_cmp(tim1_cmp),
  .tim2_cmp(tim2_cmp),
  .gpio_port_a(gpio_a)
);

endmodule		 

   
  
