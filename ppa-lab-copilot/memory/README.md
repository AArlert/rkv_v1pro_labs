# Memory — 二级记忆系统（v2）

> 本目录在 v2 工作流下已 md 化（替换原 jsonl/json）。详细规则见 `../workflow-v2.md`。

## 结构

```
memory/
├── README.md
├── design_state.md     # 跨角色共享状态（表格）
├── run_state.md        # 仅 2 行: last / next
├── architecture/
│   ├── knowledge.md      # 蒸馏页 (≤ 1 页)
│   └── experiences.md    # append-only, 无序列表
├── rtl/
│   ├── knowledge.md
│   └── experiences.md
└── dv/
    ├── knowledge.md
    └── experiences.md
```

## 写入协议

### experiences.md（无序列表，append-only）

任何角色完成 stage / 学到一次教训时，追加一个列表块：

```
- **场景**: <lab / stage / 目标>
- **时间**: <ISO8601>
- **操作**: <做了什么>
- **结果**: <PASS/FAIL/blocked + 一句话>
- **教训**: <可空>
- **artifacts**: <文件:行 / log / 波形路径>
```

蒸馏后**不删**，仅作 history。

### knowledge.md

每个 Lab 关单时，把本 lab 的 experiences 蒸馏为 ≤ 1 页：
- 主题分组（≤ 5 个主题）
- 每条 ≤ 3 行
- 引文件:行或 experiences.md 中的"时间 + 场景"作证

### design_state.md（表格）

包含 `Meta` / `Labs Progress` / `Open RISKs` / `History` 四张表。原子写：
```bash
cp memory/design_state.md memory/design_state.md.tmp
# 编辑 .tmp
mv memory/design_state.md.tmp memory/design_state.md
```

### run_state.md

仅 2 行：
```
last: <谁/在哪/做到啥>
next: <谁/做啥>
```

ORCH 每次 session 头尾改一次。

## 读取协议

- ORCH 每次 session 开头 `cat run_state.md` → `cat design_state.md` → `tail doc/ppa-risk-register.md`
- 每个角色启用时读对应 `<domain>/knowledge.md`（不读 experiences.md 全文，太长）
- REV 读 spec + 当前 lab 文件 + `<domain>/knowledge.md`

## 与 git 的关系

- `design_state.md` / `run_state.md` / `knowledge.md` / `experiences.md` → **commit**
- 临时 `*.tmp` → `.gitignore`

## v1 → v2 迁移说明

| v1 | v2 |
|---|---|
| `design_state.json` | `design_state.md`（表格） |
| `<domain>/experiences.jsonl` | `<domain>/experiences.md`（无序列表块） |
| `run_state.md`（多段） | `run_state.md`（2 行） |

旧 jsonl / json 已在转换后移除；如需历史可查 git。
