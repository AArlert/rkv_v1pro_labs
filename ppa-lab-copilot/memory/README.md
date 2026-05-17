# Memory — 二级记忆系统

参考 [chuanseng-ng/digital-chip-design-agents](https://github.com/chuanseng-ng/digital-chip-design-agents) 的记忆设计。

## 结构

```
memory/
├── README.md           # 本文件
├── design_state.json   # 跨角色共享状态（参考 ppa-plan.md §2.3 schema）
├── run_state.md        # 当前活跃 run 的身份与上次中断点
├── architecture/
│   ├── knowledge.md     # 蒸馏后的人类可读总结（≤ 1 页）
│   └── experiences.jsonl # append-only 原始记录
├── rtl/
│   ├── knowledge.md
│   └── experiences.jsonl
└── dv/
    ├── knowledge.md
    └── experiences.jsonl
```

## 写入协议

### experiences.jsonl

任何角色完成一个 stage / 学到一个教训时 append 一行 JSON：

```json
{"run_id":"rtl-2026-05-20-01","ts":"2026-05-20T16:30","role":"rtl-designer","lab":"lab1","stage":"impl-W1P","decision":"start_o 用 hit_ctrl & wdata[1] & PENABLE & ~start_o_d","outcome":"TC6 PASS","artifacts":["lab1/svtb/sim/run.log"],"lessons":"忘了 ~start_o_d 会双拍"}
```

字段约定：
- `run_id`：自由文本，建议 `<role>-<date>-<seq>`
- `ts`：ISO8601
- `role`：5 个角色之一
- `lab`：lab1/lab2/lab3/lab4
- `stage`：自由文本
- `decision`：本次做了什么决定
- `outcome`：结果（PASS/FAIL/blocked）
- `artifacts`：相关日志/波形/文件路径
- `lessons`：教训（可空）

### knowledge.md

每个 Lab 关单时，把本 Lab 的 experiences.jsonl 蒸馏为 knowledge.md：
- 用主题分组（≤ 5 个主题）
- 每条 ≤ 3 行
- 引文件:行或 experiences.jsonl `run_id` 作证

蒸馏由我手动做（或让 Copilot Agent 用 `skill/copilot-log-triage` 辅助）。**蒸馏后 experiences.jsonl 不删**，仅作 history。

### design_state.json

任何角色更新都遵守原子写：
```bash
cp memory/design_state.json memory/design_state.json.tmp
# 编辑 .tmp
mv memory/design_state.json.tmp memory/design_state.json
```

并发风险：本仓库单人单 session，几乎不可能并发。harness 化时需加 flock。

## 读取协议

- Orchestrator 每个 session 开头 `cat design_state.json` + `cat run_state.md`
- 每个角色启用时读对应 `<domain>/knowledge.md`（不读 experiences.jsonl 全文，太长）
- Reviewer 读 spec + 当前文件 + `<domain>/knowledge.md`

## 与 git 的关系

- `design_state.json`、`run_state.md`、`knowledge.md` → **commit**
- `experiences.jsonl` → **commit**（append-only，不会大）
- 临时 `*.tmp` → `.gitignore`
