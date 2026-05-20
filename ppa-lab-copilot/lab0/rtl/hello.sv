module hello (
    input  logic clk,
    input  logic rst_n,
    output logic [7:0] data_out
);
    always_ff @(posedge clk or negedge rst_n) begin : hello_process
        if (!rst_n) begin
            data_out <= 8'b0;
        end else begin
            for (int i = 0; i < 8; i++) begin
                data_out[i] <= i;
            end
        end
    end
endmodule