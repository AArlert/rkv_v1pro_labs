# Spec ↔ 实现 ↔ 测试 可追溯矩阵

> 每条 spec 需求对应一行，确保无遗漏

| Spec § | 需求摘要 | 实现位置 | 测试位置 | 状态 |
|--------|----------|----------|----------|------|
| §3.1 | APB 两段式传输 | lab1/rtl/ppa_apb_slave_if.sv | lab1/svtb/tb/ppa_tb.sv:tc_apb_basic_rw | VERIFIED |
| §3.1 | PREADY=1 | lab1/rtl/ppa_apb_slave_if.sv | lab1/svtb/tb/ppa_tb.sv:tc_apb_basic_rw | VERIFIED |
| §3.2 | CSR 地址映射 | lab1/rtl/ppa_apb_slave_if.sv | lab1/svtb/tb/ppa_tb.sv:tc_csr_default_rw | VERIFIED |
| §3.2 | 保留/越界地址 PSLVERR | lab1/rtl/ppa_apb_slave_if.sv | lab1/svtb/tb/ppa_tb.sv:tc_apb_basic_rw | VERIFIED |
| §3.3 | CSR 默认值 | lab1/rtl/ppa_apb_slave_if.sv | lab1/svtb/tb/ppa_tb.sv:tc_csr_default_rw | VERIFIED |
| §3.3 | RW/RO/W1P/RW1C 属性 | lab1/rtl/ppa_apb_slave_if.sv | lab1/svtb/tb/ppa_tb.sv:tc_csr_default_rw | VERIFIED |
| §3.4 | PKT_MEM 写映射 | lab1/rtl/ppa_apb_slave_if.sv | lab1/svtb/tb/ppa_tb.sv:tc_pkt_mem_write | VERIFIED |
| §3.4 | busy 写保护 | lab1/rtl/ppa_apb_slave_if.sv | — | TODO (Lab3) |
| §3.5 | 中断逻辑 | lab1/rtl/ppa_apb_slave_if.sv | lab1/svtb/tb/ppa_tb.sv:tc_csr_default_rw | VERIFIED |
| §4.1 | 双端口 SRAM | lab1/rtl/ppa_packet_sram.sv | lab1/svtb/tb/ppa_tb.sv:tc_pkt_mem_write | VERIFIED |
| §5.1 | 三态 FSM | lab2/rtl/ppa_packet_proc_core.sv | lab2/svtb/tb/ppa_tb.sv:TC1,TC3 | VERIFIED |
| §5.2 | busy/done 时序 | lab2/rtl/ppa_packet_proc_core.sv | lab2/svtb/tb/ppa_tb.sv:TC3 | VERIFIED |
| §5.3 | 包头解析 | lab2/rtl/ppa_packet_proc_core.sv | lab2/svtb/tb/ppa_tb.sv:TC1 | VERIFIED |
| §5.4 | 长度检查 | lab2/rtl/ppa_packet_proc_core.sv | lab2/svtb/tb/ppa_tb.sv:TC2a,TC2b | VERIFIED |
| §5.4 | 类型检查 | lab2/rtl/ppa_packet_proc_core.sv | lab2/svtb/tb/ppa_tb.sv:TC4a,TC4b | VERIFIED |
| §5.4 | 头校验 | lab2/rtl/ppa_packet_proc_core.sv | lab2/svtb/tb/ppa_tb.sv:TC5a,TC5b | VERIFIED |
| §5.5 | payload sum/XOR | lab2/rtl/ppa_packet_proc_core.sv | lab2/svtb/tb/ppa_tb.sv:TC5c | VERIFIED |
| §2.1 | ppa_top 顶层连线 | lab3/rtl/ppa_top.sv (TBD) | — | TODO |
| §5.2 | 连续两帧处理 | lab3 (TBD) | — | TODO |
