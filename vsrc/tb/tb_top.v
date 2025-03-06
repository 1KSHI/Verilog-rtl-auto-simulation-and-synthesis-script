module tb_top();
reg clk, rst;
wire counter;

top uut(
    .clk(clk),
    .rst(rst),
    .counter(counter)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    rst = 1;
    #10;
    rst = 0;
    #100;
    $finish;
end

endmodule
