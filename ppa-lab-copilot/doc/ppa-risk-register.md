# PPA Risk Register

> 跨 Agent 回退 / REV P0 / 自纠错预算耗尽 的**唯一**登记表。详细规则见 `workflow-v2.md §3.2 / §6`。
>
> 写入触发：
> 1. 某 Agent 自纠错 N 轮失败（ARCH≤2, RTL≤3, DV≤3）
> 2. 跨 Agent 回退（RTL→ARCH、DV→RTL、DV→ARCH）
> 3. REV 报告 P0
>
> 任何一次登记必须同步更新 `memory/design_state.md`（history + open RISKs 表）和 `memory/run_state.md`（2 行），并在 `lab*/doc/handoff.md` 写交接段。

---

## 字段约定（每条 RISK 一个无序列表块）

- **id**: `RISK-NNNN`（递增四位数）
- **时间**: ISO8601（精确到分）
- **来源 Agent**: ARCH / RTL / DV / REV
- **目标 Agent**（建议接手者）: ARCH / RTL / DV / ORCH
- **lab / 阶段**: 例如 `lab1 / rtl-impl`
- **现象**: 一句话描述卡点
- **证据**: 文件:行 / log 路径 / 波形路径 / spec § 引用
- **建议**: 推荐对方做什么
- **状态**: `open` / `in-progress` / `resolved` / `dropped`
- **resolution**（关闭时填）: 一句话说清楚怎么消化的

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
- **lab / 阶段**: lab1 / dv-tc-run
- **现象**: TC5 (RO 写保护) PSLVERR 期望 1 实测 0
- **证据**: lab1/svtb/sim/run.log:120-128；spec §2.3.1 PSLVERR 规则
- **建议**: 排查 ppa_apb_slave_if.sv 写路径的 RO 判定逻辑
- **状态**: open
- **resolution**: —
```
