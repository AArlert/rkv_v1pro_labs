# PPA Risk Register

> 只登记跨角色阻塞、REV P0、当前角色内部自纠错无法收敛的问题。普通语法错误、脚本路径错误、testplan 漏项等应先在当前角色内部修正，不进入本表。

## Open Risks

| Risk ID | Severity | Lab | Owner | From | Status | Summary | Evidence | Next Action |
|---|---|---|---|---|---|---|---|---|
| none | - | - | - | - | - | 当前无登记风险 | - | - |

## Closed Risks

| Risk ID | Closed Time | Resolution | Evidence |
|---|---|---|---|
| - | - | - | - |

## 登记规则

- P0/blocker 必须登记，并同步更新 `memory/design_state.md`、`memory/run_state.md`、`labX/handoff.md`。
- ARCH/RTL/DV 内部自纠错失败后才登记。
- 每条风险必须写清：期望、实际、证据、已排除项、请求 ORCH 做出的决策。
