# Lab1 状态摘要（AI 入口）

> 新 Agent 先读本文件；只在需要审计细节时阅读 `log.md` 全文。最后更新：2026-04-29。

## 当前阶段

- 阶段：审查完成，验证补强待做。
- 范围：M1 `ppa_apb_slave_if` + M2 `ppa_packet_sram` + 基础 SV TB/Makefile。
- Review 结论：123/123 PASS；无功能性偏差。

## 已完成

- M1/M2 端口、地址映射、CSR 复位/属性、PSLVERR、start 脉冲、中断逻辑均完成审查。
- Makefile `comp/run/rung/clean` 审查 PASS。
- TC1 CSR 默认值、TC3 RES_* 读通路与 APB 基础时序审查 PASS。

## 进行中 / 待补

| 项 | 描述 | 优先级 |
| --- | --- | --- |
| L1-TC2-AUTO | TC2 对 SRAM 回读数据增加程序化比对 | P0 |
| L1-PSLVERR | 写 RO、访问保留/越界地址 testcase | P1 |
| L1-IRQ | IRQ_EN → IRQ_STA → irq_o 完整路径 testcase | P1 |
| L1-LAB3 | Lab3 连接 M1/M2/M3 后验证 PKT_MEM 读写链路 | P0 for Lab3 |

## 下一步

1. Verification Plan Agent 补全 `testplan.md`，将上述待补项表格化。
2. 若用户允许改 SVTB，再补 `ppa_tb.sv` 自动比对。
3. Integration Agent 在 Lab3 首个 smoke 中验证 byte order 和 PKT_MEM 链路。
