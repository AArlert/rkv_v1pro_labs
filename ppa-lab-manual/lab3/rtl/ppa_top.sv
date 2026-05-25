// ---------------------------------------------------------------------------
// ppa_top — PPA-Lite 顶层
// ---------------------------------------------------------------------------
// Spec reference: doc/ppa-lite-spec.md §2.1 框图, §2.2 模块职责, §2.3 顶层端口
// 约束（spec §2.2）："薄层连线，无状态逻辑" —— 本文件禁止出现 always_ff
// REV 触发：phase=design / target=rtl-ppa_top
// ---------------------------------------------------------------------------

module ppa_top (
    input  logic        PCLK,
    input  logic        PRESETn,
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic        PWRITE,
    input  logic [11:0] PADDR,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic        PSLVERR,
    output logic        irq_o
);

    // -----------------------------------------------------------------------
    // M1 ↔ M2 / M3 互连信号
    // TODO(student): 按 ../doc/design-note.md §3 连线表声明 wire/logic
    // -----------------------------------------------------------------------

    // TODO(student): 例化 apb_slave_if (M1)
    // TODO(student): 例化 packet_sram   (M2)，clk=PCLK, rst_n=PRESETn
    // TODO(student): 例化 packet_proc_core (M3)，clk=PCLK, rst_n=PRESETn

    // 注：以下默认值仅占位，DUT 完成后必须删除
    assign PRDATA  = 32'b0;
    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;
    assign irq_o   = 1'b0;

endmodule
