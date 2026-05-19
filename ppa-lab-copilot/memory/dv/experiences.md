# DV Experiences

> Append-only。每条 = 一次 DV 角色 run（含 testplan / TB / Makefile 撰写、FAIL 根因、自纠错经历）。蒸馏到 `knowledge.md` 后**不删**。
>
> 格式：每条一个无序列表块，字段——场景 / 时间 / 操作 / 结果 / 教训 / artifacts。

---

<!-- 示例：

- **场景**: lab1 / TC5 RO 写保护 FAIL → 判定 RTL bug
- **时间**: 2026-05-23T09:10
- **操作**: 自纠错 1 轮（检查 TB 期望、apb_write task），仍 FAIL；调 xwave 看 PSLVERR 波形，确认 RTL 未拉高
- **结果**: 登记 RISK-0001，handoff → RTL
- **教训**: 自纠错前先排除"TB 期望写错"，本次确认 expect_slverr=1 正确
- **artifacts**: lab1/svtb/sim/run.log, memory/state.md#RISK-0001
-->

（暂无）
