# Orchestrator Experiences

> Append-only。每条 = 一次 ORCH 决策或 SOP 反思（升级/降级判断、SOP 漏洞修补、dispatch 切换原因）。蒸馏到 `knowledge.md` 后**不删**。
>
> 格式：每条一个无序列表块，字段——场景 / 时间 / 操作 / 结果 / 教训 / artifacts。

---

<!-- 示例：

- **场景**: lab1 关单复盘 — 检查本 lab 4 次 RISK 中是否有"本可在 Agent 内消化的"
- **时间**: 2026-05-30T18:00
- **操作**: 复盘 RISK-0002（DV 报 "Makefile 调通后又 FAIL"，实际是 DV 自己漏配 +UVM_TESTNAME）→ 这条本应进 DV Inner Loop
- **结果**: 把"DV 跑 UVM 前先核对 testname"补进 agents/dv-engineer.md Inner Loop
- **教训**: 升级前的"自纠错预算耗尽"判断要更严格，不能 ≤3 轮就升级
- **artifacts**: memory/state.md#RISK-0002, agents/dv-engineer.md
-->

```markdown
- **场景**: lab0 测试 vcs、verdi 可用性，调整 Makefile；debug tb.sv — 跑通仿真流程
- **时间**: 2026-05-20T23:00
- **操作**: 
    - 修改 Makefile，调整 vcs 和 verdi 的运行参数
- **结果**: 仿真环境可用，Makefile 跑通
- **教训**: 
    - RUN_OPTS = -R — -R 是 vcs 编译器选项（编译后立即运行），不是 simv 运行时选项，传给 ./simv 无效
    - verdi -vpd sim.vpd — -vpd 不是 Verdi 的有效参数，应使用 -ssf
    - -LDFLAGS -Wl,--no-as-needed（未引号） — -LDFLAGS '-Wl,--no-as-needed'（加引号更安全）
    - 严格按照 /skill/manual-vcs-flags/SKILL.md 和 /skill/manual-verdi-workflow/SKILL.md 的说明设置 Makefile
- **artifacts**: Makefile, comp.log, run.log
```
