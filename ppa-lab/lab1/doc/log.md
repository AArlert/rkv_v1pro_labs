# Lab1 实验日志

## Status（新 Agent 只读此段）

- **当前阶段**：验证阶段完成 → 待验收
- **最后更新**：2026-05-11
- **结论**：testplan 已编写（10 TC / 61 checks），`make comp` 0 error 0 warning，`make run` 61/61 PASS
- **遗留**：U-1（PKT_MEM APB 读返回 0，Lab3 解决）；F1-08/F1-12 仅 M1 级验证（端到端待 Lab3）
- **下一步**：由 Sign-off Agent 按 acceptance.md 逐项判定
- **责任 Agent**：VPlan Agent → Sign-off Agent

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

---

## 2 审查阶段

### 2.1 审查范围

Review Agent 对 DUT Agent 交付的 Lab1 RTL（M1 + M2）、最小 TB、Makefile 进行 Spec 一致性审查

### 2.2 编译仿真结果

| 命令 | 结果 |
|------|------|
| `make comp` | 0 error, 0 warning |
| `make run` | 25/25 PASS, 0 FAIL |

### 2.3 RTL-Spec 一致性检查（F1-01 ~ F1-15）

| ID | 功能 | Spec § | RTL 实现 | 判定 |
|----|------|--------|---------|------|
| F1-01 | APB 两段式传输时序 | §4.1 | `apb_write = PSEL & PENABLE & PWRITE`，ACCESS 阶段执行 | 一致 |
| F1-02 | PREADY 固定为 1 | §4.1 | `assign PREADY = 1'b1` | 一致 |
| F1-03 | CSR 地址映射（0x000~0x028） | §4.2 | `is_csr = PADDR <= 0x028 && word-aligned` | 一致 |
| F1-04 | 保留地址返回 PSLVERR=1 | §4.2 | `!is_valid_addr → PSLVERR=1` | 一致 |
| F1-05 | CSR 默认值正确 | §5.2 | 复位值完全匹配（CFG=0xF1 等） | 一致（TC1 验证） |
| F1-06 | RW 寄存器读写 | §5.1 | CTRL/CFG/IRQ_EN/PKT_LEN_EXP 读写逻辑正确 | 一致 |
| F1-07 | RO 寄存器写保护 | §8.3 | `write_ro → PSLVERR=1`，6 个 RO 地址均判定 | 一致 |
| F1-08 | W1P 行为（CTRL.start） | §5.1 | 单拍脉冲 `start_pulse <= start_accepted`，读回恒 0 | 一致 |
| F1-09 | RW1C 行为（IRQ_STA） | §5.1 | 写 1 清零，互斥分支防止清除/置位竞争 | 一致 |
| F1-10 | PKT_MEM 地址映射 | §6.1 | `0x040 <= PADDR <= 0x05C && word-aligned` | 一致 |
| F1-11 | PKT_MEM 写端口生成 | §6.2 | `pkt_mem_we_o/addr_o/wdata_o` 正确生成 | 一致（TC2 验证） |
| F1-12 | busy=1 写 PKT_MEM 报错 | §6.3 | `write_pktmem_busy → PSLVERR=1`，`we_o` 被门控 | 一致 |
| F1-13 | M2 双端口同步 SRAM | §2.2 | 8×32-bit，同步读写，端口匹配 | 一致 |
| F1-14 | M2 复位清零 | §2.2 | 异步复位清零全部 8 word | 一致 |
| F1-15 | 中断逻辑（irq_o） | §8.2 | done 上升沿检测 + IRQ_EN 门控 + 组合输出 | 一致 |

### 2.4 非阻塞性问题

| ID | 描述 | 严重性 | 处置 |
|----|------|--------|------|
| U-1 | PKT_MEM APB 读返回 0 而非 SRAM 数据 | LOW | Spec M1 端口表未定义 `pkt_mem_rdata_i`，读路径需 Lab3 顶层集成解决 |

### 2.5 阻塞性问题

无

### 2.6 审查结论

**PASS** — RTL 实现与 Spec 完全一致，无阻塞性不一致项。交接至 Verification Plan Agent 进行验证阶段

---

## 3 验证阶段

### 3.1 验证范围

VPlan Agent 编写 testplan.md 并补充 7 条定向用例（TC4~TC10），覆盖 feature-matrix 中 6 个 TB #TODO 功能点 + 1 个 RW readback 补充

### 3.2 编译仿真结果

| 命令 | 结果 |
|------|------|
| `make comp` | 0 error, 0 warning |
| `make run` | 61/61 PASS, 0 FAIL |

### 3.3 新增用例设计目标与结果

| TC | 名称 | 目标功能 | checks | 结果 |
|----|------|----------|--------|------|
| TC4 | tc_slverr_reserved | F1-04 保留/越界/非对齐地址 PSLVERR | 6 | PASS |
| TC5 | tc_ro_write_protect | F1-07 RO 寄存器写保护 | 12 | PASS |
| TC6 | tc_w1p_start | F1-08 W1P start 脉冲行为 | 5 | PASS |
| TC7 | tc_rw1c_irq_sta | F1-09 RW1C 写 1 清零 | 2 | PASS |
| TC8 | tc_busy_write_protect | F1-12 busy 写保护 | 3 | PASS |
| TC9 | tc_irq_logic | F1-15 中断路径完整 | 4 | PASS |
| TC10 | tc_rw_readback | F1-06 RW 写后读 | 4 | PASS |

### 3.4 关键验证决策

1. **PSLVERR 捕获方式**：新增 `apb_write_with_slverr` / `apb_read_with_slverr` 辅助 task，在 ACCESS 阶段第三个 posedge 用 blocking 赋值捕获组合输出
2. **F1-08/F1-12 验证范围**：虽标注"待 Lab3 端到端验证"，但 W1P 脉冲机制和 busy 写保护均为 M1 行为，可在 Lab1 用 stub 完整验证；端到端路径留 Lab3
3. **IRQ 测试状态管理**：done_stub 的 0→1 跳变需先置 0 等 2 拍清除 done_i_d，否则无法触发 done_rising
4. **TC 执行顺序**：10 条 TC 顺序执行于同一仿真，后续 TC 依赖前序 TC 的 stub 状态，每个 TC 入口负责设置自身所需状态
