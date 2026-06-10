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
    output logic        algo_mode_o,        // CFG.algo_mode
    output logic  [3:0] type_mask_o,        // CFG.type_mask
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
    // [Section 1] 固定输出
    // ========================================================================
    // 【解释】APB 3.0 允许从设备通过 PREADY 插入等待状态。本设计所有寄存器访问
    //         均可在单拍完成，因此 PREADY 恒为高，即"零等待"从设备。

    assign PREADY = 1'b1;

    // ========================================================================
    // [Section 2] APB 握手条件信号
    // ========================================================================
    // 【解释】APB 两段式传输：
    //   第 1 拍 SETUP 阶段：Master 驱动 PSEL=1, PENABLE=0, PADDR/PWDATA/PWRITE 有效
    //   第 2 拍 ACCESS 阶段：Master 保持 PSEL=1, 拉高 PENABLE=1
    //   数据在 ACCESS 阶段的上升沿被采样（写）或输出（读）
    //
    // 【提示】定义两个组合信号，用于后续逻辑中判断"当前是否是有效的写/读传输"
    //   apb_write = PSEL & PENABLE & PWRITE   （ACCESS 阶段 + 写方向）
    //   apb_read  = PSEL & PENABLE & ~PWRITE  （ACCESS 阶段 + 读方向）
    //   这两个信号是后续所有寄存器写入/读出逻辑的使能条件。

    // TODO: 实现 apb_write 和 apb_read 的组合逻辑
    logic apb_write;
    logic apb_read;

    assign apb_write = PSEL & PENABLE & PWRITE;
    assign apb_read  = PSEL & PENABLE & ~PWRITE;

    // ========================================================================
    // [Section 3] 地址常量定义
    // ========================================================================
    // 【解释】将地址偏移定义为 localparam，避免硬编码"魔法数字"，提高可读性。
    //         地址来源：spec 第 5.2 节寄存器表 + 第 6.1 节 PKT_MEM 映射表。

    localparam logic [11:0] ADDR_CTRL            = 12'h000;
    localparam logic [11:0] ADDR_CFG             = 12'h004;
    localparam logic [11:0] ADDR_STATUS          = 12'h008;
    localparam logic [11:0] ADDR_IRQ_EN          = 12'h00C;
    localparam logic [11:0] ADDR_IRQ_STA         = 12'h010;
    localparam logic [11:0] ADDR_PKT_LEN_EXP     = 12'h014;
    localparam logic [11:0] ADDR_RES_PKT_LEN     = 12'h018;
    localparam logic [11:0] ADDR_RES_PKT_TYPE    = 12'h01C;
    localparam logic [11:0] ADDR_RES_PAYLOAD_SUM = 12'h020;
    localparam logic [11:0] ADDR_RES_PAYLOAD_XOR = 12'h024;
    localparam logic [11:0] ADDR_ERR_FLAG        = 12'h028;

    localparam logic [11:0] ADDR_PKT_MEM_BASE    = 12'h040;  // PKT_MEM 起始
    localparam logic [11:0] ADDR_PKT_MEM_END     = 12'h05C;  // PKT_MEM 结束（含）

    // ========================================================================
    // [Section 4] CSR 寄存器声明
    // ========================================================================
    // 【解释】只有"可写"寄存器才需要在模块内分配存储（reg/flip-flop）。
    //         RO 寄存器的值来自外部输入端口（如 busy_i, done_i），无需本地存储。
    //
    // 寄存器属性速查（详见 spec 5.1 节）：
    //   RW   - 可读可写，写入后保持新值。需要 flip-flop 存储。
    //   W1P  - 写1产生单拍脉冲，不存储。需要组合/时序逻辑产生脉冲。
    //   RW1C - 可读，写1清零对应位。需要 flip-flop 存储 + 特殊清零逻辑。
    //   RO   - 只读，值来自外部输入。无需存储。

    // --- RW 寄存器 ---
    logic       reg_ctrl_enable;       // CTRL[0]          复位值=0
    logic       reg_cfg_algo_mode;     // CFG[0]           复位值=1
    logic [3:0] reg_cfg_type_mask;     // CFG[7:4]         复位值=4'b1111
    logic       reg_irq_en_done;       // IRQ_EN[0]        复位值=0
    logic       reg_irq_en_err;        // IRQ_EN[1]        复位值=0
    logic [5:0] reg_pkt_len_exp;       // PKT_LEN_EXP[5:0] 复位值=0

    // --- RW1C 寄存器 ---
    logic       reg_irq_sta_done;      // IRQ_STA[0]       复位值=0
    logic       reg_irq_sta_err;       // IRQ_STA[1]       复位值=0

    // --- W1P 内部信号（不存储，产生单拍脉冲） ---
    logic       start_pulse;           // CTRL.start 写1时产生的单拍脉冲

    // --- 辅助信号 ---
    logic       done_i_prev;           // done_i 上一拍值，用于检测上升沿

    // ========================================================================
    // [Section 5] RW 寄存器写入逻辑
    // ========================================================================
    // 【解释】RW 寄存器的行为：
    //   - 复位时恢复默认值
    //   - APB 写命中对应地址时，锁存 PWDATA 中的有效位
    //   - 其他时刻保持不变
    //
    // 【提示】使用 always_ff @(posedge PCLK or negedge PRESETn) 实现时序逻辑。
    //         在 if (!PRESETn) 分支中赋复位值，
    //         在 else if (apb_write && PADDR == ADDR_xxx) 分支中锁存新值。
    //
    // 【注意复位值】spec 第 5.2 节：
    //   - reg_ctrl_enable   复位值 = 0
    //   - reg_cfg_algo_mode 复位值 = 1
    //   - reg_cfg_type_mask 复位值 = 4'b1111
    // 
    // 【APB 地址偏移和映射的本质】一个 APB 写传输中：
    //   - PWDATA 是固定的 32-bit 值（在 SETUP 和 ACCESS 两拍中保持不变）
    //   - 当 PADDR=0x000 时，PWDATA[0] → reg_ctrl_enable
    //   - 当 PADDR=0x004 时，PWDATA[0] → reg_cfg_algo_mode
    //   - 如果要写多个寄存器的多个字段，需要多个独立的 APB 写传输

    // TODO: 实现 RW 寄存器的写入逻辑
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            reg_ctrl_enable   <= 1'b0;
            reg_cfg_algo_mode <= 1'b1;    // spec: 复位值=1
            reg_cfg_type_mask <= 4'b1111; // spec: 复位值=4'b1111
            reg_irq_en_done   <= 1'b0;
            reg_irq_en_err    <= 1'b0;
            reg_pkt_len_exp   <= 6'b0;
        end
        else if (apb_write) begin
            case (PADDR)
                ADDR_CTRL: begin
                    reg_ctrl_enable <= PWDATA[0];
                end
                ADDR_CFG: begin
                    reg_cfg_algo_mode <= PWDATA[0];
                    reg_cfg_type_mask <= PWDATA[7:4];
                end
                ADDR_IRQ_EN: begin
                    reg_irq_en_done <= PWDATA[0];
                    reg_irq_en_err  <= PWDATA[1];  
                end
                ADDR_PKT_LEN_EXP: begin
                    reg_pkt_len_exp <= PWDATA[5:0];
                end
                default: begin
                    // 其他地址不写入 RW 寄存器
                end
            endcase
        end
    end

    // ========================================================================
    // [Section 6] W1P (Write-One-Pulse) 逻辑 —— CTRL.start
    // ========================================================================
    // 【解释】W1P 的含义：
    //   - 软件向 CTRL[1]（start 位）写 1 时，硬件产生"恰好 1 个时钟周期"的高脉冲
    //   - 该脉冲不存储（下一拍自动回 0），软件读 CTRL[1] 永远得到 0
    //   - 用途：告诉 M3"开始处理"，是一个边沿触发命令
    //
    // 【约束条件】spec 第 5.2 节：
    //   start 仅在 enable=1 且 busy=0 时被接受。否则写 1 无效（不产生脉冲）。
    //
    // 【提示】实现方式：
    //   start_pulse = apb_write && (PADDR == ADDR_CTRL) && PWDATA[1]
    //                 && reg_ctrl_enable && !busy_i;
    //   注意：这是组合逻辑（不需要 always_ff），但也可以用寄存器实现"延迟 1 拍"的脉冲。
    //         spec 中未要求延迟，推荐组合逻辑产生同拍脉冲。

    // TODO: 实现 start_pulse 逻辑


    // ========================================================================
    // [Section 7] RW1C (Read/Write-One-to-Clear) 逻辑 —— IRQ_STA
    // ========================================================================
    // 【解释】RW1C 的行为：
    //   置位：当事件发生时（如 done 上升沿 + 中断使能），硬件自动将对应位置 1
    //   清零：软件向对应位写 1 时清零（写 0 则无效）
    //   读出：返回当前锁存的状态值
    //
    // 【置位条件】spec 第 8.2 节：
    //   - IRQ_STA[0] done_irq：done_i 上升沿 且 done_irq_en=1
    //   - IRQ_STA[1] err_irq ：done_i 上升沿 且 任意错误有效 且 err_irq_en=1
    //
    // 【提示】需要检测 done_i 的上升沿：done_i && !done_i_prev
    //         需要一个寄存器 done_i_prev 来记录上一拍的 done_i 值。

    // TODO: 实现 done_i_prev 寄存器（用于上升沿检测）
    // always_ff @(posedge PCLK or negedge PRESETn) begin
    //     if (!PRESETn)
    //         done_i_prev <= 1'b0;
    //     else
    //         done_i_prev <= done_i;
    // end

    // TODO: 实现 IRQ_STA 寄存器逻辑
    // 优先级：复位 > 软件写1清零 > 硬件事件置位 > 保持
    // always_ff @(posedge PCLK or negedge PRESETn) begin
    //     if (!PRESETn) begin
    //         reg_irq_sta_done <= 1'b0;
    //         reg_irq_sta_err  <= 1'b0;
    //     end else begin
    //         // 清零逻辑：apb_write && PADDR==ADDR_IRQ_STA && PWDATA[x]==1
    //         // 置位逻辑：done_i 上升沿 && 对应使能
    //     end
    // end


    // ========================================================================
    // [Section 8] PKT_MEM 写通路
    // ========================================================================
    // 【解释】PKT_MEM 地址窗口 0x040~0x05C 映射到 M2 的 Word 0~7。
    //         当 APB 写命中这个窗口时，需要：
    //         1. 产生 pkt_mem_we_o = 1（告诉 M2 "有数据要写入"）
    //         2. 计算 pkt_mem_addr_o = (PADDR - 0x040) / 4，即 PADDR[4:2]
    //         3. 透传 pkt_mem_wdata_o = PWDATA
    //
    // 【约束】spec 第 6.3 节：
    //         busy=1 期间写 PKT_MEM 无效（PSLVERR=1，不产生写使能）
    //
    // 【提示】判断地址是否落在 PKT_MEM 窗口：
    //   addr_in_pkt_mem = (PADDR >= ADDR_PKT_MEM_BASE) && (PADDR <= ADDR_PKT_MEM_END)
    //                     && (PADDR[1:0] == 2'b00)  // 4字节对齐
    //
    //   pkt_mem_we_o    = apb_write && addr_in_pkt_mem && !busy_i
    //   pkt_mem_addr_o  = PADDR[4:2]   （3-bit，刚好 0~7）
    //   pkt_mem_wdata_o = PWDATA

    logic addr_in_pkt_mem;

    // TODO: 实现 addr_in_pkt_mem 判断逻辑

    // TODO: 实现 pkt_mem_we_o / pkt_mem_addr_o / pkt_mem_wdata_o


    // ========================================================================
    // [Section 9] PSLVERR 错误响应逻辑
    // ========================================================================
    // 【解释】PSLVERR 是 APB 的错误响应信号，在 ACCESS 阶段（PSEL & PENABLE）有效。
    //         以下情况需要返回 PSLVERR=1：
    //         1. 写只读寄存器（RO 地址：STATUS/RES_*/ERR_FLAG）
    //         2. busy=1 期间写 PKT_MEM
    //         3. 访问保留/未定义地址（0x02C~0x03F, >=0x060, 非 4 字节对齐等）
    //
    // 【提示】可以用"正向列举合法地址"或"反向检测非法条件"两种思路。
    //         推荐方式：先判断地址是否落在合法区域，不合法则报错。
    //         对于 RO 寄存器，仅在写方向时报错（读方向正常返回值）。
    //
    // 【注意】PSLVERR 是组合输出，在 ACCESS 阶段同拍有效。
    //         当 PSEL=0 或 PENABLE=0 时，PSLVERR 应为 0（无传输进行时不报错）。

    // TODO: 实现 PSLVERR 组合逻辑
    // 建议结构：
    // always_comb begin
    //     PSLVERR = 1'b0;
    //     if (PSEL && PENABLE) begin
    //         case (PADDR)
    //             ADDR_CTRL:        PSLVERR = 1'b0;  // RW，读写均合法
    //             ADDR_STATUS:      PSLVERR = PWRITE; // RO，写报错
    //             ...
    //             default:          PSLVERR = 1'b1;  // 未定义地址
    //         endcase
    //         // 特殊：PKT_MEM 窗口 busy 时写也报错
    //     end
    // end


    // ========================================================================
    // [Section 10] APB 读数据通路（PRDATA 多路选择）
    // ========================================================================
    // 【解释】当 APB 读访问发生时（apb_read = 1），根据 PADDR 返回对应寄存器的值。
    //         - RW 寄存器：返回本地存储值（如 reg_ctrl_enable）
    //         - RO 寄存器：返回外部输入（如 busy_i, res_pkt_len_i）
    //         - W1P 位：读回始终为 0
    //         - 未使用位：读回为 0
    //
    // 【提示】使用 always_comb + case(PADDR) 实现读数据多路选择器：
    //
    // always_comb begin
    //     PRDATA = 32'h0;  // 默认值
    //     if (PSEL && PENABLE && !PWRITE) begin
    //         case (PADDR)
    //             ADDR_CTRL:   PRDATA = {30'b0, 1'b0, reg_ctrl_enable};
    //                          // bit[1]=start 是 W1P，读回恒 0；bit[0]=enable
    //             ADDR_CFG:    PRDATA = {24'b0, reg_cfg_type_mask, 3'b0, reg_cfg_algo_mode};
    //                          // bit[7:4]=type_mask, bit[0]=algo_mode
    //             ADDR_STATUS: PRDATA = {28'b0, format_ok_i, error_status, done_i, busy_i};
    //                          // bit[3]=format_ok, bit[2]=error, bit[1]=done, bit[0]=busy
    //                          // 其中 error = length_error_i | type_error_i | chk_error_i
    //             // ... 其他地址类推
    //             // ADDR_RES_PKT_LEN:     PRDATA = {26'b0, res_pkt_len_i};
    //             // ADDR_RES_PKT_TYPE:    PRDATA = {24'b0, res_pkt_type_i};
    //             // ADDR_RES_PAYLOAD_SUM: PRDATA = {24'b0, res_payload_sum_i};
    //             // ADDR_RES_PAYLOAD_XOR: PRDATA = {24'b0, res_payload_xor_i};
    //             // ADDR_ERR_FLAG:        PRDATA = {29'b0, chk_error_i, type_error_i, length_error_i};
    //             default: PRDATA = 32'h0;
    //         endcase
    //     end
    // end
    //
    // 【注意】STATUS 和 ERR_FLAG 是"直透"（pass-through），即直接使用外部输入端口的值，
    //         无需本地寄存器存储。这意味着 M3 输出变化后，APB 下一次读就能看到新值。


    // ========================================================================
    // [Section 11] 中断输出逻辑
    // ========================================================================
    // 【解释】irq_o 是最终的中断输出引脚，定义为 IRQ_STA 中任意位为高时有效。
    //         irq_o = reg_irq_sta_done | reg_irq_sta_err
    //         这是纯组合逻辑，无额外延迟。

    // TODO: 实现 irq_o 组合逻辑


    // ========================================================================
    // [Section 12] CSR 输出端口赋值
    // ========================================================================
    // 【解释】将内部寄存器值连接到模块输出端口，供 M3 和顶层使用。

    assign enable_o       = reg_ctrl_enable;
    assign start_o        = start_pulse;
    assign algo_mode_o    = reg_cfg_algo_mode;
    assign type_mask_o    = reg_cfg_type_mask;
    assign exp_pkt_len_o  = reg_pkt_len_exp;
    assign done_irq_en_o  = reg_irq_en_done;
    assign err_irq_en_o   = reg_irq_en_err;

endmodule
