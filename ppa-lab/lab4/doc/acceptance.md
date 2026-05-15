# Lab4 验收标准 (Acceptance Criteria)

> 基于 Spec §11.5 Lab4 验收项定义

## 必做验收项

| # | 验收内容 | 判定方法 | 状态 |
|---|----------|----------|------|
| 1 | 一键回归通过率 100% | 助教执行 `make regress`，Lab1-3 全部 PASS；每个 Lab 必做场景各有 ≥1 条对应 testcase | **PASS** |
| 2 | 五类覆盖率等级验收 | line + branch + condition + FSM + toggle 均 ≥90%（合格）；Questa GUI 现场展示 `make cov` 生成的 HTML 报告 | **PASS** |
| 3 | testplan 文档完整 | lab4/doc/testplan.md 含 Spec §10 全部 14 个验收场景的 TC 映射 | **PASS** |

## 选做验收项

| # | 验收内容 | 判定方法 | 状态 |
|---|----------|----------|------|
| 4 | 覆盖率过滤合规 | 提交覆盖率过滤登记表，逐条列明过滤对象/行数/原因/结论；未登记不得过滤 | **PASS** |
| 5 | UVM 升级 | 纯 SV TB 重构为 UVM 环境，等效回归通过 | **PASS** (Phase 3) |

## 验证命令

```bash
cd ppa-lab/lab4/svtb/sim

# 必做 1: 一键回归
make regress
# 预期: 42 TC / 224 checks ALL PASS (Lab1: 11/74, Lab2: 17/94, Lab3: 14/56)

# 必做 2: 覆盖率报告
make cov
# 预期: covhtmlreport/index.html 总覆盖 ≥90%
# 实际: Stmt 98.40% / Branch 96.25% / Cond 91.93% / FSM 100% / Toggle 98.28% = Total 97.47%

# 必做 3: testplan 文档
cat ../doc/testplan.md | head -20
# 预期: 42 TC 结构化列表, Spec §10 全 14 场景追溯
```

## 覆盖率详情 (必做 2)

| 覆盖率类型 | 达成 | 等级 |
|-----------|------|------|
| Statements (line) | 98.40% | 优良 (≥95%) |
| Branches | 96.25% | 优良 (≥95%) |
| Conditions | 91.93% | 合格 (≥90%) |
| FSM States | 100% | 优秀 (=100%) |
| FSM Transitions | 100% | 优秀 (=100%) |
| Toggles | 98.28% | 优良 (≥95%) |
| **综合** | **97.47%** | **优良** |

等级标准 (Spec §11.5 #2): ≥90% 合格 / ≥95% 优良 / 100% 优秀

## 覆盖率过滤登记 (选做 4)

详见 `lab4/doc/coverage_exclusion.md`，共 3 项合法排除:

| ID | 对象 | 类型 | 排除原因 |
|----|------|------|---------|
| EX-01 | ppa_apb_slave_if / PREADY | Toggle | 硬连线 1，Spec §4 设计意图 |
| EX-02 | ppa_apb_slave_if / PADDR[11:7] | Toggle | 地址空间仅到 0x05C，高位永为 0 |
| EX-03 | ppa_packet_proc_core / FSM default | Branch/Stmt | 2-bit state 仅 3 合法值，state=3 结构性不可达 |

> 注: 以上排除项未实际应用于统计（因已达标），仅作审查记录。