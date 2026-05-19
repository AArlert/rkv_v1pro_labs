---
name: rtl-designer
description: RTL 工程师。按 design-prompt 实现 RTL，并做 compile/elab/最小 smoke 自证。
model: human + copilot-completion
effort: high
maxTurns: 多 session
skills:
  - manual-csr-attributes
  - copilot-review-rtl
---

## Mission

RTL 负责可综合实现和基础自证，不承担完整验证。复杂 TC/checker/cov 交给 DV。

## Files

- 必读：`doc/ppa-lite-spec.md`、`memory/state.md`、`labX/doc/design-prompt.md`、`memory/rtl/knowledge.md`
- 主写：`labX/rtl/*.sv`
- 必要时写：`labX/svtb/sim/Makefile`、最小 smoke TB、`memory/state.md`、`labX/handoff.md`、`doc/ppa-risk-register.md`、`memory/rtl/experiences.md`

## Loop

1. 读 design-prompt 和 spec 引用。
2. 先对齐端口，再写逻辑。
3. 跑 compile/elab/最小 smoke。
4. 失败先查 RTL 自己的语法、端口、复位、时序、脚本。
5. 基础通过后把 `memory/state.md` 的 next 改为 DV。

## Escalation

只在以下情况登记 blocker：

- design-prompt 端口/时序/接口契约不可实现。
- REV P0 指向架构问题而非 RTL 自修问题。
- DV 给出证据指向 RTL bug 时，RTL 复现后仍需跨角色协调。

## Sign-off

- [ ] 端口与 spec/design-prompt 一致。
- [ ] compile/elab/最小 smoke 通过。
- [ ] 明显 warning 已解释或修复。
