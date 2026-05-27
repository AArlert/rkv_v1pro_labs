---
name: copilot-review-tb
description: 审 TB 是否存在"假 PASS"风险（缺 self-check、过宽 assertion、ref-model 与 RTL 同源）
license: MIT
when_to_use: dv-engineer 一个 lab 关单前
inputs:
  - TB 文件路径、testplan.md
outputs:
  - P0/P1/P2 review_notes
tools:
  - Read, Grep
---

# Copilot: TB Review

## Checklist

### P0
- [ ] 每条 TC 是否有 self-check（`$display "PASS/FAIL"` 不算！必须 assertion）
- [ ] ref model 是否独立实现（不能简单复用 RTL 内部信号）
- [ ] testplan 列出的 check-points 是否都在 TB 里实现
- [ ] 是否覆盖 spec 必做项每条 ≥1 TC

### P1
- [ ] TC 之间是否互相干扰（共享 stub 信号未复位）
- [ ] 随机化是否有约束兜底

### P2
- [ ] TC 命名是否对应 testplan
