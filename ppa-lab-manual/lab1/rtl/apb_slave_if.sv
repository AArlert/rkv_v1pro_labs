// ---------------------------------------------------------------------------
// apb_slave_if  (M1)
// ---------------------------------------------------------------------------
// Spec reference: doc/ppa-lite-spec.md §2.3 (M1 ports) + §5 (CSR table)
// Design note:    doc/design-note.md §2, §4
//
// 学生手写：
//   1. 端口表（已给骨架；学生确认与 spec §2.3 100% 一致）
//   2. CSR 寄存器组 + 读/写译码
//   3. W1P / RW1C 行为
//   4. SRAM 写端口与 IRQ 输出
// Copilot 补齐：
//   - case 分支的重复部分
//   - always_ff 模板
// REV 触发：在 lab1/doc/progress.md 追加
//   >>> CALL REV @<ts> on rtl-apb_slave_if phase=design
// ---------------------------------------------------------------------------

module apb_slave_if (
    // APB
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

    // 控制下发（CTRL / CFG / PKT_LEN_EXP / IRQ_EN）
    output logic        enable_o,
    output logic        start_o,         // W1P 单拍脉冲
    output logic        algo_mode_o,
    output logic [3:0]  type_mask_o,
    output logic [5:0]  exp_pkt_len_o,
    output logic        done_irq_en_o,
    output logic        err_irq_en_o,

    // SRAM 写端口（送 M2）
    output logic        pkt_mem_we_o,
    output logic [2:0]  pkt_mem_addr_o,
    output logic [31:0] pkt_mem_wdata_o,

    // 来自 M3 的状态/结果
    input  logic        busy_i,
    input  logic        done_i,
    input  logic        format_ok_i,
    input  logic        length_error_i,
    input  logic        type_error_i,
    input  logic        chk_error_i,
    input  logic [5:0]  res_pkt_len_i,
    input  logic [7:0]  res_pkt_type_i,
    input  logic [7:0]  res_payload_sum_i,
    input  logic [7:0]  res_payload_xor_i,

    // 中断
    output logic        irq_o
);

    // -----------------------------------------------------------------------
    // TODO(student): CSR 偏移 / 默认值 / 字段定义（建议放 verif/common/ppa_reg_pkg.sv 复用）
    // TODO(student): APB 两段式时序（SETUP / ACCESS）
    // TODO(student): 写译码 / 读译码 / PSLVERR 生成
    // TODO(student): W1P (start) / RW1C (IRQ_STA) 行为
    // TODO(student): irq_o = done_irq | err_irq
    // -----------------------------------------------------------------------

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;  // TODO(student): replace
    assign PRDATA  = 32'b0; // TODO(student): replace

endmodule
