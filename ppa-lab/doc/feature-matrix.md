# PPA-Lite Feature Matrix

状态枚举：`TODO` / `WIP` / `PARTIAL` / `DONE` / `BLOCKED` / `N/A`。本表是功能状态主表；每次会话结束前必须更新相关行。

| ID | Lab | Feature | spec 来源 | Owner Agent | 实现状态 | TB 状态 | 验收状态 | 关联 testcase / acceptance | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F-L1-APB | Lab1 | APB 3.0 SETUP/ACCESS、PREADY、PRDATA/PSLVERR 基础时序 | §4.1/§8.3/§11.2 | DUT-CSR | DONE | DONE | DONE | lab1 A-L1-01 | log: 2.3/2.9/2.11 |
| F-L1-CSR | Lab1 | CSR 复位值、RW/RO/W1P/RW1C 属性、读数据位域 | §5/§8/§9 | DUT-CSR | DONE | PARTIAL | WIP | lab1 A-L1-02/A-L1-04 | 选做/异常路径需继续补 testcase |
| F-L1-PKTMEM | Lab1 | PKT_MEM 0x040~0x05C 写入映射到 M2 | §6.1/§6.2 | DUT-CSR/DUT-Mem | DONE | PARTIAL | WIP | lab1 A-L1-03 | TC2 缺程序化回读比对 |
| F-L1-IRQ | Lab1 | IRQ_EN/IRQ_STA/irq_o 路径 | §8.2/§9.3 | DUT-CSR | DONE | PARTIAL | WIP | lab1 A-L1-05 | 需要完整路径 testcase |
| F-L2-FSM | Lab2 | IDLE→PROCESS→DONE，busy/done 保持与再次 start | §7/§8.1 | DUT-Core | DONE | DONE | DONE | lab2 A-L2-01/A-L2-03 | log: 2.2/2.3/2.13 |
| F-L2-LEN | Lab2 | pkt_len 范围和 exp_pkt_len 一致性检查 | §3.2/§9/§10.2 | DUT-Core | DONE | PARTIAL | WIP | lab2 A-L2-02 | exp_pkt_len_i 非零待补 |
| F-L2-TYPE | Lab2 | one-hot pkt_type 与 type_mask 检查 | §3.1/§9/§10.2 | DUT-Core | DONE | DONE | DONE | lab2 A-L2-04 | TC4a/TC4b PASS |
| F-L2-CHK | Lab2 | hdr_chk 校验与 algo_mode 旁路 | §3.1/§9/§10.2 | DUT-Core | DONE | DONE | DONE | lab2 A-L2-05 | TC5a/TC5b PASS |
| F-L2-PAYLOAD | Lab2 | payload sum/xor 计算 | §3.4/§7.3 | DUT-Core | DONE | DONE | DONE | lab2 A-L2-06 | TC1/TC5c PASS |
| F-L3-TOP | Lab3 | ppa_top 三模块集成、端到端链路 | §2/§11.4 | Integration | TODO | TODO | TODO | TBD | 创建 Lab3 后推进 |
| F-L3-BYTEORDER | Lab3 | M1 写入与 M3 读取字节序一致性 | §3.1/§6/§7 | Integration | TODO | TODO | TODO | TBD | 关联风险 R-002 |
| F-L4-REGRESS | Lab4 | smoke/regress/cov 统一入口和结果汇总 | §10/§11.5/§12 | Integration | TODO | TODO | TODO | TBD | Lab4 范围 |
| F-HARNESS | Project | status/matrix/handoff/risk/traceability/acceptance Harness 入口 | harness.md/harness-v1.md | Orchestrator | DONE | N/A | DONE | 文档自检 | 本次升级 |
