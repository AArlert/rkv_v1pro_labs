# Memory — v3 最小记忆系统

v3 只保留一个日常状态入口：`memory/state.md`。经验文件仍保留，但不再按 stage 强制写。

## 结构

```text
memory/
├── README.md
├── state.md                 # 唯一日常状态：当前在哪、下一步、open blocker、lab 简表
├── architecture/
│   ├── knowledge.md
│   └── experiences.md       # 可选：非显然架构经验
├── rtl/
│   ├── knowledge.md
│   └── experiences.md       # 可选：非显然 RTL/调试经验
└── dv/
    ├── knowledge.md
    └── experiences.md       # 可选：非显然验证/回归经验
```

## `state.md` 规则

`state.md` 只回答：当前在哪、上次做到哪、下次先做什么、是否有 open blocker、各 lab 粗状态。不要在这里写详细日志。

## experiences.md 规则

只在以下情况追加经验：

- 同一类问题之后可能再次遇到。
- 调试过程有可复用方法。
- Lab close 时做一次总结。
- REV 发现高价值审查模式。

模板：

```markdown
## EXP-YYYY-MM-DD-NN — <标题>

- 场景：labX / role / stage
- 触发：为什么值得记录
- 做法：采用了什么操作
- 结果：PASS / FAIL / deferred
- 证据：文件/日志/波形/review 路径
- 复用：下次遇到什么情况时看这条
```

## blocker 升级规则

普通错误留在当前角色内部修。只有 blocker/P0/明确上游问题才登记到 `doc/ppa-risk-register.md`，并在当前 `labX/handoff.md` 引用该 risk。

日常结束只更新 `memory/state.md`；升级或关单才更新 handoff/risk。
