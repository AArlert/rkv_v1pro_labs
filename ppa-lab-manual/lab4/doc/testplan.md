# lab4 testplan —— 全回归矩阵

> 汇总 lab1–3 全部必做 + 已完成选做，转为 UVM testcase 形式。
> 每行格式遵循 spec §11.5 必做3 要求：testcase 名 / 检查点 / 输入摘要 / 期望输出 / 结果。

| TC name | check-point | 输入摘要 | 期望输出 | 结果 |
|---|---|---|---|---|
| csr_default_test       | CK-L1-1 | 复位后读全部 CSR | 默认值匹配 spec §5 | ⬜ |
| pkt_mem_write_test     | CK-L1-2/3 | APB 写 8 word 到 PKT_MEM | wr_en/wr_addr/wr_data 正确 | ⬜ |
| res_read_test          | CK-L1-4 | stub RES_*，APB 读回 | 与 stub 一致 | ⬜ |
| pkt_proc_legal_test    | CK-L2-1/3 | 8B 合法包 | format_ok=1, res_* 正确 | ⬜ |
| pkt_proc_overflow_test | CK-L2-2 | pkt_len=3/33 | length_error=1, FSM 不卡死 | ⬜ |
| pkt_proc_busy_done_test| CK-L2-5 | start → busy → done → start | 时序符合 | ⬜ |
| e2e_smoke_test         | CK-L3-1 | 端到端 1 帧 | RES_* 正确 | ⬜ |
| e2e_two_frames_test    | CK-L3-2 | 端到端连续 2 帧 | 两帧独立正确 | ⬜ |
| e2e_status_test        | CK-L3-3 | 端到端 + STATUS 读 | STATUS 实时反映 | ⬜ |

## 覆盖率目标（spec §11.5 必做2）

| 类型 | 目标 |
|---|---|
| line | ≥ 90% |
| branch | ≥ 90% |
| condition | ≥ 90% |
| FSM (M3) | 全状态 + 全转移命中 |
| toggle | ≥ 90% |

## 选做（spec §11.5 选做5）

- 覆盖率过滤登记表（Excel）—— 与本 testplan 一同提交
