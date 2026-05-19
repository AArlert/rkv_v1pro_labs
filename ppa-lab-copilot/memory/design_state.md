# Design State

> 跨角色共享状态。由 `workflow-v2.md` 定义；任何角色完成 stage / 提 RISK 都要更新。原子写：先改副本再 `mv` 替换。

## Meta

| 字段 | 值 |
|---|---|
| spec_version | `ppa-lite-spec.md@2026-04-13` |
| created | 2026-05-18 |
| current_lab | lab1 |
| current_stage | architect-design-prompt |
| cross_role_iteration_count | 0 |

## Labs Progress

| Lab | rtl | tb | cov | accept |
|---|---|---|---|---|
| lab1 | wip | todo | todo | todo |
| lab2 | todo | todo | todo | todo |
| lab3 | todo | todo | todo | todo |
| lab4 | todo | todo | todo | todo |

> 取值：`todo / wip / blocked / done`；当出现回退时把对应字段改回 `wip` 并在 history 写明。

## Open RISKs（与 `doc/ppa-risk-register.md` 对应）

| RISK id | from | to | lab/stage | 现象 | 状态 |
|---|---|---|---|---|---|
| —  | — | — | — | — | — |

## History

| 时间 | role | action | ref |
|---|---|---|---|
| 2026-05-18T00:00 | ORCH | project initialized | doc/ppa-plan.md |
