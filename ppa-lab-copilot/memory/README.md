# Memory — v2 人可读记忆系统

本目录保存 ORCH/ARCH/RTL/DV/REV 之间的轻量共享状态。v2 取消 JSONL/JSON 作为主要人工维护格式，改为 Markdown。

## 结构

```text
memory/
├── README.md
├── design_state.md          # 跨角色共享状态，表格维护
├── run_state.md             # 只保留两行：上次干到哪、下次先干啥
├── architecture/
│   ├── knowledge.md
│   └── experiences.md       # 架构经验登记
├── rtl/
│   ├── knowledge.md
│   └── experiences.md       # RTL 经验登记
└── dv/
    ├── knowledge.md
    └── experiences.md       # DV 经验登记
```

## 写入协议

### experiences.md

任何角色完成一个 stage、定位一次问题、形成一条可复用教训时，追加一个条目。不用表格，用无序列表，便于人手写。

```markdown
## EXP-YYYY-MM-DD-NNN — <一句话标题>

- 场景：labX / role / stage
- 时间：YYYY-MM-DDTHH:MM:SSZ
- 角色：architect | rtl-designer | dv-engineer | reviewer | orchestrator
- 输入：相关 spec/doc/RTL/TB/log 路径
- 操作：本次实际做了什么
- 结果：PASS / FAIL / blocked / deferred
- 证据：日志、波形、文件、review notes 路径
- 教训：可复用经验
- 后续：无 / RISK-XXXX / 下一动作
```

### knowledge.md

每个 Lab 关单时，把本 Lab 的 experiences.md 蒸馏为 knowledge.md：

- 按主题分组，保留 1 页以内。
- 每条尽量引用 spec、文件路径或 EXP id。
- 只写未来会复用的经验，不写流水账。

### design_state.md

`design_state.md` 是 ORCH 和各角色共享的状态快照：

- 顶部记录当前 lab/stage/owner。
- Lab 状态用表格维护。
- 风险只记录索引，详细内容写 `doc/ppa-risk-register.md`。
- History 只记录关键事件，不替代 `labX/handoff.md`。

### run_state.md

只允许两行：

```markdown
上次干到哪：<一句话>
下次先干啥：<一句话>
```

## 读取协议

- ORCH：每个 session 开头读 `run_state.md` → `design_state.md` → `doc/ppa-risk-register.md`。
- ARCH：读 spec、`memory/architecture/knowledge.md`、当前 `labX/handoff.md`。
- RTL：读 design-prompt、`memory/rtl/knowledge.md`、当前 `labX/handoff.md`。
- DV：读 spec/design-prompt/RTL、`memory/dv/knowledge.md`、当前 `labX/handoff.md`。
- REV：读 spec、被审对象、相关 knowledge、risk register。

## 升级规则

当前角色先内部自纠错；只有以下情况进入跨角色登记：

- 内部循环无法收敛。
- 证据指向上游产物错误。
- REV 发现 P0。
- 需要 ORCH 裁决责任或取舍。

跨角色问题必须同步更新：

1. `doc/ppa-risk-register.md`
2. `memory/design_state.md`
3. `memory/run_state.md`
4. `labX/handoff.md`
