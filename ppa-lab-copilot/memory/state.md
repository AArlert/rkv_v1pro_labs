# State (Single Source of Truth)

> v3：合并 v2 的 `run_state.md` + `design_state.md`。ORCH 每 session 开头**只读这一份**。原子写：`cp state.md{,.tmp} && 编辑.tmp && mv .tmp state.md`。

## Meta

| 字段 | 值 |
|---|---|
| spec_version | `ppa-lite-spec.md@2026-04-13` |
| created | 2026-05-18 |
| workflow | `workflow-v3.md` |

## Cursor

- **lab**: lab1
- **phase**: arch              <!-- arch | rtl | dv | review | close -->
- **last**: ORCH 完成 v3 工作流迁移（state.md 合并 / review_report/ 目录化 / orchestrator 记忆位）— 2026-05-19
- **next**: 切 ARCH 角色，读 spec §2/§4，开始写 lab1/doc/design-prompt.md

## Dispatch

- **role**: ARCH               <!-- ARCH | RTL | DV | REV | ORCH-decide -->
- **reason**: 进入 lab1 架构阶段

## Labs Progress

| Lab | arch | rtl | tb | cov | accept |
|---|---|---|---|---|---|
| lab1 | wip  | todo | todo | todo | todo |
| lab2 | todo | todo | todo | todo | todo |
| lab3 | todo | todo | todo | todo | todo |
| lab4 | todo | todo | todo | todo | todo |

> 取值：`todo / wip / blocked / done`。出现跨 Agent 回退 → 把对应字段改 `blocked` + `Dispatch.role` 指接手者 + RISK 入下表。

## Open RISKs（摘要；详情见 `doc/ppa-risk-register.md`）

| RISK id | from → to | lab.phase | 一句话现象 | 状态 |
|---|---|---|---|---|
| — | — | — | — | — |

## History

| 时间 | role | action | ref |
|---|---|---|---|
| 2026-05-18T00:00 | ORCH | project initialized | doc/ppa-plan.md |
| 2026-05-18T12:00 | ORCH | v2 落地（agents/memory/risk-register 对齐 v2） | workflow-v2.md |
| 2026-05-19T08:30 | ORCH | v3 落地（state.md 合并 / review_report 目录 / orchestrator 记忆位） | workflow-v3.md |
