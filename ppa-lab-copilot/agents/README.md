# Agents — 角色定义与协作协议（v2）

> 本目录定义 5 个角色。在 v2 工作流（见 `../workflow-v2.md`）下，**ORCH/ARCH/RTL/DV 由人扮演，REV 由纯 Agent 担任**。

## 角色清单

| 文件 | 角色 | 担任 | 主要交付 |
|---|---|---|---|
| `orchestrator.md` | ORCH | 人 | 调度 + 执行/维护 SOP + 升级决策 |
| `architect.md` | ARCH | 人 | `lab*/doc/design-prompt.md` |
| `rtl-designer.md` | RTL | 人 + Copilot 补齐 | `lab*/rtl/*.sv` + 最小可验证 tb |
| `dv-engineer.md` | DV | 人 + Copilot 补齐 | `lab*/doc/testplan.md`、`lab*/svtb/`、cov |
| `reviewer.md` | REV | 纯 Agent | `lab*/doc/review_notes.md`（P0/P1/P2） |

## 切换协议（与 v1 同）

切换角色时在 `lab*/doc/log.md` 写：
```
>>> ROLE: rtl-designer @ 2026-05-20 14:00 — 开始实现 W1P start 逻辑
<<< ROLE: rtl-designer @ 2026-05-20 16:30 — 完成
```

## 两层纠错（v2 核心）

每个 agent .md 都明示：
1. **Inner Loop（自纠错）**：在自己阶段内的"产物→自检→重读输入→改产物"循环 + 软上限
2. **Outer Loop（跨 Agent 回退/升级）**：自纠错失败 → 登记 `doc/ppa-risk-register.md` + 更新 `memory/design_state.md` + 更新 `memory/run_state.md` + 写 `lab*/doc/handoff.md`，由 ORCH 重新 dispatch

## 共享状态

唯一跨角色通道：`memory/design_state.md` + `doc/ppa-risk-register.md` + `memory/run_state.md`。任何角色完成 stage 或登记 RISK 后都按原子写更新这三处。

## REV 调用模式

- **按需**：任何 Agent 在自己 inner loop 中觉得需要外部 sanity-check，可调 REV（在 `lab*/doc/log.md` 写一行 `>>> CALL REV @<ts> on <target>`）
- **强制**：labX 关单前 ORCH 必须 dispatch REV 对整 lab（ARCH+RTL+DV 三方产物）做完整审查
- REV 报告若含 P0 → 走升级流程（同跨 Agent 回退）

## 模板

每个 agent .md 按下述骨架：
```
---
name / description / model / effort / maxTurns / skills
---
## Inputs（监控/读取的文件，目录树）
## Outputs（产出文件，目录树）
## Stage Sequence
## Inner Loop（自纠错流程图 + 软上限）
## Outer Loop（跨 Agent 回退条件 + 登记动作）
## Tool Options
## Sign-off Criteria
## Behaviour Rules
## Memory（读哪些 knowledge.md / 写哪些 experiences.md）
## Design State（关心 design_state.md 哪些字段）
```
