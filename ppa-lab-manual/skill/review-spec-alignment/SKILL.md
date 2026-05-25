---
name: review-spec-alignment
description: 端口 / CSR / FSM 三轴严格对齐 spec；任何不一致 = 强 P0
license: MIT
when_to_use: 任何 phase=design 审查中由 review-rtl 内部调起
inputs:
  - RTL 文件路径
  - doc/ppa-lite-spec.md
outputs:
  - 报告 "Where / How-to-fix / Why / How-it-was-done" 四段填充（标 [ESCALATE]）
tools:
  - Read, Grep
---

# Skill: Review Spec Alignment

## Purpose

PPA-Lite 的 spec 是 **immutable ground truth**（见 memory）。本 skill 做"机械对齐"：把 RTL 里的端口、CSR、FSM 三组事实抓出来，与 spec 表逐字比对。

## When to Use

- `review-rtl` 处理 `target=rtl-*` 时强制内嵌调用
- 学生从 spec 抄端口可能漏一行；本 skill 是兜底

## 三轴

### 轴 1 — 端口对齐
比对 RTL `module` 块端口表 vs spec §2.3 表：
- 端口名（大小写敏感）
- 方向 input/output
- 位宽 [N:0]

任何 1 个差异 → P0 `[ESCALATE]`。

### 轴 2 — CSR 对齐（M1 / apb_slave_if）
比对 RTL 中地址译码 / 默认值 vs spec §5 寄存器表：
- 地址偏移
- 字段位宽
- reset value
- 属性（RW / RO / W1P / RW1C）

### 轴 3 — FSM 对齐（M3 / packet_proc_core）
比对 RTL FSM 状态机 vs spec §6 状态图：
- 状态数量与命名
- 转移条件
- DONE 态保持行为

## Checklist

- [ ] 列出 RTL 中所有端口 → 与 spec §2.3 表逐行 diff
- [ ] M1：列出所有 CSR offset 与 reset → 与 spec §5 表 diff
- [ ] M3：从 RTL case/typedef 提取 FSM 状态 → 与 spec §6 diff

## Output Mapping

每条差异 → 报告四段：
- **Where**: `file:line` 的端口/case/默认值
- **How-to-fix**: 改成 spec 里的写法（具体到位宽/字面值）
- **Why**: 引 spec §X.Y 表 / 状态图
- **How-it-was-done**: 推测学生是从旧版 spec / design-note 推断的（可能 design-note 与 spec 表述不一致 → spec 优先）

## Notes / Gotchas

- 本 skill 不允许"宽容判定"。即使是 `data` vs `pdata` 这种顺手小写差异，也是 P0
- 学生如果发现 spec 本身有歧义 → 报告里加一行 "[SPEC-AMBIGUITY] suggest ARCH clarify §X.Y"，但仍按 spec 字面意思判 P0（spec 不可改）
