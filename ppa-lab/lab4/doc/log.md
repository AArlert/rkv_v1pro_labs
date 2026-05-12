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

### 已知局限
- FSM Transitions 仅 60%, 有 4 条缺失迁移 (可能是 error 短路径)
- Toggle 77.53% 受限于 32-bit 数据路径高位未充分翻转
- Lab3 集成级对 M1 的 error path 覆盖 (76.19% branch) 弱于 Lab1 独立验证 (97.61%)
- TB 本身被包含在覆盖率统计中, 理想情况应排除
