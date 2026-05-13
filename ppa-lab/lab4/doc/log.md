# Lab4 实验日志 (Log)

## Status: Phase 2 完成 — Coverage Closure, 五类覆盖率全部 ≥90% (总 97.47%)

---

## Phase 0: 全量 Testcase 整理 (2026-05-13)

**执行者**: Verification Plan Agent

### 目标
整理 Lab1-3 全部必做 testcase 为结构化回归列表, 为后续 Makefile 统一入口和覆盖率收集奠定基础。

### 产出
- `lab4/doc/testplan.md` — 36 TC / 177 checks 回归列表
- `lab4/doc/handoff.md` — 交接笔记
- `lab4/doc/log.md` — 本文件

### 关键发现
1. Lab1-3 共 36 个 TC, 分布在 3 个独立 TB 中, 涵盖 module-level (M1+M2, M3) 和 integration-level (ppa_top) 两个验证层级
2. Spec §10 全部 14 个验收场景 (N-1~N-4, E-1~E-6, B-1~B-4) 均有 TC 覆盖, 无遗漏
3. 36 个 Feature (F1-01~F1-15 + F2-01~F2-15 + F3-01~F3-06) 全部 #VERIFIED
4. E-2/E-4/B-4 仅有 module-level 覆盖 (无 E2E TC), 但核心逻辑已验, 端到端链路由其他 TC 覆盖

### 决策
- 回归 ID 采用 `L<lab>_TC<nn>` 前缀消歧 (避免 3 个 TB 的 TC ID 冲突)
- Smoke 集选定 4 个 TC (L1_TC01/L1_TC02/L2_TC01/L3_TC01), 覆盖每个 DUT 层级的最基础功能
- 保持 3 个 TB 独立编译运行 (不合并), 保留 module-level 验证的独立性

---

## Phase 1: Makefile 统一入口 + 全量回归 + 覆盖率基线 (2026-05-13)

**执行者**: Verification Phase 1 Agent

### 目标
建立 `make smoke / regress / cov` 统一入口, 运行全量回归确认 36 TC 全 PASS, 收集 Questa line/branch/condition/FSM/toggle coverage 基线并生成 HTML 报告。

### 产出
- `lab4/svtb/sim/Makefile` — 统一回归与覆盖率 Makefile
- `covhtmlreport/index.html` — Questa HTML 覆盖率报告 (gitignored)
- `covdata/merged.ucdb` — 合并后 UCDB (gitignored)
- 更新 `.gitignore` — 添加覆盖率生成物忽略规则
- 更新 `lab4/doc/handoff.md` — 含 Coverage 基线数据和 UVM 升级扩展指南

### 回归结果
- **36 TC / 177 checks ALL PASS** (Lab1: 10/61, Lab2: 15/76, Lab3: 11/40)
- 0 error, 0 warning (编译和仿真)
- 运行时间: ~15 秒 (全量), ~5 秒 (smoke)

### 覆盖率基线

| 类型 | Coverage |
|------|----------|
| Statements | 96.54% |
| Branches | 87.79% |
| Conditions | 75.71% |
| FSM States | 100.00% |
| FSM Transitions | 60.00% |
| Toggles | 77.53% |
| **Total** | **82.93%** |

### 关键决策
1. `make smoke` 定义为 Lab1 完整运行 (10 TC) — 当前 TB 为 monolithic initial 块, 无法选择单个 TC; UVM 升级后可改为 `+UVM_TESTNAME` 选择
2. Coverage 使用 `-cover bcstf` (不含 expression) — 匹配 Questa 2021.1 常用配置
3. 每个 lab 使用独立 work library (`work_lab1/2/3`) — 因 3 个 `ppa_tb` 模块名相同但实现不同
4. UCDB merge 时 TB 代码覆盖率有 mismatch 警告 — 仅影响 TB 代码覆盖, RTL 覆盖率完整无损

### 已知局限 → 覆盖率根因分析

Spec §11.5 #2 验收标准: ≥90% 合格 / ≥95% 优良。当前 Branches (87.79%), Conditions (75.71%), FSM Transitions (60%), Toggles (77.53%) 共 4 项不合格。

#### 根因 A: TB 代码污染 RTL 覆盖率

| 迁移 | 触发条件 | 覆盖状态 |
|------|---------|---------|
| S_IDLE → S_PROCESS | start_i in IDLE | COVERED (多个 TC) |
| S_PROCESS → S_DONE | 处理完成 | COVERED (多个 TC) |
| S_DONE → S_PROCESS | start_i in DONE | COVERED (L2_TC06, L3_TC02) |
| S_PROCESS → S_IDLE | **reset during PROCESS** | **MISS** (line 131) |
| S_DONE → S_IDLE | **reset during DONE** | **MISS** (line 131) |

TB 的 check macro (`actual === expected`)、fail 计数器 (`fail_cnt`)、timeout 逻辑被纳入覆盖率统计。这些代码在全 PASS 回归中 false 分支永远不走, 导致 `/ppa_tb` 实例 branch=50%, condition=25%, toggle=67.82%。

修复方法: Makefile `cov` target 的 vlog 拆成两步, RTL 用 `-cover bcstf`, TB 不加 `-cover`。

#### 根因 B: 缺少异步复位测试

| 迁移 | 触发条件 | 覆盖状态 |
|------|---------|---------|
| S_IDLE → S_PROCESS | start_i in IDLE | COVERED (多个 TC) |
| S_PROCESS → S_DONE | 处理完成 | COVERED (多个 TC) |
| S_DONE → S_PROCESS | start_i in DONE | COVERED (L2_TC06, L3_TC02) |
| S_PROCESS → S_IDLE | **reset during PROCESS** | **MISS** (line 131) |
| S_DONE → S_IDLE | **reset during DONE** | **MISS** (line 131) |

FSM 缺失迁移 (ppa_packet_proc_core.sv:131):
- `S_PROCESS → S_IDLE` (处理中途 reset)
- `S_DONE → S_IDLE` (完成态 reset)

所有 TB 在仿真开头一次性复位 (FSM 必在 S_IDLE), 之后不再 reset。`rst_n` 也只有 0→1 方向。

修复方法: 新增 mid-sim reset TC, FSM Transitions 60% → 100%。另: `case(state) default` (line 243) 是结构性不可达, 应登记为排除项。

#### 根因 C: 跨 Lab 实例重复统计

| 缺失项 (Lab3 M1 实例 `/ppa_tb/u_dut/u_m1`)    | RTL 位置       | Lab1 覆盖        | Lab3 缺失原因             |
| ---------------------------------------- | ------------ | -------------- | --------------------- |
| `!is_valid_addr` → slverr 分支             | line 142     | 已覆盖 (TC4)      | Lab3 不测非法地址           |
| `write_ro` → slverr 分支                   | line 144     | 已覆盖 (TC5)      | Lab3 不测 RO 写保护        |
| `err_irq` 路径 5 个 condition 项             | line 202     | 部分覆盖 (TC9)     | Lab3 TC10 仅测 done_irq |
| `ADDR_PKT_LEN_EXP` write 条件              | line 193     | 已覆盖 (TC10)     | Lab3 从未写此寄存器          |
| `ADDR_CTRL/CFG/IRQ_EN/IRQ_STA` read case | line 217-222 | 已覆盖 (TC1/TC10) | Lab3 只读结果寄存器          |
| `type_mask[0:3]` toggle                  | —            | 部分覆盖 (TC8)     | Lab3 保持复位默认 4'b1111   |

`ppa_apb_slave_if` 两个实例: Lab1 独立 (branch 97.61%) 和 Lab3 集成 (branch 76.19%)。Lab3 集成测试不覆盖 CSR error path (`!is_valid_addr`/`write_ro`/`err_irq`), 拉低了 M1 的覆盖率。

修复方法: ① `vcover merge -du` 按 Design Unit 合并; ② 新增 Lab3 err_irq E2E TC。

#### 根因 D: 测试数据多样性不足

| 未翻转信号                          | 原因                             | 可否排除                                                             |
| ------------------------------ | ------------------------------ | ---------------------------------------------------------------- |
| `PREADY` (硬连线 1)               | Spec §4: PREADY 固定为 1, 无等待状态   | 合法排除                                                             |
| `PADDR[7:11]`                  | 地址空间仅到 0x05C, 高 5 位永为 0        | 合法排除                                                             |
| `res_pkt_type_o[3:7]`          | 测试仅用 0x01/0x02/0x04/0x08       | 可补充                                                              |
| `res_pkt_len_o[4]`             | 包长 4~32, 无 bit4=1 的值 (16 不在范围) | 合法排除 (pkt_len∈[4,32], bit4 翻转需 len=16 but [4,15] vs [16,32] 可覆盖) |
| `exp_pkt_len_i[0:5]` (Lab3 实例) | Lab3 从未写 PKT_LEN_EXP           | 可补充                                                              |

32-bit 数据路径高位未充分翻转 (`res_pkt_type_o[3:7]`, `res_pkt_len_o[4]`, `exp_pkt_len_i` 等)。`PREADY` 硬连线 1 和 `PADDR[7:11]` 设计意图上不会翻转, 应排除。

修复方法: 增加 payload 多样性 (0xFF/0xAA/0x55); 建立覆盖率排除登记表。

---

## Phase 2: Coverage Closure (2026-05-13)

**执行者**: Coverage Closure Agent

### 目标

将五类代码覆盖率全部提升到 ≥90% (合格线), 争取 ≥95% (优良)。一命令 `make cov` 完成全流程。

### 实施步骤

| 步骤 | 动作 | 影响 |
|------|------|------|
| S1 | Makefile vlog 拆分: RTL 加 `-cover bcstf`, TB 不加 | 消除 TB 污染 (Cond +16%, Branch +8%, Toggle +11%) |
| S2 | 尝试 `vcover merge -du` → Questa 2021.1 不支持, 改为确保各实例 TB 内充分覆盖 | — |
| S3 | Lab2 新增 TC16 (reset in S_PROCESS) + TC17 (reset in S_DONE) | FSM Trans 60→100% |
| S4 | Lab3 新增 TC12 (err_irq E2E, 含 PKT_LEN_EXP 写) | Cond +4%, Branch +2% |
| S5 | Lab2/Lab3 payload 改为 0xFF/0xAA/0x55 模式 | Toggle +3% |
| S6 | Lab3 新增 TC13 (集成级 mid-sim reset) | FSM Trans 补齐 Lab3 实例 |
| S7 | Lab1 TC11 增加 Phase 6 (exp_pkt_len/type_mask 全位翻转) + Phase 7 (PADDR OOB) | Toggle: Lab1 实例 |
| S8 | Lab3 新增 TC14 (toggle exercise: pkt_len=20, type=0xF0, sum/xor=0xE3, PADDR/is_valid_addr/write_ro) | Toggle 88.85→98.28% |
| S9 | 创建 `coverage_exclusion.md` 排除登记表 | 审查记录 (未实际应用, 因已达标) |

### 最终覆盖率

| 覆盖率类型 | Phase 1 | Phase 2 | 提升 | 判定 |
|-----------|---------|---------|------|------|
| Statements | 96.54% | 98.40% | +1.86% | 优良 |
| Branches | 87.79% | 96.25% | +8.46% | 优良 |
| Conditions | 75.71% | 91.93% | +16.22% | 合格 |
| FSM States | 100% | 100% | — | 优秀 |
| FSM Transitions | 60% | 100% | +40% | 优秀 |
| Toggles | 77.53% | 98.28% | +20.75% | 优良 |
| **Total** | **82.93%** | **97.47%** | **+14.54%** | **优良** |

### 回归规模

42 TC / 224 checks, ALL PASS (Lab1: 11/74, Lab2: 17/94, Lab3: 14/56)

### 关键决策

1. **不应用 Questa exclude file** — 当前五类已全部达标, 排除项仅作审查记录和规范文档, 不实际影响统计。后续若需推高可启用。
2. **Toggle 收敛策略: 信号分析→定向 TC** — 用 `vcover report -toggle -details` 定位具体未翻转节点, 按信号分类 (CSR 控制位/结果位/地址位) 设计定向 toggle 激励, 单个 TC 可修复 100+ miss bins。
3. **`vcover merge -du` 放弃** — Questa 2021.1 不支持; 替代方案是在每个 Lab TB 中补充足够激励, 使同一 RTL 的每个实例都独立达标。
4. **PADDR toggle 通过 OOB 访问覆盖** — 驱动 PADDR 高位地址 (0x080~0x800) 虽触发 SLVERR, 但端口电平确实翻转, 是覆盖率收集的合法手段。

### 覆盖率排除登记 (审查记录)

详见 `lab4/doc/coverage_exclusion.md`。三项合法排除:

| ID | 模块 | 信号 | 类型 | 排除原因 |
|----|------|------|------|---------|
| EX-01 | ppa_apb_slave_if | PREADY | Toggle | 硬连线 1, Spec §4 |
| EX-02 | ppa_apb_slave_if | PADDR[11:7] | Toggle | 地址空间仅到 0x05C |
| EX-03 | ppa_packet_proc_core | FSM default branch | Branch/Stmt | 2-bit state 仅 3 值, state=3 不可达 |

注: 因覆盖率已达标, 以上排除项**未实际应用于统计**, 仅作为规范性文档留存。如后续 Condition 需从 91.93% 推至 95%, 可启用 exclude file 补偿。

### 挑战与教训

1. **sum 手算陷阱** — 28 字节逐字节 8-bit wrapping sum 极易在中间步骤出错。关键是分段核对: 每 4 字节一组求和后取 mod 256, 再逐组累加。RTL 行为是唯一真相源。
2. **done 上升沿 vs 电平** — M1 中断逻辑用 `done_i` 上升沿检测; 若 done_stub 已为高电平, 不会再触发中断。Lab1 TC11 Phase 3 必须先清 done 再重新拉高。
3. **Toggle 覆盖率的非线性** — 前 10% 提升 (77→88%) 靠消除 TB 污染+基础多样性; 最后 10% (88→98%) 需要逐信号定位 miss bin 并设计定向激励。
