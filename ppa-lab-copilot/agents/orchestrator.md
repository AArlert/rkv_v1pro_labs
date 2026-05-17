---
name: orchestrator
description: 项目流水线调度者，读 design_state.json 决定下一步该哪个角色干什么；本仓库由人扮演，未来 harness 化交给 meta-agent
model: human
effort: medium
maxTurns: unbounded
skills: []
---

## Stage Sequence

每个 session 开头都按以下 SOP：

1. `cat memory/design_state.json` 查看 `current_lab` / `current_stage` / open `fix_requests[]`
2. 检查 `memory/run_state.md` 中上次中断点
3. 决定本次 session 的目标：推进 stage？修 FR？跑回归？
4. 选择要扮演的角色，读对应 `agents/<role>.md`
5. （可选）请 Copilot Agent 协助 = 调用对应 `skill/copilot-*` skill
6. 执行
7. Session 结束：append `history[]`、更新 `current_stage`、写 handoff

## Tool Options

| 工具 | 调用方 | 用途 |
|---|---|---|
| `vcs / verdi` | 我 | 跑仿真、看波形 |
| `xwave` | Copilot Agent | FSDB 波形 NPI 查询 |
| `xtrace` | Copilot Agent | RTL driver/load 追踪 |
| `make smoke/regress/cov` | 我 | 一键回归 |

## Loop-Back Rules

| 触发 | 动作 | 上限 |
|---|---|---|
| TC FAIL | DV 写 fix_request → 切 RTL 角色修 | 同 FR 重开 ≤ 3 次 |
| 覆盖率 < 90% | DV 加 TC / covergroup | 一个 Lab 加 ≤ 5 轮 |
| spec 与实现冲突 | 切 Architect 角色重审 | 立即停手，不要继续写代码 |
| Copilot 给的代码我看不懂 | 拒绝接受，改回手写 | 总在 Copilot 输出>3 行时触发 |

## Sign-off Criteria

每个 Lab 关单条件：
- [ ] `lab*/doc/acceptance.md` 全部必做项 ✅
- [ ] `lab*/doc/handoff.md` 已写
- [ ] `memory/<domain>/knowledge.md` 已 distill 本 Lab 的经验
- [ ] `memory/design_state.json` 中本 lab 的 `accept` 字段=`done`

## Output Format

handoff 段落直接写入 `lab*/doc/handoff.md`：
```
## Handoff: Lab<N> → Lab<N+1> (date)
### I did
### I didn't / TODO
### Gotchas
### Min verify cmd
### Next steps
```

## Behaviour Rules

- 永远先读 spec，再读 knowledge.md，最后才写代码
- 任何"复制 /ppa-lab/ 代码"的动作立刻拒绝
- 同一天最多扮演 2 个角色，避免上下文糊掉
- 每个 stage 结束必写 experiences.jsonl 一条

## Memory

读：`memory/*/knowledge.md`、`memory/design_state.json`
写：`memory/design_state.json`（history/state）、`memory/run_state.md`

## Design State

关心字段：`current_lab`、`current_stage`、`labs.*.{rtl,tb,cov,accept}`、`fix_requests[]`、`cross_role_iteration_count`
