# Lab2 测试计划 (Test Plan)

> 由 Verification Plan Agent 在验证阶段填充。设计阶段仅提供最小可验证 TB（见 `svtb/tb/ppa_tb.sv`）覆盖必做项 1/2/3。

## 设计阶段最小 TB 覆盖

| TC ID | 名称 | 关联 Feature |
|-------|------|--------------|
| TC1 | tc_min_legal_pkt（pkt_len=4） | F2-01 / F2-04 / F2-05 |
| TC2 | tc_8byte_legal（含 4B payload） | F2-01 / F2-04 / F2-09 / F2-10 |
| TC3 | tc_length_underflow（pkt_len=3） | F2-05 / F2-13 |
| TC4 | tc_length_overflow（pkt_len=33） | F2-05 / F2-13 |
| TC5 | tc_busy_done_timing | F2-02 / F2-03 / F2-12 |
| TC6 | tc_two_frames | F2-12 |

待补充（VPlan 阶段）：F2-06 / F2-07 / F2-08 / F2-11 / F2-14。
