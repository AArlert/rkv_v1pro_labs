# Memory — 二级记忆系统（v6）

> v6：继承 v5 的 `state.md` 单一来源、orchestrator 记忆位、`## RISKs` 段。
> 模板（experiences 条目 / RISK 一条）拆到 [`../template/`](../template/) 单独小文件，不再内联在 workflow-vX.md。
> 详细规则见 [`../workflow-v6.md`](../workflow-v6.md)。

## 结构

```
memory/
├── README.md
├── state.md                  # 单一状态源 (Meta + Cursor + Dispatch + Labs Progress + RISKs + History)
├── orchestrator/
│   ├── knowledge.md          # ORCH 蒸馏页 (≤ 1 页)
│   └── experiences.md        # ORCH 每次决策 / 关单复盘
├── architecture/
│   ├── knowledge.md
│   └── experiences.md
├── rtl/
│   ├── knowledge.md
│   └── experiences.md
└── dv/
    ├── knowledge.md
    └── experiences.md
```

## 写入协议

### state.md（单一状态源）

ORCH 每 session 开头**只读这一份**。包含：
- **Meta**：spec_version / workflow / created
- **Cursor**：`lab` / `phase` ∈ `arch|rtl|dv|review|close` / `last`（≤1 行） / `next`（≤1 行）
- **Dispatch**：`role` ∈ `ARCH|RTL|DV|REV|ORCH-decide` / `reason`
- **Labs Progress**：每 lab 的 `arch/rtl/tb/cov/accept`，取值 `todo/wip/blocked/done`
- **RISKs**：`### Open` / `### Resolved` 两段，每条 RISK 全字段（id / time / from / to / lab.phase / summary / evidence / advice / status / resolution）
- **History**：append-only 表

原子写：
```bash
cp memory/state.md memory/state.md.tmp
# 编辑 .tmp
mv memory/state.md.tmp memory/state.md
```

### experiences.md（无序列表，append-only）

任何角色完成 stage / 学到一次教训 / ORCH 做出决策时，按 [`../template/experiences-entry.md`](../template/experiences-entry.md) 追加一个列表块。蒸馏到 `knowledge.md` 后**不删**。

### knowledge.md

每个 Lab 关单时，把本 lab 的 experiences 蒸馏为 ≤ 1 页：
- 主题分组（≤ 5 个主题）
- 每条 ≤ 3 行
- 引文件:行或 experiences.md 中的"时间 + 场景"作证

## 读取协议

- ORCH 每次 session 开头：`cat memory/state.md`（一次读全，含 RISKs）
- 每个角色启用时读对应 `<domain>/knowledge.md`（不读 experiences.md 全文，太长）
- REV 读 spec + 当前 lab 文件 + `<domain>/knowledge.md`；产物写 `lab*/doc/review_report/<时间戳>-<trigger>-<target>.md`
- `doc/ppa-outlook.htm` 浏览器端 `fetch('../memory/state.md')` 解析渲染（v4 起）

## 与 git 的关系

- `state.md` / `knowledge.md` / `experiences.md` → **commit**
- 临时 `*.tmp` → `.gitignore`

## v3 → v6 迁移说明

**v3 → v4**：

| v3 | v4 |
|---|---|
| `doc/ppa-risk-register.md`（详情） + `state.md` 的 `Open RISKs` 摘要表 | **合并** → `state.md` 的 `## RISKs` 段，每条全字段 |
| `lab*/doc/review_report/INDEX.md`（手工目录） | **删除**；按时间戳文件名的目录列表即索引 |
| ORCH "SOP 自维护反思"（独立仪式） | 降级为 `orchestrator/experiences.md` 一条普通关单复盘 |

**v4 → v5**：

| v4 | v5 |
|---|---|
| 模板（handoff/acceptance/log/testplan/cov_exclusion/experiences）散落或缺失 | 全部内嵌 `workflow-v5.md` §7 |
| Skill ↔ Agent 对应散落 | 单一矩阵 `workflow-v5.md` §4 |
| `Cursor.phase` 含 `close` 但从不使用 | 枚举去 `close`（关单由 `Labs Progress.<lab>.accept=done` 表达） |
| EDA 工具版本无处明示 | 锁定 VCS/Verdi/Spyglass 2018 + Ubuntu 22.04 |
| 无 Spyglass | 新增 `manual-spyglass-lint` skill；RTL Sign-off 加一条 |

**v5 → v6**：

| v5 | v6 |
|---|---|
| 模板内嵌 `workflow-v5.md` §7 | 拆到 `../template/*.md` 单独小文件；workflow 不再内联 |
| 完整文件树在 `workflow-v5.md` §3 | 搬到 `../doc/ppa-outlook.htm` 新章 + `../doc/ppa-plan.md` §1.2 |
| REV 不直接跑 EDA | REV 可经 `make <target>` 在本机重跑 VCS/Verdi/Spyglass |
| ppa-plan.md 与 workflow/agents 内容重复 | 蒸馏为人用计划，删 §1.2/§1.4-1.5/§2/§9 重复段 |

旧 `doc/ppa-risk-register.md` 已在 v4 移除；如需历史可查 git。
