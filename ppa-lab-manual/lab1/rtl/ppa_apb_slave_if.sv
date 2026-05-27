// ============================================================================
// Module: ppa_apb_slave_if
// Description: APB 3.0 从接口 + CSR 寄存器组
//   - 两段式传输：SETUP -> ACCESS
//   - PREADY 固定为 1，无等待状态
//   - 寄存器属性：RW / RO / W1P / RW1C
// Register Address Space：向外暴露字段信息
//   - 0x000 ~ 0x02B：CSR 区，控制 / 状态 / 中断 / 结果寄存器
//   - 0x02C ~ 0x03F：保留，访问返回 PSLVERR=1
//   - 0x040 ~ 0x05C：PKT_MEM 区，Packet 数据写入窗口（8 个 word）
//   - 0x05D ~ 0x05F：保留，访问返回 PSLVERR=1
//   - 0x060 ~      ：未定义，访问返回 PSLVERR=1
// Ports: 详见 ppa-lite-spec.md 2.3 节 M1 端口表
// ============================================================================

module ppa_apb_slave_if (
    // APB 接口
    input  logic        PCLK,               // APB 时钟
    input  logic        PRESETn,            // APB 复位，低有效
    input  logic        PSEL,               // APB 从设备选择
    input  logic        PENABLE,            // APB 使能
    input  logic        PWRITE,             // APB 写使能
    input  logic [11:0] PADDR,              // APB 写地址
    input  logic [31:0] PWDATA,             // APB 写数据
    output logic [31:0] PRDATA,             // APB 读数据
    output logic        PREADY,             // APB 就绪，固定为 1（无等待状态）
    output logic        PSLVERR,            // APB 访问错误标志

    // CSR 输出（送 M3 / 顶层）
    output logic        enable_o,           // CTRL.enable
    output logic        start_o,            // W1P 单拍脉冲（触发处理）
    output logic        algo_mode_o,        // CTRL.algo_mode
    output logic  [3:0] type_mask_o,        // CTRL.type_mask
    output logic  [5:0] exp_pkt_len_o,      // PKT_LEN_EXP.exp_pkt_len
    output logic        done_irq_en_o,      // IRQ_EN.done_irq_en
    output logic        err_irq_en_o,       // IRQ_EN.err_irq_en

    // PKT_MEM 写端口（送 M2）
    output logic        pkt_mem_we_o,       // SRAM 写使能（送 M2）
    output logic  [2:0] pkt_mem_addr_o,     // SRAM 写地址（送 M2）
    output logic [31:0] pkt_mem_wdata_o,    // SRAM 写数据（送 M2）

    // M3 状态/结果输入
    input  logic        busy_i,             // M3 busy 状态
    input  logic        done_i,             // M3 done 状态
    input  logic        format_ok_i,        // M3 格式合法标志
    input  logic        length_error_i,     // M3 长度错误标志
    input  logic        type_error_i,       // M3 类型错误标志
    input  logic        chk_error_i,        // M3 校验错误标志
    input  logic  [5:0] res_pkt_len_i,      // M3 解析包长
    input  logic  [7:0] res_pkt_type_i,     // M3 解析包类型
    input  logic  [7:0] res_payload_sum_i,  // M3 payload 字节和
    input  logic  [7:0] res_payload_xor_i,  // M3 payload XOR

    // 中断输出
    output logic        irq_o               // 中断输出（= done_irq | err_irq）
);
    // ========================================================================
    // 内部信号
    // ========================================================================
    
endmodule