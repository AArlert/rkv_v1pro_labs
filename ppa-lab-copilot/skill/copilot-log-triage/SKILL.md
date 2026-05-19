---
name: copilot-log-triage
description: 让 Copilot Agent 读 run.log / comp.log，提取 FAIL TC、UVM_ERROR、assertion 失败、并归因
license: MIT
when_to_use: 跑完 make regress 想知道"挂了哪些、为啥"
inputs:
  - log 文件路径列表
outputs:
  - PASS/FAIL 统计
  - 每条 FAIL 的：TC 名 / 错误类型 / 关键行号 / 是否建议登记 risk
tools:
  - Read, Grep
---

# Copilot: Log Triage

## Purpose

`run.log` 动辄数千行；让 Agent 一遍读完输出"今天该修什么"。

## When to Use

- 跑完 `make regress` / `make uvm` 之后
- 怀疑 UVM_ERROR 隐藏在 verbosity 之下

## How to Use

Agent SOP：

1. `grep -E "(\[CMP_FINAL_PASS\]|\[CMP_FINAL_FAIL\]|UVM_ERROR|UVM_FATAL|^Error)" <log>`
2. 对每个 FAIL：定位上下 ±20 行
3. 分类：assertion / mismatch / timeout / uvm-build-fail / compile-fail
4. 输出表格 + 建议是否登记到 doc/ppa-risk-register.md

## Output Template

```markdown
## Regression Triage — <date>

| TC | Status | Class | Hint |
|---|---|---|---|
| TC1 | PASS | — | — |
| TC5 | FAIL | mismatch | PSLVERR expected 1 got 0 @ 235ns → 若 DV 自查后仍指向 RTL，登记 RISK-NNNN |
| TC8 | FAIL | timeout | done_o 未拉高 in 10us，看 FSM 是否卡 PROCESS |

## Suggested risk items
- RISK-NNNN: expected / observed / evidence / owner / next action
```

## Notes

- 不替我做 fix；只提示
- 同类错误聚合（10 个 TC 都因为同一个 RTL bug 挂 → 1 个 RISK）
