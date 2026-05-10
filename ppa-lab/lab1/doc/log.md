# Lab1 实验日志

## Status（新 Agent 只读此段）

- **当前阶段**：设计阶段完成
- **最后更新**：2026-05-10
- **结论**：M1+M2 RTL 已实现，TB 骨架已搭建，含 3 条测试用例（TC1 CSR 默认值 / TC2 PKT_MEM 写入+回读比对 / TC3 RES_* 读通路）
- **遗留**：待编译验证（make comp / make run）
- **下一步**：运行编译和仿真，确认 0 error；后续由 Verification Plan Agent 补充 testplan
- **责任 Agent**：DUT Agent -> Verification Plan Agent

---

## 1 设计阶段

### 1.1 设计决策

**M1 ppa_apb_slave_if 关键设计点**

1. **APB 传输时序**：ACCESS 阶段（PSEL=1 & PENABLE=1）才执行读写操作
2. **PREADY 固定为 1**：无等待态，符合 spec 4.1
3. **地址空间划分**：
   - is_csr 判定：PADDR <= 0x028 且 word-aligned
   - is_pkt_mem 判定：0x040 <= PADDR <= 0x05C 且 word-aligned
   - 其余地址均返回 PSLVERR=1
4. **CSR 属性实现**：
   - RW：直接写入/读回
   - RO（STATUS/RES_*/ERR_FLAG）：读回 M3 输入端口值，写操作返回 PSLVERR=1
   - W1P（CTRL.start）：写 1 产生单拍脉冲，读回恒为 0
   - RW1C（IRQ_STA）：写 1 清零，清除/置位互斥分支避免竞争
5. **start 门控**：仅在 reg_enable=1（已生效值）且 busy_i=0 时接受
6. **中断逻辑**：done 上升沿检测（done_i & ~done_i_d），置位条件包含 irq_en 门控
7. **PKT_MEM 写端口**：wr_addr = PADDR[4:2]，利用 0x040 的 [4:2]=000 特性直接取位

**M2 ppa_packet_sram 关键设计点**

1. **存储体**：8x32-bit，logic [31:0] mem [0:7]
2. **同步读写**：读写均在 posedge clk 采样
3. **复位清零**：异步复位清零全部 8 个 word

### 1.2 与 Spec 的对应关系

| 设计点 | Spec 章节 | 实现状态 |
|--------|-----------|----------|
| APB 两段式时序 | 4.1 | 已实现 |
| 地址空间划分 | 4.2 | 已实现 |
| CSR 完整寄存器表 | 5.1~5.2 | 已实现（11 个寄存器） |
| PKT_MEM 窗口写入 | 6.1~6.3 | 已实现 |
| busy 写保护 | 6.3 | 已实现 |
| PSLVERR 统一策略 | 8.3 | 已实现 |
| 中断时序 | 8.1~8.2 | 已实现 |
| M2 双端口 SRAM | 2.2 | 已实现 |

### 1.3 TB 改进（相比旧版本）

- TC2（PKT_MEM 写入）增加了 SRAM 回读自动比对（sram_read_check task），不再依赖波形弱验证
