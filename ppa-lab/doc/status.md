# PPA-Lite 项目状态（AI 入口）

> 新 Agent 第一读。本文件是运行时摘要，不替代 spec、testplan 或 log。最后更新：2026-04-29。

## 当前阶段

- Harness 升级：进行中，本次重构新增状态/交接/矩阵/风险/验收入口。
- Lab1：M1 APB/CSR + M2 SRAM 已完成审查阶段，Review 结论 123/123 PASS；仍有验证补强项。
- Lab2：M3 FSM/算法核已完成设计与审查阶段，Review 结论 78/78 PASS；仍有覆盖补强项。
- Lab3：尚未开始 top 集成。
- Lab4：尚未开始回归与覆盖率闭环。

## 当前焦点

1. 使用 `feature-matrix.md` 作为单一功能状态清单。
2. 新 Agent 从 lab `status.md` + `handoff.md` 起步，不默认通读 `log.md`。
3. Lab3 开始前优先处理跨 Lab 风险：M1/M3 字节序、Lab1 PKT_MEM 读/写验证补强、端到端 done/irq。

## 阻塞项

- 无硬阻塞。
- 工具环境未在本会话运行 Questa/Make；仿真命令需在有 Questasim 的环境人工执行。

## 未决问题

| ID | 问题 | 归属 | 状态 |
| --- | --- | --- | --- |
| OQ-001 | spec §8.3 将 W1P 与 RO 并列描述 PSLVERR，和附录 C/W1P 语义存在歧义 | Spec Steward | OPEN，暂以附录 C 与现有 RTL 行为为准 |
| OQ-002 | M1 写入与 M3 读取的 byte order 需 Lab3 集成验证 | Integration | OPEN |
| OQ-003 | Lab1 TC2 需要程序化 SRAM 回读比对，不能只依赖波形 | VPlan/VDebug | OPEN |

## 下一步建议

1. Verification Plan Agent：补全 `lab1/doc/testplan.md`，把 TC2 SRAM 回读和 PSLVERR/IRQ 选做项结构化。
2. Integration Agent：创建 Lab3 top 集成计划，优先验证 M1→M2→M3 byte order。
3. Review/Sign-off Agent：Lab3 结束后按 acceptance 表做端到端 sign-off。
