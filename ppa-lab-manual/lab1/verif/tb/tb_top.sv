// ---------------------------------------------------------------------------
// tb_top — lab1 顶层 testbench
// ---------------------------------------------------------------------------
// 学生手写：时钟/复位生成、DUT 例化、接口绑定、smoke testcase 入口
// Copilot 补齐：APB write/read task 模板、$finish 兜底
// ---------------------------------------------------------------------------

`timescale 1ns/1ps

module tb_top;

    // -----------------------------------------------------------------------
    // clock / reset
    // -----------------------------------------------------------------------
    logic PCLK;
    logic PRESETn;

    initial PCLK = 0;
    always  #5 PCLK = ~PCLK;  // 100 MHz

    initial begin
        PRESETn = 0;
        repeat (4) @(posedge PCLK);
        PRESETn = 1;
    end

    // -----------------------------------------------------------------------
    // APB / DUT 信号
    // -----------------------------------------------------------------------
    // TODO(student): 声明 PSEL/PENABLE/PWRITE/PADDR/PWDATA/PRDATA/PREADY/PSLVERR
    // TODO(student): 例化 apb_slave_if (M1) + packet_sram (M2)，按 spec 连线
    // TODO(student): stub 化 M3 输入端（busy_i/done_i/res_*_i）

    // -----------------------------------------------------------------------
    // smoke test runner
    // -----------------------------------------------------------------------
    initial begin
        $display("[TB] lab1 smoke start");
        // TODO(student): 调用 testcase
        #1000;
        $display("[TB] lab1 smoke done");
        $finish;
    end

endmodule
