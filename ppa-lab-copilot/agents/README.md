# Agents — 角色定义与协作协议（v3）

> 5 个角色，ORCH/ARCH/RTL/DV 由人扮演，REV 由纯 Agent 担任。详细工作流见 `../workflow-v3.md`。

## 角色清单

| 文件 | 角色 | 担任 | 主要交付 |
|---|---|---|---|
| `orchestrator.md` | ORCH | 人 | 调度 + 执行/维护 SOP + 升级决策 |
| `architect.md` | ARCH | 人 | `lab*/doc/design-prompt.md` |
| `rtl-designer.md` | RTL | 人 + Copilot 补齐 | `lab*/rtl/*.sv` + 最小可验证 tb |
| `dv-engineer.md` | DV | 人 + Copilot 补齐 | `lab*/doc/testplan.md` + `lab*/svtb/` + cov |
| `reviewer.md` | REV | 纯 Agent | `lab*/doc/review_report/<时间戳>-<trigger>-<target>.md` |

## 切换协议

切换角色时在 `lab*/doc/log.md` 写：
```
>>> ROLE: rtl-designer @ 2026-05-20 14:00 — 开始实现 W1P start 逻辑
<<< ROLE: rtl-designer @ 2026-05-20 16:30 — 完成
```

## 两层纠错（与 v2 同）

每个 agent .md 都明示：
1. **Inner Loop（自纠错，不出阶段）**：产物→自检→重读输入→改产物 + 软上限
2. **Outer Loop（跨 Agent 回退/升级，出阶段）**：自纠错失败 → "登记" + "交接" → ORCH 重新 dispatch

## v3 关键约束

- **状态单一来源**：`memory/state.md` 是 ORCH 与所有 Agent 共享状态的唯一文件。任何角色更新状态都改这一份（原子写）。
- **登记 vs 交接 职责分离**：
  - 登记 = `memory/state.md`（Open RISKs 摘要 + Labs Progress + History + Dispatch 改向）+ `doc/ppa-risk-register.md`（详情）
  - 交接 = `lab*/doc/handoff.md`（人读上下文）
- **REV 报告归档**：每份独立文件存 `lab*/doc/review_report/<YYYYMMDD>-<HHMM>-<trigger>-<target>.md`，**永不覆盖**。
- **ORCH 有自己的记忆位**：`memory/orchestrator/{experiences,knowledge}.md`。

## REV 调用模式

- **按需**：任何 Agent 在自己 Inner Loop 中需要外部 sanity-check，调 REV（在 `lab*/doc/log.md` 写 `>>> CALL REV @<ts> on <target>`）
- **强制**：labX 关单前 ORCH 必须 dispatch REV 对整 lab 三方产物做完整审查（trigger=`labclose`）
- REV 报告若含 P0 → 升级流程（同跨 Agent 回退）

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
## Outer Loop（跨 Agent 回退条件 + 登记动作 + 交接动作）
## Tool Options
## Sign-off Criteria
## Behaviour Rules
## Memory（读哪些 knowledge.md / 写哪些 experiences.md）
## State（更新 state.md 哪些字段）
```
