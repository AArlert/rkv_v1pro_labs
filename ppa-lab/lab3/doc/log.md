# Lab3 实验日志 (Log)

## Status 摘要

- **阶段**: 验证完成 → 待验收
- **DUT Agent**: 完成 ppa_top 顶层连线 + 最小端到端 TB（TC1~TC3）
- **Review Agent**: 15 项连线一致性检查全通过，无阻塞性问题
- **VPlan Agent**: 补充 TC4~TC11（8 TC），覆盖 F3-01~F3-06 全部功能点
- **关键决策**: M2 读端口 MUX 仲裁（M3 优先）；M1 新增读回端口解决 U-1
- **待验收**: `make comp` 0 error; `make run` TC1~TC11 全 PASS

---

## §1 设计阶段

### 挑战

1. **M2 读端口共享**: M2 为单读端口 SRAM，M3 处理时需要读，M1 APB 读 PKT_MEM 也需要读。需要仲裁
2. **U-1 解决**: Lab1 遗留 PKT_MEM APB 读返回 0 的问题，需要在 Lab3 集成时解决
3. **时序匹配**: M1 的 `pkt_mem_re_o` 在 SETUP 阶段发起，SRAM 同步读需 1 拍，数据在 ACCESS 阶段到达——恰好匹配 APB 两段式时序

### 设计决策

| ID | 决策 | 理由 |
|----|------|------|
| L3-D-1 | 读端口 MUX 放在 ppa_top，M3 `mem_rd_en_o` 做优先级选择 | 保持 M1/M2/M3 接口不互相感知；ppa_top 仅 2 行组合逻辑，不算"状态逻辑" |
| L3-D-2 | M1 新增 `pkt_mem_rdata_i` + `pkt_mem_re_o` | 最小侵入：M1 只加 1 个输入 + 1 个输出 + 2 行逻辑；lab1 TB 向后兼容 |
| L3-D-3 | busy=1 期间 APB 读 PKT_MEM 返回 M3 的当前读数据（非精确语义） | 单读端口物理限制；文档已记入 risk-register |

### 对规格的假设

- ppa_top "无额外状态逻辑"解释为无寄存器/无 FSM；组合 MUX 属于"纯连线"范畴
- busy=1 时 APB 读 PKT_MEM 为 corner case，不在 Lab3 必做验收范围内

---

## §2 审查阶段

### 审查范围

逐项检查 `ppa_top.sv` 连线与 spec §2.1/§2.3 一致性，覆盖以下维度：
- ppa_top 顶层端口 vs spec §2.3 Top 端口表
- 时钟/复位分发（PCLK/PRESETn → M1/M2/M3）
- M1→M2 写端口连线
- M2 读端口 MUX 仲裁（M3 优先）
- M1→M3 控制信号（start, algo_mode, type_mask, exp_pkt_len）
- M3→M1 状态/结果信号（busy, done, format_ok, errors, res_*）
- M1 未连接输出合理性
- U-1 解决方案（pkt_mem_rdata_i / pkt_mem_re_o）
- TB 预期值正确性
- Makefile 编译文件路径

### 一致性检查结果

| # | 检查项 | Spec 依据 | RTL 实现 | 结论 |
|---|--------|-----------|----------|------|
| 1 | ppa_top 顶层端口（11 个信号） | §2.3 Top 端口表 | 完全匹配：PCLK/PRESETn/PSEL/PENABLE/PWRITE/PADDR[11:0]/PWDATA[31:0]/PRDATA[31:0]/PREADY/PSLVERR/irq_o | ✓ 一致 |
| 2 | M1 时钟复位：PCLK/PRESETn 直连 | §2.1 "M1 使用 PCLK/PRESETn" | `.PCLK(PCLK), .PRESETn(PRESETn)` | ✓ 一致 |
| 3 | M2 时钟复位：PCLK→clk, PRESETn→rst_n | §2.1 "M2 使用 clk/rst_n（由 PCLK/PRESETn 映射）" | `.clk(PCLK), .rst_n(PRESETn)` | ✓ 一致 |
| 4 | M3 时钟复位：PCLK→clk, PRESETn→rst_n | §2.1 "M3 使用 clk/rst_n（由 PCLK/PRESETn 映射）" | `.clk(PCLK), .rst_n(PRESETn)` | ✓ 一致 |
| 5 | M1→M2 写端口（we/addr/wdata） | §2.1 "写端口来自 M1" | `wr_en←m1_pkt_mem_we, wr_addr←m1_pkt_mem_addr, wr_data←m1_pkt_mem_wdata` | ✓ 一致 |
| 6 | M3→M2 读端口（rd_en/addr） | §2.1 "读端口来自 M3" | 经 MUX 仲裁：`m2_rd_en = m3_mem_rd_en \| m1_pkt_mem_re; m2_rd_addr = m3_mem_rd_en ? m3_addr : m1_addr` | ✓ 一致（MUX 为 §6.3 APB 读功能必需） |
| 7 | M2 读数据→M3 | §2.3 M3 "mem_rd_data_i SRAM 读数据" | `.mem_rd_data_i(m2_rd_data)` | ✓ 一致 |
| 8 | M2 读数据→M1（U-1 解决） | §6.3 "APB 读 PKT_MEM 返回当前 SRAM 内容" | `.pkt_mem_rdata_i(m2_rd_data)` | ✓ 一致（R-1 已关闭） |
| 9 | M1→M3 控制：start_o→start_i | §2.3 "触发脉冲（来自 M1.start_o）" | `.start_i(m1_start)` ← `M1.start_o(m1_start)` | ✓ 一致 |
| 10 | M1→M3 控制：algo_mode/type_mask/exp_pkt_len | §2.3 M3 输入 | 三路均正确连接 | ✓ 一致 |
| 11 | M3→M1 状态：busy/done/format_ok | §2.3 M1 输入 | `busy_i←m3_busy, done_i←m3_done, format_ok_i←m3_format_ok` | ✓ 一致 |
| 12 | M3→M1 错误：length/type/chk_error | §2.3 M1 输入 | 三路均正确连接 | ✓ 一致 |
| 13 | M3→M1 结果：res_pkt_len/type/sum/xor | §2.3 M1 输入 | 四路均正确连接 | ✓ 一致 |
| 14 | irq_o 顶层引出 | §2.3 "中断输出（来自 M1）" | `M1.irq_o(irq_o)` → `ppa_top.irq_o` | ✓ 一致 |
| 15 | ppa_top 无状态逻辑 | §2.2 "无额外状态逻辑" | 仅含 2 行组合 MUX，无寄存器/FSM/地址译码 | ✓ 一致 |

### 非阻塞性观察

| # | 观察 | 严重性 | 说明 |
|---|------|--------|------|
| O-1 | M1 新增端口 pkt_mem_rdata_i/pkt_mem_re_o 不在 spec §2.3 M1 端口表中 | INFO | 实现 spec §6.3 必需；已通过 R-1 记录并关闭 |
| O-2 | M1 enable_o/done_irq_en_o/err_irq_en_o 在 ppa_top 中未连接 | INFO | M3 不需要这些信号（M1 内部消费）；spec 架构图无此连线 |
| O-3 | busy=1 期间 APB 读 PKT_MEM 返回 M3 当前读数据 | LOW | R-4 已登记；单读端口物理限制；不在必做验收范围 |

### TB 预期值验证

| TC | 包内容 | 关键预期值 | 验证 |
|----|--------|-----------|------|
| TC1 | pkt_len=8, type=0x02, hdr_chk=0x0A, payload=0x01020304 | sum=0x0A, xor=0x04, STATUS=0x0A, ERR_FLAG=0x00 | ✓ 正确 |
| TC2 | pkt_len=4, type=0x01, hdr_chk=0x05, 无 payload | sum=0x00, STATUS=0x0A | ✓ 正确 |
| TC3 | pkt_len=12, type=0x04, hdr_chk=0x08 | busy 期间 STATUS[1:0]=0x01, done 期间 STATUS[1:0]=0x02 | ✓ 正确 |

### 审查结论

**通过** — F3-01~F3-04 涉及的 ppa_top 连线与 spec §2.1/§2.3 完全一致，无阻塞性问题。建议进入验证阶段（VPlan Agent）。

---

## §3 验证阶段

### 用例设计目标

在 DUT Agent 最小 TB（TC1~TC3，覆盖必做验收 1~3）基础上，补充 8 个集成级端到端 TC：

| TC | 验证意图 | 覆盖场景 |
|----|----------|----------|
| TC4 | 最大合法包（32B）端到端处理 | N-3 |
| TC5 | 包长下溢错误通路端到端 | E-1 |
| TC6 | 非法 pkt_type 错误通路端到端 | E-3 |
| TC7 | hdr_chk 校验错误通路端到端 | E-5 |
| TC8 | algo_mode=0 旁路端到端（CFG 路径验证） | E-6 |
| TC9 | busy 期间写 PKT_MEM 保护（选做 4） | B-2 |
| TC10 | 中断路径闭环（选做 5） | B-3 |
| TC11 | PKT_MEM APB 读回路径（U-1 修复验证） | — |

### 设计决策

| ID | 决策 | 理由 |
|----|------|------|
| L3-V-1 | 错误场景 TC5~TC8 仅各选 1 个代表性 case | Lab2 已覆盖全量错误组合（TC3~TC14）；Lab3 重点是验证 ERR_FLAG/STATUS 端到端通路，非重复覆盖 M3 逻辑 |
| L3-V-2 | TC9 使用 32B 包提供 busy 窗口 | 32B 包给 M3 约 8 拍处理时间，远大于 APB 写事务的 3 拍；避免时序竞争 |
| L3-V-3 | TC10 仅测试 done_irq 路径 | done_irq 和 err_irq 机制对称，Lab1 TC9 已独立验证两条路径；集成级验证一条即可 |
| L3-V-4 | 新增 apb_write_slverr task | TC9 需要在 APB 写事务中捕获 PSLVERR 值；原 apb_write 不返回错误状态 |

### 运行结果（首次 make run：39 PASS / 1 FAIL）

| TC | 结果 | 备注 |
|----|------|------|
| TC1~TC9 | PASS | 39 checks 全部通过 |
| TC10 | FAIL | `irq_o asserted: got 0x00000000, expected 0x00000001` |
| TC11 | PASS | 8 checks 全部通过 |

---

## §4 验证调试阶段

### 失败记录

| 项目 | 内容 |
|------|------|
| 失败 TC | TC10: tc_irq_path_e2e |
| 报错行 | `ppa_tb.sv:390` — `check("TC10 irq_o asserted", ...)` |
| 失败信息 | `[FAIL] TC10 irq_o asserted: got 0x00000000, expected 0x00000001` |
| 同 TC 其余 check | 3/4 PASS（IRQ_STA[0]=1、irq_o deasserted=0、IRQ_STA cleared=0） |
| 复现命令 | `cd ppa-lab/lab3/svtb/sim && make comp && make run` |

### Root Cause 分析

**归因：TB 缺陷**（非 RTL 缺陷）

4B 最小包（pkt_len=4，仅 header 无 payload）在 M3 中只需 2 拍即完成处理，导致 `done_o` 上升沿与 `poll_done()` 的 PRDATA 捕获落在**同一 posedge PCLK**。

时序链路（以 `apb_write(CTRL, 0x03)` 的 ACCESS phase 为 W3）：

| 时钟边沿 | M3 (done_o) | M1 (done_i / done_i_d / done_rising) | M1 (reg_done_irq, NBA) | irq_o |
|----------|-------------|---------------------------------------|------------------------|-------|
| W3 | S_DONE | 1 / 1 / 0 | — | 0 |
| W4 (→PROCESS) | **0** | 1→0 / 1 / 0 | — | 0 |
| W5 (→DONE) | **1** | 0 / 0 / 0→**1** (after NBA) | — | 0 |
| **W6** | 1 | 1 / **0** / **1** | **reg_done_irq ← 1 (NBA)** | **0→1 (after NBA)** |

`poll_done()` 的最后一次 `apb_read(STATUS)` 在 W6 posedge 的 active region 捕获 `PRDATA`（done_i=1，组合输出），随即退出循环。`check(irq_o)` 也在 W6 的 active region 执行，此时 `reg_done_irq` 尚处于 NBA 排队阶段（值仍为 0），因此 `irq_o = 0`。

3 拍后（W9），`apb_read(IRQ_STA)` 读取时 `reg_done_irq` 已经更新为 1，因此 IRQ_STA[0]=1 通过。

### 修复

**文件**: `lab3/svtb/tb/ppa_tb.sv`，TC10 `poll_done()` 后新增 `@(posedge PCLK)`。

等待 1 拍使 `reg_done_irq` 的 NBA 生效后再采样 `irq_o`，与 spec §8.2 "同拍立即置位"语义一致（done_rising 同拍 NBA 设置 reg_done_irq，下一拍 irq_o 即为 1）。
