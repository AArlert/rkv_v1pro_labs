# skill/ — REV 可调用的 skill 库

> 本项目唯一 agent 是 REV，所以这里所有 skill 都是 **审查面向** 的。
> 每个 skill 一个目录，含 `SKILL.md`，带 YAML frontmatter。
> 设计参考 `ppa-lab-copilot/skill/` 的 SKILL 规范，但去掉 `copilot-*` / `manual-*` 二分（这里只有审查类）。

## Skill 索引

| Skill | 用途 | 何时被 REV 调起 |
|---|---|---|
| [`review-rtl`](review-rtl/SKILL.md) | 按 checklist 审 RTL：可综合性、正确性、与 spec 端口对齐 | phase=`design`，target=`rtl-*` |
| [`review-tb`](review-tb/SKILL.md) | 审 TB 是否存在"假 PASS"：缺 self-check、ref model 同源、testplan 漏 TC | phase=`tb`，target=`tb`/`env` |
| [`review-uvm-env`](review-uvm-env/SKILL.md) | 审 UVM 树结构、phase 顺序、TLM 连接、virtual sequencer 用法 | lab4 phase=`tb`/`regression` |
| [`review-spec-alignment`](review-spec-alignment/SKILL.md) | 端口/CSR/FSM 三轴严格对齐 spec（强 P0） | 任何 phase 都被 review-rtl 内部调起 |
| [`log-triage`](log-triage/SKILL.md) | 读 `sim/*.log` 归因 FAIL/UVM_ERROR/assertion | phase=`tb`/`integration`/`regression` |

## SKILL.md 模板

```markdown
---
name: <kebab-name>
description: 一句话用途
license: MIT
when_to_use: 一句话触发条件
inputs:  [输入文件/参数]
outputs: [输出格式 = REV 报告里的某几段]
tools:   [Read, Grep, ...]
---

# <Title>

## Purpose
## When to Use
## Checklist （P0/P1/P2 或 四段式填充指引）
## Output Mapping （checklist 项 → 报告里哪段）
## Notes / Gotchas
```

## 与 `ppa-lab-copilot/skill/` 的差异

| 维度 | `ppa-lab-copilot` | 本项目 |
|---|---|---|
| 分类 | `copilot-*` / `manual-*` 两类 | 只有审查类（去掉 manual 速查卡） |
| 消费者 | 多 agent 都消费 | 只有 REV 消费 |
| 报告映射 | 输出"review_notes" P0/P1/P2 表 | 输出 "Where/How-to-fix/Why/How-it-was-done" 四段填充 |
