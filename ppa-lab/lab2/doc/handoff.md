# Lab2 Handoff Notes

## Handoff: Orchestrator → Integration Agent (2026-04-29, Lab2, copilot/harness-upgrade-refactor)
- Context: Lab2 M3 独立设计/审查已完成，主要风险转移到 Lab3 集成。
- Done:
  - 新增 `lab2/doc/status.md` 总结 78/78 PASS 审查结论。
  - 新增 `lab2/doc/acceptance.md` 机器化验收判据。
  - 项目 matrix 将 FSM/length/type/chk/payload 拆成独立 feature。
- Not Done / Deferred:
  - 未修改 RTL/TB/Makefile。
  - 未新增 pkt_len=32、exp_pkt_len_i 非零、pkt_len=0 testcase。
- Pitfalls:
  - M3 独立 TB 假设 Word0 小端字节序；Lab3 必须验证 M1 写入一致。
  - pkt_len=4 需要额外 PROCESS 拍属于已接受设计开销，不是功能失败。
- Open Questions:
  - None。
- Minimal Verification:
  - 未运行：本次仅文档 Harness 重构，且云端未确认 Questasim 环境。
- Next Actions:
  1. Lab3 top 集成时先做一帧合法包端到端 smoke。
  2. 增加 byte-order 观测点或 checker。
  3. 之后补边界 testcase 到 Lab2/Lab4 回归。
