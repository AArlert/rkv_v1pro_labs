# Lab1 验收标准 (Acceptance Criteria)

> 每条验收标准配有可执行判据，供 Sign-off 时逐项检查

| # | 验收标准 | 可执行判据 | 状态 |
|---|----------|-----------|------|
| 1 | APB 基础读写时序正确 | `make run` PASS 且 log 中 `tc_apb_basic_rw PASS` | ✅ PASS |
| 2 | CSR 默认值正确 | `make run` PASS 且 log 中 `tc_csr_default_rw PASS`，8 个寄存器 read-back == reset 值 | ✅ PASS |
| 3 | PKT_MEM 写入地址映射正确 | `make run` PASS 且 log 中 `tc_pkt_mem_write PASS`，8 word 写入后 SRAM 内容与写入值一致 | ✅ PASS |
| 4 | RES_* 寄存器读通路正确 | `make run` PASS 且 CSR 读回值位域正确（RO 字段来自内部信号） | ✅ PASS |

## Sign-off 记录

- **审查通过时间**：2026-04-23
- **审查项数**：123 项全 PASS
- **遗留项**：5 项 LOW-MEDIUM 限制（详见 risk-register.md）
- **结论**：Lab1 验收通过，可进入 Lab3 集成阶段
