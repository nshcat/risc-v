module uart_baud_tick(
    input clk,
    input reset,
    output baud_tick
);

// We are oversampling with a counter to 16.
// Target baud rate is 9600. 16*9600 = 153600
// 16_500_000 Hz / 153600 ~= 108
localparam [7:0] counter_thres = 8'd108;

reg [7:0] baud_counter;

always @(posedge clk or negedge reset) begin
    if(!reset) begin
        baud_counter <= 8'h0; 
    end
    else begin
        if(baud_counter == counter_thres) begin
            baud_counter <= 8'h0;
        end
        else begin
            baud_counter <= baud_counter + 8'h1;
        end
    end
end

assign baud_tick = (baud_counter == counter_thres);


endmodule