# Agents — 角色定义与协作协议（v5）

> 5 个角色，ORCH/ARCH/RTL/DV 由人扮演，REV 由纯 Agent 担任。详细工作流见 [`../workflow-v5.md`](../workflow-v5.md)。
> 环境锁定 / Skill 矩阵 / 标准模板 全部在 workflow-v5.md，本文档只列**协作规约**。

## 角色清单

| 文件 | 角色 | 担任 | 主要交付 |
|---|---|---|---|
| `orchestrator.md` | ORCH | 人 | 调度 + 执行/维护 SOP + 升级决策 |
| `architect.md` | ARCH | 人 | `lab*/doc/design-prompt.md` |
| `rtl-designer.md` | RTL | 人 + Copilot 补齐 | `lab*/rtl/*.sv` + 最小可验证 tb + Spyglass `.rpt` |
| `dv-engineer.md` | DV | 人 + Copilot 补齐 | `lab*/doc/testplan.md` + `lab*/svtb/` + cov |
| `reviewer.md` | REV | 纯 AI Agent | `lab*/doc/review_report/<时间戳>-<trigger>-<target>.md` |

## Skill × Agent 矩阵（v5 权威，与 workflow-v5 §4 / skill/README.md 同步）

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

## 切换协议（标准模板见 workflow-v5 §7.1）

切换角色时在 `lab*/doc/log.md` append 一段 ROLE 块，按需调 REV 用单独的 `>>> CALL REV` 一行。

## 两层纠错（与 v4 同）

1. **Inner Loop（自纠错，不出阶段）**：产物→自检→重读输入→改产物 + 软上限
2. **Outer Loop（跨 Agent 回退/升级，出阶段）**：自纠错失败 → "登记" + "交接" → ORCH 重新 dispatch

## v5 关键约束

- **状态单一来源**：`memory/state.md` 是 ORCH 与所有 Agent 共享状态的唯一文件。任何角色更新状态都改这一份（原子写）。
- **登记 vs 交接 职责分离**：
  - 登记 = `memory/state.md` 一处（`## RISKs.Open` 加一条 RISK 全字段 + 更新 `Labs Progress` + 改 `Dispatch` + `History` +1）
  - 交接 = `lab*/doc/handoff.md`（人读上下文，模板见 workflow-v5 §7.2）
- **REV 报告归档**：每份独立文件存 `lab*/doc/review_report/<YYYYMMDD>-<HHMM>-<trigger>-<target>.md`，**永不覆盖**。
- **ORCH 有自己的记忆位**：`memory/orchestrator/{experiences,knowledge}.md`。
- **Skill 白名单**：每个 agent .md 的 `skills:` frontmatter = 矩阵该列；多/少都视为漂移，PR 时纠正。

## REV 调用模式

- **按需**：任何 Agent 在自己 Inner Loop 中需要外部 sanity-check
  - 在 `lab*/doc/log.md` 写一行 `>>> CALL REV @<ts> on <target>`（格式 workflow-v5 §7.1）
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
