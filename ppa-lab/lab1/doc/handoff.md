# Lab1 Handoff Notes

## Handoff: Orchestrator → Verification Plan Agent (2026-04-29, Lab1, copilot/harness-upgrade-refactor)
- Context: Harness 升级后，Lab1 不再要求新 AI 通读完整 log，状态入口已拆到 status/acceptance/feature-matrix。
- Done:
  - 新增 `lab1/doc/status.md` 总结审查结论与待补项。
  - 新增 `lab1/doc/acceptance.md` 给出可执行验收判据。
  - 项目 `feature-matrix.md` 已把 Lab1 APB/CSR/PKT_MEM/IRQ 拆成独立 feature。
- Not Done / Deferred:
  - 未修改 RTL/TB/Makefile。
  - 未补 Lab1 空 `testplan.md` 的完整 testcase 矩阵。
- Pitfalls:
  - TC2 当前弱点是“没有程序化 SRAM 回读比对”，不是 RTL 功能失败。
  - `log.md` 中已有完整审查表，后续不要重复考古，按需引用章节即可。
- Open Questions:
  - spec §8.3 中 W1P/RO PSLVERR 表述需 Spec Steward 或用户最终确认。
- Minimal Verification:
  - 未运行：本次仅文档 Harness 重构，且云端未确认 Questasim 环境。
- Next Actions:
  1. 补全 `lab1/doc/testplan.md`。
  2. 在允许修改 SVTB 时补 TC2 自动比对。
  3. 将 PSLVERR/IRQ testcase 纳入 Lab3/Lab4 回归。
