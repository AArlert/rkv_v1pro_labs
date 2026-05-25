# lab2 design-note — M3 packet_proc_core

> 学生手写。设计意图记录在这里。

## 1 设计目标

- spec §6 的 3 态 FSM（IDLE → PROCESS → DONE）
- 字计数器驱动 mem_rd_addr_o 递增
- 第 0 拍提取包头字段（pkt_len/pkt_type/flags/hdr_chk）
- 长度范围检查 [4, 32]
- DONE 态结果保持

## 2 心智模型

- start_i 单拍脉冲触发 IDLE → PROCESS
- PROCESS 期间逐拍读 SRAM 累计 sum / xor
- 字数到达 `ceil(pkt_len/4)` → 进入 DONE
- DONE 态 done_o 持续保持，等下一次 start_i 后清零

## 3 与 spec 的偏离 / 澄清

| 项 | spec 章节 | 本设计选择 | 原因 |
|---|---|---|---|
| — | — | — | — |

## 4 端口表确认（与 spec §2.3 M3 表）

- [ ] clk / rst_n / start_i
- [ ] algo_mode_i / type_mask_i[3:0] / exp_pkt_len_i[5:0]
- [ ] mem_rd_en_o / mem_rd_addr_o[2:0] / mem_rd_data_i[31:0]
- [ ] busy_o / done_o
- [ ] res_pkt_len_o[5:0] / res_pkt_type_o[7:0] / res_payload_sum_o[7:0] / res_payload_xor_o[7:0]
- [ ] format_ok_o / length_error_o / type_error_o / chk_error_o

## 5 FSM 转移图（与 spec §6 对照）

```
IDLE ──start_i──► PROCESS ──last_word──► DONE ──start_i──► PROCESS
  ▲                                        │
  └────────────── (reset) ─────────────────┘
```

## 6 关键算法（学生填）

- payload_sum：__ ?（截断 8-bit 加法）
- payload_xor：__ ?（全字节 XOR）
- hdr_chk：仅在 `algo_mode_i=1` 时校验
- pkt_type：one-hot；与 `type_mask_i` AND 后判合法
