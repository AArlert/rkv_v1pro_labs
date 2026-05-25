// lab3 集成 TB —— 复用 lab1 APB 任务，端到端驱动
`timescale 1ns/1ps

module tb_top;
    logic PCLK = 0, PRESETn;
    always #5 PCLK = ~PCLK;
    initial begin
        PRESETn = 0;
        repeat (4) @(posedge PCLK);
        PRESETn = 1;
    end

    // TODO(student): APB 信号 + 例化 ppa_top
    // TODO(student): include / import lab1 的 apb_master_task（write/read）
    // TODO(student): end-to-end sequence

    initial begin
        $display("[TB] lab3 e2e smoke start");
        #5000;
        $display("[TB] lab3 e2e smoke done");
        $finish;
    end
endmodule
