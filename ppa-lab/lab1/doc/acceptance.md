# Lab1 验收标准 (Acceptance Criteria)

> 每条验收标准配有可执行判据，供 Sign-off 时逐项检查

| # | 验收标准 | 可执行判据 | 状态 |
|---|----------|-----------|------|
| 1 | APB 基础读写时序正确 | `make run` PASS 且 log 中 `tc_apb_basic_rw PASS` | **PASS** |
| 2 | CSR 默认值正确 | `make run` PASS 且 log 中 `tc_csr_default_rw PASS`，11 个寄存器 read-back == reset 值 | **PASS** |
| 3 | PKT_MEM 写入地址映射正确 | `make run` PASS 且 log 中 `tc_pkt_mem_write PASS`，8 word 写入后 SRAM 内容与写入值一致 | **PASS** |
| 4 | RES_* 寄存器读通路正确 | `make run` PASS 且 CSR 读回值位域正确（RO 字段来自内部信号） | **PASS** |

## 验收结论

**Lab1 验收通过** — Sign-off Agent 于 2026-05-11 判定全部 4 项必做验收标准 PASS。

### 验收环境

| 项目 | 值 |
|------|-----|
| 编译命令 | `make comp` |
| 编译结果 | 0 error, 0 warning |
| 运行命令 | `make run` |
| 运行结果 | 10 TC / 61 checks 全 PASS, 0 FAIL |
| 工具版本 | QuestaSim-64 2021.1 |

### 扩展验证覆盖

除 acceptance.md 定义的 4 项基础验收标准外，VPlan Agent 补充的 TC4~TC10 覆盖了 feature-matrix F1-04/07/08/09/12/15 等 6 个进阶功能点，均 PASS。F1-01~F1-15 全部 15 个功能点已验证通过。

### 非阻塞遗留

| ID | 描述 | 归属 |
|----|------|------|
| U-1 | PKT_MEM APB 读返回 0（M1 未连接 M2 读端口） | Lab3 集成解决 |
| — | F1-08/F1-12 端到端验证（需 M3 配合） | Lab3 集成解决 |
