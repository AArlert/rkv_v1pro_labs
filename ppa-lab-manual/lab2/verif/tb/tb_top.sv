// ---------------------------------------------------------------------------
// lab2 tb_top — 独立 TB（不依赖 lab1 RTL）
// 用 SV 数组替代 packet_sram，仅供 M3 读端口使用
// ---------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_top;
    logic        clk = 0;
    logic        rst_n;
    always #5 clk = ~clk;

    initial begin
        rst_n = 0;
        repeat (4) @(posedge clk);
        rst_n = 1;
    end

    // TODO(student): SRAM stub（8×32-bit SV 数组）
    // TODO(student): DUT 例化 packet_proc_core
    // TODO(student): testcase 入口

    initial begin
        $display("[TB] lab2 smoke start");
        #2000;
        $display("[TB] lab2 smoke done");
        $finish;
    end
endmodule
