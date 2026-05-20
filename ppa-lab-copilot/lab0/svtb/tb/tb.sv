module tb;
    reg clk;
    reg rst_n;
    wire [7:0] data_out;

    hello uut (
        .clk(clk),
        .rst_n(rst_n),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 0;
        #10 rst_n = 1;
        #100;
        $display("data_out = %0h", data_out);
        $finish;
    end

    initial begin
        $fsdbDumpfile("sim.fsdb");
        $fsdbDumpvars(0, tb);
    end

endmodule