# progress — 全项目进度看板

> 人维护；REV 不写本文件。
> 每个 lab 的细粒度阶段进度见 `labN/doc/progress.md`。
> 每次 REV 报告生成后，在对应 lab 行追加报告文件名。

## Lab 进度总览

| Lab | 模块 | Design | Verify | Integrate | Regression | 最近 REV 报告 |
|---|---|:-:|:-:|:-:|:-:|---|
| lab1 | M1 apb_slave_if + M2 packet_sram | ⬜ | ⬜ | — | — | — |
| lab2 | M3 packet_proc_core | ⬜ | ⬜ | — | — | — |
| lab3 | ppa_top 集成 | ⬜ | ⬜ | ⬜ | — | — |
| lab4 | 全系统回归 + 覆盖率 + UVM | ⬜ | ⬜ | ⬜ | ⬜ | — |

> 图例：⬜ 未开始 / 🔄 进行中 / ✅ 已完成（且最近一次 REV 报告 0 P0）

## 阶段闭合规则

每个阶段标记为 ✅ 的前提：
1. 对应代码 / 文档存在
2. `make smoke`（design/verify 阶段）或 `make regress`（regression 阶段）退出码 0
3. `doc/review_report/` 中至少有一份 **同 lab + 同 phase** 的最新报告，且 "Where" 段为空（无 bug）

## REV 调用记录

> 每次调用 REV 时在此追加一行（人维护），便于审计"谁、什么时候、看了什么"。

| 时间 | 调用人 | 目标 | 报告文件 |
|---|---|---|---|
| — | — | — | — |
