// ---------------------------------------------------------------------------
// ppa_reg_pkg — PPA-Lite CSR 偏移 / 字段宏 / 复位值
// Spec reference: doc/ppa-lite-spec.md §5
// 跨 lab 复用；lab1 起维护
// ---------------------------------------------------------------------------

package ppa_reg_pkg;

    // -----------------------------------------------------------------------
    // CSR 偏移（来自 spec §5）
    // TODO(student): 与 spec §5 寄存器表对齐
    // -----------------------------------------------------------------------
    parameter logic [11:0] ADDR_CTRL         = 12'h000;
    parameter logic [11:0] ADDR_CFG          = 12'h004;
    parameter logic [11:0] ADDR_STATUS       = 12'h008;
    parameter logic [11:0] ADDR_IRQ_EN       = 12'h00C;
    parameter logic [11:0] ADDR_IRQ_STA      = 12'h010;
    parameter logic [11:0] ADDR_PKT_LEN_EXP  = 12'h014;
    parameter logic [11:0] ADDR_RES_PKT_LEN  = 12'h018;
    parameter logic [11:0] ADDR_RES_PKT_TYPE = 12'h01C;
    parameter logic [11:0] ADDR_RES_PAY_SUM  = 12'h020;
    parameter logic [11:0] ADDR_RES_PAY_XOR  = 12'h024;
    parameter logic [11:0] ADDR_PKT_MEM_BASE = 12'h040;  // 0x040..0x05C (8 words)
    parameter logic [11:0] ADDR_PKT_MEM_END  = 12'h05C;

endpackage : ppa_reg_pkg
