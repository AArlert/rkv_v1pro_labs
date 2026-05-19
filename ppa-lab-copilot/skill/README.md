# Skills — 命名规约与索引（v6）

两类 skill 共用 SKILL 规范（每个 skill 一个目录，含 `SKILL.md`，带 YAML frontmatter）。
v5 起本 README 显式登记每条 skill 的**消费者（哪些 agent 调用）**；v6 不变。

## 命名

| 前缀 | 含义 | 谁可以调 |
|---|---|---|
| `copilot-*` | 给 AI Agent 用的 skill — 描述 Agent 该如何分析/审查/生成 | 任意 agent（含 REV） |
| `manual-*` | 给人用的知识卡片 — 边学边写、答辩复习、工作中复用 | 人（ORCH/ARCH/RTL/DV）；**禁止 REV** |

> 规则源自 v5 决定：REV 只读机器可解析的 SOP，不读人的速查卡，避免审查时被"看上去合理但缺证据"的口诀带偏。

## SKILL.md 模板

```markdown
---
name: <kebab-name>
description: 一句话用途，决定何时被调用
license: MIT
when_to_use: 一句话触发条件
inputs:  [输入文件/参数]
outputs: [输出格式]
tools:   [依赖的外部工具（如 xwave, xtrace, vcs, verdi, spyglass）]
---

# <Title>
## Purpose
## When to Use
## How to Use
## Example
## Notes / Gotchas
```

## 索引（Consumers 列即 agent 分配）

### Copilot skills（AI Agent 直接执行）

| Skill | 用途 | 依赖工具 | Consumers |
|---|---|---|---|
| copilot-wave-analyze | 用 xwave 查 FSDB 波形答疑 | xwave | REV |
| copilot-rtl-trace    | 用 xtrace 追 driver/load 解释 RTL 行为 | xtrace | REV |
| copilot-log-triage   | 分析 run.log / vcs.log 归因 FAIL | grep | RTL, DV, REV |
| copilot-review-rtl   | 按 checklist 审 RTL 可综合性/正确性 | Read | REV |
| copilot-review-tb    | 审 TB 是否存在"假 PASS"风险 | Read | REV |
| copilot-make-script  | 生成/修订 VCS+Verdi Makefile | — | RTL, DV, REV |

### Manual skills（人读、人执行；**禁 REV**）

| Skill | 内容 | Consumers |
|---|---|---|
| manual-apb-protocol     | APB 3.0 时序、SETUP/ACCESS、PSLVERR | ARCH, RTL, DV |
| manual-csr-attributes   | RW/RO/W1P/RW1C 实现模板             | ARCH, RTL, DV |
| manual-vcs-flags        | VCS 2018 常用 flag 速查              | RTL, DV |
| manual-verdi-workflow   | FSDB dump + Verdi 2018 流程          | RTL, DV |
| manual-make-templates   | smoke/regress/cov Makefile 模板      | RTL, DV |
| manual-sv-tb-patterns   | task / program / clocking / fork-join | RTL, DV |
| manual-uvm-env-skeleton | UVM 树骨架                            | DV (lab4) |
| manual-coverage-closure | 功能/代码覆盖率收敛方法              | DV |
| manual-spyglass-lint    | Spyglass 2018 lint/CDC sign-off 流程 | RTL |

> ORCH 的 `skills: []`——它只调度，不直接执行专业工艺技能。

## 接入 xwave / xtrace

外部工具克隆到 `tools/xwave/` 和 `tools/xtrace/`（git submodule 或本地 `ln -s`）。
- xwave: https://github.com/BLANK2077/xwave
- xtrace: https://github.com/BLANK2077/xtrace

两者均提供 `<cmd> ai query --json` 接口，输出 `<cmd>.ai.v1` JSON schema，便于 Agent 解析。

## v4 → v6 变化

| v4 | v5 | v6 |
|---|---|---|
| Skill 索引无 Consumers 列；agent ↔ skill 对应散落 | 索引加 Consumers 列；与 agents/README.md 矩阵互引 | 不变 |
| 无 Spyglass skill | 新增 `manual-spyglass-lint` | 不变 |
| 隐含约定"manual 禁 REV" | 显式写在命名表与 README 顶部 | 不变 |
| Spyglass / VCS / Verdi 与 REV 互动 | REV 不直接跑 EDA，只读 RTL/DV 留下的 `.rpt`/log/fsdb | **v6 起 REV 可经 `make <target>` 在本机重跑**；详见 `agents/reviewer.md` |
