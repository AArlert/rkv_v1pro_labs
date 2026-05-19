# template: `memory/state.md` `## RISKs` 一条

> **单源在 `memory/state.md` 自身的 `### 模板` 段**。本文件是入口，避免双源漂移。

打开 [`../memory/state.md`](../memory/state.md) → 翻到 `## RISKs → ### 模板`，复制其中代码块到 `### Open` 段顶端。

字段（与 state.md 内模板逐字一致）：

```
- **id**: RISK-XXXX                # 顺序递增
- **time**: YYYY-MM-DDTHH:MM
- **from**: <ARCH|RTL|DV|REV>
- **to**:   <ARCH|RTL|DV|ORCH>
- **lab.phase**: lab<N>.<arch|rtl|dv|review>
- **summary**: <一句话>
- **evidence**: <log:line / spec § / review_report 路径>
- **advice**: <一句话建议>
- **status**: open
- **resolution**: —
```

## 登记同步动作（外层循环必须做）

1. 在 `state.md` 的 `## RISKs → ### Open` 加这一条
2. 把 `Labs Progress.lab<N>.<phase>` 改 `blocked`
3. 把 `Dispatch.role` 改 RISK 的 `to`（或 `ORCH-decide`）
4. `History` 表追加一行
5. 在 `lab*/doc/handoff.md` 写交接段（用 [`handoff.md`](handoff.md) 模板，括号里写本 RISK id）
