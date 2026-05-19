# RTL Experiences

> Append-only。每条 = 一次 RTL 角色 run（含实现决策、debug、被 DV/REV 回退、自纠错经历）。蒸馏到 `knowledge.md` 后**不删**。
>
> 格式：每条一个无序列表块，字段——场景 / 时间 / 操作 / 结果 / 教训 / artifacts。

---

<!-- 示例：

- **场景**: lab1 / 实现 W1P start 逻辑 / ppa_apb_slave_if.sv
- **时间**: 2026-05-22T16:30
- **操作**: 用 `start_o = hit_ctrl & wdata[1] & PENABLE & ~start_o_d` 触发单拍
- **结果**: 最小 tb TC6 自跑 PASS；DV TC6 PASS
- **教训**: 忘加 `~start_o_d` 会产生双拍，必须保留延迟版做边沿检测
- **artifacts**: lab1/rtl/ppa_apb_slave_if.sv, lab1/svtb/sim/run.log
-->

（暂无）
