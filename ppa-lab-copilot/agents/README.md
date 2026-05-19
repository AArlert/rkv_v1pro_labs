# Agents — 角色定义与协作协议（v6）

> 5 个角色，ORCH/ARCH/RTL/DV 由人扮演，REV 由纯 Agent 担任。详细工作流见 [`../workflow-v6.md`](../workflow-v6.md)。
> 环境锁定 / Skill 矩阵 / 标准模板 拆解到对应文件：环境见各 agent `## Tool Options`；模板见 [`../template/`](../template/)；完整文件树见 [`../doc/ppa-outlook.htm`](../doc/ppa-outlook.htm)。

## 角色清单

| 文件 | 角色 | 担任 | 主要交付 |
|---|---|---|---|
| `orchestrator.md` | ORCH | 人 | 调度 + 执行/维护 SOP + 升级决策 |
| `architect.md` | ARCH | 人 | `lab*/doc/design-prompt.md` |
| `rtl-designer.md` | RTL | 人 + Copilot 补齐 | `lab*/rtl/*.sv` + 最小可验证 tb + Spyglass `.rpt` |
| `dv-engineer.md` | DV | 人 + Copilot 补齐 | `lab*/doc/testplan.md` + `lab*/svtb/` + cov |
| `reviewer.md` | REV | 纯 AI Agent | `lab*/doc/review_report/<时间戳>-<trigger>-<target>.md` |

## Skill × Agent 矩阵（v6 权威，与 workflow-v6 / skill/README.md 同步）

| Skill | ORCH | ARCH | RTL | DV | REV |
|---|:-:|:-:|:-:|:-:|:-:|
| manual-apb-protocol     |   | ✓ | ✓ | ✓ |   |
| manual-csr-attributes   |   | ✓ | ✓ | ✓ |   |
| manual-vcs-flags        |   |   | ✓ | ✓ |   |
| manual-verdi-workflow   |   |   | ✓ | ✓ |   |
| manual-make-templates   |   |   | ✓ | ✓ |   |
| manual-sv-tb-patterns   |   |   | ✓ | ✓ |   |
| manual-uvm-env-skeleton |   |   |   | ✓ |   |
| manual-coverage-closure |   |   |   | ✓ |   |
| manual-spyglass-lint    |   |   | ✓ |   |   |
| copilot-wave-analyze    |   |   |   |   | ✓ |
| copilot-rtl-trace       |   |   |   |   | ✓ |
| copilot-log-triage      |   |   | ✓ | ✓ | ✓ |
| copilot-review-rtl      |   |   |   |   | ✓ |
| copilot-review-tb       |   |   |   |   | ✓ |
| copilot-make-script     |   |   | ✓ | ✓ | ✓ |

> 约束：`copilot-*` 任意角色都能调；`manual-*` **禁 REV**。

## 切换协议（模板见 [`../template/log-role.md`](../template/log-role.md)）

切换角色时在 `lab*/doc/log.md` append 一段 ROLE 块；按需调 REV 用单独的一行（模板：[`../template/log-call-rev.md`](../template/log-call-rev.md)）。

## 两层纠错（与 v4 同）

1. **Inner Loop（自纠错，不出阶段）**：产物→自检→重读输入→改产物 + 软上限
2. **Outer Loop（跨 Agent 回退/升级，出阶段）**：自纠错失败 → "登记" + "交接" → ORCH 重新 dispatch

## v6 关键约束

- **状态单一来源**：`memory/state.md` 是 ORCH 与所有 Agent 共享状态的唯一文件。任何角色更新状态都改这一份（原子写）。
- **登记 vs 交接 职责分离**：
  - 登记 = `memory/state.md` 一处（用 [`../template/risk-entry.md`](../template/risk-entry.md) 指引）
  - 交接 = `lab*/doc/handoff.md`（用 [`../template/handoff.md`](../template/handoff.md)）
- **REV 报告归档**：每份独立文件存 `lab*/doc/review_report/<YYYYMMDD>-<HHMM>-<trigger>-<target>.md`，**永不覆盖**。模板：[`../template/review-report.md`](../template/review-report.md)。
- **ORCH 有自己的记忆位**：`memory/orchestrator/{experiences,knowledge}.md`（experiences 模板：[`../template/experiences-entry.md`](../template/experiences-entry.md)）。
- **Skill 白名单**：每个 agent .md 的 `skills:` frontmatter = 矩阵该列；多/少都视为漂移，PR 时纠正。
- **【v6 新增】REV 经 make 调 EDA**：本机 VCS/Verdi/Spyglass 许可对 REV 开放，但**只通过现有 `make <target>` 触发**；详见 reviewer.md `## Tool Options`。

## REV 调用模式

- **按需**：任何 Agent 在自己 Inner Loop 中需要外部 sanity-check
  - 在 `lab*/doc/log.md` 写一行 `>>> CALL REV @<ts> on <target>`（模板：[`../template/log-call-rev.md`](../template/log-call-rev.md)）
- **强制**：labX 关单前 ORCH 必须 dispatch REV 对整 lab 三方产物做完整审查（trigger=`labclose`）
- REV 报告若含 P0 → 升级流程（同跨 Agent 回退）

## agent .md 模板

```
---
name / description / model / effort / maxTurns
skills:                                ← = §4 矩阵该列（白名单）
---
## Inputs                              ← 表/树：本角色读什么
## Outputs                             ← 表/树：本角色写什么
## Stage Sequence                      ← 编号步骤
## Inner Loop                          ← mermaid + 软上限
## Outer Loop                          ← 触发表
## Tool Options                        ← 工具/版本/用途
## Sign-off Criteria                   ← 复选框
## Behaviour Rules                     ← 短 bullet
## Memory                              ← 读/写位置
## State                               ← 改 state.md 哪些字段
```

> `model: human` / `model: copilot` / `model: human + copilot-completion` 是给人读的非机器字段——表示"主导执行者是谁"。
