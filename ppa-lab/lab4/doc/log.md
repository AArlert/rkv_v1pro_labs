# Lab4 实验日志 (Log)

## Status: Phase 1 完成 — Makefile + 全量回归 + 覆盖率基线

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

TB 的 check macro (`actual === expected`)、fail 计数器 (`fail_cnt`)、timeout 逻辑被纳入覆盖率统计。这些代码在全 PASS 回归中 false 分支永远不走, 导致 `/ppa_tb` 实例 branch=50%, condition=25%, toggle=67.82%。

修复方法: Makefile `cov` target 的 vlog 拆成两步, RTL 用 `-cover bcstf`, TB 不加 `-cover`。

#### 根因 B: 缺少异步复位测试

FSM 缺失迁移 (ppa_packet_proc_core.sv:131):
- `S_PROCESS → S_IDLE` (处理中途 reset)
- `S_DONE → S_IDLE` (完成态 reset)

所有 TB 在仿真开头一次性复位 (FSM 必在 S_IDLE), 之后不再 reset。`rst_n` 也只有 0→1 方向。

修复方法: 新增 mid-sim reset TC, FSM Transitions 60% → 100%。另: `case(state) default` (line 243) 是结构性不可达, 应登记为排除项。

#### 根因 C: 跨 Lab 实例重复统计

`ppa_apb_slave_if` 两个实例: Lab1 独立 (branch 97.61%) 和 Lab3 集成 (branch 76.19%)。Lab3 集成测试不覆盖 CSR error path (`!is_valid_addr`/`write_ro`/`err_irq`), 拉低了 M1 的覆盖率。

修复方法: ① `vcover merge -du` 按 Design Unit 合并; ② 新增 Lab3 err_irq E2E TC。

#### 根因 D: 测试数据多样性不足

32-bit 数据路径高位未充分翻转 (`res_pkt_type_o[3:7]`, `res_pkt_len_o[4]`, `exp_pkt_len_i` 等)。`PREADY` 硬连线 1 和 `PADDR[7:11]` 设计意图上不会翻转, 应排除。

修复方法: 增加 payload 多样性 (0xFF/0xAA/0x55); 建立覆盖率排除登记表。
