---
name: review-rtl
description: 按 checklist 审 RTL 文件：可综合性、正确性、端口与 spec 对齐
license: MIT
when_to_use: REV 处理 phase=design / target=rtl-* 时
inputs:
  - RTL 文件路径
  - 对应 design-note.md
  - spec 对应模块章节（§2.3, §5, §6）
outputs:
  - 报告 "Where / How-to-fix / Why / How-it-was-done" 四段填充
tools:
  - Read, Grep
---

# Skill: Review RTL

## Purpose

枚举 RTL 中违反 spec、违反可综合性、违反"教科书 SV 写法"的真实 bug，每条转成四段式报告条目。

## When to Use

- REV 接到 `phase=design` 的触发
- 学生在 `labN/rtl/` 下新增/修改了 `.sv` 文件
- 与 `review-spec-alignment` 联动使用（端口/CSR/FSM 对齐归后者）

## Checklist

### A. 端口与对外接口（→ 通常归 `review-spec-alignment`，本 skill 只兜底）
- [ ] 端口列表与 spec §2.3 100% 一致（名称/方向/位宽）
- [ ] 模块名与 spec §2.2 一致

### B. 复位与时序
- [ ] 异步 assert + 同步 deassert（或全项目统一约定）
- [ ] `always_ff` 内只用非阻塞赋值 `<=`，`always_comb` 只用阻塞 `=`
- [ ] 时钟单源；无组合反馈环

### C. 组合逻辑
- [ ] `always_comb` 所有分支覆盖（无 latch）
- [ ] case 有 default 兜底
- [ ] 无 multi-driver

### D. CSR（M1 专属）
- [ ] CSR 默认值与 spec §5.x 一致
- [ ] CSR 属性正确：RW/RO/W1P/RW1C 按规范实现
- [ ] 地址译码无漏译码、无重叠

### E. FSM（M3 专属）
- [ ] 所有状态可达；无 unreachable
- [ ] DONE 态信号保持行为符合 spec §6.x
- [ ] start_i 的边沿/电平处理与 spec 一致

### F. 可读性（P2 区，不强求）
- [ ] 命名 snake_case
- [ ] 关键 always 块前有意图注释

## Output Mapping（checklist 项 → 报告四段）

| Checklist 项 | Where | Why 引用 |
|---|---|---|
| B. 时序混用 | `file:line` of 错误赋值 | "可综合性常识 + spec §1.4 SV 语言要求" |
| D. CSR 默认值错 | `file:line` of `<reg> <= <wrong>;` | spec §5.x 表 |
| E. FSM 漏状态 | `file:line` of case 语句 | spec §6.1 状态图 |

## Notes / Gotchas

- VCS / Spyglass 已经能报的（latch、multi-driver）不要重复指出，只在 sim/lint log 里没看到时才补
- 端口对齐违例属于"硬性 P0"，必须在报告头部加 `[ESCALATE]`
- `How-it-was-done` 段不要羞辱学生；只指出 spec 的哪行可能被漏看
