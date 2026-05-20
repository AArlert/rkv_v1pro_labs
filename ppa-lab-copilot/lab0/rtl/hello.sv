module hello (
    input  logic clk,
    input  logic rst_n,
    output logic [7:0] data_out
);
    always_ff @(posedge clk or negedge rst_n) begin : hello_process
        if (!rst_n) begin
            data_out <= 8'b0;
        end else begin
            data_out[0] <= 0;
            data_out[1] <= 1;
            data_out[2] <= 0;
            data_out[3] <= 1;
            data_out[4] <= 0;
            data_out[5] <= 1;
            data_out[6] <= 0;
            data_out[7] <= 1;
        end
    end
endmodule