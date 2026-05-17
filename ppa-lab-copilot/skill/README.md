# Skills — 命名规约与索引

本目录包含两类 skill，**均**遵循通用 SKILL 规范（每个 skill 一个目录，含 `SKILL.md`，带 YAML frontmatter）。

## 命名

| 前缀 | 含义 | 消费者 |
|---|---|---|
| `copilot-*` | 给 AI Agent 用的 skill — 描述 Agent 该如何分析/审查/生成 | Copilot Agent |
| `manual-*` | 给我自己用的知识卡片 — 边学边写，答辩复习 | 我 |

## SKILL.md 模板

```markdown
---
name: <kebab-name>
description: 一句话用途，决定何时被调用
license: MIT
when_to_use: 一句话触发条件
inputs:
  - 输入文件/参数
outputs:
  - 输出格式
tools:
  - 依赖的外部工具（如 xwave, xtrace, vcs）
---

# <Title>

## Purpose
## When to Use
## How to Use
## Example
## Notes / Gotchas
```

## 索引

### Copilot skills（给 Agent）

| Skill | 用途 | 依赖工具 |
|---|---|---|
| copilot-wave-analyze | 用 xwave 查 FSDB 波形答疑 | xwave |
| copilot-rtl-trace | 用 xtrace 追 driver/load 解释 RTL 行为 | xtrace |
| copilot-log-triage | 分析 run.log / vcs.log 归因 FAIL | grep |
| copilot-review-rtl | 按 checklist 审 RTL 可综合性/正确性 | Read |
| copilot-review-tb | 审 TB 是否存在"假 PASS"风险 | Read |
| copilot-make-script | 生成/修订 VCS+Verdi Makefile | — |

### Manual skills（给我）

| Skill | 内容 |
|---|---|
| manual-apb-protocol | APB 3.0 时序、SETUP/ACCESS、PSLVERR |
| manual-csr-attributes | RW/RO/W1P/RW1C 实现模板 |
| manual-vcs-flags | VCS 常用 flag 速查 |
| manual-verdi-workflow | FSDB dump + Verdi 流程 |
| manual-make-templates | smoke/regress/cov Makefile 模板 |
| manual-sv-tb-patterns | task/program/clocking block/fork-join |
| manual-uvm-env-skeleton | UVM 树骨架 |
| manual-coverage-closure | 功能/代码覆盖率收敛方法 |

## 接入 xwave / xtrace

外部工具克隆到 `tools/xwave/` 和 `tools/xtrace/`（git submodule 或本地 ln -s）。
- xwave: https://github.com/BLANK2077/xwave
- xtrace: https://github.com/BLANK2077/xtrace

两者均提供 `<cmd> ai query --json` 接口，输出符合 `<cmd>.ai.v1` 的 JSON schema，便于 Agent 解析。
