# Spec ↔ Implementation ↔ Test Traceability

| Trace ID | spec 章节 | 需求摘要 | 实现位置 | 测试/检查位置 | 覆盖状态 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| T-APB-001 | §4.1 | APB 两阶段访问、PREADY 固定、ACCESS 生效 | lab1/rtl/ppa_apb_slave_if.sv | lab1/doc/log.md 2.3/2.11 | REVIEWED | 已审查 |
| T-CSR-001 | §5 | CSR 地址、复位、属性 | lab1/rtl/ppa_apb_slave_if.sv | lab1/doc/log.md 2.4~2.7 | REVIEWED | 异常 testcase 待增强 |
| T-PKTMEM-001 | §6 | PKT_MEM 写窗口映射 | lab1/rtl/ppa_apb_slave_if.sv; lab1/rtl/ppa_packet_sram.sv | lab1/doc/log.md 2.9/2.10/2.11 | PARTIAL | 程序化回读待补 |
| T-IRQ-001 | §8.2/§9.3 | done/error irq 生成与清除 | lab1/rtl/ppa_apb_slave_if.sv | lab1/doc/log.md 2.8 | PARTIAL | 完整 testcase 待补 |
| T-FSM-001 | §7/§8.1 | M3 状态机与 busy/done 时序 | lab2/rtl/ppa_packet_proc_core.sv | lab2/doc/log.md 2.2/2.3/2.13 | REVIEWED | 已审查 |
| T-FMT-001 | §3/§9 | 长度、类型、hdr_chk 错误检查 | lab2/rtl/ppa_packet_proc_core.sv | lab2/doc/testplan.md; lab2/doc/log.md 2.6~2.8 | PARTIAL | exp_pkt_len 非零待补 |
| T-PAYLOAD-001 | §3.4/§7.3 | payload sum/xor | lab2/rtl/ppa_packet_proc_core.sv | lab2/doc/testplan.md TC1/TC5c | REVIEWED | 已审查 |
| T-TOP-001 | §2/§11.4 | top 集成与端到端处理 | TBD | TBD | TODO | Lab3 |
| T-REG-001 | §10/§11.5/§12 | 回归、覆盖率、交付清单 | TBD | TBD | TODO | Lab4 |
