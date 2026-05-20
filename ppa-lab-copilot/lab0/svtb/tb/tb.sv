module tb;
    reg clk;
    reg rst_n;
    reg [7:0] data_out;
    
    hello uut (
        .clk(clk),
        .rst_n(rst_n),
        .data_out(data_out)
    );

    initial begin
        forever #5 clk = ~clk; // Continue toggling clock indefinitely
    end

    initial begin
        clk = 0;
        rst_n = 0;

        #10 rst_n = 1; // Release reset after 10 time units
    end

endmodule