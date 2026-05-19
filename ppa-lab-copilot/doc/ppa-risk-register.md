# PPA Risk Register (v3)

> 跨 Agent 回退 / REV P0 / 自纠错预算耗尽 的**详情登记表**。摘要见 `memory/state.md` 的 `Open RISKs` 表。详细规则见 `workflow-v3.md §5`。
>
> 写入触发：
> 1. 某 Agent 自纠错 N 轮失败（ARCH≤2, RTL≤3, DV≤3）
> 2. 跨 Agent 回退（RTL→ARCH、DV→RTL、DV→ARCH）
> 3. REV 报告 P0
>
> 任何一次登记同步：`memory/state.md`（Open RISKs 摘要 + History + Labs Progress 字段改 `blocked` + Dispatch 改指接手者），并在 `lab*/doc/handoff.md` 写"上下文交接段"。

---

## 字段约定（每条 RISK 一个无序列表块）

- **id**: `RISK-NNNN`（递增四位数）
- **时间**: ISO8601（精确到分）
- **来源 Agent**: ARCH / RTL / DV / REV
- **目标 Agent**: ARCH / RTL / DV / ORCH
- **lab**: lab1..lab4
- **phase**: `arch | rtl | dv | review | close`
- **现象**: 一句话描述卡点
- **证据**: 文件:行 / log 路径 / 波形路径 / spec § 引用 / review_report 文件
- **建议**: 推荐对方做什么
- **状态**: `open` / `in-progress` / `resolved` / `dropped`
- **resolution**（关闭时填）: 一句话怎么消化的

---

## Open RISKs

（暂无）

---

## Resolved / Dropped RISKs (recent)

（暂无）

---

## 模板（复制使用）

```
- **id**: RISK-0001
- **时间**: 2026-05-20T14:00
- **来源 Agent**: DV
- **目标 Agent**: RTL
- **lab**: lab1
- **phase**: dv
- **现象**: TC5 (RO 写保护) PSLVERR 期望 1 实测 0
- **证据**: lab1/svtb/sim/run.log:120-128；spec §2.3.1 PSLVERR 规则；lab1/doc/review_report/20260520-1400-ondemand-rtl-ppa_apb_slave_if.md
- **建议**: 排查 ppa_apb_slave_if.sv 写路径的 RO 判定逻辑
- **状态**: open
- **resolution**: —
```
