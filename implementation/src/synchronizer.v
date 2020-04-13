module synchronizer(
    input clk,
    input reset,
    input [WIDTH-1:0] in,   // The signal comming from outside the clock domain
    output [WIDTH-1:0] out  // The synchronized signal
);

parameter WIDTH = 1;
parameter DEPTH = 2;

reg [WIDTH-1:0] stages [DEPTH-1:0];

genvar i;
generate 
    for(i = 0; i < DEPTH; i++) begin
        always @(posedge clk or negedge reset) begin
            if(!reset) begin
                stages[i] <= {(WIDTH){1'b0}};
            end
            else begin
                if(i == 0) begin
                    stages[i] <= in;
                end
                else begin
                    stages[i] <= stages[i-1];
                end
            end
        end
    end
endgenerate


assign out = stages[DEPTH - 1];


endmodule