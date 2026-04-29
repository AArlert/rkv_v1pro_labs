# Lab2 状态摘要（AI 入口）

> 新 Agent 先读本文件；只在需要审计细节时阅读 `log.md` 全文。最后更新：2026-04-29。

## 当前阶段

- 阶段：设计与审查完成，边界覆盖补强待做。
- 范围：M3 `ppa_packet_proc_core` 独立验证，SV 数组 SRAM 行为模型。
- Review 结论：78/78 PASS；无功能性偏差。

## 已完成

- FSM IDLE→PROCESS→DONE、busy/done 时序、包头解析、长度/类型/hdr_chk 检查、错误并行性、payload sum/xor、结果清零均审查 PASS。
- 9 个 testcase 期望值和测试向量与 spec 一致。
- Makefile `comp/run/rung/clean` 审查 PASS。

## 待补

| 项 | 描述 | 优先级 |
| --- | --- | --- |
| L2-LEN32 | 最大合法包 pkt_len=32 | P1 |
| L2-EXP-LEN | exp_pkt_len_i 非零时长度一致性 | P1 |
| L2-LEN0 | pkt_len=0 极端越界 | P2 |
| L2-BYTEORDER | Lab3 与 M1 写入 byte order 集成验证 | P0 for Lab3 |

## 下一步

1. Verification Plan Agent 将边界 testcase 追加到 `testplan.md`。
2. Integration Agent 在 Lab3 smoke 中覆盖 M1 写入 → M2 存储 → M3 解析链路。
3. Review/Sign-off Agent 在 Lab3 完成后复核 done/irq 与错误标志跨模块闭环。
