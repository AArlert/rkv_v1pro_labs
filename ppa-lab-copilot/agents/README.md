# Agents — 角色定义与协作协议

本目录定义本仓库的 5 个角色。我（人）轮流扮演这些角色；未来的 `ppa-lab-harness` 仓库会把这些角色交给独立 Agent。

## 角色清单

| 文件 | 角色 | 主要交付物 |
|---|---|---|
| `orchestrator.md` | Orchestrator（流水线调度） | `memory/design_state.json` 更新、stage 路由 |
| `architect.md` | 微架构师 | `lab*/doc/design-prompt.md`、CSR 表、模块划分 |
| `rtl-designer.md` | RTL 工程师 | `lab*/rtl/*.sv`、lint 通过 |
| `dv-engineer.md` | 验证工程师 | `lab*/doc/testplan.md`、`lab*/svtb/`、cov 报告 |
| `reviewer.md` | 评审者（通常由 Copilot Agent 担任） | review_notes（含 P0/P1/P2 issue） |

## 切换协议

每次切换角色时，**必须**在当前 lab 的 `doc/log.md` 写一行：
```
>>> ROLE: rtl-designer @ 2026-05-20 14:00 — 开始实现 W1P start 逻辑
... 工作内容 ...
<<< ROLE: rtl-designer @ 2026-05-20 16:30 — 完成，FR-0001 已 open
```

这样未来 harness 化时可以把每段 log 精确归属到某个 agent。

## 共享状态

唯一跨角色通道是 `memory/design_state.json`。任何角色完成 stage 后：
1. `cp design_state.json design_state.json.tmp`
2. 修改 tmp（更新 `current_stage` / append `history[]` / 提交 `fix_requests[]`）
3. `mv design_state.json.tmp design_state.json` 原子替换

## Fix-Request 闭环

见 `ppa-plan.md §2.5`。同一 FR 反复打开 ≥ 3 次时，Orchestrator 必须停下来重读 spec。

## 模板格式

每个角色文件按下列骨架填写（参考 chuanseng-ng/digital-chip-design-agents）：

```markdown
---
name: <role-name>
description: 一句话职责
model: human / copilot
effort: low/medium/high
maxTurns: <int>
skills:
  - manual-<topic>
  - copilot-<topic>
---

## Stage Sequence
## Tool Options
## Loop-Back Rules
## Sign-off Criteria
## Output Format (JSON 或 markdown)
## Behaviour Rules
## Memory（读哪些 knowledge.md / 写哪些 experiences.jsonl）
## Design State（关心 design_state.json 的哪些字段）
```
