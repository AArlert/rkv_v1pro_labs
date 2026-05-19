---
name: orchestrator
description: 项目流水线调度者。执行并维护 SOP。读 memory/state.md（单一状态源）决定下一步谁干什么。
model: human
effort: medium
maxTurns: unbounded
skills: []
---

## Inputs（监控/读取）

```
ppa-lab-copilot/
├── doc/
│   ├── ppa-lite-spec.md          ← 只读（spec 不可改）
│   ├── ppa-plan.md
│   └── ppa-risk-register.md      ← state.md 中 Open RISKs 非空时才读详情
├── memory/
│   ├── state.md                  ← 单一状态源：Cursor / Dispatch / Labs Progress / Open RISKs / History
│   ├── orchestrator/knowledge.md ← 本角色蒸馏页
│   ├── architecture/knowledge.md
│   ├── rtl/knowledge.md
│   └── dv/knowledge.md
└── lab*/doc/
    ├── handoff.md                ← 跨 Agent 交接上下文
    ├── log.md                    ← ROLE 切换记录
    └── review_report/            ← REV 报告档案
        ├── INDEX.md
        └── <YYYYMMDD>-<HHMM>-<trigger>-<target>.md
```

## Outputs（产出）

```
ppa-lab-copilot/
├── memory/
│   ├── state.md                  ← 推进 Cursor / Dispatch / Labs / Open RISKs / History（原子写）
│   └── orchestrator/
│       ├── experiences.md        ← 每次决策 / SOP 反思 append 一条
│       └── knowledge.md          ← 每 lab 关单蒸馏
├── doc/
│   └── ppa-risk-register.md      ← 关闭/转派 RISK 时写 resolution
└── lab*/doc/
    ├── handoff.md                ← labN→labN+1 关单交接
    └── log.md                    ← ROLE 调度记录
```

## Stage Sequence（5 步 SOP，比 v2 少 1 步）

1. `cat memory/state.md`（一次读全：Cursor + Dispatch + Open RISKs）
2. `Open RISKs` 非空 → `tail doc/ppa-risk-register.md` 看详情
3. 决策：
   - `Dispatch.role` 是具体角色 → 沿用
   - `Dispatch.role == ORCH-decide` 或有 open RISK → 重新决策（选 ARCH/RTL/DV/REV）
4. dispatch `<role>`：在 `lab*/doc/log.md` 写 `>>> ROLE: <role> ...`
5. 角色执行后收尾：append 对应 `experiences.md` + 原子写 `memory/state.md`（更新 Cursor / Dispatch / Labs / History）

```mermaid
flowchart LR
    O1["1 cat memory/state.md"] --> O2{"Open RISKs 非空?"}
    O2 -- "是" --> O3["tail risk-register"]
    O2 -- "否" --> O4
    O3 --> O4{"Dispatch=ORCH-decide<br/>or RISK open?"}
    O4 -- "是" --> O5a["决策选角色"]
    O4 -- "否" --> O5b["沿用 Dispatch.role"]
    O5a --> O6["dispatch <role>"]
    O5b --> O6
    O6 --> O7["角色执行 (Inner Loop)"]
    O7 --> O8["收尾: experiences + 原子写 state.md"]
```

## Inner Loop（ORCH 自纠错 = SOP 自维护）

每 lab 关单后做 1 次 SOP 反思（≤ 5 分钟）：

```mermaid
flowchart LR
    L1["labX 关单"] --> L2["复盘本 lab 所有 RISK"]
    L2 --> L3{"有 RISK 本可<br/>在 Agent 内消化?"}
    L3 -- "是" --> L4["把场景写进对应<br/>agents/<role>.md 的 Inner Loop"]
    L3 -- "否" --> L5["归档"]
    L4 --> L6["记一条到<br/>memory/orchestrator/experiences.md"]
    L5 --> L6
```

软上限：每关 1 个 lab，SOP 反思 1 次。

## Outer Loop（ORCH 接收升级）

ORCH 是升级链终点。触发与响应：

| 触发 | 来源 | 响应 |
|---|---|---|
| 跨 Agent 回退 RISK | ARCH/RTL/DV | `Labs Progress.<phase>` 改 `blocked`；`Dispatch.role` 指定接手者；下次 dispatch 该角色 |
| REV P0 RISK | REV | 同上，接手者由 P0 指向决定（看 review_report.md 里 P0 项的文件归属） |
| 自纠错预算耗尽 RISK | 任何 Agent | 重读 spec → 判断"设计假设错 / TB 假设错 / spec 理解错" → 选角色 |
| 同一 RISK 重开 ≥ 3 次 | — | 停下来重读 spec；必要时把 RISK 改 `dropped` 并写明 |

## Tool Options

| 工具 | 用途 |
|---|---|
| `vcs / verdi` | 跑仿真、看波形（人手工） |
| `make smoke/regress/cov` | 一键回归（关单审查前跑一次） |
| Copilot Agent | 提示阅读 spec / 蒸馏 experiences |
| **xwave / xtrace** | **REV 专用**（ORCH 不直接调） |

## Sign-off Criteria（每个 lab 关单条件）

- [ ] `lab*/doc/acceptance.md` 全部必做项 ✅
- [ ] REV 在 `lab*/doc/review_report/<...>-labclose-full.md` 给出 0 P0 报告
- [ ] `lab*/doc/handoff.md` 已写到下个 lab
- [ ] 四类 `memory/<domain>/knowledge.md`（含 orchestrator）已蒸馏
- [ ] `memory/state.md` 中本 lab 的 `accept = done`
- [ ] SOP 反思已记一条到 `memory/orchestrator/experiences.md`

## Behaviour Rules

- **永远先读 state.md（一次读全）**，再决策
- 拒绝任何"复制 /ppa-lab/ 代码"动作
- 同一天最多扮演 2 个角色
- 每个 stage 结束必写 experiences.md 一条
- SOP 反思不可跳过（每 lab 1 次）

## Memory

- 读：`memory/state.md`、`memory/*/knowledge.md`
- 写：`memory/state.md`（Cursor / Dispatch / Labs / Open RISKs / History）、`memory/orchestrator/experiences.md`

## State（更新 state.md 哪些字段）

- 推进时：`Cursor.lab/phase/last/next` + `Dispatch.role/reason` + `History` +1
- 关单时：`Labs Progress.lab<N>.{arch,rtl,tb,cov,accept}` 全部 `done`
- 处理 RISK：`Open RISKs` 表追加/关闭一行；`Labs Progress.<phase>` 标 `blocked` 或恢复 `wip`
