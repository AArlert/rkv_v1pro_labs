---
name: copilot-review-rtl
description: 按 checklist 审 RTL 文件，找可综合性/正确性/可读性问题，输出 P0/P1/P2 review_notes
license: MIT
when_to_use: rtl-designer 完成一个模块后 sign-off 前
inputs:
  - RTL 文件路径
  - 对应 design-prompt.md
  - 对应 spec 章节
outputs:
  - markdown review_notes，含 P0/P1/P2 分类
tools:
  - Read, Grep, xtrace (可选)
---

# Copilot: RTL Review

## Checklist

### P0 — 必须修
- [ ] 端口列表是否与 design-prompt 表 100% 一致（名称/方向/位宽）
- [ ] 复位策略：异步 assert + 同步 deassert？
- [ ] 是否有 latch（`always_comb` 内分支未覆盖）
- [ ] 是否有 multi-driver
- [ ] CSR 默认值与 spec 一致
- [ ] CSR 属性：RW/RO/W1P/RW1C 是否按规范实现
- [ ] FSM：是否有未达成状态？default 是否安全？
- [ ] 时序错误：`always_ff` 内组合赋值、阻塞/非阻塞混用

### P1 — 应该修
- [ ] 信号命名是否符合 spec
- [ ] 不必要的逻辑（防御性代码）
- [ ] 模块边界是否清晰

### P2 — 锦上添花
- [ ] 注释（仅"为什么"，不写"什么"）

## Output Format

参考 `agents/reviewer.md` 的 Output Format。每条 P0 必须引：
- `<file>:<line>` 指出问题位置
- spec §X.Y 或 design-prompt §Z 引述违反的条款
- 1 句建议修法

## Behaviour

- 不直接改文件
- 不抠 style
- 不重复 lint 已覆盖的（latch / multi-driver 这些 VCS 自带 lint 报）
