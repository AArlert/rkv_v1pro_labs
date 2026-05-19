# State (memory/state.md)

<!--
v6 单一状态源。ORCH 每 session 开头只读这一份；outlook.htm 也通过 fetch 解析这一份。
解析锚点：以下 H2 标题（## Cursor / ## Dispatch / ## Labs Progress / ## RISKs / ## History）
是机器约定，**勿改名/勿改顺序**。表头列名也是机器约定。
原子写：cp state.md{,.tmp} && 编辑 .tmp && mv .tmp state.md
-->

## Meta

| 字段 | 值 |
|---|---|
| spec_version | `ppa-lite-spec.md@2026-04-13` |
| workflow | `workflow-v6.md` |
| created | 2026-05-18 |

## Cursor

- **lab**: lab1
- **phase**: arch              <!-- arch | rtl | dv | review  （v5 起去除 close） -->
- **last**: ORCH 完成 v6 迁移（template/ 拆解 / ppa-plan 蒸馏 / REV 经 make 调 EDA / 文件树进 outlook） — 2026-05-19
- **next**: 切 ARCH 角色，读 spec §2/§4，开始写 lab1/doc/design-prompt.md

## Dispatch

- **role**: ARCH               <!-- ARCH | RTL | DV | REV | ORCH-decide -->
- **reason**: 进入 lab1 架构阶段

## Labs Progress

| Lab | arch | rtl | tb | cov | accept |
|---|---|---|---|---|---|
| lab1 | wip  | todo | todo | todo | todo |
| lab2 | todo | todo | todo | todo | todo |
| lab3 | todo | todo | todo | todo | todo |
| lab4 | todo | todo | todo | todo | todo |

<!-- 取值：todo / wip / blocked / done -->

## RISKs

<!--
v4 起：合并原 doc/ppa-risk-register.md。
每条 RISK 是一个二级列表块，字段固定如下；状态机：open → in-progress → resolved | dropped。
登记触发：自纠错预算耗尽 / 跨 Agent 回退 / REV P0。
登记动作：append 本段一条 + 改 Cursor/Dispatch/Labs 字段 + History +1 + 在 lab*/doc/handoff.md 写交接段。
-->

### Open

（暂无）

### Resolved / Dropped (recent)

（暂无）

### 模板

```
- **id**: RISK-0001
- **time**: 2026-05-20T14:00
- **from**: DV
- **to**: RTL
- **lab.phase**: lab1.dv
- **summary**: TC5 (RO 写保护) PSLVERR 期望 1 实测 0
- **evidence**: lab1/svtb/sim/run.log:120-128；spec §2.3.1；lab1/doc/review_report/20260520-1400-ondemand-rtl-ppa_apb_slave_if.md
- **advice**: 排查 ppa_apb_slave_if.sv 写路径 RO 判定
- **status**: open
- **resolution**: —
```

## History

| 时间 | role | action | ref |
|---|---|---|---|
| 2026-05-18T00:00 | ORCH | project initialized | doc/ppa-plan.md |
| 2026-05-18T12:00 | ORCH | v2 落地 | workflow-v2.md |
| 2026-05-19T08:30 | ORCH | v3 落地 | workflow-v3.md |
| 2026-05-19T09:00 | ORCH | v4 落地（RISKs 入 state；outlook 实时监控） | workflow-v4.md |
| 2026-05-19T09:30 | ORCH | v5 落地（skill 矩阵；Spyglass；人友好模板；完整文件树） | workflow-v5.md |
| 2026-05-19T10:00 | ORCH | v6 落地（template/ 拆解；ppa-plan 蒸馏；REV 经 make 调 EDA；文件树进 outlook） | workflow-v6.md |
