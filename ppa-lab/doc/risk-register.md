# Risk & Assumption Register

状态：`OPEN` / `MITIGATED` / `ACCEPTED` / `CLOSED`。

| ID | 类型 | 描述 | 影响 | 严重性 | Owner | 状态 | 处理建议 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| R-001 | Spec 歧义 | spec §8.3 将 W1P 与 RO 并列描述 PSLVERR，和附录 C/W1P 可写脉冲语义存在歧义 | CTRL.start 写 1 是否应报错 | LOW | Spec Steward | OPEN | 暂以附录 C 与现有 RTL 行为为准；需用户确认后再改 spec |
| R-002 | 集成假设 | M1 APB 写入 Word0 小端字节序需与 M3 解析一致 | Lab3 端到端包头可能错位 | MEDIUM | Integration | OPEN | Lab3 smoke 必测 byte order |
| R-003 | 验证缺口 | Lab1 TC2 未对 SRAM 回读值做程序化比对 | PKT_MEM 写映射可能只靠波形人工判断 | MEDIUM | VPlan | OPEN | 补 Lab1 testplan 与自动比对 |
| R-004 | 覆盖缺口 | Lab1 PSLVERR、IRQ 完整路径 testcase 不足 | 异常/中断路径回归置信度不足 | LOW | VPlan | OPEN | 作为 Lab1 选做或 Lab3 集成回归补齐 |
| R-005 | 覆盖缺口 | Lab2 未覆盖 pkt_len=32、pkt_len=0、exp_pkt_len_i 非零 | 边界覆盖不足 | LOW | VPlan | OPEN | 补充 P1/P2 testcase |
| R-006 | 工具环境 | 当前云端会话无法确认 Questasim 可用 | 无法在本次文档重构中运行仿真 | LOW | Orchestrator | ACCEPTED | 记录人工执行命令即可 |
