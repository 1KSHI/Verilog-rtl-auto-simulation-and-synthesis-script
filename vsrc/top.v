module top(
    input clk,
    input rst,
    output reg [3:0]counter
);

always@(posedge clk)begin
    if(rst)begin
        counter <= 0;
    end
    else begin
        counter <= counter + 1;
    end
end

endmodule