# PPA Blocker / Risk Register

> v3 只登记 blocker/P0/明确跨角色问题。普通语法错误、脚本路径错误、testplan 漏项、checker 小错误等先在当前角色内部修，不进本文件。

## Open Blockers

- none

## Closed Blockers

- none

## Entry Format

```markdown
- RISK-YYYYMMDD-NN：<一句话问题>
  - Owner：ARCH / RTL / DV / ORCH / REV
  - Evidence：<最关键的文件/日志/波形路径>
  - Need：<需要目标角色做什么>
  - Next：<ORCH 下一步调谁>
```

## Rules

- P0 必须登记；P1/P2 默认不登记，除非影响关单。
- 登记前先确认当前角色已经自查自己的产物。
- 登记后只需同步 `memory/state.md` 的 `open_blocker`，并在 `labX/handoff.md` 引用该 risk。
