---
name: review-tb
description: 审 TB 是否存在"假 PASS"：缺 self-check、ref model 与 RTL 同源、testplan 漏 TC
license: MIT
when_to_use: REV 处理 phase=tb / target=tb 或 env 时
inputs:
  - TB 文件路径（labN/verif/tb/*.sv + verif/tests/*.sv + verif/sequences/*.sv）
  - testplan.md
  - ref_model 路径
outputs:
  - 报告 "Where / How-to-fix / Why / How-it-was-done" 四段填充
tools:
  - Read, Grep
---

# Skill: Review TB

## Purpose

防"假 PASS"。常见情况：testcase 只 `$display "PASS"` 没断言；或 ref model 偷懒引用了 RTL 内部信号；或 testplan 列了 8 个 check-point 但 TB 只实现了 5 个。

## When to Use

- REV 接到 `phase=tb` 触发
- lab 关单前的 `target=full` 强制审查也会跑

## Checklist

### A. Self-check 充分性（P0）
- [ ] 每条 testcase 有真实断言（`assert` / scoreboard 比较），不能只 `$display`
- [ ] 比较失败时有清晰的 expected vs actual 打印
- [ ] testbench 顶层至少有 1 个 `$fatal` / `error count > 0 → exit 1` 兜底

### B. Ref model 独立性（P0）
- [ ] ref model 不引用任何 `dut.*` 内部信号
- [ ] ref model 不 `force` / `release` 任何 DUT 信号
- [ ] ref model 算法与 RTL 算法独立实现（同一段代码 copy 过来不算）

### C. testplan 覆盖（P0）
- [ ] testplan.md 中每个 check-point 至少有 1 条 TC
- [ ] spec §10 列出的 "必做场景" N-1～N-4 / E-1～E-6 各有对应 TC（按 lab 范围）

### D. TC 独立性（P1）
- [ ] 不同 TC 之间不共享未复位的状态
- [ ] 随机激励有约束兜底（不出 spec 范围）

### E. 命名（P2）
- [ ] TC 命名能反查 testplan 行号

## Output Mapping

| Checklist 项 | Why 引用 |
|---|---|
| A. 假 PASS | spec §10 验收场景表 + 验收质量要求 |
| B. ref 同源 | testbench 工程通行规则（无 spec 直接条款时引 design-note） |
| C. testplan 漏 | testplan.md 第 N 行 |

## Notes / Gotchas

- "假 PASS" 是教学项目最常见的失分点；这类 bug 应当无条件标 P0
- `$display "PASS"` 没有 assertion 兜底 = 必然 P0
