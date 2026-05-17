---
name: architect
description: 微架构师。读 spec，决定模块边界、接口契约、CSR 地址图、寄存器属性、FSM 状态划分，输出 design-prompt
model: human
effort: medium
maxTurns: 1-session
skills:
  - manual-apb-protocol
  - manual-csr-attributes
---

## Stage Sequence

1. 读 `doc/ppa-lite-spec.md` 对应章节（Lab1→§2/§4，Lab2→§5，Lab3→§6）
2. 读 `memory/architecture/knowledge.md`（如果之前 Lab 有遗留经验）
3. 在 `lab*/doc/design-prompt.md` 用自己的话**复述** spec（强制自检）
4. 列出：模块端口、CSR 地址表（含复位值/属性）、FSM 状态/转移、错误条件
5. 决定接口边界：M1↔M3 的握手、M2 仲裁策略
6. （可选）让 Copilot Agent 帮我审一遍 design-prompt（reviewer 角色）

## Tool Options

- mermaid 画框图、时序、状态机
- 纸笔（推荐！画时序最快）
- Copilot Agent 用 `skill/copilot-review-rtl` 审 design-prompt 的"可实现性"

## Loop-Back Rules

- 如果 design-prompt 写到一半发现 spec 与自己理解冲突 → 立刻停笔，回头读 spec
- 如果 RTL 角色实现时反馈"接口无法实现/歧义" → 重开本角色修订 design-prompt（不要让 RTL 角色私自改）

## Sign-off Criteria

- [ ] design-prompt.md 含：模块端口表、CSR 表、FSM 图、错误条件、接口约束
- [ ] 与 spec 章节逐条对应（每个段落标 §X.Y 引用）
- [ ] Reviewer Agent 给出 0 个 P0 issue

## Output Format

`lab*/doc/design-prompt.md` 章节结构：
```
1. 模块职责（一句话）
2. 端口表（方向/位宽/含义）
3. CSR 表 / FSM 图 / 关键时序
4. 错误条件枚举
5. 与其他模块的接口契约
6. 不做什么（明确划界）
7. spec 引用列表
```

## Behaviour Rules

- 不写一行 RTL！只输出文档与图
- 任何模糊处都用一行 `> Q: ...` 标记，留给后续角色解答（不要自行假设）
- 决策要给"为什么"（trade-off）

## Memory

读：`memory/architecture/knowledge.md`、spec
写：`memory/architecture/experiences.jsonl`（一条 = 一次重要架构决策）

## Design State

更新 `labs.<labN>.rtl=ready-for-impl` 当 design-prompt 完成
