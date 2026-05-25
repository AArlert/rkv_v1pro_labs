# lab1 testplan

> 学生维护。每条 testcase 必须可追溯到 spec §10 验收场景或 §11.2 必做项。

## testcase 矩阵

| TC ID | 文件 | 目的 | spec 引用 | 必做/选做 | 状态 |
|---|---|---|---|---|---|
| TC-L1-01 | `verif/tests/csr_default_test.sv` | 复位后读所有 CSR，比对默认值 | §5 寄存器表 + §11.2 必做1 | 必做 | ⬜ |
| TC-L1-02 | `verif/tests/pkt_mem_write_test.sv` | APB 写 8 个 word 到 0x040–0x05C，监控 wr_en/wr_addr/wr_data | §11.2 必做2 | 必做 | ⬜ |
| TC-L1-03 | `verif/tests/res_read_test.sv` | stub 赋 res_*_i，APB 读回 RES_* CSR 比对 | §11.2 必做3 | 必做 | ⬜ |
| TC-L1-04 | `verif/tests/pslverr_test.sv`（选做） | 写 RO 寄存器 / 未定义地址 → PSLVERR=1 | §11.2 选做4 + §10.3 B-2 | 选做 | ⬜ |
| TC-L1-05 | `verif/tests/irq_path_test.sv`（选做） | IRQ_EN / IRQ_STA RW1C / irq_o 拉低 | §11.2 选做5 + §10.3 B-3 | 选做 | ⬜ |

## check-point 列表（self-check 必须覆盖）

- CK-1: 每个 CSR 复位值与 spec §5 表完全一致
- CK-2: PKT_MEM 写入 wr_addr 按 0→7 递增（地址映射正确）
- CK-3: PKT_MEM 写入 wr_data 与 PWDATA 一致
- CK-4: RES_PKT_LEN/TYPE/SUM/XOR 读回值 = stub 输入值
- CK-5（选做）: PSLVERR=1 时寄存器值不变
- CK-6（选做）: 写 IRQ_STA 对应位为 1 → 该位清零（RW1C）

## 状态约定
- ⬜ 未实现 / 🔄 已实现待跑 / ✅ PASS / ❌ FAIL
