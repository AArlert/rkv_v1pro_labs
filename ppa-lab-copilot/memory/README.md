# Memory — 二级记忆系统（v3）

> v3：合并 v2 的 `run_state.md` + `design_state.md` → `state.md` 单文件；新增 ORCH 自己的记忆位。详细规则见 `../workflow-v3.md`。

## 结构

```
memory/
├── README.md
├── state.md                  # 单一状态源 (Meta + Cursor + Dispatch + Labs Progress + Open RISKs + History)
├── orchestrator/
│   ├── knowledge.md          # ORCH SOP 蒸馏页 (≤ 1 页)
│   └── experiences.md        # ORCH 每次决策/SOP 反思
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
- **Meta**：spec_version / created / workflow
- **Cursor**：`lab` / `phase` ∈ `arch|rtl|dv|review|close` / `last`（≤1 行） / `next`（≤1 行）
- **Dispatch**：`role` ∈ `ARCH|RTL|DV|REV|ORCH-decide` / `reason`
- **Labs Progress**：每 lab 的 `arch/rtl/tb/cov/accept`，取值 `todo/wip/blocked/done`
- **Open RISKs**：摘要表（id / from→to / lab.phase / 一句话 / 状态）
- **History**：append-only 表

原子写：
```bash
cp memory/state.md memory/state.md.tmp
# 编辑 .tmp
mv memory/state.md.tmp memory/state.md
```

### experiences.md（无序列表，append-only）

任何角色完成 stage / 学到一次教训 / ORCH 做出决策时，追加一个列表块：

```
- **场景**: <lab / phase / 目标>
- **时间**: <ISO8601>
- **操作**: <做了什么>
- **结果**: <PASS/FAIL/blocked + 一句话>
- **教训**: <可空>
- **artifacts**: <文件:行 / log / 波形 / review_report 路径>
```

蒸馏到 `knowledge.md` 后**不删**。

### knowledge.md

每个 Lab 关单时，把本 lab 的 experiences 蒸馏为 ≤ 1 页：
- 主题分组（≤ 5 个主题）
- 每条 ≤ 3 行
- 引文件:行或 experiences.md 中的"时间 + 场景"作证

## 读取协议

- ORCH 每次 session 开头：`cat memory/state.md` → 若 `Open RISKs` 非空再 `tail doc/ppa-risk-register.md`
- 每个角色启用时读对应 `<domain>/knowledge.md`（不读 experiences.md 全文，太长）
- REV 读 spec + 当前 lab 文件 + `<domain>/knowledge.md`；产物写 `lab*/doc/review_report/<时间戳>-<trigger>-<target>.md`

## 与 git 的关系

- `state.md` / `knowledge.md` / `experiences.md` → **commit**
- 临时 `*.tmp` → `.gitignore`

## v2 → v3 迁移说明

| v2 | v3 |
|---|---|
| `memory/run_state.md`（2 行） | **合并** → `memory/state.md` 的 `Cursor` 段 |
| `memory/design_state.json` / v2 `memory/design_state.md` | **合并** → `memory/state.md` 余下各表 |
| ORCH 复盘塞进 `memory/architecture/experiences.md` | 独立 `memory/orchestrator/{experiences,knowledge}.md` |
| `current_lab` / `current_stage` 自由字符串 | 正交字段：`Cursor.lab` / `Cursor.phase` / `Dispatch.role` |

旧 `run_state.md` / `design_state.md` 已在转换后移除；如需历史可查 git。
