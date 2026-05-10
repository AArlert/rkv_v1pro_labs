# Lab1 验收标准 (Acceptance Criteria)

> 每条验收标准配有可执行判据，供 Sign-off 时逐项检查

| # | 验收标准 | 可执行判据 | 状态 |
|---|----------|-----------|------|
| 1 | APB 基础读写时序正确 | `make run` PASS 且 log 中 `tc_apb_basic_rw PASS` | PENDING |
| 2 | CSR 默认值正确 | `make run` PASS 且 log 中 `tc_csr_default_rw PASS`，11 个寄存器 read-back == reset 值 | PENDING |
| 3 | PKT_MEM 写入地址映射正确 | `make run` PASS 且 log 中 `tc_pkt_mem_write PASS`，8 word 写入后 SRAM 内容与写入值一致 | PENDING |
| 4 | RES_* 寄存器读通路正确 | `make run` PASS 且 CSR 读回值位域正确（RO 字段来自内部信号） | PENDING |
