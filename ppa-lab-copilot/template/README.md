# template/ — 标准模板（v6 起）

> **干活时直接复制粘贴用的样板**。每个文件 ≤ 30 行，3 分钟读完、5 行内写完。
> 工作流维护文档（`workflow-vX.md`）不再内联这些模板，agent .md 引用本目录即可。

## 索引

| 文件 | 用在哪 | 谁写 |
|---|---|---|
| [`log-role.md`](log-role.md) | `lab*/doc/log.md` ROLE 块 | 任意角色（每次进入/退出） |
| [`log-call-rev.md`](log-call-rev.md) | `lab*/doc/log.md` 按需调 REV 一行 | ARCH / RTL / DV |
| [`handoff.md`](handoff.md) | `lab*/doc/handoff.md` 跨 Agent 交接段 | 回退方 + lab 关单方 |
| [`acceptance.md`](acceptance.md) | `lab*/doc/acceptance.md` 关单自检 | DV 维护，ORCH 关单前查 |
| [`testplan-row.md`](testplan-row.md) | `lab*/doc/testplan.md` 单条 TC 行 | DV |
| [`coverage-exclusion-row.md`](coverage-exclusion-row.md) | `lab*/doc/coverage_exclusion.md` 单条豁免 | DV，ORCH 批 |
| [`experiences-entry.md`](experiences-entry.md) | `memory/<domain>/experiences.md` 单条经验 | 所有角色 |
| [`risk-entry.md`](risk-entry.md) | `memory/state.md` 的 `## RISKs` 一条 | 登记方（见 outer loop） |
| [`review-report.md`](review-report.md) | `lab*/doc/review_report/<...>.md` 报告骨架 | REV |

## 使用规则

1. **复制粘贴**到目标位置，不要 include / 软链——保持每个 lab 的文档自包含。
2. 模板里的 `<尖括号>` 是占位符，写实即可；不要保留尖括号。
3. 模板**只长不缩**：项目里发现需要新增字段，先改本目录的 master，再回填各 lab。
4. `template/` 自身不参与 lab 关单审查；REV 不审 template/。
5. 模板和 `memory/state.md` 内已有的"模板"段是**单源**——RISK 的模板以 `memory/state.md` 内的 `### 模板` 段为准，`risk-entry.md` 仅做指针。

## 与 workflow-vX 的边界

- `workflow-vX.md` = 工作流**维护**文档（差异、设计决策、约束）。
- `template/` = 干活时**直接用**的样板（不解释为什么，只给样子）。
- 两者交集为零；如果模板有"为什么"的解释，写到 workflow-vX.md，本目录只放样板。
